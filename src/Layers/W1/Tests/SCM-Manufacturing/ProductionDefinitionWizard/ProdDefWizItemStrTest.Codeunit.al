// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Wizard;

codeunit 137432 "Prod. Def. Wiz. Item Str. Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - DefineItemStructure Mode
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
        WizardResult: Boolean;
        // Handler state
        TargetBOMNoForK1: Code[20];


    [Test]
    [HandlerFunctions('HandleWizardK1SelectBOMNoSave,HandleProductionBOMListForK1')]
    procedure TestK1_DefineItemStructure_SaveFalse_ItemBOMUnchanged()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        OriginalBOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO K1] Mode = DefineItemStructure; user selects a different BOM in the wizard; Save = false → Item BOM unchanged after finish
        Initialize();

        // [GIVEN] Item with BOM-A; a second BOM-B also exists
        OriginalBOMNo := ProdDefWizLibrary.CreateBOM(2);
        TargetBOMNoForK1 := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(OriginalBOMNo, '');
        Item.Get(ItemNo);

        // [WHEN] Wizard opens; user selects BOM-B on Step 2 but leaves Save = false and finishes
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Item."Production BOM No." still equals BOM-A (finish without save leaves Item unchanged)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemBOMUnchanged(ItemNo, OriginalBOMNo);
    end;


    [Test]
    [HandlerFunctions('HandleWizardCancel')]
    procedure TestK2_DefineItemStructure_UserCancels_ItemUnchanged_NoProdOrder()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO K2] DefineItemStructure mode: user cancels wizard → Item unchanged, no Production Order created
        Initialize();

        // [GIVEN] Item with an existing BOM
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User opens wizard in DefineItemStructure mode and cancels without finishing
        WizardFinished := false;
        Commit();
        WizardResult := ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] RunForSource returns false; Item BOM is unchanged; no Production Order exists
        Assert.IsFalse(WizardResult, 'RunForSource should return false when wizard is cancelled');
        Assert.IsFalse(WizardFinished, 'WizardFinished should be false after cancel');
        ProdDefWizCheckLib.VerifyItemBOMUnchanged(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyNoProdOrderForItem(ItemNo);
    end;

    [ModalPageHandler]
    procedure HandleWizardCancel(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate one step then close without finishing (simulates cancel)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
    end;


    [ModalPageHandler]
    procedure HandleWizardK1SelectBOMNoSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Explicitly disable Save
        Wizard.SaveBOMRoutingField.SetValue(false);
        // Navigate to Step 2 (BOM)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Select BOM-B via AssistEdit on ProductionBOMNoField
        // (opens Production BOM List — handled by HandleProductionBOMListForK4)
        Wizard.ProductionBOMNoField.AssistEdit();
        // Navigate and finish without saving
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleProductionBOMListForK1(var ProductionBOMList: TestPage "Production BOM List")
    begin
        ProductionBOMList.Filter.SetFilter("No.", TargetBOMNoForK1);
        ProductionBOMList.First();
        ProductionBOMList.OK.Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Item Str. Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Item Str. Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Item Str. Test");
    end;

    [Test]
    [HandlerFunctions('HandleWizardK3SaveToItem')]
    procedure TestK3_DefineItemStructure_SaveTrue_ItemBOMAndRoutingAssigned()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        PreWizardLastBOMNo: Code[20];
        PostWizardLastBOMNo: Code[20];
        PreWizardLastRoutingNo: Code[20];
        PostWizardLastRoutingNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO K3] Mode = DefineItemStructure; Save = Item → Item."Production BOM No." and "Routing No." are assigned after finish
        Initialize();

        // [GIVEN] Item with no BOM and no Routing; wizard configured for Nothing scenario
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User enables Save = Item and finishes the wizard
        PreWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        PreWizardLastRoutingNo := ProdDefWizCheckLib.GetLastRoutingNo();
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Item."Production BOM No." and "Routing No." are now assigned to the wizard-created BOM/Routing
        PostWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        PostWizardLastRoutingNo := ProdDefWizCheckLib.GetLastRoutingNo();
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreNotEqual(PreWizardLastBOMNo, PostWizardLastBOMNo, 'Wizard should have created a new Production BOM');
        Assert.AreNotEqual(PreWizardLastRoutingNo, PostWizardLastRoutingNo, 'Wizard should have created a new Routing');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, PostWizardLastBOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, PostWizardLastRoutingNo);
    end;

    [ModalPageHandler]
    procedure HandleWizardK3SaveToItem(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save = Item
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Navigate to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

}