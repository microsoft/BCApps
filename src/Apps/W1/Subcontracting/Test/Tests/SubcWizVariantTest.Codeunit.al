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
using Microsoft.Manufacturing.Wizard;
using Microsoft.Purchases.Document;

codeunit 139996 "Subc. Wiz. Variant Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard Variant Tests
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        ProdOrderCheckLib: Codeunit "Subc. ProdOrderCheckLib";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        WizardFinishedSuccessfully: Boolean;
        WizardWasOpened: Boolean;
        NoToSelect, VersionToSelect : Code[20];


    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardNewBOMVariant')]
    procedure TestC1_NewBOMVariant_LinesEditable()
    var
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO C1] new BOM variant - Button "New Variant" - Lines are editable
        // [GIVEN] Item with BOM and Routing, setup configured to allow editing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and create new BOM variant
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have opened and new BOM variant should be creatable with editable lines
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with new BOM variant');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardModifyBOMLines')]
    procedure TestC2_ModifyBOMLines_ChangesAppliedToComponents()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO C2] Lines changed, deleted, added - In UI - Changes are output in component lines
        // [GIVEN] Item with BOM and Routing, setup configured to allow editing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and modify BOM lines
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully and changes should be applied to production order components
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with modified components
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary components with modified values from handler
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);

        // Update the temporary record with the expected modified values from the handler
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindFirst() then begin
            TempProdOrderComponent."Quantity per" := 5;  // Value that will be set in handler
            TempProdOrderComponent.Modify();
        end;

        // Verify that the modified components match the expected values
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardNewRoutingVariant')]
    procedure TestC3_NewRoutingVariant_LinesEditable()
    var
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO C3] new routing variant - Button "New Variant" - Lines are editable
        // [GIVEN] Item with BOM and Routing, setup configured to allow editing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and create new Routing variant
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have opened and new Routing variant should be creatable with editable lines
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with new Routing variant');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardModifyRoutingLines')]
    procedure TestC4_ModifyRoutingLines_ChangesAppliedToOperations()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO C4] Lines changed, deleted, added - In UI - Changes are output in production routing operations
        // [GIVEN] Item with BOM and Routing, setup configured to allow editing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and modify Routing lines
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully and changes should be applied to production order routing lines
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with modified routing lines
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary routing lines with modified values from handler
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);

        // Update the temporary record with the expected modified values from the handler
        TempProdOrderRoutingLine.Reset();
        if TempProdOrderRoutingLine.FindFirst() then begin
            TempProdOrderRoutingLine."Run Time" := 10;  // Value set in handler
            TempProdOrderRoutingLine."Setup Time" := 20; // Value set in handler
            TempProdOrderRoutingLine.Modify();
        end;

        // Verify that the modified routing lines match the expected values
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardSaveToStockkeeping')]
    procedure TestH1_SaveWithStockkeeping_NewVariantInStockkeeping()
    var
        ProductionBOMVersion: Record "Production BOM Version";
        PurchLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
        LocationCode: Code[10];
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO H1] Save + Stockkeeping filled - new variant in stockkeeping
        // [GIVEN] Item with BOM and Routing, Stockkeeping Unit exists, save is enabled
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create Stockkeeping Unit (using available library methods)
        LocationCode := SubCreateProdOrdWizLibrary.CreateLocationCode();
        SubCreateProdOrdWizLibrary.CreateStockkeepingUnit(StockkeepingUnit, ItemNo, LocationCode);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line with location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // [WHEN] Run the Production Order Creation Wizard and save new variant to stockkeeping
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully and new BOM variant should be saved to stockkeeping unit
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify that a new BOM version was created and assigned to stockkeeping unit
        StockkeepingUnit.Get(LocationCode, ItemNo, '');
        Assert.AreNotEqual('', StockkeepingUnit."Production BOM No.", 'Stockkeeping Unit should have BOM assigned');

        // Verify new BOM version exists
        ProductionBOMVersion.SetRange("Production BOM No.", StockkeepingUnit."Production BOM No.");
        ProductionBOMVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsFalse(ProductionBOMVersion.IsEmpty(), 'New BOM version should exist');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardSaveToItem')]
    procedure TestH2_SaveWithItem_NewVariantInItem()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        OriginalBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO H2] Save + Item filled - new variant in item
        // [GIVEN] Item with BOM and Routing, no stockkeeping unit, save is enabled
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Store original BOM No
        Item.Get(ItemNo);
        OriginalBOMNo := Item."Production BOM No.";

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and save new variant to item
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully and new BOM variant should be saved to item
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify that item has new BOM assigned (equal to original)
        Item.Get(ItemNo);
        Assert.AreEqual(OriginalBOMNo, Item."Production BOM No.", 'Item should have same BOM assigned');

        // Verify new BOM version exists
        ProductionBOMVersion.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsTrue(ProductionBOMVersion.FindFirst(), 'New BOM version should exist');
        Assert.AreEqual(ProductionBOMVersion.Status, ProductionBOMVersion.Status::Certified, 'New BOM should be certified');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardSaveNoChanges')]
    procedure TestH3_SaveNoChanges_NoNewVariant()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        OriginalBOMNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO H3] Save + no changes - no new variant
        // [GIVEN] Item with BOM and Routing, save is enabled but no changes made
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Store original BOM No
        Item.Get(ItemNo);
        OriginalBOMNo := Item."Production BOM No.";

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard without making changes
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully but no new variant should be created
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify that item still has original BOM (no new variant created)
        Item.Get(ItemNo);
        Assert.AreEqual(OriginalBOMNo, Item."Production BOM No.", 'Item should still have original BOM when no changes made');

        // Verify no new BOM version was created
        ProductionBOMVersion.SetRange("Production BOM No.", Item."Production BOM No.");
        ProductionBOMVersion.SetFilter("Version Code", '<>%1', '');
        Assert.IsTrue(ProductionBOMVersion.IsEmpty(), 'No new BOM version should exist when no changes made');
    end;


    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardNewBOMVersion')]
    procedure TestI1_NewBOMVersion_NewestVersionUsed()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO I1] new BOM version - newest version is used
        // [GIVEN] Item with BOM and Routing, new BOM version exists
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create new BOM version (simulated by creating another BOM)
        SubCreateProdOrdWizLibrary.CreateBOMVersionWithTwoLines(BOMNo, 'A');
        SubCreateProdOrdWizLibrary.CreateBOMVersionWithTwoLines(BOMNo, 'B');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard with new BOM version available
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should use the new BOM version
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Verify production order was created with new BOM version
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOMVersion(TempProdOrderComponent, BOMNo, 'B', PurchLine);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardNewRoutingVersion')]
    procedure TestI2_NewRoutingVersion_NewestVersionUsed()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO I2] new Routing version - newest version is used
        // [GIVEN] Item with BOM and Routing, new Routing version exists
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create new Routing version
        SubCreateProdOrdWizLibrary.CreateRoutingVersionWithTwoLines(RoutingNo, 'A');
        SubCreateProdOrdWizLibrary.CreateRoutingVersionWithTwoLines(RoutingNo, 'B');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard with new Routing version available
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should use the new Routing version
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Verify production order was created with new Routing version
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRoutingVersion(TempProdOrderRoutingLine, RoutingNo, 'B');
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardSelectBOMVariant,SelectBOMVersion')]
    procedure TestJ1_SelectExistingBOMVariant_LinesExchanged()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO J1] use existing BOM variant - Lines are exchanged
        // [GIVEN] Item with BOM and Routing, alternate BOM version exists
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create alternate BOM version with different lines
        SubCreateProdOrdWizLibrary.CreateBOMVersionWithTwoLines(BOMNo, 'A');
        SubCreateProdOrdWizLibrary.CreateBOMVersionWithTwoLines(BOMNo, 'B');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and select alternate BOM variant
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully and used alternate BOM version
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with alternate BOM version components
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary components from alternate BOM version
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOMVersion(TempProdOrderComponent, BOMNo, 'A', PurchLine);

        // Verify that the components match the alternate BOM version
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardSelectRoutingVariant,SelectRoutingVersion')]
    procedure TestJ2_SelectExistingRoutingVariant_LinesExchanged()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO J2] use existing Routing variant - Routing lines are exchanged
        // [GIVEN] Item with BOM and Routing, alternate Routing version exists
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create alternate Routing version with different lines
        SubCreateProdOrdWizLibrary.CreateRoutingVersionWithTwoLines(RoutingNo, 'A');
        SubCreateProdOrdWizLibrary.CreateRoutingVersionWithTwoLines(RoutingNo, 'B');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard and select alternate Routing variant
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();

        // [THEN] Wizard should have finished successfully and used alternate Routing version
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with alternate Routing version lines
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary routing lines from alternate Routing version
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRoutingVersion(TempProdOrderRoutingLine, RoutingNo, 'A');

        // Verify that the routing lines match the alternate Routing version
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardNewBOMVariant(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO C1] Handle wizard to create new BOM variant
        WizardWasOpened := true;

        // Navigate through wizard steps until we can create a new BOM version
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            // Check if we can create a new BOM version on this step
            if ProductionDefinitionWizard.CreateBOMVersionField.Visible() then begin
                ProductionDefinitionWizard.CreateBOMVersionField.SetValue(true);
                // Verify that BOM lines are now editable
                Assert.IsTrue(ProductionDefinitionWizard.BOMLinesPart.Editable(), 'BOM lines should be editable when creating new version');
            end;
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardModifyBOMLines(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO C2] Handle wizard to modify BOM lines
        WizardWasOpened := true;

        // Navigate through wizard steps and modify BOM lines
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            // Check if we can create a new BOM version on this step
            if ProductionDefinitionWizard.CreateBOMVersionField.Visible() then begin
                ProductionDefinitionWizard.CreateBOMVersionField.SetValue(true);
                // Verify that BOM lines are now editable
                Assert.IsTrue(ProductionDefinitionWizard.BOMLinesPart.Editable(), 'BOM lines should be editable when creating new version');
                ProductionDefinitionWizard.BOMLinesPart.First();
                // Modify the quantity per of the first BOM line
                ProductionDefinitionWizard.BOMLinesPart."Quantity per".SetValue(5);
            end;
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardNewRoutingVariant(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO C3] Handle wizard to create new Routing variant
        WizardWasOpened := true;

        // Navigate through wizard steps until we can create a new Routing version
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            // Check if we can create a new Routing version on this step
            if ProductionDefinitionWizard.CreateRoutingVersionField.Visible() then begin
                ProductionDefinitionWizard.CreateRoutingVersionField.SetValue(true);
                // Verify that Routing lines are now editable
                Assert.IsTrue(ProductionDefinitionWizard.RoutingLinesPart.Editable(), 'Routing lines should be editable when creating new version');
            end;
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardModifyRoutingLines(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO C4] Handle wizard to modify Routing lines
        WizardWasOpened := true;

        // Navigate through wizard steps and modify Routing lines
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            // Check if we can create a new Routing version on this step
            if ProductionDefinitionWizard.CreateRoutingVersionField.Visible() then begin
                ProductionDefinitionWizard.CreateRoutingVersionField.SetValue(true);
                // Verify that Routing lines are now editable
                Assert.IsTrue(ProductionDefinitionWizard.RoutingLinesPart.Editable(), 'Routing lines should be editable when creating new version');
                ProductionDefinitionWizard.RoutingLinesPart.First();
                // Modify some routing lines here
                ProductionDefinitionWizard.RoutingLinesPart."Run Time".SetValue(10);
                ProductionDefinitionWizard.RoutingLinesPart."Setup Time".SetValue(20);
            end;
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardSaveToStockkeeping(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO H1] Handle wizard to save new variant to stockkeeping unit
        WizardWasOpened := true;

        Assert.IsFalse(ProductionDefinitionWizard.SaveBomRtngToSourceField.Editable(), 'Save to source should not be Editable initially');
        ProductionDefinitionWizard.SaveBOMRoutingField.SetValue(true);
        Assert.IsTrue(ProductionDefinitionWizard.SaveBomRtngToSourceField.Editable(), 'Save to source should be Editable after enabling save');
        ProductionDefinitionWizard.SaveBomRtngToSourceField.SetValue("Prod. Definition Source"::StockkeepingUnit);

        // Navigate through wizard steps and enable saving to stockkeeping
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            // Check if we can create a new BOM version and save it
            if ProductionDefinitionWizard.CreateBOMVersionField.Visible() then
                ProductionDefinitionWizard.CreateBOMVersionField.SetValue(true);
            // Enable saving the variant (simulated)
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardSaveToItem(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO H2] Handle wizard to save new variant to item
        WizardWasOpened := true;

        Assert.IsFalse(ProductionDefinitionWizard.SaveBomRtngToSourceField.Editable(), 'Save to source should not be Editable initially');
        ProductionDefinitionWizard.SaveBOMRoutingField.SetValue(true);
        Assert.IsTrue(ProductionDefinitionWizard.SaveBomRtngToSourceField.Editable(), 'Save to source should be Editable after enabling save');
        ProductionDefinitionWizard.SaveBomRtngToSourceField.SetValue("Prod. Definition Source"::Item);

        // Navigate through wizard steps and enable saving to item
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            // Check if we can create a new BOM version and save it
            if ProductionDefinitionWizard.CreateBOMVersionField.Visible() then
                ProductionDefinitionWizard.CreateBOMVersionField.SetValue(true);
            // Enable saving the variant (simulated)
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardSaveNoChanges(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO H3] Handle wizard without making changes (no save needed)
        WizardWasOpened := true;

        Assert.AreEqual(Format("Prod. Definition Source"::Empty), ProductionDefinitionWizard.SaveBomRtngToSourceField.Value(), 'Save to source should be empty initially');

        // Navigate through wizard steps without making changes
        while ProductionDefinitionWizard.ActionNext.Enabled() do
            // Don't create new versions or make changes
            ProductionDefinitionWizard.ActionNext.Invoke();

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardNewBOMVersion(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO I1] Handle wizard to use new BOM version
        WizardWasOpened := true;

        // Navigate through wizard steps and use new BOM version
        while ProductionDefinitionWizard.ActionNext.Enabled() do
            // The wizard should automatically select the newest version
            ProductionDefinitionWizard.ActionNext.Invoke();

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardNewRoutingVersion(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO I2] Handle wizard to use new Routing version
        WizardWasOpened := true;

        // Navigate through wizard steps and use new Routing version
        while ProductionDefinitionWizard.ActionNext.Enabled() do
            // The wizard should automatically select the newest version
            ProductionDefinitionWizard.ActionNext.Invoke();

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    [HandlerFunctions('SelectBOMVersion')]
    procedure HandleProductionDefinitionWizardSelectBOMVariant(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        BOMVersion: Record "Production BOM Version";
        NewItemNo: Text;
        OriginalItemNo: Text;
    begin
        // [SCENARIO J1] Handle wizard to select existing BOM variant and verify lines are updated
        WizardWasOpened := true;

        if ProductionDefinitionWizard.ActionNext.Enabled() then
            ProductionDefinitionWizard.ActionNext.Invoke();

        // Get the current BOM lines before changing version
        if ProductionDefinitionWizard.BOMLinesPart.First() then
            OriginalItemNo := ProductionDefinitionWizard.BOMLinesPart."No.".Value();

        // Find and select the alternate BOM version 'B'
        BOMVersion.SetRange("Production BOM No.", ProductionDefinitionWizard.ProductionBOMNoField.Value());
        BOMVersion.SetRange("Version Code", 'A');
        Assert.IsTrue(BOMVersion.FindFirst(), 'BOM version A should exist for selected BOM');

        // Select the alternate BOM version
        NoToSelect := BOMVersion."Production BOM No.";
        VersionToSelect := BOMVersion."Version Code";
        ProductionDefinitionWizard.SelectedBOMVersionField.AssistEdit();

        // Verify that the BOM lines have been updated after version change
        if ProductionDefinitionWizard.BOMLinesPart.First() then begin
            NewItemNo := ProductionDefinitionWizard.BOMLinesPart."No.".Value();
            // The lines should be different between versions (different component items)
            Assert.AreNotEqual(OriginalItemNo, NewItemNo, 'BOM lines should be updated when version is changed');
        end;

        // Navigate through remaining wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do
            ProductionDefinitionWizard.ActionNext.Invoke();

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    [HandlerFunctions('SelectRoutingVersion')]
    procedure HandleProductionDefinitionWizardSelectRoutingVariant(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        RoutingVersion: Record "Routing Version";
        NewWorkCenterNo: Text;
        OriginalWorkCenterNo: Text;
    begin
        // [SCENARIO J2] Handle wizard to select existing Routing variant and verify lines are updated
        WizardWasOpened := true;

        if ProductionDefinitionWizard.ActionNext.Enabled() then
            ProductionDefinitionWizard.ActionNext.Invoke(); //Components

        if ProductionDefinitionWizard.ActionNext.Enabled() then
            ProductionDefinitionWizard.ActionNext.Invoke(); //Routing

        // Get the current Routing lines before changing version
        if ProductionDefinitionWizard.RoutingLinesPart.First() then
            OriginalWorkCenterNo := ProductionDefinitionWizard.RoutingLinesPart."No.".Value();

        // Find and select the alternate Routing version 'A'
        RoutingVersion.SetRange("Routing No.", ProductionDefinitionWizard.RoutingNoField.Value());
        RoutingVersion.SetRange("Version Code", 'A');
        Assert.IsTrue(RoutingVersion.FindFirst(), 'Routing version A should exist for selected Routing');

        // Set global variables for the SelectRoutingVersion handler
        NoToSelect := RoutingVersion."Routing No.";
        VersionToSelect := RoutingVersion."Version Code";
        ProductionDefinitionWizard.SelectedRoutingVersionField.AssistEdit();

        // Verify that the Routing lines have been updated after version change
        if ProductionDefinitionWizard.RoutingLinesPart.First() then begin
            NewWorkCenterNo := ProductionDefinitionWizard.RoutingLinesPart."No.".Value();
            // The lines should be different between versions (different work centers)
            Assert.AreNotEqual(OriginalWorkCenterNo, NewWorkCenterNo, 'Routing lines should be updated when version is changed');
        end;

        // Navigate through remaining wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do
            ProductionDefinitionWizard.ActionNext.Invoke();

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardSwitchVariants(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO J3] Handle wizard to switch between variants
        WizardWasOpened := true;

        // Navigate through wizard steps and switch between variants
        while ProductionDefinitionWizard.ActionNext.Enabled() do
            // Switch between variants (simulated)
            ProductionDefinitionWizard.ActionNext.Invoke();

        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardInvalidVariant(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO J4] Handle wizard to select invalid variant (should cause error)
        WizardWasOpened := true;

        // This handler should cause an error
        Error('Invalid variant selected');
    end;

    [ModalPageHandler]
    procedure SelectBOMVersion(var BOMVersionList: TestPage "Prod. BOM Version List")
    var
        BOMVersion: Record "Production BOM Version";
    begin
        BOMVersionList.First();
        BOMVersion.Get(NoToSelect, VersionToSelect);
        BOMVersionList.GoToRecord(BOMVersion);
        BOMVersionList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectRoutingVersion(var RoutingVersionList: TestPage "Routing Version List")
    var
        RoutingVersion: Record "Routing Version";
    begin
        RoutingVersionList.First();
        RoutingVersion.Get(NoToSelect, VersionToSelect);
        RoutingVersionList.GoToRecord(RoutingVersion);
        RoutingVersionList.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Variant Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. Variant Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. Variant Test");
    end;
}