// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.BOM.Tree;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Availability;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Journal;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.Routing;

codeunit 137107 "SCM Kitting - Able To Make"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [Able to Make] [SCM]
        isInitialized := false;
    end;

    var
        BOMBuffer: Record "BOM Buffer";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryTrees: Codeunit "Library - Trees";
        LibraryNotificationMgt: Codeunit "Library - Notification Mgt.";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryPlanning: Codeunit "Library - Planning";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        FilterType: Option "None",Location,Variant,"Header Location","Header Variant","Component Location","Component Variant";
        SupplyType: Option Inventory,Purchase,"Prod. Order";
        ItemErr: Label '%1 Item must Exist';
        ItemNotExistErr: Label '%1 Item must not Exist';

    [Normal]
    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Able To Make");
        // Initialize setup.
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Able To Make");

        // Setup Demonstration data.
        isInitialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryPlanning.SetDefaultSafetyLeadTime('<1D>');
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Able To Make");
    end;

    [Normal]
    local procedure SetupAbleToMake(var BOMBuffer: Record "BOM Buffer"; TestLocation: Boolean; TestVariant: Boolean; SourceType: Option; BottleneckFactor: Decimal; ShowTotalAvailability: Boolean; DueDateDelay: Text; ChildLeaves: Integer; Depth: Integer; DirectAvailFactor: Decimal)
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
        LibraryTrees.AddTreeVariants(Item."No.");
        LibraryTrees.CreateNodeSupply(Item."No.", Location.Code, WorkDate(), SourceType, AbleToMake, BottleneckFactor, DirectAvailFactor);

        Item.SetRange("No.", Item."No.");
        Evaluate(DueDateDelayDateFormula, DueDateDelay);
        Item.SetRange("Date Filter", 0D, CalcDate(DueDateDelayDateFormula, WorkDate()));

        if TestVariant then
            LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        Item.SetRange("Variant Filter", ItemVariant.Code);

        if TestLocation then
            LibraryWarehouse.CreateLocation(Location);
        Item.SetRange("Location Filter", Location.Code);

        if TestLocation or (DueDateDelay <> '<0D>') then
            AbleToMake := 0;

        // Exercise: Create the BOM tree.
        CalculateBOMTree.SetShowTotalAvailability(ShowTotalAvailability);
        CalculateBOMTree.GenerateTreeForManyItems(Item, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuffer, Item."No.", ShowTotalAvailability, BottleneckFactor, AbleToMake, 1, DirectAvailFactor, 0);
        VerifyNode(BOMBuffer, Item."No.", 0, AbleToMake * BottleneckFactor, 1, 1);
        BOMBuffer."Location Code" := Location.Code;
        BOMBuffer.Modify();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SunshineItemJnl()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Inventory, 1, true, '<0D>', 1, 1, 0.3);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SunshinePurchaseOrders()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, 1, true, '<0D>', 1, 1, 0.5);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ShowTotalAvailFalse()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, 1, false, '<0D>', 1, 1, 0.6)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegativeAvailForSubassembly()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Inventory, 1, true, '<0D>', 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NegAvailForSubassemblyUnbalancedTree()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Inventory, 0.7, true, '<0D>', 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LocationFilter()
    begin
        SetupAbleToMake(BOMBuffer, true, false, SupplyType::Purchase, 1, true, '<0D>', 1, 1, 0.8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantFilter()
    begin
        SetupAbleToMake(BOMBuffer, false, true, SupplyType::Purchase, 1, true, '<0D>', 1, 1, 0.2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DemandDateFilter()
    begin
        SetupAbleToMake(BOMBuffer, true, true, SupplyType::Purchase, 1, true, '<-7D>', 1, 1, 0.4);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BigTree()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, 1, true, '<0D>', 3, 2, 0.6);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnbalancedTreeTotalAvailFalse()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, 0.8, false, '<0D>', 1, 1, 0.8);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure UnbalancedTreeTotalAvailTrue()
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, 0.8, true, '<0D>', 1, 1, 0.3);
    end;

    [Normal]
    local procedure GenerateTreeForAsm(AsmOrderFilterType: Option; DueDateDelay: Text; BottleneckFactor: Decimal; ShowTotalAvailability: Boolean; DirectAvailFactor: Decimal; AvailabilityCorrection: Decimal)
    var
        Location: Record Location;
        BOMBuffer: Record "BOM Buffer";
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        ItemFilter: Record Item;
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        InitialAbleToMake: Decimal;
        AbleToMake: Decimal;
        AssemblyQty: Decimal;
        DueDateDelayDateFormula: DateFormula;
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, BottleneckFactor, ShowTotalAvailability, '<0D>', 1, 1, DirectAvailFactor);
        Evaluate(DueDateDelayDateFormula, DueDateDelay);

        if DirectAvailFactor <> 0 then
            AssemblyQty := LibraryRandom.RandInt(Round(BOMBuffer."Able to Make Top Item" * DirectAvailFactor, 1, '<'))
        else
            AssemblyQty := Round(BOMBuffer."Able to Make Top Item", 1, '<') + AvailabilityCorrection;

        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, CalcDate(DueDateDelayDateFormula, WorkDate()), BOMBuffer."No.", BOMBuffer."Location Code",
          AssemblyQty, BOMBuffer."Variant Code");
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

        AbleToMake := BOMBuffer."Able to Make Top Item" - AssemblyQty;
        InitialAbleToMake := BOMBuffer."Able to Make Top Item";
        if AsmOrderFilterType = FilterType::"Component Location" then
            AbleToMake := 0;

        if DueDateDelay <> '<0D>' then begin
            InitialAbleToMake := 0;
            AbleToMake := 0;
        end;

        // Exercise.
        ItemFilter.SetFilter("Location Filter", '%1', AssemblyHeader."Location Code");
        CalculateBOMTree.SetItemFilter(ItemFilter);
        CalculateBOMTree.SetShowTotalAvailability(ShowTotalAvailability);
        CalculateBOMTree.GenerateTreeForSource(AssemblyHeader, BOMBuffer, "BOM Tree Type"::Availability, "BOM Structure Show By"::Assembly, AssemblyHeader."Due Date");

        // Verify: Check the top item.
        VerifyTopItem(BOMBuffer, AssemblyHeader."Item No.", AssemblyQty, AbleToMake, ShowTotalAvailability);
        VerifyTreeAsmOrder(
          BOMBuffer, ShowTotalAvailability, BottleneckFactor, InitialAbleToMake / BottleneckFactor, 1, DirectAvailFactor, AssemblyHeader,
          AsmOrderFilterType);

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckReplenishmentSystemOnAvailabilityPageWithLocationFilter()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ItemAvailabilityPage: TestPage "Item Availability by BOM Level";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Item Availability by BOM Level] [Stockkeeping Unit]
        // [SCENARIO 363686] Replenishment System on Availability by BOM level Page is taken from SKU of filtering Location

        // [GIVEN] Item with Replenishment System = "X"
        // [GIVEN] SKU for Item on Location "L" with Replenishment System = "Y"
        CreateBOMItemWithSKUonLocation(Item, SKU, LocationCode);

        // [WHEN] Set "Location Filter" on Availability by BOM level to "L"
        ItemAvailabilityPage.OpenEdit();
        ItemAvailabilityPage.ItemFilter.SetValue(Item."No.");
        ItemAvailabilityPage.LocationFilter.SetValue(LocationCode);

        // [THEN] Replenishment System on Availability by BOM level Page is "Y"
        ItemAvailabilityPage."Replenishment System".AssertEquals(SKU."Replenishment System");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckReplenishmentSystemOnAvailabilityPageWithoutLocationFilter()
    var
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        ItemAvailabilityPage: TestPage "Item Availability by BOM Level";
        LocationCode: Code[10];
    begin
        // [FEATURE] [Item Availability by BOM Level] [Stockkeeping Unit]
        // [SCENARIO 363686] Replenishment System on Availability by BOM level Page is taken from Item if not filtering by Location

        // [GIVEN] Item with Replenishment System = "X"
        // [GIVEN] SKU for Item on Location "L" with Replenishment System = "Y"
        CreateBOMItemWithSKUonLocation(Item, SKU, LocationCode);

        // [WHEN] "Location Filter" on Availability by BOM is empty
        ItemAvailabilityPage.OpenEdit();
        ItemAvailabilityPage.ItemFilter.SetValue(Item."No.");

        // [THEN] Replenishment System on Availability by BOM level Page is "X"
        ItemAvailabilityPage."Replenishment System".AssertEquals(Item."Replenishment System");
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure SunshineAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 1, true, 0.4, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UnbalancedTreeAsmOrderShowTotalAvailTrue()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 0.8, true, 0.4, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure UnbalancedTreeAsmOrderShowTotalAvailFalse()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 0.8, false, 0.6, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PosAvailForLeafAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 1, true, 0, -1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure PosAvailForLeafAsmOrderUnbalancedTree()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 0.7, true, 0, -1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NegAvailForLeafAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 1, true, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure NegAvailForLeafAsmOrderUnbalancedTree()
    begin
        GenerateTreeForAsm(FilterType::None, '<0D>', 0.7, true, 0, 1);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    [Scope('OnPrem')]
    procedure DateFilterAsmOrder()
    begin
        GenerateTreeForAsm(FilterType::None, '<-7D>', 1, true, 0.4, 0);
    end;

    [Test]
    [HandlerFunctions('MessageHandler,BOMLevelAbleToMakeHandler')]
    [Scope('OnPrem')]
    procedure CyclicalAsmOrder()
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        AssemblyOrder: TestPage "Assembly Order";
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Inventory, 1, true, '<0D>', 1, 1, 0.6);
        LibraryAssembly.CreateAssemblyHeader(
          AssemblyHeader, WorkDate(), BOMBuffer."No.", BOMBuffer."Location Code", BOMBuffer."Able to Make Top Item", BOMBuffer."Variant Code");
        LibraryAssembly.CreateAssemblyLine(
          AssemblyHeader, AssemblyLine, "BOM Component Type"::Item, AssemblyHeader."Item No.",
          AssemblyHeader."Unit of Measure Code", LibraryRandom.RandInt(5), 1, '');

        // Exercise.
        CalculateBOMTree.SetShowTotalAvailability(true);
        CalculateBOMTree.GenerateTreeForSource(AssemblyHeader, BOMBuffer, "BOM Tree Type"::Availability, "BOM Structure Show By"::Assembly, AssemblyHeader."Due Date");

        // Verify: BOM Level - Able to Make page.
        AssemblyOrder.OpenEdit();
        AssemblyOrder.FILTER.SetFilter("No.", AssemblyHeader."No.");

        AssemblyOrder."BOM Level".Invoke();
        AssemblyOrder.OK().Invoke();

        LibraryNotificationMgt.RecallNotificationsForRecordID(AssemblyHeader.RecordId);
    end;

    local procedure GenerateTreeForProdOrder(TestLocation: Boolean; DueDateDelay: Text)
    var
        Location: Record Location;
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        ReleasedProductionOrder: TestPage "Released Production Order";
        AbleToMake: Decimal;
        DueDateDelayDateFormula: DateFormula;
    begin
        SetupAbleToMake(BOMBuffer, false, false, SupplyType::Purchase, 1, true, '<0D>', 1, 1, 0.4);
        Evaluate(DueDateDelayDateFormula, DueDateDelay);
        LibraryManufacturing.CreateProductionOrder(
          ProductionOrder, ProductionOrder.Status::Released, ProductionOrder."Source Type"::Item, BOMBuffer."No.",
          BOMBuffer."Able to Make Top Item");
        LibraryManufacturing.RefreshProdOrder(ProductionOrder, false, true, false, true, false);

        FindProdOrderLine(ProdOrderLine, ProductionOrder);
        LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Location Code"), BOMBuffer."Location Code");
        LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Variant Code"), BOMBuffer."Variant Code");
        LibraryManufacturing.UpdateProdOrderLine(
          ProdOrderLine, ProdOrderLine.FieldNo("Due Date"), CalcDate(DueDateDelayDateFormula, WorkDate()));

        LibraryManufacturing.CreateProductionOrderComponent(
          ProdOrderComponent, ProductionOrder.Status, ProductionOrder."No.", ProdOrderLine."Line No.");
        LibraryInventory.CreateItem(Item);
        ProdOrderComponent.Validate("Item No.", Item."No.");
        ProdOrderComponent.Validate("Quantity per", LibraryRandom.RandInt(5));
        ProdOrderComponent.Modify(true);
        LibraryTrees.CreateSupply(
          Item."No.", '', BOMBuffer."Location Code", WorkDate(), SupplyType::Inventory,
          ProductionOrder.Quantity * ProdOrderComponent."Quantity per");

        if TestLocation then begin
            LibraryWarehouse.CreateLocation(Location);
            LibraryManufacturing.UpdateProdOrderLine(ProdOrderLine, ProdOrderLine.FieldNo("Location Code"), Location.Code);
        end;

        AbleToMake := ProductionOrder.Quantity;

        // Exercise.
        CalculateBOMTree.SetShowTotalAvailability(true);
        CalculateBOMTree.GenerateTreeForSource(ProdOrderLine, BOMBuffer, "BOM Tree Type"::Availability, "BOM Structure Show By"::Production, ProdOrderLine."Due Date");

        // Verify: Check top item.
        VerifyTopItem(BOMBuffer, ProdOrderLine."Item No.", AbleToMake, 0, true);

        // Verify: BOM Level - Able to Make page.
        ReleasedProductionOrder.OpenEdit();
        ReleasedProductionOrder.FILTER.SetFilter("No.", ProductionOrder."No.");

        ReleasedProductionOrder.ProdOrderLines.ItemAvailabilityByBOMLevel.Invoke();
        ReleasedProductionOrder.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('BOMLevelAbleToMakeHandler')]
    [Scope('OnPrem')]
    procedure SunshineProdOrder()
    begin
        GenerateTreeForProdOrder(false, '<0D>');
    end;

    [Test]
    [HandlerFunctions('BOMLevelAbleToMakeHandler')]
    [Scope('OnPrem')]
    procedure LocationFilterProdOrder()
    begin
        GenerateTreeForProdOrder(true, '<0D>');
    end;

    [Test]
    [HandlerFunctions('BOMLevelAbleToMakeHandler')]
    [Scope('OnPrem')]
    procedure DateFilterProdOrder()
    begin
        GenerateTreeForProdOrder(false, '<-7D>');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CreateBOMTreeWithLeafItemsMorePlaces()
    var
        rootItem: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        ItemD: Record Item;
        ItemX: Record Item;
        ItemY: Record Item;
        BOMComponent: Record "BOM Component";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        p1: Decimal;
        b1: Decimal;
        p2: Decimal;
        c1: Decimal;
        c2: Decimal;
        p3: Decimal;
        d1: Decimal;
        ItemXDemand: Decimal;
        ItemYDemand: Decimal;
    begin
        // BOM
        // rootItem
        // - p1 * ItemB
        // - - - b1 * ItemX
        // - p2 * ItemC
        // - - - c1 * ItemX
        // - - - c2 * ItemY
        // - p3 * ItemD
        // - - - d1 * ItemC
        // - - - - -c1 * ItemX
        // - - - - -c2 * ItemY

        // Demand of ItemX per ParentItem := p1*b1 + p2*c1 + p3*d1*c1
        // Demand of ItemY per ParentItem := 0 + p2*c2 + p3*d1*c2

        LibraryAssembly.CreateItem(rootItem, rootItem."Costing Method"::Standard, rootItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ItemB, ItemB."Costing Method"::Standard, ItemB."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ItemC, ItemC."Costing Method"::Standard, ItemC."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ItemD, ItemD."Costing Method"::Standard, ItemD."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ItemX, ItemX."Costing Method"::Standard, ItemX."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ItemY, ItemY."Costing Method"::Standard, ItemY."Replenishment System"::Assembly, '', '');

        p1 := 2;
        b1 := 3;
        p2 := 4;
        c1 := 5;
        c2 := 6;
        p3 := 7;
        d1 := 8;
        ItemXDemand := p1 * b1 + p2 * c1 + p3 * d1 * c1;
        ItemYDemand := p2 * c2 + p3 * d1 * c2;

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemB."No.", rootItem."No.", '', BOMComponent."Resource Usage Type"::Direct, p1, true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemC."No.", rootItem."No.", '', BOMComponent."Resource Usage Type"::Direct, p2, true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemD."No.", rootItem."No.", '', BOMComponent."Resource Usage Type"::Direct, p3, true);

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemX."No.", ItemB."No.", '', BOMComponent."Resource Usage Type"::Direct, b1, true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemX."No.", ItemC."No.", '', BOMComponent."Resource Usage Type"::Direct, c1, true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemY."No.", ItemC."No.", '', BOMComponent."Resource Usage Type"::Direct, c2, true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ItemC."No.", ItemD."No.", '', BOMComponent."Resource Usage Type"::Direct, d1, true);

        // Not able to make 1 PCS of rootItem:
        LibraryTrees.CreateSupply(ItemX."No.", '', '', WorkDate(), SupplyType::Inventory, ItemXDemand / 2);
        LibraryTrees.CreateSupply(ItemY."No.", '', '', WorkDate(), SupplyType::Inventory, ItemYDemand / 2);

        // Exercise.
        CalculateBOMTree.SetShowTotalAvailability(true);
        rootItem.SetRange("No.", rootItem."No.");
        rootItem.SetRange("Date Filter", 0D, WorkDate());
        CalculateBOMTree.GenerateTreeForManyItems(rootItem, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Able to make is a fraction of 1.
        VerifyNode(BOMBuffer, rootItem."No.", 0, 0.5, 1, 1);

        // Able to make 1 PCS of rootItem:
        LibraryTrees.CreateSupply(ItemX."No.", '', '', WorkDate(), SupplyType::Inventory, ItemXDemand / 2);
        LibraryTrees.CreateSupply(ItemY."No.", '', '', WorkDate(), SupplyType::Inventory, ItemYDemand / 2);
        CalculateBOMTree.GenerateTreeForManyItems(rootItem, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Able to make is 1.
        VerifyNode(BOMBuffer, rootItem."No.", 0, 1, 1, 1);

        // Able to make 1 PCS of rootItem, different supply for X and Y.
        LibraryTrees.CreateSupply(ItemX."No.", '', '', WorkDate(), SupplyType::Inventory, ItemXDemand);
        CalculateBOMTree.GenerateTreeForManyItems(rootItem, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Able to make is 1.
        VerifyNode(BOMBuffer, rootItem."No.", 0, 1, 1, 1);

        // Able to make more than 1 PCS of rootItem:
        LibraryTrees.CreateSupply(ItemY."No.", '', '', WorkDate(), SupplyType::Inventory, ItemYDemand);
        CalculateBOMTree.GenerateTreeForManyItems(rootItem, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Able to make is 1.
        VerifyNode(BOMBuffer, rootItem."No.", 0, 2, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestBottleneckAssignments()
    var
        RootItem: Record Item;
        InventoryItem: Record Item;
        NonInventoryItem: Record Item;
        BOMComponent: Record "BOM Component";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
    begin
        LibraryAssembly.CreateItem(RootItem, RootItem."Costing Method"::Standard, RootItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(InventoryItem, InventoryItem."Costing Method"::Standard, InventoryItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(NonInventoryItem, NonInventoryItem."Costing Method"::Standard, NonInventoryItem."Replenishment System"::Assembly, '', '');

        NonInventoryItem.Type := NonInventoryItem.Type::"Non-Inventory";
        NonInventoryItem.Modify();

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, InventoryItem."No.", RootItem."No.", '', BOMComponent."Resource Usage Type"::Direct, 1, true);

        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, NonInventoryItem."No.", RootItem."No.", '', BOMComponent."Resource Usage Type"::Direct, 1, true);

        // Exercise
        CalculateBOMTree.SetShowTotalAvailability(true);
        RootItem.SetRange("No.", RootItem."No.");
        RootItem.SetRange("Date Filter", 0D, WorkDate());
        CalculateBOMTree.GenerateTreeForManyItems(RootItem, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Inventory Item is bottleneck
        BOMBuffer.SetRange("No.", InventoryItem."No.");
        BomBuffer.FindFirst();
        Assert.IsTrue(BOMBuffer.Bottleneck, 'Inventory item should be a bottleneck');

        // Verify: Non inventory Item is not a bottleneck
        BOMBuffer.SetRange("No.", NonInventoryItem."No.");
        BomBuffer.FindFirst();
        Assert.IsFalse(BOMBuffer.Bottleneck, 'Non inventory item should never be a bottleneck');

        // Adjust stock for Inventory Items
        SelectItemJournal(ItemJournalBatch);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalBatch."Journal Template Name",
          ItemJournalBatch.Name, ItemJournalLine."Entry Type"::
          "Positive Adjmt.", InventoryItem."No.", LibraryRandom.RandDec(10, 2));
        LibraryInventory.PostItemJournalLine(ItemJournalBatch."Journal Template Name", ItemJournalBatch.Name);

        CalculateBOMTree.GenerateTreeForManyItems(RootItem, BOMBuffer, "BOM Tree Type"::Availability);

        // Verify: Inventory Item is a bottleneck now
        BOMBuffer.SetRange("No.", InventoryItem."No.");
        BomBuffer.FindFirst();
        Assert.IsTrue(BOMBuffer.Bottleneck, 'Inventory item should be a bottleneck');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemInTreeWithProdAndAssemblyBOM()
    var
        ParentItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        AssemblyItemNo: Code[20];
    begin
        // Check Assembly Bom Item in BomBuffer after created AssemblyBOM and Prodtion BOM for Parent Item with Replenishment System is Assembly.

        // Setup: Create assembly and production BOM for Parent Item.
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::FIFO, ParentItem."Replenishment System"::Assembly, '', '');
        LibraryManufacturing.CreateCertifiedProductionBOM(
          ProductionBOMHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        UpdateParentItemWithProdBomNo(ParentItem, ProductionBOMHeader."No.");
        AssemblyItemNo := CreateAssemblyComponent(ParentItem."No.");

        // Exercise: Fill the BOMBuffer for Parent Item.
        CalculateBOMTree.GenerateTreeForOneItem(ParentItem, BOMBuffer, 0D, "BOM Tree Type"::" ");

        // Verify: Check Assembly BOM Item exist in BOMBuffer
        VerifyItemInBomBuffer(AssemblyItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemInTreeWithAssemblyBom()
    var
        ParentItem: Record Item;
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
        AssemblyItemNo: Code[20];
    begin
        // Check Assembly Bom Item not in BomBuffer after created AssemblyBOM for Parent Item with Replenishment System is Prod. Order.

        // Setup: Create assembly BOM for Parent Item.
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::FIFO, ParentItem."Replenishment System"::"Prod. Order", '', '');
        AssemblyItemNo := CreateAssemblyComponent(ParentItem."No.");

        // Exercise: Fill the BOMBuffer for Parent Item.
        CalculateBOMTree.GenerateTreeForOneItem(ParentItem, BOMBuffer, 0D, "BOM Tree Type"::" ");

        // Verify: Check Assembly BOM Item does not exist in BOMBuffer
        VerifyItemNotInBomBuffer(AssemblyItemNo);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure CheckItemInTreeWithProdBOM()
    var
        ParentItem: Record Item;
        Item: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
    begin
        // Check Production Bom Item not in BomBuffer after created Production BOM for Parent Item with Replenishment System is Assembly.

        // Setup:
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::FIFO, ParentItem."Replenishment System"::Assembly, '', '');
        LibraryManufacturing.CreateCertifiedProductionBOM(
          ProductionBOMHeader, LibraryInventory.CreateItem(Item), LibraryRandom.RandInt(5));
        UpdateParentItemWithProdBomNo(ParentItem, ProductionBOMHeader."No.");

        // Exercise:
        CalculateBOMTree.GenerateTreeForOneItem(ParentItem, BOMBuffer, 0D, "BOM Tree Type"::" ");

        // Verify: Check Production BOM Item does not exist in BOMBuffer
        VerifyItemNotInBomBuffer(Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOnBOMBufferEntryFromProductionBOM()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        BOMBuffer: Record "BOM Buffer";
        EntryNo: Integer;
    begin
        // [FEATURE] [Production BOM] [UT]
        // [SCENARIO 257036] Description on BOM Buffer entry transferred from a production BOM, is copied from Description field on the production BOM line.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Description := LibraryUtility.GenerateGUID();
        Item.Modify(true);

        ProductionBOMLine.Init();
        ProductionBOMLine.Type := ProductionBOMLine.Type::Item;
        ProductionBOMLine."No." := Item."No.";
        ProductionBOMLine.Description := LibraryUtility.GenerateGUID();
        ProductionBOMLine.Insert();

        EntryNo := LibraryUtility.GetNewRecNo(BOMBuffer, BOMBuffer.FieldNo("Entry No."));
        BOMBuffer.TransferFromProdComp(EntryNo, ProductionBOMLine, 0, 0, 0, 0, WorkDate(), '', Item, 1);

        BOMBuffer.TestField(Description, ProductionBOMLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOnBOMBufferEntryFromRouting()
    var
        WorkCenter: Record "Work Center";
        RoutingLine: Record "Routing Line";
        BOMBuffer: Record "BOM Buffer";
        EntryNo: Integer;
    begin
        // [FEATURE] [Routing] [UT]
        // [SCENARIO 257036] Description on BOM Buffer entry transferred from a routing, is copied from Description field on the routing line.
        Initialize();

        WorkCenter.Init();
        WorkCenter."No." := LibraryUtility.GenerateGUID();
        WorkCenter.Name := LibraryUtility.GenerateGUID();
        WorkCenter.Insert();

        RoutingLine.Init();
        RoutingLine.Type := RoutingLine.Type::"Work Center";
        RoutingLine."No." := WorkCenter."No.";
        RoutingLine.Description := LibraryUtility.GenerateGUID();
        RoutingLine.Insert();

        EntryNo := LibraryUtility.GetNewRecNo(BOMBuffer, BOMBuffer.FieldNo("Entry No."));
        BOMBuffer.TransferFromProdRouting(EntryNo, RoutingLine, 0, 0, WorkDate(), '');

        BOMBuffer.TestField(Description, RoutingLine.Description);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DescriptionOnBOMBufferEntryFromAssemblyBOM()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
        BOMBuffer: Record "BOM Buffer";
        EntryNo: Integer;
    begin
        // [FEATURE] [Assembly BOM] [UT]
        // [SCENARIO 257036] Description on BOM Buffer entry transferred from an assembly BOM, is copied from Description field on the assembly component line.
        Initialize();

        LibraryInventory.CreateItem(Item);
        Item.Description := LibraryUtility.GenerateGUID();
        Item.Modify(true);

        BOMComponent.Init();
        BOMComponent.Type := BOMComponent.Type::Item;
        BOMComponent."No." := Item."No.";
        BOMComponent.Description := LibraryUtility.GenerateGUID();
        BOMComponent.Insert();

        EntryNo := LibraryUtility.GetNewRecNo(BOMBuffer, BOMBuffer.FieldNo("Entry No."));
        BOMBuffer.TransferFromBOMComp(EntryNo, BOMComponent, 0, 0, 0, WorkDate(), '');

        BOMBuffer.TestField(Description, BOMComponent.Description);
    end;

    local procedure CreateBOMItemWithSKUonLocation(var Item: Record Item; var SKU: Record "Stockkeeping Unit"; var LocationCOde: Code[10])
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        LocationCOde := Location.Code;

        CreateBOMItem(Item);

        LibraryInventory.CreateStockkeepingUnitForLocationAndVariant(SKU, LocationCOde, Item."No.", '');
        SKU.Validate("Replenishment System", SKU."Replenishment System"::Transfer);
        SKU.Modify(true);
    end;

    local procedure CreateBOMItem(var ParentItem: Record Item)
    var
        CompItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ParentItem);
        LibraryInventory.CreateItem(CompItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ParentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", LibraryRandom.RandDec(10, 2));
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        ParentItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ParentItem.Modify(true);
    end;

    local procedure SelectItemJournal(var ItemJournalBatch: Record "Item Journal Batch")
    var
        ItemJournalTemplate: Record "Item Journal Template";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.ClearItemJournal(ItemJournalTemplate, ItemJournalBatch);
    end;

    local procedure CreateAssemblyComponent(ParentItemNo: Code[20]): Code[20]
    var
        AssemblyItem: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(AssemblyItem, AssemblyItem."Costing Method"::FIFO, AssemblyItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, AssemblyItem."No.", ParentItemNo, '',
          BOMComponent."Resource Usage Type"::Direct, LibraryRandom.RandDec(2, 4), true);
        exit(AssemblyItem."No.");
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
    local procedure VerifyTree(var BOMBuffer: Record "BOM Buffer"; ParentItemNo: Code[20]; ShowTotalAvailability: Boolean; BottleneckFactor: Decimal; ExpAbleToMakeParent: Decimal; ParentQtyPer: Decimal; DirectAvailabilityFactor: Decimal; LocalDemand: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItemNo);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);

        if BOMComponent.FindSet() then
            repeat
                BOMBuffer.Reset();
                BOMComponent.CalcFields("Assembly BOM");

                if BOMComponent."Assembly BOM" then
                    VerifyNode(
                      BOMBuffer, BOMComponent."No.",
                      ExpAbleToMakeParent *
                      BottleneckFactor * BOMComponent."Quantity per" * DirectAvailabilityFactor - LocalDemand * BOMComponent."Quantity per",
                      ExpAbleToMakeParent * BottleneckFactor * BOMComponent."Quantity per" * (1 - DirectAvailabilityFactor),
                      BOMComponent."Quantity per", ParentQtyPer * BOMComponent."Quantity per")
                else
                    if ShowTotalAvailability then
                        VerifyNode(
                          BOMBuffer, BOMComponent."No.",
                          ExpAbleToMakeParent * BOMComponent."Quantity per" - LocalDemand * BOMComponent."Quantity per", 0,
                          BOMComponent."Quantity per", ParentQtyPer * BOMComponent."Quantity per")
                    else
                        VerifyNode(
                          BOMBuffer, BOMComponent."No.",
                          ExpAbleToMakeParent * BottleneckFactor * BOMComponent."Quantity per" - LocalDemand * BOMComponent."Quantity per", 0,
                          BOMComponent."Quantity per", ParentQtyPer * BOMComponent."Quantity per");

                VerifyTree(
                  BOMBuffer, BOMComponent."No.", ShowTotalAvailability, 1,
                  ExpAbleToMakeParent * BottleneckFactor * BOMComponent."Quantity per" * (1 - DirectAvailabilityFactor),
                  ParentQtyPer * BOMComponent."Quantity per", DirectAvailabilityFactor, 0);
            until BOMComponent.Next() = 0;
    end;

    [Normal]
    local procedure VerifyTreeAsmOrder(var BOMBuffer: Record "BOM Buffer"; ShowTotalAvailability: Boolean; BottleneckFactor: Decimal; InitAbleToMakeParent: Decimal; ParentQtyPer: Decimal; DirectAvailabilityFactor: Decimal; AssemblyHeader: Record "Assembly Header"; AsmFilterType: Option)
    var
        AssemblyLine: Record "Assembly Line";
        Item: Record Item;
        ExpAbleToMakeParent: Decimal;
    begin
        AssemblyLine.SetRange("Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange("Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(Type, AssemblyLine.Type::Item);

        if AssemblyLine.FindSet() then
            repeat
                BOMBuffer.Reset();
                Item.Get(AssemblyLine."No.");
                Item.CalcFields("Assembly BOM");

                if (AssemblyLine."Location Code" <> AssemblyHeader."Location Code") and
                   (AsmFilterType = FilterType::"Component Location")
                then
                    ExpAbleToMakeParent := 0
                else
                    ExpAbleToMakeParent := InitAbleToMakeParent;

                if Item."Assembly BOM" then
                    VerifyNode(
                      BOMBuffer, AssemblyLine."No.",
                      ExpAbleToMakeParent * BottleneckFactor * AssemblyLine."Quantity per" * DirectAvailabilityFactor - AssemblyLine.Quantity,
                      ExpAbleToMakeParent * BottleneckFactor * AssemblyLine."Quantity per" * (1 - DirectAvailabilityFactor),
                      AssemblyLine."Quantity per", ParentQtyPer * AssemblyLine."Quantity per")
                else
                    if ShowTotalAvailability then
                        VerifyNode(
                          BOMBuffer, AssemblyLine."No.", ExpAbleToMakeParent * AssemblyLine."Quantity per" - AssemblyLine.Quantity, 0,
                          AssemblyLine."Quantity per", ParentQtyPer * AssemblyLine."Quantity per")
                    else
                        VerifyNode(
                          BOMBuffer, AssemblyLine."No.",
                          ExpAbleToMakeParent * BottleneckFactor * AssemblyLine."Quantity per" - AssemblyLine.Quantity, 0,
                          AssemblyLine."Quantity per", ParentQtyPer * AssemblyLine."Quantity per");

                VerifyTree(
                  BOMBuffer, AssemblyLine."No.", ShowTotalAvailability, 1,
                  InitAbleToMakeParent * BottleneckFactor * AssemblyLine."Quantity per" * (1 - DirectAvailabilityFactor),
                  ParentQtyPer * AssemblyLine."Quantity per", DirectAvailabilityFactor, 0);
            until AssemblyLine.Next() = 0;
    end;

    [Normal]
    local procedure VerifyNode(var BOMBuffer: Record "BOM Buffer"; ItemNo: Code[20]; DirectAvailability: Decimal; IndirectAvailability: Decimal; QtyPerParent: Decimal; QtyPerTopItem: Decimal)
    var
        AbleToMake: Decimal;
    begin
        BOMBuffer.Reset();
        BOMBuffer.SetRange(Type, BOMBuffer.Type::Item);
        BOMBuffer.SetRange("No.", ItemNo);
        BOMBuffer.FindFirst();

        // Validate: The BOM Tree record.
        Assert.AreNearlyEqual(QtyPerParent, BOMBuffer."Qty. per Parent", 0.00001, 'Wrong qty per parent for item ' + ItemNo);
        Assert.AreNearlyEqual(QtyPerTopItem, BOMBuffer."Qty. per Top Item", 0.00001, 'Wrong qty per top item for item ' + ItemNo);
        Assert.AreNearlyEqual(DirectAvailability, BOMBuffer."Available Quantity", 0.00001, 'Wrong avail. qty for item ' + ItemNo);

        if BOMBuffer."Available Quantity" + IndirectAvailability > 0 then
            AbleToMake := BOMBuffer."Available Quantity" + IndirectAvailability
        else
            AbleToMake := 0;

        Assert.AreNearlyEqual(
          AbleToMake / BOMBuffer."Qty. per Top Item", BOMBuffer."Able to Make Top Item", 0.00001,
          'Wrong able to make top item for Item ' + ItemNo);
        Assert.AreNearlyEqual(
          AbleToMake / BOMBuffer."Qty. per Parent", BOMBuffer."Able to Make Parent", 0.00001,
          'Wrong able to make parent for Item ' + ItemNo);
    end;

    [Normal]
    local procedure VerifyTopItem(var BOMBuffer: Record "BOM Buffer"; ItemNo: Code[20]; AvailableQty: Decimal; AbleToMake: Decimal; ShowTotalAvailability: Boolean)
    begin
        BOMBuffer.Reset();
        BOMBuffer.SetRange(Type, BOMBuffer.Type::Item);
        BOMBuffer.SetRange("No.", ItemNo);
        BOMBuffer.FindFirst();

        // Validate: The BOM Tree record.
        if AbleToMake < 0 then
            AbleToMake := 0;

        if not ShowTotalAvailability then
            AvailableQty := 0;

        Assert.AreEqual(1, BOMBuffer."Qty. per Parent", 'Wrong qty per parent for item ' + ItemNo);
        Assert.AreEqual(1, BOMBuffer."Qty. per Top Item", 'Wrong qty per top item for item ' + ItemNo);
        Assert.AreEqual(AvailableQty, BOMBuffer."Available Quantity", 'Wrong avail. qty for item ' + ItemNo);
        Assert.AreEqual(AbleToMake, BOMBuffer."Able to Make Top Item", 'Wrong able to make top item for Item ' + ItemNo);
        Assert.AreEqual(AbleToMake, BOMBuffer."Able to Make Parent", 'Wrong able to make parent for Item ' + ItemNo);
    end;

    local procedure VerifyItemInBomBuffer(ItemNo: Code[20])
    begin
        BOMBuffer.SetRange(Type, BOMBuffer.Type::Item);
        BOMBuffer.SetRange("No.", ItemNo);
        if BOMBuffer.IsEmpty() then
            Error(ItemErr, ItemNo);
    end;

    local procedure VerifyItemNotInBomBuffer(ItemNo: Code[20])
    begin
        BOMBuffer.SetRange(Type, BOMBuffer.Type::Item);
        BOMBuffer.SetRange("No.", ItemNo);
        Assert.IsTrue(BOMBuffer.IsEmpty, StrSubstNo(ItemNotExistErr, ItemNo))
    end;

    local procedure UpdateParentItemWithProdBomNo(var ParentItem: Record Item; ProductionBOMHeaderNo: Code[20])
    begin
        ParentItem.Validate("Production BOM No.", ProductionBOMHeaderNo);
        ParentItem.Modify(true);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure MessageHandler(Message: Text)
    begin
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure BOMLevelAbleToMakeHandler(var BOMLevelAbleToMake: TestPage "Item Availability by BOM Level")
    begin
        BOMLevelAbleToMake.First();
    end;
}

