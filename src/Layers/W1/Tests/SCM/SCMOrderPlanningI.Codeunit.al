codeunit 137046 "SCM Order Planning - I"
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
        LocationIntransit: Record Location;
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryApplicationArea: Codeunit "Library - Application Area";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        VerifyOnGlobal: Option RequisitionLine,Orders;
        DemandTypeGlobal: Option Sales,Production;
        IsInitialized: Boolean;
        ValidationError: Label '%1  must be %2 in %3.';
        FinishOrderMessage: Label 'Do you still want to finish the order?';
        LineCountError: Label 'There should be '' %1 '' line(s) in the planning worksheet for item. ';
        CostIsAdjustedErr: Label '"Cost Is Adjusted" in Inventory Adjmt. Entry (Order) should be TRUE if Item was deleted';
        UnitOfMeasureErr: Label 'Unit of Measure Code on Requisition Line doesn''t equal to the Purch. Unit of Measure of Item';
        RequisitionLineQtyErr: Label 'Requisition quantity not qual to expected quantity of %1', Comment = '%1 - Requisition Line Expected Quantity';

    [Test]
    [Scope('OnPrem')]
    procedure ProdWithLessConsumption()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ChildItem: Record Item;
        BOMQuantity: Decimal;
    begin
        // Setup : Create Manufacturing Item Setup, Create Production Order and consume less than required quantity
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        BOMQuantity := LibraryRandom.RandDec(10, 2);
        CreateManufacturingSetup(ParentItem, ChildItem, BOMQuantity, false);  // Child Item With Replenishment System Purchase.
        UpdateItemInventory(BOMQuantity, ChildItem."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", '', LibraryRandom.RandDec(5, 2) + 1,
          CalcDate('<' + Format(LibraryRandom.RandInt(2) + 2) + 'D>', WorkDate()));
        CreateAndPostConsumWithQty(ProductionOrder."No.", BOMQuantity);

        // Exercise : Run Order Planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify : Verify That Quantity on Requisition Line same as Remaining Quantity on ProdOrderComponent.
        VerifyDemandQtyAndLocation(ProductionOrder."No.", DemandTypeGlobal::Production, ProductionOrder.Status::Released);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ProdLessConsmpMakeSupplyOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        BOMQuantity: Decimal;
    begin
        // Setup : Create Manufacturing Item Setup, Create Production Order and consume less than required quantity and run Order Planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        BOMQuantity := LibraryRandom.RandDec(10, 2);
        CreateManufacturingSetup(ParentItem, ChildItem, BOMQuantity, false);  // Child Item With Replenishment System Purchase.
        UpdateItemInventory(BOMQuantity, ChildItem."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", '', LibraryRandom.RandDec(5, 2) + 1,
          CalcDate('<' + Format(LibraryRandom.RandInt(2) + 2) + 'D>', WorkDate()));
        CreateAndPostConsumWithQty(ProductionOrder."No.", BOMQuantity);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise : Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Verify That Quantity on Purchase Order is same as Required quantity in Production BOM Component Line.
        VerifyPurchaseQtyAgainstProd(ProductionOrder);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ProdEqualsConsumption()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        BOMQuantity: Decimal;
    begin
        // Setup : Create Manufacturing Item Setup, Create Released Production Order and consume demand quantity.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        BOMQuantity := LibraryRandom.RandInt(10);
        CreateManufacturingSetup(ParentItem, ChildItem, BOMQuantity, false);  // Child Item With Replenishment System Purchase.
        UpdateItemInventory(BOMQuantity, ChildItem."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", '', 1,
          CalcDate('<' + Format(LibraryRandom.RandInt(2) + 2) + 'D>', WorkDate()));  // Value Needed.

        CreateAndPostConsumWithQty(ProductionOrder."No.", BOMQuantity);

        // Exercise : Run Order Planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify : Verify That No Requisition Line Created if consumption for required quantity is posted.
        AssertNoLinesForItem(ProductionOrder."No.", ChildItem."No.", '', 0);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure RoutingOnInventoryAdjmtEntryOrder()
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        InventoryAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
        RoutingNo: Code[20];
        Qty: Decimal;
    begin
        // [FEATURE] [Production]
        // [SCENARIO 378138] Finish Production Order Job should update "Routing No." of Inventory Adjmt Entry Order
        Initialize();

        // [GIVEN] Production Order Line with "Routing No." blank
        Qty := LibraryRandom.RandDec(10, 2);
        CreateProdOrderForItem(ProductionOrder, ParentItem, Qty);
        RoutingNo := SetRoutingOnProdOrderLine(ProductionOrder."No.", '');

        // [GIVEN] Post Consumption. Inventory Adjmt Entry Order is created with "Routing No." blank
        CreateAndPostConsumWithQty(ProductionOrder."No.", Qty);

        // [GIVEN] Set "Routing No." on Production Order Line to "X"
        SetRoutingOnProdOrderLine(ProductionOrder."No.", RoutingNo);

        // [GIVEN] Post Output
        CreateAndPostOutputJournal(ProductionOrder."No.", ParentItem."No.");

        // [WHEN] Finish Production Order
        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder."No.");

        // [THEN] Inventory Adjmt Entry Order has "Routing No." = "X"
        InventoryAdjmtEntryOrder.FindLast();
        InventoryAdjmtEntryOrder.TestField("Routing No.", RoutingNo);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForProdMakeSupplyOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Release Production Order
        // and run Order Planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2), false);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", '', LibraryRandom.RandDec(10, 2) + 10, WorkDate());
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise : Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Verify That Quantity on Purchase Order and Quantity on Production Order is same as define in Production BOM and child item.
        VerifyPurchaseQtyAgainstProd(ProductionOrder);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningForSalesOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup : Create Sales Order with Quantity greater than inventory Quantity and ship the inventory quantity.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity);
        CreateSalesOrder(SalesHeader, Item."No.", '', Quantity + LibraryRandom.RandDec(10, 2), Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Verify That Requisition Line has same quantity as on outstanding on sales order.
        VerifyDemandQtyAndLocation(SalesHeader."No.", DemandTypeGlobal::Sales, "Production Order Status"::Simulated);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningForSaleMakeSupplyOrder()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        RequisitionLine: Record "Requisition Line";
        Quantity: Decimal;
    begin
        // Setup : Create Sales Order with Quantity greater than inventory Quantity and ship the inventory quantity.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity);
        CreateSalesOrder(SalesHeader, Item."No.", LocationRed.Code, Quantity + LibraryRandom.RandDec(10, 2), Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify : Verify That Quantity on Purchase Order is same as remaining demand quantity on Sales Order.
        VerifyDemandQtyWithPurchQty(SalesHeader."No.", Item."No.", LocationRed.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningPurchaseEqualsSales()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        PurchaseHeader: Record "Purchase Header";
        Quantity: Decimal;
    begin
        // Setup : Create Sales Order with Quantity as Quantity on inventory and ship the inventory quantity.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        Quantity := LibraryRandom.RandDec(100, 2);
        CreateAndReleasePurchaseOrder(PurchaseHeader, Item."No.", Quantity);
        CreateSalesOrder(SalesHeader, Item."No.", '', Quantity, Quantity);
        LibrarySales.PostSalesDocument(SalesHeader, true, true);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Verify That No Requisition Line has Created for Sales Order after posting total demand quantity.
        AssertNoLinesForItem(SalesHeader."No.", Item."No.", '', 0);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleSalesMakeOrderActLine()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // Setup : Create Two Item, Locations and Multiple Sales Order for multiple Location on Line.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        CreateItem(Item2, Item."Replenishment System"::Purchase, '', '', Item."Vendor No.");
        CreateMultipleSalesOrder(SalesHeader, SalesHeader2, SalesHeader3, LocationBlue.Code, LocationRed.Code, Item."No.", Item2."No.");
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Supply Orders for Active Line on Requisition Line.
        MakeSupplyOrdersActiveLine(
          SalesHeader."No.", Item."No.", LocationBlue.Code, ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Verify : Verify That Purchase Order Quantity is same as demand quantity for sales order created by Make supply Order by
        // active Line.
        VerifyDemandQtyWithPurchQty(SalesHeader."No.", Item."No.", LocationBlue.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleSalesMakeOrderCalcPlan()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        Item2: Record Item;
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // Setup : Create Two Item, Locations and Multiple Sales Order for multiple Location on Line And Make Supply Order For Active Line.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        CreateItem(Item2, Item."Replenishment System"::Purchase, '', '', Item."Vendor No.");
        CreateMultipleSalesOrder(SalesHeader, SalesHeader2, SalesHeader3, LocationBlue.Code, LocationRed.Code, Item."No.", Item2."No.");
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        MakeSupplyOrdersActiveLine(
          SalesHeader."No.", Item."No.", LocationBlue.Code, ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Exercise: Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check That No Requisition Line is created after Make Supply order by Active Line for the sales Order.
        AssertNoLinesForItem(SalesHeader."No.", Item."No.", LocationBlue.Code, 0);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure MultipleSalesMakeOrderAllLine()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        Item2: Record Item;
    begin
        // Setup : Create Two Item, Locations and Multiple Sales Order for multiple Location on Line And Make Supply Order For Active Line.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        CreateItem(Item2, Item."Replenishment System"::Purchase, '', '', Item."Vendor No.");
        CreateMultipleSalesOrder(SalesHeader, SalesHeader2, SalesHeader3, LocationBlue.Code, LocationRed.Code, Item."No.", Item2."No.");
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Supply Order for All line in Requisition Line.
        ClearRequisitionLines(SalesHeader."No.", SalesHeader2."No.", SalesHeader3."No.");
        MakeSupplyOrdersAllLine(RequisitionLine, SalesHeader."No.", SalesHeader2."No.", SalesHeader3."No.");

        // Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Verify That No requisition Line created for sales order after create Make Supply Order for All Line.
        RequisitionLine.SetFilter("Demand Order No.", '%1|%2|%3', SalesHeader."No.", SalesHeader2."No.", SalesHeader3."No.");
        asserterror RequisitionLine.FindFirst();

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ChangeReplenishmentCalcPlan()
    var
        RequisitionLine: Record "Requisition Line";
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory and Replenishment System Production,
        // Create Firm Planned Production Order and run Order Planning Production.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2), true);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", '', LibraryRandom.RandDec(10, 2) + 10, WorkDate());
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise : Change Replenishment System on Requisition Line and calculate plan for sales.
        ChangeReplenishmentSystem(
          RequisitionLine, RequisitionLine."Replenishment System"::"Prod. Order", RequisitionLine."Replenishment System"::Purchase,
          ProductionOrder."No.", ParentItem."Vendor No.");
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Verify That Replenishment System is not change after calculating plan for sales.
        RequisitionLine.SetRange("Demand Order No.", ProductionOrder."No.");
        RequisitionLine.SetRange("No.", ChildItem."No.");
        RequisitionLine.FindFirst();
        Assert.AreEqual(
          RequisitionLine."Replenishment System"::Purchase, RequisitionLine."Replenishment System",
          StrSubstNo(ValidationError, RequisitionLine.FieldCaption("Replenishment System"),
            RequisitionLine."Replenishment System"::Purchase, RequisitionLine.TableCaption()));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeReplenishmentMakeOrder()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Firm Planned Production Order
        // and run Order Planning Production And Change the Replenishment System.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2), true);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) +
          10, WorkDate());
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        ChangeReplenishmentSystem(
          RequisitionLine, RequisitionLine."Replenishment System"::"Prod. Order", RequisitionLine."Replenishment System"::Purchase,
          ProductionOrder."No.", ParentItem."Vendor No.");

        // Exercise : Make Order for changed Replenishment System on Requisition Line.
        MakeSupplyOrdersActiveLine(
          ProductionOrder."No.", RequisitionLine."No.", LocationBlue.Code,
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Verify : Verify That Quantity on Purchase Line remain same after change Replenishment System on Requisition Line.
        PurchaseLine.SetRange("Buy-from Vendor No.", ParentItem."Vendor No.");
        PurchaseLine.SetRange("No.", ChildItem."No.");
        PurchaseLine.FindFirst();
        Assert.AreEqual(
          RequisitionLine.Quantity, PurchaseLine.Quantity,
          StrSubstNo(ValidationError, RequisitionLine.FieldCaption(Quantity), PurchaseLine.Quantity, RequisitionLine.TableCaption()));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeReplMakeOrderCalcPlan()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Firm Planned Production Order
        // and run Order Planning Production, Change the Replenishment System and Make Order.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2), true);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) +
          10, WorkDate());
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        ChangeReplenishmentSystem(
          RequisitionLine, RequisitionLine."Replenishment System"::"Prod. Order", RequisitionLine."Replenishment System"::Purchase,
          ProductionOrder."No.", ParentItem."Vendor No.");
        MakeSupplyOrdersActiveLine(
          ProductionOrder."No.", RequisitionLine."No.", LocationBlue.Code,
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Exercise.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify : Check That No Requisition Line created after Make Supply Order of changed Replenishment System.
        AssertNoLinesForItem(ProductionOrder."No.", ChildItem."No.", LocationBlue.Code, 0);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ChangeReplMakeOrderCreateProd()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseLine: Record "Purchase Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ProductionOrder: Record "Production Order";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        PurchaseOrderNo: Code[20];
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Firm Planned Production Order
        // and run Order Planning Production, Change the Replenishment System and Make Order.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2), true);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) +
          10, WorkDate());
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        ChangeReplenishmentSystem(
          RequisitionLine, RequisitionLine."Replenishment System"::"Prod. Order", RequisitionLine."Replenishment System"::Purchase,
          ProductionOrder."No.", ParentItem."Vendor No.");
        MakeSupplyOrdersActiveLine(
          ProductionOrder."No.", RequisitionLine."No.", LocationBlue.Code,
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Exercise : Create Firm Planned Production Order and again Change Replenishment System and Make Order.
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2),
          WorkDate());
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        ChangeReplenishmentSystem(
          RequisitionLine, RequisitionLine."Replenishment System"::"Prod. Order", RequisitionLine."Replenishment System"::Purchase,
          ProductionOrder."No.", ParentItem."Vendor No.");
        PurchaseOrderNo := FindPurchaseOrderNo();
        MakeSupplyOrdersActiveLine(
          ProductionOrder."No.", RequisitionLine."No.", LocationBlue.Code,
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Verify: Verify That Quantity on Purchase Line remain same after Change Replenishment System on Requisition Line.
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", PurchaseOrderNo);
        PurchaseLine.SetRange("Buy-from Vendor No.", ParentItem."Vendor No.");
        PurchaseLine.SetRange("No.", ChildItem."No.");
        PurchaseLine.SetRange("Location Code", LocationBlue.Code);
        PurchaseLine.FindFirst();
        Assert.AreEqual(
          RequisitionLine.Quantity, PurchaseLine.Quantity,
          StrSubstNo(ValidationError, RequisitionLine.FieldCaption(Quantity), PurchaseLine.Quantity, RequisitionLine.TableCaption()));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningProdOrdWithItemVariant()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Check That Replenishment System is same as it define in Stock Keeping Unit for various Transfer Location after calculating plan
        // for Planned Production Order.
        Initialize();
        CreateProdOrderWithItemVariant(ProductionOrder.Status::Planned, false);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningProdOrdMakeOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Check That item and quantity is same as define on Replenishment System in Purchase Order, Production Order and Transfer Order
        // for Planned Production Order.
        Initialize();
        CreateProdOrderWithItemVariant(ProductionOrder.Status::Planned, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlanningFirmProdOrdWithVariant()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Check That Replenishment System is same as it define in Stock Keeping Unit for various Transfer Location after calculating plan
        // for Firm Planned Production Order.
        Initialize();
        CreateProdOrderWithItemVariant(ProductionOrder.Status::"Firm Planned", false);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PlanningFirmProdOrdMakeOrder()
    var
        ProductionOrder: Record "Production Order";
    begin
        // Check That item and quantity is same as define on Replenishment System in Purchase Order, Production Order and Transfer Order
        // for Firm Planned Production Order.
        Initialize();
        CreateProdOrderWithItemVariant(ProductionOrder.Status::"Firm Planned", true);
    end;

    local procedure CreateProdOrderWithItemVariant(Status: Enum "Production Order Status"; MakeOrder: Boolean)
    var
        ParentItem: Record Item;
        ItemVariant: Record "Item Variant";
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup: Create Location, Work Center, Routing , Item , Item Variant, Transfer Routes, Stock Keeping Unit.
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '', '');
        LibraryInventory.CreateItemVariant(ItemVariant, ChildItem."No.");
        CreateAndUpdateSKU(ChildItem, LocationRed, LocationBlue, LocationBlue2);
        CreateItemWithProductionBOM(ParentItem, ChildItem, ItemVariant.Code, LibraryRandom.RandDec(10, 2));
        CreateAndRefreshProdOrder(
          ProductionOrder, Status, ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2),
          CalcDate('<' + Format(LibraryRandom.RandInt(2) + 2) + 'D>', WorkDate()));
        CreateAndRefreshProdOrder(
          ProductionOrder2, Status, ParentItem."No.", LocationRed.Code, LibraryRandom.RandDec(10, 2),
          CalcDate('<' + Format(LibraryRandom.RandInt(10) + 10) + 'D>', WorkDate()));
        CreateAndRefreshProdOrder(
          ProductionOrder3, Status, ParentItem."No.", LocationBlue2.Code, LibraryRandom.RandDec(10, 2),
          CalcDate('<' + Format(LibraryRandom.RandInt(10) + 10) + 'D>', WorkDate()));

        // Exercise: Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Make Order and Verify .
        if MakeOrder then begin
            ClearRequisitionLines(ProductionOrder."No.", ProductionOrder2."No.", ProductionOrder3."No.");
            MakeSupplyOrdersAllLine(RequisitionLine, ProductionOrder."No.", ProductionOrder2."No.", ProductionOrder3."No.");

            // Verify.
            VerifyQtyWithRequiredQtySKU(ProductionOrder."No.", VerifyOnGlobal::Orders, Status);
            VerifyQtyWithRequiredQtySKU(ProductionOrder2."No.", VerifyOnGlobal::Orders, Status);
            VerifyQtyWithRequiredQtySKU(ProductionOrder3."No.", VerifyOnGlobal::Orders, Status);
        end else begin
            VerifyDemandQtyAndLocation(ProductionOrder."No.", DemandTypeGlobal::Production, Status);
            VerifyDemandQtyAndLocation(ProductionOrder2."No.", DemandTypeGlobal::Production, Status);
            VerifyDemandQtyAndLocation(ProductionOrder3."No.", DemandTypeGlobal::Production, Status);

            // Verify: Replenishment System With SKU and Item Variant.
            VerifyQtyWithRequiredQtySKU(ProductionOrder."No.", VerifyOnGlobal::RequisitionLine, Status);
            VerifyQtyWithRequiredQtySKU(ProductionOrder2."No.", VerifyOnGlobal::RequisitionLine, Status);
            VerifyQtyWithRequiredQtySKU(ProductionOrder3."No.", VerifyOnGlobal::RequisitionLine, Status);
        end;
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure OnePurchOfTwoSalesLineDiffDate()
    begin
        // Check That One Purchase Order Created for Two Sales Line Item with different Shipment Date.
        OnePurchOfTwoSalesLineWithDate(
          CalcDate('<' + Format(LibraryRandom.RandInt(2) + 3) + 'D>', WorkDate()),
          CalcDate('<' + Format(LibraryRandom.RandInt(2) + 20) + 'D>', WorkDate()));
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure OnePurchOfTwoSalesLineSameDate()
    begin
        // Check That One Purchase Order Created for Two Sales Line Item with Same Shipment Date.
        OnePurchOfTwoSalesLineWithDate(WorkDate(), WorkDate());
    end;

    local procedure OnePurchOfTwoSalesLineWithDate(ShipmentDate: Date; ShipmentDate2: Date)
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        LibrarySales: Codeunit "Library - Sales";
        PurchaseOrderNo: Code[20];
        Quantity: Decimal;
    begin
        // Setup : Create Two Item, Locations and Sales Order With two line having Shipment Date.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        CreateItem(Item2, Item."Replenishment System"::Purchase, '', '', Item."Vendor No.");
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesLine(SalesHeader, Item."No.", '', ShipmentDate, Quantity, Quantity);
        CreateSalesLine(SalesHeader, Item2."No.", '', ShipmentDate2, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        PurchaseOrderNo := FindPurchaseOrderNo();

        // Exercise: Run Make Supply Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify: Check that Expected Receipt Date is equal Shipment Date and Purchase Quantity is equal to Quantity.
        FindPurchaseLine(PurchaseLine, PurchaseOrderNo);
        VerifyPurchaseLine(PurchaseLine, Item."No.", Quantity, ShipmentDate);
        PurchaseLine.Next();
        VerifyPurchaseLine(PurchaseLine, Item2."No.", Quantity, ShipmentDate2);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure GenerateRequisitionLine()
    var
        SalesHeader: Record "Sales Header";
        Item: Record Item;
        Item2: Record Item;
        Item3: Record Item;
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        RequisitionLine: Record "Requisition Line";
        RequisitionWkshName: Record "Requisition Wksh. Name";
        LibrarySales: Codeunit "Library - Sales";
        Quantity: Decimal;
        ShipmentDate: Date;
        ShipmentDate2: Date;
        ShipmentDate3: Date;
    begin
        // Setup : Create Two Item, Locations and Multiple Sales Order for multiple Location on Line.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        CreateItem(Item2, Item."Replenishment System"::Purchase, '', '', Item."Vendor No.");
        CreateItem(Item3, Item."Replenishment System"::"Prod. Order", '', '', Item."Vendor No.");

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        Quantity := LibraryRandom.RandDec(10, 2);
        ShipmentDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        CreateSalesLine(SalesHeader, Item."No.", LocationRed.Code, ShipmentDate, Quantity, Quantity);
        ShipmentDate2 := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', ShipmentDate);
        CreateSalesLine(SalesHeader, Item2."No.", LocationBlue.Code, ShipmentDate2, Quantity, Quantity);
        ShipmentDate3 := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', ShipmentDate2);
        CreateSalesLine(SalesHeader, Item3."No.", LocationBlue2.Code, ShipmentDate3, Quantity, Quantity);

        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        CreateRequisitionWorksheetName(RequisitionWkshName);

        // Exercise: Make supply order by changing option.
        MakeOrderWithChangeOption(SalesHeader."No.", RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);

        // Verify: Check That Requisition Worksheet is created after change option in make supply order request page.
        FilterRequisitionWorksheetLine(RequisitionLine, RequisitionWkshName);
        VerifyRequisitionWorksheet(RequisitionLine, Item."No.", ShipmentDate, LocationRed.Code, Quantity);
        VerifyRequisitionWorksheet(RequisitionLine, Item2."No.", ShipmentDate2, LocationBlue.Code, Quantity);
        VerifyRequisitionWorksheet(RequisitionLine, Item3."No.", ShipmentDate3, LocationBlue2.Code, Quantity);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerTrue')]
    [Scope('OnPrem')]
    procedure DifferentProdOrderWithDueDate()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ProductionOrder: Record "Production Order";
        ProductionOrder2: Record "Production Order";
        ProductionOrder3: Record "Production Order";
        ProductionOrder4: Record "Production Order";
        RequisitionLine: Record "Requisition Line";
        DueDate: Date;
    begin
        // Setup: Create Work Center, Routing, Item, Create different Production Order with different Due Date.
        CreateManufacturingSetup(ParentItem, ChildItem, LibraryRandom.RandDec(10, 2), false);

        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', WorkDate());
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Simulated, ParentItem."No.", '', LibraryRandom.RandDec(10, 2), DueDate);
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', DueDate);
        CreateAndRefreshProdOrder(
          ProductionOrder2, ProductionOrder2.Status::Planned, ParentItem."No.", '', LibraryRandom.RandDec(10, 2), DueDate);
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', DueDate);
        CreateAndRefreshProdOrder(
          ProductionOrder3, ProductionOrder3.Status::"Firm Planned", ParentItem."No.", '', LibraryRandom.RandDec(10, 2), DueDate);
        DueDate := CalcDate('<' + Format(LibraryRandom.RandInt(10)) + 'D>', DueDate);
        CreateAndRefreshProdOrder(
          ProductionOrder4, ProductionOrder4.Status::Released, ParentItem."No.", '', LibraryRandom.RandDec(10, 2), DueDate);

        LibraryManufacturing.ChangeStatusReleasedToFinished(ProductionOrder4."No.");

        // Exercise: Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify: Verify total line create for each Production Order after calculate Plan.
        AssertNoLinesForItem(ProductionOrder."No.", ChildItem."No.", '', 0);  // Simulated Production Order.
        AssertNoLinesForItem(ProductionOrder2."No.", ChildItem."No.", '', 1);  // Planned Production Order.
        AssertNoLinesForItem(ProductionOrder3."No.", ChildItem."No.", '', 1);  // Firm Planned Production Order.
        AssertNoLinesForItem(ProductionOrder4."No.", ChildItem."No.", '', 0);  // Finished Production order.
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SeveralUnitOfMeasure()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        QuantityToShip: Decimal;
    begin
        // Setup: Create Unit Of Measure, Item , Item Unit Of Measure and Sale Order.
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItemWithPurchUnitOfMeasure(Item);

        QuantityToShip := LibraryRandom.RandDec(10, 2);
        CreateSalesOrder(SalesHeader, Item."No.", '', QuantityToShip + LibraryRandom.RandDec(10, 2), QuantityToShip);

        // Exercise: Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify : Check That Unit of measure is same as on Item Purchase Unit Of measure and Demand Unit of Measure is same as Item Base
        // Unit Of Measure.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", '');
        Assert.AreEqual(
          Item."Purch. Unit of Measure", RequisitionLine."Unit of Measure Code",
          StrSubstNo(
            ValidationError, Item.FieldCaption("Purch. Unit of Measure"), Item."Purch. Unit of Measure",
            RequisitionLine.FieldCaption("Unit Of Measure Code (Demand)")));
        Assert.AreEqual(
          Item."Base Unit of Measure", RequisitionLine."Unit Of Measure Code (Demand)",
          StrSubstNo(
            ValidationError, Item.FieldCaption("Purch. Unit of Measure"), Item."Base Unit of Measure",
            RequisitionLine.FieldCaption("Unit of Measure Code")));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateRequisitionLineWithPurchUnitOfMeasure()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Verify Purch. Unit of Measure of Item will be filled on Req. Line when the Req. Line is manually inserted.

        // Setup: Create Item, create a new Item Unit of Measure, set Purch. Unit of Measure to the new Unit of Measure code.
        CreateItemWithPurchUnitOfMeasure(Item);

        // Exercise: Create a Requisition Line, fill the Item No.
        CreateRequisitionLine(RequisitionLine, Item."No.");

        // Verify.
        Assert.AreEqual(Item."Purch. Unit of Measure", RequisitionLine."Unit of Measure Code", UnitOfMeasureErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CostIsAdjustedIsSetToTrueAfterDeletingItem()
    var
        Item: Record Item;
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [FEATURE] [UT] [Cost Adjustment] [Production]
        // [SCENARIO 361637] "Cost Is Adjusted" set to TRUE in Inventory Adjmt. Entry (Order) while Deleting Item

        // [GIVEN] Inventory Adjmt. Entry (Order) with Cost Is Adjusted "FALSE"
        LibraryInventory.CreateItem(Item);
        CreateInvtAdjmtEntryOrder(InvtAdjmtEntryOrder, Item."No.");

        // [WHEN] Delete Item
        Item.Delete(true);

        // [THEN] "Cost Is Adjusted" in Inventory Adjmt. Entry (Order) is TRUE
        InvtAdjmtEntryOrder.Find();
        Assert.IsTrue(InvtAdjmtEntryOrder."Cost is Adjusted", CostIsAdjustedErr);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OverheadRateAndIndirCostOnSetProdOrderLine()
    var
        Item: Record Item;
        ProdOrderLine: Record "Prod. Order Line";
        InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)";
    begin
        // [FEATURE] [UT] [Cost Adjustment] [Production]
        // [SCENARIO 375357] "Overhead rate" and "Indirect Cost %" of "Inventory Adjmt. Entry (Order)" table are taken from Prod. Order Line by SetProdOrderLine

        // [GIVEN] Item with "Indirect Cost %" = "X1", "Overhead Rate" = "X2"
        MockItem(Item);

        // [GIVEN] Prod. Order Line for Item with "Indirect Cost %" = "Y1", "Overhead Rate" = "Y2"
        MockProdOrderLine(ProdOrderLine, Item."No.");

        // [GIVEN] Inventory Adjmt. Entry (Order) for Item
        CreateInvtAdjmtEntryOrder(InvtAdjmtEntryOrder, Item."No.");

        // [WHEN] Run SetProdOrderLine on Inventory Adjmt. Entry (Order)
        InvtAdjmtEntryOrder.SetProdOrderLine(ProdOrderLine);

        // [THEN] Inventory Adjmt. Entry (Order) has "Indirect Cost %" = "Y1", "Overhead Rate" = "Y2"
        InvtAdjmtEntryOrder.TestField("Indirect Cost %", ProdOrderLine."Indirect Cost %");
        InvtAdjmtEntryOrder.TestField("Overhead Rate", ProdOrderLine."Overhead Rate");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseHeaderSellToCustomerNoPopulatedForSpecialOrder()
    var
        Purchasing: Record Purchasing;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Special Order] [Requisition Worksheet] [Carry Out Action]
        // [SCENARIO 234009] Purchase Header "Sell-To Customer No." is blank for Special Order Purchasing
        Initialize();

        // [GIVEN] Sales Order of Item "I" with Special Order Purchasing
        CreateItemWithVendorNo(Item);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        LibraryPurchase.CreateSpecialOrderPurchasingCode(Purchasing);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);

        // [GIVEN] Requisition Worksheet Get Special Order
        GetSpecialOrder(RequisitionLine, Item."No.");

        // [WHEN] Carry Out Action Message
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] Purchase Order is created and its "Sell-to Customer No." field is blank
        FindPurchaseHeaderByItemNo(PurchaseHeader, Item."No.");
        PurchaseHeader.TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchaseHeaderSellToCustomerNoPopulatedForDropShpmnt()
    var
        Purchasing: Record Purchasing;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        // [FEATURE] [Drop Shipment] [Requisition Worksheet] [Carry Out Action]
        // [SCENARIO 234009] Purchase Header "Sell-To Customer No." is populated for Drop Shipment Purchasing
        Initialize();

        // [GIVEN] Sales Order "SO" of Item "I" with Drop Shipment Purchasing
        CreateItemWithVendorNo(Item);
        LibrarySales.CreateSalesDocumentWithItem(
          SalesHeader, SalesLine, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo(),
          Item."No.", LibraryRandom.RandInt(10), '', WorkDate());

        LibraryPurchase.CreateDropShipmentPurchasingCode(Purchasing);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);

        // [GIVEN] Run "Get drop shipment" action from the requisition worksheet
        GetDropShipment(RequisitionLine, SalesLine);

        // [WHEN] Run "Carry Out Action Message" in the requisition worksheet
        LibraryPlanning.CarryOutReqWksh(RequisitionLine, WorkDate(), WorkDate(), WorkDate(), WorkDate(), '');

        // [THEN] Purchase Order is created and its "Sell-to Customer No." field is populated with "SO"."Sell-to Customer No."
        FindPurchaseHeaderByItemNo(PurchaseHeader, Item."No.");
        PurchaseHeader.TestField("Sell-to Customer No.", SalesHeader."Sell-to Customer No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestItemCardReplenishmentSystem()
    var
        Item: Record item;
        ItemCard: TestPage "Item Card";
    begin
        Initialize();

        LibraryInventory.CreateItem(Item);

        // open the page
        ItemCard.OpenEdit();

        // test allowed options
        ItemCard."Replenishment System".Value(Format(Item."Replenishment System"::Assembly));
        ItemCard."Replenishment System".Value(Format(Item."Replenishment System"::Purchase));
        ItemCard."Replenishment System".Value(Format(Item."Replenishment System"::"Prod. Order"));

        // test not allowed options
        asserterror ItemCard."Replenishment System".Value(Format(Item."Replenishment System"::" "));
        asserterror ItemCard."Replenishment System".Value(Format(Item."Replenishment System"::Transfer));
    end;

    [Test]
    [Scope('OnPrem')]
    [HandlerFunctions('OrderPromisingHandler')]
    procedure PlanDelDateAndEarliestShptDateInOrderPromLinesIsSumOfLeadTimeCalcOfItemVendAndInvntSetupAndOrderPromSetup()
    var
        Customer: Record Customer;
        Item: Record Item;
        ItemVendor: Record "Item Vendor";
        InventorySetup: Record "Inventory Setup";
        OrderPromisingSetup: Record "Order Promising Setup";
        SalesHeader: Record "Sales Header";
        Salesline: Record "Sales Line";
        Vendor: Record Vendor;
        DateFormula: DateFormula;
        PlannedDeliveryDate: Date;
    begin
        // [SCENARIO 568517] "Planned Delivery Date" and "Earliest Shipment Date" in Order Promising Lines is equal to the sum of "Lead Time Calculation" of ItemVendor, "Default Safety Lead Time" of Inventory Setup and "Offset (Time)" of Order Promising Setup.
        Initialize();

        // [GIVEN] Generate and save DateFormula in a variable.
        Evaluate(DateFormula, StrSubstNo('%1D', LibraryRandom.RandIntInRange(1, 1)));

        // [GIVEN] Validate "Default Safety Lead Time" in Inventory Setup.
        InventorySetup.Get();
        InventorySetup.Validate("Default Safety Lead Time", DateFormula);
        InventorySetup.Modify(true);

        // [GIVEN] Validate "Offset (Time)" in Order Promising Setup.
        OrderPromisingSetup.Get();
        OrderPromisingSetup.Validate("Offset (Time)", DateFormula);
        OrderPromisingSetup.Modify(true);

        // [GIVEN] Generate and save DateFormula in a variable.
        Evaluate(DateFormula, StrSubstNo('%1D', LibraryRandom.RandIntInRange(10, 10)));

        // [GIVEN] Create a Vendor and Validate "Lead Time Calculation".
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Lead Time Calculation", DateFormula);
        Vendor.Modify(true);

        // [GIVEN] Generate and save DateFormula in a variable.
        Evaluate(DateFormula, StrSubstNo('%1D', LibraryRandom.RandIntInRange(20, 20)));

        // [GIVEN] Create an Item and Validate "Vendor No." and "Lead Time Calculation".
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Validate("Lead Time Calculation", DateFormula);
        Item.Modify(true);

        // [GIVEN] Create an ItemVendor.
        CreateItemVendor(ItemVendor, Vendor."No.", Item."No.", '');

        // [GIVEN] Create a Customer.
        LibrarySales.CreateCustomer(Customer);

        // [GIVEN] Create a Sales Header.
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");

        // [GIVEN] Create a Sales Line.
        LibrarySales.CreateSalesLine(Salesline, SalesHeader, Salesline.Type::Item, Item."No.", LibraryRandom.RandIntInRange(2, 2));

        // [GIVEN] Generate and save PlannedDeliveryDate in a Variable.
        PlannedDeliveryDate := CalcDate('<' + Format(ItemVendor."Lead Time Calculation") + '+' + Format(InventorySetup."Default Safety Lead Time") + '+' + Format(OrderPromisingSetup."Offset (Time)") + '>', WorkDate());

        // [WHEN] Open Order Promising Page.
        LibraryVariableStorage.Enqueue(PlannedDeliveryDate);
        LibraryVariableStorage.Enqueue(PlannedDeliveryDate);
        OpenOrderPromisingPage(SalesHeader."No.");

        // [THEN] Run Capable-to-Promise action and "Planned Delivery Date" and "Earliest Shipment Date" 
        // are equal to PlannedDeliveryDate in OrderPromisingHandler.
    end;

    [Test]
    procedure JobDemandWithMultiplePlanningLines()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        Job: Record Job;
        JobTask: Record "Job Task";
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLine2: Record "Job Planning Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        RequisitionLine: Record "Requisition Line";
        LibraryJob: Codeunit "Library - Job";
        FirstQuantity: Decimal;
        SecondQuantity: Decimal;
    begin
        // [SCENARIO 611683] Order Planning for Job Demand with multiple planning lines should not net received quantities across lines.
        Initialize();

        // [GIVEN] Create Item with Replenishment Method = Purchase
        LibraryPurchase.CreateVendor(Vendor);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', Vendor."No.");

        // [GIVEN] Create Job with Apply Usage Link = TRUE
        LibraryJob.CreateJob(Job);
        Job.Validate("Apply Usage Link", true);
        Job.Modify(true);

        // [GIVEN] Create Job Task Line of type Posting
        LibraryJob.CreateJobTask(Job, JobTask);

        // [GIVEN] Create first Job Planning Line with Quantity = 2
        FirstQuantity := 2;
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.Validate("No.", Item."No.");
        JobPlanningLine.Validate(Quantity, FirstQuantity);
        JobPlanningLine.Modify(true);

        // [GIVEN] Run Order Planning for Job Demand
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [GIVEN] Make Purchase Order from Requisition Line
        LibraryPlanning.CarryOutActionMsgPlanWksh(RequisitionLine);

        // [GIVEN] Purchase Order is created
        PurchaseLine.SetRange("Job No.", Job."No.");
        PurchaseLine.SetRange("No.", Item."No.");
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");

        // [GIVEN] Post Receipt only (not invoice)
        PurchaseHeader.Validate("Vendor Invoice No.", LibraryUtility.GenerateGUID());
        PurchaseHeader.Modify(true);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, false);

        // [GIVEN] Create second Job Planning Line for same item with Quantity = 10
        SecondQuantity := 10;
        LibraryJob.CreateJobPlanningLine(JobPlanningLine2."Line Type"::Budget, JobPlanningLine2.Type::Item, JobTask, JobPlanningLine2);
        JobPlanningLine2.Validate("No.", Item."No.");
        JobPlanningLine2.Validate(Quantity, SecondQuantity);
        JobPlanningLine2.Modify(true);

        // [WHEN] Run Order Planning again for Job Demand
        RequisitionLine.DeleteAll();
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [THEN] Requisition Line is created with Quantity = 10 (not 8)
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.SetRange("Demand Order No.", Job."No.");
        RequisitionLine.FindFirst();
        Assert.AreEqual(SecondQuantity, RequisitionLine.Quantity, StrSubstNo(RequisitionLineQtyErr, SecondQuantity));
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Planning - I");
        ClearGlobals();

        LibraryApplicationArea.EnableEssentialSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Planning - I");

        CreateLocationSetup();
        NoSeriesSetup();
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Planning - I");
    end;

    local procedure ClearGlobals()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Clear(VerifyOnGlobal);
        Clear(DemandTypeGlobal);
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

    local procedure ChangeReplenishmentSystem(var RequisitionLine: Record "Requisition Line"; OldReplenishmentSystem: Enum "Replenishment System"; NewReplenishmentSystem: Enum "Replenishment System"; DemandOrderNo: Code[20]; VendorNo: Code[20])
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("Replenishment System", OldReplenishmentSystem);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Replenishment System", NewReplenishmentSystem);
        RequisitionLine.Validate("Vendor No.", VendorNo);
        RequisitionLine.Modify(true);
    end;

    local procedure ChangeManufUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; ReqWkshTemplateName: Code[10]; RequisitionWkshName: Code[10])
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Copy to Req. Wksh",
              ManufacturingUserTemplate."Create Production Order"::"Copy to Req. Wksh",
              ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");

        ManufacturingUserTemplate.Validate("Purchase Req. Wksh. Template", ReqWkshTemplateName);
        ManufacturingUserTemplate.Validate("Purchase Wksh. Name", RequisitionWkshName);
        ManufacturingUserTemplate.Validate("Prod. Req. Wksh. Template", ReqWkshTemplateName);
        ManufacturingUserTemplate.Validate("Prod. Wksh. Name", RequisitionWkshName);
        ManufacturingUserTemplate.Modify(true);
    end;

    local procedure ClearRequisitionLines(OrderNo: Code[20]; OrderNo2: Code[20]; OrderNo3: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetFilter("Demand Order No.", '<>%1&<>%2&<>%3', OrderNo, OrderNo2, OrderNo3);
        RequisitionLine.DeleteAll(true);
    end;

    local procedure CreateManufacturingSetup(var Item: Record Item; var ChildItem: Record Item; BOMQuantity: Decimal; ChildWithBOM: Boolean)
    var
        ChildItem2: Record Item;
    begin
        if ChildWithBOM then
            CreateProdItem(ChildItem, ChildItem2) // Create Child Item with its own Production BOM hierarchy.
        else
            CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '', '');
        UpdateItem(ChildItem, ChildItem.Reserve::Optional);  // Child Item with Order Tracking - None.
        CreateItemWithProductionBOM(Item, ChildItem, '', BOMQuantity);
    end;

    local procedure CreateProdItem(var ParentItem: Record Item; var ChildItem: Record Item)
    begin
        // Create Child Item.
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '', '');

        // Create Parent Item.
        CreateItemWithProductionBOM(ParentItem, ChildItem, '', LibraryRandom.RandDec(100, 2));
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
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", RoutingHeader."No.", ProductionBOMHeader."No.", '');
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; RoutingHeaderNo: Code[20]; ProductionBOMNo: Code[20]; VendorNo: Code[20])
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        LibraryInventory.CreateItem(Item);
        GeneralLedgerSetup.Get();
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(20, 2));
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Rounding Precision", GeneralLedgerSetup."Amount Rounding Precision");
        if VendorNo = '' then
            VendorNo := LibraryPurchase.CreateVendorNo();
        Item.Validate("Vendor No.", VendorNo);
        Item.Validate("Routing No.", RoutingHeaderNo);
        Item.Validate("Production BOM No.", ProductionBOMNo);
        Item.Modify(true);
    end;

    local procedure CreateItemWithVendorNo(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", LibraryPurchase.CreateVendorNo());
        Item.Modify(true);
    end;

    local procedure MockItem(var Item: Record Item)
    begin
        Item."No." := LibraryUtility.GenerateGUID();
        Item."Indirect Cost %" := LibraryRandom.RandDec(10, 2);
        Item."Overhead Rate" := LibraryRandom.RandDec(10, 2);
        Item.Insert();
    end;

    local procedure MockProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ItemNo: Code[20])
    begin
        ProdOrderLine."Prod. Order No." := LibraryUtility.GenerateGUID();
        ProdOrderLine."Item No." := ItemNo;
        ProdOrderLine."Indirect Cost %" := LibraryRandom.RandDec(10, 2);
        ProdOrderLine."Overhead Rate" := LibraryRandom.RandDec(10, 2);
        ProdOrderLine.Insert();
    end;

    local procedure UpdateItem(var Item: Record Item; Reserve: Enum "Reserve Method")
    begin
        Item.Validate("Reordering Policy", Item."Reordering Policy"::"Lot-for-Lot");
        Item.Validate(Reserve, Reserve);
        Item.Validate("Order Tracking Policy", Item."Order Tracking Policy"::None);
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
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
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
          RoutingLine, RoutingHeader, CenterNo, OperationNo, LibraryRandom.RandDec(5, 2), LibraryRandom.RandDec(5, 2));
    end;

    local procedure ClearManufacturingUserTemplate()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        ManufacturingUserTemplate.SetRange("User ID", UserId);
        if ManufacturingUserTemplate.FindFirst() then
            ManufacturingUserTemplate.Delete(true);
    end;

    local procedure CreateAndPostConsumWithQty(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalBatch: Record "Item Journal Batch";
    begin
        LibraryManufacturing.CreateProdItemJournal(ItemJournalBatch, '', ItemJournalBatch."Template Type"::Consumption, ProductionOrderNo);
        UpdateQuantityOnConsmpJournal(ProductionOrderNo, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; DueDate: Date)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Validate("Due Date", DueDate);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateAndReleasePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal)
    begin
        CreatePurchaseOrder(PurchaseHeader, ItemNo, Quantity, LibraryRandom.RandDec(100, 2));
        LibraryPurchase.ReleasePurchaseDocument(PurchaseHeader);
    end;

    local procedure CreateAndUpdateSKU(Item: Record Item; LocationBlue: Record Location; LocationRed: Record Location; LocationOrange: Record Location)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        Item.SetRange("No.", Item."No.");
        LibraryInventory.CreateStockKeepingUnit(Item, "SKU Creation Method"::"Location & Variant", false, false);
        UpdatePurchReplenishmentOnSKU(
          StockkeepingUnit, Item, LocationOrange, StockkeepingUnit."Replenishment System"::Purchase, Item."Vendor No.");
        UpdatePurchReplenishmentOnSKU(StockkeepingUnit, Item, LocationRed, StockkeepingUnit."Replenishment System"::"Prod. Order", '');
        UpdateTransReplenishmentOnSKU(
          StockkeepingUnit, Item, LocationBlue, StockkeepingUnit."Replenishment System"::Transfer, LocationRed.Code);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateLocation(LocationRed, false);
        CreateLocation(LocationBlue, false);
        CreateLocation(LocationBlue2, false);
        CreateLocation(LocationIntransit, true);
        CreateTransferRoutesSetup(LocationRed, LocationBlue, LocationBlue2, LocationIntransit);
    end;

    local procedure CreateMultipleSalesOrder(var SalesHeader: Record "Sales Header"; var SalesHeader2: Record "Sales Header"; var SalesHeader3: Record "Sales Header"; LocationCode: Code[10]; LocationCode2: Code[10]; ItemNo: Code[20]; ItemNo2: Code[20])
    var
        Quantity: Decimal;
        QuantityToShip: Decimal;
    begin
        // Random values used are not important for test.
        Quantity := LibraryRandom.RandDec(100, 2) + 10;
        QuantityToShip := LibraryRandom.RandDec(10, 2);

        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, WorkDate(), Quantity, QuantityToShip);
        CreateSalesLine(SalesHeader, ItemNo2, LocationCode, WorkDate(), Quantity, QuantityToShip);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode2, WorkDate(), Quantity, QuantityToShip);

        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesHeader2, ItemNo, LocationCode, WorkDate(), Quantity, QuantityToShip);

        LibrarySales.CreateSalesHeader(SalesHeader3, SalesHeader3."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesHeader3, ItemNo2, LocationCode2, WorkDate(), Quantity, QuantityToShip);
    end;

    local procedure CreatePurchaseOrder(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20]; Quantity: Decimal; DirectUnitCost: Decimal)
    var
        PurchaseLine: Record "Purchase Line";
    begin
        // Create Purchase Order with One Item Line.Random values used are not important for test.
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, '');
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, ItemNo, Quantity);
        PurchaseLine.Validate("Qty. to Receive", Quantity);
        PurchaseLine.Validate("Direct Unit Cost", DirectUnitCost);
        PurchaseLine.Modify(true);
    end;

    local procedure CreateProdOrderForItem(var ProductionOrder: Record "Production Order"; var ParentItem: Record Item; Qty: Decimal)
    var
        ChildItem: Record Item;
    begin
        CreateManufacturingSetup(ParentItem, ChildItem, Qty, false);
        UpdateItemInventory(Qty, ChildItem."No.");
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", '', LibraryRandom.RandDec(5, 2), WorkDate());
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; ShipmentDate: Date; Quantity: Decimal; QuantityToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
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

    local procedure CreateLocation(var Location: Record Location; UseAsInTransit: Boolean)
    begin
        Clear(Location);
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        if UseAsInTransit then begin
            Location.Validate("Use As In-Transit", true);
            Location.Modify(true);
        end;
    end;

    local procedure CreateTransferRoutesSetup(LocationRed: Record Location; LocationBlue: Record Location; LocationOrange: Record Location; TransitLocation: Record Location)
    begin
        CreateTransferRoute(LocationRed.Code, LocationBlue.Code, TransitLocation.Code);
        CreateTransferRoute(LocationBlue.Code, LocationRed.Code, TransitLocation.Code);
        CreateTransferRoute(LocationBlue.Code, LocationOrange.Code, TransitLocation.Code);
        CreateTransferRoute(LocationOrange.Code, LocationRed.Code, TransitLocation.Code);
        CreateTransferRoute(LocationOrange.Code, LocationBlue.Code, TransitLocation.Code);
    end;

    local procedure CreateTransferRoute(LocationCode: Code[10]; LocationCode2: Code[10]; TransitLocationCode: Code[10])
    var
        TransferRoute: Record "Transfer Route";
    begin
        LibraryWarehouse.CreateTransferRoute(TransferRoute, LocationCode, LocationCode2);
        TransferRoute.Validate("In-Transit Code", TransitLocationCode);
        TransferRoute.Modify(true);
    end;

    local procedure CreateRequisitionWorksheetName(var RequisitionWkshName: Record "Requisition Wksh. Name")
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
    begin
        ReqWkshTemplate.SetRange(Type, ReqWkshTemplate.Type::"Req.");
        RequisitionWkshName.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
    end;

    local procedure CreateItemWithPurchUnitOfMeasure(var Item: Record Item)
    var
        UnitOfMeasure: Record "Unit of Measure";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '', '');
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", UnitOfMeasure.Code, 1);
        Item.Validate("Purch. Unit of Measure", UnitOfMeasure.Code);
        Item.Modify(true);
    end;

    local procedure CreateRequisitionLine(var RequisitionLine: Record "Requisition Line"; No: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        RequisitionLine.Validate(Type, RequisitionLine.Type::Item);
        RequisitionLine.Validate("No.", No);
        RequisitionLine.Modify(true);
    end;

    local procedure CreateAndPostOutputJournal(ProductionOrderNo: Code[20]; ItemNo: Code[20])
    var
        ItemJournalLine: Record "Item Journal Line";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Output);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type, ItemJournalTemplate.Name);
        LibraryManufacturing.CreateOutputJournal(ItemJournalLine, ItemJournalTemplate, ItemJournalBatch, ItemNo, ProductionOrderNo);
        LibraryManufacturing.OutputJnlExplodeRoute(ItemJournalLine);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure CreateInvtAdjmtEntryOrder(var InvtAdjmtEntryOrder: Record "Inventory Adjmt. Entry (Order)"; ItemNo: Code[20])
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(InvtAdjmtEntryOrder);
        InvtAdjmtEntryOrder."Order Type" := InvtAdjmtEntryOrder."Order Type"::Production;
        InvtAdjmtEntryOrder."Order No." := LibraryUtility.GenerateGUID();
        InvtAdjmtEntryOrder."Order Line No." := LibraryUtility.GetNewLineNo(RecRef, InvtAdjmtEntryOrder.FieldNo("Order Line No."));
        InvtAdjmtEntryOrder."Item No." := ItemNo;
        InvtAdjmtEntryOrder."Cost is Adjusted" := false;
        InvtAdjmtEntryOrder.Insert();
    end;

    local procedure CalculateExpectedQuantity(DocumentType: Enum "Sales Document Type"; OutStandingQuantity: Decimal): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        if DocumentType = SalesHeader."Document Type"::"Return Order" then
            OutStandingQuantity := -OutStandingQuantity;

        exit(OutStandingQuantity);
    end;

    local procedure GetSpecialOrder(var RequisitionLine: Record "Requisition Line"; ItemNo: Code[20])
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSpecialOrder(RequisitionLine, ItemNo);
    end;

    local procedure GetDropShipment(var RequisitionLine: Record "Requisition Line"; var SalesLine: Record "Sales Line")
    var
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        CreateRequisitionWorksheetName(RequisitionWkshName);
        LibraryPlanning.CreateRequisitionLine(RequisitionLine, RequisitionWkshName."Worksheet Template Name", RequisitionWkshName.Name);
        LibraryPlanning.GetSalesOrders(SalesLine, RequisitionLine, 0);
    end;

    local procedure SetRoutingOnProdOrderLine(ProdOrdeNo: Code[20]; NewRoutingNo: Code[20]) OldRoutingNo: Code[20]
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrdeNo);
        ProdOrderLine.FindFirst();
        OldRoutingNo := ProdOrderLine."Routing No.";
        ProdOrderLine.Validate("Routing No.", NewRoutingNo);
        ProdOrderLine.Modify(true);
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

    local procedure FindPurchaseLine(var PurchaseLine: Record "Purchase Line"; DocumentNo: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", DocumentNo);
        PurchaseLine.FindSet();
    end;

    local procedure FindPurchaseHeaderByItemNo(var PurchaseHeader: Record "Purchase Header"; ItemNo: Code[20])
    var
        PurchaseLine: Record "Purchase Line";
    begin
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", ItemNo);
        PurchaseLine.FindFirst();
        PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
    end;

    local procedure FilterRequisitionWorksheetLine(var RequisitionLine: Record "Requisition Line"; RequisitionWkshName: Record "Requisition Wksh. Name")
    begin
        RequisitionLine.SetRange("Worksheet Template Name", RequisitionWkshName."Worksheet Template Name");
        RequisitionLine.SetRange("Journal Batch Name", RequisitionWkshName.Name);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
    end;

    local procedure GetManufacturingUserTemplate(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders",
              CreateProductionOrder, ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
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

    local procedure MakeSupplyOrdersAllLine(var RequisitionLine: Record "Requisition Line"; OrderNo: Code[20]; OrderNo2: Code[20]; OrderNo3: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        RequisitionLine.SetFilter("Demand Order No.", '%1|%2|%3', OrderNo, OrderNo2, OrderNo3);
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"All Lines",
          ManufacturingUserTemplate."Create Production Order"::"Firm Planned");
    end;

    local procedure MakeSupplyOrdersActiveLine(DemandOrderNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10]; CreateProductionOrder: Enum "Planning Create Prod. Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange("No.", ItemNo);
        RequisitionLine.SetRange("Location Code", LocationCode);
        RequisitionLine.FindFirst();
        MakeSupplyOrders(RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Line", CreateProductionOrder);
    end;

    local procedure MakeSupplyOrders(var RequisitionLine: Record "Requisition Line"; MakeOrders: Option; CreateProductionOrder: Enum "Planning Create Prod. Order")
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        GetManufacturingUserTemplate(ManufacturingUserTemplate, MakeOrders, CreateProductionOrder);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure MakeOrderWithChangeOption(DemandOrderNo: Code[20]; ReqWkshTemplateName: Code[10]; RequisitionWkshName: Code[10])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();
        ChangeManufUserTemplate(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Order", ReqWkshTemplateName, RequisitionWkshName);
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
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

    local procedure UpdateItemInventory(Quantity: Decimal; ItemNo: Code[20])
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        // Create Item Journal to populate Item Quantity.
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, "Item Journal Template Type"::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, "Item Journal Template Type"::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name, ItemJournalLine."Entry Type"::Purchase, ItemNo,
          Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure UpdateQuantityOnConsmpJournal(ProductionOrderNo: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        ItemJournalLine.SetRange("Order Type", ItemJournalLine."Order Type"::Production);
        ItemJournalLine.SetRange("Order No.", ProductionOrderNo);
        ItemJournalLine.FindSet();
        repeat
            ItemJournalLine.Validate(Quantity, Quantity);
            ItemJournalLine.Modify(true);
        until ItemJournalLine.Next() = 0;
    end;

    local procedure UpdateTransReplenishmentOnSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; Location: Record Location; ReplenishmentSystem: Enum "Replenishment System"; TransferFromCode: Code[10])
    begin
        // Update Replenishment System on Stock Keeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.SetRange("Location Code", Location.Code);
        StockkeepingUnit.FindFirst();
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Transfer-from Code", TransferFromCode);
        StockkeepingUnit.Modify(true);
    end;

    local procedure UpdatePurchReplenishmentOnSKU(var StockkeepingUnit: Record "Stockkeeping Unit"; Item: Record Item; Location: Record Location; ReplenishmentSystem: Enum "Replenishment System"; VendorNo: Code[20])
    begin
        // Update Replenishment System on Stock Keeping Unit.
        StockkeepingUnit.SetRange("Item No.", Item."No.");
        StockkeepingUnit.SetRange("Location Code", Location.Code);
        StockkeepingUnit.FindFirst();
        StockkeepingUnit.Validate("Replenishment System", ReplenishmentSystem);
        StockkeepingUnit.Validate("Vendor No.", VendorNo);
        StockkeepingUnit.Modify(true);
    end;

    local procedure AssertNoLinesForItem(DemandOrderNo: Code[20]; No: Code[20]; LocationCode: Code[10]; NoOfLines: Integer)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetCurrentKey(Type, "No.", "Variant Code", "Location Code", "Starting Date");
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("No.", No);
        if LocationCode <> '' then
            RequisitionLine.SetRange("Location Code", LocationCode);
        Assert.AreEqual(NoOfLines, RequisitionLine.Count, StrSubstNo(LineCountError, No));
    end;

    local procedure VerifyDemandQtyAndLocation(DemandOrderNo: Code[20]; DemandType: Option; Status: Enum "Production Order Status")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ExpectedOutstandingQuantity: Decimal;
    begin
        case DemandType of
            DemandTypeGlobal::Sales:
                begin
                    SalesLine.SetRange("Document No.", DemandOrderNo);
                    SalesLine.FindSet();
                    repeat
                        SalesHeader.Get(SalesLine."Document Type", SalesLine."Document No.");
                        FindRequisitionLine(RequisitionLine, SalesLine."Document No.", SalesLine."No.", SalesLine."Location Code");
                        RequisitionLine.SetRange("Location Code", SalesLine."Location Code");
                        RequisitionLine.FindFirst();
                        ExpectedOutstandingQuantity := CalculateExpectedQuantity(SalesHeader."Document Type", SalesLine."Outstanding Quantity");
                        RequisitionLine.TestField("Demand Quantity", ExpectedOutstandingQuantity);
                        RequisitionLine.TestField(Status, SalesHeader.Status);
                        RequisitionLine.TestField("Location Code", SalesLine."Location Code");
                        RequisitionLine.TestField("Due Date", SalesLine."Shipment Date");
                    until SalesLine.Next() = 0;
                end;
            DemandTypeGlobal::Production:
                begin
                    ProdOrderComponent.SetRange("Prod. Order No.", DemandOrderNo);
                    ProdOrderComponent.SetRange(Status, Status);
                    ProdOrderComponent.FindSet();
                    repeat
                        FindRequisitionLine(
                          RequisitionLine, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Item No.", ProdOrderComponent."Location Code");
                        RequisitionLine.TestField("Demand Quantity", ProdOrderComponent."Remaining Quantity");
                        RequisitionLine.TestField("Location Code", ProdOrderComponent."Location Code");
                        RequisitionLine.TestField("Due Date", ProdOrderComponent."Due Date");
                    until ProdOrderComponent.Next() = 0;
                end;
        end;
    end;

    local procedure VerifyPurchaseQtyAgainstProd(ProductionOrder: Record "Production Order")
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.FindSet();
        Clear(ProductionOrder);
        repeat
            Item.Get(ProdOrderComponent."Item No.");
            case Item."Replenishment System" of
                Item."Replenishment System"::Purchase:
                    begin
                        PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
                        PurchaseLine.FindFirst();
                        PurchaseLine.TestField("Buy-from Vendor No.", Item."Vendor No.");
                        PurchaseLine.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
                        PurchaseLine.TestField("Location Code", ProdOrderComponent."Location Code");
                    end;
                Item."Replenishment System"::"Prod. Order":
                    begin
                        ProductionOrder.SetRange("Source No.", Item."No.");
                        ProductionOrder.FindFirst();
                        ProductionOrder.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
                        ProductionOrder.TestField("Location Code", ProdOrderComponent."Location Code");
                    end;
            end;
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyPurchaseLine(PurchaseLine: Record "Purchase Line"; No: Code[20]; Quantity: Decimal; ExpectedReceiptDate: Date)
    begin
        PurchaseLine.TestField("No.", No);
        PurchaseLine.TestField(Quantity, Quantity);
        PurchaseLine.TestField("Expected Receipt Date", ExpectedReceiptDate);
    end;

    local procedure VerifyDemandQtyWithPurchQty(SalesOrderNo: Code[20]; ItemNo: Code[20]; LocationCode: Code[10])
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.SetRange("Location Code", LocationCode);
        SalesLine.FindFirst();

        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.SetRange("Location Code", LocationCode);
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, SalesLine."Outstanding Quantity");
    end;

    local procedure VerifyQtyWithRequiredQtySKU(ProductionOrderNo: Code[20]; VerifyOn: Option; Status: Enum "Production Order Status")
    var
        PurchaseLine: Record "Purchase Line";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        StockkeepingUnit: Record "Stockkeeping Unit";
        TransferLine: Record "Transfer Line";
        RequisitionLine: Record "Requisition Line";
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrderNo);
        ProdOrderComponent.SetRange(Status, Status);
        ProdOrderComponent.FindSet();
        repeat
            StockkeepingUnit.SetRange("Location Code", ProdOrderComponent."Location Code");
            StockkeepingUnit.SetRange("Item No.", ProdOrderComponent."Item No.");
            StockkeepingUnit.SetRange("Variant Code", ProdOrderComponent."Variant Code");
            StockkeepingUnit.FindFirst();
            case StockkeepingUnit."Replenishment System" of
                StockkeepingUnit."Replenishment System"::Purchase:
                    case VerifyOn of
                        VerifyOnGlobal::Orders:
                            begin
                                PurchaseLine.SetRange("No.", ProdOrderComponent."Item No.");
                                PurchaseLine.FindFirst();
                                PurchaseLine.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
                                PurchaseLine.TestField("Expected Receipt Date", ProdOrderComponent."Due Date");
                            end;
                        VerifyOnGlobal::RequisitionLine:
                            begin
                                FindRequisitionLine(
                                  RequisitionLine, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Item No.",
                                  ProdOrderComponent."Location Code");
                                RequisitionLine.TestField("Replenishment System", StockkeepingUnit."Replenishment System");
                                RequisitionLine.TestField("Supply From", StockkeepingUnit."Vendor No.");
                                RequisitionLine.TestField("Due Date", ProdOrderComponent."Due Date");
                            end;
                    end;
                StockkeepingUnit."Replenishment System"::"Prod. Order":
                    case VerifyOn of
                        VerifyOnGlobal::Orders:
                            begin
                                ProductionOrder.SetRange("Source No.", ProdOrderComponent."Item No.");
                                ProductionOrder.FindFirst();
                                ProductionOrder.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
                            end;
                        VerifyOnGlobal::RequisitionLine:
                            begin
                                FindRequisitionLine(
                                  RequisitionLine, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Item No.",
                                  ProdOrderComponent."Location Code");
                                RequisitionLine.TestField("Replenishment System", StockkeepingUnit."Replenishment System");
                                RequisitionLine.TestField("Due Date", ProdOrderComponent."Due Date");
                            end;
                    end;
                StockkeepingUnit."Replenishment System"::Transfer:
                    case VerifyOn of
                        VerifyOnGlobal::Orders:
                            begin
                                TransferLine.SetRange("Item No.", ProdOrderComponent."Item No.");
                                TransferLine.FindFirst();
                                TransferLine.TestField(Quantity, ProdOrderComponent."Remaining Quantity");
                            end;
                        VerifyOnGlobal::RequisitionLine:
                            begin
                                FindRequisitionLine(
                                  RequisitionLine, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Item No.",
                                  ProdOrderComponent."Location Code");
                                RequisitionLine.TestField("Replenishment System", StockkeepingUnit."Replenishment System");
                                RequisitionLine.TestField("Supply From", StockkeepingUnit."Transfer-from Code");
                                RequisitionLine.TestField("Due Date", ProdOrderComponent."Due Date");
                            end;
                    end;
            end;
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure VerifyRequisitionWorksheet(var RequisitionLine: Record "Requisition Line"; No: Code[20]; ShipmentDate: Date; LocationCode: Code[10]; Quantity: Decimal)
    begin
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Location Code", LocationCode);
        RequisitionLine.TestField("Due Date", ShipmentDate);
    end;

    local procedure RestoreSalesReceivableSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    local procedure OpenOrderPromisingPage(SalesHeaderNo: Code[20])
    var
        SalesOrder: TestPage "Sales Order";
    begin
        SalesOrder.OpenView();
        SalesOrder.Filter.SetFilter("No.", SalesHeaderNo);
        SalesOrder.SalesLines.OrderPromising.Invoke();
    end;

    local procedure CreateItemVendor(var ItemVendor: Record "Item Vendor"; VendorNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        ItemVendor.Init();
        ItemVendor."Vendor No." := VendorNo;
        ItemVendor."Item No." := ItemNo;
        ItemVendor."Variant Code" := VariantCode;
        Evaluate(ItemVendor."Lead Time Calculation", StrSubstNo('<%1D>', LibraryRandom.RandIntInRange(10, 10)));
        ItemVendor."Vendor Item No." := LibraryUtility.GenerateGUID();
        ItemVendor.Insert(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure OrderPromisingHandler(var OrderPromisingLines: TestPage "Order Promising Lines")
    begin
        OrderPromisingLines.CapableToPromise.Invoke();
        OrderPromisingLines.First();
        OrderPromisingLines."Planned Delivery Date".AssertEquals(LibraryVariableStorage.DequeueDate());
        OrderPromisingLines."Earliest Shipment Date".AssertEquals(LibraryVariableStorage.DequeueDate());
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandlerTrue(ConfirmMessage: Text[1024]; var Reply: Boolean)
    begin
        Assert.AreNotEqual(0, StrPos(ConfirmMessage, FinishOrderMessage), ConfirmMessage);
        Reply := true;
    end;
}

