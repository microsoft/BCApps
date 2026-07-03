// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137424 "Prod. Def. Wiz. Source Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - Source Prioritization & Scenario Resolution
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ProdDefWizLibrary: Codeunit "Prod. Def. Wiz. Library";
        ProdDefWizSetupLib: Codeunit "Prod. Def. Wiz. Setup Lib.";
        ProdDefWizCheckLib: Codeunit "Prod. Def. Wiz. Check Lib.";
        IsInitialized: Boolean;
        WizardFinished: Boolean;
        // Handler state
        ActualSourceText: Text;
        ActualBOMNoFromWizardB5: Code[20];
        ActualRoutingNoFromWizardB5: Code[20];

    [Test]
    [HandlerFunctions('HandleWizardCaptureSourceWithSave')]
    procedure TestB1_NeitherHasData_EmptySource_PlaceholderCreated()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO B1] Neither SKU nor Item has BOM/Routing → Empty source, placeholder lines created
        Initialize();

        // [GIVEN] Item has no BOM and no Routing; no SKU for the item
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized from the Item
        ActualSourceText := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Source = Empty; wizard saved a placeholder BOM with 1 line to the item
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('Manufacturing Setup', ActualSourceText, 'Source should be empty when item has no BOM or Routing');
        Item.Get(ItemNo);
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        Assert.AreEqual(1, ProductionBOMLine.Count(), 'Item BOM should have 1 placeholder line');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSource')]
    procedure TestB2_ItemHasBOMOnly_PartialScenario_RoutingPlaceholder()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO B2] Item has only BOM (no Routing) → Partial scenario, BOM from Item, Routing placeholder
        Initialize();

        // [GIVEN] Item has BOM-A but no Routing
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized from the Item
        ActualSourceText := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Source = Item; BOM-A has 2 lines in the database
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('Item', ActualSourceText, 'Source should be Item');
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ProductionBOMLine.SetRange("Version Code", '');
        Assert.AreEqual(2, ProductionBOMLine.Count(), 'BOM-A should have 2 lines');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSourceWithSave')]
    procedure TestB3_ItemHasRoutingOnly_PartialScenario_BOMPlaceholder()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO B3] Item has only Routing (no BOM) → Partial scenario, Routing from Item, BOM placeholder
        Initialize();

        // [GIVEN] Item has Routing-A but no BOM
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized from the Item
        ActualSourceText := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Source = Item; wizard saved a placeholder BOM with 1 line to the item
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('Item', ActualSourceText, 'Source should be Item');
        Item.Get(ItemNo);
        ProductionBOMLine.SetRange("Production BOM No.", Item."Production BOM No.");
        Assert.AreEqual(1, ProductionBOMLine.Count(), 'Item BOM should have 1 placeholder line');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSource')]
    procedure TestB4_InitFromSalesLine_NoSKUForLocation_ItemUsed()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO B4] InitializeFromSalesLine: item data resolved when no SKU for that location
        Initialize();

        // [GIVEN] Sales line for an item with BOM-A and Routing-A; sales line location has no SKU
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is launched from the Sales Line
        ActualSourceText := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Source = Item; prod order has 2 component lines from BOM-A;
        //         prod order quantity = 5, due date = WorkDate(), location = sales line location, variant = ''
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('Item', ActualSourceText, 'Source should be Item (no SKU for location)');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 2);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 5, WorkDate(), LocationCode, '');
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureSource(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Capture source type text from Step 1
        ActualSourceText := Wizard.BOMRtngFromSourceField.Value();

        // Navigate to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureSourceWithSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Capture source type text from Step 1
        ActualSourceText := Wizard.BOMRtngFromSourceField.Value();

        // Enable Save so BOM/Routing changes are persisted to the item
        Wizard.SaveBOMRoutingField.SetValue(true);

        // Navigate to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Source Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Source Test");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Source Test");
    end;

    // -----------------------------------------------------------------------------------------
    // CRITICAL #1 — Mixed-source BOM+Routing resolution
    // Bug: GetBOMAndRoutingFromBestSource exits after finding SKU BOM, never retrieves Item Routing
    // -----------------------------------------------------------------------------------------
    [Test]
    [HandlerFunctions('HandleWizardCaptureBOMAndRoutingForB5')]
    procedure TestB5_SKUHasBOMOnly_ItemHasRoutingOnly_BothResolved()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        SKU: Record "Stockkeeping Unit";
        ProdDefManager: Codeunit "Production Definition Manager";
        SKUBOMNo: Code[20];
        ItemRoutingNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO B5] SKU has BOM only (no Routing); Item has Routing only (no BOM).
        //               Wizard must resolve BOM from SKU AND Routing from Item — BothAvailable scenario.
        //               Detects BUG: GetBOMAndRoutingFromBestSource exits after SKU BOM found,
        //               never reading Item-level Routing; wizard shows PartiallyAvailable instead.
        Initialize();

        // [GIVEN] Item has Routing-A (no BOM); SKU at LocationCode has BOM-A (no Routing)
        SKUBOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemRoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', ItemRoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU, ItemNo, LocationCode, '', SKUBOMNo, '');
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 3, LocationCode, '', WorkDate());
        // Configure both display scenarios to Edit so all steps are visible regardless of resolved scenario
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is launched from the Sales Line (Sales Line matches the SKU at LocationCode)
        ActualBOMNoFromWizardB5 := '';
        ActualRoutingNoFromWizardB5 := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Wizard shows BOM from SKU
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual(SKUBOMNo, ActualBOMNoFromWizardB5,
            'BOM No. in wizard should be the SKU BOM (not empty); mixed-source resolution failed');
        // [THEN] Wizard shows Routing from Item (not empty) — key assertion for the critical bug
        Assert.AreEqual(ItemRoutingNo, ActualRoutingNoFromWizardB5,
            'Routing No. in wizard should come from Item even though SKU has no Routing; GetBOMAndRoutingFromBestSource must not exit early');
        // [THEN] Production Order has 2 components (from SKU BOM) and 2 routing lines (from Item Routing)
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 2);
        ProdDefWizCheckLib.VerifyProdOrderHasRoutingLineCount(ProdOrder, 2);
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureBOMAndRoutingForB5(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM step) and capture the resolved BOM No.
        Wizard.ActionNext.Invoke();
        ActualBOMNoFromWizardB5 := CopyStr(Wizard.ProductionBOMNoField.Value(), 1, 20);
        // Navigate to Step 3 (Routing step) and capture the resolved Routing No.
        // If the bug is present and only PartiallyAvailable is resolved, Routing step may be empty.
        Wizard.ActionNext.Invoke();
        ActualRoutingNoFromWizardB5 := CopyStr(Wizard.RoutingNoField.Value(), 1, 20);
        // Navigate to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;
}