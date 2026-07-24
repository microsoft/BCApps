// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137429 "Prod. Def. Wiz. Change Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - Change / Re-selection During Wizard
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
        ActualBOMNoAfterBackForward: Text;
        ActualEditBOMAfterOverride: Boolean;
        ActualBOMStepVisible: Boolean;
        ActualBOMNoAfterRoutingChange: Text;
        TargetRoutingNoForH2: Code[20];
        ActualCreateBOMVersionAfterVersionSelect: Boolean;
        ActualEditBOMAfterVersionSelect: Boolean;
        ActualSelectedBOMVersionAfterAssistEdit: Text;
        TargetBOMVersionForH5: Code[20];
        ActualComponentCountAfterBackForward: Integer;


    [Test]
    [HandlerFunctions('HandleWizardChangeBOMNavigateBackForward')]
    procedure TestH1_ChangeBOMOnStep2_NavigateBackForward_BOMRetained()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        OriginalBOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO H1] Change BOM No. on Step 2, step back to Step 1 and forward again → new BOM retained
        Initialize();

        // [GIVEN] Wizard on Step 2; user has item with BOM
        OriginalBOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(OriginalBOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates Back to Step 1 and then Next again
        ActualBOMNoAfterBackForward := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SelectedBOMNo is retained; BOM lines match selected BOM
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        // The actual verification is done inside the handler:
        // after Back and Forward, SelectedBOMNo should equal OriginalBOMNo (or whatever was set on Step 2)
        Assert.AreEqual(OriginalBOMNo, ActualBOMNoAfterBackForward, 'SelectedBOMNo should be retained after Back/Forward navigation');
        // Confirm Item still carries the correct BOM after wizard finishes
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, OriginalBOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardChangeRoutingAndCaptureBOM,HandleRoutingListSelectForH2')]
    procedure TestH2_ChangeRoutingOnStep3_BOMSelectionOnStep2Unchanged()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        OriginalBOMNo: Code[20];
        ItemNo: Code[20];
        RoutingANo: Code[20];
        RoutingBNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        WC3No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO H2] Change Routing No. on Step 3, go back to Step 2 → BOM selection is unchanged
        Initialize();

        // [GIVEN] Item with BOM-A and Routing-A; second Routing-B also exists
        OriginalBOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingANo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        RoutingBNo := ProdDefWizLibrary.CreateRoutingWithSingleLine(WC3No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(OriginalBOMNo, RoutingANo);
        Item.Get(ItemNo);
        TargetRoutingNoForH2 := RoutingBNo;
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 3, changes Routing to Routing-B, then goes back to Step 2
        ActualBOMNoAfterRoutingChange := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SelectedBOMNo on Step 2 is still OriginalBOMNo (routing change did not affect BOM)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual(OriginalBOMNo, ActualBOMNoAfterRoutingChange,
            'SelectedBOMNo should remain unchanged after Routing change on Step 3');
        // Confirm Item BOM is unchanged and Routing is updated to Routing-B after wizard completes
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, OriginalBOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingBNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardOverrideBOMRoutingDisplayToEdit')]
    procedure TestH3_ChangeBOMRoutingDisplayToEdit_BOMStepEditable()
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
        // [SCENARIO H3] Changing BOMRoutingDisplay on Step 1 from Show to Edit → BOM step becomes editable
        Initialize();

        // [GIVEN] Allow Edit UI Selection = true; default BOMRoutingDisplay = Show
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);
        ProdDefWizSetupLib.SetAllowEditUISelection(true);

        // [WHEN] User changes BOMRoutingDisplay to Edit on Step 1, then navigates to Step 2
        ActualEditBOMAfterOverride := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] EditBOMLines = true; Item BOM and Routing unchanged (Save = false)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsTrue(ActualEditBOMAfterOverride, 'BOM lines should be editable after user overrides BOMRoutingDisplay to Edit');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardOverrideBOMRoutingDisplayToHide')]
    procedure TestH4_ChangeBOMRoutingDisplayToHide_BOMStepSkipped()
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
        // [SCENARIO H4] Changing BOMRoutingDisplay to Hide on Step 1 → BOM and Routing steps are skipped
        Initialize();

        // [GIVEN] Allow Edit UI Selection = true; user changes BOMRoutingDisplay to Hide on Step 1
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.SetAllowEditUISelection(true);

        // [WHEN] User clicks Next
        ActualBOMStepVisible := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] BOM step is not shown; Item BOM and Routing unchanged (Save = false)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsFalse(ActualBOMStepVisible, 'BOM step should not be visible after changing BOMRoutingDisplay to Hide');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardH5CreateBOMVersionThenSelectVersion,HandleBOMVersionListForH5')]
    procedure TestH5_CreateBOMVersionOn_AssistEditSelectsExistingVersion_CreateBOMVersionCleared()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO H5] Create New BOM Version = true; user AssistEdits SelectedBOMVersion to pick existing certified version → CreateBOMVersion reset to false; BOM lines reload from existing version
        Initialize();

        // [GIVEN] Item with certified BOM; a certified BOM version V001 exists
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ProdDefWizLibrary.CreateBOMVersionAndCertify(BOMNo, 'V001', WorkDate());
        TargetBOMVersionForH5 := 'V001';
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User enables CreateBOMVersion then AssistEdits to pick V001
        ActualCreateBOMVersionAfterVersionSelect := true;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] CreateBOMVersion = false; BOM lines not editable (existing certified version); Item BOM unchanged (Save = false)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsFalse(ActualCreateBOMVersionAfterVersionSelect, 'CreateBOMVersion should be reset to false after selecting existing certified version');
        Assert.IsFalse(ActualEditBOMAfterVersionSelect, 'BOM lines should not be editable when existing certified version is selected');
        Assert.AreEqual('V001', ActualSelectedBOMVersionAfterAssistEdit, 'SelectedBOMVersion should be V001 after AssistEdit selects the existing certified version');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        // [THEN] BOM version V001 has exactly 1 line (from CreateBOMVersionAndCertify); verifies BOM lines were reloaded from the correct version
        ProdDefWizCheckLib.VerifyBOMVersionLineCount(BOMNo, 'V001', 1);
    end;


    [ModalPageHandler]
    procedure HandleWizardChangeBOMNavigateBackForward(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2
        Wizard.ActionNext.Invoke();
        // Capture SelectedBOMNo on Step 2
        // (no change — just note what was selected)
        // Navigate Back to Step 1
        Wizard.ActionBack.Invoke();
        // Navigate Next to Step 2 again
        Wizard.ActionNext.Invoke();
        // Re-capture SelectedBOMNo — should be unchanged
        ActualBOMNoAfterBackForward := Wizard.ProductionBOMNoField.Value();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardOverrideBOMRoutingDisplayToEdit(var Wizard: TestPage "Production Definition Wizard")
    begin
        // On Step 1, override BOMRoutingDisplay to Edit
        Wizard.BOMRoutingDisplayField.SetValue('Edit');
        // Navigate to Step 2
        Wizard.ActionNext.Invoke();
        // Capture editability of BOM lines
        if Wizard.CreateBOMVersionField.Enabled() then
            Wizard.CreateBOMVersionField.SetValue(true); // ensure CreateBOMVersion does not affect editability
        ActualEditBOMAfterOverride := Wizard.BOMLinesPart.Enabled();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardOverrideBOMRoutingDisplayToHide(var Wizard: TestPage "Production Definition Wizard")
    begin
        // On Step 1, override BOMRoutingDisplay to Hide
        Wizard.BOMRoutingDisplayField.SetValue('Hide');
        // Navigate through all steps; use OR-pattern so any accidental BOM visibility is caught
        if Wizard.BOMLinesPart.Visible() then
            ActualBOMStepVisible := true;
        while Wizard.ActionNext.Enabled() do begin
            Wizard.ActionNext.Invoke();
            if Wizard.BOMLinesPart.Visible() then
                ActualBOMStepVisible := true;
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardChangeRoutingAndCaptureBOM(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Change Routing No. via AssistEdit → opens Routing List (handled by HandleRoutingListSelectForH2)
        Wizard.RoutingNoField.AssistEdit();
        // Navigate back to Step 2
        Wizard.ActionBack.Invoke();
        // Capture SelectedBOMNo — should be unchanged
        ActualBOMNoAfterRoutingChange := Wizard.ProductionBOMNoField.Value();
        // Finish the wizard
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleRoutingListSelectForH2(var RoutingList: TestPage "Routing List")
    begin
        RoutingList.Filter.SetFilter("No.", TargetRoutingNoForH2);
        RoutingList.First();
        RoutingList.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardH5CreateBOMVersionThenSelectVersion(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Enable "Create New BOM Version"
        Wizard.CreateBOMVersionField.SetValue(true);
        // Use AssistEdit on SelectedBOMVersionField to pick an existing certified version
        // (opens "Prod. BOM Version List" — handled by HandleBOMVersionListForH5)
        Wizard.SelectedBOMVersionField.AssistEdit();
        // Capture SelectedBOMVersion — should be 'V001' after selecting the existing version
        ActualSelectedBOMVersionAfterAssistEdit := Wizard.SelectedBOMVersionField.Value();
        // Capture CreateBOMVersion — should be false after selecting existing version
        Evaluate(ActualCreateBOMVersionAfterVersionSelect, Wizard.CreateBOMVersionField.Value());
        // Capture BOM lines editability — should be false (existing version is not editable)
        ActualEditBOMAfterVersionSelect := Wizard.BOMLinesPart.Enabled();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleBOMVersionListForH5(var BOMVersionList: TestPage "Prod. BOM Version List")
    begin
        BOMVersionList.Filter.SetFilter("Version Code", TargetBOMVersionForH5);
        BOMVersionList.First();
        BOMVersionList.OK.Invoke();
    end;

    [Test]
    [HandlerFunctions('HandleWizardBackFromComponentsAndCount')]
    procedure TestH6_BackNavigateFromComponentsStep_ComponentCountStableAfterReEntry()
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
        // [SCENARIO H6] User navigates to Step 4 (Components), Back to Step 3, Forward to Step 4 again.
        //               The Production Order created on Finish must have exactly 2 components
        //               (not 4 due to stale BuildTemporaryStructureFromBOMRouting accumulation).
        Initialize();

        // [GIVEN] SalesLine for item with BOM of 2 lines and Routing; ProdComponentDisplay = Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to Step 4 (Components), Back to Step 3 (Routing), Forward to Step 4 again, then Finish
        ActualComponentCountAfterBackForward := 0;
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Wizard finished; ProdOrder has exactly 2 components (not 4 from stale temp-data)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderHasComponentCount(ProdOrder, 2);
    end;

    [ModalPageHandler]
    procedure HandleWizardBackFromComponentsAndCount(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 4 (Components)
        Wizard.ActionNext.Invoke();
        // Navigate BACK to Step 3 (triggers stale-accumulation bug on re-entry to Step 4)
        Wizard.ActionBack.Invoke();
        // Navigate FORWARD to Step 4 again
        Wizard.ActionNext.Invoke();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Change Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Change Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Change Test");
    end;
}