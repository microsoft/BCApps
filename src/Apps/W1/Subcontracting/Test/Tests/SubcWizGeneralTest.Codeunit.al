// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

codeunit 149918 "Subc. Wiz. General Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard
        IsInitialized := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        SubCreateProdOrdWizLibrary: Codeunit "Subc. CreateProdOrdWizLibrary";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        ProdOrderCheckLib: Codeunit "Subc. ProdOrderCheckLib";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
        WizardFinishedSuccessfully: Boolean;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizard')]
    procedure TestOpenAndFinishingWizard()
    var
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Test Open wizard functionality
        // [GIVEN] proper setup configuration
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Create purchase line with subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Verify wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizard')]
    procedure TestCreateProdOrderWizardNothingPresentScenario()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
    begin
        // [SCENARIO] Test Production Order Creation Wizard for NothingPresent scenario
        // [GIVEN] Item without BOM and Routing, proper setup configuration
        Initialize();

        // Create item without BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', '');

        // Create purchase line with subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Verify wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        ProdOrderCheckLib.CreateTempProdOrderComponentFromSetup(TempProdOrderComponent, PurchLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromSetup(TempProdOrderRoutingLine, '10');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizard')]
    procedure TestCreateProdOrderWizardBothPresentScenario()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO] Test Production Order Creation Wizard for BothPresent scenario
        // [GIVEN] Item with both BOM (2 lines) and Routing (2 lines), proper setup configuration
        Initialize();

        // Create BOM with 2 lines
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();

        // Create Routing with 2 lines
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();

        // Create item with BOM and Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create purchase line with subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Verify wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records based on BOM and Routing
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizard')]
    procedure TestCreateProdOrderWizardRoutingPresentBOMFromSetupScenario()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO] Test Production Order Creation Wizard for RoutingPresent scenario
        // [GIVEN] Item with Routing (2 lines) but no BOM, BOM components from setup configuration
        Initialize();

        // Create Routing with 2 lines
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();

        // Create item with Routing but no BOM
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting('', RoutingNo);

        // Create purchase line with subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Verify wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records: BOM from setup, Routing from item
        ProdOrderCheckLib.CreateTempProdOrderComponentFromSetup(TempProdOrderComponent, PurchLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizard')]
    procedure TestCreateProdOrderWizardBOMPresentRoutingFromSetupScenario()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
    begin
        // [SCENARIO] Test Production Order Creation Wizard for BOMPresent scenario
        // [GIVEN] Item with BOM (2 lines) but no Routing, Routing from setup configuration
        Initialize();

        // Create BOM with 2 lines
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();

        // Create item with BOM but no Routing
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');

        // Create purchase line with subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Verify wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records: BOM from item, Routing from setup
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromSetup(TempProdOrderRoutingLine, '10');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizard')]
    procedure TestWizardPreservesDescription2ThroughBOMAndRoutingLines()
    var
        ProdOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
        SubcWorkCenterNo: Code[20];
        BOMLineDescription2: Text[50];
        RoutingLineDescription2: Text[50];
    begin
        // [SCENARIO] Description 2 from BOM line and Routing line is preserved end-to-end through
        // the Production Order Creation Wizard to Prod. Order Components and Routing Lines
        // [FEATURE] Bug 620556 - Subcontracting Description 2 alignment

        // [GIVEN] Proper setup configuration
        Initialize();

        // [GIVEN] A BOM with a line that has Description 2 set
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithDescription2(BOMLineDescription2);

        // [GIVEN] A Routing with a subcontracting work center line that has Description 2 set
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithSubcWorkCenterAndDescription2(SubcWorkCenterNo, RoutingLineDescription2);

        // [GIVEN] An item with the BOM and Routing above
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // [GIVEN] A purchase line with a subcontracting vendor
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard completed successfully
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // [THEN] Production Order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order No. should be set on Purchase Line');
        ProdOrder.Get("Production Order Status"::Released, PurchLine."Prod. Order No.");

        // [THEN] Description 2 from the BOM line is preserved on the Prod. Order Component
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(ProdOrderComponent.FindFirst(), 'Prod. Order Component must exist');
        Assert.AreEqual(
            BOMLineDescription2, ProdOrderComponent."Description 2",
            'Description 2 from the Production BOM Line must be preserved on the Prod. Order Component');

        // [THEN] Description 2 from the Routing line is preserved on the Prod. Order Routing Line
        ProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderRoutingLine.SetRange("Work Center No.", SubcWorkCenterNo);
        Assert.IsTrue(ProdOrderRoutingLine.FindFirst(), 'Prod. Order Routing Line must exist for subcontracting work center');
        Assert.AreEqual(
            RoutingLineDescription2, ProdOrderRoutingLine."Description 2",
            'Description 2 from the Routing Line must be preserved on the Prod. Order Routing Line');
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizard(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // [SCENARIO] Handle the Production Order Creation Wizard for all scenarios
        // The wizard should navigate through all steps and finish successfully

        // Simply navigate through the wizard by clicking Next until Finish is available
        // This handler works for both NothingPresent and BothPresent scenarios

        // Click Next to proceed through the wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            Assert.AreEqual('Next', LibraryVariableStorage.DequeueText(), 'Unexpected wizard navigation action');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        // Click Finish to complete the wizard
        if ProductionDefinitionWizard.ActionFinish.Enabled() then begin
            Assert.AreEqual('Finish', LibraryVariableStorage.DequeueText(), 'Unexpected wizard finish action');
            ProductionDefinitionWizard.ActionFinish.Invoke();
            WizardFinishedSuccessfully := true;
        end;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. General Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();
        EnqueueWizardNavigation(4);

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. General Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. General Test");
    end;

    local procedure EnqueueWizardNavigation(NextCount: Integer)
    var
        Index: Integer;
    begin
        for Index := 1 to NextCount do
            LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('Finish');
    end;
}