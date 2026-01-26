// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;

codeunit 139997 "Subc. Wiz. Source Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard BOM/Routing Source Tests
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        WizardFinishedSuccessfully: Boolean;
        WizardWasOpened: Boolean;
        ExpectedSourceType: Enum "Subc. RtngBOMSourceType";

    // ==================== SCENARIO G: Source Data Validation ====================

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardVerifyStockkeepingSource')]
    procedure TestG1_StockkeepingHasData_StockkeepingHasPriority()
    var
        PurchLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        BOMNo: Code[20];
        ItemBOMNo: Code[20];
        ItemNo: Code[20];
        ItemRoutingNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO G1] Stockkeeping has data → Stockkeeping has priority
        // [GIVEN] Item with BOM and Routing, Stockkeeping Unit with different BOM and Routing
        Initialize();

        // Create BOMs and Routings for both Item and Stockkeeping Unit
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemBOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        ItemRoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();

        // Create item with BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(ItemBOMNo, ItemRoutingNo);

        // Create location and stockkeeping unit with different BOM and Routing
        LocationCode := SubCreateProdOrdWizLibrary.CreateLocationCode();
        SubCreateProdOrdWizLibrary.CreateStockkeepingUnit(StockkeepingUnit, ItemNo, LocationCode);
        StockkeepingUnit."Production BOM No." := BOMNo;
        StockkeepingUnit."Routing No." := RoutingNo;
        StockkeepingUnit.Modify();

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line with location (to trigger stockkeeping unit usage)
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // Set expected source type for handler verification
        ExpectedSourceType := ExpectedSourceType::StockkeepingUnit;

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should show Stockkeeping Unit as source
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Stockkeeping Unit as source');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardVerifyItemSource')]
    procedure TestG2_ItemHasData_StockkeepingEmpty_ItemUsed()
    var
        PurchLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO G2] Item has data → Stockkeeping empty → Item used
        // [GIVEN] Item with BOM and Routing, Stockkeeping Unit without BOM and Routing
        Initialize();

        // Create BOM and Routing for Item
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create location and stockkeeping unit without BOM and Routing
        LocationCode := SubCreateProdOrdWizLibrary.CreateLocationCode();
        SubCreateProdOrdWizLibrary.CreateStockkeepingUnit(StockkeepingUnit, ItemNo, LocationCode);
        // Stockkeeping Unit has empty BOM and Routing (default)

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line with location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // Set expected source type for handler verification
        ExpectedSourceType := ExpectedSourceType::Item;

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should show Item as source
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Item as source');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardVerifySetupSource')]
    procedure TestG3_NothingFilled_NoData_SetupApplies()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO G3] Nothing filled → no data → Setup applies
        // [GIVEN] Item without BOM and Routing, no stockkeeping unit
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line without location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected source type for handler verification (should be Empty when using setup)
        ExpectedSourceType := ExpectedSourceType::Empty;

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should show Empty as source (setup is used)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Empty source (setup used)');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardVerifyEmptySource')]
    procedure TestG4_NothingFilled_NoSetup_FieldsEmpty()
    var
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO G4] Nothing filled → no setup → Fields empty
        // [GIVEN] Item without BOM and Routing, no stockkeeping unit, minimal setup
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line without location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected source type for handler verification
        ExpectedSourceType := ExpectedSourceType::Empty;

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should show Empty as source
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Empty source');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardVerifyNewSetupSource')]
    procedure TestG5_SetupChanged_NewSetup_NewSetupApplies()
    var
        PurchLine: Record "Purchase Line";
        SubManagementSetup: Record "Subc. Management Setup";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO G5] Setup changed → new setup → new setup applies
        // [GIVEN] Item without BOM and Routing, setup is changed during test
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure initial setup for nothing present scenario
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line without location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Change setup during test (simulate setup change by modifying a field)
        SubManagementSetup.Get();
        SubManagementSetup.ShowRtngBOMSelect_Nothing := SubManagementSetup.ShowRtngBOMSelect_Nothing::Show;
        SubManagementSetup.Modify();

        // Set expected source type for handler verification
        ExpectedSourceType := ExpectedSourceType::Empty;

        // [WHEN] Run the Production Order Creation Wizard with changed setup
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should use the new setup
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with new setup');
    end;

    // ==================== MODAL PAGE HANDLERS ====================

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardVerifyStockkeepingSource(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // [SCENARIO G3] Verify that BomRtngFromSource shows Empty when setup is used
        WizardWasOpened := true;

        // Verify that the source field shows StockkeepingUnit
        Assert.AreEqual(Format(ExpectedSourceType::StockkeepingUnit), PurchProvisionWizard.BomRtngFromSource.Value(),
            'BomRtngFromSource should show StockkeepingUnit when stockkeeping unit has data');

        // Navigate through wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardVerifyItemSource(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // [SCENARIO G4] Verify that BomRtngFromSource shows Empty when no setup exists
        WizardWasOpened := true;

        // Verify that the source field shows Item
        Assert.AreEqual(Format(ExpectedSourceType::Item), PurchProvisionWizard.BomRtngFromSource.Value(),
            'BomRtngFromSource should show Item when item has data and stockkeeping unit is empty');

        // Navigate through wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardVerifySetupSource(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        SubManSetupLbl: Label 'Subcontracting Management Setup', Locked = true;
    begin
        // [SCENARIO G5] Verify that BomRtngFromSource reflects new setup
        WizardWasOpened := true;

        // Verify that the source field shows Empty (new setup is used)
        Assert.AreEqual(SubManSetupLbl, PurchProvisionWizard.BomRtngFromSource.Value(),
            'BomRtngFromSource should reflect new setup configuration');

        // Navigate through wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardVerifyEmptySource(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        SubManSetupLbl: Label 'Subcontracting Management Setup', Locked = true;
    begin
        // [SCENARIO G4] Verify that BomRtngFromSource shows Empty when no setup exists
        WizardWasOpened := true;

        // Verify that the source field shows Empty
        Assert.AreEqual(SubManSetupLbl, PurchProvisionWizard.BomRtngFromSource.Value(),
            'BomRtngFromSource should show Empty when no data and no setup exists');

        // Navigate through wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardVerifyNewSetupSource(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        SubManSetupLbl: Label 'Subcontracting Management Setup', Locked = true;
    begin
        // [SCENARIO G5] Verify that BomRtngFromSource reflects new setup
        WizardWasOpened := true;

        // Verify that the source field shows Empty (new setup is used)
        Assert.AreEqual(SubManSetupLbl, PurchProvisionWizard.BomRtngFromSource.Value(),
            'BomRtngFromSource should reflect new setup configuration');

        // Navigate through wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Source Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. Source Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. Source Test");
    end;
}