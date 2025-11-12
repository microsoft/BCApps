// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Inventory.Location;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Inventory.BOM;
using Microsoft.Manufacturing.StandardCost;
using Microsoft.Inventory.BOM.Tree;

codeunit 137110 "SCM Kitting - Cost Shares Tree"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Assembly] [BOM Tree] [SCM]
        isInitialized := false;
    end;

    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryRandom: Codeunit "Library - Random";
        LibraryTrees: Codeunit "Library - Trees";
        LibraryUtility: Codeunit "Library - Utility";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        isInitialized: Boolean;
        ERRWrongCostShareErr: Label 'Wrong %1 in item %2.', Comment = '%1: Caption of the field with the incorrect value; %2: Item No.';
        ERRWrongCostShareCalcErr: Label 'Wrong %1 in item %2 - versus calculated value.', Comment = '%1: Caption of the field with the incorrect value; %2: Item No.';
        GLBChangeType: Option "None","Purchase With Assembly BOM","Purchase with Prod. BOM","Prod. without Prod. BOM","Assembly without BOM";
        ERRWrongWarningParentErr: Label 'Warning were not issued for parent item.';
        ERRWrongWarningElementErr: Label 'Wrong BOM Warning Log found for entity %1.', Comment = '%1: Warning text.';

    local procedure CostSharesTreeBasic(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTopItem(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBasic()
    begin
        CostSharesTreeBasic(Enum::"Item Replenishment System"::Assembly, 2, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderBasic()
    begin
        CostSharesTreeBasic(Enum::"Item Replenishment System"::"Prod. Order", 2, 1, 2);
    end;

    local procedure CostSharesTreeOverhead(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddOverhead(TempItem, TempResource, TempWorkCenter, TempMachineCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTopItem(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyOverhead()
    begin
        CostSharesTreeOverhead(Enum::"Item Replenishment System"::Assembly, 2, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderOverhead()
    begin
        CostSharesTreeOverhead(Enum::"Item Replenishment System"::"Prod. Order", 2, 1, 2);
    end;

    local procedure CostSharesTreeItemScrap(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddScrapForItems(TempItem);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTreeWithScrap(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyItemScrap()
    begin
        CostSharesTreeItemScrap(Enum::"Item Replenishment System"::Assembly, 2, 2, 0);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderItemScrap()
    begin
        CostSharesTreeItemScrap(Enum::"Item Replenishment System"::"Prod. Order", 2, 2, 0);
    end;

    local procedure CostSharesTreeBOMScrap(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddScrapForProdBOM(TempItem);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTreeWithScrap(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMScrap()
    begin
        CostSharesTreeBOMScrap(Enum::"Item Replenishment System"::Assembly, 1, 2, 1);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderBOMScrap()
    begin
        CostSharesTreeBOMScrap(Enum::"Item Replenishment System"::"Prod. Order", 1, 2, 1);
    end;

    local procedure CostSharesTreeRoutingScrap(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddScrapForRoutings(TempItem);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTreeWithScrap(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyRoutingScrap()
    begin
        CostSharesTreeRoutingScrap(Enum::"Item Replenishment System"::Assembly, 1, 1, 3);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderRoutingScrap()
    begin
        CostSharesTreeRoutingScrap(Enum::"Item Replenishment System"::"Prod. Order", 1, 1, 3);
    end;

    local procedure CostSharesTreeMachineCenterScrap(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddScrapForMachineCenters(TempMachineCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTopItem(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyMCenterScrap()
    begin
        CostSharesTreeMachineCenterScrap(Enum::"Item Replenishment System"::Assembly, 1, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderMCenterScrap()
    begin
        CostSharesTreeMachineCenterScrap(Enum::"Item Replenishment System"::"Prod. Order", 1, 1, 2);
    end;

    local procedure CostSharesTreeSubcontracting(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddSubcontracting(TempWorkCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTopItem(BOMBuf, Item);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblySubcontr()
    begin
        CostSharesTreeSubcontracting(Enum::"Item Replenishment System"::Assembly, 1, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderSubcontr()
    begin
        CostSharesTreeSubcontracting(Enum::"Item Replenishment System"::"Prod. Order", 1, 1, 2);
    end;

    local procedure CostSharesTreeWarning(TopItemReplSystem: Enum "Replenishment System"; WarningTableID: Integer; ChangeType: Option)
    var
        Item: Record Item;
        Item1: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
        WarningText: Text[20];
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, 2, 1, 1);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        case WarningTableID of
            DATABASE::"Production BOM Header":
                AddBOMWarning(TempItem, Item1, WarningText);
            DATABASE::"Routing Header":
                AddRoutingWarning(TempItem, Item1, WarningText);
            DATABASE::Item:
                AddReplSystemWarning(TempItem, Item1, WarningText, ChangeType);
        end;
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyWarnings(BOMBuf, WarningTableID, WarningText);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMWarning()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::Assembly, DATABASE::"Production BOM Header", GLBChangeType::None);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyRoutingWarning()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::Assembly, DATABASE::"Routing Header", GLBChangeType::None);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyReplWarning1()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::Assembly, DATABASE::Item, GLBChangeType::"Purchase With Assembly BOM");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyReplWarning2()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::Assembly, DATABASE::Item, GLBChangeType::"Purchase with Prod. BOM");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyReplWarning3()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::Assembly, DATABASE::Item, GLBChangeType::"Prod. without Prod. BOM");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyReplWarning4()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::Assembly, DATABASE::Item, GLBChangeType::"Assembly without BOM");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdBOMWarning()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::"Prod. Order", DATABASE::"Production BOM Header", GLBChangeType::None);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdRoutingWarning()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::"Prod. Order", DATABASE::"Routing Header", GLBChangeType::None);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdReplWarning1()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::"Prod. Order", DATABASE::Item, GLBChangeType::"Purchase With Assembly BOM");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdReplWarning2()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::"Prod. Order", DATABASE::Item, GLBChangeType::"Purchase with Prod. BOM");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdReplWarning3()
    begin
        CostSharesTreeWarning(Enum::"Item Replenishment System"::"Prod. Order", DATABASE::Item, GLBChangeType::"Prod. without Prod. BOM");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBOMStructureWithLongLocationFilter()
    var
        TempBOMBuffer: Record "BOM Buffer" temporary;
        Item: Record Item;
        EntryNo: Integer;
    begin
        // [FEATURE] [Filter] [UT]
        // [SCENARIO 274335] Long compound filters on the Item table do not cause run-time error when calculating item's BOM structure

        Initialize();

        Item."No." := LibraryUtility.GenerateGUID();
        Item."Replenishment System" := Item."Replenishment System"::"Prod. Order";
        Item.Insert();

        Item.SetFilter(
          "Location Filter", StrSubstNo('%1..%2', LibraryUtility.GenerateRandomCode(Item.FieldNo("Location Filter"), DATABASE::Item)));
        Item.SetFilter(
          "Variant Filter", StrSubstNo('%1..%2', LibraryUtility.GenerateRandomCode(Item.FieldNo("Variant Filter"), DATABASE::Item)));
        TempBOMBuffer.SetLocationVariantFiltersFrom(Item);

        TempBOMBuffer.TransferFromItem(EntryNo, Item, WorkDate());

        TempBOMBuffer.TestField(Type, TempBOMBuffer.Type::Item);
        TempBOMBuffer.TestField("No.", Item."No.");
        TempBOMBuffer.TestField("Replenishment System", Item."Replenishment System");
    end;

    [Test]
    [Scope('OnPrem')]
    procedure ItemBOMStructureWithVariantLocationFiltersAndSKU()
    var
        TempBOMBuffer: Record "BOM Buffer" temporary;
        Item: Record Item;
        SKU: Record "Stockkeeping Unit";
        EntryNo: Integer;
    begin
        // [FEATURE] [Filter] [UT]
        // [SCENARIO 274335] When calculating item's BOM structure and the "Item" table is filtered by location and variant, BOM buffer is initialized from the SKU on the location and variant taken from filters

        Initialize();
        Item."No." := LibraryUtility.GenerateGUID();
        Item.Insert();

        SKU."Location Code" := LibraryUtility.GenerateRandomCode(SKU.FieldNo("Location Code"), DATABASE::"Stockkeeping Unit");
        SKU."Variant Code" := LibraryUtility.GenerateRandomCode(SKU.FieldNo("Variant Code"), DATABASE::"Stockkeeping Unit");
        SKU."Item No." := Item."No.";
        SKU."Replenishment System" := SKU."Replenishment System"::"Prod. Order";
        SKU.Insert();

        Item.SetFilter("Location Filter", SKU."Location Code");
        Item.SetFilter("Variant Filter", SKU."Variant Code");
        TempBOMBuffer.SetLocationVariantFiltersFrom(Item);

        TempBOMBuffer.TransferFromItem(EntryNo, Item, WorkDate());

        TempBOMBuffer.TestField(Type, TempBOMBuffer.Type::Item);
        TempBOMBuffer.TestField("No.", Item."No.");
        TempBOMBuffer.TestField("Replenishment System", SKU."Replenishment System");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyPerTopItemAssemblyLeaf()
    begin
        ZeroQtyPerTree(Enum::"Item Replenishment System"::Assembly, 1, true)
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyPerTopItemAssemblyLeafLvl2()
    begin
        ZeroQtyPerTree(Enum::"Item Replenishment System"::Assembly, 2, true)
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyPerTopItemAssemblySub()
    begin
        ZeroQtyPerTree(Enum::"Item Replenishment System"::Assembly, 1, false)
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyPerTopItemAssemblySubLvl2()
    begin
        ZeroQtyPerTree(Enum::"Item Replenishment System"::Assembly, 2, false)
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyPerTopItemProdLeafLevel2()
    begin
        ZeroQtyPerTree(Enum::"Item Replenishment System"::"Prod. Order", 2, true)
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler')]
    [Scope('OnPrem')]
    procedure ZeroQtyPerTopItemProdSubLevel2()
    begin
        ZeroQtyPerTree(Enum::"Item Replenishment System"::"Prod. Order", 2, false)
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMBufferTransferFromProdLineWithCustomCalculationScrapZero()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        BOMBuffer: Record "BOM Buffer";
        EntryNo: Integer;
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 286910] Scrap Qty is 0 in BOM Buffer when Production BOM Line uses Calculation for Quantity and Scrap % = 0
        Initialize();

        // [GIVEN] A Prodiction BOM Line with Calculation = Width*Length and Scrap % = 0
        CreateProductionBOMLineWithCalculation(ProductionBOMLine);

        // [GIVEN] EntryNo for BOM Buffer and Item needed to invoke TransferFromProdComp
        EntryNo := LibraryUtility.GetNewRecNo(BOMBuffer, BOMBuffer.FieldNo("Entry No."));
        LibraryInventory.CreateItem(Item);

        // [WHEN] Create BOM Buffer from Production BOM Line
        BOMBuffer.TransferFromProdComp(EntryNo, ProductionBOMLine, 0, 0, 0, 0, WorkDate(), '', Item, 1);

        // [THEN] "Scrap Qty. per Parent" = 0
        BOMBuffer.TestField("Scrap Qty. per Parent", 0);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure BOMBufferTransferFromProdLineWithCustomCalculationScrapNonZero()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        BOMBuffer: Record "BOM Buffer";
        EntryNo: Integer;
        ExpectedScrapQtyPerParent: Decimal;
    begin
        // [FEATURE] [Production BOM]
        // [SCENARIO 286910] Scrap Qty is calculated in BOM Buffer when Production BOM Line uses Calculation for Quantity and Scrap % not zero
        Initialize();

        // [GIVEN] A Production BOM Line with Calculation = Width*Length and Scrap % not zero
        CreateProductionBOMLineWithCalculation(ProductionBOMLine);
        ProductionBOMLine.Validate("Scrap %", LibraryRandom.RandDecInDecimalRange(5, 10, 1));
        ProductionBOMLine.Modify();

        // [GIVEN] EntryNo for BOM Buffer and Item needed to invoke TransferFromProdComp
        EntryNo := LibraryUtility.GetNewRecNo(BOMBuffer, BOMBuffer.FieldNo("Entry No."));
        LibraryInventory.CreateItem(Item);

        // [WHEN] Create BOM Buffer from Production BOM Line
        BOMBuffer.TransferFromProdComp(EntryNo, ProductionBOMLine, 0, 0, 0, 0, WorkDate(), '', Item, 1);

        // [THEN] "Scrap Qty. per Parent" is calculated using Length and Width
        ExpectedScrapQtyPerParent :=
            Round(
                ((1 + ProductionBOMLine."Scrap %" / 100) * ProductionBOMLine.Length * ProductionBOMLine.Width - ProductionBOMLine.Length * ProductionBOMLine.Width) * ProductionBOMLine."Quantity per",
                0.00001);

        BOMBuffer.TestField("Scrap Qty. per Parent", ExpectedScrapQtyPerParent);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM Kitting - Cost Shares Tree");
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM Kitting - Cost Shares Tree");

        // Setup Demonstration data.
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();

        isInitialized := true;
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM Kitting - Cost Shares Tree");
    end;

    local procedure ZeroQtyPerTree(TopItemReplSystem: Enum "Replenishment System"; Indentation: Integer; IsLeaf: Boolean)
    var
        BOMComponent: Record "BOM Component";
        Item: Record Item;
        BOMBuf: Record "BOM Buffer";
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, 2, 2, 0);
        CalculateTree(BOMBuf, Item);
        SetQtyPerInTree(BOMBuf, BOMComponent.Type::Item, Indentation, IsLeaf, 0);
        SetQtyPerInTree(BOMBuf, BOMComponent.Type::Resource, Indentation, true, 0);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));

        // Exercise: Create the BOM tree.
        CalculateTree(BOMBuf, Item);

        // Verify: Navigate through the tree and check the results.
        VerifyTree(BOMBuf, Item);
        VerifyTopItem(BOMBuf, Item);
    end;

    local procedure CalculateTree(var BOMBuf: Record "BOM Buffer"; var Item: Record Item)
    var
        Item1: Record Item;
        CalculateBOMTree: Codeunit "Calculate BOM Tree";
    begin
        Item.Get(Item."No.");
        Item1.SetRange("No.", Item."No.");
        CalculateBOMTree.GenerateTreeForManyItems(Item1, BOMBuf, "BOM Tree Type"::Cost);
    end;

    local procedure AddBOMWarning(var TempItem: Record Item temporary; var BOMItem: Record Item; var WarningText: Text)
    var
        ProdBOMHeader: Record "Production BOM Header";
    begin
        TempItem.FindSet();
        TempItem.SetFilter("Production BOM No.", '<>%1', '');

        TempItem.Next(TempItem.Count);
        ProdBOMHeader.Get(TempItem."Production BOM No.");
        ProdBOMHeader.Validate(Status, ProdBOMHeader.Status::"Under Development");
        ProdBOMHeader.Modify(true);

        BOMItem.Get(TempItem."No.");
        WarningText := BOMItem."Production BOM No.";
    end;

    local procedure AddRoutingWarning(var TempItem: Record Item temporary; var RoutingItem: Record Item; var WarningText: Text)
    var
        RoutingHeader: Record "Routing Header";
    begin
        TempItem.FindSet();
        TempItem.SetFilter("Routing No.", '<>%1', '');
        TempItem.Next(TempItem.Count);
        RoutingHeader.Get(TempItem."Routing No.");
        RoutingHeader.Validate(Status, RoutingHeader.Status::"Under Development");
        RoutingHeader.Modify(true);

        RoutingItem.Get(TempItem."No.");
        WarningText := RoutingItem."Routing No.";
    end;

    local procedure AddReplSystemWarning(var TempItem: Record Item temporary; var WarningItem: Record Item; var WarningText: Text[20]; ChangeType: Option)
    var
        BOMComponent: Record "BOM Component";
    begin
        case ChangeType of
            GLBChangeType::"Purchase With Assembly BOM":
                begin
                    TempItem.FindSet();
                    TempItem.SetRange("Replenishment System", TempItem."Replenishment System"::Assembly);
                    TempItem.Next(LibraryRandom.RandInt(TempItem.Count));
                    WarningItem.Get(TempItem."No.");
                    WarningItem.Validate("Replenishment System", TempItem."Replenishment System"::Purchase);
                end;
            GLBChangeType::"Purchase with Prod. BOM":
                begin
                    TempItem.FindSet();
                    TempItem.SetRange("Replenishment System", TempItem."Replenishment System"::"Prod. Order");
                    TempItem.Next(LibraryRandom.RandInt(TempItem.Count));
                    WarningItem.Get(TempItem."No.");
                    WarningItem.Validate("Replenishment System", TempItem."Replenishment System"::Purchase);
                end;
            GLBChangeType::"Prod. without Prod. BOM":
                begin
                    TempItem.FindSet();
                    TempItem.SetRange("Replenishment System", TempItem."Replenishment System"::"Prod. Order");
                    TempItem.Next(LibraryRandom.RandInt(TempItem.Count));
                    WarningItem.Get(TempItem."No.");
                    WarningItem.Validate("Production BOM No.", '');
                end;
            GLBChangeType::"Assembly without BOM":
                begin
                    TempItem.FindSet();
                    TempItem.SetRange("Replenishment System", TempItem."Replenishment System"::Assembly);
                    TempItem.Next(LibraryRandom.RandInt(TempItem.Count));
                    WarningItem.Get(TempItem."No.");
                    BOMComponent.SetRange("Parent Item No.", WarningItem."No.");
                    BOMComponent.DeleteAll();
                end;
        end;

        WarningItem.Modify();
        WarningText := WarningItem."No.";
    end;

    local procedure CreateProductionBOMLineWithCalculation(var ProductionBOMLine: Record "Production BOM Line")
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        ProductionBOMLine.Init();
        ProductionBOMLine."Line No." := LibraryUtility.GetNewRecNo(ProductionBOMLine, ProductionBOMLine.FieldNo("Line No."));
        ProductionBOMLine.Type := ProductionBOMLine.Type::Item;
        ProductionBOMLine."No." := Item."No.";
        ProductionBOMLine."Quantity per" := LibraryRandom.RandInt(10);
        ProductionBOMLine.Length := LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 1);
        ProductionBOMLine.Width := LibraryRandom.RandDecInDecimalRange(0.1, 0.9, 1);
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Length * Width");
        ProductionBOMLine.Insert();
    end;

    local procedure SetQtyPerInTree(ParentBOMBuffer: Record "BOM Buffer"; BOMCompType: Enum "BOM Component Type"; Indentation: Integer; IsLeaf: Boolean; NewQtyPer: Decimal)
    var
        BOMComponent: Record "BOM Component";
    begin
        ParentBOMBuffer.SetRange(Indentation, Indentation - 1);
        ParentBOMBuffer.SetRange("Is Leaf", false);
        ParentBOMBuffer.SetRange("Replenishment System", ParentBOMBuffer."Replenishment System"::Assembly);
        ParentBOMBuffer.Next(LibraryRandom.RandInt(ParentBOMBuffer.Count));

        BOMComponent.SetRange(Type, BOMCompType);
        BOMComponent.SetRange("Parent Item No.", ParentBOMBuffer."No.");
        BOMComponent.CalcFields("Assembly BOM");
        BOMComponent.SetRange("Assembly BOM", not IsLeaf);

        BOMComponent.Next(LibraryRandom.RandInt(BOMComponent.Count));
        BOMComponent.Validate("Quantity per", NewQtyPer);
        BOMComponent.Modify(true);
    end;

    local procedure VerifyTree(var BOMBuf: Record "BOM Buffer"; Item: Record Item)
    var
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        RoundingFactor: Decimal;
    begin
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        Item.Get(Item."No.");

        if TempItem.FindSet() then
            repeat
                BOMBuf.SetRange(Type, BOMBuf.Type::Item);
                BOMBuf.SetRange("No.", TempItem."No.");
                BOMBuf.FindSet();
                repeat
                    if TempItem."No." = Item."No." then begin
                        RoundingFactor := 100 * LibraryERM.GetUnitAmountRoundingPrecision();
                        Assert.AreNearlyEqual(Item."Unit Cost", BOMBuf."Unit Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Unit Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Rolled-up Material Cost", BOMBuf."Rolled-up Material Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Rolled-up Material Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Rolled-up Capacity Cost", BOMBuf."Rolled-up Capacity Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Rolled-up Capacity Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Rolled-up Subcontracted Cost", BOMBuf."Rolled-up Subcontracted Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Rolled-up Subcontracted Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Rolled-up Mfg. Ovhd Cost", BOMBuf."Rolled-up Mfg. Ovhd Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Rolled-up Mfg. Ovhd Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Rolled-up Cap. Overhead Cost", BOMBuf."Rolled-up Capacity Ovhd. Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Rolled-up Mfg. Ovhd Cost"), TempItem."No."));

                        Assert.AreNearlyEqual(Item."Single-Level Material Cost", BOMBuf."Single-Level Material Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Single-Level Material Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Single-Level Capacity Cost", BOMBuf."Single-Level Capacity Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Single-Level Capacity Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Single-Level Subcontrd. Cost", BOMBuf."Single-Level Subcontrd. Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Single-Level Subcontrd. Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Single-Level Cap. Ovhd Cost", BOMBuf."Single-Level Cap. Ovhd Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Single-Level Cap. Ovhd Cost"), TempItem."No."));
                        Assert.AreNearlyEqual(Item."Single-Level Mfg. Ovhd Cost", BOMBuf."Single-Level Mfg. Ovhd Cost", RoundingFactor,
                          StrSubstNo(ERRWrongCostShareErr, Item.FieldCaption("Single-Level Mfg. Ovhd Cost"), TempItem."No."));
                    end;
                until BOMBuf.Next() = 0;
            until TempItem.Next() = 0;

        if TempResource.FindSet() then
            repeat
                BOMBuf.SetRange(Type, BOMBuf.Type::Resource);
                BOMBuf.SetRange("No.", TempResource."No.");
                BOMBuf.FindSet();
            until TempResource.Next() = 0;

        if TempMachineCenter.FindSet() then
            repeat
                BOMBuf.SetRange(Type, BOMBuf.Type::"Machine Center");
                BOMBuf.SetRange("No.", TempMachineCenter."No.");
                BOMBuf.FindSet();
            until TempMachineCenter.Next() = 0;

        if TempWorkCenter.FindSet() then
            repeat
                BOMBuf.SetRange(Type, BOMBuf.Type::"Work Center");
                BOMBuf.SetRange("No.", TempWorkCenter."No.");
                BOMBuf.FindSet();
            until TempWorkCenter.Next() = 0;
    end;

    local procedure VerifyTopItem(BOMBuf: Record "BOM Buffer"; Item: Record Item)
    var
        RolledUpMaterialCost: Decimal;
        RolledUpCapacityCost: Decimal;
        RolledUpCapOvhd: Decimal;
        RolledUpMfgOvhd: Decimal;
        SglLevelMaterialCost: Decimal;
        SglLevelCapCost: Decimal;
        SglLevelCapOvhd: Decimal;
        SglLevelMfgOvhd: Decimal;
        RoundingFactor: Decimal;
    begin
        Item.Get(Item."No.");
        LibraryTrees.GetTreeCost(
          RolledUpMaterialCost, RolledUpCapacityCost, RolledUpCapOvhd, RolledUpMfgOvhd, SglLevelMaterialCost, SglLevelCapCost,
          SglLevelCapOvhd, SglLevelMfgOvhd, Item);
        BOMBuf.SetRange(Type, BOMBuf.Type::Item);
        BOMBuf.SetRange("No.", Item."No.");
        BOMBuf.FindFirst();

        RoundingFactor := 100 * LibraryERM.GetUnitAmountRoundingPrecision();
        Assert.AreNearlyEqual(RolledUpMaterialCost, BOMBuf."Rolled-up Material Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Rolled-up Material Cost"), Item."No."));
        Assert.AreNearlyEqual(RolledUpCapacityCost, BOMBuf."Rolled-up Capacity Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Rolled-up Capacity Cost"), Item."No."));
        Assert.AreNearlyEqual(RolledUpMfgOvhd, BOMBuf."Rolled-up Mfg. Ovhd Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Rolled-up Mfg. Ovhd Cost"), Item."No."));
        Assert.AreNearlyEqual(RolledUpCapOvhd, BOMBuf."Rolled-up Capacity Ovhd. Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Rolled-up Cap. Overhead Cost"), Item."No."));

        Assert.AreNearlyEqual(SglLevelMaterialCost, BOMBuf."Single-Level Material Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Single-Level Material Cost"), Item."No."));
        Assert.AreNearlyEqual(SglLevelCapCost, BOMBuf."Single-Level Capacity Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Single-Level Capacity Cost"), Item."No."));
        Assert.AreNearlyEqual(SglLevelMfgOvhd, BOMBuf."Single-Level Mfg. Ovhd Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Single-Level Mfg. Ovhd Cost"), Item."No."));
        Assert.AreNearlyEqual(SglLevelCapOvhd, BOMBuf."Single-Level Cap. Ovhd Cost", RoundingFactor,
          StrSubstNo(ERRWrongCostShareCalcErr, Item.FieldCaption("Single-Level Cap. Ovhd Cost"), Item."No."));
    end;

    local procedure VerifyTreeWithScrap(BOMBuf: Record "BOM Buffer"; Item: Record Item)
    var
        RolledUpTreeCostWithScrap: Decimal;
        SglLevelScrapCost: Decimal;
    begin
        LibraryTrees.GetTreeCostWithScrap(RolledUpTreeCostWithScrap, SglLevelScrapCost, Item);
        BOMBuf.SetRange(Type, BOMBuf.Type::Item);
        BOMBuf.SetRange("No.", Item."No.");
        BOMBuf.FindFirst();

        Assert.AreNearlyEqual(
            SglLevelScrapCost, BOMBuf."Single-Level Scrap Cost", LibraryERM.GetAmountRoundingPrecision(),
            STRSUBSTNO(ERRWrongCostShareCalcErr, BOMBuf.FIELDCAPTION("Single-Level Scrap Cost"), Item."No."));
        Assert.AreNearlyEqual(
            RolledUpTreeCostWithScrap, BOMBuf."Unit Cost", LibraryERM.GetAmountRoundingPrecision(),
            STRSUBSTNO(ERRWrongCostShareCalcErr, BOMBuf.FIELDCAPTION("Rolled-up Scrap Cost"), Item."No."));
    end;

    local procedure VerifyWarnings(BOMBuf: Record "BOM Buffer"; TableID: Integer; WarningText: Text[20])
    var
        BOMWarningLog: Record "BOM Warning Log";
    begin
        Assert.AreEqual(false, BOMBuf.AreAllLinesOk(BOMWarningLog), ERRWrongWarningParentErr);

        BOMWarningLog.SetRange("Table ID", TableID);
        BOMWarningLog.SetFilter("Table Position", '*' + WarningText + '*');
        Assert.AreEqual(1, BOMWarningLog.Count, StrSubstNo(ERRWrongWarningElementErr, WarningText));
    end;

    [StrMenuHandler]
    [Scope('OnPrem')]
    procedure CalcStdCostMenuHandler(Option: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Choice := 2;
    end;

    [ConfirmHandler]
    [Scope('OnPrem')]
    procedure ProducedCompConfirmHandler(Question: Text; var Reply: Boolean)
    begin
        Reply := true;
    end;
}

