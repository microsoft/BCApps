// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Reports;
using Microsoft.Manufacturing.Routing;
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

    [Test]
    procedure RoutingPriceUsesLCYWhenForeignCurrencyPriceExists()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        ForeignCurrencyCode: Code[10];
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        LCYPrice: Decimal;
    begin
        // [SCENARIO 638367] SetRoutingPriceListCost must filter Subcontractor Price by Currency Code so the
        // LCY (blank-currency) price drives Calc Standard Cost / Prod. Order Routing, not the alphabetically-last
        // foreign-currency row picked by FindLast() when Currency Code is left unfiltered.
        Initialize();

        // [GIVEN] Item, vendor and a subcontracting work center with zero indirect/overhead.
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);

        // [GIVEN] A foreign currency whose code sorts after the blank LCY code.
        ForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 15, 15);

        // [GIVEN] Two subcontractor prices — LCY = 10 and the foreign currency = 20.
        LCYPrice := 10;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, ForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 20);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for an LCY routing line (blank Currency Code).
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, '', '');

        // [WHEN] SetRoutingPriceListCost runs for a routing line of qty 1 in the base UoM.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The LCY price (10) is used, not the foreign-currency price converted to LCY.
        Assert.AreEqual(
            LCYPrice, DirUnitCost,
            'SetRoutingPriceListCost must use the LCY subcontractor price, not a foreign-currency row.');
    end;

    [Test]
    procedure RoutingPriceFallsBackToCatchAllStandardTaskCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Prod. Order Routing path, SetRoutingPriceListCost must fall back to the
        // catch-all (blank Standard Task Code) subcontractor price when the routing line carries a Standard
        // Task Code that has no dedicated price — instead of leaving the routing cost in place.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank task, blank variant).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for a routing line with a Standard Task Code that has no own price.
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, '', 'TASK1');

        // [WHEN] SetRoutingPriceListCost runs.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The catch-all price (333) is applied.
        Assert.AreEqual(
            CatchAllPrice, DirUnitCost,
            'SetRoutingPriceListCost must fall back to the blank-Standard-Task-Code price.');
    end;

    [Test]
    procedure RoutingPriceFallsBackToCatchAllVariantCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Prod. Order Routing path, SetRoutingPriceListCost must fall back to the
        // catch-all (blank Variant Code) subcontractor price when the prod. order line has a Variant Code
        // that has no dedicated price.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank variant, blank task).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for a routing line with a Variant Code that has no own price.
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, 'VAR1', '');

        // [WHEN] SetRoutingPriceListCost runs.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The catch-all price (333) is applied.
        Assert.AreEqual(
            CatchAllPrice, DirUnitCost,
            'SetRoutingPriceListCost must fall back to the blank-Variant-Code price.');
    end;

    [Test]
    procedure RoutingPricePrefersVariantSpecificOverStandardTaskSpecific()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        StandardTask: Record "Standard Task";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        InSubcontractorPrice: Record "Subcontractor Price";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        UnitCostCalcType: Enum "Unit Cost Calculation Type";
        DirUnitCost, IndirCostPct, OvhdRate, UnitCost : Decimal;
        VariantPrice, TaskPrice : Decimal;
    begin
        // [SCENARIO 638400] When a routing line matches BOTH a variant-specific price (blank Standard Task Code)
        // and a standard-task-specific price (blank Variant Code), the lookup must be deterministic. With empty
        // fallback on both fields, FindLast follows the Subcontractor Price primary key order, where Variant Code
        // (field 4) precedes Standard Task Code (field 5), so the variant-specific row wins. This pins that
        // precedence so it stays consistent across the routing, worksheet, and purchase-line lookups.
        Initialize();

        // [GIVEN] Item (with a variant), a standard task, vendor and a subcontracting work center.
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        LibraryInventory.CreateItemVariant(ItemVariant, Item."No.");
        LibraryManufacturing.CreateStandardTask(StandardTask);

        // [GIVEN] A variant-specific price (blank task = 100) and a standard-task-specific price (blank variant = 200).
        VariantPrice := 100;
        TaskPrice := 200;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', ItemVariant.Code, WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", VariantPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", StandardTask.Code, '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", TaskPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] InSubcontractorPrice staged for a routing line carrying both the variant and the standard task.
        StageInSubcontractorPrice(InSubcontractorPrice, Vendor, WorkCenter, Item, ItemVariant.Code, StandardTask.Code);

        // [WHEN] SetRoutingPriceListCost runs.
        SubcPriceManagement.SetRoutingPriceListCost(
            InSubcontractorPrice, WorkCenter, DirUnitCost, IndirCostPct, OvhdRate, UnitCost, UnitCostCalcType, 1, 1, 1);

        // [THEN] The variant-specific price (100) wins over the standard-task-specific price (200).
        Assert.AreEqual(
            VariantPrice, DirUnitCost,
            'When both a variant-specific and a standard-task-specific price match, the variant-specific price (per PK order) must win.');
    end;

    [Test]
    procedure WorksheetPriceFallsBackToCatchAllStandardTaskCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Subcontracting Worksheet path, GetSubcPriceForReqLine must fall back to the
        // catch-all (blank Standard Task Code) subcontractor price when the worksheet line carries a Standard
        // Task Code that has no dedicated price.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank task, blank variant).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A worksheet (requisition) line with a Standard Task Code that has no own price.
        StageRequisitionLine(RequisitionLine, Vendor, WorkCenter, Item, '', 'TASK1');

        // [WHEN] GetSubcPriceForReqLine runs.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] The catch-all price (333) is applied to the worksheet line.
        Assert.AreEqual(
            CatchAllPrice, RequisitionLine."Direct Unit Cost",
            'GetSubcPriceForReqLine must fall back to the blank-Standard-Task-Code price.');
    end;

    [Test]
    procedure WorksheetPriceFallsBackToCatchAllVariantCode()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        RequisitionLine: Record "Requisition Line";
        SubcPriceManagement: Codeunit "Subc. Price Management";
        CatchAllPrice: Decimal;
    begin
        // [SCENARIO 638400] On the Subcontracting Worksheet path, GetSubcPriceForReqLine must fall back to the
        // catch-all (blank Variant Code) subcontractor price when the worksheet line has a Variant Code that
        // has no dedicated price.
        Initialize();

        // [GIVEN] Item, vendor, subcontracting work center and a single catch-all price (blank variant, blank task).
        CreateItemVendorAndSubcontractingWorkCenter(Item, Vendor, WorkCenter);
        CatchAllPrice := 333;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", CatchAllPrice);
        SubcontractorPrice.Modify(true);

        // [GIVEN] A worksheet (requisition) line with a Variant Code that has no own price.
        StageRequisitionLine(RequisitionLine, Vendor, WorkCenter, Item, 'VAR1', '');

        // [WHEN] GetSubcPriceForReqLine runs.
        SubcPriceManagement.GetSubcPriceForReqLine(RequisitionLine, '');

        // [THEN] The catch-all price (333) is applied to the worksheet line.
        Assert.AreEqual(
            CatchAllPrice, RequisitionLine."Direct Unit Cost",
            'GetSubcPriceForReqLine must fall back to the blank-Variant-Code price.');
    end;

    [Test]
    procedure ProdOrderRoutingUnitCostUsesLCYWhenForeignCurrencyPriceExists()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ForeignCurrencyCode: Code[10];
        LCYPrice: Decimal;
    begin
        // [SCENARIO 638367] Refreshing a Released Production Order must price the subcontracting Prod. Order
        // Routing line from the LCY (blank-currency) subcontractor price, not from the alphabetically-last
        // foreign-currency price converted to LCY. End-to-end check of the routing path via the
        // OnAfterTransferRoutingLine subscriber -> ApplySubcontractorPricingToProdOrderRouting.
        Initialize();

        // [GIVEN] A subcontracting item with a single-operation routing on a subcontracting work center.
        CreateSubcontractingItemWithSingleOperationRouting(Item, Vendor, WorkCenter);

        // [GIVEN] A foreign currency with a non-LCY exchange rate whose code sorts after blank/LCY.
        ForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 15, 15);

        // [GIVEN] Two subcontractor prices for the item/work center/vendor — LCY = 10 and foreign = 20.
        LCYPrice := 10;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, ForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 20);
        SubcontractorPrice.Modify(true);

        // [WHEN] A Released Production Order for the item is created and refreshed.
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, Item."No.", 1);

        // [THEN] The Prod. Order Routing line Direct Unit Cost and Unit Cost per equal the LCY price (10).
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Direct Unit Cost",
            'Prod. Order Routing Direct Unit Cost must use the LCY subcontractor price, not a foreign-currency one.');
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Unit Cost per",
            'Prod. Order Routing Unit Cost per must use the LCY subcontractor price, not a foreign-currency one.');
    end;

    [Test]
    procedure ProdOrderRoutingUnitCostUsesLCYAmongMultipleForeignCurrencies()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        SubcontractorPrice: Record "Subcontractor Price";
        ProductionOrder: Record "Production Order";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        FirstForeignCurrencyCode: Code[10];
        SecondForeignCurrencyCode: Code[10];
        LCYPrice: Decimal;
    begin
        // [SCENARIO 638367] Even when several foreign-currency prices exist (all sorting after blank on the
        // primary key), the Prod. Order Routing line must still resolve to the single LCY (blank-currency) price.
        Initialize();

        // [GIVEN] A subcontracting item with a single-operation routing on a subcontracting work center.
        CreateSubcontractingItemWithSingleOperationRouting(Item, Vendor, WorkCenter);

        // [GIVEN] Two foreign currencies with non-LCY exchange rates.
        FirstForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 15, 15);
        SecondForeignCurrencyCode := LibraryERM.CreateCurrencyWithExchangeRate(WorkDate(), 12, 12);

        // [GIVEN] An LCY price (10) and two foreign-currency prices (20 and 18).
        LCYPrice := 10;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", LCYPrice);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, FirstForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 20);
        SubcontractorPrice.Modify(true);
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, SecondForeignCurrencyCode);
        SubcontractorPrice.Validate("Direct Unit Cost", 18);
        SubcontractorPrice.Modify(true);

        // [WHEN] A Released Production Order for the item is created and refreshed.
        SubcontractingMgmtLibrary.CreateAndRefreshProductionOrder(
            ProductionOrder, "Production Order Status"::Released, "Prod. Order Source Type"::Item, Item."No.", 1);

        // [THEN] The Prod. Order Routing line still resolves to the LCY price (10).
        ProdOrderRoutingLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderRoutingLine.FindFirst();
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Direct Unit Cost",
            'Prod. Order Routing Direct Unit Cost must use the LCY price even among multiple foreign-currency prices.');
        Assert.AreEqual(
            LCYPrice, ProdOrderRoutingLine."Unit Cost per",
            'Prod. Order Routing Unit Cost per must use the LCY price even among multiple foreign-currency prices.');
    end;

    local procedure CreateItemVendorAndSubcontractingWorkCenter(var Item: Record Item; var Vendor: Record Vendor; var WorkCenter: Record "Work Center")
    begin
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);
    end;

    local procedure CreateSubcontractingItemWithSingleOperationRouting(var Item: Record Item; var Vendor: Record Vendor; var WorkCenter: Record "Work Center")
    var
        RoutingNo: Code[20];
    begin
        Vendor.Get(LibraryMfgManagement.CreateSubcontractorWithCurrency(''));

        LibraryMfgManagement.CreateWorkCenterWithCalendar(WorkCenter, 0);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Modify(true);

        RoutingNo := CreateCertifiedSubcontractingRouting(WorkCenter."No.");

        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
    end;

    local procedure CreateCertifiedSubcontractingRouting(WorkCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
    begin
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

#pragma warning disable AA0210
        CapacityUnitOfMeasure.SetRange(Type, CapacityUnitOfMeasure.Type::Minutes);
#pragma warning restore AA0210
        CapacityUnitOfMeasure.FindFirst();

        LibraryManufacturing.CreateRoutingLineSetup(RoutingLine, RoutingHeader, WorkCenterNo, '10', 0, 1);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapacityUnitOfMeasure.Code);
        RoutingLine.Modify(true);

        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    local procedure StageInSubcontractorPrice(var InSubcontractorPrice: Record "Subcontractor Price"; Vendor: Record Vendor; WorkCenter: Record "Work Center"; Item: Record Item; VariantCode: Code[10]; StandardTaskCode: Code[10])
    begin
        // Mirrors how SetSubcontractorPriceForPriceCalculation stages the lookup record for a routing line.
        InSubcontractorPrice.Init();
        InSubcontractorPrice."Vendor No." := Vendor."No.";
        InSubcontractorPrice."Item No." := Item."No.";
        InSubcontractorPrice."Standard Task Code" := StandardTaskCode;
        InSubcontractorPrice."Work Center No." := WorkCenter."No.";
        InSubcontractorPrice."Variant Code" := VariantCode;
        InSubcontractorPrice."Unit of Measure Code" := Item."Base Unit of Measure";
        InSubcontractorPrice."Starting Date" := WorkDate();
        InSubcontractorPrice."Currency Code" := '';
    end;

    local procedure StageRequisitionLine(var RequisitionLine: Record "Requisition Line"; Vendor: Record Vendor; WorkCenter: Record "Work Center"; Item: Record Item; VariantCode: Code[10]; StandardTaskCode: Code[10])
    begin
        RequisitionLine.Init();
        RequisitionLine.Type := RequisitionLine.Type::Item;
        RequisitionLine."No." := Item."No.";
        RequisitionLine."Vendor No." := Vendor."No.";
        RequisitionLine."Work Center No." := WorkCenter."No.";
        RequisitionLine."Variant Code" := VariantCode;
        RequisitionLine."Subc. Standard Task Code" := StandardTaskCode;
        RequisitionLine."Unit of Measure Code" := Item."Base Unit of Measure";
        RequisitionLine."Currency Code" := '';
        RequisitionLine."Order Date" := WorkDate();
        RequisitionLine.Quantity := 1;
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

    [Test]
    procedure DetailedCalculationReportUsesSubcontractorPricing()
    var
        Item: Record Item;
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        SubcontractorPrice: Record "Subcontractor Price";
        DetailedCalculation: Report "Detailed Calculation";
        SubcPriceAmount: Decimal;
        WorkCenterDirectCost: Decimal;
    begin
        // [SCENARIO 638464] Report "Detailed Calculation" must use subcontractor pricing for
        // work centers with a subcontractor when the Subcontracting app is installed, via
        // the OnAfterGetRecordRoutingLineOnBeforeCalcRoutingCostPerUnit event.
        Initialize();

        // [GIVEN] Item with a routing that has a single Work Center operation.
        LibraryInventory.CreateItem(Item);
        LibraryPurchase.CreateVendor(Vendor);
        WorkCenterDirectCost := 50;
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Direct Unit Cost", WorkCenterDirectCost);
        WorkCenter.Validate("Subcontractor No.", Vendor."No.");
        WorkCenter.Validate("Indirect Cost %", 0);
        WorkCenter.Validate("Overhead Rate", 0);
        WorkCenter.Validate("Unit Cost", WorkCenterDirectCost);
        WorkCenter.Modify(true);

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Run Time", 1);
        RoutingLine.Modify(true);
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        Item.Validate("Routing No.", RoutingHeader."No.");
        Item.Validate("Lot Size", 1);
        Item.Modify(true);

        // [GIVEN] A subcontractor price of 200 for this item/work center (different from WorkCenter."Direct Unit Cost" of 50).
        SubcPriceAmount := 200;
        SubcontractingMgmtLibrary.CreateSubContractingPrice(
            SubcontractorPrice, WorkCenter."No.", Vendor."No.", Item."No.", '', '', WorkDate(), Item."Base Unit of Measure", 0, '');
        SubcontractorPrice.Validate("Direct Unit Cost", SubcPriceAmount);
        SubcontractorPrice.Modify(true);

        // [WHEN] Run the "Detailed Calculation" report (BaseApp 99000756) for this item.
        Commit();
        Item.SetRecFilter();
        DetailedCalculation.SetTableView(Item);

        DetailedCalculation.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());

        // [THEN] The ProdUnitCost in the report dataset equals the subcontractor price (200),
        // not the Work Center's generic Direct Unit Cost (50).
        LibraryReportDataset.LoadDataSetFile();
        LibraryReportDataset.AssertElementWithValueExists('ProdUnitCost', SubcPriceAmount);
    end;

    var
        Assert: Codeunit Assert;
        LibraryERM: Codeunit "Library - ERM";
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
