codeunit 148090 "Compensations CZC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Compensations]
        isInitialized := false;
    end;

    var
        CompensationsSetupCZC: Record "Compensations Setup CZC";
        Assert: Codeunit Assert;
        LibraryCompensationCZC: Codeunit "Library - Compensation CZC";
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        CompensationSourceTypeCZC: Enum "Compensation Source Type CZC";
        isInitialized: Boolean;

    local procedure Initialize()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Compensations CZC");
        LibraryRandom.Init();
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Compensations CZC");

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Validate("Credit Memo Nos.", LibraryERM.CreateNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
        LibrarySales.SetPostedNoSeriesInSetup();

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Invoice Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Validate("Credit Memo Nos.", LibraryERM.CreateNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
        LibraryPurchase.SetPostedNoSeriesInSetup();

        CompensationsSetupCZC.Get();
        CompensationsSetupCZC."Compensation Nos." := LibraryERM.CreateNoSeriesCode();
        CompensationsSetupCZC."Compensation Bal. Account No." := LibraryERM.CreateGLAccountNo();
        CompensationsSetupCZC."Compensation Proposal Method" := CompensationsSetupCZC."Compensation Proposal Method"::"Registration No.";
        CompensationsSetupCZC."Max. Rounding Amount" := 1;
        CompensationsSetupCZC."Debit Rounding Account" := LibraryERM.CreateGLAccountNo();
        CompensationsSetupCZC."Credit Rounding Account" := LibraryERM.CreateGLAccountNo();
        CompensationsSetupCZC.Modify();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Compensations CZC");
    end;

    [Test]
    procedure ReleasingCompensationWithCustLedgEntries()
    begin
        ReleasingCompensation(CompensationSourceTypeCZC::Customer);
    end;

    [Test]
    procedure ReleasingCompensationWithVendLedgEntries()
    begin
        ReleasingCompensation(CompensationSourceTypeCZC::Vendor);
    end;

    local procedure ReleasingCompensation(CompensationSourceTypeCZC: Enum "Compensation Source Type CZC")
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        CompensationLineCZC1: Record "Compensation Line CZC";
        CompensationLineCZC2: Record "Compensation Line CZC";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] Compensations Release
        Initialize();

        // [GIVEN] New compensation header has been created
        CreateCompensationHeader(CompensationHeaderCZC, CompensationSourceTypeCZC);

        // [GIVEN] New compensation lines has been created
        case CompensationSourceTypeCZC of
            CompensationLineCZC1."Source Type"::Customer:
                begin
                    CreateCustomerLedgerEntry(CustLedgerEntry, CompensationHeaderCZC."Company No.", "Sales Document Type"::Invoice);
                    CreateCompensationLine(
                      CompensationLineCZC1, CompensationHeaderCZC, CompensationSourceTypeCZC, CustLedgerEntry."Entry No.");
                    CreateCustomerLedgerEntry(CustLedgerEntry, CompensationHeaderCZC."Company No.", "Sales Document Type"::"Credit Memo");
                    CreateCompensationLine(
                      CompensationLineCZC2, CompensationHeaderCZC, CompensationSourceTypeCZC, CustLedgerEntry."Entry No.");
                end;
            CompensationLineCZC1."Source Type"::Vendor:
                begin
                    CreateVendorLedgerEntry(VendorLedgerEntry, CompensationHeaderCZC."Company No.", "Purchase Document Type"::Invoice);
                    CreateCompensationLine(
                      CompensationLineCZC1, CompensationHeaderCZC, CompensationSourceTypeCZC, VendorLedgerEntry."Entry No.");
                    CreateVendorLedgerEntry(VendorLedgerEntry, CompensationHeaderCZC."Company No.", "Purchase Document Type"::"Credit Memo");
                    CreateCompensationLine(
                      CompensationLineCZC2, CompensationHeaderCZC, CompensationSourceTypeCZC, VendorLedgerEntry."Entry No.");
                end;
        end;

        // [GIVEN] Compensation lines has been balanced
        if Abs(CompensationLineCZC1."Amount (LCY)") > Abs(CompensationLineCZC2."Amount (LCY)") then
            LibraryCompensationCZC.UpdateCompensationLine(CompensationLineCZC1, -CompensationLineCZC2."Amount (LCY)")
        else
            LibraryCompensationCZC.UpdateCompensationLine(CompensationLineCZC2, -CompensationLineCZC1."Amount (LCY)");

        // [WHEN] Release compensation
        ReleaseCompensation(CompensationHeaderCZC);

        // [THEN] Compensation will be released
        CompensationHeaderCZC.Get(CompensationHeaderCZC."No.");
        CompensationHeaderCZC.TestField(Status, CompensationHeaderCZC.Status::Released);

        // [WHEN] Reopen compensation
        Reopen(CompensationHeaderCZC);

        // [THEN] Compensation will be open
        CompensationHeaderCZC.TestField(Status, CompensationHeaderCZC.Status::Open);
    end;

    [Test]
    procedure PostingCompensationWithCustLedgEntries()
    begin
        PostingCompensation(CompensationSourceTypeCZC::Customer);
    end;

    [Test]
    procedure PostingCompensationWithVendLedgEntries()
    begin
        PostingCompensation(CompensationSourceTypeCZC::Vendor);
    end;

    local procedure PostingCompensation(CompensationSourceTypeCZC: Enum "Compensation Source Type CZC")
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        CompensationLineCZC1: Record "Compensation Line CZC";
        CompensationLineCZC2: Record "Compensation Line CZC";
        PostedCompensationHeaderCZC: Record "Posted Compensation Header CZC";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO] Compensations Posting
        Initialize();

        // [GIVEN] New compensation header has been created
        CreateCompensationHeader(CompensationHeaderCZC, CompensationSourceTypeCZC);

        // [GIVEN] New compensation lines has been created
        case CompensationSourceTypeCZC of
            CompensationLineCZC1."Source Type"::Customer:
                begin
                    CreateCustomerLedgerEntry(CustLedgerEntry, CompensationHeaderCZC."Company No.", "Sales Document Type"::Invoice);
                    CreateCompensationLine(
                      CompensationLineCZC1, CompensationHeaderCZC, CompensationSourceTypeCZC, CustLedgerEntry."Entry No.");
                    CreateCustomerLedgerEntry(CustLedgerEntry, CompensationHeaderCZC."Company No.", "Sales Document Type"::"Credit Memo");
                    CreateCompensationLine(
                      CompensationLineCZC2, CompensationHeaderCZC, CompensationSourceTypeCZC, CustLedgerEntry."Entry No.");
                end;
            CompensationLineCZC1."Source Type"::Vendor:
                begin
                    CreateVendorLedgerEntry(VendorLedgerEntry, CompensationHeaderCZC."Company No.", "Purchase Document Type"::Invoice);
                    CreateCompensationLine(
                      CompensationLineCZC1, CompensationHeaderCZC, CompensationSourceTypeCZC, VendorLedgerEntry."Entry No.");
                    CreateVendorLedgerEntry(VendorLedgerEntry, CompensationHeaderCZC."Company No.", "Purchase Document Type"::"Credit Memo");
                    CreateCompensationLine(
                      CompensationLineCZC2, CompensationHeaderCZC, CompensationSourceTypeCZC, VendorLedgerEntry."Entry No.");
                end;
        end;

        // [GIVEN] Compensation lines has been balanced
        if Abs(CompensationLineCZC1."Amount (LCY)") > Abs(CompensationLineCZC2."Amount (LCY)") then
            LibraryCompensationCZC.UpdateCompensationLine(CompensationLineCZC1, -CompensationLineCZC2."Amount (LCY)")
        else
            LibraryCompensationCZC.UpdateCompensationLine(CompensationLineCZC2, -CompensationLineCZC1."Amount (LCY)");

        // [GIVEN] Post compensation
        PostCompensation(CompensationHeaderCZC);

        // [THEN] Posted compensation will exists
        PostedCompensationHeaderCZC.Get(CompensationHeaderCZC."No.");
    end;

    [Test]
    [HandlerFunctions('ModalPageCompensationProposalHandler')]
    procedure AutomaticSuggestCompensationLines()
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        CompensationLineCZC: Record "Compensation Line CZC";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocNo: array[2] of Code[20];
        Amount: array[2] of Decimal;
    begin
        // [SCENARIO] Suggest Compensation
        Initialize();

        // [GIVEN] New compensation header has been created
        CreateCompensationHeader(CompensationHeaderCZC, CompensationSourceTypeCZC::Customer);

        // [GIVEN] Sales Invoice has been created and posted
        CreateSalesInvoice(SalesHeader, SalesLine, CompensationHeaderCZC."Company No.");
        Amount[1] := SalesLine."Amount Including VAT";
        PostedDocNo[1] := PostSalesDocument(SalesHeader);

        // [GIVEN] Sales Credit Memo has been created and posted
        CreateSalesCreditMemo(SalesHeader, SalesLine, CompensationHeaderCZC."Company No.");
        Amount[2] := SalesLine."Amount Including VAT";
        PostedDocNo[2] := PostSalesDocument(SalesHeader);

        // [WHEN] Suggest compensation lines
        LibraryCompensationCZC.RunSuggestCompensationLines(CompensationHeaderCZC);

        // [THEN] Compensation line to sales credit memo will exist
        CompensationLineCZC.SetRange("Compensation No.", CompensationHeaderCZC."No.");
        CompensationLineCZC.FindSet();
        CompensationLineCZC.TestField("Document Type", CompensationLineCZC."Document Type"::"Credit Memo");
        CompensationLineCZC.TestField("Document No.", PostedDocNo[2]);
        CompensationLineCZC.TestField(Amount, -Amount[2]);

        // [THEN] Compensation line to sales invoice will exists
        CompensationLineCZC.Next();
        CompensationLineCZC.TestField("Document Type", CompensationLineCZC."Document Type"::Invoice);
        CompensationLineCZC.TestField("Document No.", PostedDocNo[1]);
        CompensationLineCZC.TestField(Amount, Amount[1]);
    end;

    [Test]
    [HandlerFunctions('ModalPageCompensationProposalHandler')]
    procedure BlockingEntriesOnReleasedCompensations()
    var
        CompensationHeaderCZC1: Record "Compensation Header CZC";
        CompensationHeaderCZC2: Record "Compensation Header CZC";
        CompensationLineCZC1: Record "Compensation Line CZC";
        CompensationLineCZC2: Record "Compensation Line CZC";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        // [SCENARIO] Compensations Blocking entries
        Initialize();

        // [GIVEN] Compensation header has been created
        CreateCompensationHeader(CompensationHeaderCZC1, CompensationSourceTypeCZC::Customer);

        // [GIVEN] Sales invoice has been created and posted
        CreateSalesInvoice(SalesHeader, SalesLine, CompensationHeaderCZC1."Company No.");
        PostSalesDocument(SalesHeader);

        // [GIVEN] Sales invoice has been created and posted
        CreateSalesCreditMemo(SalesHeader, SalesLine, CompensationHeaderCZC1."Company No.");
        PostSalesDocument(SalesHeader);

        // [GIVEN] Compensation lines has been suggested
        LibraryCompensationCZC.RunSuggestCompensationLines(CompensationHeaderCZC1);
        CompensationLineCZC1.Get(CompensationHeaderCZC1."No.", 10000);
        CompensationLineCZC2.Get(CompensationHeaderCZC1."No.", 20000);

        // [GIVEN] Compensation lines has been balanced
        if Abs(CompensationLineCZC1."Amount (LCY)") > Abs(CompensationLineCZC2."Amount (LCY)") then
            LibraryCompensationCZC.UpdateCompensationLine(CompensationLineCZC1, -CompensationLineCZC2."Amount (LCY)")
        else
            LibraryCompensationCZC.UpdateCompensationLine(CompensationLineCZC2, -CompensationLineCZC1."Amount (LCY)");

        // [GIVEN] Compensation document has been released
        ReleaseCompensation(CompensationHeaderCZC1);

        // [GIVEN] Compensation header has been created with the same customer
        CreateCompensationHeader(CompensationHeaderCZC2, CompensationSourceTypeCZC::Customer);
        CompensationHeaderCZC2.Validate("Company No.", CompensationHeaderCZC1."Company No.");
        CompensationHeaderCZC2.Modify(false);

        // [WHEN] Suggest compensation lines
        LibraryCompensationCZC.RunSuggestCompensationLines(CompensationHeaderCZC2);

        // [THEN] No compensation line will exist
        CompensationLineCZC2.SetRange("Compensation No.", CompensationHeaderCZC2."No.");
        Assert.AreEqual(0, CompensationLineCZC2.Count(), 'No compensation line was expected for this compensation.');
    end;

    [Test]
    [HandlerFunctions('CustomerSourceEntryLookupHandler')]
    procedure CustomerSourceEntryLookupRespectsEventFilters()
    begin
        SourceEntryLookupRespectsEventFilters(CompensationSourceTypeCZC::Customer);
    end;

    [Test]
    [HandlerFunctions('VendorSourceEntryLookupHandler')]
    procedure VendorSourceEntryLookupRespectsEventFilters()
    begin
        SourceEntryLookupRespectsEventFilters(CompensationSourceTypeCZC::Vendor);
    end;

    local procedure SourceEntryLookupRespectsEventFilters(SourceType: Enum "Compensation Source Type CZC")
    var
        CompensationHeaderCZC: Record "Compensation Header CZC";
        CompensationLineCZC: Record "Compensation Line CZC";
        CompLookupSubscribersCZC: Codeunit "Comp. Lookup Subscribers CZC";
        CompensationCardCZC: TestPage "Compensation Card CZC";
        InitialSourceEntryNo: Integer;
        SourceEntryNo: Integer;
    begin
        // [SCENARIO] Source entry lookup respects filters changed by the event for the selected source type.
        Initialize();

        // [GIVEN] Three invoices are posted, with one already used on a compensation line.
        CreateCompensationHeader(CompensationHeaderCZC, SourceType);
        SourceEntryNo := CreateSourceEntryLookupInvoices(CompensationHeaderCZC, SourceType, InitialSourceEntryNo);
        CreateCompensationLine(CompensationLineCZC, CompensationHeaderCZC, SourceType, InitialSourceEntryNo);
        CompensationsSetupCZC.Get();
        CompensationsSetupCZC."Including Entries with On Hold" := false;
        CompensationsSetupCZC.Modify();

        // [GIVEN] A manually bound subscriber restricts the two eligible invoices to the last invoice.
        Assert.IsTrue(BindSubscription(CompLookupSubscribersCZC), 'The lookup subscribers must be bound.');
        LibraryVariableStorage.Enqueue(SourceEntryNo);
        CompensationCardCZC.OpenEdit();
        CompensationCardCZC.GoToRecord(CompensationHeaderCZC);
        CompensationCardCZC.CompensationLinesCZC.GoToRecord(CompensationLineCZC);

        // [WHEN] The source entry lookup is opened and its only entry is selected.
        CompensationCardCZC.CompensationLinesCZC."Source Entry No.".Lookup();
        CompensationCardCZC.Close();
        Assert.IsTrue(UnbindSubscription(CompLookupSubscribersCZC), 'The lookup subscribers must be unbound.');

        // [THEN] The selected entry was saved on the compensation line.
        CompensationLineCZC.Get(CompensationLineCZC."Compensation No.", CompensationLineCZC."Line No.");
        CompensationLineCZC.TestField("Source Entry No.", SourceEntryNo);
        CompensationLineCZC.TestField("Source No.", CompensationHeaderCZC."Company No.");
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateSourceEntryLookupInvoices(CompensationHeaderCZC: Record "Compensation Header CZC"; SourceType: Enum "Compensation Source Type CZC"; var InitialSourceEntryNo: Integer): Integer
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        CustLedgerEntry: Record "Cust. Ledger Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
        InvoiceIndex: Integer;
    begin
        for InvoiceIndex := 1 to 3 do
            case SourceType of
                SourceType::Customer:
                    begin
                        CreateSalesInvoice(SalesHeader, SalesLine, CompensationHeaderCZC."Company No.");
                        DocumentNo := PostSalesDocument(SalesHeader);
                    end;
                SourceType::Vendor:
                    begin
                        CreatePurchaseDocument(
                          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, CompensationHeaderCZC."Company No.");
                        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
                    end;
            end;

        case SourceType of
            SourceType::Customer:
                begin
                    CustLedgerEntry.SetRange("Customer No.", CompensationHeaderCZC."Company No.");
                    CustLedgerEntry.SetRange(Open, true);
                    CustLedgerEntry.SetRange(Prepayment, false);
                    CustLedgerEntry.SetRange("Compensation Amount (LCY) CZC", 0);
                    CustLedgerEntry.SetRange("On Hold", '');
                    Assert.AreEqual(3, CustLedgerEntry.Count(), 'Three eligible customer ledger entries must exist.');
                    CustLedgerEntry.SetFilter("Document No.", '<>%1', DocumentNo);
                    CustLedgerEntry.FindFirst();
                    InitialSourceEntryNo := CustLedgerEntry."Entry No.";
                    CustLedgerEntry.SetRange("Document No.", DocumentNo);
                    CustLedgerEntry.FindFirst();
                    CustLedgerEntry.Validate(Description, 'Lookup event filter CZC');
                    CustLedgerEntry.Modify(true);
                    exit(CustLedgerEntry."Entry No.");
                end;
            SourceType::Vendor:
                begin
                    VendorLedgerEntry.SetRange("Vendor No.", CompensationHeaderCZC."Company No.");
                    VendorLedgerEntry.SetRange(Open, true);
                    VendorLedgerEntry.SetRange(Prepayment, false);
                    VendorLedgerEntry.SetRange("Compensation Amount (LCY) CZC", 0);
                    VendorLedgerEntry.SetRange("On Hold", '');
                    Assert.AreEqual(3, VendorLedgerEntry.Count(), 'Three eligible vendor ledger entries must exist.');
                    VendorLedgerEntry.SetFilter("Document No.", '<>%1', DocumentNo);
                    VendorLedgerEntry.FindFirst();
                    InitialSourceEntryNo := VendorLedgerEntry."Entry No.";
                    VendorLedgerEntry.SetRange("Document No.", DocumentNo);
                    VendorLedgerEntry.FindFirst();
                    VendorLedgerEntry.Validate(Description, 'Lookup event filter CZC');
                    VendorLedgerEntry.Modify(true);
                    exit(VendorLedgerEntry."Entry No.");
                end;
        end;
    end;

    local procedure CreateCompensationHeader(var CompensationHeaderCZC: Record "Compensation Header CZC"; CompensationSourceTypeCZC: Enum "Compensation Source Type CZC")
    begin
        case CompensationSourceTypeCZC of
            CompensationSourceTypeCZC::Customer:
                LibraryCompensationCZC.CreateCompensationHeader(CompensationHeaderCZC, CompensationSourceTypeCZC, LibrarySales.CreateCustomerNo());
            CompensationSourceTypeCZC::Vendor:
                LibraryCompensationCZC.CreateCompensationHeader(CompensationHeaderCZC, CompensationSourceTypeCZC, LibraryPurchase.CreateVendorNo());
        end;
    end;

    local procedure CreateCompensationLine(var CompensationLineCZC: Record "Compensation Line CZC"; CompensationHeaderCZC: Record "Compensation Header CZC";
                                           CompensationSourceTypeCZC: Enum "Compensation Source Type CZC"; SourceEntryNo: Integer)
    begin
        LibraryCompensationCZC.CreateCompensationLine(CompensationLineCZC, CompensationHeaderCZC, CompensationSourceTypeCZC, SourceEntryNo);
    end;

    local procedure CreateGLAccount(var GLAccount: Record "G/L Account"; WithVATPostingSetup: Boolean)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccountNo: Code[20];
    begin
        if not WithVATPostingSetup then
            LibraryERM.CreateGLAccount(GLAccount)
        else begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
            GLAccount.Get(GLAccountNo);
        end;
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line";
                                        SalesDocumentType: Enum "Sales Document Type"; CustomerNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesDocumentType, CustomerNo);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GetNewGLAccountNo(true), 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(10000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesCreditMemo(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
    end;

    local procedure CreateSalesInvoice(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; CustomerNo: Code[20])
    begin
        CreateSalesDocument(SalesHeader, SalesLine, SalesHeader."Document Type"::Invoice, CustomerNo);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line";
                                           DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GetNewGLAccountNo(true), 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure GetNewGLAccountNo(WithVATPostingSetup: Boolean): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        CreateGLAccount(GLAccount, WithVATPostingSetup);
        exit(GLAccount."No.");
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"; CustomerNo: Code[20]; DocumentType: Enum "Sales Document Type")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PostedDocumentNo: Code[20];
    begin
        CreateSalesDocument(SalesHeader, SalesLine, DocumentType, CustomerNo);
        PostedDocumentNo := PostSalesDocument(SalesHeader);

        CustLedgerEntry.Reset();
        CustLedgerEntry.SetRange("Customer No.", CustomerNo);
        CustLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        case DocumentType of
            DocumentType::Invoice:
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::Invoice);
            DocumentType::"Credit Memo":
                CustLedgerEntry.SetRange("Document Type", CustLedgerEntry."Document Type"::"Credit Memo");
        end;
        CustLedgerEntry.SetRange(Open, true);
        CustLedgerEntry.FindFirst();
    end;

    local procedure CreateVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PostedDocumentNo: Code[20];
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseLine, DocumentType, VendorNo);
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VendorLedgerEntry.Reset();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Document No.", PostedDocumentNo);
        case DocumentType of
            DocumentType::Invoice:
                VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::Invoice);
            DocumentType::"Credit Memo":
                VendorLedgerEntry.SetRange("Document Type", VendorLedgerEntry."Document Type"::"Credit Memo");
        end;
        VendorLedgerEntry.SetRange(Open, true);
        VendorLedgerEntry.FindFirst();
    end;

    local procedure PostCompensation(var CompensationHeaderCZC: Record "Compensation Header CZC")
    begin
        LibraryCompensationCZC.RunPostCompensation(CompensationHeaderCZC);
    end;

    local procedure PostSalesDocument(var SalesHeader: Record "Sales Header"): Code[20]
    begin
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure ReleaseCompensation(var CompensationHeaderCZC: Record "Compensation Header CZC")
    begin
        LibraryCompensationCZC.RunReleaseCompensation(CompensationHeaderCZC);
    end;

    local procedure Reopen(var CompensationHeaderCZC: Record "Compensation Header CZC")
    begin
        LibraryCompensationCZC.RunReopenCompensation(CompensationHeaderCZC);
    end;

    [ModalPageHandler]
    procedure CustomerSourceEntryLookupHandler(var CustomerLedgerEntries: TestPage "Customer Ledger Entries")
    begin
        Assert.IsTrue(CustomerLedgerEntries.First(), 'The filtered customer entry must be shown.');
        CustomerLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueInteger());
        Assert.IsFalse(CustomerLedgerEntries.Next(), 'No other customer entry may be shown.');
        CustomerLedgerEntries.First();
        CustomerLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure VendorSourceEntryLookupHandler(var VendorLedgerEntries: TestPage "Vendor Ledger Entries")
    begin
        Assert.IsTrue(VendorLedgerEntries.First(), 'The filtered vendor entry must be shown.');
        VendorLedgerEntries."Entry No.".AssertEquals(LibraryVariableStorage.DequeueInteger());
        Assert.IsFalse(VendorLedgerEntries.Next(), 'No other vendor entry may be shown.');
        VendorLedgerEntries.First();
        VendorLedgerEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ModalPageCompensationProposalHandler(var CompensationProposalCZC: TestPage "Compensation Proposal CZC")
    begin
        CompensationProposalCZC.CustLedgEntries.First();
        CompensationProposalCZC.CustLedgEntries.SetMark.Invoke();
        CompensationProposalCZC.CustLedgEntries.Next();
        CompensationProposalCZC.CustLedgEntries.SetMark.Invoke();
        CompensationProposalCZC.OK().Invoke();
    end;
}
