codeunit 144003 "IT - Activity Code"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Activity Code]
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryRandom: Codeunit "Library - Random";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryService: Codeunit "Library - Service";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        IncorrectFieldLengthErr: Label '%1 should be of length %2 only';
        MissingActivityCodeErr: Label '%1 must have a value in %2: %3=%4, %5=%6. It cannot be zero or empty.';
        MissingActivityCodeOnJournalErr: Label '%1 must have a value in %2: %3=%4, %5=%6, %7=%8. It cannot be zero or empty.';

    [Test]
    [Scope('OnPrem')]
    procedure MaximumLengthOfFieldActivityCodeOnActivityCodeTable()
    var
        ActivityCode: Record "Activity Code";
    begin
        // [SCENARIO 338450] Activity Code's table has Activity Code field of length 6
        Initialize();

        // [THEN] Verify the length of field 'Activity Code' on Activity Code table.
        Assert.AreEqual(
          6, LibraryUtility.GetFieldLength(12124, 1), StrSubstNo(IncorrectFieldLengthErr, ActivityCode.FieldCaption(Code), 6));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPostingPossibleWithoutActivityCodeForJournals()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Post]
        // [SCENARIO 338450] User can not post Gen. Journal line without Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Gen. Journal was created without Activity Code
        CreateGenJournalLine(GenJournalLine);

        // [WHEN] Try post the line
        AssertError Codeunit.Run(Codeunit::"Gen. Jnl.-Post Batch", GenJournalLine);

        // [THEN] Activity code error appears
        Assert.ExpectedError(
              StrSubstNo(
                MissingActivityCodeOnJournalErr, GenJournalLine.FieldCaption("Activity Code"), GenJournalLine.TableCaption(), GenJournalLine.FieldCaption("Journal Template Name"),
                GenJournalLine."Journal Template Name", GenJournalLine.FieldCaption("Journal Batch Name"), GenJournalLine."Journal Batch Name", GenJournalLine.FieldCaption("Line No."), GenJournalLine."Line No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPostingPossibleWithoutActivityCodeForPurchaseDocuments()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase] [Post]
        // [SCENARIO 338450] User can not post Purchase document without Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Purchase header was created without Activity Code
        CreatePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate(Ship, true);
        PurchaseHeader.Validate(Receive, true);
        PurchaseHeader.Validate(Invoice, true);
        PurchaseHeader.Modify(true);

        // [WHEN] Try post the document
        AssertError Codeunit.Run(Codeunit::"Purch.-Post", PurchaseHeader);

        // [THEN] Activity code error appears
        Assert.ExpectedError(
              StrSubstNo(
                MissingActivityCodeErr, PurchaseHeader.FieldCaption("Activity Code"), PurchaseHeader.TableCaption(), PurchaseHeader.FieldCaption("Document Type"), PurchaseHeader."Document Type",
                PurchaseHeader.FieldCaption("No."), PurchaseHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPostingPossibleWithoutActivityCodeForSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [FEATURE] [Sales] [Post]
        // [SCENARIO 338450] User can not post Sales document without Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Sales header was created without Activity Code
        CreateSalesDocument(SalesHeader);
        SalesHeader.Validate(Ship, true);
        SalesHeader.Validate(Receive, true);
        SalesHeader.Validate(Invoice, true);
        SalesHeader.Validate("Activity Code", '');
        SalesHeader.Modify(true);

        // [WHEN] Try post the document
        AssertError Codeunit.Run(Codeunit::"Sales-Post", SalesHeader);

        // [THEN] Activity code error appears
        Assert.ExpectedError(
              StrSubstNo(
                MissingActivityCodeErr, SalesHeader.FieldCaption("Activity Code"), SalesHeader.TableCaption(), SalesHeader.FieldCaption("Document Type"), SalesHeader."Document Type",
                SalesHeader.FieldCaption("No."), SalesHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoPostingPossibleWithoutActivityCodeForServiceDocuments()
    var
        ServiceHeader: Record "Service Header";
    begin
        // [FEATURE] [Service] [Post]
        // [SCENARIO 338450] User can not post Service document without Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Service header was created without Activity Code
        CreateServiceDocument(ServiceHeader);

        // [WHEN] Try post the document
        AssertError Codeunit.Run(Codeunit::"Service-Post", ServiceHeader);

        // [THEN] Activity code error appears
        Assert.ExpectedError(
              StrSubstNo(
                MissingActivityCodeErr, ServiceHeader.FieldCaption("Activity Code"), ServiceHeader.TableCaption(), ServiceHeader.FieldCaption("Document Type"), ServiceHeader."Document Type",
                ServiceHeader.FieldCaption("No."), ServiceHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForJournals()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [Post]
        // [SCENARIO 338450] User can post Gen. Journal Line with Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] General journal line was created with an activity code
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine.Validate("Activity Code", CreateActivityCode());
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Document is posted and VAT Entry has activity code
        VerifyActivityCodeOnVATEntry(GenJournalLine."Document No.", GenJournalLine."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForRecurringJournalWithMoreThanOneAllocation()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Recurring Journal] [Post]
        // [SCENARIO 338450] User can post Recurring Gen. Journal Line with Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Recurring Gen. Journal line was created with an activity code
        CreateRecurringGenJournalLine(GenJournalLine);
        GenJournalLine.Validate("Activity Code", CreateActivityCode());
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Line is posted and VAT Entry has activity code
        VerifyActivityCodeOnVATEntry(GenJournalLine."Document No.", GenJournalLine."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForPurchaseDocuments()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Post]
        // [SCENARIO 338450] User can post Purchase document with Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Purchase header was created with an activity code
        CreatePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Activity Code", CreateActivityCode());
        PurchaseHeader.Modify();

        // [GIVEN] Purchase header was posted
        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Document is posted and VAT Entry has activity code
        VerifyActivityCodeOnVATEntry(PostedDocumentNo, PurchaseHeader."Activity Code");
        VerifyActivityCodeOnPostedPurchaseInvoice(PostedDocumentNo, PurchaseHeader."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForSalesDocuments()
    var
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales] [Post]
        // [SCENARIO 338450] User can post Sales document with Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Sales header was created with an activity code
        CreateSalesDocument(SalesHeader);
        SalesHeader.Validate("Activity Code", CreateActivityCode());
        SalesHeader.Modify();

        // [WHEN] Pos sales header
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Document is posted and VAT Entry has activity code
        VerifyActivityCodeOnVATEntry(PostedDocumentNo, SalesHeader."Activity Code");
        VerifyActivityCodeOnPostedSalesInvoice(PostedDocumentNo, SalesHeader."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForServiceDocuments()
    var
        ServiceHeader: Record "Service Header";
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        // [FEATURE] [Service] [Post]
        // [SCENARIO 338450] User can post Service document with Activity Code when Use activity code is enabled
        Initialize();

        // [GIVEN] Service header was created with an activity code
        CreateServiceDocument(ServiceHeader);
        ServiceHeader.Validate("Activity Code", CreateActivityCode());
        ServiceHeader.Modify();

        // [WHEN] Post service header
        LibraryService.PostServiceOrder(ServiceHeader, true, false, true);
        CustLedgerEntry.SetRange("Customer No.", ServiceHeader."Customer No.");
        CustLedgerEntry.FindFirst();

        // [THEN] Document is posted and VAT Entry has activity code
        VerifyActivityCodeOnVATEntry(CustLedgerEntry."Document No.", ServiceHeader."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VATEntryHasActivityCodeWhenUseActivityCodeOptionDisabled()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [General Journal] [Post]
        // [SCENARIO 405435] VAT Entry has activity code even when "Use Activity Code" option is disabled

        Initialize();

        // [GIVEN] "Use Activity Code" is disabled in General Ledger Setup
        SetUseActivityCodeOnGLSetup(false);

        // [GIVEN] General journal line was created with an activity code
        CreateGenJournalLine(GenJournalLine);
        GenJournalLine.Validate("Activity Code", CreateActivityCode());
        GenJournalLine.Modify();

        // [WHEN] Post Gen. Journal line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Document is posted and VAT Entry has activity code
        VerifyActivityCodeOnVATEntry(GenJournalLine."Document No.", GenJournalLine."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForPurchaseDocumentsNotMandatory()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Purchase]
        // [SCENARIO 423162] xxxxxx
        Initialize();

        SetUseActivityCodeOnGLSetup(false);

        CreatePurchaseDocument(PurchaseHeader);
        PurchaseHeader.Validate("Activity Code", CreateActivityCode());
        PurchaseHeader.Modify(true);

        PostedDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        VerifyActivityCodeOnPostedPurchaseInvoice(PostedDocumentNo, PurchaseHeader."Activity Code");
        VerifyActivityCodeOnVATEntry(PostedDocumentNo, PurchaseHeader."Activity Code");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPossibleWithActivityCodeForSalesDocumentsNotMandatory()
    var
        SalesHeader: Record "Sales Header";
        PostedDocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO 423162] xxxxxx
        Initialize();

        SetUseActivityCodeOnGLSetup(false);

        CreateSalesDocument(SalesHeader);
        SalesHeader.Validate("Activity Code", CreateActivityCode());
        SalesHeader.Modify();

        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        VerifyActivityCodeOnPostedSalesInvoice(PostedDocumentNo, SalesHeader."Activity Code");
        VerifyActivityCodeOnVATEntry(PostedDocumentNo, SalesHeader."Activity Code");
    end;

    local procedure Initialize()
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        SetUseActivityCodeOnGLSetup(true);

        LibrarySetupStorage.SaveGeneralLedgerSetup();

        IsInitialized := true;
    end;

    local procedure CreateGenJnlAllocation(GenJournalLine: Record "Gen. Journal Line"; AllocationPercent: Decimal)
    var
        GenJnlAllocation: Record "Gen. Jnl. Allocation";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGenJnlAllocation(
          GenJnlAllocation, GenJournalLine."Journal Template Name", GenJournalLine."Journal Batch Name", GenJournalLine."Line No.");
        LibraryERM.CreateGLAccount(GLAccount);
        GenJnlAllocation.Validate("Account No.", GLAccount."No.");
        GenJnlAllocation.Validate("Allocation %", AllocationPercent);
        GenJnlAllocation.Modify(true);
    end;

    local procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        BankAccount: Record "Bank Account";
    begin
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.FindBankAccount(BankAccount);
        GenJournalBatch.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"Bank Account");
        GenJournalBatch.Validate("Bal. Account No.", BankAccount."No.");
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(1000, 2));
    end;

    local procedure CreateGLAccount(): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
        GLAccount.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        GLAccount.Validate("Gen. Posting Type", GLAccount."Gen. Posting Type"::Purchase);
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header")
    var
        Vendor: Record Vendor;
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));
    end;

    local procedure CreateActivityCode(): Code[6]
    var
        ActivityCode: Record "Activity Code";
    begin
        ActivityCode.Init();
        ActivityCode.Validate(
          Code,
          CopyStr(LibraryUtility.GenerateRandomCode(ActivityCode.FieldNo(Code), DATABASE::"Activity Code"),
            1, LibraryUtility.GetFieldLength(DATABASE::"Activity Code", ActivityCode.FieldNo(Code))));
        ActivityCode.Insert(true);
        ActivityCode.Validate(Description, ActivityCode.Code);
        ActivityCode.Modify(true);
        exit(ActivityCode.Code);
    end;

    local procedure CreateRecurringGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        RecurringFrequency: DateFormula;
        i: Integer;
    begin
        LibraryERM.CreateRecurringTemplateName(GenJournalTemplate);
        LibraryERM.CreateRecurringBatchName(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Posting No. Series", '');
        GenJournalBatch.Modify(true);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::"G/L Account", CreateGLAccount(), LibraryRandom.RandDec(1000, 2));
        GenJournalLine.Validate("Recurring Method", GenJournalLine."Recurring Method"::"F  Fixed");
        EVALUATE(RecurringFrequency, '1M');
        GenJournalLine.Validate("Recurring Frequency", RecurringFrequency);
        GenJournalLine.Modify(true);
        for i := 1 to 2 do
            CreateGenJnlAllocation(GenJournalLine, 50.0);
    end;

    local procedure CreateSalesDocument(var SalesHeader: Record "Sales Header")
    var
        Customer: Record Customer;
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(10));
    end;

    local procedure CreateServiceDocument(var ServiceHeader: Record "Service Header")
    var
        Customer: Record Customer;
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibraryService.CreateServiceItem(ServiceItem, Customer."No.");
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, LibraryInventory.CreateItem(Item));
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, LibraryRandom.RandInt(10));
        ServiceLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        ServiceLine.Modify(true);
    end;

    local procedure SetUseActivityCodeOnGLSetup(NewActivityCode: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Use Activity Code", NewActivityCode);
        GeneralLedgerSetup.Modify();
    end;

    local procedure VerifyActivityCodeOnVATEntry(DocumentNo: Code[20]; ExpectedActivityCode: Code[6])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindSet();
        REPEAT
            VATEntry.TestField("Activity Code", ExpectedActivityCode);
        UNTIL VATEntry.Next() = 0;
    end;

    local procedure VerifyActivityCodeOnPostedPurchaseInvoice(DocumentNo: Code[20]; ExpectedActivityCode: Code[6])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Activity Code", ExpectedActivityCode);
    end;

    local procedure VerifyActivityCodeOnPostedSalesInvoice(DocumentNo: Code[20]; ExpectedActivityCode: Code[6])
    var
        PurchInvHeader: Record "Sales Invoice Header";
    begin
        PurchInvHeader.Get(DocumentNo);
        PurchInvHeader.TestField("Activity Code", ExpectedActivityCode);
    end;
}

