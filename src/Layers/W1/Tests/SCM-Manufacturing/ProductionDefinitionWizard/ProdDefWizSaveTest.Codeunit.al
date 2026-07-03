// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Wizard;

codeunit 137428 "Prod. Def. Wiz. Save Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - Save Behavior
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
        ActualSaveTargetAfterToggleOff: Text;
        ActualSKUNotAllowedErrorRaised: Boolean;


    [Test]
    [HandlerFunctions('HandleWizardNoSave')]
    procedure TestF1_SaveOff_ItemBOMRoutingUnchanged()
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
        // [SCENARIO F1] Save toggle OFF → Item Card BOM/Routing unchanged after finish
        Initialize();

        // [GIVEN] Item with BOM-A and Routing-A; wizard opened with Save = false (default)
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User finishes the wizard without enabling Save
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Item."Production BOM No." and Item."Routing No." remain unchanged
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemBOMUnchanged(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyItemRoutingUnchanged(ItemNo, RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSaveToItem')]
    procedure TestF2_SaveToItem_ItemBOMRoutingUpdated()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        PreWizardLastBOMNo: Code[20];
        PostWizardLastBOMNo: Code[20];
        PreWizardLastRoutingNo: Code[20];
        PostWizardLastRoutingNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO F2] Save = Item, source was Item → Item BOM/Routing updated to selected values
        Initialize();

        // [GIVEN] Item with no BOM and no Routing; wizard opened from Item
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User enables Save = Item and finishes the wizard
        PreWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        PreWizardLastRoutingNo := ProdDefWizCheckLib.GetLastRoutingNo();
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Item."Production BOM No." is populated with the wizard-selected BOM; Item."Routing No." with the wizard-selected Routing
        PostWizardLastBOMNo := ProdDefWizCheckLib.GetLastProductionBOMNo();
        PostWizardLastRoutingNo := ProdDefWizCheckLib.GetLastRoutingNo();
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreNotEqual(PreWizardLastBOMNo, PostWizardLastBOMNo, 'Wizard should have created a new Production BOM');
        Assert.AreNotEqual(PreWizardLastRoutingNo, PostWizardLastRoutingNo, 'Wizard should have created a new Routing');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, PostWizardLastBOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, PostWizardLastRoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSaveToSKU')]
    procedure TestF3_SaveToSKU_SKUUpdated_ItemUnchanged()
    var
        SKU: Record "Stockkeeping Unit";
        ProdDefManager: Codeunit "Production Definition Manager";
        OriginalItemBOMNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO F3] Save = StockkeepingUnit, source was SKU → SKU BOM/Routing updated
        Initialize();

        // [GIVEN] SKU with no BOM/Routing; Item has BOM-A
        OriginalItemBOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(OriginalItemBOMNo, '');
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU, ItemNo, LocationCode, '', '', '');
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User opens wizard from SKU Card, enables Save = StockkeepingUnit, finishes
        Commit();
        ProdDefManager.RunForSource(SKU, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SKU."Production BOM No." is set to the wizard-selected BOM; Item."Production BOM No." still = BOM-A
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifySKUHasBOM(ItemNo, LocationCode, '', OriginalItemBOMNo);
        ProdDefWizCheckLib.VerifyItemBOMUnchanged(ItemNo, OriginalItemBOMNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardTrySaveToSKUFromItem')]
    procedure TestF4_SaveSKU_SourceIsItem_Error()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        SaveBOMRtngSKUNotAllowedErr: Label 'Stockkeeping Unit is not allowed when the source is Item.';
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO F4] Save = StockkeepingUnit not allowed when source was Item
        Initialize();

        // [GIVEN] Wizard opened from Item Card (Source = Item)
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User attempts to set SaveBOMRoutingToSource = StockkeepingUnit
        ActualSKUNotAllowedErrorRaised := false;
        Commit();
        asserterror ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] An error is raised
        Assert.ExpectedError(SaveBOMRtngSKUNotAllowedErr);
    end;

    [Test]
    [HandlerFunctions('HandleWizardSaveOnThenOff')]
    procedure TestF5_SaveOnThenOff_SaveTargetCleared()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO F5] Save toggle ON and then OFF: SaveBOMRoutingToSource is cleared
        Initialize();

        // [GIVEN] Wizard open on Step 1
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User sets Save = true (SaveBOMRoutingToSource auto-set to Item), then sets Save = false
        ActualSaveTargetAfterToggleOff := 'NOT-EMPTY';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SaveBOMRoutingToSource = Empty
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual(' ', ActualSaveTargetAfterToggleOff, 'SaveBOMRoutingToSource should be cleared (Empty) after Save toggle off');
    end;

    [Test]
    [HandlerFunctions('HandleWizardNoSave')]
    procedure TestF6_DefineItemStructure_NoSave_NoProdOrderCreated()
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
        // [SCENARIO F6] DefineItemStructure mode: finish without Save does not create any production order
        Initialize();

        // [GIVEN] Mode = DefineItemStructure; item with BOM and Routing; Save = false
        ProdDefWizSetupLib.ConfigureForBothAvailable(
    "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);

        // [WHEN] User finishes the wizard
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] No Production Order record exists for this item
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyNoProdOrderForItem(ItemNo);
    end;


    [ModalPageHandler]
    procedure HandleWizardNoSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Do not change SaveBOMRouting (leave as false)
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardSaveToItem(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save (auto-sets SaveBOMRoutingToSource = Item for Item source)
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
    procedure HandleWizardSaveToSKU(var Wizard: TestPage "Production Definition Wizard")
    begin
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
    procedure HandleWizardTrySaveToSKUFromItem(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save first to activate SaveBomRtngToSourceField
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Attempt to set StockkeepingUnit — should raise an error since source is Item
        Wizard.SaveBOMRtngToSourceField.SetValue("Prod. Definition Save Target"::StockkeepingUnit);
        ActualSKUNotAllowedErrorRaised := true;
        // Finish (if possible)
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardSaveOnThenOff(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Set Save = true
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Set Save = false
        Wizard.SaveBOMRoutingField.SetValue(false);
        // Capture SaveBomRtngToSourceField value (should be ' ' = Empty)
        ActualSaveTargetAfterToggleOff := Wizard.SaveBOMRtngToSourceField.Value();
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
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Save Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Save Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Save Test");
    end;
}