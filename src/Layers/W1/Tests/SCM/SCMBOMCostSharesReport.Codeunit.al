codeunit 137391 "SCM - BOM Cost Shares Report"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [BOM Cost Share Distribution] [SCM]
        isInitialized := false;
    end;

    var
        GLBItem: Record Item;
        LibraryERM: Codeunit "Library - ERM";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryTrees: Codeunit "Library - Trees";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        Assert: Codeunit Assert;
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryAssembly: Codeunit "Library - Assembly";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        isInitialized: Boolean;
        GLBShowLevelAs: Option "First BOM Level","BOM Leaves";
        GLBShowCostShareAs: Option "Single-level","Rolled-up";
        IncorrectValueErr: Label 'Incorrect value of %1.%2.';

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(CODEUNIT::"SCM - BOM Cost Shares Report");
        // Initialize setup.
        LibraryVariableStorage.Clear();
        if isInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(CODEUNIT::"SCM - BOM Cost Shares Report");

        // Setup Demonstration data.
        isInitialized := true;
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        Commit();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(CODEUNIT::"SCM - BOM Cost Shares Report");
    end;

    [Test]
    procedure RolledUpCostShareNotAffectedByLotSizeWithRoutingAndNoBOM()
    var
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        BOMCostShares: TestPage "BOM Cost Shares";
        TotalLeafsRolledUpCapacityCost: Decimal;
    begin
        // [FEATURE] [BOM Cost Share] [UI] [UT]
        // [SCENARIO 305392] BOM Cost Shares page shows Rolled-up Material Cost and Rolled-up Capacity Cost not affected by a Lot Size value
        Initialize();

        SetupItemWithRoutingWithCosts(Item);

        UpdateItemLotSize(Item, LibraryRandom.RandIntInRange(3, 5));
        BOMCostShares.Trap();
        RunBOMCostSharesPage(Item);
        TotalLeafsRolledUpCapacityCost += GetRolledUpCapacityCostValue(BOMCostShares, BOMBuffer.Type::"Machine Center");
        TotalLeafsRolledUpCapacityCost += GetRolledUpCapacityCostValue(BOMCostShares, BOMBuffer.Type::"Work Center");
        VerifyParentItemMaterialAndCapacityCost(BOMCostShares, Item."No.", Item."Unit Cost", TotalLeafsRolledUpCapacityCost);
        BOMCostShares.Close();
    end;

    local procedure CreateCostSharesTree(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; Width: Integer; ShowLevelAs: Option; ShowDetails: Boolean; ShowCostShareAs: Option)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, Width, 2);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddOverhead(TempItem, TempResource, TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddSubcontracting(TempWorkCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));
        Item.Get(Item."No.");

        // Exercise: Run BOM Cost Shares Distribution Report.
        RunBOMCostSharesReport(Item, ShowLevelAs, ShowDetails, ShowCostShareAs);

        // Verify: Check the cost values for top item.
        if ShowCostShareAs = GLBShowCostShareAs::"Rolled-up" then
            VerifyBOMCostSharesReport(Item."No.",
              Item."Rolled-up Material Cost",
              Item."Rolled-up Capacity Cost",
              Item."Rolled-up Mfg. Ovhd Cost",
              Item."Rolled-up Cap. Overhead Cost",
              Item."Rolled-up Subcontracted Cost",
              Item."Unit Cost")
        else
            VerifyBOMCostSharesReport(Item."No.",
              Item."Single-Level Material Cost",
              Item."Single-Level Capacity Cost",
              Item."Single-Level Mfg. Ovhd Cost",
              Item."Single-Level Cap. Ovhd Cost",
              Item."Single-Level Subcontrd. Cost",
              Item."Unit Cost")
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMLeavesSglLvl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"BOM Leaves", true, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderBOMLeavesSglLvl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"BOM Leaves", true, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMLeavesRldUp()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"BOM Leaves", true, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderBOMLeavesRldUp()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"BOM Leaves", true, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyFstLvlSglLvl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"First BOM Level", true, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderFstLvlSglLvl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"First BOM Level", true, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyFstLvlRldUp()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 1, 1, GLBShowLevelAs::"First BOM Level", true, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderFstLvlRldUp()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"First BOM Level", true, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMLeavesSglLvlNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"BOM Leaves", false, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderBOMLeavesSglLvlNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"BOM Leaves", false, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMLeavesRldUpNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"BOM Leaves", false, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderBOMLeavesRldUpNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"BOM Leaves", false, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyFstLvlSglLvlNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"First BOM Level", false, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderFstLvlSglLvlNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"First BOM Level", false, GLBShowCostShareAs::"Single-level");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyFstLvlRldUpNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::Assembly, 2, 1, GLBShowLevelAs::"First BOM Level", false, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderFstLvlRldUpNoDtl()
    begin
        CreateCostSharesTree(
          GLBItem."Replenishment System"::"Prod. Order", 2, 1, GLBShowLevelAs::"First BOM Level", false, GLBShowCostShareAs::"Rolled-up");
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesPageHandlerRunDistribution,BOMCostSharesDistributionRequestPageHandler')]
    procedure OpeningBOMCostSharesPageForItemWithSpecialCharacterInName()
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
    begin
        // [FEATURE] [UT]
        // [SCENARIO 391950] Open BOM Cost Shares page for item with special character in name.
        Initialize();

        // [GIVEN] Item no. "ITEM1>" (with filter character '>' in name)
        Item.Init();
        Item."No." := LibraryUtility.GenerateGUID() + '>';
        Item.Description := Item."No.";
        Item.Insert(true);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, Item."No.", '', 1);
        Item.Validate("Base Unit of Measure", ItemUnitOfMeasure.Code);
        Item.Modify(true);

        // [GIVEN] Create BOM for the item.
        LibraryManufacturing.CreateProductionBOM(Item, 1);

        // [WHEN] Run BOM Cost Shares page and invoke BOM Cost Shares distribution report from it.
        // [THEN] The page and report are running okay with the item no. "ITEM1>".
        LibraryVariableStorage.Enqueue(Item."No.");
        LibraryVariableStorage.Enqueue(Item."No.");
        RunBOMCostSharesPage(Item);

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    procedure OnlyRunTimeIsMultipliedByQtyPerWhenCalculateQtyPerTopItem()
    var
        CompItem: Record Item;
        ProdItem: Record Item;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMBuffer: Record "BOM Buffer";
        BOMCostShares: TestPage "BOM Cost Shares";
        QtyPer: Integer;
    begin
        // [FEATURE] [Bom Cost Share] [Routing]
        // [SCENARIO 405462] Only Run Time is multiplied by "Quantity per" in "Qty. per Top Item" field for routing line in BOM Cost Shares page.
        Initialize();
        QtyPer := LibraryRandom.RandIntInRange(2, 10);

        // [GIVEN] Component item "C", final product "P".
        LibraryInventory.CreateItem(CompItem);
        LibraryInventory.CreateItem(ProdItem);

        // [GIVEN] Create routing, fill in "Setup Time", "Run Time", "Wait Time", and "Move Time".
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(1), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandInt(100));
        RoutingLine.Validate("Run Time", LibraryRandom.RandInt(100));
        RoutingLine.Validate("Wait Time", LibraryRandom.RandInt(100));
        RoutingLine.Validate("Move Time", LibraryRandom.RandInt(100));
        RoutingLine.Modify(true);
        LibraryManufacturing.UpdateRoutingStatus(RoutingHeader, RoutingHeader.Status::Certified);

        // [GIVEN] Production BOM with 2 pcs of component "C".
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ProdItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem."No.", QtyPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Assign the routing to component "C".
        CompItem.Find();
        CompItem.Validate("Replenishment System", CompItem."Replenishment System"::"Prod. Order");
        CompItem.Validate("Routing No.", RoutingHeader."No.");
        CompItem.Modify(true);

        // [GIVEN] Assign the production BOM to product "P", quantity per = 2 (!).
        ProdItem.Find();
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Modify(true);

        // [WHEN] Open "BOM Cost Shares" page for "P".
        BOMCostShares.Trap();
        RunBOMCostSharesPage(ProdItem);

        // [THEN] Locate the line that represents the routing.
        // [THEN] "Qty. per Parent" = "Run Time" + (setup + wait + move).
        // [THEN] "Qty. per Top Item" = "Run Time" * 2 + (setup + wait + move)
        BOMCostShares.Expand(true);
        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::"Work Center"));
        BOMCostShares.FILTER.SetFilter("No.", WorkCenter."No.");
        BOMCostShares."Qty. per Parent".AssertEquals(
          RoutingLine."Setup Time" + RoutingLine."Run Time" + RoutingLine."Wait Time" + RoutingLine."Move Time");
        BOMCostShares."Qty. per Top Item".AssertEquals(
          RoutingLine."Setup Time" + RoutingLine."Run Time" * QtyPer + RoutingLine."Wait Time" + RoutingLine."Move Time");
    end;

    local procedure SetupItemWithRoutingWithCosts(var Item: Record Item)
    begin
        LibraryAssembly.CreateItem(Item, Item."Costing Method"::FIFO, Item."Replenishment System"::"Prod. Order", '', '');
        Item.Validate("Unit Cost", LibraryRandom.RandDecInRange(50, 100, 2));
        Item.Modify(true);

        LibraryManufacturing.CreateProductionRouting(Item, LibraryRandom.RandInt(2));
        UpdateRoutingCostValues(Item."Routing No.");
    end;

    local procedure UpdateRoutingCostValues(RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        MachineCenter: Record "Machine Center";
        WorkCenter: Record "Work Center";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindSet();
        repeat
            case RoutingLine.Type of
                RoutingLine.Type::"Machine Center":
                    begin
                        MachineCenter.Get(RoutingLine."No.");
                        MachineCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(5));
                        MachineCenter.Modify(true);
                    end;
                RoutingLine.Type::"Work Center":
                    begin
                        WorkCenter.Get(RoutingLine."No.");
                        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandInt(5));
                        WorkCenter.Modify(true);
                    end;
            end;
        until RoutingLine.Next() = 0;
    end;

    local procedure UpdateItemLotSize(var Item: Record Item; NewLotSize: Integer)
    begin
        Item.Validate("Lot Size", NewLotSize);
        Item.Modify(true);
    end;

    local procedure TestCostSharesTreePage(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer; RoutingLines: Integer)
    var
        Item: Record Item;
        TempItem: Record Item temporary;
        TempResource: Record Resource temporary;
        TempWorkCenter: Record "Work Center" temporary;
        TempMachineCenter: Record "Machine Center" temporary;
        CalcStandardCost: Codeunit "Calculate Standard Cost";
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, RoutingLines);
        LibraryTrees.GetTree(TempItem, TempResource, TempWorkCenter, TempMachineCenter, Item);
        LibraryTrees.AddCostToRouting(TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddOverhead(TempItem, TempResource, TempWorkCenter, TempMachineCenter);
        LibraryTrees.AddSubcontracting(TempWorkCenter);
        CalcStandardCost.CalcItem(Item."No.", (Item."Replenishment System" = Item."Replenishment System"::Assembly));
        LibraryVariableStorage.Enqueue(Item."No.");

        // Exercise: Run BOM Cost SharesPage.
        RunBOMCostSharesPage(Item);

        // Verify: Cost fields on BOM Cost Shares page: In Page Handler.
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,ProducedCompConfirmHandler,BOMCostSharesPageHandler,NoWarningsMessageHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyPage()
    begin
        TestCostSharesTreePage(GLBItem."Replenishment System"::Assembly, 2, 1, 2);
    end;

    [Test]
    [HandlerFunctions('CalcStdCostMenuHandler,BOMCostSharesPageHandler,NoWarningsMessageHandler,BOMCostSharesDistribReportHandler')]
    [Scope('OnPrem')]
    procedure TopItemProdOrderPage()
    begin
        TestCostSharesTreePage(GLBItem."Replenishment System"::"Prod. Order", 2, 1, 2);
    end;

    local procedure TestBOMStructurePage(TopItemReplSystem: Enum "Replenishment System"; Depth: Integer; ChildLeaves: Integer)
    var
        Item: Record Item;
    begin
        // Setup.
        Initialize();
        LibraryTrees.CreateMixedTree(Item, TopItemReplSystem, Item."Costing Method"::Standard, Depth, ChildLeaves, 2);
        LibraryVariableStorage.Enqueue(Item."No.");

        // Exercise: Run BOM Cost SharesPage.
        RunBOMStructurePage(Item);

        // Verify: Cost fields on BOM Structure page: In Page Handler.
    end;

    [Test]
    [HandlerFunctions('BOMStructurePageHandler,NoWarningsMessageHandler,ItemAvailabilityByBOMPageHandler')]
    [Scope('OnPrem')]
    procedure TopItemAssemblyBOMStructurePage()
    begin
        TestBOMStructurePage(GLBItem."Replenishment System"::Assembly, 2, 1);
    end;

    [Test]
    [Scope('OnPrem')]
    procedure TestQtyPerParentOnCostSharesPage()
    var
        Item: Record Item;
        BOMBuffer: Record "BOM Buffer";
        BOMCostShares: TestPage "BOM Cost Shares";
        QtyPerParent: Decimal;
        QtyPerTopItem: Decimal;
    begin
        // [SCENARIO 268941] Test "Qty. per Parent" field on BOM Cost Shares page when a BOM tree includes nested Production BOMs.
        Initialize();

        // [GIVEN] Create a BOM tree with Production BOMs having lines typed of "Production BOM".
        LibraryTrees.CreateMixedTree(Item, Item."Replenishment System"::"Prod. Order", Item."Costing Method"::Standard, 2, 2, 0);

        // [WHEN] Run BOM Cost Shares page.
        BOMCostShares.Trap();
        RunBOMCostSharesPage(Item);

        // [THEN] Verify "Qty. per Parent" field on the page.
        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.Expand(true);
        while BOMCostShares.Next() do begin
            BOMCostShares.Expand(true);
            LibraryTrees.GetQtyPerInTree(QtyPerParent, QtyPerTopItem, Item."No.", Format(BOMCostShares."No."));
            Assert.AreEqual(QtyPerParent, BOMCostShares."Qty. per Parent".AsDecimal(), 'Qty. per Parent is invalid.');
        end;
    end;

    [Test]
    procedure CostSharesIncludesComponentsWithNegativeQtyPer()
    var
        ProdItem: Record Item;
        CompItem: array[2] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMCostShares: TestPage "BOM Cost Shares";
        QtyPer: Decimal;
    begin
        // [FEATURE] [Production BOM] [BOM Cost Share]
        // [SCENARIO 387285] BOM Cost Shares Page shows production BOM components with negative Quantity Per.
        Initialize();

        // [GIVEN] Two component items "P" and "N".
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

        // [GIVEN] Certified production BOM with two lines.
        // [GIVEN] 1st line: No. = "P", Quantity Per = 20.
        // [GIVEN] 2nd line: No. = "N", Quantity Per = -20 (negative).
        QtyPer := LibraryRandom.RandIntInRange(10, 20);
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

        // [WHEN] Run BOM Cost Shares page for item "A".
        BOMCostShares.Trap();
        RunBOMCostSharesPage(ProdItem);

        // [THEN] A line exists for the component "P" with "Quantity Per Parent" = 20
        BOMCostShares.Expand(true);
        BOMCostShares.FILTER.SetFilter("No.", CompItem[1]."No.");
        BOMCostShares."Qty. per Parent".AssertEquals(QtyPer);

        // [THEN] A line exists for the component "N" with "Quantity Per Parent" = -20
        BOMCostShares.FILTER.SetFilter("No.", CompItem[2]."No.");
        BOMCostShares."Qty. per Parent".AssertEquals(-QtyPer);
    end;

    [Test]
    [HandlerFunctions('BOMStructureVerifyComponentPageHandler')]
    procedure BOMStructureIncludesComponentsWithNegativeQtyPer()
    var
        ProdItem: Record Item;
        CompItem: array[2] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        QtyPer: Decimal;
    begin
        // [FEATURE] [Production BOM] [BOM Structure]
        // [SCENARIO 398178] BOM Structure page shows production BOM components with negative Quantity Per.
        Initialize();
        QtyPer := LibraryRandom.RandIntInRange(10, 20);

        // [GIVEN] Two component items "P" and "N".
        LibraryInventory.CreateItem(CompItem[1]);
        LibraryInventory.CreateItem(CompItem[2]);

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

        // [WHEN] Open BOM Structure page for item "A".
        LibraryVariableStorage.Enqueue(CompItem[2]."No.");
        LibraryVariableStorage.Enqueue(-QtyPer);
        RunBOMStructurePage(ProdItem);

        // [THEN] Negative component "N" is present in the BOM structure.
        // Verification is done in BOMStructureVerifyComponentPageHandler.

        LibraryVariableStorage.AssertEmpty();
    end;

    [Test]
    [HandlerFunctions('AllLevelsStrMenuHandler')]
    procedure VerifyCostsOnBOMCostSharesForWorkCenterWithLotSize()
    var
        MfgSetup: Record "Manufacturing Setup";
        WorkCenter: Record "Work Center";
        ProdItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        BOMBuffer: Record "BOM Buffer";
        CompItem: array[2] of Record Item;
        BOMCostShares: TestPage "BOM Cost Shares";
        CalculateStandardCost: Codeunit "Calculate Standard Cost";
        RoutingNo: Code[20];
        LotSize, Scrap, Cost, Rounding : Decimal;
    begin
        // [SCENARIO 460218] Verify Cost Shares are calculated correctly for Work Center, with Lot Size defined
        Initialize();

        // [GIVEN] Init values
        LotSize := 100;
        Scrap := 10;
        Cost := 10;
        Rounding := 0.00001;

        // [GIVEN] Set Cost Incl. Setup to true on Manufacturing Setup
        LibraryManufacturing.UpdateManufacturingSetup(MfgSetup, '', '', true, true, true);

        // [GIVEN] Create Work Center with Calendar
        CreateWorkCenterWithCalendar(WorkCenter);

        // [GIVEN] Create Prod. and Comp. Items
        CreateItems(ProdItem, CompItem, LotSize, Scrap, Cost, Rounding);

        // [GIVEN] Create Production BOM
        CreateProductionBOM(ProductionBOMHeader, CompItem);

        // [GIVEN] Create Routing for Work Center
        RoutingNo := CreateRoutingWithWorkCenter(WorkCenter."No.", 10, 2, LotSize);

        // [GIVEN] Update Item with Production BOM and Routing No.
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        ProdItem.Validate("Routing No.", RoutingNo);
        ProdItem.Modify(true);

        // [WHEN] Calculate Standard Cost for "PI"
        CalculateStandardCost.CalcItem(ProdItem."No.", false);

        // [THEN] Standard cost is 61
        ProdItem.Find();
        Assert.AreNearlyEqual(61, ProdItem."Standard Cost", ProdItem."Rounding Precision", StrSubstNo(IncorrectValueErr, ProdItem.TableName, ProdItem.FieldName("Standard Cost")));

        // [WHEN] Cost Shares
        BOMCostShares.Trap();
        RunBOMCostSharesPage(ProdItem);

        // [THEN] Verify Cost Shares for Work Center
        BOMCostShares.Expand(true);
        BOMCostShares.Filter.SetFilter(Type, Format(BOMBuffer.Type::"Work Center"));
        BOMCostShares.Filter.SetFilter("No.", WorkCenter."No.");
        BOMCostShares."Qty. per Parent".AssertEquals(0.12);
        BOMCostShares."Qty. per Top Item".AssertEquals(0.12);
        BOMCostShares."Rolled-up Capacity Cost".AssertEquals(6);
        BOMCostShares.Close();
    end;

    [Test]
    procedure RolledUpMaterialAndCapacityCostWithRoutingAndNoBOM()
    var
        FinalItem: Record Item;
        InterimItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        BOMBuffer: Record "BOM Buffer";
        BOMCostShares: TestPage "BOM Cost Shares";
        TotalLeafsRolledUpCapacityCost: Decimal;
        QtyPer: Decimal;
    begin
        // [FEATURE] [BOM Cost Share]
        // [SCENARIO 500356] Rolled-up Material Cost and Rolled-up Capacity Cost for a interim production item with no BOM.
        Initialize();
        QtyPer := LibraryRandom.RandIntInRange(5, 10);

        LibraryAssembly.CreateItem(InterimItem, InterimItem."Costing Method"::FIFO, InterimItem."Replenishment System"::"Prod. Order", '', '');
        InterimItem.Validate("Unit Cost", LibraryRandom.RandDecInRange(50, 100, 2));
        InterimItem.Modify(true);
        LibraryManufacturing.CreateProductionRouting(InterimItem, LibraryRandom.RandInt(2));
        UpdateRoutingCostValues(InterimItem."Routing No.");

        LibraryAssembly.CreateItem(FinalItem, FinalItem."Costing Method"::FIFO, FinalItem."Replenishment System"::"Prod. Order", '', '');
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, FinalItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, InterimItem."No.", QtyPer);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
        FinalItem.Validate("Production BOM No.", ProductionBOMHeader."No.");
        FinalItem.Modify(true);

        BOMCostShares.Trap();
        RunBOMCostSharesPage(FinalItem);
        TotalLeafsRolledUpCapacityCost += GetRolledUpCapacityCostValue(BOMCostShares, BOMBuffer.Type::"Machine Center");
        TotalLeafsRolledUpCapacityCost += GetRolledUpCapacityCostValue(BOMCostShares, BOMBuffer.Type::"Work Center");
        VerifyParentItemMaterialAndCapacityCost(BOMCostShares, InterimItem."No.", InterimItem."Unit Cost" * QtyPer, TotalLeafsRolledUpCapacityCost);
        BOMCostShares.Close();
    end;

    [Test]
    procedure BOMCostSharePageCorrectlyPopulateMaterialandTotalCosts()
    var
        Item: array[2] of Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        RoutingNo: Code[20];
        StandardCost: Decimal;
        UnitCostPer: Integer;
        BOMCostShares: TestPage "BOM Cost Shares";
    begin
        // [SCENARIO 533684] When Stan runs BOM Cost Share Page for Parent Item then Rolled-up Material Cost,
        // Total Cost are correctly populated for Parent and Component Item.
        Initialize();

        // [GIVEN] Create a Vendor.
        LibraryPurchase.CreateVendor(Vendor);

        // [GIVEN] Create a Work Center with Calendar.
        CreateWorkCenterWithSpecificUnitCostWithCalendar(WorkCenter, Vendor."No.");

        // [GIVEN] Generate a Unit Cost Per and save it in a Variable.
        UnitCostPer := LibraryRandom.RandIntInRange(10, 10);

        // [GIVEN] Create a Routing for Work Center and Update Unit Cost Per.
        RoutingNo := CreateRoutingWithWorkCenter(WorkCenter."No.", 0, 0, 0);
        UpdateUnitCostPerOnRoutingLine(RoutingNo, UnitCostPer);

        // [GIVEN] Generate a Standard Cost and save it in a Variable.
        StandardCost := LibraryRandom.RandDecInDecimalRange(100, 100, 2);

        // [GIVEN] Create a Component Item.
        CreateItem(Item[1], StandardCost);
        Item[1].Validate(Item[1]."Routing No.", RoutingNo);
        Item[1].Modify(true);

        // [GIVEN] Create a Production BOM.
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item[1]."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, Item[1]."No.", LibraryRandom.RandInt(0));
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);

        // [GIVEN] Create a Parent Item.
        CreateItem(Item[2], 0);
        Item[2].Validate(Item[1]."Production BOM No.", ProductionBOMHeader."No.");
        Item[1].Modify(true);

        // [WHEN] Run BOM Cost Share Page from Parent Item.
        BOMCostShares.Trap();
        RunBOMCostSharesPage(Item[2]);
        BOMCostShares.Expand(true);

        // [THEN] Verify Rolled-up Material Cost, Total Cost for Component Item.
        VerifyBOMCost(BOMCostShares, Item[1]."No.", StandardCost, (StandardCost + UnitCostPer));

        // [THEN] Verify Rolled-up Material Cost, Total Cost for Parent Item.
        VerifyBOMCost(BOMCostShares, Item[2]."No.", StandardCost, (StandardCost + UnitCostPer));

        BOMCostShares.Close();
    end;

    [Test]
    [HandlerFunctions('BOMCostSharesHandler')]
    [Scope('OnPrem')]
    procedure QtyPerParentInCostSharesIncludeFixedScrpQtyOfRoutingEvenIfCompIsOfSubProdBOM()
    var
        ProdItem: Record Item;
        CompItem: array[3] of Record Item;
        ProductionBOMHeader: array[2] of Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
        QtyPerParent: Decimal;
    begin
        // [SCENARIO 305392] 
        Initialize();

        // [GIVEN] Create a Production Item.
        CreateItem(ProdItem);

        // [GIVEN] Create three Component Items.
        CreateItem(CompItem[1]);
        CreateItem(CompItem[2]);
        CreateItem(CompItem[3]);

        // [GIVEN] Create a Work Center.
        CreateWorkCenter(WorkCenter);

        // [GIVEN] Create and Certify Routing.
        CreateAndCertifyRouting(RoutingHeader, RoutingLine, WorkCenter);

        // [GIVEN] Create and Certify Production BOM.
        CreateAndCertifyProductionBOM(ProductionBOMHeader[1], ProductionBOMHeader[2], CompItem[1], CompItem[2], CompItem[3]);

        // [GIVEN] Find Production BOM Line.
        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader[1]."No.");
        ProductionBOMLine.FindFirst();

        // [GIVEN] Generate and save Qty. per Parent in a Variable.
        QtyPerParent := ProductionBOMLine."Quantity per" + RoutingLine."Fixed Scrap Quantity" + ProductionBOMLine."Scrap %" / 100;

        // [GIVEN] Validate "Costing Method", "Unit Cost", "Routing No." and 
        // "Production BOM No." in ProdItem.
        ProdItem.Validate("Costing Method", ProdItem."Costing Method"::FIFO);
        ProdItem.Validate("Unit Cost", 0);
        ProdItem.Validate("Routing No.", RoutingHeader."No.");
        ProdItem.Validate("Production BOM No.", ProductionBOMHeader[2]."No.");
        ProdItem.Modify(true);

        // [WHEN] Run BOM Cost Shares page.
        LibraryVariableStorage.Enqueue(QtyPerParent);
        LibraryVariableStorage.Enqueue(Format(CompItem[1]."No."));
        LibraryVariableStorage.Enqueue(Format(CompItem[2]."No."));
        LibraryVariableStorage.Enqueue(Format(CompItem[3]."No."));
        RunBOMCostSharesPage(ProdItem);

        // [THEN] "Qty. per Parent" of all Component Items in BOM Cost Shares page
        // is equal to QtyPerParent in BOMCostSharesHandler.
    end;

    local procedure CreateRoutingWithWorkCenter(WorkCenterNo: Code[20]; SetupTime: Decimal; RunTime: Decimal; LotSize: Decimal): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
          RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandInt(100)), RoutingLine.Type::"Work Center", WorkCenterNo);
        RoutingLine.Validate("Setup Time", SetupTime);
        RoutingLine.Validate("Run Time", RunTime);
        RoutingLine.Validate("Lot Size", LotSize);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure CreateProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; CompItem: array[2] of Record Item)
    var
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, CompItem[1]."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[1]."No.", 1);
        LibraryManufacturing.CreateProductionBOMLine(
          ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, CompItem[2]."No.", 2);
        LibraryManufacturing.UpdateProductionBOMStatus(ProductionBOMHeader, ProductionBOMHeader.Status::Certified);
    end;

    local procedure CreateItems(var ProdItem: Record Item; var CompItem: array[2] of Record Item; LotSize: Decimal; Scrap: Decimal; Cost: Decimal; Rounding: Decimal)
    begin
        LibraryInventory.CreateItem(CompItem[1]);
        UpdateItemData(CompItem[1], Cost, Scrap, Rounding);
        LibraryInventory.CreateItem(CompItem[2]);
        UpdateItemData(CompItem[2], Cost * 2, Scrap, Rounding);
        LibraryInventory.CreateItem(ProdItem);
        ProdItem.Validate("Costing Method", ProdItem."Costing Method"::Standard);
        ProdItem.Validate("Replenishment System", ProdItem."Replenishment System"::"Prod. Order");
        ProdItem.Validate("Rounding Precision", Rounding);
        ProdItem.Validate("Lot Size", LotSize);
        ProdItem.Modify(true);
    end;

    local procedure UpdateItemData(var Item: Record Item; Cost: Decimal; Scrap: Decimal; Rounding: Decimal)
    begin
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", Cost);
        Item.Validate("Scrap %", Scrap);
        Item.Validate("Rounding Precision", Rounding);
        Item.Modify(true);
    end;

    local procedure CreateWorkCenterWithCalendar(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Direct Unit Cost", 50);
        WorkCenter.Validate("Unit of Measure Code", 'HOURS');
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate(Efficiency, 100);
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', Today()), CalcDate('<1M>', Today()));
    end;

    local procedure RunBOMCostSharesReport(Item: Record Item; ShowLevelAs: Option; ShowDetails: Boolean; ShowCostShareAs: Option)
    var
        Item1: Record Item;
    begin
        Item1.SetRange("No.", Item."No.");
        Commit();
        LibraryVariableStorage.Enqueue(ShowCostShareAs);
        LibraryVariableStorage.Enqueue(ShowLevelAs);
        LibraryVariableStorage.Enqueue(ShowDetails);
        REPORT.Run(REPORT::"BOM Cost Share Distribution", true, false, Item1);
    end;

    local procedure VerifyBOMCostSharesReport(ItemNo: Code[20]; ExpMaterialCost: Decimal; ExpCapacityCost: Decimal; ExpMfgOvhdCost: Decimal; ExpCapOvhdCost: Decimal; ExpSubcontractedCost: Decimal; ExpTotalCost: Decimal)
    var
        CostAmount: Decimal;
        RoundingFactor: Decimal;
    begin
        RoundingFactor := 100 * LibraryERM.GetUnitAmountRoundingPrecision();

        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.SetRange('ItemNo', ItemNo);

        CostAmount := LibraryReportDataset.Sum('MaterialCost');
        Assert.AreNearlyEqual(ExpMaterialCost, CostAmount, RoundingFactor, 'Wrong Material Cost in item ' + ItemNo);

        CostAmount := LibraryReportDataset.Sum('CapacityCost');
        Assert.AreNearlyEqual(ExpCapacityCost, CostAmount, RoundingFactor, 'Wrong Capacity Cost in item ' + ItemNo);

        CostAmount := LibraryReportDataset.Sum('MfgOvhdCost');
        Assert.AreNearlyEqual(ExpMfgOvhdCost, CostAmount, RoundingFactor, 'Wrong Mfg. Overhead in item ' + ItemNo);

        CostAmount := LibraryReportDataset.Sum('CapOvhdCost');
        Assert.AreNearlyEqual(ExpCapOvhdCost, CostAmount, RoundingFactor, 'Wrong Cap. Overhead in item ' + ItemNo);

        CostAmount := LibraryReportDataset.Sum('SubcontrdCost');
        Assert.AreNearlyEqual(
          ExpSubcontractedCost, CostAmount, RoundingFactor, 'Wrong Subcontracted Cost in item ' + ItemNo);

        CostAmount := LibraryReportDataset.Sum('TotalCost');
        Assert.AreNearlyEqual(ExpTotalCost, CostAmount, RoundingFactor, 'Wrong Total Cost in item ' + ItemNo);
    end;

    local procedure RunBOMCostSharesPage(var Item: Record Item)
    var
        BOMCostShares: Page "BOM Cost Shares";
    begin
        BOMCostShares.InitItem(Item);
        BOMCostShares.Run();
    end;

    local procedure VerifyBOMCostSharesPage(var BOMCostShares: TestPage "BOM Cost Shares"; ItemNo: Code[20]; ExpMaterialCost: Decimal; ExpCapacityCost: Decimal; ExpMfgOvhdCost: Decimal; ExpCapOvhdCost: Decimal; ExpSubcontractedCost: Decimal; ExpTotalCost: Decimal)
    var
        BOMBuffer: Record "BOM Buffer";
        RoundingFactor: Decimal;
    begin
        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.FILTER.SetFilter("No.", ItemNo);
        BOMCostShares.First();

        RoundingFactor := 100 * LibraryERM.GetUnitAmountRoundingPrecision();
        Assert.AreNearlyEqual(
          ExpMaterialCost, BOMCostShares."Rolled-up Material Cost".AsDecimal(), RoundingFactor,
          'Wrong Material Cost in item ' + ItemNo);
        Assert.AreNearlyEqual(
          ExpCapacityCost, BOMCostShares."Rolled-up Capacity Cost".AsDecimal(), RoundingFactor,
          'Wrong Capacity Cost in item ' + ItemNo);
        Assert.AreNearlyEqual(
          ExpMfgOvhdCost, BOMCostShares."Rolled-up Mfg. Ovhd Cost".AsDecimal(), RoundingFactor,
          'Wrong Mfg. Overhead in item ' + ItemNo);
        Assert.AreNearlyEqual(
          ExpCapOvhdCost, BOMCostShares."Rolled-up Capacity Ovhd. Cost".AsDecimal(), RoundingFactor,
          'Wrong Cap. Overhead in item ' + ItemNo);
        Assert.AreNearlyEqual(
          ExpSubcontractedCost, BOMCostShares."Rolled-up Subcontracted Cost".AsDecimal(), RoundingFactor,
          'Wrong Subcontracted Cost in item ' + ItemNo);
        Assert.AreNearlyEqual(
          ExpTotalCost, BOMCostShares."Total Cost".AsDecimal(), RoundingFactor, 'Wrong Total Cost in item ' + ItemNo);
    end;

    local procedure VerifyParentItemMaterialAndCapacityCost(var BOMCostShares: TestPage "BOM Cost Shares"; ItemNo: Code[20]; ExpectedItemCost: Decimal; ExpectedCapacityCost: Decimal)
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.FILTER.SetFilter("No.", ItemNo);
        BOMCostShares.First();
        BOMCostShares."Rolled-up Material Cost".AssertEquals(ExpectedItemCost);
        BOMCostShares."Rolled-up Capacity Cost".AssertEquals(ExpectedCapacityCost);
    end;

    local procedure GetRolledUpCapacityCostValue(var BOMCostShares: TestPage "BOM Cost Shares"; BOMBufferType: Enum "BOM Type"): Decimal
    begin
        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBufferType));
        BOMCostShares.First();
        exit(BOMCostShares."Rolled-up Capacity Cost".AsDecimal());
    end;

    local procedure RunBOMStructurePage(var Item: Record Item)
    var
        BOMStructure: Page "BOM Structure";
    begin
        BOMStructure.InitItem(Item);
        BOMStructure.Run();
    end;

    local procedure CreateWorkCenterWithSpecificUnitCostWithCalendar(var WorkCenter: Record "Work Center"; SubContractorNo: Code[20])
    begin
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Work Center Group Code", '1');
        WorkCenter.Validate("Specific Unit Cost", true);
        WorkCenter.Validate("Unit Cost Calculation", WorkCenter."Unit Cost Calculation"::Units);
        WorkCenter.Validate("Unit of Measure Code", 'MINUTES');
        WorkCenter.Validate(Capacity, 1);
        WorkCenter.Validate(Efficiency, 100);
        WorkCenter.Validate("Shop Calendar Code", '1');
        WorkCenter.Validate("Subcontractor No.", SubContractorNo);
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-1M>', Today()), CalcDate('<1M>', Today()));
    end;

    local procedure UpdateUnitCostPerOnRoutingLine(RoutingNo: Code[20]; UnitCostPer: Decimal)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
    begin
        RoutingHeader.Get(RoutingNo);
        RoutingHeader.Validate(Status, RoutingHeader.Status::"Under Development");
        RoutingHeader.Modify(true);

        RoutingLine.SetRange("Routing No.", RoutingHeader."No.");
        RoutingLine.FindFirst();
        RoutingLine.Validate("Unit Cost per", UnitCostPer);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateItem(var Item: Record Item; StandardCost: Decimal)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Standard Cost", StandardCost);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Manufacturing Policy", Item."Manufacturing Policy"::"Make-to-Order");
        Item.Modify(true);
    end;

    local procedure VerifyBOMCost(
        var BOMCostShares: TestPage "BOM Cost Shares"; ItemNo: Code[20];
        ExpectedRolledUpMatCost: Decimal; ExpectedTotalCost: Decimal)
    var
        BOMBuffer: Record "BOM Buffer";
    begin
        BOMCostShares.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.FILTER.SetFilter("No.", ItemNo);
        BOMCostShares.First();
        BOMCostShares."Rolled-up Material Cost".AssertEquals(ExpectedRolledUpMatCost);
        BOMCostShares."Total Cost".AssertEquals(ExpectedTotalCost);
    end;

    local procedure CreateItem(var Item: Record Item)
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Costing Method", Item."Costing Method"::Standard);
        Item.Validate("Unit Cost", LibraryRandom.RandIntInRange(1, 1));
        Item.Modify(true);
    end;

    local procedure CreateWorkCenter(var WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateWorkCenterWithCalendar(WorkCenter);
        WorkCenter.Validate("Unit Cost", LibraryRandom.RandDec(100, 2));
        WorkCenter.Validate(Capacity, LibraryRandom.RandIntInRange(3, 3));
        WorkCenter.Validate(Efficiency, LibraryRandom.RandIntInRange(100, 100));
        WorkCenter.Modify(true);
    end;

    local procedure CreateAndCertifyRouting(var RoutingHeader: Record "Routing Header"; var RoutingLine: Record "Routing Line"; WorkCenter: Record "Work Center")
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', Format(LibraryRandom.RandIntInRange(10, 10)), RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", LibraryRandom.RandIntInRange(10, 10));
        RoutingLine.Validate("Run Time", LibraryRandom.RandIntInRange(10, 10));
        RoutingLine.Validate("Fixed Scrap Quantity", LibraryRandom.RandIntInRange(5, 5));
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
    end;

    local procedure CreateAndCertifyProductionBOM(var ProductionBOMHeader: Record "Production BOM Header"; var ProductionBOMHeader2: Record "Production BOM Header"; Item: Record Item; Item2: Record Item; Item3: Record Item)
    var
        ProductionBOMLine: array[4] of Record "Production BOM Line";
    begin
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, Item."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine[1], '', ProductionBOMLine[1].Type::Item, Item."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionBOMLine[1].Validate("Scrap %", LibraryRandom.RandIntInRange(5, 5));
        ProductionBOMLine[1].Modify(true);

        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine[2], '', ProductionBOMLine[2].Type::Item, Item2."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionBOMLine[2].Validate("Scrap %", LibraryRandom.RandIntInRange(5, 5));
        ProductionBOMLine[2].Modify(true);

        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader2, Item3."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader2, ProductionBOMLine[3], '', ProductionBOMLine[3].Type::"Production BOM", ProductionBOMHeader."No.", LibraryRandom.RandIntInRange(1, 1));

        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader2, ProductionBOMLine[4], '', ProductionBOMLine[4].Type::Item, Item3."No.", LibraryRandom.RandIntInRange(1, 1));
        ProductionBOMLine[4].Validate("Scrap %", LibraryRandom.RandIntInRange(5, 5));
        ProductionBOMLine[4].Modify(true);

        ProductionBOMHeader2.Validate(Status, ProductionBOMHeader2.Status::Certified);
        ProductionBOMHeader2.Modify(true);
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

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesPageHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        Item: Record Item;
        VariantVar: Variant;
        ShowLevelAs: Option "First BOM Level","BOM Leaves";
        ShowCostShareAs: Option "Single-level","Rolled-up";
        ItemNo: Code[20];
    begin
        LibraryVariableStorage.Dequeue(VariantVar);
        ItemNo := VariantVar;
        Item.Get(ItemNo);
        VerifyBOMCostSharesPage(BOMCostShares, Item."No.", Item."Rolled-up Material Cost", Item."Rolled-up Capacity Cost",
          Item."Rolled-up Mfg. Ovhd Cost", Item."Rolled-up Cap. Overhead Cost", Item."Rolled-up Subcontracted Cost", Item."Unit Cost");

        Commit();
        BOMCostShares."Show Warnings".Invoke(); // Call Show Warnings for code coverage purposes.

        // Enqueue parameters for report.
        LibraryVariableStorage.Enqueue(ShowCostShareAs::"Single-level");
        LibraryVariableStorage.Enqueue(ShowLevelAs::"BOM Leaves");
        LibraryVariableStorage.Enqueue(true);
        BOMCostShares."BOM Cost Share Distribution".Invoke(); // Call BOM Cost Shares distribution report for code coverage purposes.
        BOMCostShares.OK().Invoke();
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesHandler(var BOMCostShares: TestPage "BOM Cost Shares")
    var
        BOMBuffer: Record "BOM Buffer";
        Variant: Variant;
        CompItemNo: array[3] of Code[20];
        QtyPerParent: Decimal;
    begin
        LibraryVariableStorage.Dequeue(Variant);
        QtyPerParent := Variant;
        LibraryVariableStorage.Dequeue(Variant);
        CompItemNo[1] := Variant;
        LibraryVariableStorage.Dequeue(Variant);
        CompItemNo[2] := Variant;
        LibraryVariableStorage.Dequeue(Variant);
        CompItemNo[3] := Variant;

        BOMCostShares.Filter.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.Filter.SetFilter("No.", CompItemNo[1]);
        BOMCostShares.First();
        BOMCostShares."Qty. per Parent".AssertEquals(QtyPerParent);

        BOMCostShares.Filter.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.Filter.SetFilter("No.", CompItemNo[2]);
        BOMCostShares.First();
        BOMCostShares."Qty. per Parent".AssertEquals(QtyPerParent);

        BOMCostShares.Filter.SetFilter(Type, Format(BOMBuffer.Type::Item));
        BOMCostShares.Filter.SetFilter("No.", CompItemNo[3]);
        BOMCostShares.First();
        BOMCostShares."Qty. per Parent".AssertEquals(QtyPerParent);
    end;

    [MessageHandler]
    [Scope('OnPrem')]
    procedure NoWarningsMessageHandler(Message: Text)
    begin
    end;

    [RequestPageHandler]
    [Scope('OnPrem')]
    procedure BOMCostSharesDistribReportHandler(var BOMCostShareDistribution: TestRequestPage "BOM Cost Share Distribution")
    var
        ShowCostShareAs: Variant;
        ShowLevelAs: Variant;
        ShowDetails: Variant;
    begin
        LibraryVariableStorage.Dequeue(ShowCostShareAs);
        LibraryVariableStorage.Dequeue(ShowLevelAs);
        LibraryVariableStorage.Dequeue(ShowDetails);

        BOMCostShareDistribution.ShowCostShareAs.SetValue(ShowCostShareAs);
        BOMCostShareDistribution.ShowLevelAs.SetValue(ShowLevelAs);
        BOMCostShareDistribution.ShowDetails.SetValue(ShowDetails);
        BOMCostShareDistribution.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [PageHandler]
    procedure BOMCostSharesPageHandlerRunDistribution(var BOMCostShares: TestPage "BOM Cost Shares")
    begin
        BOMCostShares.ItemFilter.AssertEquals(StrSubstNo('''%1''', LibraryVariableStorage.DequeueText()));

        Commit();
        BOMCostShares."BOM Cost Share Distribution".Invoke();
        BOMCostShares.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure BOMCostSharesDistributionRequestPageHandler(var BOMCostShareDistribution: TestRequestPage "BOM Cost Share Distribution")
    begin
        Assert.AreEqual(
          StrSubstNo('''%1''', LibraryVariableStorage.DequeueText()),
          BOMCostShareDistribution.Item.GetFilter(BOMCostShareDistribution.Item."No."), '');
    end;

    [PageHandler]
    [Scope('OnPrem')]
    procedure BOMStructurePageHandler(var BOMStructure: TestPage "BOM Structure")
    var
        BOMBuffer: Record "BOM Buffer";
        VariantVar: Variant;
        ShowLevelAs: Option "First BOM Level","BOM Leaves";
        ShowCostShareAs: Option "Single-level","Rolled-up";
        ItemNo: Code[20];
        QtyPerParent: Decimal;
        QtyPerTopItem: Decimal;
    begin
        LibraryVariableStorage.Dequeue(VariantVar);
        ItemNo := VariantVar;

        BOMStructure.Expand(true);
        BOMStructure.FILTER.SetFilter(Type, Format(BOMBuffer.Type::Item));
        while BOMStructure.Next() do begin
            LibraryTrees.GetQtyPerInTree(QtyPerParent, QtyPerTopItem, ItemNo, Format(BOMStructure."No."));
            Assert.AreEqual(
              QtyPerParent, BOMStructure."Qty. per Parent".AsDecimal(), 'Wrong Qty per parent on page for item ' + Format(BOMStructure."No."));
            Assert.AreEqual(false, BOMStructure.HasWarning.AsBoolean(), 'Unexpected warning present in item ' + Format(BOMStructure."No."));
        end;

        Commit();
        BOMStructure."Show Warnings".Invoke(); // Call Show Warnings for code coverage purposes.

        // Enqueue parameters for report.
        LibraryVariableStorage.Enqueue(ShowCostShareAs::"Single-level");
        LibraryVariableStorage.Enqueue(ShowLevelAs::"BOM Leaves");
        LibraryVariableStorage.Enqueue(true);
        BOMStructure."BOM Level".Invoke(); // Call BOM Cost Shares distribution report for code coverage purposes.
        BOMStructure.OK().Invoke();
    end;

    [PageHandler]
    procedure BOMStructureVerifyComponentPageHandler(var BOMStructure: TestPage "BOM Structure")
    begin
        BOMStructure.Expand(true);
        BOMStructure.FILTER.SetFilter("No.", LibraryVariableStorage.DequeueText());
        BOMStructure."Qty. per Parent".AssertEquals(LibraryVariableStorage.DequeueDecimal());
    end;

    [ModalPageHandler]
    [Scope('OnPrem')]
    procedure ItemAvailabilityByBOMPageHandler(var ItemAvailByBOMLevel: TestPage "Item Availability by BOM Level")
    begin
        ItemAvailByBOMLevel.OK().Invoke();
    end;

    [StrMenuHandler]
    procedure AllLevelsStrMenuHandler(StrMenuText: Text; var Choice: Integer; InstructionText: Text)
    begin
        Choice := 2; // All levels
    end;
}

