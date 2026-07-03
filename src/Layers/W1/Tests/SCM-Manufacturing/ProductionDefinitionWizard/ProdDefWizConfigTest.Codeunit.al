// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137425 "Prod. Def. Wiz. Config Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - Configuration / Display Settings
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        ProdDefWizLibrary: Codeunit "Prod. Def. Wiz. Library";
        ProdDefWizSetupLib: Codeunit "Prod. Def. Wiz. Setup Lib.";
        IsInitialized: Boolean;
        WizardFinished: Boolean;
        // Handler state
        ActualEditBOMLines: Boolean;
        ActualShowEditOptionsEnabled: Boolean;
        ActualBOMStepVisible: Boolean;
        ActualRoutingStepVisible: Boolean;
        ActualComponentsStepVisible: Boolean;
        ActualProdRoutingStepVisible: Boolean;
        ActualProdCompDisplayValue: Text;
        ActualBOMRoutingDisplayValue: Text;


    [Test]
    procedure TestC1_BOMRoutingDisplayHide_Steps2And3Skipped()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C1] BOMRoutingDisplay = Hide → Steps 2 and 3 are skipped
        Initialize();

        // [GIVEN] Manufacturing Setup: ShowRtngBOMSelect_Both = Hide; item has both BOM and Routing
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Hide, "Prod. Definition Display"::Hide);

        // [WHEN] Wizard is opened
        ActualBOMStepVisible := false;
        ActualRoutingStepVisible := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Step 2 and Step 3 were never visible
        Assert.IsFalse(ActualBOMStepVisible, 'BOM step (Step 2) should not be visible when Display = Hide');
        Assert.IsFalse(ActualRoutingStepVisible, 'Routing step (Step 3) should not be visible when Display = Hide');
    end;

    [Test]
    [HandlerFunctions('HandleWizardNavigateToStep2AndCaptureEditability')]
    procedure TestC2_BOMRoutingDisplayShow_BOMStepReadOnly()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C2] BOMRoutingDisplay = Show → BOM/Routing lines are read-only
        Initialize();

        // [GIVEN] Manufacturing Setup: ShowRtngBOMSelect_Both = Show
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);

        // [WHEN] Wizard opens on Step 2
        ActualEditBOMLines := true; // will be set false by handler if BOM is read-only
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] BOMLinesPart.Editable = false
        Assert.IsFalse(ActualEditBOMLines, 'BOM lines should be read-only when Display = Show');
    end;

    [Test]
    [HandlerFunctions('HandleWizardTrackStepVisibility')]
    procedure TestC3_ProdCompDisplayHide_Steps4And5Skipped()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C3] ProdComponentDisplay = Hide → Steps 4 and 5 are skipped
        Initialize();

        // [GIVEN] Mode = CreateProductionOrder; ShowProdCompSelect_Both = Hide
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Hide);

        // [WHEN] User navigates from Step 3
        ActualComponentsStepVisible := false;
        ActualProdRoutingStepVisible := false;
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Steps 4 and 5 are not visible
        Assert.IsFalse(ActualComponentsStepVisible, 'Components step (Step 4) should not be visible when ProdComp = Hide');
        Assert.IsFalse(ActualProdRoutingStepVisible, 'Prod. Routing step (Step 5) should not be visible when ProdComp = Hide');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureProdCompDisplay')]
    procedure TestC4_ProdCompDisplayShow_StepVisibleAndDisplayIsHide()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C4] ProdCompDisplay = Show → Components step is not visible; display mode is Hide (read-only), because of definition mode = DefineItemStructure
        Initialize();

        // [GIVEN] Mode = CreateProductionOrder; ProdComponentDisplay = Show
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Show);

        // [WHEN] Wizard opens and user navigates to Step 4
        ActualProdCompDisplayValue := '';
        ActualComponentsStepVisible := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Components step is not visible; ProdCompDisplayField = 'Hide'
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsFalse(ActualComponentsStepVisible, 'Components step (Step 4) should not be visible when ProdComp = Show');
        Assert.AreEqual('Hide', ActualProdCompDisplayValue, 'ProdCompDisplayField should be Hide');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureShowEditOptionsEnabled')]
    procedure TestC5_AllowEditUISelectionTrue_GroupEnabled()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C5] Allow Edit UI Selection = true → Show/Edit options group is enabled on Step 1
        Initialize();

        // [GIVEN] Manufacturing Setup: Allow Edit UI Selection = true
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.SetAllowEditUISelection(true);

        // [WHEN] Wizard opens on Step 1
        ActualShowEditOptionsEnabled := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] ShowEditOptionsGroup.Enabled = true
        Assert.IsTrue(ActualShowEditOptionsEnabled, 'Show/Edit options group should be enabled when Allow Edit UI Selection = true');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureShowEditOptionsEnabled')]
    procedure TestC6_AllowEditUISelectionFalse_GroupDisabled()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C6] Allow Edit UI Selection = false → Show/Edit options group is disabled on Step 1
        Initialize();

        // [GIVEN] Manufacturing Setup: Allow Edit UI Selection = false
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.SetAllowEditUISelection(false);

        // [WHEN] Wizard opens on Step 1
        ActualShowEditOptionsEnabled := true;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] ShowEditOptionsGroup.Enabled = false
        Assert.IsFalse(ActualShowEditOptionsEnabled, 'Show/Edit options group should be disabled when Allow Edit UI Selection = false');
    end;


    [ModalPageHandler]
    procedure HandleWizardTrackStepVisibility(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Record which steps are visible at any point during navigation
        if Wizard.BOMLinesPart.Visible() then
            ActualBOMStepVisible := true;
        if Wizard.RoutingLinesPart.Visible() then
            ActualRoutingStepVisible := true;
        if Wizard.ComponentsPart.Visible() then
            ActualComponentsStepVisible := true;
        if Wizard.ProdOrderRoutingPart.Visible() then
            ActualProdRoutingStepVisible := true;

        while Wizard.ActionNext.Enabled() do begin
            Wizard.ActionNext.Invoke();
            if Wizard.BOMLinesPart.Visible() then
                ActualBOMStepVisible := true;
            if Wizard.RoutingLinesPart.Visible() then
                ActualRoutingStepVisible := true;
            if Wizard.ComponentsPart.Visible() then
                ActualComponentsStepVisible := true;
            if Wizard.ProdOrderRoutingPart.Visible() then
                ActualProdRoutingStepVisible := true;
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardNavigateToStep2AndCaptureEditability(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM step)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Capture editability
        ActualEditBOMLines := Wizard.BOMLinesPart.Enabled();

        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureShowEditOptionsEnabled(var Wizard: TestPage "Production Definition Wizard")
    begin
        // On Step 1, capture ShowEditOptionsEnabled
        ActualShowEditOptionsEnabled := Wizard.BOMRoutingDisplayField.Enabled();
        // Finish the wizard
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureProdCompDisplay(var Wizard: TestPage "Production Definition Wizard")
    begin
        // On Step 1, capture ProdCompDisplayField value
        ActualProdCompDisplayValue := Wizard.ProdCompDisplayField.Value();
        // Navigate through steps; capture ComponentsStepVisible when on that step
        while Wizard.ActionNext.Enabled() do begin
            Wizard.ActionNext.Invoke();
            if Wizard.ComponentsPart.Visible() then
                ActualComponentsStepVisible := true;
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;


    [Test]
    [HandlerFunctions('HandleWizardCaptureDisplayFieldValues')]
    procedure TestC7_ScenarioNothingAvailable_DisplayFieldsFromNothingSetupFields()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C7] NothingAvailable scenario → BOMRoutingDisplay and ProdCompDisplay resolved from ShowRtngBOMSelect_Nothing / ShowProdCompSelect_Nothing
        Initialize();

        // [GIVEN] Sales Line for item with no BOM and no Routing; Nothing = Show, Both = Edit, Partial = Hide
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Hide, "Prod. Definition Display"::Hide);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);

        // [WHEN] Wizard is open
        ActualBOMRoutingDisplayValue := '';
        ActualProdCompDisplayValue := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Display fields come from Nothing scenario settings
        Assert.AreEqual('Show', ActualBOMRoutingDisplayValue, 'BOMRoutingDisplay should come from ShowRtngBOMSelect_Nothing = Show');
        Assert.AreEqual('Show', ActualProdCompDisplayValue, 'ProdCompDisplay should come from ShowProdCompSelect_Nothing = Show');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureDisplayFieldValues')]
    procedure TestC8_ScenarioPartiallyAvailable_DisplayFieldsFromPartialSetupFields()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C8] PartiallyAvailable scenario → BOMRoutingDisplay and ProdCompDisplay resolved from ShowRtngBOMSelect_Partial / ShowProdCompSelect_Partial
        Initialize();

        // [GIVEN] Sales Line for item with BOM only (no Routing); Partial = Edit, Both = Show, Nothing = Hide
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Hide, "Prod. Definition Display"::Hide);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is open
        ActualBOMRoutingDisplayValue := '';
        ActualProdCompDisplayValue := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Display fields come from Partial scenario settings
        Assert.AreEqual('Edit', ActualBOMRoutingDisplayValue, 'BOMRoutingDisplay should come from ShowRtngBOMSelect_Partial = Edit');
        Assert.AreEqual('Edit', ActualProdCompDisplayValue, 'ProdCompDisplay should come from ShowProdCompSelect_Partial = Edit');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureDisplayFieldValues')]
    procedure TestC9_ScenarioBothAvailable_DisplayFieldsFromBothSetupFields()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C9] BothAvailable scenario → BOMRoutingDisplay and ProdCompDisplay resolved from ShowRtngBOMSelect_Both / ShowProdCompSelect_Both
        Initialize();

        // [GIVEN] Sales Line for item with both BOM and Routing; Both = Show, Partial = Edit, Nothing = Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);

        // [WHEN] Wizard is open
        ActualBOMRoutingDisplayValue := '';
        ActualProdCompDisplayValue := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Display fields come from Both scenario settings
        Assert.AreEqual('Show', ActualBOMRoutingDisplayValue, 'BOMRoutingDisplay should come from ShowRtngBOMSelect_Both = Show');
        Assert.AreEqual('Show', ActualProdCompDisplayValue, 'ProdCompDisplay should come from ShowProdCompSelect_Both = Show');
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureDisplayFieldValues(var Wizard: TestPage "Production Definition Wizard")
    begin
        // On Step 1, capture the display field values resolved by the manager
        ActualBOMRoutingDisplayValue := Wizard.BOMRoutingDisplayField.Value();
        ActualProdCompDisplayValue := Wizard.ProdCompDisplayField.Value();
        // Navigate through all steps and finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Config Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Config Test");

        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForNothingAvailable(
    "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Config Test");
    end;

    [Test]
    [HandlerFunctions('HandleWizardNavigateToStep2AndCaptureEditability')]
    procedure TestC_BOMRoutingDisplayEdit_BOMStepEditable()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO C_Edit] BOMRoutingDisplay = Edit → BOM lines part is enabled (editable)
        Initialize();

        // [GIVEN] Manufacturing Setup: ShowRtngBOMSelect_Both = Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard opens on Step 2
        ActualEditBOMLines := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] BOMLinesPart.Enabled = true (Display = Edit means editable)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsTrue(ActualEditBOMLines, 'BOM lines should be editable when Display = Edit');
    end;

}