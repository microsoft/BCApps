codeunit 137087 "SCM Order Planning - II"
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
        LibraryERM: Codeunit "Library - ERM";
        LibraryJob: Codeunit "Library - Job";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryService: Codeunit "Library - Service";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryDimension: Codeunit "Library - Dimension";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        DemandTypeGlobal: Option Sales,Production;
        IsInitialized: Boolean;
        ValidationError: Label '%1  must be %2 in %3.';
        LocationErrorText: Label 'Location Code must be equal to ''%1''  in Requisition Line';
        ExpectedQuantity: Decimal;
        QuantityError: Label 'Available Quantity must match.';
        RequisitionLineMustNotExist: Label 'Requisition Line must not exist for Item %1.';
        PostDateOutOfRangeErr: Label 'Posting Date is not within your range of allowed posting dates in Warehouse Shipment Header No.=';

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningChangeItem()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
    begin
        // Setup: Create Sales Order planning setup,Create new item, and change Item on sales line after calculate order planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateSalesOrderPlanningSetup(SalesHeader, Item, '', LibraryRandom.RandDec(10, 2));
        CreateItem(Item2, Item2."Replenishment System"::Purchase, '', '');

        // Change Item No in sales Line.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("No."), Item2."No.");

        // Exercise: Run Make Supply Order.
        SalesHeader.Get(SalesHeader."Document Type", SalesHeader."No.");
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify that error message is same as accepted during make order when change sales line No. after calculate plan.
        Assert.ExpectedTestFieldError(ReqLine.FieldCaption("No."), Item2."No.");
        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrdPlngChangeShipmentDate()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
        ShipmentDate: Date;
    begin
        // Setup: Create Sales Order planning setup, and change Shipment Date on sales line after calculate order planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateSalesOrderPlanningSetup(SalesHeader, Item, '', LibraryRandom.RandDec(10, 2));
        ShipmentDate := CalcDate('<' + Format(LibraryRandom.RandInt(2) + 2) + 'D>', WorkDate());

        // Change Shipment Date On Sales Line.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Shipment Date"), ShipmentDate);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify that error message is same as accepted during make order when change sales line Shipment Date after calculate plan.
        Assert.ExpectedTestFieldError(ReqLine.FieldCaption("Demand Date"), Format(ShipmentDate));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningChangeQty()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ReqLine: Record "Requisition Line";
        Quantity: Decimal;
        Quantity2: Decimal;
    begin
        // Setup: Create Sales Order planning setup, and change Quantity on sales line after calculate order planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateSalesOrderPlanningSetup(SalesHeader, Item, '', Quantity);
        Quantity2 := Quantity + LibraryRandom.RandDec(10, 2);

        // Change Quantity On Sales Line.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo(Quantity), Quantity2);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify that error message is same as accepted during make order when change sales line Quantity after calculate plan.
        Assert.ExpectedTestFieldError(ReqLine.FieldCaption("Demand Quantity (Base)"), Format(Quantity2));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningChangeLoc()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        Item: Record Item;
        ReqLine: Record "Requisition Line";
    begin
        // Setup: Create Sales Order planning setup, and change Location on sales line after calculate order planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateSalesOrderPlanningSetup(SalesHeader, Item, LocationRed.Code, LibraryRandom.RandDec(10, 2));

        // Change Location On Sales Line.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Location Code"), LocationBlue.Code);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify that error message is same as accepted during make order when change sales line Location Code after calculate plan.
        Assert.ExpectedTestFieldError(ReqLine.FieldCaption("Location Code"), LocationBlue.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderPlanningChangeUOM()
    var
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Item: Record Item;
        ReqLine: Record "Requisition Line";
    begin
        // Setup: Create Sales Order planning setup, and change Unit Of Measure Code on sales line after calculate order planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateSalesOrderPlanningSetup(SalesHeader, Item, '', LibraryRandom.RandDec(10, 2));

        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, Item."No.", LibraryRandom.RandInt(5) + 1);

        // Change Unit Of Measure On Sales Line.
        ChangeDataOnSalesLine(SalesHeader, Item."No.", SalesLine.FieldNo("Unit of Measure Code"), ItemUnitOfMeasure.Code);

        // Exercise: Run Make Supply Order.
        asserterror MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify that error message is same as accepted during make order when change sales line UOM Code after calculate plan.
        Assert.ExpectedTestFieldError(ReqLine.FieldCaption("Qty. per UOM (Demand)"), Format(ItemUnitOfMeasure."Qty. per Unit of Measure"));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleReleasedSalesOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        PlanningMultipleSalesOrder(Item."Replenishment System"::Purchase, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleOpenSalesOrder()
    var
        Item: Record Item;
    begin
        Initialize();
        PlanningMultipleSalesOrder(Item."Replenishment System"::"Prod. Order", false);
    end;

    local procedure PlanningMultipleSalesOrder(ReplenishmentSystem: Enum "Replenishment System"; StatusReleased: Boolean)
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        Item2: Record Item;
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        SalesHeader3: Record "Sales Header";
    begin
        // Setup : Create Two Item with Replenishment System and create Multiple Sales Order with Status.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateItem(Item, ReplenishmentSystem, '', '');
        CreateItem(Item2, ReplenishmentSystem, '', '');
        CreateMultipleSalesOrder(SalesHeader, SalesHeader2, SalesHeader3, LocationBlue.Code, LocationRed.Code, Item."No.", Item2."No.");

        if StatusReleased then begin
            LibrarySales.ReleaseSalesDocument(SalesHeader);
            LibrarySales.ReleaseSalesDocument(SalesHeader2);
            LibrarySales.ReleaseSalesDocument(SalesHeader3);
        end;

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify.
        VerifyDemandQtyAndLocation(SalesHeader."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);
        VerifyDemandQtyAndLocation(SalesHeader2."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);
        VerifyDemandQtyAndLocation(SalesHeader3."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeSalesReturn()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ParentItem: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Quantity: Decimal;
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory and Replenishment System Production,
        // Create Negative Sales Return.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, ChildItem.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateSalesReturnOrder(SalesHeader, Item."No.", ParentItem."No.", LocationRed.Code, -Quantity);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify.
        VerifyDemandQtyAndLocation(SalesHeader."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeSalesReturnMakeOrder()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        ParentItem: Record Item;
        ChildItem: Record Item;
        SalesHeader: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Quantity: Decimal;
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory and Replenishment System Production,
        // Create Negative Sales Return, and run Order Planning.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        CreateManufacturingSetup(ParentItem, ChildItem, ChildItem.Reserve::Optional);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateSalesReturnOrder(SalesHeader, Item."No.", ParentItem."No.", LocationRed.Code, -Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Make Supply Order with Option Active Order.
        MakeSupplyOrdersActiveOrder(SalesHeader."No.");

        // Verify.
        VerifyReturnQtyWithPurchQty(SalesHeader."No.", Item."No.");
        VerifyQtyWithProdOrder(ParentItem."No.", Quantity, LocationRed.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedAndOpenSalesOrder()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        SalesHeader2: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Quantity: Decimal;
    begin
        // Setup : Create Two Item with Replenishment System Production Order and create Open Sales Order and Released Sales Order.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", '', '');
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order", '', '');
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        CreateSalesOrder(SalesHeader2, Item2."No.", '', Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader2);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify.
        VerifyDemandQtyAndLocation(SalesHeader."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);
        VerifyDemandQtyAndLocation(SalesHeader2."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SalesLinesWithMultipleLocation()
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        Quantity: Decimal;
    begin
        // Setup : Create Two Item with Replenishment System Production Order and create Sales Order with Multiple Sales Line and Location.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", '', '');
        CreateItem(Item2, Item2."Replenishment System"::"Prod. Order", '', '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, Item."No.", LocationRed.Code, Quantity, Quantity);
        CreateSalesLine(SalesHeader, Item2."No.", LocationRed.Code, Quantity, Quantity);
        CreateSalesLine(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        CreateSalesLine(SalesHeader, Item2."No.", LocationBlue.Code, Quantity, Quantity);
        CreateSalesLine(SalesHeader, Item."No.", '', Quantity, Quantity);
        CreateSalesLine(SalesHeader, Item2."No.", '', Quantity, Quantity);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify.
        VerifyDemandQtyAndLocation(SalesHeader."No.", SalesHeader."Document Type", DemandTypeGlobal::Sales, DemandTypeGlobal::Sales);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReplenishmentToProduction()
    var
        Item: Record Item;
    begin
        Initialize();
        ChangeReplenishmentSalesOrder(Item."Replenishment System"::Purchase, Item."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ReplenishmentToPurchase()
    var
        Item: Record Item;
    begin
        Initialize();
        ChangeReplenishmentSalesOrder(Item."Replenishment System"::"Prod. Order", Item."Replenishment System"::Purchase);
    end;

    local procedure ChangeReplenishmentSalesOrder(ReplenishmentSystem: Enum "Replenishment System"; ReplenishmentSystem2: Enum "Replenishment System")
    var
        RequisitionLine: Record "Requisition Line";
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        Quantity: Decimal;
    begin
        // Setup : Create Item , Sales Order , Calculate Planning and Change the Replenishment System.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, ReplenishmentSystem, '', '');
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        ChangeReplenishmentSystem(
          RequisitionLine, ReplenishmentSystem, ReplenishmentSystem2, SalesHeader."No.", LibraryPurchase.CreateVendorNo());

        // Exercise : Make Order for changed Replenishment System on Requisition Line.
        MakeSupplyOrdersActiveLine(
          SalesHeader."No.", RequisitionLine."No.", LocationBlue.Code, ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Verify : Verify That Quantity on Purchase Order or Production Order is same as remaining demand quantity on Sales Order after change Replenishment System on Requisition Line.
        if ReplenishmentSystem2 = Item."Replenishment System"::Purchase then
            VerifyDemandQtyWithPurchQty(SalesHeader."No.", Item."No.", LocationBlue.Code)
        else
            VerifyQtyWithProdOrder(Item."No.", Quantity, LocationBlue.Code);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityAvailableForTransfer()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        OrderPlanning: TestPage "Order Planning";
        Quantity: Decimal;
    begin
        // Setup : Create Item with inventory on location, Sale order and Calculate Plan.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemInventory(Quantity, Item."No.", LocationBlue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue2.Code, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise : Open Order Planning Page.
        OpenOrderPlanningPage(OrderPlanning, SalesHeader."No.", Item."No.");

        // Verify : Check the value of Available to Transfer and Quantity Available.
        OrderPlanning.AvailableForTransfer.AssertEquals(Quantity);
        OrderPlanning.QuantityAvailable.AssertEquals(-Quantity);

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('AlternativeSupplyPageHandler')]
    [Scope('OnPrem')]
    procedure NeededQtyOnAlternativeSupply()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        OrderPlanning: TestPage "Order Planning";
        Quantity: Decimal;
    begin
        // Setup : Create Item with inventory on location, Sale order and Calculate Plan and Open Order Planning Page in edit mode.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemInventory(Quantity, Item."No.", LocationBlue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue2.Code, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        ExpectedQuantity := Quantity;
        OpenOrderPlanningPage(OrderPlanning, SalesHeader."No.", Item."No.");
        Commit();

        // Exercise and Verify : Click on Available for Transfer from order planning page. Check That the value on Get alternative supply page is same as expected, Verification is done under Page Handler.
        OrderPlanning."Alternative Supply".Invoke();

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [HandlerFunctions('GetAlternativeSupplyPageHandler')]
    [Scope('OnPrem')]
    procedure ReplenishmentToTransfer()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary;
        SalesHeader: Record "Sales Header";
        OrderPlanning: TestPage "Order Planning";
        Quantity: Decimal;
    begin
        // Setup : Create Item with inventory on location, Sale order and Calculate Plan and Open Order Planning Page in edit mode and  Click On Assist edit of Available to transfer from order planning page for Get Alternative Supply Page.
        Initialize();
        UpdateSalesReceivablesSetup(TempSalesReceivablesSetup);
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItemInventory(Quantity, Item."No.", LocationBlue.Code);
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue2.Code, Quantity, Quantity);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        OpenOrderPlanningPage(OrderPlanning, SalesHeader."No.", Item."No.");
        Commit();

        // Exercise : Click On Assist Edit Of Available To Transfer, Select the value and click OK on Order Planning Page.
        OrderPlanning."Alternative Supply".Invoke();
        OrderPlanning.OK().Invoke();

        // Verify : Check that Replenishment System and Quantity is same as expected on Order Planning.
        FindRequisitionLine(RequisitionLine, SalesHeader."No.", Item."No.", LocationBlue2.Code);
        Assert.AreEqual(
          RequisitionLine."Replenishment System"::Transfer, RequisitionLine."Replenishment System",
          StrSubstNo(ValidationError, RequisitionLine.FieldCaption("Replenishment System"),
            RequisitionLine."Replenishment System"::Transfer, RequisitionLine.TableCaption()));
        Assert.AreEqual(
          LocationBlue.Code, RequisitionLine."Supply From",
          StrSubstNo(ValidationError, RequisitionLine.FieldCaption("Supply From"), LocationBlue.Code, RequisitionLine.TableCaption()));

        // Tear Down.
        RestoreSalesReceivableSetup(TempSalesReceivablesSetup);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProdOrderPlanning()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        PlanningForProduction(ProductionOrder.Status::Released);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProdOrderPlanning()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        PlanningForProduction(ProductionOrder.Status::Planned);
    end;

    local procedure PlanningForProduction(Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: Record "Sales Header";
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Released Production Order.
        CreateManufacturingSetup(ParentItem, ChildItem, ChildItem.Reserve::Optional);
        CreateAndRefreshProdOrder(ProductionOrder, Status, ParentItem."No.", '', LibraryRandom.RandDec(10, 2));

        // Exercise : Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify : Verify That Quantity on Requisition Line has same as quantity on Production BOM Component Line.
        VerifyDemandQtyAndLocation(
            ProductionOrder."No.", SalesHeader."Document Type"::Invoice, DemandTypeGlobal::Production, Status.AsInteger());
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlannedProdOrderMakeOrder()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        Initialize();
        PlanningForProdMakeOrderActiveLine(ManufacturingUserTemplate."Create Production Order"::"Firm Planned");
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdOrderMakeOrder()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        Initialize();
        PlanningForProdMakeOrderActiveLine(ManufacturingUserTemplate."Create Production Order"::Planned);
    end;

    local procedure PlanningForProdMakeOrderActiveLine(CreateProductionOrder: Enum "Planning Create Prod. Order")
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Release Production Order
        // and run Order Planning.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, ChildItem.Reserve::Optional);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::Released, ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) + 10);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Exercise : Run Make order Active Line from Order Planning Worksheet.
        MakeSupplyOrdersActiveLine(ProductionOrder."No.", ChildItem."No.", LocationBlue.Code, CreateProductionOrder);

        // Verify : Verify Quantity on Purchase Order and Quantity on Production Order is same as define in Production BOM and child item.
        VerifyPurchaseQtyAgainstProd(ProductionOrder);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure PlannedProdChangeReplenishment()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        PlanningForProdChangeRepl(ProductionOrder.Status::Planned)
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure FirmPlannedChangeReplenishment()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        PlanningForProdChangeRepl(ProductionOrder.Status::"Firm Planned")
    end;

    local procedure PlanningForProdChangeRepl(Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        // Setup : Create Manufacturing Item Setup with child Item without inventory, Create Production Order
        // and run Order Planning and Change Replisment System To Transfer.
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, ChildItem.Reserve::Optional);
        CreateAndRefreshProdOrder(ProductionOrder, Status, ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) + 10);
        UpdateChildItemInventory(ProdOrderComponent, ChildItem."No.", ProductionOrder."No.", LocationBlue2.Code);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        ChangeReplForTrasferOrder(
          RequisitionLine, RequisitionLine."Replenishment System"::Purchase, RequisitionLine."Replenishment System"::Transfer,
          ProductionOrder."No.", LocationBlue2.Code);

        // Exercise : Make Order for changed Replenishment System on Requisition Line.
        MakeSupplyOrdersActiveOrder(ProductionOrder."No.");

        // Verify : Verify That Quantity on Purchase Order and Quantity on Production Order is same as define in Production BOM
        // and child item.
        VerifyTransferLine(ChildItem."No.", ProdOrderComponent."Remaining Quantity");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveProdPlanningAlways()
    var
        ChildItem: Record Item;
    begin
        Initialize();
        ReserveProductionPlanning(ChildItem.Reserve::Never, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReserveProdPlanningNever()
    var
        ChildItem: Record Item;
    begin
        Initialize();
        ReserveProductionPlanning(ChildItem.Reserve::Always, false);
    end;

    local procedure ReserveProductionPlanning(ReserveOnItem: Enum "Reserve Method"; ReserveOnRequistition: Boolean)
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
    begin
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, ReserveOnItem);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) +
          10);

        // Exercise.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify : Check that Reserve is TRUE OR False While we create child item Reserve Always and Never.
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationBlue.Code);
        asserterror RequisitionLine.Validate(Reserve, ReserveOnRequistition);
        if ReserveOnRequistition then
            Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption(Reserve), Format(false))
        else
            Assert.ExpectedTestFieldError(RequisitionLine.FieldCaption(Reserve), Format(true))
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ResvProdPlanAlwaysMakeOrder()
    var
        ChildItem: Record Item;
    begin
        Initialize();
        ReserveProdPlanMakeOrder(ChildItem.Reserve::Always);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure ResvProdPlanNeverMakeOrder()
    var
        ChildItem: Record Item;
    begin
        Initialize();
        ReserveProdPlanMakeOrder(ChildItem.Reserve::Never);
    end;

    local procedure ReserveProdPlanMakeOrder(ReserveOnItem: Enum "Reserve Method")
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        ReservationEntry: Record "Reservation Entry";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        Initialize();
        CreateManufacturingSetup(ParentItem, ChildItem, ReserveOnItem);
        CreateAndRefreshProdOrder(
          ProductionOrder, ProductionOrder.Status::"Firm Planned", ParentItem."No.", LocationBlue.Code, LibraryRandom.RandDec(10, 2) +
          10);
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", LocationBlue.Code);

        // Exercise : Run Make order from Order Planning Worksheet.
        MakeSupplyOrdersActiveLine(
          ProductionOrder."No.", ChildItem."No.", LocationBlue.Code, ManufacturingUserTemplate."Create Production Order"::"Firm Planned");

        // Verify : Check That Reservation Entry Created after Make Supply Order.
        if ReserveOnItem = ChildItem.Reserve::Always then begin
            FindProdOrderComponent(ProdOrderComponent, ProductionOrder."No.", ChildItem."No.");
            ReservationEntry.SetRange("Item No.", ChildItem."No.");
            ReservationEntry.SetRange("Source Type", DATABASE::"Purchase Line");
            ReservationEntry.FindFirst();
            Assert.AreEqual(
              ProdOrderComponent."Remaining Quantity", ReservationEntry.Quantity,
              StrSubstNo(
                ValidationError, ReservationEntry.FieldCaption(Quantity), ProdOrderComponent."Remaining Quantity",
                ReservationEntry.TableCaption()));
        end else begin
            // Verify : Check That Reservation Entry Not Created after Make Supply Order.
            ReservationEntry.SetRange("Item No.", ChildItem."No.");
            asserterror ReservationEntry.FindFirst();
        end;
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PlannedProdDimOnOrderPlanning()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        DimensionOnOrderPlanning(ProductionOrder.Status::Planned);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FirmPlanProdDimOnOrderPlanning()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        DimensionOnOrderPlanning(ProductionOrder.Status::"Firm Planned");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReleasedProdDimOnOrderPlanning()
    var
        ProductionOrder: Record "Production Order";
    begin
        Initialize();
        DimensionOnOrderPlanning(ProductionOrder.Status::Released);
    end;

    local procedure DimensionOnOrderPlanning(Status: Enum "Production Order Status")
    var
        ProductionOrder: Record "Production Order";
        ParentItem: Record Item;
        ChildItem: Record Item;
        RequisitionLine: Record "Requisition Line";
        DefaultDimension: Record "Default Dimension";
        DimensionValue: Record "Dimension Value";
    begin
        // Setup : Create Manufacturing Item Setup with child Item With Dimension, Create Production Order.
        CreateManufacturingSetup(ParentItem, ChildItem, ChildItem.Reserve::Optional);
        CreateDimensionWithValue(DimensionValue);
        LibraryDimension.CreateDefaultDimensionItem(
          DefaultDimension, ChildItem."No.", DimensionValue."Dimension Code", DimensionValue.Code);
        CreateAndRefreshProdOrder(ProductionOrder, Status, ParentItem."No.", '', LibraryRandom.RandDec(10, 2));

        // Exercise : Run Calculate order planning.
        LibraryPlanning.CalculateOrderPlanProduction(RequisitionLine);

        // Verify.
        FindRequisitionLine(RequisitionLine, ProductionOrder."No.", ChildItem."No.", '');
        VerifyDimensionSetEntry(DimensionValue."Dimension Code", DimensionValue.Code, RequisitionLine."Dimension Set ID");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderPlanningForSpecialSalesOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        SalesLine: Record "Sales Line";
        Quantity: Decimal;
    begin
        // Setup: Create Item.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');

        // Create Sales Order and update Purchasing Code Special Order on Sales Line.
        CreateSalesOrder(SalesHeader, Item."No.", '', Quantity, Quantity);
        UpdateSalesLinePurchasingCode(SalesHeader, Item."No.");

        // Exercise: Calculate Order Planning for Sales.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Verify: Verify that no Requisition line is created for Order Planning for Sales of Special Order.
        FindSalesLine(SalesLine, SalesHeader, Item."No.");
        RequisitionLine.SetRange("Purchasing Code", SalesLine."Purchasing Code");
        RequisitionLine.SetRange("Demand Order No.", SalesHeader."No.");
        Assert.IsTrue(RequisitionLine.IsEmpty, StrSubstNo(RequisitionLineMustNotExist, Item."No."));
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPlanningMakeOrderForPurchaseWithVendorHavingCurrency()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        VendorCurrencyCode: Code[10];
        Quantity: Decimal;
    begin
        // Setup: Create Item.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        VendorCurrencyCode := UpdateItemWithVendor(Item);

        // Create Sales Order.
        CreateSalesOrder(SalesHeader, Item."No.", '', Quantity, Quantity);

        // Calculate Order Planning for Sales.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exrecise: Run Make Supply Order for Purchase Order.
        MakeSupplyOrdersActiveOrderForPurchase(SalesHeader."No.");

        // Verify: Verify created Purchase Order is updated with correct Vendor No. and Currency Code.
        VerifyPurchaseVendorAndCurrency(Item, VendorCurrencyCode);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPlanningForRequisitionFromSalesWithMakeOrder()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        Quantity: Decimal;
    begin
        // Setup: Create Item.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');

        // Create Sales Order with Location.
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);

        // Calculate Order Planning for Sales.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // Exercise: Run Make Supply Order for Active Line and Copy to Requisition Worksheet.
        MakeSupplyOrdersActiveLineWithCopyToReq(ManufacturingUserTemplate, Item."No.");

        // Verify: Verify Quantity and Location on Requisition Worksheet.
        VerifyRequisitionLine(ManufacturingUserTemplate."Purchase Req. Wksh. Template", Item."No.", LocationBlue.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure SalesOrderWithDropShipmentNotReservedForReqLineCreatedFromOrderPlanning()
    var
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        Quantity: Decimal;
    begin
        // [FEATURE] [Drop Shipment] [Order Planning] [Reservation]
        // [SCENARIO 231925] Sales order that is set for drop shipment after it is planned by Order Planning functionality, is not reserved from resulting requisition worksheet.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);

        // [GIVEN] Item with Reserve option = "Always".
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        Item.Validate(Reserve, Item.Reserve::Always);
        Item.Modify(true);

        // [GIVEN] Sales Order.
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);

        // [GIVEN] Calculate Order Planning for sales.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [GIVEN] The sales line is set up for Drop Shipment.
        FindSalesLine(SalesLine, SalesHeader, Item."No.");
        SalesLine.Validate("Drop Shipment", true);
        SalesLine.Modify(true);

        // [WHEN] Run "Make Supply Order for Active Line" with "Copy to Requisition Worksheet" action.
        MakeSupplyOrdersActiveLineWithCopyToReq(ManufacturingUserTemplate, Item."No.");

        // [THEN] Requisition line is created.
        FindRequisitionLine(RequisitionLine, '', Item."No.", LocationBlue.Code);

        // [THEN] The sales line is not reserved from requisition line.
        SalesLine.Find();
        SalesLine.CalcFields("Reserved Quantity");
        SalesLine.TestField(Reserve, SalesLine.Reserve::Never);
        SalesLine.TestField("Reserved Quantity", 0);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure RequisitionLineForMultipleSalesMakeOrderTwice()
    var
        Item: Record Item;
        Item2: Record Item;
        SalesHeader: Record "Sales Header";
        RequisitionLine: Record "Requisition Line";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        SalesHeader2: Record "Sales Header";
        Quantity: Decimal;
    begin
        // Setup: Create two Items.
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        CreateItem(Item2, Item."Replenishment System"::Purchase, '', '');

        // Create two Sales Orders for same Location.
        CreateSalesOrder(SalesHeader, Item."No.", LocationBlue.Code, Quantity, Quantity);
        CreateSalesOrder(SalesHeader2, Item2."No.", LocationBlue.Code, Quantity, Quantity);

        // Calculate Order Planning for Sales and Make Order for first item to create Requisition Worksheet line.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
        MakeSupplyOrdersActiveLineWithCopyToReq(ManufacturingUserTemplate, Item."No.");

        // Exercise: Make Order again for second item to create another Requisition Worksheet line.
        MakeSupplyOrdersActiveLineWithCopyToReq(ManufacturingUserTemplate, Item2."No.");

        // Verify: Verify Requisition Worksheet line for first item is still available, and is not overwritten by Make Order for second Item.
        VerifyRequisitionLine(ManufacturingUserTemplate."Purchase Req. Wksh. Template", Item."No.", LocationBlue.Code, Quantity);
        VerifyRequisitionLine(ManufacturingUserTemplate."Purchase Req. Wksh. Template", Item2."No.", LocationBlue.Code, Quantity);
    end;

    [Test]
    [HandlerFunctions('MakeSupplyOrdersPageHandler')]
    [Scope('OnPrem')]
    procedure OrderPlanningReservationServiceOrder()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        ServiceHeader: Record "Service Header";
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        Quantity: Decimal;
    begin
        // [FEATURE] [Reservation] [Requisition Worksheet] [Order Planning] [Service Order]
        // [SCENARIO 134557] Item is reserved in supply Req. Worksheet when "Reserve" = "Always" and Req. Worksheet is created from Order Planning.

        // [GIVEN] Item "I" with "Replenishment System" = "Purchase", "Reserve" = "Always"
        Initialize();
        Quantity := LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        UpdateItem(Item, Item.Reserve::Always);

        // [GIVEN] Create Service Order with "I", Calculate Order Planning.
        CreateServiceOrder(ServiceHeader, Item."No.", Quantity);
        LibraryPlanning.CalculateOrderPlanService(RequisitionLine);

        // [GIVEN] Make supply orders with "Copy to Requisition Worksheet" option.
        MakeSupplyOrdersActiveLineWithCopyToReq(ManufacturingUserTemplate, Item."No.");

        // [THEN] Item is reserved in Requisition Worksheet.
        VerifyServiceReservationEntry(
          ServiceHeader."Document Type", ServiceHeader."No.", Item."No.", -Quantity);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QuantityAvailableWithJobPlanning()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        JobNo: Code[20];
        Quantities: array[2] of Decimal;
    begin
        // Setup : Create Item with inventory on location, Sale order and Calculate Plan.
        Initialize();
        Quantities[1] := 10 * LibraryRandom.RandDec(10, 2);
        Quantities[2] := 10 * LibraryRandom.RandDec(10, 2);
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        JobNo := CreateJobPlanningLines(Item."No.", LocationBlue.Code, Quantities);

        // Exercise : Calculate Order Planning.
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // Verify : Check values of Needed Quantity.
        VerifyNeededQuantities(JobNo, Item."No.", Quantities);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure RequisitionLineDescriptionAfterOrderPlanning()
    var
        Vendor: Record Vendor;
        Item: Record Item;
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        RequisitionLine: Record "Requisition Line";
        ItemTranslationDescription: Text[50];
    begin
        // [FEATURE] [Order Planning] [Item Translation]
        // [SCENARIO 375674] Field "Description" of Requisition Line should be taken from Item Translation during Order Planning
        Initialize();

        // [GIVEN] Vendor "V" with Language Code = "C"
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Language Code", LibraryERM.GetAnyLanguageDifferentFromCurrent());
        Vendor.Modify(true);

        // [GIVEN] Item with "Vendor No." = "V", "Translation Code" = "C", where Description = "D"
        LibraryInventory.CreateItem(Item);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
        ItemTranslationDescription := CreateItemTranslation(Item."No.", Vendor."Language Code");

        // [GIVEN] Sales Order for Item
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, Item."No.", LibraryRandom.RandInt(10));

        // [WHEN] Calculate Plan in Order Planning
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [THEN] Requisition Line is created with Description = "D"
        RequisitionLine.SetRange("No.", Item."No.");
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Description, ItemTranslationDescription);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure JobOrderPlanCalculationWithServiceItem()
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        Item: array[2] of Record Item;
        RequisitionLine: Record "Requisition Line";
        i: Integer;
    begin
        // [FEATURE] [Order Planning] [Job] [Item] [Item Type]
        // [SCENARIO 260178] Service item is not involved in order plan calculation.
        Initialize();

        // [GIVEN] Item "I" and item with type Service "SI"
        LibraryInventory.CreateItem(Item[1]);
        LibraryInventory.CreateServiceTypeItem(Item[2]);

        // [GIVEN] Two "Job Planning Line": first with "I", second with "SI"
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);

        for i := 1 to 2 do
            CreateJobPlanningLine(JobTask, Item[i]."No.", '', WorkDate(), LibraryRandom.RandInt(100));

        // [WHEN] Calculate Order Planning
        LibraryPlanning.CalculateOrderPlanJob(RequisitionLine);

        // [THEN] Item "SI" is not planned
        RequisitionLine.SetRange("No.", Item[1]."No.");
        Assert.RecordIsNotEmpty(RequisitionLine);

        RequisitionLine.SetRange("No.", Item[2]."No.");
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderWithoutPostingWhseShipment()
    var
        ServiceHeader: Record "Service Header";
        ServiceLine: Record "Service Line";
        Location: Record Location;
        Bin: Record Bin;
        WarehouseSetup: Record "Warehouse Setup";
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        UserSetup: Record "User Setup";
    begin
        // [FEATURE] [Service Order] [Warehouse Shipment]
        // [SCENARIO 254701] After unsuccessful attempt of Whse. Shpmt it must be impossible to post a Service Order the shipment was derived from.

        Initialize();

        // [GIVEN] Create Location with a bin
        CreateLocationWithBin(Location, Bin, true, false, false, true, true);

        // [GIVEN] Modify Whse. Setup in order to catch expected errors when posting
        WarehouseSetup.Get();
        WarehouseSetup.Validate(
          "Receipt Posting Policy", WarehouseSetup."Receipt Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Validate(
          "Shipment Posting Policy", WarehouseSetup."Shipment Posting Policy"::"Stop and show the first posting error");
        WarehouseSetup.Modify(true);

        // [GIVEN] Create Service Order with Service Line
        CreateServiceOrderWithServiceLine(ServiceHeader, ServiceLine, LibraryInventory.CreateItemNo(), Location);
        ServiceLine.Validate("Qty. to Ship", ServiceLine.Quantity);
        ServiceLine.Modify(true);

        // [GIVEN] Release Create Whse. Shipment
        ReleaseServiceOrderAndCreateShpmt(WarehouseShipmentHeader, ServiceHeader, Bin);

        // [GIVEN] Create user setup with posting date restrictions in order to cause expected error when the Whse. Shipment is posted
        if UserSetup.Get(UserId) then
            UserSetup.Delete(true);
        UserSetup.Init();
        UserSetup.Validate("User ID", UserId);
        UserSetup.Validate("Allow Posting From", WorkDate() + 1);
        UserSetup.Insert(true);

        // [GIVEN] Try to post Whse. Shipment
        Commit();
        asserterror LibraryWarehouse.PostWhseShipment(WarehouseShipmentHeader, false);

        // [GIVEN] Catch an expected posting date error
        Assert.ExpectedError(PostDateOutOfRangeErr);

        // [GIVEN] Drop posting date restrictions
        UserSetup.Validate("Allow Posting From", WorkDate() - 1);
        UserSetup.Modify(true);

        // [WHEN] Trying to post the Service Order
        asserterror LibraryService.PostServiceOrder(ServiceHeader, true, false, true);

        // [THEN] Catch an error because Whse. Shipment is still not posted
        Assert.ExpectedErrorCannotFind(Database::"Posted Whse. Shipment Header");

        UserSetup.Delete(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PostServiceOrderAsShpmtWhseEntryCreated()
    var
        ServiceHeader: Record "Service Header";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
        ServiceLineSilver: Record "Service Line";
        BlueLocation: Record Location;
        SilverLocation: Record Location;
        BlueBin: Record Bin;
        SilverBin: Record Bin;
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        Item: Record Item;
        WarehouseEntry: Record "Warehouse Entry";
    begin
        // [FEATURE] [Service Order] [Warehouse]
        // [SCENARIO 258679] When posting a service order with 2 lines - one requiring warehouse shipment, the other not - the line without whse. shipment is posted and creates warehouse entry.

        Initialize();

        // [GIVEN] Create Item
        LibraryInventory.CreateItem(Item);

        // [GIVEN] Create SILVER Location
        CreateLocationWithBin(SilverLocation, SilverBin, true, false, false, false, false);

        // [GIVEN] Create random stock for the ItemNo on the SILVER Location
        CreateStockForItem(Item, SilverLocation.Code, SilverBin.Code, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Create BLUE Location with a bin
        CreateLocationWithBin(BlueLocation, BlueBin, true, false, false, true, true);

        // [GIVEN] Create random stock for the ItemNo on the BLUE Location
        CreateStockForItem(Item, BlueLocation.Code, BlueBin.Code, LibraryRandom.RandIntInRange(10, 20));

        // [GIVEN] Create Service Order with Service Line for BLUE Location
        CreateServiceOrderWithServiceLine(ServiceHeader, ServiceLine, Item."No.", BlueLocation);

        // [GIVEN] Create another Service Line with SILVER Location
        ServiceItemLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceItemLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceItemLine.FindFirst();
        CreateServiceLine(
          ServiceLineSilver, ServiceHeader, ServiceItemLine, Item."No.", SilverLocation.Code, LibraryRandom.RandIntInRange(1, 10));

        // [GIVEN] Release Service Order and Create Whse. Shipment
        ReleaseServiceOrderAndCreateShpmt(WarehouseShipmentHeader, ServiceHeader, BlueBin);

        // [GIVEN] Post Service Order as Shipment only
        LibraryService.PostServiceOrder(ServiceHeader, true, false, false);

        // [WHEN] Try to find a Whse. Entry
        WarehouseEntry.SetRange("Source Document", WarehouseEntry."Source Document"::"Serv. Order");
        WarehouseEntry.SetRange("Source No.", ServiceLineSilver."Document No.");
        WarehouseEntry.SetRange("Source Line No.", ServiceLineSilver."Line No.");

        // [THEN] Whse. Line derived from Serevice Line which was shipped from SILVER is there, no errors occur.
        WarehouseEntry.FindFirst();
    end;

    [Test]
    [HandlerFunctions('GetAlternativeSupplyPageHandler')]
    [Scope('OnPrem')]
    procedure QuantityAvailableForTransferWithPreviouslyPlannedTransfer()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: array[2] of Record "Sales Header";
        OrderPlanning: TestPage "Order Planning";
        Qty: Decimal;
    begin
        // [FEATURE] [Order Planning] [Transfer]
        // [SCENARIO 328253] Quantity Available For Transfer on Order Planning page shows quantity can be transferred from another location with previously planned transfers.
        Initialize();
        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Item with 100 pcs stored on location "Blue".
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(2 * Qty, Item."No.", LocationBlue.Code);

        // [GIVEN] Two sales orders "SO1", "SO2" on location "Red", each order for 50 pcs.
        CreateSalesOrder(SalesHeader[1], Item."No.", LocationRed.Code, Qty, Qty);
        CreateSalesOrder(SalesHeader[2], Item."No.", LocationRed.Code, Qty, Qty);

        // [GIVEN] Calculate plan.
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [GIVEN] Open order planning page and place position on order "SO1".
        // [GIVEN] Open "Available for transfer" page and set "SO1" to be fulfilled by a transfer from location "Blue".
        OpenOrderPlanningPage(OrderPlanning, SalesHeader[1]."No.", Item."No.");
        OrderPlanning."Alternative Supply".Invoke();

        // [WHEN] Place position on sales order "SO2".
        OrderPlanning.FILTER.SetFilter("Demand Order No.", SalesHeader[2]."No.");
        OrderPlanning.Expand(true);
        OrderPlanning.FILTER.SetFilter("No.", Item."No.");

        // [THEN] "Available for Transfer" shows 50 available pcs for this order (total of 100 pcs minus 50 pcs for order "SO1").
        OrderPlanning.AvailableForTransfer.AssertEquals(Qty);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure RequisitionLinesAreRemovedOnDeleteAllActionOnOrderPlanning()
    var
        Item: Record Item;
        RequisitionLine: Record "Requisition Line";
        SalesHeader: array[2] of Record "Sales Header";
        OrderPlanning: TestPage "Order Planning";
        Qty: Decimal;
    begin
        // [SCENARIO 542430] Requisition lines are removed when all lines are deleted on Order Planning page 
        Initialize();
        Qty := LibraryRandom.RandIntInRange(50, 100);

        // [GIVEN] Remove all requisition lines
        RequisitionLine.DeleteAll();

        // [GIVEN] Item with 100 pcs stored on location "Blue".
        LibraryInventory.CreateItem(Item);
        UpdateItemInventory(2 * Qty, Item."No.", LocationBlue.Code);

        // [GIVEN] Two sales orders "SO1", "SO2" on location "Red", each order for 50 pcs.
        CreateSalesOrder(SalesHeader[1], Item."No.", LocationRed.Code, Qty, Qty);
        CreateSalesOrder(SalesHeader[2], Item."No.", LocationRed.Code, Qty, Qty);

        // [WHEN] Calculate plan
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);

        // [THEN] Verify Requisition lines are created
        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Worksheet Template Name", '');
        Assert.RecordIsNotEmpty(RequisitionLine);

        // [WHEN] Open order planning page and call Delete All action
        OrderPlanning.OpenEdit();
        OrderPlanning."Delete All".Invoke();

        // [THEN] Verify Requisition lines are removed
        RequisitionLine.SetRange("User ID", UserId);
        RequisitionLine.SetRange("Worksheet Template Name", '');
        Assert.RecordIsEmpty(RequisitionLine);
    end;

    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Order Planning - II");
        ClearGlobals();

        LibraryApplicationArea.EnableEssentialSetup();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Order Planning - II");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        CreateLocationSetup();
        NoSeriesSetup();
        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Order Planning - II");
    end;

    local procedure ClearGlobals()
    var
        RequisitionLine: Record "Requisition Line";
    begin
        Clear(DemandTypeGlobal);
        Clear(ExpectedQuantity);
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

    local procedure ChangeReplForTrasferOrder(var RequisitionLine: Record "Requisition Line"; OldReplenishmentSystem: Enum "Replenishment System"; NewReplenishmentSystem: Enum "Replenishment System"; DemandOrderNo: Code[20]; SupplyFrom: Code[20])
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.SetRange(Type, RequisitionLine.Type::Item);
        RequisitionLine.SetRange("Replenishment System", OldReplenishmentSystem);
        RequisitionLine.FindFirst();
        RequisitionLine.Validate("Replenishment System", NewReplenishmentSystem);
        RequisitionLine.Validate("Supply From", SupplyFrom);
        RequisitionLine.Validate("Transfer Shipment Date", RequisitionLine."Order Date");
        RequisitionLine.Modify(true);
    end;

    local procedure CreateManufacturingSetup(var Item: Record Item; var ChildItem: Record Item; Reserve: Enum "Reserve Method")
    begin
        CreateItem(ChildItem, ChildItem."Replenishment System"::Purchase, '', '');
        UpdateItem(ChildItem, Reserve);
        CreateItemWithProductionBOM(Item, ChildItem);
    end;

    local procedure CreateItemWithProductionBOM(var Item: Record Item; ChildItem: Record Item)
    var
        RoutingHeader: Record "Routing Header";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create Production BOM and Routing.
        CreateAndCertifyProductionBOM(ProductionBOMHeader, ChildItem, '', LibraryRandom.RandDec(5, 2));
        CreateRoutingSetup(RoutingHeader);

        // Create Parent Item.
        CreateItem(Item, Item."Replenishment System"::"Prod. Order", RoutingHeader."No.", ProductionBOMHeader."No.");
    end;

    local procedure CreateItem(var Item: Record Item; ReplenishmentSystem: Enum "Replenishment System"; RoutingHeaderNo: Code[20]; ProductionBOMNo: Code[20])
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

    local procedure CreateStockForItem(var Item: Record Item; LocationCode: Code[10]; BinCode: Code[20]; Quantity: Decimal)
    var
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, Item."No.", LocationCode, BinCode, Quantity);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");
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

    local procedure CreateServiceLine(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header"; ServiceItemLine: Record "Service Item Line"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate("Location Code", LocationCode);
        ServiceLine.Validate(Quantity, Quantity);
        ServiceLine.Modify(true);
    end;

    local procedure ClearManufacturingUserTemplate()
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
    begin
        ManufacturingUserTemplate.SetRange("User ID", UserId);
        if ManufacturingUserTemplate.FindFirst() then
            ManufacturingUserTemplate.Delete(true);
    end;

    local procedure CreateAndRefreshProdOrder(var ProductionOrder: Record "Production Order"; Status: Enum "Production Order Status"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibraryManufacturing.CreateProductionOrder(ProductionOrder, Status, ProductionOrder."Source Type"::Item, ItemNo, Quantity);
        ProductionOrder.Validate("Location Code", LocationCode);
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);
    end;

    local procedure CreateLocationSetup()
    begin
        CreateLocation(LocationRed, false);
        CreateLocation(LocationBlue, false);
        CreateLocation(LocationBlue2, false);
        CreateLocation(LocationIntransit, true);
        CreateTransferRoutesSetup(LocationRed, LocationBlue, LocationBlue2, LocationIntransit);
    end;

    local procedure CreateLocationWithBin(var Location: Record Location; var Bin: Record Bin; BinMandatory: Boolean; RequirePutAway: Boolean; RequirePick: Boolean; RequireReceive: Boolean; RequireShipment: Boolean)
    begin
        LibraryWarehouse.CreateLocationWMS(Location, BinMandatory, RequirePutAway, RequirePick, RequireReceive, RequireShipment);
        LibraryWarehouse.CreateBin(
          Bin, Location.Code, LibraryUtility.GenerateRandomCode(Bin.FieldNo(Code), DATABASE::Bin), '', '');
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
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, Quantity, QuantityToShip);
        CreateSalesLine(SalesHeader, ItemNo2, LocationCode, Quantity, QuantityToShip);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode2, Quantity, QuantityToShip);

        LibrarySales.CreateSalesHeader(SalesHeader2, SalesHeader2."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesHeader2, ItemNo, LocationCode, Quantity, QuantityToShip);

        LibrarySales.CreateSalesHeader(SalesHeader3, SalesHeader3."Document Type"::Order, SalesHeader."Sell-to Customer No.");
        CreateSalesLine(SalesHeader3, ItemNo2, LocationCode2, Quantity, QuantityToShip);
    end;

    local procedure CreateSalesLine(SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; QuantityToShip: Decimal)
    var
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Quantity);
        SalesLine.Validate("Qty. to Ship", QuantityToShip);
        SalesLine.Validate("Unit Price", LibraryRandom.RandDec(100, 2));
        SalesLine.Validate("Location Code", LocationCode);
        SalesLine.Modify(true);
    end;

    local procedure CreateSalesOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; LocationCode: Code[10]; Quantity: Decimal; QtyToShip: Decimal)
    begin
        // Random values used are not important for test.
        Clear(SalesHeader);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        SalesHeader.Validate("Location Code", LocationCode);
        SalesHeader.Modify(true);
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, Quantity, QtyToShip);
    end;

    local procedure CreateServiceOrder(var ServiceHeader: Record "Service Header"; ItemNo: Code[20]; Qty: Decimal)
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        ServiceLine: Record "Service Line";
    begin
        Clear(ServiceHeader);
        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, LibrarySales.CreateCustomerNo());
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        LibraryService.CreateServiceLine(ServiceLine, ServiceHeader, ServiceLine.Type::Item, ItemNo);
        ServiceLine.Validate("Service Item Line No.", ServiceItemLine."Line No.");
        ServiceLine.Validate(Quantity, Qty);
        ServiceLine.Modify(true);
    end;

    local procedure CreateServiceOrderWithServiceLine(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; ItemNo: Code[20]; Location: Record Location)
    var
        ServiceItem: Record "Service Item";
        ServiceItemLine: Record "Service Item Line";
        Customer: Record Customer;
        Item: Record Item;
        CompItem: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        CompItem.Get(ItemNo);
        LibrarySales.CreateCustomer(Customer);

        LibraryService.CreateServiceHeader(ServiceHeader, ServiceHeader."Document Type"::Order, Customer."No.");
        ServiceHeader.Validate("Location Code", Location.Code);
        ServiceHeader.Modify(true);
        LibraryService.CreateServiceItem(ServiceItem, ServiceHeader."Customer No.");
        ServiceItem.Validate("Item No.", Item."No.");
        ServiceItem.Modify(true);
        LibraryService.CreateServiceItemLine(ServiceItemLine, ServiceHeader, ServiceItem."No.");

        CreateServiceLine(ServiceLine, ServiceHeader, ServiceItemLine, CompItem."No.", Location.Code, LibraryRandom.RandIntInRange(1, 10));
    end;

    local procedure CreateJobPlanningLines(ItemNo: Code[20]; LocationCode: Code[10]; Quantities: array[2] of Decimal): Code[20]
    var
        Job: Record Job;
        JobTask: Record "Job Task";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(
          JobTask, ItemNo, LocationCode,
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(1, 10)) + 'D>', WorkDate()), Quantities[1]);
        LibraryJob.CreateJob(Job);
        LibraryJob.CreateJobTask(Job, JobTask);
        CreateJobPlanningLine(JobTask, ItemNo, LocationCode, WorkDate(), Quantities[1]);
        CreateJobPlanningLine(
          JobTask, ItemNo, LocationCode,
          CalcDate('<-' + Format(LibraryRandom.RandIntInRange(11, 20)) + 'D>', WorkDate()), Quantities[2]);
        exit(Job."No.");
    end;

    local procedure CreateJobPlanningLine(JobTask: Record "Job Task"; ItemNo: Code[20]; LocationCode: Code[10]; PlanningDate: Date; PlanningQuantity: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        LibraryJob: Codeunit "Library - Job";
    begin
        LibraryJob.CreateJobPlanningLine(JobPlanningLine."Line Type"::Budget, JobPlanningLine.Type::Item, JobTask, JobPlanningLine);
        JobPlanningLine.InitJobPlanningLine();
        JobPlanningLine.Validate("Location Code", LocationCode);
        JobPlanningLine.Validate("Planning Date", PlanningDate);
        JobPlanningLine.Validate("No.", ItemNo);
        JobPlanningLine.Validate("Usage Link", true);
        JobPlanningLine.Validate(Quantity, PlanningQuantity);
        JobPlanningLine.Modify(true);
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

    local procedure CreateDimensionWithValue(var DimensionValue: Record "Dimension Value")
    var
        Dimension: Record Dimension;
    begin
        LibraryDimension.CreateDimension(Dimension);
        LibraryDimension.CreateDimensionValue(DimensionValue, Dimension.Code);
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

    local procedure CreateSalesOrderPlanningSetup(var SalesHeader: Record "Sales Header"; var Item: Record Item; LocationCode: Code[10]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        ClearManufacturingUserTemplate();
        CreateItem(Item, Item."Replenishment System"::Purchase, '', '');
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        CreateSalesLine(SalesHeader, Item."No.", LocationCode, Quantity, Quantity);
        LibrarySales.ReleaseSalesDocument(SalesHeader);
        LibraryPlanning.CalculateOrderPlanSales(RequisitionLine);
    end;

    local procedure CreateSalesReturnOrder(var SalesHeader: Record "Sales Header"; ItemNo: Code[20]; ItemNo2: Code[20]; LocationCode: Code[10]; Quantity: Decimal)
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::"Return Order", '');
        CreateSalesLine(SalesHeader, ItemNo, LocationCode, Quantity, Quantity);
        CreateSalesLine(SalesHeader, ItemNo2, LocationCode, Quantity, Quantity);
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

    local procedure CalculateExpectedQuantity(DocumentType: Enum "Sales Document Type"; OutStandingQuantity: Decimal): Decimal
    var
        SalesHeader: Record "Sales Header";
    begin
        if DocumentType = SalesHeader."Document Type"::"Return Order" then
            OutStandingQuantity := -OutStandingQuantity;

        exit(OutStandingQuantity);
    end;

    local procedure CreateItemTranslation(ItemNo: Code[20]; LanguageCode: Code[10]): Text[50]
    var
        ItemTranslation: Record "Item Translation";
    begin
        ItemTranslation.Init();
        ItemTranslation.Validate("Item No.", ItemNo);
        ItemTranslation.Validate("Language Code", LanguageCode);
        ItemTranslation.Validate(Description, ItemNo + LanguageCode);
        ItemTranslation.Insert(true);
        exit(ItemTranslation.Description);
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

    local procedure FindProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; ProdOrderNo: Code[20]; ItemNo: Code[20])
    begin
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent.SetRange("Item No.", ItemNo);
        ProdOrderComponent.FindFirst();
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

    local procedure OpenOrderPlanningPage(var OrderPlanning: TestPage "Order Planning"; DemandOrderNo: Code[20]; No: Code[20])
    begin
        OrderPlanning.OpenEdit();
        OrderPlanning.FILTER.SetFilter("Demand Order No.", DemandOrderNo);
        OrderPlanning.Expand(true);
        OrderPlanning.FILTER.SetFilter("No.", No);
    end;

    local procedure ReleaseServiceOrderAndCreateShpmt(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var ServiceHeader: Record "Service Header"; Bin: Record Bin)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
    begin
        LibraryService.ReleaseServiceDocument(ServiceHeader);
        LibraryWarehouse.CreateWhseShipmentFromServiceOrder(ServiceHeader);

        WarehouseShipmentLine.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseShipmentLine.SetRange("Source Subtype", 1); // 1 - ServiceLine."Document Type"::Order (option #1)
        WarehouseShipmentLine.SetRange("Source No.", ServiceHeader."No.");
        WarehouseShipmentLine.FindFirst();
        WarehouseShipmentLine.Validate("Bin Code", Bin.Code);
        WarehouseShipmentLine.Modify(true);

        WarehouseShipmentHeader.Get(WarehouseShipmentLine."No.");
    end;

    local procedure UpdateChildItemInventory(var ProdOrderComponent: Record "Prod. Order Component"; ItemNo: Code[20]; ProductionOrderNo: Code[20]; LocationCode: Code[10])
    begin
        FindProdOrderComponent(ProdOrderComponent, ProductionOrderNo, ItemNo);
        UpdateItemInventory(ProdOrderComponent."Remaining Quantity", ItemNo, LocationCode);
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

    local procedure UpdateItemInventory(Quantity: Decimal; ItemNo: Code[20]; LocationCode: Code[10])
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
        ItemJournalLine.Validate("Location Code", LocationCode);
        ItemJournalLine.Modify(true);

        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);
    end;

    local procedure CreatePurchasingCodeWithSpecialOrder(var Purchasing: Record Purchasing)
    begin
        LibraryPurchase.CreatePurchasingCode(Purchasing);
        Purchasing.Validate("Special Order", true);
        Purchasing.Modify(true);
    end;

    local procedure UpdateSalesLinePurchasingCode(SalesHeader: Record "Sales Header"; ItemNo: Code[20])
    var
        Purchasing: Record Purchasing;
        SalesLine: Record "Sales Line";
    begin
        CreatePurchasingCodeWithSpecialOrder(Purchasing);
        FindSalesLine(SalesLine, SalesHeader, ItemNo);
        SalesLine.Validate("Purchasing Code", Purchasing.Code);
        SalesLine.Modify(true);
    end;

    local procedure SelectPurchaseOrderLine(var PurchaseLine: Record "Purchase Line"; No: Code[20])
    begin
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("No.", No);
        PurchaseLine.FindFirst();
    end;

    local procedure UpdateItemWithVendor(var Item: Record Item): Code[10]
    var
        Vendor: Record Vendor;
    begin
        CreateVendorFCY(Vendor);
        Item.Validate("Vendor No.", Vendor."No.");
        Item.Modify(true);
        exit(Vendor."Currency Code");
    end;

    local procedure SelectRequisitionTemplate(var ReqWkshTemplate: Record "Req. Wksh. Template"; Type: Enum "Req. Worksheet Template Type")
    begin
        ReqWkshTemplate.SetRange(Type, Type);
        ReqWkshTemplate.SetRange(Recurring, false);
        ReqWkshTemplate.FindFirst();
    end;

    local procedure SelectManufacturingUserTemplateForRequisition(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option)
    var
        ReqWkshTemplate: Record "Req. Wksh. Template";
        RequisitionWkshName: Record "Requisition Wksh. Name";
    begin
        SelectRequisitionTemplate(ReqWkshTemplate, ReqWkshTemplate.Type::"Req.");
        LibraryPlanning.CreateRequisitionWkshName(RequisitionWkshName, ReqWkshTemplate.Name);
        GetManufacturingUserTemplateForRequisition(
          ManufacturingUserTemplate, MakeOrder, ManufacturingUserTemplate."Create Purchase Order"::"Copy to Req. Wksh");
        ManufacturingUserTemplate.Validate("Purchase Req. Wksh. Template", ReqWkshTemplate.Name);
        ManufacturingUserTemplate.Validate("Purchase Wksh. Name", RequisitionWkshName.Name);
        ManufacturingUserTemplate.Modify(true);
    end;

    local procedure MakeSupplyOrdersActiveOrderForPurchase(DemandOrderNo: Code[20])
    var
        ManufacturingUserTemplate: Record "Manufacturing User Template";
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Demand Order No.", DemandOrderNo);
        RequisitionLine.FindFirst();
        MakeSupplyOrders(
          RequisitionLine, ManufacturingUserTemplate."Make Orders"::"The Active Order",
          ManufacturingUserTemplate."Create Purchase Order"::"Make Purch. Orders");
    end;

    local procedure MakeSupplyOrdersActiveLineWithCopyToReq(var ManufacturingUserTemplate: Record "Manufacturing User Template"; No: Code[20])
    var
        RequisitionLine: Record "Requisition Line";
    begin
        SelectManufacturingUserTemplateForRequisition(
          ManufacturingUserTemplate, ManufacturingUserTemplate."Make Orders"::"The Active Line");
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        LibraryPlanning.MakeSupplyOrders(ManufacturingUserTemplate, RequisitionLine);
    end;

    local procedure CreateVendorFCY(var Vendor: Record Vendor)
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("Currency Code", LibraryERM.CreateCurrencyWithRandomExchRates());
        Vendor.Modify(true);
    end;

    local procedure GetManufacturingUserTemplateForRequisition(var ManufacturingUserTemplate: Record "Manufacturing User Template"; MakeOrder: Option; CreatePurchaseOrder: Enum "Planning Create Purchase Order")
    begin
        if not ManufacturingUserTemplate.Get(UserId) then
            LibraryPlanning.CreateManufUserTemplate(
              ManufacturingUserTemplate, UserId, MakeOrder, CreatePurchaseOrder,
              ManufacturingUserTemplate."Create Production Order"::"Firm Planned",
              ManufacturingUserTemplate."Create Transfer Order"::"Make Trans. Orders");
    end;

    local procedure VerifyDemandQtyAndLocation(DemandOrderNo: Code[20]; SalesDocType: Enum "Sales Document Type"; DemandType: Option; Status: Option)
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
                    SalesLine.SetRange("Document Type", SalesDocType);
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

    local procedure VerifyReturnQtyWithPurchQty(SalesOrderNo: Code[20]; ItemNo: Code[20])
    var
        SalesLine: Record "Sales Line";
        PurchaseLine: Record "Purchase Line";
    begin
        SalesLine.SetRange("Document No.", SalesOrderNo);
        SalesLine.SetRange("No.", ItemNo);
        SalesLine.FindFirst();
        PurchaseLine.SetRange("No.", SalesLine."No.");
        PurchaseLine.FindFirst();
        PurchaseLine.TestField(Quantity, -SalesLine."Outstanding Quantity");
    end;

    local procedure VerifyQtyWithProdOrder(ItemNo: Code[20]; Quantity: Decimal; LocationCode: Code[10])
    var
        ProductionOrder: Record "Production Order";
    begin
        ProductionOrder.SetRange("Source Type", ProductionOrder."Source Type"::Item);
        ProductionOrder.SetRange("Source No.", ItemNo);
        ProductionOrder.FindFirst();
        ProductionOrder.TestField(Quantity, Quantity);
        ProductionOrder.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyGetAlternativeSupplyPage(GetAlternativeSupply: TestPage "Get Alternative Supply")
    begin
        Assert.AreEqual(
          LocationBlue.Code, GetAlternativeSupply."Transfer-from Code".Value, StrSubstNo(LocationErrorText, LocationBlue.Code));
        Assert.AreEqual(ExpectedQuantity, GetAlternativeSupply."Demand Qty. Available".AsDecimal(), QuantityError);
    end;

    local procedure VerifyTransferLine(ItemNo: Code[20]; ExpectedQuantity: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.FindFirst();
        TransferLine.TestField(Quantity, ExpectedQuantity);
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

    local procedure VerifyRequisitionLine(WorksheetTemplateName: Code[20]; No: Code[20]; LocationCode: Code[20]; Quantity: Decimal)
    var
        RequisitionLine: Record "Requisition Line";
    begin
        RequisitionLine.SetRange("Worksheet Template Name", WorksheetTemplateName);
        RequisitionLine.SetRange("No.", No);
        RequisitionLine.FindFirst();
        RequisitionLine.TestField(Quantity, Quantity);
        RequisitionLine.TestField("Location Code", LocationCode);
    end;

    local procedure VerifyPurchaseVendorAndCurrency(Item: Record Item; CurrencyCode: Code[10])
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
    begin
        SelectPurchaseOrderLine(PurchaseLine, Item."No.");
        PurchaseHeader.Get(PurchaseLine."Document Type"::Order, PurchaseLine."Document No.");
        PurchaseHeader.TestField("Buy-from Vendor No.", Item."Vendor No.");
        PurchaseLine.TestField("Currency Code", CurrencyCode);
    end;

    local procedure VerifyServiceReservationEntry(ServiceHeaderType: Enum "Service Document Type"; ServiceHeaderNo: Code[20]; ItemNo: Code[20]; Qty: Decimal)
    var
        ReservationEntry: Record "Reservation Entry";
    begin
        ReservationEntry.SetRange("Item No.", ItemNo);
        ReservationEntry.SetRange("Source Type", DATABASE::"Service Line");
        ReservationEntry.SetRange("Source Subtype", ServiceHeaderType);
        ReservationEntry.SetRange("Source ID", ServiceHeaderNo);
        ReservationEntry.FindFirst();
        ReservationEntry.TestField(Quantity, Qty);
    end;

    local procedure VerifyNeededQuantities(JobNo: Code[20]; ItemNo: Code[20]; Quantities: array[2] of Decimal)
    var
        OrderPlanning: TestPage "Order Planning";
    begin
        OpenOrderPlanningPage(OrderPlanning, JobNo, ItemNo);
        OrderPlanning."Needed Quantity".AssertEquals(Quantities[1]);
        OrderPlanning.Next();
        OrderPlanning."Needed Quantity".AssertEquals(Quantities[2]);
    end;

    local procedure RestoreSalesReceivableSetup(TempSalesReceivablesSetup: Record "Sales & Receivables Setup" temporary)
    begin
        SalesReceivablesSetup.Get();
        SalesReceivablesSetup.Validate("Credit Warnings", TempSalesReceivablesSetup."Credit Warnings");
        SalesReceivablesSetup.Validate("Stockout Warning", TempSalesReceivablesSetup."Stockout Warning");
        SalesReceivablesSetup.Modify(true);
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure MakeSupplyOrdersPageHandler(var MakeSupplyOrders: Page "Make Supply Orders"; var Response: Action)
    begin
        Response := ACTION::LookupOK;
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure AlternativeSupplyPageHandler(var GetAlternativeSupply: TestPage "Get Alternative Supply")
    begin
        GetAlternativeSupply.First();
        VerifyGetAlternativeSupplyPage(GetAlternativeSupply);  // Check the value on Get alternative supply page.
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure GetAlternativeSupplyPageHandler(var GetAlternativeSupply: TestPage "Get Alternative Supply")
    begin
        GetAlternativeSupply.First();
        GetAlternativeSupply.OK().Invoke();  // Click Ok after selecting first record.
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

