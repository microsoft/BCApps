codeunit 137351 "SCM Inventory Reports - IV"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Reports] [SCM]
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryItemTracking: Codeunit "Library - Item Tracking";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryAccountSchedule: Codeunit "Library - Account Schedule";
        LibraryRandom: Codeunit "Library - Random";
        LibraryLowerPermissions: Codeunit "Library - Lower Permissions";
        LibraryPriceCalculation: Codeunit "Library - Price Calculation";
        ErrorTypeRef: Option "None","Division by Zero","Period Error","Invalid Formula","Cyclic Formula",All;
        isInitialized: Boolean;
        Amount: Label 'Amount';
        AnalysisLineDateFilterError: Label 'Specify a filter for the Date Filter field in the Analysis Line table.';
        AnalysisViewCodeError: Label 'Enter an analysis view code.';
        ColumnTemplateError: Label 'Enter a column template.';
        DateFilterText: Label 'w', Comment = '%1 Workdate';
        DivisionByZero: Label '%1/0';
        DateFilterError: Label 'Enter a date filter.';
        ErrorTxt: Label '* ERROR *';
        NotAvailable: Label 'Not Available';
        PostingMessage: Label 'Do you want to post the journal lines?';
        PostedLinesMessage: Label 'The journal lines were successfully posted.';
        RevaluationLinesCreated: Label 'Revaluation journal lines have also been created.';
        StartingDateError: Label 'You cannot base a date calculation on an undefined date.';
        StatusDateError: Label 'Enter the Status Date';
        ValueNotMatchedError: Label 'Value not matched.';
        InventoryCostPostedToGLCap: Label 'Inventory Cost Posted to G/L';
        RowNotFoundErr: Label 'There is no dataset row corresponding to Element Name %1 with value %2.', Comment = '%1=Field Caption,%2 = Field Value';
        ExpandBOMErr: Label 'BOM component should not exist for Item %1';
        ColumnFormulaMsg: Label 'Column formula: %1.', Comment = '%1 - text of Column formula';
        ColumnFormulaErrorMsg: Label 'Error: %1.', Comment = '%1 - text of ErrorTypeRef';
        IncorrectExpectedMessageErr: Label 'Incorrect Expected Message';
        WrongItemAnalysisViewAmountErr: Label 'Amount in Analysis View Report is incorrect.';
        WrongReportNameSelectedErr: Label 'Report Lookup returned incorrect report name.';
        ValueEntriesWerePostedTxt: Label 'value entries have been posted to the general ledger.';
        WrongSourceFilterErr: Label 'Source filter is incorrect';
        RowVisibilityErr: Label 'Analysis row must only be visible in Inventory Analysis Matrix when Show <> No.';
        ColumnVisibilityErr: Label 'Analysis column must only be visible in Inventory Analysis Matrix when Show <> Never.';
        ColumnDoesNotExistErr: Label 'Analysis column does not exist in Analysis Column Template and therefore must not be visible.';
        TransferLineDimensionChangeQst: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to General Ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';

    [Test]
    [Scope('OnPrem')]
    procedure ValueEntryAfterPostingSalesOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        SalesInvoiceLine: Record "Sales Invoice Line";
    begin
        // Verify Value Entry after posting Sales Order.

        // Setup: Create Item, create and post Item Journal Line.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");

        // Exercise.
        // Use Random months to change Posting Date.
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2),
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()), CreateCustomer());  // Use Random value for Quantity.
        SalesInvoiceLine.SetRange(Type, SalesInvoiceLine.Type::Item);
        SalesInvoiceLine.SetRange("No.", Item."No.");
        SalesInvoiceLine.FindFirst();

        // Verify: Verify Cost Amount on Value Entry.
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.FindFirst();
        ValueEntry.TestField("Cost Amount (Actual)", -Round(Item."Standard Cost" * SalesLine.Quantity));
        ValueEntry.TestField("Document No.", SalesInvoiceLine."Document No.");
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionReportAfterPostingSalesOrder()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
    begin
        // Verify Item Age Composition Report after posting Sales Order.

        // Setup: Create Item, create and post Item Journal Line and Sales Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        CreateAndPostSalesOrder(SalesLine, Item."No.", ItemJournalLine.Quantity / 2, WorkDate(), CreateCustomer());  // Post partial Quantity.

        // Exercise.
        Commit();
        RunItemAgeCompositionValueReport(Item."No.");

        // Verify: Verify Item Age Composition Report.
        Item.CalcFields(Inventory);
        VerifyItemAgeCompositionReport(Item."No.", Round(Item.Inventory * Item."Standard Cost"));
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure RevaluationJournalLinesUsingStdCostWorksheet()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
    begin
        // Verify creation of Revaluation Journal Lines using Standard Cost Worksheet.

        // Setup: Create Item, Standard Cost Worksheet Name.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateStandardCostWorksheetName(StandardCostWorksheetName);

        // Exercise.
        SuggestAndImplementStandardCostChanges(ItemJournalBatch, Item, StandardCostWorksheetName.Name);

        // Verify: Verify Revaluation Journal Line created through Standard Cost Worksheet.
        StandardCostWorksheet.Get(StandardCostWorksheetName.Name, StandardCostWorksheet.Type::Item, Item."No.");
        VerifyItemJournalLine(ItemJournalBatch, Item."No.", StandardCostWorksheet."New Standard Cost");
    end;

    [Test]
    [HandlerFunctions('ImplementStandardCostChangePageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure StandardCostUpdationUsingStdCostWorksheet()
    var
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        StandardCostWorksheet: Record "Standard Cost Worksheet";
        StandardCostWorksheetName: Record "Standard Cost Worksheet Name";
    begin
        // Verify updated Standard Cost on Item when Cost is updated using Standard Cost Worksheet.

        // Setup: Create Item and Standard Cost Worksheet Name.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryInventory.CreateStandardCostWorksheetName(StandardCostWorksheetName);

        // Exercise.
        SuggestAndImplementStandardCostChanges(ItemJournalBatch, Item, StandardCostWorksheetName.Name);

        // Verify: Verify updated Standard Cost.
        StandardCostWorksheet.Get(StandardCostWorksheetName.Name, StandardCostWorksheet.Type::Item, Item."No.");
        Item.Get(Item."No.");
        Item.TestField("Standard Cost", StandardCostWorksheet."New Standard Cost");
    end;

    [Test]
    [HandlerFunctions('ItemTrackingLinesPageHandler,EnterQuantityToCreatePageHandler,ItemTrackingSummaryPageHandler')]
    [Scope('OnPrem')]
    procedure PhysicalInventoryJournalWithSerialNo()
    var
        Bin: Record Bin;
        Item: Record Item;
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        PurchaseLine: Record "Purchase Line";
        SerialNo: array[10] of Code[50];
        "Count": Integer;
        TrackingOption: Option AssignSerialNo,SelectEntries;
    begin
        // Verify available Serial Nos on Physical Inventory Journal after calculating Inventory.

        // Setup: Create Item with Tracking Code, create Location with Bin, create and receive Purchase Order with Tracking Lines. Run Calculate Inventory on Phys. Inventory Journal.
        Initialize();
        CreateLocationWithBin(Bin);
        LibraryInventory.CreateTrackedItem(Item, '', LibraryUtility.GetGlobalNoSeriesCode(), CreateItemTrackingCodeSerialSpecific());  // Use blank value for Lot No.
        CreateAndModifyPurchaseOrder(PurchaseLine, Item."No.", Bin."Location Code", Bin.Code);
        LibraryVariableStorage.Enqueue(TrackingOption::AssignSerialNo);  // Enqueue value for ItemTrackingLinesPageHandler.
        PurchaseLine.OpenItemTrackingLines();
        Count := StoreSerialNos(SerialNo, PurchaseLine."No.");
        PostPurchaseOrder(PurchaseLine, true, false);

        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::"Phys. Inventory");
        RunCalculateInventoryReport(ItemJournalBatch, PurchaseLine."No.");
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        LibraryVariableStorage.Enqueue(TrackingOption::SelectEntries);  // Enqueue value for ItemTrackingLinesPageHandler.
        LibraryVariableStorage.Enqueue(Count);  // Enqueue value for ItemTrackingSummaryPageHandler.
        EnqueueSerialNos(SerialNo, Count);

        // Exercise: Open Item Tracking Lines from Phys. Inventory Journal.
        ItemJournalLine.OpenItemTrackingLines(false);  // False for IsReclass.

        // Verify: Verify Phys. Inventory Journal and Serial No. on Item Tracking Line in ItemTrackingSummaryPageHandler.
        VerifyPhysicalInventoryJournal(ItemJournalBatch, PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReportWithDateError()
    begin
        // Verify Status report for blank Status Date.

        // Setup.
        Initialize();

        // Enqueue values for StatusRequestPageHandler.
        LibraryVariableStorage.Enqueue(0D);  // 0D for Status Date.
        LibraryVariableStorage.Enqueue('');  // Blank for File name.

        // Exercise.
        Commit();
        asserterror RunStatusReport('');  // Use blank for Item No.

        // Verify.
        Assert.ExpectedError(StatusDateError);
    end;

    [Test]
    [HandlerFunctions('StatusRequestPageHandler')]
    [Scope('OnPrem')]
    procedure StatusReportAfterPostingPurchaseOrder()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        DocumentNo: Code[20];
    begin
        // Verify Status Report after posting Purchase Order.

        // Setup: Create and post Purchase Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreatePurchaseOrder(PurchaseLine, Item."No.", '');
        DocumentNo := PostPurchaseOrder(PurchaseLine, true, false);

        // Enqueue values for StatusRequestPageHandler.
        Commit();
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(PurchaseLine."No.");

        // Exercise.
        RunStatusReport(PurchaseLine."No.");

        // Verify: Verify Quantity and Unit Cost on Status report.
        VerifyStatusReport(PurchaseLine, DocumentNo);
    end;

    [Test]
    [HandlerFunctions('ItemDimensionTotalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalAnalysisViewCodeError()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        ItemAnalysisView: Record "Item Analysis View";
        SetValue: Option IncludeDimension,NotIncludeDimension;
    begin
        // Verify error on Item Dimension Total report for blank Analysis View Code.

        // Setup: Create Item Analysis View, Analysis Column Template.
        Initialize();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");

        // Enqueue values for 'ItemDimensionTotalRequestPageHandler' and 'AnalysisDimSelectionLevelPageHandler'.
        LibraryVariableStorage.Enqueue(SetValue::NotIncludeDimension);
        EnqueueValuesForItemDimensionTotalReport(ItemAnalysisView."Analysis Area", '', AnalysisColumnTemplate.Name, '');

        // Exercise.
        Commit();
        asserterror REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // Verify.
        Assert.ExpectedError(AnalysisViewCodeError);
    end;

    [Test]
    [HandlerFunctions('ItemDimensionTotalPageHandlerForColumnTemplate')]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalColumnTemplateError()
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Verify error on Item Dimension Total report for blank Column Template.

        // Setup: Create Item Analysis View.
        Initialize();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Purchase);

        // Enqueue values 'ItemDimensionTotalPageHandlerForColumnTemplate'.
        EnqueueValuesForItemDimensionTotalReport(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, '', '');

        // Exercise.
        Commit();
        asserterror REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // Verify.
        Assert.ExpectedError(ColumnTemplateError);
    end;

    [Test]
    [HandlerFunctions('ItemDimensionTotalRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalReportDateFilterError()
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        ItemAnalysisView: Record "Item Analysis View";
        SetValue: Option IncludeDimension,NotIncludeDimension;
    begin
        // Verify error on Item Dimension Total report for blank Date Filter.

        // Setup: Create Item Analysis View, Analysis Column Template.
        Initialize();
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");

        // Enqueue values 'ItemDimensionTotalRequestPageHandler' and 'AnalysisDimSelectionLevelPageHandler'.
        LibraryVariableStorage.Enqueue(SetValue::NotIncludeDimension);
        EnqueueValuesForItemDimensionTotalReport(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, AnalysisColumnTemplate.Name, '');

        // Exercise.
        Commit();
        asserterror REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // Verify.
        Assert.ExpectedError(DateFilterError);
    end;

    [Test]
    [HandlerFunctions('ItemDimensionTotalRequestPageHandler,AnalysisDimSelectionLevelPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalReportWithSalesAnalysisArea()
    var
        AnalysisColumn: Record "Analysis Column";
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        CustomerNo: Code[20];
    begin
        // Verify Item Dimension Total report for Sales Analysis Area.

        // Setup: Create Item, Customer, create and post Sales Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CustomerNo := CreateCustomer();
        UpdateCustomerDimension(DefaultDimension, CustomerNo);
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate(), CustomerNo);  // Use Random value for Quantity.
        SetupDimTotalReportWithAnalysisArea(ItemAnalysisView,
          DefaultDimension, ItemAnalysisView."Analysis Area"::Sales, AnalysisColumn."Value Type"::"Cost Amount");

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // Verify: Verify Quantity and Cost Amount(Actual) on Item Dimension Total report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyItemDimensionTotalReport(
          DefaultDimension."Dimension Code", ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ItemDimensionTotalRequestPageHandler,AnalysisDimSelectionLevelPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalReportWithInventoryAnalysisArea()
    var
        AnalysisColumn: Record "Analysis Column";
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Item Dimension Total report for Inventory Analysis Area.

        // Setup: Create Item, Customer, create and post Item Journal Line.
        Initialize();
        CreateItemWithDefaultDimension(Item, DefaultDimension);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        SetupDimTotalReportWithAnalysisArea(ItemAnalysisView,
          DefaultDimension, ItemAnalysisView."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Cost Amount");

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // Verify: Verify Quantity and Cost Amount(Actual) on Item Dimension Total report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyItemDimensionTotalReport(
          DefaultDimension."Dimension Code", ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ItemDimensionTotalRequestPageHandler,AnalysisDimSelectionLevelPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalReportWithPurchaseAnalysisArea()
    var
        AnalysisColumn: Record "Analysis Column";
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Item Dimension Total report for Inventory Analysis Area.

        // Setup: Create Item, Vendor, create and post Purchase Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        UpdateVendorDimension(DefaultDimension, CreateVendor());
        CreatePurchaseOrder(PurchaseLine, Item."No.", DefaultDimension."No.");
        PostPurchaseOrder(PurchaseLine, true, true);
        SetupDimTotalReportWithAnalysisArea(ItemAnalysisView,
          DefaultDimension, ItemAnalysisView."Analysis Area"::Purchase, AnalysisColumn."Value Type"::"Cost Amount");

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // Verify: Verify Quantity and Cost Amount(Actual) on Item Dimension Total report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyItemDimensionTotalReport(
          DefaultDimension."Dimension Code", ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForSale()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // Verify Cost Shares Breakdown report for Sale.

        // Setup: Create Item, Create and Post Item Journal Line, Create and Post Sales Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate(), CreateCustomer());  // Use Random value for Quantity.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");

        // Exercise.
        Commit();
        RunCostSharesBreakdownReport(Item."No.", PrintCostShare::Sale, false);

        // Verify: Verify Quantity and Material Direct Cost Applied in the report.
        VerifyCostSharesBreakdownReport(ItemLedgerEntry, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForInventory()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // Verify Cost Shares Breakdown report for Inventory.

        // Setup: Create Item, Create and Post Item Journal Line.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");

        // Exercise.
        Commit();
        RunCostSharesBreakdownReport(Item."No.", PrintCostShare::Inventory, false);

        // Verify: Verify Quantity and Material Direct Cost Applied in the report.
        VerifyCostSharesBreakdownReport(ItemLedgerEntry, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandler,ConfirmHandler,MessageHandler,CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForWIPInventory()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // Verify Cost Shares Breakdown report for WIP Inventory.

        // Setup: Create Child Item, Create and Post Item Journal Line for Child Item. Create and modify Parent Item with Production BOM.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, Item."No.", Item2."Base Unit of Measure", 1);
        UpdateProductionBOMOnItem(Item2, ProductionBOMHeader."No.");

        // Create Released Production Order and Post Production Journal.
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, Item2."No.", ItemJournalLine.Quantity / 2);

        // Enqueue values for Confirm and Message Handlers.
        LibraryVariableStorage.Enqueue(PostingMessage);
        LibraryVariableStorage.Enqueue(PostedLinesMessage);
        CreateAndPostProductionJournal(ProductionOrder);
        FindItemLedgerEntry(ItemLedgerEntry, Item2."No.", ItemLedgerEntry."Entry Type"::Output);

        // Exercise.
        Commit();
        RunCostSharesBreakdownReport(Item2."No.", PrintCostShare::"WIP Inventory", false);

        // Verify: Verify Quantity and Material Direct Cost Applied in the report.
        VerifyCostSharesBreakdownReport(ItemLedgerEntry, ItemLedgerEntry.Quantity * Item2."Unit Cost");
        AssertReportValue('NewMatOvrHd_PrintInvCstShrBuf', ItemLedgerEntry.Quantity * Item2."Overhead Rate");
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportInDetail()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
        RevaluationCost: Decimal;
        AdjustedAmount: Decimal;
    begin
        // Verify Cost Shares Breakdown report in detail.

        // Setup: Create Item, Create and Post Item Journal Line, Create and Post Sales Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate(), CreateCustomer());  // Use Random value for Quantity.

        // Post Revaluation Journal.
        AdjustedAmount := CreateAndPostRevaluationJournal(Item."No.");
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        RevaluationCost :=
          Round(ItemLedgerEntry.Quantity * (AdjustedAmount / ItemJournalLine.Quantity), LibraryERM.GetAmountRoundingPrecision());

        // Exercise.
        Commit();
        RunCostSharesBreakdownReport(Item."No.", PrintCostShare::Sale, true);

        // Verify: Verify Quantity and Material Direct Cost Applied in the report.
        VerifyCostSharesBreakdownReport(
          ItemLedgerEntry, ItemLedgerEntry."Cost Amount (Actual)" - RevaluationCost);
        AssertReportValue('NewReval_PrintInvCstShrBuf', RevaluationCost);
    end;

    [Test]
    [HandlerFunctions('ItemBudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemBudgetReportStartingDateError()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ValueType: Option "Sales Amount","Cost Amount",Quantity;
    begin
        // Verify error on Item Budget report for blank Starting Date.

        // Setup: Create Item Budget Entry.
        Initialize();
        SetupItemBudgetWithAnalysisArea(ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ValueType::"Sales Amount", 0D, false);  // FALSE for Amount Whole in 1000s only.

        // Exercise: Run Item Budget report.
        Commit();
        asserterror RunItemBudgetReport(ItemBudgetEntry."Item No.");

        // Verify: Verify error for blank Starting Date.
        Assert.ExpectedError(StartingDateError);
    end;

    [Test]
    [HandlerFunctions('ItemBudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemBudgetReportWithPurchAnalysisArea()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ValueType: Option "Sales Amount","Cost Amount",Quantity;
    begin
        // Verify Item Budget report for Purchase Analysis area.

        // Setup: Create Item Budget Entry.
        Initialize();
        SetupItemBudgetWithAnalysisArea(
          ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Purchase, ValueType::"Cost Amount", WorkDate(), false);  // FALSE for Amount Whole in 1000s only.

        // Exercise: Run Item Budget report.
        Commit();
        RunItemBudgetReport(ItemBudgetEntry."Item No.");

        // Verify: Verify Cost Amount on Item Budget report.
        VerifyItemBudgetReport(ItemBudgetEntry."Item No.", ItemBudgetEntry."Cost Amount");
    end;

    [Test]
    [HandlerFunctions('ItemBudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemBudgetReportWithSalesAnalysisArea()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ValueType: Option "Sales Amount","Cost Amount",Quantity;
    begin
        // Verify Item Budget report for Sales Analysis area.

        // Setup: Create Item Budget Entry.
        Initialize();
        SetupItemBudgetWithAnalysisArea(ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ValueType::"Sales Amount", WorkDate(), false);  // FALSE for Amount Whole in 1000s only.

        // Exercise: Run Item Budget report.
        Commit();
        RunItemBudgetReport(ItemBudgetEntry."Item No.");

        // Verify: Verify Sales Amount on Item Budget report.
        VerifyItemBudgetReport(ItemBudgetEntry."Item No.", ItemBudgetEntry."Sales Amount");
    end;

    [Test]
    [HandlerFunctions('ItemBudgetRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemBudgetReportWithWholeAmountOptionTrue()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        ValueType: Option "Sales Amount","Cost Amount",Quantity;
    begin
        // Verify Item Budget report with Whole Amount in 1000s True.

        // Setup: Create Item Budget Entry.
        Initialize();
        SetupItemBudgetWithAnalysisArea(ItemBudgetEntry, ItemBudgetEntry."Analysis Area"::Sales, ValueType::"Sales Amount", WorkDate(), true);  // TRUE for Amount Whole in 1000s only.

        // Exercise: Run Item Budget report.
        Commit();
        RunItemBudgetReport(ItemBudgetEntry."Item No.");

        // Verify: Verify Sales Amount on Item Budget report.
        VerifyItemBudgetReport(ItemBudgetEntry."Item No.", Round(ItemBudgetEntry."Sales Amount" / 1000, 1, '<'));
    end;

    [Test]
    [HandlerFunctions('ItemDimensionDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimDetailReportAnalysisViewCodeError()
    begin
        // Verify error on Item Dimension Detail report for blank Analysis View Code.
        ItemDimDetailReportError('', AnalysisViewCodeError);
    end;

    [Test]
    [HandlerFunctions('ItemDimensionDetailRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimDetailReportDateFilterError()
    begin
        // Verify error on Item Dimension Detail report for blank Date Filter.
        ItemDimDetailReportError(CreateItemAnalysisView(), DateFilterError);
    end;

    local procedure ItemDimDetailReportError(ItemAnalysisViewCode: Code[10]; Error: Text[50])
    var
        ItemAnalysisView: Record "Item Analysis View";
        SetValue: Option IncludeDimension,NotIncludeDimension;
    begin
        // Setup.
        Initialize();

        // Enqueue values 'ItemDimensionDetailRequestPageHandler'.
        LibraryVariableStorage.Enqueue(SetValue::NotIncludeDimension);
        EnqueueValuesForItemDimensionDetailReport(ItemAnalysisView."Analysis Area"::Sales, ItemAnalysisViewCode, '');

        // Exercise: Run Item Dimension Detail report.
        Commit();
        asserterror REPORT.Run(REPORT::"Item Dimensions - Detail", true, false);

        // Verify.
        Assert.ExpectedError(Error);
    end;

    [Test]
    [HandlerFunctions('ItemDimensionDetailRequestPageHandler,AnalysisDimSelectionLevelPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimDetailReportWithSalesAnalysisArea()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
    begin
        // Verify Item Dimension Total report for Sales Analysis Area.

        // Setup: Create Item, Customer, create and post Sales Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        UpdateCustomerDimension(DefaultDimension, CreateCustomer());
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate(), DefaultDimension."No.");  // Use Random value for Quantity.
        SetupDimDetailReportWithAnalysisArea(DefaultDimension, ItemAnalysisView."Analysis Area"::Sales);

        // Exercise: Run Item Dimension Detail report.
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Detail", true, false);

        // Verify: Verify Quantity and Cost Amount(Actual) on Item Dimension Total report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
        VerifyItemDimensionDetailReport(
          Item."No.", ItemLedgerEntry.Quantity, 'TempValEntrySaleAmtActExp', ItemLedgerEntry."Sales Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ItemDimensionDetailRequestPageHandler,AnalysisDimSelectionLevelPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimDetailReportWithInvtAnalysisArea()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        // Verify Item Dimension Total report for Inventory Analysis Area.

        // Setup: Create Item, Customer, create and post Item Journal Line.
        Initialize();
        CreateItemWithDefaultDimension(Item, DefaultDimension);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        SetupDimDetailReportWithAnalysisArea(DefaultDimension, ItemAnalysisView."Analysis Area"::Inventory);

        // Exercise: Run Item Dimension Detail report.
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Detail", true, false);

        // Verify: Verify Quantity and Cost Amount(Actual) on Item Dimension Total report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyItemDimensionDetailReport(
          Item."No.", ItemLedgerEntry.Quantity, 'TVECostAmtActExpNonInvtbl', ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('ItemDimensionDetailRequestPageHandler,AnalysisDimSelectionLevelPageHandler')]
    [Scope('OnPrem')]
    procedure ItemDimDetailReportWithPurchAnalysisArea()
    var
        DefaultDimension: Record "Default Dimension";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
    begin
        // Verify Item Dimension Total report for Inventory Analysis Area.

        // Setup: Create Item, Vendor, create and post Purchase Order.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase);
        UpdateVendorDimension(DefaultDimension, CreateVendor());
        CreatePurchaseOrder(PurchaseLine, Item."No.", DefaultDimension."No.");
        PostPurchaseOrder(PurchaseLine, true, true);
        SetupDimDetailReportWithAnalysisArea(DefaultDimension, ItemAnalysisView."Analysis Area"::Purchase);

        // Exercise: Run Item Dimension Detail report.
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Detail", true, false);

        // Verify: Verify Quantity on Item Dimension Total report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyItemDimensionDetailReport(
          Item."No.", ItemLedgerEntry.Quantity, 'TVECostAmtActExpNonInvtbl', ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('InvtCostAndPriceListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvtCostAndPriceListUsingSKUTrue()
    var
        Item: Record Item;
    begin
        // Verify Unit Cost of Item with Average Cost.

        // Create Setup to generate Inventory Cost and Price List Report with Use Stockkeeping as True.
        Initialize();
        InvtCostAndPriceListSetup(Item);

        // Exercise.
        LibraryCosting.AdjustCostItemEntries(Item."No.", '');

        // Verify: Verify Unit Cost of Item with Average Cost.
        VerifyInvtCostAndPriceListReport(Item."No.");
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportAnalysisLineTemplateError()
    begin
        // Verify Analysis report for blank Analysis Line Template.

        // Setup.
        Initialize();
        AnalysisReportErrorLine('', '');
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportAnalysisColumnTemplateError()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Verify Analysis report for blank Analysis Column Template.

        // Setup: Create Analysis Line Template.
        Initialize();
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisView."Analysis Area"::Inventory);
        AnalysisReportErrorColumn(AnalysisLineTemplate.Name, '');
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportDateFilterError()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Verify Analysis report for blank Date Filter.

        // Setup: Create Analysis Line Template and Analysis Column Template.
        Initialize();
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisView."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area"::Inventory);
        AnalysisReportError(AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name, AnalysisLineDateFilterError);
    end;

    local procedure AnalysisReportError(AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10]; Error: Text[1024])
    var
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        ShowError: Option "None","Division by Zero","Period Error",Both;
    begin
        // Create Analysis report name and enqueue values for 'AnalysisRequestPageHandler'.
        CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area"::Inventory);
        EnqueueValuesForAnalysisReport(
          ItemAnalysisView."Analysis Area"::Inventory, AnalysisReportName.Name, AnalysisLineTemplateName, AnalysisColumnTemplateName, 0D,
          ShowError::None);  // Take 0D for blank Date Filter.

        // Exercise.
        Commit();
        asserterror REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify.
        Assert.ExpectedError(Error);
    end;

    local procedure AnalysisReportErrorColumn(AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        ShowError: Option "None","Division by Zero","Period Error",Both;
    begin
        // Create Analysis report name and enqueue values for 'AnalysisRequestPageHandler'.
        CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area"::Inventory);
        EnqueueValuesForAnalysisReport(
          ItemAnalysisView."Analysis Area"::Inventory, AnalysisReportName.Name, AnalysisLineTemplateName, AnalysisColumnTemplateName, 0D,
          ShowError::None);  // Take 0D for blank Date Filter.

        // Exercise.
        Commit();
        asserterror REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify.
        Assert.ExpectedErrorCannotFind(Database::"Analysis Column Template");
    end;

    local procedure AnalysisReportErrorLine(AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportName: Record "Analysis Report Name";
        ItemAnalysisView: Record "Item Analysis View";
        ShowError: Option "None","Division by Zero","Period Error",Both;
    begin
        // Create Analysis report name and enqueue values for 'AnalysisRequestPageHandler'.
        CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area"::Inventory);
        EnqueueValuesForAnalysisReport(
          ItemAnalysisView."Analysis Area"::Inventory, AnalysisReportName.Name, AnalysisLineTemplateName, AnalysisColumnTemplateName, 0D,
          ShowError::None);  // Take 0D for blank Date Filter.

        // Exercise.
        Commit();
        asserterror REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify.
        Assert.ExpectedErrorCannotFind(Database::"Analysis Line Template");
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportWithPurchaseAnalysisArea()
    var
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchaseLine: Record "Purchase Line";
        ShowError: Option "None","Division by Zero","Period Error",Both;
        RowRefNo: Code[10];
    begin
        // Verify Analysis report for Purchase Analysis Area.

        // Setup: Create Item, create and post Purchase Order.
        Initialize();
        RowRefNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(PurchaseLine.FieldNo("Location Code"), DATABASE::"Purchase Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Purchase Line", PurchaseLine.FieldNo("Location Code")));
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreatePurchaseOrder(PurchaseLine, Item."No.", CreateVendor());
        PostPurchaseOrder(PurchaseLine, true, true);  // Post as Receive and Invoice.
        SetupAnalysisReportWithAnalysisArea(
          ItemAnalysisView."Analysis Area"::Purchase, AnalysisColumn."Value Type"::"Cost Amount", ShowError::None, WorkDate(), Item."No.",
          RowRefNo);

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify: Verify Quantity and Cost Amount on Analysis report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Purchase);
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyIAnalysisReport(RowRefNo, ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportWithSalesAnalysisArea()
    var
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        SalesLine: Record "Sales Line";
        ShowError: Option "None","Division by Zero","Period Error",Both;
        RowRefNo: Code[10];
    begin
        // Verify Analysis report for Sales Analysis Area.

        // Setup: Create Item, create and post Sales Order.
        Initialize();
        RowRefNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(SalesLine.FieldNo("Location Code"), DATABASE::"Sales Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Sales Line", SalesLine.FieldNo("Location Code")));
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate(), CreateCustomer());  // Use Random value for Quantity.
        SetupAnalysisReportWithAnalysisArea(
          ItemAnalysisView."Analysis Area"::Sales, AnalysisColumn."Value Type"::"Sales Amount", ShowError::None, WorkDate(), Item."No.",
          RowRefNo);

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify: Verify Quantity and Sales Amount on Analysis report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::Sale);
        ItemLedgerEntry.CalcFields("Sales Amount (Actual)");
        VerifyIAnalysisReport(RowRefNo, ItemLedgerEntry.Quantity, ItemLedgerEntry."Sales Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportWithInventoryAnalysisArea()
    var
        AnalysisColumn: Record "Analysis Column";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ItemJournalLine: Record "Item Journal Line";
        ShowError: Option "None","Division by Zero","Period Error",Both;
        RowRefNo: Code[10];
    begin
        // Verify Analysis report for Inventory Analysis Area.

        // Setup: Create Item, create and post Item Journal Line.
        Initialize();
        RowRefNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Location Code"), DATABASE::"Item Journal Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Line", ItemJournalLine.FieldNo("Location Code")));
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        SetupAnalysisReportWithAnalysisArea(
          ItemAnalysisView."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Cost Amount", ShowError::None, WorkDate(), Item."No.",
          RowRefNo);

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify: Verify Quantity and Cost Amount on Analysis report.
        FindItemLedgerEntry(ItemLedgerEntry, Item."No.", ItemLedgerEntry."Entry Type"::"Positive Adjmt.");
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        VerifyIAnalysisReport(RowRefNo, ItemLedgerEntry.Quantity, ItemLedgerEntry."Cost Amount (Actual)");
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportShowErrorDivisionByZero()
    var
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisView: Record "Item Analysis View";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ShowError: Option "None","Division by Zero","Period Error",Both;
        AnalysisColumnTemplateName: Code[10];
        RowRefNo: Code[10];
    begin
        // Verify Analysis report for Show error as Division By Zero.

        // Setup: Create Item, create and post Item Journal Line.
        Initialize();
        RowRefNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Location Code"), DATABASE::"Item Journal Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Line", ItemJournalLine.FieldNo("Location Code")));
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        AnalysisColumnTemplateName :=
          SetupAnalysisReportWithAnalysisArea(
            ItemAnalysisView."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Cost Amount", ShowError::"Division by Zero",
            WorkDate(), Item."No.", RowRefNo);
        UpdateAnalysisColumn(ItemAnalysisView."Analysis Area"::Inventory, AnalysisColumnTemplateName);

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify: Verify report for Show error as Division By Zero.
        VerifyAnalysisReportForShowError(RowRefNo, ErrorTxt);
    end;

    [Test]
    [HandlerFunctions('AnalysisRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportShowErrorPeriodError()
    var
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisView: Record "Item Analysis View";
        ItemJournalLine: Record "Item Journal Line";
        Item: Record Item;
        ShowError: Option "None","Division by Zero","Period Error",Both;
        RowRefNo: Code[10];
    begin
        // Verify Analysis report for Show error as Period error.

        // Setup: Create Item, create and post Item Journal Line.
        Initialize();
        RowRefNo :=
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Location Code"), DATABASE::"Item Journal Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Line", ItemJournalLine.FieldNo("Location Code")));
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        SetupAnalysisReportWithAnalysisArea(
          ItemAnalysisView."Analysis Area"::Inventory, AnalysisColumn."Value Type"::"Cost Amount", ShowError::"Period Error", 99991231D,
          Item."No.", RowRefNo);  // Take 31/12/9999 as per report design.

        // Exercise.
        Commit();
        REPORT.Run(REPORT::"Analysis Report", true, false);

        // Verify: Verify report for Show error as Period error.
        VerifyAnalysisReportForShowError(RowRefNo, NotAvailable);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportRequestPageHandler,InventoryAnalysisMatrixPageHandler,VerifyDrillDownMessageHandler')]
    [Scope('OnPrem')]
    procedure AnalysisReportMatrixDrillDownDivisionByZero()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisReportName: Record "Analysis Report Name";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        Formula: Code[80];
    begin
        // [FEATURE] [UI]
        // [SCENARIO 363269] Drill Down cell with Formula on Inventory Analysis Matrix shows error message in case of division by zero
        Initialize();

        // [GIVEN] Analysis Column with "Formula" = "1 / 0"
        Formula := '1/0';
        LibraryInventory.CreateItem(Item);

        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Inventory);
        CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");
        CreateAnalysisColumn(AnalysisColumn, ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, LibraryUtility.GenerateGUID());
        UpdateAnalysisColumnFormula(AnalysisColumn, Formula);

        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisView."Analysis Area");
        CreateAndModifyAnalysisLine(
          AnalysisLine, ItemAnalysisView."Analysis Area", AnalysisLineTemplate.Name, Item."No.", GetRndLocationCode(), AnalysisLine.Type::Item);

        LibraryVariableStorage.Enqueue(StrSubstNo(ColumnFormulaMsg, Formula));
        LibraryVariableStorage.Enqueue(StrSubstNo(ColumnFormulaErrorMsg, ErrorTypeRef::"Division by Zero"));

        // [WHEN] Run Drill Down on Formula on Inventory Analysis Matrix page
        OpenAnalysisReportInventory(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [THEN] Drill Down Message shows text of Formula
        // [THEN] Drill Down Message shows Error Type
        // Verification is done in VerifyDrillDownMessageHandler
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler,PostedSalesDocumentLinesPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForInventoryWithDifferentTransaction()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        DocumentNo: Code[20];
        Qty: Decimal;
        MaterialDirectCost: Decimal;
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // Verify Cost Shares Breakdown report for Inventory when there are different kind types of transaction.

        // Setup: Create Item, Create and Post an Item Journal.
        Initialize();
        Qty := 10 + LibraryRandom.RandDec(10, 2); // Just make sure there are enough Item on Inventory.
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournal(
          ItemJournalLine, Item."No.", ItemJournalLine."Entry Type"::"Positive Adjmt.", Qty, LibraryRandom.RandDec(10, 2));

        // Create and Post Sales Order.
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandDec(10, 2), WorkDate(), CreateCustomer());

        // Create and post Sales Return Order by Get Posted Document To Reverse.
        DocumentNo := CreateAndPostSalesReturnOrderByGetPostedDocToReverse(SalesLine."Sell-to Customer No.");

        // Exercise: Run Cost Shares Breakdown Report.
        Commit();
        RunCostSharesBreakdownReport(Item."No.", PrintCostShare::Inventory, true);

        // Verify: Verify Quantity and Material Direct Cost Applied in the report.
        // Verify Quantity and Material Direct Cost for Item Journal.
        Item.Get(Item."No.");
        LibraryReportDataset.LoadDataSetFile();
        MaterialDirectCost := (Qty - SalesLine.Quantity) * ItemJournalLine."Unit Cost";
        VerifyCostSharesBreakdownReportForInventory(ItemJournalLine."Document No.", Qty - SalesLine.Quantity, MaterialDirectCost);

        // Verify Quantity and Material Direct Cost for Sales Return Order.
        MaterialDirectCost := SalesLine.Quantity * Item."Unit Cost";
        VerifyCostSharesBreakdownReportForInventory(DocumentNo, SalesLine.Quantity, MaterialDirectCost);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForInventoryWithDebtInventory()
    var
        Item: Record Item;
        ItemJournalLine: array[3] of Record "Item Journal Line";
        Qty: Decimal;
        UnitCost: Decimal;
        MaterialDirectCost: Decimal;
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // Verify Cost Shares Breakdown report for Inventory when Item with different Unit Cost is not enough on Inventory.

        // Setup: Create Item, Create and Post 3 Item Journals. One for Sale, another two for Positive Adjmt.
        Initialize();
        Qty := LibraryRandom.RandDec(10, 2);
        UnitCost := LibraryRandom.RandDec(10, 2);
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournal(ItemJournalLine[1], Item."No.", ItemJournalLine[1]."Entry Type"::"Positive Adjmt.", Qty, UnitCost);
        CreateAndPostItemJournal(ItemJournalLine[2], Item."No.", ItemJournalLine[2]."Entry Type"::"Positive Adjmt.", Qty, UnitCost + 1);
        CreateAndPostItemJournal(ItemJournalLine[3], Item."No.", ItemJournalLine[3]."Entry Type"::Sale, 3 * Qty, UnitCost); // Sale 3 times Quantity to make debt inventory.

        // Exercise: Run Cost Shares Breakdown Report.
        Commit();
        RunCostSharesBreakdownReport(Item."No.", PrintCostShare::Inventory, true);

        // Verify: Verify Quantity and Material Direct Cost Applied in the report.
        // Verify Quantity and Material Direct Cost for Debt Inventory.
        Item.Get(Item."No.");
        LibraryReportDataset.LoadDataSetFile();
        MaterialDirectCost :=
          Qty * ItemJournalLine[1]."Unit Cost" + Qty * ItemJournalLine[2]."Unit Cost" - 3 * Qty * Item."Unit Cost";
        VerifyCostSharesBreakdownReportForInventory(ItemJournalLine[3]."Document No.", -Qty, MaterialDirectCost);
    end;

    [Test]
    [HandlerFunctions('PostInventoryCostToGLRequestPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure InvAmountOnPostInventoryCostToGLTestReport()
    var
        ItemNo: Code[20];
    begin
        // Verify Inventory Cost Posted to GL Caption with Inventory Amount exist on generated report.

        // Setup: Create and Post Purchase Order.
        Initialize();
        LibraryLowerPermissions.SetOutsideO365Scope();
        ItemNo := CreateAndPostPurchaseOrder();

        // Exercise: Run Post Inventory Cost To G/L Report.
        LibraryVariableStorage.Enqueue(ValueEntriesWerePostedTxt);

        LibraryLowerPermissions.SetO365Full();

        RunPostInventoryCostToGL(ItemNo);

        // Verify: Verified Inventory Cost Posted to GL Caption with Inventory Amount.
        VerifyAmountsOnInventoryCostToGL(ItemNo);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForInventoryWithPartialRevaluation()
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalLine2: Record "Item Journal Line";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
        AdjustedAmount: Decimal;
    begin
        // Verify Cost Shares Breakdown report for Inventory with doing partial Revaluation.

        // Setup: Create Item, Create and Post a Positive Adjmt. Item Journal, then post a Negative Adjmt. Item Journal with partial quantity.
        // Do Revaluation for remaining quantity of the Item in inventory
        Initialize();
        SetupCostSharesBreakdownReportWithPartialRevaluation(ItemJournalLine, ItemJournalLine2, AdjustedAmount);

        // Exercise: Run Cost Shares Breakdown Report for Inventory.
        RunCostSharesBreakdownReport(ItemJournalLine."Item No.", PrintCostShare::Inventory, true);

        // Verify: Verify Quantity, Material Direct Cost Applied, Revaluation and Total Amount in the report for Positive Adjmt. Item Ledger Entry
        VerifyFieldsOnCostSharesBreakdownReport(
          ItemJournalLine."Document No.", ItemJournalLine.Quantity - ItemJournalLine2.Quantity,
          ItemJournalLine.Quantity * ItemJournalLine."Unit Cost" - ItemJournalLine2.Quantity * ItemJournalLine2."Unit Cost",
          AdjustedAmount);
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForInventoryWithRevaluationForTransferQty()
    var
        PurchaseLine: Record "Purchase Line";
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // Verify Cost Shares Breakdown report for Inventory with doing Revaluation for Transfered Quantity.

        // Setup: Create Item, Location, Post purchase order for the item with the location.
        // Post transfer Order for the item to move partial quantity to a new location. Do Revaluation for the remaining Quantity in
        // the old location and do revaluation for the transfered quantity in the new location.
        Initialize();
        SetupCostSharesBreakdownReportWithRevaluationForTransferQty(ItemJournalLine, PurchaseLine);

        // Exercise: Run Cost Shares Breakdown Report For Inventory.
        RunCostSharesBreakdownReport(ItemJournalLine."Item No.", PrintCostShare::Inventory, true);
        FindItemLedgerEntryWithDocType(
          ItemLedgerEntry, ItemJournalLine."Item No.", ItemLedgerEntry."Document Type"::"Transfer Receipt");

        // Verify: Verify Quantity, Material Direct Cost Applied, Revaluation and Total Amount in the report for Transfer Receipt Item Ledger Entry
        VerifyFieldsOnCostSharesBreakdownReport(
          ItemLedgerEntry."Document No.", ItemJournalLine.Quantity,
          ItemJournalLine.Quantity * PurchaseLine."Direct Unit Cost", ItemJournalLine.Amount);
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesPageHandler')]
    [Scope('OnPrem')]
    procedure BOMCostSharesWithMultipleProdBOMLevels()
    var
        BOMItem: Record Item;
        TopBOMItem: Record Item;
        BOMItemNo: Code[20];
        QtyPer: Decimal;
    begin
        // Setup: Create Top BOM Item with BOM Item as Component. Create Child Item for BOM Item.
        CreateItemWithUnitCost(TopBOMItem, TopBOMItem."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(10));
        QtyPer := LibraryRandom.RandInt(10);
        BOMItemNo := CreateSetupForProductionBOM(TopBOMItem."No.", QtyPer);
        CreateSetupForProductionBOM(BOMItemNo, LibraryRandom.RandInt(10));

        // Exercise: Run BOM Cost Shares Page for Top BOM Item.
        // Verify: Verify Rolled-up Material Cost of the 2nd BOM which is a Purchase Item and it does not account cost from its component.
        BOMItem.Get(BOMItemNo);
        LibraryVariableStorage.Enqueue(BOMItem."Unit Cost" * QtyPer);
        LibraryVariableStorage.Enqueue(BOMItem."No.");
        RunBOMCostSharesPage(TopBOMItem);
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportRequestPageHandler,InventoryAnalysisMatrixRequestPageHandler2')]
    [Scope('OnPrem')]
    procedure AnalysisReportWithFormatPrecision()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisReportName: Record "Analysis Report Name";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        Value: Decimal;
    begin
        // [FEATURE] [Inventory Analysis Matrix]
        // [SCENARIO] Verify that values in Inventory Analysis Matrix are formatted to have max 2 digits in fraction.

        // [GIVEN] Value in Analysis Matrix column having long fraction: 0,115.
        Initialize();
        Value := 0.115;
        LibraryInventory.CreateItem(Item);
        AnalysisReportWithAnalysisView(
          AnalysisReportName, AnalysisLineTemplate, AnalysisColumnTemplate, ItemAnalysisView."Analysis Area"::Inventory,
          AnalysisColumn."Value Type"::"Cost Amount", GetRndLocationCode(), Item."No.");
        CreateAndModifyAnalysisLine(
          AnalysisLine, ItemAnalysisView."Analysis Area"::Inventory, AnalysisLineTemplate.Name, Format(Value),
          GetRndLocationCode(), AnalysisLine.Type::Formula);
        LibraryVariableStorage.Enqueue(AnalysisLine."Row Ref. No.");  // Enqueue AnalysisLine."Row Ref. No." value in InventoryAnalysisMatrixRequestPageHandler2.
        LibraryVariableStorage.Enqueue(Format(Value, 0, LibraryAccountSchedule.GetAutoFormatString()));  // Enqueue expected column value in InventoryAnalysisMatrixRequestPageHandler2.

        // [WHEN] Open Analysis Matrix.
        OpenAnalysisReportInventory(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [THEN] Value on Page: 0,12.
        // Verification is done in InventoryAnalysisMatrixRequestPageHandler2.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellCostAmountInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Cost Amount", true);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry."Cost Amount (Actual)", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellCostAmountNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Cost Amount", false);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry."Cost Amount (Expected)", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellQuantityInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::Quantity, true);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry."Invoiced Quantity", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellQuantityNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::Quantity, false);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry.Quantity, ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellSalesAmountInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Sales Amount", true);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry."Sales Amount (Actual)", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellSalesAmountNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Sales Amount", false);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry."Sales Amount (Expected)", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellNonInventoriableAmountInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Non-Invntble Amount", true);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellNonInventoriableAmountNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Non-Invntble Amount", false);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(0, ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueCostAmountInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Cost Amount", true);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries."Cost Amount (Actual)".AssertEquals(ItemAnalysisViewEntry."Cost Amount (Actual)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueCostAmountNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Cost Amount", false);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries."Cost Amount (Expected)".AssertEquals(ItemAnalysisViewEntry."Cost Amount (Expected)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueQuantityInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::Quantity, true);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries."Invoiced Quantity".AssertEquals(ItemAnalysisViewEntry."Invoiced Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueQuantityNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::Quantity, false);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries.Quantity.AssertEquals(ItemAnalysisViewEntry.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueSalesAmountInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Sales Amount", true);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries."Sales Amount (Actual)".AssertEquals(ItemAnalysisViewEntry."Sales Amount (Actual)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueSalesAmountNotInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Sales Amount", false);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries."Sales Amount (Expected)".AssertEquals(ItemAnalysisViewEntry."Sales Amount (Expected)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportValueNonInventoriableAmountInvoiced()
    var
        ItemAnalysisViewEntry: Record "Item Analysis View Entry";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        ItemAnalysisViewEntries: TestPage "Item Analysis View Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports]

        CreateAnalysisWithMockEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewEntry, AnalysisColumn."Value Type"::"Non-Invntble Amount", true);

        ItemAnalysisViewEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalysisViewEntries."Cost Amount (Non-Invtbl.)".AssertEquals(ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellBudgetCostAmount()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Budget]

        CreateAnalysisWithMockItemBudgetEntry(
          AnalysisLine, AnalysisColumn, ItemBudgetEntry, AnalysisColumn."Analysis Area"::Purchase,
          AnalysisColumn."Value Type"::"Cost Amount");

        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemBudgetEntry."Cost Amount", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellBudgetSalesAmount()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Budget]

        CreateAnalysisWithMockItemBudgetEntry(
          AnalysisLine, AnalysisColumn, ItemBudgetEntry, AnalysisColumn."Analysis Area"::Sales,
          AnalysisColumn."Value Type"::"Sales Amount");

        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemBudgetEntry."Sales Amount", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellBudgetQuantity()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Budget]

        CreateAnalysisWithMockItemBudgetEntry(
          AnalysisLine, AnalysisColumn, ItemBudgetEntry, AnalysisColumn."Analysis Area"::Purchase,
          AnalysisColumn."Value Type"::Quantity);

        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemBudgetEntry.Quantity, ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportCellBudgetCostAmount()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemBudgetEntries: TestPage "Item Budget Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Budget]

        CreateAnalysisWithMockItemBudgetEntry(
          AnalysisLine, AnalysisColumn, ItemBudgetEntry, AnalysisColumn."Analysis Area"::Purchase,
          AnalysisColumn."Value Type"::"Cost Amount");

        ItemBudgetEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemBudgetEntries."Cost Amount".AssertEquals(ItemBudgetEntry."Cost Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportCellBudgetSalesAmount()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemBudgetEntries: TestPage "Item Budget Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Budget]

        CreateAnalysisWithMockItemBudgetEntry(
          AnalysisLine, AnalysisColumn, ItemBudgetEntry, AnalysisColumn."Analysis Area"::Sales,
          AnalysisColumn."Value Type"::"Sales Amount");

        ItemBudgetEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemBudgetEntries."Sales Amount".AssertEquals(ItemBudgetEntry."Sales Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportCellBudgetQuantity()
    var
        ItemBudgetEntry: Record "Item Budget Entry";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemBudgetEntries: TestPage "Item Budget Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Budget]

        CreateAnalysisWithMockItemBudgetEntry(
          AnalysisLine, AnalysisColumn, ItemBudgetEntry, AnalysisColumn."Analysis Area"::Purchase,
          AnalysisColumn."Value Type"::Quantity);

        ItemBudgetEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemBudgetEntries.Quantity.AssertEquals(ItemBudgetEntry.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellAnalysisViewBudgetCostAmount()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Analysis View Budget]

        CreateAnalysisWithMockAnalysisViewBudgEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewBudgEntry, AnalysisColumn."Value Type"::"Cost Amount");
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewBudgEntry."Cost Amount", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellAnalysisViewBudgetSalesAmount()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Analysis View Budget]

        CreateAnalysisWithMockAnalysisViewBudgEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewBudgEntry, AnalysisColumn."Value Type"::"Sales Amount");
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewBudgEntry."Sales Amount", ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CalcItemAnalysisReportCellAnalysisViewBudgetQuantity()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ActualAmount: Decimal;
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Analysis View Budget]

        CreateAnalysisWithMockAnalysisViewBudgEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewBudgEntry, AnalysisColumn."Value Type"::Quantity);
        ActualAmount := CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, false);
        Assert.AreEqual(ItemAnalysisViewBudgEntry.Quantity, ActualAmount, WrongItemAnalysisViewAmountErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportCellAnalysisViewBudgetCostAmount()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ItemAnalyViewBudgEntries: TestPage "Item Analy. View Budg. Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Analysis View Budget]

        CreateAnalysisWithMockAnalysisViewBudgEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewBudgEntry, AnalysisColumn."Value Type"::"Cost Amount");

        ItemAnalyViewBudgEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalyViewBudgEntries."Cost Amount".AssertEquals(ItemAnalysisViewBudgEntry."Cost Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportCellAnalysisViewBudgetSalesAmount()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ItemAnalyViewBudgEntries: TestPage "Item Analy. View Budg. Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Analysis View Budget]

        CreateAnalysisWithMockAnalysisViewBudgEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewBudgEntry, AnalysisColumn."Value Type"::"Sales Amount");

        ItemAnalyViewBudgEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalyViewBudgEntries."Sales Amount".AssertEquals(ItemAnalysisViewBudgEntry."Sales Amount");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DrillDownItemAnalysisReportCellAnalysisViewBudgetQuantity()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry";
        ItemAnalyViewBudgEntries: TestPage "Item Analy. View Budg. Entries";
    begin
        // [FEATURE] [Item Analysis View] [Inventory Analysis Reports] [Item Analysis View Budget]

        CreateAnalysisWithMockAnalysisViewBudgEntry(
          AnalysisLine, AnalysisColumn, ItemAnalysisViewBudgEntry, AnalysisColumn."Value Type"::Quantity);

        ItemAnalyViewBudgEntries.Trap();
        CalcAnalysisReportCell(AnalysisLine, AnalysisColumn, true);
        ItemAnalyViewBudgEntries.Quantity.AssertEquals(ItemAnalysisViewBudgEntry.Quantity);
    end;

    [Test]
    [HandlerFunctions('AnalysisReportNamesPageHandler')]
    [Scope('OnPrem')]
    procedure LookupAnalysisReportName()
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisReportManagement: Codeunit "Analysis Report Management";
        ReportName: Code[10];
    begin
        // [FEATURE] [Inventory Analysis Reports]

        MockAnalysisReportName(AnalysisReportName, AnalysisLineTemplate."Analysis Area"::Inventory);

        LibraryVariableStorage.Enqueue(AnalysisReportName."Analysis Area");
        LibraryVariableStorage.Enqueue(AnalysisReportName.Name);
        AnalysisReportManagement.LookupAnalysisReportName(AnalysisReportName."Analysis Area", ReportName);

        Assert.AreEqual(AnalysisReportName.Name, ReportName, WrongReportNameSelectedErr);
    end;

    [Test]
    [HandlerFunctions('AnalysisLineTemplatesPageHandler')]
    [Scope('OnPrem')]
    procedure LookupAnalysisLineTemplateName()
    var
        ItemAnalysisView: Record "Item Analysis View";
        AnalysisLine: Record "Analysis Line";
        Item: Record Item;
        AnalysisReportManagement: Codeunit "Analysis Report Management";
        AnalysisLineTemplateName: Code[10];
    begin
        // [FEATURE] [Inventory Analysis Reports]

        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        CreateAnalysisLineWithTemplate(AnalysisLine, ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, Item."No.");

        AnalysisLine.SetRange("Analysis Area", ItemAnalysisView."Analysis Area");
        AnalysisLine.SetRange("Analysis Line Template Name", AnalysisLine."Analysis Line Template Name");
        AnalysisReportManagement.LookupAnalysisLineTemplName(AnalysisLineTemplateName, AnalysisLine);

        Assert.AreEqual(AnalysisLine."Analysis Line Template Name", AnalysisLineTemplateName, '');
    end;

    [Test]
    [HandlerFunctions('SetAnalysisReportRequestFilterPageHandler,InventoryAnalysisMatrixVerifyFilterPageHandler')]
    [Scope('OnPrem')]
    procedure LongSourceNoFilterAcceptedByInventoryAnalysisMatrix()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisReportName: Record "Analysis Report Name";
        Item: array[2] of Record Item;
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // [FEATURE] [UI] [Inventory Analysis Reports]
        // [SCENARIO 381039] The page "Inventory Analysis Matrix" should accept source no. filter longer than 30 symbols
        Initialize();

        // [GIVEN] 2 items, each with 20 symbols long "No."
        MockItemWithLongNo(Item[1]);
        MockItemWithLongNo(Item[2]);

        // [GIVEN] Create analysis view, analysis report, analysis column template and analysis line template
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Inventory);
        CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");
        CreateAnalysisColumn(AnalysisColumn, ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, LibraryUtility.GenerateGUID());

        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisView."Analysis Area");
        CreateAndModifyAnalysisLine(
          AnalysisLine, ItemAnalysisView."Analysis Area", AnalysisLineTemplate.Name, Item[1]."No.",
          GetRndLocationCode(), AnalysisLine.Type::Item);

        // [GIVEN] Open "Inventory Analysis Report" page, set "Source No. Filter" = "ITEM1|ITEM2". Filter length is 41 characters
        // [WHEN] Invoke "Show Matrix" action
        LibraryVariableStorage.Enqueue(AnalysisLine."Source Type Filter"::Item);
        LibraryVariableStorage.Enqueue(Item[1]."No." + '|' + Item[2]."No.");
        OpenAnalysisReportInventory(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [THEN] Filter is transferred from "Inventory Analysis Report" to "Inventory Analysis Matrix"
        // Verification is done in InventoryAnalysisMatrixVerifyFilterPageHandler
    end;

    [Test]
    [HandlerFunctions('EditAnalysisReportInventoryRequestPageHandler,InvtAnalysisMatrixExcludeByShowReportPageHandler')]
    [Scope('OnPrem')]
    procedure InventoryAnalysisReportExcludesNoShowLinesAndColumns()
    var
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: array[2] of Record "Analysis Line";
        AnalysisColumn: array[2] of Record "Analysis Column";
    begin
        // [FEATURE] [Inventory Analysis Report]
        // [SCENARIO 359346] Inventory analysis matrix does not show lines with Show = "No" and columns with Show = "Never".
        Initialize();

        // [GIVEN] Inventory analysis report.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Inventory);

        // [GIVEN] Analysis line "L1" is set up for Show = "No".
        CreateInventoryAnalysisLineWithShowSetting(AnalysisLine[1], AnalysisLineTemplate.Name, AnalysisLine[1].Show::No);
        LibraryVariableStorage.Enqueue(AnalysisLine[1]);

        // [GIVEN] Analysis line "L2" is set up for Show = "Yes".
        CreateInventoryAnalysisLineWithShowSetting(AnalysisLine[2], AnalysisLineTemplate.Name, AnalysisLine[2].Show::Yes);
        LibraryVariableStorage.Enqueue(AnalysisLine[2]);

        // [GIVEN] Analysis column "C1" is set up for Show = "Never".
        CreateInventoryAnalysisColumnWithShowSetting(AnalysisColumn[1], AnalysisColumnTemplate.Name, AnalysisColumn[1].Show::Never);
        LibraryVariableStorage.Enqueue(AnalysisColumn[1]);

        // [GIVEN] Analysis column "C2" is set up for Show = "Always".
        CreateInventoryAnalysisColumnWithShowSetting(AnalysisColumn[2], AnalysisColumnTemplate.Name, AnalysisColumn[2].Show::Always);
        LibraryVariableStorage.Enqueue(AnalysisColumn[2]);

        // [WHEN] Open Inventory Analysis Matrix to view the report.
        OpenAnalysisReportInventory(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [THEN] Line "L1" is not shown, Line "L2" is visible.
        // [THEN] Column "C1" is not shown, Column "C2" is visible.
        // [THEN] The matrix has maximum of 32 columns, but only one column ("C2") is now visible.
        // The verification is done in InvtAnalysisMatrixExcludeByShowReportPageHandler handler.
    end;

    [Test]
    [HandlerFunctions('ItemVendorCatalogRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemVendorCatalogReportForExtendedPriceCalculation()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ItemVendor: Record "Item Vendor";
    begin
        // [FEATURE] [Item Vendor Catalog] [Purchase Price]
        // [SCENARIO 365977] "Item/Vendor Catalog" Report prints data for enabled extended price calculation feature

        Initialize();

        // [GIVEN] Enable Extended Price Calculation
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Create Item, Vendor, purchase Price List Line and Item Vendor
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryPurchase.CreateVendor(Vendor);
        CreateItemVendorWithVendorItemNo(ItemVendor, Vendor."No.", Item."No.");
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor."No.");
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [WHEN] Report "Item/Vendor Catalog" is being run
        Commit();
        RunItemVendorReport(Item."No.");

        // [THEN] Report dataset contains line with data from Price List Line
        LibraryReportDataset.LoadDataSetFile();
        VerifyItemVendorCatalogReportExtPriceCalc(
          Item."No.", Vendor."No.", ItemVendor."Vendor Item No.", Format(ItemVendor."Lead Time Calculation"), PriceListLine."Direct Unit Cost");

        LibraryPriceCalculation.DisableExtendedPriceCalculation();
    end;

    [Test]
    [HandlerFunctions('VendorItemCatalogRequestPageHandler')]
    [Scope('OnPrem')]
    procedure VendorItemCatalogReportForExtendedPriceCalculation()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        PriceListHeader: Record "Price List Header";
        PriceListLine: Record "Price List Line";
        ItemVendor: Record "Item Vendor";
    begin
        // [FEATURE] [Vendor Item Catalog] [Purchase Price]
        // [SCENARIO 365977] "Vendor Item Catalog" report prints data for enabled extended price calculation feature

        Initialize();

        // [GIVEN] Enable Extended Price Calculation
        LibraryPriceCalculation.EnableExtendedPriceCalculation();

        // [GIVEN] Create Item, Vendor, purchase Price List Line and Item Vendor
        CreateItem(Item, Item."Replenishment System"::Purchase);
        LibraryPurchase.CreateVendor(Vendor);
        CreateItemVendorWithVendorItemNo(ItemVendor, Vendor."No.", Item."No.");
        LibraryPriceCalculation.CreatePriceHeader(PriceListHeader, "Price Type"::Purchase, "Price Source Type"::Vendor, Vendor."No.");
        LibraryPriceCalculation.CreatePriceListLine(PriceListLine, PriceListHeader, "Price Amount Type"::Price, "Price Asset Type"::Item, Item."No.");
        PriceListLine.Status := PriceListLine.Status::Active;
        PriceListLine.Modify();

        // [WHEN] Report "Item/Vendor Catalog" is being run
        Commit();
        RunVendorItemCatalogReport(Vendor."No.");

        // [THEN] Report dataset contains line with data from Price List Line
        LibraryReportDataset.LoadDataSetFile();
        VerifyVendorItemCatalogReportExtPriceCalc(
          Item."No.", Vendor."No.", ItemVendor."Vendor Item No.", Format(ItemVendor."Lead Time Calculation"), PriceListLine."Direct Unit Cost");

        LibraryPriceCalculation.DisableExtendedPriceCalculation();
    end;

    [Test]
    [HandlerFunctions('ProductionJournalPageHandlerOnlyOutput,ConfirmHandler,MessageHandler,CostSharesBreakdownRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownReportForInventoryOnlyOutput()
    var
        ProdItem: Record Item;
        CompItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ItemLedgerEntry: Record "Item Ledger Entry";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // [SCENARIO 374328] Cost Shares Breakdown report with no consumption posted should be generated correctly
        Initialize();

        // [GIVEN] Product Item. Item Journal Line for that Item is Created and Posted
        CreateItem(ProdItem, ProdItem."Replenishment System"::Purchase);
        CreateAndPostItemJournalLine(ItemJournalLine, ProdItem."No.");

        // [GIVEN] Component Item with Production BOM.
        CreateItem(CompItem, CompItem."Replenishment System"::"Prod. Order");
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ProdItem."No.", CompItem."Base Unit of Measure", 1);
        UpdateProductionBOMOnItem(CompItem, ProductionBOMHeader."No.");

        // [GIVEN] Released Production Order
        CreateAndRefreshProductionOrder(ProductionOrder, ProductionOrder.Status::Released, CompItem."No.", ItemJournalLine.Quantity / 2);

        // [WHEN] Set quantity for the Consumption lines to 0 in the Production Journal and then post it.
        LibraryVariableStorage.Enqueue(PostingMessage);
        LibraryVariableStorage.Enqueue(PostedLinesMessage);
        CreateAndPostProductionJournal(ProductionOrder);

        // [THEN] Cost Shares Breakdown report should be generated correctly and without errors
        Commit();
        RunCostSharesBreakdownReport(CompItem."No.", PrintCostShare::Inventory, true);
        FindItemLedgerEntry(ItemLedgerEntry, CompItem."No.", ItemLedgerEntry."Entry Type"::Output);
        VerifyCostSharesBreakdownReport(ItemLedgerEntry, ItemLedgerEntry.Quantity * CompItem."Unit Cost");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('CostSharesBreakdownRequestPageHandler')]
    procedure CostSharesBreakdownReportForSalesInPeriod()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        SalesLine: Record "Sales Line";
        ValueEntry: Record "Value Entry";
        PrintCostShare: Option Sale,Inventory,"WIP Inventory";
    begin
        // [FEATURE] [Cost Shares Breakdown]
        // [SCENARIO 389622] Cost Shares Breakdown report shows only sales between Starting Date and Ending Date set on the request page.
        Initialize();

        // [GIVEN] Post 100 pcs of an item to inventory.
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateAndPostItemJournal(
          ItemJournalLine, Item."No.", ItemJournalLine."Entry Type"::Purchase,
          LibraryRandom.RandIntInRange(100, 200), LibraryRandom.RandDec(100, 2));

        // [GIVEN] Post 4 sales orders, posting dates = "D1", "D2", "D3", "D4" respectively.
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandInt(10), WorkDate(), '');
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandInt(10), WorkDate() + 30, '');
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandInt(10), WorkDate() + 60, '');
        CreateAndPostSalesOrder(SalesLine, Item."No.", LibraryRandom.RandInt(10), WorkDate() + 90, '');

        // [GIVEN] Sales quantity in period "D2".."D3" = "Q".
        // [GIVEN] Cost amount in period "D2".."D3" = "X".
        ValueEntry.SetRange("Item No.", Item."No.");
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Sale);
        ValueEntry.SetRange("Valuation Date", WorkDate() + 30, WorkDate() + 60);
        ValueEntry.CalcSums("Item Ledger Entry Quantity", "Cost Amount (Actual)");

        // [WHEN] Run Cost Shares Breakdown report for sales with starting date = "D2" and ending date = "D3".
        Commit();
        RunCostSharesBreakdownReportForPeriod(Item."No.", WorkDate() + 30, WorkDate() + 60, PrintCostShare::Sale, false);

        // [THEN] The report shows total quantity = "Q" and total cost = "X".
        VerifyCostSharesBreakdownReportForItem(Item."No.", ValueEntry."Item Ledger Entry Quantity", ValueEntry."Cost Amount (Actual)");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('InventoryAnalysisMatrixVerifyDateFilterPageHandler')]
    procedure InventoryAnalysisReportCurrentMonthByDefault()
    var
        Item: Record Item;
        AnalysisReportName: Record "Analysis Report Name";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        InventoryAnalysisReport: TestPage "Inventory Analysis Report";
        InventoryPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        // [FEATURE] [Inventory Analysis Report]
        // [SCENARIO 391465] When Stan runs inventory analysis report first by year and then by month, the data will be filtered by the current month.
        Initialize();

        // [GIVEN] Inventory analysis report.
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Inventory);
        CreateInventoryAnalysisLineWithShowSetting(AnalysisLine, AnalysisLineTemplate.Name, AnalysisLine.Show::Yes);
        CreateInventoryAnalysisColumnWithShowSetting(AnalysisColumn, AnalysisColumnTemplate.Name, AnalysisColumn.Show::Always);

        // [GIVEN] Open the analysis report card for editing.
        InventoryAnalysisReport.Trap();
        OpenAnalysisReportInventory(AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name);

        // [GIVEN] Current workdate = 25/01/23.
        // [GIVEN] Set "View by" = Year and show matrix. The date filter in the report = 01/01/23..31/12/23 (current year).
        Item.SetRange("Date Filter", CalcDate('<-CY>', WorkDate()), CalcDate('<CY>', WorkDate()));
        LibraryVariableStorage.Enqueue(Item.GetFilter("Date Filter"));
        InventoryAnalysisReport.PeriodType.SetValue(InventoryPeriodType::Year);
        InventoryAnalysisReport.ShowMatrix.Invoke();

        // [WHEN] Now set "View by" = Month and show matrix again. The date filter in the report = 01/01/23..31/01/23 (current month).
        Item.SetRange("Date Filter", CalcDate('<-CM>', WorkDate()), CalcDate('<CM>', WorkDate()));
        LibraryVariableStorage.Enqueue(Item.GetFilter("Date Filter"));
        InventoryAnalysisReport.PeriodType.SetValue(InventoryPeriodType::Month);
        InventoryAnalysisReport.ShowMatrix.Invoke();
    end;

    [Test]
    [HandlerFunctions('TransferDimensionUpdateConfirmHandler,ItemDimensionTotalRequestPageHandler,AnalysisDimSelectionLevelPageHandlerForAllLevels')]
    procedure InventoryByItemLocationAndDimension()
    var
        AnalysisColumn: Record "Analysis Column";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisLine: Record "Analysis Line";
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisReportName: Record "Analysis Report Name";
        DefaultDimension: Record "Default Dimension";
        Dimension: Record Dimension;
        DimensionValue: array[3] of Record "Dimension Value";
        FromLocation: Record Location;
        InTransitLocation: Record Location;
        InventorySetup: Record "Inventory Setup";
        Item: Record Item;
        ItemAnalysisView: Record "Item Analysis View";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ToLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        LibraryDimension: Codeunit "Library - Dimension";
        CodeAsList: List of [Text[30]];
    begin
        // [SCENARIO 550677] Report Item Dimension - Details show wrong Cost Amounts for Transferred items
        Initialize();

        // [GIVEN] Create Inventory analysis report
        LibraryInventory.CreateAnalysisReportName(AnalysisReportName, AnalysisReportName."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisLineTemplate."Analysis Area"::Inventory);
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisColumnTemplate."Analysis Area"::Inventory);
        CreateInventoryAnalysisLineWithShowSetting(AnalysisLine, AnalysisLineTemplate.Name, AnalysisLine.Show::Yes);
        CreateInventoryAnalysisColumnWithShowSetting(AnalysisColumn, AnalysisColumnTemplate.Name, AnalysisColumn.Show::Always);

        // [GIVEN] Create 2 new dimension values for global dimension 1
        LibraryDimension.CreateDimensionValue(DimensionValue[1], LibraryERM.GetGlobalDimensionCode(1));
        LibraryDimension.CreateDimensionValue(DimensionValue[2], LibraryERM.GetGlobalDimensionCode(1));
        Dimension.Get(DimensionValue[1]."Dimension Code");

        // [GIVEN] Create From Location, To Location and In-Transit Locations
        LibraryWarehouse.CreateLocation(FromLocation);
        LibraryWarehouse.CreateLocation(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);

        // [GIVEN] Add Default Dimension to to FROM and TO Locations
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Location, FromLocation.Code, DimensionValue[1]."Dimension Code", DimensionValue[1].Code);
        LibraryDimension.CreateDefaultDimension(
            DefaultDimension, Database::Location, ToLocation.Code, DimensionValue[2]."Dimension Code", DimensionValue[2].Code);

        // [GIVEN] Create New Item and add create Inventory Posting Setup with locations
        CreateItem(Item, Item."Replenishment System"::Purchase);
        InventorySetup.Get();
        LibraryInventory.NoSeriesSetup(InventorySetup);
        LibraryInventory.UpdateInventoryPostingSetup(FromLocation, Item."Inventory Posting Group");
        LibraryInventory.UpdateInventoryPostingSetup(ToLocation, Item."Inventory Posting Group");
        LibraryInventory.UpdateInventoryPostingSetup(InTransitLocation, Item."Inventory Posting Group");

        // [GIVEN] Create and Post Purchase Order
        LibraryPurchase.CreatePurchaseOrder(PurchaseHeader);
        PurchaseHeader.SetHideValidationDialog(true);
        PurchaseHeader.Validate("Posting Date", Today());
        PurchaseHeader.Modify(true);

        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", 1);
        PurchaseLine.Validate("Location Code", FromLocation.Code);
        PurchaseLine.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        // [GIVEN] Create Transfer Order and update FROM Location dimension code on shortcut dimension 1 code and post its shipment
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocation.Code, ToLocation.Code, InTransitLocation.Code);
        TransferHeader.Validate("Posting Date", Today());
        TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[1].Code);
        TransferHeader.Modify(true);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, Item."No.", 1);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, false);

        // [GIVEN] Update shortcut dimension 1 code to TO Location dimension code and post its receipt
        TransferHeader.SetHideValidationDialog(true);
        TransferHeader.Validate("Shortcut Dimension 1 Code", DimensionValue[2].Code);
        LibraryWarehouse.PostTransferOrder(TransferHeader, false, true);

        // [GIVEN] Apply filters on Item Analysis View
        CodeAsList.Add(Item.TableCaption);
        CodeAsList.Add(ToLocation.TableCaption);
        CodeAsList.Add(Dimension.Name);
        SetupDimTotalReportWithAnalysisArea(ItemAnalysisView,
                  DefaultDimension, CodeAsList, ItemAnalysisView."Analysis Area"::Inventory, AnalysisColumn."Value Type"::Quantity);

        // [WHEN] Run Item Dimension - Total report
        Commit();
        REPORT.Run(REPORT::"Item Dimensions - Total", true, false, ItemAnalysisView);

        // [THEN] Total Lines should not be available for Dimension Value 1 Code as the there is no inventory available for the dimension after Transfer Shipment
        VerifyItemDimensionTotalReport(DimensionValue[1].Code, false);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Reports - IV");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - IV");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        UpdateInventorySetupCostPosting();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Reports - IV");
    end;

    local procedure AnalysisReportWithAnalysisView(var AnalysisReportName: Record "Analysis Report Name"; var AnalysisLineTemplate: Record "Analysis Line Template"; var AnalysisColumnTemplate: Record "Analysis Column Template"; AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type"; RowRefNo: Code[10]; ItemNo: Code[20]): Code[10]
    var
        ItemJournalLine: Record "Item Journal Line";
        AnalysisColumn: Record "Analysis Column";
        AnalysisLine: Record "Analysis Line";
        ItemAnalysisView: Record "Item Analysis View";
    begin
        // Create Item Analysis View and Analysis report name.
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, AnalysisArea);
        CreateAnalysisReportName(AnalysisReportName, ItemAnalysisView."Analysis Area");

        // Create Analysis Column Template amd Analysis Columns.
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");
        CreateAndModifyAnalysisColumn(
          ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, ItemJournalLine.FieldCaption(Quantity),
          AnalysisColumn."Value Type"::Quantity, true);
        CreateAndModifyAnalysisColumn(ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, Amount, ValueType, true);

        // Create Analysis Line Template and Analysis Line.
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, ItemAnalysisView."Analysis Area");
        CreateAndModifyAnalysisLine(
          AnalysisLine, ItemAnalysisView."Analysis Area", AnalysisLineTemplate.Name, ItemNo, RowRefNo, AnalysisLine.Type::Item);
        exit(AnalysisLine."Row Ref. No.");
    end;

    local procedure AssertReportValue(ElementName: Text; ExpectedValue: Decimal)
    var
        VarDecimal: Variant;
        ActValue: Variant;
    begin
        LibraryReportDataset.FindCurrentRowValue(ElementName, VarDecimal);
        ActValue := VarDecimal;
        Assert.AreNearlyEqual(ExpectedValue, ActValue, LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);
    end;

    local procedure CalcAnalysisReportCell(AnalysisLine: Record "Analysis Line"; AnalysisColumn: Record "Analysis Column"; DrillDown: Boolean): Decimal
    var
        AnalysisReportManagement: Codeunit "Analysis Report Management";
    begin
        AnalysisLine.SetRange("Date Filter", WorkDate());
        exit(AnalysisReportManagement.CalcCell(AnalysisLine, AnalysisColumn, DrillDown));
    end;

    local procedure CalculateItemAverageCost(): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        Item: Record Item;
        ItemCostManagement: Codeunit ItemCostManagement;
        ItemAverageCost: Decimal;
        AverageCostACY: Decimal;
    begin
        GeneralLedgerSetup.Get();
        ItemCostManagement.CalculateAverageCost(Item, ItemAverageCost, AverageCostACY);  // Average Cost ACY calculated in Item Cost Management.
        ItemAverageCost := Round(ItemAverageCost, GeneralLedgerSetup."Unit-Amount Rounding Precision");
        exit(ItemAverageCost);
    end;

    local procedure CreateAnalysisReportName(var AnalysisReportName: Record "Analysis Report Name"; AnalysisArea: Enum "Analysis Area Type")
    begin
        AnalysisReportName.Init();
        AnalysisReportName.Validate("Analysis Area", AnalysisArea);
        AnalysisReportName.Validate(
          Name, LibraryUtility.GenerateRandomCode(AnalysisReportName.FieldNo(Name), DATABASE::"Analysis Report Name"));
        AnalysisReportName.Insert(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; ItemNo: Code[20]; BaseUnitOfMeasure: Code[10]; QtyPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ItemNo, QtyPer);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateSetupForProductionBOM(BOMItemNo: Code[20]; QtyPer: Decimal): Code[20]
    var
        ChildItem: Record Item;
        BOMItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithUnitCost(ChildItem, ChildItem."Replenishment System"::Purchase, LibraryRandom.RandInt(10));
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem."No.", ChildItem."Base Unit of Measure", QtyPer);
        BOMItem.Get(BOMItemNo);
        UpdateProductionBOMOnItem(BOMItem, ProductionBOMHeader."No.");
        exit(ChildItem."No.");
    end;

    local procedure CreateAndModifyAnalysisColumn(AnalysisArea: Enum "Analysis Area Type"; AnalysisColumnTemplate: Code[10]; ColumnHeader: Text[50]; ValueType: Enum "Analysis Value Type"; IsInvoiced: Boolean)
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        CreateAnalysisColumn(AnalysisColumn, AnalysisArea, AnalysisColumnTemplate, ColumnHeader);
        AnalysisColumn.Validate(Invoiced, IsInvoiced);
        AnalysisColumn.Validate("Value Type", ValueType);
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateAnalysisColumn(var AnalysisColumn: Record "Analysis Column"; AnalysisArea: Enum "Analysis Area Type"; AnalysisColumnTemplate: Code[10]; ColumnHeader: Text[50])
    begin
        LibraryERM.CreateAnalysisColumn(AnalysisColumn, AnalysisArea, AnalysisColumnTemplate);
        AnalysisColumn.Validate("Column No.", CopyStr(LibraryUtility.GenerateGUID(), 1, AnalysisColumn.FieldNo("Column No.")));
        AnalysisColumn.Validate("Column Header", ColumnHeader);
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateAnalysisColumnWithTemplate(var AnalysisColumn: Record "Analysis Column"; AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type"; Invoiced: Boolean)
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
    begin
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, AnalysisArea);
        CreateAndModifyAnalysisColumn(AnalysisArea, AnalysisColumnTemplate.Name, LibraryUtility.GenerateGUID(), ValueType, Invoiced);
        AnalysisColumn.SetRange("Analysis Area", AnalysisArea);
        AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumnTemplate.Name);
        AnalysisColumn.FindFirst();
    end;

    local procedure CreateAnalysisColumnWithTemplateBudgetSource(var AnalysisColumn: Record "Analysis Column"; AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type")
    begin
        CreateAnalysisColumnWithTemplate(AnalysisColumn, AnalysisArea, ValueType, false);
        AnalysisColumn.Validate("Ledger Entry Type", AnalysisColumn."Ledger Entry Type"::"Item Budget Entries");
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateAnalysisLineWithTemplate(var AnalysisLine: Record "Analysis Line"; AnalysisArea: Enum "Analysis Area Type"; ItemAnalysisViewCode: Code[10]; ItemNo: Code[20])
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
    begin
        LibraryInventory.CreateAnalysisLineTemplate(AnalysisLineTemplate, AnalysisArea);
        AnalysisLineTemplate.Validate("Item Analysis View Code", ItemAnalysisViewCode);
        AnalysisLineTemplate.Modify(true);

        CreateAndModifyAnalysisLine(
          AnalysisLine, AnalysisArea, AnalysisLineTemplate.Name, ItemNo, GetRndLocationCode(), AnalysisLine.Type::Item);
    end;

    local procedure CreateAnalysisViewWithMockBudgEntry(var ItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry"; ItemNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        CreateItemAnalysisViewWithDimension(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales, DimensionCode);
        MockItemAnalysisViewBudgEntry(ItemAnalysisViewBudgEntry, ItemAnalysisView, ItemNo, DimensionValueCode);
    end;

    local procedure CreateAnalysisViewWithMockEntry(var ItemAnalysisView: Record "Item Analysis View"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemNo: Code[20]; DimensionCode: Code[20]; DimensionValueCode: Code[20])
    begin
        CreateItemAnalysisViewWithDimension(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales, DimensionCode);
        MockItemAnalysisViewEntry(ItemAnalysisViewEntry, ItemAnalysisView, ItemNo, DimensionValueCode);
    end;

    local procedure CreateAnalysisWithMockAnalysisViewBudgEntry(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry"; ValueType: Enum "Analysis Value Type")
    var
        ItemAnalysisView: Record "Item Analysis View";
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
    begin
        CreateItemWithDefaultDimension(Item, DefaultDimension);
        CreateAnalysisViewWithMockBudgEntry(
          ItemAnalysisView, ItemAnalysisViewBudgEntry, Item."No.", DefaultDimension."Dimension Code",
          DefaultDimension."Dimension Value Code");

        CreateAnalysisColumnWithTemplateBudgetSource(AnalysisColumn, ItemAnalysisView."Analysis Area", ValueType);
        CreateAnalysisLineWithTemplate(AnalysisLine, ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, Item."No.");
    end;

    local procedure CreateAnalysisWithMockEntry(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ValueType: Enum "Analysis Value Type"; Invoiced: Boolean)
    var
        ItemAnalysisView: Record "Item Analysis View";
        Item: Record Item;
        DefaultDimension: Record "Default Dimension";
    begin
        CreateItemWithDefaultDimension(Item, DefaultDimension);
        CreateAnalysisViewWithMockEntry(
          ItemAnalysisView, ItemAnalysisViewEntry, Item."No.", DefaultDimension."Dimension Code", DefaultDimension."Dimension Value Code");

        CreateAnalysisColumnWithTemplate(AnalysisColumn, ItemAnalysisView."Analysis Area", ValueType, Invoiced);
        CreateAnalysisLineWithTemplate(AnalysisLine, ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, Item."No.");
    end;

    local procedure CreateAnalysisWithMockItemBudgetEntry(var AnalysisLine: Record "Analysis Line"; var AnalysisColumn: Record "Analysis Column"; var ItemBudgetEntry: Record "Item Budget Entry"; AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type")
    var
        Item: Record Item;
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateItemBudgetEntry(ItemBudgetEntry, AnalysisArea, Item."No.");

        CreateAnalysisColumnWithTemplateBudgetSource(AnalysisColumn, AnalysisArea, ValueType);
        CreateAnalysisLineWithTemplate(AnalysisLine, AnalysisArea, '', Item."No.");
    end;

    local procedure CreateInventoryAnalysisLineWithShowSetting(var AnalysisLine: Record "Analysis Line"; AnalysisLineTemplateName: Code[10]; ShowSetting: Option)
    begin
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisLine."Analysis Area"::Inventory, AnalysisLineTemplateName);
        AnalysisLine.Validate(Show, ShowSetting);
        AnalysisLine.Modify(true);
    end;

    local procedure CreateInventoryAnalysisColumnWithShowSetting(var AnalysisColumn: Record "Analysis Column"; AnalysisColumnTemplateName: Code[10]; ShowSetting: Option)
    begin
        LibraryInventory.CreateAnalysisColumn(AnalysisColumn, AnalysisColumn."Analysis Area"::Inventory, AnalysisColumnTemplateName);
        AnalysisColumn.Validate("Column Header", LibraryUtility.GenerateGUID());
        AnalysisColumn.Validate(Show, ShowSetting);
        AnalysisColumn.Modify(true);
    end;

    local procedure CreateAndModifyAnalysisLine(var AnalysisLine: Record "Analysis Line"; AnalysisArea: Enum "Analysis Area Type"; AnalysisLineTemplateName: Code[10]; Range: Code[20]; RowRefNo: Code[10]; Type: Enum "Analysis Line Type")
    begin
        LibraryInventory.CreateAnalysisLine(AnalysisLine, AnalysisArea, AnalysisLineTemplateName);
        AnalysisLine.Validate(Type, Type);
        AnalysisLine.Validate("Row Ref. No.", RowRefNo);
        AnalysisLine.Validate(Range, Range);
        AnalysisLine.Modify(true);
    end;

    local procedure CreateAndModifyPurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; LocationCode: Code[10]; BinCode: Code[20])
    begin
        CreatePurchaseOrder(PurchaseLine, ItemNo, '');
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Validate("Bin Code", BinCode);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateAndPostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, 10 + LibraryRandom.RandDec(10, 2));  // Use Random Quantity.
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostItemJournal(var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; Qty: Decimal; UnitCost: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Item);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, EntryType, ItemNo, Qty);
        ItemJournalLine.Validate("Unit Cost", UnitCost);
        ItemJournalLine.Amount := ItemJournalLine."Unit Cost" * Qty; // It is necessary to Validate this field to update Item."Unit Cost".
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostRevaluationJournal(ItemNo: Code[20]): Decimal
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateRevaluationJournal(ItemJournalLine, ItemJournalBatch, ItemNo);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine.Amount);
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20])
    var
        Item: Record Item;
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        Item.SetRange("No.", ItemNo);
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);
        LibraryCosting.CreateRevaluationJournal(
          ItemJournalBatch, Item, WorkDate(), ItemJournalLine."Document No.", "Inventory Value Calc. Per"::"Item Ledger Entry", false, false, false,
          "Inventory Value Calc. Base"::" ", false);

        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + LibraryRandom.RandDec(10, 2));  // Use Random value for Unit Cost Revalued.
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateAndPostSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; PostingDate: Date; CustomerNo: Code[20]): Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CustomerNo);
        SalesHeader.Validate("Posting Date", PostingDate);
        SalesHeader.Modify(true);
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        exit(LibrarySales.PostSalesDocument(SalesHeader, true, true));
    end;

    local procedure CreateAndPostSalesReturnOrderByGetPostedDocToReverse(CustomerNo: Code[20]) PostedDocumentNo: Code[20]
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", CustomerNo);
        SalesHeader.GetPstdDocLinesToReverse();
        PostedDocumentNo := LibrarySales.PostSalesDocument(SalesHeader, true, false); // Post as Receive.
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceNo: Code[20]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndUpdateItemAnalysisView(var ItemAnalysisView: Record "Item Analysis View"; AnalysisArea: Enum "Analysis Area Type"; DimensionCode: Code[20])
    begin
        CreateItemAnalysisViewWithDimension(ItemAnalysisView, AnalysisArea, DimensionCode);
        UpdateItemAnalysisView(ItemAnalysisView.Code);
    end;

    local procedure CreateAndPostPurchaseOrder(): Code[20]
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseOrder(PurchaseLine, LibraryInventory.CreateItem(Item), '');
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(100, 2));
        PurchaseLine.Modify(true);
        PostPurchaseOrder(PurchaseLine, true, true);
        exit(Item."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for Standard Cost.
        Item.Validate("Unit Price", LibraryRandom.RandDec(10, 2));  // Use Random value for UnitPrice.
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);
    end;

    local procedure CreateItemWithDefaultDimension(var Item: Record Item; var DefaultDimension: Record "Default Dimension")
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        UpdateItemDimension(DefaultDimension, Item."No.");
    end;

    local procedure CreateItemWithUnitCost(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; UnitCost: Decimal)
    begin
        CreateItem(Item, ReplenishmentSystem);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify(true);
    end;

    local procedure CreateItemAnalysisView(): Code[10]
    var
        ItemAnalysisView: Record "Item Analysis View";
    begin
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, ItemAnalysisView."Analysis Area"::Sales);
        exit(ItemAnalysisView.Code);
    end;

    local procedure CreateItemAnalysisViewWithDimension(var ItemAnalysisView: Record "Item Analysis View"; AnalysisArea: Enum "Analysis Area Type"; DimensionCode: Code[20])
    begin
        LibraryERM.CreateItemAnalysisView(ItemAnalysisView, AnalysisArea);
        ItemAnalysisView.Validate("Dimension 1 Code", DimensionCode);
        ItemAnalysisView.Modify(true);
    end;

    local procedure CreateItemBudgetEntry(var ItemBudgetEntry: Record "Item Budget Entry"; AnalysisArea: Enum "Analysis Area Type"; ItemNo: Code[20])
    begin
        // Multiply by 1000 to generate random Sales Amount and Cost Amount in multiples of 1000.
        LibraryInventory.CreateItemBudgetEntry(ItemBudgetEntry, AnalysisArea, FindItemBudgetName(AnalysisArea), WorkDate(), ItemNo);
        case AnalysisArea of
            AnalysisArea::Sales:
                ItemBudgetEntry.Validate("Sales Amount", 1000 * LibraryRandom.RandDec(10, 2));
            AnalysisArea::Purchase:
                ItemBudgetEntry.Validate("Cost Amount", 1000 * LibraryRandom.RandDec(10, 2));
        end;
        ItemBudgetEntry.Validate(Quantity, 1000 * LibraryRandom.RandDec(10, 2));
        ItemBudgetEntry.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch"; TemplateType: Enum "Analysis Value Type")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, TemplateType);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
        LibraryUtility.GenerateGUID();  // To avoid 'Item Journal Batch already exists' error.
    end;

    local procedure CreateItemTrackingCodeSerialSpecific(): Code[10]
    var
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        LibraryItemTracking.CreateItemTrackingCode(ItemTrackingCode, true, false);
        ItemTrackingCode.Validate("SN Warehouse Tracking", true);
        ItemTrackingCode.Modify(true);
        exit(ItemTrackingCode.Code);
    end;

    local procedure CreateItemVendorWithVendorItemNo(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20])
    var
        DateFormula: DateFormula;
    begin
        LibraryInventory.CreateItemVendor(ItemVendor, VendorNo, ItemNo);
        ItemVendor.Validate("Vendor Item No.", LibraryUtility.GenerateGUID());
        Evaluate(DateFormula, StrSubstNo('%1D', LibraryRandom.RandIntInRange(2, 5)));
        ItemVendor.Validate("Lead Time Calculation", DateFormula);
        ItemVendor.Modify(true);
    end;

    local procedure CreateCustomer(): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        exit(Customer."No.");
    end;

    local procedure CreateLocationWithBin(var Bin: Record Bin)
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        Location.Validate("Bin Mandatory", true);
        Location.Modify(true);
        LibraryWarehouse.CreateBin(Bin, Location.Code, LibraryUtility.GenerateGUID(), '', '');  // Use blank value for Zone Code and Bin Type Code.
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VendorNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));  // Use random value for Quantity.
    end;

    local procedure CreateStockkeepingUnit(ItemNo: Code[20]; SKUCreationMethod: Enum "SKU Creation Method")
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        LibraryInventory.CreateStockKeepingUnit(Item, SKUCreationMethod, false, false);
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.");
    end;

    local procedure CreateAndPostTransferOrder(var TransferHeader: Record "Transfer Header"; FromLocationCode: Code[10]; ItemNo: Code[20]; Quantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
        Location: Record Location;
        Location2: Record Location;
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryWarehouse.CreateInTransitLocation(Location2);
        LibraryWarehouse.CreateTransferHeader(TransferHeader, FromLocationCode, Location.Code, Location2.Code);
        LibraryWarehouse.CreateTransferLine(TransferHeader, TransferLine, ItemNo, Quantity);
        LibraryWarehouse.PostTransferOrder(TransferHeader, true, true);
    end;

    local procedure EnqueueSerialNos(SerialNo: array[10] of Code[50]; "Count": Integer)
    var
        Iteration: Integer;
    begin
        for Iteration := 1 to Count do
            LibraryVariableStorage.Enqueue(SerialNo[Iteration]);  // Enqueue value for ItemTrackingSummaryPageHandler.
    end;

    local procedure EnqueueValuesForAnalysisReport(AnalysisArea: Enum "Analysis Area Type"; AnalysisReportName: Code[10]; AnalysisLineTemplate: Code[10]; AnalysisColumnTemplate: Code[10]; DateFilter: Date; ShowError: Option)
    begin
        LibraryVariableStorage.Enqueue(AnalysisArea);
        LibraryVariableStorage.Enqueue(AnalysisReportName);
        LibraryVariableStorage.Enqueue(AnalysisLineTemplate);
        LibraryVariableStorage.Enqueue(AnalysisColumnTemplate);
        LibraryVariableStorage.Enqueue(DateFilter);
        LibraryVariableStorage.Enqueue(ShowError);
    end;

    local procedure EnqueueValuesForItemBudgetReport(ItemBudgetEntry: Record "Item Budget Entry"; ValueType: Option; Date: Date; ShowAmount: Boolean)
    begin
        // Enqueue values for 'ItemBudgetRequestPageHandler'.
        LibraryVariableStorage.Enqueue(ItemBudgetEntry."Analysis Area");
        LibraryVariableStorage.Enqueue(ItemBudgetEntry."Budget Name");
        LibraryVariableStorage.Enqueue(ValueType);
        LibraryVariableStorage.Enqueue(Date);
        LibraryVariableStorage.Enqueue(ShowAmount);
        LibraryVariableStorage.Enqueue(ItemBudgetEntry."Item No.");
    end;

    local procedure EnqueueValuesForItemDimensionDetailReport(AnalysisArea: Enum "Analysis Area Type"; AnaysisViewCode: Code[10]; DateFilter: Text[250])
    begin
        LibraryVariableStorage.Enqueue(AnalysisArea);
        LibraryVariableStorage.Enqueue(AnaysisViewCode);
        LibraryVariableStorage.Enqueue(DateFilter);
    end;

    local procedure EnqueueValuesForItemDimensionTotalReport(AnalysisArea: Enum "Analysis Area Type"; AnaysisViewCode: Code[10]; ColumnTemplate: Code[10]; DateFilter: Text[250])
    begin
        LibraryVariableStorage.Enqueue(AnalysisArea);
        LibraryVariableStorage.Enqueue(AnaysisViewCode);
        LibraryVariableStorage.Enqueue(ColumnTemplate);
        LibraryVariableStorage.Enqueue(DateFilter);
    end;

    local procedure FindItemBudgetName(AnalysisArea: Enum "Analysis Area Type"): Code[10]
    var
        ItemBudgetName: Record "Item Budget Name";
    begin
        ItemBudgetName.SetRange("Analysis Area", AnalysisArea);
        ItemBudgetName.FindFirst();
        exit(ItemBudgetName.Name);
    end;

    local procedure FindItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindFirst();
    end;

    local procedure FindItemLedgerEntry(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure FindItemLedgerEntryWithDocType(var ItemLedgerEntry: Record "Item Ledger Entry"; ItemNo: Code[20]; DocumentType: Enum "Item Ledger Document Type")
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Document Type", DocumentType);
        ItemLedgerEntry.FindFirst();
    end;

    local procedure GetRndLocationCode(): Code[10]
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        exit(
          CopyStr(
            LibraryUtility.GenerateRandomCode(ItemJournalLine.FieldNo("Location Code"), DATABASE::"Item Journal Line"), 1,
            LibraryUtility.GetFieldLength(DATABASE::"Item Journal Line", ItemJournalLine.FieldNo("Location Code"))));
    end;

    local procedure InvtCostAndPriceListSetup(var Item: Record Item)
    var
        Bin: Record Bin;
        PurchaseLine: Record "Purchase Line";
    begin
        CreateItem(Item, Item."Costing Method"::Average);
        CreateStockkeepingUnit(Item."No.", "SKU Creation Method"::Location);
        CreateLocationWithBin(Bin);
        CreateAndModifyPurchaseOrder(PurchaseLine, Item."No.", Bin."Location Code", Bin.Code);
        PostPurchaseOrder(PurchaseLine, true, true);

        Commit();
        Item.SetRange("No.", Item."No.");
        LibraryVariableStorage.Enqueue(true);
        REPORT.Run(REPORT::"Inventory Cost and Price List", true, false, Item);
    end;

    local procedure MockItemWithLongNo(var Item: Record Item)
    begin
        Item."No." := LibraryUtility.GenerateGUID() + LibraryUtility.GenerateGUID();
        Item.Insert();
    end;

    local procedure CreateAndPostProductionJournal(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        // Create Production Journal.
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");

        // Posting of Production Journal is done in 'ProductionJournalPageHandler'.
    end;

    local procedure MockAnalysisReportName(var AnalysisReportName: Record "Analysis Report Name"; AnalysisArea: Enum "Analysis Area Type")
    begin
        AnalysisReportName."Analysis Area" := AnalysisArea;
        AnalysisReportName.Name := LibraryUtility.GenerateGUID();
        AnalysisReportName.Insert();
    end;

    local procedure MockItemAnalysisViewBudgEntry(var ItemAnalysisViewBudgEntry: Record "Item Analysis View Budg. Entry"; ItemAnalysisView: Record "Item Analysis View"; ItemNo: Code[20]; DimensionValueCode: Code[20])
    begin
        ItemAnalysisViewBudgEntry."Analysis Area" := ItemAnalysisView."Analysis Area";
        ItemAnalysisViewBudgEntry."Analysis View Code" := ItemAnalysisView.Code;
        ItemAnalysisViewBudgEntry."Item No." := ItemNo;
        ItemAnalysisViewBudgEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemAnalysisViewBudgEntry, ItemAnalysisViewBudgEntry.FieldNo("Entry No."));
        ItemAnalysisViewBudgEntry."Dimension 1 Value Code" := DimensionValueCode;
        ItemAnalysisViewBudgEntry."Posting Date" := WorkDate();
        ItemAnalysisViewBudgEntry."Cost Amount" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewBudgEntry."Sales Amount" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewBudgEntry.Quantity := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewBudgEntry.Insert();
    end;

    local procedure MockItemAnalysisViewEntry(var ItemAnalysisViewEntry: Record "Item Analysis View Entry"; ItemAnalysisView: Record "Item Analysis View"; ItemNo: Code[20]; DimensionValueCode: Code[20])
    begin
        ItemAnalysisViewEntry."Analysis Area" := ItemAnalysisView."Analysis Area";
        ItemAnalysisViewEntry."Analysis View Code" := ItemAnalysisView.Code;
        ItemAnalysisViewEntry."Item No." := ItemNo;
        ItemAnalysisViewEntry."Entry No." := LibraryUtility.GetNewRecNo(ItemAnalysisViewEntry, ItemAnalysisViewEntry.FieldNo("Entry No."));
        ItemAnalysisViewEntry."Dimension 1 Value Code" := DimensionValueCode;
        ItemAnalysisViewEntry."Posting Date" := WorkDate();
        ItemAnalysisViewEntry."Cost Amount (Actual)" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry."Cost Amount (Expected)" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry."Cost Amount (Non-Invtbl.)" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry."Sales Amount (Actual)" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry."Sales Amount (Expected)" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry."Invoiced Quantity" := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry.Quantity := LibraryRandom.RandDec(100, 2);
        ItemAnalysisViewEntry.Insert();
    end;

    local procedure OpenAnalysisReportInventory(AnalysisReportName: Code[10]; AnalysisLineTemplateName: Code[10]; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisReportInventory: TestPage "Analysis Report Inventory";
    begin
        AnalysisReportInventory.OpenEdit();
        AnalysisReportInventory.FILTER.SetFilter(Name, AnalysisReportName);
        AnalysisReportInventory."Analysis Line Template Name".SetValue(AnalysisLineTemplateName);
        AnalysisReportInventory."Analysis Column Template Name".SetValue(AnalysisColumnTemplateName);
        AnalysisReportInventory.EditAnalysisReport.Invoke();  // Edit Analysis Report page Handled by EditAnalysisReportPageHandler.
    end;

    local procedure PostPurchaseOrder(PurchaseLine: Record "Purchase Line"; Receive: Boolean; Invoice: Boolean): Code[20]
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
        exit(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, Receive, Invoice));
    end;

    local procedure RunCalculateInventoryReport(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.Init();
        ItemJournalLine.Validate("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.Validate("Journal Batch Name", ItemJournalBatch.Name);
        LibraryInventory.CalculateInventoryForSingleItem(ItemJournalLine, ItemNo, WorkDate(), true, false);
    end;

    local procedure RunCostSharesBreakdownReport(No: Code[20]; CostSharePrint: Option; ShowDetails: Boolean)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(CostSharePrint);
        LibraryVariableStorage.Enqueue(ShowDetails);
        REPORT.Run(REPORT::"Cost Shares Breakdown", true, false, Item);
    end;

    local procedure RunCostSharesBreakdownReportForPeriod(No: Code[20]; StartDate: Date; EndDate: Date; CostSharePrint: Option; ShowDetails: Boolean)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        LibraryVariableStorage.Enqueue(StartDate);
        LibraryVariableStorage.Enqueue(EndDate);
        LibraryVariableStorage.Enqueue(CostSharePrint);
        LibraryVariableStorage.Enqueue(ShowDetails);
        REPORT.Run(REPORT::"Cost Shares Breakdown", true, false, Item);
    end;

    local procedure RunImplementStandardCostChangeReport(StdCostWorksheetName: Code[10])
    var
        ImplementStandardCostChange: Report "Implement Standard Cost Change";
    begin
        Clear(ImplementStandardCostChange);
        ImplementStandardCostChange.SetStdCostWksh(StdCostWorksheetName);
        ImplementStandardCostChange.UseRequestPage(true);
        Commit();
        ImplementStandardCostChange.Run();
    end;

    local procedure RunItemAgeCompositionValueReport(No: Code[20])
    var
        Item: Record Item;
        PeriodLength: DateFormula;
    begin
        Item.SetRange("No.", No);
        Evaluate(PeriodLength, '<1M>');  // Use 1M for monthly Period.
        LibraryVariableStorage.Enqueue(WorkDate() - 1);
        LibraryVariableStorage.Enqueue(PeriodLength);
        REPORT.Run(REPORT::"Item Age Composition - Value", true, false, Item);
    end;

    local procedure RunItemBudgetReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        REPORT.Run(REPORT::"Item Budget", true, false, Item);
    end;

    local procedure RunItemVendorReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        REPORT.Run(REPORT::"Item/Vendor Catalog", true, false, Item);
    end;

    local procedure RunVendorItemCatalogReport(No: Code[20])
    var
        Vendor: Record Vendor;
    begin
        Vendor.SetRange("No.", No);
        Report.Run(Report::"Vendor Item Catalog", true, false, Vendor);
    end;

    local procedure RunStatusReport(No: Code[20])
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", No);
        REPORT.Run(REPORT::Status, true, false, Item);
    end;

    local procedure RunPostInventoryCostToGL(ItemNo: Code[20])
    var
        PostValueEntryToGL: Record "Post Value Entry to G/L";
    begin
        PostValueEntryToGL.SetRange("Item No.", ItemNo);
        PostValueEntryToGL.SetRange("Posting Date", WorkDate());
        Commit();
        REPORT.Run(REPORT::"Post Inventory Cost to G/L", true, false, PostValueEntryToGL);
    end;

    local procedure RunBOMCostSharesPage(var Item: Record Item)
    var
        BOMCostShares: Page "BOM Cost Shares";
    begin
        BOMCostShares.InitItem(Item);
        BOMCostShares.Run();
    end;

    local procedure StoreSerialNos(var SerialNo: array[10] of Code[50]; ItemNo: Code[20]): Integer
    var
        ReservationEntry: Record "Reservation Entry";
        "Count": Integer;
    begin
        Count := 1;
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.FindSet();
        repeat
            SerialNo[Count] := ReservationEntry."Serial No.";
            Count += 1;
        until ReservationEntry.Next() = 0;
        exit(ReservationEntry.Count);
    end;

    [HandlerFunctions('AnalysisRequestPageHandler')]
    local procedure SetupAnalysisReportWithAnalysisArea(AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type"; ShowError: Option; DateFilter: Date; ItemNo: Code[20]; RowRefNo: Code[10]): Code[10]
    var
        AnalysisLineTemplate: Record "Analysis Line Template";
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisReportName: Record "Analysis Report Name";
    begin
        AnalysisReportWithAnalysisView(
          AnalysisReportName, AnalysisLineTemplate, AnalysisColumnTemplate, AnalysisArea, ValueType, RowRefNo, ItemNo);

        // Enqueue values for 'AnalysisRequestPageHandler'.
        EnqueueValuesForAnalysisReport(
          AnalysisArea, AnalysisReportName.Name, AnalysisLineTemplate.Name, AnalysisColumnTemplate.Name, DateFilter, ShowError);
        exit(AnalysisColumnTemplate.Name);
    end;

    local procedure SetupDimDetailReportWithAnalysisArea(DefaultDimension: Record "Default Dimension"; AnalysisArea: Enum "Analysis Area Type")
    var
        ItemAnalysisView: Record "Item Analysis View";
        SetValue: Option IncludeDimension,NotIncludeDimension;
    begin
        CreateAndUpdateItemAnalysisView(ItemAnalysisView, AnalysisArea, DefaultDimension."Dimension Code");

        // Enqueue values 'ItemDimensionDetailRequestPageHandler' and 'AnalysisDimSelectionLevelPageHandler'.
        LibraryVariableStorage.Enqueue(SetValue::IncludeDimension);
        EnqueueValuesForItemDimensionDetailReport(ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, DateFilterText);
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");
    end;

    local procedure SetupDimTotalReportWithAnalysisArea(var ItemAnalysisView: Record "Item Analysis View"; var DefaultDimension: Record "Default Dimension"; AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type")
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
        ItemJournalLine: Record "Item Journal Line";
        SetValue: Option IncludeDimension,NotIncludeDimension;
    begin
        CreateAndUpdateItemAnalysisView(ItemAnalysisView, AnalysisArea, DefaultDimension."Dimension Code");

        // Create Analysis Column Template and Analysis Column.
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");
        CreateAndModifyAnalysisColumn(
          ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, ItemJournalLine.FieldCaption(Quantity),
          AnalysisColumn."Value Type"::Quantity, true);
        CreateAndModifyAnalysisColumn(ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, Amount, ValueType, true);

        // Enqueue values 'ItemDimensionTotalRequestPageHandler' and 'AnalysisDimSelectionLevelPageHandler'.
        LibraryVariableStorage.Enqueue(SetValue::IncludeDimension);
        EnqueueValuesForItemDimensionTotalReport(
          ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, AnalysisColumnTemplate.Name, DateFilterText);
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Code");
        LibraryVariableStorage.Enqueue(DefaultDimension."Dimension Value Code");
    end;

    local procedure SetupItemBudgetWithAnalysisArea(var ItemBudgetEntry: Record "Item Budget Entry"; AnalysisArea: Enum "Analysis Area Type"; ValueType: Option; Date: Date; ShowAmount: Boolean)
    var
        Item: Record Item;
    begin
        CreateItem(Item, Item."Replenishment System"::Purchase);
        CreateItemBudgetEntry(ItemBudgetEntry, AnalysisArea, Item."No.");
        EnqueueValuesForItemBudgetReport(ItemBudgetEntry, ValueType, Date, ShowAmount);
    end;

    local procedure SetupCostSharesBreakdownReportWithPartialRevaluation(var ItemJournalLine: Record "Item Journal Line"; var ItemJournalLine2: Record "Item Journal Line"; var AdjustedAmount: Decimal)
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No."); // Increase inventory for Item
        CreateAndPostItemJournal(
          ItemJournalLine2, Item."No.", ItemJournalLine."Entry Type"::"Negative Adjmt.",
          ItemJournalLine.Quantity / 2, ItemJournalLine."Unit Cost"); // Decrease partial Quantity in inventory

        AdjustedAmount := CreateAndPostRevaluationJournal(Item."No."); // Do Revaluation for remaining quantity in inventory
    end;

    local procedure SetupCostSharesBreakdownReportWithRevaluationForTransferQty(var ItemJournalLine: Record "Item Journal Line"; var PurchaseLine: Record "Purchase Line")
    var
        Item: Record Item;
        Bin: Record Bin;
        TransferHeader: Record "Transfer Header";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.CreateItem(Item);
        CreateLocationWithBin(Bin);
        CreateAndModifyPurchaseOrder(PurchaseLine, Item."No.", Bin."Location Code", Bin.Code);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        PurchaseLine.Modify(true);
        PostPurchaseOrder(PurchaseLine, true, true);
        CreateAndPostTransferOrder(TransferHeader, Bin."Location Code", Item."No.", PurchaseLine.Quantity / 2); // Transfered Partial Quantity to another location

        CreateRevaluationJournal(ItemJournalLine, ItemJournalBatch, Item."No.");
        // Do Revaluation for remaining quantity in inventory
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.FindLast();
        // Find the Revaluation journal line for the transfered Quantity
        ItemJournalLine.Validate("Unit Cost (Revalued)", ItemJournalLine."Unit Cost (Calculated)" + LibraryRandom.RandDec(10, 2));
        // Use Random value for Unit Cost Revalued.
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name); // Do Revaluation for Transfered Quantity
    end;

    local procedure SuggestAndImplementStandardCostChanges(var ItemJournalBatch: Record "Item Journal Batch"; Item: Record Item; StdCostWorksheetName: Code[10])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalTemplate: Record "Item Journal Template";
        SalesLine: Record "Sales Line";
        StandardCostWorksheet: Record "Standard Cost Worksheet";
    begin
        // Create and post Item Journal Line and Sales Order.
        CreateAndPostItemJournalLine(ItemJournalLine, Item."No.");
        CreateAndPostSalesOrder(SalesLine, Item."No.", ItemJournalLine.Quantity / 2, WorkDate(), CreateCustomer());  // Post partial Quantity.

        // Suggest Standard Cost on Standard Cost Worksheet and update Standard Cost.
        LibraryCosting.SuggestItemStandardCost(Item, StdCostWorksheetName, 1, '');  // StandardCostAdjustmentFactor is 1 and StandardCostRoundingMethod is blank.
        CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Type::Revaluation);

        // Enqueue values for ImplementStandardCostChangePageHandler and Message Handler.
        LibraryVariableStorage.Enqueue(ItemJournalBatch."Journal Template Name");
        LibraryVariableStorage.Enqueue(ItemJournalBatch.Name);
        LibraryVariableStorage.Enqueue(RevaluationLinesCreated);

        StandardCostWorksheet.Get(StdCostWorksheetName, StandardCostWorksheet.Type::Item, Item."No.");
        StandardCostWorksheet.Validate("New Standard Cost", LibraryRandom.RandDec(10, 2));  // Use Random value for updating Standard Cost.
        StandardCostWorksheet.Modify(true);

        // Implement Standard Cost Changes on Standard Cost Worksheet.
        RunImplementStandardCostChangeReport(StdCostWorksheetName);
    end;

    local procedure UpdateAnalysisColumn(AnalysisArea: Enum "Analysis Area Type"; AnalysisColumnTemplateName: Code[10])
    var
        AnalysisColumn: Record "Analysis Column";
    begin
        AnalysisColumn.SetRange("Analysis Area", AnalysisArea);
        AnalysisColumn.SetRange("Analysis Column Template", AnalysisColumnTemplateName);
        AnalysisColumn.FindFirst();
        UpdateAnalysisColumnFormula(AnalysisColumn, StrSubstNo(DivisionByZero, AnalysisColumn."Column No."));
    end;

    local procedure UpdateAnalysisColumnFormula(var AnalysisColumn: Record "Analysis Column"; Formula: Code[80])
    begin
        AnalysisColumn.Validate("Column Type", AnalysisColumn."Column Type"::Formula);
        AnalysisColumn.Validate(Formula, Formula);
        AnalysisColumn.Modify(true);
    end;

    local procedure UpdateCustomerDimension(var DefaultDimension: Record "Default Dimension"; CustomerNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionCustomer(DefaultDimension, CustomerNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdateItemAnalysisView("Code": Code[10])
    var
        ItemAnalysisViewList: TestPage "Item Analysis View List";
    begin
        ItemAnalysisViewList.OpenEdit();
        ItemAnalysisViewList.FILTER.SetFilter(Code, Code);
        ItemAnalysisViewList."&Update".Invoke();
    end;

    local procedure UpdateItemDimension(var DefaultDimension: Record "Default Dimension"; ItemNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, ItemNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure UpdateProductionBOMOnItem(var Item: Record Item; ProductionBOMNo: Code[20])
    begin
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Overhead Rate", LibraryRandom.RandDec(5, 2));  // Use Random value for Overhead Rate.
        Item.Modify(true);
    end;

    local procedure UpdateVendorDimension(var DefaultDimension: Record "Default Dimension"; VendorNo: Code[20])
    var
        Dimension: Record Dimension;
        DimensionValue: Record "Dimension Value";
        LibraryDimension: Codeunit "Library - Dimension";
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
        LibraryDimension.CreateDefaultDimensionVendor(DefaultDimension, VendorNo, Dimension.Code, DimensionValue.Code);
    end;

    local procedure VerifyIAnalysisReport(ItemNo: Code[20]; Quantity: Decimal; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('RowRefNo_AnlysLine', ItemNo);
        LibraryReportDataset.GetNextRow();
        AssertReportValue('ColumnValuesAsText1', Quantity);
        AssertReportValue('ColumnValuesAsText2', Amount);
    end;

    local procedure VerifyAnalysisReportForShowError(ItemNo: Code[20]; ErrorText: Text[50])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('RowRefNo_AnlysLine', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ColumnValuesAsText1', ErrorText);
    end;

    local procedure VerifyCostSharesBreakdownReport(ItemLedgerEntry: Record "Item Ledger Entry"; MaterialDirectCost: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('CostShareBufDocumentNo', ItemLedgerEntry."Document No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CostShareBufNewQuantity', ItemLedgerEntry.Quantity);
        AssertReportValue('NewMatrl_PrintInvCstShrBuf', MaterialDirectCost);
    end;

    local procedure VerifyCostSharesBreakdownReportForInventory(DocumentNo: Code[20]; Quantity: Decimal; MaterialDirectCost: Decimal)
    begin
        LibraryReportDataset.SetRange('CostShareBufDocumentNo', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CostShareBufNewQuantity', Quantity);
        AssertReportValue('NewMatrl_PrintInvCstShrBuf', MaterialDirectCost);
    end;

    local procedure VerifyCostSharesBreakdownReportForItem(ItemNo: Code[20]; Qty: Decimal; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('CostShareBufItemNo', ItemNo);
        Assert.AreEqual(
          Qty, LibraryReportDataset.Sum('CostShareBufNewQuantity'), 'Wrong total quantity in Cost Shares Breakdown report.');
        Assert.AreEqual(
          Amount, LibraryReportDataset.Sum('CostShareBufNewMaterial'), 'Wrong total amount in Cost Shares Breakdown report.');
    end;

    local procedure VerifyItemAgeCompositionReport(ItemNo: Code[20]; ExpectedValue: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtValue5_Item', ExpectedValue);
    end;

    local procedure VerifyItemJournalLine(ItemJournalBatch: Record "Item Journal Batch"; ItemNo: Code[20]; StandardCost: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
        UnitCost: Decimal;
    begin
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Item No.", ItemNo);
        UnitCost := Round(ItemJournalLine."Unit Cost (Revalued)");
        Assert.AreNearlyEqual(UnitCost, StandardCost, LibraryERM.GetAmountRoundingPrecision(), ValueNotMatchedError);
    end;

    local procedure VerifyItemVendorCatalogReportExtPriceCalc(ItemNo: Code[20]; VendorNo: Code[20]; VendorItemNo: Text[20]; LeadTime: Text; UnitCost: Decimal)
    begin
        LibraryReportDataset.SetRange('Price_Vendor_No', VendorNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Item__No__', ItemNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemVend_Vendor_Item_No', VendorItemNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemVend_Lead_Time_Calculation', LeadTime);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price_Direct_Unit_Cost', UnitCost);
    end;

    local procedure VerifyVendorItemCatalogReportExtPriceCalc(ItemNo: Code[20]; VendorNo: Code[20]; VendorItemNo: Text[20]; LeadTime: Text; UnitCost: Decimal)
    begin
        LibraryReportDataset.SetRange('No_Vendor', VendorNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Price_ItemNo', ItemNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price_ItemVendVendorItemNo', VendorItemNo);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price_ItemVendLeadTimeCal', LeadTime);
        LibraryReportDataset.AssertCurrentRowValueEquals('Price_DrctUnitCost', UnitCost);
    end;

    local procedure VerifyItemBudgetReport(ItemNo: Code[20]; CostAmount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ItemBudgetedAmount1', CostAmount);
    end;

    local procedure VerifyItemDimensionDetailReport(ItemNo: Code[20]; Quantity: Decimal; AmountElementName: Text; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('TempValueEntryItemNo', ItemNo);
        LibraryReportDataset.AssertElementWithValueExists(AmountElementName, Amount);
        while LibraryReportDataset.GetNextRow() do
            LibraryReportDataset.AssertCurrentRowValueEquals('TempValueEntryValuedQty', Quantity);
    end;

    local procedure VerifyItemDimensionTotalReport(DimensionCode: Code[20]; Quantity: Decimal; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DimCode1', DimensionCode);
        LibraryReportDataset.GetNextRow();
        AssertReportValue('ColumnValuesAsText11', Quantity);
        AssertReportValue('ColumnValuesAsText21', Amount);
    end;

    local procedure VerifyInvtCostAndPriceListReport(ItemNo: Code[20])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
        ItemAverageCost: Decimal;
    begin
        ItemAverageCost := CalculateItemAverageCost();
        StockkeepingUnit.SetRange("Item No.", ItemNo);
        StockkeepingUnit.FindSet();
        LibraryReportDataset.LoadDataSetFile();

        repeat
            LibraryReportDataset.SetRange('LocationCode_StockKeepingUnit', StockkeepingUnit."Location Code");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('No_Item', StockkeepingUnit."Item No.");
            LibraryReportDataset.AssertCurrentRowValueEquals('AverageCost_StockKeepingUnit', ItemAverageCost);
            Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'More than one record found for ' + StockkeepingUnit."Location Code");
        until StockkeepingUnit.Next() = 0;
    end;

    local procedure VerifyPhysicalInventoryJournal(ItemJournalBatch: Record "Item Journal Batch"; PurchaseLine: Record "Purchase Line")
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        FindItemJournalLine(ItemJournalLine, ItemJournalBatch);
        ItemJournalLine.TestField("Item No.", PurchaseLine."No.");
        ItemJournalLine.TestField("Location Code", PurchaseLine."Location Code");
        ItemJournalLine.TestField("Bin Code", PurchaseLine."Bin Code");
    end;

    local procedure VerifyStatusReport(PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DocumentNo_ItemLedgerEntry', DocumentNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('No_Item', PurchaseLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('RemainingQty', PurchaseLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('UnitCost', PurchaseLine."Unit Cost (LCY)");
    end;

    local procedure VerifyAmountsOnInventoryCostToGL(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('InventoryCostPostedtoGLCaption', InventoryCostPostedToGLCap);
        if not LibraryReportDataset.GetNextRow() then
            Error(RowNotFoundErr, 'InventoryCostPostedtoGLCaption', InventoryCostPostedToGLCap);
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        LibraryReportDataset.AssertCurrentRowValueEquals('InvtAmt', ValueEntry."Cost Posted to G/L");
        LibraryReportDataset.AssertCurrentRowValueEquals('DirCostAmt', -ValueEntry."Cost Posted to G/L");
    end;

    local procedure VerifyFieldsOnCostSharesBreakdownReport(DocumentNo: Code[20]; Quantity: Decimal; MaterialDirectCost: Decimal; Revaluation: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        VerifyCostSharesBreakdownReportForInventory(DocumentNo, Quantity, MaterialDirectCost);
        AssertReportValue('NewReval_PrintInvCstShrBuf', Revaluation);
        AssertReportValue('TotalPrintInvtCostShareBuf', MaterialDirectCost + Revaluation);
    end;

    local procedure UpdateInventorySetupCostPosting()
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Automatic Cost Posting", false);
        InventorySetup.Modify(true);
    end;

    local procedure SetupDimTotalReportWithAnalysisArea(var ItemAnalysisView: Record "Item Analysis View"; var DefaultDimension: Record "Default Dimension"; DimensionList: List of [Text[30]]; AnalysisArea: Enum "Analysis Area Type"; ValueType: Enum "Analysis Value Type")
    var
        AnalysisColumnTemplate: Record "Analysis Column Template";
        AnalysisColumn: Record "Analysis Column";
        ItemJournalLine: Record "Item Journal Line";
        SetValue: Option IncludeDimension,NotIncludeDimension;
    begin
        CreateAndUpdateItemAnalysisView(ItemAnalysisView, AnalysisArea, DefaultDimension."Dimension Code");

        // Create Analysis Column Template and Analysis Column.
        LibraryInventory.CreateAnalysisColumnTemplate(AnalysisColumnTemplate, ItemAnalysisView."Analysis Area");
        CreateAndModifyAnalysisColumn(
          ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, ItemJournalLine.FieldCaption(Quantity),
          AnalysisColumn."Value Type"::Quantity, true);
        CreateAndModifyAnalysisColumn(ItemAnalysisView."Analysis Area", AnalysisColumnTemplate.Name, Amount, ValueType, true);

        // Enqueue values 'ItemDimensionTotalRequestPageHandler' and 'AnalysisDimSelectionLevelPageHandler'.
        LibraryVariableStorage.Enqueue(SetValue::IncludeDimension);

        EnqueueValuesForItemDimensionTotalReport(
          ItemAnalysisView."Analysis Area", ItemAnalysisView.Code, AnalysisColumnTemplate.Name, 't');
        LibraryVariableStorage.Enqueue(DimensionList);
    end;

    local procedure VerifyItemDimensionTotalReport(DimensionCode: Code[20]; ShowBody: Boolean)
    var
        BooleanValue: Variant;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('DimValCode3', DimensionCode);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.FindCurrentRowValue('Level3Body3ShowOutput', BooleanValue);
        Assert.AreEqual(ShowBody, BooleanValue, 'No match');
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisDimSelectionLevelPageHandler(var AnalysisDimSelectionLevel: TestPage "Analysis Dim. Selection-Level")
    var
        AnalysisDimSelectionBuffer: Record "Analysis Dim. Selection Buffer";
        "Code": Variant;
        DimensionValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(Code);
        LibraryVariableStorage.Dequeue(DimensionValue);
        AnalysisDimSelectionLevel.FILTER.SetFilter(Code, Code);
        AnalysisDimSelectionLevel.Level.SetValue(AnalysisDimSelectionBuffer.Level::"Level 1");
        AnalysisDimSelectionLevel."Dimension Value Filter".SetValue(DimensionValue);
        AnalysisDimSelectionLevel.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisRequestPageHandler(var AnalysisReport: TestRequestPage "Analysis Report")
    var
        AnalysisArea: Variant;
        AnalysisReportName: Variant;
        AnalysisLineName: Variant;
        AnalysisColumnName: Variant;
        DateFilter: Variant;
        ShowError: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(AnalysisArea);
        LibraryVariableStorage.Dequeue(AnalysisReportName);
        LibraryVariableStorage.Dequeue(AnalysisLineName);
        LibraryVariableStorage.Dequeue(AnalysisColumnName);
        LibraryVariableStorage.Dequeue(DateFilter);
        LibraryVariableStorage.Dequeue(ShowError);
        AnalysisReport.AnalysisArea.SetValue(AnalysisArea);
        AnalysisReport.AnalysisReportName.SetValue(AnalysisReportName);
        AnalysisReport.AnalysisLineName.SetValue(AnalysisLineName);
        AnalysisReport.AnalysisColumnName.SetValue(AnalysisColumnName);
        AnalysisReport.DateFilter.SetValue(DateFilter);
        AnalysisReport.ShowError.SetValue(ShowError);

        AnalysisReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure EnterQuantityToCreatePageHandler(var EnterQuantityToCreate: TestPage "Enter Quantity to Create")
    begin
        EnterQuantityToCreate.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ImplementStandardCostChangePageHandler(var ImplementStandardCostChange: TestRequestPage "Implement Standard Cost Change")
    var
        BatchName: Variant;
        TemplateName: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(TemplateName);
        LibraryVariableStorage.Dequeue(BatchName);
        ImplementStandardCostChange.PostingDate.SetValue(WorkDate());
        ImplementStandardCostChange.ItemJournalTemplate.SetValue(TemplateName);
        ImplementStandardCostChange.ItemJournalBatchName.SetValue(BatchName);
        ImplementStandardCostChange.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemBudgetRequestPageHandler(var ItemBudget: TestRequestPage "Item Budget")
    var
        FileName: Variant;
        AnalysisArea: Variant;
        ItemBudgetName: Variant;
        ShowValueAs: Variant;
        StartingDate: Variant;
        ShowAmount: Variant;
    begin
        // Dequeue variable.
        LibraryVariableStorage.Dequeue(AnalysisArea);
        LibraryVariableStorage.Dequeue(ItemBudgetName);
        LibraryVariableStorage.Dequeue(ShowValueAs);
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(ShowAmount);
        LibraryVariableStorage.Dequeue(FileName);

        ItemBudget.AnalysisArea.SetValue(AnalysisArea);
        ItemBudget.ItemBudgetFilterCtrl.SetValue(ItemBudgetName);
        ItemBudget.ShowValueAs.SetValue(ShowValueAs);
        ItemBudget.StartingDate.SetValue(StartingDate);
        ItemBudget.AmountsInWhole1000s.SetValue(ShowAmount);
        ItemBudget.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalRequestPageHandler(var ItemDimensionsTotal: TestRequestPage "Item Dimensions - Total")
    var
        AnalysisArea: Variant;
        AnaysisViewCode: Variant;
        ColumnTemplate: Variant;
        DateFilter: Variant;
        SetValueVariant: Variant;
        SetValue: Option IncludeDimension,NotIncludeDimension;
        SetValue2: Option;
    begin
        // Dequeue variable.
        LibraryVariableStorage.Dequeue(SetValueVariant);
        LibraryVariableStorage.Dequeue(AnalysisArea);
        LibraryVariableStorage.Dequeue(AnaysisViewCode);
        LibraryVariableStorage.Dequeue(ColumnTemplate);
        LibraryVariableStorage.Dequeue(DateFilter);
        ItemDimensionsTotal.AnalysisArea.SetValue(AnalysisArea);
        ItemDimensionsTotal.AnalysisViewCode.SetValue(AnaysisViewCode);
        ItemDimensionsTotal.ColumnTemplate.SetValue(ColumnTemplate);
        ItemDimensionsTotal.DateFilter.SetValue(DateFilter);
        SetValue2 := SetValueVariant;
        if SetValue2 = SetValue::IncludeDimension then
            ItemDimensionsTotal.IncludeDimensions.AssistEdit();

        ItemDimensionsTotal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemDimensionDetailRequestPageHandler(var ItemDimensionsDetail: TestRequestPage "Item Dimensions - Detail")
    var
        AnalysisArea: Variant;
        AnaysisViewCode: Variant;
        DateFilter: Variant;
        SetValueVariant: Variant;
        SetValue: Option IncludeDimension,NotIncludeDimension;
        SetValue2: Option;
    begin
        // Dequeue variable.
        LibraryVariableStorage.Dequeue(SetValueVariant);
        LibraryVariableStorage.Dequeue(AnalysisArea);
        LibraryVariableStorage.Dequeue(AnaysisViewCode);
        LibraryVariableStorage.Dequeue(DateFilter);
        ItemDimensionsDetail.AnalysisArea.SetValue(AnalysisArea);
        ItemDimensionsDetail.AnalysisViewCode.SetValue(AnaysisViewCode);

        ItemDimensionsDetail.DateFilterCtrl.SetValue(DateFilter);
        SetValue2 := SetValueVariant;
        if SetValue2 = SetValue::IncludeDimension then
            ItemDimensionsDetail.IncludeDimensions.AssistEdit();

        ItemDimensionsDetail.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemDimensionTotalPageHandlerForColumnTemplate(var ItemDimensionsTotal: TestRequestPage "Item Dimensions - Total")
    var
        AnalysisArea: Variant;
        AnaysisViewCode: Variant;
        ColumnTemplate: Variant;
        DateFilter: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(AnalysisArea);
        LibraryVariableStorage.Dequeue(AnaysisViewCode);
        LibraryVariableStorage.Dequeue(ColumnTemplate);
        LibraryVariableStorage.Dequeue(DateFilter);

        ItemDimensionsTotal.AnalysisArea.SetValue(AnalysisArea);
        ItemDimensionsTotal.AnalysisViewCode.SetValue(AnaysisViewCode);
        ItemDimensionsTotal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingLinesPageHandler(var ItemTrackingLines: TestPage "Item Tracking Lines")
    var
        OptionValue: Variant;
        OptionString: Option AssignSerialNo,SelectEntries;
        TrackingOption: Option;
    begin
        LibraryVariableStorage.Dequeue(OptionValue);  // Dequeue variable.
        TrackingOption := OptionValue;  // To convert Variant into Option.
        case TrackingOption of
            OptionString::AssignSerialNo:
                ItemTrackingLines."Assign Serial No.".Invoke();
            OptionString::SelectEntries:
                ItemTrackingLines."Select Entries".Invoke();
        end;
        ItemTrackingLines.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemTrackingSummaryPageHandler(var ItemTrackingSummary: TestPage "Item Tracking Summary")
    var
        SerialNo: Variant;
        Iteration: Variant;
        "Count": Integer;
        IterationCount: Integer;
    begin
        LibraryVariableStorage.Dequeue(Iteration);  // Dequeue variable.
        IterationCount := Iteration;  // To convert Variant into Integer.
        ItemTrackingSummary.First();
        for Count := 1 to IterationCount do begin
            LibraryVariableStorage.Dequeue(SerialNo);  // Dequeue variable.
            ItemTrackingSummary."Serial No.".AssertEquals(SerialNo);
            ItemTrackingSummary.Next();
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.ExpectedMessage(ExpectedMessage, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandler(var ProductionJournal: TestPage "Production Journal")
    begin
        ProductionJournal.Post.Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProductionJournalPageHandlerOnlyOutput(var ProductionJournal: TestPage "Production Journal")
    var
        EntryType: Enum "Item Ledger Entry Type";
    begin
        Assert.IsTrue(ProductionJournal.FindFirstField(ProductionJournal."Entry Type", EntryType::Consumption), '');
        repeat
            ProductionJournal.Quantity.SetValue(0);
        until not ProductionJournal.FindNextField(ProductionJournal."Entry Type", EntryType::Consumption);
        ProductionJournal.Post.Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure StatusRequestPageHandler(var Status: TestRequestPage Status)
    var
        Date: Variant;
        Name: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(Date);
        LibraryVariableStorage.Dequeue(Name);
        Status.StatusDate.SetValue(Date);
        Status.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EditAnalysisReportRequestPageHandler(var InventoryAnalysisReport: TestPage "Inventory Analysis Report")
    begin
        Commit();  // Due to limitation in Page testability Commit is required for this Test case.
        InventoryAnalysisReport.ShowMatrix.Invoke();  // Show Matrix page Handled by InventoryAnalysisMatrixRequestPageHandler.
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure SetAnalysisReportRequestFilterPageHandler(var InventoryAnalysisReport: TestPage "Inventory Analysis Report")
    var
        SourceNoFilter: Text;
    begin
        InventoryAnalysisReport.CurrentSourceTypeFilter.SetValue(LibraryVariableStorage.DequeueInteger());
        SourceNoFilter := LibraryVariableStorage.DequeueText();
        InventoryAnalysisReport.CurrentSourceTypeNoFilter.SetValue(SourceNoFilter);

        LibraryVariableStorage.Enqueue(SourceNoFilter); // Value will be verified in InventoryAnalysisMatrixVerifyFilterPageHandler
        InventoryAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InventoryAnalysisMatrixRequestPageHandler2(var InventoryAnalysisMatrix: TestPage "Inventory Analysis Matrix")
    var
        ReferenceNumber: Variant;
        FormattedValue: Variant;
    begin
        LibraryVariableStorage.Dequeue(ReferenceNumber);
        LibraryVariableStorage.Dequeue(FormattedValue);
        InventoryAnalysisMatrix.FILTER.SetFilter("Row Ref. No.", ReferenceNumber);
        InventoryAnalysisMatrix.Field1.AssertEquals(FormattedValue);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InventoryAnalysisMatrixPageHandler(var InventoryAnalysisMatrix: TestPage "Inventory Analysis Matrix")
    begin
        InventoryAnalysisMatrix.Field1.DrillDown();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InventoryAnalysisMatrixVerifyFilterPageHandler(var InventoryAnalysisMatrix: TestPage "Inventory Analysis Matrix")
    begin
        Assert.AreEqual(
          LibraryVariableStorage.DequeueText(), InventoryAnalysisMatrix.FILTER.GetFilter("Source No. Filter"), WrongSourceFilterErr);
    end;

    [PageHandler]
    procedure InventoryAnalysisMatrixVerifyDateFilterPageHandler(var InventoryAnalysisMatrix: TestPage "Inventory Analysis Matrix")
    begin
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), InventoryAnalysisMatrix.FILTER.GetFilter("Date Filter"), '');
        InventoryAnalysisMatrix.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure EditAnalysisReportInventoryRequestPageHandler(var InventoryAnalysisReport: TestPage "Inventory Analysis Report")
    var
        InventoryPeriodType: Option Day,Week,Month,Quarter,Year,"Accounting Period";
    begin
        InventoryAnalysisReport.PeriodType.SetValue(InventoryPeriodType::Year);
        InventoryAnalysisReport.ShowMatrix.Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InvtAnalysisMatrixExcludeByShowReportPageHandler(var InventoryAnalysisMatrix: TestPage "Inventory Analysis Matrix")
    var
        AnalysisLine: Record "Analysis Line";
        AnalysisColumn: Record "Analysis Column";
        RecordVariant: Variant;
    begin
        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisLine := RecordVariant;
        Assert.AreEqual(
          AnalysisLine.Show <> AnalysisLine.Show::No, InventoryAnalysisMatrix.GotoRecord(AnalysisLine),
          RowVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisLine := RecordVariant;
        Assert.AreEqual(
          AnalysisLine.Show <> AnalysisLine.Show::No, InventoryAnalysisMatrix.GotoRecord(AnalysisLine),
          RowVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisColumn := RecordVariant;
        Assert.AreEqual(
          AnalysisColumn."Column Header" = InventoryAnalysisMatrix.Field1.Caption, AnalysisColumn.Show <> AnalysisColumn.Show::Never,
          ColumnVisibilityErr);

        LibraryVariableStorage.Dequeue(RecordVariant);
        AnalysisColumn := RecordVariant;
        Assert.AreEqual(
          AnalysisColumn."Column Header" = InventoryAnalysisMatrix.Field1.Caption, AnalysisColumn.Show <> AnalysisColumn.Show::Never,
          ColumnVisibilityErr);

        Assert.IsFalse(InventoryAnalysisMatrix.Field2.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field3.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field4.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field5.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field6.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field7.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field8.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field9.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field10.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field11.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field12.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field13.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field14.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field15.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field16.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field17.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field18.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field19.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field20.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field21.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field22.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field23.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field24.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field25.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field26.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field27.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field28.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field29.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field30.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field31.Visible(), ColumnDoesNotExistErr);
        Assert.IsFalse(InventoryAnalysisMatrix.Field32.Visible(), ColumnDoesNotExistErr);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure VerifyDrillDownMessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, IncorrectExpectedMessageErr);
        LibraryVariableStorage.Dequeue(ExpectedMessage);
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, IncorrectExpectedMessageErr);
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionValueRequestPageHandler(var ItemAgeCompositionValue: TestRequestPage "Item Age Composition - Value")
    var
        EndingDate: Variant;
        PeriodLength: Variant;
    begin
        LibraryVariableStorage.Dequeue(EndingDate);
        LibraryVariableStorage.Dequeue(PeriodLength);

        ItemAgeCompositionValue.EndingDate.SetValue(EndingDate);
        ItemAgeCompositionValue.PeriodLength.SetValue(PeriodLength);
        ItemAgeCompositionValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemVendorCatalogRequestPageHandler(var ItemVendorCatalog: TestRequestPage "Item/Vendor Catalog")
    begin
        ItemVendorCatalog.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure VendorItemCatalogRequestPageHandler(var VendorItemCatalog: TestRequestPage "Vendor Item Catalog")
    begin
        VendorItemCatalog.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CostSharesBreakdownRequestPageHandler(var CostSharesBreakdown: TestRequestPage "Cost Shares Breakdown")
    var
        StartDate: Variant;
        EndDate: Variant;
        CostSharesPrint: Variant;
        ShowDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartDate);
        LibraryVariableStorage.Dequeue(EndDate);
        LibraryVariableStorage.Dequeue(CostSharesPrint);
        LibraryVariableStorage.Dequeue(ShowDetails);

        CostSharesBreakdown.StartDate.SetValue(StartDate);
        CostSharesBreakdown.EndDate.SetValue(EndDate);
        CostSharesBreakdown.CostSharePrint.SetValue(CostSharesPrint);
        CostSharesBreakdown.ShowDetails.SetValue(ShowDetails);
        CostSharesBreakdown.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InvtCostAndPriceListRequestPageHandler(var InventoryCostAndPriceList: TestRequestPage "Inventory Cost and Price List")
    var
        UseStockkeepingUnit: Variant;
    begin
        LibraryVariableStorage.Dequeue(UseStockkeepingUnit);

        InventoryCostAndPriceList.UseStockkeepingUnit.SetValue(UseStockkeepingUnit);
        InventoryCostAndPriceList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure PostedSalesDocumentLinesPageHandler(var PostedSalesDocumentLines: TestPage "Posted Sales Document Lines")
    begin
        PostedSalesDocumentLines.OK().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure PostInventoryCostToGLRequestPageHandler(var PostInventoryCostToGL: TestRequestPage "Post Inventory Cost to G/L")
    begin
        PostInventoryCostToGL.PostMethod.SetValue(Format(PostInventoryCostToGL.PostMethod.GetOption(2)));
        PostInventoryCostToGL.DocumentNo.SetValue('');
        PostInventoryCostToGL.Post.SetValue(true);
        PostInventoryCostToGL.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        RolledupMaterialCost: Variant;
        ItemNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(RolledupMaterialCost);
        LibraryVariableStorage.Dequeue(ItemNo);
        BOMCostShares.Expand(true);
        BOMCostShares.Next();
        BOMCostShares."No.".AssertEquals(ItemNo);
        BOMCostShares.HasWarning.AssertEquals(true);
        BOMCostShares."Rolled-up Material Cost".AssertEquals(RolledupMaterialCost);

        // Verify no component item expanded.
        BOMCostShares.Expand(true);
        Assert.IsFalse(BOMCostShares.Next(), StrSubstNo(ExpandBOMErr, ItemNo));
        BOMCostShares.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisReportNamesPageHandler(var AnalysisReportNames: TestPage "Analysis Report Names")
    begin
        AnalysisReportNames.GotoKey(LibraryVariableStorage.DequeueInteger(), LibraryVariableStorage.DequeueText());
        AnalysisReportNames.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisLineTemplatesPageHandler(var AnalysisLineTemplates: TestPage "Analysis Line Templates")
    begin
        AnalysisLineTemplates.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AnalysisDimSelectionLevelPageHandlerForAllLevels(var AnalysisDimSelectionLevel: TestPage "Analysis Dim. Selection-Level")
    var
        AnalysisDimSelectionBuffer: Record "Analysis Dim. Selection Buffer";
        "CodeListAsVariant": Variant;
        Code: Text[30];
        CodeList: List of [Text[30]];
        Level: Integer;
    begin
        CodeListAsVariant := CodeList;
        LibraryVariableStorage.Dequeue(CodeListAsVariant);
        CodeList := CodeListAsVariant;

        foreach Code in CodeList do begin
            AnalysisDimSelectionLevel.FILTER.SetFilter(Description, Code);
            Level += 1;
            case Level of
                1:
                    AnalysisDimSelectionLevel.Level.SetValue(AnalysisDimSelectionBuffer.Level::"Level 1");
                2:
                    AnalysisDimSelectionLevel.Level.SetValue(AnalysisDimSelectionBuffer.Level::"Level 2");
                3:
                    AnalysisDimSelectionLevel.Level.SetValue(AnalysisDimSelectionBuffer.Level::"Level 3");
            end;
        end;
        AnalysisDimSelectionLevel.Filter.SetFilter(Description, '');
        AnalysisDimSelectionLevel.OK().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure TransferDimensionUpdateConfirmHandler(Message: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Message, TransferLineDimensionChangeQst) > 0, Message);
        Reply := true;
    end;
}
