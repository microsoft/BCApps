codeunit 144058 "Test CH Small Features"
{
    EventSubscriberInstance = Manual;
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    var
        LibraryFixedAsset: Codeunit "Library - Fixed Asset";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        IsInitialized: Boolean;
        AccountTxt: Label 'Account';
        GlobalHeaderLabel: Text[30];
        GlobalHeaderTxt: Text;
        GlobalFooterLabel: Text[30];
        GlobalFooterTxt: Text;
        ShipingDateTxt: Label 'Shipping Date';
        CompressPrepaymentCannotBeUsedWithApplyInvRoundAmtToVATErr: Label 'You cannot use %1 for %2 %3 when %4 is enabled in %5.', Comment = '%1 - Compress Prepayment field caption, %2 - Document Type field value, %3 - No. field value, %4 - Apply Inv. Round. Amt. To VAT field caption, %5 - Sales & Receivables Setup table caption.';

    [Test]
    [Scope('OnPrem')]
    procedure VATForFixedAssets()
    var
        FAPostingGroup: Record "FA Posting Group";
        FADepreciationBook: Record "FA Depreciation Book";
        DepreciationBook: Record "Depreciation Book";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
        FixedAsset: Record "Fixed Asset";
        GLAccount: Record "G/L Account";
        FALedgerEntry: Record "FA Ledger Entry";
    begin
        Initialize();

        // Setup.
        LibraryERM.CreateGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        LibraryERM.CreateGLAccount(GLAccount);
        GenJournalBatch.Validate("Copy VAT Setup to Jnl. Lines", true);
        GenJournalBatch.Modify(true);

        LibraryFixedAsset.CreateDepreciationBook(DepreciationBook);
        DepreciationBook.Validate("G/L Integration - Acq. Cost", true);
        DepreciationBook.Modify(true);

        LibraryFixedAsset.CreateFAPostingGroup(FAPostingGroup);
        FAPostingGroup.Validate("Acquisition Cost Account", GLAccount."No.");
        FAPostingGroup.Modify(true);

        LibraryFixedAsset.CreateFixedAsset(FixedAsset);
        LibraryFixedAsset.CreateFADepreciationBook(FADepreciationBook, FixedAsset."No.", DepreciationBook.Code);
        FADepreciationBook.Validate("FA Posting Group", FAPostingGroup.Code);
        FADepreciationBook.Modify(true);

        LibraryERM.CreateGeneralJnlLineWithBalAcc(GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
          GenJournalLine."Document Type"::" ", GenJournalLine."Account Type"::"Fixed Asset", FixedAsset."No.",
          GenJournalLine."Bal. Account Type"::"G/L Account", GLAccount."No.", LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("FA Posting Type", GenJournalLine."FA Posting Type"::"Acquisition Cost");
        GenJournalLine.Validate("Depreciation Book Code", DepreciationBook.Code);
        GenJournalLine.Modify(true);

        // Exercise.
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Verify.
        FALedgerEntry.SetRange("FA No.", FixedAsset."No.");
        FALedgerEntry.FindFirst();
        FALedgerEntry.TestField("VAT Amount", 0);
        FALedgerEntry.TestField("VAT Bus. Posting Group", '');
        FALedgerEntry.TestField("VAT Prod. Posting Group", '');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ExactCostRevMandatoryWithNegativeQty()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        Initialize();

        // Setup.
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup."Exact Cost Reversing Mandatory" := true;
        PurchasesPayablesSetup.Modify();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::" ");
        Item.Validate(Type, Item.Type::"Non-Inventory");
        Item.Modify(true);

        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.",
          -LibraryRandom.RandDec(10, 2));

        // Exercise.
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Verify: No errors.
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvDiscAppliedToVAT()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        AmtInclVAT: Decimal;
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := LibraryRandom.RandDecInRange(0, 1, 2);
        GeneralLedgerSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Apply Inv. Round. Amt. To VAT" := true;
        SalesReceivablesSetup.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // Exercise.
        AmtInclVAT :=
          Round(SalesLine."Unit Price" * SalesLine.Quantity * (100 - SalesLine."Line Discount %") / 100,
            GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        LibraryVariableStorage.Enqueue(AmtInclVAT);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.Statistics.Invoke();

        // Verify: in the handler.
    end;
#endif
    [Test]
    [HandlerFunctions('SalesOrderStatisticsPageHandlerNM')]
    [Scope('OnPrem')]
    procedure SalesInvDiscAppliedToVATNM()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        AmtInclVAT: Decimal;
    begin
        Initialize();

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Inv. Rounding Precision (LCY)" := LibraryRandom.RandDecInRange(0, 1, 2);
        GeneralLedgerSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Apply Inv. Round. Amt. To VAT" := true;
        SalesReceivablesSetup.Modify(true);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Prices Including VAT", true);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Modify(true);

        // Exercise.
        AmtInclVAT :=
          Round(SalesLine."Unit Price" * SalesLine.Quantity * (100 - SalesLine."Line Discount %") / 100,
            GeneralLedgerSetup."Inv. Rounding Precision (LCY)");
        LibraryVariableStorage.Enqueue(AmtInclVAT);
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        SalesOrder.SalesOrderStatistics.Invoke();

        // Verify: in the handler.
    end;

    [Test]
    [HandlerFunctions('SalesReturnOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesReturnOrderHeaderAndFooter()
    var
        SalesHeader: Record "Sales Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Sales Return Order]
        // [SCENARIO 283760] Report 6631 "Return Order Confirmation" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create return order
        CreateSalesReturnOrder(SalesHeader);
        UpdateSalesHeaderYourReferenceAndSalespersoneName(SalesHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Return Order Confirmation is being printed
        Commit();
        REPORT.Run(REPORT::"Return Order Confirmation", true, false, SalesHeader);

        // [THEN] CH header and footer data printed
        VerifySalesBaseHeaderAndFooterData(SalesHeader, true);
        // [THEN] Extended header and footer data printed
        VerifySalesExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('SalesShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesShipmentHeaderAndFooter()
    var
        SalesHeader: Record "Sales Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Sales Shipment]
        // [SCENARIO 283760] Report 208 "Sales - Shipment" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create and post sales shipment with Shipment Date <> Document Date
        LibrarySales.CreateSalesOrder(SalesHeader);
        UpdateSalesHeaderYourReferenceAndSalespersoneName(SalesHeader);
        SalesHeader.Validate("Shipment Date", SalesHeader."Document Date" + 1);
        SalesHeader.Modify();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        FindSalesShipment(SalesShipmentHeader, SalesHeader."No.");

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Sales - Shipment is being printed
        Commit();
        REPORT.Run(REPORT::"Sales - Shipment", true, false, SalesShipmentHeader);

        // [THEN] CH header and footer data printed
        VerifySalesBaseHeaderAndFooterData(SalesHeader, false);
        // [THEN] Shipment Date printed in footer
        LibraryReportDataset.AssertElementTagWithValueExists('FooterLabel2', ShipingDateTxt);
        LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt2', Format(SalesHeader."Shipment Date", 0, 4));
        // [THEN] Extended header and footer data printed
        VerifySalesExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('SalesBlanketOrderPageHandler')]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderHeaderAndFooter()
    var
        SalesHeader: Record "Sales Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Sales Blanket Order]
        // [SCENARIO 283760] Report 210 "Blanket Sales Order" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create sales blanket order
        CreateSalesBlanketOrder(SalesHeader);
        UpdateSalesHeaderYourReferenceAndSalespersoneName(SalesHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Blanket Sales Order is being printed
        Commit();
        REPORT.Run(REPORT::"Blanket Sales Order", true, false, SalesHeader);

        // [THEN] CH header and footer data printed
        VerifySalesBaseHeaderAndFooterData(SalesHeader, true);
        // [THEN] Extended header and footer data printed
        VerifySalesExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('SalesInvoiceESRRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SalesInvoiceESRHeaderAndFooter()
    var
        SalesHeader: Record "Sales Header";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Sales Invoice]
        // [SCENARIO 283760] Report 3010532 "Sales Invoice ESR" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create and post sales invoice
        LibrarySales.CreateSalesInvoice(SalesHeader);
        UpdateSalesHeaderYourReferenceAndSalespersoneName(SalesHeader);
        SalesInvoiceHeader.Get(LibrarySales.PostSalesDocument(SalesHeader, true, true));

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] "Sales Invoice ESR" is being printed
        Commit();
        REPORT.Run(REPORT::"Sales Invoice ESR", true, false, SalesInvoiceHeader);

        // [THEN] CH header and footer data printed
        VerifySalesBaseHeaderAndFooterData(SalesHeader, true);
        // [THEN] Extended header and footer data printed
        VerifySalesExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('SalesPickingListPageHandler')]
    [Scope('OnPrem')]
    procedure SalesPickingListHeaderAndFooter()
    var
        SalesHeader: Record "Sales Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Sales Order]
        // [SCENARIO 283760] Report 11512 "Sales Picking List" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create sales order
        LibrarySales.CreateSalesOrder(SalesHeader);
        UpdateSalesHeaderYourReferenceAndSalespersoneName(SalesHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Sales Picking List is being printed
        Commit();
        REPORT.Run(REPORT::"Sales Picking List", true, false, SalesHeader);

        // [THEN] CH header and footer data printed
        VerifySalesBaseHeaderAndFooterData(SalesHeader, false);
        // [THEN] Extended header and footer data printed
        VerifySalesExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('PurchQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchQuoteHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Purchase Quote]
        // [SCENARIO 283760] Report 404 "Purchase - Quote" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create purchase quote
        LibraryPurchase.CreatePurchaseQuote(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Sales - Quote is being printed
        Commit();
        REPORT.Run(REPORT::"Purchase - Quote", true, false, PurchaseHeader);

        // [THEN] CH header and footer data printed
        VerifyPurchBaseHeaderAndFooterData(PurchaseHeader);
        // [THEN] Extended header and footer data printed
        VerifyPurchExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('PurchOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchOrderHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Purchase Order]
        // [SCENARIO 283760] Report 405 "Order" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create purchase order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Order is being printed
        Commit();
        REPORT.Run(REPORT::Order, true, false, PurchaseHeader);

        // [THEN] CH header and footer data printed
        VerifyPurchBaseHeaderAndFooterData(PurchaseHeader);
        // [THEN] Extended header and footer data printed
        VerifyPurchExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('PurchInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
    begin
        // [FEATURE] [UT] [Purchase Invoice]
        // [SCENARIO 283760] Report 406 "Purchase - Invoice" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);
        PurchInvHeader.DeleteAll();
        // [GIVEN] Create and post purchase order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] "Purchase - Invoice" is being printed
        Commit();
        REPORT.Run(REPORT::"Purchase - Invoice", true, false, PurchInvHeader);

        // [THEN] CH header and footer data printed
        VerifyPurchInvoiceHeaderAndFooterData(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('PurchCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Purchase Credit Memo]
        // [SCENARIO 283760] Report 407 "Purchase - Credit Memo" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create and post purchase credit memo
        LibraryPurchase.CreatePurchaseCreditMemo(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Purchase - Credit Memo is being printed
        Commit();
        REPORT.Run(REPORT::"Purchase - Credit Memo", true, false, PurchCrMemoHdr);

        // [THEN] CH header and footer data printed
        VerifyPurchBaseHeaderAndFooterData(PurchaseHeader);
        // [THEN] Extended header and footer data printed
        VerifyPurchExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('PurchReceiptRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReceiptHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Purchase Credit Memo]
        // [SCENARIO 283760] Report 408 "Purchase - Receipt" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create and post purchase receipt
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        FindPurchReceipt(PurchRcptHeader, PurchaseHeader."No.");

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Purchase - Receipt is being printed
        Commit();
        REPORT.Run(REPORT::"Purchase - Receipt", true, false, PurchRcptHeader);

        // [THEN] CH header and footer data printed
        VerifyPurchBaseHeaderAndFooterData(PurchaseHeader);
        // [THEN] Extended header and footer data printed
        VerifyPurchExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('PurchBlanketOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchBlanketOrderHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Purchase Quote]
        // [SCENARIO 283760] Report 410 "Blanket Purchase Order" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create purchase blanket order
        CreatePurchaseBlanketOrder(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Blanket Purchase Order is being printed
        Commit();
        REPORT.Run(REPORT::"Blanket Purchase Order", true, false, PurchaseHeader);

        // [THEN] CH header and footer data printed
        VerifyPurchBaseHeaderAndFooterData(PurchaseHeader);
        // [THEN] Extended header and footer data printed
        VerifyPurchExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('PurchReturnOrderRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchReturnHeaderAndFooter()
    var
        PurchaseHeader: Record "Purchase Header";
        TestCHSmallFeatures: Codeunit "Test CH Small Features";
        HeaderLabel: Text[30];
        HeaderTxt: Text;
        FooterLabel: Text[30];
        FooterTxt: Text;
    begin
        // [FEATURE] [UT] [Purchase Return Order]
        // [SCENARIO 283760] Report 6641 "Return Order" prints CH header and footer data
        Initialize();

        // [GIVEN] Subscirbe to OnAfterPrepareHeader and OnAfterPrepareFooter of CH Repor Management codeunit
        BindSubscription(TestCHSmallFeatures);

        // [GIVEN] Create purchase return order
        CreatePurchaseReturnOrder(PurchaseHeader);
        UpdatePurchHeaderYourReferenceAndSalespersoneName(PurchaseHeader);

        // [GIVEN] Prepare extended header and footer data
        TestCHSmallFeatures.SetExtendedParamenters(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);

        // [WHEN] Return Order is being printed
        Commit();
        REPORT.Run(REPORT::"Return Order", true, false, PurchaseHeader);

        // [THEN] CH header and footer data printed
        VerifyPurchBaseHeaderAndFooterData(PurchaseHeader);
        // [THEN] Extended header and footer data printed
        VerifyPurchExtendedHeaderAndFooterData(HeaderLabel, HeaderTxt, FooterLabel, FooterTxt);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure S463717_CompressPrepaymentCannotBeUsedWithApplyInvRoundAmtToVAT()
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [FEATURE] [UT] [Apply Inv. Round. Amt. To VAT] [Compress Prepayment]
        // [SCENARIO 283760] "Compress Prepayment" cannot be used in Sales Header when "Apply Inv. Round. Amt. To VAT" is enabled.
        Initialize();

        // [GIVEN] Set "Apply Inv. Round. Amt. To VAT" to true.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Apply Inv. Round. Amt. To VAT" := true;
        SalesReceivablesSetup.Modify(true);

        // [WHEN] Create Sales Order 1.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [THEN] Compress Prepayment is false.
        SalesHeader.TestField("Compress Prepayment", false);
        Clear(SalesHeader);

        // [GIVEN] Set "Apply Inv. Round. Amt. To VAT" to false.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Apply Inv. Round. Amt. To VAT" := false;
        SalesReceivablesSetup.Modify(true);

        // [WHEN] Create Sales Order 2.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');

        // [THEN] Compress Prepayment is true.
        SalesHeader.TestField("Compress Prepayment", true);

        // [GIVEN] Set "Apply Inv. Round. Amt. To VAT" to true after Sales Order is created.
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup."Apply Inv. Round. Amt. To VAT" := true;
        SalesReceivablesSetup.Modify(true);

        // [GIVEN] Create Sales Line with Prepayment % = 1.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Line Discount %", LibraryRandom.RandDec(10, 2));
        SalesLine.Validate("Prepayment %", 1);
        SalesLine.Modify(true);

        // [WHEN] Try to Post Prepayment Invoice.
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);
        ErrorMessages.Trap();
        SalesOrder.PostPrepaymentInvoice.Invoke(); // Uses ConfirmHandler.

        // [THEN] Error is thrown that Compress Prepayment cannot be used with Apply Inv. Round. Amt. To VAT.
        ErrorMessages.Description.AssertEquals(StrSubstNo(CompressPrepaymentCannotBeUsedWithApplyInvRoundAmtToVATErr, SalesHeader.FieldCaption("Compress Prepayment"), SalesHeader."Document Type", SalesHeader."No.", SalesReceivablesSetup.FieldCaption("Apply Inv. Round. Amt. To VAT"), SalesReceivablesSetup.TableCaption()));
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"Test CH Small Features");
        LibrarySetupStorage.Restore();
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"Test CH Small Features");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Sales & Receivables Setup");
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"Test CH Small Features");
    end;

    local procedure CreateSalesBlanketOrder(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header")
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", LibrarySales.CreateCustomerNo());
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(
          Item, LibraryRandom.RandDecInRange(1, 100, 2), LibraryRandom.RandDecInRange(1, 100, 2));
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
    end;

    local procedure CreatePurchaseBlanketOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 99, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", LibraryPurchase.CreateVendorNo());
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 99, 2));
        PurchaseLine.Modify(true);
    end;

    local procedure FindSalesShipment(var SalesShipmentHeader: Record "Sales Shipment Header"; OrderNo: Code[20])
    begin
        SalesShipmentHeader.SetRange("Order No.", OrderNo);
        SalesShipmentHeader.FindFirst();
    end;

    local procedure FindPurchReceipt(var PurchRcptHeader: Record "Purch. Rcpt. Header"; OrderNo: Code[20])
    begin
        PurchRcptHeader.SetRange("Order No.", OrderNo);
        PurchRcptHeader.FindFirst();
    end;

    local procedure UpdateSalesHeaderYourReferenceAndSalespersoneName(var SalesHeader: Record "Sales Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        SalesHeader."Your Reference" :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(SalesHeader."Your Reference"), 1),
            1,
            MaxStrLen(SalesHeader."Your Reference"));
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        SalesHeader."Salesperson Code" := SalespersonPurchaser.Code;
        SalesHeader.Modify();

        SalespersonPurchaser.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(SalespersonPurchaser.Name), 1),
            1,
            MaxStrLen(SalespersonPurchaser.Name));
        SalespersonPurchaser.Modify();
    end;

    local procedure UpdatePurchHeaderYourReferenceAndSalespersoneName(var PurchaseHeader: Record "Purchase Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
    begin
        PurchaseHeader."Your Reference" :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(PurchaseHeader."Your Reference"), 1),
            1,
            MaxStrLen(PurchaseHeader."Your Reference"));
        LibrarySales.CreateSalesperson(SalespersonPurchaser);
        PurchaseHeader."Purchaser Code" := SalespersonPurchaser.Code;
        PurchaseHeader.Modify();

        SalespersonPurchaser.Name :=
          CopyStr(
            LibraryUtility.GenerateRandomAlphabeticText(MaxStrLen(SalespersonPurchaser.Name), 1),
            1,
            MaxStrLen(SalespersonPurchaser.Name));
        SalespersonPurchaser.Modify();
    end;

    local procedure VerifySalesBaseHeaderAndFooterData(SalesHeader: Record "Sales Header"; CheckBankInfo: Boolean)
    var
        CompanyInformation: Record "Company Information";
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryReportDataset.LoadDataSetFile();
        SalespersonPurchaser.Get(SalesHeader."Salesperson Code");
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt1', SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt2', SalesHeader."Your Reference");
        PaymentTerms.Get(SalesHeader."Payment Terms Code");
        LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt1', PaymentTerms.Description);
        if CheckBankInfo then begin
            CompanyInformation.Get();
            LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt2',
              CompanyInformation."Bank Name" + ', ' + AccountTxt + ' ' + CompanyInformation."Bank Account No.");
        end;
    end;

    local procedure VerifySalesExtendedHeaderAndFooterData(HeaderLabel: Text[30]; HeaderTxt: Text; FooterLabel: Text[30]; FooterTxt: Text)
    begin
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderLabel3', HeaderLabel);
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt3', HeaderTxt);
        LibraryReportDataset.AssertElementTagWithValueExists('FooterLabel3', FooterLabel);
        LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt3', FooterTxt);
    end;

    local procedure VerifyPurchBaseHeaderAndFooterData(PurchaseHeader: Record "Purchase Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryReportDataset.LoadDataSetFile();
        SalespersonPurchaser.Get(PurchaseHeader."Purchaser Code");
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt1', SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt2', PurchaseHeader."Your Reference");
        PaymentTerms.Get(PurchaseHeader."Payment Terms Code");
        LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt1', PaymentTerms.Description);
    end;

    local procedure VerifyPurchExtendedHeaderAndFooterData(HeaderLabel: Text[30]; HeaderTxt: Text; FooterLabel: Text[30]; FooterTxt: Text)
    begin
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderLabel3', HeaderLabel);
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt3', HeaderTxt);
        LibraryReportDataset.AssertElementTagWithValueExists('FooterLabel2', FooterLabel);
        LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt2', FooterTxt);
    end;

    local procedure VerifyPurchInvoiceHeaderAndFooterData(PurchaseHeader: Record "Purchase Header")
    var
        SalespersonPurchaser: Record "Salesperson/Purchaser";
        PaymentTerms: Record "Payment Terms";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt1', PurchaseHeader."No.");
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt2', PurchaseHeader."Vendor Invoice No.");
        SalespersonPurchaser.Get(PurchaseHeader."Purchaser Code");
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt3', SalespersonPurchaser.Name);
        LibraryReportDataset.AssertElementTagWithValueExists('HeaderTxt4', PurchaseHeader."Your Reference");
        PaymentTerms.Get(PurchaseHeader."Payment Terms Code");
        LibraryReportDataset.AssertElementTagWithValueExists('FooterTxt1', PaymentTerms.Description);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 3; // Ship and invoice.
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentReportHandler(var SalesShipment: Report "Sales - Shipment")
    begin
    end;

#if not CLEAN26
    [Obsolete('The statistics action will be replaced with the SalesStatistics action. The new action uses RunObject and does not run the action trigger', '26.0')]
    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandler(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        AmtInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmtInclVAT);
        SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(AmtInclVAT);
    end;
#endif
    [PageHandler]
    [Scope('OnPrem')]
    procedure SalesOrderStatisticsPageHandlerNM(var SalesOrderStatistics: TestPage "Sales Order Statistics")
    var
        AmtInclVAT: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmtInclVAT);
        SalesOrderStatistics.TotalInclVAT_Invoicing.AssertEquals(AmtInclVAT);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesInvoiceESRRequestPageHandler(var SalesInvoiceESR: TestRequestPage "Sales Invoice ESR")
    begin
        SalesInvoiceESR.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesReturnOrderRequestPageHandler(var ReturnOrderConfirmation: TestRequestPage "Return Order Confirmation")
    begin
        ReturnOrderConfirmation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesShipmentRequestPageHandler(var SalesShipment: TestRequestPage "Sales - Shipment")
    begin
        SalesShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesBlanketOrderPageHandler(var BlanketSalesOrder: TestRequestPage "Blanket Sales Order")
    begin
        BlanketSalesOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SalesPickingListPageHandler(var SalesPickingList: TestRequestPage "Sales Picking List")
    begin
        SalesPickingList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    begin
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchOrderRequestPageHandler(var "Order": TestRequestPage "Order")
    begin
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchReceiptRequestPageHandler(var PurchaseReceipt: TestRequestPage "Purchase - Receipt")
    begin
        PurchaseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchBlanketOrderRequestPageHandler(var BlanketPurchaseOrder: TestRequestPage "Blanket Purchase Order")
    begin
        BlanketPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchReturnOrderRequestPageHandler(var ReturnOrder: TestRequestPage "Return Order")
    begin
        ReturnOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [Scope('OnPrem')]
    procedure SetExtendedParamenters(var HeaderLabel: Text[30]; var HeaderTxt: Text; var FooterLabel: Text[30]; var FooterTxt: Text)
    begin
        HeaderLabel := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 1), 1, MaxStrLen(HeaderLabel));
        HeaderTxt := LibraryUtility.GenerateRandomAlphabeticText(30, 1);
        FooterLabel := CopyStr(LibraryUtility.GenerateRandomAlphabeticText(30, 1), 1, MaxStrLen(FooterLabel));
        FooterTxt := LibraryUtility.GenerateRandomAlphabeticText(30, 1);
        GlobalHeaderLabel := HeaderLabel;
        GlobalHeaderTxt := HeaderTxt;
        GlobalFooterLabel := FooterLabel;
        GlobalFooterTxt := FooterTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CH Report Management", 'OnAfterPrepareHeader', '', false, false)]
    local procedure OnAfterPrepareHeader(RecRef: RecordRef; ReportId: Integer; var HeaderLabel: array[20] of Text[30]; var HeaderTxt: array[20] of Text)
    begin
        HeaderLabel[20] := GlobalHeaderLabel;
        HeaderTxt[20] := GlobalHeaderTxt;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CH Report Management", 'OnAfterPrepareFooter', '', false, false)]
    local procedure OnAfterPrepareFooter(RecRef: RecordRef; ReportId: Integer; var FooterLabel: array[20] of Text[30]; var FooterTxt: array[20] of Text)
    begin
        FooterLabel[20] := GlobalFooterLabel;
        FooterTxt[20] := GlobalFooterTxt;
    end;
}
