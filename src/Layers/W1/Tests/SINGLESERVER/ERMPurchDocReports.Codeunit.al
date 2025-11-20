codeunit 134335 "ERM Purch. Doc. Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [Purchase]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryDimension: Codeunit "Library - Dimension";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        isInitialized: Boolean;
        ValidationErr: Label '%1 must be %2 in Report.', Comment = '%1 = Caption, %2 = Value';
        InteractionLogEntryExistErr: Label 'Interaction Log Entry must exist.';
        UndefinedDateErr: Label 'You cannot base a date calculation on an undefined date.';
        BalanceOnCaptionTxt: Label 'Balance on %1', Comment = '%1 = Work date';
        AgedBy: Label 'Aged by %1';
        DimensionValueTxt: Label '%1 - %2', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
        AgingBy: Option "Due Date","Posting Date","Document Date";
        HeadingType: Option "Date Interval","Number of Days";
        UndoReceiptMsg: Label 'Do you really want to undo the selected Receipt lines?';
        UndoPurchRetOrderMsg: Label 'Do you really want to undo the selected Return Shipment lines?';
        MustBeEqualErr: Label '%1 must be equal to %2.', Comment = '%1 = Expected Amount %2 = Actual Amount.';
        NoDatasetRowErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2', Comment = '%1 = Element Name, %2 = Value';
        NumberOfRowsErr: Label 'Number of rows must match.';

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseReceipt')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptNoOption()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        // Check Purchase Receipt with No Option Selected.

        // Setup: Create and Post Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), '');
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise.
        SavePurchaseReceipt(DocumentNo, false, false, false);

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Qty_PurchRcptLine', PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('UOM_PurchRcptLine', PurchaseLine."Unit of Measure");
        LibraryReportDataset.AssertElementWithValueExists('PaytoVenNo_PurchRcptHeader', PurchaseHeader."Pay-to Vendor No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseReceipt')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptInternalInfo()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
        ExpectedDimensionValue: Text[120];
    begin
        // Check Purchase Receipt with Show Internal Information Option.

        // Setup: Create and Post Purchase Order.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', DefaultDimension."No.", '');
        ExpectedDimensionValue := StrSubstNo('%1 - %2', DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise.
        SavePurchaseReceipt(DocumentNo, true, false, false);

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText1', ExpectedDimensionValue);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerPurchaseReceipt')]
    [Scope('OnPrem')]
    procedure PurchaseReceiptLogEntry()
    var
        InteractionLogEntry: Record "Interaction Log Entry";
        PurchaseHeader: Record "Purchase Header";
        NoSeries: Codeunit "No. Series";
        DocumentNo: Code[20];
    begin
        // Check Purchase Receipt with Log Entry Option.

        // Setup: Create and Post Purchase Order.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), '');
        DocumentNo := NoSeries.PeekNextNo(PurchaseHeader."Receiving No. Series");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise.
        SavePurchaseReceipt(DocumentNo, false, true, false);

        // Verify: Verify Interaction Log Entry with Posted Receipt.
        InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Purch. Rcpt.");
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(InteractionLogEntry.FindFirst(), InteractionLogEntryExistErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReportHandlerPurchaseReceipt')]
    [Scope('OnPrem')]
    procedure UndoPurchReceiptReportWithCorrectionLine()
    var
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        // Verify Purchase Receipt Report after undo Receipt with Show Correction Lines.

        // Setup: Create Purchase Order, post and undo Purchase Receipt.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::Order);
        FindReceiptLine(PurchRcptLine, PurchaseLine."No.");
        LibraryVariableStorage.Enqueue(UndoReceiptMsg);  // Enqueue value for ConfirmHandler.
        UndoPurchaseReceiptLines(PurchaseLine."No.");

        // Exercise.
        SavePurchaseReceipt(PurchRcptLine."Document No.", false, false, true);

        // Verify: Verify Purchase Receipt Report with Show Correction Line.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Qty_PurchRcptLine', PurchaseLine.Quantity);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPaymentReceipt')]
    [Scope('OnPrem')]
    procedure VendorPaymentReceipt()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Vendor - Payment Receipt]
        // [SCENARIO] Vendor Payment Receipt Report for payment and invoice in LCY

        // [GIVEN] Purchase Invoice Payment Discount LCY = "D", Payment Tolerance LCY = "T"
        // [GIVEN] Applied Payment with Amount LCY = "P" > Invoice Amount
        Initialize();
        DocumentNo := SetupAndPostVendorPmtTolerance(GenJournalLine, '');

        // [WHEN] Run Vendor Payment Receipt Report
        SaveVendorPaymentReceipt(GenJournalLine);

        // [THEN] 'NegPmtDiscInvCurrVendLedgEntry1' = Payment Discount LCY = "D"
        // [THEN] 'NegPmtTolInvCurrVendLedgEntry1' = Payment Tolerance LCY = "T"
        // [THEN] 'NegOriginalAmt_VendLedgEntry' = Payment Amount LCY = "P"
        // [THEN] 'NegRemainingAmt' Payment Amount Not Allocated LCY = Payment Remaining Amount LCY
        // Verify: Verify Different fields data on Saved Report.
        VerifyVendorPaymentReceiptReport(DocumentNo, GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPaymentReceipt')]
    [Scope('OnPrem')]
    procedure VendorPaymentReceiptFCYPaymentLCYInvoice()
    var
        GenJournalLine: Record "Gen. Journal Line";
        DocumentNo: Code[20];
    begin
        // [FEATURE] [Vendor - Payment Receipt]
        // [SCENARIO 371840] Vendor Payment Receipt Report for payment with LCY, invoice in FCY
        Initialize();

        // [GIVEN] Purchase Invoice in FCY with Payment Discount LCY = "D", Payment Tolerance LCY = "T"
        // [GIVEN] Applied Payment in LCY with Amount LCY = "P" > Invoice Amount
        DocumentNo :=
          SetupAndPostVendorPmtTolerance(
            GenJournalLine,
            LibraryERM.CreateCurrencyWithExchangeRate(
              WorkDate(), LibraryRandom.RandIntInRange(2, 4), LibraryRandom.RandIntInRange(2, 4)));

        // [WHEN] Run Vendor Payment Receipt Report
        SaveVendorPaymentReceipt(GenJournalLine);

        // [THEN] 'NegPmtDiscInvCurrVendLedgEntry1' = Payment Discount LCY = "D"
        // [THEN] 'NegPmtTolInvCurrVendLedgEntry1' = Payment Tolerance LCY = "T"
        // [THEN] 'NegOriginalAmt_VendLedgEntry' = Payment Amount LCY = "P"
        // [THEN] 'NegRemainingAmt' Payment Amount Not Allocated LCY = Payment Remaining Amount LCY
        VerifyVendorPaymentReceiptReport(DocumentNo, GenJournalLine."Document No.", GenJournalLine.Amount);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SummaryAgingNoOption()
    var
        VendorSummaryAging: Report "Vendor - Summary Aging";
    begin
        // Check Vendor Summary Aging Report without any option selected.

        // Setup.
        Initialize();

        // Exercise: Try to Save Vendor Summary Aging without any option.
        Clear(VendorSummaryAging);
        VendorSummaryAging.InitializeRequest(0D, '', false);
        asserterror VendorSummaryAging.SaveAsExcel('Test');

        // Verify: Verify Error raised during save Vendor Summary Aging Report.
        Assert.ExpectedError(UndefinedDateErr);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorSummaryAging')]
    [Scope('OnPrem')]
    procedure SummaryAgingPostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Vendor Summary Aging Report with Posting Date.

        // Setup: Post Invoice Entry for Vendor on WORKDATE.
        Initialize();
        CreatePostGeneralJournalLine(GenJournalLine, LibraryPurchase.CreateVendorNo(), '', '0D');

        // Exercise: Save Vendor Summary Aging Report with Posting Date.
        SaveVendorSummaryAging(GenJournalLine."Account No.", GenJournalLine."Posting Date", Format(0D), false);

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalVendAmtDueLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('VendBalanceDueLCY_1_', 0);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorSummaryAging')]
    [Scope('OnPrem')]
    procedure SummaryAgingPeriodLength()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Vendor Summary Aging Report with Period Length.

        // Setup: Post Invoice Entry for Vendor on WORKDATE.
        Initialize();
        CreatePostGeneralJournalLine(GenJournalLine, LibraryPurchase.CreateVendorNo(), '', '0D');

        // Save and Verify Vendor Summary Aging Report with Period Length.
        SaveAndVerifySummaryAging(GenJournalLine, false);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorSummaryAging')]
    [Scope('OnPrem')]
    procedure SummaryAgingCurrency()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Vendor Summary Aging Report with Currency.

        // Setup: Post Invoice Entry for Vendor on WORKDATE with Currency Attached.
        Initialize();
        CreatePostGeneralJournalLine(GenJournalLine, LibraryPurchase.CreateVendorNo(), CreateCurrencyAndExchangeRate(), '0D');

        // Save and Verify Vendor Summary Aging Report with Currency.
        SaveAndVerifySummaryAging(GenJournalLine, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderSummaryNoOption()
    var
        VendorOrderSummary: Report "Vendor - Order Summary";
    begin
        // Check Vendor Order Summary Report with out any Option Selected.

        // Setup.
        Initialize();

        // Exercise: Try to Save Vendor Summary Aging without any option.
        Clear(VendorOrderSummary);
        asserterror VendorOrderSummary.SaveAsExcel('Test');

        // Verify: Verify Error raised during save Vendor Order Summary Report.
        Assert.ExpectedError(UndefinedDateErr);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderSummary')]
    [Scope('OnPrem')]
    procedure OrderSummaryPostingDate()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        AmountOnOrder2: Variant;
        OrderAmount: Variant;
    begin
        // Check Vendor Order Summary Report with Posting Date

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', '', '');
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Exercise: Save Vendor Order Summary without Currency.
        SaveVendorOrderSummary(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", false);

        // Verify: Verify Saved Report Data with Customized Formula.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PurchAmtOnOrder3', 0);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('PurchAmtOnOrder2', AmountOnOrder2);
        Assert.AreNearlyEqual(AmountOnOrder2, PurchaseLine."Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, 'Total', PurchaseLine."Line Amount"));
        LibraryReportDataset.FindCurrentRowValue('PurchOrderAmount', OrderAmount);
        Assert.AreNearlyEqual(OrderAmount, PurchaseLine."Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(ValidationErr, 'Total (LCY)', PurchaseLine."Line Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderSummary')]
    [Scope('OnPrem')]
    procedure OrderSummaryCurrency()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Currency: Record Currency;
        ActualAmountLCY: Variant;
        ActualAmountOnOrder2: Variant;
        AmountLCY: Decimal;
    begin
        // Check Vendor Order Summary Report with Currency.

        // Setup: Create Purchase Document with Currency.
        Initialize();
        LibraryERM.FindCurrency(Currency);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, Currency.Code, '', '');
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        AmountLCY := Round(LibraryERM.ConvertCurrency(PurchaseLine."Line Amount", Currency.Code, '', PurchaseHeader."Posting Date"));

        // Exercise: Save Vendor Order Summary with Currency.
        SaveVendorOrderSummary(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", true);

        // Verify: Verify Saved Report Data with Customized Formula.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PurchAmtOnOrder3', 0);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('PurchAmtOnOrder2', ActualAmountOnOrder2);
        Assert.AreNearlyEqual(ActualAmountOnOrder2, PurchaseLine."Line Amount", LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(MustBeEqualErr, PurchaseLine."Line Amount", 'Total'));
        LibraryReportDataset.FindCurrentRowValue('PurchOrderAmountLCY', ActualAmountLCY);
        Assert.AreNearlyEqual(ActualAmountLCY, AmountLCY, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(MustBeEqualErr, AmountLCY, 'Total (LCY)'));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderDetail')]
    [Scope('OnPrem')]
    procedure OrderDetailReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ActualOutstandingOrders: Variant;
    begin
        // Check Vendor Order Detail Report with default option.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), '');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // Exercise: Save Vendor Order Details Report with option Amount LCY FALSE.
        SaveOrderDetailReport(PurchaseHeader."Buy-from Vendor No.", false);

        // Verify: Verify Report values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('PurchOrderHeaderNo', PurchaseHeader."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(NoDatasetRowErr, 'PurchOrderHeaderNo', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_PurchaseLine', PurchaseLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstandingQty_PurchLine', PurchaseLine."Outstanding Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals('DirectUnitCost_PurchLine', PurchaseLine."Direct Unit Cost");
        LibraryReportDataset.FindCurrentRowValue('PurchOrderAmount', ActualOutstandingOrders);
        Assert.AreNearlyEqual(PurchaseLine."Outstanding Amt. Ex. VAT (LCY)", ActualOutstandingOrders, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(MustBeEqualErr, PurchaseLine."Outstanding Amt. Ex. VAT (LCY)", 'Outstanding Orders'));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderDetail')]
    [Scope('OnPrem')]
    procedure OrderDetailReportAmountLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ActualOutstandingOrders: Variant;
    begin
        // Check Vendor Order Detail Report with Amount LCY.

        // Setup.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateCurrencyAndExchangeRate(), CreateItem(), '');
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        // Exercise: Save Vendor Order Details Report with option Amount LCY TRUE.
        SaveOrderDetailReport(PurchaseHeader."Buy-from Vendor No.", true);

        // Verify: Verify Report values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('PurchOrderHeaderNo', PurchaseHeader."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(NoDatasetRowErr, 'PurchOrderHeaderNo', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_PurchaseLine', PurchaseLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('OutstandingQty_PurchLine', PurchaseLine."Outstanding Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals('DirectUnitCost_PurchLine', PurchaseLine."Unit Cost (LCY)");
        LibraryReportDataset.FindCurrentRowValue('PurchOrderAmount', ActualOutstandingOrders);
        Assert.AreNearlyEqual(PurchaseLine."Outstanding Amt. Ex. VAT (LCY)", ActualOutstandingOrders, LibraryERM.GetAmountRoundingPrecision(),
          StrSubstNo(MustBeEqualErr, PurchaseLine."Outstanding Amt. Ex. VAT (LCY)", 'Outstanding Orders'));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalance()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedInvoiceNo: Code[20];
    begin
        // Check Vendor Detail Trial Balance Report.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', CreateItem(), '');
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Vendor Detail Trial Balance Report with default option.
        SaveVendorDetailTrialBalReport(PurchaseHeader."Buy-from Vendor No.", false, false, WorkDate());

        // Verify: Verify Report all different values.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        VendorLedgerEntry.CalcFields(Amount, "Remaining Amount");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendAmount', VendorLedgerEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('VendRemainAmount', VendorLedgerEntry."Remaining Amount");
        LibraryReportDataset.AssertElementWithValueExists('VendBalanceLCY', VendorLedgerEntry.Amount);
        LibraryReportDataset.AssertElementWithValueExists('EntryNo_VendorLedgerEntry', VendorLedgerEntry."Entry No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceAmountLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PostedInvoiceNo: Code[20];
    begin
        // Check Vendor Detail Trial Balance Report for LCY fields.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', CreateItem(), '');
        PostedInvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Vendor Detail Trial Balance Report with option Show Amount in LCY = TRUE.
        SaveVendorDetailTrialBalReport(PurchaseHeader."Buy-from Vendor No.", true, false, WorkDate());

        // Verify: Verify LCY fields.
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, PostedInvoiceNo);
        VendorLedgerEntry.CalcFields("Amount (LCY)", "Remaining Amt. (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendAmount', VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('VendRemainAmount', VendorLedgerEntry."Remaining Amt. (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('VendBalanceLCY', VendorLedgerEntry."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('DocNo_VendLedgerEntry', VendorLedgerEntry."Document No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceExclBalance()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Check Vendor Detail Trial Balance Report for Option Exclude Vendors That Have a Balance Only.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Save Vendor Detail Trial Balance Report with option Exclude Vendor Balance Only = TRUE.
        // Using Random for Random Date.
        SaveVendorDetailTrialBalReport(
          PurchaseHeader."Buy-from Vendor No.", false, true, CalcDate('<' + Format(LibraryRandom.RandInt(2)) + 'M>', WorkDate()));

        // Verify: Verify Error in Detail Trial Balance Report when Exclude G/L Account that have Balance Only.
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists('', DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorItemCatalog')]
    [Scope('OnPrem')]
    procedure VendorItemCatalog()
    var
        ItemVendor: Record "Item Vendor";
        PurchasePrice: Record "Purchase Price";
        Vendor: Record Vendor;
    begin
        // Check Vendor Item Catalog report.

        // Setup.
        Initialize();
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchasePrice(PurchasePrice, Vendor."No.");
        CreateItemVendor(ItemVendor, PurchasePrice."Item No.", Vendor."No.");

        // Exercise: Save Vendor Item Catalog Report.
        SaveVendorItemCatalog(Vendor."No.");

        // Verify: Verify all fields of Item Catalog Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('StartingDt_PurchPrice', Format(PurchasePrice."Starting Date"));
        LibraryReportDataset.AssertElementWithValueExists('DrctUnitCost_PurchPrice', PurchasePrice."Direct Unit Cost");
        LibraryReportDataset.AssertElementWithValueExists('ItemVendLeadTimeCal', Format(ItemVendor."Lead Time Calculation"));
        LibraryReportDataset.AssertElementWithValueExists('ItemVendVendorItemNo', ItemVendor."Vendor Item No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseList')]
    [Scope('OnPrem')]
    procedure PurchaseListShowAddress()
    begin
        // Create New Vendor and verify Vendor Address showing while Hide Address detail = FALSE on Request page.
        Initialize();
        VendorPurchaseList(false);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseList')]
    [Scope('OnPrem')]
    procedure PurchaseListHideAddress()
    begin
        // Create New Vendor and verify whether Vendor Address not showing while Hide Address detail = TRUE on Request page.
        Initialize();
        asserterror VendorPurchaseList(true);
        Assert.ExpectedError('No row found');
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseList')]
    [Scope('OnPrem')]
    procedure PurchaseListAmountLCY()
    begin
        // Verify Vendor Purchase List Report include only those entry where Purchase Amount is greater than 0.
        Initialize();
        asserterror VendorPurchaseListAmountLCY(0.1);  // Using 0.1 because Report generate only for greater then O Amount Entry.
        Assert.ExpectedError('No row found');
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseList')]
    [Scope('OnPrem')]
    procedure PurchaseListIncludeZeroAmount()
    begin
        // Verify Vendor Purchase List Report include all entries.
        Initialize();
        VendorPurchaseListAmountLCY(0);  // Using 0 because Report generate for all entries including O Amount.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateNoOption()
    var
        VendorBalanceToDate: Report "Vendor - Balance to Date";
    begin
        // Check Vendor Balance To Date without any option selected.

        // Setup.
        Initialize();
        Clear(VendorBalanceToDate);
        VendorBalanceToDate.InitializeRequest(false, false, false);

        // Exercise: Try to Save Vendor Balance to Date Report.
        asserterror VendorBalanceToDate.SaveAsExcel('Test');

        // Verify: Verify Error which is Raised during Save without any option selected.
        Assert.AssertNoFilter();
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateVendorNo()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Check Vendor Balance To Date with Vendor No.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Original Amount");

        // Save and Verify Vendor Balance to Date Report.
        SaveVendorBalanceToDate(PurchaseHeader, false, false, false);
        VerifyVendorBalanceToDate(PurchaseHeader."Buy-from Vendor No.", DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntry."Original Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateFCY()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Check Vendor Balance To Date with Currency.

        // Setup.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateCurrencyAndExchangeRate(), CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Original Amount");

        // Save and Verify Report Vendor Balance to Date.
        SaveVendorBalanceToDate(PurchaseHeader, false, false, false);
        VerifyVendorBalanceToDate(PurchaseHeader."Buy-from Vendor No.", DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('CurrTotalBufferCurrCode', PurchaseHeader."Currency Code");
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntry."Original Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateAmountLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        ElementValue: Variant;
        ReportOriginalAmt: Decimal;
        DocumentNo: Code[20];
    begin
        // Check Vendor Balance To Date with Currency.

        // Setup.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateCurrencyAndExchangeRate(), CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);
        VendorLedgerEntry.CalcFields("Original Amt. (LCY)");

        // Save and Verify Report Vendor Balance to Date.
        SaveVendorBalanceToDate(PurchaseHeader, true, false, false);
        VerifyVendorBalanceToDate(PurchaseHeader."Buy-from Vendor No.", DocumentNo);
        LibraryReportDataset.MoveToRow(1);
        LibraryReportDataset.GetElementValueInCurrentRow('OriginalAmt', ElementValue);
        Evaluate(ReportOriginalAmt, Format(ElementValue));
        VendorLedgerEntry.TestField("Original Amt. (LCY)", ReportOriginalAmt);

        asserterror LibraryReportDataset.AssertElementWithValueExists('', PurchaseHeader."Currency Code");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateUnapplied()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        AutoFormat: Codeunit "Auto Format";
        DocumentNo: Code[20];
        LineAmount: Decimal;
    begin
        // Check Vendor Balance To Date with Unapplied Entries.

        // Setup.
        Initialize();
        LineAmount := CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Apply Posted Invoice. Take Less Line Amount for Payment.
        ApplyPaymentFromGenJournalLine(GenJournalLine, PurchaseHeader."Buy-from Vendor No.", LineAmount / 2, DocumentNo);

        // Save and Verify Report Vendor Balance to Date.
        SaveVendorBalanceToDate(PurchaseHeader, false, true, false);
        VerifyVendorBalanceToDate(PurchaseHeader."Buy-from Vendor No.", DocumentNo);
        LibraryReportDataset.AssertElementWithValueExists('DocType_DtldVendLedEnt', Format(GenJournalLine."Document Type"));
        LibraryReportDataset.AssertElementWithValueExists('Amt', Format(Round(LineAmount / 2), 0,
            AutoFormat.ResolveAutoFormat("Auto Format"::AmountFormat, GenJournalLine."Currency Code")));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsError()
    var
        PurchaseStatistics: Report "Purchase Statistics";
        PeriodLength: DateFormula;
    begin
        // Check Error Message on Purchase Statistics Report with Blank Period Length and Starting Date.

        // Setup.
        Initialize();
        Clear(PurchaseStatistics);
        Evaluate(PeriodLength, '');  // Make Period Length Blank.

        // Exercise: Take Blank Starting Date and Period Length.
        asserterror PurchaseStatistics.InitializeRequest(PeriodLength, 0D);

        // Verify: Verify Error Message appeared.
        Assert.ExpectedError(UndefinedDateErr);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseStatistics')]
    [Scope('OnPrem')]
    procedure PurchaseStatistics()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Counter: Integer;
        Amount: array[5] of Decimal;
        VendorNo: Code[20];
    begin
        // Check Purchase Statistics Report with Data in all columns.

        // Setup: Post Invoice Entry for Vendor on different Posting Dates to populate data in all columns.
        Initialize();
        VendorNo := CreateAndUpdateVendor();
        for Counter := 1 to 5 do begin
            CreatePostGeneralJournalLine(GenJournalLine, VendorNo, '', '<-' + Format(Counter) + 'M>');
            Amount[Counter] := -GenJournalLine.Amount;
        end;

        // Exercise: Take Starting Date less than WORKDATE and Save Purchase Statistics Report.
        SavePurchaseStatistics(GenJournalLine."Account No.", CalcDate('<-' + Format(Counter) + 'M>', WorkDate()));

        // Verify: Verify Amounts in the Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendPurchLCY_5_', Amount[1]);
        LibraryReportDataset.AssertElementWithValueExists('VendPurchLCY_4_', Amount[2]);
        LibraryReportDataset.AssertElementWithValueExists('VendPurchLCY_3_', Amount[3]);
        LibraryReportDataset.AssertElementWithValueExists('VendPurchLCY_2_', Amount[4]);
        LibraryReportDataset.AssertElementWithValueExists('VendPurchLCY_1_', Amount[5]);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseStatistics')]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsInvDiscount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Check Invoice Discount on Purchase Statistics Report.

        // Setup: Create and Post Purchase Order after calculating Invoice Discount.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), CreateAndUpdateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Take Starting Date as WORKDATE and Save Purchase Statistics Report.
        SavePurchaseStatistics(PurchaseHeader."Buy-from Vendor No.", WorkDate());

        // Verify: Verify Invoice Discount Amount.
        Vendor.Get(PurchaseHeader."Buy-from Vendor No.");
        Vendor.CalcFields("Inv. Discounts (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendInvDiscAmountLCY_1_', Vendor."Inv. Discounts (LCY)");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseStatistics')]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPmtDiscount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Vendor: Record Vendor;
    begin
        // Check Payment Discount on Purchase Statistics Report.

        // Setup:  Create and Post Purchase order for Vendor and Make a Payment for it.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), CreateAndUpdateVendor());
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Payment, PurchaseHeader."Buy-from Vendor No.", PurchaseLine."Line Amount");
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // Exercise: Take Starting Date as WORKDATE and Save Purchase Statistics Report.
        SavePurchaseStatistics(PurchaseHeader."Buy-from Vendor No.", WorkDate());

        // Verify: Verify Payment Discount Amount.
        Vendor.Get(GenJournalLine."Account No.");
        Vendor.CalcFields("Pmt. Discounts (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendPaymentDiscLCY_1_', Vendor."Pmt. Discounts (LCY)");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorPurchaseStatistics')]
    [Scope('OnPrem')]
    procedure PurchaseStatisticsPmtTolerance()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Vendor: Record Vendor;
    begin
        // Check Payment tolerance on Purchase Statistics Report.

        // Setup.
        Initialize();
        SetupAndPostVendorPmtTolerance(GenJournalLine, '');

        // Exercise.
        SavePurchaseStatistics(GenJournalLine."Account No.", WorkDate());

        // Verify: Verify Payment Tolerance Amount.
        Vendor.Get(GenJournalLine."Account No.");
        Vendor.CalcFields("Pmt. Tolerance (LCY)");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendPaymentTolLcy_1_', Vendor."Pmt. Tolerance (LCY)");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerAgedAccountPayable')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableDueDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
        Counter: Integer;
        VendorNo: Code[20];
        Amount: array[5] of Decimal;
    begin
        // Check Aged Accounts Payable Report with Aging By Due Date option.

        // Setup: Create Vendor and Post Multiple General Journal Lines with Custom Posting Dates.
        Initialize();
        VendorNo := CreateAndUpdateVendor();
        for Counter := 1 to 5 do begin
            CreatePostGeneralJournalLine(GenJournalLine, VendorNo, '', '<-' + Format(Counter - 1) + 'M>');
            Amount[Counter] := GenJournalLine.Amount;
        end;

        // Exercise: Save Aged Accounts Payable Report with Aging By Due Date option.
        SaveAgedAccountsPayable(VendorNo, AgingBy::"Due Date", false, false, HeadingType::"Date Interval");

        // Verify: Verify Report Data for all columns.
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.AssertElementWithValueExists('SelectAgeByDuePostngDocDt', StrSubstNo(AgedBy, Format(AgingBy::"Due Date")));
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE1RemAmtLCY', Amount[1]);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE2RemAmtLCY', Amount[2]);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE3RemAmtLCY', Amount[3]);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE4RemAmtLCY', Amount[4]);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE5RemAmtLCY', Amount[5]);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerAgedAccountPayable')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayablePostingDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Aged Accounts Payable Report with Aging By Posting Date option.

        // Setup: Create and Post General Journal Lines for Vendor. Save Report with Aging By: Document Date.
        Initialize();
        SetupSaveAgedAccountsPayable(GenJournalLine, '', AgingBy::"Posting Date", false, false, HeadingType::"Date Interval");

        // Verify: Verify Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AgedVendLedgEnt2RemAmtLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE2RemAmtLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('SelectAgeByDuePostngDocDt',
          StrSubstNo(AgedBy, Format(AgingBy::"Posting Date")));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerAgedAccountPayable')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableDocDate()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Aged Accounts Payable Report with Aging By Document Date option.

        // Setup: Create and Post General Journal Lines for Vendor. Save Report with Aging By: Document Date.
        Initialize();
        SetupSaveAgedAccountsPayable(GenJournalLine, '', AgingBy::"Document Date", false, false, HeadingType::"Date Interval");

        // Verify: Verify Values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AgedVendLedgEnt2RemAmtLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE2RemAmtLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('SelectAgeByDuePostngDocDt',
          StrSubstNo(AgedBy, Format(AgingBy::"Document Date")));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerAgedAccountPayable')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableAmountLCY()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Aged Accounts Payable Report with Print Amounts in LCY option TRUE.

        // Setup: Post Invoice with Currency for Vendor. Save Report with Print Amounts in LCY option TRUE.
        Initialize();
        SetupSaveAgedAccountsPayable(
          GenJournalLine, CreateCurrencyAndExchangeRate(), AgingBy::"Due Date", true, false, HeadingType::"Date Interval");

        // Verify: Verify Report Values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AgedVendLedgEnt2RemAmtLCY', GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE2RemAmtLCY', GenJournalLine."Amount (LCY)");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerAgedAccountPayable')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayablePrintDetail()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Aged Accounts Payable Report with Print Details option TRUE.

        // Setup: Create Currency and Post General Journal Lines using it. Save Aged Accounts Payable Report with Print Details TRUE.
        Initialize();
        SetupSaveAgedAccountsPayable(
          GenJournalLine, CreateCurrencyAndExchangeRate(), AgingBy::"Due Date", false, true, HeadingType::"Date Interval");

        // Verify: Verify Report Values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AgedVendLedgEnt2RemAmt', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('GrandTotalVLE2RemAmtLCY', GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('TempCurrency2Code', GenJournalLine."Currency Code");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerAgedAccountPayable')]
    [Scope('OnPrem')]
    procedure AgedAccountsPayableHeadingType()
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // Check Aged Accounts Payable Report with Heading Type: Number of Days option.

        // Setup: Create and Post General Journal Lines for Vendor. Save Aged Accounts Payable Report with Heading Type= Number of Days.
        Initialize();
        GeneralLedgerSetup.Get();
        SetupSaveAgedAccountsPayable(GenJournalLine, '', AgingBy::"Due Date", false, false, HeadingType::"Number of Days");

        // Verify: Verify Values.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendLedgEntryEndingDtAmt', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('VLEEndingDateRemAmtLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('AgedVendLedgEnt2RemAmtLCY', GenJournalLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('CurrCode_TempVenLedgEntryLoop', GeneralLedgerSetup."LCY Code");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerBlanketPurchaseOrder')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrder()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Blanket Purchase Order Report.

        // Setup:
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', CreateItem(), '');
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Exercise: Save Blanket Purchase Order Report withount any option selected.
        SaveBlanketPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Document Type", false, false);

        // Verify:
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Quantity_PurchLine', PurchaseLine.Quantity);
        LibraryReportDataset.AssertElementWithValueExists('UOM_PurchLine', PurchaseLine."Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerBlanketPurchaseOrder')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        DefaultDimension: Record "Default Dimension";
    begin
        // Check Dimension Value after saving Blanket Purchase Order Report.

        // Setup.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', DefaultDimension."No.", '');

        // Exercise: Save Blanket Purchase Order Report with Show Internal Information TRUE.
        SaveBlanketPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Document Type", true, false);

        // Verify: Verify Dimension on Blanket Purchase Order.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText1',
              StrSubstNo(DimensionValueTxt, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerBlanketPurchaseOrder')]
    [Scope('OnPrem')]
    procedure BlanketPurchaseOrderLogEntry()
    var
        PurchaseHeader: Record "Purchase Header";
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        // Check Interaction Log Entry after saving Blanket Purchase Order Report.

        // Setup.
        Initialize();
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Blanket Order", '', CreateItem(), '');

        // Exercise: Save Blanket Purchase Order Report with Log Interaction TRUE.
        SaveBlanketPurchaseOrder(PurchaseHeader."No.", PurchaseHeader."Document Type", false, true);

        // Verify.
        VerifyInteractionLogEntry(InteractionLogEntry."Document Type"::"Purch. Blnkt. Ord.", PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,ReportHandlerPurchaseReturnShipment')]
    [Scope('OnPrem')]
    procedure UndoPurchRetShptReportWithCorrectionLine()
    var
        PurchaseLine: Record "Purchase Line";
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        // Verify Purchase Return Shipment Report after undo Return Shipment with Show Correction Lines.

        // Setup: Create Purchase Return Order, post and undo Purchase Return Shipment.
        Initialize();
        CreateAndPostPurchaseDocument(PurchaseLine, PurchaseLine."Document Type"::"Return Order");
        FindReturnShipmentLine(ReturnShipmentLine, PurchaseLine."No.");
        LibraryVariableStorage.Enqueue(UndoPurchRetOrderMsg);  // Enqueue value for ConfirmHandler.
        UndoReturnShipment(PurchaseLine."No.");

        // Exercise.
        SavePurchaseRetShipment(ReturnShipmentLine."Document No.");

        // Verify: Verify Purchase Return Shipment Report with Show Correction Line.
        VerifyPurchRtnShipReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('SuggestVendorPaymentsWithAvailableAmtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentforCreditMemoLine()
    var
        Vendor: Record Vendor;
        GenJournalLine: Record "Gen. Journal Line";
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalTemplate: Record "Gen. Journal Template";
        Amount: Decimal;
    begin
        // Verify that general journal line exists with credit memo after running the suggest vendor payment report.

        // Setup: Create and post general journal line with document type invoice and credit memo.
        Initialize();
        Amount := LibraryRandom.RandIntInRange(10, 50);
        LibraryPurchase.CreateVendor(Vendor);
        CreateGeneralJournalBatch(GenJournalBatch, GenJournalTemplate.Type::General);
        CreateGeneralJurnlLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.",
          GenJournalLine."Document Type"::Invoice, -(Amount + LibraryRandom.RandIntInRange(10, 50)));
        CreateGeneralJurnlLine(GenJournalLine, GenJournalBatch, WorkDate(), Vendor."No.",
          GenJournalLine."Document Type"::"Credit Memo", Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        LibraryVariableStorage.Enqueue(Vendor."No.");

        // Exercise: Run report suggest vendor payment
        SuggestVendorPaymentUsingPage(GenJournalLine);

        // Verify: Verifying that general journal line exist with credit memo.
        VerifyGenJnlLineWithCreditMemo(GenJournalLine, -Amount);
    end;

    [Test]
    [HandlerFunctions('PurchaseQuoteRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckLinesonPurchaseQuoteReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify that purchase quote report shows line where type is blank.

        // Setup: Create purchase quote with type blank.
        Initialize();
        CreatePurchaseQuoteWithMultipleLine(PurchaseHeader);
        LibraryVariableStorage.Enqueue(PurchaseHeader."No.");

        // Exercise: Run Purchase-Quote report.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Purchase - Quote", true, false, PurchaseHeader);

        // Verify: Verifying that both line exists on report.
        LibraryReportValidation.DownloadFile();
        LibraryReportValidation.OpenFile();
        LibraryReportValidation.SetRange(PurchaseLine.FieldCaption(Description), PurchaseHeader."No.");
        Assert.AreEqual(2, LibraryReportValidation.CountRows(), NumberOfRowsErr);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderSummary')]
    [Scope('OnPrem')]
    procedure VendorOrderSummaryWithDurationAmount()
    var
        VendorNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Setup: Create a Vendor, create one Purchase Order with two Lines.
        Initialize();
        CreatePurchaseOrderWithTwoLines(VendorNo, ExpectedAmount);

        // Exercise: Generate the Vendor Order Summary report.
        SaveVendorOrderSummary(VendorNo, WorkDate(), false);

        // Verify: verify Total showed corretly on Vendor Order Summary report.
        VerifyAmountOnVendorOrderSummaryReport(VendorNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderSummary')]
    [Scope('OnPrem')]
    procedure VendorOrderSummaryWithReleasedDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        VendorNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Setup: Create a Vendor, create one Purchase Order with two Lines.
        Initialize();
        CreatePurchaseOrderWithTwoLines(VendorNo, ExpectedAmount);

        // Release Purchase Order.
        ReleasePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);

        // Exercise: Generate the Vendor Order Summary report.
        SaveVendorOrderSummary(VendorNo, WorkDate(), false);

        // Verify: verify Total showed corretly on Vendor Order Summary report.
        VerifyAmountOnVendorOrderSummaryReport(VendorNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderDetail')]
    [Scope('OnPrem')]
    procedure VendorOrderDetailWithReleasedDocument()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        ExpectedAmount: Decimal;
    begin
        // Setup: Create a Vendor, create one Purchase Order with two Lines.
        Initialize();
        CreatePurchaseOrderWithTwoLines(VendorNo, ExpectedAmount);

        // Release Purchase Order.
        ReleasePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);

        // Exercise: Generate the Vendor Order Detail report.
        SaveOrderDetailReport(VendorNo, false);

        // Verify: Verify Outstanding Orders and Total showed corretly on Vendor Order Detail report.
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
        VerifyOutstandingOrdersAndTotalOnVendorOrderDetailReport(PurchaseLine, VendorNo, ExpectedAmount);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateClosedEntryAppliedUnappliedAppliedOutOfPeriod()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378237] Vendor Balance To Date for Entry where unapplication and then application are out of Ending Date
        Initialize();

        // [GIVEN] Vendor with payment of Amount = 150
        MockVendorLedgerEntry(VendorLedgerEntry, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2), WorkDate());

        // [GIVEN] Closed Vendor Ledger Entry on 31.12.15 with Amount = -100
        // [GIVEN] Application dtld. vend. ledger entries of Amount = 100 applied on 31.12.15 and unapplied on 01.01.16
        // [GIVEN] Application dtld. vend. ledger entry with Amount = 100 on 01.01.16
        Amount := MockApplyUnapplyScenario(VendorLedgerEntry."Vendor No.", WorkDate(), WorkDate() + 1, WorkDate() + 1);

        // [WHEN] Save Vendor Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunVendorBalanceToDateWithVendor(VendorLedgerEntry."Vendor No.", false, WorkDate());

        // [THEN] Payment Entry of 150 is printed, -100 is not printed, Total Amount = 150
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 232772
        VerifyVendorBalanceToDateDoesNotExist(VendorLedgerEntry."Vendor No.", VendorLedgerEntry.Amount, Amount);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateClosedEntryAppliedUnappliedAppliedOutOfPeriodIncludeUnapplied()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378237] Vendor Balance To Date for closed Entry with zero balance inside period and application after Ending Date
        Initialize();

        // [GIVEN] Vendor with payment of Amount = 150
        MockVendorLedgerEntry(VendorLedgerEntry, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2), WorkDate());

        // [GIVEN] Closed Vendor Ledger Entry on 31.12.15 with Amount = -100
        // [GIVEN] Application dtld. vend. ledger entries of Amount = 100 applied on 31.12.15 and unapplied on 01.01.16
        // [GIVEN] Application dtld. vend. ledger entry with Amount = 100 on 01.01.16
        Amount := MockApplyUnapplyScenario(VendorLedgerEntry."Vendor No.", WorkDate(), WorkDate() + 1, WorkDate() + 1);

        // [WHEN] Save Vendor Balance To Data report on 31.12.15 with Include Unapplied Entries = Yes
        RunVendorBalanceToDateWithVendor(VendorLedgerEntry."Vendor No.", true, WorkDate());

        // [THEN] Payment Entry of 150 is printed, -100 is printed with 0 balance, Total Amount = 150
        // [THEN] Applied Entry (01.01.16) is not printed
        VerifyVendorBalanceToDateTwoEntriesExist(
          VendorLedgerEntry."Vendor No.", VendorLedgerEntry.Amount, Amount, VendorLedgerEntry.Amount);
        // [THEN] Applied Entry (31.12.15) is printed. Initial TFSID 232772
        LibraryReportDataset.AssertElementWithValueNotExist('PostDate_DtldVendLedEnt', Format(WorkDate() + 1));
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateClosedEntryAppliedInPeriodUnappliedAppliedOutOfPeriod()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        Amount: Decimal;
    begin
        // [SCENARIO 378848] Vendor Balance To Date for unapplied entry inside period and application after Ending Date
        Initialize();

        // [GIVEN] Vendor with payment of Amount = 150
        MockVendorLedgerEntry(VendorLedgerEntry, LibraryPurchase.CreateVendorNo(), LibraryRandom.RandDec(100, 2), WorkDate());

        // [GIVEN] Closed Vendor Ledger Entry on 31.12.15 with Amount = -100
        // [GIVEN] Application dtld. vend. ledger entries of Amount = 100 applied on 31.12.15 and unapplied on 31.12.15
        // [GIVEN] Application dtld. vend. ledger entry with Amount = 100 on 01.01.16
        Amount := MockApplyUnapplyScenario(VendorLedgerEntry."Vendor No.", WorkDate(), WorkDate(), WorkDate() + 1);

        // [WHEN] Save Vendor Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunVendorBalanceToDateWithVendor(VendorLedgerEntry."Vendor No.", false, WorkDate());

        // [THEN] Payment Entry of 150 is printed, -100 is printed, Total Amount = 50
        // [THEN] Applied Entry (01.01.16) of 100 is not printed. Initial TFSID 232772
        VerifyVendorBalanceToDateTwoEntriesExist(
          VendorLedgerEntry."Vendor No.", VendorLedgerEntry.Amount, Amount, VendorLedgerEntry.Amount + Amount);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateClosedEntryWithinPeriod()
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        PmtAmount: Decimal;
    begin
        // [SCENARIO 211599] Vendor Balance To Date for closed Entry inside period
        Initialize();

        // [GIVEN] Vendor with payment of Amount = 150
        PmtAmount := -LibraryRandom.RandDec(100, 2);
        MockVendorLedgerEntry(VendorLedgerEntry, LibraryPurchase.CreateVendorNo(), PmtAmount, WorkDate());

        // [GIVEN] Closed Vendor Ledger Entry on 30.12.15 with Amount = -100

        MockVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Vendor No.", LibraryRandom.RandDec(100, 2), WorkDate() - 1);

        // [GIVEN] Application dtld. vend. ledger entry with Amount = 100 on 31.12.15
        MockDtldVendLedgEntry(VendorLedgerEntry."Vendor No.", VendorLedgerEntry."Entry No.", -VendorLedgerEntry.Amount, false, WorkDate());
        UpdateOpenOnVendLedgerEntry(VendorLedgerEntry."Entry No.");

        // [WHEN] Save Vendor Balance To Data report on 31.12.15 with Include Unapplied Entries = No
        RunVendorBalanceToDateWithVendor(VendorLedgerEntry."Vendor No.", false, WorkDate());

        // [THEN] Payment Entry of 150 is printed, -100 is not printed, Total Amount = 150
        VerifyVendorBalanceToDateDoesNotExist(VendorLedgerEntry."Vendor No.", PmtAmount, VendorLedgerEntry.Amount);
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalance_EntryNoCaption()
    begin
        // [FEATURE] [Vendor] [Detail Trial Balance]
        // [SCENARIO 379230] REP 304 "Vendor - Detail Trial Balance" prints "Entry No." column caption
        Initialize();

        // [WHEN] Run REP 304 "Vendor - Detail Trial Balance"
        SaveVendorDetailTrialBalReport(LibraryPurchase.CreateVendorNo(), false, false, WorkDate());

        // [THEN] "Entry No." column caption is shown
        LibraryReportDataset.LoadParametersFile();
        LibraryReportDataset.AssertParameterValueExists('EntryNo_VendorLedgerEntryCaption', 'Entry No.');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedPurchaseOrderReportWithPricesInclVATAndTwoLines()
    var
        VATPostingSetup: array[2] of Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        TotalBaseAmount: Decimal;
        TotalVATAmount: Decimal;
    begin
        // [FEATURE] [Archive] [Prices Incl. VAT] [Order]
        // [SCENARIO 381574] Report 416 "Archived Purchase Order" correctly prints total vat base/amount in case of "Prices Including VAT" = TRUE and two lines with different VAT Setup
        Initialize();

        // [GIVEN] Purchase order with "Prices Including VAT" = TRUE, two lines with different VAT Setup
        CreatePurchaseOrderWithTwoVATSetupLines(VATPostingSetup, PurchaseHeader, TotalBaseAmount, TotalVATAmount);
        // [GIVEN] Archive purchase order
        ArchivePurchaseDocument(PurchaseHeader);

        // [WHEN] Print archived purchase order (REP 416 "Archived Purchase Order")
        RunArchivedPurchaseOrderReport(PurchaseHeader);

        // [THEN] Report correctly prints total VAT Amount and Total VAT Base Amount
        VerifyArchiveDocExcelTotalVATBaseAmount('AJ', 52, TotalVATAmount, TotalBaseAmount);

        // Tear Down
        VATPostingSetup[1].Delete(true);
        VATPostingSetup[2].Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedPurchaseOrderReportInCaseOfInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvDiscountAmount: Decimal;
    begin
        // [FEATURE] [Archive] [Invoice Discount] [Order]
        // [SCENARIO 201417] Report 416 "Archived Purchase Order" correctly prints totals in case of Invoice Discount
        Initialize();

        // [GIVEN] Purchase Order with "Line Amount" = 1000, "Invoice Discount Amount" = 200, "VAT %" = 25
        CreatePurchaseDocWithItemAndVATSetup(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Order);
        InvDiscountAmount := Round(PurchaseLine.Amount / 3);
        ApplyInvDiscBasedOnAmt(PurchaseHeader, InvDiscountAmount);
        // [GIVEN] Archive the purchase order
        ArchivePurchaseDocument(PurchaseHeader);

        // [WHEN] Print archived purchase order (REP 416 "Archived Purchase Order")
        RunArchivedPurchaseOrderReport(PurchaseHeader);

        // [THEN] Subtotal Amount = 1000, Invoice Discount Amount = -200, Total Excl. VAT = 800, VAT Amount = 200, Total Incl. VAT = 1000
        PurchaseLine.Find();
        VerifyArchiveOrderExcelTotalsWithDiscount(
          'AJ', 49, PurchaseLine."Line Amount", InvDiscountAmount, PurchaseLine."VAT Base Amount",
          PurchaseLine."Amount Including VAT" - PurchaseLine.Amount, PurchaseLine."Amount Including VAT");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ArchivedPurchaseReturnOrderReportInCaseOfInvoiceDiscountAmount()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        InvDiscountAmount: Decimal;
    begin
        // [FEATURE] [Archive] [Invoice Discount] [Return Order]
        // [SCENARIO 201417] Report 417 "Arch.Purch. Return Order" correctly prints totals in case of Invoice Discount
        Initialize();

        // [GIVEN] Purchase Return Order with "Line Amount" = 1000, "Invoice Discount Amount" = 200, "VAT %" = 25
        CreatePurchaseDocWithItemAndVATSetup(PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Return Order");
        InvDiscountAmount := Round(PurchaseLine.Amount / 3);
        ApplyInvDiscBasedOnAmt(PurchaseHeader, InvDiscountAmount);
        // [GIVEN] Archive the purchase return order
        ArchivePurchaseDocument(PurchaseHeader);

        // [WHEN] Print archived purchase rturn order (REP 417 "Arch.Purch. Return Order")
        RunArchivedPurchaseReturnOrderReport(PurchaseHeader);

        // [THEN] Subtotal Amount = 1000, Invoice Discount Amount = -200, Total = 800
        PurchaseLine.Find();
        VerifyArchiveRetOrderExcelTotalsWithDiscount(
          'AC', 49, PurchaseLine."Line Amount", InvDiscountAmount, PurchaseLine."VAT Base Amount");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorDetailTrialBalance')]
    [Scope('OnPrem')]
    procedure DetailTrialBalanceExtDocNo()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Detail Trial Balance]
        // [SCENARIO 262729] External Document No. is included in report Vendor - Detail Trial Balance.
        Initialize();

        // [GIVEN]
        CreateGeneralJournalLine(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, LibraryPurchase.CreateVendorNo(), -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("External Document No.", CopyStr(LibraryUtility.GenerateRandomXMLText(35), 1, 35));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [WHEN] Save Vendor Detail Trial Balance Report.
        SaveVendorDetailTrialBalReport(GenJournalLine."Account No.", false, false, WorkDate());

        // [THEN] Verify External Document No. on Detail Trial Balance Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ExtDocNo_VendLedgerEntry', GenJournalLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('VendorDetailTrialBalanceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceCorrOfRemainingAmount()
    var
        GenJournalLine: Record "Gen. Journal Line";
        CurrencyCode: Code[10];
        VendNo: Code[20];
        i: Integer;
    begin
        // [FEATURE] [Vendor - Detail Trial Bal.]
        // [SCENARIO 280971] "Correction of remaining amount" does not affect totals in Vendor - Detail Trial Bal. report

        Initialize();

        // [GIVEN] Currency with exchange rate 1 to 0.33333
        CurrencyCode := CreateCurrencyWithFixedExchRates(0.33333);

        // [GIVEN] Post two invoices with currency and amount = 1 (LCY Amount = 0.33)
        VendNo := LibraryPurchase.CreateVendorNo();
        for i := 1 to 2 do
            CreatePostGeneralJournalLineCustomDocTypeAndAmount(
              GenJournalLine, GenJournalLine."Document Type"::Invoice, VendNo, CurrencyCode, -1);

        // [GIVEN] Post payment with currency and amount = 2 (LCY Amount = 0.67)
        CreatePostGeneralJournalLineCustomDocTypeAndAmount(GenJournalLine, GenJournalLine."Document Type"::Payment, VendNo, CurrencyCode, 2);

        // [GIVEN] Applied payment to both invoices
        ApplyPaymentToAllOpenInvoices(GenJournalLine."Document No.", VendNo);

        // [GIVEN] Post invoice with currency and amount = 400 (LCY Amount = 133.33)
        CreatePostGeneralJournalLineCustomDocTypeAndAmount(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, VendNo, CurrencyCode, -LibraryRandom.RandDec(100, 2));

        // [WHEN] Generate the Vendor Detail Trial Balance Report.
        RunDtldVendTrialBalanceReportWithDateFilter(GenJournalLine."Account No.");

        // [THEN] Verify start balance is zero and vendor balance is 133.33
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(31, 7, Format(GenJournalLine."Amount (LCY)", 0, 9));
        LibraryReportValidation.VerifyCellValue(31, 9, Format(GenJournalLine."Amount (LCY)", 0, 9));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorOrderSummaryExcel')]
    [Scope('OnPrem')]
    procedure VendorOrderSummaryMultipleCurrencies()
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        CurrencyCode: array[2] of Code[10];
        Amount: array[2] of Decimal;
        I: Integer;
    begin
        // [FEATURE] [Vendor Order Summary]
        // [SCENARIO 286863] Vendor Order Summary splits lines for orders in different currencies
        Initialize();

        // [GIVEN] Created Vendor
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Currency "CUR01" with Exchange Rate created
        // [GIVEN] Purchase Order "SO01" for Vendor with Amount = 100 in Currency "CUR01"
        // [GIVEN] Currency "CUR02" with Exchange Rate created
        // [GIVEN] Purchase Order "SO02" for Vendor with Amount = 200 in Currency "CUR02"
        for I := 1 to ArrayLen(CurrencyCode) do begin
            CurrencyCode[I] := CreateCurrencyAndExchangeRate();
            Amount[I] :=
              CreatePurchaseDocument(
                PurchaseHeader,
                PurchaseHeader."Document Type"::Order,
                CurrencyCode[I],
                LibraryInventory.CreateItemNo(),
                Vendor."No.");
        end;

        // [WHEN] Run Report "Vendor Order Summary" for Vendor
        LibraryReportValidation.SetFileName(Vendor."No.");
        SaveVendorOrderSummary(Vendor."No.", WorkDate(), false);

        // [THEN] Amount = 100 for Currency "CUR01"
        // [THEN] Amount = 200 for Currency "CUR02"
        VerifyMultipleCurrencyAmountsOnVendorOrderSummaryReport(CurrencyCode, Amount);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceReportWithPuchaseLineWithDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 306140] There is no error in calculating Total VAT Amount in report "Purchase - Invoice" when Dimensions are applied to purchase line.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Invoice with "Prices Including VAT" set to TRUE and a Purchase Line with Direct Unit Cost "110", VAT % "10", Quantity "2"
        // [GIVEN] Purchase Line has Dimension Set with enough Dimensions to fill more than one line in Report "Purchase - Invoice".
        CreatePurchaseDocWithDimensions(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::Invoice, LibraryRandom.RandInt(100));

        // [GIVEN] Purchase Invoice is posted.
        PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Report "Purchase - Invoice" is run with "Show Internal Information" set to TRUE.
        PurchInvHeader.SetRecFilter();
        REPORT.Run(REPORT::"Purchase - Invoice", true, true, PurchInvHeader);

        // [THEN] In resulting file cell with Total VAT Amount is equal to 20.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(86, 33, Format(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / (100 + PurchaseLine."VAT %"))));
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportWithPuchaseLineWithDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 306140] There is no error in calculating Total VAT Amount in report "Purchase - Credit Memo" when Dimensions are applied to purchase line.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Credit Memo with "Prices Including VAT" set to TRUE and a Purchase Line with Direct Unit Cost "110", VAT % "10", Quantity "2"
        // [GIVEN] Purchase Line has Dimension Set with enough Dimensions to fill more than one line in Report "Purchase - Credit Memo".
        CreatePurchaseDocWithDimensions(
          PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandInt(100));

        // [GIVEN] Purchase Credit Memo is posted.
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Report "Purchase - Credit Memo" is run with "Show Internal Information" set to TRUE.
        PurchCrMemoHdr.SetRecFilter();
        REPORT.Run(REPORT::"Purchase - Credit Memo", true, true, PurchCrMemoHdr);

        // [THEN] In resulting file cell with Total VAT Amount is equal to 20.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(42, 29, Format(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * PurchaseLine."VAT %" / (100 + PurchaseLine."VAT %"))));
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDateUseExternalDocNo')]
    procedure VendorBalanceToDateVendorLedgerEntryDocumentNumber()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RefVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 285509] Vendor Balance To Date prints Document No. for not applied entry when Use External Document No. = No
        Initialize();

        // [GIVEN] Create and post invoice for vendor "VEND" with "Document No." = "DOCNO"
        CreateAndPostPurchaseInvoice(PurchInvHeader);

        // [WHEN] Vendor Balance To Date report is being printed for vendor "VEND" with Use External Document No. = No
        RunVendorBalanceToDateWithUseExternalDocNo(PurchInvHeader."Buy-from Vendor No.", false);

        // [THEN] Vendor ledger entry printed with "Document No." = "DOCNO"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocNo_VendLedgEntry3', PurchInvHeader."No.");
        LibraryReportDataset.AssertElementWithValueExists('DocNoCaption', RefVendorLedgerEntry.FieldCaption("Document No."));
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDateUseExternalDocNo')]
    procedure VendorBalanceToDateDtldVendorLedgerEntryDocumentNumber()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 285509] Vendor Balance To Date prints Document No. for partly applied entry when Use External Document No. = No
        Initialize();

        // [GIVEN] Create and post invoice for vendor "VEND" with "Document No." = "DOCNO"
        CreateAndPostPurchaseInvoice(PurchInvHeader);

        // [GIVEN] Create and post partial payment applied to invoice with "Document No." = "PAYNO"
        CreateAndApplyPartialPayment(GenJnlLine, PurchInvHeader);

        // [WHEN] Vendor Balance To Date report is being printed for vendor "VEND" with Use External Document No. = No
        RunVendorBalanceToDateWithUseExternalDocNo(PurchInvHeader."Buy-from Vendor No.", false);

        // [THEN] Detailed vendor ledger entry printed with "Document No." = "PAYNO"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocNo_DtldVendLedgEntry', GenJnlLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDateUseExternalDocNo')]
    procedure VendorBalanceToDateVendorLedgerEntryExternalDocumentNumber()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RefVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 285509] Vendor Balance To Date prints External Document No. for not applied entry when Use External Document No. = Yes
        Initialize();

        // [GIVEN] Create and post invoice for vendor "VEND" with "External Document No." = "EXTDOCNO"
        CreateAndPostPurchaseInvoice(PurchInvHeader);

        // [WHEN] Vendor Balance To Date report is being printed for vendor "VEND" with Use External Document No. = Yes
        RunVendorBalanceToDateWithUseExternalDocNo(PurchInvHeader."Buy-from Vendor No.", true);

        // [THEN] Vendor ledger entry printed with "External Document No." = "EXTDOCNO"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocNo_VendLedgEntry3', PurchInvHeader."Vendor Invoice No.");
        LibraryReportDataset.AssertElementWithValueExists('DocNoCaption', RefVendorLedgerEntry.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDateUseExternalDocNo')]
    procedure VendorBalanceToDateDtldVendorLedgerEntryExternalDocumentNumber()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        GenJnlLine: Record "Gen. Journal Line";
    begin
        // [SCENARIO 285509] Vendor Balance To Date prints External Document No. for partly applied entry when Use External Document No. = Yes
        Initialize();

        // [GIVEN] Create and post invoice for vendor "VEND" with "Document No." = "DOCNO"
        CreateAndPostPurchaseInvoice(PurchInvHeader);

        // [GIVEN] Create and post partial payment applied to invoice with "External Document No." = "EXTPAYNO"
        CreateAndApplyPartialPayment(GenJnlLine, PurchInvHeader);

        // [WHEN] Vendor Balance To Date report is being printed for vendor "VEND" with Use External Document No. = Yes
        RunVendorBalanceToDateWithUseExternalDocNo(PurchInvHeader."Buy-from Vendor No.", true);

        // [THEN] Detailed vendor ledger entry printed with "External Document No." = "EXTPAYNO"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocNo_DtldVendLedgEntry', GenJnlLine."External Document No.");
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateMultipleCurrenciesWithTheSameAmount()
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        VendorLedgerEntryInvoice: Record "Vendor Ledger Entry";
        VendorLedgerEntryCrMemo: Record "Vendor Ledger Entry";
        InvoiceDocumentNo: Code[20];
        CrMemoDocumentNo: Code[20];
        Amount: Decimal;
        ItemsCount: Integer;
    begin
        // [SCENARIO 341358] Check Vendor Balance To Date with two lines with the same Amount in different Currency

        Initialize();
        ItemsCount := LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] Created Purchase Credit Memo with Currency for Vendor
        CreatePurchaseDocumentWithAmount(
          PurchaseHeaderCrMemo,
          PurchaseHeaderCrMemo."Document Type"::"Credit Memo",
          CreateCurrencyAndExchangeRate(),
          CreateItem(),
          LibraryPurchase.CreateVendorNo(),
          Amount,
          ItemsCount);
        CrMemoDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, true);

        // [GIVEN] Created Purchase Invoice for Vendor
        CreatePurchaseDocumentWithAmount(
          PurchaseHeaderInvoice,
          PurchaseHeaderInvoice."Document Type"::Invoice,
          '',
          CreateItem(),
          PurchaseHeaderCrMemo."Buy-from Vendor No.",
          Amount,
          ItemsCount);
        InvoiceDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [GIVEN] Found Vendor Ledger Entries for created Documents
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryInvoice, VendorLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryCrMemo, VendorLedgerEntryCrMemo."Document Type"::"Credit Memo", CrMemoDocumentNo);
        VendorLedgerEntryCrMemo.CalcFields("Original Amount");
        VendorLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN]  Save Report "Vendor Balance to Date".
        SaveVendorBalanceToDate(PurchaseHeaderCrMemo, false, false, false);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Original Amount was filled correctly
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntryCrMemo."Original Amount"));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntryInvoice."Original Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateMultipleCurrenciesWithTheSameAmountWithShowEntriesWithZeroBalance()
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        VendorLedgerEntryInvoice: Record "Vendor Ledger Entry";
        VendorLedgerEntryCrMemo: Record "Vendor Ledger Entry";
        InvoiceDocumentNo: Code[20];
        CrMemoDocumentNo: Code[20];
        Amount: Decimal;
        ItemsCount: Integer;
    begin
        // [SCENARIO 341358] Check Vendor Balance To Date with two lines with the same Amount in different Currency

        Initialize();
        ItemsCount := LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] Created Purchase Credit Memo with Currency for Vendor
        CreatePurchaseDocumentWithAmount(
          PurchaseHeaderCrMemo,
          PurchaseHeaderCrMemo."Document Type"::"Credit Memo",
          CreateCurrencyAndExchangeRate(),
          CreateItem(),
          LibraryPurchase.CreateVendorNo(),
          Amount,
          ItemsCount);
        CrMemoDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, true);

        // [GIVEN] Created Purchase Invoice for Vendor
        CreatePurchaseDocumentWithAmount(
          PurchaseHeaderInvoice,
          PurchaseHeaderInvoice."Document Type"::Invoice,
          '',
          CreateItem(),
          PurchaseHeaderCrMemo."Buy-from Vendor No.",
          Amount,
          ItemsCount);
        InvoiceDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [GIVEN] Found Vendor Ledger Entries for created Documents
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryInvoice, VendorLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryCrMemo, VendorLedgerEntryCrMemo."Document Type"::"Credit Memo", CrMemoDocumentNo);
        VendorLedgerEntryCrMemo.CalcFields("Original Amount");
        VendorLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN]  Run Report "Vendor Balance to Date" with Show Entries with Zero Balance = 'No'
        SaveVendorBalanceToDate(PurchaseHeaderCrMemo, false, false, true);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Original Amount was filled correctly
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntryCrMemo."Original Amount"));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntryInvoice."Original Amount"));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateWithTheSameAmountSkipReport()
    var
        PurchaseHeaderCrMemo: Record "Purchase Header";
        PurchaseHeaderInvoice: Record "Purchase Header";
        VendorLedgerEntryInvoice: Record "Vendor Ledger Entry";
        VendorLedgerEntryCrMemo: Record "Vendor Ledger Entry";
        InvoiceDocumentNo: Code[20];
        CrMemoDocumentNo: Code[20];
        Amount: Decimal;
        ItemsCount: Integer;
    begin
        // [SCENARIO 341358] Check Vendor Balance To Date with two lines skip with the same Amount

        Initialize();
        ItemsCount := LibraryRandom.RandInt(10);
        Amount := LibraryRandom.RandDecInRange(100, 1000, 2);

        // [GIVEN] Created Purchase Credit Memo for Vendor
        CreatePurchaseDocumentWithAmount(
          PurchaseHeaderCrMemo,
          PurchaseHeaderCrMemo."Document Type"::"Credit Memo",
          '',
          CreateItem(),
          LibraryPurchase.CreateVendorNo(),
          Amount,
          ItemsCount);
        CrMemoDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderCrMemo, true, true);

        // [GIVEN] Created Purchase Invoice for Vendor
        CreatePurchaseDocumentWithAmount(
          PurchaseHeaderInvoice,
          PurchaseHeaderInvoice."Document Type"::Invoice,
          '',
          CreateItem(),
          PurchaseHeaderCrMemo."Buy-from Vendor No.",
          Amount,
          ItemsCount);
        InvoiceDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [GIVEN] Found Vendor Ledger Entries for created Documents
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryInvoice, VendorLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        LibraryERM.FindVendorLedgerEntry(
          VendorLedgerEntryCrMemo, VendorLedgerEntryCrMemo."Document Type"::"Credit Memo", CrMemoDocumentNo);
        VendorLedgerEntryCrMemo.CalcFields("Original Amount");
        VendorLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN]  Save Report "Vendor Balance to Date".
        SaveVendorBalanceToDate(PurchaseHeaderCrMemo, false, false, false);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Documents are not exported
        LibraryReportDataset.AssertElementTagWithValueNotExist('DocNo_VendLedgEntry', VendorLedgerEntryCrMemo."Document No.");
        LibraryReportDataset.AssertElementTagWithValueNotExist('DocNo_VendLedgEntry', VendorLedgerEntryInvoice."Document No.");
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoReportTotalAmountExclVATWithPuchaseLineWithDimensions()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // [FEATURE] [Dimensions]
        // [SCENARIO 386412] There is no error in calculating Total Amount Excluding VAT in report "Purchase - Credit Memo" when Dimensions are applied to purchase line.
        Initialize();
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());

        // [GIVEN] Purchase Credit Memo with "Prices Including VAT" set to TRUE and a Purchase Line with Direct Unit Cost "110", Quantity "2", VAT % "10".
        // [GIVEN] Purchase Line has Dimension Set with enough Dimensions to fill more than one line in Report "Purchase - Credit Memo".
        CreatePurchaseDocWithDimensions(
            PurchaseHeader, PurchaseLine, PurchaseHeader."Document Type"::"Credit Memo", LibraryRandom.RandInt(100));

        // [GIVEN] Purchase Credit Memo is posted.
        PurchCrMemoHdr.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true));

        // [WHEN] Report "Purchase - Credit Memo" is run with "Show Internal Information" set to TRUE.
        PurchCrMemoHdr.SetRecFilter();
        REPORT.Run(REPORT::"Purchase - Credit Memo", true, true, PurchCrMemoHdr);

        // [THEN] In resulting file cell with Total Amount Excluding VAT is equal to 200.
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.CheckIfValueExistsInSpecifiedColumn('AA', Format(Round(PurchaseLine.Quantity * PurchaseLine."Direct Unit Cost" * 100 / (100 + PurchaseLine."VAT %"))));
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDateUseExternalDocNo')]
    procedure VerifyVendorBalanceToDateVendorLedgerEntryWithExternalDocumentNumber()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
        RefVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // [SCENARIO 448068] Vendor Balance To Date prints External Document No. for not applied entry when Use External Document No. = Yes
        Initialize();

        // [GIVEN] Create and post invoice for vendor "VEND" with "External Document No." = "EXTDOCNO"
        CreateAndPostPurchaseInvoice(PurchInvHeader);

        // [WHEN] Vendor Balance To Date report is being printed for vendor "VEND" with Use External Document No. = Yes
        RunVendorBalanceToDateWithUseExternalDocNo(PurchInvHeader."Buy-from Vendor No.", true);

        // [THEN] Vendor ledger entry printed with "External Document No." = "EXTDOCNO"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocNo_VendLedgEntry3', PurchInvHeader."Vendor Invoice No.");
        LibraryReportDataset.AssertElementWithValueExists('DocNoCaption', RefVendorLedgerEntry.FieldCaption("External Document No."));
    end;

    [Test]
    [HandlerFunctions('ReportHandlerVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateForZeroAmountInvoiceWithShowEntriesWithZeroBalance()
    var
        PurchaseHeaderInvoice: Record "Purchase Header";
        VendorLedgerEntryInvoice: Record "Vendor Ledger Entry";
        InvoiceDocumentNo: Code[20];
    begin
        // [SCENARIO 442479] Check Vendor Balance To Date for zero amount invoice
        Initialize();

        // [GIVEN] Create Purchase Invoice with GL and Amount will be 0.
        CreatePurchaseDocumentWithZeroAmount(PurchaseHeaderInvoice, PurchaseHeaderInvoice."Document Type"::Invoice, '', LibraryPurchase.CreateVendorNo());

        // [THEN] Post Purchase Invoice of 0 amount
        InvoiceDocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeaderInvoice, true, true);

        // [GIVEN] Found Vendor Ledger Entries for created Documents
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntryInvoice, VendorLedgerEntryInvoice."Document Type"::Invoice, InvoiceDocumentNo);
        VendorLedgerEntryInvoice.CalcFields("Original Amount");

        // [WHEN]  Save Report "Vendor Balance to Date". for Show Entrie with Zero Balancce = true
        SaveVendorBalanceToDate(PurchaseHeaderInvoice, false, false, true);

        // [THEN] Report was created
        LibraryReportDataset.LoadDataSetFile();

        // [VERIFY] Original Amount was filled correctly
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(VendorLedgerEntryInvoice."Original Amount"));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purch. Doc. Reports");
        LibraryVariableStorage.Clear();
        Clear(LibraryReportValidation);
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purch. Doc. Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateLocalData();
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purch. Doc. Reports");
    end;

    local procedure ApplyPaymentFromGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; Amount: Decimal; DocumentNo: Code[20])
    begin
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Payment, VendorNo, Amount);
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", DocumentNo);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure ClearGenJournalLine(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure CreateTwoVATPostingSetups(var VATPostingSetup: array[2] of Record "VAT Posting Setup")
    var
        DummyGLAccount: Record "G/L Account";
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup[1], VATPostingSetup[1]."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        DummyGLAccount."VAT Bus. Posting Group" := VATPostingSetup[1]."VAT Bus. Posting Group";
        DummyGLAccount."VAT Prod. Posting Group" := VATPostingSetup[1]."VAT Prod. Posting Group";
        VATPostingSetup[2].Get(
          VATPostingSetup[1]."VAT Bus. Posting Group",
          LibraryERM.CreateRelatedVATPostingSetup(DummyGLAccount));
    end;

    local procedure CreatePurchaseDocWithDimensions(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DirectUnitCost: Integer)
    var
        DimVal: Record "Dimension Value";
        DimSetID: Integer;
        i: Integer;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, LibraryPurchase.CreateVendorNo());
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, '', LibraryRandom.RandInt(10));
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);

        DimSetID := PurchaseLine."Dimension Set ID";
        for i := 1 to 3 do begin
            LibraryDimension.CreateDimWithDimValue(DimVal);
            DimSetID := LibraryDimension.CreateDimSet(DimSetID, DimVal."Dimension Code", DimVal.Code);
        end;
        PurchaseLine.Validate("Dimension Set ID", DimSetID);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithTwoVATSetupLines(var VATPostingSetup: array[2] of Record "VAT Posting Setup"; var PurchaseHeader: Record "Purchase Header"; var TotalBaseAmount: Decimal; var TotalVATAmount: Decimal)
    var
        GLAccount: Record "G/L Account";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        CreateTwoVATPostingSetups(VATPostingSetup);
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup[1]."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Prices Including VAT", true);
        PurchaseHeader.Modify(true);

        for i := 1 to ArrayLen(VATPostingSetup) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
              LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup[i], GLAccount."Gen. Posting Type"::Purchase), 1);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
            PurchaseLine.Modify(true);
            TotalBaseAmount += PurchaseLine.Amount;
            TotalVATAmount += PurchaseLine."Amount Including VAT" - PurchaseLine.Amount;
        end;
    end;

    local procedure CreatePurchaseDocWithItemAndVATSetup(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        VATPostingSetup: Record "VAT Posting Setup";
        GeneralPostingSetup: Record "General Posting Setup";
        Item: Record Item;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        LibraryERM.FindGeneralPostingSetup(GeneralPostingSetup);
        LibraryInventory.CreateItemWithPostingSetup(
          Item, GeneralPostingSetup."Gen. Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");

        CreatePurchaseDocument(
          PurchaseHeader, DocumentType, '', Item."No.",
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    local procedure CreateAndPostPurchaseDocument(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, '', CreateItem(), '');
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");
    end;

    local procedure CreateAndPostPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header")
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, '', CreateItem(), '');
        PurchInvHeader.get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false));
    end;

    local procedure CreateAndApplyPartialPayment(var GenJournalLine: Record "Gen. Journal Line"; PurchInvHeader: Record "Purch. Inv. Header")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        CreatePaymentsJournalBatch(GenJournalBatch);
        PurchInvHeader.CalcFields("Amount Including VAT");
        LibraryERM.CreateGeneralJnlLine(
            GenJournalLine,
            GenJournalBatch."Journal Template Name",
            GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment,
            GenJournalLine."Account Type"::Vendor,
            PurchInvHeader."Buy-from Vendor No.",
            round(PurchInvHeader."Amount Including VAT" / 2));
        GenJournalLine.Validate("External Document No.",
            LibraryUtility.GenerateRandomCode(
                GenJournalLine.FieldNo("External Document No."),
                Database::"Gen. Journal Line"));
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", PurchInvHeader."No.");
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePaymentsJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Payments);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
        GenJournalBatch.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalBatch.Modify(true);
    end;

    local procedure CreateAndUpdateVendor(): Code[20]
    var
        PaymentTerms: Record "Payment Terms";
        Vendor: Record Vendor;
    begin
        LibraryERM.GetDiscountPaymentTerm(PaymentTerms);
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", PaymentTerms.Code);
        Vendor.Validate("Invoice Disc. Code", CreateVendorInvoiceDiscount(Vendor."No."));
        Vendor.Validate("Application Method", Vendor."Application Method"::"Apply to Oldest");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCurrencyAndExchangeRate(): Code[10]
    var
        Currency: Record Currency;
        LibraryERM: Codeunit "Library - ERM";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; DocumentType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        ClearGenJournalLine(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
    end;

    local procedure CreateItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Last Direct Cost", LibraryRandom.RandDec(100, 2));   // Using RANDOM value for Last Direct Cost.
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; ItemNo: Code[20]; VendorNo: Code[20])
    begin
        // Using Random value for Lead Time Calculation.
        LibraryInventory.CreateItemVendor(ItemVendor, VendorNo, ItemNo);
        ItemVendor.Validate(
          "Vendor Item No.", LibraryUtility.GenerateRandomCode(ItemVendor.FieldNo("Vendor Item No."), DATABASE::"Item Vendor"));
        Evaluate(ItemVendor."Lead Time Calculation", '<' + Format(LibraryRandom.RandInt(5)) + 'D>');
        ItemVendor.Modify(true);
    end;

    local procedure CreateItemWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, CreateItem(), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreatePaymentTerms(): Code[10]
    var
        PaymentTerms: Record "Payment Terms";
    begin
        // Take Random Values of Discount %.
        LibraryERM.CreatePaymentTerms(PaymentTerms);
        PaymentTerms.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        PaymentTerms.Validate("Calc. Pmt. Disc. on Cr. Memos", true);
        PaymentTerms.Modify(true);
        exit(PaymentTerms.Code);
    end;

    local procedure CreatePostGeneralJournalLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; CurrencyCode: Code[10]; DateInterval: Text[10])
    var
        PeriodDifference: DateFormula;
    begin
        // Create and Post General Journal Lines with Random Amount and Updated Custom Posting Date.
        Evaluate(PeriodDifference, DateInterval);
        CreateGeneralJournalLine(GenJournalLine, GenJournalLine."Document Type"::Invoice, VendorNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Validate("Posting Date", CalcDate(PeriodDifference, GenJournalLine."Posting Date"));
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePostGeneralJournalLineCustomDocTypeAndAmount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; VendorNo: Code[20]; CurrencyCode: Code[10]; Amount: Decimal)
    begin
        CreateGeneralJournalLine(GenJournalLine, DocType, VendorNo, Amount);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; ItemNo: Code[20]; VendorNo: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Document with Random Quantity and Direct Unit Cost for Item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Use Random Value.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
        PurchaseLine.Modify(true);
        exit(PurchaseLine."Line Amount");
    end;

    local procedure CreatePurchaseDocumentWithAmount(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; ItemNo: Code[20]; VendorNo: Code[20]; DirectUnitCost: Decimal; ItemQuantity: Integer)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseDocument(PurchaseHeader, DocumentType, CurrencyCode, ItemNo, VendorNo);
        FindPurchaseLine(PurchaseLine, DocumentType, PurchaseHeader."No.");
        PurchaseLine.Validate(Quantity, ItemQuantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithTwoLines(var VendorNo: Code[20]; var ExpectedAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine1: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        DirectUnitCost: Decimal;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        VendorNo := PurchaseHeader."Buy-from Vendor No.";

        // Generate a number with Second decimal places is 3 or 4.
        // Outstanding Orders = Line Amount Incl. VAT(##0.00) / (1 + VAT%).
        // Total((##0.00)) = Round(Sum(Line Amount Incl. VAT / (1 + VAT%))
        // Using hardcode of Quantity to let the third decimal places of Line Amount Incl. VAT can be truncated when calculating Outstanding Orders.
        // So when verify Total = Sum(Outstanding Orders) after creating two Purchase Lines, the issue can be Reproduced.
        DirectUnitCost := LibraryRandom.RandDec(100, 1) + LibraryRandom.RandIntInRange(3, 4) / 100;
        CreatePurchaseLine(PurchaseHeader, PurchaseLine1, DirectUnitCost, 1);
        CreatePurchaseLine(PurchaseHeader, PurchaseLine2, DirectUnitCost, 1);
        ExpectedAmount := Round(PurchaseLine1.Amount * PurchaseLine1."Outstanding Quantity" / PurchaseLine1.Quantity) +
          Round(PurchaseLine2.Amount * PurchaseLine2."Outstanding Quantity" / PurchaseLine2.Quantity);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, CreateItem(), Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchasePrice(var PurchasePrice: Record "Purchase Price"; VendorNo: Code[20])
    var
        Item: Record Item;
        LibraryCosting: Codeunit "Library - Costing";
    begin
        Item.Get(CreateItem());
        LibraryCosting.CreatePurchasePrice(PurchasePrice, VendorNo, Item."No.", WorkDate(), '', '', Item."Base Unit of Measure", 0);
        PurchasePrice.Validate("Direct Unit Cost", Item."Last Direct Cost");
        PurchasePrice.Modify(true);
    end;

    local procedure CreatePurchaseQuoteWithMultipleLine(var PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Quote, '');
        PreparePurchLineWithBlankType(PurchaseLine, PurchaseHeader);
        AddPurchLine(PurchaseLine);
        AddPurchLine(PurchaseLine);
    end;

    local procedure CreateVendorInvoiceDiscount(VendorNo: Code[20]): Code[20]
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
    begin
        // Take blank Currency and Random Minimum Amount and Integer Discount Percent. Integer Value important for test.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, VendorNo, '', LibraryRandom.RandDec(5, 2));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(5, 2));
        VendorInvoiceDisc.Modify(true);
        exit(VendorInvoiceDisc.Code);
    end;

    local procedure CreateVendorWithPmtTerms(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Payment Terms Code", CreatePaymentTerms());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateGeneralJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch"; Type: Enum "Gen. Journal Template Type")
    var
        GenJournalTemplate: Record "Gen. Journal Template";
    begin
        GenJournalTemplate.SetRange(Recurring, false);
        GenJournalTemplate.SetRange(Type, Type);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);
    end;

    local procedure CreateGeneralJurnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; PostingDate: Date; VendorNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; Amount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, VendorNo, Amount);
        GenJournalLine.Validate("Document No.", GenJournalBatch.Name + Format(GenJournalLine."Line No."));
        GenJournalLine.Validate("External Document No.", GenJournalLine."Document No.");
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Validate("Bal. Account Type", GenJournalLine."Bal. Account Type"::"G/L Account");
        GenJournalLine.Validate("Bal. Account No.", LibraryERM.CreateGLAccountNo());
        GenJournalLine.Modify(true);
    end;

    local procedure CreateCurrencyWithFixedExchRates(RelExchRateAmount: Decimal): Code[10]
    var
        Currency: Record Currency;
        CurrencyExchangeRate: Record "Currency Exchange Rate";
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.SetCurrencyGainLossAccounts(Currency);

        LibraryERM.CreateExchRate(CurrencyExchangeRate, Currency.Code, WorkDate());
        CurrencyExchangeRate.Validate("Exchange Rate Amount", 1);
        CurrencyExchangeRate.Validate("Adjustment Exch. Rate Amount", 1);
        CurrencyExchangeRate.Validate("Relational Exch. Rate Amount", RelExchRateAmount);
        CurrencyExchangeRate.Validate("Relational Adjmt Exch Rate Amt", RelExchRateAmount);
        CurrencyExchangeRate.Modify(true);
        exit(Currency.Code);
    end;

    local procedure AddPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Line No." := PurchaseLine."Line No." + 10000;
        PurchaseLine.Insert();
    end;

    local procedure ReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; VendorNo: Code[20])
    begin
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure ArchivePurchaseDocument(PurchaseHeader: Record "Purchase Header")
    var
        ArchiveManagement: Codeunit ArchiveManagement;
    begin
        ArchiveManagement.StorePurchDocument(PurchaseHeader, false);
    end;

    local procedure ApplyInvDiscBasedOnAmt(var PurchaseHeader: Record "Purchase Header"; InvDiscountAmount: Decimal)
    var
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
    begin
        PurchCalcDiscByType.ApplyInvDiscBasedOnAmt(InvDiscountAmount, PurchaseHeader);
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindReceiptLine(var PurchRcptLine: Record "Purch. Rcpt. Line"; No: Code[20])
    begin
        PurchRcptLine.SetRange("No.", No);
        PurchRcptLine.FindFirst();
    end;

    local procedure FindReturnShipmentLine(var ReturnShipmentLine: Record "Return Shipment Line"; No: Code[20])
    begin
        ReturnShipmentLine.SetRange("No.", No);
        ReturnShipmentLine.FindFirst();
    end;

    local procedure FindPurchaseHeaderArchive(var PurchaseHeaderArchive: Record "Purchase Header Archive"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseHeader."No.");
        PurchaseHeaderArchive.FindFirst();
    end;

    local procedure PreparePurchLineWithBlankType(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseLine.Init();
        PurchaseLine."Document Type" := PurchaseHeader."Document Type"::Quote;
        PurchaseLine."Document No." := PurchaseHeader."No.";
        PurchaseLine.Description := PurchaseHeader."No.";
    end;

    local procedure SuggestVendorPaymentUsingPage(var GenJournalLine: Record "Gen. Journal Line")
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        SuggestVendorPayments: Report "Suggest Vendor Payments";
    begin
        GenJournalBatch.SetFilter("No. Series", '<>%1', '');
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
        GenJournalLine.Init();  // INIT is mandatory for Gen. Journal Line to Set the General Template and General Batch Name.
        GenJournalLine.Validate("Journal Template Name", GenJournalBatch."Journal Template Name");
        GenJournalLine.Validate("Journal Batch Name", GenJournalBatch.Name);

        Commit();  // Commit required to avoid test failure.
        SuggestVendorPayments.SetGenJnlLine(GenJournalLine);
        SuggestVendorPayments.Run();
    end;

    local procedure MockApplyUnapplyScenario(VendorNo: Code[20]; ApplnDate1: Date; UnapplDate: Date; ApplnDate2: Date) Amount: Decimal
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        Amount := -LibraryRandom.RandDec(100, 2);
        MockVendorLedgerEntry(VendorLedgerEntry, VendorNo, Amount, WorkDate());
        MockDtldVendLedgEntry(VendorNo, VendorLedgerEntry."Entry No.", -Amount, true, ApplnDate1);
        MockDtldVendLedgEntry(VendorNo, VendorLedgerEntry."Entry No.", Amount, true, UnapplDate);
        MockDtldVendLedgEntry(VendorNo, VendorLedgerEntry."Entry No.", -Amount, false, ApplnDate2);
        UpdateOpenOnVendLedgerEntry(VendorLedgerEntry."Entry No.");
    end;

    local procedure MockVendorLedgerEntry(var VendorLedgerEntry: Record "Vendor Ledger Entry"; VendorNo: Code[20]; EntryAmount: Decimal; PostingDate: Date)
    begin
        VendorLedgerEntry.Init();
        VendorLedgerEntry."Entry No." := LibraryUtility.GetNewRecNo(VendorLedgerEntry, VendorLedgerEntry.FieldNo("Entry No."));
        VendorLedgerEntry."Vendor No." := VendorNo;
        VendorLedgerEntry."Posting Date" := PostingDate;
        VendorLedgerEntry.Amount := EntryAmount;
        VendorLedgerEntry.Open := true;
        VendorLedgerEntry.Insert();
        MockInitialDtldVendLedgEntry(VendorNo, VendorLedgerEntry."Entry No.", EntryAmount, PostingDate);
    end;

    local procedure MockInitialDtldVendLedgEntry(VendorNo: Code[20]; VendLedgEntryNo: Integer; EntryAmount: Decimal; PostingDate: Date)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        MockDtldVLE(
          DetailedVendorLedgEntry,
          VendorNo, VendLedgEntryNo, DetailedVendorLedgEntry."Entry Type"::"Initial Entry", EntryAmount, false, PostingDate);
    end;

    local procedure MockDtldVendLedgEntry(VendorNo: Code[20]; VendLedgEntryNo: Integer; EntryAmount: Decimal; UnappliedEntry: Boolean; PostingDate: Date)
    var
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        MockDtldVLE(
          DetailedVendorLedgEntry,
          VendorNo, VendLedgEntryNo, DetailedVendorLedgEntry."Entry Type"::Application, EntryAmount, UnappliedEntry, PostingDate);
    end;

    local procedure MockDtldVLE(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry"; VendorNo: Code[20]; VendLedgEntryNo: Integer; EntryType: Enum "Detailed CV Ledger Entry Type"; EntryAmount: Decimal; UnappliedEntry: Boolean; PostingDate: Date)
    begin
        DetailedVendorLedgEntry.Init();
        DetailedVendorLedgEntry."Entry No." := LibraryUtility.GetNewRecNo(DetailedVendorLedgEntry, DetailedVendorLedgEntry.FieldNo("Entry No."));
        DetailedVendorLedgEntry."Vendor No." := VendorNo;
        DetailedVendorLedgEntry."Entry Type" := EntryType;
        DetailedVendorLedgEntry."Posting Date" := PostingDate;
        DetailedVendorLedgEntry."Vendor Ledger Entry No." := VendLedgEntryNo;
        DetailedVendorLedgEntry.Amount := EntryAmount;
        DetailedVendorLedgEntry.Unapplied := UnappliedEntry;
        DetailedVendorLedgEntry.Insert();
    end;

    local procedure SaveAgedAccountsPayable(No: Code[20]; AgingBy: Option; PrintAmountLCY: Boolean; PrintDetails: Boolean; HeadingType: Option)
    var
        Vendor: Record Vendor;
        AgedAccountsPayable: Report "Aged Accounts Payable";
        DatePeriod: DateFormula;
    begin
        // Taking Date Period 1M to generate columns with One Month difference and New Page Per Vendor option as FALSE.
        LibraryVariableStorage.Enqueue(AgingBy);
        LibraryVariableStorage.Enqueue(PrintAmountLCY);
        LibraryVariableStorage.Enqueue(PrintDetails);
        LibraryVariableStorage.Enqueue(HeadingType);

        Clear(AgedAccountsPayable);
        Vendor.SetRange("No.", No);
        AgedAccountsPayable.SetTableView(Vendor);
        Evaluate(DatePeriod, '<1M>');
        AgedAccountsPayable.InitializeRequest(WorkDate(), AgingBy, DatePeriod, PrintAmountLCY, PrintDetails, HeadingType, false);
        AgedAccountsPayable.Run();
    end;

    local procedure SaveAndVerifySummaryAging(GenJournalLine: Record "Gen. Journal Line"; AmountLCY: Boolean)
    var
        DatePeriod: DateFormula;
    begin
        // Exercise: Save Vendor Summary Aging Report with Currency.
        Evaluate(DatePeriod, '<' + Format(LibraryRandom.RandInt(5)) + 'M>');
        SaveVendorSummaryAging(GenJournalLine."Account No.", GenJournalLine."Posting Date", Format(DatePeriod), AmountLCY);

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('TotalVendAmtDueLCY', GenJournalLine."Amount (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('VendBalanceDueLCY_3_', 0);
        LibraryReportDataset.AssertElementWithValueExists('TotalVendAmtDueLCY', GenJournalLine."Amount (LCY)");
    end;

    local procedure SaveBlanketPurchaseOrder(No: Code[20]; DocumentType: Enum "Purchase Document Type"; ShowInternalInfo: Boolean; LogInteraction: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        BlanketPurchaseOrder: Report "Blanket Purchase Order";
    begin
        Commit(); // Required to run report with request page.
        Clear(BlanketPurchaseOrder);
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("No.", No);
        BlanketPurchaseOrder.SetTableView(PurchaseHeader);
        BlanketPurchaseOrder.InitializeRequest(0, ShowInternalInfo, LogInteraction);  // Passing zero for No. of copies.
        BlanketPurchaseOrder.Run();
    end;

    local procedure SaveOrderDetailReport(No: Code[20]; ShowAmountInLCY: Boolean)
    var
        Vendor: Record Vendor;
        VendorOrderDetail: Report "Vendor - Order Detail";
    begin
        Commit(); // Required to run report with request page.
        Clear(VendorOrderDetail);
        Vendor.SetRange("No.", No);
        VendorOrderDetail.SetTableView(Vendor);
        VendorOrderDetail.InitializeRequest(ShowAmountInLCY, false);
        VendorOrderDetail.Run();
    end;

    local procedure SavePurchaseListReport(No: Code[20]; No2: Code[20]; MinAmtLCY: Decimal; HideAddress: Boolean)
    var
        Vendor: Record Vendor;
        VendorPurchaseList: Report "Vendor - Purchase List";
    begin
        LibraryVariableStorage.Enqueue(MinAmtLCY);
        LibraryVariableStorage.Enqueue(HideAddress);

        Commit(); // Required to run report with request page.
        Clear(VendorPurchaseList);
        Vendor.SetFilter("No.", '%1|%2', No, No2);
        VendorPurchaseList.SetTableView(Vendor);
        VendorPurchaseList.Run();
    end;

    local procedure SavePurchaseReceipt(No: Code[20]; ShowInternalInfo: Boolean; LogInteraction: Boolean; ShowCorrectionLine: Boolean)
    var
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchaseReceipt: Report "Purchase - Receipt";
    begin
        Commit(); // Required to run report with request page.
        Clear(PurchaseReceipt);
        PurchRcptHeader.SetRange("No.", No);
        PurchaseReceipt.SetTableView(PurchRcptHeader);
        PurchaseReceipt.InitializeRequest(0, ShowInternalInfo, LogInteraction, ShowCorrectionLine);
        PurchaseReceipt.Run();
    end;

    local procedure SavePurchaseRetShipment(No: Code[20])
    var
        ReturnShipmentHeader: Record "Return Shipment Header";
        PurchaseReturnShipment: Report "Purchase - Return Shipment";
    begin
        Commit(); // Required to run report with request page.
        Clear(PurchaseReturnShipment);
        ReturnShipmentHeader.SetRange("No.", No);
        PurchaseReturnShipment.SetTableView(ReturnShipmentHeader);
        PurchaseReturnShipment.InitializeRequest(0, false, true, false);
        PurchaseReturnShipment.Run();
    end;

    local procedure SavePurchaseStatistics(No: Code[20]; PostingDate: Date)
    var
        Vendor: Record Vendor;
        PurchaseStatistics: Report "Purchase Statistics";
        PeriodLength: DateFormula;
    begin
        Commit(); // Required to run report with request page.
        Evaluate(PeriodLength, '<1M>');  // Taking 1 Month as period length to gap Dates with 1 Month. Value required for test.
        Clear(PurchaseStatistics);
        Vendor.SetRange("No.", No);
        PurchaseStatistics.SetTableView(Vendor);
        PurchaseStatistics.InitializeRequest(PeriodLength, PostingDate);
        PurchaseStatistics.Run();
    end;

    local procedure SaveVendorDetailTrialBalReport(No: Code[20]; PrintAmountsInLCY: Boolean; ExcludeBalanceOnly: Boolean; PostingDate: Date)
    var
        Vendor: Record Vendor;
        VendorDetailTrialBalance: Report "Vendor - Detail Trial Balance";
    begin
        Commit(); // Required to run report with request page.
        Clear(VendorDetailTrialBalance);
        Vendor.SetRange("No.", No);
        Vendor.SetRange("Date Filter", PostingDate);
        VendorDetailTrialBalance.SetTableView(Vendor);
        VendorDetailTrialBalance.InitializeRequest(PrintAmountsInLCY, false, ExcludeBalanceOnly);  // Set FALSE for Print Only Per Page.
        VendorDetailTrialBalance.Run();
    end;

    local procedure SaveVendorItemCatalog(VendorNo: Code[20])
    var
        Vendor: Record Vendor;
        VendorItemCatalog: Report "Vendor Item Catalog";
    begin
        Commit();
        Clear(VendorItemCatalog);
        Vendor.SetRange("No.", VendorNo);
        VendorItemCatalog.SetTableView(Vendor);
        VendorItemCatalog.Run();
    end;

    local procedure SaveVendorOrderSummary(No: Code[20]; PostingDate: Date; AmountLCY: Boolean)
    var
        Vendor: Record Vendor;
        VendorOrderSummary: Report "Vendor - Order Summary";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(AmountLCY);

        Commit(); // Required to run report with request page.
        Clear(VendorOrderSummary);
        Vendor.SetRange("No.", No);
        VendorOrderSummary.SetTableView(Vendor);
        VendorOrderSummary.Run();
    end;

    local procedure SaveVendorPaymentReceipt(GenJournalLine: Record "Gen. Journal Line")
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        VendorPaymentReceipt: Report "Vendor - Payment Receipt";
    begin
        Commit(); // Required to run report with request page.
        Clear(VendorPaymentReceipt);
        VendorLedgerEntry.SetRange("Document Type", GenJournalLine."Document Type");
        VendorLedgerEntry.SetRange("Document No.", GenJournalLine."Document No.");
        VendorPaymentReceipt.SetTableView(VendorLedgerEntry);
        VendorPaymentReceipt.Run();
    end;

    local procedure SaveVendorSummaryAging(AccountNo: Code[20]; PostingDate: Date; DatePeriod: Text[10]; AmountLCY: Boolean)
    var
        Vendor: Record Vendor;
        VendorSummaryAging: Report "Vendor - Summary Aging";
    begin
        LibraryVariableStorage.Enqueue(PostingDate);
        LibraryVariableStorage.Enqueue(DatePeriod);
        LibraryVariableStorage.Enqueue(AmountLCY);

        Commit(); // Required to run report with request page.
        Clear(VendorSummaryAging);
        Vendor.SetRange("No.", AccountNo);
        VendorSummaryAging.SetTableView(Vendor);
        VendorSummaryAging.Run();
    end;

    local procedure SaveVendorBalanceToDate(PurchaseHeader: Record "Purchase Header"; AmountLCY: Boolean; Unapplied: Boolean; ShowEntriesWithZeroBalance: Boolean)
    var
        Vendor: Record Vendor;
        VendorBalanceToDate: Report "Vendor - Balance to Date";
    begin
        LibraryVariableStorage.Enqueue(AmountLCY);
        LibraryVariableStorage.Enqueue(Unapplied);
        LibraryVariableStorage.Enqueue(ShowEntriesWithZeroBalance);

        // Exercise.
        Commit(); // Required to run report with request page.
        Clear(VendorBalanceToDate);
        Vendor.SetRange("No.", PurchaseHeader."Buy-from Vendor No.");
        Vendor.SetRange("Date Filter", PurchaseHeader."Posting Date");
        VendorBalanceToDate.SetTableView(Vendor);
        VendorBalanceToDate.InitializeRequest(AmountLCY, false, Unapplied);
        VendorBalanceToDate.Run();
    end;

    local procedure RunVendorBalanceToDateWithVendor(VendorNo: Code[20]; Unapplied: Boolean; EndingDate: Date)
    var
        Vendor: Record Vendor;
        VendorBalanceToDate: Report "Vendor - Balance to Date";
    begin
        Commit();
        Clear(VendorBalanceToDate);
        Vendor.SetRange("No.", VendorNo);
        Vendor.SetRange("Date Filter", EndingDate);
        VendorBalanceToDate.SetTableView(Vendor);
        VendorBalanceToDate.InitializeRequest(false, false, Unapplied);
        VendorBalanceToDate.Run();
    end;

    local procedure RunVendorBalanceToDateWithUseExternalDocNo(VendorNo: Code[20]; UseExternalDocNo: Boolean)
    var
        Vendor: Record Vendor;
        VendorBalanceToDate: Report "Vendor - Balance to Date";
    begin
        Commit();
        LibraryVariableStorage.Enqueue((UseExternalDocNo));
        Clear(VendorBalanceToDate);
        Vendor.SetRange("No.", VendorNo);
        Vendor.SetRange("Date Filter", CalcDate('<CM>', WorkDate()));
        VendorBalanceToDate.SetTableView(Vendor);
        VendorBalanceToDate.Run();
    end;

    local procedure RunArchivedPurchaseOrderReport(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        FindPurchaseHeaderArchive(PurchaseHeaderArchive, PurchaseHeader);
        REPORT.SaveAsExcel(REPORT::"Archived Purchase Order", LibraryReportValidation.GetFileName(), PurchaseHeaderArchive);
    end;

    local procedure RunArchivedPurchaseReturnOrderReport(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
    begin
        FindPurchaseHeaderArchive(PurchaseHeaderArchive, PurchaseHeader);
        REPORT.SaveAsExcel(REPORT::"Arch.Purch. Return Order", LibraryReportValidation.GetFileName(), PurchaseHeaderArchive);
    end;

    local procedure RunDtldVendTrialBalanceReportWithDateFilter(VendNo: Code[20])
    var
        Vendor: Record Vendor;
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(false);
        LibraryVariableStorage.Enqueue(VendNo);
        Commit();
        Vendor.Get(VendNo);
        Vendor.SetRecFilter();
        Vendor.SetFilter("Date Filter", '%1..', WorkDate());
        REPORT.Run(REPORT::"Vendor - Detail Trial Balance", true, false, Vendor);
    end;

    local procedure SetupAndPostVendorPmtTolerance(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]) DocumentNo: Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Amount: Decimal;
        DiscountAmount: Decimal;
        PmtTolerance: Decimal;
    begin
        PmtTolerance := LibraryRandom.RandDec(10, 2);  // Using Random value for Payment Tolerance.
        UpdateGeneralLedgerSetup(PmtTolerance);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, CurrencyCode, CreateItem(), CreateVendorWithPmtTerms());
        FindPurchaseLine(PurchaseLine, PurchaseHeader."Document Type", PurchaseHeader."No.");

        // Calculate Payment Tolerance and Payment Discount Amount.
        PmtTolerance := Round(PurchaseLine."Amount Including VAT" * PmtTolerance / 100);
        Amount := PurchaseLine."Line Amount" + Round(PurchaseLine."Line Amount" * PurchaseLine."VAT %" / 100);
        DiscountAmount := Round(Amount * PurchaseHeader."Payment Discount %" / 100);
        Amount := Amount - DiscountAmount;
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Make Payment for Vendor, Apply it on Invoice and Post it.
        ApplyPaymentFromGenJournalLine(GenJournalLine, PurchaseHeader."Buy-from Vendor No.", Amount - PmtTolerance, DocumentNo);
    end;

    local procedure SetupSaveAgedAccountsPayable(var GenJournalLine: Record "Gen. Journal Line"; CurrencyCode: Code[10]; AgingBy: Option; PrintAmountLCY: Boolean; PrintDetails: Boolean; HeadingType: Option)
    begin
        // Setup:  Post Invoice Entry for Vendor. Take Posting Date One Month earlier than WORKDATE to generate data for Report.
        CreatePostGeneralJournalLine(GenJournalLine, CreateAndUpdateVendor(), CurrencyCode, '<-1M>');

        // Exercise: Save Aged Accounts Payable Report as per the option selected.
        SaveAgedAccountsPayable(GenJournalLine."Account No.", AgingBy, PrintAmountLCY, PrintDetails, HeadingType);
    end;

    local procedure UndoPurchaseReceiptLines(No: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
    begin
        FindReceiptLine(PurchRcptLine, No);
        LibraryPurchase.UndoPurchaseReceiptLine(PurchRcptLine);
    end;

    local procedure UndoReturnShipment(No: Code[20])
    var
        ReturnShipmentLine: Record "Return Shipment Line";
    begin
        FindReturnShipmentLine(ReturnShipmentLine, No);
        LibraryPurchase.UndoReturnShipmentLine(ReturnShipmentLine);
    end;

    local procedure UpdateGeneralLedgerSetup(PaymentTolerance: Decimal)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.Validate("Payment Tolerance %", PaymentTolerance);
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure UpdateOpenOnVendLedgerEntry(EntryNo: Integer)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        VendorLedgerEntry.Get(EntryNo);
        VendorLedgerEntry.CalcFields(Amount);
        VendorLedgerEntry.Open := VendorLedgerEntry.Amount <> 0;
        VendorLedgerEntry.Modify();
    end;

    local procedure VendorPurchaseList(HideAddress: Boolean)
    var
        Vendor: Record Vendor;
    begin
        // Setup.
        LibraryPurchase.CreateVendorWithVATRegNo(Vendor);
        Vendor.Validate(Address, Vendor.Name);
        Vendor.Validate("Address 2", CopyStr(Vendor.Address, 1, MaxStrLen(Vendor."Address 2")));
        Vendor.Modify(true);

        // Exercise: Save Vendor Purchase List Report.
        SavePurchaseListReport(Vendor."No.", Vendor."No.", 0, HideAddress);

        // Verify: Verify Vendor Information.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('VendNo', Vendor."No.");
        LibraryReportDataset.AssertElementWithValueExists('VendName', Vendor.Name);
        LibraryReportDataset.AssertElementWithValueExists('VendVATRegNo', Vendor."VAT Registration No.");
        LibraryReportDataset.AssertElementWithValueExists('VendAddr3', Vendor.Address);
    end;

    local procedure VendorPurchaseListAmountLCY(AmountLCY: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DocumentNo: Code[20];
    begin
        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Order, '', CreateItem(), '');
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, DocumentNo);

        // Exercise: Save Purchase List Report for different Amount.
        SavePurchaseListReport(PurchaseHeader."Buy-from Vendor No.", Vendor."No.", AmountLCY, false);

        // Verify: Verify Vendor Purchase (LCY) Amount.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('AmtPurchLCY', -VendorLedgerEntry."Purchase (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('VendNo', Vendor."No.")
    end;

    local procedure ApplyPaymentToAllOpenInvoices(PmtNo: Code[20]; VendNo: Code[20])
    var
        GenJournalLine: Record "Gen. Journal Line";
        ApplyingVendLedgerEntry: Record "Vendor Ledger Entry";
        VendLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(
          ApplyingVendLedgerEntry, GenJournalLine."Document Type"::Payment, PmtNo);
        ApplyingVendLedgerEntry.CalcFields("Remaining Amount");
        LibraryERM.SetApplyVendorEntry(ApplyingVendLedgerEntry, ApplyingVendLedgerEntry."Remaining Amount");
        VendLedgerEntry.SetRange("Vendor No.", VendNo);
        VendLedgerEntry.SetRange("Document Type", VendLedgerEntry."Document Type"::Invoice);
        VendLedgerEntry.SetRange(Open, true);
        LibraryERM.SetAppliestoIdVendor(VendLedgerEntry);
        LibraryERM.PostVendLedgerApplication(ApplyingVendLedgerEntry);
    end;

    local procedure VerifyInteractionLogEntry(DocumentType: Enum "Interaction Log Entry Document Type"; DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", DocumentType);
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        InteractionLogEntry.FindFirst();
    end;

    local procedure VerifyPurchRtnShipReport(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('Qty_ReturnShipmentLine', PurchaseLine.Quantity);
    end;

    local procedure VerifyVendorBalanceToDate(VendorNo: Code[20]; DocumentNo: Code[20])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        // Verify: Verify Saved Report Data.
        VendorLedgerEntry.SetFilter("Vendor No.", VendorNo);
        VendorLedgerEntry.SetFilter("Document No.", DocumentNo);
        VendorLedgerEntry.FindFirst();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DocType_VendLedgEntry3', Format(VendorLedgerEntry."Document Type"));
        LibraryReportDataset.AssertElementWithValueExists('DocNo_VendLedgEntry3', VendorLedgerEntry."Document No.");
        LibraryReportDataset.AssertElementWithValueExists('StrNoVenGetMaxDtFilter', StrSubstNo(BalanceOnCaptionTxt, WorkDate()));
    end;

    local procedure VerifyGenJnlLineWithCreditMemo(GenJournalLine: Record "Gen. Journal Line"; Amount: Decimal)
    var
        SuggestVendorGenJnlLine: Record "Gen. Journal Line";
    begin
        SuggestVendorGenJnlLine.SetRange("Journal Template Name", GenJournalLine."Journal Template Name");
        SuggestVendorGenJnlLine.SetRange("Journal Batch Name", GenJournalLine."Journal Batch Name");
        SuggestVendorGenJnlLine.SetRange("Applies-to Doc. Type", SuggestVendorGenJnlLine."Applies-to Doc. Type"::"Credit Memo");
        SuggestVendorGenJnlLine.FindFirst();
        SuggestVendorGenJnlLine.TestField(Amount, Amount);
    end;

    local procedure VerifyAmountOnVendorOrderSummaryReport(VendorNo: Code[20]; ExpectedAmount: Decimal)
    var
        ActualAmount: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vendor', VendorNo);
        ActualAmount := LibraryReportDataset.Sum('PurchAmtOnOrder2');
        Assert.AreEqual(ExpectedAmount, Round(ActualAmount), StrSubstNo(MustBeEqualErr, ExpectedAmount, Round(ActualAmount)));
    end;

    local procedure VerifyMultipleCurrencyAmountsOnVendorOrderSummaryReport(CurrencyCode: array[2] of Code[10]; ExpectedAmount: array[2] of Decimal)
    var
        RowNo: Integer;
        I: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        for I := 1 to ArrayLen(CurrencyCode) do begin
            RowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(4, CurrencyCode[I]);
            LibraryReportValidation.VerifyCellValueByRef('G', RowNo, 1, LibraryReportValidation.FormatDecimalValue(ExpectedAmount[I]));
        end;
    end;

    local procedure VerifyOutstandingOrdersAndTotalOnVendorOrderDetailReport(PurchaseLine: Record "Purchase Line"; VendorNo: Code[20]; ExpectedTotal: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vendor', VendorNo);
        if not LibraryReportDataset.GetNextRow() then
            Error(NoDatasetRowErr, 'No_Vendor', VendorNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchOrderAmount', PurchaseLine.Amount);
        LibraryReportDataset.GetNextRow();
        PurchaseLine.Next();
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchOrderAmount', PurchaseLine.Amount);
        LibraryReportDataset.AssertElementWithValueExists('TotalAmtCurrTotalBuffer', ExpectedTotal);
    end;

    local procedure VerifyVendorPaymentReceiptReport(InvoiceNo: Code[20]; PaymentNo: Code[20]; PaymentAmount: Decimal)
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Invoice, InvoiceNo);
        LibraryReportDataset.LoadDataSetFile();

        LibraryReportDataset.AssertElementWithValueExists('DocNo_VendLedgEntry1', InvoiceNo);
        LibraryReportDataset.AssertElementWithValueExists('NegPmtDiscInvCurrVendLedgEntry1', -VendorLedgerEntry."Pmt. Disc. Rcd.(LCY)");
        LibraryReportDataset.AssertElementWithValueExists('NegPmtTolInvCurrVendLedgEntry1', -VendorLedgerEntry."Pmt. Tolerance (LCY)");

        LibraryReportDataset.AssertElementWithValueExists('NegOriginalAmt_VendLedgEntry', -PaymentAmount);

        LibraryERM.FindVendorLedgerEntry(VendorLedgerEntry, VendorLedgerEntry."Document Type"::Payment, PaymentNo);
        VendorLedgerEntry.CalcFields("Remaining Amt. (LCY)");
        LibraryReportDataset.AssertElementWithValueExists('NegRemainingAmt', VendorLedgerEntry."Remaining Amt. (LCY)");
    end;

    local procedure VerifyVendorBalanceToDateTwoEntriesExist(VendorNo: Code[20]; PmtAmount: Decimal; Amount: Decimal; TotalAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vendor', VendorNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(PmtAmount));
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(Amount));
        LibraryReportDataset.AssertElementWithValueExists('CurrTotalBufferTotalAmt', TotalAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('PostDate_DtldVendLedEnt', Format(WorkDate() + 1));
    end;

    local procedure VerifyVendorBalanceToDateDoesNotExist(VendorNo: Code[20]; PmtAmount: Decimal; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vendor', VendorNo);
        LibraryReportDataset.AssertElementWithValueExists('OriginalAmt', Format(PmtAmount));
        LibraryReportDataset.AssertElementWithValueNotExist('OriginalAmt', Format(Amount));
        LibraryReportDataset.AssertElementWithValueExists('CurrTotalBufferTotalAmt', PmtAmount);
        LibraryReportDataset.AssertElementWithValueNotExist('PostDate_DtldVendLedEnt', Format(WorkDate() + 1));
    end;

    local procedure VerifyArchiveDocExcelTotalVATBaseAmount(ColumnName: Text; RowNo: Integer; TotalVATAmount: Decimal; TotalBaseAmount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, LibraryReportValidation.FormatDecimalValue(TotalVATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 1, 1, LibraryReportValidation.FormatDecimalValue(TotalBaseAmount));
    end;

    local procedure VerifyArchiveOrderExcelTotalsWithDiscount(ColumnName: Text; RowNo: Integer; Amount: Decimal; InvDicountAmount: Decimal; ExclVATAmount: Decimal; VATAmount: Decimal; InclVATAmount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, LibraryReportValidation.FormatDecimalValue(Amount));
        LibraryReportValidation.VerifyCellValueByRef(
          ColumnName, RowNo + 1, 1, LibraryReportValidation.FormatDecimalValue(-InvDicountAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 2, 1, LibraryReportValidation.FormatDecimalValue(ExclVATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 3, 1, LibraryReportValidation.FormatDecimalValue(VATAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 4, 1, LibraryReportValidation.FormatDecimalValue(InclVATAmount));
    end;

    local procedure VerifyArchiveRetOrderExcelTotalsWithDiscount(ColumnName: Text; RowNo: Integer; Amount: Decimal; InvDicountAmount: Decimal; ExclVATAmount: Decimal)
    begin
        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo, 1, LibraryReportValidation.FormatDecimalValue(Amount));
        LibraryReportValidation.VerifyCellValueByRef(
          ColumnName, RowNo + 1, 1, LibraryReportValidation.FormatDecimalValue(-InvDicountAmount));
        LibraryReportValidation.VerifyCellValueByRef(ColumnName, RowNo + 2, 1, LibraryReportValidation.FormatDecimalValue(ExclVATAmount));
    end;

    local procedure CreatePurchaseDocumentWithZeroAmount(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; VendorNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", '', 1);  // Use Random Value.
        PurchaseLine.Validate(Quantity, 1);
        PurchaseLine.Modify(true);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Question, ExpectedMessage) > 0, Question);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.ShowInternalInfo.SetValue(true);
        PurchaseInvoice.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.ShowInternalInfo.SetValue(true);
        PurchaseCreditMemo.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerPurchaseReceipt(var PurchaseReceipt: TestRequestPage "Purchase - Receipt")
    begin
        PurchaseReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorPaymentReceipt(var VendorPaymentReceipt: TestRequestPage "Vendor - Payment Receipt")
    begin
        VendorPaymentReceipt.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorSummaryAging(var VendorSummaryAging: TestRequestPage "Vendor - Summary Aging")
    var
        StartingDate: Variant;
        AmountLCY: Variant;
        DatePeriod: Variant;
        DatePeriodFormula: DateFormula;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(DatePeriod);
        Evaluate(DatePeriodFormula, DatePeriod);
        LibraryVariableStorage.Dequeue(AmountLCY);
        VendorSummaryAging."PeriodStartDate[2]".SetValue(StartingDate);
        VendorSummaryAging.PeriodLength.SetValue(DatePeriodFormula);
        VendorSummaryAging.PrintAmountsInLCY.SetValue(AmountLCY);
        VendorSummaryAging.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorOrderSummary(var VendorOrderSummary: TestRequestPage "Vendor - Order Summary")
    var
        StartingDate: Variant;
        AmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(AmountLCY);
        VendorOrderSummary.StartingDate.SetValue(StartingDate);
        VendorOrderSummary.AmountsinLCY.SetValue(AmountLCY);
        VendorOrderSummary.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorOrderSummaryExcel(var VendorOrderSummary: TestRequestPage "Vendor - Order Summary")
    var
        StartingDate: Variant;
        AmountLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(AmountLCY);
        VendorOrderSummary.StartingDate.SetValue(StartingDate);
        VendorOrderSummary.AmountsinLCY.SetValue(AmountLCY);
        VendorOrderSummary.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorOrderDetail(var VendorOrderDetail: TestRequestPage "Vendor - Order Detail")
    begin
        VendorOrderDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorDetailTrialBalance(var VendorDetailTrialBalance: TestRequestPage "Vendor - Detail Trial Balance")
    begin
        VendorDetailTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorItemCatalog(var VendorItemCatalog: TestRequestPage "Vendor Item Catalog")
    begin
        VendorItemCatalog.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorPurchaseList(var VendorPurchaseList: TestRequestPage "Vendor - Purchase List")
    var
        MinAmtLCY: Variant;
        HideAddress: Variant;
    begin
        LibraryVariableStorage.Dequeue(MinAmtLCY);
        LibraryVariableStorage.Dequeue(HideAddress);
        VendorPurchaseList.MinAmtLCY.SetValue(MinAmtLCY);
        VendorPurchaseList.HideAddr.SetValue(HideAddress);
        VendorPurchaseList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorBalanceToDate(var VendorBalanceToDate: TestRequestPage "Vendor - Balance to Date")
    var
        AmountLCY: Variant;
        Unapplied: Variant;
    begin
        LibraryVariableStorage.Dequeue(AmountLCY);
        LibraryVariableStorage.Dequeue(Unapplied);
        VendorBalanceToDate.ShowAmountsInLCY.SetValue(AmountLCY);
        VendorBalanceToDate.PrintUnappliedEntries.SetValue(Unapplied);
        VendorBalanceToDate.ShowEntriesWithZeroBalance.SetValue(LibraryVariableStorage.DequeueBoolean());
        VendorBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerVendorPurchaseStatistics(var PurchaseStatistics: TestRequestPage "Purchase Statistics")
    begin
        PurchaseStatistics.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerAgedAccountPayable(var AgedAccountsPayable: TestRequestPage "Aged Accounts Payable")
    var
        AgingBy: Variant;
        PrintAmountLCY: Variant;
        PrintDetails: Variant;
        HeadingType: Variant;
    begin
        LibraryVariableStorage.Dequeue(AgingBy);
        LibraryVariableStorage.Dequeue(PrintAmountLCY);
        LibraryVariableStorage.Dequeue(PrintDetails);
        LibraryVariableStorage.Dequeue(HeadingType);
        AgedAccountsPayable.AgingBy.SetValue(AgingBy);
        AgedAccountsPayable.PrintAmountInLCY.SetValue(PrintAmountLCY);
        AgedAccountsPayable.PrintDetails.SetValue(PrintDetails);
        AgedAccountsPayable.HeadingType.SetValue(HeadingType);
        AgedAccountsPayable.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerBlanketPurchaseOrder(var BlanketPurchaseOrder: TestRequestPage "Blanket Purchase Order")
    begin
        BlanketPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ReportHandlerPurchaseReturnShipment(var PurchaseReturnShipment: TestRequestPage "Purchase - Return Shipment")
    begin
        PurchaseReturnShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SuggestVendorPaymentsWithAvailableAmtRequestPageHandler(var SuggestVendorPayments: TestRequestPage "Suggest Vendor Payments")
    var
        VendorNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(VendorNo);
        SuggestVendorPayments.Vendor.SetFilter("No.", VendorNo);
        SuggestVendorPayments.LastPaymentDate.SetValue(WorkDate());
        SuggestVendorPayments.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseQuoteRequestPageHandler(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    var
        PurchaseHeaderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(PurchaseHeaderNo);
        LibraryReportValidation.SetFileName(PurchaseHeaderNo);
        PurchaseQuote.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorBalanceToDate(var VendorBalanceToDate: TestRequestPage "Vendor - Balance to Date")
    begin
        VendorBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorBalanceToDateUseExternalDocNo(var VendorBalanceToDate: TestRequestPage "Vendor - Balance to Date")
    begin
        VendorBalanceToDate.UseExternalDocNo.SetValue(LibraryVariableStorage.DequeueBoolean());
        VendorBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorDetailTrialBalanceExcelRequestPageHandler(var VendorDetailTrialBalance: TestRequestPage "Vendor - Detail Trial Balance")
    begin
        VendorDetailTrialBalance.ShowAmountsInLCY.SetValue(LibraryVariableStorage.DequeueDecimal());
        VendorDetailTrialBalance.NewPageperVendor.SetValue(LibraryVariableStorage.DequeueBoolean());
        VendorDetailTrialBalance.ExcludeCustHaveaBalanceOnly.SetValue(LibraryVariableStorage.DequeueBoolean());
        VendorDetailTrialBalance.Vendor.SetFilter("No.", LibraryVariableStorage.DequeueText());
        VendorDetailTrialBalance.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;
}
