// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137426 "Prod. Def. Wiz. BOM Rtng Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - BOM & Routing Step Behavior
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
        ActualBOMLineItemNos: List of [Code[20]];
        ActualRoutingLineWCNos: List of [Code[20]];
        ActualComponentItemNos: List of [Code[20]];
        ActualProdRoutingWCNos: List of [Code[20]];
        ActualSelectedBOMVersion: Text;
        ActualSelectedRoutingVersion: Text;
        TargetBOMNoForLookup: Code[20];
        TargetRoutingNoForLookup: Code[20];


    [Test]
    [HandlerFunctions('HandleWizardCaptureBOMLineNos')]
    procedure TestD1_BOMLoadedFromItemBOM_TwoLines()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ProductionBOMLine: Record "Production BOM Line";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        ActualItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D1] BOM lines loaded from Item's Production BOM on open
        Initialize();

        // [GIVEN] Item has certified BOM with 2 lines
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard opens, user navigates to Step 2
        Clear(ActualBOMLineItemNos);
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] BOMLinesPart displays exactly 2 lines, each a component of the BOM
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ActualBOMLineItemNos.Remove('');
        Assert.AreEqual(ProductionBOMLine.Count(), ActualBOMLineItemNos.Count(), 'BOMLinesPart should display exactly 2 lines from the certified BOM');
        foreach ActualItemNo in ActualBOMLineItemNos do begin
            ProductionBOMLine.SetRange("No.", ActualItemNo);
            Assert.IsTrue(ProductionBOMLine.FindFirst(), StrSubstNo('BOM component %1 should belong to BOM %2', ActualItemNo, BOMNo));
        end;

        // [THEN] Each BOM line has Quantity per > 0 (lines created with Qty = line index 1, 2, ...)
        ProductionBOMLine.Reset();
        ProductionBOMLine.SetRange("Production BOM No.", BOMNo);
        ProductionBOMLine.SetRange("Version Code", '');
        if ProductionBOMLine.FindSet() then
            repeat
                Assert.IsTrue(ProductionBOMLine."Quantity per" > 0,
                    StrSubstNo('BOM line for component %1 should have Quantity per > 0', ProductionBOMLine."No."));
            until ProductionBOMLine.Next() = 0;
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureRoutingLineNos')]
    procedure TestD2_RoutingLoadedFromItemRouting_TwoLines()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        RoutingLine: Record "Routing Line";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        ActualWCNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D2] Routing lines loaded from Item's Routing on open
        Initialize();

        // [GIVEN] Item has certified Routing with 2 operation lines
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard opens, user navigates to Step 3
        Clear(ActualRoutingLineWCNos);
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] RoutingLinesPart displays exactly 2 lines, each a work center of the Routing
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        RoutingLine.SetRange("Routing No.", RoutingNo);
        ActualRoutingLineWCNos.Remove('');
        Assert.AreEqual(RoutingLine.Count(), ActualRoutingLineWCNos.Count(), 'RoutingLinesPart should display exactly 2 lines from the certified Routing');
        foreach ActualWCNo in ActualRoutingLineWCNos do begin
            RoutingLine.SetRange("No.", ActualWCNo);
            Assert.IsTrue(RoutingLine.FindFirst(), StrSubstNo('Routing work center %1 should belong to Routing %2', ActualWCNo, RoutingNo));
        end;

        // [THEN] Routing lines carry the expected Setup Time and Run Time values
        //        Line '10': Setup=10, Run=5; Line '20': Setup=15, Run=8 (per CreateRoutingWithTwoLines)
        RoutingLine.Reset();
        RoutingLine.SetRange("Routing No.", RoutingNo);
        RoutingLine.SetRange("Version Code", '');
        RoutingLine.SetRange("Operation No.", '10');
        Assert.IsTrue(RoutingLine.FindFirst(), 'Routing line operation 10 must exist');
        Assert.AreEqual(10, RoutingLine."Setup Time", 'Routing line 10 Setup Time should be 10');
        Assert.AreEqual(5, RoutingLine."Run Time", 'Routing line 10 Run Time should be 5');
        RoutingLine.SetRange("Operation No.", '20');
        Assert.IsTrue(RoutingLine.FindFirst(), 'Routing line operation 20 must exist');
        Assert.AreEqual(15, RoutingLine."Setup Time", 'Routing line 20 Setup Time should be 15');
        Assert.AreEqual(8, RoutingLine."Run Time", 'Routing line 20 Run Time should be 8');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSelectedBOMVersion')]
    procedure TestD3_ActiveBOMVersionSelectedByDefault()
    var
        Item: Record Item;
        ProductionBOMVersion: Record "Production BOM Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D3] BOM version is selected as default active version
        Initialize();

        // [GIVEN] Item's Production BOM has two certified versions; V2 is active as of WorkDate
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        ProdDefWizLibrary.CreateBOMVersionAndCertify(BOMNo, 'V1', CalcDate('<-1Y>', WorkDate()));
        ProdDefWizLibrary.CreateBOMVersionAndCertify(BOMNo, 'V2', WorkDate());
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard opens and navigates to Step 2
        ActualSelectedBOMVersion := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SelectedBOMVersion shows V2 (most recent active version)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('V2', ActualSelectedBOMVersion, 'SelectedBOMVersion should be V2 (active version as of WorkDate)');

        // [THEN] BOM version V2 is certified and has the correct Starting Date
        ProductionBOMVersion.Get(BOMNo, 'V2');
        Assert.AreEqual(ProductionBOMVersion.Status::Certified, ProductionBOMVersion.Status,
            'BOM version V2 should be Certified');
        Assert.AreEqual(WorkDate(), ProductionBOMVersion."Starting Date",
            'BOM version V2 Starting Date should equal WorkDate()');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSelectedRoutingVersion')]
    procedure TestD4_ActiveRoutingVersionSelectedByDefault()
    var
        Item: Record Item;
        RoutingVersion: Record "Routing Version";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D4] Routing version is selected as default active version
        Initialize();

        // [GIVEN] Item's Routing has two certified versions; V2 is active as of WorkDate
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ProdDefWizLibrary.CreateRoutingVersionAndCertify(RoutingNo, 'V1', CalcDate('<-1Y>', WorkDate()));
        ProdDefWizLibrary.CreateRoutingVersionAndCertify(RoutingNo, 'V2', WorkDate());
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard opens and navigates to Step 3
        ActualSelectedRoutingVersion := '';
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] SelectedRoutingVersion shows V2 (most recent active version as of WorkDate)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('V2', ActualSelectedRoutingVersion, 'SelectedRoutingVersion should be V2 (active version as of WorkDate)');
        // [THEN] Routing version V2 is certified and has the correct Starting Date
        RoutingVersion.Get(RoutingNo, 'V2');
        Assert.AreEqual(RoutingVersion.Status::Certified, RoutingVersion.Status,
            'Routing version V2 should be Certified');
        Assert.AreEqual(WorkDate(), RoutingVersion."Starting Date",
            'Routing version V2 Starting Date should equal WorkDate()');
    end;

    [Test]
    [HandlerFunctions('HandleWizardBOMAssistEditAndCaptureLines,HandleProductionBOMListSelect')]
    procedure TestD5_AssistEditBOMNo_ReloadsBOMLines()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        ProductionBOMLine: Record "Production BOM Line";
        BOMBNo: Code[20];
        OriginalBOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        ActualItemNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D5] AssistEdit on BOM No. selects a different BOM → BOM lines reload from the new BOM
        Initialize();

        // [GIVEN] Item has BOM-B (3 lines); display = Edit
        BOMBNo := ProdDefWizLibrary.CreateBOM(3); // BOM-B to switch to
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        OriginalBOMNo := ProdDefWizLibrary.CreateBOM(2);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(OriginalBOMNo, RoutingNo);
        Item.Get(ItemNo);
        TargetBOMNoForLookup := BOMBNo;
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User uses AssistEdit on BOM No. to select BOM-B
        Clear(ActualBOMLineItemNos);
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] BOMLinesPart now shows 3 lines from BOM-B, each a component of BOM-B
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProductionBOMLine.SetRange("Production BOM No.", BOMBNo);
        ActualBOMLineItemNos.Remove('');
        Assert.AreEqual(ProductionBOMLine.Count(), ActualBOMLineItemNos.Count(), 'BOMLinesPart should display 3 lines from the newly selected BOM-B');
        foreach ActualItemNo in ActualBOMLineItemNos do begin
            ProductionBOMLine.SetRange("No.", ActualItemNo);
            Assert.IsTrue(ProductionBOMLine.FindFirst(), StrSubstNo('BOM component %1 should belong to BOM-B %2', ActualItemNo, BOMBNo));
        end;

        // [THEN] Item BOM No. is changed to TargetBOMNoForLookup in the database (Save=true → new BOM retained)
        Item.Get(ItemNo);
        Assert.AreEqual(TargetBOMNoForLookup, Item."Production BOM No.",
            'Item Production BOM No. should be updated to the new BOM after wizard when Save=true');
    end;

    [Test]
    [HandlerFunctions('HandleWizardRoutingAssistEditAndCaptureLines,HandleRoutingListSelect')]
    procedure TestD6_AssistEditRoutingNo_ReloadsRoutingLines()
    var
        Item: Record Item;
        ProdDefManager: Codeunit "Production Definition Manager";
        RoutingLine: Record "Routing Line";
        BOMNo: Code[20];
        RoutingBNo: Code[20];
        OriginalRoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        WC3No: Code[20];
        ActualWCNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D6] AssistEdit on Routing No. selects a different Routing → Routing lines reload
        Initialize();

        // [GIVEN] Item has Routing-A (1 line); Routing-B (2 lines) also exists; display = Edit
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingBNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No); // Routing-B to switch to
        OriginalRoutingNo := ProdDefWizLibrary.CreateRoutingWithSingleLine(WC3No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, OriginalRoutingNo);
        Item.Get(ItemNo);
        TargetRoutingNoForLookup := RoutingBNo;
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] User uses AssistEdit on Routing No. to select Routing-B
        Clear(ActualRoutingLineWCNos);
        Commit();
        ProdDefManager.RunForSource(Item, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] RoutingLinesPart now shows 2 lines from Routing-B, each a work center of Routing-B
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        RoutingLine.SetRange("Routing No.", RoutingBNo);
        ActualRoutingLineWCNos.Remove('');
        Assert.AreEqual(RoutingLine.Count(), ActualRoutingLineWCNos.Count(), 'RoutingLinesPart should display 2 lines from the newly selected Routing-B');
        foreach ActualWCNo in ActualRoutingLineWCNos do begin
            RoutingLine.SetRange("No.", ActualWCNo);
            Assert.IsTrue(RoutingLine.FindFirst(), StrSubstNo('Routing work center %1 should belong to Routing-B %2', ActualWCNo, RoutingBNo));
        end;

        // [THEN] Item Routing No. is updated in the database (Save=true → new Routing retained)
        Item.Get(ItemNo);
        Assert.AreEqual(TargetRoutingNoForLookup, Item."Routing No.",
            'Item Routing No. should be updated to the new Routing after wizard when Save=true');
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureCompAndRoutingNos')]
    procedure TestD7_ComponentsAndRoutingPreview_CorrectFromBOMAndRouting()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        ProdOrderComponent: Record "Prod. Order Component";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        LocationCode: Code[10];
        ActualItemNo: Code[20];
        ActualNo: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D7] Components Preview (Step 4) and Routing Preview (Step 5) show correct lines
        Initialize();

        // [GIVEN] Sales Line for item with BOM (2 components) and Routing (2 operations); ProdComponentDisplay = Show
        BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);

        // [WHEN] User navigates to Steps 4 and 5 and finishes (creates a Production Order)
        Clear(ActualComponentItemNos);
        Clear(ActualProdRoutingWCNos);
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] ComponentsPart shows items matching the created Prod. Order components;
        //        ProdOrderRoutingPart shows work centers matching the created Prod. Order routing lines
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdOrderComponent.SetRange(Status, ProdOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualComponentItemNos.Remove('');
        Assert.AreEqual(ProdOrderComponent.Count(), ActualComponentItemNos.Count(), 'ComponentsPart should list 2 lines matching the Prod. Order components');
        foreach ActualItemNo in ActualComponentItemNos do begin
            ProdOrderComponent.SetRange("Item No.", ActualItemNo);
            Assert.IsTrue(ProdOrderComponent.FindFirst(), StrSubstNo('Component item %1 should exist in the created Prod. Order', ActualItemNo));
        end;
        ProdOrderRoutingLine.SetRange(Status, ProdOrder.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProdOrder."No.");
        ActualProdRoutingWCNos.Remove('');
        Assert.AreEqual(ProdOrderRoutingLine.Count(), ActualProdRoutingWCNos.Count(), 'ProdOrderRoutingPart should list 2 lines matching the Prod. Order routing lines');
        foreach ActualNo in ActualProdRoutingWCNos do begin
            ProdOrderRoutingLine.SetRange("No.", ActualNo);
            Assert.IsTrue(ProdOrderRoutingLine.FindFirst(), StrSubstNo('Work center %1 should exist in the created Prod. Order routing', ActualNo));
        end;

        // [THEN] Prod. Order fields: Qty = 5 (from SalesLine), Due Date = WorkDate() +1, Location matches SalesLine
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 5, WorkDate(), LocationCode, '');
        // [THEN] First component has Quantity per = 1 (BOM created with Qty = line index starting at 1)
        ProdDefWizCheckLib.VerifyProdOrderComponentHasQtyPerForFirstComponent(ProdOrder, 1);
    end;


    [ModalPageHandler]
    procedure HandleWizardCaptureBOMLineNos(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM step)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Collect BOM line component item Nos
        Clear(ActualBOMLineItemNos);
        if Wizard.BOMLinesPart.First() then
            repeat
                ActualBOMLineItemNos.Add(CopyStr(Wizard.BOMLinesPart."No.".Value(), 1, 20));
            until not Wizard.BOMLinesPart.Next();
        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureRoutingLineNos(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Collect Routing line work center Nos
        Clear(ActualRoutingLineWCNos);
        if Wizard.RoutingLinesPart.First() then
            repeat
                ActualRoutingLineWCNos.Add(CopyStr(Wizard.RoutingLinesPart."No.".Value(), 1, 20));
            until not Wizard.RoutingLinesPart.Next();
        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureSelectedBOMVersion(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM step)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Capture selected BOM version
        ActualSelectedBOMVersion := Wizard.SelectedBOMVersionField.Value();
        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardCaptureSelectedRoutingVersion(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Capture selected Routing version
        ActualSelectedRoutingVersion := Wizard.SelectedRoutingVersionField.Value();
        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleWizardBOMAssistEditAndCaptureLines(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM step)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Trigger AssistEdit on BOM No. field → opens Production BOM List (handled by HandleProductionBOMListSelect)
        Wizard.ProductionBOMNoField.AssistEdit();
        // Collect BOM line item Nos after the new BOM was selected
        Clear(ActualBOMLineItemNos);
        if Wizard.BOMLinesPart.First() then
            repeat
                ActualBOMLineItemNos.Add(CopyStr(Wizard.BOMLinesPart."No.".Value(), 1, 20));
            until not Wizard.BOMLinesPart.Next();
        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleProductionBOMListSelect(var ProductionBOMList: TestPage "Production BOM List")
    begin
        ProductionBOMList.Filter.SetFilter("No.", TargetBOMNoForLookup);
        ProductionBOMList.First();
        ProductionBOMList.OK.Invoke();
    end;

    [ModalPageHandler]
    procedure HandleWizardRoutingAssistEditAndCaptureLines(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate to Step 2 (BOM)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Navigate to Step 3 (Routing step)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();
        // Trigger AssistEdit on Routing No. field → opens Routing List (handled by HandleRoutingListSelect)
        Wizard.RoutingNoField.AssistEdit();
        // Collect Routing line work center Nos after the new Routing was selected
        Clear(ActualRoutingLineWCNos);
        if Wizard.RoutingLinesPart.First() then
            repeat
                ActualRoutingLineWCNos.Add(CopyStr(Wizard.RoutingLinesPart."No.".Value(), 1, 20));
            until not Wizard.RoutingLinesPart.Next();
        // Continue to finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;

    [ModalPageHandler]
    procedure HandleRoutingListSelect(var RoutingList: TestPage "Routing List")
    begin
        RoutingList.Filter.SetFilter("No.", TargetRoutingNoForLookup);
        RoutingList.First();
        RoutingList.OK.Invoke();
    end;


    [ModalPageHandler]
    procedure HandleWizardCaptureCompAndRoutingNos(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Navigate through BOM and Routing steps
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke(); // Step 2 BOM
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke(); // Step 3 Routing
        // Step 4: Components — collect component item Nos
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            Clear(ActualComponentItemNos);
            if Wizard.ComponentsPart.First() then
                repeat
                    ActualComponentItemNos.Add(CopyStr(Wizard.ComponentsPart."Item No.".Value(), 1, 20));
                until not Wizard.ComponentsPart.Next();
        end;
        // Step 5: Prod. Routing — collect work center Nos
        if Wizard.ActionNext.Enabled() then begin
            Wizard.ActionNext.Invoke();
            Clear(ActualProdRoutingWCNos);
            if Wizard.ProdOrderRoutingPart.First() then
                repeat
                    ActualProdRoutingWCNos.Add(CopyStr(Wizard.ProdOrderRoutingPart."No.".Value(), 1, 20));
                until not Wizard.ProdOrderRoutingPart.Next();
        end;
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;


    [Test]
    [HandlerFunctions('HandleWizardCaptureCompAndRoutingNos')]
    procedure TestD8_BOMLineFields_TransferredToProdOrderComponent()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        ComponentItemNo: Code[20];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D8] BOM line fields (Length, Width, Weight, Depth, Scrap %, Calculation Formula) are transferred to Prod. Order Component on Production Order creation
        Initialize();

        // [GIVEN] BOM with one component line having dimensional fields, Scrap % = 5 and Calculation Formula = Fixed Quantity
        BOMNo := ProdDefWizLibrary.CreateBOMWithDimensionalFields(ComponentItemNo);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithSingleLine(WC1No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 1, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);

        // [WHEN] Wizard creates a Production Order from the Sales Line
        Clear(ActualComponentItemNos);
        Clear(ActualProdRoutingWCNos);
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Prod. Order Component has Scrap % = 5, Length = 2, Width = 3, Weight = 4, Depth = 1 from BOM line
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderComponentBOMFields(ProdOrder, ComponentItemNo, 5, 2, 3, 4, 1);
        // [THEN] Prod. Order Component has Calculation Formula = Fixed Quantity from BOM line
        ProdDefWizCheckLib.VerifyProdOrderComponentCalcFormula(ProdOrder, ComponentItemNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureCompAndRoutingNos')]
    procedure TestD9_RoutingLineFields_TransferredToProdOrderRoutingLine()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        WC1No: Code[20];
        WC2No: Code[20];
        CapUOMCode: Code[10];
        LocationCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO D9] Routing line fields (UOM codes, Fixed Scrap Qty, Scrap Factor %, Send-Ahead Qty, Concurrent Capacities, Lot Size, Prev/Next Operation No.) are transferred to Prod. Order Routing Line on Production Order creation
        Initialize();

        // [GIVEN] Routing with two lines where operation '10' has all extended capacity and scrap fields set; after certification Prev/Next Op No. are auto-populated
        BOMNo := ProdDefWizLibrary.CreateBOM(1);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLinesAndExtendedFields(WC1No, WC2No, CapUOMCode);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 1, LocationCode, '', WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Show, "Prod. Definition Display"::Show);

        // [WHEN] Wizard creates a Production Order from the Sales Line
        Clear(ActualComponentItemNos);
        Clear(ActualProdRoutingWCNos);
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Prod. Order Routing Line '10' has all extended fields transferred from Routing Line
        //        Previous Op No. = '' (first in serial routing), Next Op No. = '20' (auto-populated on certification)
        //        All time UOM codes match the created Capacity UOM; Fixed Scrap Qty = 3, Scrap Factor % = 10,
        //        Send-Ahead Qty = 5, Concurrent Capacities = 2, Lot Size = 1
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderRoutingLineExtendedFields(
            ProdOrder, '10', '', '20', CapUOMCode, CapUOMCode, CapUOMCode, CapUOMCode, 3, 10, 5, 2, 1);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. BOM Rtng Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. BOM Rtng Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. BOM Rtng Test");
    end;
}