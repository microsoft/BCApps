codeunit 141007 "ERM GST APAC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [GST]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryAPACLocalization: Codeunit "Library - APAC Localization";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryRandom: Codeunit "Library - Random";
        UnexpectedErr: Label 'Value must be match.';
        WrongValueInGSTEntryErr: Label 'Wrong %2 in %1.';
        LineCountTxt: Label 'line count';
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUTUtility: Codeunit "Library UT Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        FADescriptionErr: Label '%1 must be %2 in %3.', Comment = '%1= Field Name, %2= Expected Value, %3= Table Name';

    [Test]
    [Scope('OnPrem')]
    procedure GSTSaleReportForOrderWithDiffVATProdPostingGrp()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GSTSalesEntry: Record "GST Sales Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] GST Sales Report for Sales Order with different VAT Prod. Posting Group.
        Initialize();

        // [GIVEN] Create Sales Credit Memo with multiple line and differnt VAT Prod. Posting Group.
        // [GIVEN] Unrealized VAT - False, GST Report - True.
        UpdateGeneralLedgerSetup(false, true);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Order, SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLineWithDiffVATProdPostingGrp(SalesLine2, SalesHeader, SalesHeader."VAT Bus. Posting Group");
        // [WHEN] Post document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] Verify GST Sales Entry amounts by document line
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.SetRange("Document Line No.", SalesLine."Line No.");
        GSTSalesEntry.FindFirst();
        VerifyGSTEntry(
          GSTSalesEntry."GST Base", -SalesLine.Amount, GSTSalesEntry.Amount, -GetVATAmount(SalesLine));
        // [THEN] Verify GST Sales Entry amounts by document line
        GSTSalesEntry.SetRange("Document Line No.", SalesLine2."Line No.");
        GSTSalesEntry.FindFirst();
        VerifyGSTEntry(
          GSTSalesEntry."GST Base", -SalesLine2.Amount, GSTSalesEntry.Amount, -GetVATAmount(SalesLine2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesReportForCrMemoWithDiffVATProdPostingGrp()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        GSTSalesEntry: Record "GST Sales Entry";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Sales]
        // [SCENARIO] GST Sales Report for Sales Credit Memo with different VAT Prod. Posting Group.
        Initialize();

        // [GIVEN] Create Sales Credit Memo with multiple line and differnt VAT Prod. Posting Group.
        // [GIVEN] Unrealized VAT - False, GST Report - True.
        UpdateGeneralLedgerSetup(false, true);
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::"Credit Memo", SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLineWithDiffVATProdPostingGrp(SalesLine2, SalesHeader, SalesHeader."VAT Bus. Posting Group");
        // [WHEN] Post document
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);
        // [THEN] Verify GST Sales Entry amounts by document line
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        GSTSalesEntry.SetRange("Document Line No.", SalesLine."Line No.");
        GSTSalesEntry.FindFirst();
        VerifyGSTEntry(
          GSTSalesEntry."GST Base", SalesLine.Amount, GSTSalesEntry.Amount, GetVATAmount(SalesLine));
        // [THEN] Verify GST Sales Entry amounts by document line
        GSTSalesEntry.SetRange("Document Line No.", SalesLine2."Line No.");
        GSTSalesEntry.FindFirst();
        VerifyGSTEntry(
          GSTSalesEntry."GST Base", SalesLine2.Amount, GSTSalesEntry.Amount, GetVATAmount(SalesLine2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTPurchaseEntryAfterPostGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GSTPurchaseEntry: Record "GST Purchase Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        OldRealizedWHTType: Integer;
    begin
        // [SCENARIO] GST Purchase Payment Entry with FCY.
        Initialize();

        // [GIVEN] Create Purchase payment Gen. Journal with FCY.
        UpdateGeneralLedgerSetup(false, true);  // Unrealized VAT - False, GST Report - True.
        OldRealizedWHTType := CreateAndUpdateWHTPostingSetup(WHTPostingSetup."Realized WHT Type"::" ");
        CreateGeneralJournalLineWithFCY(
          GenJournalLine, LibraryRandom.RandDecInRange(10, 100, 2), GenJournalLine."Gen. Posting Type"::Purchase);  // Using Random for Amount.

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GST Purchase Entry.
        GSTPurchaseEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GSTPurchaseEntry.FindFirst();
        VerifyGSTEntry(
          GSTPurchaseEntry."GST Base", GenJournalLine."Amount (LCY)" - GenJournalLine."VAT Amount (LCY)",
          GSTPurchaseEntry.Amount, GenJournalLine."VAT Amount (LCY)");

        // Tear Down.
        CreateAndUpdateWHTPostingSetup(OldRealizedWHTType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntryAfterPostGeneralJournal()
    var
        GenJournalLine: Record "Gen. Journal Line";
        GSTSalesEntry: Record "GST Sales Entry";
        WHTPostingSetup: Record "WHT Posting Setup";
        OldRealizedWHTType: Integer;
    begin
        // [SCENARIO] GST Sales Payment Entry with FCY.
        Initialize();

        // [GIVEN] Create Sales payment Gen. Journal with FCY.
        UpdateGeneralLedgerSetup(false, true);  // Unrealized VAT - False, GST Report - True.
        OldRealizedWHTType := CreateAndUpdateWHTPostingSetup(WHTPostingSetup."Realized WHT Type"::" ");
        CreateGeneralJournalLineWithFCY(
          GenJournalLine, -LibraryRandom.RandDecInRange(10, 100, 2), GenJournalLine."Gen. Posting Type"::Sale);  // Using Random for Amount.

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] Verify GST Sales Entry.
        GSTSalesEntry.SetRange("Document No.", GenJournalLine."Document No.");
        GSTSalesEntry.FindFirst();
        VerifyGSTEntry(
          GSTSalesEntry."GST Base", GenJournalLine."Amount (LCY)" - GenJournalLine."VAT Amount (LCY)",
          GSTSalesEntry.Amount, GenJournalLine."VAT Amount (LCY)");

        // Tear Down.
        CreateAndUpdateWHTPostingSetup(OldRealizedWHTType);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoApplyInvoiceWithUnrealizedGST()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        PostedCrMemoNo: Code[20];
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [Sales]
        // [SCENARIO] Unrealized GST GL/VAT Entry after post sales credit memo applied to invoice
        Initialize();

        // [GIVEN] Unrealized GST posting setup with "GST %" = 20
        // [GIVEN] Posted sales invoice with Amount = 10000
        PostedInvNo := CreatePostGLSalesInvoiceWithUnrealizedVAT(VATPostingSetup, CustomerNo, VATBase, VATAmount);
        // [GIVEN] Sales credit memo applied to posted invoice with Amount = 10000
        CreateSalesCreditMemoForPostedInvoice(SalesHeader, CustomerNo, PostedInvNo);
        UpdateSalesHeaderAppliesTo(SalesHeader, PostedInvNo);

        // [WHEN] Post the credit memo
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Unrealized GST GL Entry for posted credit memo has Amount = 2000
        FindGLEntry(GLEntry, GLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, VATPostingSetup."Sales VAT Unreal. Account");
        GLEntry.TestField(Amount, VATAmount);

        // [THEN] Unrealized GST (VAT) Entry for posted invoice has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = -10000, Unrealized Amount = -2000
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        FindVATEntry(VATEntry, VATEntry.Type::Sale, CustomerNo, VATEntry."Document Type"::Invoice, PostedInvNo);
        VerifyVATEntryAmounts(VATEntry, 0, 0, -VATBase, -VATAmount, 0, 0);

        // [THEN] Unrealized GST (VAT) Entry for posted credit memo has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = 10000, Unrealized Amount = 2000
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        FindVATEntry(VATEntry, VATEntry.Type::Sale, CustomerNo, VATEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        VerifyVATEntryAmounts(VATEntry, 0, 0, VATBase, VATAmount, 0, 0);

        // Tear Down.
        ResetUnrealizedVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesCrMemoApplyInvoiceAfterPartialRcptWithUnrealizedGST()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        SalesHeader: Record "Sales Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        PostedCrMemoNo: Code[20];
        PostedInvNo: Code[20];
        CustomerNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
        CashReceiptVATBase: Decimal;
        CashReceiptVATAmount: Decimal;
        CrMemoVATAmount: Decimal;
        CrMemoVATBase: Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [Sales]
        // [SCENARIO 218599] Unrealized GST GL/VAT Entry after post partial sales credit memo applied to invoice after partial cash receipt
        Initialize();

        // [GIVEN] Unrealized GST posting setup with "GST %" = 20
        // [GIVEN] Posted sales invoice with Amount = 10000 (VAT Base = 10000, VAT Amont = 2000)
        PostedInvNo := CreatePostGLSalesInvoiceWithUnrealizedVAT(VATPostingSetup, CustomerNo, VATBase, VATAmount);
        // [GIVEN] Posted cash receipt applied to the posted invoice with Amount = 1200 (VAT Base = 1000, VAT Amont = 200)
        CashReceiptVATBase := Round(VATBase / 5);
        CashReceiptVATAmount := Round(CashReceiptVATBase * VATPostingSetup."VAT %" / 100);
        CreatePostPmtAppliedToInvoice(
          GenJournalLine."Account Type"::Customer, CustomerNo, PostedInvNo, -(CashReceiptVATBase + CashReceiptVATAmount));
        // [GIVEN] Sales credit memo applied to posted invoice with Amount = 6000 (VAT Base = 6000, VAT Amont = 1200)
        CreateSalesCreditMemoForPostedInvoice(SalesHeader, CustomerNo, PostedInvNo);
        UpdateSalesHeaderAppliesTo(SalesHeader, PostedInvNo);
        CrMemoVATBase := Round(VATBase / 3);
        CrMemoVATAmount := Round(CrMemoVATBase * VATPostingSetup."VAT %" / 100);
        UpdateSalesDocUnitPrice(SalesHeader, CrMemoVATBase);

        // [WHEN] Post the credit memo
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] Unrealized GST GL Entry for posted credit memo has Amount = 1200
        FindGLEntry(GLEntry, GLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, VATPostingSetup."Sales VAT Unreal. Account");
        GLEntry.TestField(Amount, CrMemoVATAmount);

        // [THEN] Unrealized GST (VAT) Entry for posted invoice has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = -10000, Unrealized Amount = -2000
        // [THEN] Remaining Unrealized Base = -3000, Remaining Unrealized Amount = -600
        FindVATEntry(VATEntry, VATEntry.Type::Sale, CustomerNo, VATEntry."Document Type"::Invoice, PostedInvNo);
        VerifyVATEntryAmounts(
          VATEntry, 0, 0, -VATBase, -VATAmount,
          -(VATBase - CashReceiptVATBase - CrMemoVATBase),
          -(VATAmount - CashReceiptVATAmount - CrMemoVATAmount));

        // [THEN] Unrealized GST (VAT) Entry (1/3) for posted credit memo has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = 6000, Unrealized Amount = 1200
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        FindVATEntry(VATEntry, VATEntry.Type::Sale, CustomerNo, VATEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        VerifyVATEntryAmounts(VATEntry, 0, 0, CrMemoVATBase, CrMemoVATAmount, 0, 0);

        // [THEN] Unrealized GST (VAT) Entry (2/3) for posted credit memo has:
        // [THEN] Base = -6000, Amount = -1200
        // [THEN] Unrealized Base = 0, Unrealized Amount = 0
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        VATEntry.Next();
        VerifyVATEntryAmounts(VATEntry, -CrMemoVATBase, -CrMemoVATAmount, 0, 0, 0, 0);

        // [THEN] Unrealized GST (VAT) Entry (3/3) for posted credit memo has:
        // [THEN] Base = 6000, Amount = 1200
        // [THEN] Unrealized Base = 0, Unrealized Amount = 0
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        VATEntry.Next();
        VerifyVATEntryAmounts(VATEntry, CrMemoVATBase, CrMemoVATAmount, 0, 0, 0, 0);

        // Tear Down.
        ResetUnrealizedVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesInvoiceWithDiffDims()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesLine2: Record "Sales Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify GST Entries after posting Sales Invoice with two lines having different dimension values.
        Initialize();

        // [GIVEN] Sales Invoice with two lines, different dimension sets
        UpdateGeneralLedgerSetup(false, true);  // Unrealized VAT - False, GST Report - True.
        CreateSalesDocument(SalesLine, SalesHeader."Document Type"::Invoice, SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
        CreateSalesLineWithDiffDims(SalesLine2, SalesHeader);

        // [WHEN] Posting Sales Invoice
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);  // Using true for ship and invoice.

        // [THEN] 2 GST Sales Entries created, total GST Base equals to total Invoice Amount
        VerifyGSTSalesEntries(DocumentNo, 2, -(SalesLine.Amount + SalesLine2.Amount));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTPurchInvoiceWithDiffDims()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // [SCENARIO] Verify GST Entries after posting Purchase Invoice with two lines having different dimension values.
        Initialize();

        // [GIVEN] Purchase Invoice with two lines, different dimension sets
        UpdateGeneralLedgerSetup(false, true);  // Unrealized VAT - False, GST Report - True.
        CreatePurchaseDocument(
          PurchaseLine, PurchaseHeader."Document Type"::Invoice, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo());
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        CreatePurchLineWithDiffDims(PurchaseLine2, PurchaseHeader);

        // [WHEN] Posting Purchase Invoice
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // Using true for ship and invoice.

        // [THEN] 2 GST Purchase Entries created, total GST Base equals to total Invoice Amount
        VerifyGSTPurchEntries(DocumentNo, 2, PurchaseLine.Amount + PurchaseLine2.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTSalesEntrySalesOrderWithPrepmt()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        EnableGST: Boolean;
        AdjmtMandatory: Boolean;
        FullGSTOnPrepmt: Boolean;
        GSTReport: Boolean;
        EnableWHT: Boolean;
        InvoiceRounding: Boolean;
    begin
        // [FEATURE] [Prepayment] [Sales]
        // [SCENARIO] GST Base is correct after Prepayment Invoice and Order posted
        Initialize();

        UpdateGSTGLSetup(
          true, true, true, true, false, false,
          EnableGST, AdjmtMandatory, FullGSTOnPrepmt, GSTReport, EnableWHT, InvoiceRounding);
        // [GIVEN] Sales Order, "Prepayment %" = 100, "Compress Prepayment" = FALSE
        CreateSalesOrderWithTwoLines(SalesHeader);
        FindGLSalesLine(SalesLine, SalesHeader);
        // [GIVEN] Posted Prepayment Invoice
        LibrarySales.PostSalesPrepaymentInvoice(SalesHeader);

        // [WHEN] Post Sales Order
        DocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] "GST Sales Entry"."VAT Base" = "Sales Line".Amount per each sales line
        VerifyGSTVATEntries(DocumentNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryBASAdjWhenGenJnlWithBasAdj()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [BAS Adjustment]
        // [SCENARIO 380740] GST BAS Adjustment set to TRUE when post Gen Journal Line with BAS Adjustment
        Initialize();

        // [GIVEN] General Jnl Line with "BAS Adjustment" = TRUE
        CreateGenJournalLineWithoutBASCalcSheet(GenJournalLine, true);

        // [WHEN] Post General Jnl Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GST Entry "BAS Adjustment" set to TRUE
        VerifyGSTBASAdj(GenJournalLine."Document No.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryBASAdjWhenGenJnlWithoutBasAdj()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [BAS Adjustment]
        // [SCENARIO 380740] GST BAS Adjustment set to FALSE when post Gen Journal Line without BAS Adjustment
        Initialize();

        // [GIVEN] General Jnl Line with "BAS Adjustment" = FALSE
        CreateGenJournalLineWithoutBASCalcSheet(GenJournalLine, false);

        // [WHEN] Post General Jnl Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GST Entry "BAS Adjustment" set to FALSE
        VerifyGSTBASAdj(GenJournalLine."Document No.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryBASAdjWhenBASCalcSheetUpdated()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [BAS Adjustment]
        // [SCENARIO 380740] GST BAS Adjustment set to FALSE when BAS Calc. Sheet Updated
        Initialize();

        // [GIVEN] General Jnl Line with Updated BAS Calculation Sheet
        CreateGenJournalLineWithUpdateBASCalcSheet(GenJournalLine);

        // [WHEN] Post General Jnl Line
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] GST Entry "BAS Adjustment" set to FALSE
        VerifyGSTBASAdj(GenJournalLine."Document No.", false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BASAdjustmentIsFalseForSalesVATGLEntry()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        DummyGLEntry: Record "G/L Entry";
        CustomerNo: Code[20];
        PostedCrMemoNo: Code[20];
        PostedInvoiceNo: Code[20];
        SalesVATAccountNo: Code[20];
    begin
        // [FEATURE] [BAS Adjustment] [Sales]
        // [SCENARIO 381036] Sales VAT Account GLEntry."BAS Adjustment" = FALSE after reverse Credit Memo
        Initialize();
        CustomerNo := LibrarySales.CreateCustomerNo();

        // [GIVEN] Posted Sales Invoice "SI" with GLAccount "GL"
        PostedInvoiceNo := CreatePostGLSalesInvoice(CustomerNo, LibraryERM.CreateGLAccountWithSalesSetup());
        // [GIVEN] Sales Credit Memo. Get posted Invoice lines to reverse.
        CreateSalesCreditMemoForPostedInvoice(SalesHeader, CustomerNo, PostedInvoiceNo);
        FindGLSalesLine(SalesLine, SalesHeader);
        SalesVATAccountNo := GetSalesVATAccountNo(SalesLine);
        // [GIVEN] Update Sales Credit Memo "Adjustment Applies-to" = "SI". SalesHeader."BAS Adjustment" is automatically set to TRUE.
        UpdateSalesHeaderAdjAppliesTo(SalesHeader, PostedInvoiceNo);

        // [WHEN] Post Sales Credit Memo
        PostedCrMemoNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] There are 3 posted GLEntries related to the Credit Memo:
        DummyGLEntry.SetRange("Document Type", DummyGLEntry."Document Type"::"Credit Memo");
        DummyGLEntry.SetRange("Document No.", PostedCrMemoNo);
        Assert.RecordCount(DummyGLEntry, 3);
        // [THEN] "G/L Account No." = 5610 (<Sales VAT Account>), "BAS Adjustment" = FALSE
        VerifyGLEntryBASAdjustment(
          DummyGLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, SalesVATAccountNo, false);
        // [THEN] "G/L Account No." = 2310 (<Receivables Account>), "BAS Adjustment" = TRUE
        VerifyGLEntryBASAdjustment(
          DummyGLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, GetReceivablesAccountNo(CustomerNo), true);
        // [THEN] "G/L Account No." = "GL", "BAS Adjustment" = TRUE
        VerifyGLEntryBASAdjustment(
          DummyGLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, SalesLine."No.", true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoApplyInvoiceWithUnrealizedGST()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        PostedCrMemoNo: Code[20];
        PostedInvNo: Code[20];
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [Purchase]
        // [SCENARIO 218599] Unrealized GST GL/VAT Entry after post purchase credit memo applied to invoice
        Initialize();

        // [GIVEN] Unrealized GST posting setup with "GST %" = 20
        // [GIVEN] Posted purchase invoice with Amount = 10000
        PostedInvNo := CreatePostGLPurchaseInvoiceWithUnrealizedVAT(VATPostingSetup, VendorNo, VATBase, VATAmount);
        // [GIVEN] Puchase credit memo applied to posted invoice with Amount = 10000
        CreatePurchaseCreditMemoForPostedInvoice(PurchaseHeader, VendorNo, PostedInvNo);
        UpdatePurchaseHeaderAppliesTo(PurchaseHeader, PostedInvNo);

        // [WHEN] Post the credit memo
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Unrealized GST GL Entry for posted credit memo has Amount = -2000
        FindGLEntry(GLEntry, GLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, VATPostingSetup."Purch. VAT Unreal. Account");
        GLEntry.TestField(Amount, -VATAmount);

        // [THEN] Unrealized GST (VAT) Entry for posted invoice has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = 10000, Unrealized Amount = 2000
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        FindVATEntry(VATEntry, VATEntry.Type::Purchase, VendorNo, VATEntry."Document Type"::Invoice, PostedInvNo);
        VerifyVATEntryAmounts(VATEntry, 0, 0, VATBase, VATAmount, 0, 0);

        // [THEN] Unrealized GST (VAT) Entry for posted credit memo has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = -10000, Unrealized Amount = -2000
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        FindVATEntry(VATEntry, VATEntry.Type::Purchase, VendorNo, VATEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        VerifyVATEntryAmounts(VATEntry, 0, 0, -VATBase, -VATAmount, 0, 0);

        // Tear Down.
        ResetUnrealizedVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseCrMemoApplyInvoiceAfterPartialPmtWithUnrealizedGST()
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        GenJournalLine: Record "Gen. Journal Line";
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        PostedCrMemoNo: Code[20];
        PostedInvNo: Code[20];
        VendorNo: Code[20];
        VATBase: Decimal;
        VATAmount: Decimal;
        PaymentVATBase: Decimal;
        PaymentVATAmount: Decimal;
        CrMemoVATAmount: Decimal;
        CrMemoVATBase: Decimal;
    begin
        // [FEATURE] [Unrealized VAT] [Purchase]
        // [SCENARIO 218599] Unrealized GST GL/VAT Entry after post partial purchase credit memo applied to invoice after partial payment
        Initialize();

        // [GIVEN] Unrealized GST posting setup with "GST %" = 20
        // [GIVEN] Posted purchase invoice with Amount = 10000 (VAT Base = 10000, VAT Amont = 2000)
        PostedInvNo := CreatePostGLPurchaseInvoiceWithUnrealizedVAT(VATPostingSetup, VendorNo, VATBase, VATAmount);
        // [GIVEN] Posted payment applied to the posted invoice with Amount = 1200 (VAT Base = 1000, VAT Amont = 200)
        PaymentVATBase := Round(VATBase / 5);
        PaymentVATAmount := Round(PaymentVATBase * VATPostingSetup."VAT %" / 100);
        CreatePostPmtAppliedToInvoice(
          GenJournalLine."Account Type"::Vendor, VendorNo, PostedInvNo, PaymentVATBase + PaymentVATAmount);
        // [GIVEN] Purchase credit memo applied to posted invoice with Amount = 6000 (VAT Base = 6000, VAT Amont = 1200)
        CreatePurchaseCreditMemoForPostedInvoice(PurchaseHeader, VendorNo, PostedInvNo);
        UpdatePurchaseHeaderAppliesTo(PurchaseHeader, PostedInvNo);
        CrMemoVATBase := Round(VATBase / 3);
        CrMemoVATAmount := Round(CrMemoVATBase * VATPostingSetup."VAT %" / 100);
        UpdatePurchaseDocDirectUnitPrice(PurchaseHeader, CrMemoVATBase);

        // [WHEN] Post the credit memo
        PostedCrMemoNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Unrealized GST GL Entry for posted credit memo has Amount = -1200
        FindGLEntry(GLEntry, GLEntry."Document Type"::"Credit Memo", PostedCrMemoNo, VATPostingSetup."Purch. VAT Unreal. Account");
        GLEntry.TestField(Amount, -CrMemoVATAmount);

        // [THEN] Unrealized GST (VAT) Entry for posted invoice has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = 10000, Unrealized Amount = 2000
        // [THEN] Remaining Unrealized Base = 3000, Remaining Unrealized Amount = 600
        FindVATEntry(VATEntry, VATEntry.Type::Purchase, VendorNo, VATEntry."Document Type"::Invoice, PostedInvNo);
        VerifyVATEntryAmounts(
          VATEntry, 0, 0, VATBase, VATAmount,
          VATBase - PaymentVATBase - CrMemoVATBase,
          VATAmount - PaymentVATAmount - CrMemoVATAmount);

        // [THEN] Unrealized GST (VAT) Entry (1/3) for posted credit memo has:
        // [THEN] Base = 0, Amount = 0
        // [THEN] Unrealized Base = -6000, Unrealized Amount = -1200
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        FindVATEntry(VATEntry, VATEntry.Type::Purchase, VendorNo, VATEntry."Document Type"::"Credit Memo", PostedCrMemoNo);
        VerifyVATEntryAmounts(VATEntry, 0, 0, -CrMemoVATBase, -CrMemoVATAmount, 0, 0);

        // [THEN] Unrealized GST (VAT) Entry (2/3) for posted credit memo has:
        // [THEN] Base = 6000, Amount = 1200
        // [THEN] Unrealized Base = 0, Unrealized Amount = 0
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        VATEntry.Next();
        VerifyVATEntryAmounts(VATEntry, CrMemoVATBase, CrMemoVATAmount, 0, 0, 0, 0);

        // [THEN] Unrealized GST (VAT) Entry (3/3) for posted credit memo has:
        // [THEN] Base = -6000, Amount = -1200
        // [THEN] Unrealized Base = 0, Unrealized Amount = 0
        // [THEN] Remaining Unrealized Base = 0, Remaining Unrealized Amount = 0
        VATEntry.Next();
        VerifyVATEntryAmounts(VATEntry, -CrMemoVATBase, -CrMemoVATAmount, 0, 0, 0, 0);

        // Tear Down.
        ResetUnrealizedVATPostingSetup(VATPostingSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryWhenPostFASalesInvWithEnabledGSTReport()
    var
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Sales] [Fixed Asset]
        // [SCENARIO 259961] GST Sales Entry is created for posted Sales Invoice with Fixed Asset when "GST Report" is enabled in G/L Setup
        Initialize();

        // [GIVEN] "GST Report" = Yes in G/L Setup
        UpdateGeneralLedgerSetup(false, true);

        // [GIVEN] Sales Invoice with Fixed Asset, having line Amount = 100.0
        CreateSalesInvoiceWithFixedAsset(SalesHeader);
        SalesHeader.CalcFields(Amount);
        ExpectedAmount := -SalesHeader.Amount;

        // [WHEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GST Sales Entry is created for Posted Sales Invoice with "GST Base" = -100.0
        VerifyGSTSalesEntries(PostedDocNo, 1, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryWhenPostFAPurchInvWithEnabledGSTReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // [FEATURE] [Purchase] [Fixed Asset]
        // [SCENARIO 259961] GST Purchase Entry is created for posted Purchase Invoice with Fixed Asset when "GST Report" is enabled in G/L Setup
        Initialize();

        // [GIVEN] "GST Report" = Yes in G/L Setup
        UpdateGeneralLedgerSetup(false, true);

        // [GIVEN] Purchase Invoice with Fixed Asset, having line Amount = 100.0
        CreatePurchInvoiceWithFixedAsset(PurchaseHeader);
        PurchaseHeader.CalcFields(Amount);
        ExpectedAmount := PurchaseHeader.Amount;

        // [WHEN] Post Purchase Invoice
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GST Purchase Entry is created for Posted Purchase Invoice with "GST Base" = 100.0
        VerifyGSTPurchEntries(PostedDocNo, 1, ExpectedAmount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryWhenPostFASalesInvWithDisabledGSTReport()
    var
        SalesHeader: Record "Sales Header";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Sales] [Fixed Asset]
        // [SCENARIO 259961] GST Sales Entry is not created for posted Sales Invoice with Fixed Asset when "GST Report" is disabled in G/L Setup
        Initialize();

        // [GIVEN] "GST Report" = No in G/L Setup
        UpdateGeneralLedgerSetup(false, false);

        // [GIVEN] Sales Invoice with Fixed Asset
        CreateSalesInvoiceWithFixedAsset(SalesHeader);

        // [WHEN] Post Sales Invoice
        PostedDocNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // [THEN] GST Sales Entry is not created for Posted Sales Invoice
        VerifyGSTSalesEntries(PostedDocNo, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure GSTEntryWhenPostFAPurchInvWithDisabledGSTReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PostedDocNo: Code[20];
    begin
        // [FEATURE] [Purchase] [Fixed Asset]
        // [SCENARIO 259961] GST Purchase Entry is not created for posted Purchase Invoice with Fixed Asset when "GST Report" is disabled in G/L Setup
        Initialize();

        // [GIVEN] "GST Report" = No in G/L Setup
        UpdateGeneralLedgerSetup(false, false);

        // [GIVEN] Purchase Invoice with Fixed Asset
        CreatePurchInvoiceWithFixedAsset(PurchaseHeader);

        // [WHEN] Post Purchase Invoice
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] GST Purchase Entry is not created for Posted Purchase Invoice
        VerifyGSTPurchEntries(PostedDocNo, 0, 0);
    end;

    [Test]
    [HandlerFunctions('ApplyCustomerEntriesSelectDocModalPageHandler,YesConfirmHandler')]
    [Scope('OnPrem')]
    procedure SalesCreditMemoAdjustmentAppliesToPermission()
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
        SalesHeaderCreditMemo: Record "Sales Header";
        SalesCreditMemo: TestPage "Sales Credit Memo";
    begin
        // [FEATURE] [Sales] [Credit Memo] [Permissions] [Customer Ledger Entry]
        // [SCENARIO 300754] "Adjustment Applies-to" can be assigned
        Initialize();

        // [GIVEN] Created Cust. Ledger Entry
        CreateCustomerLedgerEntry(CustLedgerEntry);

        // [GIVEN] Created Sales Credit Memo
        CreateSalesCreditMemoForCustomer(SalesHeaderCreditMemo, CustLedgerEntry."Customer No.");

        // [GIVEN] Created Cust. Ledger Entry
        LibraryLowerPermissions.SetSalesDocsCreate();

        // [WHEN] Open Sales Credit Memo page and change the value in 'Adjustment Applies-to' field
        LibraryVariableStorage.Enqueue(CustLedgerEntry."Entry No.");
        SalesCreditMemo.OpenEdit();
        SalesCreditMemo.FILTER.SetFilter("No.", SalesHeaderCreditMemo."No.");
        SalesCreditMemo."Adjustment Applies-to".Lookup();
        SalesCreditMemo.OK().Invoke();

        // [THEN] The value is applied successfully
        SalesHeaderCreditMemo.TestField("Adjustment Applies-to", CustLedgerEntry."Document No.");
    end;

    [Test]
    procedure FixedAssetsLedgerEntryDescriptionIsCorrect()
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
        FALedgerEntry: Record "FA Ledger Entry";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        FADescription: Text[100];
        PostedDocNo: Code[20];
    begin
        // [SCENARIO 592594] Fixed Assets Ledger Entry description is correct.
        Initialize();

        // [GIVEN] Create and store Fixed assets description.
        FADescription := LibraryUTUtility.GetNewCode();

        // [GIVEN] Create a Fixed Asset with Posting Group and add Description.
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        FixedAsset.Validate(Description, FADescription);
        FixedAsset.Modify(true);

        // [GIVEN] Create a Depreciation Book for the Fixed Asset and set FA Posting Group and Acquisition Date.
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Modify(true);

        // [GIVEN] Create Purchase Header with the type Invoice.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());

        // [GIVEN] Create Purchase Line with the type Fixed Asset.
        LibraryPurchase.CreatePurchaseLine(
            PurchaseLine,
            PurchaseHeader,
            PurchaseLine.Type::"Fixed Asset",
            FixedAsset."No.",
            LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);

        // [WHEN] Post Purchase Invoice.
        PostedDocNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [THEN] Find the Fixed Asset Ledger Entry should have the same description as the Fixed Asset.
        FALedgerEntry.SetRange("Document No.", PostedDocNo);
        FALedgerEntry.FindFirst();
        Assert.AreEqual(
            FADescription,
            FALedgerEntry.Description,
            StrSubstNo(
                FADescriptionErr,
                FALedgerEntry.FieldCaption(Description),
                FADescription, FALedgerEntry.TableName()));
    end;

    local procedure Initialize()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Link Doc. Date To Posting Date", true);
        PurchasesPayablesSetup.Modify();
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Link Doc. Date To Posting Date", true);
        SalesReceivablesSetup.Modify();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        IsInitialized := true;
    end;

    local procedure CreateCustomerLedgerEntry(var CustLedgerEntry: Record "Cust. Ledger Entry")
    var
        Customer: Record Customer;
        GLEntry: Record "G/L Entry";
    begin
        CreateGLEntry(GLEntry);
        LibrarySales.CreateCustomer(Customer);

        CustLedgerEntry.Init();
        CustLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(CustLedgerEntry, CustLedgerEntry.FieldNo("Entry No."));
        CustLedgerEntry.Insert();
        CustLedgerEntry."Document Type" := CustLedgerEntry."Document Type"::Invoice;
        CustLedgerEntry."Customer No." := Customer."No.";
        CustLedgerEntry.Open := true;
        CustLedgerEntry.Positive := true;
        CustLedgerEntry."Pmt. Disc. Given (LCY)" := LibraryRandom.RandDec(10, 2);
        CustLedgerEntry."Due Date" := WorkDate();
        CustLedgerEntry."Posting Date" := WorkDate();
        CustLedgerEntry."Transaction No." := GLEntry."Transaction No.";
        CustLedgerEntry."Closed by Entry No." := CustLedgerEntry."Entry No.";
        CustLedgerEntry.Modify();
    end;

    local procedure CreateGLEntry(var GLEntry: Record "G/L Entry")
    begin
        GLEntry.Init();
        GLEntry."Entry No." := LibraryUtility.GetNewRecNo(GLEntry, GLEntry.FieldNo("Entry No."));
        GLEntry."G/L Account No." := LibraryUTUtility.GetNewCode();
        GLEntry."Document No." := LibraryUTUtility.GetNewCode();
        GLEntry."Transaction No." := LibraryUtility.GetLastTransactionNo() + 1;
        GLEntry.Insert();
    end;

    local procedure CreateSalesCreditMemoForCustomer(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20])
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, '', LibraryRandom.RandInt(100));
        SalesHeader.Validate("Sell-to Customer No.", CustomerNo);
        SalesHeader.Modify();
    end;

    local procedure CreateSalesInvoiceWithFixedAsset(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Fixed Asset", CreateFixedAssetNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchInvoiceWithFixedAsset(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Fixed Asset", CreateFixedAssetNo(), LibraryRandom.RandDecInRange(10, 20, 2));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateFixedAssetNo(): Code[20]
    var
        FixedAsset: Record "Fixed Asset";
        FADepreciationBook: Record "FA Depreciation Book";
    begin
        LibraryFixedAsset.CreateFAWithPostingGroup(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", LibraryFixedAsset.GetDefaultDeprBook());
        FADepreciationBook.Validate("FA Posting Group", FixedAsset."FA Posting Group");
        FADepreciationBook.Validate("Acquisition Date", WorkDate());
        FADepreciationBook.Modify(true);
        exit(FixedAsset."No.");
    end;

    local procedure CreateGeneralJournalLineWithFCY(var GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal; GenPostingType: Enum "General Posting Type")
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment,
          GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(), Amount);
        GenJournalLine.Validate("Currency Code", CreateCurrency());
        GenJournalLine.Validate("Gen. Posting Type", GenPostingType);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateAndUpdateWHTPostingSetup(RealizedWHTType: Option) OldRealizedWHTType: Integer
    var
        WHTPostingSetup: Record "WHT Posting Setup";
    begin
        if not WHTPostingSetup.Get() then
            LibraryAPACLocalization.CreateWHTPostingSetup(WHTPostingSetup, '', '');  // Using blank for WHT Business Posting Group, WHT Product Posting Group
        OldRealizedWHTType := WHTPostingSetup."Realized WHT Type";
        WHTPostingSetup.Validate("Realized WHT Type", RealizedWHTType);
        WHTPostingSetup.Modify(true);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGLAccountFromGLAccount(SetupGLAccount: Record "G/L Account"): Code[20]
    var
        GLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateGLAccount(GLAccount);
        GLAccount.Validate("Gen. Bus. Posting Group", SetupGLAccount."Gen. Bus. Posting Group");
        GLAccount.Validate("Gen. Prod. Posting Group", SetupGLAccount."Gen. Prod. Posting Group");
        GLAccount.Validate("VAT Bus. Posting Group", SetupGLAccount."VAT Bus. Posting Group");
        GLAccount.Validate("VAT Prod. Posting Group", SetupGLAccount."VAT Prod. Posting Group");
        GLAccount.Modify(true);
        exit(GLAccount."No.");
    end;

    local procedure CreateSalesDocument(var SalesLine: Record "Sales Line"; DocumentType: Enum "Sales Document Type"; Type: Enum "Sales Line Type"; No: Code[20])
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, LibrarySales.CreateCustomerNo());
        CreateSalesLine(SalesLine, SalesHeader, Type, No);
    end;

    local procedure CreatePurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; Type: Enum "Purchase Line Type"; No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendor(Vendor));
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No);
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; No: Code[20])
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, No, 1);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDecInRange(1000, 2000, 2));
        SalesLine.Modify(true);
    end;

    local procedure CreatePostGLSalesInvoice(CustomerNo: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Invoice, CustomerNo);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", GLAccountNo);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreatePostGLSalesInvoiceWithUnrealizedVAT(var VATPostingSetup: Record "VAT Posting Setup"; var CustomerNo: Code[20]; var VATBase: Decimal; var VATAmount: Decimal): Code[20]
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        LibraryERM.SetUnrealizedVAT(true);
        CreateUnrealVATPostingSetup(VATPostingSetup);
        CustomerNo := LibrarySales.CreateCustomerWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Sale);
        SalesInvoiceHeader.Get(CreatePostGLSalesInvoice(CustomerNo, GLAccountNo));
        SalesInvoiceHeader.CalcFields(Amount, "Amount Including VAT");
        VATBase := SalesInvoiceHeader.Amount;
        VATAmount := SalesInvoiceHeader."Amount Including VAT" - SalesInvoiceHeader.Amount;
        exit(SalesInvoiceHeader."No.");
    end;

    local procedure CreatePostGLPurchaseInvoice(VendorNo: Code[20]; GLAccountNo: Code[20]): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", GLAccountNo);
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));
    end;

    local procedure CreatePostGLPurchaseInvoiceWithUnrealizedVAT(var VATPostingSetup: Record "VAT Posting Setup"; var VendorNo: Code[20]; var VATBase: Decimal; var VATAmount: Decimal): Code[20]
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        GLAccount: Record "G/L Account";
        GLAccountNo: Code[20];
    begin
        LibraryERM.SetUnrealizedVAT(true);
        CreateUnrealVATPostingSetup(VATPostingSetup);
        VendorNo := LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group");
        GLAccountNo := LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase);
        PurchInvHeader.Get(CreatePostGLPurchaseInvoice(VendorNo, GLAccountNo));
        PurchInvHeader.CalcFields(Amount, "Amount Including VAT");
        VATBase := PurchInvHeader.Amount;
        VATAmount := PurchInvHeader."Amount Including VAT" - PurchInvHeader.Amount;
        exit(PurchInvHeader."No.");
    end;

    local procedure CreateSalesCreditMemoForPostedInvoice(var SalesHeader: Record "Sales Header"; CustomerNo: Code[20]; PostedInvoiceNo: Code[20])
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Credit Memo", CustomerNo);
        SalesHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        SalesHeader.Modify(true);
        LibrarySales.CopySalesDocument(SalesHeader, "Sales Document Type From"::"Posted Invoice", PostedInvoiceNo, false, false);
    end;

    local procedure CreatePurchaseCreditMemoForPostedInvoice(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; PostedInvoiceNo: Code[20])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", VendorNo);
        PurchaseHeader.Validate("Posting Date", CalcDate('<1M>', WorkDate()));
        PurchaseHeader.Modify(true);
        LibraryPurchase.CopyPurchaseDocument(PurchaseHeader, "Purchase Document Type From"::"Posted Invoice", PostedInvoiceNo, false, false);
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; No: Code[20])
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, No, 1);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesLineWithDiffVATProdPostingGrp(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; VATBusPostingGroup: Code[20])
    var
        VATPostingSetup: Record "VAT Posting Setup";
        VATProductPostingGroup: Record "VAT Product Posting Group";
    begin
        LibraryERM.CreateVATProductPostingGroup(VATProductPostingGroup);
        LibraryERM.CreateVATPostingSetup(VATPostingSetup, VATBusPostingGroup, VATProductPostingGroup.Code);
        VATPostingSetup.Validate("VAT %", 0);  // As per test case requirement, using 0.
        VATPostingSetup.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesLine.Validate("VAT Bus. Posting Group", VATBusPostingGroup);
        SalesLine.Validate("VAT Prod. Posting Group", VATProductPostingGroup.Code);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesLineWithDiffDims(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo());
        SalesLine.Validate("Shortcut Dimension 1 Code", CreateGlobalDim1Value());
        SalesLine.Modify(true);
    end;

    local procedure CreatePurchLineWithDiffDims(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo());
        PurchaseLine.Validate("Shortcut Dimension 1 Code", CreateGlobalDim1Value());
        PurchaseLine.Modify(true);
    end;

    local procedure CreateGlobalDim1Value(): Code[20]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        exit(DimensionValue.Code);
    end;

    local procedure CreateSalesOrderWithTwoLines(var SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        LineGLAccount: Record "G/L Account";
    begin
        LibrarySales.CreatePrepaymentVATSetup(LineGLAccount, "Tax Calculation Type"::"Normal VAT");
        LibrarySales.CreateSalesHeader(
          SalesHeader, SalesHeader."Document Type"::Order,
          LibrarySales.CreateCustomerWithBusPostingGroups(
            LineGLAccount."Gen. Bus. Posting Group", LineGLAccount."VAT Bus. Posting Group"));
        SalesHeader.Validate("Prepayment %", 100);
        SalesHeader.Validate("Compress Prepayment", false);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", LineGLAccount."No.");
        CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::"G/L Account", CreateGLAccountFromGLAccount(LineGLAccount));
        SalesHeader.CalcFields("Amount Including VAT");
    end;

    local procedure CreateGenJournalLineWithoutBASCalcSheet(var GenJournalLine: Record "Gen. Journal Line"; BASAdjustment: Boolean)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::" ",
            GenJournalLine."Account Type"::"G/L Account", LibraryERM.CreateGLAccountWithSalesSetup(),
            GenJournalLine."Bal. Account Type"::Customer, LibrarySales.CreateCustomerNo(), LibraryRandom.RandInt(100));
        GenJournalLine.Validate("Gen. Posting Type", GenJournalLine."Gen. Posting Type"::Sale);
        GenJournalLine.Validate("BAS Adjustment", BASAdjustment);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJournalLineWithUpdateBASCalcSheet(var GenJournalLine: Record "Gen. Journal Line")
    var
        BASCalculationSheet: Record "BAS Calculation Sheet";
    begin
        CreateGenJournalLineWithoutBASCalcSheet(GenJournalLine, true);
        LibraryAPACLocalization.CreateBASCalculationSheet(BASCalculationSheet);
        BASCalculationSheet.Validate(Updated, true);
        BASCalculationSheet.Modify(true);
        GenJournalLine.Validate("BAS Doc. No.", BASCalculationSheet.A1);
        GenJournalLine.Validate("BAS Version", BASCalculationSheet."BAS Version");
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePostPmtAppliedToInvoice(AccountType: Enum "Gen. Journal Account Type"; CVNo: Code[20]; PostedInvoiceNo: Code[20]; LineAmount: Decimal)
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Payment, AccountType, CVNo, LineAmount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PostedInvoiceNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateUnrealVATPostingSetup(var VATPostingSetup: Record "VAT Posting Setup")
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::Percentage);
        VATPostingSetup.Validate("Sales VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Validate("Purch. VAT Unreal. Account", LibraryERM.CreateGLAccountNo());
        VATPostingSetup.Modify(true);
    end;

    local procedure FindGLSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::"G/L Account");
        SalesLine.FindFirst();
    end;

    local procedure FindGLPurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::"G/L Account");
        PurchaseLine.FindFirst();
    end;

    local procedure FindGLEntry(var GLEntry: Record "G/L Entry"; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20])
    begin
        GLEntry.SetRange("Document Type", DocumentType);
        GLEntry.SetRange("Document No.", DocumentNo);
        GLEntry.SetRange("G/L Account No.", GLAccountNo);
        GLEntry.FindFirst();
    end;

    local procedure FindVATEntry(var VATEntry: Record "VAT Entry"; VATEntryType: Enum "General Posting Type"; CVNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20])
    begin
        VATEntry.SetRange(Type, VATEntryType);
        VATEntry.SetRange("Bill-to/Pay-to No.", CVNo);
        VATEntry.SetRange("Document Type", DocumentType);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
    end;

    local procedure GetVATAmount(SalesLine: Record "Sales Line"): Decimal
    begin
        exit(SalesLine."Amount Including VAT" - SalesLine."VAT Base Amount");
    end;

    local procedure GetSalesVATAccountNo(SalesLine: Record "Sales Line"): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        VATPostingSetup.Get(SalesLine."VAT Bus. Posting Group", SalesLine."VAT Prod. Posting Group");
        exit(VATPostingSetup."Sales VAT Account");
    end;

    local procedure GetReceivablesAccountNo(CustomerNo: Code[20]): Code[20]
    var
        Customer: Record Customer;
        CustomerPostingGroup: Record "Customer Posting Group";
    begin
        Customer.Get(CustomerNo);
        CustomerPostingGroup.Get(Customer."Customer Posting Group");
        exit(CustomerPostingGroup."Receivables Account");
    end;

    local procedure UpdateGeneralLedgerSetup(UnrealizedVAT: Boolean; GSTReport: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Unrealized VAT", UnrealizedVAT);
        GeneralLedgerSetup.Validate("GST Report", GSTReport);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateGSTGLSetup(EnableGST: Boolean; AdjmtMandatory: Boolean; FullGSTOnPrepmt: Boolean; GSTReport: Boolean; EnableWHT: Boolean; InvoiceRounding: Boolean; var SavedEnableGST: Boolean; var SavedAdjmtMandatory: Boolean; var SavedFullGSTOnPrepmt: Boolean; var SavedGSTReport: Boolean; var SavedEnableWHT: Boolean; var SavedInvoiceRounding: Boolean)
    var
        GLSetup: Record "General Ledger Setup";
        SalesSetup: Record "Sales & Receivables Setup";
    begin
        GLSetup.Get();
        SavedEnableGST := GLSetup."Enable GST (Australia)";
        SavedAdjmtMandatory := GLSetup."Adjustment Mandatory";
        SavedFullGSTOnPrepmt := GLSetup."Full GST on Prepayment";
        SavedGSTReport := GLSetup."GST Report";
        SavedEnableWHT := GLSetup."Enable WHT";

        SalesSetup.Get();
        SavedInvoiceRounding := SalesSetup."Invoice Rounding";

        GLSetup."Enable GST (Australia)" := EnableGST;
        GLSetup."Adjustment Mandatory" := AdjmtMandatory;
        GLSetup."Full GST on Prepayment" := FullGSTOnPrepmt;
        GLSetup."GST Report" := GSTReport;
        GLSetup."Enable WHT" := EnableWHT;
        GLSetup.Modify(true);

        SalesSetup."Invoice Rounding" := InvoiceRounding;
        SalesSetup.Modify(true);
    end;

    local procedure UpdateSalesHeaderAdjAppliesTo(var SalesHeader: Record "Sales Header"; AdjustmentAppliesTo: Code[20])
    begin
        SalesHeader.Validate("Adjustment Applies-to", AdjustmentAppliesTo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdateSalesHeaderAppliesTo(var SalesHeader: Record "Sales Header"; AppliesToDocNo: Code[20])
    begin
        SalesHeader.Validate("Applies-to Doc. Type", SalesHeader."Applies-to Doc. Type"::Invoice);
        SalesHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        SalesHeader.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderAppliesTo(var PurchaseHeader: Record "Purchase Header"; AppliesToDocNo: Code[20])
    begin
        PurchaseHeader.Validate("Applies-to Doc. Type", PurchaseHeader."Applies-to Doc. Type"::Invoice);
        PurchaseHeader.Validate("Applies-to Doc. No.", AppliesToDocNo);
        PurchaseHeader.Modify(true);
    end;

    local procedure UpdateSalesDocUnitPrice(SalesHeader: Record "Sales Header"; NewUnitPrice: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        FindGLSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate("Unit Price", NewUnitPrice);
        SalesLine.Modify(true);
    end;

    local procedure UpdatePurchaseDocDirectUnitPrice(PurchaseHeader: Record "Purchase Header"; NewDirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        FindGLPurchaseLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.Validate("Direct Unit Cost", NewDirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure ResetUnrealizedVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup")
    begin
        VATPostingSetup.Validate("Unrealized VAT Type", VATPostingSetup."Unrealized VAT Type"::" ");
        VATPostingSetup.Modify(true);
    end;

    local procedure VerifyGSTEntry(GSTBase: Decimal; ActualGSTBase: Decimal; GSTAmount: Decimal; ActualGSTAmount: Decimal)
    begin
        Assert.AreNearlyEqual(GSTBase, ActualGSTBase, LibraryERM.GetAmountRoundingPrecision(), UnexpectedErr);
        Assert.AreNearlyEqual(GSTAmount, ActualGSTAmount, LibraryERM.GetAmountRoundingPrecision(), UnexpectedErr);
    end;

    local procedure VerifyGSTSalesEntries(DocumentNo: Code[20]; ExpectedCount: Integer; ExpectedAmount: Decimal)
    var
        GSTSalesEntry: Record "GST Sales Entry";
    begin
        GSTSalesEntry.SetRange("Document Type", GSTSalesEntry."Document Type"::Invoice);
        GSTSalesEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(ExpectedCount, GSTSalesEntry.Count, StrSubstNo(WrongValueInGSTEntryErr, GSTSalesEntry.TableCaption(), LineCountTxt));
        GSTSalesEntry.CalcSums("GST Base");
        Assert.AreEqual(
          ExpectedAmount, GSTSalesEntry."GST Base", StrSubstNo(WrongValueInGSTEntryErr, GSTSalesEntry.TableCaption(), GSTSalesEntry.FieldCaption("GST Base")));
    end;

    local procedure VerifyGSTPurchEntries(DocumentNo: Code[20]; ExpectedCount: Integer; ExpectedAmount: Decimal)
    var
        GSTPurchaseEntry: Record "GST Purchase Entry";
    begin
        GSTPurchaseEntry.SetRange("Document Type", GSTPurchaseEntry."Document Type"::Invoice);
        GSTPurchaseEntry.SetRange("Document No.", DocumentNo);
        Assert.AreEqual(ExpectedCount, GSTPurchaseEntry.Count, StrSubstNo(WrongValueInGSTEntryErr, GSTPurchaseEntry.TableCaption(), LineCountTxt));
        GSTPurchaseEntry.CalcSums("GST Base");
        Assert.AreEqual(
          ExpectedAmount, GSTPurchaseEntry."GST Base", StrSubstNo(WrongValueInGSTEntryErr, GSTPurchaseEntry.TableCaption(), GSTPurchaseEntry.FieldCaption("GST Base")));
    end;

    local procedure VerifyGSTVATEntries(DocumentNo: Code[20])
    var
        SalesInvLine: Record "Sales Invoice Line";
        GSTSalesEntry: Record "GST Sales Entry";
        VATEntry: Record "VAT Entry";
    begin
        SalesInvLine.SetRange("Document No.", DocumentNo);
        SalesInvLine.FindSet();
        repeat
            GSTSalesEntry.SetRange("Document No.", SalesInvLine."Document No.");
            GSTSalesEntry.SetRange("Customer No.", SalesInvLine."Sell-to Customer No.");
            GSTSalesEntry.SetRange("GST Base", SalesInvLine.Amount);
            Assert.RecordIsNotEmpty(GSTSalesEntry);
            Assert.AreEqual(1, GSTSalesEntry.Count, UnexpectedErr);

            VATEntry.SetRange("Document No.", SalesInvLine."Document No.");
            VATEntry.SetRange("Bill-to/Pay-to No.", SalesInvLine."Sell-to Customer No.");
            VATEntry.SetRange(Base, SalesInvLine.Amount);
            Assert.RecordIsNotEmpty(VATEntry);
            Assert.AreEqual(1, VATEntry.Count, UnexpectedErr);
        until SalesInvLine.Next() = 0;
    end;

    local procedure VerifyGSTBASAdj(DocumentNo: Code[20]; ExpectedBASAdjusnment: Boolean)
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindFirst();
        VATEntry.TestField("BAS Adjustment", ExpectedBASAdjusnment);
    end;

    local procedure VerifyGLEntryBASAdjustment(DocumentType: Enum "Gen. Journal Document Type"; DocumentNo: Code[20]; GLAccountNo: Code[20]; ExpectedBASAdjustment: Boolean)
    var
        GLEntry: Record "G/L Entry";
    begin
        FindGLEntry(GLEntry, DocumentType, DocumentNo, GLAccountNo);
        Assert.AreEqual(ExpectedBASAdjustment, GLEntry."BAS Adjustment", GLEntry.FieldCaption("BAS Adjustment"));
    end;

    local procedure VerifyVATEntryAmounts(VATEntry: Record "VAT Entry"; ExpectedBase: Decimal; ExpectedAmount: Decimal; ExpectedUnrealizedBase: Decimal; ExpectedUnrealizedAmount: Decimal; ExpectedRemUnrealizedBase: Decimal; ExpectedRemUnrealizedAmount: Decimal)
    begin
        VATEntry.TestField(Base, ExpectedBase);
        VATEntry.TestField(Amount, ExpectedAmount);
        VATEntry.TestField("Unrealized Base", ExpectedUnrealizedBase);
        VATEntry.TestField("Unrealized Amount", ExpectedUnrealizedAmount);
        VATEntry.TestField("Remaining Unrealized Base", ExpectedRemUnrealizedBase);
        VATEntry.TestField("Remaining Unrealized Amount", ExpectedRemUnrealizedAmount);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ApplyCustomerEntriesSelectDocModalPageHandler(var ApplyCustomerEntries: TestPage "Apply Customer Entries")
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        CustLedgerEntry.SetRange("Entry No.", LibraryVariableStorage.DequeueInteger());
        CustLedgerEntry.FindFirst();
        ApplyCustomerEntries.FILTER.SetFilter("Entry No.", Format(CustLedgerEntry."Entry No."));
        ApplyCustomerEntries.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure YesConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

