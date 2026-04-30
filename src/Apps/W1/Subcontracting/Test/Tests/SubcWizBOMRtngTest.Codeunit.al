// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Purchases.Document;

codeunit 139995 "Subc. Wiz. BOM/Rtng Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Subcontracting Management - Production Order Creation Wizard BOM/Routing Selection Tests
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
        BOMNoToSelect, RoutingNoToSelect : Code[20];

    // ==================== SCENARIO J: BOM/Routing Selection (not just versions) ====================

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardSelectDifferentBOM,SelectBOM')]
    procedure TestJ1_SelectDifferentBOM_LinesExchanged()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo1, BOMNo2 : Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO J1] Different BOM selected - BOM lines are exchanged
        // [GIVEN] Item with BOM and Routing, alternate BOM exists
        Initialize();

        // Create two different BOMs with different components
        BOMNo1 := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        BOMNo2 := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines(); // This will have different component items
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo1, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set the BOM to select in the handler
        BOMNoToSelect := BOMNo2;

        // [WHEN] Run the Production Order Creation Wizard and select different BOM
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and used the selected BOM
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with the selected BOM components
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary components from the selected BOM
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo2, PurchLine);

        // Verify that the components match the selected BOM
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardSelectDifferentRouting,SelectRouting')]
    procedure TestJ2_SelectDifferentRouting_LinesExchanged()
    var
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo1, RoutingNo2 : Code[20];
    begin
        // [SCENARIO J2] Different Routing selected - Routing lines are exchanged
        // [GIVEN] Item with BOM and Routing, alternate Routing exists
        Initialize();

        // Create two different Routings with different operations
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo1 := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        RoutingNo2 := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines(); // This will have different work centers
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo1);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set the Routing to select in the handler
        RoutingNoToSelect := RoutingNo2;

        // [WHEN] Run the Production Order Creation Wizard and select different Routing
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and used the selected Routing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with the selected Routing lines
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary routing lines from the selected Routing
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo2);

        // Verify that the routing lines match the selected Routing
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardSelectBothDifferent,SelectBOM,SelectRouting')]
    procedure TestJ3_SelectDifferentBOMAndRouting_BothLinesExchanged()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        TempProdOrderRoutingLine: Record "Prod. Order Routing Line" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo1, BOMNo2 : Code[20];
        ItemNo: Code[20];
        RoutingNo1, RoutingNo2 : Code[20];
    begin
        // [SCENARIO J3] Different BOM and Routing selected - Both component and routing lines are exchanged
        // [GIVEN] Item with BOM and Routing, alternate BOM and Routing exist
        Initialize();

        // Create two different BOMs and Routings
        BOMNo1 := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        BOMNo2 := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo1 := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        RoutingNo2 := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo1, RoutingNo1);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set the BOM and Routing to select in the handlers
        BOMNoToSelect := BOMNo2;
        RoutingNoToSelect := RoutingNo2;

        // [WHEN] Run the Production Order Creation Wizard and select different BOM and Routing
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully and used both selected BOM and Routing
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary components from the selected BOM
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo2, PurchLine);
        // Create expected temporary routing lines from the selected Routing
        ProdOrderCheckLib.CreateTempProdOrderRoutingFromRouting(TempProdOrderRoutingLine, RoutingNo2);

        // Verify that both components and routing lines match the selected BOM and Routing
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
        ProdOrderCheckLib.VerifyProdOrderRoutingLinesMatchTempRecords(ProdOrder, TempProdOrderRoutingLine);
    end;

    [Test]
    [HandlerFunctions('HandlePurchProvisionWizardSelectSameBOM,SelectBOM')]
    procedure TestJ4_SelectSameBOM_NoChanges()
    var
        TempProdOrderComponent: Record "Prod. Order Component" temporary;
        ProdOrder: Record "Production Order";
        PurchLine: Record "Purchase Line";
        CreateProdOrdOpt: Codeunit "Subc. Create Prod. Ord. Opt.";
        BOMNo: Code[20];
        ItemNo: Code[20];
        RoutingNo: Code[20];
    begin
        // [SCENARIO J4] Same BOM selected - No changes should occur
        // [GIVEN] Item with BOM and Routing
        Initialize();

        // Create BOM and Routing
        BOMNo := SubCreateProdOrdWizLibrary.CreateBOMWithTwoLines();
        RoutingNo := SubCreateProdOrdWizLibrary.CreateRoutingWithTwoLines();
        ItemNo := SubCreateProdOrdWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);

        // Configure setup to edit both
        SubSetupLibrary.ConfigureSubManagementForBothPresentScenario("Subc. Show/Edit Type"::Edit, "Subc. Show/Edit Type"::Edit);

        // Create purchase line
        SubCreateProdOrdWizLibrary.CreatePurchaseLineWithSubcontractingVendor(PurchLine, ItemNo);

        // Set the same BOM to select in the handler
        BOMNoToSelect := BOMNo;

        // [WHEN] Run the Production Order Creation Wizard and select the same BOM
        WizardWasOpened := false;
        WizardFinishedSuccessfully := false;
        Commit();
        CreateProdOrdOpt.Run(PurchLine);

        // [THEN] Wizard should have finished successfully with original BOM
        Assert.IsTrue(WizardWasOpened, 'Wizard should have opened');
        Assert.IsTrue(WizardFinishedSuccessfully, 'Wizard should have finished successfully');

        // Verify production order was created with original BOM components
        PurchLine.Get(PurchLine."Document Type", PurchLine."Document No.", PurchLine."Line No.");
        Assert.AreNotEqual('', PurchLine."Prod. Order No.", 'Production Order should have been created');

        ProdOrderCheckLib.VerifyProdOrder(PurchLine, ProdOrder);

        // Create expected temporary components from the original BOM
        ProdOrderCheckLib.SetRefreshedProdOrder(true);
        ProdOrderCheckLib.CreateTempProdOrderComponentFromBOM(TempProdOrderComponent, BOMNo, PurchLine);

        // Verify that the components match the original BOM
        ProdOrderCheckLib.VerifyProdOrderComponentsMatchTempRecords(ProdOrder, TempProdOrderComponent);
    end;

    // ==================== MODAL PAGE HANDLERS ====================

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardSelectDifferentBOM(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        NewItemNo: Text;
        OriginalItemNo: Text;
    begin
        // [SCENARIO J1] Handle wizard to select different BOM and verify lines are updated
        WizardWasOpened := true;

        // Navigate to BOM step
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        // Get the current BOM lines before changing BOM
        if PurchProvisionWizard.BOMLinesPart.First() then
            OriginalItemNo := PurchProvisionWizard.BOMLinesPart."No.".Value();

        // Select the different BOM
        PurchProvisionWizard."Production BOM No.".AssistEdit();

        // Verify that the BOM lines have been updated after BOM change
        if PurchProvisionWizard.BOMLinesPart.First() then begin
            NewItemNo := PurchProvisionWizard.BOMLinesPart."No.".Value();
            // The lines should be different between BOMs (different component items)
            Assert.AreNotEqual(OriginalItemNo, NewItemNo, 'BOM lines should be updated when BOM is changed');
        end;

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardSelectDifferentRouting(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        NewWorkCenterNo: Text;
        OriginalWorkCenterNo: Text;
    begin
        // [SCENARIO J2] Handle wizard to select different Routing and verify lines are updated
        WizardWasOpened := true;

        // Navigate to BOM step
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        // Navigate to Routing step
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        // Get the current Routing lines before changing Routing
        if PurchProvisionWizard.RoutingLinesPart.First() then
            OriginalWorkCenterNo := PurchProvisionWizard.RoutingLinesPart."No.".Value();

        // Select the different Routing
        PurchProvisionWizard."Routing No.".AssistEdit();

        // Verify that the Routing lines have been updated after Routing change
        if PurchProvisionWizard.RoutingLinesPart.First() then begin
            NewWorkCenterNo := PurchProvisionWizard.RoutingLinesPart."No.".Value();
            // The lines should be different between Routings (different work centers)
            Assert.AreNotEqual(OriginalWorkCenterNo, NewWorkCenterNo, 'Routing lines should be updated when Routing is changed');
        end;

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardSelectBothDifferent(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        NewItemNo, OriginalItemNo : Text;
        NewWorkCenterNo, OriginalWorkCenterNo : Text;
    begin
        // [SCENARIO J3] Handle wizard to select different BOM and Routing
        WizardWasOpened := true;

        // Navigate to BOM step
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        // Get the current BOM lines before changing BOM
        if PurchProvisionWizard.BOMLinesPart.First() then
            OriginalItemNo := PurchProvisionWizard.BOMLinesPart."No.".Value();

        // Select the different BOM
        PurchProvisionWizard."Production BOM No.".AssistEdit();

        // Verify that the BOM lines have been updated
        if PurchProvisionWizard.BOMLinesPart.First() then begin
            NewItemNo := PurchProvisionWizard.BOMLinesPart."No.".Value();
            Assert.AreNotEqual(OriginalItemNo, NewItemNo, 'BOM lines should be updated when BOM is changed');
        end;

        // Navigate to Routing step
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        // Get the current Routing lines before changing Routing
        if PurchProvisionWizard.RoutingLinesPart.First() then
            OriginalWorkCenterNo := PurchProvisionWizard.RoutingLinesPart."No.".Value();

        // Select the different Routing
        PurchProvisionWizard."Routing No.".AssistEdit();

        // Verify that the Routing lines have been updated
        if PurchProvisionWizard.RoutingLinesPart.First() then begin
            NewWorkCenterNo := PurchProvisionWizard.RoutingLinesPart."No.".Value();
            Assert.AreNotEqual(OriginalWorkCenterNo, NewWorkCenterNo, 'Routing lines should be updated when Routing is changed');
        end;

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure HandlePurchProvisionWizardSelectSameBOM(var PurchProvisionWizard: TestPage "Subc. PurchProvisionWizard")
    var
        NewItemNo: Text;
        OriginalItemNo: Text;
    begin
        // [SCENARIO J4] Handle wizard to select same BOM (no changes expected)
        WizardWasOpened := true;

        // Navigate to BOM step
        if PurchProvisionWizard.ActionNext.Enabled() then
            PurchProvisionWizard.ActionNext.Invoke();

        // Get the current BOM lines before "changing" BOM
        if PurchProvisionWizard.BOMLinesPart.First() then
            OriginalItemNo := PurchProvisionWizard.BOMLinesPart."No.".Value();

        // Select the same BOM (this should not change anything)
        PurchProvisionWizard."Production BOM No.".AssistEdit();

        // Verify that the BOM lines remain the same
        if PurchProvisionWizard.BOMLinesPart.First() then begin
            NewItemNo := PurchProvisionWizard.BOMLinesPart."No.".Value();
            Assert.AreEqual(OriginalItemNo, NewItemNo, 'BOM lines should remain the same when same BOM is selected');
        end;

        // Navigate through remaining wizard steps
        while PurchProvisionWizard.ActionNext.Enabled() do
            PurchProvisionWizard.ActionNext.Invoke();

        PurchProvisionWizard.ActionFinish.Invoke();
        WizardFinishedSuccessfully := true;
    end;

    [ModalPageHandler]
    procedure SelectBOM(var ProductionBOMList: TestPage "Production BOM List")
    var
        ProductionBOMHeader: Record "Production BOM Header";
    begin
        ProductionBOMList.First();
        ProductionBOMHeader.Get(BOMNoToSelect);
        ProductionBOMList.GoToRecord(ProductionBOMHeader);
        ProductionBOMList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure SelectRouting(var RoutingList: TestPage "Routing List")
    var
        RoutingHeader: Record "Routing Header";
    begin
        RoutingList.First();
        RoutingHeader.Get(RoutingNoToSelect);
        RoutingList.GoToRecord(RoutingHeader);
        RoutingList.OK().Invoke();
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Wiz. BOM/Rtng Test");
        LibrarySetupStorage.Restore();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Wiz. BOM/Rtng Test");

        SubcontractingMgmtLibrary.Initialize();
        LibraryMfgManagement.Initialize();
        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Wiz. BOM/Rtng Test");
    end;
}