codeunit 137009 "SCM Availability by Event"
{
    // // [FEATURE] [Item Availability] [SCM]
    // Case 1
    //   Simple: 1 PO, 1 SO out of resheduling period, 1 cancel PO (same date), 1 new (same date as sales), no excess inventory;

    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Item Availability] [SCM]
        Initialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySales: Codeunit "Library - Sales";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryPatterns: Codeunit "Library - Patterns";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        Initialized: Boolean;
        WrongReservedQtyErr: Label 'Wrong reserved quantity in Item Availability by Event';

    local procedure Initialize()
    begin
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Availability by Event");
        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Availability by Event");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryERMCountryData.CreateGeneralPostingSetupData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        NoSeriesSetup();

        LibrarySetupStorage.Save(DATABASE::"Assembly Setup");

        Commit();

        Initialized := true;
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Availability by Event");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CollectEventsCase1()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Evaluate(Item."Rescheduling Period", '<5D>');
        Item.Modify(true);

        CreatePurchaseOrder(PurchaseLine, Item."No.", 8, CalcDate('<+5D>', WorkDate()));
        CreateSalesOrder(SalesLine, Item."No.", 7, CalcDate('<+11D>', WorkDate()));
        LibraryManufacturing.CalculateWorksheetPlan(Item, CalcDate('<+2D>', WorkDate()), CalcDate('<+16D>', WorkDate()));

        // Should give 2 lines + Cancel + New from Planning plus one per Period Type, no excess inventory
        RunPage(Item, '', false, true, 0, 6, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastedItemAvailabilityIsCalculatedByVariant()
    var
        Item: Record Item;
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastEntry2: Record "Production Forecast Entry";
        ProductionForecastName: Record "Production Forecast Name";
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
    begin
        Initialize();

        // Create an item with 2 variants
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Create a forecast and setup manufacturing setup
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateForecastSetup(ProductionForecastName.Name, true, true);

        // Create forecasted demand for the first item variant 
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name, Item."No.", '', CalcDate('<+5D>', WorkDate()), false);
        ProductionForecastEntry.Validate("Variant Code", ItemVariant.Code);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", 3);
        ProductionForecastEntry.Modify(true);

        // Create forecasted demand for the second item variant 
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry2, ProductionForecastName.Name, Item."No.", '', CalcDate('<+10D>', WorkDate()), false);
        ProductionForecastEntry2.Validate("Variant Code", ItemVariant2.Code);
        ProductionForecastEntry2.Validate("Forecast Quantity (Base)", 9);
        ProductionForecastEntry2.Modify(true);

        // Should give 2 lines from forecast plus one per Period Type, total forecasted availability of -12
        RunPage(Item, ProductionForecastName.Name, false, true, 0, 4, -12);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ForecastedItemAvailabilityIsCalculatedForAVariantWhenVariatnFilterIsDefined()
    var
        Item: Record Item;
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastEntry2: Record "Production Forecast Entry";
        ProductionForecastName: Record "Production Forecast Name";
        ItemVariant: Record "Item Variant";
        ItemVariant2: Record "Item Variant";
    begin
        Initialize();

        // Create an item with 2 variants
        LibraryInventory.CreateItem(Item);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Modify(true);

        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryInventory.CreateItemVariant(ItemVariant2, Item."No.");

        // Create a forecast and setup manufacturing setup
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateForecastSetup(ProductionForecastName.Name, true, true);


        // Create forecasted demand for the first item variant 
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name, Item."No.", '', CalcDate('<+5D>', WorkDate()), false);
        ProductionForecastEntry.Validate("Variant Code", ItemVariant.Code);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", 3);
        ProductionForecastEntry.Modify(true);

        // Create forecasted demand for the second item variant 
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry2, ProductionForecastName.Name, Item."No.", '', CalcDate('<+10D>', WorkDate()), false);
        ProductionForecastEntry2.Validate("Variant Code", ItemVariant2.Code);
        ProductionForecastEntry2.Validate("Forecast Quantity (Base)", 9);
        ProductionForecastEntry2.Modify(true);

        // Should give 1 line from forecast plus one for Period Type, total forecasted availability of -3
        Item.SetRange("Variant Filter", ItemVariant.Code);
        RunPage(Item, ProductionForecastName.Name, false, true, 0, 2, -3);
    end;

    local procedure UpdateForecastSetup(CurrentDemandForecast: Code[10]; UseForecastOnLocations: Boolean; UseForecastOnVariants: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Current Demand Forecast", CurrentDemandForecast);
        InventorySetup.Validate("Use Forecast on Locations", UseForecastOnLocations);
        InventorySetup.Validate("Use Forecast on Variants", UseForecastOnVariants);
        InventorySetup.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedReceiptIsEqualToPurchaseQtyInAvailByEvent()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempInvtPageData: Record "Inventory Page Data" temporary;
    begin
        // [SCENARIO 361672] "Reserved Receipt" in Item Availability by Event is equal to Purchase Line qty. when sales order is reserved against purch. order
        Initialize();
        LibraryWarehouse.CreateLocation(Location);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));

        // [GIVEN] Purchase order for item "X", quantity = "Q"
        LibraryPurchase.CreatePurchaseOrder(
          PurchaseHeader, PurchaseLine, Item, Location.Code, '', LibraryRandom.RandInt(100), WorkDate(), Item."Unit Cost");
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);

        // [GIVEN] Sales order with reservation against purchase order, reserved quantity = "Q"
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, Location.Code, '', PurchaseLine.Quantity, WorkDate(), Item."Unit Price");

        SalesLine.Validate("Shipment Date", PurchaseLine."Expected Receipt Date");
        SalesLine.Modify(true);
        AutoReserveSalesLine(SalesLine);

        // [WHEN] Item availability by event is calculated
        CalculateAvailabilityByEvent(TempInvtPageData, Item, '');

        // [THEN] "Reserved Receipt" = "Q"
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Purchase);
        Assert.AreEqual(PurchaseLine.Quantity, TempInvtPageData."Reserved Receipt", WrongReservedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedRequirementIsEqualToNegativePurchReturnQtyInAvailByEvent()
    var
        Item: Record Item;
        Location: Record Location;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        TempInvtPageData: Record "Inventory Page Data" temporary;
        Quantity: Integer;
    begin
        // [SCENARIO 361672] "Reserved Requirement" in Item Availability by Event is equal to negative Purchase Return qty. when return is reserved against inventory
        Initialize();
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));

        // [GIVEN] "Q" units of item "X" on inventory
        Quantity := LibraryRandom.RandInt(100);
        LibraryInventory.PostPositiveAdjustment(Item, Location.Code, '', '', Quantity, WorkDate(), Item."Unit Cost");

        // [GIVEN] Purchase return order with "Q" units of item "X" reserved on inventory
        LibraryPurchase.CreatePurchaseReturnOrder(PurchaseHeader, PurchaseLine, Item, Location.Code, '', Quantity, WorkDate(), Item."Unit Cost");
        AutoReservePurchaseLine(PurchaseLine);

        // [WHEN] Item availability by event is calculated
        CalculateAvailabilityByEvent(TempInvtPageData, Item, '');

        // [THEN] "Reserved Requirement" = -"Q"
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::"Purch. Return");
        Assert.AreEqual(-PurchaseLine.Quantity, TempInvtPageData."Reserved Requirement", WrongReservedQtyErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReservedReceiptInAvailByEventShowsInboundAndShippedReservedQtyInTransfer()
    var
        Item: Record Item;
        FromLocation: Record Location;
        ToLocation: Record Location;
        InTransitLocation: Record Location;
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempInvtPageData: Record "Inventory Page Data" temporary;
        Qty: Decimal;
    begin
        // [FEATURE] [Transfer] [Reservation]
        // [SCENARIO 213103] Shipped and reserved quantity on transfer line should be included in Reserved Receipt in Item Availability by Event.
        Initialize();

        // [GIVEN] Locations "L1", "L2" and an in-transit location.
        CreateLocationsForTransfer(FromLocation, ToLocation, InTransitLocation);

        // [GIVEN] "Q" pcs of item "I" is is stock on "L1".
        LibraryInventory.CreateItemSimple(Item, Item."Costing Method"::Standard, LibraryPatterns.RandCost(Item));
        Qty := LibraryRandom.RandIntInRange(50, 100);
        LibraryInventory.PostPositiveAdjustment(Item, FromLocation.Code, '', '', Qty, WorkDate(), Item."Unit Cost");

        // [GIVEN] Transfer Order from "L1" to "L2". Quantity = "Q", "Qty. to Ship" = "q" < "Q".
        LibraryInventory.CreateTransferOrder(
          TransferHeader, TransferLine, Item, FromLocation, ToLocation, InTransitLocation, '', Qty, WorkDate(), WorkDate());
        TransferLine.Validate("Qty. to Ship", LibraryRandom.RandInt(20));
        TransferLine.Modify(true);

        // [GIVEN] Sales Order for "Q" pcs is reserved from Transfer Order.
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, ToLocation.Code, '', Qty, WorkDate(), Item."Unit Price");
        SalesLine.Validate("Shipment Date", LibraryRandom.RandDate(10));
        SalesLine.Modify(true);
        AutoReserveSalesLine(SalesLine);

        // [GIVEN] Transfer Order is shipped.
        // [GIVEN] Reserved Qty. Inbnd. (Base) becomes equal to "Q" - "q", Reserved Qty. Shipped (Base) = "q".
        LibraryInventory.PostTransferHeader(TransferHeader, true, false);
        TransferLine.Find();
        TransferLine.CalcFields("Reserved Qty. Inbnd. (Base)", "Reserved Qty. Shipped (Base)");

        // [WHEN] Calculate item availability by event.
        CalculateAvailabilityByEvent(TempInvtPageData, Item, '');

        // [THEN] "Reserved Receipt" on the availability line representing the transfer is equal to "Q".
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Transfer);
        Assert.AreEqual(
          TransferLine."Reserved Qty. Inbnd. (Base)" + TransferLine."Reserved Qty. Shipped (Base)",
          TempInvtPageData."Reserved Receipt", WrongReservedQtyErr);
    end;

    [Test]
    [HandlerFunctions('DummyNotificationHandler,ItemAvailabilityByLocationPageHandler,ConfirmHadlerYes')]
    [Scope('OnPrem')]
    procedure AvailabilityNotificationAppearsInSalesOrderWhenLocationChangedByItemAvailPage()
    var
        Item: Record Item;
        Location: Record Location;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order] [Availability] [Available - Sales Lines] [Notification]
        // [SCENARIO 279806] Availability notification must be called when Location Code is changed through Item Availability by Location page.
        Initialize();

        // [GIVEN] Create an Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create a Location
        LibraryWarehouse.CreateLocation(Location);

        // [GIVEN] Create a Sales Order with single Sales Line, Location Code left empty
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', LibraryRandom.RandInt(5), WorkDate(), LibraryRandom.RandInt(10));

        // [GIVEN] Open created Sales Order on test page
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Invoke Item Availability by Location page and choose Location
        Commit();
        LibraryVariableStorage.Enqueue(Location.Code);
        SalesOrder.SalesLines.ItemAvailabilityByLocation.Invoke();

        // [THEN] DummyNotificationHandler has been invoked - Notification was called properly

        LibraryVariableStorage.AssertEmpty();
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('DummyNotificationHandler,ItemAvailabilityByVariantPageHandler,ConfirmHadlerYes')]
    [Scope('OnPrem')]
    procedure AvailabilityNotificationAppearsInSalesOrderWhenVariantChangedByItemAvailPage()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        SalesOrder: TestPage "Sales Order";
    begin
        // [FEATURE] [Sales Order] [Availability] [Available - Sales Lines] [Notification]
        // [SCENARIO 279806] Availability notification must be called when Variant Code is changed through Item Availability by Variant page.
        Initialize();

        // [GIVEN] Create an Item with an Item Variant
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");

        // [GIVEN] Create a Sales Order with single Sales Line, Variant Code left empty
        LibrarySales.CreateSalesOrder(SalesHeader, SalesLine, Item, '', '', LibraryRandom.RandInt(5), WorkDate(), LibraryRandom.RandInt(10));

        // [GIVEN] Open created Sales Order on test page
        SalesOrder.OpenEdit();
        SalesOrder.GotoRecord(SalesHeader);

        // [WHEN] Invoke Item Availability by Variant page and choose Item Variant
        Commit();
        SalesOrder.SalesLines.ItemAvailabilityByVariant.Invoke();

        // [THEN] DummyNotificationHandler has been invoked - Notification was called properly
        LibraryNotificationMgt.RecallNotificationsForRecord(SalesLine);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityLineListPageHandler,ProdOrderComponentPageHandler')]
    [Scope('OnPrem')]
    procedure DrillingDownToGrossReqInItemAvailShowsListOfFirmPlannedProdOrders()
    var
        Item: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        ItemCard: TestPage "Item Card";
        ItemAvailabilityByPeriod: TestPage "Item Availability by Periods";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Availability] [Prod. Order Component] [Manufacturing]
        // [SCENARIO 382414] Prod. order components of Firm Planned production orders should be shown on drilling down Gross Requirements value on Item Available by Periods page.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item "I" which is a Prod. Order Component in Firm Planned production order. "Remaining Quantity" = "X".
        LibraryInventory.CreateItem(Item);
        MockProdOrderComponent(Item."No.", Qty);

        // [GIVEN] Item Availability by Periods page is opened for "I".
        ItemCard.OpenView();
        ItemCard.GotoRecord(Item);
        ItemAvailabilityByPeriod.Trap();
        ItemCard.Period.Invoke();

        // [WHEN] Drill down Gross Requirement value on Item Availability by Periods page.
        LibraryVariableStorage.Enqueue(ProdOrderComponent.TableCaption());
        LibraryVariableStorage.Enqueue(Qty);
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(Qty);
        ItemAvailabilityByPeriod.ItemAvailLines.FILTER.SetFilter("Period Start", Format(WorkDate()));
        ItemAvailabilityByPeriod.ItemAvailLines.GrossRequirement.DrillDown();

        // [THEN] Gross Requirement for "I" shows "X" units in prod. order components.
        // [THEN] Drilling down to "X" value shows "X" units of item "I" as a component of Firm Planned production order.
        // Verifications are done in ItemAvailabilityLineListPageHandler and ProdOrderComponentPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NetForecastByAssemblyDemandInAvailByEvent()
    var
        CompItem: Record Item;
        AsmItem: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        TempInvtPageData: Record "Inventory Page Data" temporary;
        QtyAsm: Decimal;
        QtyForecast: Decimal;
    begin
        // [FEATURE] [Demand Forecast] [Assembly]
        // [SCENARIO 328549] Assembly demand nets forecast on item availability by event page.
        Initialize();
        QtyForecast := LibraryRandom.RandIntInRange(100, 200);
        QtyAsm := LibraryRandom.RandIntInRange(10, 20);

        LibraryAssembly.SetStockoutWarning(false);

        // [GIVEN] Assembled item "A" with component "C".
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(AsmItem);
        Commit();
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, CompItem."No.", AsmItem."No.", '', 0, 1, true);

        // [GIVEN] Assembly order for item "A". Demand of component "C" = 10 pcs.
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, WorkDate(), AsmItem."No.", '', QtyAsm, '');

        // [GIVEN] Add a demand forecast entry with item "C" and "Forecast Quantity" = 100 pcs.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName.Name, CompItem."No.", '', CalcDate('<-CM>', WorkDate()), true);
        ProductionForecastEntry.Validate("Qty. per Unit of Measure", 1);
        ProductionForecastEntry.Validate("Forecast Quantity", QtyForecast);
        ProductionForecastEntry.Modify(true);

        // [WHEN] Calculate item availability by event.
        CalculateAvailabilityByEvent(TempInvtPageData, CompItem, ProductionForecastName.Name);

        // [THEN] Remaining forecast quantity = -90 pcs (the assembly demand is netting the forecast).
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Forecast);
        TempInvtPageData.TestField("Remaining Forecast", QtyAsm - QtyForecast);
    end;

    [Test]
    procedure AvailabilityByEventWithReversedDemandForecastAndSalesOrder()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        ProductionForecastName: Record "Production Forecast Name";
        ProductionForecastEntry: Record "Production Forecast Entry";
        TempInvtPageData: Record "Inventory Page Data" temporary;
        Date: Record Date;
        StartDate: Date;
        ForecastQty: Decimal;
        SalesQty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Demand Forecast] [Sales]
        // [SCENARIO 441854] Item availability must display the same result when demand forecast does not exist and when it is reversed.
        Initialize();
        ForecastQty := LibraryRandom.RandIntInRange(100, 200);
        SalesQty := LibraryRandom.RandInt(10);
        StartDate := CalcDate('<-CM>', WorkDate());

        // [GIVEN] Create demand forecast for 4 months period.
        // [GIVEN] Month = Jan, Quantity = 100.
        // [GIVEN] Month = Feb, Quantity = 100.
        // [GIVEN] Month = Mar, Quantity = 100.
        // [GIVEN] Month = Apr, Quantity = 100.
        LibraryInventory.CreateItem(Item);
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);

        Date."Period Type" := Date."Period Type"::Month;
        Date."Period Start" := StartDate;
        Date.Find();
        for i := 1 to 4 do begin
            LibraryManufacturing.CreateProductionForecastEntry(
              ProductionForecastEntry, ProductionForecastName.Name, Item."No.", '', Date."Period Start", false);
            ProductionForecastEntry.Validate("Qty. per Unit of Measure", 1);
            ProductionForecastEntry.Validate("Forecast Quantity", ForecastQty);
            ProductionForecastEntry.Modify(true);
            Date.Next();
        end;

        // [GIVEN] Create a reverse forecast entry in February, quantity = -100.
        // [GIVEN] That makes it zero in February, so the system must behave the same as if there wasn't any forecast in Feb.
        LibraryManufacturing.CreateProductionForecastEntry(
          ProductionForecastEntry, ProductionForecastName.Name, Item."No.", '', CalcDate('<1M>', StartDate), false);
        ProductionForecastEntry.Validate("Qty. per Unit of Measure", 1);
        ProductionForecastEntry.Validate("Forecast Quantity", -ForecastQty);
        ProductionForecastEntry.Modify(true);

        // [GIVEN] Sales order for 5 qty., shipment date = March 10.
        CreateSalesOrder(SalesLine, Item."No.", SalesQty, LibraryRandom.RandDateFrom(CalcDate('<2M>', StartDate), 20));

        // [WHEN] Calculate item availability by event.
        CalculateAvailabilityByEvent(TempInvtPageData, Item, ProductionForecastName.Name);

        // [THEN] The sales order does not affect remaining forecast values before March.
        // [THEN] Remaining Forecast in Jan = -100.
        TempInvtPageData.SetRange("Period Start", StartDate);
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Forecast);
        TempInvtPageData.TestField("Remaining Forecast", -ForecastQty);

        // [THEN] Remaining Forecast in Feb = 0.
        TempInvtPageData.SetRange("Period Start", CalcDate('<1M>', StartDate));
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Forecast);
        TempInvtPageData.TestField("Remaining Forecast", 0);

        // [THEN] Remaining Forecast in Mar = -95.
        TempInvtPageData.SetRange("Period Start", CalcDate('<2M>', StartDate));
        FindInvtPageData(TempInvtPageData, TempInvtPageData.Type::Forecast);
        TempInvtPageData.TestField("Remaining Forecast", -ForecastQty + SalesQty);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByEventPageHandler,PlanningWorksheetModalPageHandler')]
    procedure LookupItemAvailabilityByEventOnItemCardOpenTheCorrectPlanningWorksheetBatch()
    var
        Item: Record Item;
        NewPlanningWorkSheetBatchName: Code[10];
        OldPlanningWorkSheetBatchName: Code[10];
        ItemCard: TestPage "Item Card";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        // [SCENARIO 575726] Verify that the 'Lookup Item Availability by Event' on the item card opens the correct planning worksheet batch.
        Initialize();

        // [GIVEN] Create a Item.
        LibraryInventory.CreateItem(Item);
        LibraryVariableStorage.Enqueue(Item."No.");

        // [GIEVN] Get old planning worksheet batch name.
        OldPlanningWorkSheetBatchName := GetRequisitionWkshBatch();

        // [GIVEN] Open planning worksheet batch.
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.New();

        // [GIVEN] Set the old planning worksheet batch name.
        PlanningWorksheet.CurrentWkshBatchName.SetValue(OldPlanningWorkSheetBatchName);
        LibraryVariableStorage.Enqueue(OldPlanningWorkSheetBatchName);

        // [GIVEN] Set the item number and quantity in the planning worksheet.
        PlanningWorksheet."No.".SetValue(Item."No.");
        PlanningWorksheet.Quantity.SetValue(LibraryRandom.RandIntInRange(10, 20));
        PlanningWorksheet.Close();

        // [GIVEN] Set new planning worksheet batch.
        NewPlanningWorkSheetBatchName := CreateRequisitionWkshBatch();
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(NewPlanningWorkSheetBatchName);
        PlanningWorksheet.Close();

        // [THEN] Verify the current planning worksheet batch name.
        PlanningWorksheet.OpenView();
        Assert.Equal(NewPlanningWorkSheetBatchName, PlanningWorksheet.CurrentWkshBatchName.Value);

        // [GIVEN] Open Item Card.
        ItemCard.OpenEdit();
        ItemCard.GoToRecord(Item);

        // [WHEN] Invoke Item Availability by Event Action.
        ItemCard."<Action110>".Invoke();
        ItemCard.Close();

        // [THEN] Verify Lookup Item Availability by Event on the item card opens the correct planning worksheet batch.
        // It was verified on the PlanningWorksheetModalPageHandler. 
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure AutoReservePurchaseLine(PurchaseLine: Record "Purchase Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservMgt.SetReservSource(PurchaseLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', WorkDate(), PurchaseLine.Quantity, PurchaseLine."Quantity (Base)");
    end;

    local procedure AutoReserveSalesLine(SalesLine: Record "Sales Line")
    var
        ReservMgt: Codeunit "Reservation Management";
        FullAutoReservation: Boolean;
    begin
        ReservMgt.SetReservSource(SalesLine);
        ReservMgt.AutoReserve(FullAutoReservation, '', SalesLine."Shipment Date", SalesLine.Quantity, SalesLine."Quantity (Base)");
    end;

    local procedure RunPage(var Item: Record Item; ForecastName: Code[10]; InclBlanketOrders: Boolean; InclPlan: Boolean; PeriodType: Option; ExpectedNoOfLines: Integer; ExpextedEndBalance: Decimal)
    var
        PageTempInvtPageData: Record "Inventory Page Data" temporary;
        TempInvtPageData: Record "Inventory Page Data" temporary;
        CalcInvtPageData: Codeunit "Calc. Inventory Page Data";
        RunningBalance: Decimal;
        RunningBalanceForecast: Decimal;
        RunningBalancePlan: Decimal;
    begin
        // Works more less like Page 5530 except for the view part
        // Initialize + get events in background table in cu
        CalcInvtPageData.Initialize(Item, ForecastName, InclBlanketOrders, 0D, InclPlan);

        // Create Period aggegation entries in Page background table
        TempInvtPageData.Reset();
        TempInvtPageData.DeleteAll();
        TempInvtPageData.SetCurrentKey("Period Start", "Line No.");
        CalcInvtPageData.CreatePeriodEntries(TempInvtPageData, PeriodType);   // got events in background table in cu

        // Get event details
        TempInvtPageData.SetRange(Level, 0);
        if TempInvtPageData.Find('-') then
            repeat
                // get one entry per involved period in tempinv
                CalcInvtPageData.DetailsForPeriodEntry(TempInvtPageData, true);
                CalcInvtPageData.DetailsForPeriodEntry(TempInvtPageData, false);
            until TempInvtPageData.Next() = 0;
        TempInvtPageData.SetRange(Level);

        // Populate the view table likedon on expandall in the page
        PageTempInvtPageData.Reset();
        PageTempInvtPageData.DeleteAll();
        PageTempInvtPageData.SetCurrentKey("Period Start", "Line No.");
        if TempInvtPageData.Find('-') then
            repeat
                PageTempInvtPageData := TempInvtPageData;
                PageTempInvtPageData.UpdateInventorys(RunningBalance, RunningBalanceForecast, RunningBalancePlan);
                PageTempInvtPageData.Insert();
            until TempInvtPageData.Next() = 0;

        Assert.AreEqual(ExpectedNoOfLines, PageTempInvtPageData.Count,
          'Asserting that the no. of lines match');
        Assert.AreEqual(ExpextedEndBalance, PageTempInvtPageData."Suggested Projected Inventory",
          'Asserting that the ultimo Suggested Projected Inventory match');
    end;

    local procedure NoSeriesSetup()
    var
        PurchPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchPayablesSetup.Get();
        PurchPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchPayablesSetup.Modify(true);
    end;

    local procedure CalculateAvailabilityByEvent(var TempInvtPageData: Record "Inventory Page Data" temporary; Item: Record Item; ForecastName: Code[10])
    var
        CalcInventoryPageData: Codeunit "Calc. Inventory Page Data";
        PeriodType: Option Day,Week,Month,Quarter,Year;
    begin
        CalcInventoryPageData.Initialize(Item, ForecastName, false, 0D, false);
        CalcInventoryPageData.CreatePeriodEntries(TempInvtPageData, PeriodType::Day);
        TempInvtPageData.SetRange(Level, 0);
        TempInvtPageData.FindSet();
        repeat
            CalcInventoryPageData.DetailsForPeriodEntry(TempInvtPageData, true);
            CalcInventoryPageData.DetailsForPeriodEntry(TempInvtPageData, false);
        until TempInvtPageData.Next() = 0;
    end;

    local procedure CreateLocationsForTransfer(var FromLocation: Record Location; var ToLocation: Record Location; var InTransitLocation: Record Location)
    begin
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(FromLocation);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(ToLocation);
        LibraryWarehouse.CreateInTransitLocation(InTransitLocation);
    end;

    local procedure CreatePurchaseOrder(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; Quantity: Decimal; AvailableDate: Date)
    var
        PurchaseHeader: Record "Purchase Header";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", AvailableDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Quantity: Decimal; AvailableDate: Date)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Shipment Date", AvailableDate);
        SalesLine.Modify(true);
    end;

    local procedure FindInvtPageData(var InvtPageData: Record "Inventory Page Data"; DataType: Enum "Inventory Page Data Type")
    begin
        InvtPageData.SetRange(Level, 1);
        InvtPageData.SetRange(Type, DataType);
        InvtPageData.FindFirst();
    end;

    local procedure MockProdOrderComponent(ItemNo: Code[20]; Qty: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Init();
        ProdOrderComponent.Status := ProdOrderComponent.Status::"Firm Planned";
        ProdOrderComponent."Item No." := ItemNo;
        ProdOrderComponent."Due Date" := WorkDate();
        ProdOrderComponent."Remaining Quantity" := Qty;
        ProdOrderComponent."Remaining Qty. (Base)" := Qty;
        ProdOrderComponent.Insert();
    end;

    local procedure GetRequisitionWkshBatch(): Code[10]
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();

        exit(RequisitionWkshName.Name);
    end;

    local procedure GetRequisitionWkshTemplate(): Code[10]
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        RequisitionWkshName.SetRange("Template Type", RequisitionWkshName."Template Type"::Planning);
        RequisitionWkshName.FindFirst();

        exit(RequisitionWkshName."Worksheet Template Name");
    end;

    local procedure CreateRequisitionWkshBatch(): Code[10]
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, GetRequisitionWkshTemplate());

        exit(RequisitionWkshName.Name);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByLocationPageHandler(var ItemAvailabilitybyLocation: TestPage "Item Availability by Location")
    begin
        ItemAvailabilitybyLocation.ItemAvailLocLines.GotoKey(LibraryVariableStorage.DequeueText());
        ItemAvailabilitybyLocation.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByVariantPageHandler(var ItemAvailabilitybyVariant: TestPage "Item Availability by Variant")
    begin
        ItemAvailabilitybyVariant.ItemAvailLocLines.First();
        ItemAvailabilitybyVariant.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityLineListPageHandler(var ItemAvailabilityLineList: TestPage "Item Availability Line List")
    begin
        ItemAvailabilityLineList.Name.AssertEquals(LibraryVariableStorage.DequeueText());
        ItemAvailabilityLineList.Quantity.AssertEquals(LibraryVariableStorage.DequeueDecimal());
        ItemAvailabilityLineList.Quantity.DrillDown();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ProdOrderComponentPageHandler(var ProdOrderCompLineList: TestPage "Prod. Order Comp. Line List")
    begin
        ProdOrderCompLineList."Item No.".AssertEquals(LibraryVariableStorage.DequeueText());
        ProdOrderCompLineList."Remaining Quantity".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [SendNotificationHandler]
    [Scope('OnPrem')]
    procedure DummyNotificationHandler(var Notification: Notification): Boolean
    begin
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Text: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHadlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure ItemAvailabilityByEventPageHandler(var ItemAvailabilitybyEvent: TestPage "Item Availability by Event")
    var
        InventoryPageDataType: Enum "Inventory Page Data Type";
    begin
        ItemAvailabilitybyEvent.IncludePlanningSuggestions.SetValue(true);
        ItemAvailabilitybyEvent.Filter.SetFilter(Type, Format(InventoryPageDataType::Plan));
        ItemAvailabilitybyEvent."Show Document".Invoke();
        ItemAvailabilitybyEvent.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PlanningWorksheetModalPageHandler(var PlanningWorksheet: TestPage "Planning Worksheet")
    var
        CurrentWkshBatchName: Variant;
        ItemNo: Variant;
    begin
        ItemNo := LibraryVariableStorage.DequeueText();
        CurrentWkshBatchName := LibraryVariableStorage.DequeueText();
        PlanningWorksheet.CurrentWkshBatchName.AssertEquals(CurrentWkshBatchName);
        PlanningWorksheet."No.".AssertEquals(ItemNo);
    end;
}

