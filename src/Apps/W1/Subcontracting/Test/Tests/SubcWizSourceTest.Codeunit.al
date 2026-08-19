// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

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
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
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
        ManSetupLbl: Label 'Manufacturing Setup', Locked = true;


    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardVerifyStockkeepingSource')]
    procedure TestG1_StockkeepingHasData_StockkeepingHasPriority()
    var
        PurchLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
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
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line with location (to trigger stockkeeping unit usage)
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // Set expected source type for handler verification
        EnqueueExpectedSource(Format("Prod. Definition Source"::StockkeepingUnit));

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should show Stockkeeping Unit as source
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Stockkeeping Unit as source');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardVerifyItemSource')]
    procedure TestG2_ItemHasData_StockkeepingEmpty_ItemUsed()
    var
        PurchLine: Record "Purchase Line";
        StockkeepingUnit: Record "Stockkeeping Unit";
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
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line with location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);
        PurchLine.Validate("Location Code", LocationCode);
        PurchLine.Modify();

        // Set expected source type for handler verification
        EnqueueExpectedSource(Format("Prod. Definition Source"::Item));

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should show Item as source
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Item as source');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardVerifySetupSource')]
    procedure TestG3_NothingFilled_NoData_SetupApplies()
    var
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO G3] Nothing filled → no data → Setup applies
        // [GIVEN] Item without BOM and Routing, no stockkeeping unit
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line without location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected source type for handler verification (should be Empty when using setup)
        EnqueueExpectedSource(ManSetupLbl);

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should show Empty as source (setup is used)
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Empty source (setup used)');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardVerifyEmptySource')]
    procedure TestG4_NothingFilled_NoSetup_FieldsEmpty()
    var
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO G4] Nothing filled → no setup → Fields empty
        // [GIVEN] Item without BOM and Routing, no stockkeeping unit, minimal setup
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line without location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set expected source type for handler verification
        EnqueueExpectedSource(ManSetupLbl);

        // [WHEN] Run the Production Order Creation Wizard
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should show Empty as source
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with Empty source');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardVerifyNewSetupSource')]
    procedure TestG5_SetupChanged_NewSetup_NewSetupApplies()
    var
        PurchLine: Record "Purchase Line";
        ManufacturingSetup: Record "Manufacturing Setup";
        ItemNo: Code[20];
    begin
        // [SCENARIO G5] Setup changed → new setup → new setup applies
        // [GIVEN] Item without BOM and Routing, setup is changed during test
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Configure initial setup for nothing present scenario
        SubSetupLibrary.ConfigureSubManagementForNothingPresentScenario("Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // Create purchase line without location
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Change setup during test (simulate setup change by modifying a field)
        ManufacturingSetup.Get();
        ManufacturingSetup."Show Prod Comp Select Nothing" := "Prod. Definition Display"::Show;
        ManufacturingSetup.Modify();

        // Set expected source type for handler verification
        EnqueueExpectedSource(ManSetupLbl);

        // [WHEN] Run the Production Order Creation Wizard with changed setup
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should use the new setup
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully with new setup');
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardVerifyStockkeepingSource(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO G3] Verify that BomRtngFromSource shows Empty when setup is used
        WizardWasOpened := true;

        // Verify that the source field shows StockkeepingUnit
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionDefinitionWizard.BomRtngFromSourceField.Value(),
            'BomRtngFromSource should show StockkeepingUnit when stockkeeping unit has data');

        // Navigate through wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            Assert.AreEqual('Next', LibraryVariableStorage.DequeueText(), 'Unexpected wizard navigation action');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        Assert.AreEqual('Finish', LibraryVariableStorage.DequeueText(), 'Unexpected wizard finish action');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardVerifyItemSource(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO G4] Verify that BomRtngFromSource shows Empty when no setup exists
        WizardWasOpened := true;

        // Verify that the source field shows Item
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionDefinitionWizard.BomRtngFromSourceField.Value(),
            'BomRtngFromSource should show Item when item has data and stockkeeping unit is empty');

        // Navigate through wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            Assert.AreEqual('Next', LibraryVariableStorage.DequeueText(), 'Unexpected wizard navigation action');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        Assert.AreEqual('Finish', LibraryVariableStorage.DequeueText(), 'Unexpected wizard finish action');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardVerifySetupSource(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO G5] Verify that BomRtngFromSource reflects new setup
        WizardWasOpened := true;

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionDefinitionWizard.BomRtngFromSourceField.Value(),
            'BomRtngFromSource should reflect new setup configuration');

        // Navigate through wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            Assert.AreEqual('Next', LibraryVariableStorage.DequeueText(), 'Unexpected wizard navigation action');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        Assert.AreEqual('Finish', LibraryVariableStorage.DequeueText(), 'Unexpected wizard finish action');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardVerifyEmptySource(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO G4] Verify that BomRtngFromSource shows Empty when no setup exists
        WizardWasOpened := true;

        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionDefinitionWizard.BomRtngFromSourceField.Value(),
            'BomRtngFromSource should show Empty when no data and no setup exists');

        // Navigate through wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            Assert.AreEqual('Next', LibraryVariableStorage.DequeueText(), 'Unexpected wizard navigation action');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        Assert.AreEqual('Finish', LibraryVariableStorage.DequeueText(), 'Unexpected wizard finish action');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardVerifyNewSetupSource(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO G5] Verify that BomRtngFromSource reflects new setup
        WizardWasOpened := true;

        // Verify that the source field shows Empty (new setup is used)
        Assert.AreEqual(LibraryVariableStorage.DequeueText(), ProductionDefinitionWizard.BomRtngFromSourceField.Value(),
            'BomRtngFromSource should reflect new setup configuration');

        // Navigate through wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            Assert.AreEqual('Next', LibraryVariableStorage.DequeueText(), 'Unexpected wizard navigation action');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        Assert.AreEqual('Finish', LibraryVariableStorage.DequeueText(), 'Unexpected wizard finish action');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Source Test");
        LibraryVariableStorage.Clear();
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

    local procedure EnqueueExpectedSource(ExpectedSource: Text)
    var
        Index: Integer;
    begin
        LibraryVariableStorage.Enqueue(ExpectedSource);
        for Index := 1 to 4 do
            LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('Finish');
    end;
}