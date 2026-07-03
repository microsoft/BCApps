// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137427 "Prod. Def. Wiz. Version Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - Version Management
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
        ActualEditBOMLines: Boolean;
        ActualSelectedBOMVersionText: Text;
        ActualCreateBOMVersionToggleRaisedError: Boolean;
        ActualCreateBOMVersionErrorText: Text;
        ActualEditRoutingLines: Boolean;
        ActualSelectedRoutingVersionText: Text;
        ActualCreateRoutingVersionToggleRaisedError: Boolean;
        ActualCreateRoutingVersionErrorText: Text;


    [Test]
    [HandlerFunctions('HandleWizardToggleCreateBOMVersionOn')]
    procedure TestE1_CreateNewBOMVersionToggleOn_BOMEditable()
    var
        SalesLine: Record "Sales Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E1] "Create New BOM Version" toggle enabled → BOM lines become editable
        Initialize();

        // [GIVEN] Wizard is on Step 2; BOMRoutingDisplay = Edit; item has a certified BOM with Version Nos. series
        BOMNo := ProdDefWizLibrary.CreateBOM(2); // already sets Version Nos.
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User turns on "Create New BOM Version"
        ActualEditBOMLines := false;
        ActualSelectedBOMVersionText := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] EditBOMLines = true; SelectedBOMVersion starts with 'TEMP'
        // Note: Save=false and AlwaysSaveModifiedVersions=false → the TEMP version is discarded at Finish.
        // VerifyNoBOMVersionExists confirms the version was not inadvertently committed to the database.
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.IsTrue(ActualEditBOMLines, 'BOM lines should be editable after toggling Create New BOM Version');
        Assert.IsTrue(ActualSelectedBOMVersionText.StartsWith('TEMP'), 'SelectedBOMVersion should start with TEMP');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyNoBOMVersionExists(BOMNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardToggleCreateBOMVersionOnThenOff')]
    procedure TestE2_CreateNewBOMVersionToggleOff_LinesRevert()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E2] "Create New BOM Version" disabled (turned off again) → BOM lines revert to source lines
        Initialize();

        // [GIVEN] User had turned on "Create New BOM Version" on Step 2
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User turns off "Create New BOM Version"
        ActualSelectedBOMVersionText := 'NOT-EMPTY'; // will be reset by handler
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SelectedBOMVersion is cleared (empty)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('', ActualSelectedBOMVersionText, 'SelectedBOMVersion should be cleared after turning off Create New BOM Version');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyNoBOMVersionExists(BOMNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardToggleCreateRoutingVersionOnAndClose')]
    procedure TestE3_CreateNewRoutingVersionToggleOn_RoutingEditable()
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
        // [SCENARIO E3] "Create New Routing Version" toggle enabled → Routing lines become editable
        Initialize();

        // [GIVEN] Item has certified BOM and certified Routing with Version Nos. series set; display = Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User navigates to the Routing step and turns on "Create New Routing Version"
        ActualEditRoutingLines := false;
        ActualSelectedRoutingVersionText := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] EditRoutingLines = true; SelectedRoutingVersion starts with 'TEMP';
        // the TEMP version is discarded at closing
        Assert.IsFalse(WizardFinished, 'Wizard should not have finished');
        Assert.IsTrue(ActualEditRoutingLines, 'Routing lines should be editable after toggling Create New Routing Version');
        Assert.IsTrue(ActualSelectedRoutingVersionText.StartsWith('TEMP'), 'SelectedRoutingVersion should start with TEMP');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
        ProdDefWizCheckLib.VerifyNoBOMVersionExists(BOMNo);
        ProdDefWizCheckLib.VerifyNoRoutingVersionExists(RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCreateNewBOMVersionAndSave')]
    procedure TestE4_FinishWithNewBOMVersion_VersionCertified()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        LastBOMVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E4] "Create New BOM Version" on finish: new BOM version is created and certified
        Initialize();

        // [GIVEN] Wizard on Step 2 with "Create New BOM Version" = true; Save = Item
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        LastBOMVersionBefore := ProdDefWizCheckLib.GetLastBOMVersionCode(BOMNo);

        // [WHEN] User finishes the wizard with Create New BOM Version enabled
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] The item still has the same BOM; a new certified BOM version was created
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyNewLastBOMVersionCertified(BOMNo, LastBOMVersionBefore);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCreateNewRoutingVersionAndSave')]
    procedure TestE5_FinishWithNewRoutingVersion_VersionCertified()
    var
        Item: Record Item;
        RoutingHeader: Record "Routing Header";
        RoutingVersion: Record "Routing Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        LastRoutingVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E5] "Create New Routing Version" on finish: new Routing version is created and certified
        Initialize();

        // [GIVEN] Item has certified BOM and certified Routing with Version Nos. series set; Save = Item
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        LastRoutingVersionBefore := ProdDefWizCheckLib.GetLastRoutingVersionCode(RoutingNo);

        // [WHEN] User enables Save and "Create New Routing Version", then finishes
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] The item still has the same Routing; a new certified Routing version was created
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
        ProdDefWizCheckLib.VerifyNewLastRoutingVersionCertified(RoutingNo, LastRoutingVersionBefore);

        // [THEN] The new Routing version Type is not blank (must inherit Serial or Parallel from source Routing Header)
        //        Detects BUG: RoutingVersion.Type never set; defaults to blank (0)
        RoutingHeader.Get(RoutingNo);
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.FindLast();
        Assert.AreEqual(Format(RoutingHeader.Type), Format(RoutingVersion.Type),
            'New Routing version Type should match the source Routing Header Type (Serial/Parallel), not remain blank');

        // [THEN] The new Routing version Starting Date = WorkDate()
        Assert.AreEqual(WorkDate(), RoutingVersion."Starting Date",
            'New Routing version Starting Date should be WorkDate()');
    end;

    [Test]
    [HandlerFunctions('HandleWizardToggleCreateBOMVersionError')]
    procedure TestE6_BOMWithoutVersionNos_ToggleRaisesError()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E6] BOM without Version Nos. series → "Create New BOM Version" check raises error
        Initialize();

        // [GIVEN] Item has a certified BOM where "Version Nos." field is empty
        BOMNo := ProdDefWizLibrary.CreateBOMWithoutVersionNos();
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User turns on "Create New BOM Version" on Step 2
        ActualCreateBOMVersionToggleRaisedError := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] An error is raised indicating version number series is required
        Assert.IsTrue(ActualCreateBOMVersionToggleRaisedError, 'Turning on Create New BOM Version without Version Nos. should raise an error');
        Assert.AreNotEqual('', ActualCreateBOMVersionErrorText, 'Error text must be captured to confirm the correct error was raised');
        Assert.IsTrue(ActualCreateBOMVersionErrorText.Contains('Version Nos.'),
            StrSubstNo('Expected error about ''Version Nos.'' but got: %1', ActualCreateBOMVersionErrorText));
        ProdDefWizCheckLib.VerifyItemHasBOM(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyNoBOMVersionExists(BOMNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCreateNewBOMVersionAndSaveVersionOnly')]
    procedure TestE7_AlwaysSaveModifiedVersions_True_VersionKept()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        LastBOMVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E7] Always Save Modified Versions = true → new version kept even when Save toggle is off
        Initialize();

        // [GIVEN] Manufacturing Setup: Always Save Modified Versions = true; user creates new BOM version but Save toggle = false
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.SetAlwaysSaveModifiedVersions(true);
        // Re-read Manufacturing Setup to confirm the flag was persisted before the wizard runs
        Assert.IsTrue(ProdDefWizSetupLib.GetAlwaysSaveModifiedVersions(), 'AlwaysSaveModifiedVersions must be true in Manufacturing Setup before the wizard runs');
        LastBOMVersionBefore := ProdDefWizCheckLib.GetLastBOMVersionCode(BOMNo);

        // [WHEN] User finishes wizard with Create New BOM Version = true but SaveBOMRouting = false
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Item BOM unchanged; a new certified BOM version was saved
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemBOMUnchanged(ItemNo, BOMNo);
        ProdDefWizCheckLib.VerifyNewLastBOMVersionCertified(BOMNo, LastBOMVersionBefore);

        // [THEN] The new BOM version has exactly 2 lines (source BOM has 2 lines)
        //        Detects stale-accumulation bug if line count is doubled
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        ProductionBOMVersion.FindLast();
        ProdDefWizCheckLib.VerifyBOMVersionLineCount(BOMNo, ProductionBOMVersion."Version Code", 2);
    end;

    [Test]
    [HandlerFunctions('HandleWizardToggleCreateRoutingVersionError')]
    procedure TestE9_RoutingWithoutVersionNos_ToggleRaisesError()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        RoutingNo: Code[20];
        ItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E9] Routing without Version Nos. series → "Create New Routing Version" check raises error
        Initialize();

        // [GIVEN] Item has a certified Routing where "Version Nos." field is empty
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithoutVersionNos();
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User turns on "Create New Routing Version" on Step 3
        ActualCreateRoutingVersionToggleRaisedError := false;
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] An error is raised indicating version number series is required
        Assert.IsTrue(ActualCreateRoutingVersionToggleRaisedError, 'Turning on Create New Routing Version without Version Nos. should raise an error');
        Assert.AreNotEqual('', ActualCreateRoutingVersionErrorText, 'Error text must be captured to confirm the correct error was raised');
        Assert.IsTrue(ActualCreateRoutingVersionErrorText.Contains('Version Nos.'),
            StrSubstNo('Expected error about ''Version Nos.'' but got: %1', ActualCreateRoutingVersionErrorText));
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
        ProdDefWizCheckLib.VerifyNoRoutingVersionExists(RoutingNo);
    end;


    [ModalPageHandler]
    procedure HandleWizardToggleCreateBOMVersionOn(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New BOM Version
        Wizard.CreateBOMVersionField.SetValue(true);
        // Capture state
        ActualEditBOMLines := Wizard.BOMLinesPart.Enabled();
        ActualSelectedBOMVersionText := Wizard.SelectedBOMVersionField.Value();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardToggleCreateBOMVersionOnThenOff(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Toggle on, then off
        Wizard.CreateBOMVersionField.SetValue(true);
        Wizard.CreateBOMVersionField.SetValue(false);
        // Capture SelectedBOMVersion (should be empty)
        ActualSelectedBOMVersionText := Wizard.SelectedBOMVersionField.Value();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCreateNewBOMVersionAndSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save to Item on Step 1
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New BOM Version
        Wizard.CreateBOMVersionField.SetValue(true);
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardToggleCreateBOMVersionError(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New BOM Version — expect error because no Version Nos. series
        asserterror Wizard.CreateBOMVersionField.SetValue(true);
        ActualCreateBOMVersionToggleRaisedError := true;
        ActualCreateBOMVersionErrorText := GetLastErrorText();
        // Close wizard by invoking Finish (if still enabled)
        if Wizard.ActionFinish.Enabled() then
            Wizard.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardCreateNewBOMVersionAndSaveVersionOnly(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Do NOT set SaveBOMRouting (leave false)
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New BOM Version
        Wizard.CreateBOMVersionField.SetValue(true);
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardToggleCreateRoutingVersionError(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New Routing Version — expect error because no Version Nos. series
        asserterror Wizard.CreateRoutingVersionField.SetValue(true);
        ActualCreateRoutingVersionToggleRaisedError := true;
        ActualCreateRoutingVersionErrorText := GetLastErrorText();
        // Close wizard by invoking Finish (if still enabled)
        if Wizard.ActionFinish.Enabled() then
            Wizard.ActionFinish.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardToggleCreateRoutingVersionOnAndClose(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New Routing Version
        Wizard.CreateRoutingVersionField.SetValue(true);
        // Capture state
        ActualEditRoutingLines := Wizard.RoutingLinesPart.Enabled();
        ActualSelectedRoutingVersionText := Wizard.SelectedRoutingVersionField.Value();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardToggleCreateRoutingVersionOnThenOff(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Toggle on, then off
        Wizard.CreateRoutingVersionField.SetValue(true);
        Wizard.CreateRoutingVersionField.SetValue(false);
        // Capture SelectedRoutingVersion (should be empty after toggle-off)
        ActualSelectedRoutingVersionText := Wizard.SelectedRoutingVersionField.Value();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCreateNewRoutingVersionAndSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save to Item on Step 1
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New Routing Version
        Wizard.CreateRoutingVersionField.SetValue(true);
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [Test]
    [HandlerFunctions('HandleWizardToggleCreateRoutingVersionOnThenOff')]
    procedure TestE8_CreateNewRoutingVersionToggleOff_LinesRevert()
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
        // [SCENARIO E8] "Create New Routing Version" disabled (turned off again) → Routing lines revert to source lines
        Initialize();

        // [GIVEN] Item with certified BOM and Routing; user had turned on "Create New Routing Version" on Step 3
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User turns off "Create New Routing Version"
        ActualSelectedRoutingVersionText := 'NOT-EMPTY'; // will be reset by handler
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SelectedRoutingVersion is cleared (empty); no routing version committed to the database
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('', ActualSelectedRoutingVersionText, 'SelectedRoutingVersion should be cleared after turning off Create New Routing Version');
        ProdDefWizCheckLib.VerifyItemHasRouting(ItemNo, RoutingNo);
        ProdDefWizCheckLib.VerifyNoRoutingVersionExists(RoutingNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCreateNewBOMVersionAndSave')]
    procedure TestE_BOMVersionLinesHaveCorrectVersionCode()
    var
        Item: Record Item;
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        LastBOMVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E_BOMVersionLines] After the wizard creates a new BOM version every BOM line carries
        // the correct "Version Code" (regression test for BUG-01).
        Initialize();

        // [GIVEN] Item with certified BOM; wizard configured with Create New BOM Version + Save=Item
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        LastBOMVersionBefore := ProdDefWizCheckLib.GetLastBOMVersionCode(BOMNo);

        // [WHEN] Wizard creates and saves a new BOM version
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] A new certified BOM version exists
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyNewLastBOMVersionCertified(BOMNo, LastBOMVersionBefore);

        // [THEN] Every BOM line under the new version has "Version Code" = the new version code
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        ProductionBOMVersion.FindLast();
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ProductionBOMLine.SetRange("Version Code", ProductionBOMVersion."Version Code");
        Assert.IsTrue(ProductionBOMLine.FindSet(),
            StrSubstNo('New BOM version %1 must have at least one line', ProductionBOMVersion."Version Code"));
        repeat
            Assert.AreEqual(ProductionBOMVersion."Version Code", ProductionBOMLine."Version Code",
                StrSubstNo('BOM line "Version Code" must equal the new version code; expected %1, got %2',
                    ProductionBOMVersion."Version Code", ProductionBOMLine."Version Code"));
        until ProductionBOMLine.Next() = 0;
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Version Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Version Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Version Test");
    end;

    // -----------------------------------------------------------------------------------------
    // CRITICAL #2 — UpdateBOMVersionCode stale accumulation
    // Bug: old TempBOMLine records not deleted before re-inserting updated copy;
    //      back-forward navigation doubles the BOM version line count.
    // -----------------------------------------------------------------------------------------
    [Test]
    [HandlerFunctions('HandleWizardCreateBOMVersionBackForwardThenSave')]
    procedure TestE10_BackForwardNavigation_BOMVersionLineCountStable()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        LastBOMVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E10] "Create New BOM Version" enabled; user navigates Back then Forward on the
        //                BOM step; the resulting BOM version must contain exactly the original number
        //                of BOM lines (2), not double (4) due to stale TempBOMLine accumulation.
        Initialize();

        // [GIVEN] Item with certified BOM of 2 lines; wizard configured with Create New BOM Version + Save = Item
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        LastBOMVersionBefore := ProdDefWizCheckLib.GetLastBOMVersionCode(BOMNo);

        // [WHEN] User enables CreateBOMVersion, navigates Back to Step 1, then Forward to Step 2 again, then finishes
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] A new certified BOM version was created
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyNewLastBOMVersionCertified(BOMNo, LastBOMVersionBefore);

        // [THEN] The new BOM version has exactly 2 lines — not 4 due to stale TempBOMLine records
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        ProductionBOMVersion.FindLast();
        ProdDefWizCheckLib.VerifyBOMVersionLineCount(BOMNo, ProductionBOMVersion."Version Code", 2);
    end;

    // -----------------------------------------------------------------------------------------
    // LOW #16 — AlwaysSaveModifiedVersions + Routing version (mirrors TestE7 for BOM)
    // -----------------------------------------------------------------------------------------
    [Test]
    [HandlerFunctions('HandleWizardCreateNewRoutingVersionNoSave')]
    procedure TestE11_AlwaysSaveModifiedVersions_True_RoutingVersionKept()
    var
        Item: Record Item;
        RoutingVersion: Record "Routing Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        LastRoutingVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E11] Always Save Modified Versions = true → new Routing version kept even when
        //                Save toggle is off.  Mirrors TestE7 (BOM) for the Routing path.
        Initialize();

        // [GIVEN] Item with certified BOM and Routing; AlwaysSaveModifiedVersions = true; Save toggle = false
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        ProdDefWizSetupLib.SetAlwaysSaveModifiedVersions(true);
        Assert.IsTrue(ProdDefWizSetupLib.GetAlwaysSaveModifiedVersions(),
            'AlwaysSaveModifiedVersions must be true in Manufacturing Setup before the wizard runs');
        LastRoutingVersionBefore := ProdDefWizCheckLib.GetLastRoutingVersionCode(RoutingNo);

        // [WHEN] User finishes wizard with Create New Routing Version = true but SaveBOMRouting = false
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Item Routing unchanged; a new certified Routing version was saved
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyItemRoutingUnchanged(ItemNo, RoutingNo);
        ProdDefWizCheckLib.VerifyNewLastRoutingVersionCertified(RoutingNo, LastRoutingVersionBefore);

        // [THEN] The new Routing version has exactly 2 lines (source Routing has 2 lines)
        //        Detects UpdateRoutingVersionCode stale-accumulation bug if line count is doubled
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.FindLast();
        ProdDefWizCheckLib.VerifyRoutingVersionLineCount(RoutingNo, RoutingVersion."Version Code", 2);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCreateRoutingVersionBackForwardThenSave')]
    procedure TestE12_BackForwardNavigation_RoutingVersionLineCountStable()
    var
        Item: Record Item;
        RoutingVersion: Record "Routing Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        LastRoutingVersionBefore: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO E12] "Create New Routing Version" enabled; user navigates Back then Forward on the
        //                Routing step; the resulting Routing version must contain exactly the original
        //                number of lines (2), not double (4) due to stale TempRoutingLine accumulation.
        Initialize();

        // [GIVEN] Item with certified BOM and Routing of 2 lines; wizard configured with Create New Routing Version + Save = Item
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);
        LastRoutingVersionBefore := ProdDefWizCheckLib.GetLastRoutingVersionCode(RoutingNo);

        // [WHEN] User enables CreateRoutingVersion, navigates Back to Step 2, then Forward to Step 3 again, then finishes
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] A new certified Routing version was created
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyNewLastRoutingVersionCertified(RoutingNo, LastRoutingVersionBefore);

        // [THEN] The new Routing version has exactly 2 lines — not 4 due to stale TempRoutingLine records
        //        Detects BUG: UpdateRoutingVersionCode does not delete old temp records before re-insert
        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.FindLast();
        ProdDefWizCheckLib.VerifyRoutingVersionLineCount(RoutingNo, RoutingVersion."Version Code", 2);
    end;

    [ModalPageHandler]
    procedure HandleWizardCreateBOMVersionBackForwardThenSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save to Item
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Navigate to Step 2 (BOM) and enable Create New BOM Version
        Wizard.ActionNext.Invoke();
        Wizard.CreateBOMVersionField.SetValue(true);
        // Navigate BACK to Step 1 (triggers internal BOM version temp-data refresh)
        Wizard.ActionBack.Invoke();
        // Navigate FORWARD to Step 2 again (re-triggers UpdateBOMVersionCode; bug = lines doubled)
        Wizard.ActionNext.Invoke();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCreateRoutingVersionBackForwardThenSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Enable Save to Item
        Wizard.SaveBOMRoutingField.SetValue(true);
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing) and enable Create New Routing Version
        Wizard.ActionNext.Invoke();
        Wizard.CreateRoutingVersionField.SetValue(true);
        // Navigate BACK to Step 2 (triggers internal Routing version temp-data refresh)
        Wizard.ActionBack.Invoke();
        Wizard.ActionNext.Invoke();
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCreateNewRoutingVersionNoSave(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Do NOT set SaveBOMRouting (leave false)
        // Navigate to Step 2 (BOM)
        Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        Wizard.ActionNext.Invoke();
        // Toggle on Create New Routing Version
        Wizard.CreateRoutingVersionField.SetValue(true);
        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;
}