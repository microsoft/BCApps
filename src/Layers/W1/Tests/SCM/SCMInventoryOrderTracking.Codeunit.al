codeunit 137250 "SCM Inventory Order Tracking"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Order Tracking] [SCM]
        isInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        WhseItemLineRegister: Label 'Do you want to register the journal lines?';
        WhseItemLineRegistered: Label 'The journal lines were successfully registered.';
        OrderTrackingPolicyMsg: Label 'The change will not affect existing entries.';
        OpenOrderTrackingMsg: Label 'There are no order tracking entries for this line.';

    [Test]
    [HandlerFunctions('ConfirmHandler,MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForReleasedProductionOrder()
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify Order Tracking Line for Released Production Order created after Calculate Regenerative Plan and Carry Out Action Message on Planning Worksheet.

        // Setup.
        Initialize();
        SetupForReleasedProductionOrder(ProdOrderLine);

        // Exercise: Open Order Tracking Page.
        OpenOrderTrkgForProduction(ProdOrderLine);

        // Verify: Verify Order Tracking Line for Production Order. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgFromPlannedProdOrder()
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        Quantity: Decimal;
    begin
        // Setup: Create Production and Component Item.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. on Production Item and creation of Planned & Firm Planned Production Orders.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per quantity is 1 in BOM Line.
        Quantity := LibraryRandom.RandInt(50);  // Random Integer Value required.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ProductionOrder."Source Type"::Item, ProductionItem."No.", Quantity,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CreateAndRefreshProdOrder(
          ProductionOrder2, ProductionOrder2.Status::"Firm Planned", ProductionOrder2."Source Type"::Item, ComponentItem2."No.", Quantity,
          WorkDate());
        EnqueueForOrderTracking(ProductionOrder2.Quantity, Quantity, 0, ProductionOrder2."Source No.");  // Enqueue values for Order Tracking page handler.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder2.Status, ProductionOrder2."Source No.", '');  // Use blank for Location Code.

        // Exercise: Check order tracking for Firm Planned Production Order Line.
        OpenOrderTrkgForProduction(ProdOrderLine);

        // Verify: Verify Order Tracking Line for Firm Planned Production Order Line which have Component Item, used in another Released Prod. Order as a component. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForCompFromPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Verify Order Tracking Line for Firm Planned Production Order Component Item, which have Planned Production Order.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);  // Random Integer Value required.
        SetupForOrderTracking(ProductionOrder, Quantity);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder);
        ProdOrderComponent.FindFirst();  // Find component Item 1.
        EnqueueForOrderTracking(ProductionOrder.Quantity, -Quantity, 0, ProdOrderComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check order tracking for Component items of Firm Planned Production Order Line.
        OpenOrderTrkgForProductionComponent(ProdOrderComponent);

        // Verify: Verify Order Tracking Line for Firm Planned Production Order Component Item. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForUnpalnnedCompOnFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        Quantity: Decimal;
    begin
        // Verify Order Tracking Line for Firm Planned Production Order Component Item which used in another Firm Planned Prod. Order as a Component Item.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(50);  // Random Integer Value required.
        SetupForOrderTracking(ProductionOrder, Quantity);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder);
        ProdOrderComponent.FindLast();  // Find component Item 2.
        EnqueueForOrderTracking(ProductionOrder.Quantity, -Quantity, 0, ProdOrderComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check order tracking for Component items of Firm Planned Production Order Line.
        OpenOrderTrkgForProductionComponent(ProdOrderComponent);

        // Verify: Verify Order Tracking Line for Firm Planned Production Order Component Item. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForPlanningCompFromPurchOrder()
    var
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        Quantity: Decimal;
        PurchaseQuantity: Decimal;
        UntrackedQuantity: Decimal;
    begin
        // Verify Order Tracking Line for Planning line Component Item, which have Purchase Order.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(15);  // Random Integer Value required.
        PurchaseQuantity := Quantity + LibraryRandom.RandInt(5);
        SetupForPlanningWkstComponentOrderTrkg(RequisitionLine, Quantity, PurchaseQuantity);
        UntrackedQuantity := RequisitionLine.Quantity - PurchaseQuantity;
        FindPlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.FindFirst();  // Find Component Item 1.
        EnqueueForOrderTracking(
          RequisitionLine.Quantity, UntrackedQuantity - RequisitionLine.Quantity, UntrackedQuantity, PlanningComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise.
        OpenOrderTrkgForPlanningComponent(PlanningComponent);

        // Verify: Verify Order Tracking Line for Planning line Component Item. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForPlanningCompFromPlanningLine()
    var
        RequisitionLine: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        Quantity: Decimal;
        PurchaseQuantity: Decimal;
        UntrackedQuantity: Decimal;
    begin
        // Verify Order Tracking Line for Planning line Component Item, which have another Planning line.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(15);  // Random Integer Value required.
        PurchaseQuantity := Quantity + LibraryRandom.RandInt(5);
        SetupForPlanningWkstComponentOrderTrkg(RequisitionLine, Quantity, PurchaseQuantity);
        UntrackedQuantity := RequisitionLine.Quantity - Quantity;
        FindPlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.FindLast();  // Find Component Item 2.
        EnqueueForOrderTracking(
          RequisitionLine.Quantity, UntrackedQuantity - RequisitionLine.Quantity, UntrackedQuantity, PlanningComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise.
        OpenOrderTrkgForPlanningComponent(PlanningComponent);

        // Verify: Verify Order Tracking Line for Planning line Component Item. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForRelProdOrderFromPlanningLine()
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        RequisitionLine: Record "Requisition Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        SchedulingDirection: Option Back;
        UntrackedQuantity: Decimal;
        Quantity: Decimal;
        TemplateType: Option "Req.","For. Labor",Planning;
    begin
        // Verify: Verify Order Tracking Line for Component Item on Released Production Order Line, which have Planning Line and used as component of Production item on Planning Line.

        // Setup: Create Production and Component Item.
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking & Action Msg.");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase,
          ComponentItem2."Order Tracking Policy"::"Tracking & Action Msg.");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order",
          ProductionItem."Order Tracking Policy"::"Tracking & Action Msg.");

        // Update BOM No. on Production Item and creation of Planning Line, Calculate Quantity and Untracked Quantity.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per quantity is 1 in BOM Line.
        Quantity := LibraryRandom.RandInt(15);  // Random Integer Value required.
        CreateRequisitiontLine(RequisitionLine, TemplateType::Planning, ComponentItem2."No.", Quantity, WorkDate());
        UntrackedQuantity := Quantity;  // Save Planning Line Quantity for ComponentItem2 as a Untracked Quantity.
        CreateRequisitiontLine(
          RequisitionLine, TemplateType::Planning, ProductionItem."No.", Quantity + LibraryRandom.RandInt(5),
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));

        // Refresh Planning and Production Order & Create Released Production Orders.
        FindRequisitionLine(RequisitionLine, ProductionItem."No.", '');  // Used blank for Location.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, SchedulingDirection::Back, true, true);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ComponentItem2."No.",
          RequisitionLine.Quantity, WorkDate());
        Quantity := RequisitionLine.Quantity - UntrackedQuantity;  // Calculate Order Tracking quantity.
        EnqueueForOrderTracking(ProductionOrder.Quantity, Quantity, UntrackedQuantity, ProductionOrder."Source No.");  // Enqueue values for Order Tracking page handler.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."Source No.", '');  // Use blank for Location Code.

        // Excercise. Check order tracking for Released Production Order Line.
        OpenOrderTrkgForProduction(ProdOrderLine);

        // Verify: Verify Order Tracking Line for Component Item on Released Production Order Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgFromItemLedgerEntry()
    var
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        PurchaseQuantity: Decimal;
        Quantity: Decimal;
        UntrackedQuantity: Decimal;
    begin
        // Verify Order Tracking Line for Component Lines of Planning Worksheet Line, component item partially received from purchase order.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Random Integer Value required.
        PurchaseQuantity := Quantity + LibraryRandom.RandInt(10);  // Purchase Quantity should be more than Requisition Line Quantity.
        SetupForPlanningWkshLineOrderTrkg(RequisitionLine, Quantity, PurchaseQuantity);
        FindPlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.FindFirst();  // Find Component Item 1.
        UntrackedQuantity := RequisitionLine.Quantity - PurchaseQuantity;
        EnqueueForOrderTracking(
          RequisitionLine.Quantity, UntrackedQuantity - RequisitionLine.Quantity, UntrackedQuantity, PlanningComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check order tracking for Requistition Line Component Items.
        OpenOrderTrkgForPlanningComponent(PlanningComponent);

        // Verify Order Tracking Line for Component Lines of Planning Worksheet Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgFromPlanningWksh()
    var
        PlanningComponent: Record "Planning Component";
        RequisitionLine: Record "Requisition Line";
        PurchaseQuantity: Decimal;
        Quantity: Decimal;
        UntrackedQuantity: Decimal;
    begin
        // Verify Order Tracking Line for Component Lines of Planning Worksheet Line, component item partially exist in Planning Worksheet Line.

        // Setup.
        Initialize();
        Quantity := LibraryRandom.RandInt(10);  // Random Integer Value required.
        PurchaseQuantity := Quantity + LibraryRandom.RandInt(10);  // Purchase Quantity should be more than Requisition Line Quantity.
        SetupForPlanningWkshLineOrderTrkg(RequisitionLine, Quantity, PurchaseQuantity);
        FindPlanningComponent(PlanningComponent, RequisitionLine);
        PlanningComponent.FindLast();  // Find Component Item 2.
        UntrackedQuantity := RequisitionLine.Quantity - Quantity;
        EnqueueForOrderTracking(
          RequisitionLine.Quantity, UntrackedQuantity - RequisitionLine.Quantity, UntrackedQuantity, PlanningComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check order tracking for Requistition Line Component Items.
        OpenOrderTrkgForPlanningComponent(PlanningComponent);

        // Verify Order Tracking Line for Component Lines of Planning Worksheet Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgOnRlsdProdOrderFromPlanningWkshLine()
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem: Record Item;
        ComponentItem3: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
        UntrackedQuantity: Decimal;
        Direction: Option Forward,Backward;
        TemplateType: Option "Req.","For. Labor",Planning;
    begin
        // Verify Order Tracking Line for Released Production Order after creating Planning Line for Source item.

        // Setup: Create Production and Component Item.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem3, ComponentItem3."Replenishment System"::Purchase, ComponentItem3."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. on Production Item and creation of Planning Line.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per Quantity is 1 in BOM Line.
        Quantity := LibraryRandom.RandInt(10);  // Random Integer Value required.
        CreateRequisitiontLine(RequisitionLine, TemplateType::Planning, ComponentItem2."No.", Quantity, WorkDate());
        UntrackedQuantity := Quantity;  // Save Planning Line Quantity for ComponentItem2 as a Untracked Quantity.
        CreateRequisitiontLine(
          RequisitionLine, TemplateType::Planning, ProductionItem."No.", Quantity + LibraryRandom.RandInt(10),
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        FindRequisitionLine(RequisitionLine, ProductionItem."No.", '');
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Forward, true, true);

        // Creation of Released Production Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ComponentItem2."No.",
          RequisitionLine.Quantity, WorkDate());
        Quantity := ProductionOrder.Quantity - UntrackedQuantity;  // Save Reserve Quantity from Rel. Prod. Order as a Quantity.
        EnqueueForOrderTracking(ProductionOrder.Quantity, Quantity, UntrackedQuantity, ProductionOrder."Source No.");  // Enqueue values for Order Tracking page handler.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."Source No.", '');  // Use blank for Location Code.

        // Exercise: Check order tracking for Released Production Order Line.
        OpenOrderTrkgForProduction(ProdOrderLine);

        // Verify: Verify Order Tracking Line for Released Production Order Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgOnFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify Order Tracking Line for Firm Planned Production Order Line.

        // Setup.
        Initialize();
        SetupForFirmPlannedProdOrderLine(ProductionOrder, false);
        EnqueueForOrderTracking(ProductionOrder.Quantity, ProductionOrder.Quantity, 0, ProductionOrder."Source No.");  // Enqueue values for Order Tracking page handler.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."Source No.", '');  // Use blank for Location Code.

        // Exercise: Check order tracking for Firm Planned Production Order Line.
        OpenOrderTrkgForProduction(ProdOrderLine);

        // Verify: Verify Order Tracking Line for Firm Planned Production Order Line which have Component Item as a source item. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgOnCompOfFirmPlannedProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Verify Order Tracking Line for Component Line of Firm Planned Production Order.

        // Setup.
        Initialize();
        SetupForFirmPlannedProdOrderLine(ProductionOrder, true);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder);
        ProdOrderComponent.FindFirst();  // Find component Item 1.
        EnqueueForOrderTracking(ProductionOrder.Quantity, -ProductionOrder.Quantity, 0, ProdOrderComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check order tracking for Firm Planned Production Order's Component Items.
        OpenOrderTrkgForProductionComponent(ProdOrderComponent);

        // Verify: Verify Order Tracking Line for Firm Planned Production Order Component which used in Planned Prod. Order as a Source Item. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgFromRlsdProdOrder()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Verify Order Tracking Line for Component Lines of Released Production Order, component item have another Released Production Order.

        // Setup.
        Initialize();
        SetupForRlsdProdOrderComponentLineTrkg(ProductionOrder);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder);
        ProdOrderComponent.FindLast();  // Find component Item 2.
        EnqueueForOrderTracking(ProductionOrder.Quantity, -ProductionOrder.Quantity, 0, ProdOrderComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check Production Order's Component Lines Order Tracking.
        OpenOrderTrkgForProductionComponent(ProdOrderComponent);

        // Verify: Verify Order Tracking Line for Production Order Component Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgFromRequisitionLine()
    var
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Verify Order Tracking Line for Component Lines of Released Production Order, component item have Requisition Line.

        // Setup.
        Initialize();
        SetupForRlsdProdOrderComponentLineTrkg(ProductionOrder);
        FindProdOrderComponent(ProdOrderComponent, ProductionOrder);
        ProdOrderComponent.FindFirst();  // Find component Item 1.
        EnqueueForOrderTracking(ProductionOrder.Quantity, -ProductionOrder.Quantity, 0, ProdOrderComponent."Item No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check Production Order's Component Lines Order Tracking.
        OpenOrderTrkgForProductionComponent(ProdOrderComponent);

        // Verify: Verify Order Tracking Line for Produciton Order Component Line from Requisition Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForPostedPurchaseReceipt()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Verify Order Tracking for Purchase Receipt Line.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only");
        Quantity := LibraryRandom.RandInt(5);  // Random Integer Value required.
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", Quantity);
        EnqueueForOrderTracking(Quantity, Quantity, Quantity, Item."No.");

        // Exercise: Check Purchase Receipt Line Order Tracking.
        OpenOrderTrkgForPurchaseReceipt(PurchaseHeader."Last Receiving No.");

        // Verify: Verify Order Tracking for Purchase Receipt Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForSalesOrderLineFromUnpostedPurchOrder()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
        SalesQuantity: Decimal;
    begin
        // Verify Order Tracking for Sale Order Line which have item that reserved as a Item Ledger Entry and Purchase Order.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only");
        Quantity := LibraryRandom.RandInt(5);  // Random Integer Value required.
        SalesQuantity := Quantity + LibraryRandom.RandInt(5);  // Random Integer Value required.
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", Quantity);

        // Create Purchase Order and Sales Order
        CreatePurchaseDocument(PurchaseHeader, Item."No.", SalesQuantity - Quantity);
        CreateSalesOrder(SalesLine, '', Item."No.", SalesQuantity);  // Used blank for Location Code.

        EnqueueForOrderTracking(SalesLine.Quantity, -Quantity, 0, Item."No.");  // Enqueue values for Order Tracking page handler.
        EnqueueForOrderTracking(SalesLine.Quantity, Quantity - SalesQuantity, 0, Item."No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check Sales Order Line Order Tracking.
        OpenOrderTrkgForSales(SalesLine);

        // Verify: Verify Order Tracking Line for Sales Order Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForSalesOrderLineFromPostedPurchOrder()
    var
        Item: Record Item;
        SalesLine: Record "Sales Line";
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
        SalesQuantity: Decimal;
    begin
        // Verify Order Tracking for Sale Order Line which have item that reserved as a Item Ledger Entry.

        // Setup.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking Only");
        Quantity := LibraryRandom.RandInt(5);  // Random Integer Value required.
        CreateAndPostPurchaseOrder(PurchaseHeader, Item."No.", Quantity);
        SalesQuantity := Quantity + LibraryRandom.RandInt(5);  // Random Integer Value required.
        CreateSalesOrder(SalesLine, '', Item."No.", SalesQuantity);  // Used blank for Location Code.
        EnqueueForOrderTracking(SalesLine.Quantity, -Quantity, SalesQuantity - Quantity, Item."No.");  // Enqueue values for Order Tracking page handler.

        // Exercise: Check Sales Order Line Order Tracking.
        OpenOrderTrkgForSales(SalesLine);

        // Verify: Verify Order Tracking Line for Sales Order Line. Verification done in OrderTrackingPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler,OrderTrackingHdrPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrkgForSimulatedProdOrder()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        // Verify Order Tracking for Simulated Production Order Line which have item that exist in another Simulated Prod. Order and Sales Quotes.

        // Setup: Create Item, Simulated Production Order, Sales Quote.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking & Action Msg.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Simulated, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(35), WorkDate());
        CreateAndRefreshProdOrder(
          ProductionOrder2, ProductionOrder2.Status::Simulated, ProductionOrder2."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(30), WorkDate());
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Quote, CreateCustomer(''));  // Used blank for Location Code.
        LibrarySales.CreateSalesLine(
          SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", ProductionOrder.Quantity + ProductionOrder2.Quantity);

        LibraryVariableStorage.Enqueue(OpenOrderTrackingMsg); // Enqueue value for message handler.
        EnqueueForOrderTracking(ProductionOrder.Quantity, ProductionOrder.Quantity, ProductionOrder.Quantity, ProductionOrder."Source No.");  // Enqueue values for Order Tracking page handler.
        FindProductionOrderLine(ProdOrderLine, ProductionOrder.Status, ProductionOrder."Source No.", '');  // Used blank for Location Code.

        // Exercise: Check Simulated Prod. Order Line Order Tracking.
        OpenOrderTrkgForProduction(ProdOrderLine);

        // Verify: Verify Order Tracking for Simulated Production Order Line. Verification done in OrderTrackingHdrPageHandler.
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NoOrderTrackingForItemJournalLine()
    var
        Item: Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ReservationEntry: Record "Reservation Entry";
        ReservationManagement: Codeunit "Reservation Management";
        Qty: Decimal;
    begin
        // [FEATURE] [Item Journal]
        // [SCENARIO 372762] No order tracking is created for item journal line.
        Initialize();
        Qty := LibraryRandom.RandInt(10);

        // [GIVEN] Item with enabled Order Tracking.
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Order Tracking Policy"::"Tracking & Action Msg.");

        // [GIVEN] Create and post item journal line for 10 pcs.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Create item journal line for -10 pcs.
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", '', '', -Qty);

        // [WHEN] Auto-track the negative item journal line.
        ReservationManagement.SetReservSource(ItemJournalLine);
        ReservationManagement.AutoTrack(ItemJournalLine.Quantity);

        // [THEN] No order tracking has been established between inventory and the negative adjustment.
        ReservationEntry.SetRange("Item No.", Item."No.");
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Tracking);
        Assert.RecordIsEmpty(ReservationEntry);

        // [THEN] All remaining stock is tracked as "Surplus".
        ReservationEntry.SetRange("Reservation Status", ReservationEntry."Reservation Status"::Surplus);
        ReservationEntry.CalcSums(Quantity);
        ReservationEntry.TestField(Quantity, Qty);

        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Inventory Order Tracking");
        LibraryVariableStorage.Clear();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Inventory Order Tracking");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Inventory Order Tracking");
    end;

    local procedure CalcRegenPlanAndCarryOutActionMsg(Item: Record Item; LocationCode: Code[10])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), CalcDate('<CY>', WorkDate()));  // Dates based on WORKDATE.
        FindRequisitionLine(RequisitionLine, Item."No.", LocationCode);
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; BaseUnitOfMeasure: Code[10]; No: Code[20])
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, BaseUnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, No, 1);  // Use blank value for Version Code and 1 for Quantity per.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    local procedure CreateAndPostPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; No: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseDocument(PurchaseHeader, No, Quantity);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; SourceType: Enum "Prod. Order Source Type"; SourceNo: Code[20]; Quantity: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, SourceType, SourceNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
        ProductionOrder.Get(ProductionOrder.Status, ProductionOrder."No.");
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        UpdateProdOrderLine(ProductionOrder);
    end;

    local procedure CreateCustomer(LocationCode: Code[10]): Code[20]
    var
        Customer: Record Customer;
    begin
        LibrarySales.CreateCustomer(Customer);
        Customer.Validate("Location Code", LocationCode);
        Customer.Modify(true);
        exit(Customer."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateItemJournalBatch(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalBatch."Template Type"::Item);
        LibraryInventory.CreateItemJournalBatch(ItemJournalBatch, ItemJournalTemplate.Name);
        ItemJournalBatch.Validate("No. Series", LibraryUtility.GetGlobalNoSeriesCode());
        ItemJournalBatch.Modify(true);
    end;

    local procedure CreatePurchaseDocument(var PurchaseHeader: Record "Purchase Header"; No: Code[20]; Quantity: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendor());
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, No, Quantity);
    end;

    local procedure CreateRequisitiontLine(var RequisitionLine: Record "Requisition Line"; TemplateType: Option; ItemNo: Code[20]; Quantity: Integer; DueDate: Date)
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        FindWorksheetTemplate(RequisitionWkshName, TemplateType);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", ItemNo);
        RequisitionLine.Validate(Quantity, Quantity);
        RequisitionLine.Validate("Due Date", DueDate);  // Required Due Date less Prod. Order Date.
        RequisitionLine.Validate("Action Message", RequisitionLine."Action Message"::New);
        RequisitionLine.Validate("Starting Date", CalcDate('<-1D>', DueDate));  // Take 1 because Starting Date and Ending Date should be just less than 1day of Due Date.
        RequisitionLine.Validate("Ending Date", RequisitionLine."Starting Date");
        RequisitionLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesLine: Record "Sales Line"; LocationCode: Code[10]; No: Code[20]; Quantity: Decimal)
    var
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, CreateCustomer(LocationCode));
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, No, CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()),
          Quantity);  // Use Random days to calculate Shipment Date.
    end;

    local procedure CreateVendor(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        exit(Vendor."No.")
    end;

    local procedure CreateWarehouseJournalLine(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; ItemNo: Code[20])
    var
        WarehouseJournalBatch: Record "Warehouse Journal Batch";
        WarehouseJournalTemplate: Record "Warehouse Journal Template";
    begin
        // Use Random value for Quantity.
        LibraryWarehouse.SelectWhseJournalTemplateName(WarehouseJournalTemplate, WarehouseJournalTemplate.Type::Item);
        LibraryWarehouse.CreateWhseJournalBatch(WarehouseJournalBatch, WarehouseJournalTemplate.Name, Bin."Location Code");
        LibraryWarehouse.CreateWhseJournalLine(
          WarehouseJournalLine, WarehouseJournalTemplate.Name, WarehouseJournalBatch.Name, Bin."Location Code", Bin."Zone Code", Bin.Code,
          WarehouseJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, LibraryRandom.RandDec(100, 2));
    end;

    local procedure EnqueueForOrderTracking(ProductionOrderQuantity: Decimal; Quantity: Decimal; UntrackedQuantity: Decimal; ItemNo: Code[20])
    begin
        // Enqueue value for verification on OrderTrackingPageHandler.
        LibraryVariableStorage.Enqueue(ProductionOrderQuantity);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue(UntrackedQuantity);
        LibraryVariableStorage.Enqueue(ItemNo);
    end;

    local procedure FindPlanningComponent(var PlanningComponent: Record "Planning Component"; RequisitionLine: Record "Requisition Line")
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
    end;

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
    end;

    local procedure FindProductionOrderLine(var ProdOrderLine: Record "Prod. Order Line"; Status: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        ProdOrderLine.SetRange(Status, Status);
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.SetRange("Location Code", LocationCode);
        ProdOrderLine.FindFirst();
    end;

    local procedure FindRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
    end;

    local procedure FindWorksheetTemplate(var RequisitionWkshName: Record "Requisition Wksh. Name"; TemplateType: Option)
    begin
        RequisitionWkshName.SetRange("Template Type", TemplateType);
        RequisitionWkshName.SetRange(Recurring, false);
        RequisitionWkshName.FindFirst();
    end;

    local procedure FindPickZone(LocationCode: Code[10]): Code[10]
    var
        Zone: Record Zone;
    begin
        Zone.SetRange("Location Code", LocationCode);
        Zone.SetRange("Bin Type Code", LibraryWarehouse.SelectBinType(false, false, true, true));
        Zone.SetRange("Cross-Dock Bin Zone", false);
        Zone.FindFirst();
        exit(Zone.Code);
    end;

    local procedure OpenOrderTrkgForPlanningComponent(PlanningComponent: Record "Planning Component")
    var
        OrderTracking: Page "Order Tracking";
    begin
        // Open Order Tracking page for required Planning Line Component.
        OrderTracking.SetPlanningComponent(PlanningComponent);
        OrderTracking.RunModal();
    end;

    local procedure OpenOrderTrkgForProduction(ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.ShowOrderTracking();
    end;

    local procedure OpenOrderTrkgForProductionComponent(ProdOrderComponent: Record "Prod. Order Component")
    begin
        ProdOrderComponent.ShowOrderTracking();
    end;

    local procedure OpenOrderTrkgForPurchaseReceipt(No: Code[20])
    var
        PostedPurchaseReceipt: TestPage "Posted Purchase Receipt";
    begin
        // Open Order Tracking page for required Posted Purchase Receipt.
        PostedPurchaseReceipt.OpenView();
        PostedPurchaseReceipt.FILTER.SetFilter("No.", No);
        PostedPurchaseReceipt.PurchReceiptLines.OrderTracking.Invoke();
    end;

    local procedure OpenOrderTrkgForSales(SalesLine: Record "Sales Line")
    begin
        // Open Order Tracking page for required Sales Order.
        SalesLine.ShowOrderTracking();
    end;

    local procedure SetupForOrderTracking(var ProductionOrder2: Record "Production Order"; Quantity: Decimal)
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionOrder3: Record "Production Order";
    begin
        // Setup: Create Production and Component Item.
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. on Production Item and creation of Planned & Firm Planned Production Orders.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per quantity is 1 in BOM Line.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Planned, ProductionOrder."Source Type"::Item, ComponentItem."No.", Quantity, WorkDate());
        CreateAndRefreshProdOrder(
          ProductionOrder2, ProductionOrder2.Status::"Firm Planned", ProductionOrder2."Source Type"::Item, ProductionItem."No.", Quantity,
          CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CreateAndRefreshProdOrder(
          ProductionOrder3, ProductionOrder3.Status::"Firm Planned", ProductionOrder3."Source Type"::Item, ComponentItem2."No.", Quantity,
          WorkDate());
    end;

    local procedure SetupForFirmPlannedProdOrderLine(var ProductionOrder3: Record "Production Order"; IsComponentOrderTracking: Boolean)
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ComponentItem3: Record Item;
        ProductionItem: Record Item;
        ProductionItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMHeader2: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
    begin
        // Create Production and Component items.
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem3, ComponentItem3."Replenishment System"::Purchase, ComponentItem3."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem2, ProductionItem2."Replenishment System"::Purchase, ProductionItem2."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. in Production Items and creation of Released & Firm Planned Porduction Orders.
        UpdateItemForBomNo(
          ProductionItem2."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader2, ComponentItem3."No.", ComponentItem2."No.", 1));  // Component Item per Quantity is 1 in BOM Line.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per Quantity is 1 in BOM Line.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ComponentItem."No.",
          LibraryRandom.RandInt(50), WorkDate());
        CreateAndRefreshProdOrder(
          ProductionOrder2, ProductionOrder2.Status::"Firm Planned", ProductionOrder2."Source Type"::Item, ProductionItem."No.",
          ProductionOrder.Quantity, CalcDate('<' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CreateAndRefreshProdOrder(
          ProductionOrder3, ProductionOrder3.Status::"Firm Planned", ProductionOrder3."Source Type"::Item, ComponentItem2."No.",
          ProductionOrder.Quantity, WorkDate());

        if IsComponentOrderTracking then
            ProductionOrder3 := ProductionOrder2;
    end;

    local procedure SetupForPlanningWkstComponentOrderTrkg(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal; PurchaseQuantity: Decimal)
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem: Record Item;
        PurchaseHeader: Record "Purchase Header";
        ProductionBOMHeader: Record "Production BOM Header";
        SchedulingDirection: Option Back;
        TemplateType: Option "Req.","For. Labor",Planning;
    begin
        // Setup: Create Production and Component Item.
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. on Production Item and creation of Planned & Firm Planned Production Orders.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per quantity is 1 in BOM Line.
        CreateRequisitiontLine(RequisitionLine, TemplateType::Planning, ComponentItem2."No.", Quantity, WorkDate());
        CreateAndPostPurchaseOrder(PurchaseHeader, ComponentItem."No.", PurchaseQuantity);
        CreateRequisitiontLine(
          RequisitionLine, TemplateType::Planning, ProductionItem."No.", PurchaseQuantity + LibraryRandom.RandInt(5),
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        FindRequisitionLine(RequisitionLine, ProductionItem."No.", '');  // Used blank for Location.
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, SchedulingDirection::Back, true, true);
    end;

    local procedure SetupForPlanningWkshLineOrderTrkg(var RequisitionLine: Record "Requisition Line"; Quantity: Decimal; PurchaseQuantity: Decimal)
    var
        ComponentItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        PurchaseHeader: Record "Purchase Header";
        Direction: Option Forward,Backward;
        TemplateType: Option "Req.","For. Labor",Planning;
    begin
        // Creating 3 Component Items and 2 Production Items with Order Tacking Policy and Replanishment System.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. on Production Item.
        UpdateItemForBomNo(
          ProductionItem."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem."No.", ComponentItem2."No.", 1));  // Component Item per Quantity is 1 in BOM Line.

        // Creation of Planning Worksheet and Recieve/Invoice of Purchase Order.
        CreateRequisitiontLine(RequisitionLine, TemplateType::Planning, ComponentItem2."No.", Quantity, WorkDate());
        FindRequisitionLine(RequisitionLine, ComponentItem2."No.", '');
        CreateAndPostPurchaseOrder(PurchaseHeader, ComponentItem."No.", PurchaseQuantity);
        CreateRequisitiontLine(
          RequisitionLine, TemplateType::Planning, ProductionItem."No.", PurchaseQuantity + LibraryRandom.RandInt(5),
          CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        FindRequisitionLine(RequisitionLine, ProductionItem."No.", '');
        LibraryPlanning.RefreshPlanningLine(RequisitionLine, Direction::Forward, true, true);
    end;

    local procedure SetupForReleasedProductionOrder(var ProdOrderLine: Record "Prod. Order Line")
    var
        Bin: Record Bin;
        ChildItem: Record Item;
        ParentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        SalesLine: Record "Sales Line";
        WarehouseJournalLine: Record "Warehouse Journal Line";
    begin
        // Create Production Item. Create and register Warehouse Journal Line. Create and post Item journal Line for child Item after Calculating Whse. Adjustment. Create Sales Order. Calculate Regenerative Plan and Carry Out Action Message on Planning
        // Worksheet. Change Status of create Production Order from Firm Planned to Released.

        // Enqueue value for message handler.dler.
        LibraryVariableStorage.Enqueue(WhseItemLineRegister);
        LibraryVariableStorage.Enqueue(WhseItemLineRegistered);

        WhiteLocationSetup(Bin);
        CreateItem(ParentItem, ParentItem."Replenishment System"::"Prod. Order", ParentItem."Order Tracking Policy"::None);
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, ChildItem."Order Tracking Policy"::None);
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ParentItem."Base Unit of Measure", ChildItem."No.");
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);

        UpdateInventoryFromWarehouseJournal(WarehouseJournalLine, Bin, ChildItem);
        CreateSalesOrder(SalesLine, Bin."Location Code", ParentItem."No.", WarehouseJournalLine.Quantity / 2);  // Take less Quantity for Sales Order.

        // Enqueue value for verification on OrderTrackingPageHandler.
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);
        LibraryVariableStorage.Enqueue(SalesLine.Quantity);  // Enqueue to handle Negative value in Order Tracking test case
        LibraryVariableStorage.Enqueue(0);  // Taken zero value for Untracked Quantity on Order Tracking.
        LibraryVariableStorage.Enqueue(SalesLine."No.");

        CalcRegenPlanAndCarryOutActionMsg(ParentItem, Bin."Location Code");
        FindProductionOrderLine(ProdOrderLine, ProdOrderLine.Status::"Firm Planned", ParentItem."No.", Bin."Location Code");
        LibraryManufacturing.ChangeStatusFirmPlanToReleased(ProdOrderLine."Prod. Order No.");
        FindProductionOrderLine(ProdOrderLine, ProdOrderLine.Status::Released, ParentItem."No.", Bin."Location Code");
    end;

    local procedure SetupForRlsdProdOrderComponentLineTrkg(var ProductionOrder2: Record "Production Order")
    var
        ComponentItem: Record Item;
        ProductionItem: Record Item;
        ComponentItem2: Record Item;
        ProductionItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        TemplateType: Option "Req.","For. Labor",Planning;
    begin
        // Setup. Create 3 Component Items and 2 Production Items with Order Tacking Policy and Replanishment System.
        Initialize();
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(ComponentItem, ComponentItem."Replenishment System"::Purchase, ComponentItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem, ProductionItem."Replenishment System"::"Prod. Order", ProductionItem."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ComponentItem2, ComponentItem2."Replenishment System"::Purchase, ComponentItem2."Order Tracking Policy"::"Tracking Only");
        LibraryVariableStorage.Enqueue(OrderTrackingPolicyMsg);  // Enqueue value for message handler.
        CreateItem(
          ProductionItem2, ProductionItem2."Replenishment System"::Purchase, ProductionItem2."Order Tracking Policy"::"Tracking Only");

        // Update BOM No. in Production Items and creation of Released Porduction Order and Requisition Line.
        UpdateItemForBomNo(
          ProductionItem2."No.",
          LibraryManufacturing.CreateCertifProdBOMWithTwoComp(
            ProductionBOMHeader, ComponentItem2."No.", ComponentItem."No.", 1));  // Component Item per Quantity is 1 in BOM Line.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ComponentItem2."No.",
          LibraryRandom.RandInt(50), CalcDate('<-' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        CreateRequisitiontLine(
          RequisitionLine, TemplateType::"Req.", ComponentItem."No.", ProductionOrder.Quantity,
          CalcDate('<-' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate()));
        CreateAndRefreshProdOrder(
          ProductionOrder2, ProductionOrder2.Status::Released, ProductionOrder2."Source Type"::Item, ProductionItem2."No.",
          ProductionOrder.Quantity, WorkDate());
    end;

    local procedure UpdateInventoryFromWarehouseJournal(var WarehouseJournalLine: Record "Warehouse Journal Line"; Bin: Record Bin; Item: Record Item)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        CreateWarehouseJournalLine(WarehouseJournalLine, Bin, Item."No.");
        LibraryWarehouse.RegisterWhseJournalLine(
          WarehouseJournalLine."Journal Template Name", WarehouseJournalLine."Journal Batch Name", WarehouseJournalLine."Location Code",
          false);  // false for Batch Job.
        CreateItemJournalBatch(ItemJournalBatch);
        LibraryWarehouse.CalculateWhseAdjustment(Item, ItemJournalBatch);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateItemForBomNo(ItemNo: Code[20]; ProdctionBOMNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Production BOM No.", ProdctionBOMNo);
        Item.Modify(true);
    end;

    local procedure UpdateProdOrderLine(ProductionOrder: Record "Production Order")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
        ProdOrderLine.Validate("Due Date", ProductionOrder."Due Date");
        ProdOrderLine.Validate("Starting Date", CalcDate('<-1D>', ProdOrderLine."Due Date"));  // Take 1 because Starting Date and Ending Date should be just less than 1day of Due Date.
        ProdOrderLine.Validate("Ending Date", ProdOrderLine."Starting Date");
        ProdOrderLine.Modify(true);
    end;

    local procedure VerifyOrderTracking(var OrderTracking: TestPage "Order Tracking")
    var
        UntrackedQuantity: Variant;
        TotalQuantity: Variant;
        Quantity: Variant;
        ItemNo: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(TotalQuantity);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(UntrackedQuantity);
        LibraryVariableStorage.Dequeue(ItemNo);

        OrderTracking.CurrItemNo.AssertEquals(ItemNo);
        OrderTracking."Total Quantity".AssertEquals(TotalQuantity);
        OrderTracking."Untracked Quantity".AssertEquals(UntrackedQuantity);
        OrderTracking."Item No.".AssertEquals(ItemNo);
        OrderTracking.Quantity.AssertEquals(Quantity);
    end;

    local procedure VerifyOrderTrackingHeader(var OrderTracking: TestPage "Order Tracking")
    var
        UntrackedQuantity: Variant;
        TotalQuantity: Variant;
        Quantity: Variant;
        ItemNo: Variant;
    begin
        // Dequeue variables.
        LibraryVariableStorage.Dequeue(TotalQuantity);
        LibraryVariableStorage.Dequeue(Quantity);
        LibraryVariableStorage.Dequeue(UntrackedQuantity);
        LibraryVariableStorage.Dequeue(ItemNo);

        OrderTracking.CurrItemNo.AssertEquals(ItemNo);
        OrderTracking."Total Quantity".AssertEquals(TotalQuantity);
        OrderTracking."Untracked Quantity".AssertEquals(UntrackedQuantity);
        OrderTracking."Total Quantity".AssertEquals(Quantity);
    end;

    local procedure WhiteLocationSetup(var Bin: Record Bin)
    var
        Location: Record Location;
        WarehouseEmployee: Record "Warehouse Employee";
    begin
        LibraryWarehouse.CreateFullWMSLocation(Location, 1);  // Use 1 for No. of Bins per Zone.
        LibraryWarehouse.CreateWarehouseEmployee(WarehouseEmployee, Location.Code, true);
        LibraryWarehouse.FindBin(Bin, Location.Code, FindPickZone(Location.Code), 1);  // 1 is for Bin Index.
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(ConfirmMessage: Text[1024]; var Reply: Boolean)
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(ConfirmMessage, ExpectedMessage) > 0, ConfirmMessage);
        Reply := true;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text[1024])
    var
        ExpectedMessage: Variant;
    begin
        LibraryVariableStorage.Dequeue(ExpectedMessage);  // Dequeue Variable.
        Assert.IsTrue(StrPos(Message, ExpectedMessage) > 0, Message);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        // Verify required Quantity values - Total Quantity, Untracked Quantity, Quantity and Item No.
        VerifyOrderTracking(OrderTracking);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingHdrPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        // Verify required Quantity values - Total Quantity, Untracked Quantity and Item No.
        VerifyOrderTrackingHeader(OrderTracking);
    end;
}

