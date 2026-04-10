codeunit 137058 "SCM Planning Transparency"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Planning] [Order Tracking] [SCM]
        isInitialized := false;
    end;

    var
        LocationBlue: Record Location;
        LocationRed: Record Location;
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryPlanning: Codeunit "Library - Planning";
        Counter: Integer;
        UntrackedQuantity: Decimal;
        TotalQuantity: Decimal;
        isInitialized: Boolean;
        TrackingMsg: Label 'The change will not affect existing entries';
        NoTrackingLinesMsg: Label 'There are no order tracking entries for this line';
        ExceptionMsg: Label 'Exception: The projected available inventory is below Safety Stock Quantity';
        AttentionMsg: Label 'Attention: The Starting Date ';
        AttentionProdOrderMsg: Label 'Attention: The Status of Prod. Order';
        SafetyStockMsg: Label 'Safety Stock Quantity';
        OrderMultipleMsg: Label 'Order Multiple';
        MinOrderQtyMsg: Label 'Minimum Order Quantity';
        ReorderPointMsg: Label 'Reorder Point';
        ReorderQtyMsg: Label 'Reorder Quantity';
        BlanketOrderMsg: Label 'Blanket Order';
        ProductionForecastMsg: Label 'Demand Forecast';
        MaximumInventoryMsg: Label 'Maximum Inventory';
        ErrUntrackedPlanningElementMsg: Label 'Untracked Planning Element Source must be same.';
        GlobalItemNo: Code[20];

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseOrderBeforeCarryOutActionMsg()
    begin
        // Setup.
        Initialize();
        OrderTrackingForPurchaseOrder(false);  // Do not run Regenerative Plan or modify Sales Order.
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseOrderCarryOutAMAndUpdateSalesQuantity()
    begin
        // Setup.
        Initialize();
        OrderTrackingForPurchaseOrder(true);  // Run Regenerative Plan, Carry Out Action message and modify Sales Order.
    end;

    local procedure OrderTrackingForPurchaseOrder(CalcPlanAndUpdateSales: Boolean)
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseQuantity: Decimal;
    begin
        // Create Item with Maximum Quantity. Create Purchase and Sales Order.
        CreateMaxQtyItem(
          Item, LibraryRandom.RandInt(5) + 5, LibraryRandom.RandInt(2), 1, Item."Replenishment System"::Purchase);  // Value important for test. Maximum Inventory, Reorder Point. Safety Stock Quantity.
        PurchaseQuantity := LibraryRandom.RandDec(5, 2) + 10;
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", PurchaseQuantity, WorkDate() + 1);  // Large Random Value required for Test, Receipt date includes safety lead time.
        // Value must be less than Purchase Order Qty.
        CreateSalesOrder(SalesHeader, Item."No.", '', PurchaseQuantity - 5, WorkDate() + 1);

        if CalcPlanAndUpdateSales then begin
            // Planning Worksheet -> Calculate Regenerative plan & Carry Out Action Message.
            LibraryPlanning.CalcRegenPlanForPlanWksh(
              Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
            CarryOutActionMessage(Item."No.");
            ModifySalesOrderQuantity(SalesHeader, '', PurchaseQuantity - 10);  // New quantity less than previous sales quantity.
        end;

        // Select Sales and Purchase Line for Expected quantities.
        SelectSalesLine(SalesLine, SalesHeader);
        SelectPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."No.");

        // Exercise & Verify: Open Order Tracking from Purchase Order page.Verification is done inside test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := PurchaseLine.Quantity - SalesLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForPurchase(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseOrderCalcRegenPlanAndCarryOutActionMsg()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseQuantity: Decimal;
    begin
        // Setup: Create Item with Purchase and Sales Order. Planning Worksheet -> Calculate Regenerative plan & Carry Out Action Message.
        Initialize();
        CreateMaxQtyItem(
          Item, LibraryRandom.RandInt(5) + 10, LibraryRandom.RandInt(10), LibraryRandom.RandInt(5),
          Item."Replenishment System"::Purchase);  // Value important for Test. Maximum Inventory,Reorder Point,Safety Stock Qty.
        PurchaseQuantity := LibraryRandom.RandDec(5, 2) + 10;
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::Order, Item."No.", PurchaseQuantity, WorkDate() + 1);  // Large Random Value required for Test, Receipt date includes safety lead time.
        // Value must be less than Purchase Order Qty. Random shipment date.
        CreateSalesOrder(
          SalesHeader, Item."No.", '', PurchaseQuantity - 5, CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));

        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        CarryOutActionMessage(Item."No.");

        // Select Sales and Purchase Lines for Expected quantities.
        SelectSalesLine(SalesLine, SalesHeader);
        SelectPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::Order, PurchaseHeader."No.");
        SelectPurchaseLine2(PurchaseLine2, PurchaseLine2."Document Type"::Order, PurchaseHeader."No.", Item."No.");

        // Exercise & Verify: Open Order Tracking from Purchase Order page. Verification is done inside test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := PurchaseLine.Quantity - SalesLine.Quantity + Item."Safety Stock Quantity";  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForPurchase(PurchaseLine);

        UntrackedQuantity := 0;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := PurchaseLine2.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForPurchase(PurchaseLine2);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseReturnOrderWithCarryOutActionMsg()
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        PurchaseLine2: Record "Purchase Line";
    begin
        // Setup: Create Create Lot for Lot item with Purchase return order, Planning Worksheet -> Calculate Regenerative plan  & Carry Out Action Message.
        Initialize();
        CreateLotForLotItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(5) + 5, LibraryRandom.RandInt(10) + 5,
          LibraryRandom.RandInt(5) + 5, 0);  // Value important for Test.
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.",
          LibraryRandom.RandInt(5), WorkDate() + 1);  // Small Random Value required for Test, Date includes safety lead time.

        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        CarryOutActionMessage(Item."No.");

        // Select Purchase Return Line and Purchase Order Line for Expected Quantities.
        SelectPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order", PurchaseHeader."No.");
        SelectPurchaseLine2(PurchaseLine2, PurchaseLine2."Document Type"::Order, PurchaseHeader."No.", Item."No.");

        // Exercise & Verify: Open Order Tracking from Purchase Order page. Verification is done inside test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := PurchaseLine2.Quantity - PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := PurchaseLine2.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForPurchase(PurchaseLine2);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseReturnOrderWithoutCarryoutMsg()
    var
        PurchaseReturnQty: Decimal;
        MinimumOrderQty: Decimal;
        SafetyStockQty: Decimal;
        OrderMultipleQty: Decimal;
    begin
        // Setup: Select Item planning parameters with Purchase return order qty. Values important for test.
        Initialize();
        MinimumOrderQty := LibraryRandom.RandInt(5) * 10;
        SafetyStockQty := MinimumOrderQty / 2;
        OrderMultipleQty := SafetyStockQty / 2;
        PurchaseReturnQty := MinimumOrderQty + OrderMultipleQty + SafetyStockQty;
        OrderTrackingForPurchaseReturnOrder(
            PurchaseReturnQty, SafetyStockQty, MinimumOrderQty, OrderMultipleQty, SelectUntrackedPlanningSource(ExceptionMsg, AttentionMsg, SafetyStockMsg, '', ''));
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseReturnOrderWithOrderMultipleQty()
    var
        PurchaseReturnQty: Decimal;
        MinimumOrderQty: Decimal;
        SafetyStockQty: Decimal;
        OrderMultipleQty: Decimal;
    begin
        // Setup: Select Item planning parameters with Purchase return order qty. Values important for test.
        Initialize();
        MinimumOrderQty := LibraryRandom.RandInt(5) * 10;
        SafetyStockQty := MinimumOrderQty / 2;
        OrderMultipleQty := SafetyStockQty / 2;
        PurchaseReturnQty := MinimumOrderQty + SafetyStockQty + 1;
        OrderTrackingForPurchaseReturnOrder(
            PurchaseReturnQty, SafetyStockQty, MinimumOrderQty, OrderMultipleQty, SelectUntrackedPlanningSource(ExceptionMsg, AttentionMsg, SafetyStockMsg, OrderMultipleMsg, ''));
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForPurchaseReturnOrderWithOrderMultipleAndMinimimOrderQty()
    var
        PurchaseReturnQty: Decimal;
        MinimumOrderQty: Decimal;
        SafetyStockQty: Decimal;
        OrderMultipleQty: Decimal;
    begin
        // Setup: Select Item planning parameters with Purchase return order qty. Values important for test.
        Initialize();
        MinimumOrderQty := LibraryRandom.RandInt(5) * 10;
        SafetyStockQty := MinimumOrderQty / 2 - 1;
        OrderMultipleQty := MinimumOrderQty / 2 + 1;
        PurchaseReturnQty := OrderMultipleQty;
        OrderTrackingForPurchaseReturnOrder(
            PurchaseReturnQty, SafetyStockQty, MinimumOrderQty, OrderMultipleQty, SelectUntrackedPlanningSource(ExceptionMsg, AttentionMsg, SafetyStockMsg, MinOrderQtyMsg, OrderMultipleMsg));
    end;

    local procedure OrderTrackingForPurchaseReturnOrder(PurchaseReturnQuantity: Decimal; SafetyStockQuantity: Decimal; MinimumOrderQuantity: Decimal; OrderMultiple: Decimal; PlanningSource: array[7] of Text[250])
    var
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Create Lot for Lot item with Purchase return order, Planning Worksheet -> Calculate Regenerative plan.
        CreateLotForLotItem(Item, Item."Replenishment System"::Purchase, SafetyStockQuantity, MinimumOrderQuantity, OrderMultiple, 0);
        CreatePurchaseOrder(
          PurchaseHeader, PurchaseHeader."Document Type"::"Return Order", Item."No.",
          PurchaseReturnQuantity, WorkDate() + 1);  // Purchase Line Quantity important for Test, Date include safety lead time.
        SelectPurchaseLine(PurchaseLine, PurchaseLine."Document Type"::"Return Order", PurchaseHeader."No.");
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Select Requisition Line for Expected Quantities.
        SelectRequisitionLine(RequisitionLine, Item."No.", '');
        RequisitionLine.Next();

        // Exercise & Verify: Open Order Tracking from Purchase Return Order page. Verify untracked Quantity is caused by Safety Stock Quantity, Minimum Order Quantity, Order Multiple in test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := RequisitionLine.Quantity - PurchaseLine.Quantity + Item."Safety Stock Quantity";  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForRequisition(RequisitionLine);

        // Verify Untracked planning elements.
        VerifyUntrackedPlanningElementSource(PlanningSource);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForItemWithFixedReorderQtyWithCarryOutMsg()
    var
        Item: Record Item;
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create item with Fixed Reorder Quantity, Planning Worksheet -> Calculate Regenerative plan.
        Initialize();
        CreateFixedReorderQtyItem(Item, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));  // Reorder Point, Reorder Quantity.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        CarryOutActionMessage(Item."No.");

        // Select Purchase Line for Expected Quantities.
        SelectPurchaseLineUsingItem(PurchaseLine, Item."No.");
        PurchaseLine.FindFirst();

        // Exercise & Verify: Open Order Tracking from Purchase Order p age. Verification is done inside test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForPurchase(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForSalesOrderWithFixedReorderQtyWithCalRegenPlan()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create item with Fixed Reorder Quantity, Create Sales Order, Planning Worksheet -> Calculate Regenerative plan.
        Initialize();
        CreateFixedReorderQtyItem(Item, LibraryRandom.RandInt(5), LibraryRandom.RandIntInRange(6, 10));  // Reorder Point, Reorder Quantity.
        // Large Random Value required for Test. Random shipment date.
        CreateSalesOrder(
          SalesHeader, Item."No.", '', LibraryRandom.RandInt(10) + 10,
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Select Sales Line and Requisition Line for Expected Quantities.
        SelectSalesLine(SalesLine, SalesHeader);
        SelectRequisitionLine(RequisitionLine, Item."No.", '');

        // Exercise & Verify: Open Order Tracking from Planning Worksheet  page. Verify untracked Quantity is caused by Reorder Quantity in test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := SelectRequisitionLineQuantity(RequisitionLine) - SalesLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForRequisition(RequisitionLine);

        SelectRequisitionLine(RequisitionLine, Item."No.", '');
        RequisitionLine.FindLast();
        UntrackedQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForRequisition(RequisitionLine);

        // Verify Untracked planning elements.
        VerifyUntrackedPlanningElementSource(ExceptionMsg, ReorderPointMsg, ReorderQtyMsg, '', '');
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForSalesOrderWithFixedReorderQtyWithCarryOutMsg()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        // Setup: Create item with Fixed Reorder Quantity,Planning Worksheet -> Calculate Regenerative plan with Carry Out Message.
        Initialize();
        CreateFixedReorderQtyItem(Item, LibraryRandom.RandInt(5), LibraryRandom.RandInt(5));  // Reorder Point, Reorder Quantity.
        CreateSalesOrder(
          SalesHeader, Item."No.", '', LibraryRandom.RandInt(10) + 10,
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));  // Large Random Value required for Test. Random shipment date.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        CarryOutActionMessage(Item."No.");

        // Select Sales Line for Expected Quantities.
        SelectSalesLine(SalesLine, SalesHeader);
        SelectPurchaseLineUsingItem(PurchaseLine, Item."No.");
        PurchaseLine.FindLast();

        // Exercise & Verify: Open Order Tracking from Sales Order  page. Verify untracked Quantity is caused by Reorder Quantity in test page handler - OrderTrackingPageHandler.
        UntrackedQuantity := PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := PurchaseLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForPurchase(PurchaseLine);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForSalesOrderAfterCalcRegenPlanLFLItem()
    begin
        // Setup:
        Initialize();
        OrderTrackingForSalesOrderWithSKU(false);  // Update Sales and Calc Plan - FALSE.
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForSalesOrderAfterCalcRegenPlanAndUpdateSalesQuantityLFLItem()
    begin
        // Setup:
        Initialize();
        OrderTrackingForSalesOrderWithSKU(true);  // Update Sales and Calc Plan - TRUE.
    end;

    local procedure OrderTrackingForSalesOrderWithSKU(UpdateSalesAndCalcPlan: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        SalesLineQty: Decimal;
    begin
        // Create Item Stockkeeping Unit setup and sales order. Planning Worksheet -> Calculate Regenerative plan.
        CreateLotForLotItemSKUSetup(Item);
        SalesLineQty := LibraryRandom.RandInt(10) + 10;  // Value required.
        // Random shipment date.
        CreateSalesOrder(
          SalesHeader, Item."No.", LocationBlue.Code, SalesLineQty,
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate() + LibraryRandom.RandInt(30));

        if UpdateSalesAndCalcPlan then begin  // Update Sales Order. Run Regenerative plan again & Select Requisition Line for Expected quantities.
            ModifySalesOrderQuantity(SalesHeader, LocationRed.Code, SalesLineQty - 1);  // New quantity less than previous sales quantity.
            LibraryPlanning.CalcRegenPlanForPlanWksh(Item, WorkDate(), WorkDate() + LibraryRandom.RandInt(30));
            SelectRequisitionLine(RequisitionLine, Item."No.", LocationRed.Code);
        end else
            SelectRequisitionLine(RequisitionLine, Item."No.", LocationBlue.Code);

        // Select Sales and Requisition Line for Expected quantities.
        SelectSalesLine(SalesLine, SalesHeader);
        UntrackedQuantity := SalesLine.Quantity - RequisitionLine.Quantity;  // Assign Global variable for Page Handler.
        TotalQuantity := SalesLine.Quantity;  // Assign Global variable for Page Handler.

        // Exercise & Verify: Open Order Tracking page. Verification is done inside test page handler - OrderTrackingPageHandler.
        OpenOrderTrackingForRequisition(RequisitionLine);
    end;

    [Test]
    [HandlerFunctions('NoTrackingLinesMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForBlanketSalesOrderAfterCalcRegenPlanOrderItem()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item with re-order policy - Order, Create Blanket Sales Order, Planning Worksheet -> Calculate Regenerative plan.
        Initialize();
        CreateItem(Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::Order, Item."Order Tracking Policy"::None);
        // Large Random Value required for Test. Random shipment date.
        CreateBlanketSalesOrder(
          SalesHeader, Item."No.", LibraryRandom.RandInt(10) + 10,
          CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'D>', WorkDate()));
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Select Sales Line and Requisition Line for Expected Quantities.
        SelectSalesLine(SalesLine, SalesHeader);
        SelectRequisitionLine(RequisitionLine, Item."No.", '');

        // Exercise & Verify: Open Order Tracking from Planning Worksheet  page. Verify untracked Quantity in page handler - OrderTrackingPageHandler.
        UntrackedQuantity := SalesLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := SalesLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForRequisition(RequisitionLine);

        // Verify Untracked planning elements.
        VerifyUntrackedPlanningElementSource(BlanketOrderMsg, '', '', '', '');
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForReleasedProdOrderAfterCalcRegenPlanLFLItem()
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item with re-order policy - LFL and planning parameters, Create Released Prod. Order, Planning Worksheet -> Calculate Regenerative plan.
        Initialize();
        CreateLotForLotItem(
          Item, Item."Replenishment System"::"Prod. Order", LibraryRandom.RandInt(5) + 20, 0, LibraryRandom.RandInt(5),
          LibraryRandom.RandInt(5) + 10);  // Values required.
        CreateAndRefreshReleasedProductionOrder(ProductionOrder, Item."No.", Item."Maximum Order Quantity");  // Large Random Value required for Test.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));

        // Select Requisition Line for Expected Quantities.
        SelectRequisitionLine(RequisitionLine, Item."No.", '');

        // Exercise & Verify: Open Order Tracking from Planning Worksheet  page. Verify untracked Quantity in page handler - OrderTrackingPageHandler.
        repeat
            UntrackedQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
            TotalQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
            OpenOrderTrackingForRequisition(RequisitionLine);
        until RequisitionLine.Next() = 0;

        // Verify Untracked planning elements.
        VerifyUntrackedPlanningElementSource(SafetyStockMsg, ExceptionMsg, AttentionMsg, AttentionMsg, AttentionProdOrderMsg);
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,CalculateRegenPlanPlanWkshRequestPageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForForecastAfterCalcRegenPlanLFLItem()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Item with re-order policy - Order, Create Blanket Sales Order, Planning Worksheet -> Calculate Regenerative plan.
        Initialize();
        CreateLotForLotItem(
          Item, Item."Replenishment System"::Purchase, LibraryRandom.RandInt(5) + 5, LibraryRandom.RandInt(5) + 20,
          LibraryRandom.RandInt(5) + 10, 0);  // Values required.
        CreateProductionForecastSetup(Item."No.");
        GlobalItemNo := Item."No.";
        CalcRegenPlanForPlanningWorksheet();  // Calculate plan using Planning worksheet page.

        // Select Requisition Line for Expected Quantities.
        SelectRequisitionLine(RequisitionLine, Item."No.", '');

        // Exercise & Verify: Open Order Tracking from Planning Worksheet page. Verify untracked Quantity in page handler - OrderTrackingPageHandler.
        UntrackedQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        TotalQuantity := RequisitionLine.Quantity;  // Assign Global variable for Page Handler OrderTrackingPageHandler.
        OpenOrderTrackingForRequisition(RequisitionLine);

        // Verify Untracked planning elements.
        VerifyUntrackedPlanningElementSource(ProductionForecastMsg, SafetyStockMsg, ExceptionMsg, AttentionMsg, '');
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForProductionWithSalesAfterCalcPlan()
    begin
        // Setup.
        Initialize();
        OrderTrackingForProductionOrder(false, false);  // Sales Order only. Calculate Plan only.
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForProductionWithSalesAndFirmPlanProdCalcPlan()
    begin
        // Setup.
        Initialize();
        OrderTrackingForProductionOrder(true, false);  // Sales Order with Firm Plan Production Order. Calculate Plan only.
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForProductionWithSalesAfterCalcPlanCarryOutActionMsg()
    begin
        // Setup.
        Initialize();
        OrderTrackingForProductionOrder(false, true);  // Sales Order only. Calculate Plan and Carry Out Action message.
    end;

    [Test]
    [HandlerFunctions('TrackingLineMessageHandler,OrderTrackingPageHandler')]
    [Scope('OnPrem')]
    procedure OrderTrackingForProductionWithSalesAndFirmPlanProdCalcPlanCarryOutActionMsg()
    begin
        // Setup.
        Initialize();
        OrderTrackingForProductionOrder(true, true);  // Sales Order with Firm Plan Production Order. Calculate Plan and Carry Out Action message.
    end;

    local procedure OrderTrackingForProductionOrder(ExistFirmPlanProdOrder: Boolean; CarryOutActionMessageForProdOrder: Boolean)
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        RequisitionLine: Record "Requisition Line";
        FirmPlannedProdQty: Decimal;
        SalesOrderQty: Decimal;
        SalesShipmentDate: Date;
    begin
        // Create Item, Reorder Policy - Maximum Quantity.
        CreateMaxQtyItem(
          Item, LibraryRandom.RandInt(5) + 100, LibraryRandom.RandInt(5) + 10, 0,
          Item."Replenishment System"::"Prod. Order");  // Value important for test. Maximum Inventory, Reorder Point. Safety Stock Quantity.

        // Create Firm Planned Production Order.
        if ExistFirmPlanProdOrder then begin
            FirmPlannedProdQty := Item."Reorder Point";
            CreateAndRefreshFirmPlannedProductionOrder(ProductionOrder, Item."No.", FirmPlannedProdQty);
        end;

        // Create Sales Order.
        SalesOrderQty := Item."Reorder Point" + FirmPlannedProdQty + 1;
        // Shipment date greater than WORKDATE.
        SalesShipmentDate := CalcDate('<' + '+' + Format(LibraryRandom.RandInt(2) + 1) + 'D>', WorkDate());
        CreateSalesOrder(SalesHeader, Item."No.", '', SalesOrderQty, SalesShipmentDate);

        // Calculate Order Tracking Expected quantities.
        UntrackedQuantity := Item."Maximum Inventory" - SalesOrderQty;  // Assign Global variable - Page Handler OrderTrackingPageHandler.
        TotalQuantity := Item."Maximum Inventory" - FirmPlannedProdQty;  // Assign Global variable - Page Handler OrderTrackingPageHandler.

        // Exercise: Planning Worksheet -> Calculate Regenerative plan & Carry Out Action Message.
        // Start Date and End Date to cover any shipments.
        LibraryPlanning.CalcRegenPlanForPlanWksh(
          Item, WorkDate(), CalcDate('<' + '+' + Format(LibraryRandom.RandInt(30)) + 'D>', WorkDate()));
        if CarryOutActionMessageForProdOrder then
            CarryOutActionMessage(Item."No.");

        // Verify: Verify quantities using Order Tracking, Production Quantity, and Untracked planning source for Requisition line.
        if CarryOutActionMessageForProdOrder then begin
            SelectProdOrderLine(ProdOrderLine, Item."No.");
            OpenOrderTrackingForProduction(ProdOrderLine);  // Open and verify Order Tracking from Production Order page.Verification is inside test page handler - OrderTrackingPageHandler.
            ProdOrderLine.TestField(Quantity, TotalQuantity);  // Verify New Production Order Quantity.
        end else begin
            SelectRequisitionLine(RequisitionLine, Item."No.", '');
            OpenOrderTrackingForRequisition(RequisitionLine);  // Open and verify Order Tracking from Planning Worksheet page.Verification is inside test page handler - OrderTrackingPageHandler.
            VerifyUntrackedPlanningElementSource(ReorderPointMsg, MaximumInventoryMsg, '', '', '');  // Verify untracked planning element for Requisition line.
        end;
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Planning Transparency");
        ClearGlobals();
        LibraryApplicationArea.EnableEssentialSetup();
        LibrarySetupStorage.Restore();

        // Lazy Setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Planning Transparency");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();
        NoSeriesSetup();
        CreateLocationSetup();
        isInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Planning Transparency");
    end;

    local procedure ClearGlobals()
    var
        ReservationEntry: Record "Reservation Entry";
        UntrackedPlanningElement: Record "Untracked Planning Element";
        RequisitionLine: Record "Requisition Line";
    begin
        ReservationEntry.DeleteAll();
        UntrackedPlanningElement.DeleteAll();
        RequisitionLine.DeleteAll();

        Clear(UntrackedQuantity);
        Clear(TotalQuantity);
        Clear(Counter);
        Clear(GlobalItemNo);
    end;

    local procedure NoSeriesSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        PurchasesPayablesSetup.Get();
        PurchasesPayablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Validate("Return Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        PurchasesPayablesSetup.Modify(true);

        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Order Nos.", LibraryUtility.GetGlobalNoSeriesCode());
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure CreateLocationSetup()
    begin
        LibraryWarehouse.CreateLocation(LocationBlue);
        LibraryWarehouse.CreateLocation(LocationRed);
    end;

    local procedure CreateMaxQtyItem(var Item: Record Item; MaximumInventory: Integer; ReorderPoint: Integer; SafetyStockQuantity: Integer; ReplenishmentSystem: Enum "Replenishment System")
    begin
        CreateItem(Item, ReplenishmentSystem, Item."Reordering Policy"::"Maximum Qty.", Item."Order Tracking Policy"::"Tracking Only");
        Item.Validate("Maximum Inventory", MaximumInventory);
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; SafetyStockQuantity: Decimal; MinimumOrderQuantity: Decimal; OrderMultiple: Decimal; MaximumOrderQuantity: Decimal)
    begin
        // Create Lot-for-Lot Item with Order Multiple and Minimum Order Quantity.
        CreateItem(Item, ReplenishmentSystem, Item."Reordering Policy"::"Lot-for-Lot", Item."Order Tracking Policy"::"Tracking Only");
        Item.Validate("Safety Stock Quantity", SafetyStockQuantity);
        Item.Validate("Minimum Order Quantity", MinimumOrderQuantity);
        if ReplenishmentSystem = Item."Replenishment System"::"Prod. Order" then
            Item.Validate("Maximum Order Quantity", MaximumOrderQuantity);
        Item.Validate("Order Multiple", OrderMultiple);
        Item.Modify(true);
    end;

    local procedure ModifySalesOrderQuantity(SalesHeader: Record "Sales Header"; LocationCode: Code[10]; Quantity: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        SelectSalesLine(SalesLine, SalesHeader);
        SalesLine.Validate(Quantity, Quantity);  // Quantity less than original.
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateFixedReorderQtyItem(var Item: Record Item; ReorderPoint: Integer; ReorderQuantity: Integer)
    begin
        CreateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Fixed Reorder Qty.",
          Item."Order Tracking Policy"::"Tracking Only");
        Item.Validate("Reorder Point", ReorderPoint);
        Item.Validate("Reorder Quantity", ReorderQuantity);
        Item.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; ReorderingPolicy: Enum "Reordering Policy"; OrderTrackingPolicy: Enum "Order Tracking Policy")
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Reordering Policy", ReorderingPolicy);
        Item.Validate("Order Tracking Policy", OrderTrackingPolicy);
        Item.Modify(true);
    end;

    local procedure CreateLotForLotItemSKUSetup(var Item: Record Item)
    var
        ItemVariant: Record "Item Variant";
        TransferRoute: Record "Transfer Route";
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        CreateItem(
          Item, Item."Replenishment System"::Purchase, Item."Reordering Policy"::"Lot-for-Lot",
          Item."Order Tracking Policy"::"Tracking Only");
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        CreateTransferRoute(TransferRoute, LocationBlue.Code, LocationRed.Code);
        CreateStockkeepingUnit(
          LocationRed.Code, Item."No.", ItemVariant.Code, StockkeepingUnit."Replenishment System"::Transfer,
          LibraryRandom.RandDec(5, 2), LocationBlue.Code);
        CreateStockkeepingUnit(
          LocationBlue.Code, Item."No.", ItemVariant.Code, StockkeepingUnit."Replenishment System"::Purchase,
          LibraryRandom.RandDec(5, 2) + 3, '');  // Value required.
    end;

    local procedure CreateStockkeepingUnit(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; ReplenishmentSystem: Enum "Replenishment System"; OrderMultiple: Decimal; TransferFromCode: Code[10])
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(StockkeepingUnit, LocationCode, ItemNo, VariantCode);
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Order Multiple", OrderMultiple);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; DocumentType: Enum "Purchase Document Type"; ItemNo: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, DocumentType, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Expected Receipt Date", ExpectedReceiptDate);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, ShipmentDate);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, SalesHeader."Shipment Date", Quantity);
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesHeader(var SalesHeader: Record "Sales Header"; DocumentType: Enum "Sales Document Type"; ShipmentDate: Date)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, DocumentType, '');
        SalesHeader.Validate("Shipment Date", ShipmentDate);
        SalesHeader.Modify(true);
    end;

    local procedure CreateBlanketSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; Quantity: Decimal; ShipmentDate: Date)
    var
        SalesLine: Record "Sales Line";
    begin
        CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Blanket Order", ShipmentDate);
        LibrarySales.CreateSalesLineWithShipmentDate(
          SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, SalesHeader."Shipment Date", Quantity);
    end;

    local procedure SelectSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.FindFirst();
    end;

    local procedure SelectPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.FindFirst();
    end;

    local procedure SelectPurchaseLine2(var PurchaseLine: Record "Purchase Line"; DocumentType: Enum "Purchase Document Type"; DocumentNo: Code[20]; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", DocumentType);
        PurchaseLine.SetFilter("Document No.", '<>%1', DocumentNo);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
    end;

    local procedure SelectPurchaseLineUsingItem(var PurchaseLine: Record "Purchase Line"; ItemNo: Code[20])
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
    end;

    local procedure SelectRequisitionLine(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindSet();
    end;

    local procedure SelectRequisitionLineQuantity(var RequisitionLine2: Record "Requisition Line") RequisitionLineQuantity: Decimal
    begin
        RequisitionLineQuantity := RequisitionLine2.Quantity;
        RequisitionLine2.Next();
        RequisitionLineQuantity += RequisitionLine2.Quantity;
    end;

    local procedure OpenOrderTrackingForPurchase(var PurchaseLine: Record "Purchase Line")
    begin
        PurchaseLine.ShowOrderTracking();
    end;

    local procedure OpenOrderTrackingForRequisition(var RequisitionLine: Record "Requisition Line")
    var
        OrderTracking: Page "Order Tracking";
    begin
        // Open Order Tracking page for required Purchase Order.
        OrderTracking.SetReqLine(RequisitionLine);
        OrderTracking.RunModal();
    end;

    local procedure OpenOrderTrackingForProduction(var ProdOrderLine: Record "Prod. Order Line")
    begin
        ProdOrderLine.ShowOrderTracking();
    end;

    local procedure CarryOutActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        AcceptActionMessage(ItemNo);
        SelectRequisitionLine(RequisitionLine, ItemNo, '');
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);
    end;

    local procedure AcceptActionMessage(ItemNo: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
        VendorNo: Code[20];
    begin
        VendorNo := LibraryPurchase.CreateVendorNo();
        SelectRequisitionLine(RequisitionLine, ItemNo, '');
        repeat
            if RequisitionLine."Ref. Order Type" = RequisitionLine."Ref. Order Type"::Purchase then
                RequisitionLine.Validate("Vendor No.", VendorNo);
            RequisitionLine.Validate("Accept Action Message", true);
            RequisitionLine.Modify(true);
        until RequisitionLine.Next() = 0;
    end;

    local procedure CreateTransferRoute(var TransferRoute: Record "Transfer Route"; TransferFrom: Code[10]; TransferTo: Code[10])
    begin
        // Find Transfer Route.
        TransferRoute.SetRange("Transfer-from Code", TransferFrom);
        TransferRoute.SetRange("Transfer-to Code", TransferTo);

        // If Transfer Not Found then Create it.
        if not TransferRoute.FindFirst() then
            LibraryWarehouse.CreateTransferRoute(TransferRoute, TransferFrom, TransferTo);
    end;

    local procedure CreateAndRefreshReleasedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        // Create Released Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo, Quantity, ProductionOrder.Status::Released);
    end;

    local procedure CreateAndRefreshFirmPlannedProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        // Create Firm Planned Production Order.
        CreateAndRefreshProductionOrder(ProductionOrder, ItemNo, Quantity, ProductionOrder.Status::"Firm Planned");
    end;

    local procedure CreateAndRefreshProductionOrder(var ProductionOrder: Record "Production Order"; ItemNo: Code[20]; Quantity: Decimal; Status: Enum "Production Order Status")
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure UpdateDemandForecastSetup(CurrentProductionForecast: Code[10]; UseForecastOnLocations: Boolean)
    var
        InventorySetup: Record "Inventory Setup";
    begin
        InventorySetup.Get();
        InventorySetup.Validate("Current Demand Forecast", CurrentProductionForecast);
        InventorySetup.Validate("Use Forecast on Locations", UseForecastOnLocations);
        InventorySetup.Modify(true);
    end;

    local procedure CreateProductionForecastSetup(ItemNo: Code[20])
    var
        ProductionForecastEntry: Record "Production Forecast Entry";
        ProductionForecastName: Record "Production Forecast Name";
    begin
        // Using Random Value and Dates based on WORKDATE.
        LibraryManufacturing.CreateProductionForecastName(ProductionForecastName);
        UpdateDemandForecastSetup(ProductionForecastName.Name, true);
        LibraryManufacturing.CreateProductionForecastEntry(ProductionForecastEntry, ProductionForecastName.Name, ItemNo, '', WorkDate(), false);
        ProductionForecastEntry.Validate("Forecast Quantity (Base)", LibraryRandom.RandDec(5, 2) + 200);  // Large random value required.
        ProductionForecastEntry.Modify(true);
    end;

    local procedure CalcRegenPlanForPlanningWorksheet()
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
        PlanningWorksheet: TestPage "Planning Worksheet";
    begin
        Commit();
        RequisitionWkshName.FindFirst();
        PlanningWorksheet.OpenEdit();
        PlanningWorksheet.CurrentWkshBatchName.SetValue(RequisitionWkshName.Name);
        PlanningWorksheet.CalculateRegenerativePlan.Invoke();  // Open report on Handler CalculatePlanPlanWkshRequestPageHandler.
        PlanningWorksheet.OK().Invoke();
    end;

    local procedure SelectUntrackedPlanningSource(Message: Text[250]; Message2: Text[250]; Message3: Text[250]; Message4: Text[250]; Message5: Text[250]) PlanningSource: array[7] of Text[250]
    begin
        PlanningSource[1] := Message;
        PlanningSource[2] := Message2;
        PlanningSource[3] := Message3;
        PlanningSource[4] := Message4;
        PlanningSource[5] := Message5;
    end;

    local procedure SelectProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::"Firm Planned");
        ProdOrderLine.SetRange("Item No.", ItemNo);
        ProdOrderLine.FindLast();
    end;

    local procedure VerifyUntrackedPlanningElementSource(Message: Text[250]; Message2: Text[250]; Message3: Text[250]; Message4: Text[250]; Message5: Text[250])
    begin
        VerifyUntrackedPlanningElementSource(SelectUntrackedPlanningSource(Message, Message2, Message3, Message4, Message5));
    end;

    local procedure VerifyUntrackedPlanningElementSource(PlanningSource: array[7] of Text[250])
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
        Index: Integer;
    begin
        UntrackedPlanningElement.FindSet();
        Index := 1;
        repeat
            Assert.IsTrue(StrPos(UntrackedPlanningElement.Source, PlanningSource[Index]) > 0, ErrUntrackedPlanningElementMsg);
            Index += 1;
        until UntrackedPlanningElement.Next() = 0;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderTrackingPageHandler(var OrderTracking: TestPage "Order Tracking")
    begin
        // Verify required Quantity values - Total Qty and Untracked Qty.
        OrderTracking."Untracked Quantity".AssertEquals(UntrackedQuantity);
        OrderTracking."Total Quantity".AssertEquals(TotalQuantity);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure TrackingLineMessageHandler(Message: Text[1024])
    begin
        Counter += 1;
        case Counter of
            1:
                Assert.IsTrue(StrPos(Message, TrackingMsg) > 0, Message);
            2:
                Assert.IsTrue(StrPos(Message, NoTrackingLinesMsg) > 0, Message);
        end;
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NoTrackingLinesMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, NoTrackingLinesMsg) > 0, Message);
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure CalculateRegenPlanPlanWkshRequestPageHandler(var CalculatePlanPlanWksh: TestRequestPage "Calculate Plan - Plan. Wksh.")
    begin
        // Calculate Regenerative Plan using page.
        CalculatePlanPlanWksh.Item.SetFilter("No.", GlobalItemNo);
        CalculatePlanPlanWksh.StartingDate.SetValue(WorkDate());
        CalculatePlanPlanWksh.EndingDate.SetValue(CalcDate('<' + '+' + Format(LibraryRandom.RandInt(5)) + 'M>', WorkDate()));
        CalculatePlanPlanWksh.OK().Invoke();
    end;
}

