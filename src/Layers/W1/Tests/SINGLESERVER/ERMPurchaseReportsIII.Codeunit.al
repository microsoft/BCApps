codeunit 134988 "ERM Purchase Reports III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Purchase] [Report]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryUtilityOnPrem: Codeunit "Library - Utility OnPrem";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryReportValidation: Codeunit "Library - Report Validation";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AmtPurchCrMemoHeaderLbl: Label 'Amt_PurchCrMemoHeader';
        AmtPurchInvHeaderLbl: Label 'Amt_PurchInvHeader';
        DocEntryTableNameLbl: Label 'DocEntryTableName';
        DocEntryNoofRecordsLbl: Label 'DocEntryNoofRecords';
        ValidationErr: Label '%1 must be %2 in Report.', Comment = '%1 = Element, %2 = Value';
        HeaderDimensionTxt: Label '%1 - %2', Comment = '%1 = Dimension Code, %2 = Dimension Value Code';
        VendorInvoiceNoErr: Label 'Vendor Invoice No. must be specified.';
        AssignedQuantityErr: Label 'Incorrect Assigned Quantity in report.';
        PstDatePurchInvHeaderLbl: Label 'PstDate_PurchInvHeader';
        PstDatePurchCrMemoHeaderLbl: Label 'PstDate_PurchCrMemoHeader';
        RowNotFoundErr: Label 'There is not dataset row corresponding to Element Name %1 with value %2', Comment = '%1 = Element, %2 = Value';
        VALExchRateTok: Label 'VALExchRate';
        WrongExchRateErr: Label 'Wrong exchange rate.';
        VATIdentifierTok: Label 'VATAmountLine__VAT_Identifier__Control245';
        RowVisibilityErr: Label 'Analysis row must only be visible in Purchase Analysis Matrix when Show <> No.';
        ColumnVisibilityErr: Label 'Analysis column must only be visible in Purchase Analysis Matrix when Show <> Never.';
        ColumnDoesNotExistErr: Label 'Analysis column does not exist in Analysis Column Template and therefore must not be visible.';

    [Test]
    [HandlerFunctions('RHPurchasePrepmtDocTest')]
    [Scope('OnPrem')]
    procedure PurchasePrepmtDocTestInvoice()
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Purchase Prepayment Document Test Report with Invoice and Dimension False Option.

        // Create Purchase Order with Prepayment % and Prepayment Line Amount.
        Initialize();
        SetupPrepaymentPurchaseDoc(PurchaseLine, CreateVendor());

        // Verify: Verify Saved Report Data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Purchase_Line__Type', Format(PurchaseLine.Type));
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Purchase_Line__Type', Format(PurchaseLine.Type));
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___No__', PurchaseLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line__Description', PurchaseLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line__Quantity', PurchaseLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___Prepayment___', PurchaseLine."Prepayment %");
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___Prepmt__Line_Amount_', PurchaseLine."Prepmt. Line Amount");
    end;

    [Test]
    [HandlerFunctions('RHVendorTrialBalance')]
    [Scope('OnPrem')]
    procedure VendorTrialBalanceNoOption()
    var
        VendorTrialBalance: Report "Vendor - Trial Balance";
    begin
        // [FEATURE] [Vendor - Trial Balance]
        // [SCENARIO] Check Vendor Trial Balance Report without Any option Selected.
        Initialize();

        // [GIVEN] Cleared Request Page of Vendor Trial Balance Report
        Clear(VendorTrialBalance);

        // [WHEN] Try to Save Vendor Trial Balance Report without any Filter.
        Commit();
        asserterror VendorTrialBalance.Run();

        // [THEN] Error raised during save Vendor Trial Balance Report.
        Assert.AssertNoFilter();
    end;

    [Test]
    [HandlerFunctions('RHVendorTrialBalance')]
    [Scope('OnPrem')]
    procedure VendorTrialBalanceDateFilter()
    var
        PurchaseHeader: Record "Purchase Header";
        LineAmount: Decimal;
    begin
        // [FEATURE] [Vendor - Trial Balance]
        // [SCENARIO] Check Vendor Trial Balance Report with Date Filter.
        Initialize();

        // [GIVEN] Posted Purchase Order with Amount = "X"
        LineAmount :=
          CreatePurchaseDocument(
            PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)),
            PurchaseHeader."Document Type"::Order, LibraryInventory.CreateItemNo());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run Vendor - Trial Balance Report on Posting Date
        RunVendorTrialBalanceReport(PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", '', '');

        // [THEN] Reported Amount = "X" is shown in report
        VerifyVendorTrialBalanceReportValues(PurchaseHeader."Buy-from Vendor No.", LineAmount);
    end;

    [Test]
    [HandlerFunctions('RHVendorTrialBalance')]
    [Scope('OnPrem')]
    procedure VendorTrialBalanceWithDimension()
    var
        PurchaseHeader: Record "Purchase Header";
        GlobalDim1Value: Code[20];
        GlobalDim2Value: Code[20];
        Amount: Decimal;
        AmountDim: Decimal;
    begin
        // [FEATURE] [Vendor - Trial Balance]
        // [SCENARIO 122717] Run Customer - Trial Balance report with dimension filters
        Initialize();

        // [GIVEN] New Dimension Values for Global Dimension: "G1","G2"
        CreateGlobalDimValues(GlobalDim1Value, GlobalDim2Value);
        // [GIVEN] Posted Purchase Order with Amount = "X" without dimensions
        Amount :=
          CreatePurchaseDocument(
            PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)),
            PurchaseHeader."Document Type"::Order, LibraryInventory.CreateItemNo());
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Vendor Ledger Entry with Amount = "X1" and dimensions "G1","G2"
        AmountDim :=
          CreateAndPostGeneralJournalLineWithDimensions(PurchaseHeader."Buy-from Vendor No.", GlobalDim1Value, GlobalDim2Value);

        // [WHEN] Run Vendor - Trial Balance Report
        RunVendorTrialBalanceReport(
          PurchaseHeader."Buy-from Vendor No.", PurchaseHeader."Posting Date", GlobalDim1Value, GlobalDim2Value);

        // [THEN] Reported Amount = "X1" is filtered and shown in report
        VerifyVendorTrialBalanceReportValues(PurchaseHeader."Buy-from Vendor No.", AmountDim);
        // [THEN] Sum of Amounts = "X" + "X1" is not shown in report
        LibraryReportDataset.AssertElementWithValueNotExist('PeriodCreditAmt', Amount);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Document Test Report Warning with Invoice.
        Initialize();
        SetupPurchaseDocWarning(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseOrderNoWarning()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Document Test Report Warning with Order.
        Initialize();
        SetupPurchaseDocWarning(PurchaseHeader."Document Type"::Order);
    end;

    local procedure SetupPurchaseDocWarning(DocumentType: Enum "Purchase Document Type")
    begin
        // Create Purchase Document and Save Purchase Document Test Report.
        CreatePurchaseDocSaveReport('', DocumentType);

        // Verify: Verify Warning when found on Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ErrorText_Number_', StrSubstNo(VendorInvoiceNoErr));
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceWarning()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Document Test Report without Warning with Invoice.
        Initialize();
        SetupPurchaseDocNoWarning(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseOrderWarning()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Document Test Report without Warning with Order.
        Initialize();
        SetupPurchaseDocNoWarning(PurchaseHeader."Document Type"::Order);
    end;

    local procedure SetupPurchaseDocNoWarning(DocumentType: Enum "Purchase Document Type")
    begin
        // Create Purchase Document and Save Purchase Document Test Report.
        CreatePurchaseDocSaveReport(Format(LibraryRandom.RandInt(100)), DocumentType);

        // Verify: Verify No Warning message on Report.
        LibraryReportDataset.LoadDataSetFile();
        asserterror LibraryReportDataset.AssertElementWithValueExists('', StrSubstNo(VendorInvoiceNoErr));
    end;

    [Test]
    [HandlerFunctions('RHPurchaseQuote')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteWithInternalInformation()
    var
        DefaultDimension: Record "Default Dimension";
        PurchaseHeader: Record "Purchase Header";
        ExpectedDimensionValue: Text[120];
    begin
        // Check Purchase Quote Report with Show Internal Information option.

        // Setup: Create Item with Dimension and Purchase Quote.
        Initialize();
        CreateItemWithDimension(DefaultDimension);
        CreatePurchaseDocument(
          PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)), PurchaseHeader."Document Type"::Quote,
          DefaultDimension."No.");
        ExpectedDimensionValue :=
          StrSubstNo(HeaderDimensionTxt, DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        // Exercise: Save Report using Show Internal Information flag yes.
        SavePurchaseQuoteReport(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", true, false, false);

        // Verify: Verify Dimension on Purchase Quote Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('DimText1', ExpectedDimensionValue);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseQuote')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteWithArchive()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Purchase Quote Report with Archive Document option.

        // Setup: Create Purchase Quote.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)),
          PurchaseHeader."Document Type"::Quote, LibraryInventory.CreateItemNo());
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise: Save Report using Archive Document flag yes.
        SavePurchaseQuoteReport(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", false, true, false);

        // Verify: Verify Archive Entry created for Purchase Quote.
        VerifyPurchaseArchive(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseQuote')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteInteractionEntry()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Check Purchase Quote Report with Log Interaction option.

        // Setup: Create Purchase Quote.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)),
          PurchaseHeader."Document Type"::Quote, LibraryInventory.CreateItemNo());

        // Exercise: Save Report using Log Interaction flag yes.
        SavePurchaseQuoteReport(PurchaseHeader."No.", PurchaseHeader."Buy-from Vendor No.", false, false, true);

        // Verify: Verify Interaction Log Entry created for Purchase Quote.
        VerifyInteractionLogEntry(PurchaseHeader."No.");
    end;

    [Test]
    [HandlerFunctions('RHPurchaseQuote')]
    [Scope('OnPrem')]
    procedure PurchaseQuoteWithValues()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // Check Purchase Quote Report showing correct values.

        // Setup: Create Purchase Quote.
        Initialize();
        CreatePurchaseDocument(
          PurchaseHeader, CreateVendor(), Format(LibraryRandom.RandInt(100)),
          PurchaseHeader."Document Type"::Quote, LibraryInventory.CreateItemNo());
        FindPurchaseLine(PurchaseLine, PurchaseHeader."No.");

        // Exercise: Save Report using default value.
        SavePurchaseQuoteReport(PurchaseLine."Document No.", PurchaseLine."Buy-from Vendor No.", false, false, false);

        // Verify: Verify values on Purchase Quote Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_PurchaseLine', PurchaseLine."No.");
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'LineNo_PurchaseLine', PurchaseLine."Line No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('PurchHeadNo', PurchaseHeader."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Quantity_PurchaseLine', PurchaseLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Description_PurchaseLine', PurchaseLine.Description);
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitOfMeasure_PurchaseLine', PurchaseLine."Unit of Measure");
    end;

    [Test]
    [HandlerFunctions('RHOrder')]
    [Scope('OnPrem')]
    procedure OrderReportWithPostingDateBlankOnPurchaseOrder()
    var
        VendorInvoiceDisc: Record "Vendor Invoice Disc.";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        "Order": Report "Order";
    begin
        // Check Saved Purchase Order Report to Verify that program generates report.

        // Setup.
        Initialize();
        UpdatePurchasePayablesSetup(PurchasesPayablesSetup."Default Posting Date"::"No Date");
        SetupInvoiceDiscount(VendorInvoiceDisc);

        // Create Purchase Order with Currency and Calculate Invoice discount with Random values.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorInvoiceDisc.Code);
        ModifyCurrencyCodeOnPurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item,
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        ModifyDirectUnitCostOnPurchaseLine(PurchaseLine, VendorInvoiceDisc."Minimum Amount");
        CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);

        // Exercise: Generate Report as external file for Purchase Order.
        Clear(Order);
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Order.SetTableView(PurchaseHeader);
        Commit();
        Order.Run();

        // Verify: Verify that Saved files have some data.
        LibraryReportDataset.LoadDataSetFile();
        LibraryUtilityOnPrem.CheckFileNotEmpty(LibraryReportDataset.GetFileName());
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReportForPurchaseInvoice()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Assigned Quantity on Purchase Document Test Report when Purchase Invoice created with Charge Item.
        AssignedQuantityOnPurchaseDocumentTestReport(PurchaseHeader."Document Type"::Invoice);
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReportForPurchaseCreditMemo()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // Verify Assigned Quantity on Purchase Document Test Report when Purchase Credit Memo created with Charge Item.
        AssignedQuantityOnPurchaseDocumentTestReport(PurchaseHeader."Document Type"::"Credit Memo");
    end;

    [Test]
    [HandlerFunctions('RHPurchaseDocumentTest')]
    [Scope('OnPrem')]
    procedure PurchaseDocTestForCreditMemoInvDiscAmt()
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Purchase Document - Test]
        // [SCENARIO 363729] When printing the Purchase Document - Test Report the invoice discount is displayed
        Initialize();

        // [GIVEN] Purchase & Payables Setup option "Calc. Inv. Discount" is set to YES
        UpdatePurchasePayablesSetupCalcInvDisc(true);

        // [GIVEN] Purchase Credit Memo with Invoice Discount Amount = "X"
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo",
          '', LibraryInventory.CreateItemNo(), CreateVendor(), '');

        // [WHEN] Run Purchase Document - Test Report
        RunPurchaseCreditMemoTestReport(PurchaseHeader."No.");
        LibraryReportDataset.LoadDataSetFile();

        // [THEN] Invoice Discount Amount "X" is shown on the report
        VerifyInvoiceDiscountInReport(PurchaseHeader);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntryReportForPurchaseReceipt()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
        PostedPurchaseReceiptPage: Page "Posted Purchase Receipt";
        DocumentNo: Code[20];
    begin
        // Verify Document Entry report for Purchase Receipt.

        // Setup: Create and receive Purchase Order.
        Initialize();
        CreatePurchaseOrder(PurchaseHeader, PurchaseHeader."Document Type"::Order,
          '', LibraryInventory.CreateItemNo(), CreateVendor(), '');  // Blank value for Currency Code and Location Code.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // FALSE for Invoice.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedPurchaseReceipt.OpenEdit();
        PostedPurchaseReceipt.FILTER.SetFilter("No.", DocumentNo);

        // Exercise: Open Nevigate page.
        PostedPurchaseReceipt."&Navigate".Invoke();  // Invoking Navigate.

        // Verify: Verify Posted Purchase Receipt Entry on Document Entry Report.
        PurchRcptHeader.SetRange("No.", DocumentNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedPurchaseReceiptPage.Caption, PurchRcptHeader.Count);
        VerifyValueEntryItemLedgerEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocEntryReportForPurchInvShowAmtInLCYFalse()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Verify Document Entry report for Purchase Invoice with Show Amount in LCY FALSE.

        // Setup and Exercise.
        SetupForDocEntryReportForPurchaseInvoice(PurchInvHeader, false);  // FALSE for Show Amount in LCY.

        // Verify: verify Amount on Document Entry report.
        VerifyAmountOnDocumentEntryReport(PstDatePurchInvHeaderLbl, AmtPurchInvHeaderLbl, PurchInvHeader.Amount);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocEntryReportForPurchInvShowAmtInLCYTrue()
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        // Verify Document Entry report for Purchase Invoice with Show Amount in LCY TRUE.

        // Setup and Exercise.
        SetupForDocEntryReportForPurchaseInvoice(PurchInvHeader, true);  // TRUE for Show Amount in LCY.

        // Verify: verify Amount on Document Entry report.
        VerifyAmountOnDocumentEntryReport(
          PstDatePurchInvHeaderLbl, AmtPurchInvHeaderLbl, PurchInvHeader.Amount / PurchInvHeader."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntryReportForPurchReturnShipment()
    var
        PurchaseHeader: Record "Purchase Header";
        ReturnShipmentHeader: Record "Return Shipment Header";
        PostedReturnShipment: TestPage "Posted Return Shipment";
        PostedReturnShipmentPage: Page "Posted Return Shipment";
        DocumentNo: Code[20];
    begin
        // Verify Document Entry report for Purchase Return Shipment.

        // Setup: Create and ship Purchase Return Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order",
          '', LibraryInventory.CreateItemNo(), CreateVendor(), '');  // Blank value for Currency Code and Location Code.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);  // FALSE for Invoice.
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedReturnShipment.OpenEdit();
        PostedReturnShipment.FILTER.SetFilter("No.", DocumentNo);

        // Exercise: Open Nevigate page.
        PostedReturnShipment."&Navigate".Invoke();  // Invoking Navigate.

        // Verify: Verify various entries on Document Entry report.
        ReturnShipmentHeader.SetRange("No.", DocumentNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedReturnShipmentPage.Caption, ReturnShipmentHeader.Count);
        VerifyValueEntryItemLedgerEntry(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocEntryReportForPurchCrMemoShowAmtInLCYFalse()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Verify Document Entry report for Purchase Credit Memo with Show Amount in LCY FALSE.

        // Setup and Exercise.
        SetupForDocEntryReportForPurchCreditMemo(PurchCrMemoHdr, false);  // FALSE for Show Amount in LCY.

        // Verify: verify Amount on Document Entry report.
        VerifyAmountOnDocumentEntryReport(PstDatePurchCrMemoHeaderLbl, AmtPurchCrMemoHeaderLbl, PurchCrMemoHdr.Amount);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocEntryReportForPurchCrMemoShowAmtInLCYTrue()
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        // Verify Document Entry report for Purchase Credit Memo with Show Amount in LCY TRUE.

        // Setup and Exercise.
        SetupForDocEntryReportForPurchCreditMemo(PurchCrMemoHdr, true);  // TRUE for Show Amount in LCY.

        // Verify: verify Amount on Document Entry report.
        VerifyAmountOnDocumentEntryReport(
          PstDatePurchCrMemoHeaderLbl, AmtPurchCrMemoHeaderLbl, PurchCrMemoHdr.Amount / PurchCrMemoHdr."Currency Factor");
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesWithTransferShipment()
    var
        TransferShipmentHeader: Record "Transfer Shipment Header";
        PostedTransferShipment: TestPage "Posted Transfer Shipment";
        PostedTransferShipmentPage: Page "Posted Transfer Shipment";
        TransferOrderNo: Code[20];
    begin
        // Verify Transfer Shipment Header on Document Entries Report.

        // Setup: Create and post Transfer Order as Ship and Receive.
        Initialize();
        TransferOrderNo := CreateAndPostTransferOrder();
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedTransferShipment.OpenView();
        PostedTransferShipment.FILTER.SetFilter("Transfer Order No.", TransferOrderNo);

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        PostedTransferShipment."&Navigate".Invoke();  // Control is using to Navigate Page.

        // Verify: Verify Transfer Shipment Header Table Name and number of Records on Document Entries Report.
        TransferShipmentHeader.SetRange("Transfer Order No.", TransferOrderNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedTransferShipmentPage.Caption, TransferShipmentHeader.Count);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesWithTransferReceipt()
    var
        TransferReceiptHeader: Record "Transfer Receipt Header";
        PostedTransferReceipt: TestPage "Posted Transfer Receipt";
        PostedTransferReceiptPage: Page "Posted Transfer Receipt";
        TransferOrderNo: Code[20];
    begin
        // Verify Transfer Receipt Header on Document Entries Report.

        // Setup: Create and post Transfer Order as Ship and Receive.
        Initialize();
        TransferOrderNo := CreateAndPostTransferOrder();
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedTransferReceipt.OpenView();
        PostedTransferReceipt.FILTER.SetFilter("Transfer Order No.", TransferOrderNo);

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        PostedTransferReceipt."&Navigate".Invoke();  // Control is using to Navigate Page.

        // Verify: Verify Transfer Receipt Header Table Name and number of Records on Document Entries Report.
        TransferReceiptHeader.SetRange("Transfer Order No.", TransferOrderNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedTransferReceiptPage.Caption, TransferReceiptHeader.Count);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesWithPhysInvtLedgEntry()
    var
        ItemJournalLine: Record "Item Journal Line";
        PhysInventoryLedgerEntry: Record "Phys. Inventory Ledger Entry";
        PhysInventoryLedgerEntries: TestPage "Phys. Inventory Ledger Entries";
    begin
        // Verify Physical Inventory Ledger Entry on Document Entries Report.

        // Setup: Create and post Physical Inventory Journal Line.
        Initialize();
        CreateAndPostItemJournalLine(ItemJournalLine, '');  // Blank value for Location Code.
        PostItemJnlLineAfterCalculateInventory(ItemJournalLine."Item No.");
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PhysInventoryLedgerEntries.OpenView();
        PhysInventoryLedgerEntries.FILTER.SetFilter("Item No.", ItemJournalLine."Item No.");

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        PhysInventoryLedgerEntries."&Navigate".Invoke();  // Control is using to Navigate Page.

        // Verify: Verify Physical Inventory Ledger Entry Table Name and number of Records on Document Entries Report.
        PhysInventoryLedgerEntry.SetRange("Item No.", ItemJournalLine."Item No.");
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PhysInventoryLedgerEntry.TableCaption(), PhysInventoryLedgerEntry.Count);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesReportForPstdWhseRcptLn()
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // Verify Posted Warehouse Receipt Line on Document Entries Report.

        // Setup: Create Purchase Order with multiple lines, Create and post Warehouse Receipt from Purchase Order.
        Initialize();
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.FILTER.SetFilter("Order No.", CreateAndPostWhseReceiptFromPO());

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        Commit();
        PostedPurchaseReceipt."&Navigate".Invoke();  // Control is using to Navigate Page.

        // Verify: Verify Posted Warehouse Receipt Line Table Name and number of Records on Document Entries Report.
        PostedWhseReceiptLine.SetRange("Posted Source No.", Format(PostedPurchaseReceipt."No."));
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedWhseReceiptLine.TableCaption(), PostedWhseReceiptLine.Count);
    end;

    [Test]
    [HandlerFunctions('NavigatePageHandler,DocumentEntriesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DocumentEntriesReportForPstdWhseShptLn()
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        PostedReturnShipment: TestPage "Posted Return Shipment";
        DocumentNo: Code[20];
    begin
        // Verify Posted Warehouse Shipment Line on Document Entries Report.

        // Setup: Create and Release Purchase Return Order,create and post Warehouse Shipment.
        Initialize();
        DocumentNo := CreateAndPostWhseShptFromPurchaseReturnOrder();
        LibraryVariableStorage.Enqueue(false);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedReturnShipment.OpenView();
        PostedReturnShipment.FILTER.SetFilter("Return Order No.", DocumentNo);

        // Exercise: Run Document Entries Report from NavigatePagehandler.
        PostedReturnShipment."&Navigate".Invoke();  // Control is using to Navigate Page.

        // Verify: Verify Posted Warehouse Shipment Line Table Name and number of Records on Document Entries Report.
        PostedWhseShipmentLine.SetRange("Source No.", DocumentNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedWhseShipmentLine.TableCaption(), PostedWhseShipmentLine.Count);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckPostedPurchaseCreditMemoReport()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        Item: Record Item;
        DocumentNo: Code[20];
        Counter: Integer;
    begin
        // Verify that program generate multiple line on purchase credit memo report with same item no.

        // Setup: Create purchase credit memo
        Initialize();
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo", '', LibraryInventory.CreateItem(Item), CreateVendor(), '');
        for Counter := 1 to LibraryRandom.RandInt(5) do
            CreatePurchaseLine(PurchaseHeader, '', Item."No.");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // Exercise: Post Credit Memo.
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Purchase - Credit Memo", true, false, PurchCrMemoHdr);

        // Verify: Verify purchase credit memo report in XML file.
        VerifyPurchaseCreditMemoReport(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportWithEnabledPrintVATSpecInLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Setup
        Initialize();
        InitGeneralLedgerSetup(true);

        // Excercise
        CreateAndSetupPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        SavePurchaseInvoiceReport(DocumentNo);

        // Verify
        VerifyPurchaseInvoiceReportVATAmountInLCY(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('PurchaseCreditMemoRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchCreditMemoReportWithEnabledPrintVATSpecInLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // Setup
        Initialize();
        InitGeneralLedgerSetup(true);

        // Excercise
        CreateAndSetupPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::"Credit Memo");
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
        SavePurchaseCreditMemoReport(DocumentNo);

        // Verify
        VerifyPurchaseCreditMemoReportVATAmountInLCY(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RequestHandlerPurchaseDocumentTest,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseDocumentTestReportExchangeRate()
    var
        CurrencyExchangeRate: Record "Currency Exchange Rate";
        ActualResult: Variant;
        PurchaseHeaderNo: Code[20];
        ExpectedResult: Decimal;
        VATIdentifier: Code[20];
    begin
        // [FEATURE] [Purchase Document - Test]
        // [SCENARIO 378473] Purchase Document - Test report should show Exchange Rate from Purchase header in section "VAT Amount Specification ..."
        Initialize();

        // [GIVEN] Currency "C" with Exchange Rate = "X"
        CreateCurrencyWithExchRate(CurrencyExchangeRate);

        // [GIVEN] "General Ledger Setup"."Print VAT specification in LCY" = TRUE
        InitGeneralLedgerSetup(true);

        // [GIVEN] Purchase Invoice with "Currency Code" = "C" and Exchange Rate = "Y"
        CreatePurchaseInvoiceWithCurrFactor(PurchaseHeaderNo, ExpectedResult, VATIdentifier, CurrencyExchangeRate);

        // [WHEN] Run "Purchase Document - Test"
        SavePurchaseDocumentTest(PurchaseHeaderNo);

        // [THEN] Exchange Rate = "Y"
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange(VATIdentifierTok, VATIdentifier);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.GetElementValueInCurrentRow(VALExchRateTok, ActualResult);
        Assert.AreNotEqual(0, StrPos(ActualResult, Format(ExpectedResult)), WrongExchRateErr);
    end;

    [Test]
    [HandlerFunctions('PurchaseInvoiceExcelRequestPageHandler')]
    [Scope('OnPrem')]
    procedure PurchInvoiceReportLayoutWithEnabledPrintVATSpecInLCY()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentNo: Code[20];
    begin
        // [SCENARIO 379970] Report Purchase - Invoice includes VAT specification in LCY section
        Initialize();

        // [GIVEN] "General Ledger Setup"."Print VAT specification in LCY" is true
        InitGeneralLedgerSetup(true);

        // [GIVEN] Purchase Invoice posted
        CreateAndSetupPurchaseDocument(PurchaseHeader, PurchaseHeader."Document Type"::Invoice);
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [WHEN] Run Purchase - Invoice report
        SavePurchaseInvoiceReport(DocumentNo);

        // [THEN] VAT specification in LCY section printed
        VerifyPurchaseInvoiceReportVATAmountInLCYSection(DocumentNo);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckVendorBalanceToDateWithGlobalDimension1()
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        DimensionNo: array[2] of Code[20];
    begin
        // [SCENARIO 378084] Check Customer Balance To Date report with filter on Vendor."Global Dimension 1 Filter"

        // [GIVEN] Posted Purchase Invoice with Global Dimension 1 = "D1" where Amount = "A1"
        // [GIVEN] Posted Purchase Invoice with Global Dimension 1 = "D2" where Amount = "A2"
        Initialize();
        GeneralLedgerSetup.Get();
        VendorNo := CreateVendor();
        Vendor.Get(VendorNo);
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        DimensionNo[1] := DimensionValue.Code;
        DimensionNo[2] := LibraryDimension.FindDifferentDimensionValue(GeneralLedgerSetup."Global Dimension 1 Code", DimensionNo[1]);
        Vendor.Validate("Global Dimension 1 Code", DimensionNo[1]);
        Vendor.Modify();
        CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo, DimensionNo[1], '', '');
        CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo, DimensionNo[2], '', '');

        // [WHEN] Save Vendor - Balance To Date report with "Limits Total To" on Global Dimension 1 = "D2"
        RunVendorBalanceToDate(VendorNo, DimensionNo[2], '', '');

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyVendorBalanceToBalance(VendorNo, DimensionNo[2], '', '');
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckVendorBalanceToDateWithGlobalDimension2()
    var
        DimensionValue: Record "Dimension Value";
        GeneralLedgerSetup: Record "General Ledger Setup";
        Vendor: Record Vendor;
        VendorNo: Code[20];
        DimensionNo: array[2] of Code[20];
    begin
        // [SCENARIO 378084] Check Customer Balance To Date report with filter on Vendor."Global Dimension 2 Filter"

        // [GIVEN] Posted Purchase Invoice with Global Dimension 2 = "D1" where Amount = "A1"
        // [GIVEN] Posted Purchase Invoice with Global Dimension 2 = "D2" where Amount = "A2"
        Initialize();
        GeneralLedgerSetup.Get();
        VendorNo := CreateVendor();
        Vendor.Get(VendorNo);
        LibraryDimension.FindDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        DimensionNo[1] := DimensionValue.Code;
        DimensionNo[2] := LibraryDimension.FindDifferentDimensionValue(GeneralLedgerSetup."Global Dimension 2 Code", DimensionNo[1]);
        Vendor.Validate("Global Dimension 2 Code", DimensionNo[1]);
        Vendor.Modify();
        CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo, '', DimensionNo[1], '');
        CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo, '', DimensionNo[2], '');

        // [WHEN] Save Vendor - Balance To Date report with "Limits Total To" on Global Dimension 2 = "D2"
        RunVendorBalanceToDate(VendorNo, '', DimensionNo[2], '');

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyVendorBalanceToBalance(VendorNo, '', DimensionNo[2], '');
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure CheckVendorBalanceToDateWithCurrencyCode()
    var
        VendorNo: Code[20];
        CurrencyCode: Code[10];
    begin
        // [SCENARIO 378084] Check Customer Balance To Date report with filter on Vendor."Currency Filter"

        // [GIVEN] Posted Purchase Invoice with Currency Code = "C1" where Amount = "A1"
        // [GIVEN] Posted Purchase Invoice with Currency Code = "C2" where Amount = "A2"
        Initialize();
        VendorNo := CreateVendorWithCurrency();
        CurrencyCode := CreateCurrency();
        CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo, '', '', '');
        CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo, '', '', CurrencyCode);

        // [WHEN] Save Vendor - Balance To Date report with "Limits Total To" on Currency Code = "D2"
        RunVendorBalanceToDate(VendorNo, '', '', CurrencyCode);

        // [THEN] 'Original Amount' value is equal to "A2".
        VerifyVendorBalanceToBalance(VendorNo, '', '', CurrencyCode);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportWithPrepmtAndTwoLines()
    var
        ReportSelections: Record "Report Selections";
        HeaderDimensionValue: Record "Dimension Value";
        Line1DimensionValue: array[4] of Record "Dimension Value";
        Line2DimensionValue: array[4] of Record "Dimension Value";
        PrepmtGLAccount: Record "G/L Account";
        HeaderDimSetID: Integer;
        LineDimSetID: array[2] of Integer;
        DocumentNo: Code[20];
        LinePrepmtAmountValue: array[2] of Decimal;
    begin
        // [FEATURE] [Order] [Prepayment] [Dimension]
        // [SCENARIO 222383] REP 405 "Order" doesn't print dimensions in prepayment specification section
        // [SCENARIO 222383] in case of ShowInternalInfo = FALSE
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", REPORT::Order);

        // [GIVEN] Purchase order with prepayment having "Purch. Prepayments Account" = "A"
        // [GIVEN] where "A" - G\L Account with "Name" = "B", header dimension and two lines:
        // [GIVEN] Line1 with dimension and prepayment amount = 100
        // [GIVEN] Line2 with dimension and prepayment amount = 200
        CreateHeaderAndLineDimSetID(HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, HeaderDimSetID, LineDimSetID, 1);
        DocumentNo :=
          CreatePurchaseOrderWithPrepmtTwoLinesAndDims(PrepmtGLAccount, LinePrepmtAmountValue, false, HeaderDimSetID, LineDimSetID);

        // [WHEN] Print "Order" report (REP 405) using "ShowInternalInfo" = FALSE
        RunPurchaseOrderReport(DocumentNo, false);

        // [THEN] There are two lines have been printed in the prepayment section:
        // [THEN] Line1: "G/L Account No." = "A", "Description" = "B", "Amount" = 100
        // [THEN] Line2: "G/L Account No." = "A", "Description" = "B", "Amount" = 200
        // [THEN] Total: "Amount" = 300
        VerifyPurchOrderRepPrepmtSecTwoLinesWithoutDims(PrepmtGLAccount, LinePrepmtAmountValue);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportWithPrepmtTwoLinesOneDimPerLineAndShowInternalInfo()
    var
        ReportSelections: Record "Report Selections";
        HeaderDimensionValue: Record "Dimension Value";
        Line1DimensionValue: array[4] of Record "Dimension Value";
        Line2DimensionValue: array[4] of Record "Dimension Value";
        PrepmtGLAccount: Record "G/L Account";
        HeaderDimSetID: Integer;
        LineDimSetID: array[2] of Integer;
        DocumentNo: Code[20];
        LinePrepmtAmountValue: array[2] of Decimal;
    begin
        // [FEATURE] [Order] [Prepayment] [Dimension]
        // [SCENARIO 222383] Report 405 "Order" prints dimensions in prepayment specification section
        // [SCENARIO 222383] in case of ShowInternalInfo = TRUE, one dimension per line
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", REPORT::Order);

        // [GIVEN] Purchase order with prepayment having "Purch. Prepayments Account" = "A"
        // [GIVEN] where "A" - G\L Account with "Name" = "B", header dimension code\value = "HC"\"HV" and two lines:
        // [GIVEN] Line1 with dimension code\value = "L1C"\"L1V" and prepayment amount = 100
        // [GIVEN] Line2 with dimension code\value = "L2C"\"L2V" and prepayment amount = 200
        CreateHeaderAndLineDimSetID(HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, HeaderDimSetID, LineDimSetID, 1);
        DocumentNo :=
          CreatePurchaseOrderWithPrepmtTwoLinesAndDims(PrepmtGLAccount, LinePrepmtAmountValue, false, HeaderDimSetID, LineDimSetID);

        // [WHEN] Print "Order" report (REP 405) using "ShowInternalInfo" = TRUE
        RunPurchaseOrderReport(DocumentNo, true);

        // [THEN] There are four lines have been printed in the prepayment section:
        // [THEN] Line1: "G/L Account No." = "A", "Description" = "B", "Amount" = 100
        // [THEN] Line2: "Description" = "HC HV, L1C L1V"
        // [THEN] Line3: "G/L Account No." = "A", "Description" = "B", "Amount" = 200
        // [THEN] Line2: "Description" = "HC HV, L2C L2V"
        // [THEN] Total: "Amount" = 300
        VerifyPurchOrderRepPrepmtSecTwoLinesWithSingleDims(
          PrepmtGLAccount, LinePrepmtAmountValue, HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, 5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportWithPrepmtTwoLinesSevDimsPerLineAndShowInternalInfo()
    var
        ReportSelections: Record "Report Selections";
        HeaderDimensionValue: Record "Dimension Value";
        Line1DimensionValue: array[4] of Record "Dimension Value";
        Line2DimensionValue: array[4] of Record "Dimension Value";
        PrepmtGLAccount: Record "G/L Account";
        HeaderDimSetID: Integer;
        LineDimSetID: array[2] of Integer;
        DocumentNo: Code[20];
        LinePrepmtAmountValue: array[2] of Decimal;
    begin
        // [FEATURE] [Order] [Prepayment] [Dimension]
        // [SCENARIO 222383] Report 405 "Order" prints dimensions in prepayment specification section
        // [SCENARIO 222383] in case of ShowInternalInfo = TRUE, several dimensions per line
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", REPORT::Order);

        // [GIVEN] Purchase order with prepayment having "Purch. Prepayments Account" = "A"
        // [GIVEN] where "A" - G\L Account with "Name" = "B", header dimension code\value = "HC"\"HV" and two lines:
        // [GIVEN] Line1 with dimension codes\values = "L1C1"\"L1V1".."L1C4"\"L1V4" and prepayment amount = 100
        // [GIVEN] Line2 with dimension codes\values = "L2C1"\"L2V1".."L2C4"\"L2V4" and prepayment amount = 200
        CreateHeaderAndLineDimSetID(HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, HeaderDimSetID, LineDimSetID, 4);
        DocumentNo :=
          CreatePurchaseOrderWithPrepmtTwoLinesAndDims(PrepmtGLAccount, LinePrepmtAmountValue, false, HeaderDimSetID, LineDimSetID);

        // [WHEN] Print "Order" report (REP 405) using "ShowInternalInfo" = TRUE
        RunPurchaseOrderReport(DocumentNo, true);

        // [THEN] There are six lines have been printed in the prepayment section:
        // [THEN] Line1: "G/L Account No." = "A", "Description" = "B", "Amount" = 100
        // [THEN] Line2: "Description" = "HC HV, L1C1 L1V1, L1C2 L1V2"
        // [THEN] Line3: "Description" = "L1C3 L1V3, L1C4 L1V4"
        // [THEN] Line4: "G/L Account No." = "A", "Description" = "B", "Amount" = 200
        // [THEN] Line5: "Description" = "HC HV, L2C1 L2V1, L2C2 L2V2"
        // [THEN] Line6: "Description" = "L2C3 L2V3, L2C4 L2V4"
        // [THEN] Total: "Amount" = 300
        VerifyPurchOrderRepPrepmtSecTwoLinesWithMultipleDims(
          PrepmtGLAccount, LinePrepmtAmountValue, HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, 9);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportWithPrepmtTwoLinesOneDimPerLineAndShowInternalInfoPricesInclVAT()
    var
        ReportSelections: Record "Report Selections";
        HeaderDimensionValue: Record "Dimension Value";
        Line1DimensionValue: array[4] of Record "Dimension Value";
        Line2DimensionValue: array[4] of Record "Dimension Value";
        PrepmtGLAccount: Record "G/L Account";
        HeaderDimSetID: Integer;
        LineDimSetID: array[2] of Integer;
        DocumentNo: Code[20];
        LinePrepmtAmountValue: array[2] of Decimal;
    begin
        // [FEATURE] [Order] [Prepayment] [Dimension] [Prices Incl. VAT]
        // [SCENARIO 222383] Report 405 "Order" prints dimensions in prepayment specification section
        // [SCENARIO 222383] in case of ShowInternalInfo = TRUE, one dimension per line, prices including VAT
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", REPORT::Order);

        // [GIVEN] Purchase order with prepayment having "Purch. Prepayments Account" = "A"
        // [GIVEN] where "A" - G\L Account with "Name" = "B", header dimension code\value = "HC"\"HV" and two lines:
        // [GIVEN] Line1 with dimension code\value = "L1C"\"L1V" and prepayment amount = 100
        // [GIVEN] Line2 with dimension code\value = "L2C"\"L2V" and prepayment amount = 200
        CreateHeaderAndLineDimSetID(HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, HeaderDimSetID, LineDimSetID, 1);
        DocumentNo :=
          CreatePurchaseOrderWithPrepmtTwoLinesAndDims(PrepmtGLAccount, LinePrepmtAmountValue, true, HeaderDimSetID, LineDimSetID);

        // [WHEN] Print "Order" report (REP 405) using "ShowInternalInfo" = TRUE
        RunPurchaseOrderReport(DocumentNo, true);

        // [THEN] There are four lines have been printed in the prepayment section:
        // [THEN] Line1: "G/L Account No." = "A", "Description" = "B", "Amount" = 100
        // [THEN] Line2: "Description" = "HC HV, L1C L1V"
        // [THEN] Line3: "G/L Account No." = "A", "Description" = "B", "Amount" = 200
        // [THEN] Line2: "Description" = "HC HV, L2C L2V"
        // [THEN] Total: "Amount" = 300
        VerifyPurchOrderRepPrepmtSecTwoLinesWithSingleDims(
          PrepmtGLAccount, LinePrepmtAmountValue, HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, 11);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderReportWithPrepmtTwoLinesSevDimsPerLineAndShowInternalInfoPricesInclVAT()
    var
        ReportSelections: Record "Report Selections";
        HeaderDimensionValue: Record "Dimension Value";
        Line1DimensionValue: array[4] of Record "Dimension Value";
        Line2DimensionValue: array[4] of Record "Dimension Value";
        PrepmtGLAccount: Record "G/L Account";
        HeaderDimSetID: Integer;
        LineDimSetID: array[2] of Integer;
        DocumentNo: Code[20];
        LinePrepmtAmountValue: array[2] of Decimal;
    begin
        // [FEATURE] [Order] [Prepayment] [Dimension] [Prices Incl. VAT]
        // [SCENARIO 222383] Report 405 "Order" prints dimensions in prepayment specification section
        // [SCENARIO 222383] in case of ShowInternalInfo = TRUE, several dimensions per line, prices including VAT
        Initialize();
        LibraryERM.SetupReportSelection(ReportSelections.Usage::"P.Order", REPORT::Order);

        // [GIVEN] Purchase order with prepayment having "Purch. Prepayments Account" = "A"
        // [GIVEN] where "A" - G\L Account with "Name" = "B", header dimension code\value = "HC"\"HV" and two lines:
        // [GIVEN] Line1 with dimension codes\values = "L1C1"\"L1V1".."L1C4"\"L1V4" and prepayment amount = 100
        // [GIVEN] Line2 with dimension codes\values = "L2C1"\"L2V1".."L2C4"\"L2V4" and prepayment amount = 200
        CreateHeaderAndLineDimSetID(HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, HeaderDimSetID, LineDimSetID, 4);
        DocumentNo :=
          CreatePurchaseOrderWithPrepmtTwoLinesAndDims(PrepmtGLAccount, LinePrepmtAmountValue, true, HeaderDimSetID, LineDimSetID);

        // [WHEN] Print "Order" report (REP 405) using "ShowInternalInfo" = TRUE
        RunPurchaseOrderReport(DocumentNo, true);

        // [THEN] There are six lines have been printed in the prepayment section:
        // [THEN] Line1: "G/L Account No." = "A", "Description" = "B", "Amount" = 100
        // [THEN] Line2: "Description" = "HC HV, L1C1 L1V1, L1C2 L1V2"
        // [THEN] Line3: "Description" = "L1C3 L1V3, L1C4 L1V4"
        // [THEN] Line4: "G/L Account No." = "A", "Description" = "B", "Amount" = 200
        // [THEN] Line5: "Description" = "HC HV, L2C1 L2V1, L2C2 L2V2"
        // [THEN] Line6: "Description" = "L2C3 L2V3, L2C4 L2V4"
        // [THEN] Total: "Amount" = 300
        VerifyPurchOrderRepPrepmtSecTwoLinesWithMultipleDims(
          PrepmtGLAccount, LinePrepmtAmountValue, HeaderDimensionValue, Line1DimensionValue, Line2DimensionValue, 15);
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDateEnableShowEntriesWithZeroBalance')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateShowEntriesWithZeroBalance()
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // [FEATURE] [Vendor - Balance to Date]
        // [SCENARIO 275908] Report Vendor - Balance to Date shows entries with zero balance when "Show Entries with Zero Balance" was enabled on request page
        Initialize();

        // [GIVEN] Posted Invoice Gen. Journal Line with Vendor Account and Amount = -1000
        CreateGenJnlLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          LibraryPurchase.CreateVendorNo(), GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -LibraryRandom.RandDecInRange(100, 200, 2));
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Posted Credit Memo Gen. Journal Line with Vendor Account and Amount = 1000
        CreateGenJnlLineWithBalAccount(
          GenJournalLine, GenJournalLine."Document Type"::"Credit Memo", GenJournalLine."Account Type"::Vendor,
          GenJournalLine."Account No.", GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(),
          -GenJournalLine.Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [GIVEN] Stan ran report "Vendor - Balance to Date" and enabled "Show Entries with Zero Balance" on request page
        RunVendorBalanceToDate(GenJournalLine."Account No.", '', '', '');

        // [WHEN] Stan pushes OK on request page
        // Done in RHVendorBalanceToDateEnableShowEntriesWithZeroBalance

        // [THEN] Report shows formatted Invoice and Credit Memo entries for Vendor
        // [THEN] Report shows formatted balance value = 0 for Vendor
        VerifyVendorEntriesAndBalanceInVendorBalanceToDate(GenJournalLine, 0);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportPurchRequestPageHandler,PurchAnalysisMatrixExcludeByShowReportPageHandler')]
    [Scope('OnPrem')]
    procedure PurchaseAnalysisReportExcludesNoShowLinesAndColumns()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: array[2] of Record "Analysis Line";
        AnalysisColumn: array[2] of Record "Analysis Column";
    begin
        // [FEATURE] [Purchase Analysis Report]
        // [SCENARIO 359346] Purchase analysis matrix does not show lines with Show = "No" and columns with Show = "Never".
        Initialize();

        // [GIVEN] Purchase analysis report.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Purchase);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Purchase);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Purchase);

        // [GIVEN] Analysis line "L1" is set up for Show = "No".
        CreatePurchAnalysisLineWithShowSetting(AnalysisLine[1], AnalysisLineTemplate.Name, AnalysisLine[1].Show::No);
        LibraryVariableStorage.Enqueue(AnalysisLine[1]);

        // [GIVEN] Analysis line "L2" is set up for Show = "Yes".
        CreatePurchAnalysisLineWithShowSetting(AnalysisLine[2], AnalysisLineTemplate.Name, AnalysisLine[2].Show::Yes);
        LibraryVariableStorage.Enqueue(AnalysisLine[2]);

        // [GIVEN] Analysis column "C1" is set up for Show = "Never".
        CreatePurchAnalysisColumnWithShowSetting(AnalysisColumn[1], AnalysisColumnTemplate.Name, AnalysisColumn[1].Show::Never);
        LibraryVariableStorage.Enqueue(AnalysisColumn[1]);

        // [GIVEN] Analysis column "C2" is set up for Show = "Always".
        CreatePurchAnalysisColumnWithShowSetting(AnalysisColumn[2], AnalysisColumnTemplate.Name, AnalysisColumn[2].Show::Always);
        LibraryVariableStorage.Enqueue(AnalysisColumn[2]);

        // [WHEN] Open Purchase Analysis Matrix to view the report.
        OpenAnalysisReportPurch(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [THEN] Line "L1" is not shown, Line "L2" is visible.
        // [THEN] Column "C1" is not shown, Column "C2" is visible.
        // [THEN] The matrix has maximum of 32 columns, but only one column ("C2") is now visible.
        // The verification is done in PurchAnalysisMatrixExcludeByShowReportPageHandler handler.
    end;

    [Test]
    [HandlerFunctions('RHVendorBalanceToDate')]
    [Scope('OnPrem')]
    procedure VendorBalanceToDateRemainingAmount()
    var
        GenJournalLine: array[3] of Record "Gen. Journal Line";
        Vendor: Record Vendor;
        AutoFormat: Codeunit "Auto Format";
    begin
        // [FEATURE] [Vendor - Balance to Date]
        // [SCENARIO 288122] Remaining Amount in "Vendor - Balance to Date" report shows sum of invoice that is closed at a later date.
        Initialize();

        // [GIVEN] Invoice Gen. Jnl. Line with Amount 'X', Payment Gen. Jnl. Line with Amount 'Y', Payment Gen. Jnl. Line with Amount -'X'-'Y'
        LibraryPurchase.CreateVendor(Vendor);
        CreateGenJournalLine(
          GenJournalLine[1], WorkDate(), Vendor."No.",
          GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document Type"::" ", '', LibraryRandom.RandIntInRange(-1000, -500));
        LibraryERM.PostGeneralJnlLine(GenJournalLine[1]);

        CreateGenJournalLine(
          GenJournalLine[2], WorkDate() + 1, Vendor."No.",
          GenJournalLine[1]."Document Type"::Payment, GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document No.", LibraryRandom.RandInt(499));
        LibraryERM.PostGeneralJnlLine(GenJournalLine[2]);

        CreateGenJournalLine(
          GenJournalLine[3], WorkDate() + 2, Vendor."No.",
          GenJournalLine[1]."Document Type"::Payment, GenJournalLine[1]."Document Type"::Invoice, GenJournalLine[1]."Document No.", -GenJournalLine[1].Amount - GenJournalLine[2].Amount);
        LibraryERM.PostGeneralJnlLine(GenJournalLine[3]);

        // [WHEN] "Vendor - Balance to Date" report is run
        Vendor.SetRange("No.", Vendor."No.");
        Vendor.SetRange("Date Filter", WorkDate() + 1);
        REPORT.Run(REPORT::"Vendor - Balance to Date", true, false, Vendor);

        // [THEN] RemainingAmt is equal to 'X' + 'Y'
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('RemainingAmt',
            Format(GenJournalLine[1].Amount + GenJournalLine[2].Amount, 0,
                AutoFormat.ResolveAutoFormat("Auto Format"::AmountFormat, GenJournalLine[1]."Currency Code")));
    end;

    [Test]
    [HandlerFunctions('StandardPurchaseOrderRequestPageHandler')]
    procedure StandardPurchaseOrderReceiptDates()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Standard Purchase - Order]
        // [SCENARIO 330370] Fields Planned/Expected/Promised/Requested Receipt Date are available in the report Standard Purchase - Order dataset

        // [GIVEN] Create purchase order with one line, where Planned
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);

        // [GIVEN] Set Planned/Expected/Promised/Requested Receipt Dates = 01.01, 02.01, 03.01, 04.01
        UpdatePurchaseLineReceiptDates(PurchaseLine);

        // [WHEN] Report Standard Purchase - Order is being printed
        Commit();
        Report.Run(Report::"Standard Purchase - Order", true, false, PurchaseHeader);

        // [THEN] Report dataset has Planned/Expected/Promised/Requested Receipt Dates = 01.01, 02.01, 03.01, 04.01
        VerifyStandardPurchaseOrderReceiptDates(PurchaseLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"ERM Purchase Reports III");
        Clear(LibraryReportDataset);
        Clear(LibraryReportValidation);
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"ERM Purchase Reports III");

        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdatePrepaymentAccounts();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibrarySetupStorage.Save(DATABASE::"Purchases & Payables Setup");
        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"ERM Purchase Reports III");
    end;

    local procedure InitGeneralLedgerSetup(VATSpecificationInLCY: Boolean)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        GeneralLedgerSetup."Print VAT specification in LCY" := VATSpecificationInLCY;
        GeneralLedgerSetup.Modify(true);
    end;

    local procedure AssignedQuantityOnPurchaseDocumentTestReport(DocumentType: Enum "Purchase Document Type")
    var
        PurchaseHeader: Record "Purchase Header";
        TotalAssignedQuantityForChargeItem: Decimal;
        ItemChargeNo: Code[20];
    begin
        // Setup: Create Purchase Document with Item and Charge Items.
        Initialize();
        CreatePurchaseOrder(
          PurchaseHeader, DocumentType, '', LibraryInventory.CreateItemNo(), CreateVendor(), '');  // Blank value for Currency Code and Location Code.
        ItemChargeNo := LibraryInventory.CreateItemChargeNo();
        TotalAssignedQuantityForChargeItem :=
          CreateMultiplePurchaseLinesWithChargeItem(PurchaseHeader, ItemChargeNo);

        // Exercise: Save Purchase Docment Test Report using Purchase Document Test Request Page Handler.
        Commit();  // Due to limitation in Report Commit is required for this Test case.
        RunPurchaseDocumentTestReport(PurchaseHeader);

        // Verify: Verify Assignable Quantity on Purchase Document Test Report.
        LibraryReportDataset.LoadDataSetFile();
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'Purchase_Line___No__', ItemChargeNo);
        Assert.AreEqual(TotalAssignedQuantityForChargeItem, LibraryReportDataset.Sum('PurchLine2_Quantity'), AssignedQuantityErr);
    end;

    local procedure CreateVendorWithVATPostingSetup(VATPostingSetup: Record "VAT Posting Setup"): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", VATPostingSetup."VAT Bus. Posting Group");
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; LocationCode: Code[10])
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateItemJournalBatch(ItemJournalBatch);

        // Use Random value for Quantity
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.",
          LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(10, 2));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndSetupPurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type")
    var
        PurchaseLine: Record "Purchase Line";
        VATPostingSetup: Record "VAT Posting Setup";
        GLAccount: Record "G/L Account";
        CurrencyCode: Code[10];
        ExchangeRate: Decimal;
        LineQuantity: Decimal;
        LineUnitCost: Decimal;
        VATPercent: Integer;
    begin
        // Certain values to get rounding error
        LineQuantity := 1;
        LineUnitCost := 2575872;
        ExchangeRate := 1.284;
        VATPercent := 10;

        // Init setups
        CurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), ExchangeRate, ExchangeRate);
        LibraryERM.UpdateVATPostingSetup(VATPostingSetup, VATPercent);

        // Cteare and post document
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, DocumentType, CreateVendorWithVATPostingSetup(VATPostingSetup));
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Validate("Posting Date", WorkDate());
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account",
          LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase), LineQuantity);
        PurchaseLine.Validate("Direct Unit Cost", LineUnitCost);
        PurchaseLine.Validate("VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostWhseShptFromPurchaseReturnOrder(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        // Create and Release Purchase Return Order.
        CreateAndReleasePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateLocationWithWarehouseEmployee(true, false));

        // Create Warehouse Shipment from Purchase return Order. Post Warehouse Shipment.
        LibraryWarehouse.CreateWhseShipmentFromPurchaseReturnOrder(PurchaseHeader);
        WarehouseShipmentLine.SetRange("Source Document", WarehouseShipmentLine."Source Document"::"Purchase Return Order");
        WarehouseShipmentLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);  // Post as Ship.
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndPostGeneralJournalLineWithDimensions(AccountNo: Code[20]; GlobalDim1Value: Code[20]; GlobalDim2Value: Code[20]): Decimal
    var
        GenJournalBatch: Record "Gen. Journal Batch";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SelectGenJournalBatch(GenJournalBatch);
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, GenJournalLine."Document Type"::Invoice,
          GenJournalLine."Account Type"::Vendor, AccountNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDim1Value);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", GlobalDim2Value);
        GenJournalLine.Modify(true);
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        exit(-GenJournalLine.Amount);
    end;

    local procedure CreateAndPostTransferOrder(): Code[20]
    var
        InventorySetup: Record "Inventory Setup";
        ItemJournalLine: Record "Item Journal Line";
        LocationInTransit: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        TransferRoute: Record "Transfer Route";
        LocationFrom: Code[10];
        LocationTo: Code[10];
    begin
        // Create Transfer Route. Create and post Item Journal Line.
        LocationFrom := CreateLocationWithWarehouseEmployee(false, false);
        LocationTo := CreateLocationWithWarehouseEmployee(false, false);
        LibraryWarehouse.CreateInTransitLocation(LocationInTransit);
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationFrom, LocationTo);
        CreateAndPostItemJournalLine(ItemJournalLine, LocationFrom);

        // Update Number Series of Posted Transfer Receipt Number. Create and post Transfer Order as Ship and Receive.
        InventorySetup.Get();
        InventorySetup.Validate("Posted Transfer Rcpt. Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        InventorySetup.Modify(true);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, LocationFrom, LocationTo, LocationInTransit.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemJournalLine."Item No.", ItemJournalLine.Quantity);
        LibraryWarehouse.ReleaseTransferOrder(TransferHeader);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
        exit(TransferHeader."No.")
    end;

    local procedure CreateAndPostWhseReceiptFromPO(): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        // Create and Release Purchase Order.
        CreateAndReleasePurchaseDocument(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateLocationWithWarehouseEmployee(false, true));

        // Create and post Warehouse Receipt.
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        WarehouseReceiptLine.SetRange("Source Document", WarehouseReceiptLine."Source Document"::"Purchase Order");
        WarehouseReceiptLine.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseReceiptLine.FindFirst();
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
        exit(PurchaseHeader."No.");
    end;

    local procedure CreateAndReleasePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; LocationCode: Code[10])
    begin
        CreatePurchaseOrder(
          PurchaseHeader, DocumentType, '', LibraryInventory.CreateItemNo(), CreateVendor(), LocationCode);  // Blank value for Currency Code.
        CreatePurchaseLine(PurchaseHeader, LocationCode, LibraryInventory.CreateItemNo());
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreatePurchaseDocSaveReport(VendorInvoiceNo: Code[20]; DocumentType: Enum "Purchase Document Type")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocumentTest: Report "Purchase Document - Test";
    begin
        // Setup.
        LibraryPurchase.CreateVendor(Vendor);
        CreatePurchaseDocument(PurchaseHeader, Vendor."No.", VendorInvoiceNo, DocumentType, LibraryInventory.CreateItemNo());

        // Exercise: Save Purchase Document Test Report with Receive and Invoice Option.
        Clear(PurchaseDocumentTest);
        PurchaseHeader.SetRange("Document Type", DocumentType);
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        PurchaseDocumentTest.InitializeRequest(true, true, false, false);
        Commit();
        PurchaseDocumentTest.Run();
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; CurrencyCode: Code[10]; ItemNo: Code[20]; VendorNo: Code[20]; LocationCode: Code[10])
    begin
        // Create Purchase Document with Random Quantity and Direct Unit Cost for Item.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Currency Code", CurrencyCode);
        PurchaseHeader.Validate("Vendor Cr. Memo No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        CreatePurchaseLine(PurchaseHeader, LocationCode, ItemNo);
    end;

    local procedure CreatePurchaseLine(var PurchaseHeader: Record "Purchase Header"; LocationCode: Code[10]; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDec(10, 2));  // Use Random Value.
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2)); // Use Random Value.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderWithPrepmtTwoLinesAndDims(var PrepmtGLAccount: Record "G/L Account"; var LinePrepmtAmountValue: array[2] of Decimal; PricesInclVAT: Boolean; HeaderDimSetID: Integer; LineDimSetID: array[2] of Integer): Code[20]
    var
        VATPostingSetup: Record "VAT Posting Setup";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        i: Integer;
    begin
        LibraryERM.CreateVATPostingSetupWithAccounts(
          VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", LibraryRandom.RandIntInRange(10, 30));
        LibraryPurchase.CreatePurchHeader(
          PurchaseHeader, PurchaseHeader."Document Type"::Order,
          LibraryPurchase.CreateVendorWithVATBusPostingGroup(VATPostingSetup."VAT Bus. Posting Group"));
        PurchaseHeader.Validate("Prices Including VAT", PricesInclVAT);
        PurchaseHeader.Validate("Prepayment %", LibraryRandom.RandIntInRange(10, 30));
        PurchaseHeader.Validate("Dimension Set ID", HeaderDimSetID);
        PurchaseHeader.Modify(true);

        CreateGLAccountWithVATSetupAndDescription(PrepmtGLAccount, VATPostingSetup);
        UpdateGenPostingSetup(
          PurchaseHeader."Gen. Bus. Posting Group", PrepmtGLAccount."Gen. Prod. Posting Group", PrepmtGLAccount."No.");
        for i := 1 to ArrayLen(LineDimSetID) do begin
            LibraryPurchase.CreatePurchaseLine(
              PurchaseLine, PurchaseHeader, PurchaseLine.Type::"G/L Account", PrepmtGLAccount."No.", 1);
            PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1000, 2000, 2));
            PurchaseLine.Validate("Dimension Set ID", LineDimSetID[i]);
            PurchaseLine.Modify(true);
            LinePrepmtAmountValue[i] := PurchaseLine."Prepmt. Line Amount";
        end;

        exit(PurchaseHeader."No.");
    end;

    local procedure CreateItemWithDimension(var DefaultDimension: Record "Default Dimension")
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.FindDimension(Dimension);
        LibraryDimension.FindDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, LibraryInventory.CreateItemNo(), DimensionValue."Dimension Code", DimensionValue.Code);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.CreateItemJournalTemplate(ItemJournalTemplate);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreateLocationWithWarehouseEmployee(RequireShipment: Boolean; RequireReceive: Boolean): Code[10]
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Require Shipment", RequireShipment);
        Location.Validate("Require Receive", RequireReceive);
        Location.Modify(true);
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        exit(Location.Code);
    end;

    local procedure CreateGenJnlLineWithBalAccount(var GenJournalLine: Record "Gen. Journal Line"; DocType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; BalAccountType: Enum "Gen. Journal Account Type"; BalAccountNo: Code[20]; Amount: Decimal)
    var
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryJournals.CreateGenJournalBatch(GenJournalBatch);
        CreateGenJnlLine(GenJournalLine, GenJournalBatch, DocType, AccountType, AccountNo, Amount);
        GenJournalLine.Validate("Bal. Account Type", BalAccountType);
        GenJournalLine.Validate("Bal. Account No.", BalAccountNo);
        GenJournalLine.Modify(true);
    end;

    local procedure CreateGenJnlLine(var GenJournalLine: Record "Gen. Journal Line"; GenJournalBatch: Record "Gen. Journal Batch"; DocumentType: Enum "Gen. Journal Document Type"; AccountType: Enum "Gen. Journal Account Type"; AccountNo: Code[20]; Quantity: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType, AccountType, AccountNo, Quantity);
    end;

    [Scope('OnPrem')]
    procedure CreateGenJournalLine(var GenJournalLine: Record "Gen. Journal Line"; PostingDate: Date; CustomerNo: Code[20]; DocumentType: Enum "Gen. Journal Document Type"; AppliesToDocType: Enum "Gen. Journal Document Type"; AppliesToDocNo: Code[20]; Amount: Integer)
    var
        GLAccount: Record "G/L Account";
        GenJournalTemplate: Record "Gen. Journal Template";
        GenJournalBatch: Record "Gen. Journal Batch";
    begin
        LibraryERM.CreateGLAccount(GLAccount);

        GenJournalTemplate.SetRange(Type, GenJournalTemplate.Type::Purchases);
        GenJournalTemplate.SetRange(Recurring, false);
        LibraryERM.FindGenJournalTemplate(GenJournalTemplate);
        LibraryERM.CreateGenJournalBatch(GenJournalBatch, GenJournalTemplate.Name);

        LibraryERM.CreateGeneralJnlLine(
          GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name, DocumentType,
          GenJournalLine."Account Type"::Vendor, CustomerNo, Amount);
        GenJournalLine.Validate("Bal. Account No.", GLAccount."No.");
        GenJournalLine.Validate("Applies-to Doc. Type", AppliesToDocType);
        GenJournalLine.Validate("Applies-to Doc. No.", AppliesToDocNo);
        GenJournalLine.Validate("Posting Date", PostingDate);
        GenJournalLine.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; VendorNo: Code[20]; VendorInvoiceNo: Code[20]; DocumentType: Enum "Purchase Document Type"; No: Code[20]): Decimal
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, VendorNo);
        PurchaseHeader.Validate("Vendor Invoice No.", VendorInvoiceNo);
        PurchaseHeader.Modify(true);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, LibraryRandom.RandDec(10, 2));  // Use Random Value for Purchase Line Quantity.
        ModifyDirectUnitCostOnPurchaseLine(PurchaseLine, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
        PurchaseHeader.CalcFields("Amount Including VAT");
        LibraryPurchase.ReopenPurchaseDocument(PurchaseHeader);
        exit(PurchaseHeader."Amount Including VAT");
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
        PaymentMethod: Record "Payment Method";
    begin
        LibraryPurchase.CreateVendor(Vendor);
        PaymentMethod.SetRange("Bal. Account No.", '');
        LibraryERM.FindPaymentMethod(PaymentMethod);
        Vendor.Validate("Payment Method Code", PaymentMethod.Code);
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateMultiplePurchaseLinesWithChargeItem(var PurchaseHeader: Record "Purchase Header"; ItemChargeNo: Code[20]) PurchaseLineQuantity: Decimal
    var
        ItemChargeAssignmentPurch: Record "Item Charge Assignment (Purch)";
        PurchaseLine: Record "Purchase Line";
        "Count": Integer;
        Quantity: Decimal;
    begin
        Quantity := LibraryRandom.RandDec(10, 2);
        for Count := 1 to LibraryRandom.RandIntInRange(2, 5) do begin
            LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)", ItemChargeNo, Quantity);
            LibraryInventory.CreateItemChargeAssignPurchase(
              ItemChargeAssignmentPurch, PurchaseLine, PurchaseLine."Document Type", PurchaseLine."Document No.", PurchaseLine."Line No.",
              ItemChargeNo);
            PurchaseLineQuantity += PurchaseLine.Quantity;
        end;
        PurchaseLine.ModifyAll("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        exit(PurchaseLineQuantity);
    end;

    local procedure CreateCurrency(): Code[10]
    var
        Currency: Record Currency;
    begin
        LibraryERM.CreateCurrency(Currency);
        LibraryERM.CreateRandomExchangeRate(Currency.Code);
        exit(Currency.Code);
    end;

    local procedure CreateGlobalDimValues(var GlobalDim1Value: Code[20]; var GlobalDim2Value: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        DimensionValue: Record "Dimension Value";
    begin
        GeneralLedgerSetup.Get();
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 1 Code");
        GlobalDim1Value := DimensionValue.Code;
        LibraryDimension.CreateDimensionValue(DimensionValue, GeneralLedgerSetup."Global Dimension 2 Code");
        GlobalDim2Value := DimensionValue.Code;
    end;

    local procedure CreateCurrencyWithExchRate(var CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        CurrencyCode: Code[10];
    begin
        CurrencyCode := LibraryERM.CreateCurrencyWithRandomExchRates();
        CurrencyExchangeRate.SetRange("Currency Code", CurrencyCode);
        CurrencyExchangeRate.FindFirst();
    end;

    local procedure CreatePurchaseInvoiceWithCurrFactor(var PurchaseHeaderNo: Code[20]; var ExpectedResult: Decimal; var VATIdentifier: Code[20]; CurrencyExchangeRate: Record "Currency Exchange Rate")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, LibraryPurchase.CreateVendorNo());
        LibraryInventory.CreateItemWithUnitPriceAndUnitCost(Item, LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2));
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        PurchaseHeader.Validate("Currency Code", CurrencyExchangeRate."Currency Code");
        PurchaseHeader.Validate("Currency Factor",
          CurrencyExchangeRate."Exchange Rate Amount" / CurrencyExchangeRate."Relational Exch. Rate Amount" +
          LibraryRandom.RandDec(100, 2));
        PurchaseHeader.Modify(true);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        PurchaseHeaderNo := PurchaseHeader."No.";
        ExpectedResult := Round(CurrencyExchangeRate."Exchange Rate Amount" / PurchaseHeader."Currency Factor", 0.000001);
        VATIdentifier := PurchaseLine."VAT Identifier";
    end;

    local procedure CreateVendorWithCurrency(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        Vendor.Get(CreateVendor());
        Vendor.Validate("Currency Code", CreateCurrency());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure CreateCustomerAndPostGenJnlLinesWithFilters(VendorNo: Code[20]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; CurrencyCode: Code[10])
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryJournals.CreateGenJournalLineWithBatch(
          GenJournalLine, GenJournalLine."Document Type"::Invoice, GenJournalLine."Account Type"::Vendor,
          VendorNo, -LibraryRandom.RandDec(100, 2));
        GenJournalLine.Validate("Shortcut Dimension 1 Code", GlobalDimension1Code);
        GenJournalLine.Validate("Shortcut Dimension 2 Code", GlobalDimension2Code);
        GenJournalLine.Validate("Currency Code", CurrencyCode);
        GenJournalLine.Modify();
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
    end;

    local procedure CreateHeaderAndLineDimSetID(var HeaderDimensionValue: Record "Dimension Value"; var Line1DimensionValue: array[4] of Record "Dimension Value"; var Line2DimensionValue: array[4] of Record "Dimension Value"; var HeaderDimSetID: Integer; var LineDimSetID: array[2] of Integer; NoOfDimsPerLine: Integer)
    var
        i: Integer;
    begin
        LibraryDimension.CreateDimWithDimValue(HeaderDimensionValue);
        HeaderDimSetID := LibraryDimension.CreateDimSet(0, HeaderDimensionValue."Dimension Code", HeaderDimensionValue.Code);
        LineDimSetID[1] := HeaderDimSetID;
        LineDimSetID[2] := HeaderDimSetID;

        for i := 1 to NoOfDimsPerLine do begin
            LibraryDimension.CreateDimWithDimValue(Line1DimensionValue[i]);
            LineDimSetID[1] :=
              LibraryDimension.CreateDimSet(LineDimSetID[1], Line1DimensionValue[i]."Dimension Code", Line1DimensionValue[i].Code);

            LibraryDimension.CreateDimWithDimValue(Line2DimensionValue[i]);
            LineDimSetID[2] :=
              LibraryDimension.CreateDimSet(LineDimSetID[2], Line2DimensionValue[i]."Dimension Code", Line2DimensionValue[i].Code);
        end;
    end;

    local procedure CreateGLAccountWithVATSetupAndDescription(var GLAccount: Record "G/L Account"; VATPostingSetup: Record "VAT Posting Setup")
    begin
        GLAccount.Get(LibraryERM.CreateGLAccountWithVATPostingSetup(VATPostingSetup, GLAccount."Gen. Posting Type"::Purchase));
        GLAccount.Validate(Name, LibraryUtility.GenerateGUID());
        GLAccount.Modify(true);
    end;

    local procedure CreatePurchAnalysisLineWithShowSetting(var AnalysisLine: Record "Analysis Line"; AnalysisLineTemplateName: Code[10]; ShowSetting: Option)
    begin
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLine."Analysis Area"::Purchase, AnalysisLineTemplateName);
        AnalysisLine.Validate(Show, ShowSetting);
        AnalysisLine.Modify(true);
    end;

    local procedure CreatePurchAnalysisColumnWithShowSetting(var AnalysisColumn: Record "Analysis Column"; AnalysisColumnTemplateName: Code[10]; ShowSetting: Option)
    begin
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Purchase, AnalysisColumnTemplateName);
        AnalysisColumn.Validate("Column Header", LibraryUtility.GenerateGUID());
        AnalysisColumn.Validate(Show, ShowSetting);
        AnalysisColumn.Modify(true);
    end;

    local procedure SelectGenJournalBatch(var GenJournalBatch: Record "Gen. Journal Batch")
    begin
        // Select General Journal Batch and clear General Journal Lines to make sure that no line exist before creating
        // General Journal Lines.
        LibraryERM.SelectGenJnlBatch(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch)
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Quote);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindFirst();
    end;

    local procedure FindPurchOrderRepPrepmtSpecColumnRowNo(var StartingRowNo: Integer; var GLAccountColumn: Integer; var DescriptionColumn: Integer; var AmountColumn: Integer)
    var
        PrepaymentSpecificationHeaderRowNo: Integer;
    begin
        LibraryReportValidation.OpenExcelFile();
        PrepaymentSpecificationHeaderRowNo := LibraryReportValidation.FindRowNoFromColumnNoAndValue(1, 'Prepayment Specification');
        StartingRowNo := PrepaymentSpecificationHeaderRowNo + 4;
        GLAccountColumn :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'G/L Account No.', StrSubstNo('>%1', PrepaymentSpecificationHeaderRowNo), '');
        DescriptionColumn :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Description', StrSubstNo('>%1', PrepaymentSpecificationHeaderRowNo), '');
        AmountColumn :=
          LibraryReportValidation.FindColumnNoFromColumnCaptionInsideArea(
            'Amount', StrSubstNo('>%1', PrepaymentSpecificationHeaderRowNo), '');
    end;

    local procedure ModifyCurrencyCodeOnPurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate("Currency Code", CreateCurrency());
        PurchaseHeader.Modify(true);
    end;

    local procedure ModifyDirectUnitCostOnPurchaseLine(var PurchaseLine: Record "Purchase Line"; DirectUnitCost: Decimal)
    begin
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure OpenAnalysisReportPurch(AnalysisReportName: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportPurchase: TestPage "Analysis Report Purchase";
    begin
        AnalysisReportPurchase.OpenEdit();
        AnalysisReportPurchase.FILTER.SetFilter(Name, AnalysisReportName);
        AnalysisReportPurchase."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportPurchase."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportPurchase.EditAnalysisReport.Invoke();
    end;

    local procedure PostItemJnlLineAfterCalculateInventory(ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal Batch with Document Number.
        CreateItemJournalBatch(ItemJournalBatch);

        // Calculate Inventory and Post Item Journal Line.
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure RunPurchaseDocumentTestReport(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        REPORT.Run(REPORT::"Purchase Document - Test", true, false, PurchaseHeader);
    end;

    local procedure RunPurchaseCreditMemoTestReport(DocNo: Code[20])
    var
        PurchaseCreditMemo: TestPage "Purchase Credit Memo";
    begin
        PurchaseCreditMemo.OpenEdit();
        PurchaseCreditMemo.FILTER.SetFilter("No.", DocNo);
        PurchaseCreditMemo.TestReport.Invoke();
    end;

    local procedure RunVendorTrialBalanceReport(VendorNo: Code[20]; PostingDate: Date; Dim1Filter: Code[20]; Dim2Filter: Code[20])
    var
        Vendor: Record Vendor;
        VendorTrialBalance: Report "Vendor - Trial Balance";
    begin
        Clear(VendorTrialBalance);
        Vendor.SetRange("No.", VendorNo);
        Vendor.SetRange("Date Filter", PostingDate);
        Vendor.SetFilter("Global Dimension 1 Filter", Dim1Filter);
        Vendor.SetFilter("Global Dimension 2 Filter", Dim2Filter);
        VendorTrialBalance.SetTableView(Vendor);
        VendorTrialBalance.Run();
    end;

    local procedure RunVendorBalanceToDate(VendorNo: Code[20]; GlobalDimension1Filter: Text; GlobalDimension2Filter: Text; CurrencyFilter: Text)
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("No.", VendorNo);
        Vendor.SetRange("Global Dimension 1 Filter", GlobalDimension1Filter);
        Vendor.SetRange("Global Dimension 2 Filter", GlobalDimension2Filter);
        Vendor.SetRange("Currency Filter", CurrencyFilter);
        Vendor.SetRange("Date Filter", WorkDate());
        REPORT.Run(REPORT::"Vendor - Balance to Date", true, false, Vendor);
    end;

    local procedure RunPurchaseOrderReport(DocumentNo: Code[20]; ShowInternalInfo: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        "Order": Report "Order";
    begin
        PurchaseHeader.SetRange("No.", DocumentNo);
        LibraryReportValidation.SetFileName('test');
        Clear(Order);
        Order.SetTableView(PurchaseHeader);
        Order.InitializeRequest(0, ShowInternalInfo, false, false);
        Order.UseRequestPage(false);
        Order.SaveAsExcel(LibraryReportValidation.GetFileName());
    end;

    local procedure SetupPrepaymentPurchaseDoc(var PurchaseLine: Record "Purchase Line"; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        GeneralPostingSetup: Record "General Posting Setup";
        GLAccount: Record "G/L Account";
    begin
        // Setup.
        CreatePurchaseDocument(
          PurchaseHeader, VendorNo, Format(LibraryRandom.RandInt(100)),
          PurchaseHeader."Document Type"::Order, LibraryInventory.CreateItemNo());
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.FindFirst();

        GeneralPostingSetup.Get(PurchaseLine."Gen. Bus. Posting Group", PurchaseLine."Gen. Prod. Posting Group");
        GLAccount.Get(GeneralPostingSetup."Purch. Prepayments Account");
        GLAccount."VAT Prod. Posting Group" := PurchaseLine."VAT Prod. Posting Group";
        GLAccount.Modify();

        PurchaseLine.Validate("Prepayment %", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);

        // Exercise.
        PurchaseHeader.SetRange("No.", PurchaseHeader."No.");
        Commit();
        REPORT.Run(REPORT::"Purchase Prepmt. Doc. - Test", true, false, PurchaseHeader);
    end;

    local procedure SetupForDocEntryReportForPurchaseInvoice(var PurchInvHeader: Record "Purch. Inv. Header"; ShowLCY: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseInvoice: TestPage "Posted Purchase Invoice";
        PostedPurchaseInvoice2: Page "Posted Purchase Invoice";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchase Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateCurrency(),
          LibraryInventory.CreateItemNo(), CreateVendor(), '');  // Blank value for Location Code.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Invoice.
        LibraryVariableStorage.Enqueue(ShowLCY);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedPurchaseInvoice.OpenEdit();
        PostedPurchaseInvoice.FILTER.SetFilter("No.", DocumentNo);

        // Exercise: Open Nevigate page.
        PostedPurchaseInvoice."&Navigate".Invoke();  // Invoking Navigate.

        // Verify: Verify various entries on Document Entry report.
        PurchInvHeader.SetRange("No.", DocumentNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedPurchaseInvoice2.Caption, PurchInvHeader.Count);
        VerifyVariousEntriesOnDocEntriesReport(DocumentNo);
        PurchInvHeader.FindFirst();
        PurchInvHeader.CalcFields(Amount);
    end;

    local procedure SetupForDocEntryReportForPurchCreditMemo(var PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr."; ShowLCY: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
        PostedPurchaseCreditMemo: TestPage "Posted Purchase Credit Memo";
        PostedPurchaseCreditMemoPage: Page "Posted Purchase Credit Memo";
        DocumentNo: Code[20];
    begin
        // Setup: Create and post Purchase Return Order.
        Initialize();
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", CreateCurrency(),
          LibraryInventory.CreateItemNo(), CreateVendor(), '');  // Blank value for Location Code.
        DocumentNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);  // TRUE for Invoice.
        LibraryVariableStorage.Enqueue(ShowLCY);  // Enqueue for DocumentEntriesRequestPageHandler.
        PostedPurchaseCreditMemo.OpenEdit();
        PostedPurchaseCreditMemo.FILTER.SetFilter("No.", DocumentNo);

        // Exercise: Open Nevigate page.
        PostedPurchaseCreditMemo."&Navigate".Invoke();  // Invoking Navigate.

        // Verify: Verify entries on Document Entry report.
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        LibraryReportDataset.LoadDataSetFile();
        VerifyDocumentEntriesReport(PostedPurchaseCreditMemoPage.Caption, PurchCrMemoHdr.Count);
        VerifyVariousEntriesOnDocEntriesReport(DocumentNo);
        PurchCrMemoHdr.FindFirst();
        PurchCrMemoHdr.CalcFields(Amount);
    end;

    local procedure SavePurchaseQuoteReport(No: Code[20]; VendorNo: Code[20]; ShowInternalInfo: Boolean; ArchiveDocument: Boolean; LogInteraction: Boolean)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryVariableStorage.Enqueue(ShowInternalInfo);
        LibraryVariableStorage.Enqueue(ArchiveDocument);
        LibraryVariableStorage.Enqueue(LogInteraction);
        PurchaseHeader.SetRange("No.", No);
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        Commit();
        REPORT.Run(REPORT::"Purchase - Quote", true, false, PurchaseHeader);
    end;

    local procedure SetupInvoiceDiscount(var VendorInvoiceDisc: Record "Vendor Invoice Disc.")
    begin
        // Required Random Value for "Minimum Amount" and "Discount %" fields value is not important.
        LibraryERM.CreateInvDiscForVendor(VendorInvoiceDisc, CreateVendor(), '', LibraryRandom.RandInt(100));
        VendorInvoiceDisc.Validate("Discount %", LibraryRandom.RandDec(10, 2));
        VendorInvoiceDisc.Modify(true);
    end;

    local procedure UpdatePurchasePayablesSetup(DefaultPostingDate: Enum "Default Posting Date")
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Default Posting Date", DefaultPostingDate);
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure UpdatePurchasePayablesSetupCalcInvDisc(CalcInvDiscount: Boolean)
    var
        PurchasePayablesSetup: Record "Purchases & Payables Setup";
    begin
        PurchasePayablesSetup.Get();
        PurchasePayablesSetup.Validate("Calc. Inv. Discount", CalcInvDiscount);
        PurchasePayablesSetup.Modify(true);
    end;

    local procedure UpdateGenPostingSetup(GenBusPostingGroupCode: Code[20]; GenProdPostingGroupCode: Code[20]; PurchPrepmtAccountNo: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
    begin
        GeneralPostingSetup.Get(GenBusPostingGroupCode, GenProdPostingGroupCode);
        GeneralPostingSetup.Validate("Purch. Prepayments Account", PurchPrepmtAccountNo);
        GeneralPostingSetup.Modify(true);
    end;

    local procedure UpdatePurchaseLineReceiptDates(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine."Expected Receipt Date" := CalcDate('<+1D>', PurchaseLine."Planned Receipt Date");
        PurchaseLine."Promised Receipt Date" := CalcDate('<+2D>', PurchaseLine."Planned Receipt Date");
        PurchaseLine."Requested Receipt Date" := CalcDate('<+3D>', PurchaseLine."Planned Receipt Date");
        PurchaseLine.Modify();
    end;

    local procedure SavePurchaseDocumentTest(No: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseDocumentTest: Report "Purchase Document - Test";
    begin
        Clear(PurchaseDocumentTest);
        PurchaseHeader.SetRange("No.", No);
        PurchaseDocumentTest.SetTableView(PurchaseHeader);
        PurchaseDocumentTest.InitializeRequest(true, true, false, false);
        Commit();
        PurchaseDocumentTest.Run();
    end;

    local procedure VerifyAmountOnDocumentEntryReport(RowCaption: Text[50]; ColumnCaption: Text[50]; Amount: Decimal)
    begin
        LibraryReportDataset.SetRange(RowCaption, Format(WorkDate()));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, Amount);
    end;

    local procedure VerifyDocumentEntriesReport(RowValue: Text; ColumnValue: Decimal)
    begin
        LibraryReportDataset.SetRange(DocEntryTableNameLbl, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(DocEntryNoofRecordsLbl, ColumnValue);
    end;

    local procedure VerifyInteractionLogEntry(DocumentNo: Code[20])
    var
        InteractionLogEntry: Record "Interaction Log Entry";
    begin
        InteractionLogEntry.SetRange("Document Type", InteractionLogEntry."Document Type"::"Purch.Qte.");
        InteractionLogEntry.SetRange("Document No.", DocumentNo);
        Assert.IsTrue(InteractionLogEntry.FindFirst(), ValidationErr);
    end;

    local procedure VerifyPurchaseArchive(PurchaseLine: Record "Purchase Line")
    var
        PurchaseHeaderArchive: Record "Purchase Header Archive";
        PurchaseLineArchive: Record "Purchase Line Archive";
    begin
        PurchaseHeaderArchive.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseHeaderArchive.SetRange("No.", PurchaseLine."Document No.");
        PurchaseHeaderArchive.FindFirst();
        PurchaseHeaderArchive.TestField("Buy-from Vendor No.", PurchaseLine."Buy-from Vendor No.");

        PurchaseLineArchive.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLineArchive.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLineArchive.FindFirst();
        PurchaseLineArchive.TestField(Quantity, PurchaseLine.Quantity);
    end;

    local procedure VerifyPurchaseCreditMemoReport(DocumentNo: Code[20])
    var
        PurchCrMemoLine: Record "Purch. Cr. Memo Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        PurchCrMemoLine.SetRange("Document No.", DocumentNo);
        PurchCrMemoLine.FindSet();
        repeat
            LibraryReportDataset.AssertElementWithValueExists('LineNo_PurchCrMemoLine', PurchCrMemoLine."Line No.");
            LibraryReportDataset.AssertElementWithValueExists('No_PurchCrMemoLine', PurchCrMemoLine."No.");
        until PurchCrMemoLine.Next() = 0;
    end;

    local procedure VerifyVariousEntriesOnDocEntriesReport(DocumentNo: Code[20])
    var
        GLEntry: Record "G/L Entry";
        VATEntry: Record "VAT Entry";
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry";
    begin
        GLEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(GLEntry.TableCaption(), GLEntry.Count);
        VerifyValueEntry(DocumentNo);
        VATEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(VATEntry.TableCaption(), VATEntry.Count);
        VendorLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(VendorLedgerEntry.TableCaption(), VendorLedgerEntry.Count);
        DetailedVendorLedgEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(DetailedVendorLedgEntry.TableCaption(), DetailedVendorLedgEntry.Count);
    end;

    local procedure VerifyValueEntry(DocumentNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(ValueEntry.TableCaption(), ValueEntry.Count);
    end;

    local procedure VerifyValueEntryItemLedgerEntry(DocumentNo: Code[20])
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        VerifyValueEntry(DocumentNo);
        ItemLedgerEntry.SetRange("Document No.", DocumentNo);
        VerifyDocumentEntriesReport(ItemLedgerEntry.TableCaption(), ItemLedgerEntry.Count);
    end;

    local procedure VerifyPurchaseInvoiceReportVATAmountInLCY(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        RowNo: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();

        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", "Gen. Journal Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindLast();

        RowNo := LibraryReportDataset.FindRow('VALVATAmtLCY', Round(VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision()));
        Assert.IsTrue(RowNo > 0, StrSubstNo(RowNotFoundErr, 'VALVATAmtLCY', VATEntry.Amount));
        RowNo := LibraryReportDataset.FindRow('VALVATBaseLCY', Round(VATEntry.Base, LibraryERM.GetAmountRoundingPrecision()));
        Assert.IsTrue(RowNo > 0, StrSubstNo(RowNotFoundErr, 'VALVATBaseLCY', VATEntry.Base));
    end;

    local procedure VerifyPurchaseCreditMemoReportVATAmountInLCY(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
        RowNo: Integer;
    begin
        LibraryReportDataset.LoadDataSetFile();

        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", "Gen. Journal Document Type"::"Credit Memo");
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindLast();

        RowNo := LibraryReportDataset.FindRow('VALVATAmountLCY', Round(-VATEntry.Amount, LibraryERM.GetAmountRoundingPrecision()));
        Assert.IsTrue(RowNo > 0, StrSubstNo(RowNotFoundErr, 'VALVATAmountLCY', -VATEntry.Amount));
        RowNo := LibraryReportDataset.FindRow('VALVATBaseLCY', Round(-VATEntry.Base, LibraryERM.GetAmountRoundingPrecision()));
        Assert.IsTrue(RowNo > 0, StrSubstNo(RowNotFoundErr, 'VALVATBaseLCY', -VATEntry.Base));
    end;

    local procedure VerifyInvoiceDiscountInReport(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.FindFirst();
        LibraryReportDataset.SetRange('Purchase_Line__Type', Format(PurchaseLine.Type));
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line__Quantity', PurchaseLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___Line_Amount_', PurchaseLine."Line Amount");
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___No__', PurchaseLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___Allow_Invoice_Disc__', PurchaseLine."Allow Invoice Disc.");
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___VAT_Identifier_', PurchaseLine."VAT Identifier");

        LibraryReportDataset.Reset();
        LibraryReportDataset.SetRange('Purchase_Line___Line_Discount___', PurchaseLine."Line Discount %");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Purchase_Line___Inv__Discount_Amount_', PurchaseLine."Inv. Discount Amount");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('TempPurchLine__Inv__Discount_Amount_', -PurchaseLine."Inv. Discount Amount");
    end;

    local procedure VerifyVendorTrialBalanceReportValues(VendorNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Vendor', VendorNo);
        Assert.IsTrue(LibraryReportDataset.GetNextRow(), StrSubstNo(RowNotFoundErr, 'No_Vendor', VendorNo));
        LibraryReportDataset.AssertCurrentRowValueEquals('PeriodCreditAmt', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('YTDCreditAmt', Amount);
        LibraryReportDataset.AssertCurrentRowValueEquals('YTDTotal', -Amount); // This for Ending Balance
    end;

    local procedure VerifyPurchaseInvoiceReportVATAmountInLCYSection(DocumentNo: Code[20])
    var
        VATEntry: Record "VAT Entry";
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Purchase);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", DocumentNo);
        VATEntry.FindLast();

        LibraryReportValidation.OpenExcelFile();
        LibraryReportValidation.VerifyCellValue(106, 17, LibraryReportValidation.FormatDecimalValue(VATEntry.Base));
        LibraryReportValidation.VerifyCellValue(106, 29, LibraryReportValidation.FormatDecimalValue(VATEntry.Amount));
    end;

    local procedure VerifyVendorBalanceToBalance(VendorNo: Code[20]; GlobalDimension1Code: Code[20]; GlobalDimension2Code: Code[20]; CurrencyCode: Code[10])
    var
        VendorLedgerEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        VendorLedgerEntry.SetRange("Vendor No.", VendorNo);
        VendorLedgerEntry.SetRange("Global Dimension 1 Code", GlobalDimension1Code);
        VendorLedgerEntry.SetRange("Global Dimension 2 Code", GlobalDimension2Code);
        VendorLedgerEntry.SetRange("Currency Code", CurrencyCode);
        VendorLedgerEntry.FindFirst();
        VendorLedgerEntry.CalcFields(Amount);
        LibraryReportDataset.SetRange('PostDt_VendLedgEntry3', Format(WorkDate()));
        LibraryReportDataset.SetRange('DocType_VendLedgEntry3', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(VendorLedgerEntry.Amount));
    end;

    local procedure VerifyVendorEntriesAndBalanceInVendorBalanceToDate(GenJournalLine: Record "Gen. Journal Line"; Balance: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocType_VendLedgEntry3', Format(GenJournalLine."Document Type"::Invoice));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(-GenJournalLine.Amount));
        LibraryReportDataset.SetRange('DocType_VendLedgEntry3', Format(GenJournalLine."Document Type"::"Credit Memo"));
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OriginalAmt', Format(GenJournalLine.Amount));
        LibraryReportDataset.SetRange('Name1_Vendor', GenJournalLine."Account No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CurrTotalBufferTotalAmt', Balance);
    end;

    local procedure VerifyPurchOrderRepPrepmtSecGLAccLine(RowNo: Integer; GLAccountColumnNo: Integer; DescriptionColumnNo: Integer; AmountColumnNo: Integer; GLAccount: Record "G/L Account"; Amount: Decimal)
    begin
        LibraryReportValidation.VerifyCellValue(RowNo, GLAccountColumnNo, GLAccount."No.");
        LibraryReportValidation.VerifyCellValue(RowNo, DescriptionColumnNo, GLAccount.Name);
        LibraryReportValidation.VerifyCellValue(RowNo, AmountColumnNo, LibraryReportValidation.FormatDecimalValue(Amount));
    end;

    local procedure VerifyPurchOrderRepPrepmtSecTwoLinesWithoutDims(PrepmtGLAccount: Record "G/L Account"; LinePrepmtAmountValue: array[2] of Decimal)
    var
        StartingRowNo: Integer;
        GLAccountColumnNo: Integer;
        DescriptionColumnNo: Integer;
        AmountColumnNo: Integer;
    begin
        FindPurchOrderRepPrepmtSpecColumnRowNo(StartingRowNo, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo);
        VerifyPurchOrderRepPrepmtSecGLAccLine(
          StartingRowNo, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo, PrepmtGLAccount, LinePrepmtAmountValue[1]);
        VerifyPurchOrderRepPrepmtSecGLAccLine(
          StartingRowNo + 1, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo, PrepmtGLAccount, LinePrepmtAmountValue[2]);
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 3, AmountColumnNo,
          LibraryReportValidation.FormatDecimalValue(LinePrepmtAmountValue[1] + LinePrepmtAmountValue[2]));
    end;

    local procedure VerifyPurchOrderRepPrepmtSecTwoLinesWithSingleDims(PrepmtGLAccount: Record "G/L Account"; LinePrepmtAmountValue: array[2] of Decimal; HeaderDimensionValue: Record "Dimension Value"; Line1DimensionValue: array[4] of Record "Dimension Value"; Line2DimensionValue: array[4] of Record "Dimension Value"; TotalPrepmtLineOffset: Integer)
    var
        StartingRowNo: Integer;
        GLAccountColumnNo: Integer;
        DescriptionColumnNo: Integer;
        AmountColumnNo: Integer;
    begin
        FindPurchOrderRepPrepmtSpecColumnRowNo(StartingRowNo, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo);
        VerifyPurchOrderRepPrepmtSecGLAccLine(
          StartingRowNo, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo, PrepmtGLAccount, LinePrepmtAmountValue[1]);
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 1, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2, %3 %4',
            HeaderDimensionValue."Dimension Code", HeaderDimensionValue.Code,
            Line1DimensionValue[1]."Dimension Code", Line1DimensionValue[1].Code));
        VerifyPurchOrderRepPrepmtSecGLAccLine(
          StartingRowNo + 2, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo, PrepmtGLAccount, LinePrepmtAmountValue[2]);
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 3, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2, %3 %4',
            HeaderDimensionValue."Dimension Code", HeaderDimensionValue.Code,
            Line2DimensionValue[1]."Dimension Code", Line2DimensionValue[1].Code));
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + TotalPrepmtLineOffset, AmountColumnNo,
          LibraryReportValidation.FormatDecimalValue(LinePrepmtAmountValue[1] + LinePrepmtAmountValue[2]));
    end;

    local procedure VerifyPurchOrderRepPrepmtSecTwoLinesWithMultipleDims(PrepmtGLAccount: Record "G/L Account"; LinePrepmtAmountValue: array[2] of Decimal; HeaderDimensionValue: Record "Dimension Value"; Line1DimensionValue: array[4] of Record "Dimension Value"; Line2DimensionValue: array[4] of Record "Dimension Value"; TotalPrepmtLineOffset: Integer)
    var
        StartingRowNo: Integer;
        GLAccountColumnNo: Integer;
        DescriptionColumnNo: Integer;
        AmountColumnNo: Integer;
    begin
        FindPurchOrderRepPrepmtSpecColumnRowNo(StartingRowNo, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo);
        VerifyPurchOrderRepPrepmtSecGLAccLine(
          StartingRowNo, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo, PrepmtGLAccount, LinePrepmtAmountValue[1]);
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 1, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2, %3 %4',
            HeaderDimensionValue."Dimension Code", HeaderDimensionValue.Code,
            Line1DimensionValue[1]."Dimension Code", Line1DimensionValue[1].Code));
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 2, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2, %3 %4',
            Line1DimensionValue[2]."Dimension Code", Line1DimensionValue[2].Code,
            Line1DimensionValue[3]."Dimension Code", Line1DimensionValue[3].Code));
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 3, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2',
            Line1DimensionValue[4]."Dimension Code", Line1DimensionValue[4].Code));
        VerifyPurchOrderRepPrepmtSecGLAccLine(
          StartingRowNo + 4, GLAccountColumnNo, DescriptionColumnNo, AmountColumnNo, PrepmtGLAccount, LinePrepmtAmountValue[2]);
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 5, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2, %3 %4',
            HeaderDimensionValue."Dimension Code", HeaderDimensionValue.Code,
            Line2DimensionValue[1]."Dimension Code", Line2DimensionValue[1].Code));
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 6, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2, %3 %4',
            Line2DimensionValue[2]."Dimension Code", Line2DimensionValue[2].Code,
            Line2DimensionValue[3]."Dimension Code", Line2DimensionValue[3].Code));
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + 7, DescriptionColumnNo,
          StrSubstNo(
            '%1 %2',
            Line2DimensionValue[4]."Dimension Code", Line2DimensionValue[4].Code));
        LibraryReportValidation.VerifyCellValue(
          StartingRowNo + TotalPrepmtLineOffset, AmountColumnNo,
          LibraryReportValidation.FormatDecimalValue(LinePrepmtAmountValue[1] + LinePrepmtAmountValue[2]));
    end;

    local procedure VerifyStandardPurchaseOrderReceiptDates(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('PlannedReceiptDate', Format(PurchaseLine."Planned Receipt Date", 0, 4));
        LibraryReportDataset.AssertElementWithValueExists('ExpectedReceiptDate', Format(PurchaseLine."Expected Receipt Date", 0, 4));
        LibraryReportDataset.AssertElementWithValueExists('PromisedReceiptDate', Format(PurchaseLine."Promised Receipt Date", 0, 4));
        LibraryReportDataset.AssertElementWithValueExists('RequestedReceiptDate', Format(PurchaseLine."Requested Receipt Date", 0, 4));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostAndApplyVendPageHandler(var ApplyVendorEntries: TestPage "Apply Vendor Entries")
    begin
        ApplyVendorEntries.ActionSetAppliesToID.Invoke();
        ApplyVendorEntries.ActionPostApplication.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DocumentEntriesRequestPageHandler(var DocumentEntries: TestRequestPage "Document Entries")
    var
        ShowAmountInLCY: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowAmountInLCY);
        DocumentEntries.PrintAmountsInLCY.SetValue(ShowAmountInLCY);  // Show Amount In LCY.
        DocumentEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        // Message Handler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure NavigatePageHandler(var Navigate: TestPage Navigate)
    begin
        Navigate.Print.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostApplicationPageHandler(var PostApplication: Page "Post Application"; var Response: Action)
    begin
        // Modal Page Handler.
        Response := ACTION::OK
    end;

    local procedure SavePurchaseInvoiceReport(DocumentNo: Code[20])
    var
        PurchInvHeader: Record "Purch. Inv. Header";
    begin
        LibraryReportValidation.SetFileName(LibraryUtility.GenerateGUID());
        LibraryVariableStorage.Enqueue(LibraryReportValidation.GetFileName());
        Commit();

        PurchInvHeader.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Purchase - Invoice", true, false, PurchInvHeader);
    end;

    local procedure SavePurchaseCreditMemoReport(DocumentNo: Code[20])
    var
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
    begin
        PurchCrMemoHdr.SetRange("No.", DocumentNo);
        REPORT.Run(REPORT::"Purchase - Credit Memo", true, false, PurchCrMemoHdr);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseCreditMemoRequestPageHandler(var PurchaseCreditMemo: TestRequestPage "Purchase - Credit Memo")
    begin
        PurchaseCreditMemo.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchasePrepmtDocTest(var PurchasePrepmtDocTest: TestRequestPage "Purchase Prepmt. Doc. - Test")
    begin
        PurchasePrepmtDocTest.ShowDimensions.SetValue(true);
        PurchasePrepmtDocTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorTrialBalance(var VendorTrialBalance: TestRequestPage "Vendor - Trial Balance")
    begin
        VendorTrialBalance.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchaseDocumentTest(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        PurchaseDocumentTest.ShowItemChargeAssignment.SetValue(true);
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHPurchaseQuote(var PurchaseQuote: TestRequestPage "Purchase - Quote")
    var
        ShowInternalInfo: Variant;
        ArchiveDocument: Variant;
        LogInteraction: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowInternalInfo);
        LibraryVariableStorage.Dequeue(ArchiveDocument);
        LibraryVariableStorage.Dequeue(LogInteraction);
        PurchaseQuote.NoOfCopies.SetValue(0);
        PurchaseQuote.ShowInternalInfo.SetValue(ShowInternalInfo);
        PurchaseQuote.ArchiveDocument.SetValue(ArchiveDocument);
        PurchaseQuote.LogInteraction.SetValue(LogInteraction);
        PurchaseQuote.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHOrder(var "Order": TestRequestPage "Order")
    begin
        Order.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RequestHandlerPurchaseDocumentTest(var PurchaseDocumentTest: TestRequestPage "Purchase Document - Test")
    begin
        PurchaseDocumentTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EditAnalysisReportPurchRequestPageHandler(var PurchaseAnalysisReport: TestPage "Purchase Analysis Report")
    var
        PurchPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        PurchaseAnalysisReport.PeriodType.SetValue(PurchPeriodType::Year);
        PurchaseAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PurchAnalysisMatrixExcludeByShowReportPageHandler(var PurchaseAnalysisMatrix: TestPage "Purchase Analysis Matrix")
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        RecordVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisLine := RecordVariant;
        Assert.AreEqual(
          AnalysisLine.Show <> AnalysisLine.Show::No, PurchaseAnalysisMatrix.GotoRecord(AnalysisLine),
          RowVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisLine := RecordVariant;
        Assert.AreEqual(
          AnalysisLine.Show <> AnalysisLine.Show::No, PurchaseAnalysisMatrix.GotoRecord(AnalysisLine),
          RowVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisColumn := RecordVariant;
        Assert.AreEqual(
          AnalysisColumn."Column Header" = PurchaseAnalysisMatrix.Field1.Caption, AnalysisColumn.Show <> AnalysisColumn.Show::Never,
          ColumnVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisColumn := RecordVariant;
        Assert.AreEqual(
          AnalysisColumn."Column Header" = PurchaseAnalysisMatrix.Field1.Caption, AnalysisColumn.Show <> AnalysisColumn.Show::Never,
          ColumnVisibilityErr);

        Assert.IsFalse(PurchaseAnalysisMatrix.Field2.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field3.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field4.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field5.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field6.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field7.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field8.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field9.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field10.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field11.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field12.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field13.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field14.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field15.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field16.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field17.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field18.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field19.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field20.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field21.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field22.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field23.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field24.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field25.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field26.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field27.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field28.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field29.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field30.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field31.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(PurchaseAnalysisMatrix.Field32.Visible(), ColumnDoesNotExistErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PurchaseInvoiceExcelRequestPageHandler(var PurchaseInvoice: TestRequestPage "Purchase - Invoice")
    begin
        PurchaseInvoice.SaveAsExcel(LibraryVariableStorage.DequeueText());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorBalanceToDate(var VendorBalanceToDate: TestRequestPage "Vendor - Balance to Date")
    begin
        VendorBalanceToDate.ShowEntriesWithZeroBalance.SetValue(false);
        VendorBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StandardPurchaseOrderRequestPageHandler(var StandardPurchaseOrder: TestRequestPage "Standard Purchase - Order")
    begin
        StandardPurchaseOrder.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RHVendorBalanceToDateEnableShowEntriesWithZeroBalance(var VendorBalanceToDate: TestRequestPage "Vendor - Balance to Date")
    begin
        VendorBalanceToDate.ShowEntriesWithZeroBalance.SetValue(true);
        VendorBalanceToDate.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}
