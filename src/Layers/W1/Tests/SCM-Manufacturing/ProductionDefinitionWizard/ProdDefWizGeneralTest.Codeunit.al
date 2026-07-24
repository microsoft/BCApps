// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137423 "Prod. Def. Wiz. General Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - General: Open & Finish
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
        // Handler state for step-checking tests
        Step1BackWasDisabled: Boolean;
        Step2BackWasEnabled: Boolean;
        DefineItemStructure_Step4Visible: Boolean;
        DefineItemStructure_Step5Visible: Boolean;
        CreateProdOrder_Step2Visible: Boolean;
        CreateProdOrder_Step3Visible: Boolean;
        CreateProdOrder_Step4Visible: Boolean;
        CreateProdOrder_Step5Visible: Boolean;


    [Test]
    [HandlerFunctions('HandleWizardSaveToItemAndCaptureBOM')]
    procedure TestA1_OpenFromItemNoBOMRouting_OpensAndFinishes()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        PreWizardLastBOMNo: Code[20];
        PostWizardLastBOMNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO A1] Open wizard from Item with no BOM/Routing — wizard opens and finishes; BOM assigned
        Initialize();

        // [GIVEN] An item with no Production BOM and no Routing
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] The Production Definition action is invoked (wizard run in DefineItemStructure mode with Save)
        WizardFinished := false;
        PreWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Wizard opened and completed; Item now has a Production BOM assigned
        PostWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        Assert.IsTrue(WizardFinished, 'Wizard should have finished successfully');
        Assert.AreNotEqual(PreWizardLastBOMNo, PostWizardLastBOMNo, 'Wizard should have created a new Production BOM');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, PostWizardLastBOMNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSaveToSKUAndCaptureBOM')]
    procedure TestA2_OpenFromSKU_OpensAndFinishes()
    var
        SKU: Record "Stockkeeping Unit";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        LocationCode: Code[10];
        PreWizardLastBOMNo: Code[20];
        PostWizardLastBOMNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO A2] Open wizard from SKU — wizard opens and finishes; BOM assigned to SKU
        Initialize();

        // [GIVEN] A Stockkeeping Unit for any item with no BOM/Routing
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU, ItemNo, LocationCode, '', '', '');
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] The Production Definition action is invoked on the SKU (with Save)
        WizardFinished := false;
        PreWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        Commit();
        ProdDefManager.RunForSource(SKU, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Wizard opens and finishes without error; SKU now has a Production BOM assigned
        PostWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        Assert.IsTrue(WizardFinished, 'Wizard should have finished successfully from SKU');
        Assert.AreNotEqual(PreWizardLastBOMNo, PostWizardLastBOMNo, 'Wizard should have created a new Production BOM for the SKU');
        ProdDefWizCheckLib.VerifySKUHasBOM(ItemNo, LocationCode, '', PostWizardLastBOMNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCheckStep1BackDisabled')]
    procedure TestA3_Step1_BackButtonDisabled()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO A3] Wizard step navigation: Back button on Step 1 is disabled
        // [INFRASTRUCTURE TEST] Verifies wizard UI navigation state (Back button disabled on Step 1), not business logic.
        Initialize();

        // [GIVEN] Wizard is open on Step 1 (Introduction), BOMRoutingDisplay = Edit
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);

        // [WHEN] Checking the state of the Back action on Step 1
        Step1BackWasDisabled := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] ActionBack.Enabled = false on Step 1
        Assert.IsTrue(Step1BackWasDisabled, 'Back button should be disabled on Step 1');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCheckStep2BackEnabled')]
    procedure TestA4_Step2_BackButtonEnabled()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO A4] Wizard step navigation: Back button becomes enabled on Step 2
        // [INFRASTRUCTURE TEST] Verifies wizard UI navigation state (Back button enabled on Step 2), not business logic.
        Initialize();

        // [GIVEN] Wizard is open; BOMRoutingDisplay = Edit (DefineItemStructure mode)
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);

        // [WHEN] Wizard moves to Step 2
        Step2BackWasEnabled := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] ActionBack.Enabled = true on Step 2
        Assert.IsTrue(Step2BackWasEnabled, 'Back button should be enabled on Step 2');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCheckDefineItemStructureSteps')]
    procedure TestA5_DefineItemStructureMode_OnlySteps1To3()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO A5] DefineItemStructure mode: wizard has exactly Steps 1–3
        Initialize();

        // [GIVEN] Wizard opened with Mode = DefineItemStructure; steps 4 and 5 are absent due to mode, not missing data
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);

        // [WHEN] User navigates through all visible steps
        DefineItemStructure_Step4Visible := false; // handler sets to true only if the step becomes visible
        DefineItemStructure_Step5Visible := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Steps 4 (Components Preview) and 5 (Production Routing Preview) are never shown
        Assert.IsFalse(DefineItemStructure_Step4Visible, 'Step 4 (Components) should not be visible in DefineItemStructure mode');
        Assert.IsFalse(DefineItemStructure_Step5Visible, 'Step 5 (Prod. Routing) should not be visible in DefineItemStructure mode');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCheckCreateProdOrderSteps')]
    procedure TestA6_CreateProductionOrderMode_AllSteps1To5()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        RoutingNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO A6] CreateProductionOrder mode: wizard has Steps 1–5
        Initialize();

        // [GIVEN] Sales Line for item with BOM and Routing; setup: BOMRoutingDisplay=Edit, ProdComponentDisplay=Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit,
            "Prod. Definition Display"::Edit);

        // [WHEN] User navigates through all visible steps in CreateProductionOrder mode
        CreateProdOrder_Step2Visible := false;
        CreateProdOrder_Step3Visible := false;
        CreateProdOrder_Step4Visible := false;
        CreateProdOrder_Step5Visible := false;
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Steps 2, 3, 4 and 5 are all shown
        Assert.IsTrue(CreateProdOrder_Step2Visible, 'Step 2 (BOM) should be visible in CreateProductionOrder mode');
        Assert.IsTrue(CreateProdOrder_Step3Visible, 'Step 3 (Routing) should be visible in CreateProductionOrder mode');
        Assert.IsTrue(CreateProdOrder_Step4Visible, 'Step 4 (Components) should be visible in CreateProductionOrder mode');
        Assert.IsTrue(CreateProdOrder_Step5Visible, 'Step 5 (Prod. Routing) should be visible in CreateProductionOrder mode');
        // Verify a Production Order was actually created for the item after wizard completes
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 2);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 5, WorkDate(), LocationCode, '');
        ProdDefWizCheckLib.VerifyProdOrderHasRoutingLineCount(ProdOrder, 2);
    end;


    [ModalPageHandler]
    procedure HandleWizardSimpleFinish(var Wizard: TestPage "Production Definition Wizard")
    begin
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCheckStep1BackDisabled(var Wizard: TestPage "Production Definition Wizard")
    begin
        // On opening, wizard is on Step 1 — verify Back is disabled
        Step1BackWasDisabled := not Wizard.ActionBack.Enabled();
        // Finish the wizard
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then
            Wizard.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardCheckStep2BackEnabled(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2
        Wizard.ActionNext.Invoke();
        // Check Back is now enabled
        Step2BackWasEnabled := Wizard.ActionBack.Enabled();
        // Finish the wizard
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then
            Wizard.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardCheckDefineItemStructureSteps(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate through all steps and track which are visible
        // In DefineItemStructure mode, ComponentsStepVisible and ProdRoutingStepVisible should be false
        DefineItemStructure_Step4Visible := Wizard.ComponentsPart.Visible();
        DefineItemStructure_Step5Visible := Wizard.ProdOrderRoutingPart.Visible();
        while Wizard.ActionNext.Enabled() do begin
            Wizard.ActionNext.Invoke();
            // Re-check after each navigation step
            if Wizard.ComponentsPart.Visible() then
                DefineItemStructure_Step4Visible := true;
            if Wizard.ProdOrderRoutingPart.Visible() then
                DefineItemStructure_Step5Visible := true;
        end;
        if Wizard.ActionFinish.Enabled() then
            Wizard.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardCheckCreateProdOrderSteps(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Check visibility at initial open
        if Wizard.BOMLinesPart.Visible() then
            CreateProdOrder_Step2Visible := true;
        if Wizard.RoutingLinesPart.Visible() then
            CreateProdOrder_Step3Visible := true;
        if Wizard.ComponentsPart.Visible() then
            CreateProdOrder_Step4Visible := true;
        if Wizard.ProdOrderRoutingPart.Visible() then
            CreateProdOrder_Step5Visible := true;

        // Navigate and re-check
        while Wizard.ActionNext.Enabled() do begin
            Wizard.ActionNext.Invoke();
            if Wizard.BOMLinesPart.Visible() then
                CreateProdOrder_Step2Visible := true;
            if Wizard.RoutingLinesPart.Visible() then
                CreateProdOrder_Step3Visible := true;
            if Wizard.ComponentsPart.Visible() then
                CreateProdOrder_Step4Visible := true;
            if Wizard.ProdOrderRoutingPart.Visible() then
                CreateProdOrder_Step5Visible := true;
        end;
        if Wizard.ActionFinish.Enabled() then
            Wizard.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardSaveToItemAndCaptureBOM(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save = Item so BOM is persisted to the item record
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Navigate to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardSaveToSKUAndCaptureBOM(var Wizard: TestPage "Production Definition Wizard")
    var
        SaveBomRoutingToSource: Boolean;
    begin
        Evaluate(SaveBomRoutingToSource, Wizard.SaveBOMRoutingField.Value());
        Assert.IsTrue(SaveBomRoutingToSource,
            'SaveBOMRoutingToSource should be StockkeepingUnit when Save is enabled for SKU source');
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. General Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. General Test");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForNothingAvailable(
    "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. General Test");
    end;
}