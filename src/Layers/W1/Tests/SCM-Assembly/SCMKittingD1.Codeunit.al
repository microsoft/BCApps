// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Projects.Resources.Resource;

codeunit 137090 "SCM Kitting - D1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [SCM]
        isInitialized := false;
    end;

    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryAssembly: Codeunit "Library - Assembly";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryRandom: Codeunit "Library - Random";
        LibraryUtility: Codeunit "Library - Utility";
        ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards";
        StdCostLevel: Integer;
        isInitialized: Boolean;
        ErrorNoAssemblyList: Label 'Item %1 %2 has no assembly list. The %3 will not be calculated.';
        ErrorItemNotAssembled: Label 'Item %1 %2 does not use replenishment system Assembly. The %3 will not be calculated.';
        ErrorCyclicalKit: Label 'You cannot insert item %1 as an assembly component of itself.';
        ErrorWrongType: Label 'Type must be equal to ''Item''  in BOM Component: Parent Item No.';
        StdCostRollupMessage: Label 'Select All levels to include and update the ';
        ReplMethodMessage: Label 'use replenishment system Prod. Order. Do you want to calculate standard cost for those subassemblies?';

    [Normal]
    local procedure Initialize()
    var
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - D1");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - D1");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - D1");
    end;

    [Normal]
    local procedure StdCostPriceRollup(UseBaseUoM: Boolean; NoOfItems: Integer; NoOfResources: Integer; NoOfTexts: Integer; QtyPerFactor: Integer)
    var
        Item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", UseBaseUoM,
          NoOfItems, NoOfResources, NoOfTexts, QtyPerFactor, '', '');

        StdCostLevel := 1;
        // Exercise.
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate.
        Item.Get(Item."No.");
        Item.CalcFields("Assembly BOM");
        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item."No."),
          Item."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item."No.");
        Assert.AreNearlyEqual(MaterialCost, Item."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap Cost');
        Assert.AreNearlyEqual(CapOverhead, Item."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap Overhead');
        Assert.AreNearlyEqual(CapOverhead, Item."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item."No."), Item."Unit Price", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong unit price for:' + Item."No.");
        Assert.AreEqual(NoOfItems + NoOfResources + NoOfTexts > 0, Item."Assembly BOM", 'Wrong Assembly BOM flag');
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoItemOneRes()
    begin
        StdCostPriceRollup(true, 2, 1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoItemTwoRes()
    begin
        StdCostPriceRollup(true, 2, 2, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneItemTwoRes()
    begin
        StdCostPriceRollup(true, 1, 2, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoItemTwoRes()
    begin
        StdCostPriceRollup(true, 0, 2, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneItemOneRes()
    begin
        StdCostPriceRollup(true, 1, 1, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoItemNoRes()
    begin
        StdCostPriceRollup(true, 2, 0, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoItemNoRes()
    begin
        StdCostPriceRollup(true, 0, 0, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoItemNoResNoText()
    var
        Item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 0, 0, 0, 1, '', '');

        // Exercise.
        asserterror CalculateStandardCost.CalcItem(Item."No.", true);

        // Validate.
        Assert.AreEqual(
          StrSubstNo(ErrorNoAssemblyList, Item."No.", Item.Description, 'Standard Cost'), GetLastErrorText, 'Wrong cost msg');

        // Tear down.
        ClearLastError();

        // Exercise.
        asserterror CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate.
        Assert.AreEqual(
          StrSubstNo(ErrorNoAssemblyList, Item."No.", Item.Description, 'Unit Price'), GetLastErrorText, 'Wrong price msg');

        // Tear down.
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TwoItemTwoResNonBaseUOM()
    begin
        StdCostPriceRollup(false, 2, 2, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure OneItemOneResZeroQtyPer()
    begin
        StdCostPriceRollup(true, 1, 1, 1, 0);
    end;

    [Normal]
    local procedure DiffCostingMethodsComp(CostingMethod: Enum "Costing Method"; CostAdjNeeded: Boolean; IndirectCost: Decimal; Overhead: Decimal)
    var
        Item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, CostingMethod, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(CostingMethod, Item."No.", true, 1, 1, 1, 1, '', '');
        LibraryAssembly.ModifyCostParams(Item."No.", CostAdjNeeded, IndirectCost, Overhead);

        // Exercise.
        StdCostLevel := 1;
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate.
        Item.Get(Item."No.");
        if CostingMethod <> Item."Costing Method"::Standard then
            Assert.AreEqual(0, Item."Unit Cost", 'Unit cost should be 0:' + Item."No.");
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item."No."), Item."Unit Price", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong unit price for:' + Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure FIFOCostAdj()
    begin
        DiffCostingMethodsComp(Item."Costing Method"::FIFO, true, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure LIFOCostAdj()
    begin
        DiffCostingMethodsComp(Item."Costing Method"::LIFO, true, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AvgCostAdj()
    begin
        DiffCostingMethodsComp(Item."Costing Method"::Average, true, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure StdIndirectCostOverhead()
    begin
        DiffCostingMethodsComp(
          Item."Costing Method"::Standard, false, LibraryRandom.RandDec(10, 2), LibraryRandom.RandDec(10, 2));
    end;

    [Normal]
    local procedure DiffCostingMethodsParent(CostingMethod: Enum "Costing Method"; CostAdjNeeded: Boolean; IndirectCost: Decimal; Overhead: Decimal)
    var
        Item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
        InitialCost: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, CostingMethod, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 1, 1, 1, 1, '', '');
        LibraryAssembly.ModifyItem(Item."No.", CostAdjNeeded, IndirectCost, Overhead);
        Item.Get(Item."No.");
        InitialCost := Item."Unit Cost";

        // Exercise.
        StdCostLevel := 1;
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate.
        Item.Get(Item."No.");
        if CostingMethod <> Item."Costing Method"::Standard then
            Assert.AreEqual(InitialCost, Item."Unit Cost", 'Unit cost should not be updated:' + Item."No.");
        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item."No."),
          Item."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item."No.");
        Assert.AreNearlyEqual(MaterialCost, Item."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
        Assert.AreNearlyEqual(CapOverhead, Item."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap. Overhead');
        Assert.AreNearlyEqual(CapOverhead, Item."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item."No."), Item."Unit Price", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong unit price for:' + Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentAvgCostAdj()
    begin
        DiffCostingMethodsParent(Item."Costing Method"::Average, true, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentFIFOCostAdj()
    begin
        DiffCostingMethodsParent(Item."Costing Method"::FIFO, true, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentSTDCostAdj()
    begin
        DiffCostingMethodsParent(Item."Costing Method"::Standard, true, 0, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentCostAdjOvhd()
    begin
        DiffCostingMethodsParent(
          Item."Costing Method"::Standard, true, 0, LibraryRandom.RandDec(10, 2));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ParentCostAdjIndirectCost()
    begin
        DiffCostingMethodsParent(
          Item."Costing Method"::Standard, true, LibraryRandom.RandDec(10, 2), 0);
    end;

    [Normal]
    local procedure ModifyAssemblyList(ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards"; ComponentType: Enum "BOM Component Type"; NewComponentType: Enum "BOM Component Type")
    var
        Item: Record Item;
        Item1: Record Item;
        Resource1: Record Resource;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        NewComponentNo: Code[20];
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 2, 2, 1, 1, '', '');

        if NewComponentType = BOMComponent.Type::Item then
            NewComponentNo := LibraryAssembly.CreateItem(Item1, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '')
        else
            NewComponentNo := LibraryAssembly.CreateResource(Resource1, true, '');
        LibraryAssembly.EditAssemblyList(ChangeType, ComponentType, NewComponentType, NewComponentNo, Item."No.");

        // Exercise.
        StdCostLevel := 1;
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate.
        Item.Get(Item."No.");
        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item."No."),
          Item."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item."No.");
        Assert.AreNearlyEqual(MaterialCost, Item."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
        Assert.AreNearlyEqual(CapOverhead, Item."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap. Overhead');
        Assert.AreNearlyEqual(CapOverhead, Item."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item."No."), Item."Unit Price", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Wrong unit price for:' + Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceItemRes()
    begin
        ModifyAssemblyList(ChangeType::Replace, BOMComponent.Type::Item, BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceItemItem()
    begin
        ModifyAssemblyList(ChangeType::Replace, BOMComponent.Type::Item, BOMComponent.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceResItem()
    begin
        ModifyAssemblyList(ChangeType::Replace, BOMComponent.Type::Resource, BOMComponent.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ReplaceResRes()
    begin
        ModifyAssemblyList(ChangeType::Replace, BOMComponent.Type::Resource, BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddItem()
    begin
        ModifyAssemblyList(ChangeType::Add, BOMComponent.Type::Item, BOMComponent.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AddRes()
    begin
        ModifyAssemblyList(ChangeType::Add, BOMComponent.Type::Resource, BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItem()
    begin
        ModifyAssemblyList(ChangeType::Delete, BOMComponent.Type::Item, BOMComponent.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteRes()
    begin
        ModifyAssemblyList(ChangeType::Delete, BOMComponent.Type::Resource, BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditItem()
    begin
        ModifyAssemblyList(ChangeType::Edit, BOMComponent.Type::Item, BOMComponent.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure EditRes()
    begin
        ModifyAssemblyList(ChangeType::Edit, BOMComponent.Type::Resource, BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteAll()
    var
        Item: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 2, 2, 1, 1, '', '');
        LibraryAssembly.DeleteAssemblyList(Item."No.");
        SetItemReplenishmentMethod(Item."No.", Item."Replenishment System"::Assembly);
        Commit();

        // Exercise.
        asserterror CalculateStandardCost.CalcItem(Item."No.", true);

        // Validate.
        Assert.AreEqual(
          StrSubstNo(ErrorNoAssemblyList, Item."No.", Item.Description, 'Standard Cost'), GetLastErrorText, GetLastErrorText);
        ClearLastError();
    end;

    [Normal]
    local procedure MultipleLvlRollup(ChangeType: Option " ",Add,Replace,Delete,Edit,"Delete all","Edit cards"; ComponentType: Enum "BOM Component Type"; CalcLevel: Integer; TreeDepth: Integer; NoOfComps: Integer)
    var
        Item: Record Item;
        Item1: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        InitialCost: Decimal;
        InitialPrice: Decimal;
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateMultipleLvlTree(Item, Item1, Item."Replenishment System"::Assembly,
          Item."Costing Method"::Standard, TreeDepth, NoOfComps);
        LibraryAssembly.EditAssemblyList(ChangeType, ComponentType, ComponentType, '', Item."No.");

        // Exercise.
        Item1.Get(Item1."No.");
        Item.Get(Item."No.");
        InitialCost := Item."Standard Cost";
        InitialPrice := Item."Unit Price";
        StdCostLevel := CalcLevel;
        CalculateStandardCost.CalcItem(Item1."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item1."No.");

        // Validate.
        Item1.Get(Item1."No.");
        Item.Get(Item."No.");
        Item.CalcFields("Assembly BOM");
        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item1."No."),
          Item1."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item1."No.");
        Assert.AreNearlyEqual(MaterialCost, Item1."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item1."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
        Assert.AreNearlyEqual(CapOverhead, Item1."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item1."No."), Item1."Unit Price",
          LibraryERM.GetUnitAmountRoundingPrecision(), 'Wrong unit price for:' + Item1."No.");
        Assert.AreEqual(NoOfComps > 0, Item."Assembly BOM", 'Wrong Assembly BOM flag.');

        if CalcLevel = 1 then begin
            Assert.AreEqual(InitialCost, Item."Standard Cost", Item."No.");
            Assert.AreEqual(InitialPrice, Item."Unit Price", 'Wrong unit price for:' + Item."No.");
        end
        else begin
            Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item."No."),
              Item."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item."No.");
            Assert.AreNearlyEqual(
              MaterialCost, Item."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
            Assert.AreNearlyEqual(
              CapacityCost, Item."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
            Assert.AreNearlyEqual(
              CapOverhead, Item."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap. Overhead');
            Assert.AreNearlyEqual(CapOverhead, Item."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
              'Rolled up Cap Overhead');
            Assert.AreNearlyEqual(
              LibraryAssembly.CalcExpectedPrice(Item."No."),
              Item."Unit Price", LibraryERM.GetUnitAmountRoundingPrecision(), 'Wrong unit price for:' + Item."No.");
        end;
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopLevel()
    begin
        MultipleLvlRollup(ChangeType::" ", BOMComponent.Type::Item, 1, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure MultipleLevel()
    begin
        MultipleLvlRollup(ChangeType::" ", BOMComponent.Type::Item, 2, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopLevelUpdate()
    begin
        MultipleLvlRollup(ChangeType::Delete, BOMComponent.Type::Item, 1, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure MultipleLevelUpdate()
    begin
        MultipleLvlRollup(ChangeType::Edit, BOMComponent.Type::Item, 2, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopLevelTwoLevels()
    begin
        MultipleLvlRollup(ChangeType::" ", BOMComponent.Type::Item, 1, 2, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure MultipleLevelTwoLevels()
    begin
        MultipleLvlRollup(ChangeType::" ", BOMComponent.Type::Item, 2, 2, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopLevelUpdateCard()
    begin
        MultipleLvlRollup(ChangeType::"Edit cards", BOMComponent.Type::Item, 1, 1, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAssemblyListSglLevel()
    begin
        MultipleLvlRollup(ChangeType::" ", BOMComponent.Type::Item, 1, 1, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure NoAssemblyListMultLevel()
    begin
        MultipleLvlRollup(ChangeType::" ", BOMComponent.Type::Item, 2, 1, 0);
    end;

    [Normal]
    local procedure ResUsage(FirstResUsage: Option; SecondResUsage: Option; UseSameRes: Boolean; LotSize: Integer)
    var
        Item: Record Item;
        Resource: Record Resource;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        Item.Validate("Lot Size", LotSize);
        Item.Modify(true);
        LibraryAssembly.CreateResource(Resource, true, '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '', FirstResUsage, LibraryRandom.RandDec(20, 2), true);
        if not UseSameRes then
            LibraryAssembly.CreateResource(Resource, true, '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Resource, Resource."No.", Item."No.", '', SecondResUsage, LibraryRandom.RandDec(20, 2), true);

        // Exercise.
        StdCostLevel := 1;
        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate.
        Item.Get(Item."No.");
        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item."No."),
          Item."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item."No.");
        Assert.AreNearlyEqual(MaterialCost, Item."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
        Assert.AreNearlyEqual(CapOverhead, Item."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap. Overhead');
        Assert.AreNearlyEqual(CapOverhead, Item."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreEqual(LibraryAssembly.CalcExpectedPrice(Item."No."), Item."Unit Price", 'Wrong unit price for:' + Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResNoLotDiffUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Direct, BOMComponent."Resource Usage Type"::Fixed, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffResNoLotDiffUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Fixed, BOMComponent."Resource Usage Type"::Direct, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResLotDiffUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Direct, BOMComponent."Resource Usage Type"::Fixed, true, LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffResLotDiffUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Fixed, BOMComponent."Resource Usage Type"::Direct, false, LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResNoLotSameUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Direct, BOMComponent."Resource Usage Type"::Direct, true, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffResNoLotDiffSameUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Fixed, BOMComponent."Resource Usage Type"::Fixed, false, 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure SameResLotDiffSameUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Fixed, BOMComponent."Resource Usage Type"::Fixed, true, LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DiffResLotDiffSameUsage()
    begin
        ResUsage(BOMComponent."Resource Usage Type"::Direct, BOMComponent."Resource Usage Type"::Direct, false, LibraryRandom.RandInt(10));
    end;

    [Normal]
    local procedure ReplMethod(ReplenishmentMethod: Enum "Replenishment System"; CalcLevel: Integer; TreeDepth: Integer)
    var
        Item: Record Item;
        Item1: Record Item;
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        InitialCost: Decimal;
        InitialPrice: Decimal;
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateMultipleLvlTree(Item, Item1, ReplenishmentMethod, Item."Costing Method"::Standard, TreeDepth, 2);
        SetItemReplenishmentMethod(Item."No.", ReplenishmentMethod);
        Commit();

        // Exercise.
        Item.Get(Item."No.");
        Item.CalcFields("Assembly BOM");
        InitialCost := Item."Standard Cost";
        InitialPrice := Item."Unit Price";
        StdCostLevel := CalcLevel;
        CalculateStandardCost.CalcItem(Item1."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item1."No.");
        Item1.Get(Item1."No.");

        // Validate.
        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item1."No."),
          Item1."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item1."No.");
        Assert.AreNearlyEqual(MaterialCost, Item1."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item1."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
        Assert.AreNearlyEqual(CapOverhead, Item1."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap. Overhead');
        Assert.AreNearlyEqual(
          CapOverhead, Item1."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item1."No."), Item1."Unit Price",
          LibraryERM.GetUnitAmountRoundingPrecision(), 'Wrong unit price for:' + Item1."No.");
        Assert.AreEqual(InitialCost, Item."Standard Cost", Item."No.");
        Assert.AreEqual(InitialPrice, Item."Unit Price", 'Wrong unit price for:' + Item."No.");

        asserterror CalculateStandardCost.CalcItem(Item."No.", true);
        Assert.AreEqual(
          StrSubstNo(ErrorItemNotAssembled, Item."No.", Item.Description, 'Standard Cost'),
          GetLastErrorText, GetLastErrorText);
        ClearLastError();

        asserterror CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");
        Assert.AreEqual(
          StrSubstNo(ErrorItemNotAssembled, Item."No.", Item.Description, 'Unit Price'),
          GetLastErrorText, GetLastErrorText);
        ClearLastError();
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchTopLevel()
    begin
        ReplMethod(Item."Replenishment System"::Purchase, 1, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchMultLevel()
    begin
        ReplMethod(Item."Replenishment System"::Purchase, 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchMultTwoLevels()
    begin
        ReplMethod(Item."Replenishment System"::Purchase, 2, 2);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure PurchSglTwoLevels()
    begin
        ReplMethod(Item."Replenishment System"::Purchase, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure ProdItemTopLevel()
    begin
        ReplMethod(Item."Replenishment System"::"Prod. Order", 1, 1);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,CalcStdCostDiffReplHandler')]
    [Scope('OnPrem')]
    procedure ProdItemMultLevel()
    begin
        ReplMethod(Item."Replenishment System"::"Prod. Order", 2, 1);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,CalcStdCostDiffReplHandler')]
    [Scope('OnPrem')]
    procedure ProdItemMultTwoLevels()
    begin
        ReplMethod(Item."Replenishment System"::"Prod. Order", 2, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure ProdItemSglTwoLevels()
    begin
        ReplMethod(Item."Replenishment System"::"Prod. Order", 1, 2);
    end;

    [Normal]
    local procedure CyclicalKit(CalcLevel: Integer)
    var
        Item: Record Item;
        Item1: Record Item;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item."No.", true, 2, 2, 1, 1, '', '');
        LibraryAssembly.CreateItem(Item1, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateAssemblyList(Item."Costing Method"::Standard, Item1."No.", true, 2, 2, 1, 1, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item."No.", Item1."No.", '', BOMComponent."Resource Usage Type"::Direct,
          LibraryRandom.RandDec(20, 2), true);
        if CalcLevel > 1 then
            Item := Item1;

        // Exercise.
        asserterror
          LibraryAssembly.CreateAssemblyListComponent(
            BOMComponent.Type::Item, Item."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
            LibraryRandom.RandDec(20, 2), true);

        // Validate.
        Assert.AreEqual(StrSubstNo(ErrorCyclicalKit, Item."No."), GetLastErrorText, 'Wrong error message')
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemHasItself()
    begin
        CyclicalKit(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemHasItselfReverse()
    begin
        CyclicalKit(2);
    end;

    [Normal]
    local procedure VariantComp(ComponentType: Enum "BOM Component Type")
    var
        Item: Record Item;
        Item1: Record Item;
        Resource: Record Resource;
        ItemVariant: Record "Item Variant";
        ItemVariant1: Record "Item Variant";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        MaterialCost: Decimal;
        CapacityCost: Decimal;
        CapOverhead: Decimal;
        errorCode: Text;
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(Item1, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateResource(Resource, true, '');
        LibraryInventory.CreateVariant(ItemVariant, Item1);
        LibraryInventory.CreateVariant(ItemVariant1, Item1);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", ItemVariant.Code, BOMComponent."Resource Usage Type"::Direct,
          LibraryRandom.RandDec(20, 2), true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", ItemVariant1.Code, BOMComponent."Resource Usage Type"::Direct,
          LibraryRandom.RandDec(20, 2), true);
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
          LibraryRandom.RandDec(20, 2), true);

        // Exercise.
        case ComponentType of
            "BOM Component Type"::Item:
                asserterror
                  LibraryAssembly.CreateAssemblyListComponent(
                    ComponentType, Item1."No.", Item."No.", 'NONEX', BOMComponent."Resource Usage Type"::Direct, 1, true);
            "BOM Component Type"::Resource:
                asserterror
                  LibraryAssembly.CreateAssemblyListComponent(
                    ComponentType, Resource."No.", Item."No.", ItemVariant.Code, BOMComponent."Resource Usage Type"::Direct, 1, true);
            else
                asserterror
                  LibraryAssembly.CreateAssemblyListComponent(
                    ComponentType, '', Item."No.", ItemVariant.Code, BOMComponent."Resource Usage Type"::Direct, 1, true);
        end;

        CalculateStandardCost.CalcItem(Item."No.", true);
        CalculateStandardCost.CalcAssemblyItemPrice(Item."No.");

        // Validate
        Item.Get(Item."No.");
        errorCode := GetLastErrorCode;
        if ComponentType = BOMComponent.Type::Item then
            Assert.IsTrue(errorCode = 'DB:RecordNotFound', 'Record not found error message was expected. Actual error code:' + errorCode)
        else
            Assert.IsTrue(errorCode = 'TestField', ErrorWrongType + 'Actual error code:' + errorCode);
        ClearLastError();

        Assert.AreNearlyEqual(LibraryAssembly.CalcExpectedStandardCost(MaterialCost, CapacityCost, CapOverhead, Item."No."),
          Item."Standard Cost", LibraryERM.GetAmountRoundingPrecision(), 'Wrong std. cost for:' + Item."No.");
        Assert.AreNearlyEqual(MaterialCost, Item."Single-Level Material Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Material Cost');
        Assert.AreNearlyEqual(CapacityCost, Item."Single-Level Capacity Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Capacity Cost');
        Assert.AreNearlyEqual(CapOverhead, Item."Single-Level Cap. Ovhd Cost", LibraryERM.GetUnitAmountRoundingPrecision(), 'Cap. Overhead');
        Assert.AreNearlyEqual(CapOverhead, Item."Rolled-up Cap. Overhead Cost", LibraryERM.GetUnitAmountRoundingPrecision(),
          'Rolled up Cap Overhead');
        Assert.AreNearlyEqual(
          LibraryAssembly.CalcExpectedPrice(Item."No."), Item."Unit Price",
          LibraryERM.GetUnitAmountRoundingPrecision(), 'Wrong unit price for:' + Item."No.");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantRes()
    begin
        VariantComp(BOMComponent.Type::Resource);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantItem()
    begin
        VariantComp(BOMComponent.Type::Item);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure VariantText()
    begin
        VariantComp(BOMComponent.Type::" ");
    end;

    [Normal]
    local procedure InstItemNo(Qty: Decimal)
    var
        Item: Record Item;
        Item1: Record Item;
        Item2: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // Setup.
        Initialize();
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::Standard, Item."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(Item1, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item1."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct, Qty, true);
        LibraryAssembly.CreateItem(Item2, Item."Costing Method"::Standard, Item."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, Item2."No.", Item."No.", '', BOMComponent."Resource Usage Type"::Direct,
          LibraryRandom.RandDec(20, 2), true);
        BOMComponent.SetRange(Type, BOMComponent.Type::Item);
        BOMComponent.SetRange("No.", Item2."No.");
        BOMComponent.FindFirst();

        // Exercise.
        if Qty <> 1 then begin
            asserterror BOMComponent.Validate("Installed in Item No.", Item1."No.");
            // Validate.
            Assert.ExpectedTestFieldError(BOMComponent.FieldCaption("Quantity per"), Format(1));
            ClearLastError();
        end
        else
            BOMComponent.Validate("Installed in Item No.", Item1."No.");
        BOMComponent.Modify(true);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPer1()
    begin
        InstItemNo(1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure QtyPerAny()
    begin
        InstItemNo(1 + LibraryRandom.RandInt(10));
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemPurchaseReplenishedIsConvertedToAssemblyItemWhenBOMIsAdded()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
    begin
        // [GIVEN] An Item without Assembly BOM and "Replenishment System"::Purchase
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::Average, ParentItem."Replenishment System"::Purchase, '', '');

        // [WHEN] At least one component is added as part of a BOM
        CreateAndAddComponentItemToItem(ParentItem, ComponentItem, LibraryRandom.RandIntInRange(1, 5));

        // [THEN] The parent item is converted to an assembly item with "Replenishment System"::Assembly
        ParentItem.TestField("Replenishment System", ParentItem."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyItemIsConvertedToItemPurchaseReplenishedWhenBOMIsRemoved()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
    begin
        // [GIVEN] An Assembly Item with a number of components
        CreateAssemblyItemAndComponentItem(ParentItem, ComponentItem, LibraryRandom.RandIntInRange(1, 5));

        // [WHEN] All components are removed
        RemoveAllComponents(ParentItem);

        // [THEN] The parent item is converted to an assembly item with "Replenishment System"::Purchase
        ParentItem.TestField("Replenishment System", ParentItem."Replenishment System"::Purchase);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdReplenishedIsNotConvertedToAssemblyItemWhenBOMIsAdded()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
    begin
        // [GIVEN] An Item without Assembly BOM and "Replenishment System"::"Prod. Order"
        LibraryAssembly.CreateItem(
          ParentItem, ParentItem."Costing Method"::Average, ParentItem."Replenishment System"::"Prod. Order", '', '');

        // [WHEN] At least one component is added as part of a BOM
        CreateAndAddComponentItemToItem(ParentItem, ComponentItem, LibraryRandom.RandIntInRange(1, 5));

        // [THEN] The parent item still has "Replenishment System"::"Prod. Order"
        ParentItem.TestField("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemProdReplenishedIsNotConvertedToItemPurchaseReplenishedWhenBOMIsRemoved()
    var
        ParentItem: Record Item;
        ComponentItem: Record Item;
    begin
        // [GIVEN] An Item with BOM and "Replenishment System"::"Prod. Order"
        LibraryAssembly.CreateItem(
          ParentItem, ParentItem."Costing Method"::Average, ParentItem."Replenishment System"::"Prod. Order", '', '');
        CreateAndAddComponentItemToItem(ParentItem, ComponentItem, LibraryRandom.RandIntInRange(1, 5));

        // [WHEN] All components are removed
        RemoveAllComponents(ParentItem);

        // [THEN] The parent item still has "Replenishment System"::"Prod. Order"
        ParentItem.TestField("Replenishment System", ParentItem."Replenishment System"::"Prod. Order");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure AssemblyItemReplenishmentIsUpdatedAfterRenameOfComponents()
    var
        ParentItem: Record Item;
        DestParentItem: Record Item;
        ComponentItem: Record Item;
    begin
        // [GIVEN] An Assembly Item with a component
        CreateAssemblyItemAndComponentItem(ParentItem, ComponentItem, LibraryRandom.RandIntInRange(1, 5));
        // [GIVEN] An Item without Assembly BOM and "Replenishment System"::Purchase
        LibraryAssembly.CreateItem(
          DestParentItem, DestParentItem."Costing Method"::Average, DestParentItem."Replenishment System"::Purchase, '', '');

        // [WHEN] The component in the Assembly Item is renamed and "moved" to the other item without Assembly BOM
        RenameFirstComponent(ParentItem, DestParentItem);

        // [THEN] The two item "Replenishment System" is updated accordingly
        ParentItem.TestField("Replenishment System", ParentItem."Replenishment System"::Purchase);
        DestParentItem.TestField("Replenishment System", DestParentItem."Replenishment System"::Assembly);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure DeleteItemWithAChildBOMComponent()
    var
        Item: Record Item;
        BOMComponent: Record "BOM Component";
    begin
        // [FEATURE] [Item] [BOM]
        // [SCENARIO 274234] Item with a BOM Component can be deleted.
        Initialize();

        // [GIVEN] Item "I" has a record "BOM Component" with the field "Parent Item No." = "I"
        LibraryInventory.CreateItem(Item);
        BOMComponent.Validate("Parent Item No.", Item."No.");
        BOMComponent.Validate("Line No.", LibraryUtility.GetNewRecNo(BOMComponent, BOMComponent.FieldNo("Line No.")));
        BOMComponent.Insert(true);

        // [WHEN] Commit transaction, read "I" from DB and delete "I"
        Commit();
        Item.Get(Item."No.");
        Item.Delete(true);

        // [THEN] Table "Item" does not contain "I"
        Item.SetRange("No.", Item."No.");
        Assert.RecordIsEmpty(Item);
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalcStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Assert.IsTrue(StrPos(Instruction, StdCostRollupMessage) > 0, 'Actual:' + Instruction + '; Expected:' + StdCostRollupMessage);
        Choice := StdCostLevel;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure CalcStdCostDiffReplHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Assert.IsTrue(StrPos(Question, ReplMethodMessage) > 0, 'Actual:' + Question + '; Expected:' + ReplMethodMessage);
        Reply := (StdCostLevel = 1);
    end;

    [Scope('OnPrem')]
    procedure SetItemReplenishmentMethod(ItemNo: Code[20]; ReplenishmentMethod: Enum "Replenishment System")
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Item.Validate("Replenishment System", ReplenishmentMethod);
        Item.Modify(true);
    end;

    local procedure CreateAssemblyItemAndComponentItem(var ParentItem: Record Item; var ComponentItem: Record Item; QuantityPerParent: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(ParentItem, ParentItem."Costing Method"::Average, ParentItem."Replenishment System"::Assembly, '', '');
        LibraryAssembly.CreateItem(ComponentItem, ComponentItem."Costing Method"::Average, ComponentItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '', BOMComponent."Resource Usage Type", QuantityPerParent, true);
    end;

    local procedure RenameFirstComponent(var SourceParentItem: Record Item; var DestParentItem: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", SourceParentItem."No.");
        if BOMComponent.FindFirst() then
            BOMComponent.Rename(DestParentItem."No.", BOMComponent."Line No.");
        SourceParentItem.Find();
        DestParentItem.Find();
    end;

    local procedure RemoveAllComponents(var ParentItem: Record Item)
    var
        BOMComponent: Record "BOM Component";
    begin
        BOMComponent.SetRange("Parent Item No.", ParentItem."No.");
        BOMComponent.DeleteAll(true);
        ParentItem.Find();
    end;

    local procedure CreateAndAddComponentItemToItem(var ParentItem: Record Item; var ComponentItem: Record Item; QuantityPerParent: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        LibraryAssembly.CreateItem(
          ComponentItem, ComponentItem."Costing Method"::Average, ComponentItem."Replenishment System"::Purchase, '', '');
        LibraryAssembly.CreateAssemblyListComponent(
          BOMComponent.Type::Item, ComponentItem."No.", ParentItem."No.", '', BOMComponent."Resource Usage Type", QuantityPerParent, true);
        ParentItem.Find();
    end;
}

