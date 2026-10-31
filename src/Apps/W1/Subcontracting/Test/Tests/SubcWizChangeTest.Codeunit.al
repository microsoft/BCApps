// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using System.TestLibraries.Utilities;

codeunit 139980 "Subc. Wiz. Change Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard Change Tests
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
        ProdOrderCheckLib: Codeunit "Subc. ProdOrderCheckLib";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        IsInitialized: Boolean;
        WizardFinishedSuccessfully: Boolean;
        WizardWasOpened: Boolean;
        NewComponentNo, NewWorkCenterNo : Code[20];
        ModifiedQuantity: Decimal;
        ModifiedRunTime: Decimal;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardModifyComponents')]
    procedure TestN1_ComponentQuantityChanged_ChangesAppliedToProdOrder()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO N1] Component quantity modified in wizard - Changes should be applied to production order
        // [GIVEN] Item with BOM/Routing, wizard allows component editing
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set test parameters for handler
        ModifiedQuantity := 5.5; // Change quantity from default
        EnqueueComponentQuantityChange(ModifiedQuantity);

        // [WHEN] Run the Production Order Creation Wizard with component modifications
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and component changes should be applied
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records with modified quantity
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        UpdateTempComponentQuantity(TempProdOrderComponent, ModifiedQuantity);

        // Verify production order and components
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardAddComponent')]
    procedure TestN2_ComponentAdded_NewComponentInProdOrder()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO N2] Component added in wizard - New component should appear in production order
        // [GIVEN] Item with BOM/Routing, wizard allows component editing
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Create new component item
        NewComponentNo := CreateTestItem();

        // Set test parameters for handler
        ModifiedQuantity := 2.0;
        EnqueueComponentAddition(NewComponentNo, ModifiedQuantity);

        // [WHEN] Run the Production Order Creation Wizard with component addition
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and new component should be added
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records with additional component
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        AddTempComponent(TempProdOrderComponent, NewComponentNo, ModifiedQuantity, PurchLine);

        // Verify production order and components
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardDeleteComponent')]
    procedure TestN3_ComponentDeleted_ComponentRemovedFromProdOrder()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
        FinalComponentCount: Integer;
        OriginalComponentCount: Integer;
    begin
        // [SCENARIO N3] Component deleted in wizard - Component should be removed from production order
        // [GIVEN] Item with BOM/Routing, wizard allows component editing
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Get original component count
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        OriginalComponentCount := TempProdOrderComponent.Count();

        // Configure setup to edit components
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // [WHEN] Run the Production Order Creation Wizard with component deletion
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        EnqueueComponentDeletion();
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and component should be deleted
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records with one less component
        Clear(TempProdOrderComponent);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);

        RemoveTempComponent(TempProdOrderComponent);
        FinalComponentCount := TempProdOrderComponent.Count();

        // Verify component was deleted
        Assert.AreEqual(OriginalComponentCount - 1, FinalComponentCount, 'One component should have been deleted');

        // Verify production order and components
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardChangeComponentSupplyMethod')]
    procedure TestN4_ComponentSupplyMethodChangedToEmpty_RestoresOriginalLocation()
    var
        ProdOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        PurchLine: Record "Purchase Line";
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        Initialize();

        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithoutBOMAndRouting('', RoutingNo);
        SubSetupLibrary.ConfigureSubManagementForPartiallyPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        EnqueueComponentSupplyMethodChange();
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        Assert.IsTrue(ProdOrderComponent.FindFirst(), 'Production order component should exist');
        Assert.AreEqual("Component Supply Method"::Empty, ProdOrderComponent."Component Supply Method", 'Component supply method should be Empty');
        Assert.AreEqual(PurchLine."Location Code", ProdOrderComponent."Location Code", 'Component should be restored to the original location');
        Assert.AreEqual(PurchLine."Location Code", ProdOrderComponent."Subc. Original Location Code", 'Original component location should be retained');
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardModifyRouting')]
    procedure TestO1_RoutingOperationChanged_ChangesAppliedToProdOrder()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO O1] Routing operation modified in wizard - Changes should be applied to production order
        // [GIVEN] Item with BOM/Routing, wizard allows routing editing
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit routing
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set test parameters for handler
        ModifiedRunTime := 120.5; // Change run time from default
        EnqueueRoutingRuntimeChange(ModifiedRunTime);

        // [WHEN] Run the Production Order Creation Wizard with routing modifications
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and routing changes should be applied
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records with modified run time
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);
        UpdateTempRoutingRunTime(TempProdOrderRoutingLine, ModifiedRunTime);

        // Verify production order and routing
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardAddRoutingOperation')]
    procedure TestO2_RoutingOperationAdded_NewOperationInProdOrder()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
        FinalOperationCount: Integer;
        OriginalOperationCount: Integer;
    begin
        // [SCENARIO O2] Routing operation added in wizard - New operation should appear in production order
        // [GIVEN] Item with BOM/Routing, wizard allows routing editing
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Get original operation count
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);
        OriginalOperationCount := TempProdOrderRoutingLine.Count();

        // Configure setup to edit routing
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set test parameters for handler
        ModifiedRunTime := 60.0;
        NewWorkCenterNo := CreateWorkCenterNo(); // Create or use existing work center
        EnqueueRoutingOperationAddition(NewWorkCenterNo, ModifiedRunTime);

        // [WHEN] Run the Production Order Creation Wizard with routing operation addition
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and new operation should be added
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records with additional operation
        Clear(TempProdOrderRoutingLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);
        AddTempRoutingOperation(TempProdOrderRoutingLine, '0030', ModifiedRunTime);
        FinalOperationCount := TempProdOrderRoutingLine.Count();

        // Verify operation was added
        Assert.AreEqual(OriginalOperationCount + 1, FinalOperationCount, 'One operation should have been added');

        // Verify production order and routing
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardDeleteRoutingOperation')]
    procedure TestO3_RoutingOperationDeleted_OperationRemovedFromProdOrder()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
        FinalOperationCount: Integer;
        OriginalOperationCount: Integer;
    begin
        // [SCENARIO O3] Routing operation deleted in wizard - Operation should be removed from production order
        // [GIVEN] Item with BOM/Routing, wizard allows routing editing
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Get original operation count
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);
        OriginalOperationCount := TempProdOrderRoutingLine.Count();

        // Configure setup to edit routing
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard with routing operation deletion
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        EnqueueRoutingOperationDeletion();
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and operation should be deleted
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records without deleted operation
        Clear(TempProdOrderRoutingLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);
        RemoveTempRoutingOperation(TempProdOrderRoutingLine);
        FinalOperationCount := TempProdOrderRoutingLine.Count();

        // Verify operation was deleted
        Assert.AreEqual(OriginalOperationCount - 1, FinalOperationCount, 'One operation should have been deleted');

        // Verify production order and routing
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardModifyBoth')]
    procedure TestP1_BothComponentsAndRoutingChanged_AllChangesApplied()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO P1] Both components and routing modified in wizard - All changes should be applied to production order
        // [GIVEN] Item with BOM/Routing, wizard allows editing both
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set test parameters for handler
        ModifiedQuantity := 3.5;
        ModifiedRunTime := 90.0;
        EnqueueBothChanges(ModifiedQuantity, ModifiedRunTime);

        // [WHEN] Run the Production Order Creation Wizard with both modifications
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and all changes should be applied
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records with modifications
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        UpdateTempComponentQuantity(TempProdOrderComponent, ModifiedQuantity);

        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);
        UpdateTempRoutingRunTime(TempProdOrderRoutingLine, ModifiedRunTime);

        // Verify production order and both components and routing
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandleProductionDefinitionWizardNoChanges')]
    procedure TestP2_NoChanges_OriginalDataUsed()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO P2] No changes made in wizard - Original BOM/Routing data should be used
        // [GIVEN] Item with BOM/Routing, wizard allows editing but no changes made
        Initialize();

        // Create item with BOM/Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Prod. Definition Display"::Show, "Prod. Definition Display"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // [WHEN] Run the Production Order Creation Wizard without modifications
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        EnqueueWizardNavigation(4);
        Commit();
        PurchLine.CreateSubcontractingProductionOrder();
        LibraryVariableStorage.AssertEmpty();

        // [THEN] Wizard should have finished successfully and original data should be used
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Create expected temporary records from original BOM/Routing
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo);

        // Verify production order and original data
        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardModifyComponents(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
        Quantity: Decimal;
    begin
        // Handle wizard with component modifications
        WizardWasOpened := true;

        Step := Step::Intro;
        // Navigate through all wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            // Check if we're on the components step
            if Step = Step::Components then begin
                Assert.IsTrue(ProductionDefinitionWizard.ComponentsPart.Editable(), 'Components part should be editable');
                // Modify the first component's quantity
                VerifyExpectedInteraction('First');
                ProductionDefinitionWizard.ComponentsPart.First();
                Quantity := LibraryVariableStorage.DequeueDecimal();
                ProductionDefinitionWizard.ComponentsPart."Quantity per".SetValue(Quantity);
            end;
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardChangeComponentSupplyMethod(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
    begin
        WizardWasOpened := true;

        Step := Step::Intro;
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            if Step = Step::Components then begin
                Assert.IsTrue(ProductionDefinitionWizard.ComponentsPart.Editable(), 'Components part should be editable');
                VerifyExpectedInteraction('First');
                ProductionDefinitionWizard.ComponentsPart.First();
                ProductionDefinitionWizard.ComponentsPart.SubcComponentSupplyMethod.SetValue("Component Supply Method"::Empty);
            end;
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardAddComponent(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
        ComponentNo: Code[20];
        Quantity: Decimal;
    begin
        // Handle wizard with component addition
        WizardWasOpened := true;

        Step := Step::Intro;
        // Navigate to components step
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            // Check if we're on the components step
            if Step = Step::Components then begin
                // Add a new component line
                Assert.IsTrue(ProductionDefinitionWizard.ComponentsPart.Editable(), 'Components part should be editable');
                ComponentNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(ComponentNo));
                Quantity := LibraryVariableStorage.DequeueDecimal();
                ProductionDefinitionWizard.ComponentsPart."Item No.".SetValue(ComponentNo);
                ProductionDefinitionWizard.ComponentsPart."Quantity per".SetValue(Quantity);
            end;
        end;

        // Continue to finish
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardDeleteComponent(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
    begin
        // Handle wizard with component deletion
        WizardWasOpened := true;

        Step := Step::Intro;
        // Navigate to components step
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            // Check if we're on the components step
            if Step = Step::Components then begin
                Assert.IsTrue(ProductionDefinitionWizard.ComponentsPart.Editable(), 'Components part should be editable');
                // Delete the first component using Sub Delete action
                VerifyExpectedInteraction('First');
                ProductionDefinitionWizard.ComponentsPart.First();
                VerifyExpectedInteraction('Delete');
                ProductionDefinitionWizard.ComponentsPart."Sub Delete".Invoke();
            end;
        end;

        // Continue to finish
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardAddRoutingOperation(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
        OperationNo: Code[10];
        CapacityType: Enum "Capacity Type";
        WorkCenterNo: Code[20];
        RunTime: Decimal;
    begin
        // Handle wizard with routing operation addition
        WizardWasOpened := true;

        Step := Step::Intro;

        // Navigate to routing step
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            // Check if we're on the routing step
            if Step = Step::ProdRouting then begin
                // Add a new routing operation
                Assert.IsTrue(ProductionDefinitionWizard.ProdOrderRoutingPart.Editable(), 'Routing part should be editable');
                VerifyExpectedInteraction('New');
                ProductionDefinitionWizard.ProdOrderRoutingPart.New();
                OperationNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(OperationNo));
                CapacityType := Enum::"Capacity Type".FromInteger(LibraryVariableStorage.DequeueInteger());
                WorkCenterNo := CopyStr(LibraryVariableStorage.DequeueText(), 1, MaxStrLen(WorkCenterNo));
                RunTime := LibraryVariableStorage.DequeueDecimal();
                ProductionDefinitionWizard.ProdOrderRoutingPart."Operation No.".SetValue(OperationNo);
                ProductionDefinitionWizard.ProdOrderRoutingPart.Type.SetValue(CapacityType);
                ProductionDefinitionWizard.ProdOrderRoutingPart."No.".SetValue(WorkCenterNo);
                ProductionDefinitionWizard.ProdOrderRoutingPart."Run Time".SetValue(RunTime);
            end;
        end;

        // ProdRouting is the last step - ActionFinish commits the pending subpart insert
        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardDeleteRoutingOperation(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
    begin
        // Handle wizard with routing operation deletion
        WizardWasOpened := true;

        Step := Step::Intro;
        // Navigate to routing step
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            // Check if we're on the routing step
            if Step = Step::ProdRouting then begin
                Assert.IsTrue(ProductionDefinitionWizard.ProdOrderRoutingPart.Editable(), 'Routing part should be editable');
                // Delete the first routing operation using Sub Delete action
                VerifyExpectedInteraction('First');
                ProductionDefinitionWizard.ProdOrderRoutingPart.First();
                VerifyExpectedInteraction('Delete');
                ProductionDefinitionWizard.ProdOrderRoutingPart."Subc. TestDelete".Invoke();
            end;
        end;

        // Continue to finish
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardModifyRouting(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
        RunTime: Decimal;
    begin
        // Handle wizard with routing modifications
        WizardWasOpened := true;

        Step := Step::Intro;
        // Navigate through all wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            if Step = Step::ProdRouting then begin
                // Modify the first routing line's run time
                Assert.IsTrue(ProductionDefinitionWizard.ProdOrderRoutingPart.Editable(), 'Routing part should be editable');
                VerifyExpectedInteraction('First');
                ProductionDefinitionWizard.ProdOrderRoutingPart.First();
                RunTime := LibraryVariableStorage.DequeueDecimal();
                ProductionDefinitionWizard.ProdOrderRoutingPart."Run Time".SetValue(RunTime);
            end;
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardModifyBoth(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    var
        Step: Option Intro,BOM,Routing,Components,ProdRouting;
        Quantity: Decimal;
        RunTime: Decimal;
    begin
        // Handle wizard with both component and routing modifications
        WizardWasOpened := true;

        Step := Step::Intro;
        // Navigate through all wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
            Step := Step + 1;
            if Step = Step::Components then begin
                // Modify the first component's quantity
                Assert.IsTrue(ProductionDefinitionWizard.ComponentsPart.Editable(), 'Components part should be editable');
                VerifyExpectedInteraction('First');
                ProductionDefinitionWizard.ComponentsPart.First();
                Quantity := LibraryVariableStorage.DequeueDecimal();
                ProductionDefinitionWizard.ComponentsPart."Quantity per".SetValue(Quantity);
            end else
                if Step = Step::ProdRouting then begin
                    // Modify the first routing line's run time
                    Assert.IsTrue(ProductionDefinitionWizard.ProdOrderRoutingPart.Editable(), 'Routing part should be editable');
                    VerifyExpectedInteraction('First');
                    ProductionDefinitionWizard.ProdOrderRoutingPart.First();
                    RunTime := LibraryVariableStorage.DequeueDecimal();
                    ProductionDefinitionWizard.ProdOrderRoutingPart."Run Time".SetValue(RunTime);
                end;
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandleProductionDefinitionWizardNoChanges(var ProductionDefinitionWizard: TestPage "Production Definition Wizard")
    begin
        // Handle wizard without any changes
        WizardWasOpened := true;

        // Navigate through all wizard steps
        while ProductionDefinitionWizard.ActionNext.Enabled() do begin
            VerifyExpectedInteraction('Next');
            ProductionDefinitionWizard.ActionNext.Invoke();
        end;

        VerifyExpectedInteraction('Finish');
        ProductionDefinitionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. Change Test");
        LibraryVariableStorage.Clear();
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. Change Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. Change Test");
    end;

    local procedure VerifyExpectedInteraction(ExpectedInteraction: Text)
    begin
        Assert.AreEqual(ExpectedInteraction, LibraryVariableStorage.DequeueText(), 'Unexpected wizard interaction');
    end;

    local procedure EnqueueNextActions(NextCount: Integer)
    var
        Index: Integer;
    begin
        for Index := 1 to NextCount do
            LibraryVariableStorage.Enqueue('Next');
    end;

    local procedure EnqueueWizardNavigation(NextCount: Integer)
    begin
        EnqueueNextActions(NextCount);
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueComponentQuantityChange(Quantity: Decimal)
    begin
        EnqueueNextActions(3);
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueComponentSupplyMethodChange()
    begin
        EnqueueNextActions(3);
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueComponentAddition(ComponentNo: Code[20]; Quantity: Decimal)
    begin
        EnqueueNextActions(3);
        LibraryVariableStorage.Enqueue(ComponentNo);
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueComponentDeletion()
    begin
        EnqueueNextActions(3);
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue('Delete');
        LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueRoutingRuntimeChange(RunTime: Decimal)
    begin
        EnqueueNextActions(4);
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue(RunTime);
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueRoutingOperationAddition(WorkCenterNo: Code[20]; RunTime: Decimal)
    begin
        EnqueueNextActions(4);
        LibraryVariableStorage.Enqueue('New');
        LibraryVariableStorage.Enqueue('0030');
        LibraryVariableStorage.Enqueue("Capacity Type"::"Work Center".AsInteger());
        LibraryVariableStorage.Enqueue(WorkCenterNo);
        LibraryVariableStorage.Enqueue(RunTime);
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueRoutingOperationDeletion()
    begin
        EnqueueNextActions(4);
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue('Delete');
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure EnqueueBothChanges(Quantity: Decimal; RunTime: Decimal)
    begin
        EnqueueNextActions(3);
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue(Quantity);
        LibraryVariableStorage.Enqueue('Next');
        LibraryVariableStorage.Enqueue('First');
        LibraryVariableStorage.Enqueue(RunTime);
        LibraryVariableStorage.Enqueue('Finish');
    end;

    local procedure UpdateTempComponentQuantity(var TempProdOrderComponent: Record "Prod. Order Component" temporary; NewQuantity: Decimal)
    begin
        // Update the first component's quantity
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindFirst() then begin
            TempProdOrderComponent."Quantity per" := NewQuantity;
            TempProdOrderComponent.Modify();
        end;
    end;

    local procedure AddTempComponent(var TempProdOrderComponent: Record "Prod. Order Component" temporary; ItemNo: Code[20]; Quantity: Decimal; PurchLine: Record "Purchase Line")
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        LineNo: Integer;
    begin
        // Add a new component to temporary records
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindLast() then
            LineNo := TempProdOrderComponent."Line No." + 10000
        else
            LineNo := 10000;

        TempProdOrderComponent.Init();
        TempProdOrderComponent."Line No." := LineNo;
        TempProdOrderComponent."Item No." := ItemNo;
        TempProdOrderComponent."Quantity per" := Quantity;
        TempProdOrderComponent."Location Code" := PurchLine."Location Code";
        TempProdOrderComponent."Flushing Method" := "Flushing Method"::"Pick + Manual";

        ManufacturingSetup.SetLoadFields();
        ManufacturingSetup.Get();
        TempProdOrderComponent."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
        TempProdOrderComponent.Insert();
    end;

    local procedure UpdateTempRoutingRunTime(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; NewRunTime: Decimal)
    begin
        // Update the first routing line's run time
        TempProdOrderRoutingLine.Reset();
        if TempProdOrderRoutingLine.FindFirst() then begin
            TempProdOrderRoutingLine."Run Time" := NewRunTime;
            TempProdOrderRoutingLine.Modify();
        end;
    end;

    local procedure RemoveTempComponent(var TempProdOrderComponent: Record "Prod. Order Component" temporary)
    begin
        // Remove the first component from temporary records
        TempProdOrderComponent.Reset();
        if TempProdOrderComponent.FindFirst() then
            TempProdOrderComponent.Delete();
    end;

    local procedure AddTempRoutingOperation(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary; OperationNo: Code[10]; RunTime: Decimal)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
    begin
        // Add a new routing operation to temporary records
        TempProdOrderRoutingLine.Reset();

        ManufacturingSetup.SetLoadFields("Subc. Rtng. Link Purch Prov");
        ManufacturingSetup.Get();

        TempProdOrderRoutingLine.Init();
        TempProdOrderRoutingLine."Operation No." := OperationNo;
        TempProdOrderRoutingLine.Type := TempProdOrderRoutingLine.Type::"Work Center";
        TempProdOrderRoutingLine."No." := NewWorkCenterNo;
        TempProdOrderRoutingLine."Work Center No." := NewWorkCenterNo;
        TempProdOrderRoutingLine."Routing Link Code" := ManufacturingSetup."Subc. Rtng. Link Purch Prov";
        TempProdOrderRoutingLine."Run Time" := RunTime;
        TempProdOrderRoutingLine.Insert();
    end;

    local procedure RemoveTempRoutingOperation(var TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary)
    begin
        // Remove the first routing operation from temporary records
        TempProdOrderRoutingLine.Reset();
        if TempProdOrderRoutingLine.FindFirst() then
            TempProdOrderRoutingLine.Delete();
    end;

    local procedure CreateTestItem(): Code[20]
    var
        Item: Record Item;
        LibraryInventory: Codeunit "Library - Inventory";
    begin
        LibraryInventory.CreateItem(Item);
        exit(Item."No.");
    end;

    local procedure CreateWorkCenterNo(): Code[20]
    var
        WorkCenter: Record "Work Center";
    begin
        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 1);
        exit(WorkCenter."No.");
    end;
}