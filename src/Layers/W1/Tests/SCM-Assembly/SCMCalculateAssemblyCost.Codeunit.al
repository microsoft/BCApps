// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Assembly.Document;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Vendor;
using System.Environment.Configuration;

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
        LibraryPurchase: Codeunit "Library - Purchase";
        WorkDate2: Date;
        TEXT_PARENT: Label 'Parent';
        TEXT_CHILD: Label 'Child';
        TEXT_ItemA: Label 'ItemA';
        AsmOverheadMissingErr: Label 'Assembly output should carry a manufacturing overhead.';
        ProdOverheadMissingErr: Label 'Production output should carry a manufacturing overhead.';
        AsmOverheadDriftedErr: Label 'Assembly manufacturing overhead drifted after recalculating the standard cost between cost adjustments.';
        AsmOverheadDriftedTwoDecimalErr: Label 'Assembly manufacturing overhead drifted for a two-decimal Indirect Cost percentage.';
        ProdOverheadAffectedErr: Label 'Production manufacturing overhead should not be affected by the assembly overhead recomputation.';
        Initialized: Boolean;
        GlobalVATBusPostingGroup: Code[20];
        GlobalVATProdPostingGroup: Code[20];

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

    [Test]
    procedure AsmStdOverheadStableAfterRecalcBetweenAdjmtsWithFractionalIndirectCost()
    var
        ComponentItem: Record Item;
        AssemblyItem: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OverheadBeforeCharge: Decimal;
        OverheadAfterCharge: Decimal;
    begin
        // [SCENARIO] A standard-cost assembly item with a fractional "Indirect Cost %" (more than two
        // decimals) keeps a stable manufacturing overhead when "Calc. Assembly Std. Cost" is re-run
        // between cost adjustments, so a later item charge on a component does not introduce a spurious
        // Manufacturing Overhead variance in the assembly output value entries.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] A standard-cost purchased component and a standard-cost assembly item with "Indirect Cost %" = 1.12345 and BOM quantity per = 10
        CreateStdCostAssemblyItemWithComponent(AssemblyItem, ComponentItem, 1.12345, 10);

        // [GIVEN] The component is received and invoiced (100 pcs at unit cost 1.00), cost adjusted and the assembly standard cost calculated
        PostPurchaseReceiptAndInvoice(ComponentItem."No.", 100, 1.0, PurchRcptLine);
        LibraryCosting.AdjustCostItemEntries(ComponentItem."No.", '');
        CalculateAssemblyStandardCost(AssemblyItem."No.");

        // [GIVEN] An assembly order for quantity 10 is posted and cost adjusted
        CreateAndPostAssemblyHeader(AssemblyItem."No.", 10, WorkDate2);
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');

        // [GIVEN] The manufacturing overhead of the assembly output after the first adjustment
        OverheadBeforeCharge := GetOutputMfgOverhead(AssemblyItem."No.", Enum::"Item Ledger Entry Type"::"Assembly Output");
        Assert.IsTrue(OverheadBeforeCharge > 0, AsmOverheadMissingErr);

        // [WHEN] An item charge is posted on the component receipt, the assembly standard cost is recalculated between the adjustments, and cost is adjusted again
        PostItemChargeOnReceipt(PurchRcptLine, 1.0);
        CalculateAssemblyStandardCost(AssemblyItem."No.");
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] The manufacturing overhead of the assembly output is unchanged (no spurious Manufacturing Overhead variance)
        OverheadAfterCharge := GetOutputMfgOverhead(AssemblyItem."No.", Enum::"Item Ledger Entry Type"::"Assembly Output");
        Assert.AreEqual(
          OverheadBeforeCharge, OverheadAfterCharge,
          AsmOverheadDriftedErr);
    end;

    [Test]
    procedure AsmStdOverheadStableWithTwoDecimalIndirectCost()
    var
        ComponentItem: Record Item;
        AssemblyItem: Record Item;
        PurchRcptLine: Record "Purch. Rcpt. Line";
        OverheadBeforeCharge: Decimal;
        OverheadAfterCharge: Decimal;
    begin
        // [SCENARIO] The same recalculate-between-adjustments flow with an "Indirect Cost %" that has at
        // most two decimals stays correct: the clean case keeps a stable manufacturing overhead and the
        // fix does not alter it.
        Initialize();
        LibraryInventory.SetAutomaticCostPosting(false);

        // [GIVEN] A standard-cost purchased component and a standard-cost assembly item with "Indirect Cost %" = 1.00 and BOM quantity per = 10
        CreateStdCostAssemblyItemWithComponent(AssemblyItem, ComponentItem, 1.0, 10);

        // [GIVEN] The component is received and invoiced (100 pcs at unit cost 1.00), cost adjusted and the assembly standard cost calculated
        PostPurchaseReceiptAndInvoice(ComponentItem."No.", 100, 1.0, PurchRcptLine);
        LibraryCosting.AdjustCostItemEntries(ComponentItem."No.", '');
        CalculateAssemblyStandardCost(AssemblyItem."No.");

        // [GIVEN] An assembly order for quantity 10 is posted and cost adjusted
        CreateAndPostAssemblyHeader(AssemblyItem."No.", 10, WorkDate2);
        LibraryCosting.AdjustCostItemEntries(AssemblyItem."No.", '');

        // [GIVEN] The manufacturing overhead of the assembly output after the first adjustment
        OverheadBeforeCharge := GetOutputMfgOverhead(AssemblyItem."No.", Enum::"Item Ledger Entry Type"::"Assembly Output");
        Assert.IsTrue(OverheadBeforeCharge > 0, AsmOverheadMissingErr);

        // [WHEN] An item charge is posted on the component receipt, the assembly standard cost is recalculated between the adjustments, and cost is adjusted again
        PostItemChargeOnReceipt(PurchRcptLine, 1.0);
        CalculateAssemblyStandardCost(AssemblyItem."No.");
        LibraryCosting.AdjustCostItemEntries('', '');

        // [THEN] The manufacturing overhead of the assembly output is unchanged
        OverheadAfterCharge := GetOutputMfgOverhead(AssemblyItem."No.", Enum::"Item Ledger Entry Type"::"Assembly Output");
        Assert.AreEqual(
          OverheadBeforeCharge, OverheadAfterCharge,
          AsmOverheadDriftedTwoDecimalErr);
    end;

    [Test]
    procedure ProdOrderStdOverheadUnaffectedByAssemblyBranch()
    var
        ComponentItem: Record Item;
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        OverheadBeforeRecalc: Decimal;
        OverheadAfterRecalc: Decimal;
    begin
        // [SCENARIO] A standard-cost production item with a fractional "Indirect Cost %" is not affected
        // by the assembly-only overhead recomputation: re-running "Calculate Standard Cost" (the same flow
        // that runs the assembly overhead branch) keeps the production item's single-level manufacturing
        // overhead cost share stable.
        Initialize();

        // [GIVEN] A standard-cost component with a standard cost of 1.00
        CreateItem(ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Purchase, 1.0);

        // [GIVEN] A standard-cost production item with "Indirect Cost %" = 1.12345 and a certified production BOM (quantity per = 10)
        CreateItem(ProdItem, ProdItem."Costing Method"::Standard, ProdItem."Replenishment System"::"Prod. Order", 0);
        ProdItem.Validate("Indirect Cost %", 1.12345);
        ProdItem.Modify(true);
        LibraryManufacturing.CreateCertifiedProductionBOM(ProductionBOMHeader, ComponentItem."No.", 10);
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [GIVEN] The standard cost is calculated, giving the production item a manufacturing overhead cost share
        CalculateProdStandardCost(ProdItem."No.");
        ProdItem.Get(ProdItem."No.");
        OverheadBeforeRecalc := ProdItem."Single-Level Mfg. Ovhd Cost";
        Assert.IsTrue(OverheadBeforeRecalc > 0, ProdOverheadMissingErr);

        // [WHEN] The standard cost is recalculated (the same flow that also runs the assembly overhead branch)
        CalculateProdStandardCost(ProdItem."No.");

        // [THEN] The production item's manufacturing overhead cost share is unchanged (the assembly-only branch does not run for production)
        ProdItem.Get(ProdItem."No.");
        OverheadAfterRecalc := ProdItem."Single-Level Mfg. Ovhd Cost";
        Assert.AreEqual(
          OverheadBeforeRecalc, OverheadAfterRecalc,
          ProdOverheadAffectedErr);
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

    local procedure CalculateProdStandardCost(ItemNo: Code[20])
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        CalculateStdCost: Codeunit "Calculate Standard Cost";
        ItemCostMgt: Codeunit ItemCostManagement;
    begin
        Item.SetRange("No.", ItemNo);
        CalculateStdCost.SetProperties(WorkDate2, true, false, false, '', false);
        CalculateStdCost.CalcItems(Item, TempItem);
        if TempItem.FindSet() then
            repeat
                ItemCostMgt.UpdateStdCostShares(TempItem);
            until TempItem.Next() = 0;
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
        Item.Validate("VAT Prod. Posting Group", GetSharedVATProdPostingGroup());
        Item.Validate("Standard Cost", StandardCostAmt);
        Item.Modify(true);
        EnsureGeneralPostingSetup(Item."Gen. Prod. Posting Group");
    end;

    local procedure EnsureGeneralPostingSetup(GenProdPostingGroup: Code[20])
    var
        GeneralPostingSetup: Record "General Posting Setup";
        TemplateGeneralPostingSetup: Record "General Posting Setup";
    begin
        if GeneralPostingSetup.Get('', GenProdPostingGroup) and
           (GeneralPostingSetup."Inventory Adjmt. Account" <> '') and
           (GeneralPostingSetup."Overhead Applied Account" <> '')
        then
            exit;

        // Copy all accounts from an existing, fully configured General Posting Setup so the created
        // combination is valid for inventory posting to G/L (e.g. Inventory Adjmt. Account and
        // Overhead Applied Account, which are required when posting manufacturing overhead).
        TemplateGeneralPostingSetup.SetFilter("Inventory Adjmt. Account", '<>%1', '');
        TemplateGeneralPostingSetup.SetFilter("Overhead Applied Account", '<>%1', '');
        TemplateGeneralPostingSetup.FindFirst();

        if not GeneralPostingSetup.Get('', GenProdPostingGroup) then begin
            GeneralPostingSetup := TemplateGeneralPostingSetup;
            GeneralPostingSetup."Gen. Bus. Posting Group" := '';
            GeneralPostingSetup."Gen. Prod. Posting Group" := GenProdPostingGroup;
            GeneralPostingSetup.Insert();
        end else begin
            TemplateGeneralPostingSetup."Gen. Bus. Posting Group" := GeneralPostingSetup."Gen. Bus. Posting Group";
            TemplateGeneralPostingSetup."Gen. Prod. Posting Group" := GeneralPostingSetup."Gen. Prod. Posting Group";
            GeneralPostingSetup := TemplateGeneralPostingSetup;
            GeneralPostingSetup.Modify();
        end;
    end;

    local procedure CreateStdCostAssemblyItemWithComponent(var AssemblyItem: Record Item; var ComponentItem: Record Item; IndirectCostPct: Decimal; QtyPer: Decimal)
    begin
        CreateItem(ComponentItem, ComponentItem."Costing Method"::Standard, ComponentItem."Replenishment System"::Purchase, 1.0);
        CreateItem(AssemblyItem, AssemblyItem."Costing Method"::Standard, AssemblyItem."Replenishment System"::Assembly, 0);
        AssemblyItem.Validate("Indirect Cost %", IndirectCostPct);
        AssemblyItem.Modify(true);
        CreateAssemblyListComponent(AssemblyItem."No.", ComponentItem."No.", QtyPer);
    end;

    local procedure PostPurchaseReceiptAndInvoice(ItemNo: Code[20]; Qty: Decimal; UnitCost: Decimal; var PurchRcptLine: Record "Purch. Rcpt. Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Order, CreateVendorWithSharedVAT());
        LibraryPurchase.CreatePurchaseLineWithUnitCost(PurchaseLine, PurchaseHeader, ItemNo, UnitCost, Qty);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        PurchRcptLine.SetRange("Order No.", PurchaseHeader."No.");
        PurchRcptLine.SetRange("No.", ItemNo);
        PurchRcptLine.FindFirst();
    end;

    local procedure PostItemChargeOnReceipt(PurchRcptLine: Record "Purch. Rcpt. Line"; ChargeAmount: Decimal)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        ItemCharge: Record "Item Charge";
    begin
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, PurchRcptLine."Buy-from Vendor No.");
        LibraryPurchase.CreateItemChargePurchaseLine(PurchaseLine, ItemCharge, PurchaseHeader, 1, ChargeAmount);
        PurchaseLine.Validate("VAT Prod. Posting Group", GetSharedVATProdPostingGroup());
        PurchaseLine.Modify(true);
        LibraryCosting.AssignItemChargePurch(PurchaseLine, PurchRcptLine);
        LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);
    end;

    local procedure CreateVendorWithSharedVAT(): Code[20]
    var
        Vendor: Record Vendor;
    begin
        LibraryPurchase.CreateVendor(Vendor);
        Vendor.Validate("VAT Bus. Posting Group", GetSharedVATBusPostingGroup());
        Vendor.Modify(true);
        exit(Vendor."No.");
    end;

    local procedure GetSharedVATBusPostingGroup(): Code[20]
    begin
        EnsureSharedVATPostingSetup();
        exit(GlobalVATBusPostingGroup);
    end;

    local procedure GetSharedVATProdPostingGroup(): Code[20]
    begin
        EnsureSharedVATPostingSetup();
        exit(GlobalVATProdPostingGroup);
    end;

    local procedure EnsureSharedVATPostingSetup()
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        // Create a single, fully configured 0% VAT Posting Setup and share its VAT Bus./Prod. Posting
        // Groups across the created items, vendor and item charge so purchase posting has a valid VAT
        // Posting Setup in every localization (e.g. the VAT combination is not present in demo data).
        if (GlobalVATProdPostingGroup <> '') and VATPostingSetup.Get(GlobalVATBusPostingGroup, GlobalVATProdPostingGroup) then
            exit;

        LibraryERM.CreateVATPostingSetupWithAccounts(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT", 0);
        GlobalVATBusPostingGroup := VATPostingSetup."VAT Bus. Posting Group";
        GlobalVATProdPostingGroup := VATPostingSetup."VAT Prod. Posting Group";
    end;

    local procedure GetOutputMfgOverhead(ItemNo: Code[20]; OutputEntryType: Enum "Item Ledger Entry Type"): Decimal
    var
        ValueEntry: Record "Value Entry";
        TotalOverhead: Decimal;
    begin
        ValueEntry.SetRange("Item No.", ItemNo);
        ValueEntry.SetRange("Item Ledger Entry Type", OutputEntryType);
        if ValueEntry.FindSet() then
            repeat
                if (ValueEntry."Entry Type" = ValueEntry."Entry Type"::"Indirect Cost") or
                   ((ValueEntry."Entry Type" = ValueEntry."Entry Type"::Variance) and
                    (ValueEntry."Variance Type" = ValueEntry."Variance Type"::"Manufacturing Overhead"))
                then
                    TotalOverhead += ValueEntry."Cost Amount (Actual)";
            until ValueEntry.Next() = 0;
        exit(TotalOverhead);
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

