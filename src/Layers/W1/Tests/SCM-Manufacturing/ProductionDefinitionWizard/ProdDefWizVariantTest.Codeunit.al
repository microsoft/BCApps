// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Wizard;
using Microsoft.Sales.Document;

codeunit 137430 "Prod. Def. Wiz. Variant Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        // [FEATURE] Production Definition Wizard - Variant Handling
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
        ActualSourceText: Text;
        ActualBOMLineItemNos: List of [Code[20]];


    [Test]
    procedure TestI1_SalesLineWithVariant_ProdOrderHasVariantAndQuantity()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        ItemNo: Code[20];
        VariantCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO I1] Sales Line with variant code; wizard finishes → Production Order has matching variant and quantity
        Initialize();

        // [GIVEN] Item with variant; Sales Line for that item/variant with quantity 5; wizard UI skipped (Nothing + Hide)
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting('', '');
        VariantCode := ProdDefWizLibrary.CreateVariantForItem(ItemNo);
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, '', VariantCode, WorkDate());
        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Hide, "Prod. Definition Display"::Hide);

        // [WHEN] Wizard runs from Sales Line (UI skipped — no modal handler needed)
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Production Order exists with Variant Code and Quantity = 5
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderFields(ProdOrder, ItemNo, 5, WorkDate(), '', VariantCode);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSourceAndBOMLines')]
    procedure TestI2_SKUWithVariant_WizardInitializesFromCorrectSKU()
    var
        SKU: Record "Stockkeeping Unit";
        ProductionBOMLine: Record "Production BOM Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        ActualBOMLineItemNo: Code[20];
        ItemBOMNo: Code[20];
        SKUBOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO I2] SKU with variant: wizard initializes from correct SKU (matching variant)
        Initialize();

        // [GIVEN] Item has SKU for location "EAST" + variant "BLUE" with BOM-B; Item itself has BOM-A
        ItemBOMNo := ProdDefWizLibrary.CreateBOM(2);
        SKUBOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(ItemBOMNo, RoutingNo);
        VariantCode := ProdDefWizLibrary.CreateVariantForItem(ItemNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU, ItemNo, LocationCode, VariantCode, SKUBOMNo, RoutingNo);
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard is initialized from that SKU (with variant)
        ActualSourceText := '';
        Commit();
        ProdDefManager.RunForSource(SKU, "Prod. Definition Mode"::DefineItemStructure);

        // [THEN] Source = StockkeepingUnit; BOM lines match BOM-B (not BOM-A from Item)
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('Stockkeeping Unit', ActualSourceText, 'Source should be Stockkeeping Unit (matched by variant)');
        // Verify wizard displayed lines from SKU BOM-B, not Item BOM-A
        ProductionBOMLine.SetRange("Production BOM No.", SKUBOMNo);
        ActualBOMLineItemNos.Remove('');
        Assert.IsTrue(ActualBOMLineItemNos.Count() > 0, 'Wizard should have shown BOM lines from SKU BOM-B');
        Assert.AreEqual(ProductionBOMLine.Count(), ActualBOMLineItemNos.Count(),
            'Wizard BOM line count should match SKU BOM-B line count (not Item BOM-A)');
        foreach ActualBOMLineItemNo in ActualBOMLineItemNos do
            if ActualBOMLineItemNo <> '' then begin
                ProductionBOMLine.SetRange("No.", ActualBOMLineItemNo);
                Assert.IsTrue(ProductionBOMLine.FindFirst(),
                    StrSubstNo('BOM line item %1 should belong to SKU BOM-B, not Item BOM-A', ActualBOMLineItemNo));
            end;
        // DefineItemStructure mode: no production order should have been created
        ProdDefWizCheckLib.VerifyNoProdOrderForItem(ItemNo);
    end;

    [Test]
    [HandlerFunctions('HandleWizardCaptureSourceAndBOMLines')]
    procedure TestI3_SKULookupConsidersLocationAndVariant_ExactVariantMatch()
    var
        SKU1: Record "Stockkeeping Unit";
        SKU2: Record "Stockkeeping Unit";
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProductionBOMLine: Record "Production BOM Line";
        ProdDefManager: Codeunit "Production Definition Manager";
        ActualBOMLineItemNo: Code[20];
        ItemBOMNo: Code[20];
        SKU1BOMNo: Code[20];
        SKU2BOMNo: Code[20];
        RoutingNo: Code[20];
        ItemNo: Code[20];
        VariantCode: Code[10];
        LocationCode: Code[10];
        WC1No: Code[20];
        WC2No: Code[20];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO I3] SKU lookup considers both location and variant code — exact variant match wins
        Initialize();

        // [GIVEN] Two SKUs same item: SKU1(Loc=EAST, Var=''), SKU2(Loc=EAST, Var=RED); Sales Line Loc=EAST, Var=RED
        ItemBOMNo := ProdDefWizLibrary.CreateBOM(2);
        SKU1BOMNo := ProdDefWizLibrary.CreateBOM(2);
        SKU2BOMNo := ProdDefWizLibrary.CreateBOM(2);
        RoutingNo := ProdDefWizLibrary.CreateRoutingWithTwoLines(WC1No, WC2No);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(ItemBOMNo, RoutingNo);
        VariantCode := ProdDefWizLibrary.CreateVariantForItem(ItemNo);
        LocationCode := ProdDefWizLibrary.CreateLocationCode();

        // SKU1: no variant
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU1, ItemNo, LocationCode, '', SKU1BOMNo, RoutingNo);

        // SKU2: with variant — exact match
        ProdDefWizLibrary.CreateStockkeepingUnitWithBOMAndRouting(SKU2, ItemNo, LocationCode, VariantCode, SKU2BOMNo, RoutingNo);

        // Sales Line with Loc=LocationCode, Var=VariantCode
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 3, LocationCode, VariantCode, WorkDate());
        ProdDefWizSetupLib.ConfigureForBothAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        // [WHEN] Wizard initialized from Sales Line
        ActualSourceText := '';
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] SKU2 is selected (exact variant match); its BOM populates the wizard
        Assert.IsTrue(WizardFinished, 'Wizard should have finished');
        Assert.AreEqual('Stockkeeping Unit', ActualSourceText, 'Source should be StockkeepingUnit (exact variant match)');
        // CreateProductionOrder mode: a production order must exist for this item
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProductionBOMLine.SetRange("Production BOM No.", SKU2BOMNo);
        // Verify the wizard showed BOM lines and that the count matches SKU2's BOM
        ActualBOMLineItemNos.Remove('');
        Assert.IsTrue(ActualBOMLineItemNos.Count() > 0, 'Wizard should have shown at least one BOM line');
        Assert.AreEqual(ProductionBOMLine.Count(), ActualBOMLineItemNos.Count(), 'Wizard BOM line count should match SKU2''s BOM line count');
        foreach ActualBOMLineItemNo in ActualBOMLineItemNos do
            if ActualBOMLineItemNo <> '' then begin
                ProductionBOMLine.SetRange("No.", ActualBOMLineItemNo);
                Assert.IsTrue(ProductionBOMLine.FindFirst(),
                    StrSubstNo('BOM line item %1 should belong to SKU2''s BOM (exact variant match), not SKU1''s', ActualBOMLineItemNo));
            end;
    end;


    [Test]
    procedure TestI_ComponentVariantCodePropagated()
    var
        SalesLine: Record "Sales Line";
        ProdOrder: Record "Production Order";
        ProdDefManager: Codeunit "Production Definition Manager";
        BOMNo: Code[20];
        ItemNo: Code[20];
        ComponentItemNo: Code[20];
        ComponentVariantCode: Code[10];
    begin
        // [FEATURE] Production Definition Wizard
        // [SCENARIO I_ComponentVariant] BOM line with a variant code → Prod. Order Component carries the same
        // variant code after wizard finishes (regression test for BUG-03).
        Initialize();

        // [GIVEN] BOM with one component line that specifies a variant; Sales Line sources this item
        BOMNo := ProdDefWizLibrary.CreateBOMWithComponentVariant(ComponentItemNo, ComponentVariantCode);
        ItemNo := ProdDefWizLibrary.CreateItemWithBOMAndRouting(BOMNo, '');
        ProdDefWizLibrary.CreateSalesLine(SalesLine, ItemNo, 5, '', '', WorkDate());
        ProdDefWizSetupLib.ConfigureForPartiallyAvailable(
            "Prod. Definition Display"::Hide, "Prod. Definition Display"::Hide);

        // [WHEN] Wizard runs in CreateProductionOrder mode (UI skipped — no modal handler needed)
        Commit();
        ProdDefManager.RunForSource(SalesLine, "Prod. Definition Mode"::CreateProductionOrder);

        // [THEN] Prod. Order Component inherits the variant code from the BOM line
        ProdDefWizCheckLib.VerifyProdOrderExists(ItemNo, ProdOrder);
        ProdDefWizCheckLib.VerifyProdOrderComponentHasVariantCode(ProdOrder, ComponentVariantCode);
    end;


    [ModalPageHandler]
    procedure HandleWizardCaptureSourceAndBOMLines(var Wizard: TestPage "Production Definition Wizard")
    begin
        // Capture source text on Step 1
        ActualSourceText := Wizard.BOMRtngFromSourceField.Value();
        // Navigate to Step 2 (BOM)
        if Wizard.ActionNext.Enabled() then
            Wizard.ActionNext.Invoke();

        // Capture all BOM line item Nos to verify which BOM was loaded
        Clear(ActualBOMLineItemNos);
        if Wizard.BOMLinesPart.First() then
            repeat
                ActualBOMLineItemNos.Add(CopyStr(Wizard.BOMLinesPart."No.".Value(), 1, 20));
            until not Wizard.BOMLinesPart.Next();

        // Finish
        while Wizard.ActionNext.Enabled() do
            Wizard.ActionNext.Invoke();
        if Wizard.ActionFinish.Enabled() then begin
            Wizard.ActionFinish.Invoke();
            WizardFinished := true;
        end;
    end;


    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Prod. Def. Wiz. Variant Test");
        LibrarySetupStorage.Restore();
        WizardFinished := false;
        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Variant Test");
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        ProdDefWizSetupLib.InitializeBasicSetup();

        ProdDefWizSetupLib.ConfigureForNothingAvailable(
            "Prod. Definition Display"::Edit, "Prod. Definition Display"::Edit);

        IsInitialized := true;
        Commit();
        LibrarySetupStorage.SaveManufacturingSetup();
        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Prod. Def. Wiz. Variant Test");
    end;

}