codeunit 137309 "SCM Reports"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [SCM] [Reports]
        isInitialized := false;
    end;

    var
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryAssembly: Codeunit "Library - Assembly";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        AvgCostingMethodErr: Label 'You must not revalue items with Costing Method Average, if Calculate Per is Item Ledger Entry.';
        BlockedMsg: Label 'Blocked must be No for Item %1.', Comment = '%1 = The Item Number.';
        DateMsg: Label '%1 is not within your allowed range of registering dates.', Comment = '%1 = The date being tested.';
        RoutingLineNotExistErr: Label 'Only Routing Line with Operation No. %1 should present.', Comment = '%1 = The routing operation number being tested.';
        ProductionBOMStatusErr: Label 'The maximum number of BOM levels, %1, was exceeded. The process stopped at item number %2, BOM header number', Comment = '%1 = Max. Level Value, %2 = Item No. Value';
        LineCountErr: Label 'Line count on page does not match line count in table for Usage %1.', Comment = '%1 = The report type being tested, e.g. Sales Invoice';
        MustBeEmptyErr: Label '%1 must be empty for %2.', Comment = '%1 = the expected value, %2 = the actual value.';
        RepItemAgeCompQty_Qty1Txt: Label 'InvtQty1_ItemLedgEntry';
        RepItemAgeCompQty_Qty3Txt: Label 'InvtQty3_ItemLedgEntry';
        RepItemAgeCompQty_TotalTxt: Label 'TotalInvtQty';

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionValueWithoutPeriodLength()
    begin
        // Run Item Age Composition Value report without Period Length and validate the data.
        Initialize();
        RunItemAgeCompositionValueReportAndValidateData(0, 'InvtValue1_Item', 'InvtValue5_Item');
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionValueWithPeriodLength()
    begin
        // Run Item Age Composition Value report with Period Length and validate the data.
        Initialize();
        RunItemAgeCompositionValueReportAndValidateData(
          LibraryRandom.RandInt(5), 'InvtValue1_Item', 'InvtValue5_Item');
    end;

    local procedure RunItemAgeCompositionValueReportAndValidateData(RandomDays: Integer; Column1: Text[30]; Column2: Text[30])
    var
        PeriodLength: DateFormula;
        ItemNo: Code[20];
    begin
        // Setup: Create an Item, post its ledger entry before workdate.
        Evaluate(PeriodLength, '<' + Format(RandomDays) + 'D>');
        ItemNo := LibraryInventory.CreateItemNo();
        CreateAndPostItemJournal(ItemNo, 4 * RandomDays, '');

        // Exercise: Run the Item Age Composition Value report and save it.
        RunItemAgeCompositionValueReport(ItemNo, PeriodLength);

        // Verify: Verify the data in the Report.
        VerifyItemAgeCompositionReport(ItemNo, Column1, Column2, GetCostAmountFromItemLedgerEntry(ItemNo), 0);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionQtyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionQuantityWithoutPeriodLength()
    begin
        // [FEATURE] [Item] [Item Age Composition - Qty.]
        // [SCENARIO] Report 5807 "Item Age Composition - Qty." without Period Length and validate the data.
        Initialize();
        RunItemAgeCompositionQuantityReportAndValidateData(
          0, RepItemAgeCompQty_Qty1Txt, RepItemAgeCompQty_TotalTxt);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionQtyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionQuantityWithPeriodLength()
    begin
        // [FEATURE] [Item] [Item Age Composition - Qty.]
        // [SCENARIO] Report 5807 "Item Age Composition - Qty." with Period Length and validate the data.
        Initialize();

        // Date range on the Report is calculated based on Random days as the difference between the two dates is the No. of Random days.
        RunItemAgeCompositionQuantityReportAndValidateData(
          LibraryRandom.RandInt(5),
          RepItemAgeCompQty_Qty3Txt, RepItemAgeCompQty_TotalTxt);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionQtyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemAgeCompositionQuantityLocationFilter()
    var
        PeriodLength: DateFormula;
        ItemNo: Code[20];
        LocationCode: array[2] of Code[10];
        ExpectedQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Item] [Item Age Composition - Qty.] [Location]
        // [SCENARIO 375795] Report 5807 "Item Age Composition - Qty." filters data by Location Filter
        Initialize();

        // [GIVEN] Item with 2 Positive Adjustments: Location="A" with Qty="X", Location="B" with Qty="Y"
        ItemNo := LibraryInventory.CreateItemNo();
        for i := 1 to 2 do begin
            LocationCode[i] := CreateLocation();
            CreateAndPostItemJournal(ItemNo, 0, LocationCode[i]);
        end;

        // [WHEN] Run REP 5807 "Item Age Composition - Qty." with Location Filter = "A"
        Evaluate(PeriodLength, '');
        RunItemAgeCompositionQuantityReport(ItemNo, PeriodLength, LocationCode[1]);

        // [THEN] Report shows item Quantity = "X"
        ExpectedQty := GetQuantityFromItemLedgerEntry(ItemNo, LocationCode[1]);
        VerifyItemAgeCompositionReport(ItemNo, RepItemAgeCompQty_Qty1Txt, RepItemAgeCompQty_TotalTxt, ExpectedQty, ExpectedQty);
    end;

    local procedure RunItemAgeCompositionQuantityReportAndValidateData(RandomDays: Integer; Column1: Text[30]; Column2: Text[30])
    var
        PeriodLength: DateFormula;
        ItemNo: Code[20];
        ExpectedQty: Decimal;
    begin
        // Setup: Create an Item, post its ledger entry before workdate.
        Evaluate(PeriodLength, '<' + Format(RandomDays) + 'D>');
        ItemNo := LibraryInventory.CreateItemNo();
        CreateAndPostItemJournal(ItemNo, RandomDays, '');

        // Exercise: Run the Item Age Composition Quantity report and save it.
        RunItemAgeCompositionQuantityReport(ItemNo, PeriodLength, '');

        // Verify: Verify the data in the Report.
        ExpectedQty := GetQuantityFromItemLedgerEntry(ItemNo, '');
        VerifyItemAgeCompositionReport(ItemNo, Column1, Column2, ExpectedQty, ExpectedQty);
    end;

    [Test]
    [HandlerFunctions('CalcInventoryValueTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueError()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        CalculatePer: Option "Item Ledger Entry",Item;
    begin
        // Test the functionality of Calculate Inventory Value Test with Average Costing Method.

        // Setup: Create Item with Certified BOM and Routing.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Average, ProductionBOMHeader.Status::Certified, RoutingHeader.Status::Certified);

        // Exercise: Run Calculate Inventory Value Test report.
        Commit();
        RunCalculateInventoryValueTest(Item."No.", CalculatePer::"Item Ledger Entry");

        // Verify: Verify Error Message.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemLedgEntryErrBuf__Item_No__', Item."No.");
        LibraryReportDataset.AssertElementWithValueExists('ItemLedgEntryErrBuf_Error_Text', Format(AvgCostingMethodErr));
    end;

    [Test]
    [HandlerFunctions('CalcInventoryValueTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueWithCertifiedBOMAndRouting()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        CalculatePer: Option "Item Ledger Entry",Item;
    begin
        // Test the functionality of Calculate Inventory Value Test with Certified BOM and Routing.

        // Setup: Create Item with Certified BOM and Routing.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::Certified, RoutingHeader.Status::Certified);

        // Exercise: Run Calculate Inventory Value Test report.
        Commit();
        RunCalculateInventoryValueTest(Item."No.", CalculatePer::Item);

        // Verify: Verify item info is not present in report.
        LibraryReportDataset.LoadDataSetFile();
        asserterror
          LibraryReportDataset.AssertElementWithValueExists('ItemLedgEntryErrBuf__Item_No__', Item."No.");
        asserterror
          LibraryReportDataset.AssertElementWithValueExists('ProdBOMVersionErrBuf__Production_BOM_No__', Item."Production BOM No.");
        asserterror
          LibraryReportDataset.AssertElementWithValueExists('RtngVersionErrBuf__Routing_No__', Item."Routing No.");
    end;

    [Test]
    [HandlerFunctions('CalcInventoryValueTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueWithUnderDevelopmentBOMAndRouting()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        CalculatePer: Option "Item Ledger Entry",Item;
    begin
        // Test the functionality of Calculate Inventory Value Test with Under Development BOM and Routing.

        // Setup: Create Item with Under Development BOM and Routing.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::"Under Development",
          RoutingHeader.Status::"Under Development");

        // Exercise: Run Calculate Inventory Value Test report.
        Commit();
        RunCalculateInventoryValueTest(Item."No.", CalculatePer::Item);

        // Verify: Verify report data.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCalculateInventoryValueReport(
          'ProdBOMVersionErrBuf__Production_BOM_No__', Item."Production BOM No.",
          'ProdBOMVersionErrBuf_Status', Format(ProductionBOMHeader.Status::"Under Development"));
        VerifyCalculateInventoryValueReport(
          'RtngVersionErrBuf__Routing_No__', Item."Routing No.",
          'RtngVersionErrBuf_Status', Format(RoutingHeader.Status::"Under Development"));
    end;

    [Test]
    [HandlerFunctions('CalcInventoryValueTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CalculateInventoryValueWithBOMAndRoutingVersion()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        CalculatePer: Option "Item Ledger Entry",Item;
    begin
        // Test the functionality of Calculate Inventory Value Test with BOM and Routing Versions.

        // Setup: Create Item with Under Development BOM and Routing. Create Production BOM Version and Routing Version.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::"Under Development",
          RoutingHeader.Status::"Under Development");
        CreateProductionBOMVersion(Item."Production BOM No.");
        CreateRoutingVersion(RoutingVersion, Item."Routing No.");

        // Exercise: Run Calculate Inventory Value Test report.
        Commit();
        RunCalculateInventoryValueTest(Item."No.", CalculatePer::Item);

        // Verify.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCalculateInventoryValueReport(
          'ProdBOMVersionErrBuf__Production_BOM_No__', Item."Production BOM No.",
          'ProdBOMVersionErrBuf_Status', Format(ProductionBOMHeader.Status::"Under Development"));
        VerifyCalculateInventoryValueReport(
          'RtngVersionErrBuf__Routing_No__', Item."Routing No.",
          'RtngVersionErrBuf_Status', Format(RoutingHeader.Status::"Under Development"));
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentSalesHandler,ItemChargesSpecificationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargesSpecificationSales()
    var
        SalesLine: Record "Sales Line";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        OldStockoutWarning: Boolean;
        OldCreditWarnings: Option;
        SourceType: Option Sale,Purchase;
    begin
        // Run Item Charges Specification Report and Verify Posted Item Charge for Sales Order.

        // Setup: Create and Post Sales Order with Item Charge.
        Initialize();
        UpdateSalesReceivableSetup(OldCreditWarnings, OldStockoutWarning, SalesReceivablesSetup."Credit Warnings"::"No Warning", false);
        CreateAndPostSalesOrderWithItemCharge(SalesLine);

        // Exercise: Run Item Charges Specification Report with Source Type as Sales.
        RunItemChargesSpecification(SalesLine."Sell-to Customer No.", SourceType::Sale);

        // Verify: Item Charge for the posted Sales Document.
        VerifyItemChargesSpecificationReport(SalesLine."Sell-to Customer No.", SalesLine.Amount);

        // Teardown: Rollback Sales and Receivable Setup.
        UpdateSalesReceivableSetup(OldCreditWarnings, OldStockoutWarning, OldCreditWarnings, OldStockoutWarning);
    end;

    [Test]
    [HandlerFunctions('ItemChargeAssignmentPurchaseHandler,ItemChargesSpecificationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemChargesSpecificationPurchase()
    var
        PurchaseLine: Record "Purchase Line";
        SourceType: Option Sale,Purchase;
    begin
        // Used Integer Values for Quantity and Cost Due to Difference in Decimal Values Bug ID: 274326.
        // Run Item Charges Specification Report and Verify Posted Item Charge for Purchase Order.

        // Setup: Create and Post Purchase Order with Item Charge.
        Initialize();
        CreateAndPostPurchaseOrderWithItemCharge(PurchaseLine);

        // Exercise: Run Item Charges Specification Report with Source Type as Purchase.
        RunItemChargesSpecification(PurchaseLine."Buy-from Vendor No.", SourceType::Purchase);

        // Verify: Item Charge for the Posted Purchase Document.
        VerifyItemChargesSpecificationReport(PurchaseLine."Buy-from Vendor No.", PurchaseLine.Amount);
    end;

    [Test]
    [HandlerFunctions('CompareProductionCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CompareProductionCostSharesReportForTwoItemsWithDifferentBOM()
    var
        Item: Record Item;
        Item2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        Component: Code[20];
        Component2: Code[20];
        ExpectedValue: Decimal;
        ExpectedValue2: Decimal;
    begin
        // Run Compare Production Cost Shares Report for Two Items with different BOMs and validate the data.

        // Setup: Create two Items with Routing and Production BOM.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::Certified, RoutingHeader.Status::Certified);
        CreateManufacturingItem(
          Item2, Item."Costing Method"::Standard, ProductionBOMHeader.Status::Certified, RoutingHeader.Status::Certified);

        // Exercise: Run Compare Production Cost Shares Report and calculate expected values for verification.
        Commit();
        RunCompareProductionCostSharesReport(Item."No.", Item2."No.");
        Component := GetComponent(Item."Production BOM No.");
        Component2 := GetComponent(Item2."Production BOM No.");
        ExpectedValue := CalculateExpectedValue(Item."Production BOM No.", Component) -
          CalculateExpectedValue(Item2."Production BOM No.", Component);
        ExpectedValue2 := CalculateExpectedValue(Item."Production BOM No.", Component2) -
          CalculateExpectedValue(Item2."Production BOM No.", Component2);

        // Verify: Verify data in the Report.
        LibraryReportDataset.LoadDataSetFile();
        VerifyCompareProductionCostSharesReport(Component, ExpectedValue);
        VerifyCompareProductionCostSharesReport(Component2, ExpectedValue2);
    end;

    [Test]
    [HandlerFunctions('ItemRegisterValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ItemRegisterValueReport()
    var
        ItemNo: Code[20];
        JournalBatchName: Code[10];
    begin
        // Verify data in Item Register Value report after Posting Item Journal Line.

        // Setup: Create and Post Item Journal Line.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        JournalBatchName := CreateAndPostItemJournal(ItemNo, LibraryRandom.RandInt(5), '');

        // Exercise: Run Item Register Value Report.
        RunItemRegisterValueReport(JournalBatchName);

        // Verify: Verify Item Value Entry Report.
        VerifyItemValueEntryReport(ItemNo);
    end;

    [Test]
    [HandlerFunctions('SubcontractorDispatchListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SubcontractorDispatchListWithoutSubcontractor()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Test functionality of Subcontractor Dispatch List report without updating Subcontractor No. on Work Center.

        // Setup: Create and Refresh Production Order.
        Initialize();
        ProductionOrder.Get(ProductionOrder.Status::Released, CreateAndRefreshProductionOrder());

        // Exercise: Run Subcontractor Dispatch List report without updating Subcontractor No. on Work Center.
        Commit();
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        RunSubcontractorDispatchList(ProdOrderRoutingLine);

        // Verify: Verify Report is not generated.
        LibraryReportDataset.LoadDataSetFile();
        Assert.IsFalse(LibraryReportDataset.GetNextRow(), 'Report should be empty.');
    end;

    [Test]
    [HandlerFunctions('SubcontractorDispatchListRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SubcontractorDispatchListWithSubcontractor()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        // Test functionality of Subcontractor Dispatch List report with updating Subcontractor No. on Work Center.

        // Setup: Create and Refresh Production Order.
        Initialize();
        ProductionOrder.Get(ProductionOrder.Status::Released, CreateAndRefreshProductionOrder());

        // Exercise: Run Subcontractor Dispatch List report with updating Subcontractor No. on Work Center.
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        UpdateAndCalculateWorkCenterCalendar(ProdOrderRoutingLine."No.");
        Commit();
        RunSubcontractorDispatchList(ProdOrderRoutingLine);

        // Verify: Verify Subcontractor Dispatch List report.
        VerifySubcontractorDispatchListReport(ProductionOrder, ProdOrderRoutingLine);
    end;

    [HandlerFunctions('BinContentCreationWkshtRequestPageHandler')]
    [Scope('OnPrem')]
    procedure BinContentCreateWorksheetReport()
    var
        BinCreationWorksheetLine: Record "Bin Creation Worksheet Line";
    begin
        // Test functionality of Bin Content Create Worksheet Report.

        // Setup: Create Location with Zones and Bins. Create Bin Creation Worksheet Line.
        Initialize();
        CreateBinCreationWorksheetLine(BinCreationWorksheetLine);

        // Exercise: Run Bin Content Create Worksheet Report.
        Commit();
        RunBinContentCreateWorksheetReport(BinCreationWorksheetLine);

        // Verify: Verify that the Bin Code and Location Code exist in the Report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('BinCode_BinCreateWkshLine', BinCreationWorksheetLine."Bin Code");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('LocCode_BinCreateWkshLine',
          BinCreationWorksheetLine."Location Code");
    end;

    [Test]
    [HandlerFunctions('WhsePostedShipmentRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehousePostedShipmentReport()
    var
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        // Test and verify functionality of Warehouse Posted Shipment report.

        // Setup: Create Full Warehouse Setup. Create and release Purchase Order. Create and post Warehouse Receipt. Register Put away. Create and release Sales Order. Create, release and post Warehouse Shipment.
        Initialize();
        CreateFullWarehouseSetup(Location);
        CreateAndReleasePurchaseOrder(PurchaseHeader, PurchaseLine, Location.Code);
        CreateAndPostWarehouseReceipt(PurchaseHeader);
        RegisterWarehouseActivity(PurchaseHeader."No.", WarehouseActivityLine."Activity Type"::"Put-away");
        CreateAndReleaseSalesOrder(SalesHeader, PurchaseLine);
        CreateAndReleaseWarehouseShipment(WarehouseShipmentHeader, SalesHeader);
        LibraryWarehouse.CreateWhsePick(WarehouseShipmentHeader);
        RegisterWarehouseActivity(SalesHeader."No.", WarehouseActivityLine."Activity Type"::Pick);
        LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // Exercise: Run Warehouse Posted Shipment report.
        RunWarehousePostedShipmentReport(WarehouseShipmentHeader."No.");

        // Verify: Verify Warehouse Posted Shipment report.
        VerifyWarehousePostedShipmentReport(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('WhseInvtRegisteringTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseInventoryRegisteringTestReportWithBlockedWarning()
    var
        Location: Record Location;
        ItemNo: Code[20];
    begin
        // Test to check the Blocked Warning on Warehouse Inventory Registering Test report.

        // Setup: Create Location, Create and modify Item and Create Warehouse Item Journal line.
        Initialize();
        CreateFullWarehouseSetup(Location);
        ItemNo := CreateBlockedItem();
        CreateWarehouseItemJournalLine(Location.Code, ItemNo, WorkDate());

        // Exercise: Run Warehouse Inventory Registering Test report.
        Commit();
        RunWarehouseInventoryRegisteringTestReport(ItemNo);

        // Verify: Warning for Blocked Item exist on the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Warehouse_Journal_Line__Item_No__', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ErrorText_Number_',
          Format(StrSubstNo(BlockedMsg, ItemNo)));
    end;

    [Test]
    [HandlerFunctions('WhseInvtRegisteringTestRequestPageHandler')]
    [Scope('OnPrem')]
    procedure WarehouseInventoryRegisteringTestReportWithDateWarning()
    var
        Item: Record Item;
        Location: Record Location;
        UserSetup: Record "User Setup";
        RegisteringDate: Date;
    begin
        // Test to check the Date range Warning on Warehouse Inventory Registering Test report.

        // Setup: Create Location, Create an Item, Create and modify User Setup and Create Warehouse Item Journal line.
        Initialize();
        CreateFullWarehouseSetup(Location);
        LibraryInventory.CreateItem(Item);
        CreateAndModifyUserSetup(UserSetup);
        RegisteringDate := CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', UserSetup."Allow Posting To");
        CreateWarehouseItemJournalLine(Location.Code, Item."No.", RegisteringDate);

        // Exercise: Run Warehouse Inventory Registering Test report.
        Commit();
        RunWarehouseInventoryRegisteringTestReport(Item."No.");

        // Verify: Warning for Date range exist on the report.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('Warehouse_Journal_Line__Item_No__', Item."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Warehouse_Journal_Line__Registering_Date_', Format(RegisteringDate));
        LibraryReportDataset.AssertCurrentRowValueEquals('ErrorText_Number_',
          Format(StrSubstNo(DateMsg, RegisteringDate)));

        // Clean Up: Delete the User Setup.
        UserSetup.Delete(true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure StandardCostOnItemAfterCalculatingStandardCost()
    var
        InventorySetup: Record "Inventory Setup";
        ChildItem: Record Item;
        ParentItem: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        QuantityPer: Decimal;
    begin
        // Verify Standard Cost on Item after running Calculate Standard Cost of the Item.

        // Setup: Update Inventory Setup and Create Parent and Child Items with different Replenishment Systems.
        // Also assign BOM No. to Parent Item with Component of Child Item.
        Initialize();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        QuantityPer := LibraryRandom.RandInt(10);
        CreateItemsWithDifferentReplenishmentSystems(ParentItem, ChildItem, QuantityPer);

        // Exercise: Calculate Standard Cost for Parent Item.
        CalculateStandardCost.CalcItem(ParentItem."No.", false);

        // Verify: Verify Standard Cost on Parent Item.
        ParentItem.Get(ParentItem."No.");
        ParentItem.TestField("Standard Cost", ChildItem."Unit Cost" * QuantityPer);

        // Teardown.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportWithLessthanUnitCost()
    begin
        // Verify Inventory Valuation Test Report values when Revaluation Journal posted before finishing Prod. Order with Lessthan Unit Cost(Revalued).
        InventoryValuationWIPReportWithFinishedRelProdOrder(LibraryRandom.RandDec(5, 2), WorkDate(), true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportWithGreaterthanUnitCost()
    begin
        // Verify Inventory Valuation Test Report values when Revaluation Journal posted before finishing Prod. Order with morethan Unit Cost(Revalued).
        InventoryValuationWIPReportWithFinishedRelProdOrder(-LibraryRandom.RandDec(5, 2), WorkDate(), true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportWithExactUnitCost()
    begin
        // Verify Inventory Valuation Test Report values when Revaluation Journal posted before finishing Prod. Order with total Unit Cost(Revalued).
        InventoryValuationWIPReportWithFinishedRelProdOrder(0, WorkDate(), true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportDateGreaterThanRevJournalPosted()
    begin
        // Verify Inventory Valuation WIP Test Report values when report is run for next month of Revaluation Journal Posted.
        InventoryValuationWIPReportWithFinishedRelProdOrder(0, CalcDate('<2M>', WorkDate()), true);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportAfterFinishingReleasedProdOrderWithLessUnitCost()
    begin
        // Verify Inventory Valuation WIP Test Report values when Revaluation Journal posted after finishing Prod. Order with Lessthan Unit Cost(Revalued).
        InventoryValuationWIPReportWithFinishedRelProdOrder(LibraryRandom.RandDec(5, 2), WorkDate(), false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportAfterFinishingReleasedProdOrderWithMoreUnitCost()
    begin
        // Verify Inventory Valuation WIP Test Report values when Revaluation Journal posted after finishing Prod. Order with morethan Unit Cost(Revalued).
        InventoryValuationWIPReportWithFinishedRelProdOrder(-LibraryRandom.RandDec(5, 2), WorkDate(), false);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,InventoryValuationWIPRequestPageHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportAfterFinishingReleasedProdOrderWithExactUnitCost()
    begin
        // Verify Inventory Valuation WIP Test Report values when Revaluation Journal posted before finishing Prod. Order with Total Unit Cost(Revalued).
        InventoryValuationWIPReportWithFinishedRelProdOrder(0, WorkDate(), false);
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMWithoutVersion()
    var
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMHeaderNo: Code[20];
    begin
        // Verify Quantity Explosion of BOM Test Report values when Production Bom created without version.

        // Setup: Create Item with New BOM.
        Initialize();
        LibraryInventory.CreateItem(SecondChildItem);
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order",
          CreateProductionBOM(SecondChildItem."Base Unit of Measure", ProductionBOMHeader.Status::New), 0);
        ProductionBOMHeaderNo := CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item, SecondChildItem."No.");
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeaderNo, LibraryRandom.RandDec(10, 2));

        // Exercise: Run Quantity Explosion of BOM Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Quantity Explosion of BOM", true, false, Item);

        // Verify: Verify Values on Quantity Explosion of BOM Test report values.
        VerifyQuantityExplosionOfBOMReport(SecondChildItem."No.", ParentItem."Production BOM No.");
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMWithUnCertifiedVersion()
    begin
        // Verify Quantity Explosion of BOM Test Report values when Production Bom created with Un Certified version.
        QuantityExplosionOfBOMWithVersions(Enum::"BOM Status"::New);
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMCertifiedVersion()
    begin
        // Verify Quantity Explosion of BOM Test Report values when Production Bom created with Certified versions.
        QuantityExplosionOfBOMWithVersions(Enum::"BOM Status"::Certified);
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostSharesWithoutVersion()
    var
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMHeaderNo: Code[20];
    begin
        // Verify Rolled-up Cost Shares Test Report values when Production Bom created without versions.

        // Setup: Create Item with New BOM.
        Initialize();
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order", '', LibraryRandom.RandDec(10, 2));
        ProductionBOMHeaderNo := CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(SecondChildItem));
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeaderNo, 0);

        // Exercise: Run Rolled-up Cost Shares Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Rolled-up Cost Shares", true, false, Item);

        // Verify: Verify Values on Rolled-up Cost Shares Test report values.
        LibraryReportDataset.LoadDataSetFile();
        SelectProductionBOMLines(ProductionBOMLine, ParentItem."Production BOM No.");
        repeat
            LibraryReportDataset.SetRange('ProdBOMLineIndexNo', ProductionBOMLine."No.");
            LibraryReportDataset.GetNextRow();
            LibraryReportDataset.AssertCurrentRowValueEquals('BOMCompQtyBase', ProductionBOMLine.Quantity);
        until ProductionBOMLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostSharesWithItemAndVersion()
    var
        Item: Record Item;
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeaderNo: Code[20];
    begin
        // Verify Rolled-up Cost Shares Test Report values when Production Bom Line created with Type Item and Certified version.

        // Setup: Create Item with New BOM with certified Production BOM Version.
        Initialize();
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order", '', LibraryRandom.RandDec(10, 2));
        CreateItemWithReplSysAndCostingMethod(SecondChildItem, SecondChildItem."Costing Method"::FIFO,
          SecondChildItem."Replenishment System"::"Prod. Order", CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(Item)), 0);
        ProductionBOMHeaderNo := CreateProductionBOMWithLines(SecondChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(Item));
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeaderNo, 0);
        CreateProductionBOMVersionWithBOMLines(ProductionBOMHeaderNo, ParentItem."Production BOM No.",
          LibraryInventory.CreateItem(Item), FirstChildItem."No.", ProductionBOMVersion.Status::Certified);

        // Exercise: Run Rolled-up Cost Shares Report .
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Rolled-up Cost Shares", true, false, Item);

        // Verify: Verify Values on Rolled-up Cost Shares Test report values.
        VerifyRolledupCostSharesReport(FirstChildItem."No.", ParentItem."Production BOM No.");
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledUpCostSharesWithTypeProdBomAndVersion()
    var
        Item: Record Item;
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeaderNo: Code[20];
    begin
        // Verify Rolled-up Cost Shares Test Report values when Production Bom Line created with Type Production BOM and Certified version.

        // Setup: Create Item with New BOM with certified Production BOM Version.
        Initialize();
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order", '', LibraryRandom.RandDec(10, 2));
        CreateItemWithReplSysAndCostingMethod(SecondChildItem, SecondChildItem."Costing Method"::FIFO,
          SecondChildItem."Replenishment System"::"Prod. Order", CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(Item)), 0);
        ProductionBOMHeaderNo := CreateProductionBOMWithLines(FirstChildItem,
            ProductionBOMLine.Type::"Production BOM", SecondChildItem."Production BOM No.");
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeaderNo, 0);
        CreateProductionBOMVersionWithBOMLines(ProductionBOMHeaderNo, ParentItem."Production BOM No.",
          LibraryInventory.CreateItem(Item), SecondChildItem."No.", ProductionBOMVersion.Status::Certified);

        // Exercise: Run Rolled-up Cost Shares Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Rolled-up Cost Shares", true, false, Item);

        // Verify: Verify Values on Rolled-up Cost Shares Test report values.
        VerifyRolledupCostSharesReport(SecondChildItem."No.", ParentItem."Production BOM No.");
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithTypeItemAndVersion()
    var
        Item: Record Item;
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeaderNo: Code[20];
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO] Verify Detailed Calculation Test Report values when Production Bom created with Type Item and Certified version.

        // Setup: Create Item with New BOM with certified Production BOM Version.
        Initialize();
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order", '', LibraryRandom.RandDec(10, 2));
        CreateItemWithReplSysAndCostingMethod(SecondChildItem, SecondChildItem."Costing Method"::FIFO,
          SecondChildItem."Replenishment System"::"Prod. Order", CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(Item)), 0);
        ProductionBOMHeaderNo := CreateProductionBOMWithLines(SecondChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(Item));
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeaderNo, 0);
        CreateProductionBOMVersionWithBOMLines(ProductionBOMHeaderNo, ParentItem."Production BOM No.",
          LibraryInventory.CreateItem(Item), FirstChildItem."No.", ProductionBOMVersion.Status::Certified);
        LibraryVariableStorage.Enqueue(WorkDate());

        // Exercise: Run Detailed Calculation Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Detailed Calculation", true, false, Item);

        // Verify: Verify Values on Detailed Calculation Test report values.
        VerifyDetailedCalculationReport(FirstChildItem."No.", ParentItem."Production BOM No.");
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithTypeProdBomAndVersion()
    var
        Item: Record Item;
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeaderNo: Code[20];
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO] Verify Detailed Calculation Test Report values when Production Bom created with Type Production Bom and Certified version.

        // Setup: Create Item with New BOM with certified Production BOM Version.
        Initialize();
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order", '', LibraryRandom.RandDec(10, 2));
        CreateItemWithReplSysAndCostingMethod(SecondChildItem, SecondChildItem."Costing Method"::FIFO,
          SecondChildItem."Replenishment System"::"Prod. Order", CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item,
            LibraryInventory.CreateItem(Item)), 0);
        ProductionBOMHeaderNo := CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::"Production BOM",
            SecondChildItem."Production BOM No.");
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeaderNo, 0);
        CreateProductionBOMVersionWithBOMLines(ProductionBOMHeaderNo, ParentItem."Production BOM No.",
          LibraryInventory.CreateItem(Item), SecondChildItem."No.", ProductionBOMVersion.Status::Certified);
        LibraryVariableStorage.Enqueue(WorkDate());

        // Exercise: Run Detailed Calculation Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Detailed Calculation", true, false, Item);

        // Verify: Verify Values on Detailed Calculation Test report values.
        VerifyDetailedCalculationReport(SecondChildItem."No.", ParentItem."Production BOM No.");
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithStatusCertifiedAndGreaterThanWorkDate()
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        StartingDate: Date;
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO] Verify Detailed Calculation Test Report values when Routing created with certified version and report run for greater than Routing Version Starting Date.

        // Setup: Create Item with Routing Version and delete one routing line from Routing version after copy Routing version.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::New, RoutingHeader.Status::"Under Development");
        CreateRoutingLineWithTypeMachineCenter(RoutingHeader, Item."Routing No.");
        CreateRoutingVersion(RoutingVersion, Item."Routing No.");
        StartingDate := CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate());
        FindRoutingLine(RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code");
        RoutingLine.Delete(true);
        UpdateRoutingVersion(RoutingVersion, RoutingVersion.Status::Certified, StartingDate);
        LibraryVariableStorage.Enqueue(CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), StartingDate));

        // Exercise: Run Detailed Calculation Report greater than Routing version starting date.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Detailed Calculation", true, false, Item);

        // Verify: Verify values on Detailed Calculation Test report values.
        FindRoutingLine(RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code");
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('RtngVersionCode', RoutingVersion."Version Code");
        if LibraryReportDataset.GetNextRow() then
            LibraryReportDataset.AssertCurrentRowValueEquals('OperationNo_RtngLine', RoutingLine."Operation No.")
        else
            Error(RoutingLineNotExistErr, RoutingLine."Operation No.");
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithStatusCertifiedAndLessThanWorkDate()
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO] Verify Detailed Calculation Test Report values when Routing created with certified version and report run for less than Routing Version Starting Date.
        Initialize();
        DetailedCalculationWithTypeRoutingVersionAndCalcDate(Enum::"Routing Status"::Certified, -LibraryRandom.RandInt(5));
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithStatusClosedAndGreaterThanWorkDate()
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO] Verify Detailed Calculation Test Report values when Routing created with closed version and report run for greater than Routing Version Starting Date.
        Initialize();
        DetailedCalculationWithTypeRoutingVersionAndCalcDate(Enum::"Routing Status"::Closed, LibraryRandom.RandInt(5));
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithStatusClosedAndLessThanWorkDate()
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO] Verify Detailed Calculation Test Report values when Routing created with closed version and report run for less than Routing Version Starting Date.
        Initialize();
        DetailedCalculationWithTypeRoutingVersionAndCalcDate(Enum::"Routing Status"::Closed, -LibraryRandom.RandInt(5));
    end;

    [Test]
    [HandlerFunctions('DetailedCalculationRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DetailedCalculationWithProdBOMBelowItemLines()
    var
        Item: Record Item;
        ChildItem: Record Item;
        BOMItem: Record Item;
        BOMChildItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMLineChild: Record "Production BOM Line";
        ChildBOMQty: Integer;
    begin
        // [FEATURE] [Detailed Calculation]
        // [SCENARIO 351249] Run Detailed Calculation Report Production BOM with Prod. BOM Line below the Item line
        Initialize();

        // [GIVEN] Child Production BOM "ChildBOM" having item "BOMChildItem" of Unit Cost = 7, Qty = 5
        CreateItemsWithIndirectCost(BOMItem, BOMChildItem);
        ProductionBOMLineChild.SetRange("No.", BOMChildItem."No.");
        ProductionBOMLineChild.FindFirst();

        // [GIVEN] Item "ParentItem" with Production BOM "ParentBOM" having Item "ChildItem" of Unit Cost = 10, Qty = 3
        CreateItemsWithIndirectCost(Item, ChildItem);

        // [GIVEN] "ChildBOM" is added to "ParentBOM" with Qty = 2
        ProductionBOMLine.SetRange("No.", ChildItem."No.");
        ProductionBOMLine.FindFirst();
        ProductionBOMHeader.Get(ProductionBOMLine."Production BOM No.");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);
        ChildBOMQty := LibraryRandom.RandIntInRange(5, 10);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '',
          ProductionBOMLine.Type::"Production BOM", ProductionBOMLineChild."Production BOM No.", ChildBOMQty);

        LibraryVariableStorage.Enqueue(WorkDate());

        // [WHEN] Run Detailed Calculation Report for the "ParentItem"
        Commit();
        Item.SetRecFilter();
        REPORT.Run(REPORT::"Detailed Calculation", true, false, Item);

        ProductionBOMLine.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.GetNextRow();

        // [THEN] Line for "ChildItem" is exported with 'CostTotal' = 30 (10 * 3)
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CostTotal', ChildItem."Unit Cost" * ProductionBOMLine.Quantity);
        // [THEN] Line for "ChildBOM" is exported with 'CostTotal' = 0
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('CostTotal', 0);
        // [THEN] Line for "BOMChildItem" is exported with 'CostTotal' = 70 (7 * 5 * 2)
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(
          'CostTotal', BOMChildItem."Unit Cost" * ProductionBOMLineChild.Quantity * ChildBOMQty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler,QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMWithStatusClosed()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        Item: Record Item;
    begin
        // Verify Quantity Explosion of BOM Test Report values when Production BOM is closed wihout any Error message.

        // Setup: Create Item with New Production BOM.
        Initialize();
        LibraryInventory.CreateItem(ChildItem);
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order",
          CreateProductionBOM(ChildItem."Base Unit of Measure", Enum::"BOM Status"::Closed), 0);

        // Exercise: Run Quantity Explosion of BOM Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Quantity Explosion of BOM", true, false, Item);

        // Verify: Verify no error message appear after running Quantity Explosion of BOM.
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_Item', ParentItem."No.");
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMWithProdBomLineTypeItem()
    var
        Item: Record Item;
    begin
        // Verify Error message when Quantity Explosion of Bom report is run for Production Bom Line Type Item.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Average, Enum::"BOM Status"::Certified, Enum::"Routing Status"::Certified);
        VerifyProductionBomErrorForTheReport(Item, Enum::"Production BOM Line Type"::Item,
          Item."No.", Item."Production BOM No.", REPORT::"Quantity Explosion of BOM");
    end;

    [Test]
    [HandlerFunctions('QuantityExplosionOfBOMRequestPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMWithProdBomLineTypeProdBom()
    var
        Item: Record Item;
    begin
        // Verify Error message when Quantity Explosion of Bom report is run for Production Bom Line Type Production Bom.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Average, Enum::"BOM Status"::Certified, Enum::"Routing Status"::Certified);
        VerifyProductionBomErrorForTheReport(Item, Enum::"Production BOM Line Type"::"Production BOM",
          Item."Production BOM No.", Item."Production BOM No.", REPORT::"Quantity Explosion of BOM");
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledupCostSharesWithProdBomLineTypeItem()
    var
        Item: Record Item;
    begin
        // Verify Error message when Rolled-up Cost Shares report is run for Production Bom Line Type Item.
        Initialize();
        CreateManufacturingItem(
          Item, Item."Costing Method"::Average, Enum::"BOM Status"::Certified, Enum::"Routing Status"::Certified);
        VerifyProductionBomErrorForTheReport(
            Item, Enum::"Production BOM Line Type"::Item, Item."No.", Item."Production BOM No.", Report::"Rolled-up Cost Shares");
    end;

    [Test]
    [HandlerFunctions('RolledUpCostSharesRequestPageHandler')]
    [Scope('OnPrem')]
    procedure RolledupCostSharesWithProdBomLineTypeProdBom()
    var
        Item: Record Item;
    begin
        // Verify Error message when Rolled-up Cost Shares report is run for Production Bom Line Type Production Bom.
        Initialize();

        CreateManufacturingItem(
          Item, Item."Costing Method"::Average, Enum::"BOM Status"::Certified, Enum::"Routing Status"::Certified);

        VerifyProductionBomErrorForTheReport(
            Item, Enum::"Production BOM Line Type"::"Production BOM", Item."Production BOM No.", Item."Production BOM No.",
            Report::"Rolled-up Cost Shares");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure WhereUsedFromBomErrorOnProductionBomWithCycle()
    var
        UnitOfMeasure: Record "Unit of Measure";
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        WhereUsedMgt: Codeunit "Where-Used Management";
        CircularRefErr: Label 'The production BOM %1 has a circular reference', Comment = '%1 - Production BOM No.';
    begin
        // [FEATURE] [Production BOM] [Where-Used]
        // [SCENARIO] Error message when the where-used list is run for a production BOM with circular reference

        Initialize();

        // [GIVEN] Production BOM "BOM1"
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ProdBOMHeader.Get(CreateProductionBOM(UnitOfMeasure.Code, Enum::"BOM Status"::"Under Development", 1));

        // [GIVEN] Create a BOM line adding "BOM1" as a component of itself
        LibraryManufacturing.CreateProductionBOMLine(
            ProdBOMHeader, ProdBOMLine, '', Enum::"Production BOM Line Type"::"Production BOM", ProdBOMHeader."No.", 1);

        // [WHEN] Run Where-Used for "BOM1"
        asserterror WhereUsedMgt.WhereUsedFromProdBOM(ProdBOMHeader, WorkDate(), true);

        // [THEN] Error is thrown informing that the BOM conains a circular reference
        Assert.ExpectedError(StrSubstNo(CircularRefErr, ProdBOMHeader."No."));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdBomWhereUsedMultiLevelNoCycle()
    var
        ProdBOMHeader: array[4] of Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        Item: Record Item;
        TempWhereUsedLine: Record "Where-Used Line" temporary;
        WhereUsedMgt: Codeunit "Where-Used Management";
        QtyPer: array[4] of Decimal;
        I: Integer;
    begin
        // [FEATURE] [Production BOM] [Where-Used]
        // [SCENARIO] Where-used list for a child BOM with multiple occurrences within the top-level BOM structure

        Initialize();

        // [GIVEN] Bom1 is the-top level production BOM which includes components Bom2 (Qty = Q3) and Bom3 (Qty = Q4)
        // [GIVEN] Bom2 includes components Bom3 (Qty = Q1) and Bom4 (Qty = Q2)
        LibraryInventory.CreateItem(Item);

        for I := 1 to ArrayLen(QtyPer) do
            QtyPer[I] := LibraryRandom.RandDecInRange(10, 20, 2);

        ProdBOMHeader[4].Get(CreateProductionBOM(Item."Base Unit of Measure", Enum::"BOM Status"::Certified));
        ProdBOMHeader[3].Get(CreateProductionBOM(Item."Base Unit of Measure", Enum::"BOM Status"::Certified));

        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader[2], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProdBOMHeader[2], ProdBOMLine, '', Enum::"Production BOM Line Type"::"Production BOM", ProdBOMHeader[3]."No.", QtyPer[1]);
        LibraryManufacturing.CreateProductionBOMLine(
            ProdBOMHeader[2], ProdBOMLine, '', Enum::"Production BOM Line Type"::"Production BOM", ProdBOMHeader[4]."No.", QtyPer[2]);

        LibraryManufacturing.CreateProductionBOMHeader(ProdBOMHeader[1], Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProdBOMHeader[1], ProdBOMLine, '', Enum::"Production BOM Line Type"::"Production BOM", ProdBOMHeader[2]."No.", QtyPer[3]);
        LibraryManufacturing.CreateProductionBOMLine(
            ProdBOMHeader[1], ProdBOMLine, '', Enum::"Production BOM Line Type"::"Production BOM", ProdBOMHeader[3]."No.", QtyPer[4]);

        Item.Validate("Production BOM No.", ProdBOMHeader[1]."No.");
        Item.Modify(true);

        // [WHEN] Run Where-Used list for BOM3
        WhereUsedMgt.WhereUsedFromProdBOM(ProdBOMHeader[3], WorkDate(), true);

        // [THEN] The list includes 2 lines, quantity in line 1 is Q1 * Q3, quantity in line 2 is Q4
        WhereUsedMgt.FindRecord('-', TempWhereUsedLine);
        Assert.AreEqual(Item."No.", TempWhereUsedLine."Item No.", 'Unexpected Item No. in the Where-Used list.');
        Assert.AreEqual(QtyPer[1] * QtyPer[3], TempWhereUsedLine."Quantity Needed", 'Unexpected quantity in the Where-Used list.');

        WhereUsedMgt.NextRecord(1, TempWhereUsedLine);
        Assert.AreEqual(Item."No.", TempWhereUsedLine."Item No.", 'Unexpected Item No. in the Where-Used list.');
        Assert.AreEqual(QtyPer[4], TempWhereUsedLine."Quantity Needed", 'Unexpected quantity in the Where-Used list.');
    end;

    [Test]
    [HandlerFunctions('MessageHandler,CalculateStdCostMenuHandler,ProdJournalPageHandler,AdjustCostRequestPageHandler,ConfirmHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportForCostPostedtoGLOnStartingPeriod()
    begin
        // Verify Inv. Valu. WIP Test Report values for starting period when Output is made to Expected cost in period First and Output invoiced in period Third.
        Initialize();
        // The error "Posting Date is not within your range of allowed posting dates." occur in CZ
        asserterror InvValuationWIPReportForCostPostedtoGL(
          WorkDate(), CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandIntInRange(3, 5)), WorkDate()));
    end;

    [Test]
    [HandlerFunctions('CalculateStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure InvValuationWIPReportForForCostPostedtoGLOnEndingPeriod()
    var
        InventoryValuationWIPDate: Date;
    begin
        // Verify Inv. Valu. WIP Test Report values for ending period when Output is made to Expected cost in period First and Output invoiced in period Third.
        Initialize();
        // The error "Posting Date is not within your range of allowed posting dates." occur in CZ
        InventoryValuationWIPDate := CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandIntInRange(3, 5)), WorkDate());
        asserterror InvValuationWIPReportForCostPostedtoGL(InventoryValuationWIPDate, InventoryValuationWIPDate);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionQtyRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckItemAgeCompositionQtyWithYear()
    var
        ItemNo: Code[20];
        PeriodLength: DateFormula;
    begin
        // Verify that Item Age Composition - Qty. report running successfully with year value.

        // Setup: Craete Item and evaluate date formula.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        Evaluate(PeriodLength, StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));

        // Exercise: Run Item Age Composition - Qty Report.
        Commit();
        RunItemAgeCompositionQuantityReport(ItemNo, PeriodLength, '');

        // Verify: Verifying that report running successfully with year value and Item no on report.
        VerifyItemNoOnItemAgeCompositionReport(ItemNo);
    end;

    [Test]
    [HandlerFunctions('ItemAgeCompositionValueRequestPageHandler')]
    [Scope('OnPrem')]
    procedure CheckItemAgeCompositionValueWithYear()
    var
        ItemNo: Code[20];
        PeriodLength: DateFormula;
    begin
        // Verify that Item Age Composition - Value report running successfully with year value.

        // Setup: Craete Item and evaluate date formula.
        Initialize();
        ItemNo := LibraryInventory.CreateItemNo();
        Evaluate(PeriodLength, StrSubstNo('<%1Y>', LibraryRandom.RandInt(5)));

        // Exercise: Run Item Age Composition - Value Report.
        Commit();
        RunItemAgeCompositionValueReport(ItemNo, PeriodLength);

        // Verify: Verifying that report running successfully with year value and Item no on report.
        VerifyItemNoOnItemAgeCompositionReport(ItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VerifyPickInstructionOptionForReportSelectionSales()
    var
        ReportSelections: Record "Report Selections";
        UsageOptionForPage: Option Quote,"Blanket Order","Order",Invoice,"Work Order","Return Order","Credit Memo",Shipment,"Return Receipt","Sales Document - Test","Prepayment Document - Test","S.Arch. Quote","S.Arch. Order","S. Arch. Return Order","Pick Instruction";
    begin
        // Test to check that Pick Instruction option is present and working on page report Selection - Sales.

        VerifySelectedOptionForReportSelectionSales(
          UsageOptionForPage::"Pick Instruction",
          ReportSelections.Usage::"S.Order Pick Instruction",
          REPORT::"Pick Instruction");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRoutingVersionAfterUpdateStatus()
    var
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        RoutingNo: Code[20];
    begin
        // Test Routing version can be deleted after update Status without reopen the routing version page.

        // Setup: Create Item with Under Development BOM and Routing. Create a Routing Version.
        Initialize();
        RoutingNo := CreateRouting(RoutingHeader.Status::"Under Development");
        CreateRoutingVersion(RoutingVersion, RoutingNo);
        UpdateRoutingVersion(RoutingVersion, RoutingVersion.Status::Certified, WorkDate());

        // Exercise: Update Status and delete Routing Version.
        RoutingVersion.Validate(Status, RoutingVersion.Status::New);
        RoutingVersion.Delete(true);

        // Verify: Routing Version is deleted without error pops up.
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        Assert.IsTrue(RoutingVersion.IsEmpty, StrSubstNo(MustBeEmptyErr, RoutingVersion.TableName, RoutingNo));
    end;

    [Test]
    [HandlerFunctions('AssemblyBOMsRequestPageHandler')]
    [Scope('OnPrem')]
    procedure AssemblyBOMsReportForAssemledComponent()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Assembly] [Assembly BOM]
        // [SCENARIO] Field "BOM" in report 801 "Assembly BOMs" is set to "Yes" if a component is an assembled item

        // [GIVEN] Create item "I1"
        LibraryAssembly.CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Assembly, '', '');
        // [GIVEN] Create assembly BOM with 1 component "COMP" and assign to item "I1"
        LibraryAssembly.CreateAssemblyList(ComponentItem."Costing Method"::Standard, ComponentItem."No.", true, 1, 0, 0, 1, '', '');

        BOMComponent.SetRange("Parent Item No.", ComponentItem."No.");
        BOMComponent.FindFirst();

        // [GIVEN] Create item "I2", create assembly BOM component. Set "I1" as component of "I2"
        LibraryAssembly.CreateItem(
          ParentItem, ComponentItem."Costing Method"::Standard, ParentItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '', 0, 1, true);
        // [GIVEN] Create assembly BOM component and set item "COMP" as a component of "I2"
        // [GIVEN] Assembly setup: "I1" is assembled from "COMP", "I2" is assembled from "I1" + "COMP"
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, BOMComponent."No.", ParentItem."No.", '', 0, 1, true);

        // [WHEN] Run report 801 "Assembly BOMs" for item "I2"
        ParentItem.SetRecFilter();
        REPORT.Run(REPORT::"Assembly BOMs", true, false, ParentItem);

        // [THEN] Field "BOM" in the report line corresponding to item "I1" is "Yes", "BOM" in the line corresponding to "COMP" is "No"
        LibraryReportDataset.LoadDataSetFile();
        VerifyAssemblyBOMComponent(ParentItem."No.", ComponentItem."No.", true);
        VerifyAssemblyBOMComponent(ParentItem."No.", BOMComponent."No.", false);
    end;

    [Test]
    [HandlerFunctions('AdjustCostRequestFilterItemNoPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesItemFilterExceedItemNo()
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
        ItemFilterText: text[250];
    begin
        // [SCENARIO 404541] User can enter filter text > 20 symbols on 'Item No. Filter' with no error on "Adjust Cost - Item Entries" report
        Initialize();

        // [GIVEN] Item 'GL00000000' and "GL00000001"
        // [GIVEN] "Adjust Cost - Item Entries" report request page is opened
        ItemFilterText := LibraryInventory.CreateItemNo() + '..' + LibraryInventory.CreateItemNo();
        LibraryVariableStorage.Enqueue(ItemFilterText);
        Clear(AdjustCostItemEntries);
        Commit();
        AdjustCostItemEntries.UseRequestPage(true);

        // [WHEN] "Item No. Filter" is populated with value 'GL00000000..GL00000001'
        AdjustCostItemEntries.RunModal();

        // [THEN] No error is shown and "Item No. Filter" value is 'GL00000000..GL00000001'
        Assert.AreEqual(ItemFilterText, LibraryVariableStorage.DequeueText(), ItemFilterText);
    end;

    [Test]
    [HandlerFunctions('AdjustCostRequestFilterItemNoLookUpPageHandler,ItemListModalPageHandler')]
    [Scope('OnPrem')]
    procedure AdjustCostItemEntriesItemFilterLookUpItemNo()
    var
        AdjustCostItemEntries: Report "Adjust Cost - Item Entries";
        ItemNo: code[20];
    begin
        // [SCENARIO 404541] User can lookup at "Item No. Filter" and select Item on "Adjust Cost - Item Entries" report
        Initialize();

        // [GIVEN] Item "GL00000000"
        ItemNo := LibraryInventory.CreateItemNo();
        LibraryVariableStorage.Enqueue(ItemNo);

        // [GIVEN] "Adjust Cost - Item Entries" report request page is opened
        Clear(AdjustCostItemEntries);
        Commit();
        AdjustCostItemEntries.UseRequestPage(true);

        // [WHEN] Lookup on "Item No. Filter" and selected Item "GL00000000"
        AdjustCostItemEntries.RunModal();

        // [THEN] "Item No. Filter" value is 'GL00000000'
        Assert.AreEqual(ItemNo, LibraryVariableStorage.DequeueText(), '');
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Reports");
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Reports");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateInventoryPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Reports");
    end;

    local procedure AddParentItemAsBOMComponent(Type: Enum "Production BOM Line Type"; No: Code[20]; ItemProductionBOMNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(ItemProductionBOMNo);
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Modify(true);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', Type, No, LibraryRandom.RandDec(100, 2));
    end;

    local procedure CalculateExpectedValue(ProductionBOMNo: Code[20]; ComponentNo: Code[20]): Decimal
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange("No.", ComponentNo);
        if ProductionBOMLine.FindFirst() then begin
            Item.Get(ComponentNo);
            exit(Round(Item."Unit Cost" * ProductionBOMLine.Quantity));
        end;
    end;

    local procedure CreateAndModifyUserSetup(var UserSetup: Record "User Setup")
    var
        LibraryTimeSheet: Codeunit "Library - Time Sheet";
    begin
        LibraryTimeSheet.CreateUserSetup(UserSetup, true);
        UserSetup.Validate("Allow Posting From", WorkDate());
        UserSetup.Validate("Allow Posting To", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));  // Adding Random months to WORKDATE.
        UserSetup.Modify(true);
    end;

    local procedure CreateAndPostItemJournal(ItemNo: Code[20]; RandomDays: Integer; LocationCode: Code[10]): Code[10]
    var
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        CreateItemJournalLine(ItemJournalBatch, ItemJournalLine, ItemNo);
        ItemJournalLine.Validate("Posting Date", CalcDate('<' + Format(-RandomDays) + 'D>', WorkDate()));
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        exit(ItemJournalLine."Journal Batch Name");
    end;

    local procedure CreateAndPostPurchaseOrderWithItemCharge(var PurchaseLine: Record "Purchase Line")
    var
        Vendor: Record Vendor;
        PurchaseHeader: Record "Purchase Header";
        Item: Record Item;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, Vendor."No.");
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(100)); // Use Random Quantity.
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::"Charge (Item)",
          LibraryInventory.CreateItemChargeNo(), PurchaseLine.Quantity);
        PurchaseLine.ShowItemChargeAssgnt();
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostSalesOrderWithItemCharge(var SalesLine: Record "Sales Line")
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(100, 2)); // Use Random Quantity.
        CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::"Charge (Item)", LibraryInventory.CreateItemChargeNo(), SalesLine.Quantity);
        SalesLine.ShowItemChargeAssgnt();
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
    end;

    local procedure CreateAndPostWarehouseReceipt(PurchaseHeader: Record "Purchase Header")
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
    begin
        LibraryWarehouse.CreateWhseReceiptFromPO(PurchaseHeader);
        FindWarehouseReceiptLine(WarehouseReceiptLine, WarehouseReceiptLine."Source Document"::"Purchase Order", PurchaseHeader."No.");
        WarehouseReceiptHeader.Get(WarehouseReceiptLine."No.");
        LibraryWarehouse.PostWhseReceipt(WarehouseReceiptHeader);
    end;

    local procedure CreateAndPostPurchaseOrder(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader);
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(50, 100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndPostProductionJournal(ItemNo: Code[20]): Code[20]
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionJournalMgt: Codeunit "Production Journal Mgt";
    begin
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ItemNo, LibraryRandom.RandInt(5));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        LibraryVariableStorage.Enqueue(ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProductionJournalMgt.Handling(ProductionOrder, ProdOrderLine."Line No.");
        exit(ProductionOrder."No.");
    end;

    local procedure CreateAndPostPurchaseOrderWithDirectUnitCost(ItemNo: Code[20])
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        CreatePurchaseHeader(PurchaseHeader);
        CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, LibraryRandom.RandDecInRange(50, 100, 2));
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndRefreshProductionOrder(): Code[20]
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        ProductionOrder: Record "Production Order";
    begin
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::Certified, RoutingHeader.Status::Certified);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, false);
        exit(ProductionOrder."No.");
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; LocationCode: Code[10])
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(
          PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, LibraryInventory.CreateItemNo(), LibraryRandom.RandDec(100, 2));  // Use random Qunatity.
        PurchaseLine.Validate("Location Code", LocationCode);
        PurchaseLine.Modify(true);
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndReleaseSalesOrder(var SalesHeader: Record "Sales Header"; PurchaseLine: Record "Purchase Line")
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, PurchaseLine."No.", PurchaseLine.Quantity);
        SalesLine.Validate("Location Code", PurchaseLine."Location Code");
        SalesLine.Modify(true);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure CreateAndReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; SalesHeader: Record "Sales Header")
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryWarehouse.CreateWhseShipmentFromSO(SalesHeader);
        FindWarehouseShipmentLine(WarehouseShipmentLine, WarehouseShipmentLine."Source Document"::"Sales Order", SalesHeader."No.");
        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
        LibraryWarehouse.ReleaseWarehouseShipment(WarehouseShipmentHeader);
    end;

    local procedure CreateBinCreationWorksheetLine(var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    var
        Bin: Record Bin;
        BinCreationWkshName: Record "Bin Creation Wksh. Name";
        Item: Record Item;
        Location: Record Location;
    begin
        CreateFullWarehouseSetup(Location);
        FindBin(Bin, Location.Code);
        LibraryInventory.CreateItem(Item);
        BinCreationWkshName.FindFirst();
        LibraryWarehouse.CreateBinCreationWorksheetLine(
          BinCreationWorksheetLine, BinCreationWkshName."Worksheet Template Name", BinCreationWkshName.Name, Location.Code, Bin.Code);
        BinCreationWorksheetLine.Validate("Item No.", Item."No.");
        BinCreationWorksheetLine.Validate(Fixed, true);
        BinCreationWorksheetLine.Modify(true);
    end;

    local procedure CreateRevaluationJournal(var ItemJournalLine: Record "Item Journal Line")
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Revaluation);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
        LibraryInventory.CreateItemJnlLineWithNoItem(
          ItemJournalLine, ItemJournalBatch, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.");
    end;

    local procedure CreateBlockedItem(): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate(Blocked, true);
        Item.Modify(true);
        exit(Item."No.");
    end;

    local procedure CreateFullWarehouseSetup(var Location: Record Location)
    var
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        WarehouseEmployee.SetRange("User ID", UserId);
        WarehouseEmployee.DeleteAll(true);
        LibraryWarehouse.CreateFullWMSLocation(Location, 2);  // Value used for number of bin per zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
    end;

    local procedure CreateItemJournalLine(var ItemJournalBatch: Record "Item Journal Batch"; var ItemJournalLine: Record "Item Journal Line"; ItemNo: Code[20])
    begin
        // Create Item Journal line taking Random Quantity and Unit Cost.
        SelectItemJournalBatch(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name,
          ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDecInRange(10, 20, 2));
        ItemJournalLine.Validate("Unit Cost", LibraryRandom.RandDecInRange(100, 200, 2));
        ItemJournalLine.Modify(true);
    end;

    local procedure CreateItemsWithIndirectCost(var ParentItem: Record Item; var ChildItem: Record Item)
    begin
        CreateItemsWithDifferentReplenishmentSystems(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2));
        ParentItem.Validate("Indirect Cost %", LibraryRandom.RandInt(5));
        ParentItem.Modify(true);
    end;

    local procedure CreateItemWithReplSysAndCostingMethod(var Item: Record Item; CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; ProductionBOMNo: Code[20]; UnitCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Validate("Unit Cost", UnitCost);
        Item.Modify(true);
    end;

    local procedure CreateManufacturingItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; ProductionBOMHeaderStatus: Enum "BOM Status"; RoutingHeaderStatus: Enum "Routing Status")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", CreateProductionBOM(Item."Base Unit of Measure", ProductionBOMHeaderStatus));
        Item.Validate("Routing No.", CreateRouting(RoutingHeaderStatus));
        Item.Modify(true);
    end;

    local procedure CreateProductionBOM(UnitOfMeasureCode: Code[10]; Status: Enum "BOM Status"; QtyPer: Decimal): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasureCode);
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QtyPer);
        ProductionBOMHeader.Validate(Status, Status);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionBOM(UnitOfMeasureCode: Code[10]; Status: Enum "BOM Status"): Code[20]
    begin
        exit(CreateProductionBOM(UnitOfMeasureCode, Status, LibraryRandom.RandDec(100, 2)));
    end;

    local procedure CreateProductionBOMVersion(ProductionBOMNo: Code[20])
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMCopy: Codeunit "Production BOM-Copy";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ProductionBOMNo, Format(LibraryRandom.RandInt(5)), ProductionBOMHeader."Unit of Measure Code");  // Use Random Version Code.
        ProductionBOMCopy.CopyBOM(ProductionBOMHeader."No.", '', ProductionBOMHeader, ProductionBOMVersion."Version Code");
    end;

    local procedure CreatePurchaseLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; Type: Enum "Purchase Line Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, Type, ItemNo, Quantity);
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandInt(100));  // Value not Important for test.
        PurchaseLine.Modify(true);
    end;

    local procedure CreateRouting(Status: Enum "Routing Status"): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateWorkCenterWithWorkCenterGroup(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingHeader.Validate(Status, Status);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateRoutingVersion(var RoutingVersion: Record "Routing Version"; RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLineCopyLines: Codeunit "Routing Line-Copy Lines";
    begin
        RoutingHeader.Get(RoutingNo);
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingNo, Format(LibraryRandom.RandInt(5)));  // Use Random Version Code.
        RoutingLineCopyLines.CopyRouting(RoutingNo, '', RoutingHeader, RoutingVersion."Version Code");
    end;

    local procedure CreateRoutingLineWithTypeMachineCenter(var RoutingHeader: Record "Routing Header"; ItemRoutingNo: Code[20])
    var
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
    begin
        RoutingHeader.Get(ItemRoutingNo);
        CreateWorkCenterWithWorkCenterGroup(WorkCenter);
        LibraryManufacturing.CreateMachineCenter(MachineCenter, WorkCenter."No.", LibraryRandom.RandInt(5));
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)),
          RoutingLine.Type::"Machine Center", MachineCenter."No.");
    end;

    local procedure CreateSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; Type: Enum "Sales Line Type"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, Type, ItemNo, Quantity);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2)); // Use random Unit Price.
        SalesLine.Modify(true);
    end;

    local procedure CreateWarehouseItemJournalLine(LocationCode: Code[10]; ItemNo: Code[20]; RegisteringDate: Date)
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        CreateWarehouseJournalBatch(WarehouseJournalBatch, LocationCode);
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalBatch."Journal Template Name", WarehouseJournalBatch.Name, LocationCode, '', '',
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo,
          LibraryRandom.RandDec(10, 2));  // Taking Random Quantity.
        WarehouseJournalLine.Validate("Registering Date", RegisteringDate);
        WarehouseJournalLine.Modify(true);
    end;

    local procedure CreateWarehouseJournalBatch(var WarehouseJournalBatch: Record "Warehouse Journal Batch"; LocationCode: Code[10])
    var
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, LocationCode);
    end;

    local procedure CreateWorkCenterWithWorkCenterGroup(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
    end;

    local procedure CreateItemsWithDifferentReplenishmentSystems(var ParentItem: Record Item; var ChildItem: Record Item; QuantityPer: Decimal)
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        CreateItemWithReplSysAndCostingMethod(ChildItem, ChildItem."Costing Method"::FIFO,
          ChildItem."Replenishment System"::Purchase, '', LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ChildItem."No.", QuantityPer);
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::Standard,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeader."No.", 0);
    end;

    local procedure CreateProductionBOMWithLines(var FirstChildItem: Record Item; Type: Enum "Production BOM Line Type"; No: Code[20]): Code[20]
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, FirstChildItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          FirstChildItem."No.", LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', Type,
          No, LibraryRandom.RandDec(10, 2));
        exit(ProductionBOMHeader."No.");
    end;

    local procedure CreateProductionBOMVersionWithBOMLines(ProductionBOMNo: Code[20]; ItemProductionBOMNo: Code[20]; FirstChildItemNo: Code[20]; SecondChildItemNo: Code[20]; Status: Enum "BOM Status")
    var
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMHeader.Get(ProductionBOMNo);
        LibraryManufacturing.CreateProductionBOMVersion(
          ProductionBOMVersion, ItemProductionBOMNo, Format(LibraryRandom.RandInt(5)),
          ProductionBOMHeader."Unit of Measure Code");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code",
          ProductionBOMLine.Type::Item, FirstChildItemNo, LibraryRandom.RandDec(10, 2));
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, ProductionBOMVersion."Version Code",
          ProductionBOMLine.Type::Item, SecondChildItemNo, LibraryRandom.RandDec(10, 2));
        ProductionBOMVersion.Validate(Status, Status);
        ProductionBOMVersion.Modify(true);
    end;

    local procedure CreatePurchaseHeader(var PurchaseHeader: Record "Purchase Header")
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
    end;

    local procedure DetailedCalculationWithTypeRoutingVersionAndCalcDate(Status: Enum "Routing Status"; Days: Integer)
    var
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
    begin
        // Setup: Create Item with Routing Version and delete one routing line from Routing version after copy routing version.
        CreateManufacturingItem(
          Item, Item."Costing Method"::Standard, ProductionBOMHeader.Status::"Under Development",
          RoutingHeader.Status::"Under Development");
        CreateRoutingLineWithTypeMachineCenter(RoutingHeader, Item."Routing No.");
        CreateRoutingVersion(RoutingVersion, Item."Routing No.");
        FindRoutingLine(RoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code");
        RoutingLine.Delete(true);
        UpdateRoutingVersion(RoutingVersion, Status, CalcDate(StrSubstNo('<%1D>', LibraryRandom.RandInt(5)), WorkDate()));
        LibraryVariableStorage.Enqueue(CalcDate(StrSubstNo('<%1D>', Days), RoutingVersion."Starting Date"));

        // Exercise: Run Detailed Calculation Report.
        Commit();
        Item.SetRange("No.", Item."No.");
        REPORT.Run(REPORT::"Detailed Calculation", true, false, Item);

        // Verify: Verify Values on Detailed Calculation Test report values.
        LibraryReportDataset.LoadDataSetFile();
        RoutingHeader.Get(Item."Routing No.");
        FindRoutingLine(RoutingLine, RoutingHeader."No.", RoutingHeader."Version Nos.");
        repeat
            LibraryReportDataset.AssertElementWithValueExists('OperationNo_RtngLine', RoutingLine."Operation No.");
        until RoutingLine.Next() = 0;
    end;

    local procedure CreateReportSelection(UsageOption: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelections: Record "Report Selections";
    begin
        ReportSelections.Init();
        ReportSelections.Usage := UsageOption;
        ReportSelections.Sequence :=
          LibraryUtility.GenerateRandomCode(ReportSelections.FieldNo(Sequence), DATABASE::"Report Selections");
        ReportSelections.Validate("Report ID", ReportID);
        ReportSelections.Insert();
    end;

    local procedure CreateRandNumberRepSelections(UsageOption: Enum "Report Selection Usage"; ReportID: Integer) Result: Integer
    var
        ReportSelections: Record "Report Selections";
        Counter: Integer;
    begin
        Result := LibraryRandom.RandIntInRange(1, 10);
        for Counter := 1 to Result do
            CreateReportSelection(UsageOption, ReportID);

        ReportSelections.SetRange(Usage, UsageOption);
        Result := ReportSelections.Count();
    end;

    local procedure CreateLocation(): Code[10]
    var
        Location: Record Location;
    begin
        exit(LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location));
    end;

    local procedure FindBin(var Bin: Record Bin; LocationCode: Code[10])
    var
        Zone: Record Zone;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.FindFirst();
        Bin.SetRange("Location Code", LocationCode);
        Bin.SetRange("Zone Code", Zone.Code);
        Bin.SetRange("Adjustment Bin", false);
        Bin.FindFirst();
    end;

    local procedure FindWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    begin
        WarehouseActivityLine.SetRange("Source No.", SourceNo);
        WarehouseActivityLine.SetRange("Activity Type", ActivityType);
        WarehouseActivityLine.FindFirst();
    end;

    local procedure FindWarehouseReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseReceiptLine.SetRange("Source Document", SourceDocument);
        WarehouseReceiptLine.SetRange("Source No.", SourceNo);
        WarehouseReceiptLine.FindFirst();
    end;

    local procedure FindWarehouseShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; SourceDocument: Enum "Warehouse Activity Source Document"; SourceNo: Code[20])
    begin
        WarehouseShipmentLine.SetRange("Source Document", SourceDocument);
        WarehouseShipmentLine.SetRange("Source No.", SourceNo);
        WarehouseShipmentLine.FindFirst();
    end;

    local procedure FindValueEntry(var ValueEntry: Record "Value Entry"; ItemNo: Code[20])
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::Output);
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::Revaluation);
        ValueEntry.FindFirst();
    end;

    local procedure FindRoutingLine(var RoutingLine: Record "Routing Line"; RoutingNo: Code[20]; VersionCode: Code[20])
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", VersionCode);
        RoutingLine.FindSet();
    end;

    local procedure GetComponent(ProductionBOMNo: Code[20]): Code[20]
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindFirst();
        exit(ProductionBOMLine."No.");
    end;

    local procedure GetCostAmountFromItemLedgerEntry(ItemNo: Code[20]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)");
        exit(ItemLedgerEntry."Cost Amount (Actual)");
    end;

    local procedure GetCostPostedtoGLFromValueEntry(var ValueEntry: Record "Value Entry"; DocumentNo: Code[20]; PostingDate: Date) CostPostedtoGL: Decimal
    begin
        ValueEntry.SetRange("Document No.", DocumentNo);
        ValueEntry.SetRange("Posting Date", PostingDate);
        ValueEntry.FindSet();
        repeat
            CostPostedtoGL += ValueEntry."Cost Amount (Expected)" + ValueEntry."Cost Posted to G/L";
        until ValueEntry.Next() = 0;
    end;

    local procedure GetQuantityFromItemLedgerEntry(ItemNo: Code[20]; LocationCode: Code[10]): Decimal
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
    begin
        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        if LocationCode <> '' then
            ItemLedgerEntry.SetRange("Location Code", LocationCode);
        ItemLedgerEntry.FindFirst();
        exit(ItemLedgerEntry.Quantity);
    end;

    local procedure InvValuationWIPReportForCostPostedtoGL(InventoryValuationWIPDate: Date; AllowPostingFromDate: Date)
    var
        InventorySetup: Record "Inventory Setup";
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ProductionOrderNo: Code[20];
        OldAllowPostingFrom: Date;
        CostPostedtoGL: Decimal;
    begin
        // Setup: Post Purchase Order,Production Journal and Run Adjust Cost item entries batch job.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Never,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        CreateItemsWithIndirectCost(ParentItem, ChildItem);
        CalculateStandardCost.CalcItem(ParentItem."No.", false);
        CreateAndPostPurchaseOrderWithDirectUnitCost(ChildItem."No.");
        ProductionOrderNo := CreateAndPostProductionJournal(ParentItem."No.");
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        OldAllowPostingFrom := UpdateGeneralLedgerSetup(AllowPostingFromDate);
        Commit();
        REPORT.Run(REPORT::"Adjust Cost - Item Entries");
        LibraryVariableStorage.Enqueue(InventoryValuationWIPDate);

        // Exercise: Run Inventory Valuation WIP Report.
        Commit();
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);

        // Verify: Verify Cost Posted to GL on Inventory Valuation WIP Test Report.
        CostPostedtoGL := GetCostPostedtoGLFromValueEntry(ValueEntry, ProductionOrderNo, InventoryValuationWIPDate);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ValueEntryCostPostedtoGL', -CostPostedtoGL);

        // Teardown.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        UpdateGeneralLedgerSetup(OldAllowPostingFrom);
    end;

    local procedure QuantityExplosionOfBOMWithVersions(ProdBOMVersionStatus: Enum "BOM Status")
    var
        ParentItem: Record Item;
        FirstChildItem: Record Item;
        SecondChildItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProductionBOMNo: Code[20];
    begin
        // Setup: Create Item with New BOM and Production BOM Versions.
        Initialize();
        CreateItemWithReplSysAndCostingMethod(FirstChildItem, FirstChildItem."Costing Method"::FIFO,
          FirstChildItem."Replenishment System"::"Prod. Order", '', LibraryRandom.RandDec(10, 2));
        ProductionBOMNo := CreateProductionBOMWithLines(FirstChildItem, ProductionBOMLine.Type::Item, LibraryInventory.CreateItem(Item));
        CreateItemWithReplSysAndCostingMethod(SecondChildItem, SecondChildItem."Costing Method"::FIFO,
          SecondChildItem."Replenishment System"::"Prod. Order", ProductionBOMNo, 0);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, SecondChildItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item,
          LibraryInventory.CreateItem(Item), LibraryRandom.RandDec(10, 2));
        CreateItemWithReplSysAndCostingMethod(ParentItem, ParentItem."Costing Method"::FIFO,
          ParentItem."Replenishment System"::"Prod. Order", ProductionBOMHeader."No.", 0);
        CreateProductionBOMVersionWithBOMLines(ProductionBOMHeader."No.", ParentItem."Production BOM No.",
          FirstChildItem."No.", SecondChildItem."No.", ProductionBOMVersion.Status::Certified);
        CreateProductionBOMVersionWithBOMLines(ProductionBOMNo, SecondChildItem."Production BOM No.",
          LibraryInventory.CreateItem(Item), FirstChildItem."No.", ProdBOMVersionStatus);

        // Exercise: Run Quantity Explosion of BOM Report.
        Commit();
        Item.SetRange("No.", ParentItem."No.");
        REPORT.Run(REPORT::"Quantity Explosion of BOM", true, false, Item);

        // Verify: Verify Values on Quantity Explosion of BOM Test report values.
        VerifyQuantityExplosionOfBOMReport(SecondChildItem."No.", ParentItem."Production BOM No.");
    end;

    local procedure RegisterWarehouseActivity(SourceNo: Code[20]; ActivityType: Enum "Warehouse Activity Type")
    var
        WarehouseActivityHeader: Record "Warehouse Activity Header";
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        FindWarehouseActivityLine(WarehouseActivityLine, SourceNo, ActivityType);
        WarehouseActivityHeader.Get(WarehouseActivityLine."Activity Type", WarehouseActivityLine."No.");
        LibraryWarehouse.RegisterWhseActivity(WarehouseActivityHeader);
    end;

    local procedure RevalueItemAutomatically(ItemNo: Code[20]; PostingDate: Date; UnitCost: Decimal)
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        LibraryCosting: Codeunit "Library - Costing";
    begin
        CreateRevaluationJournal(ItemJournalLine);
        Item.SetRange("No.", ItemNo);
        LibraryCosting.CalculateInventoryValue(
          ItemJournalLine, Item, PostingDate, ItemJournalLine."Document No.",
          "Inventory Value Calc. Per"::Item, false, false, true, "Inventory Value Calc. Base"::" ", false);
        UpdateRevaluedUnitCost(ItemJournalLine."Journal Template Name",
          ItemJournalLine."Journal Batch Name", ItemNo, ItemJournalLine."Unit Cost" + UnitCost);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
    end;

    local procedure InventoryValuationWIPReportWithFinishedRelProdOrder(UnitCostRevalued: Decimal; InventoryValuationWIPStartingDate: Date; RevalueThenFinish: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionOrder: Record "Production Order";
        ValueEntry: Record "Value Entry";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        ProductionOrderNo: Code[20];
    begin
        // Setup: Post Purchase Order,Production Journal and Revaluation Journal with modified Unit Cost(Revalued)
        // before finishing Released Prod. Order.
        Initialize();
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, true, true, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
        CreateItemsWithDifferentReplenishmentSystems(ParentItem, ChildItem, LibraryRandom.RandInt(5));
        CalculateStandardCost.CalcItem(ParentItem."No.", false);
        CreateAndPostPurchaseOrder(ChildItem."No.");
        ProductionOrderNo := CreateAndPostProductionJournal(ParentItem."No.");
        if RevalueThenFinish then begin
            RevalueItemAutomatically(ParentItem."No.",
              CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(2)), WorkDate()), UnitCostRevalued);
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
        end else begin
            LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrderNo);
            RevalueItemAutomatically(ParentItem."No.",
              CalcDate(StrSubstNo('<%1M>', LibraryRandom.RandInt(2)), WorkDate()), UnitCostRevalued);
        end;
        LibraryVariableStorage.Enqueue(InventoryValuationWIPStartingDate);

        // Exercise: Run Inventory Valuation WIP Report for the Workdate.
        ProductionOrder.SetRange("No.", ProductionOrderNo);
        REPORT.Run(REPORT::"Inventory Valuation - WIP", true, false, ProductionOrder);

        // Verify: Verify Values on Inventory Valuation WIP Test Report.
        FindValueEntry(ValueEntry, ParentItem."No.");
        VerifyInventoryValuationWIPReport(ValueEntry."Cost Amount (Expected)", InventoryValuationWIPStartingDate);

        // Teardown.
        LibraryInventory.UpdateInventorySetup(
          InventorySetup, false, false, InventorySetup."Automatic Cost Adjustment"::Always,
          InventorySetup."Average Cost Calc. Type"::Item, InventorySetup."Average Cost Period"::Day);
    end;

    local procedure RunBinContentCreateWorksheetReport(var BinCreationWorksheetLine: Record "Bin Creation Worksheet Line")
    begin
        BinCreationWorksheetLine.SetRange("Item No.", BinCreationWorksheetLine."Item No.");
        REPORT.Run(REPORT::"Bin Content Create Wksh Report", true, false, BinCreationWorksheetLine);
    end;

    local procedure RunCalculateInventoryValueTest(ItemNo: Code[20]; CalculatePer: Option)
    var
        Item: Record Item;
        CalcBase: Option " ","Last Direct Unit Cost","Standard Cost - Assembly List","Standard Cost - Manufacturing";
    begin
        Item.SetRange("No.", ItemNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(CalculatePer);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(CalcBase::"Standard Cost - Manufacturing");
        REPORT.Run(REPORT::"Calc. Inventory Value - Test", true, false, Item);
    end;

    local procedure RunCompareProductionCostSharesReport(ItemNo: Code[20]; ItemNo2: Code[20])
    begin
        LibraryVariableStorage.Enqueue(ItemNo);
        LibraryVariableStorage.Enqueue(ItemNo2);
        Report.Run(Report::"Compare Production Cost Shares", true, false);
    end;

    local procedure RunItemAgeCompositionQuantityReport(ItemNo: Code[20]; PeriodLength: DateFormula; LocationFilter: Text)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(PeriodLength);
        LibraryVariableStorage.Enqueue(LocationFilter);
        REPORT.Run(REPORT::"Item Age Composition - Qty.", true, false, Item);
    end;

    local procedure RunItemAgeCompositionValueReport(ItemNo: Code[20]; PeriodLength: DateFormula)
    var
        Item: Record Item;
    begin
        Item.SetRange("No.", ItemNo);
        LibraryVariableStorage.Enqueue(WorkDate());
        LibraryVariableStorage.Enqueue(PeriodLength);
        REPORT.Run(REPORT::"Item Age Composition - Value", true, false, Item);
    end;

    local procedure RunItemChargesSpecification(SourceNo: Code[20]; SourceType: Option)
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Source No.", SourceNo);
        LibraryVariableStorage.Enqueue(true);
        LibraryVariableStorage.Enqueue(SourceType);
        REPORT.Run(REPORT::"Item Charges - Specification", true, false, ValueEntry);
    end;

    local procedure RunItemRegisterValueReport(JournalBatchName: Code[10])
    var
        ItemRegister: Record "Item Register";
    begin
        ItemRegister.SetRange("Journal Batch Name", JournalBatchName);
        REPORT.Run(REPORT::"Item Register - Value", true, false, ItemRegister);
    end;

    local procedure RunSubcontractorDispatchList(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        REPORT.Run(REPORT::"Subcontractor - Dispatch List", true, false, ProdOrderRoutingLine);
    end;

    local procedure RunWarehousePostedShipmentReport(WarehouseShipmentNo: Code[20])
    var
        PostedWhseShipmentHeader: Record "Posted Whse. Shipment Header";
    begin
        PostedWhseShipmentHeader.SetRange("Whse. Shipment No.", WarehouseShipmentNo);
        REPORT.Run(REPORT::"Whse. - Posted Shipment", true, false, PostedWhseShipmentHeader);
    end;

    local procedure RunWarehouseInventoryRegisteringTestReport(ItemNo: Code[20])
    var
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        WarehouseJournalLine.SetRange("Item No.", ItemNo);
        REPORT.Run(REPORT::"Whse. Invt.-Registering - Test", true, false, WarehouseJournalLine);
    end;

    local procedure SelectItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure SelectProductionBOMLines(var ProductionBOMLine: Record "Production BOM Line"; ProductionBOMNo: Code[20])
    begin
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.FindSet();
    end;

    local procedure UpdateAndCalculateWorkCenterCalendar(WorkCenterNo: Code[20])
    var
        WorkCenter: Record "Work Center";
        Vendor: Record Vendor;
    begin
        WorkCenter.Get(WorkCenterNo);
        LibraryPurchase.CreateSubcontractor(Vendor);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, WorkDate(), WorkDate());
    end;

    local procedure UpdateGeneralLedgerSetup(AllowPostingFrom: Date) OldAllowPostingFrom: Date
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        OldAllowPostingFrom := GeneralLedgerSetup."Allow Posting From";
        GeneralLedgerSetup."Allow Posting From" := AllowPostingFrom;
        GeneralLedgerSetup.Modify(true);
        exit(OldAllowPostingFrom);
    end;

    local procedure UpdateSalesReceivableSetup(var OldCreditWarnings: Option; var OldStockoutWarning: Boolean; NewCreditWarnings: Option; NewStockoutWarning: Boolean)
    var
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        OldCreditWarnings := SalesReceivablesSetup."Credit Warnings";
        OldStockoutWarning := SalesReceivablesSetup."Stockout Warning";
        SalesReceivablesSetup.Validate("Credit Warnings", NewCreditWarnings);
        SalesReceivablesSetup.Validate("Stockout Warning", NewStockoutWarning);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdateRevaluedUnitCost(JournalTemplateName: Text[10]; JournalTemplateBatch: Text[10]; ItemNo: Code[20]; UnitCostRevalued: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Journal Template Name", JournalTemplateName);
        ItemJournalLine.SetRange("Journal Batch Name", JournalTemplateBatch);
        ItemJournalLine.SetRange("Item No.", ItemNo);
        ItemJournalLine.FindFirst();
        ItemJournalLine.Validate("Unit Cost (Revalued)", UnitCostRevalued);
        ItemJournalLine.Modify(true);
    end;

    local procedure UpdateRoutingVersion(var RoutingVersion: Record "Routing Version"; Status: Enum "Routing Status"; StartingDate: Date)
    begin
        RoutingVersion.Validate(Status, Status);
        RoutingVersion.Validate("Starting Date", StartingDate);
        RoutingVersion.Modify(true);
    end;

    local procedure VerifyAssemblyBOMComponent(ParentItemNo: Code[20]; ComponentItemNo: Code[20]; ExpectedValue: Boolean)
    begin
        LibraryReportDataset.SetRange('No_Item', ParentItemNo);
        LibraryReportDataset.SetRange('No_BOMComp', ComponentItemNo);
        LibraryReportDataset.AssertElementWithValueExists('AssemblyBOM_BOMComp', Format(ExpectedValue));
    end;

    local procedure VerifyCalculateInventoryValueReport(RowCaption: Text; RowValue: Variant; ColumnCaption: Text; ExpectedValue: Variant)
    begin
        LibraryReportDataset.SetRange(RowCaption, RowValue);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(ColumnCaption, ExpectedValue);
    end;

    local procedure VerifyCompareProductionCostSharesReport(ItemNo: Code[20]; ExpectedValue: Decimal)
    begin
        LibraryReportDataset.SetRange('No', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('DifferenceCost', ExpectedValue);
    end;

    local procedure VerifyItemAgeCompositionReport(ItemNo: Code[20]; Column1: Text; Column2: Text; ExpectedValueColumn1: Variant; ExpectedValueColumn2: Variant)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('No_Item', ItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals(Column1, ExpectedValueColumn1);
        LibraryReportDataset.AssertCurrentRowValueEquals(Column2, ExpectedValueColumn2);
    end;

    local procedure VerifyItemChargesSpecificationReport(SourceNo: Code[20]; Amount: Decimal)
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('SourceNo_ValueEntry', SourceNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('ValEntyCostAmtActSalesAct', Amount);
    end;

    local procedure VerifyItemValueEntryReport(ItemNo: Code[20])
    var
        ValueEntry: Record "Value Entry";
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.FindFirst();
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_ValueEntry', ItemNo);
        LibraryReportDataset.GetNextRow();

        LibraryReportDataset.AssertCurrentRowValueEquals('InvoicedQuantity_ValueEntry', ValueEntry."Invoiced Quantity");
        LibraryReportDataset.AssertCurrentRowValueEquals('CostperUnit_ValueEntry', ValueEntry."Cost per Unit");
    end;

    local procedure VerifyItemNoOnItemAgeCompositionReport(ItemNo: Code[20])
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('No_Item', ItemNo);
    end;

    local procedure VerifySubcontractorDispatchListReport(ProductionOrder: Record "Production Order"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('PONo_ProdOrderRtngLine', ProductionOrder."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('OprtnNo_ProdOrderRtngLine', ProdOrderRoutingLine."Operation No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('RemaingQty_ProdOrderLine', ProductionOrder.Quantity);
    end;

    local procedure VerifyWarehousePostedShipmentReport(PurchaseLine: Record "Purchase Line")
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo_PostedWhseShptLine', PurchaseLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('Qty_PostedWhseShptLine', PurchaseLine.Quantity);
    end;

    local procedure VerifyInventoryValuationWIPReport(CostAmountExpected: Decimal; StartingDate: Date)
    begin
        LibraryReportDataset.LoadDataSetFile();
        if StartingDate = WorkDate() then begin
            LibraryReportDataset.AssertElementWithValueExists('LastOutput', CostAmountExpected);
            LibraryReportDataset.AssertElementWithValueExists('AtLastDate', CostAmountExpected);
            LibraryReportDataset.AssertElementWithValueExists('ValueOfWIP', 0);
        end else begin
            LibraryReportDataset.AssertElementWithValueExists('LastOutput', -CostAmountExpected);
            LibraryReportDataset.AssertElementWithValueExists('ValueOfWIP', CostAmountExpected);
        end;
    end;

    local procedure VerifyQuantityExplosionOfBOMReport(ChildItemNo: Code[20]; ParentItemProdBOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        ProductionBOMLine.SetRange("No.", ChildItemNo);
        SelectProductionBOMLines(ProductionBOMLine, ParentItemProdBOMNo);
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('BomCompLevelNo', ChildItemNo);
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('BOMQty', ProductionBOMLine.Quantity);
        LibraryReportDataset.AssertCurrentRowValueEquals('BomCompLevelQty', ProductionBOMLine.Quantity);
    end;

    local procedure VerifyRolledupCostSharesReport(ChildItemNo: Code[20]; ParentItemProdBOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryReportDataset.LoadDataSetFile();
        ProductionBOMLine.SetRange("No.", ChildItemNo);
        SelectProductionBOMLines(ProductionBOMLine, ParentItemProdBOMNo);
        LibraryReportDataset.SetRange('ProdBOMLineIndexNo', ProductionBOMLine."No.");
        LibraryReportDataset.GetNextRow();
        LibraryReportDataset.AssertCurrentRowValueEquals('BOMCompQtyBase', ProductionBOMLine.Quantity);
    end;

    local procedure VerifyDetailedCalculationReport(ChildItemNo: Code[20]; ParentItemProdBOMNo: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
        Item: Record Item;
    begin
        LibraryReportDataset.LoadDataSetFile();
        ProductionBOMLine.SetRange("No.", ChildItemNo);
        SelectProductionBOMLines(ProductionBOMLine, ParentItemProdBOMNo);
        LibraryReportDataset.SetRange('ProdBOMLineLevelNo', ProductionBOMLine."No.");
        LibraryReportDataset.GetNextRow();
        Item.Get(ProductionBOMLine."No.");
        LibraryReportDataset.AssertCurrentRowValueEquals('ProdBOMLineLevelDesc', Item.Description);
    end;

    local procedure VerifyProductionBomErrorForTheReport(Item: Record Item; Type: Enum "Production BOM Line Type"; No: Code[20]; ProdBomNo: Code[20]; ReportId: Integer)
    begin
        // Setup: Add Type ProductionBom/Item as a Component in BOM.
        AddParentItemAsBOMComponent(Type, No, ProdBomNo);

        // Exercise: Run the Report.
        Commit();
        Item.SetRange("No.", Item."No.");
        asserterror REPORT.Run(ReportId, true, false, Item);

        // Verify: Verify Error.
        Assert.ExpectedError(StrSubstNo(ProductionBOMStatusErr, 50, Item."No."));
    end;

    local procedure CountReportSelections(ReportSelectionSalesPage: TestPage "Report Selection - Sales") Result: Integer
    begin
        if ReportSelectionSalesPage.Last() then
            repeat
                Result += 1;
            until not ReportSelectionSalesPage.Previous();
    end;

    local procedure VerifySelectedOptionForReportSelectionSales(UsageOptionForPage: Option; UsageOptionForTable: Enum "Report Selection Usage"; ReportID: Integer)
    var
        ReportSelectionsSalesPage: TestPage "Report Selection - Sales";
        SelectionsWithFilter: Integer;
    begin
        // Setup:
        Initialize();

        SelectionsWithFilter := CreateRandNumberRepSelections(UsageOptionForTable, ReportID);

        // Exercise: run Report Selection - Sales page and select "Pick Instruction" for Usage.
        ReportSelectionsSalesPage.Trap();
        PAGE.Run(PAGE::"Report Selection - Sales");
        ReportSelectionsSalesPage.ReportUsage.SetValue(UsageOptionForPage);

        // Verify: line number on page corresponds to lines in table.
        Assert.AreEqual(
          SelectionsWithFilter, CountReportSelections(ReportSelectionsSalesPage),
          StrSubstNo(LineCountErr, UsageOptionForPage));
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustCostRequestPageHandler(var AdjustCostItemEntries: TestRequestPage "Adjust Cost - Item Entries")
    begin
        AdjustCostItemEntries.Post.SetValue(true);
        AdjustCostItemEntries.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentSalesHandler(var ItemChargeAssignmentSales: TestPage "Item Charge Assignment (Sales)")
    begin
        ItemChargeAssignmentSales."Qty. to Assign".SetValue(ItemChargeAssignmentSales.AssignableQty.AsDecimal());
        ItemChargeAssignmentSales.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargeAssignmentPurchaseHandler(var ItemChargeAssignmentPurch: TestPage "Item Charge Assignment (Purch)")
    begin
        ItemChargeAssignmentPurch."Qty. to Assign".SetValue(ItemChargeAssignmentPurch.AssignableQty.AsDecimal());
        ItemChargeAssignmentPurch.OK().Invoke();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CompareProductionCostSharesRequestPageHandler(var CompareProductionCostShares: TestRequestPage "Compare Production Cost Shares")
    var
        ItemNo1: Variant;
        ItemNo2: Variant;
    begin
        LibraryVariableStorage.Dequeue(ItemNo1);
        LibraryVariableStorage.Dequeue(ItemNo2);

        CompareProductionCostShares.ItemNo1.SetValue(ItemNo1);
        CompareProductionCostShares.ItemNo2.SetValue(ItemNo2);

        CompareProductionCostShares.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BinContentCreationWkshtRequestPageHandler(var BinContentCreateWkshReport: TestRequestPage "Bin Content Create Wksh Report")
    begin
        BinContentCreateWkshReport.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
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
    procedure ItemAgeCompositionQtyRequestPageHandler(var ItemAgeCompositionQty: TestRequestPage "Item Age Composition - Qty.")
    begin
        ItemAgeCompositionQty.EndingDate.SetValue(LibraryVariableStorage.DequeueDate());
        ItemAgeCompositionQty.PeriodLength.SetValue(LibraryVariableStorage.DequeueText());
        ItemAgeCompositionQty.Item.SetFilter("Location Filter", LibraryVariableStorage.DequeueText());
        ItemAgeCompositionQty.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalcInventoryValueTestRequestPageHandler(var CalcInventoryValueTest: TestRequestPage "Calc. Inventory Value - Test")
    var
        PostingDate: Variant;
        CalculatePer: Variant;
        ByLocation: Variant;
        ByVariant: Variant;
        CalcBase: Variant;
    begin
        LibraryVariableStorage.Dequeue(PostingDate);
        LibraryVariableStorage.Dequeue(CalculatePer);
        LibraryVariableStorage.Dequeue(ByLocation);
        LibraryVariableStorage.Dequeue(ByVariant);
        LibraryVariableStorage.Dequeue(CalcBase);

        CalcInventoryValueTest.PostingDate.SetValue(PostingDate);
        CalcInventoryValueTest.CalculatePer.SetValue(CalculatePer);
        CalcInventoryValueTest."By Location".SetValue(ByLocation);
        CalcInventoryValueTest."By Variant".SetValue(ByVariant);
        CalcInventoryValueTest.CalcBase.SetValue(CalcBase);

        CalcInventoryValueTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemChargesSpecificationRequestPageHandler(var ItemChargesSpecification: TestRequestPage "Item Charges - Specification")
    var
        PrintDetails: Variant;
        SourceType: Variant;
    begin
        LibraryVariableStorage.Dequeue(PrintDetails);
        LibraryVariableStorage.Dequeue(SourceType);

        ItemChargesSpecification.PrintDetails.SetValue(PrintDetails);
        ItemChargesSpecification.SourceType.SetValue(SourceType);
        ItemChargesSpecification.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemRegisterValueRequestPageHandler(var ItemRegisterValue: TestRequestPage "Item Register - Value")
    begin
        ItemRegisterValue.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure SubcontractorDispatchListRequestPageHandler(var SubcontractorDispatchList: TestRequestPage "Subcontractor - Dispatch List")
    begin
        SubcontractorDispatchList.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhsePostedShipmentRequestPageHandler(var WhsePostedShipment: TestRequestPage "Whse. - Posted Shipment")
    begin
        WhsePostedShipment.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure WhseInvtRegisteringTestRequestPageHandler(var WhseInvtRegisteringTest: TestRequestPage "Whse. Invt.-Registering - Test")
    begin
        WhseInvtRegisteringTest.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdJournalPageHandler(var ProductionJournal: Page "Production Journal"; var Response: Action)
    var
        ItemJournalLine: Record "Item Journal Line";
        ProductionOrderNo: Variant;
    begin
        LibraryVariableStorage.Dequeue(ProductionOrderNo);
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            CODEUNIT.Run(CODEUNIT::"Item Jnl.-Post Batch", ItemJournalLine);
        until ItemJournalLine.Next() = 0;
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalculateStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        // Calculate Standard Cost for All Level when Costing Method Standard.
        Choice := 2;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure InventoryValuationWIPRequestPageHandler(var InventoryValuationWIP: TestRequestPage "Inventory Valuation - WIP")
    var
        StartingDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        InventoryValuationWIP.StartingDate.SetValue(StartingDate);
        InventoryValuationWIP.EndingDate.SetValue(CalcDate('<CM>', StartingDate));
        InventoryValuationWIP.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure DetailedCalculationRequestPageHandler(var DetailedCalculation: TestRequestPage "Detailed Calculation")
    var
        CalcDate: Variant;
    begin
        LibraryVariableStorage.Dequeue(CalcDate);
        DetailedCalculation.CalculationDate.SetValue(CalcDate);
        DetailedCalculation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure RolledUpCostSharesRequestPageHandler(var RolledUpCostShares: TestRequestPage "Rolled-up Cost Shares")
    begin
        RolledUpCostShares.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure QuantityExplosionOfBOMRequestPageHandler(var QuantityExplosionOfBOM: TestRequestPage "Quantity Explosion of BOM")
    begin
        QuantityExplosionOfBOM.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AssemblyBOMsRequestPageHandler(var AssemblyBOMs: TestRequestPage "Assembly BOMs")
    begin
        AssemblyBOMs.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustCostRequestFilterItemNoPageHandler(var AdjustCostItemEntries: TestRequestPage "Adjust Cost - Item Entries")
    begin
        AdjustCostItemEntries.FilterItemNo.SetValue(LibraryVariableStorage.DequeueText());
        LibraryVariableStorage.Enqueue(AdjustCostItemEntries.FilterItemNo.Value);
        AdjustCostItemEntries.Cancel().Invoke();
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure AdjustCostRequestFilterItemNoLookUpPageHandler(var AdjustCostItemEntries: TestRequestPage "Adjust Cost - Item Entries")
    begin
        AdjustCostItemEntries.FilterItemNo.Lookup();
        LibraryVariableStorage.Enqueue(AdjustCostItemEntries.FilterItemNo.Value);
        AdjustCostItemEntries.Cancel().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemListModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.GoToKey(LibraryVariableStorage.DequeueText());
        ItemList.OK().Invoke();
    end;

}

