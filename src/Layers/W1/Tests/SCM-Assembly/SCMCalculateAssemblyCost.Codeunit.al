// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using System.Environment.Configuration;
using Microsoft.Assembly.Document;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Inventory.Journal;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.Setup;

codeunit 137911 "SCM Calculate Assembly Cost"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        WorkDate2 := LibraryPlanning.SetSafetyWorkDate();
    end;

    var
        LibraryKitting: Codeunit "Library - Kitting";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryCosting: Codeunit "Library - Costing";
        LibraryERM: Codeunit "Library - ERM";
        LibraryPlanning: Codeunit "Library - Planning";
        LibraryRandom: Codeunit "Library - Random";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        NotificationLifecycleMgt: Codeunit "Notification Lifecycle Mgt.";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        WorkDate2: Date;
        TEXT_PARENT: Label 'Parent';
        TEXT_CHILD: Label 'Child';
        TEXT_ItemA: Label 'ItemA';
        Initialized: Boolean;

    [Test]
    [Scope('OnPrem')]
    procedure BUG235189()
    var
        ParentItem: Record Item;
        ChildItem: Record Item;
        ItemVariant: Record "Item Variant";
        StockkeepingUnit: Record "Stockkeeping Unit";
        AsmHeader: Record "Assembly Header";
        BomComponent: Record "BOM Component";
        Variant: Code[10];
        VArCost: Decimal;
    begin
        Initialize();
        // Kitting - D2: Cost amount is not updated when using SKU unit cost
        Variant := '1';
        VArCost := 20;
        ParentItem.Get(LibraryKitting.CreateStdCostItemWithNewUOMUsingItemNo(TEXT_PARENT, 10, 20, 1));
        ChildItem.Get(LibraryKitting.CreateStdCostItemWithNewUOMUsingItemNo(TEXT_CHILD, 10, 20, 1));
        LibraryInventory.CreateBOMComponent(
          BomComponent, ParentItem."No.", BomComponent.Type::Item, ChildItem."No.", 1, ChildItem."Base Unit of Measure");
        ParentItem.Validate("Replenishment System", ParentItem."Replenishment System"::Assembly);
        ParentItem.Modify();
        CalculateAssemblyStandardCost(ParentItem."No.");
        ValidateUnitCost(ParentItem."No.", 10);

        CalculateAssemblyStandardCost(ParentItem."No.");

        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ParentItem."No.", 1));

        ItemVariant.Init();
        ItemVariant."Item No." := ParentItem."No.";
        ItemVariant.Code := Variant;
        if not ItemVariant.Insert() then
            ItemVariant.Modify();

        StockkeepingUnit.Init();
        StockkeepingUnit."Item No." := ParentItem."No.";
        StockkeepingUnit."Variant Code" := Variant;
        StockkeepingUnit."Location Code" := AsmHeader."Location Code";
        StockkeepingUnit."Standard Cost" := VArCost;
        StockkeepingUnit."Unit Cost" := VArCost;
        if not StockkeepingUnit.Insert() then
            StockkeepingUnit.Modify();

        AsmHeader.Validate("Variant Code", Variant);

        ValidateHeaderCostAmount(AsmHeader, 20);
        NotificationLifecycleMgt.RecallAllNotifications();

        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderForAwithA()
    var
        BOMComponent: Record "BOM Component";
        AsmHeader: Record "Assembly Header";
        ItemA: Record Item;
        ItemB: Record Item;
        ItemC: Record Item;
        LibraryKitting: Codeunit "Library - Kitting";
    begin
        Initialize();
        ItemA.Get(LibraryKitting.CreateStdCostItemWithNewUOMUsingItemNo(TEXT_ItemA, 10, 20, 1));
        ItemB.Get(LibraryKitting.CreateItemWithNewUOM(7, 10));
        ItemC.Get(LibraryKitting.CreateItemWithNewUOM(13, 10));
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemA."No.", BOMComponent.Type::Item, ItemB."No.", 1, ItemB."Base Unit of Measure");
        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemA."No.", BOMComponent.Type::Item, ItemC."No.", 1, ItemC."Base Unit of Measure");
        ItemA.Validate("Replenishment System", ItemA."Replenishment System"::Assembly);
        ItemA.Modify();
        CalculateAssemblyStandardCost(ItemA."No.");
        ItemA.Get(ItemA."No.");
        Assert.AreEqual(ItemA."Standard Cost", 20,
          StrSubstNo('Standard cost is wrong for %1, Expected 20 got %2', ItemA."No.", ItemA."Standard Cost"));
        ValidateUnitCost(ItemA."No.", 20);

        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ItemA."No.", 1));
        LibraryKitting.AddLine(AsmHeader, "BOM Component Type"::Item, ItemA."No.", ItemA."Base Unit of Measure", 1, 1, '');
        calcAndValidate(AsmHeader, 40, 0, 0, 0);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OrderForAwithOverhead()
    var
        BOMComponent: Record "BOM Component";
        AsmHeader: Record "Assembly Header";
        ItemA: Record Item;
        ItemB: Record Item;
    begin
        Initialize();
        ItemA.Get(LibraryKitting.CreateStdCostItemWithNewUOMUsingItemNo(TEXT_ItemA, 10, 20, 1));
        ItemB.Get(LibraryKitting.CreateItemWithNewUOM(7, 10));
        ItemB."Overhead Rate" := 10;
        ItemB.Modify();

        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemA."No.", BOMComponent.Type::Item, ItemB."No.", 1, ItemB."Base Unit of Measure");
        ItemA.Validate("Replenishment System", ItemA."Replenishment System"::Assembly);
        ItemA."Overhead Rate" := 12;
        ItemA.Modify();

        CalculateAssemblyStandardCost(ItemA."No.");
        ItemA.Get(ItemA."No.");

        ValidateStandardCost(ItemA."No.", 19);
        ValidateUnitCost(ItemA."No.", 19);

        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ItemA."No.", 1));
        calcAndValidate(AsmHeader, 7, 0, 0, 12);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG206865AwithIndirectCost()
    var
        BOMComponent: Record "BOM Component";
        AsmHeader: Record "Assembly Header";
        ItemA: Record Item;
        ItemB: Record Item;
    begin
        Initialize();
        ItemA.Get(LibraryKitting.CreateStdCostItemWithNewUOMUsingItemNo(TEXT_ItemA, 10, 20, 1));
        ItemB.Get(LibraryKitting.CreateItemWithNewUOM(10, 10));
        ItemB.Modify();

        LibraryInventory.CreateBOMComponent(
          BOMComponent, ItemA."No.", BOMComponent.Type::Item, ItemB."No.", 1, ItemB."Base Unit of Measure");
        ItemA.Validate("Replenishment System", ItemA."Replenishment System"::Assembly);
        ItemA."Overhead Rate" := 4;
        ItemA."Indirect Cost %" := 10;
        ItemA.Modify();

        CalculateAssemblyStandardCost(ItemA."No.");
        ItemA.Get(ItemA."No.");

        ValidateStandardCost(ItemA."No.", 15);
        ValidateUnitCost(ItemA."No.", 15);

        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, ItemA."No.", 1));
        calcAndValidate(AsmHeader, 10, 0, 0, 5);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EmptyOrder()
    var
        AsmHeader: Record "Assembly Header";
    begin
        Initialize();
        AsmHeader.Get(AsmHeader."Document Type"::Order,
          LibraryKitting.CreateOrder(WorkDate2, LibraryKitting.CreateItemWithLotAndNewUOM(500, 700, 1), 1));
        calcAndValidate(AsmHeader, 0, 0, 0, 0);
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneRegularItem()
    var
        parentItem: Record Item;
        childItem: Record Item;
        AsmHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(50, 70));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(3, 4));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Item, childItem."No.", 5, childItem."Base Unit of Measure", false);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        calcAndValidate(AsmHeader, 1 * 5 * 3, 0, 0, 0);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResourceFixed()
    var
        parentItem: Record Item;
        resource: Record Resource;
        AsmHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(50, 70));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(17, 20));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Resource, resource."No.", 2, resource."Base Unit of Measure", true);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 4));
        calcAndValidate(AsmHeader, 0, 0, 2 * 17, 0); // everything ends up as resource overhead...
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneResource()
    var
        parentItem: Record Item;
        resource: Record Resource;
        AsmHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(50, 70));
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(17, 20));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Resource, resource."No.", 2, resource."Base Unit of Measure", false);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 4));
        calcAndValidate(AsmHeader, 0, 0, 4 * 2 * 17, 0); // everything ends up as resource overhead...
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure MultipleLinesRegularItems()
    var
        parentItem: Record Item;
        childItem: Record Item;
        AsmHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(50, 70));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(3, 4));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Item, childItem."No.", 5, childItem."Base Unit of Measure", false);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(10, 13));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Item, childItem."No.", 7, childItem."Base Unit of Measure", false);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(200, 280));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Item, childItem."No.", 2, childItem."Base Unit of Measure", false);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        calcAndValidate(AsmHeader, 1 * (5 * 3 + 7 * 10 + 2 * 200), 0, 0, 0);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneAssemblyItem()
    var
        parentItem: Record Item;
        childResource: Record Resource;
        childItem: Record Item;
        BOMcomponentItem: Record Item;
        AsmHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        BOMcomponentItem.Get(LibraryKitting.CreateItemWithNewUOM(5, 7));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(10, 12));
        LibraryKitting.CreateBOMComponentLine(
          BOMcomponentItem, BOMComponent.Type::Item, childItem."No.", 245, childItem."Base Unit of Measure", false);
        childResource.Get(LibraryKitting.CreateResourceWithNewUOM(17, 20));
        LibraryKitting.CreateBOMComponentLine(
          BOMcomponentItem, BOMComponent.Type::Resource, childResource."No.", 5, childResource."Base Unit of Measure", true);
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(50, 70));
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Item, BOMcomponentItem."No.", 6, BOMcomponentItem."Base Unit of Measure", false);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 11));
        calcAndValidate(AsmHeader, 11 * 6 * 5, 0, 0, 0);// 11*6*245*10,0,11*6*5*17);
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneNestedAssemblyItem()
    var
        parentItem: Record Item;
        childItem: Record Item;
        childResource: Record Resource;
        BOMcomponentItem: Record Item;
        subBOMComponentItem: Record Item;
        AsmHeader: Record "Assembly Header";
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        BOMcomponentItem.Get(LibraryKitting.CreateItemWithNewUOM(5, 7));
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(10, 12));
        LibraryKitting.CreateBOMComponentLine(BOMcomponentItem, BOMComponent.Type::Item, childItem."No.",
          245, childItem."Base Unit of Measure", false);
        childResource.Get(LibraryKitting.CreateResourceWithNewUOM(17, 20));
        LibraryKitting.CreateBOMComponentLine(BOMcomponentItem, BOMComponent.Type::Resource, childResource."No.",
          5, childResource."Base Unit of Measure", true);
        subBOMComponentItem.Get(LibraryKitting.CreateItemWithNewUOM(20, 18));
        childResource.Get(LibraryKitting.CreateResourceWithNewUOM(1200, 1600));
        LibraryKitting.CreateBOMComponentLine(subBOMComponentItem, BOMComponent.Type::Resource, childResource."No.",
          1.5, childResource."Base Unit of Measure", true);
        childItem.Get(LibraryKitting.CreateItemWithNewUOM(73, 99));
        LibraryKitting.CreateBOMComponentLine(subBOMComponentItem, BOMComponent.Type::Item, childItem."No.",
          19, childItem."Base Unit of Measure", false);
        LibraryKitting.CreateBOMComponentLine(BOMcomponentItem, BOMComponent.Type::Item, subBOMComponentItem."No.",
          66, subBOMComponentItem."Base Unit of Measure", false);
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(50, 70));
        LibraryKitting.CreateBOMComponentLine(parentItem, BOMComponent.Type::Item, BOMcomponentItem."No.",
          3, BOMcomponentItem."Base Unit of Measure", false);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 150));
        calcAndValidate(AsmHeader, 150 * 3 * 5, 0, 0, 0); // 150*3*(245*10+66*19*73),0,150*3*(5*17+66*1.5*1200));
        NotificationLifecycleMgt.RecallAllNotifications();
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG206635OverheadTwice()
    var
        parentItem: Record Item;
        AsmHeader: Record "Assembly Header";
        resource: Record Resource;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(5, 7));
        parentItem.Validate("Costing Method", parentItem."Costing Method"::Average);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(10, 20));
        resource.Validate("Direct Unit Cost", 8);
        resource.Validate("Unit Cost", 10);
        resource.Modify();
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Resource, resource."No.", 10, resource."Base Unit of Measure", true);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        AsmHeader.UpdateUnitCost();
        Assert.AreEqual(100, AsmHeader."Cost Amount",
          StrSubstNo('Order Cost amount is wrong, expected %1 got %2', 100, AsmHeader."Cost Amount"))
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BUG236628Overheadmissiningsum()
    var
        parentItem: Record Item;
        AsmHeader: Record "Assembly Header";
        resource: Record Resource;
        BOMComponent: Record "BOM Component";
    begin
        Initialize();
        // Resource Overhead is not summed up in Statistics
        parentItem.Get(LibraryKitting.CreateItemWithNewUOM(5, 7));
        parentItem.Validate("Costing Method", parentItem."Costing Method"::Average);
        resource.Get(LibraryKitting.CreateResourceWithNewUOM(10, 20));
        resource.Validate("Direct Unit Cost", 10);
        resource.Validate("Unit Cost", 15);
        resource.Modify();
        LibraryKitting.CreateBOMComponentLine(
          parentItem, BOMComponent.Type::Resource, resource."No.", 1, resource."Base Unit of Measure", true);
        AsmHeader.Get(AsmHeader."Document Type"::Order, LibraryKitting.CreateOrder(WorkDate2, parentItem."No.", 1));
        calcAndValidate(AsmHeader, 0, 10, 5, 0);
        asserterror Error('') // cleanup
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyOutputCostACY()
    var
        ComponentItem: Record Item;
        AssemblyItem: Record Item;
        ItemLedgerEntry: Record "Item Ledger Entry";
        CurrExchRate: Decimal;
    begin
        // [FEATURE] [ACY]
        // [SCENARIO 382120] Assembly output cost should be posted in both local currency and additional reporting currency when ACY is configured

        Initialize();
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Set additional reporting currency with exchange rate = "X"
        CurrExchRate := UpdateACYCode();

        // [GIVEN] Create an assembled item "I" with one component. Standard cost of the component is "C"
        CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard, AssemblyItem."Replenishment System"::Assembly, 0);
        CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Purchase,
          LibraryRandom.RandDecInRange(100, 200, 2));

        PostPositiveAdjustment(ComponentItem."No.", 1);
        CreateAssemblyListComponent(AssemblyItem."No.", ComponentItem."No.", 1);

        // [GIVEN] Calculate standard cost for item "I"
        CalculateAssemblyStandardCost(AssemblyItem."No.");

        // [GIVEN] Create and post assembly order for item "I"
        CreateAndPostAssemblyHeader(AssemblyItem."No.", 1, WorkDate2);

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');

        // [THEN] Assembly output entry has "Cost Amount (Actual)" = "C", "Cost Amount (Actual) (ACY)" = "C" * "X"
        VerifyOutputCostAmount(
          AssemblyItem."No.", ItemLedgerEntry."Entry Type"::"Assembly Output",
          ComponentItem."Standard Cost", ComponentItem."Standard Cost" * CurrExchRate);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure VerifyAdjustCostItemEntriesMustBeExecutedForAssemblyItem()
    var
        AssemblyItem, ComponentItem, NonInvItem : Record Item;
        ValueEntry: Record "Value Entry";
    begin
        // [SCENARIO 574360] Verify "Adjust Cost - Item Entries" must be executed for Assembly item which include non-Inventory item in Assembly BOM.
        // When "Automatic Cost Posting" is false in Inventory Setup and "Inc. Non. Inv. Cost To Prod" is true in Mfg Setup.
        Initialize();

        // [GIVEN] Set Automatic Cost Posting to false.
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] Update "Inc. Non. Inv. Cost To Prod" in Manufacturing Setup.
        LibraryManufacturing.UpdateNonInventoryCostToProductionInManufacturingSetup(true);

        // [GIVEN] Create an Assembled item with "Costing Method"::Standard.
        CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard, AssemblyItem."Replenishment System"::Assembly, 0);

        // [GIVEN] Create an Component item with "Costing Method"::FIFO.
        CreateItem(ComponentItem, ComponentItem."Costing Method"::FIFO, ComponentItem."Replenishment System"::Purchase, LibraryRandom.RandIntInRange(100, 200));

        // [GIVEN] Create Non-Inventory item with Unit Cost.
        LibraryInventory.CreateNonInventoryTypeItem(NonInvItem);
        NonInvItem.Validate("Unit Cost", LibraryRandom.RandIntInRange(200, 500));
        NonInvItem.Modify();

        // [GIVEN] Post Positive Adjustment for Component item.
        PostPositiveAdjustment(ComponentItem."No.", LibraryRandom.RandIntInRange(200, 500));

        // [GIVEN] Create Assembly List for Component and Non-Inventory item.
        CreateAssemblyListComponent(AssemblyItem."No.", ComponentItem."No.", 1);
        CreateAssemblyListComponent(AssemblyItem."No.", NonInvItem."No.", 1);

        // [GIVEN] Create and post Assembly Order.
        CreateAndPostAssemblyHeader(AssemblyItem."No.", 1, WorkDate());

        // [WHEN] Run "Adjust Cost - Item Entries"
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');

        // [THEN] Verify "Adjust Cost - Item Entries" must be executed for Assembly item.
        ValueEntry.SetRange("Item Ledger Entry Type", ValueEntry."Item Ledger Entry Type"::"Assembly Output");
        ValueEntry.SetRange("Entry Type", ValueEntry."Entry Type"::"Direct Cost - Non Inventory");
        ValueEntry.SetRange("Item No.", AssemblyItem."No.");
        Assert.RecordCount(ValueEntry, 0);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Calculate Assembly Cost");
        LibrarySetupStorage.Restore();

        if Initialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Calculate Assembly Cost");

        Initialized := true;
        Commit();

        LibrarySetupStorage.Save(DATABASE::"General Ledger Setup");
        LibrarySetupStorage.Save(DATABASE::"Inventory Setup");
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Calculate Assembly Cost");
    end;

    local procedure calcAndValidate(var AsmHeader: Record "Assembly Header"; materialCost: Decimal; resourceCost: Decimal; resourceOverheadCost: Decimal; AssemblyOverhead: Decimal)
    var
        calcStdCost: Codeunit "Calculate Standard Cost";
        ExpCost: array[5] of Decimal;
        RowIdx: Option ,MatCost,ResCost,ResOvhd,AsmOvhd,Total;
    begin
        calcStdCost.CalculateAssemblyCostExp(AsmHeader, ExpCost);

        Assert.IsFalse(
          (ExpCost[RowIdx::MatCost] <> materialCost) or
          (ExpCost[RowIdx::ResCost] <> resourceCost) or
          (ExpCost[RowIdx::AsmOvhd] <> AssemblyOverhead) or
          (ExpCost[RowIdx::ResOvhd] <> resourceOverheadCost),
          StrSubstNo('Unexpected costs [Material x Resource x Resource Overhead x Overhead] calculated. ' +
            'Expected: [%1 x %2 x %3 x %4], got: [%5 x %6 x %7 x %8]',
            materialCost, resourceCost, resourceOverheadCost, AssemblyOverhead,
            ExpCost[RowIdx::MatCost], ExpCost[RowIdx::ResCost], ExpCost[RowIdx::ResOvhd], ExpCost[RowIdx::AsmOvhd]))
    end;

    local procedure CalculateAssemblyStandardCost(ItemNo: Code[20])
    var
        CalculateStdCost: Codeunit "Calculate Standard Cost";
    begin
        CalculateStdCost.CalcItem(ItemNo, true);
    end;

    local procedure CreateAndPostAssemblyHeader(ItemNo: Code[20]; Qty: Decimal; DueDate: Date)
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        LibraryAssembly.CreateAssemblyHeader(AssemblyHeader, DueDate, ItemNo, '', Qty, '');
        LibraryAssembly.PostAssemblyHeader(AssemblyHeader, '');
    end;

    local procedure CreateAssemblyListComponent(AssemblyItemNo: Code[20]; ComponentItemNo: Code[20]; QtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateAssemblyListComponent(BOMComponent.Type::Item, ComponentItemNo, AssemblyItemNo, '', 0, QtyPer, true);
    end;

    local procedure CreateItem(var Item: Record Item; CostingMethod: Enum "Costing Method"; ReplenishmentSystem: Enum "Replenishment System"; StandardCostAmt: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", CostingMethod);
        Item.Validate("Replenishment System", ReplenishmentSystem);
        Item.Validate("Standard Cost", StandardCostAmt);
        Item.Modify(true);
    end;

    local procedure PostPositiveAdjustment(ItemNo: Code[20]; Qty: Decimal)
    var
        ItemJournalTemplate: Record "Item Journal Template";
        ItemJournalBatch: Record "Item Journal Batch";
        ItemJournalLine: Record "Item Journal Line";
    begin
        LibraryInventory.SelectItemJournalTemplateName(ItemJournalTemplate, ItemJournalTemplate.Type::Item);
        LibraryInventory.SelectItemJournalBatchName(ItemJournalBatch, ItemJournalTemplate.Type::Item, ItemJournalTemplate.Name);
        LibraryInventory.CreateItemJournalLine(
          ItemJournalLine, ItemJournalTemplate.Name, ItemJournalBatch.Name, ItemJournalLine."Entry Type"::"Positive Adjmt.", ItemNo, Qty);
        LibraryInventory.PostItemJournalLine(ItemJournalTemplate.Name, ItemJournalBatch.Name);
    end;

    local procedure UpdateACYCode(): Decimal
    var
        Currency: Record Currency;
        CurrExchRate: Decimal;
    begin
        LibraryERM.CreateCurrency(Currency);
        CurrExchRate := LibraryRandom.RandDecInRange(10, 20, 2);
        LibraryERM.CreateExchangeRate(Currency.Code, WorkDate(), CurrExchRate, CurrExchRate);
        LibraryERM.SetAddReportingCurrency(Currency.Code);

        exit(CurrExchRate);
    end;

    local procedure ValidateHeaderCostAmount(AsmHeader: Record "Assembly Header"; Expected: Decimal)
    begin
        Assert.AreEqual(Expected, AsmHeader."Cost Amount",
              StrSubstNo('Item %1 Unitcost is %2 expected %3', AsmHeader."No.", AsmHeader."Cost Amount", Expected));
    end;

    local procedure ValidateStandardCost(ItemNo: Code[20]; Expected: Decimal)
    var
        TestItem: Record Item;
    begin
        TestItem.Get(ItemNo);
        Assert.AreEqual(TestItem."Standard Cost", Expected,
          StrSubstNo('Standard cost is wrong for %1, Expected %2 got %3', TestItem."No.", Expected, TestItem."Standard Cost"))
    end;

    local procedure ValidateUnitCost(ItemNo: Code[20]; Expected: Decimal)
    var
        TestItem: Record Item;
    begin
        TestItem.Get(ItemNo);
        Assert.AreEqual(Expected, TestItem."Unit Cost",
          StrSubstNo('Item %1 Unitcost is %2 expected %3', TestItem."No.", TestItem."Unit Cost", Expected));
    end;

    local procedure VerifyOutputCostAmount(ItemNo: Code[20]; EntryType: Enum "Item Ledger Document Type"; ExpectedCostLCY: Decimal; ExpectedCostACY: Decimal)
    var
        ItemLedgerEntry: Record "Item Ledger Entry";
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        Currency.Get(GeneralLedgerSetup."Additional Reporting Currency");

        ItemLedgerEntry.SetRange("Item No.", ItemNo);
        ItemLedgerEntry.SetRange("Entry Type", EntryType);
        ItemLedgerEntry.FindFirst();
        ItemLedgerEntry.CalcFields("Cost Amount (Actual)", "Cost Amount (Actual) (ACY)");
        ItemLedgerEntry.TestField("Cost Amount (Actual)", ExpectedCostLCY);
        ItemLedgerEntry.TestField("Cost Amount (Actual) (ACY)", Round(ExpectedCostACY, Currency."Amount Rounding Precision"));
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
    end;
}

