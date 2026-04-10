codeunit 137392 "SCM - Able To Make Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Able to Make] [SCM]
        isInitialized := false;
    end;

    var
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryTrees: Codeunit "Library - Trees";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        FilterType: Option "None",Location,Variant,"Header Location","Header Variant","Component Location","Component Variant";
        SupplyType: Option Inventory,Purchase,"Prod. Order";
        GLBDateInterval: Option Day,Week,Month,Quarter,Year;

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - Able To Make Report");
        // Initialize setup.
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM - Able To Make Report");

        // Setup Demonstration data.
        isInitialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryPlanning.SetDefaultSafetyLeadTime('1D');
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM - Able To Make Report");
    end;

    [Normal]
    local procedure SetupAbleToMake(var BOMBuffer: Record "BOM Buffer"; TestLocation: Boolean; SourceType: Option; BottleneckFactor: Decimal; ShowTotalAvailability: Boolean; DueDateDelay: Text; ChildLeaves: Integer; Depth: Integer; DirectAvailFactor: Decimal; DateInterval: Option)
    var
        ItemVariant: Record "Item Variant";
        Location: Record Location;
        Item: Record Item;
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        GenProdPostingGroup: Code[20];
        InventoryPostingGroup: Code[20];
        AbleToMake: Decimal;
        DueDateDelayDateFormula: DateFormula;
    begin
        // Setup.
        Initialize();
        AbleToMake := LibraryRandom.RandIntInRange(10, 25);

        LibraryAssembly.SetupPostingToGL(GenProdPostingGroup, InventoryPostingGroup, InventoryPostingGroup, '');
        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryAssembly.CreateItem(
          Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, GenProdPostingGroup, InventoryPostingGroup);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryTrees.CreateMixedTree(Item, Item."Replenishment System"::Assembly, Item."Costing Method"::Standard, Depth, ChildLeaves, 2);
        LibraryTrees.CreateNodeSupply(Item."No.", Location.Code, WorkDate(), SourceType, AbleToMake, BottleneckFactor, DirectAvailFactor);

        Item.SetRange("No.", Item."No.");
        Evaluate(DueDateDelayDateFormula, DueDateDelay);
        Item.SetRange("Date Filter", 0D, CalcDate(DueDateDelayDateFormula, WorkDate()));

        if TestLocation then
            LibraryWarehouse.CreateLocation(Location);
        Item.SetRange("Location Filter", Location.Code);
        Item.SetRange("Variant Filter", ItemVariant.Code);

        if TestLocation or (DueDateDelay <> '<0D>') then
            AbleToMake := 0;

        // Exercise: Run Able To Make - Timeline.
        CalculateBOMTree.SetShowTotalAvailability(ShowTotalAvailability);
        CalculateBOMTree.GenerateTreeForManyItems(Item, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: The Able To Make - Timeline report.
        VerifyAbleToMakeReport(BOMBuffer, CalcDate(DueDateDelayDateFormula, WorkDate()), DateInterval, Location.Code, '', '');
        BOMBuffer.Get(BOMBuffer."Entry No.");
        BOMBuffer."Location Code" := Location.Code;
        BOMBuffer."Variant Code" := ItemVariant.Code;
        BOMBuffer.Modify();
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineItemJnlDay()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Inventory, 1, true, '<0D>', 1, 1, 0.3, GLBDateInterval::Day);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineItemJnlWeek()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Inventory, 1, true, '<0D>', 1, 1, 0.3, GLBDateInterval::Week);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SunshinePurchaseOrdersMonth()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Purchase, 1, true, '<0D>', 1, 1, 0.5, GLBDateInterval::Month);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure ShowTotalAvailFalseQuarter()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Purchase, 1, false, '<0D>', 1, 1, 0.6, GLBDateInterval::Quarter)
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NegativeAvailForSubassemblyDay()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Inventory, 1, true, '<0D>', 1, 1, 0, GLBDateInterval::Day);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NegAvailForSubassemblyUnbalancedTreeYr()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Inventory, 0.7, true, '<0D>', 1, 1, 0, GLBDateInterval::Year);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LocationFilterDay()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, true, SupplyType::Purchase, 1, true, '<0D>', 1, 1, 0.8, GLBDateInterval::Day);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DemandDateFilterDay()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Purchase, 1, true, '<-7D>', 1, 1, 0.4, GLBDateInterval::Day);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UnbalancedTreeTotalAvailFalseMonth()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Purchase, 0.8, false, '<0D>', 1, 1, 0.8, GLBDateInterval::Month);
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure UnbalancedTreeTotalAvailTrueQuarter()
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Purchase, 0.8, true, '<0D>', 1, 1, 0.3, GLBDateInterval::Quarter);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemAvailByBOMSkipsComponentsWithNegativeQtyPer()
    var
        ProdItem: Record Item;
        CompItem: array[2] of Record Item;
        ItemJournalLine: Record "Item Journal Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ItemAvailabilitybyBOMLevel: TestPage "Item Availability by BOM Level";
        QtyInStock: Decimal;
        QtyPer: Decimal;
    begin
        // [FEATURE] [Item Availability by BOM Level] [Production BOM]
        // [SCENARIO 300845] Item availability by BOM does not show production BOM components with negative Quantity Per.
        Initialize();

        QtyPer := LibraryRandom.RandIntInRange(10, 20);
        QtyInStock := QtyPer * LibraryRandom.RandIntInRange(100, 200);

        // [GIVEN] Two component items "P" and "N".
        // [GIVEN] Inventory of each item = 1000 pcs.
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem[1]."No.", '', '', QtyInStock);
        LibraryInventory.CreateItemJournalLineInItemTemplate(ItemJournalLine, CompItem[2]."No.", '', '', QtyInStock);
        LibraryInventory.PostItemJournalLine(ItemJournalLine."Journal Template Name", ItemJournalLine."Journal Batch Name");

        // [GIVEN] Certified production BOM with two lines.
        // [GIVEN] 1st line: No. = "P", Quantity Per = 20.
        // [GIVEN] 2nd line: No. = "N", Quantity Per = -20 (negative).
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItem[1]."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[1]."No.", QtyPer);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[2]."No.", -QtyPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Create a manufacturing item "A" and assign the production BOM to it.
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open Item Availability by BOM level page for item "A".
        ItemAvailabilitybyBOMLevel.Trap();
        RunItemAvailByBOMLevelPage(ProdItem, '', '');

        // [THEN] "Able to Make Parent" and "Able to Make Top Item" for production item "A" = 1000 / 20 = 50 pcs.
        ItemAvailabilitybyBOMLevel.Expand(true);
        ItemAvailabilitybyBOMLevel.FILTER.SetFilter("No.", ProdItem."No.");
        ItemAvailabilitybyBOMLevel."Able to Make Parent".AssertEquals(QtyInStock / QtyPer);
        ItemAvailabilitybyBOMLevel."Able to Make Top Item".AssertEquals(QtyInStock / QtyPer);

        // [THEN] "Able to Make Parent" and "Able to Make Top Item" for component item "P" = 1000 / 20 = 50 pcs.
        ItemAvailabilitybyBOMLevel.FILTER.SetFilter("No.", CompItem[1]."No.");
        ItemAvailabilitybyBOMLevel."Able to Make Parent".AssertEquals(QtyInStock / QtyPer);
        ItemAvailabilitybyBOMLevel."Able to Make Top Item".AssertEquals(QtyInStock / QtyPer);

        // [THEN] Component item "N" is not shown on the page.
        ItemAvailabilitybyBOMLevel.FILTER.SetFilter("No.", CompItem[2]."No.");
        Assert.IsFalse(ItemAvailabilitybyBOMLevel.First(), '');
    end;

    [Normal]
    local procedure SetupAbleToMakePage(SourceType: Option; BottleneckFactor: Decimal; DueDateDelay: Text; ChildLeaves: Integer; Depth: Integer; DirectAvailFactor: Decimal)
    var
        Location: Record Location;
        Item: Record Item;
        GenProdPostingGroup: Code[20];
        InventoryPostingGroup: Code[20];
        AbleToMake: Decimal;
        DueDateDelayDateFormula: DateFormula;
    begin
        // Setup.
        Initialize();
        AbleToMake := LibraryRandom.RandIntInRange(10, 25);

        LibraryWarehouse.CreateLocationWithInventoryPostingSetup(Location);
        LibraryAssembly.SetupPostingToGL(GenProdPostingGroup, InventoryPostingGroup, InventoryPostingGroup, '');
        LibraryAssembly.CreateItem(
          Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, GenProdPostingGroup, InventoryPostingGroup);
        LibraryTrees.CreateMixedTree(Item, Item."Replenishment System"::Assembly, Item."Costing Method"::Standard, Depth, ChildLeaves, 2);
        LibraryTrees.AddTreeVariants(Item."No.");
        LibraryTrees.CreateNodeSupply(Item."No.", Location.Code, WorkDate(), SourceType, AbleToMake, BottleneckFactor, DirectAvailFactor);

        Item.SetRange("No.", Item."No.");
        Evaluate(DueDateDelayDateFormula, DueDateDelay);
        Item.SetRange("Date Filter", 0D, CalcDate(DueDateDelayDateFormula, WorkDate()));
        Item.SetRange("Location Filter", Location.Code);

        // Exercise / Verify: Run Able To Make - Page.
        VerifyAbleToMakePage(Item, '', '', AbleToMake);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByBOMPageHandler,ItemAbleToMakeReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure SunshineItemJnlPage()
    begin
        SetupAbleToMakePage(SupplyType::Inventory, 1, '<0D>', 1, 1, 0.3);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByBOMPageHandler,ItemAbleToMakeReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure LocationFilterPage()
    begin
        SetupAbleToMakePage(SupplyType::Purchase, 1, '<0D>', 1, 1, 0.8);
    end;

    [Test]
    [HandlerFunctions('ItemAvailabilityByBOMPageHandler,ItemAbleToMakeReportHandler,MessageHandler')]
    [Scope('OnPrem')]
    procedure DemandDateFilterPage()
    begin
        SetupAbleToMakePage(SupplyType::Purchase, 1, '<-7D>', 1, 1, 0.4);
    end;

    [Normal]
    local procedure GenerateTreeForAsm(AsmOrderFilterType: Option; DueDateDelay: Text; BottleneckFactor: Decimal; ShowTotalAvailability: Boolean; DirectAvailFactor: Decimal; AvailabilityCorrection: Decimal)
    var
        Location: Record Location;
        BOMBuffer: Record "BOM Buffer";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        AbleToMake: Decimal;
        AssemblyQty: Decimal;
        DueDateDelayDateFormula: DateFormula;
    begin
        SetupAbleToMake(
          BOMBuffer, false, SupplyType::Inventory, BottleneckFactor, ShowTotalAvailability, '<0D>', 1, 1, DirectAvailFactor,
          GLBDateInterval::Day);
        Evaluate(DueDateDelayDateFormula, DueDateDelay);

        AbleToMake := BOMBuffer."Able to Make Top Item";
        if DirectAvailFactor <> 0 then
            AssemblyQty := LibraryRandom.RandInt(Round(AbleToMake * DirectAvailFactor, 1, '<'))
        else
            AssemblyQty := Round(AbleToMake, 1, '<') + AvailabilityCorrection;

        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalcDate(DueDateDelayDateFormula, WorkDate()), BOMBuffer."No.", BOMBuffer."Location Code", AssemblyQty, '');
        FindAssemblyLine(AssemblyLine, AssemblyHeader);
        LibraryWarehouse.CreateLocation(Location);

        case AsmOrderFilterType of
            FilterType::"Header Location":
                LibraryAssembly.UpdateAssemblyHeader(AssemblyHeader, AssemblyHeader.FieldNo("Location Code"), Location.Code);
            FilterType::"Header Variant":
                LibraryAssembly.UpdateAssemblyHeader(AssemblyHeader, AssemblyHeader.FieldNo("Variant Code"), '');
            FilterType::"Component Location":
                LibraryAssembly.UpdateAssemblyLine(AssemblyLine, AssemblyLine.FieldNo("Location Code"), Location.Code);
            FilterType::"Component Variant":
                LibraryAssembly.UpdateAssemblyLine(AssemblyLine, AssemblyLine.FieldNo("Variant Code"), '');
        end;

        // Exercise: Run Able To Make codeunit.
        CalculateBOMTree.SetShowTotalAvailability(ShowTotalAvailability);
        CalculateBOMTree.GenerateTreeForSource(AssemblyHeader, BOMBuffer, "BOM Tree Type"::Availability, "BOM Structure Show By"::Assembly, AssemblyHeader."Due Date");

        // Verify: Able to make report.
        VerifyAbleToMakeReport(
          BOMBuffer, CalcDate(DueDateDelayDateFormula, WorkDate()), GLBDateInterval::Day, AssemblyHeader."Location Code",
          AssemblyHeader."No.", '');

        NotificationLifecycleMgt.RecallAllNotifications();
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 1, true, 0.4, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ConfirmHandler,ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LocationFilterAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::"Header Location", '<0D>', 1, true, 0.4, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LocationCompAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::"Component Location", '<0D>', 1, true, 0.4, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NegAvailForLeafAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 1, true, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure NegAvailForLeafAsmOrderUnbalancedTree()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 0.7, true, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DateFilterAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<-7D>', 1, true, 0.4, 0);
    end;

    local procedure GenerateTreeForProdOrder(ProdOrderFilterType: Option; DueDateDelay: Text)
    var
        Location: Record Location;
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        AbleToMake: Decimal;
        DueDateDelayDateFormula: DateFormula;
    begin
        SetupAbleToMake(BOMBuffer, false, SupplyType::Inventory, 1, true, '<0D>', 1, 2, 0.4, GLBDateInterval::Day);
        Evaluate(DueDateDelayDateFormula, DueDateDelay);
        AbleToMake := BOMBuffer."Able to Make Top Item";
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, BOMBuffer."No.",
          LibraryRandom.RandInt(Round(AbleToMake * 0.4, 1, '<')));
        ProductionOrder.Validate("Due Date", CalcDate(DueDateDelayDateFormula, WorkDate()));
        ProductionOrder.Modify(true);
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);
        ProductionOrder.Find();
        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryInventory.CreateItem(Item);
        LibraryWarehouse.CreateLocation(Location);

        case ProdOrderFilterType of
            FilterType::"Header Location":
                LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Location Code"), Location.Code);
            FilterType::"Header Variant":
                LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Variant Code"), '');
            FilterType::"Component Location":
                begin
                    ProdOrderComponent.Validate("Item No.", Item."No.");
                    ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(5));
                    ProdOrderComponent.Modify(true);
                    LibraryTrees.CreateSupply(
                      Item."No.", '', BOMBuffer."Location Code", WorkDate(), SupplyType::Inventory,
                      ProductionOrder.Quantity * ProdOrderComponent."Quantity per");
                    LibraryManufacturing.UpdateProdOrderComp(ProdOrderComponent, ProdOrderComponent.FieldNo("Location Code"), Location.Code);
                    LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Location Code"), BOMBuffer."Location Code");
                end;
            else
                LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Location Code"), BOMBuffer."Location Code");
        end;

        // Exercise: Run Able To Make codeunit.
        CalculateBOMTree.SetShowTotalAvailability(true);
        CalculateBOMTree.GenerateTreeForSource(ProdOrderLine, BOMBuffer, "BOM Tree Type"::Availability, "BOM Structure Show By"::Production, ProdOrderLine."Due Date");

        // Verify: Able to make report.
        VerifyAbleToMakeReport(BOMBuffer, WorkDate(), GLBDateInterval::Day, ProdOrderLine."Location Code", '', ProductionOrder."No.");
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure SunshineProdOrder()
    begin
        GenerateTreeForProdOrder(FilterType::None, '<0D>');
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure LocationFilterProdOrder()
    begin
        GenerateTreeForProdOrder(FilterType::"Header Location", '<0D>');
    end;

    [Test]
    [HandlerFunctions('ItemAbleToMakeTimelineRequestPageHandler')]
    [Scope('OnPrem')]
    procedure DateFilterProdOrder()
    begin
        GenerateTreeForProdOrder(FilterType::None, '<-7D>');
    end;

    [Normal]
    local procedure FindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header")
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);
        AssemblyLine.FindFirst();
    end;

    [Normal]
    local procedure FindProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.FindFirst();
    end;

    [Normal]
    local procedure RunAbleToMakeReport(ItemNo: Code[20]; LocationCode: Code[10]; StartingDate: Date; DateInterval: Option; AssemblyHeaderNo: Code[20]; ProdOrderNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
        AsmHeader: Record "Assembly Header";
        Item1: Record Item;
        ItemAbleToMakeTimeline: Report "Item - Able to Make (Timeline)";
    begin
        Clear(ItemAbleToMakeTimeline);
        if (AssemblyHeaderNo <> '') and AsmHeader.Get(AsmHeader."Document Type"::Order, AssemblyHeaderNo) then
            ItemAbleToMakeTimeline.InitSource(AsmHeader, "BOM Structure Show By"::Assembly);

        if ProdOrderNo <> '' then begin
            ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
            if ProdOrderLine.FindFirst() then
                ItemAbleToMakeTimeline.InitSource(ProdOrderLine, "BOM Structure Show By"::Production);
        end;

        Commit();
        LibraryVariableStorage.Enqueue(StartingDate);
        LibraryVariableStorage.Enqueue(DateInterval);
        LibraryVariableStorage.Enqueue(7);
        LibraryVariableStorage.Enqueue(true);

        Item1.SetRange("No.", ItemNo);
        Item1.SetRange("Location Filter", LocationCode);
        ItemAbleToMakeTimeline.SetTableView(Item1);
        ItemAbleToMakeTimeline.Run();
    end;

    [Normal]
    local procedure VerifyAbleToMakeReport(BOMBuffer: Record "BOM Buffer"; StartDate: Date; DateInterval: Option; LocationCode: Code[10]; AsmHeaderNo: Code[20]; ProdOrderNo: Code[20])
    begin
        BOMBuffer.SetRange(Type, BOMBuffer.Type::Item);
        BOMBuffer.SetFilter(Indentation, '<%1', 1);
        BOMBuffer.SetRange("Is Leaf", false);
        if BOMBuffer.FindSet() then
            repeat
                RunAbleToMakeReport(BOMBuffer."No.", LocationCode, StartDate, DateInterval, AsmHeaderNo, ProdOrderNo);
                VerifyValuesForDate(StartDate, BOMBuffer);
            until BOMBuffer.Next() = 0;
    end;

    [Normal]
    local procedure VerifyValuesForDate(RowDate: Date; BOMBuffer: Record "BOM Buffer")
    var
        Qty: Decimal;
        InvtQty: Decimal;
        GrossReq: Decimal;
        SchedReceipts: Decimal;
    begin
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('AsOfPeriod', Format(RowDate));

        Qty := LibraryReportDataset.Sum('AbleToMakeQty');
        Assert.AreNearlyEqual(BOMBuffer."Able to Make Top Item", Qty, 0.00001, 'Wrong Able to make qty for item ' + BOMBuffer."No.");

        InvtQty := LibraryReportDataset.Sum('InvtQty');
        GrossReq := LibraryReportDataset.Sum('GrossReqQty');
        SchedReceipts := LibraryReportDataset.Sum('SchRcptQty');
        Assert.AreNearlyEqual(
          BOMBuffer."Available Quantity",
          InvtQty - GrossReq + SchedReceipts, 0.00001,
          'Wrong Avail. Qty for item ' + BOMBuffer."No.");

        Qty := LibraryReportDataset.Sum('TotalQty');
        Assert.AreNearlyEqual(
          BOMBuffer."Able to Make Parent" +
          BOMBuffer."Available Quantity",
          Qty, 0.00001, 'Wrong total qty for item ' + BOMBuffer."No.");
    end;

    [Normal]
    local procedure VerifyAbleToMakePage(var Item: Record Item; AsmHeaderNo: Code[20]; ProdOrderNo: Code[20]; AbleToMake: Decimal)
    begin
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(AbleToMake);

        RunItemAvailByBOMLevelPage(Item, AsmHeaderNo, ProdOrderNo);
    end;

    [Normal]
    local procedure RunItemAvailByBOMLevelPage(var Item: Record Item; AsmHeaderNo: Code[20]; ProdOrderNo: Code[20])
    var
        AsmHeader: Record "Assembly Header";
        ProdOrderLine: Record "Prod. Order Line";
        ItemAvailabilityByBOMLevel: Page "Item Availability by BOM Level";
    begin
        ItemAvailabilityByBOMLevel.InitItem(Item);

        if (AsmHeaderNo <> '') and AsmHeader.Get(AsmHeader."Document Type"::Order, AsmHeaderNo) then
            ItemAvailabilityByBOMLevel.InitSource(AsmHeader, "BOM Structure Show By"::Assembly);

        if ProdOrderNo <> '' then begin
            ProdOrderLine.SetRange(Status, ProdOrderLine.Status::Released);
            ProdOrderLine.SetRange("Prod. Order No.", ProdOrderNo);
            if ProdOrderLine.FindFirst() then
                ItemAvailabilityByBOMLevel.InitSource(ProdOrderLine, "BOM Structure Show By"::Production);
        end;

        ItemAvailabilityByBOMLevel.Run();
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := false;
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByBOMPageHandler(var ItemAvailByBOMLevel: TestPage "Item Availability by BOM Level")
    var
        DequeueVar: Variant;
        ItemNo: Code[20];
        Qty: Decimal;
    begin
        LibraryVariableStorage.Dequeue(DequeueVar);
        ItemNo := DequeueVar;
        ItemAvailByBOMLevel.FILTER.SetFilter("No.", ItemNo);
        ItemAvailByBOMLevel.First();

        LibraryVariableStorage.Dequeue(DequeueVar);
        Qty := DequeueVar;
        Assert.AreEqual(
          Qty, ItemAvailByBOMLevel."Able to Make Top Item".AsDecimal(),
          'Wrong able to make top item on page for item ' + Format(ItemAvailByBOMLevel."No."));
        Assert.AreEqual(
          Qty, ItemAvailByBOMLevel."Able to Make Parent".AsDecimal(),
          'Wrong able to make parent on page for item ' + Format(ItemAvailByBOMLevel."No."));

        Commit(); // To allow running the action from the page.
        ItemAvailByBOMLevel."Item - Able to Make (Timeline)".Invoke(); // Run Show Warnings for code coverage purposes.
        ItemAvailByBOMLevel."Show Warnings".Invoke(); // Run Item Avail by BOM Level report for code coverage purposes.
    end;

    [ReportHandler]
    [Scope('OnPrem')]
    procedure ItemAbleToMakeReportHandler(var ItemAbleToMakeTimeline: Report "Item - Able to Make (Timeline)")
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure ItemAbleToMakeTimelineRequestPageHandler(var ItemAbleToMakeTimeline: TestRequestPage "Item - Able to Make (Timeline)")
    var
        StartingDate: Variant;
        DateInterval: Variant;
        NoOfIntervals: Variant;
        ShowDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(StartingDate);
        LibraryVariableStorage.Dequeue(DateInterval);
        LibraryVariableStorage.Dequeue(NoOfIntervals);
        LibraryVariableStorage.Dequeue(ShowDetails);

        ItemAbleToMakeTimeline.StartDate.SetValue(StartingDate);
        ItemAbleToMakeTimeline.DateInterval.SetValue(DateInterval);
        ItemAbleToMakeTimeline.NoOfIntervals.SetValue(NoOfIntervals);
        ItemAbleToMakeTimeline.ShowDetails.SetValue(ShowDetails);
        ItemAbleToMakeTimeline.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;
}

