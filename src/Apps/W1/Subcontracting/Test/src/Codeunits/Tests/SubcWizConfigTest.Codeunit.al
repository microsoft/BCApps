// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;

codeunit 139994 "Subc. Wiz. Config Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard Configuration Tests
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        WizardFinishedSuccessfully: Boolean;
        WizardWasOpened: Boolean;
        ExpectedStepWasNotVisitedLbl: Label 'Expected step %1 was not visited', Locked = true;
        ExpectedSteps: List of [Text];
        StepsVisited: List of [Text];

    // ==================== SCENARIO B: Setup Configuration (Display) ====================

    [Test]
    // [HandlerFunctions('HandlePurchProvisionWizardNotExpected')]
    procedure TestB1_BothHide_WizardNotOpened()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B1] Both "Do not show" - Wizard does not open at all, production order is created automatically
        // [GIVEN] Item with both BOM and Routing, setup configured to hide both
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to hide both BOM/Routing and ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation process
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should not have opened, but production order should be created automatically
        Assert.IsFalse(WizardWasOpened, 'Wizard should not have opened when both are set to Hide');
        // Production order should still be created automatically
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created automatically');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardBOMRtngOnly')]
    procedure TestB2_BOMRtngEdit_ProdRtngCompHide_OnlyBOMRtngShown()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B2] BOM "Edit", Routing "Do not show" - Only BOM is opened in wizard for viewing & editing
        // [GIVEN] Item with both BOM and Routing, setup configured to edit BOM and hide Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit BOM/Routing and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (finish here because ProdComp/Routing are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing only BOM editing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM is set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardProdRtngCompOnly')]
    procedure TestB3_ProdRtngCompEdit_BOMRtngHide_OnlyProdRtngCompShown()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B3] Routing "Edit", BOM "Do not show" - Only routing is opened in wizard for viewing & editing
        // [GIVEN] Item with both BOM and Routing, setup configured to hide BOM and edit Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to hide BOM/Routing and edit ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing only Routing editing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Routing is set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardBothShownEdit')]
    procedure TestB4_BothEdit_BothShownEdit()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B4] Both "Edit" - Both are opened in wizard for viewing & editing
        // [GIVEN] Item with both BOM and Routing, setup configured to edit both
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both BOM/Routing and ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: All steps should be visible
        SetExpectedSteps('Intro,BOM,Routing,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing both BOM and Routing editing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when both are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardBOMSelect')]
    procedure TestB6_BOMSelect_ProdRoutingHide_BOMViewOnly()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B6] BOM "Select" instead of "Edit" - BOM is only displayed for viewing in wizard -> lines are not editable
        // [GIVEN] Item with both BOM and Routing, setup configured to select BOM (view only) and hide Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to select BOM/Routing (view only) and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Show, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (finish here because ProdComp/Routing are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing BOM for selection only (not editable)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM is set to Select');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardRoutingSelect')]
    procedure TestB7_ProdRoutingSelect_BOMHide_ProdRoutingViewOnly()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B7] Routing "Select" instead of "Edit" - Routing is only displayed for viewing in wizard -> lines are not editable
        // [GIVEN] Item with both BOM and Routing, setup configured to hide BOM and select Routing (view only)
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to hide BOM/Routing and select ProdRouting/Components (view only)
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Show);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing Routing for selection only (not editable)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Routing is set to Select');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardComponentsEdit')]
    procedure TestB8_ComponentsEdit_LinesEditable()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B8] Components / Production routing operations "Edit" - Lines are editable
        // [GIVEN] Item with both BOM and Routing, setup configured to edit Production Components/Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to hide BOM/Routing and edit ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, with editable components and routing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Components/Routing are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardComponentsHide')]
    procedure TestB10_ComponentsHide_LinesNotDisplayed()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B10] Components / Production routing operations "Do not show" - Lines are not displayed at all
        // [GIVEN] Item with both BOM and Routing, setup configured to hide Production Components/Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit BOM/Routing and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (Components/ProdRouting steps are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, without showing components and routing steps
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM/Routing are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardBOMSelect')]
    procedure TestB61_BOMSelect_ProdRoutingHide_BOMViewOnly()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B6] BOM "Select" instead of "Edit" - BOM is only displayed for viewing in wizard -> lines are not editable
        // [GIVEN] Item with Partially BOM and Routing, setup configured to select BOM (view only) and hide Routing
        Initialize();

        // Create BOM and Routing
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', RoutingNo);

        // Configure setup to select BOM/Routing (view only) and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForPartiallyPresentScenario("Subc. Show/Edit Type"::Show, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (finish here because ProdComp/Routing are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing BOM for selection only (not editable)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM is set to Select');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardRoutingSelect')]
    procedure TestB71_ProdRoutingSelect_BOMHide_ProdRoutingViewOnly()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO B7] Routing "Select" instead of "Edit" - Routing is only displayed for viewing in wizard -> lines are not editable
        // [GIVEN] Item with Partially BOM and Routing, setup configured to hide BOM and select Routing (view only)
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');

        // Configure setup to hide BOM/Routing and select ProdRouting/Components (view only)
        SubSetupLibrary.ConfigureSubManagementForPartiallyPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Show);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing Routing for selection only (not editable)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Routing is set to Select');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardComponentsEdit')]
    procedure TestB81_ComponentsEdit_LinesEditable()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO B8] Components / Production routing operations "Edit" - Lines are editable
        // [GIVEN] Item with Partially BOM and Routing, setup configured to edit Production Components/Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');

        // Configure setup to hide BOM/Routing and edit ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForPartiallyPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, with editable components and routing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Components/Routing are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardComponentsHide')]
    procedure TestB101_ComponentsHide_LinesNotDisplayed()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO B10] Components / Production routing operations "Do not show" - Lines are not displayed at all
        // [GIVEN] Item with Partially BOM and Routing, setup configured to hide Production Components/Routing
        Initialize();

        // Create BOM and Routing
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', RoutingNo);

        // Configure setup to edit BOM/Routing and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForPartiallyPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (Components/ProdRouting steps are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, without showing components and routing steps
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM/Routing are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardBOMSelect')]
    procedure TestB62_BOMSelect_ProdRoutingHide_BOMViewOnly()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO B6] BOM "Select" instead of "Edit" - BOM is only displayed for viewing in wizard -> lines are not editable
        // [GIVEN] Item with Nothing BOM and Routing, setup configured to select BOM (view only) and hide Routing
        Initialize();

        // Create BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', '');

        // Configure setup to select BOM/Routing (view only) and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Show, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (finish here because ProdComp/Routing are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing BOM for selection only (not editable)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM is set to Select');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardRoutingSelect')]
    procedure TestB72_ProdRoutingSelect_BOMHide_ProdRoutingViewOnly()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO B7] Routing "Select" instead of "Edit" - Routing is only displayed for viewing in wizard -> lines are not editable
        // [GIVEN] Item with Nothing BOM and Routing, setup configured to hide BOM and select Routing (view only)
        Initialize();

        // Create BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', '');

        // Configure setup to hide BOM/Routing and select ProdRouting/Components (view only)
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Show);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, showing Routing for selection only (not editable)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Routing is set to Select');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardComponentsEdit')]
    procedure TestB82_ComponentsEdit_LinesEditable()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO B8] Components / Production routing operations "Edit" - Lines are editable
        // [GIVEN] Item with Nothing BOM and Routing, setup configured to edit Production Components/Routing
        Initialize();

        // Create BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', '');

        // Configure setup to hide BOM/Routing and edit ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Hide, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> Components -> ProdRouting (BOM/Routing steps are hidden)
        SetExpectedSteps('Intro,Components,ProdRouting');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, with editable components and routing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when Components/Routing are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardComponentsHide')]
    procedure TestB102_ComponentsHide_LinesNotDisplayed()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO B10] Components / Production routing operations "Do not show" - Lines are not displayed at all
        // [GIVEN] Item with Nothing BOM and Routing, setup configured to hide Production Components/Routing
        Initialize();

        // Create BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', '');

        // Configure setup to edit BOM/Routing and hide ProdRouting/Components
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Hide);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected steps: Intro -> BOM -> Routing (Components/ProdRouting steps are hidden)
        SetExpectedSteps('Intro,BOM,Routing');

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Clear(StepsVisited);
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have opened and finished successfully, without showing components and routing steps
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened when BOM/Routing are set to Edit');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
        VerifyExpectedStepsVisited();
    end;

    // ==================== HELPER PROCEDURES====================

    local procedure SetExpectedSteps(StepsList: Text)
    var
        StepArray: List of [Text];
        Step: Text;
    begin
        Clear(ExpectedSteps);
        StepArray := StepsList.Split(',');
        foreach Step in StepArray do
            ExpectedSteps.Add(Step);
    end;

    local procedure VerifyExpectedStepsVisited()
    var
        i: Integer;
        ExpectedStep: Text;
    begin
        Assert.AreEqual(ExpectedSteps.Count(), StepsVisited.Count(), 'Number of visited steps should match expected steps');

        for i := 1 to ExpectedSteps.Count() do begin
            ExpectedSteps.Get(i, ExpectedStep);
            Assert.IsTrue(StepsVisited.Contains(ExpectedStep), StrSubstNo(ExpectedStepWasNotVisitedLbl, ExpectedStep));
        end;
    end;

    local procedure RecordStepVisited(StepName: Text)
    begin
        if not StepsVisited.Contains(StepName) then
            StepsVisited.Add(StepName);
    end;

    // ==================== MODAL PAGE HANDLERS ====================

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardNotExpected(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // This handler should not be called for B1 scenario
        WizardWasOpened := true;
        Error('Wizard should not have opened when both settings are set to Hide');
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardBOMRtngOnly(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B2] Handle wizard when only BOM editing is enabled
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: BOM -> Routing (then finish because ProdComp/Routing are hidden)
            case StepCount of
                1:
                    RecordStepVisited('BOM');
                2:
                    RecordStepVisited('Routing');
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after BOM and Routing steps (ProdComp/Routing are hidden)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled when ProdComp/Routing are hidden');
        Assert.AreEqual(2, StepCount, 'Should have navigated through 2 steps (BOM, Routing) when ProdComp/Routing are hidden');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardProdRtngCompOnly(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B3] Handle wizard when only Routing editing is enabled
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: Components -> ProdRouting (BOM/Routing steps are hidden)
            case StepCount of
                1:
                    RecordStepVisited('Components');
                2:
                    RecordStepVisited('ProdRouting');
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after Components and ProdRouting steps (BOM/Routing are hidden)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled on ProdRouting step');
        Assert.AreEqual(2, StepCount, 'Should have navigated through 2 steps (Components, ProdRouting) when BOM/Routing are hidden');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardBothShownEdit(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B4] Handle wizard when both BOM and Routing editing are enabled
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: BOM -> Routing -> Components -> ProdRouting
            case StepCount of
                1:
                    begin
                        RecordStepVisited('BOM');
                        Assert.IsTrue(PurchProvisionWizard.CreateBOMVersion.Visible(), 'Create BOM Version should be editable when set to Edit');
                    end;
                2:
                    begin
                        RecordStepVisited('Routing');
                        Assert.IsTrue(PurchProvisionWizard.CreateRoutingVersion.Visible(), 'Create Routing Version should be editable when set to Edit');
                    end;
                3:
                    begin
                        RecordStepVisited('Components');
                        Assert.IsTrue(PurchProvisionWizard.ComponentsPart.Editable(), 'Components should be editable when set to Edit');
                    end;
                4:
                    begin
                        RecordStepVisited('ProdRouting');
                        Assert.IsTrue(PurchProvisionWizard.ProdOrderRoutingPart.Editable(), 'ProdRouting should be editable when set to Edit');
                    end;
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after all 4 steps
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled on ProdRouting step');
        Assert.AreEqual(4, StepCount, 'Should have navigated through 4 steps (BOM, Routing, Components, ProdRouting) when both are enabled');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardDefaultBehavior(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B5] Handle wizard with default behavior
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: BOM -> Routing -> Components -> ProdRouting (default should be Edit for both)
            case StepCount of
                1:
                    RecordStepVisited('BOM');
                2:
                    RecordStepVisited('Routing');
                3:
                    RecordStepVisited('Components');
                4:
                    RecordStepVisited('ProdRouting');
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after all 4 steps (default Edit behavior)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled on ProdRouting step');
        Assert.AreEqual(4, StepCount, 'Should have navigated through 4 steps (BOM, Routing, Components, ProdRouting) with default Edit behavior');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardBOMSelect(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B6] Handle wizard when BOM is set to Select (view only) and Routing is hidden
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: BOM -> Routing (then finish because ProdComp/Routing are hidden)
            case StepCount of
                1:
                    begin
                        RecordStepVisited('BOM');
                        // Verify BOM Version is not editable (Select mode)
                        Assert.IsFalse(PurchProvisionWizard.CreateBOMVersion.Visible(), 'Create BOM Version should not be editable when set to Select');
                    end;
                2:
                    RecordStepVisited('Routing');
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after BOM and Routing steps (ProdComp/Routing are hidden)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled when ProdComp/Routing are hidden');
        Assert.AreEqual(2, StepCount, 'Should have navigated through 2 steps (BOM, Routing) when ProdComp/Routing are hidden');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardRoutingSelect(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B7] Handle wizard when Routing is set to Select (view only) and BOM is hidden
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: Components -> ProdRouting (BOM/Routing steps are hidden)
            case StepCount of
                1:
                    begin
                        RecordStepVisited('Components');
                        // Verify Components are not editable (Select mode)
                        Assert.IsFalse(PurchProvisionWizard.ProdCompRoutingShowEditTypeField.Value() = Format("Subc. Show/Edit Type"::Edit), 'Components should not be editable when set to Select');
                    end;
                2:
                    begin
                        RecordStepVisited('ProdRouting');
                        // Verify ProdRouting is not editable (Select mode)
                        Assert.IsFalse(PurchProvisionWizard.ProdCompRoutingShowEditTypeField.Value() = Format("Subc. Show/Edit Type"::Edit), 'ProdRouting should not be editable when set to Select');
                    end;
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after Components and ProdRouting steps (BOM/Routing are hidden)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled on ProdRouting step');
        Assert.AreEqual(2, StepCount, 'Should have navigated through 2 steps (Components, ProdRouting) when BOM/Routing are hidden');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardComponentsEdit(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B8] Handle wizard when Components/Routing are set to Edit
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: Components -> ProdRouting (BOM/Routing steps are hidden)
            case StepCount of
                1:
                    begin
                        RecordStepVisited('Components');
                        // Verify Components are editable (Edit mode)
                        Assert.IsTrue(PurchProvisionWizard.ComponentsPart.Editable(), 'Components should be editable when set to Edit');
                    end;
                2:
                    begin
                        RecordStepVisited('ProdRouting');
                        // Verify ProdRouting is editable (Edit mode)
                        Assert.IsTrue(PurchProvisionWizard.ProdOrderRoutingPart.Editable(), 'ProdRouting should be editable when set to Edit');
                    end;
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after Components and ProdRouting steps (BOM/Routing are hidden)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled on ProdRouting step');
        Assert.AreEqual(2, StepCount, 'Should have navigated through 2 steps (Components, ProdRouting) when BOM/Routing are hidden');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardComponentsHide(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        StepCount: Integer;
    begin
        // [SCENARIO B10] Handle wizard when Components/Routing are hidden
        WizardWasOpened := true;

        // Record that we started (Intro step)
        RecordStepVisited('Intro');

        // Navigate through the wizard and count steps
        StepCount := 0;
        while PurchProvisionWizard.ActionNext.Enabled() do begin
            PurchProvisionWizard.ActionNext.Invoke();
            StepCount += 1;

            // Record steps based on expected flow: BOM -> Routing (then finish because Components/ProdRouting are hidden)
            case StepCount of
                1:
                    RecordStepVisited('BOM');
                2:
                    RecordStepVisited('Routing');
                else
                    RecordStepVisited('Unexpected Step');
            end;
        end;

        // Should be able to finish after BOM and Routing steps (Components/ProdRouting are hidden)
        Assert.IsTrue(PurchProvisionWizard.ActionFinish.Enabled(), 'Finish should be enabled when Components/ProdRouting are hidden');
        Assert.AreEqual(2, StepCount, 'Should have navigated through 2 steps (BOM, Routing) when Components/ProdRouting are hidden');

        // Finish the wizard
        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Config Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. Config Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. Config Test");
    end;
}