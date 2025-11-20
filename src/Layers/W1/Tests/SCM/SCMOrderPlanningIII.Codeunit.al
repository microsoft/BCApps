codeunit 137088 "SCM Order Planning - III"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [SCM]
        IsInitialized := false;
    end;

    var
        LocationRed: Record Location;
        LocationBlue: Record Location;
        LocationBlue2: Record Location;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryERM: Codeunit "Library - ERM";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryService: Codeunit "Library - Service";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryJob: Codeunit "Library - Job";
        LibraryDimension: Codeunit "Library - Dimension";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryRandom: Codeunit "Library - Random";
        VerifyOnGlobal: Option RequisitionLine,Orders;
        DemandTypeGlobal: Option Sales,Production;
        GlobalChildItemNo: Code[20];
        IsInitialized: Boolean;
        ValidationError: Label '%1  must be %2 in %3.';
        ExpectedQuantity: Decimal;
        QuantityError: Label 'Available Quantity must match.';
        OrderTrackingMessage: Label 'The change will not affect existing entries.';
        UnexpectedMessageDialog: Label 'Unexpected Message dialog.  %1';
        LineCountError: Label 'There should be '' %1 '' line(s) in the planning worksheet for item. ';
        LineExistErr: Label 'Requistion line in %1 worksheet should exist for item %2';
        PurchaseLineQuantityBaseErr: Label '%1.%2 must be nearly equal to %3.', Comment = '%1 : Purchase Line, %2 : Quantity (Base), %3 : Value.';
        BOMFixedQtyCalcFormulaErr: Label 'BOM Fixed Quantity Calculation Formula should be used to calculate the values.';
        RelesedProdOrderComponentQtyPerRoundingErr: Label 'Relesed Production Order Item Component Quantity per %1 Not Match With Expected Result %2';
        RelesedProdOrderComponentExpQtyRoundingErr: Label 'Relesed Production Order Item Component Expected Quantity %1 Not Match With Expected Result %2';

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeItem()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        Item2: Record Item;
        ChildItem2: Record Item;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        CreateProdItem(Item2, ChildItem2);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Change Source No in Production Order.
        ChangeDataOnProductionOrderAndRefresh(ProductionOrder, ProductionOrder.FieldNo("Source No."), Item2."No.");

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Item No. after calculate plan.
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("No."), ChildItem2."No.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeLocation()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);

        // Change Location On Production Order.
        ChangeDataOnProductionOrderAndRefresh(ProductionOrder, ProductionOrder.FieldNo("Location Code"), LocationBlue.Code);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Location Code after calculate plan.
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("Location Code"), LocationBlue.Code);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeQty()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, Quantity);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Change Source No in Production Order.
        ChangeDataOnProductionOrderAndRefresh(
          ProductionOrder, ProductionOrder.FieldNo(Quantity), Quantity + LibraryRandom.RandDec(10, 2));
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        Quantity2 := ProdOrderComponent."Remaining Quantity";

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Quantity after calculate plan.
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("Demand Quantity (Base)"), Format(Quantity2));
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProductionOrderPlanningChangeDemandDate()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Change Source No in Production Order.
        ProductionOrder.Find();
        ProductionOrder.SetUpdateEndDate();
        ProductionOrder.Validate("Due Date", CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check that error message is same as accepted during make order when change Production Order Due Date after calculate plan.
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption("Demand Date"), Format(ProductionOrder."Due Date" - 1));
    end;

    [Test]
    [HandlerFunctions('OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForOrderTracking()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        OrderPlanning: TestPage "Order Planning";
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::"Tracking Only");
        GlobalChildItemNo := ChildItem."No.";
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        ExpectedQuantity := ProdOrderComponent."Remaining Quantity";
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise And Verify : Open Order Tracking Page and Verification is done by Handler Method. Check That Order Tracking Line Create As expected.
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");
        OrderPlanning.OrderTracking.Invoke();
        OrderPlanning.Close();
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler,OrderTrackingPageHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderAndCheckOrderTrackingInPurchOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProdOrderComponent: Record "Prod. Order Component";
        PurchaseOrder: TestPage "Purchase Order";
        PurchaseOrderNo: Code[20];
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, false, ChildItem."Order Tracking Policy"::"Tracking Only");
        GlobalChildItemNo := ChildItem."No.";
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2) +
          10);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
        ExpectedQuantity := ProdOrderComponent."Remaining Quantity";
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        PurchaseOrderNo := FindPurchaseOrderNo();

        // Exercise.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Verification is done by Handler Method. Check That Order Tracking Line Create As expected when make order from Order Planning Page.
        LibraryPurchase.DisableWarningOnCloseUnpostedDoc();
        LibraryPurchase.DisableWarningOnCloseUnreleasedDoc();
        PurchaseOrder.OpenView();
        PurchaseOrder.FILTER.SetFilter("No.", PurchaseOrderNo);
        PurchaseOrder.PurchLines.OrderTracking.Invoke();
        PurchaseOrder.Close();
    end;

    [Test]
    [HandlerFunctions('PlanningComponentPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForProdOrderPlanningComponent()
    begin
        Initialize();
        PlanningForProductionOrder(false)
    end;

    [Test]
    [HandlerFunctions('PlanningRoutingPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForProdOrderPlanningRouting()
    begin
        Initialize();
        PlanningForProductionOrder(true)
    end;

    local procedure PlanningForProductionOrder(PlanningRouting: Boolean)
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        OrderPlanning: TestPage "Order Planning";
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning.
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        GlobalChildItemNo := ChildItem."No.";
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");

        // Exercise And Verify.
        if PlanningRouting then
            // Exercise And Verify : Open Planning Routing and Verification is done by Handler Method. Check That Planning Routing is same as Routing on child item.
            OrderPlanning."Ro&uting".Invoke()
        else
            // Exercise And Verify : Open Planning Component and Verification is done by Handler Method. Check That Planning Component is same as component on child item.
            OrderPlanning.Components.Invoke();
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangePlanningComponentAndMakeOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        Item: Record Item;
        PlanningComponent: Record "Planning Component";
        QuantityPer: Decimal;
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning and Add Planning Component.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));  // Random value is Important For test.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        QuantityPer := LibraryRandom.RandDec(10, 2);
        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);
        UpdatePlanningComponent(PlanningComponent, Item."No.", Item."Base Unit of Measure", QuantityPer);

        // Exercise.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check That Production Order Component is Created with the added component in Order Planning Page.
        VerifyProdOrderComponent(Item."No.", Item."Base Unit of Measure", QuantityPer);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangePlanningRoutingAndMakeOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        PlanningRoutingLine: Record "Planning Routing Line";
        WorkCenter: Record "Work Center";
        OperationNo: Code[10];
    begin
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning and Add Planning Routing.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        CreateWorkCenter(WorkCenter);
        OperationNo := FindLastOperationNo(ChildItem."Routing No.") + Format(LibraryRandom.RandInt(5));
        LibraryManufacturing.CreatePlanningRoutingLine(PlanningRoutingLine, RequisitionLine, OperationNo);
        UpdatePlanningRoutingLine(
          PlanningRoutingLine, WorkCenter."No.", FindLastOperationNo(ChildItem."Routing No."), LibraryRandom.RandDec(10, 2),
          LibraryRandom.RandDec(10, 2));  // Random Value Required.

        // Exercise.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Check That Production Order Routing Line is Created with the added Routing Line in Order Planning Page.
        VerifyProdOrderRoutingLine(PlanningRoutingLine, ChildItem."Routing No.", OperationNo);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure StatisticOnProductionOrderWithPlanning()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProductionOrderStatistics: TestPage "Production Order Statistics";
        FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders";
        ProductionOrderStatistics2: TestPage "Production Order Statistics";
        FirmPlannedProdOrders2: TestPage "Firm Planned Prod. Orders";
        ProductionOrderNo: Code[20];
    begin
        // [FEATURE] [Manufacturing]
        // Setup: Create Work Center, Routing, Item, Create Firm Planned Production Order and calculate Plan from Order Planning ,Make Order and Open Production Order Statistics.
        Initialize();

        LibraryApplicationArea.EnablePremiumSetup();

        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");
        ProductionOrderNo := FindProductionOrderNo(ChildItem."No.");
        OpenFirmPlannedProductionOrder(FirmPlannedProdOrders, ProductionOrderStatistics, ChildItem."No.", ProductionOrderNo);

        // Exercise : Create Firm Planned Production Order and Open Production Order Statistics.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ChildItem."No.", LocationRed.Code, RequisitionLine.Quantity);
        OpenFirmPlannedProductionOrder(FirmPlannedProdOrders2, ProductionOrderStatistics2, ChildItem."No.", ProductionOrder."No.");

        // Verify : Check Production Order Statistic on Firm Planned Prod. Order created from Make Order with Production Order Statistic on Firm Planned Production Order Created Directly.
        VerifyProductionOrderStatistics(ProductionOrderStatistics, ProductionOrderStatistics2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesDimensionOnOrderPlanning()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup : Create Item with Dimension, Create Sales  Order.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.

        // Exercise : Run  Calculate Order Planning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check That Dimension on Sales Order Item Line is same as Dimension on Item.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", '');
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, RequisitionLine."Dimension Set ID");

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderCheckDimensionOnPurchOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        PurchaseOrderNo: Code[20];
    begin
        // Setup : Create Item with Dimension and Replenishment System Purchase, Create Sales  Order and Calculate Plan.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        PurchaseOrderNo := FindPurchaseOrderNo();

        // Exercise : Make Order for Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Check That Dimension On Purchase Line Created From Make Order is same as dimension on Item.
        FindPurchaseLine(PurchaseLine, PurchaseOrderNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, PurchaseLine."Dimension Set ID");

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderCheckDimensionOnProductionOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrderNo: Code[20];
    begin
        // Setup : Create Item with Dimension and Replenishment System Production Order, Create Sales  Order and Calculate Plan.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateProdItem(Item, ChildItem);
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(DefaultDimension, Item."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Order for Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Check that Dimension On Production Order Created From Make Order is same as dimension on Item.
        ProductionOrderNo := FindProductionOrderNo(Item."No.");
        ProductionOrder.Get(ProductionOrder.Status::"Firm Planned", ProductionOrderNo);
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, ProductionOrder."Dimension Set ID");

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveSalesPlanningNever()
    var
        Item: Record Item;
    begin
        // Check that Reserve is False While we create item with Reserve Never for Sales Order.
        Initialize();
        ReserveSalesOrderPlanning(Item.Reserve::Never, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveSalesPlanningAlways()
    var
        Item: Record Item;
    begin
        // Check that Reserve is TRUE While we create item with Reserve Always for Sales Order.
        Initialize();
        ReserveSalesOrderPlanning(Item.Reserve::Always, false);
    end;

    local procedure ReserveSalesOrderPlanning(ReserveOnItem: Enum "Reserve Method"; ReserveOnRequistition: Boolean)
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
    begin
        // Setup: Create Item with Reserve and Create Sales Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItem(Item, ReserveOnItem, Item."Order Tracking Policy"::None);
        CreateSalesOrder(
          SalesHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibrarySales.ReleaseSalesDocument(SalesHeader);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check that Reserve is TRUE OR False While we create child item Reserve Always and Never for Sales Order.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);
        asserterror RequisitionLine.Validate(Reserve, ReserveOnRequistition);
        if ReserveOnRequistition then
            Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption(Reserve), Format(false))
        else
            Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption(Reserve), Format(true));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanAlwaysMakeOrder()
    var
        ChildItem: Record Item;
    begin
        // Check That Reservation Entry Created after Make Supply Order for Sales Order when Child Item Reserve is Always.
        Initialize();
        ReserveSalesOrderPlanMakeOrder(ChildItem.Reserve::Always);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanNeverMakeOrder()
    var
        ChildItem: Record Item;
    begin
        // Check That Reservation Entry not Created after Make Supply Order for Sales Order when Child Item Reserve is Never.
        Initialize();
        ReserveSalesOrderPlanMakeOrder(ChildItem.Reserve::Never);
    end;

    local procedure ReserveSalesOrderPlanMakeOrder(ReserveOnItem: Enum "Reserve Method")
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ReservationEntry: Record "Reservation Entry";
        Quantity: Decimal;
    begin
        // Setup : Create Item With Reservation Option and Create Sales Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItem(Item, ReserveOnItem, Item."Order Tracking Policy"::None);
        Quantity := LibraryRandom.RandDec(20, 2);  // Random Value Required.
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);

        // Exercise : Run Make order from Order Planning.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        if ReserveOnItem = ChildItem.Reserve::Always then begin
            ReservationEntry.SetRange("Item No.", Item."No.");
            ReservationEntry.SetRange("Source Type", 39);  // Value important as it signifies Purchase Line Table ID.
            ReservationEntry.FindFirst();
            Assert.AreEqual(
              Quantity, ReservationEntry.Quantity,
              StrSubstNo(ValidationError, ReservationEntry.FieldCaption(Quantity), Quantity, ReservationEntry.TableCaption()));
        end else begin
            // Verify : Check That Reservation Entry Not Created after Make Supply Order.
            ReservationEntry.SetRange("Item No.", Item."No.");
            asserterror ReservationEntry.FindFirst();
        end;

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqAlways()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Purchase REQ Requisition Lines from Production Order Planning
        // if Item.Reserve is Always and Item."Reordering Policy" is Order
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Always, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqNever()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries NOT created when creating Purchase REQ Requisition Lines from Production Order Planning
        // if Item.Reserve is Never and Item."Reordering Policy" is Order
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Never, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqOptional1()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Prod. Order PLANNING Requisition Lines from Production Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Fixed Reorder Qty.
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Fixed Reorder Qty.",
          RequisitionLine."Replenishment System"::"Prod. Order", ReqWkshTemplate.Type::Planning);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveProdOrderPlanCopyToReqOptional2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Transfer REQ Requisition Lines from Production Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Maximum Qty.
        ReserveProdOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Maximum Qty.",
          RequisitionLine."Replenishment System"::Transfer, ReqWkshTemplate.Type::"Req.");
    end;

    local procedure ReserveProdOrderPlanCopyToReq(Reserve: Enum "Reserve Method"; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; ReqWkshTemplateType: Enum "Req. Worksheet Template Type")
    var
        Item: Record Item;
        ProdItem: Record Item;
        ProdBOMHeader: Record "Production BOM Header";
        ProdBOMLine: Record "Production BOM Line";
        ProdOrderComponent: Record "Prod. Order Component";
        RequisitionLine: Record "Requisition Line";
        ProdOrder: Record "Production Order";
        ReservationEntry: Record "Reservation Entry";
        ReqWkshTemplateName: Code[10];
        ReqWkshName: Code[10];
        Qty: Decimal;
        QtyPer: Decimal;
    begin
        // Setup : Create Production Order and Calculate Plan
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemEx(Item, Reserve, ReorderingPolicy);

        QtyPer := LibraryRandom.RandIntInRange(10, 20);
        CreateItemWithProductionBOM(ProdItem, Item, '', QtyPer);
        Qty := LibraryRandom.RandIntInRange(10, 20);
        CreateAndRefreshProdOrder(ProdOrder, ProdOrder.Status::Released, ProdItem."No.", '', Qty);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.SetRange("Item No.", Item."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Validate("Location Code", LocationBlue.Code);
        ProdOrderComponent.Modify(true);
        ProdOrder.Get(ProdOrder.Status::Released, ProdOrder."No.");
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProdOrder."No.", Item."No.", LocationBlue.Code);
        if ReplenishmentSystem <> Item."Replenishment System"::Purchase then
            ModifyRequisitionLine(RequisitionLine, Item.Reserve, ReplenishmentSystem);

        ReqWkshTemplateName := GetReqWkshTemplateName(ReqWkshTemplateType);
        ReqWkshName := GetReqWkshName(ReqWkshTemplateName, ReqWkshTemplateType);

        // Exercise : Run Make order from Order Planning.
        MakeSupplyOrdersCopyToWkshActiveOrder(ProdOrder."No.", ReqWkshTemplateName, ReqWkshName);

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        // 246 indicates reserved from requisition line
        VerifyReservationEntry(RequisitionLine, Item."No.", ReqWkshTemplateName, ReqWkshName, 246, Qty * QtyPer);
        VerifyRequisitionLine(Item."No.", ReqWkshTemplateName, ReqWkshName);

        // Tear Down
        ReservationEntry.SetRange("Item No.", Item."No.");
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry.Delete();
            until ReservationEntry.Next() = 0;
        ProdOrder.Delete();
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.Delete();
        ProdBOMLine.SetRange("Production BOM No.", ProdItem."Production BOM No.");
        ProdBOMLine.FindFirst();
        ProdBOMLine.Delete();

        ProdBOMHeader.SetRange("No.", ProdItem."Production BOM No.");
        ProdBOMHeader.FindFirst();
        ProdBOMHeader.Delete();
        ProdItem.Delete();
        Item.Delete();
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqAlways()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Purchase REQ Requisition Lines from Sales Order Planning
        // if Item.Reserve is Always and Item."Reordering Policy" is Order
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Always, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqNever()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries NOT created when creating Purchase REQ Requisition Lines from Sales Order Planning
        // if Item.Reserve is Never and Item."Reordering Policy" is Order
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Never, Item."Reordering Policy"::Order,
          RequisitionLine."Replenishment System"::Purchase, ReqWkshTemplate.Type::"Req.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqOptional1()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Prod. Order PLANNING Requisition Lines from Sales Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Fixed Reorder Qty.
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Fixed Reorder Qty.",
          RequisitionLine."Replenishment System"::"Prod. Order", ReqWkshTemplate.Type::Planning);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveSalesOrderPlanCopyToReqOptional2()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        // Check that Reservation Entries created when creating Transfer REQ Requisition Lines from Sales Order Planning
        // if Item.Reserve is Optional, Reserve field in Order Planning requisition line is TRUE and Item."Reordering Policy" is Lot-for-Lot.
        ReserveSalesOrderPlanCopyToReq(Item.Reserve::Optional, Item."Reordering Policy"::"Lot-for-Lot",
          RequisitionLine."Replenishment System"::Transfer, ReqWkshTemplate.Type::"Req.");
    end;

    local procedure ReserveSalesOrderPlanCopyToReq(Reserve: Enum "Reserve Method"; ReorderingPolicy: Enum "Reordering Policy"; ReplenishmentSystem: Enum "Replenishment System"; ReqWkshTemplateType: Enum "Req. Worksheet Template Type")
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ReservationEntry: Record "Reservation Entry";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ReqWkshTemplateName: Code[10];
        ReqWkshName: Code[10];
        Quantity: Decimal;
    begin
        // Setup : Create Sales Order and Calculate Plan
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemEx(Item, Reserve, ReorderingPolicy);
        Quantity := LibraryRandom.RandIntInRange(10, 20);
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);
        if ReplenishmentSystem <> Item."Replenishment System"::Purchase then
            ModifyRequisitionLine(RequisitionLine, Item.Reserve, ReplenishmentSystem);

        ReqWkshTemplateName := GetReqWkshTemplateName(ReqWkshTemplateType);
        ReqWkshName := GetReqWkshName(ReqWkshTemplateName, ReqWkshTemplateType);

        // Exercise : Run Make order from Order Planning.
        MakeSupplyOrdersCopyToWkshActiveOrder(SalesHeader."No.", ReqWkshTemplateName, ReqWkshName);

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        // 246 indicates reserved from requisition line
        VerifyReservationEntry(RequisitionLine, Item."No.", ReqWkshTemplateName, ReqWkshName, 246, Quantity);
        VerifyRequisitionLine(Item."No.", ReqWkshTemplateName, ReqWkshName);

        // Tear Down
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
        ReservationEntry.SetRange("Item No.", Item."No.");
        if ReservationEntry.FindSet() then
            repeat
                ReservationEntry.Delete();
            until ReservationEntry.Next() = 0;
        SalesHeader.Delete();
        SalesLine.SetRange("No.", Item."No.");
        SalesLine.FindFirst();
        SalesLine.Delete();
        Item.Delete();
    end;

    local procedure VerifyReservationEntry(RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; SourceID: Code[10]; SourceBatchName: Code[10]; SourceType: Integer; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        if RequisitionLine.Reserve then begin
            ReservationEntry.SetRange("Item No.", ItemNo);
            ReservationEntry.SetRange("Source ID", SourceID);
            ReservationEntry.SetRange("Source Type", SourceType);
            ReservationEntry.SetRange("Source Batch Name", SourceBatchName);
            ReservationEntry.FindFirst();

            Assert.AreEqual(
              Qty, ReservationEntry.Quantity,
              StrSubstNo(ValidationError, ReservationEntry.FieldCaption(Quantity), Qty, ReservationEntry.TableCaption()));
        end else begin
            // Verify : Check That Reservation Entry Not Created after Make Supply Order.
            ReservationEntry.SetRange("Item No.", ItemNo);
            asserterror ReservationEntry.FindFirst();
        end;
    end;

    local procedure VerifyRequisitionLine(ItemNo: Code[20]; WkshTemplateName: Code[10]; JournalBatchName: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", WkshTemplateName);
        RequisitionLine.SetRange("Journal Batch Name", JournalBatchName);
        RequisitionLine.SetRange("No.", ItemNo);
        Assert.IsTrue(RequisitionLine.FindFirst(), StrSubstNo(LineExistErr, WkshTemplateName, ItemNo));
    end;

    local procedure ModifyRequisitionLine(var RequisitionLine: Record "Requisition Line"; Reserve: Enum "Reserve Method"; ReplenishmentSystem: Enum "Replenishment System")
    var
        Item: Record Item;
    begin
        if Reserve = Item.Reserve::Optional then
            RequisitionLine.Reserve := true;
        RequisitionLine.Validate("Replenishment System", ReplenishmentSystem);
        if ReplenishmentSystem = RequisitionLine."Replenishment System"::Transfer then
            RequisitionLine.Validate("Supply From", LocationRed.Code);
        RequisitionLine.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReplenishmentToPurchAndCheckComponent()
    var
        Item: Record Item;
    begin
        // Check That Planning Component and Planning Routing Line created after change replenishment to Production Order.
        Initialize();
        ChangeReplenishmentAndCheckComponent(Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReplenishmentToProdAndCheckComponent()
    var
        Item: Record Item;
    begin
        // Check That Planning Component and Planning Routing Line Delete after change replenishment to Purchase Order.
        Initialize();
        ChangeReplenishmentAndCheckComponent(Item."Replenishment System"::Purchase);
    end;

    local procedure ChangeReplenishmentAndCheckComponent(ReplenishmentSystem: Enum "Replenishment System")
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        PlanningRoutingLine: Record "Planning Routing Line";
        ItemVendor: Record "Item Vendor";
        Quantity: Decimal;
    begin
        // Setup : Create Item With Reservation Option and Create Sales Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(Item, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Modify(true);

        Quantity := LibraryRandom.RandDec(10, 2);  // Random Value Required.

        LibraryInventory.CreateItemVendor(ItemVendor, LibraryPurchase.CreateVendorNo(), Item."No.");

        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);

        if ReplenishmentSystem = Item."Replenishment System"::Purchase then begin
            ChangeReplenishmentSystem(
              RequisitionLine, ReplenishmentSystem, Item."Replenishment System"::"Prod. Order", SalesHeader."No.", ItemVendor."Vendor No.");

            // Verify : Check That Planning Component and Planning Routing Line created after change replenishment to Production Order.
            FindPlanningComponent(PlanningComponent, RequisitionLine);
            FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        end else begin
            ChangeReplenishmentSystem(
              RequisitionLine, ReplenishmentSystem, Item."Replenishment System"::Purchase, SalesHeader."No.", ItemVendor."Vendor No.");

            // Verify : Check That Planning Component and Planning Routing Line Delete after change replenishment to Purchase Order.
            FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
            Assert.AreEqual(0, PlanningRoutingLine.Count, StrSubstNo(LineCountError, 0));
            FindPlanningComponent(PlanningComponent, RequisitionLine);
            Assert.AreEqual(0, PlanningComponent.Count, StrSubstNo(LineCountError, 0));
        end;

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningSalesOrderWithItemVariant()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemVariant: Record "Item Variant";
    begin
        // Setup : Create Item, Item Variant, Sale Order And Calculate Plan.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateSalesOrder(
          SalesHeader, Item."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Variant Code"), ItemVariant.Code);

        // Exercise : Calculate Plan.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check That Item Variant code on Order Planning Line is same as on Sales Line.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue.Code);
        RequisitionLine.TestField("Variant Code", ItemVariant.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderPurchaseItemWithVariant()
    var
        Item: Record Item;
    begin
        // Check That Purchase Line Created form Make Order have same Variant Cade as on Sales Line.
        Initialize();
        MakeOrderWithItemVariant(Item."Replenishment System"::Purchase);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MakeOrderProductionItemWithVariant()
    var
        Item: Record Item;
    begin
        // Check That Production Order Line Created form Make Order have same Variant Cade as on Sales Line.
        Initialize();
        MakeOrderWithItemVariant(Item."Replenishment System"::"Prod. Order");
    end;

    local procedure MakeOrderWithItemVariant(ReplenishmentSystem: Enum "Replenishment System")
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemVariant: Record "Item Variant";
        ProdOrderLine: Record "Prod. Order Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup : Create Item, Item Variant, Sale Order And Calculate Plan.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, ReplenishmentSystem, '', '');
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateSalesOrder(SalesHeader, Item."No.", '', LibraryRandom.RandDec(10, 2) + 10, LibraryRandom.RandDec(10, 2));  // Random Value Required.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Variant Code"), ItemVariant.Code);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Order for Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        if ReplenishmentSystem = Item."Replenishment System"::Purchase then begin
            // Verify : Check That Purchase Line Created form Make Order have same Variant Cade as on Sales Line.
            PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
            PurchaseLine.SetRange("No.", Item."No.");
            PurchaseLine.FindFirst();
            PurchaseLine.TestField("Variant Code", ItemVariant.Code);
        end else begin
            // Verify : Check That Production Order Line Created form Make Order have same Variant Cade as on Sales Line.
            ProdOrderLine.SetRange("Item No.", Item."No.");
            ProdOrderLine.FindFirst();
            ProdOrderLine.TestField("Variant Code", ItemVariant.Code);
        end;

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeQuantityAndCalculatePlan()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        OrderPlanning: TestPage "Order Planning";
        OrderPlanning2: TestPage "Order Planning";
        Quantity: Decimal;
    begin
        // Setup : Create Item ,Sale order and Calculate Plan and Open Order Planning Page ,Change Quantity To Order close Order Planning Page and Calculate Plan.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue2.Code, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        ChangeQuantityOnPlanning(OrderPlanning, SalesHeader."No.", Item."No.", Quantity + LibraryRandom.RandDec(10, 2));  // Random Value Required.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Open Order Planning Page.
        OpenOrderPlanningPage(OrderPlanning2, SalesHeader."No.", Item."No.");

        // Verify : Check the value of Quantity To Order is Change to Previous State after calculate Plan.
        OrderPlanning2.Quantity.AssertEquals(Quantity);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseSpecialOrderUpdateCurrencyRetainsTheSameUnitOfMeasure()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Unit of Measure] [Special Order]
        // [SCENARIO 207135] Updating of "Currency Code" in the Header of Purchase Order related with Sales Order with Special Order "Purchasing Code" retains the same "Unit of Measure Code" as it was created during Carry Out Action Message
        Initialize();

        // [GIVEN] Item "I" with "Vendor No." and "Purch. Unit of Measure";
        CreateItemWithVendorNoAndPurchUnitOfMeasure(Item);

        // [GIVEN] Sales Order "SO" with single line "SL" for "I" with Special Order "Purchasing Code"
        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Purchasing.Code);

        // [GIVEN] Get special order and carry out for "I", Purchase Order "PO" with line "PL" is created;
        GetPurchaseSpecialOrderAtWorkdateByItemNo(PurchaseHeader, PurchaseLine, Item."No.");

        // [WHEN] Update Currency Code for "PO" through the Header
        UpdatePurchaseHeaderCurrencyCode(PurchaseHeader);

        // [THEN] "PL"."Unit of Measure Code" = "SL"."Unit of Measure Code", "PL"."Quantity (Base)" = "SL"."Quantity (Base)"
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.FindFirst();  // Cannot use GET because one of the key fields "Line No." could be changed while line recreation
        VerifyPurchaseLineUnitOfMeasureCodeAndQuantityBase(
          PurchaseLine, SalesLine."Unit of Measure Code", SalesLine."Quantity (Base)");
    end;

    [Test]
    [HandlerFunctions('ConfirmHandler')]
    [Scope('OnPrem')]
    procedure PurchaseDropShipmentUpdateCurrencyRetainsTheSameUnitOfMeasure()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Purchasing: Record Purchasing;
    begin
        // [FEATURE] [Unit of Measure] [Special Order]
        // [SCENARIO 207135] Updating of "Currency Code" in the Header of Purchase Order related with Sales Order with Drop Shipment "Purchasing Code" retains the same "Unit of Measure Code" as it was created during Carry Out Action Message
        Initialize();

        // [GIVEN] Item "I" with "Vendor No." and "Purch. Unit of Measure";
        CreateItemWithVendorNoAndPurchUnitOfMeasure(Item);

        // [GIVEN] Sales Order "SO" with single line "SL" for "I" with Special Order "Purchasing Code"
        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);
        CreateSalesOrderWithPurchasingCode(SalesHeader, SalesLine, Item."No.", Purchasing.Code);

        // [GIVEN] Get drop shipment and carry out for "I", Purchase Order "PO" with line "PL" is created;
        GetPurchaseDropShipmentAtWorkdateByItemNo(PurchaseHeader, PurchaseLine, SalesLine);

        // [WHEN] Update Currency Code for "PO" through the Header
        UpdatePurchaseHeaderCurrencyCode(PurchaseHeader);

        // [THEN] "PL"."Unit of Measure Code" = "SL"."Unit of Measure Code", "PL"."Quantity (Base)" = "SL"."Quantity (Base)"
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseLine."Document No.");
        PurchaseLine.FindFirst();  // Cannot use GET because one of the key fields "Line No." could be changed while line recreation
        VerifyPurchaseLineUnitOfMeasureCodeAndQuantityBase(
          PurchaseLine, SalesLine."Unit of Measure Code", SalesLine."Quantity (Base)");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeletePlanningLinesIfMakingPurchaseFromSalesIsDeclinedByUser()
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
    begin
        // [FEATURE] [Sales] [Purchase] [Order]
        // [SCENARIO 287131] Delete planning lines generated by "Purchase Order from Sales Order" functionality, if a user does not confirm creating a new purchase order.
        Initialize();

        // [GIVEN] Sales order.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          LibraryInventory.CreateItemNo(), LibraryRandom.RandIntInRange(100, 200), '', WorkDate());

        // [WHEN] Run "Create Purchase Order" on sales order page, but do not confirm making a new purchase order.
        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", false);

        // [THEN] Requisition lines that were created during planning are deleted.
        ReqLine.SetRange("Worksheet Template Name", '');
        ReqLine.SetRange("User ID", UserId);
        Assert.RecordIsEmpty(ReqLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CanCreatePurchaseOrderFromSalesForNonInventoryItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Sales] [Purchase] [Order] [Non-Inventory Item]
        // [SCENARIO 315342] A user can create purchase order from a sales order with non-inventory item.
        Initialize();

        LibraryInventory.CreateNonInventoryTypeItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", true);

        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseHeader.TestField("Buy-from Vendor No.", Item."Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningLinesByAnotherUserAreNotConsideredInOrderPlanning()
    var
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: array[2] of Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Sales] [Purchase] [Order]
        // [SCENARIO 325237] Planning lines generated by "Purchase Order from Sales Order" functionality by another user, are not taken into consideration.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Two sales orders "SO1", "SO2".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader[1], SalesLine[1], SalesHeader[1]."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(10, 20), '', WorkDate());

        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader[2], SalesLine[2], SalesHeader[2]."Document Type"::Order, '',
          Item."No.", LibraryRandom.RandIntInRange(30, 60), '', WorkDate());

        // [GIVEN] User "A":
        // [GIVEN] Create purchase order from sales order "SO1".
        CreatePurchaseOrderFromSalesOrder(SalesHeader[1]."No.", true);

        RequisitionLine.SetRange("Worksheet Template Name", '');
        RequisitionLine.ModifyAll("User ID", LibraryUtility.GenerateGUID());

        // [GIVEN] User "B":
        // [WHEN] Create purchase order from sales order "SO2".
        CreatePurchaseOrderFromSalesOrder(SalesHeader[2]."No.", true);

        // [THEN] Second purchase order is created.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.RecordCount(PurchaseHeader, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OtherBlockedItemDoesNotPreventCreatePurchaseFromSales()
    var
        BlockedItem: Record Item;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Item] [Sales] [Purchase] [Order]
        // [SCENARIO 337908] Other blocked items do not interfere with creating purchase from sales.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Items "A" and "B".
        LibraryInventory.CreateItem(BlockedItem);
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Sales order for item "A".
        // [GIVEN] Sales order for item "B".
        CreateSalesOrder(SalesHeader, BlockedItem."No.", '', Qty, Qty);
        CreateSalesOrder(SalesHeader, Item."No.", '', Qty, Qty);

        // [GIVEN] Block item "A".
        BlockedItem.Validate(Blocked, true);
        BlockedItem.Modify(true);

        // [WHEN] Run "Create Purchase Order" from the sales order for item "B".
        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", true);

        // [THEN] A new purchase order for "B" is successfully created.
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseHeader.TestField("Buy-from Vendor No.", Item."Vendor No.");

        // Tear down.
        BlockedItem.Validate(Blocked, false);
        BlockedItem.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningTwoSalesOrdersOneSupplyCoversBoth()
    var
        Item: Record Item;
        SalesHeader: array[2] of Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: array[2] of Decimal;
    begin
        // [FEATURE] [Item] [Sales] [Purchase] [Order]
        // [SCENARIO 348685] Planning sales order using "Purchase Order from Sales Order" functionality does not suggest purchasing when a purchase has already been planned for this sales order.
        Initialize();
        Qty[1] := LibraryRandom.RandIntInRange(50, 100);
        Qty[2] := LibraryRandom.RandInt(10);

        // [GIVEN] Item with vendor no.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] First sales order for 50 pcs.
        // [GIVEN] Plan a purchase from the sales.
        // [GIVEN] Purchase order for 50 pcs is created.
        CreateSalesOrder(SalesHeader[1], Item."No.", '', Qty[1], Qty[1]);
        CreatePurchaseOrderFromSalesOrder(SalesHeader[1]."No.", true);
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.TestField(Quantity, Qty[1]);

        // [GIVEN] Second sales order for 10 pcs on a later date.
        CreateSalesOrder(SalesHeader[2], Item."No.", '', Qty[2], Qty[2]);
        FindSalesLine(SalesLine, SalesHeader[2], Item."No.");
        UpdateSalesLine(SalesLine, SalesLine.FieldNo("Shipment Date"), LibraryRandom.RandDateFrom(SalesLine."Shipment Date", 10));

        // [WHEN] Plan a purchase from the first sales again.
        CreatePurchaseOrderFromSalesOrder(SalesHeader[1]."No.", true);

        // [THEN] No new purchase order is suggested as the first sales order is considered supplied.
        PurchaseHeader.SetRange("Buy-from Vendor No.", Item."Vendor No.");
        Assert.RecordCount(PurchaseHeader, 1);

        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.CalcSums(Quantity);
        PurchaseLine.TestField(Quantity, Qty[1]);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderOfLineIsKeptOnPurchaseOrderFromSalesOrder()
    var
        Item: array[2] of Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        Qty: Decimal;
        i: Integer;
    begin
        // [FEATURE] [Sales] [Purchase] [Order]
        // [SCENARIO 353546] Line order is the same in sales order and purchase order created from it with "Purchase Order from Sales Order" functionality.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Two items with vendor - "I1" and "I2".
        for i := 1 to ArrayLen(Item) do begin
            LibraryInventory.CreateItem(Item[i]);
            Item[i].Validate("Vendor No.", VendorNo);
            Item[i].Modify(true);
        end;

        // [GIVEN] Sales order with two lines. The first line is for item "I1" on location "BLUE", the second one is for item "I2" on blank location.
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item[1]."No.", Qty, LocationBlue.Code, WorkDate());
        CreateSalesLine(SalesHeader, Item[2]."No.", '', WorkDate(), Qty, Qty);

        // [WHEN] Create purchase order from the sales order.
        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", true);

        // [THEN] The line order in the purchase order ("I1", "I2") matches the sales order.
        PurchaseHeader.SetRange("Buy-from Vendor No.", VendorNo);
        PurchaseHeader.FindFirst();
        LibraryPurchase.FindFirstPurchLine(PurchaseLine, PurchaseHeader);
        PurchaseLine.TestField("No.", Item[1]."No.");
        PurchaseLine.Next();
        PurchaseLine.TestField("No.", Item[2]."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchOrderCreatedForItemWithParanthesisInNoField()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        VendorNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Sales] [Purchase] [Order]
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        VendorNo := LibraryPurchase.CreateVendorNo();

        // [GIVEN] Item with vendor and No. has ( and ) characters.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", VendorNo);
        Item.Modify(true);
        Item.Rename(StrSubstNo('%1(1)', CopyStr(Item."No.", 1, MaxStrLen(Item."No.") - 3)));

        // [GIVEN] Sales order with a line for breated item on location "BLUE".
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", Qty, LocationBlue.Code, WorkDate());

        // [WHEN] Create purchase order from the sales order.
        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", true);

        // [THEN] The line in the purchase order matches the sales order.
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewBatchNoOnOrderPlanningFirstTime()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Order Planning] [Requisition Line] [UT]
        // [SCENARIO 358664] New batch name on Order Planning for the first time.
        Initialize();

        RequisitionLine.DeleteAll();

        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        RequisitionLine.SetRange("Journal Batch Name", '0');
        Assert.RecordIsNotEmpty(RequisitionLine);

        RequisitionLine.SetFilter("Journal Batch Name", '<>%1', '0');
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewBatchNoOnOrderPlanningHavingBlankBatchNoLines()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Order Planning] [Requisition Line] [UT]
        // [SCENARIO 358664] New batch name on Order Planning when earlier created planning lines with blank batch name exist.
        Initialize();

        RequisitionLine.DeleteAll();

        RequisitionLine.Init();
        RequisitionLine."Line No." := LibraryUtility.GetNewRecNo(RequisitionLine, RequisitionLine.FieldNo("Line No."));
        RequisitionLine.Insert();

        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Journal Batch Name", '0');
        Assert.RecordIsNotEmpty(RequisitionLine);

        RequisitionLine.SetFilter("Journal Batch Name", '<>%1', '0');
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NewBatchNoOnOrderPlanningHavingOtherUserLines()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Order Planning] [Requisition Line] [UT]
        // [SCENARIO 358664] New batch name on Order Planning when planning lines created by another user exist.
        Initialize();

        RequisitionLine.DeleteAll();

        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        RequisitionLine.ModifyAll("User ID", LibraryUtility.GenerateGUID());

        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Journal Batch Name", '1');
        Assert.RecordIsNotEmpty(RequisitionLine);

        RequisitionLine.SetFilter("Journal Batch Name", '<>%1', '1');
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RunningOrderPlanningTwiceForDifferentSources()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [Order Planning] [Requisition Line] [UT]
        // [SCENARIO 358664] Find batch name on Order Planning when planning lines created for another source exist.
        Initialize();

        RequisitionLine.DeleteAll();

        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        RequisitionLine.FindLast();

        RequisitionLine.SetFilter("Line No.", '>%1', RequisitionLine."Line No.");
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Journal Batch Name", '0');
        Assert.RecordIsNotEmpty(RequisitionLine);

        RequisitionLine.SetFilter("Journal Batch Name", '<>%1', '0');
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    procedure OtherBlockedItemVariantDoesNotPreventCreatePurchaseFromSales()
    var
        Item: Record Item;
        Item2: Record Item;
        ItemVariant: Record "Item Variant";
        SalesHeader: Record "Sales Header";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Variant] [Sales] [Purchase] [Order]
        // [SCENARIO] Other blocked item variants do not interfere with creating purchase from sales.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Items "A" and "B".
        LibraryInventory.CreateItemVariant(ItemVariant, LibraryInventory.CreateItem(Item));
        LibraryInventory.CreateItem(Item2);
        Item2.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item2.Modify(true);

        // [GIVEN] Sales order for item "A" with variant I.
        // [GIVEN] Sales order for item "B".
        CreateSalesOrderWithItemVariant(SalesHeader, Item."No.", ItemVariant.Code, '', Qty, Qty);
        CreateSalesOrder(SalesHeader, Item2."No.", '', Qty, Qty);

        // [GIVEN] Block item variant "I".
        ItemVariant.Validate(Blocked, true);
        ItemVariant.Modify(true);

        // [WHEN] Run "Create Purchase Order" from the sales order for item "B".
        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", true);

        // [THEN] A new purchase order for "B" is successfully created.
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item2."No.");
        PurchaseHeader.TestField("Buy-from Vendor No.", Item2."Vendor No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingPlanningComponentsForOrderPlanningLine()
    var
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
    begin
        // [FEATURE] [Order Planning] [Requisition Line] [Planning Component] [UT]
        // [SCENARIO 358664] Create planning component for Order Planning line with non-blank batch name.
        Initialize();

        RequisitionLine.Init();
        RequisitionLine."Journal Batch Name" := LibraryUtility.GenerateGUID();
        RequisitionLine."Line No." := LibraryUtility.GetNewRecNo(RequisitionLine, RequisitionLine.FieldNo("Line No."));
        RequisitionLine."Planning Line Origin" := RequisitionLine."Planning Line Origin"::"Order Planning";
        RequisitionLine.Insert();

        LibraryPlanning.CreatePlanningComponent(PlanningComponent, RequisitionLine);

        PlanningComponent.TestField("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreatingPlanningRoutingLineForOrderPlanningLine()
    var
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
    begin
        // [FEATURE] [Order Planning] [Requisition Line] [Planning Routing Line] [UT]
        // [SCENARIO 358664] Create planning routing line for Order Planning line with non-blank batch name.
        Initialize();

        RequisitionLine.Init();
        RequisitionLine."Journal Batch Name" := LibraryUtility.GenerateGUID();
        RequisitionLine."Line No." := LibraryUtility.GetNewRecNo(RequisitionLine, RequisitionLine.FieldNo("Line No."));
        RequisitionLine."Planning Line Origin" := RequisitionLine."Planning Line Origin"::"Order Planning";
        RequisitionLine.Insert();

        LibraryManufacturing.CreatePlanningRoutingLine(PlanningRoutingLine, RequisitionLine, LibraryUtility.GenerateGUID());

        PlanningRoutingLine.TestField("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandServiceSupplyProdOrder()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Service Order] [Production Order]
        // [SCENARIO 364274] Order-to-Order reservation is established when production order supplying service order is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I" that is replenished by production order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        // [GIVEN] Service order with service line for item "I".
        CreateServiceOrder(ServiceHeader, ServiceLine, Item."No.");

        // [GIVEN] Calculate Order Planning for service orders.
        LibraryPlanning.CalculateOrderPlanService(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        FindRequisitionLine(RequisitionLine, ServiceHeader."No.", Item."No.", '');
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make a production order to supply the service line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [THEN] The service line is now reserved from production order with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.",
          DATABASE::"Prod. Order Line");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandServiceSupplyTransfer()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        TransferRoute: Record "Transfer Route";
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Service Order] [Transfer Order]
        // [SCENARIO 364274] Order-to-Order reservation is established when transfer order supplying service order is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Locations "From", "To" with a transfer route between them.
        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location[1].Code, Location[2].Code, Location[3].Code, '', '');

        // [GIVEN] Service order with service line for item "I" at location "To".
        CreateServiceOrder(ServiceHeader, ServiceLine, Item."No.");
        ServiceLine.Validate("Location Code", Location[2].Code);
        ServiceLine.Modify(true);

        // [GIVEN] Calculate Order Planning for service orders.
        LibraryPlanning.CalculateOrderPlanService(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        // [GIVEN] Set replenishment system on the planning line to "Transfer" and select a source location "From".
        FindRequisitionLine(RequisitionLine, ServiceHeader."No.", Item."No.", Location[2].Code);
        RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Transfer);
        RequisitionLine.Validate("Supply From", Location[1].Code);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make a transfer order to supply the service line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [THEN] The service line is now reserved from transfer order with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.",
          DATABASE::"Transfer Line");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandServiceSupplyAssembly()
    var
        Item: Record Item;
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Service Order] [Assembly Order]
        // [SCENARIO 364274] Order-to-Order reservation is established when assembly order supplying service order is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I" that is replenished by assembly order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Modify(true);

        // [GIVEN] Service order with service line for item "I".
        CreateServiceOrder(ServiceHeader, ServiceLine, Item."No.");

        // [GIVEN] Calculate Order Planning for service orders.
        LibraryPlanning.CalculateOrderPlanService(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        FindRequisitionLine(RequisitionLine, ServiceHeader."No.", Item."No.", '');
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make an assembly order to supply the service line.
        GetManufacturingUserTemplate(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order", "Planning Create Prod. Order"::" ");
        ManufacturingUserTemplate.Validate(
          "Create Assembly Order", ManufacturingUserTemplate."Create Assembly Order"::"Make Assembly Orders");
        ManufacturingUserTemplate.Modify(true);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);

        // [THEN] The service line is now reserved from assembly order with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Service Line", ServiceLine."Document Type".AsInteger(), ServiceLine."Document No.", ServiceLine."Line No.",
          DATABASE::"Assembly Header");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandAssemblySupplyRequisitionLine()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Assembly Order] [Requisition Line]
        // [SCENARIO 364274] Order-to-Order reservation is established when requisition line supplying assembly line is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I" that is replenished by production order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        // [GIVEN] Make item "I" a component of a parent item "P" and create assembly order for "P".
        LibraryInventory.CreateBOMComponent(
          BOMComponent, LibraryInventory.CreateItemNo(), BOMComponent.Type::Item, Item."No.", 1, Item."Base Unit of Measure");
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, WorkDate() + 10, BOMComponent."Parent Item No.", '', LibraryRandom.RandInt(10), '');
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.FindFirst();

        // [GIVEN] Calculate Order Planning for assembly lines.
        LibraryPlanning.CalculateOrderPlanAssembly(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        FindRequisitionLine(RequisitionLine, AssemblyLine."Document No.", Item."No.", '');
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make a line in requisition worksheet to supply the assembly line.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        GetManufacturingUserTemplate(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Prod. Req. Wksh. Template", RequisitionWkshName."Worksheet Template Name");
        ManufacturingUserTemplate.Validate("Prod. Wksh. Name", RequisitionWkshName.Name);
        ManufacturingUserTemplate.Modify(true);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);

        // [THEN] The assembly line is now reserved from requisition worksheet line with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.",
          DATABASE::"Requisition Line");
        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandJobSupplyProdOrder()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Job Planning Line] [Production Order]
        // [SCENARIO 371276] Order-to-Order reservation is established when production order supplying job planning line is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I" that is replenished by production order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Modify(true);

        // [GIVEN] Job, Job Task and Job Planning Line for item "I".
        CreateJobPlanningLine(JobPlanningLine, Item."No.", '');

        // [GIVEN] Calculate Order Planning for job planning lines.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", '');
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make a production order to supply the job planning line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [THEN] The job planning line is now reserved from production order with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.",
          DATABASE::"Prod. Order Line");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandJobSupplyTransfer()
    var
        Item: Record Item;
        Location: array[3] of Record Location;
        TransferRoute: Record "Transfer Route";
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Job Planning Line] [Transfer Order]
        // [SCENARIO 371276] Order-to-Order reservation is established when transfer order supplying job planning line is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I".
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Locations "From", "To" with a transfer route between them.
        LibraryWarehouse.CreateTransferLocations(Location[1], Location[2], Location[3]);
        LibraryWarehouse.CreateAndUpdateTransferRoute(TransferRoute, Location[1].Code, Location[2].Code, Location[3].Code, '', '');

        // [GIVEN] Job, Job Task and Job Planning Line for item "I" at location "To".
        CreateJobPlanningLine(JobPlanningLine, Item."No.", Location[2].Code);

        // [GIVEN] Calculate Order Planning for job planning lines.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        // [GIVEN] Set replenishment system on the planning line to "Transfer" and select a source location "From".
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", Location[2].Code);
        RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Transfer);
        RequisitionLine.Validate("Supply From", Location[1].Code);
        RequisitionLine.Validate("Starting Date", WorkDate());
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make a transfer order to supply the job planning line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [THEN] The job planning line is now reserved from transfer order with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.",
          DATABASE::"Transfer Line");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandJobSupplyAssembly()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Job Planning Line] [Assembly Order]
        // [SCENARIO 371276] Order-to-Order reservation is established when assembly order supplying job planning line is created from Order Planning.
        Initialize();

        // [GIVEN] Item "I" that is replenished by assembly order.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::Assembly);
        Item.Modify(true);

        // [GIVEN] Job, Job Task and Job Planning Line for item "I".
        CreateJobPlanningLine(JobPlanningLine, Item."No.", '');

        // [GIVEN] Calculate Order Planning for job planning lines.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", '');
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make an assembly order to supply the job planning line.
        GetManufacturingUserTemplate(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order", "Planning Create Prod. Order"::" ");
        ManufacturingUserTemplate.Validate(
          "Create Assembly Order", ManufacturingUserTemplate."Create Assembly Order"::"Make Assembly Orders");
        ManufacturingUserTemplate.Modify(true);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);

        // [THEN] The job planning line is now reserved from assembly order with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.",
          DATABASE::"Assembly Header");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReserveOrderPlanningDemandJobSupplyRequisitionLine()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        ItemJournalLine: Record "Item Journal Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // [FEATURE] [Order Planning] [Reservation] [Binding] [Job Planning Line] [Requisition Line]
        // [SCENARIO 371276] Order-to-Order reservation is established when requisition line supplying job planning line is created from Order Planning.
        // [SCENARIO 454609] Reserved Quantity on requisition line does not exceed Quantity.
        Initialize();

        // [GIVEN] Item "I" that is replenished by production order.
        // [GIVEN] Set Reserve = Always.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        // [GIVEN] Job, Job Task and Job Planning Line for 20 pcs of item "I".
        CreateJobPlanningLine(JobPlanningLine, Item."No.", '');

        // [GIVEN] Post 5 pcs of item "I" to inventory.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', LibraryRandom.RandInt(10));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Calculate Order Planning for job planning lines.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find a planning line for item "I" and set "Reserve" = TRUE on it.
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", '');
        RequisitionLine.Validate(Reserve, true);
        RequisitionLine.Modify(true);

        // [WHEN] Make a line in requisition worksheet to supply the job planning line.
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::"Req.");
        GetManufacturingUserTemplate(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Prod. Req. Wksh. Template", RequisitionWkshName."Worksheet Template Name");
        ManufacturingUserTemplate.Validate("Prod. Wksh. Name", RequisitionWkshName.Name);
        ManufacturingUserTemplate.Modify(true);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);

        // [THEN] The job planning line is now reserved from requisition worksheet line with "Order-to-Order" binding.
        VerifyOrderToOrderBindingOnReservEntry(
          DATABASE::"Job Planning Line", JobPlanningLine.Status.AsInteger(), JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.",
          DATABASE::"Requisition Line");

        // [THEN] Reserved quantity on the requisition worksheet line = 15 pcs.
        RequisitionLine.Reset();
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.CalcFields("Reserved Quantity");
        RequisitionLine.TestField("Reserved Quantity", RequisitionLine.Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateRunTimeOnPlanRoutingLineWhenRoutingWithOneLine()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        AdditionalRunTime: Decimal;
        PlanningLineStartTime: Time;
        PlanningLineEndTime: Time;
    begin
        // [FEATURE] [Requisition Line]
        // [SCENARIO 377015] Update "Run Time" for Planning Routing Line when Routing contains only one line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 5.
        // [GIVEN] Work Center with operational hours 08:00 - 16:00, it works 8 hours per day.
        CreateProductionItemWithOneLineRouting(Item, 20200122D);

        // [GIVEN] Requisition Line for Item "I" with Quantity = 10, that was refreshed in Forward direction. Starting Date is 21.01.20, Starting Time is 09:00.
        // [GIVEN] Planning Routing Line with Operation "10" and "Run Time" = 5 is created. Starting Time is 09:00, Ending Time is 09:50.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200121D, 090000T);
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningLineStartTime := PlanningRoutingLine."Starting Time";
        PlanningLineEndTime := PlanningRoutingLine."Ending Time";
        AdditionalRunTime := LibraryRandom.RandDecInRange(5, 10, 2);

        // [WHEN] Set "Run Time" = 15 for Planning Routing Line.
        PlanningRoutingLine.Validate("Run Time", PlanningRoutingLine."Run Time" + AdditionalRunTime);
        PlanningRoutingLine.Modify(true);

        // [THEN] Ending Time for Requisition Line was updated to (09:00 + 10 * 15) = 11:30.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        VerifyRequisitionLineStartEndDateTime(
          RequisitionLine, CreateDateTime(20200121D, PlanningLineStartTime),
          CreateDateTime(20200121D, PlanningLineEndTime + AdditionalRunTime * 10 * 60000));

        // [THEN] Ending Time for Planning Routing Line was updated to (09:00 + 10 * 15) = 11:30.
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, PlanningLineStartTime),
          CreateDateTime(20200121D, PlanningLineEndTime + AdditionalRunTime * 10 * 60000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateSetupTimeOnPlanRoutingLineWhenRoutingWithOneLine()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        AdditionalSetupTime: Decimal;
        PlanningLineStartTime: Time;
        PlanningLineEndTime: Time;
    begin
        // [FEATURE] [Requisition Line]
        // [SCENARIO 377015] Update "Setup Time" for Planning Routing Line when Routing contains only one line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 5, "Setup Time" = 5.
        // [GIVEN] Work Center with operational hours 08:00 - 16:00, it works 8 hours per day.
        CreateProductionItemWithOneLineRouting(Item, 20200122D);

        // [GIVEN] Requisition Line for Item "I" with Quantity = 10, that was refreshed in Forward direction. Starting Date is 21.01.20, Starting Time is 09:00.
        // [GIVEN] Planning Routing Line with Operation "10", "Setup Time" = 5 and "Run Time" = 5 is created. Starting Time is 09:00, Ending Time is 09:55.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200121D, 090000T);
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningLineStartTime := PlanningRoutingLine."Starting Time";
        PlanningLineEndTime := PlanningRoutingLine."Ending Time";
        AdditionalSetupTime := LibraryRandom.RandDecInRange(5, 10, 2);

        // [WHEN] Set "Setup Time" = 15 for Planning Routing Line.
        PlanningRoutingLine.Validate("Setup Time", PlanningRoutingLine."Setup Time" + AdditionalSetupTime);
        PlanningRoutingLine.Modify(true);

        // [THEN] Ending Time for Requisition Line was updated to (09:00 + 10 * 5 + 15) = 10:05.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        VerifyRequisitionLineStartEndDateTime(
          RequisitionLine, CreateDateTime(20200121D, PlanningLineStartTime),
          CreateDateTime(20200121D, PlanningLineEndTime + AdditionalSetupTime * 60000));

        // [THEN] Ending Time for Planning Routing Line was updated to (09:00 + 10 * 15) = 11:30.
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, PlanningLineStartTime),
          CreateDateTime(20200121D, PlanningLineEndTime + AdditionalSetupTime * 60000));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateStartingTimeOnPlanRoutingLineWhenRoutingWithOneLine()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        TimeShiftMs: Integer;
        PlanningLineStartTime: Time;
        PlanningLineEndTime: Time;
    begin
        // [FEATURE] [Requisition Line]
        // [SCENARIO 377015] Update "Starting Date-Time" for Planning Routing Line when Routing contains only one line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 5.
        // [GIVEN] Work Center with operational hours 08:00 - 16:00, it works 8 hours per day.
        CreateProductionItemWithOneLineRouting(Item, 20200122D);

        // [GIVEN] Requisition Line for Item "I" with Quantity = 10, that was refreshed in Forward direction. Starting Date is 21.01.20, Starting Time is 09:00.
        // [GIVEN] Planning Routing Line with Operation "10" and "Run Time" = 5 is created. Starting Time is 09:00, Ending Time is 09:50.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200121D, 090000T);
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningLineStartTime := PlanningRoutingLine."Starting Time";
        PlanningLineEndTime := PlanningRoutingLine."Ending Time";
        TimeShiftMs := 2 * 3600000;

        // [WHEN] Set "Starting Date-Time" = 11:00 for Planning Routing Line.
        PlanningRoutingLine.Validate("Starting Date-Time", CreateDateTime(20200121D, PlanningLineStartTime + TimeShiftMs));
        PlanningRoutingLine.Modify(true);

        // [THEN] Starting Time and Ending Time for Requisition Line were updated to 11:00 and 11:50 respectively.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        VerifyRequisitionLineStartEndDateTime(
          RequisitionLine, CreateDateTime(20200121D, PlanningLineStartTime + TimeShiftMs),
          CreateDateTime(20200121D, PlanningLineEndTime + TimeShiftMs));

        // [THEN] Starting Time and Ending Time for Planning Routing Line were updated to 11:00 and 11:50 respectively.
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, PlanningLineStartTime + TimeShiftMs),
          CreateDateTime(20200121D, PlanningLineEndTime + TimeShiftMs));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UpdateEndingTimeOnPlanRoutingLineWhenRoutingWithOneLine()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PlanningRoutingLine: Record "Planning Routing Line";
        TimeShiftMs: Integer;
        PlanningLineStartTime: Time;
        PlanningLineEndTime: Time;
    begin
        // [FEATURE] [Requisition Line]
        // [SCENARIO 377015] Update "Ending Date-Time" for Planning Routing Line when Routing contains only one line.
        Initialize();

        // [GIVEN] Production Item "I" with Serial Routing with one Routing Line with "Run Time" = 5.
        // [GIVEN] Work Center with operational hours 08:00 - 16:00, it works 8 hours per day.
        CreateProductionItemWithOneLineRouting(Item, 20200122D);

        // [GIVEN] Requisition Line for Item "I" with Quantity = 10, that was refreshed in Forward direction. Starting Date is 21.01.20, Starting Time is 09:00.
        // [GIVEN] Planning Routing Line with Operation "10" and "Run Time" = 5 is created. Starting Time is 09:00, Ending Time is 09:50.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, Item."No.", 10, 20200121D, 090000T);
        FindFirstPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningLineStartTime := PlanningRoutingLine."Starting Time";
        PlanningLineEndTime := PlanningRoutingLine."Ending Time";
        TimeShiftMs := 2 * 3600000;

        // [WHEN] Set "Ending Date-Time" = 11:50 for Planning Routing Line.
        PlanningRoutingLine.Validate("Ending Date-Time", CreateDateTime(20200121D, PlanningLineEndTime + TimeShiftMs));
        PlanningRoutingLine.Modify(true);

        // [THEN] Starting Time and Ending Time for Requisition Line were updated to 11:00 and 11:50 respectively.
        RequisitionLine.Get(RequisitionLine."Worksheet Template Name", RequisitionLine."Journal Batch Name", RequisitionLine."Line No.");
        VerifyRequisitionLineStartEndDateTime(
          RequisitionLine, CreateDateTime(20200121D, PlanningLineStartTime + TimeShiftMs),
          CreateDateTime(20200121D, PlanningLineEndTime + TimeShiftMs));

        // [THEN] Starting Time and Ending Time for Planning Routing Line were updated to 11:00 and 11:50 respectively.
        VerifyPlanningLineStartEndDateTime(
          PlanningRoutingLine, CreateDateTime(20200121D, PlanningLineStartTime + TimeShiftMs),
          CreateDateTime(20200121D, PlanningLineEndTime + TimeShiftMs));
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderWithVendorNoModalPageHandler')]
    procedure ExpectedReceiptDateOnPurchFromSalesSelectVendorFromItemVendor()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
        LeadTimeFormula: DateFormula;
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Sales] [Expected Receipt Date] [Item Vendor] [Lead Time]
        // [SCENARIO 394956] Expected Receipt Date on purchase order addresses the shipment date of sales order when Lead Time is set up on Item Vendor Catalog and the user enters Vendor No. manually.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        Evaluate(LeadTimeFormula, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        ItemVendor.Validate("Lead Time Calculation", LeadTimeFormula);
        ItemVendor.Modify(true);

        CreateSalesOrder(SalesHeader, Item."No.", '', Qty, Qty);
        FindSalesLine(SalesLine, SalesHeader, Item."No.");

        LibraryVariableStorage.Enqueue(Vendor."No.");
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke();

        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.TestField("Expected Receipt Date", SalesLine."Shipment Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('PurchOrderFromSalesOrderLookupVendorNoModalPageHandler,ItemVendorCatalogModalPageHandler')]
    procedure ExpectedReceiptDateOnPurchFromSalesLookupVendorFromItemVendor()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        ItemVendor: Record "Item Vendor";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesOrder: TestPage "Sales Order";
        PurchaseOrder: TestPage "Purchase Order";
        LeadTimeFormula: DateFormula;
        Qty: Decimal;
    begin
        // [FEATURE] [Purchase] [Sales] [Expected Receipt Date] [Item Vendor] [Lead Time]
        // [SCENARIO 394956] Expected Receipt Date on purchase order addresses the shipment date of sales order when Lead Time is set up on Item Vendor Catalog and the user enters Vendor No. manually.
        Initialize();
        Qty := LibraryRandom.RandInt(10);
        Evaluate(LeadTimeFormula, StrSubstNo('<%1D>', LibraryRandom.RandInt(10)));

        LibraryPurchase.CreateVendor(Vendor);
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemVendor(ItemVendor, Vendor."No.", Item."No.");
        ItemVendor.Validate("Lead Time Calculation", LeadTimeFormula);
        ItemVendor.Modify(true);

        CreateSalesOrder(SalesHeader, Item."No.", '', Qty, Qty);
        FindSalesLine(SalesLine, SalesHeader, Item."No.");

        LibraryVariableStorage.Enqueue(Vendor."No.");
        PurchaseOrder.Trap();
        SalesOrder.OpenEdit();
        SalesOrder.FILTER.SetFilter("No.", SalesHeader."No.");
        SalesOrder.CreatePurchaseOrder.Invoke();

        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.TestField("Expected Receipt Date", SalesLine."Shipment Date");

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure BOMFixedQtyToCreateFirmPlannedOrderFromPlanWorksheet()
    var
        ComponentItem: Record Item;
        ProductItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        CompQtyPer: Decimal;
        ProdQty: Decimal;
        Scrap: Decimal;
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used to create firm planned order using planning worksheet.
        // [GIVEN] Component item, Product item, quantities and Production BOM
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);
        CompQtyPer := LibraryRandom.RandInt(1000);
        ProdQty := LibraryRandom.RandInt(1000);
        Scrap := LibraryRandom.RandInt(100);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", CompQtyPer);
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Scrap %", Scrap);
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Creating and refreshing planning line in the planning worksheet.
        CreateAndRefreshForwardPlanningLine(RequisitionLine, ProductItem."No.", ProdQty, WorkDate(), 090000T);
        FindPlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.FindFirst();

        // [THEN] Planning component Calculation formula should be fixed quantity, quantity per and expected quantity should be same as CompQtyPer
        Assert.AreEqual(ProductionBOMLine."Calculation Formula"::"Fixed Quantity", PlanningComponent."Calculation Formula", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(CompQtyPer, PlanningComponent."Quantity per", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(CompQtyPer, PlanningComponent."Expected Quantity", BOMFixedQtyCalcFormulaErr);

        // [WHEN] Carry Out Action Message to create firm planned order. 
        Commit();
        RunRequisitionCarryOutReportProdOrder(RequisitionLine);
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::"Firm Planned", ProductItem."No.");

        // [THEN] Quantity of the created production order line should be equal to ProdQty and Scrap % should be equal to Scrap
        Assert.AreEqual(ProdQty, ProdOrderLine.Quantity, BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(Scrap, ProdOrderLine."Scrap %", BOMFixedQtyCalcFormulaErr);

        // [WHEN] Update Quantity and Scrap
        ProdOrderLine.Validate(Quantity, ProdQty + LibraryRandom.RandInt(10));
        ProdOrderLine.Validate("Scrap %", Scrap + LibraryRandom.RandInt(10));
        ProdOrderLine.Modify();

        // [THEN] Line component should have calculation formula as fixed quantity, Qty Per and Expected Qty same as old CompQtyPer
        FindProdOrderComponent(ProdOrderComp, ProdOrderLine."Prod. Order No.", ComponentItem."No.");
        Assert.AreEqual(ProductionBOMLine."Calculation Formula"::"Fixed Quantity", ProdOrderComp."Calculation Formula", '');
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Quantity per", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Expected Quantity", BOMFixedQtyCalcFormulaErr);

        // [WHEN] Update Quantity Per on Prod Order Component
        CompQtyPer := CompQtyPer * LibraryRandom.RandIntInRange(1, 10);
        ProdOrderComp.Validate("Quantity per", CompQtyPer);

        // [THEN] Expected quantity is updated
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Expected Quantity", BOMFixedQtyCalcFormulaErr);
    end;

    [Test]
    procedure BOMFixedQtyToCreateReleasedProdOrderManually()
    var
        ComponentItem: Record Item;
        ProductItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComp: Record "Prod. Order Component";
        CompQtyPer: Decimal;
        ProdQty: Decimal;
        Scrap: Decimal;
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used to create released production order manually.
        // [GIVEN] Component item, Product item, quantities and Production BOM
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);
        CompQtyPer := LibraryRandom.RandInt(1000);
        ProdQty := LibraryRandom.RandInt(1000);
        Scrap := LibraryRandom.RandInt(100);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", CompQtyPer);
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Scrap %", Scrap);
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Create released order manually.
        CreateAndRefreshProdOrder(ProdOrder, ProdOrder.Status::Released, ProductItem."No.", '', ProdQty);
        FindProdOrderComponent(ProdOrderComp, ProdOrder."No.", ComponentItem."No.");

        // [THEN] Production order component Calculation formula should be fixed quantity, quantity per and expected quantity should be same as CompQtyPer
        Assert.AreEqual(ProductionBOMLine."Calculation Formula"::"Fixed Quantity", ProdOrderComp."Calculation Formula", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Quantity per", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Expected Quantity", BOMFixedQtyCalcFormulaErr);

        // [WHEN] Update Quantity and Scrap
        FindProdOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ProductItem."No.");
        ProdOrderLine.Validate(Quantity, ProdQty + LibraryRandom.RandInt(10));
        ProdOrderLine.Validate("Scrap %", Scrap + LibraryRandom.RandInt(10));
        ProdOrderLine.Modify();

        // [THEN] Line component should have calculation formula as fixed quantity, Qty Per and Expected Qty same as old CompQtyPer
        FindProdOrderComponent(ProdOrderComp, ProdOrderLine."Prod. Order No.", ComponentItem."No.");
        Assert.AreEqual(ProductionBOMLine."Calculation Formula"::"Fixed Quantity", ProdOrderComp."Calculation Formula", '');
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Quantity per", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Expected Quantity", BOMFixedQtyCalcFormulaErr);

        // [WHEN] Update Quantity Per on Prod Order Component
        CompQtyPer := CompQtyPer * LibraryRandom.RandIntInRange(1, 10);
        ProdOrderComp.Validate("Quantity per", CompQtyPer);

        // [THEN] Expected quantity is updated
        Assert.AreEqual(CompQtyPer, ProdOrderComp."Expected Quantity", BOMFixedQtyCalcFormulaErr);
    end;

    [Test]
    procedure BOMFixedQtyCalcFormulaNotAllowedForPhantomBOM()
    var
        ComponentItem: Record Item;
        PhantomProdBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is cannot be used for a phantom BOM.
        // [GIVEN] Component item, quantities, Production BOM and 2nd production BOM of type production BOM 
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);

        LibraryManufacturing.CreateProductionBOMHeader(PhantomProdBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(PhantomProdBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", LibraryRandom.RandInt(1000));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        PhantomProdBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        PhantomProdBOMHeader.Modify();

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::"Production BOM", PhantomProdBOMHeader."No.", LibraryRandom.RandInt(1000));

        // [WHEN] Change calculation formula to Fixed Quantity
        asserterror ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");

        // [THEN] Error is thrown as it is not allowed to use fixed quantity calculation formula for phantom BOM
        Assert.ExpectedTestFieldError(ProductionBOMLine.FieldCaption(Type), Format(ProductionBOMLine.Type::Item));
    end;

    [Test]
    [HandlerFunctions('StrMenuHandler')]
    procedure BOMFixedQtyCalcFormulaForStandardCosting()
    var
        ComponentItem: Record Item;
        ProductItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        CalculateStdCost: Codeunit "Calculate Standard Cost";
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used for standard costing method.
        // [GIVEN] Component item, product item, Production BOM
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate("Unit Cost", LibraryRandom.RandIntInRange(51, 100));
        ComponentItem.Modify();

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", LibraryRandom.RandIntInRange(51, 100));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Costing Method", ProductItem."Costing Method"::Standard);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Calculate Std Cost Batch Job
        CalculateStdCost.CalcItem(ProductItem."No.", false);

        // [THEN] Standard Cost = QtyPer * UnitCost
        ProductItem.Find();
        Assert.AreEqual(ProductionBOMLine."Quantity per" * ComponentItem."Unit Cost", ProductItem."Standard Cost", BOMFixedQtyCalcFormulaErr);

        // [WHEN] Lot size on ProductItem is updated and Calculate Std Cost
        ProductItem."Lot Size" := LibraryRandom.RandIntInRange(2, 20);
        ProductItem.Modify();
        CalculateStdCost.CalcItem(ProductItem."No.", false);

        // [THEN] Standard Cost = QtyPer * UnitCost / Lot Size
        ProductItem.Find();
        Assert.AreEqual(Round(ProductionBOMLine."Quantity per" * ComponentItem."Unit Cost" / ProductItem."Lot Size", 0.00001), ProductItem."Standard Cost", BOMFixedQtyCalcFormulaErr);
    end;

    [Test]
    procedure BOMFixedQtyItemAvailabilityByBOMLevelWindow()
    var
        ComponentMoreItem: Record Item;
        ComponentLessItem: Record Item;
        ProductItem: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemAvailByBOMLevelTestPage: TestPage "Item Availability by BOM Level";
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used during Item Availability by BOM Level Window. 
        // [GIVEN] Component more item, component less item, Production BOM with these two items as Production BOM Lines
        Initialize();
        LibraryInventory.CreateItem(ComponentMoreItem);
        LibraryInventory.CreateItem(ComponentLessItem);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentMoreItem."No.", '', '', LibraryRandom.RandIntInRange(51, 100));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, ComponentLessItem."No.", '', '', LibraryRandom.RandIntInRange(1, 20));
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentMoreItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentMoreItem."No.", LibraryRandom.RandIntInRange(21, 50));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentLessItem."No.", LibraryRandom.RandIntInRange(21, 50));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        // [GIVEN] Product item with replenishment as Production and Production BOM as the created BOM.
        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Check Item availability by BOM
        ItemAvailByBOMLevelTestPage.Trap();
        RunItemAvailByBOMLevelPage(ProductItem);

        // [THEN] ComponentMore "Able to Make Parent" is empty, bottleneck is empty
        // [THEN] ComponentLess "Able to Make Parent" is empty, bottleneck is true
        ItemAvailByBOMLevelTestPage.Expand(true);
        ItemAvailByBOMLevelTestPage.FILTER.SetFilter("No.", ComponentMoreItem."No.");
        ItemAvailByBOMLevelTestPage."Able to Make Parent".AssertEquals(0);
        ItemAvailByBOMLevelTestPage.Bottleneck.AssertEquals(false);

        ItemAvailByBOMLevelTestPage.FILTER.SetFilter("No.", ComponentLessItem."No.");
        ItemAvailByBOMLevelTestPage."Able to Make Parent".AssertEquals(0);
        ItemAvailByBOMLevelTestPage.Bottleneck.AssertEquals(true);
    end;

    [Test]
    procedure BOMFixedQtyFactBasedConsumption()
    var
        ComponentItem: Record Item;
        ProductItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProdOrder: Record "Production Order";
        ItemJournalBatch: Record "Item Journal Batch";
        ConsumptionJournalLine: Record "Item Journal Line";
        CalcBasedOn: Option "Actual Output","Expected Output";
    begin
        // [SCENARIO 317277] Fixed Quantity calculation formula is used for calculating consumption in consumption journal
        // [GIVEN] Component item, product item, Production BOM
        Initialize();
        LibraryInventory.CreateItem(ComponentItem);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", LibraryRandom.RandInt(100));
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Modify();
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify();

        // [WHEN] Create released production order and refresh.
        // [WHEN] Calculate consumption in consumption journal
        CreateAndRefreshProdOrder(ProdOrder, ProdOrder.Status::Released, ProductItem."No.", '', LibraryRandom.RandInt(100));
        LibraryInventory.CreateItemJournalBatchByType(ItemJournalBatch, ItemJournalBatch."Template Type"::Consumption);
        ConsumptionJnlCalcForProdOrder(ProdOrder, ItemJournalBatch, CalcBasedOn::"Expected Output");

        // [THEN]  New Item Journal Line for Component Item quantity = Production BOM Line Quantity Per.
        FindLastJournalLine(ConsumptionJournalLine, ItemJournalBatch);
        Assert.AreEqual(ComponentItem."No.", ConsumptionJournalLine."Item No.", BOMFixedQtyCalcFormulaErr);
        Assert.AreEqual(ProductionBOMLine."Quantity per", ConsumptionJournalLine.Quantity, BOMFixedQtyCalcFormulaErr);
    end;

    [Test]
    procedure BaseUnitOfMeasureOnRequisitionLineForAssembly()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [UT] [Unit of Measure]
        // [SCENARIO 428463] "Unit of Measure Code" is copied from item's base unit of measure on order planning line for assembly.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(
          RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Planning Line Origin", RequisitionLine."Planning Line Origin"::"Order Planning");

        RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Assembly);

        RequisitionLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    procedure BaseUnitOfMeasureOnRequisitionLineForTransfer()
    var
        Item: Record Item;
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        // [FEATURE] [UT] [Unit of Measure]
        // [SCENARIO 428463] "Unit of Measure Code" is copied from item's base unit of measure on order planning line for transfer.
        Initialize();

        LibraryInventory.CreateItem(Item);

        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(
          RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", Item."No.");
        RequisitionLine.Validate("Planning Line Origin", RequisitionLine."Planning Line Origin"::"Order Planning");

        RequisitionLine.Validate("Replenishment System", RequisitionLine."Replenishment System"::Transfer);

        RequisitionLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseOrderFromSalesIfPurchaseUOMIsBlankinItemShouldUseBaseUOM()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [SCENARIO 597028] If Purchase UOM is blank, "Purch. Order From Sales Order" will create POs With item Base Unit of Measure code.
        Initialize();

        // [GIVEN] Create Item With Purchase Unit Of Measure blank
        LibraryInventory.CreateItem(Item);
        Item.Validate("Purch. Unit of Measure", '');
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] A Sales Order 
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        // [WHEN] A purchase order is created from the sales order
        CreatePurchaseOrderFromSalesOrder(SalesHeader."No.", true);

        // [THEN] Find purchase order contains the same lines as the sales order
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");

        // [VERIFY] Verify: Purchase Line uses Unit Of Measure Code of Item Base Unit of Measure
        PurchaseLine.TestField("Unit of Measure Code", Item."Base Unit of Measure");
    end;

    local procedure FindLastJournalLine(var ItemJournalLine: Record "Item Journal Line"; ItemJournalBatch: Record "Item Journal Batch")
    begin
        ItemJournalLine.SetRange("Journal Batch Name", ItemJournalBatch.Name);
        ItemJournalLine.SetRange("Journal Template Name", ItemJournalBatch."Journal Template Name");
        ItemJournalLine.FindLast();
    end;

    local procedure ConsumptionJnlCalcForProdOrder(var ProductionOrder: Record "Production Order"; ItemJournalBatch: Record "Item Journal Batch"; CalcBasedOn: Option "Actual Output","Expected Output")
    var
        CalcConsumption: Report "Calc. Consumption";
    begin
        Commit();
        CalcConsumption.InitializeRequest(WorkDate(), CalcBasedOn);
        CalcConsumption.SetTemplateAndBatchName(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
        ProductionOrder.SetRange(Status, ProductionOrder.Status);
        ProductionOrder.SetRange("No.", ProductionOrder."No.");
        CalcConsumption.SetTableView(ProductionOrder);
        CalcConsumption.UseRequestPage(false);
        CalcConsumption.RunModal();
    end;

    local procedure RunItemAvailByBOMLevelPage(var Item: Record Item)
    var
        ItemAvailabilityByBOMLevel: Page "Item Availability by BOM Level";
    begin
        ItemAvailabilityByBOMLevel.InitItem(Item);
        ItemAvailabilityByBOMLevel.Run();
    end;

    local procedure RunRequisitionCarryOutReportProdOrder(RequisitionLine: Record "Requisition Line")
    var
        CarryOutActionMsgPlan: Report "Carry Out Action Msg. - Plan.";
        ProdOrderChoice: Enum "Planning Create Prod. Order";
    begin
        CarryOutActionMsgPlan.SetReqWkshLine(RequisitionLine);
        CarryOutActionMsgPlan.InitializeRequest(ProdOrderChoice::"Firm Planned".AsInteger(), 0, 0, 0);
        CarryOutActionMsgPlan.UseRequestPage(false);
        CarryOutActionMsgPlan.RunModal();
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProdOrderStatus: Enum "Production Order Status"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderStatus);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure StrMenuHandler(Options: Text[1024]; var Choice: Integer; Instructions: Text[1024])
    begin
        Choice := 1;
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure PullJobLinkThroughOrderPlanningToNewPurchaseOrder()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        // [FEATURE] [Order Planning] [Job Planning Line] [Purchase]
        // [SCENARIO 433588] Pull Job No., Job Task No., and Job Planning Line No. through order planning to a new purchase order.
        Initialize();

        // [GIVEN] Item with vendor no.
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);

        // [GIVEN] Job, Job Task and Job Planning Line for item "I".
        CreateJobPlanningLine(JobPlanningLine, Item."No.", '');

        // [GIVEN] Calculate Order Planning for job planning lines.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find the planning line for item "I".
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", '');

        // [WHEN] Make a purchase order to supply the job planning line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [THEN] Check that Job No., Job Task No., and Job Planning Line No. are populated on the new purchase line.
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");
        PurchaseLine.TestField("Job No.", JobPlanningLine."Job No.");
        PurchaseLine.TestField("Job Task No.", JobPlanningLine."Job Task No.");
        PurchaseLine.TestField("Job Planning Line No.", JobPlanningLine."Line No.");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure VerifyPurchInvPostedWithPurchOrderReservedForJob()
    var
        Item: Record Item;
        Location: Record Location;
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchRcptLine: Record "Purch. Rcpt. Line";
        PurchInvHeader: Record "Purch. Inv. Header";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PurchGetReceipt: Codeunit "Purch.-Get Receipt";
        ReceiptNo, VendorNo : Code[20];
    begin
        // [SCENARIO 464690] Post Purchase Invoice by getting receipt lines posted from purchase order reserved for job without tracking specification.
        Initialize();

        // [GIVEN] Item "I" with reordering policy Order and always reserve.
        LibraryInventory.CreateItem(Item);
        Item."Reordering Policy" := Item."Reordering Policy"::Order;
        Item.Reserve := Item.Reserve::Always;
        Item."Vendor No." := LibraryPurchase.CreateVendorNo();
        Item.Modify();

        // [GIVEN] Location "L" with inventory posting group.
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);

        // [GIVEN] Job, Job Task and Job Planning Line for item "I" on location "L"
        CreateJobPlanningLine(JobPlanningLine, Item."No.", Location.Code);

        // [GIVEN] Calculate Order Planning for job planning lines.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find the planning line for item "I".
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", Location.Code);
        VendorNo := RequisitionLine."Supply From";

        // [GIVEN] Make a purchase order to supply the job planning line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [GIVEN] Check that Job No., Job Task No., and Job Planning Line No. are populated on the new purchase line.
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");

        // [WHEN] Post Purchase Receipt
        ReceiptNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [THEN] Verify consumption is not posted automatically due to reservation.        
        ItemLedgerEntry.SetRange("Posting Date", PurchaseHeader."Posting Date");
        ItemLedgerEntry.SetRange("Document No.", ReceiptNo);
        ItemLedgerEntry.SetRange("Job No.", JobPlanningLine."Job No.");
        ItemLedgerEntry.SetRange("Job Task No.", JobPlanningLine."Job Task No.");
        ItemLedgerEntry.SetRange("Entry Type", ItemLedgerEntry."Entry Type"::Purchase);
        Assert.IsTrue(ItemLedgerEntry.IsEmpty, 'Purchase Receipt entry with project link posted');

        // [GIVEN] Purchase invoice with the same vendor.
        // [GIVEN] Populate the invoice lines using "Get Receipt Lines" function.
        Clear(PurchaseHeader);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        PurchRcptLine.SetRange("Document No.", ReceiptNo);
        PurchGetReceipt.SetPurchHeader(PurchaseHeader);
        PurchGetReceipt.CreateInvLines(PurchRcptLine);

        // [WHEN] Post Purchase Invoice
        // [THEN] Verify Purchase Invoice posted
        Assert.IsTrue(PurchInvHeader.Get(LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true)), 'Purchase Invoice not posted');
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    procedure VerifyItemFromJobIsNotSuggestedWhenPurchaseOrderCreatedFromOrderPlanningIsPostedReceipt()
    var
        Item: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        VendorNo: Code[20];
    begin
        // [SCENARIO 472230] Item from job is not suggested when purchase order created from order planning is posted receipt
        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);
        Item."Vendor No." := LibraryPurchase.CreateVendorNo();
        Item.Modify();

        // [GIVEN] Job, Job Task and Job Planning Line for item 
        CreateJobPlanningLine(JobPlanningLine, Item."No.", '');

        // [GIVEN] Calculate Order Planning for job planning line
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Find the planning line for item "I".
        FindRequisitionLine(RequisitionLine, JobPlanningLine."Job No.", Item."No.", '');
        VendorNo := RequisitionLine."Supply From";

        // [GIVEN] Make a purchase order to supply the job planning line.
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // [GIVEN] Check that Job No., Job Task No., and Job Planning Line No. are populated on the new purchase line
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, Item."No.");

        // [WHEN] Post Purchase Receipt
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [WHEN] Calculate Order Planning for job planning line
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [THEN] Find the planning line for item
        RequisitionLine.SetRange("Demand Order No.", JobPlanningLine."Job No.");
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanningLineUpdatingWithoutAnyError()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        OrderPlanning: TestPage "Order Planning";
        Qty: Decimal;
    begin
        // [SCENARIO 497256] Order Planning when you update the lines with Replenishment System = Prod. Order this leads to a validation error
        Initialize();

        // [GIVEN] Setup: Create Work Center, Routing, Item, and initialize random quantity
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        GlobalChildItemNo := ChildItem."No.";
        Qty := LibraryRandom.RandDecInRange(50, 100, 2);

        // [GIVEN] Create Firm Planned Production Order
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, Qty);

        // [THEN] Calculate Plan from Order Planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // [VERIFY] Exercise And Verify : Open Order Tracking Page and updating values in fields without any error
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");
        OrderPlanning.Reserve.SetValue(true);
        OrderPlanning.Quantity.SetValue(Qty - LibraryRandom.RandDecInRange(10, 20, 2));
        OrderPlanning.Quantity.SetValue(Qty - LibraryRandom.RandDecInRange(10, 20, 2));
        OrderPlanning.Close();
    end;

    [Test]
    [HandlerFunctions('InvokeSelectMultiItemsFromPlanningComponentPageHandler,SelectMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningComponentSelectMultipleItems()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        OrderPlanning: TestPage "Order Planning";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Planning Component Page adds selected items.
        Initialize();

        // [GIVEN] Create Manufacturing Setup.
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);

        // [GIVEN] Create And Refresh Production Osrder.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Calcuulate Order Plan.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // [GIVEN] Open Order Planning Page.
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");

        // [GIVEN] Filter Requisition Line.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        RequisitionLine.SetRange("Demand Order No.", ProductionOrder."No.");
        RequisitionLine.SetRange("No.", ChildItem."No.");
        RequisitionLine.FindFirst();

        // [WHEN] Open and Run Action "Select Items" from the Planning Component Page through Handler. 
        OrderPlanning.Components.Invoke();

        // [THEN] Verify the count of planning component lines as one line is added.
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        Assert.RecordCount(PlanningComponent, 2);
    end;

    [Test]
    [HandlerFunctions('InvokeSelectMultiItemsFromPlanningComponentPageHandler,SelectCancelMultiItemsModalPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningComponentCancelSelectMultipleItems()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        OrderPlanning: TestPage "Order Planning";
    begin
        // [SCENARIO 347825] Run Action "Select items" on Planning Component Page not add selected items.
        Initialize();

        // [GIVEN] Create Manufacturing Setup.
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);

        // [GIVEN] Create And Refresh Production Osrder.
        CreateAndRefreshProdOrder(ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));

        // [GIVEN] Calcuulate Order Plan.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // [GIVEN] Open Order Planning Page.
        OpenOrderPlanningPage(OrderPlanning, ProductionOrder."No.", ChildItem."No.");

        // [GIVEN] Filter Requisition Line.
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionLine."Journal Batch Name");
        RequisitionLine.SetRange("Demand Order No.", ProductionOrder."No.");
        RequisitionLine.SetRange("No.", ChildItem."No.");
        RequisitionLine.FindFirst();

        // [WHEN] Open and Run Action "Select Items" from the Planning Component Page through Handler. 
        OrderPlanning.Components.Invoke();

        // [THEN] Verify the count of planning component lines as line is not added.
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        Assert.RecordCount(PlanningComponent, 1);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure StartingTimeShouldNotBlankOnFirmPlannedProductionOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        ProductionOrderNo: Code[20];
        StartingTime: Time;
    begin
        // [SCENARIO 560672] "Starting Time" is blank when creating a "Firm Planned Production Order" using the "Planning Worksheet"
        Initialize();

        // [GIVEN] Define setup and create production order 
        LibraryApplicationArea.EnablePremiumSetup();
        CreateManufacturingSetup(ParentItem, ChildItem, true, ChildItem."Order Tracking Policy"::None);
        CreateAndRefreshProdOrder(
            ProductionOrder, ProductionOrder.Status::"Firm Planned",
            ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2));

        // [WHEN] Calculate Order Plan Production and save starting time value to verify
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationRed.Code);
        StartingTime := RequisitionLine."Starting Time";
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");
        ProductionOrderNo := FindProductionOrderNo(ChildItem."No.");

        // [THEN] Verify Starting Time on Firm Planned Production Order
        VerifyStartingTimeOnFirmPlannedProductionOrder(StartingTime, ChildItem."No.", ProductionOrderNo);
    end;

    [Test]
    [HandlerFunctions('ModalPageHandler,ErrorMessageHandler')]
    procedure ReleasedProdOrderQuantityPerandExpectedQtyRoundingPrecisionChecking()
    var
        BaseItemUnitOfMeasure: Record "Item Unit of Measure";
        ComponentItem: Record Item;
        ProdOrderComp: Record "Prod. Order Component";
        ProdOrderLine: Record "Prod. Order Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProductItem: Record Item;
        SalesHeader: Record "Sales Header";
        ExpectedQty: Decimal;
        RelesedProdOrderNo: Code[20];
        Status: Enum "Production Order Status";
    begin
        // [SCENARIO 562766] If a component's Item UOM has a 'Quantity Rounding Precision' of 1, & a Finished Good consumes partial quantity, 
        // the Prod. Order created from the Planning of a Sales Order pulls in the Component with a 'Qty. Per' and 'Exp. Qty.' of 0.
        Initialize();

        // [GIVEN] Created Component Item
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItem.Validate("Replenishment System", ComponentItem."Replenishment System"::Purchase);
        ComponentItem.Validate("Rounding Precision", LibraryRandom.RandPrecision());
        ComponentItem.Validate("Reordering Policy", ComponentItem."Reordering Policy"::"Lot-for-Lot");
        ComponentItem.Validate("Include Inventory", true);
        ComponentItem.Modify(true);

        // [GIVEN] Set Qty. Rounding Precision = 1 for Component Item
        BaseItemUnitOfMeasure.Get(ComponentItem."No.", ComponentItem."Base Unit of Measure");
        BaseItemUnitOfMeasure.Validate("Qty. Rounding Precision", 1);
        BaseItemUnitOfMeasure.Modify();

        // [GIVEN] Created Production Bom using Component Item
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", LibraryRandom.RandDecInDecimalRange(0.01, 0.99, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify();

        // [GIVEN] Created Master Item and Production Bom Assigned to Master Item
        LibraryInventory.CreateItem(ProductItem);
        ProductItem.Validate("Replenishment System", ProductItem."Replenishment System"::"Prod. Order");
        ProductItem.Validate("Rounding Precision", 1);
        ProductItem.Validate("Reordering Policy", ProductItem."Reordering Policy"::Order);
        ProductItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProductItem.Modify(true);

        // [GIVEN] Created Sales Order Using Master Item Quantity - 1
        CreateSalesOrder(SalesHeader, ProductItem."No.", '', 1, 1);

        // [WHEN] Created Released Prod. Order From Sales Order Using Planning
        LibraryManufacturing.CreateProdOrderUsingPlanning(ProductionOrder, Status::"Firm Planned", SalesHeader."No.", ProductItem."No.");
        RelesedProdOrderNo := LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProductionOrder."No.");

        // [WHEN] Find Released Production Order Component
        FindProdOrderLine(ProdOrderLine, RelesedProdOrderNo);
        FindProdOrderComponent(ProdOrderComp, ProdOrderLine."Prod. Order No.", ComponentItem."No.");

        // [WHEN] Getting Expected result using Component Rounding Precision
        ExpectedQty := Round(ProductionBOMLine."Quantity per" * BaseItemUnitOfMeasure."Qty. Rounding Precision" / BaseItemUnitOfMeasure."Qty. Rounding Precision", ComponentItem."Rounding Precision");

        // [THEN] Expected Quantity must be Equal to Production Order Component "Quantity per" And "Expected Quantity"
        Assert.AreEqual(ExpectedQty, ProdOrderComp."Quantity per", StrSubstNo(RelesedProdOrderComponentQtyPerRoundingErr, ProdOrderComp."Quantity per", ExpectedQty));
        Assert.AreEqual(ExpectedQty, ProdOrderComp."Expected Quantity", StrSubstNo(RelesedProdOrderComponentExpQtyRoundingErr, ProdOrderComp."Expected Quantity", ExpectedQty));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Planning - III");
        ClearGlobals();

        LibraryApplicationArea.EnableEssentialSetup();
        LibraryVariableStorage.Clear();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Planning - III");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Planning - III");
    end;

    local procedure ClearGlobals()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Clear(VerifyOnGlobal);
        Clear(DemandTypeGlobal);
        Clear(GlobalChildItemNo);
        Clear(ExpectedQuantity);
        RequisitionLine.Reset();
        RequisitionLine.DeleteAll();
        ClearManufacturingUserTemplate();
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);

        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);
    end;

    local procedure ChangeReplenishmentSystem(var RequisitionLine: Record "Requisition Line"; OldReplenishmentSystem: Enum "Replenishment System"; NewReplenishmentSystem: Enum "Replenishment System";
                                                                                                                          DemandOrderNo: Code[20];
                                                                                                                          VendorNo: Code[20])
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("Replenishment System", OldReplenishmentSystem);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Replenishment System", NewReplenishmentSystem);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateManufacturingSetup(var Item: Record Item; var ChildItem: Record Item; ChildWithBOM: Boolean; OrderTrackingPolicy: Enum "Order Tracking Policy")
    var
        ChildItem2: Record Item;
    begin
        // Create Child Item with its own Production BOM hierarchy.
        if ChildWithBOM then
            CreateProdItem(ChildItem, ChildItem2)
        else
            CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '');
        UpdateItem(ChildItem, ChildItem.Reserve::Optional, OrderTrackingPolicy);
        CreateItemWithProductionBOM(Item, ChildItem, '', LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateProdItem(var ParentItem: Record Item; var ChildItem: Record Item)
    begin
        // Create Child Item.
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '');

        // Create Parent Item.
        CreateItemWithProductionBOM(ParentItem, ChildItem, '', LibraryRandom.RandDec(5, 2));
    end;

    local procedure CreateProductionItemWithOneLineRouting(var Item: Record Item; DueDate: Date)
    var
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
    begin
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDaysCustomTime(080000T, 160000T);
        LibraryManufacturing.CreateWorkCenterFullWorkingWeek(WorkCenter, 080000T, 160000T);
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapUnitOfMeasure, CapUnitOfMeasure.Type::Minutes);
        WorkCenter.Validate("Unit of Measure Code", CapUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-2M>', DueDate), CalcDate('<2M>', DueDate));

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        CreateItem(Item, Item."Replenishment System"::"Prod. Order", RoutingHeader."No.", '');
    end;

    local procedure CreateItemWithProductionBOM(var Item: Record Item; ChildItem: Record Item; VariantCode: Code[10]; QuantityPer: Decimal)
    var
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Production BOM and Routing.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem, VariantCode, QuantityPer);
        CreateRoutingSetup(RoutingHeader);

        // Create Parent Item.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; RoutingHeaderNo: Code[20];
                                                                               ProductionBOMNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryInventory.CreateItem(Item);
        GeneralLedgerSetup.Get();
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(20, 2));
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision");
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Validate("Routing No.", RoutingHeaderNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNoAndPurchUnitOfMeasure(var Item: Record Item)
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateItem(Item);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandIntInRange(12, 24));
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Validate("Purch. Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure UpdateItem(var Item: Record Item; Reserve: Enum "Reserve Method"; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate(Reserve, Reserve);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure UpdateItemEx(var Item: Record Item; Reserve: Enum "Reserve Method"; ReorderingPolicy: Enum "Reordering Policy")
    var
        Qty: Integer;
    begin
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate(Reserve, Reserve);
        Qty := LibraryRandom.RandIntInRange(10, 20);
        if ReorderingPolicy = Item."Reordering Policy"::"Fixed Reorder Qty." then
            Item.Validate("Reorder Quantity", Qty)
        else
            if ReorderingPolicy = Item."Reordering Policy"::"Maximum Qty." then
                Item.Validate("Maximum Inventory", Qty);
        Item.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; Item: Record Item; VariantCode: Code[10]; QuantityPer: Decimal)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        // Create component lines in the BOM
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.", QuantityPer);
        ProductionBOMLine.Validate("Variant Code", VariantCode);
        ProductionBOMLine.Modify(true);

        // Certify BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::"Under Development");
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateRoutingSetup(var RoutingHeader: Record "Routing Header")
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        RoutingLine: Record "Routing Line";
    begin
        CreateWorkCenter(WorkCenter);
        CreateMachineCenter(MachineCenter, WorkCenter."No.");
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        CreateRoutingLine(RoutingLine, RoutingHeader, WorkCenter."No.");
        RoutingLine.Type := RoutingLine.Type::"Machine Center";
        CreateRoutingLine(RoutingLine, RoutingHeader, MachineCenter."No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterFullWorkingWeek(WorkCenter, 080000T, 160000T);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', WorkDate()), CalcDate('<1M>', WorkDate()));
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Modify(true);
    end;

    local procedure CreateMachineCenter(var MachineCenter: Record "Machine Center"; WorkCenterNo: Code[20])
    begin
        // Random value important for test.
        LibraryManufacturing.CreateMachineCenterWithCalendar(MachineCenter, WorkCenterNo, LibraryRandom.RandDec(105, 1));
        MachineCenter.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        MachineCenter.Modify(true);
    end;

    local procedure CreateRoutingLine(var RoutingLine: Record "Routing Line"; RoutingHeader: Record "Routing Header"; CenterNo: Code[20])
    var
        OperationNo: Code[10];
    begin
        // Random used such that the Next Operation No is greater than the Previous Operation No.
        OperationNo := FindLastOperationNo(RoutingHeader."No.") + Format(LibraryRandom.RandInt(5));

        // Random values not important for test.
        LibraryManufacturing.CreateRoutingLineSetup(
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDecInRange(5, 10, 2), LibraryRandom.RandDecInRange(5, 10, 2));
    end;

    local procedure ClearManufacturingUserTemplate()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        ManufacturingUserTemplate.SetRange("User ID", UserId);
        if ManufacturingUserTemplate.FindFirst() then
            ManufacturingUserTemplate.Delete(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20];
                                                                                                          LocationCode: Code[10];
                                                                                                          Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndRefreshForwardPlanningLine(var RequisitionLine: Record "Requisition Line"; SourceNo: Code[20]; Quantity: Decimal; StartingDate: Date; StartingTime: Time)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        Direction: Option Forward,Backward;
    begin
        LibraryPlanning.SelectRequisitionWkshName(RequisitionWkshName, RequisitionWkshName."Template Type"::Planning);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", SourceNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Validate("Starting Date", StartingDate);
        RequisitionLine.Validate("Starting Time", StartingTime);
        RequisitionLine.Modify(true);
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Forward, true, true);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateLocation(LocationRed);
        CreateLocation(LocationBlue);
        CreateLocation(LocationBlue2);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date; Quantity: Decimal; QuantityToShip: Decimal)
    begin
        CreateSalesLine(SalesHeader, ItemNo, '', LocationCode, ShipmentDate, Quantity, QuantityToShip);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemVariantCode: Code[10]; LocationCode: Code[10]; ShipmentDate: Date; Quantity: Decimal; QuantityToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        if ItemVariantCode <> '' then
            SalesLine."Variant Code" := ItemVariantCode;
        SalesLine.Validate("Qty. to Ship", QuantityToShip);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; QtyToShip: Decimal)
    begin
        // Random values used are not important for test.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, WorkDate(), Quantity, QtyToShip);
    end;

    local procedure CreateSalesOrderWithItemVariant(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemVariantCode: Code[10]; LocationCode: Code[10]; Quantity: Decimal; QtyToShip: Decimal)
    begin
        // Random values used are not important for test.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);

        CreateSalesLine(SalesHeader, ItemNo, ItemVariantCode, LocationCode, WorkDate(), Quantity, QtyToShip);
    end;

    local procedure CreateSalesOrderWithPurchasingCode(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ItemNo: Code[20]; PurchasingCode: Code[10])
    begin
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, '', ItemNo, LibraryRandom.RandInt(100), '', WorkDate());
        SalesLine.Validate("Purchasing Code", PurchasingCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateLocation(var Location: Record Location)
    begin
        Clear(Location);
        LibraryWarehouse.CreateLocation(Location);
    end;

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ItemNo: Code[20])
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
    begin
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");
        LibraryService.CreateServiceLineWithQuantity(
          ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo, LibraryRandom.RandInt(10));
    end;

    local procedure CreateJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; ItemNo: Code[20]; LocationCode: Code[10])
    var
        Job: Record Job;
        JobTask: Record "Job Task";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        LibraryJob.CreateJobPlanningLine(LibraryJob.PlanningLineTypeSchedule(), LibraryJob.ItemType(), JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("Planning Date", WorkDate());
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate(Quantity, LibraryRandom.RandIntInRange(11, 20));
        JobPlanningLine.Modify(true);
    end;

    local procedure CreatePurchaseOrderFromSalesOrder(SalesOrderNo: Code[20]; MakePurchOrders: Boolean)
    var
        TempManufacturingUserTemplate: Record "Manufacturing User Template" temporary;
        ReqLine: Record "Requisition Line";
        TempDocumentEntry: Record "Document Entry" temporary;
        OrderPlanningMgt: Codeunit "Order Planning Mgt.";
        MakeSupplyOrdersYesNo: Codeunit "Make Supply Orders (Yes/No)";
    begin
        TempManufacturingUserTemplate.Init();
        TempManufacturingUserTemplate."User ID" := UserId;
        TempManufacturingUserTemplate."Make Orders" := TempManufacturingUserTemplate."Make Orders"::"The Active Order";
        TempManufacturingUserTemplate."Create Purchase Order" := TempManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders";
        TempManufacturingUserTemplate."Create Production Order" := TempManufacturingUserTemplate."Create Production Order"::" ";
        TempManufacturingUserTemplate."Create Transfer Order" := TempManufacturingUserTemplate."Create Transfer Order"::" ";
        TempManufacturingUserTemplate."Create Assembly Order" := TempManufacturingUserTemplate."Create Assembly Order"::" ";
        TempManufacturingUserTemplate.Insert();

        OrderPlanningMgt.PlanSpecificSalesOrder(ReqLine, SalesOrderNo);
        if not MakePurchOrders then begin
            ReqLine.Reset();
            OrderPlanningMgt.PrepareRequisitionRecord(ReqLine);
        end;

        ReqLine.SetFilter(Quantity, '>%1', 0);
        if ReqLine.FindFirst() then begin
            MakeSupplyOrdersYesNo.SetManufUserTemplate(TempManufacturingUserTemplate);
            MakeSupplyOrdersYesNo.SetBlockForm();
            MakeSupplyOrdersYesNo.SetCreatedDocumentBuffer(TempDocumentEntry);
            MakeSupplyOrdersYesNo.Run(ReqLine);
        end;
    end;

    local procedure ChangeDataOnSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; FieldNo: Integer; Value: Variant)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.ReopenSalesDocument(SalesHeader);
        FindSalesLine(SalesLine, SalesHeader, ItemNo);
        UpdateSalesLine(SalesLine, FieldNo, Value);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
    end;

    local procedure ChangeDataOnProductionOrderAndRefresh(ProductionOrder: Record "Production Order"; FieldNo: Integer; Value: Variant)
    begin
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        UpdateProductionOrder(ProductionOrder, FieldNo, Value);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateProductionOrder(var ProductionOrder: Record "Production Order"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(ProductionOrder);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(ProductionOrder);
        ProductionOrder.Modify(true);
    end;

    local procedure UpdatePurchaseHeaderCurrencyCode(var PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.Validate(
          "Currency Code", LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), LibraryRandom.RandDec(100, 2), LibraryRandom.RandDec(100, 2)));
        PurchaseHeader.Modify(true);
    end;

    local procedure ChangeQuantityOnPlanning(var OrderPlanning: TestPage "Order Planning"; OrderNo: Code[20]; ItemNo: Code[20]; Quantity: Decimal)
    begin
        OpenOrderPlanningPage(OrderPlanning, OrderNo, ItemNo);
        OrderPlanning.Quantity.SetValue(Quantity);
        OrderPlanning.Close();
    end;

    local procedure GetSpecialOrderAndCarryOutAtWorkdateByItemNo(ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, 0D, WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure GetSalesOrdersAndCarryOutAtWorkdateByItemNo(SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        RequisitionLine: Record "Requisition Line";
        GetDim: Option Item,"Sales Line";
    begin
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, LibraryPlanning.SelectRequisitionTemplateName());
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, GetDim::"Sales Line");
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, 0D, WorkDate(), WorkDate(), WorkDate(), '');
    end;

    local procedure GetPurchaseSpecialOrderAtWorkdateByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        GetSpecialOrderAndCarryOutAtWorkdateByItemNo(ItemNo);
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, ItemNo);
    end;

    local procedure GetPurchaseDropShipmentAtWorkdateByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; SalesLine: Record "Sales Line")
    begin
        GetSalesOrdersAndCarryOutAtWorkdateByItemNo(SalesLine);
        FindPurchaseDocumentByItemNo(PurchaseHeader, PurchaseLine, SalesLine."No.");
    end;

    local procedure FindLastOperationNo(RoutingNo: Code[20]): Code[10]
    var
        RoutingLine: Record "Routing Line";
    begin
        RoutingLine.SetRange("Routing No.", RoutingNo);
        if RoutingLine.FindLast() then
            exit(RoutingLine."Operation No.");
        exit('');
    end;

    local procedure FindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; No: Code[20])
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("No.", No);
        SalesLine.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; DemandOrderNo: Code[20]; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure FindPurchaseOrderNo(): Code[20]
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        NoSeries: Codeunit "No. Series";
    begin
        PurchasesPayablesSetup.Get();
        exit(NoSeries.PeekNextNo(PurchasesPayablesSetup."Order Nos."));
    end;

    local procedure FindProductionOrderNo(ItemNo: Code[20]): Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindFirst();
        exit(ProdOrderLine."Prod. Order No.");
    end;

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
    end;

    local procedure FindPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure FindPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure FindFirstPlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; RequisitionLine: Record "Requisition Line")
    begin
        FindPlanningRoutingLine(PlanningRoutingLine, RequisitionLine);
        PlanningRoutingLine.FindFirst();
    end;

    local procedure FindPurchaseDocumentByItemNo(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure GetReqWkshTemplateName(TemplateType: Enum "Req. Worksheet Template Type"): Code[10]
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, TemplateType);
        ReqWkshTemplate.FindFirst();
        exit(ReqWkshTemplate.Name);
    end;

    local procedure GetReqWkshName(TemplateName: Code[10]; TemplateType: Enum "Req. Worksheet Template Type"): Code[10]
    var
        ReqWkshName: Record "Requisition Wksh. Name";
    begin
        ReqWkshName.SetRange("Worksheet Template Name", TemplateName);
        ReqWkshName.SetRange("Template Type", TemplateType);
        ReqWkshName.FindFirst();
        exit(ReqWkshName.Name);
    end;

    local procedure MakeSupplyOrdersActiveOrder(DemandOrderNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");
    end;

    local procedure MakeSupplyOrdersCopyToWkshActiveOrder(DemandOrderNo: Code[20]; WkshTemplateName: Code[10]; WkshName: Code[10])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();
        MakeSupplyOrdersCopyToWksh(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order", WkshTemplateName, WkshName);
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreateProductionOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure MakeSupplyOrdersCopyToWksh(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; WkshTemplateName: Code[10]; WkshName: Code[10])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // Set create order option to "Copy to Req. Wksh" for purchase, production, transfer orders
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders,
          ManufacturingUserTemplate."Create Production Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Create Purchase Order",
          ManufacturingUserTemplate."Create Purchase Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Purchase Req. Wksh. Template", WkshTemplateName);
        ManufacturingUserTemplate.Validate("Purchase Wksh. Name", WkshName);

        ManufacturingUserTemplate.Validate("Prod. Req. Wksh. Template", WkshTemplateName);
        ManufacturingUserTemplate.Validate("Prod. Wksh. Name", WkshName);

        ManufacturingUserTemplate.Validate("Create Transfer Order",
          ManufacturingUserTemplate."Create Transfer Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Transfer Req. Wksh. Template", WkshTemplateName);
        ManufacturingUserTemplate.Validate("Transfer Wksh. Name", WkshName);

        ManufacturingUserTemplate.Modify(true);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure OpenOrderPlanningPage(var OrderPlanning: TestPage "Order Planning"; DemandOrderNo: Code[20]; No: Code[20])
    begin
        OrderPlanning.OpenEdit();
        OrderPlanning.FILTER.SetFilter("Demand Order No.", DemandOrderNo);
        OrderPlanning.Expand(true);
        OrderPlanning.FILTER.SetFilter("No.", No);
    end;

    local procedure UpdateSalesLine(var SalesLine: Record "Sales Line"; FieldNo: Integer; Value: Variant)
    var
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.GetTable(SalesLine);
        FieldRef := RecRef.Field(FieldNo);
        FieldRef.Validate(Value);
        RecRef.SetTable(SalesLine);
        SalesLine.Modify(true);
    end;

    local procedure UpdateSalesReceivablesSetup(var SalesReceivablesSetup2: Record "Sales & Receivables Setup")
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup2 := SalesReceivablesSetup;
        SalesReceivablesSetup2.Insert();

        SalesReceivablesSetup.Validate("Credit Warnings", SalesReceivablesSetup."Credit Warnings"::"No Warning");
        SalesReceivablesSetup.Validate("Stockout Warning", false);
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure UpdatePlanningComponent(var PlanningComponent: Record "Planning Component"; ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    begin
        PlanningComponent.Validate("Item No.", ItemNo);
        PlanningComponent.Validate("Unit of Measure Code", UnitOfMeasureCode);
        PlanningComponent.Validate("Quantity per", QuantityPer);
        PlanningComponent.Modify(true);
    end;

    local procedure UpdatePlanningRoutingLine(var PlanningRoutingLine: Record "Planning Routing Line"; WorkCenterNo: Code[20]; PerviousOperationNo: Code[30]; SetupTime: Decimal; Runtime: Decimal)
    begin
        PlanningRoutingLine.Validate("Previous Operation No.", PerviousOperationNo);
        PlanningRoutingLine.Validate(Type, PlanningRoutingLine.Type::"Work Center");
        PlanningRoutingLine.Validate("No.", WorkCenterNo);
        PlanningRoutingLine.Validate("Setup Time", SetupTime);
        PlanningRoutingLine.Validate("Run Time", Runtime);
        PlanningRoutingLine.Modify(true);
    end;

    local procedure OpenFirmPlannedProductionOrder(var FirmPlannedProdOrders: TestPage "Firm Planned Prod. Orders"; var ProductionOrderStatistics: TestPage "Production Order Statistics"; SourceNo: Code[20]; No: Code[20])
    begin
        FirmPlannedProdOrders.OpenEdit();
        FirmPlannedProdOrders.FILTER.SetFilter("Source No.", SourceNo);
        FirmPlannedProdOrders.FILTER.SetFilter("No.", No);
        ProductionOrderStatistics.Trap();
        FirmPlannedProdOrders.Statistics.Invoke();
    end;

    local procedure VerifyDimensionSetEntry(DimensionCode: Code[20]; DimensionValueCode: Code[20]; DimensionSetID: Integer)
    var
        DimensionSetEntry: Record "Dimension Set Entry";
    begin
        DimensionSetEntry.SetRange("Dimension Code", DimensionCode);
        DimensionSetEntry.SetRange("Dimension Set ID", DimensionSetID);
        DimensionSetEntry.FindFirst();
        DimensionSetEntry.TestField("Dimension Value Code", DimensionValueCode);
    end;

    local procedure VerifyOrderTrackingPage(OrderTracking: TestPage "Order Tracking")
    begin
        Assert.AreEqual(
          GlobalChildItemNo, OrderTracking."Item No.".Value,
          StrSubstNo(ValidationError, OrderTracking."Item No.".Caption, GlobalChildItemNo, OrderTracking.Caption));
        Assert.AreEqual(ExpectedQuantity, OrderTracking.Quantity.AsDecimal(), QuantityError);
    end;

    local procedure VerifyProdOrderComponent(ItemNo: Code[20]; UnitOfMeasureCode: Code[10]; QuantityPer: Decimal)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
        ProdOrderComponent.TestField("Quantity per", QuantityPer);
        ProdOrderComponent.TestField("Unit of Measure Code", UnitOfMeasureCode);
    end;

    local procedure VerifyProdOrderRoutingLine(PlanningRoutingLine: Record "Planning Routing Line"; RoutingNo: Code[20]; OperationNo: Code[10])
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetRange("Operation No.", OperationNo);
        ProdOrderRoutingLine.SetRange("Routing No.", RoutingNo);
        ProdOrderRoutingLine.FindFirst();
        ProdOrderRoutingLine.TestField(Type, ProdOrderRoutingLine.Type);
        ProdOrderRoutingLine.TestField("No.", PlanningRoutingLine."No.");
        ProdOrderRoutingLine.TestField("Setup Time", PlanningRoutingLine."Setup Time");
        ProdOrderRoutingLine.TestField("Run Time", PlanningRoutingLine."Run Time");
        ProdOrderRoutingLine.TestField("Previous Operation No.", PlanningRoutingLine."Previous Operation No.");
    end;

    local procedure VerifyProductionOrderStatistics(ProductionOrderStatistics: TestPage "Production Order Statistics"; ProductionOrderStatistics2: TestPage "Production Order Statistics")
    begin
        ProductionOrderStatistics2.MaterialCost_StandardCost.AssertEquals(ProductionOrderStatistics.MaterialCost_StandardCost.Value);
        ProductionOrderStatistics2.CapacityCost_StandardCost.AssertEquals(ProductionOrderStatistics.CapacityCost_StandardCost.Value);
        ProductionOrderStatistics2.TotalCost_StandardCost.AssertEquals(ProductionOrderStatistics.TotalCost_StandardCost.Value);

        ProductionOrderStatistics2.MaterialCost_ExpectedCost.AssertEquals(ProductionOrderStatistics.MaterialCost_ExpectedCost.Value);
        ProductionOrderStatistics2.CapacityCost_ExpectedCost.AssertEquals(ProductionOrderStatistics.CapacityCost_ExpectedCost.Value);
        ProductionOrderStatistics2.TotalCost_ExpectedCost.AssertEquals(ProductionOrderStatistics.TotalCost_ExpectedCost.Value);

        ProductionOrderStatistics2.MaterialCost_ActualCost.AssertEquals(ProductionOrderStatistics.MaterialCost_ActualCost.Value);
        ProductionOrderStatistics2.CapacityCost_ActualCost.AssertEquals(ProductionOrderStatistics.CapacityCost_ActualCost.Value);
        ProductionOrderStatistics2.TotalCost_ActualCost.AssertEquals(ProductionOrderStatistics.TotalCost_ActualCost.Value);
    end;

    local procedure VerifyPurchaseLineUnitOfMeasureCodeAndQuantityBase(PurchaseLine: Record "Purchase Line"; UnitOfMeasureCode: Code[10]; QtyBase: Decimal)
    begin
        PurchaseLine.TestField("Unit of Measure Code", UnitOfMeasureCode);
        Assert.AreNearlyEqual(
          QtyBase, PurchaseLine."Quantity (Base)", 0.01,
          StrSubstNo(PurchaseLineQuantityBaseErr, PurchaseLine.TableName, PurchaseLine.FieldName("Quantity (Base)"), QtyBase));
    end;

    local procedure VerifyOrderToOrderBindingOnReservEntry(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; ReservedFromSourceType: Integer)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetSourceFilter(SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.Get(ReservationEntry."Entry No.", not ReservationEntry.Positive);
        ReservationEntry.TestField("Source Type", ReservedFromSourceType);
        ReservationEntry.TestField("Reservation Status", ReservationEntry."Reservation Status"::Reservation);
        ReservationEntry.TestField(Binding, ReservationEntry.Binding::"Order-to-Order");
    end;

    local procedure VerifyPlanningLineStartEndDateTime(PlanningRoutingLine: Record "Planning Routing Line"; ExpectedStartingDateTime: DateTime; ExpectedEndingDateTime: DateTime)
    begin
        PlanningRoutingLine.TestField("Starting Date-Time", ExpectedStartingDateTime);
        PlanningRoutingLine.TestField("Ending Date-Time", ExpectedEndingDateTime);
    end;

    local procedure VerifyRequisitionLineStartEndDateTime(RequisitionLine: Record "Requisition Line"; ExpectedStartingDateTime: DateTime; ExpectedEndingDateTime: DateTime)
    begin
        RequisitionLine.TestField("Starting Date-Time", ExpectedStartingDateTime);
        RequisitionLine.TestField("Ending Date-Time", ExpectedEndingDateTime);
    end;

    local procedure RestoreSalesReceivableSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure VerifyStartingTimeOnFirmPlannedProductionOrder(
        StartingTime: Time;
        SourceNo: Code[20];
        No: Code[20])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange(Status, ProductionOrder.Status::"Firm Planned");
        ProductionOrder.SetRange("Source No.", SourceNo);
        ProductionOrder.SetRange("No.", No);
        ProductionOrder.FindFirst();
        Assert.IsTrue(ProductionOrder."Starting Time" = StartingTime, '');
    end;

    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrderNo: Code[20])
    begin
        ProdOrderLine.Reset();
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderLine.FindFirst();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, OrderTrackingMessage) > 0, StrSubstNo(UnexpectedMessageDialog, Message));
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        VerifyOrderTrackingPage(OrderTracking);
        OrderTracking.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PlanningComponentPageHandler(var PlanningComponents: TestPage "Planning Components")
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
    begin
        PlanningComponents.First();
        Item.Get(GlobalChildItemNo);
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMLine.FindFirst();

        // Verify That Operation No. And Type Is same as on Production BOM Line.
        PlanningComponents."Item No.".AssertEquals(ProductionBOMLine."No.");
        PlanningComponents."Quantity per".AssertEquals(ProductionBOMLine.Quantity);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure PlanningRoutingPageHandler(var PlanningRouting: TestPage "Planning Routing")
    var
        Item: Record Item;
        RoutingLine: Record "Routing Line";
    begin
        PlanningRouting.First();
        Item.Get(GlobalChildItemNo);
        RoutingLine.SetRange("Routing No.", Item."Routing No.");
        RoutingLine.FindFirst();

        // Verify That Operation No. And Type Is same as on Routing Line.
        PlanningRouting."Operation No.".AssertEquals(RoutingLine."Operation No.");
        PlanningRouting.Type.AssertEquals(RoutingLine.Type);
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure InvokeSelectMultiItemsFromPlanningComponentPageHandler(var PlanningComponents: TestPage "Planning Components")
    begin
        PlanningComponents.SelectMultiItems.Invoke();
    end;

    [ModalPageHandler]
    procedure PurchOrderFromSalesOrderWithVendorNoModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Vendor.SetValue(LibraryVariableStorage.DequeueText());
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PurchOrderFromSalesOrderLookupVendorNoModalPageHandler(var PurchOrderFromSalesOrder: TestPage "Purch. Order From Sales Order")
    begin
        PurchOrderFromSalesOrder.Vendor.Lookup();
        PurchOrderFromSalesOrder.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ItemVendorCatalogModalPageHandler(var ItemVendorCatalog: TestPage "Item Vendor Catalog")
    begin
        ItemVendorCatalog.FILTER.SetFilter("Vendor No.", LibraryVariableStorage.DequeueText());
        ItemVendorCatalog.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        ItemList.OK().Invoke();
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure SelectCancelMultiItemsModalPageHandler(var ItemList: TestPage "Item List")
    begin
        ItemList.Next();
        ItemList.Cancel().Invoke();
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ModalPageHandler]
    procedure ModalPageHandler(var CreateOrderFromSales: Page "Create Order From Sales"; var Response: Action)
    begin
        Response := Action::Yes;
    end;

    [MessageHandler]
    procedure ErrorMessageHandler(Message: Text[1024])
    begin
    end;
}

