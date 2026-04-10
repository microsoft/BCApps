codeunit 147123 "ERM VAT Posting Preview"
{
    // // [FEATURE] [Posting Preview]
    // 
    // test cases for RegF 24891 VAT Allocation
    // 
    // ----------------------------------------------------------------------------------
    // Test Function Name                                                          TFS ID
    // ----------------------------------------------------------------------------------
    // PurchInvNotCreatedAfterDeletionPreviewedOrder                               359624
    // PurchCrMemoNotCreatedAfterDeletionPreviewedCrMemo                           359624
    // SalesInvNotCreatedAfterDeletionPreviewedOrder                               359624
    // SalesCrMemoNotCreatedAfterDeletionPreviewedCrMemo                           359624

    TestPermissions = NonRestrictive;
    Subtype = Test;

    trigger OnRun()
    begin
    end;

    var
        PurchPostingPreviewErr: Label 'Purchase %1 preview created Ledger Entries, though it should not.', Comment = '%1=Document Type';
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryERM: Codeunit "Library - ERM";
        SalesPostingPreviewErr: Label 'Sales %1 preview create Ledger Entries, though it should not.', Comment = '%1=Document Type';
        MissingSalesEntriesErr: Label 'Missing entries in Sales %1 Preview. Only %2 entries shown.', Comment = '%1=Document Type;%2=number of entries';
        LibraryRandom: Codeunit "Library - Random";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        IsInitialized: Boolean;
        PreviewDocExistsErr: Label 'Preview %1 exists.', Comment = '%1=Purchase Invoice Header table caption';
        PreviewEntryErr: Label 'G/L Entry in preview mode does not exist for G/L Account = %1', Comment = '%1 = G/L Account Code';

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewPurchOrder()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseInvoiceWithGLAcc(PurchHeader, PurchLine, '', '');

        GLEntry.FindLast();
        LastEntryNo := GLEntry."Entry No.";

        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchHeader);

        GLEntry.FindLast();
        Assert.IsTrue(
          GLEntry."Entry No." = LastEntryNo, StrSubstNo(PurchPostingPreviewErr, PurchHeader."Document Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewPurchCrMemo()
    var
        PurchHeader: Record "Purchase Header";
        PurchLine: Record "Purchase Line";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseCrMemoWithGLAcc(PurchHeader, PurchLine, '', '');

        GLEntry.FindLast();
        LastEntryNo := GLEntry."Entry No.";

        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchHeader);

        GLEntry.FindLast();
        Assert.IsTrue(
          GLEntry."Entry No." = LastEntryNo, StrSubstNo(PurchPostingPreviewErr, PurchHeader."Document Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewSalesOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
    begin
        Initialize();

        LibrarySales.CreateSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '');

        GLEntry.FindLast();
        LastEntryNo := GLEntry."Entry No.";

        asserterror LibrarySales.PreviewSalesDocument(SalesHeader);

        GLEntry.FindLast();
        Assert.IsTrue(
          GLEntry."Entry No." = LastEntryNo, StrSubstNo(SalesPostingPreviewErr, SalesHeader."Document Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewSalesCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
    begin
        Initialize();

        LibrarySales.CreateSalesCrMemoWithGLAcc(SalesHeader, SalesLine, '', '');

        GLEntry.FindLast();
        LastEntryNo := GLEntry."Entry No.";

        asserterror LibrarySales.PreviewSalesDocument(SalesHeader);

        GLEntry.FindLast();
        Assert.IsTrue(
          GLEntry."Entry No." = LastEntryNo, StrSubstNo(SalesPostingPreviewErr, SalesHeader."Document Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewSalesRobot()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GLEntry: Record "G/L Entry";
        GLPostingPreview: TestPage "G/L Posting Preview";
        LastEntryNo: Integer;
        MaxIterations: Integer;
        Iteration: Integer;
        GLCount: Integer;
    begin
        Initialize();

        MaxIterations := 1000;
        Iteration := 0;

        LibrarySales.CreateSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '');
        Commit();
        repeat
            GLEntry.FindLast();
            LastEntryNo := GLEntry."Entry No.";

            GLPostingPreview.Trap();

            asserterror LibrarySales.PreviewSalesDocument(SalesHeader);

            GLPostingPreview.FILTER.SetFilter("Table ID", StrSubstNo('%1', DATABASE::"G/L Entry"));
            GLCount := 0;
            if GLPostingPreview.First() then
                GLCount := GLPostingPreview."No. of Records".AsInteger();

            if Iteration = 0 then
                Assert.IsTrue(
                  GLCount = 4, StrSubstNo(MissingSalesEntriesErr, SalesHeader."Document Type", GLCount));

            GLEntry.FindLast();
            Assert.IsTrue(
              GLEntry."Entry No." = LastEntryNo, StrSubstNo(SalesPostingPreviewErr, SalesHeader."Document Type"));

            GLPostingPreview.Close();
            Iteration += 1;
        until Iteration = MaxIterations;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewPrepDiffCheck()
    var
        Currency: Record Currency;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        GenJnlLine: Record "Gen. Journal Line";
        BankAccount: Record "Bank Account";
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
        InvoiceDate: Date;
        DocNo: Code[20];
    begin
        InvoiceDate := WorkDate() + 10;

        LibraryERM.CreateCurrency(Currency);
        Currency."Realized Gains Acc." := LibraryERM.CreateGLAccountNo();
        Currency."Realized Losses Acc." := LibraryERM.CreateGLAccountNo();
        Currency.Modify();
        LibraryERM.CreateExchangeRate(
          Currency.Code, WorkDate(), 1, 10 + LibraryRandom.RandDec(1000, 2));
        LibraryERM.CreateExchangeRate(
          Currency.Code, InvoiceDate, 1, 10 + LibraryRandom.RandDec(1000, 2));

        LibraryERM.CreateBankAccount(BankAccount);

        LibrarySales.CreateFCYSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '', InvoiceDate, Currency.Code);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryERM.CreateCustomerPrepmtGenJnlLine(GenJnlLine, SalesHeader."Bill-to Customer No.", WorkDate(), SalesHeader."No.", -500);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
        DocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        GLEntry.FindLast();
        LastEntryNo := GLEntry."Entry No.";

        asserterror ApplySalesPaymentToInvoicePreviewMode(GenJnlLine."Document No.", DocNo);

        GLEntry.FindLast();
        Assert.IsTrue(GLEntry."Entry No." = LastEntryNo, StrSubstNo(SalesPostingPreviewErr, SalesHeader."Document Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewFAReleaseAct()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FADocHeader: Record "FA Document Header";
    begin
        // [FEATURE] [Fixed Asset] [FA Release]
        // [SCENARIO 363460] Preview posting generated G/L Entry for FA Release Act
        Initialize();
        // [GIVEN] FA Release Act
        LibraryPurchase.CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchaseLine, '', '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryFixedAsset.CreateFAReleaseDoc(FADocHeader, PurchaseLine."No.", WorkDate());

        // [WHEN] Run Posting Preview for FA Release Act
        asserterror LibraryFixedAsset.PreviewFADocument(FADocHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewFAWriteoffAct()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FADocHeader: Record "FA Document Header";
    begin
        // [FEATURE] [Fixed Asset] [FA Writeoff]
        // [SCENARIO 363460] Preview posting generated G/L Entry for FA Writeoff Act
        Initialize();
        // [GIVEN] Posted FA Release Act
        LibraryPurchase.CreatePurchaseInvoiceWithFixedAsset(PurchaseHeader, PurchaseLine, '', '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryFixedAsset.CreateFAReleaseDoc(FADocHeader, PurchaseLine."No.", WorkDate());
        LibraryFixedAsset.PostFADocument(FADocHeader);
        // [GIVEN] FA Writeoff Act
        LibraryFixedAsset.CreateFAWriteOffDoc(FADocHeader, PurchaseLine."No.", WorkDate());

        // [WHEN] Run Posting Preview for FA Writeoff Act
        asserterror LibraryFixedAsset.PreviewFADocument(FADocHeader);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewPurchPrepmtDiff()
    var
        PurchHeader: Record "Purchase Header";
        GenJnlLine: Record "Gen. Journal Line";
        GLPostingPreview: TestPage "G/L Posting Preview";
        CurrencyCode: Code[10];
        GLAccNo: Code[20];
        InvNo: Code[20];
        InvPostingDate: Date;
        TotalAmount: Decimal;
    begin
        // [FEATURE] [Prepayment] [FCY] [Purchases] [Prepayment Difference]
        // [SCENARIO 363479] Preview Page should show application and currency conversion entries when FCY purchase documents applied

        Initialize();
        UpdateCancelPrepmtAdjmtInTAOnGLSetup(true);
        // [GIVEN] Posted Purchase Invoice in FCY and G/L Account = "X"
        // [GIVEN] Prepayment in FCY with different currency factor
        CurrencyCode := SetupCurrExchRates(InvPostingDate);
        TotalAmount := CreateReleasePurchInvWithCurrency(PurchHeader, GLAccNo, InvPostingDate, CurrencyCode);
        PostPurchasePrepaymentWithCurrency(GenJnlLine, WorkDate(), PurchHeader."Pay-to Vendor No.", CurrencyCode, TotalAmount);
        InvNo := LibraryPurchase.PostPurchaseDocument(PurchHeader, true, true);

        GLPostingPreview.Trap();
        // [WHEN] Run Posting Preview for Application between Invoice and Prepayment
        asserterror ApplyPurchInvToPrepaymentPreviewMode(InvNo, GenJnlLine."Document No.");

        // [THEN] Preview G/L Entry generated for Prepayment Difference with "G/L Account No." = "X"
        VerifyGLEntryWithAccountExists(GLPostingPreview, GLAccNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostingPreviewAdvanceStatement()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Vendor: Record Vendor;
        VendorEmployee: Record Vendor;
        GLEntry: Record "G/L Entry";
        LastEntryNo: Integer;
    begin
        // [FEATURE] [Prepayment] [Advance Statement]
        // [SCENARIO]

        Initialize();

        // [GIVEN] Posted Purchase Invoice with item
        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, Vendor."No.");
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Advance Statement for Resp. Employee for this purchase
        LibraryPurchase.CreateVendor(VendorEmployee);
        VendorEmployee.Validate("Vendor Type", VendorEmployee."Vendor Type"::"Resp. Employee");
        VendorEmployee.Modify(true);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorEmployee."No.");
        PurchaseHeader.Validate("Empl. Purchase", true);
        PurchaseHeader.Modify(true);
        CreatePurchaseLineWithEmplPurchase(PurchaseHeader, PurchaseLine, Vendor);
        GLEntry.FindLast();
        LastEntryNo := GLEntry."Entry No.";

        // [WHEN] Run Posting Preview for Advance Statement
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);

        // [THEN] Preview G/L Entry generated for Advance STatement
        GLEntry.FindLast();
        Assert.IsTrue(GLEntry."Entry No." = LastEntryNo,
          StrSubstNo(PurchPostingPreviewErr, PurchaseHeader."Document Type"));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchInvNotCreatedAfterDeletionPreviewedOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseInvoiceWithGLAcc(PurchaseHeader, PurchaseLine, '', '');
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);
        Assert.IsFalse(PurchInvHeader.Get(PurchaseHeader."Posting No."), StrSubstNo(PreviewDocExistsErr, PurchInvHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchCrMemoNotCreatedAfterDeletionPreviewedCrMemo()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        Initialize();

        LibraryPurchase.CreatePurchaseCrMemoWithGLAcc(PurchaseHeader, PurchaseLine, '', '');
        asserterror LibraryPurchase.PreviewPostPurchaseDocument(PurchaseHeader);
        Assert.IsFalse(PurchCrMemoHdr.Get(PurchaseHeader."Posting No."), StrSubstNo(PreviewDocExistsErr, PurchCrMemoHdr.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesInvNotCreatedAfterDeletionPreviewedOrder()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesInvHeader: Record "Sales Invoice Header";
    begin
        Initialize();

        LibrarySales.CreateSalesInvoiceWithGLAcc(SalesHeader, SalesLine, '', '');
        asserterror LibrarySales.PreviewSalesDocument(SalesHeader);
        Assert.IsFalse(SalesInvHeader.Get(SalesHeader."Posting No."), StrSubstNo(PreviewDocExistsErr, SalesInvHeader.TableCaption()));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoNotCreatedAfterDeletionPreviewedCrMemo()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        Initialize();

        LibrarySales.CreateSalesCrMemoWithGLAcc(SalesHeader, SalesLine, '', '');
        asserterror LibrarySales.PreviewSalesDocument(SalesHeader);
        Assert.IsFalse(SalesCrMemoHeader.Get(SalesHeader."Posting No."), StrSubstNo(PreviewDocExistsErr, SalesCrMemoHeader.TableCaption()));
    end;

    local procedure Initialize()
    var
        InvtSetup: Record "Inventory Setup";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;

        InvtSetup.Get();
        if InvtSetup."Prevent Negative Inventory" then
            InvtSetup."Prevent Negative Inventory" := false;
        if not InvtSetup."Automatic Cost Posting" then
            InvtSetup."Automatic Cost Posting" := true;
        InvtSetup.Modify();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");

        IsInitialized := true;
    end;

    local procedure SetupCurrExchRates(var InvPostingDate: Date): Code[10]
    var
        Currency: Record Currency;
        InvCurrExchRate: Decimal;
        PrepmtCurrExchRate: Decimal;
        PrepmtPostingDate: Date;
    begin
        LibraryERM.CreateCurrency(Currency);

        Currency."Sales PD Gains Acc. (TA)" := LibraryERM.CreateGLAccountNo();
        Currency."PD Bal. Gain/Loss Acc. (TA)" := LibraryERM.CreateGLAccountNo();
        Currency.Modify();

        PrepmtPostingDate := WorkDate();
        PrepmtCurrExchRate := LibraryRandom.RandDec(100, 2);
        LibraryERM.CreateExchangeRate(
          Currency.Code, PrepmtPostingDate, PrepmtCurrExchRate, PrepmtCurrExchRate);
        InvPostingDate := CalcDate('<1M>', PrepmtPostingDate);
        InvCurrExchRate := PrepmtCurrExchRate * 3;
        LibraryERM.CreateExchangeRate(
          Currency.Code, InvPostingDate, InvCurrExchRate, InvCurrExchRate);
        exit(Currency.Code);
    end;

    local procedure CreateReleasePurchInvWithCurrency(var PurchaseHeader: Record "Purchase Header"; var GLAccountNo: Code[20]; PostingDate: Date; CurrencyCode: Code[10]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreateFCYPurchInvoiceWithGLAcc(PurchaseHeader, PurchaseLine, '', '', PostingDate, CurrencyCode);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        GLAccountNo := PurchaseLine."No.";
        exit(PurchaseLine."Amount Including VAT");
    end;

    local procedure CreatePurchaseLineWithEmplPurchase(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; Vendor: Record Vendor)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        RecRef: RecordRef;
    begin
        Clear(PurchaseLine);
        PurchaseLine.Validate("Document Type", PurchaseHeader."Document Type"::Invoice);
        PurchaseLine.Validate("Document No.", PurchaseHeader."No.");
        RecRef.GetTable(PurchaseLine);
        PurchaseLine.Validate("Line No.", LibraryUtility.GetNewLineNo(RecRef, PurchaseLine.FieldNo("Line No.")));
        PurchaseLine.Insert(true);
        PurchaseLine.Validate(Type, PurchaseLine.Type::"Empl. Purchase");
        PurchaseLine.Validate("Empl. Purchase Vendor No.", Vendor."No.");
        VendorLedgerEntry.SetRange("Vendor No.", Vendor."No.");
        VendorLedgerEntry.FindLast();
        PurchaseLine.Validate("Empl. Purchase Entry No.", VendorLedgerEntry."Entry No.");
        PurchaseLine.Modify(true);
    end;

    local procedure PostPurchasePrepaymentWithCurrency(var GenJnlLine: Record "Gen. Journal Line"; PostingDate: Date; VendorNo: Code[20]; CurrencyCode: Code[10]; EntryAmount: Decimal)
    begin
        LibraryERM.CreateVendorPrepmtGenJnlLineFCY(
          GenJnlLine, VendorNo, PostingDate, EntryAmount, CurrencyCode);
        LibraryERM.PostGeneralJnlLine(GenJnlLine);
    end;

    local procedure ApplyPurchInvToPrepaymentPreviewMode(InvNo: Code[20]; PrepmtNo: Code[20])
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.PreviewApplyVendorLedgerEntry(
          VendLedgEntry."Document Type"::Invoice, InvNo,
          VendLedgEntry."Document Type"::Payment, PrepmtNo);
    end;

    local procedure ApplySalesPaymentToInvoicePreviewMode(PaymentDocNo: Code[20]; InvoiceDocNo: Code[20])
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
    begin
        LibraryERM.PreviewApplyCustomerLedgerEntry(
          CustLedgEntry."Document Type"::Payment, PaymentDocNo,
          CustLedgEntry."Document Type"::Invoice, InvoiceDocNo);
    end;

    local procedure UpdateCancelPrepmtAdjmtInTAOnGLSetup(NewCancelPrepmtAdjmtInTA: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup.Validate("Cancel Prepmt. Adjmt. in TA", NewCancelPrepmtAdjmtInTA);
        GLSetup.Modify(true);
    end;

    local procedure VerifyGLEntryWithAccountExists(GLPostingPreview: TestPage "G/L Posting Preview"; GLAccountNo: Code[20])
    var
        GLEntriesPreview: TestPage "G/L Entries Preview";
    begin
        GLEntriesPreview.Trap();
        GLPostingPreview.FILTER.SetFilter("Table ID", Format(DATABASE::"G/L Entry"));
        GLPostingPreview.Show.Invoke();
        GLEntriesPreview.FILTER.SetFilter("G/L Account No.", GLAccountNo);
        Assert.IsTrue(GLEntriesPreview.First(), StrSubstNo(PreviewEntryErr, GLAccountNo));
        GLEntriesPreview.Close();
        GLPostingPreview.Close();
    end;
}

