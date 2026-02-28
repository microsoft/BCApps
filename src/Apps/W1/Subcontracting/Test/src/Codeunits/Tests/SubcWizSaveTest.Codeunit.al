// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;

codeunit 139998 "Subc. Wiz. Save Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard Save Tests
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        ProdOrderCheckLib: Codeunit "Subc. ProdOrderCheckLib";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        SaveBOMRouting: Boolean;
        WizardFinishedSuccessfully: Boolean;
        WizardWasOpened: Boolean;
        SaveBomRtngToSource: Enum "Subc. RtngBOMSourceType";
        BOMShouldExistLbl: Label 'BOM %1 should exist', Locked = true;
        RoutingShouldExistLbl: Label 'Routing %1 should exist', Locked = true;

    // ==================== SCENARIO H: BOM/Routing Save Tests ====================

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardNoSave')]
    procedure TestH1_NoSaveFlag_BOMNotSaved()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO H1] SaveBOMRouting = false - BOM should not be saved to source
        // [GIVEN] Item without BOM/Routing, wizard creates new BOM
        Initialize();

        // Create item without BOM/Routing (nothing present scenario)
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both for nothing present scenario
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);
        SetAlwaysSaveModifiedVersions(false);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set save flags for handler
        SaveBOMRouting := false;
        Clear(SaveBomRtngToSource);

        // [WHEN] Run the Production Order Creation Wizard without saving
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully but BOM should not be saved to item
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        // Verify item still has no BOM/Routing assigned
        VerifyItemHasNoBOMRouting(ItemNo);

        // Verify temporary BOM was cleaned up (should not exist in master data)
        VerifyTemporaryBOMWasCleanedUp();

        // Create expected temporary components from the selected BOM
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromSetup(TempProdOrderComponent, PurchLine);
        // Create expected temporary routing lines from the selected Routing
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromSetup(TempProdOrderRoutingLine, '10');

        // Verify that both components and routing lines match the selected BOM and Routing
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardSaveToItem')]
    procedure TestH2_SaveToItem_BOMSavedToItem()
    var
        Item: Record Item;
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        ItemNo: Code[20];
    begin
        // [SCENARIO H2] SaveBomRtngToSource = Item - BOM should be saved to item
        // [GIVEN] Item without BOM/Routing, wizard creates new BOM
        Initialize();

        // Create item without BOM/Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both for nothing present scenario
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);
        SetAlwaysSaveModifiedVersions(false);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set save flags for handler
        SaveBOMRouting := true;
        SaveBomRtngToSource := SaveBomRtngToSource::Item;

        // [WHEN] Run the Production Order Creation Wizard with save to item
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and BOM should be saved to item
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        // Verify item now has BOM/Routing assigned
        Item.Get(ItemNo);
        Assert.AreNotEqual('', Item."Production BOM No.", 'Item should have BOM assigned');
        Assert.AreNotEqual('', Item."Routing No.", 'Item should have Routing assigned');

        // Verify BOM and Routing exist in master data
        VerifyBOMExists(Item."Production BOM No.");
        VerifyRoutingExists(Item."Routing No.");

        // Create expected temporary components from the selected BOM
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, Item."Production BOM No.", PurchLine);
        // Create expected temporary routing lines from the selected Routing
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, Item."Routing No.");

        // Verify that both components and routing lines match the selected BOM and Routing
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardSaveToStockkeepingUnit')]
    procedure TestH3_SaveToStockkeepingUnit_BOMSavedToSKU()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        LocationCode: Code[10];
        ItemNo: Code[20];
    begin
        // [SCENARIO H3] SaveBomRtngToSource = StockkeepingUnit - BOM should be saved to SKU
        // [GIVEN] Item without BOM/Routing, wizard creates new BOM
        Initialize();

        // Create item without BOM/Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both for nothing present scenario
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);
        SetAlwaysSaveModifiedVersions(false);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        LocationCode := PurchLine."Location Code";

        // Set save flags for handler
        SaveBOMRouting := true;
        SaveBomRtngToSource := SaveBomRtngToSource::StockkeepingUnit;

        // [WHEN] Run the Production Order Creation Wizard with save to stockkeeping unit
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and BOM should be saved to SKU
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        // Verify item still has no BOM/Routing assigned
        VerifyItemHasNoBOMRouting(ItemNo);

        // Verify stockkeeping unit was created with BOM/Routing
        Assert.IsTrue(StockkeepingUnit.Get(LocationCode, ItemNo, ''), 'Stockkeeping Unit should have been created');
        Assert.AreNotEqual('', StockkeepingUnit."Production BOM No.", 'SKU should have BOM assigned');
        Assert.AreNotEqual('', StockkeepingUnit."Routing No.", 'SKU should have Routing assigned');

        // Verify BOM and Routing exist in master data
        VerifyBOMExists(StockkeepingUnit."Production BOM No.");
        VerifyRoutingExists(StockkeepingUnit."Routing No.");

        // Create expected temporary components from the selected BOM
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, StockkeepingUnit."Production BOM No.", PurchLine);
        // Create expected temporary routing lines from the selected Routing
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, StockkeepingUnit."Routing No.");

        // Verify that both components and routing lines match the selected BOM and Routing
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardCreateNewVersion')]
    procedure TestH4_AlwaysSaveModifiedVersionsTrue_VersionSaved()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProductionBOMVersion: Record "Production BOM Version";
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        RoutingVersion: Record "Routing Version";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO H4] Always Save Modified Versions = true - Version should be saved even without SaveBomRtngToSource
        // [GIVEN] Item with BOM/Routing, wizard creates new version
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both and always save modified versions
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);
        SetAlwaysSaveModifiedVersions(true);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set save flags for handler (no save to source, but create new version)
        SaveBOMRouting := false;
        Clear(SaveBomRtngToSource);

        // [WHEN] Run the Production Order Creation Wizard with new version creation
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and version should be saved
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        // Verify new versions were created and saved
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        ProductionBOMVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsFalse(ProductionBOMVersion.IsEmpty(), 'BOM Version should have been created');

        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsFalse(RoutingVersion.IsEmpty(), 'Routing Version should have been created');

        // Create expected temporary components from the selected BOM
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProductionBOMVersion.FindFirst();
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOMVersion(TempProdOrderComponent, ProductionBOMVersion."Production BOM No.", ProductionBOMVersion."Version Code", PurchLine);
        // Create expected temporary routing lines from the selected Routing
        RoutingVersion.FindFirst();
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRoutingVersion(TempProdOrderRoutingLine, RoutingVersion."Routing No.", RoutingVersion."Version Code");

        // Verify that both components and routing lines match the selected BOM and Routing
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardCreateNewVersionNoSave')]
    procedure TestH5_AlwaysSaveModifiedVersionsFalse_VersionNotSaved()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        PurchLine: Record "Purchase Line";
        RoutingVersion: Record "Routing Version";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO H5] Always Save Modified Versions = false and no SaveBomRtngToSource - Version should not be saved
        // [GIVEN] Item with BOM/Routing, wizard creates new version
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both but don't always save modified versions
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);
        SetAlwaysSaveModifiedVersions(false);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set save flags for handler (no save to source, create new version)
        SaveBOMRouting := false;
        Clear(SaveBomRtngToSource);

        // [WHEN] Run the Production Order Creation Wizard with new version creation but no save
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully but version should not be saved
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        // Verify no new versions were saved (temporary versions should be cleaned up)
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        ProductionBOMVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsTrue(ProductionBOMVersion.IsEmpty(), 'BOM Version should not have been saved');

        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsTrue(RoutingVersion.IsEmpty(), 'Routing Version should not have been saved');
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardCreateNewVersionSaveToItem')]
    procedure TestH6_SaveToItemWithNewVersion_VersionSaved()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        PurchLine: Record "Purchase Line";
        RoutingVersion: Record "Routing Version";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO H6] SaveBomRtngToSource = Item with new version - Version should be saved
        // [GIVEN] Item with BOM/Routing, wizard creates new version
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both but don't always save modified versions
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);
        SetAlwaysSaveModifiedVersions(false);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set save flags for handler (save to item, create new version)
        SaveBOMRouting := true;
        SaveBomRtngToSource := SaveBomRtngToSource::Item;

        // [WHEN] Run the Production Order Creation Wizard with new version creation and save to item
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and version should be saved
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        // Verify new versions were created and saved (because SaveBomRtngToSource is set)
        ProductionBOMVersion.SetRange("Production BOM No.", BOMNo);
        ProductionBOMVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsFalse(ProductionBOMVersion.IsEmpty(), 'BOM Version should have been created');

        RoutingVersion.SetRange("Routing No.", RoutingNo);
        RoutingVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsFalse(RoutingVersion.IsEmpty(), 'Routing Version should have been created');
    end;

    // ==================== MODAL PAGE HANDLERS ====================

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardNoSave(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // Handle wizard without saving BOM/Routing
        WizardWasOpened := true;

        // Set save options
        PurchProvisionWizard.SaveBOMRouting.SetValue(SaveBOMRouting);

        // Navigate through all wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardSaveToItem(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // Handle wizard with save to item
        WizardWasOpened := true;

        // Set save options
        PurchProvisionWizard.SaveBOMRouting.SetValue(SaveBOMRouting);
        if SaveBOMRouting then
            PurchProvisionWizard.SaveBomRtngToSource.SetValue(SaveBomRtngToSource);

        // Navigate through all wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardSaveToStockkeepingUnit(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // Handle wizard with save to stockkeeping unit
        WizardWasOpened := true;

        // Set save options
        PurchProvisionWizard.SaveBOMRouting.SetValue(SaveBOMRouting);
        if SaveBOMRouting then
            PurchProvisionWizard.SaveBomRtngToSource.SetValue(SaveBomRtngToSource);

        // Navigate through all wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardCreateNewVersion(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // Handle wizard with new version creation
        WizardWasOpened := true;

        // Set save options
        PurchProvisionWizard.SaveBOMRouting.SetValue(SaveBOMRouting);
        if SaveBOMRouting then
            PurchProvisionWizard.SaveBomRtngToSource.SetValue(SaveBomRtngToSource);

        // Navigate to BOM step and create new version
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.CreateBOMVersion.SetValue(true);

        // Navigate to Routing step and create new version
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.CreateRoutingVersion.SetValue(true);

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardCreateNewVersionNoSave(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // Handle wizard with new version creation but no save
        WizardWasOpened := true;

        // Set save options (no save)
        PurchProvisionWizard.SaveBOMRouting.SetValue(SaveBOMRouting);

        // Navigate to BOM step and create new version
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.CreateBOMVersion.SetValue(true);

        // Navigate to Routing step and create new version
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.CreateRoutingVersion.SetValue(true);

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardCreateNewVersionSaveToItem(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    begin
        // Handle wizard with new version creation and save to item
        WizardWasOpened := true;

        // Set save options
        PurchProvisionWizard.SaveBOMRouting.SetValue(SaveBOMRouting);
        if SaveBOMRouting then
            PurchProvisionWizard.SaveBomRtngToSource.SetValue(SaveBomRtngToSource);

        // Navigate to BOM step and create new version
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.CreateBOMVersion.SetValue(true);

        // Navigate to Routing step and create new version
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.CreateRoutingVersion.SetValue(true);

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    // ==================== HELPER METHODS ====================

    local procedure VerifyItemHasNoBOMRouting(ItemNo: Code[20])
    var
        Item: Record Item;
    begin
        Item.Get(ItemNo);
        Assert.AreEqual('', Item."Production BOM No.", 'Item should not have BOM assigned');
        Assert.AreEqual('', Item."Routing No.", 'Item should not have Routing assigned');
    end;

    local procedure VerifyBOMExists(BOMNo: Code[20])
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        Assert.IsTrue(ProductionBOMHeader.Get(BOMNo), StrSubstNo(BOMShouldExistLbl, BOMNo));
    end;

    local procedure VerifyRoutingExists(RoutingNo: Code[20])
    var
        RoutingHeader: Record "Routing Header";
    begin
        Assert.IsTrue(RoutingHeader.Get(RoutingNo), StrSubstNo(RoutingShouldExistLbl, RoutingNo));
    end;

    local procedure VerifyTemporaryBOMWasCleanedUp()
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        // Verify no temporary BOMs remain (BOMs created during wizard should be cleaned up if not saved)
        ProductionBOMHeader.SetFilter("No.", 'TEMP*');
        Assert.IsTrue(ProductionBOMHeader.IsEmpty(), 'Temporary BOMs should have been cleaned up');
    end;

    local procedure SetAlwaysSaveModifiedVersions(AlwaysSave: Boolean)
    var
        SubManagementSetup: Record "Subc. Management Setup";
    begin
        if not SubManagementSetup.Get() then begin
            SubManagementSetup.Init();
            SubManagementSetup.Insert();
        end;
        SubManagementSetup."Always Save Modified Versions" := AlwaysSave;
        SubManagementSetup.Modify();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Save Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. Save Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. Save Test");
    end;
}