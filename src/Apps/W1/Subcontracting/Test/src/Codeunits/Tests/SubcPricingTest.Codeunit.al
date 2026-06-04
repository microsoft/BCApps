// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Subcontracting;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Utilities;

codeunit 139982 "Subc. Pricing Test"
{
    // [FEATURE] Subcontracting Pricing
    Subtype = Test;
    TestPermissions = Disabled;
    TestType = IntegrationTest;

    trigger OnRun()
    begin
        IsInitialized := false;
    end;

    [Test]
    procedure RoutingPriceUsesOrderUoMWhenMultipleUoMPricesExist()
    var
        Item: Record Item;
        ItemUOM: Record "Item Unit of Measure";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        AltUOMCode: Code[10];
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        PcsPrice, SetPrice : Decimal;
        QtyPerSet: Integer;
    begin
        // [SCENARIO 636059] SetRoutingPriceListCost must select the Subcontractor Price row matching
        // the order's Unit of Measure (with blank fallback). With prices in both Base UoM and an
        // alternative UoM that sorts after it, the routing line must pick the Base UoM price when
        // the order is in Base UoM — not the alphabetically-last alternative-UoM row.
        Initialize();

        // [GIVEN] Item with Base UoM and an alternative UoM (10 base per alt) whose code sorts after the base.
        LibraryInventory.CreateItem(Item);
        QtyPerSet := 10;
        AltUOMCode := CreateUOMCodeSortingAfter(Item."Base Unit of Measure");
        LibraryInventory.CreateItemUnitOfMeasure(ItemUOM, Item."No.", AltUOMCode, QtyPerSet);

        // [GIVEN] Vendor and Work Center with the vendor as its subcontractor; zero indirect/overhead.
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);

        // [GIVEN] Two subcontractor prices — Base UoM = 1001, alternative UoM = 1004.
        PcsPrice := 1001;
        SetPrice := 1004;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", PcsPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), AltUOMCode, 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", SetPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged as SetSubcontractorPriceForPriceCalculation would — order in Base UoM.
        InSubcontractorPrice."Vendor No." := Vendor."No.";
        InSubcontractorPrice."Item No." := Item."No.";
        InSubcontractorPrice."Standard Task Code" := '';
        InSubcontractorPrice."Work Center No." := WorkCenter."No.";
        InSubcontractorPrice."Variant Code" := '';
        InSubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
        InSubcontractorPrice."Starting Date" := WorkDate();
        InSubcontractorPrice."Currency Code" := '';

        // [WHEN] SetRoutingPriceListCost runs for a Prod. Order Routing Line of qty 1 in the Base UoM.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] Direct Unit Cost equals the Base UoM price (1001), not the alt-UoM derived 100.40.
        Assert.AreEqual(
            PcsPrice, DirUnitCost,
            'SetRoutingPriceListCost must pick the Subcontractor Price row matching the order''s Unit of Measure.');
    end;

    local procedure CreateUOMCodeSortingAfter(BaseUOMCode: Code[10]): Code[10]
    var
        UnitOfMeasure: Record "Unit of Measure";
        LibraryUtility: Codeunit "Library - Utility";
        NewCode: Code[10];
    begin
        // LibraryInventory.CreateUnitOfMeasureCode generates a hex-only code (truncated GUID), so
        // any code with a 'Z' prefix is guaranteed to sort after it. This makes the multi-UoM test
        // deterministic — without the fix, FindLast() picks the alt UoM row.
        repeat
            NewCode := CopyStr('Z' + LibraryUtility.GenerateGUID(), 1, MaxStrLen(NewCode));
        until not UnitOfMeasure.Get(NewCode);
        UnitOfMeasure.Init();
        UnitOfMeasure.Code := NewCode;
        UnitOfMeasure.Description := NewCode;
        UnitOfMeasure.Insert(true);
        if UnitOfMeasure.Code <= BaseUOMCode then
            Error('Test setup: generated UoM code %1 must sort after base UoM code %2.', UnitOfMeasure.Code, BaseUOMCode);
        exit(UnitOfMeasure.Code);
    end;

    local procedure Initialize()
    begin
        LibraryTestInitialize.OnTestInitialize(Codeunit::"Subc. Pricing Test");
        LibrarySetupStorage.Restore();

        SubcontractingMgmtLibrary.Initialize();
        SubcontractingMgmtLibrary.UpdateSubMgmtSetup_ComponentAtLocation("Components at Location"::Purchase);
        LibraryMfgManagement.CreateSubcontractingReqWkshTemplateAndNameAndUpdateSetup();
        LibraryVariableStorage.Clear();

        LibraryMfgManagement.Initialize();

        if IsInitialized then
            exit;
        LibraryTestInitialize.OnBeforeTestSuiteInitialize(Codeunit::"Subc. Pricing Test");

        SubSetupLibrary.InitSetupFields();
        LibraryERMCountryData.CreateVATData();
        SubSetupLibrary.InitialSetupForGenProdPostingGroup();

        IsInitialized := true;
        Commit();

        LibraryTestInitialize.OnAfterTestSuiteInitialize(Codeunit::"Subc. Pricing Test");
    end;

    var
        Assert: Codeunit Assert;
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySetupStorage: Codeunit "Library - Setup Storage";
        LibraryTestInitialize: Codeunit "Library - Test Initialize";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";
        SubcontractingMgmtLibrary: Codeunit "Subc. Management Library";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        SubSetupLibrary: Codeunit "Subc. Setup Library";
        IsInitialized: Boolean;
}
