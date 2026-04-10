codeunit 137211 "SCM Update Unit Cost"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Manufacturing] [Update Unit Cost] [SCM]
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryERM: Codeunit "Library - ERM";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryInventory: Codeunit "Library - Inventory";
        LibrarySales: Codeunit "Library - Sales";
        LibraryRandom: Codeunit "Library - Random";
        IsInitialized: Boolean;

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Update Unit Cost");
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Update Unit Cost");

        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.CreateVATData();

        IsInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Update Unit Cost");
    end;

    [Normal]
    local procedure TestUpdateUnitCost(ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method"; UpdateReservations: Boolean)
    var
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderLine1: Record "Prod. Order Line";
        CalcMethod: Option "One Level","All Levels";
        ExpectedUnitCost: Decimal;
        ExpectedCostAmount: Decimal;
    begin
        // Setup. Create Production BOM Structure.
        Initialize();
        SetupProdItem(Item, ParentCostingMethod, CompCostingMethod);

        // Create and Refresh Released Production Order.
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, Item."No.",
          LibraryRandom.RandInt(10));
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, true, true, true, true, true);

        // Reserve document line against Prod. Order.
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        ReserveDocument(ProdOrderLine);
        ExpectedCostAmount := CalcExpectedOrderCost(ProductionOrder);
        ExpectedUnitCost := ExpectedCostAmount / ProdOrderLine."Quantity (Base)";
        // Exercise: Calculate Prod. Order Cost.
        UpdateOrderCost(ProductionOrder, CalcMethod::"All Levels", UpdateReservations);

        // Verify: Unit Cost on Prod. Order Line and related reserved document line.
        FindProdOrderLine(ProdOrderLine1, ProductionOrder);
        Assert.AreNearlyEqual(ExpectedUnitCost, ProdOrderLine1."Unit Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong prod. order line unit cost.');
        Assert.AreNearlyEqual(ExpectedCostAmount, ProdOrderLine1."Cost Amount", LibraryERM.GetAmountRoundingPrecision(),
          'Wrong prod. order line cost amount.');

        // Reserved line unit cost should not be updated if UpdateReservations is false.
        if not UpdateReservations then
            ExpectedUnitCost := ProdOrderLine."Unit Cost";
        VerifyReservedLineUnitCost(ProductionOrder, ExpectedUnitCost);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgParentStdCompNoUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Average, Enum::"Costing Method"::Standard, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgParentStdCompUpdRes()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Average, Enum::"Costing Method"::Standard, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgParentAvgCompNoUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Average, Enum::"Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgParentAvgCompUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Average, Enum::"Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdParentAvgCompUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Standard, Enum::"Costing Method"::Average, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdParentAvgCompNoUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Standard, Enum::"Costing Method"::Average, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdParentStdCompUpdRes()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Standard, Enum::"Costing Method"::Standard, true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdParentStdCompNoUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Standard, Enum::"Costing Method"::Standard, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgParentFIFOCompNoUpd()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::Average, Enum::"Costing Method"::FIFO, false);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOParentAvgCompUpdRes()
    begin
        TestUpdateUnitCost(Enum::"Costing Method"::FIFO, Enum::"Costing Method"::Average, true);
    end;

    [Test]
    procedure UpdateUnitCostOfReservedProdOrderComponent()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        CalcMethod: Option "One Level","All Levels";
        QtyPerBaseUOM: Decimal;
    begin
        // [FEATURE] [Reservation] [Item Unit of Measure] [Make-to-Order]
        // [SCENARIO 432749] Update unit cost of reserved prod. order component in an alternate unit of measure.
        Initialize();
        QtyPerBaseUOM := 0.25;

        // [GIVEN] Component item "C" with base unit of measure "BOX" and alternate unit of measure "PCS" (1 "PCS" = 0.25 "BOX").
        // [GIVEN] "C"."Unit Cost" = 10.0 LCY.
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItemUnitOfMeasureCode(ItemUnitOfMeasure, CompItem."No.", QtyPerBaseUOM);
        CompItem.Validate("Costing Method", CompItem."Costing Method"::FIFO);
        CompItem.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Manufacturing Policy", CompItem."Manufacturing Policy"::"Make-to-Order");
        CompItem.Modify(true);

        // [GIVEN] Finished item "P", create and certify production BOM: 1 pcs of "P" consists of 1 "PCS" of component "C".
        // [GIVEN] Note that we're using non-base unit of measure for the BOM component.
        LibraryInventory.CreateItem(ProdItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", 1);
        ProductionBOMLine.Validate("Unit of Measure Code", ItemUnitOfMeasure.Code);
        ProductionBOMLine.Modify(true);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Set up both "C" and "P" for "Make-to-Order" manufacturing policy.
        ProdItem.Validate("Costing Method", ProdItem."Costing Method"::FIFO);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Manufacturing Policy", ProdItem."Manufacturing Policy"::"Make-to-Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] Create and refresh make-to-order production order for 1 pcs of "C" and "P".
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, ProdItem."No.", 1);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, true, true, false);

        // [WHEN] Run "Update Unit Cost" report for the production order.
        ProductionOrder.SetRecFilter();
        UpdateOrderCost(ProductionOrder, CalcMethod::"All Levels", false);

        // [THEN] Unit Cost on the prod. order line for "P" = 2.5 LCY (1 "BOX" costs 10.0 LCY, 1 "PCS" therefore costs 2.5 LCY).
        ProdOrderLine.SetRange("Item No.", ProdItem."No.");
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        ProdOrderLine.TestField("Unit Cost", Round(CompItem."Unit Cost" * QtyPerBaseUOM));
    end;

    [Normal]
    local procedure SetupProdItem(var Item: Record Item; ParentCostingMethod: Enum "Costing Method"; CompCostingMethod: Enum "Costing Method")
    var
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Create source Production BOM.
        CreateProductionBOM(ProductionBOMHeader, CompCostingMethod);

        // Create and setup the production item card.
        LibraryInventory.CreateItem(Item);
        if Item."Base Unit of Measure" <> ProductionBOMHeader."Unit of Measure Code" then
            LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", ProductionBOMHeader."Unit of Measure Code", 1);
        Item.Validate("Costing Method", ParentCostingMethod);
        Item.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", ProductionBOMHeader."No.");
        Item.Modify(true);
    end;

    [Normal]
    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; CostingMethod: Enum "Costing Method")
    var
        ProductionBOMLine: Record "Production BOM Line";
        UnitOfMeasure: Record "Unit of Measure";
        Item: Record Item;
        Counter: Integer;
    begin
        // Create Production BOM Header.
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, UnitOfMeasure.Code);

        // Add 2 BOM component lines.
        for Counter := 1 to 2 do begin
            LibraryInventory.CreateItem(Item);
            Item.Validate("Costing Method", CostingMethod);
            Item.Validate("Unit Cost", LibraryRandom.RandDec(10, 2));
            Item.Modify(true);
            LibraryManufacturing.CreateProductionBOMLine(ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item."No.",
              LibraryRandom.RandInt(10));
        end;

        // Certify the BOM.
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
    end;

    [Normal]
    local procedure ReserveDocument(ProdOrderLine: Record "Prod. Order Line")
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
    begin
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, '');
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ProdOrderLine."Item No.", ProdOrderLine.Quantity);
        LibrarySales.AutoReserveSalesLine(SalesLine);
    end;

    [Normal]
    local procedure UpdateOrderCost(var ProductionOrder: Record "Production Order"; CalcMethod: Option; UpdateReservations: Boolean)
    var
        UpdateUnitCost: Report "Update Unit Cost";
    begin
        UpdateUnitCost.InitializeRequest(CalcMethod, UpdateReservations);
        UpdateUnitCost.SetTableView(ProductionOrder);
        UpdateUnitCost.UseRequestPage(false);
        UpdateUnitCost.RunModal();
    end;

    [Normal]
    local procedure CalcExpectedOrderCost(ProductionOrder: Record "Production Order"): Decimal
    var
        ProdOrderComponent: Record "Prod. Order Component";
        Item: Record Item;
        ProdOrderCost: Decimal;
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderCost := 0;

        // Add actual component cost.
        if ProdOrderComponent.FindSet() then
            repeat
                Item.Get(ProdOrderComponent."Item No.");
                ProdOrderCost += Item."Unit Cost" * ProdOrderComponent."Expected Qty. (Base)";
            until ProdOrderComponent.Next() = 0;

        Item.Get(ProductionOrder."Source No.");
        if Item."Costing Method" = Item."Costing Method"::Standard then
            exit(ProductionOrder."Cost Amount");
        exit(ProdOrderCost);
    end;

    [Normal]
    local procedure VerifyReservedLineUnitCost(ProductionOrder: Record "Production Order"; ExpectedUnitCost: Decimal)
    var
        SalesLine: Record "Sales Line";
        ReservationEntry: Record "Reservation Entry";
    begin
        // Find matching reservation entry for Production Order.
        ReservationEntry.SetRange("Source Type", 5406);
        ReservationEntry.SetRange("Source ID", ProductionOrder."No.");
        ReservationEntry.SetRange("Item No.", ProductionOrder."Source No.");
        ReservationEntry.FindFirst();

        // Find Sales side reservation entry.
        ReservationEntry.Get(ReservationEntry."Entry No.", false);

        // Find Sales Line based on reservation info.
        SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
        SalesLine.SetRange("Document No.", ReservationEntry."Source ID");
        SalesLine.FindFirst();

        Assert.AreNearlyEqual(ExpectedUnitCost, SalesLine."Unit Cost (LCY)", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong unit cost in reserved sales line.');
    end;

    [Normal]
    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;
}

