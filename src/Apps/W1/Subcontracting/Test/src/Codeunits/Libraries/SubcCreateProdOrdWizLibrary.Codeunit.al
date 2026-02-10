// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting.Test;

using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Vendor;

codeunit 139986 "Subc. CreateProdOrdWizLibrary"
{
    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryRandom: Codeunit "Library - Random";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryMfgManagement: Codeunit "Subc. Library Mfg. Management";

    procedure CreateAndCalculateNeededWorkCenter(var WorkCenter: Record "Work Center"; IsSubcontracting: Boolean)
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
        WorkCenterNo: Code[20];
        UnitCostCalculation: Option Time,Units;
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();

        // Create Work Center
        CreateWorkCenter(WorkCenterNo, ShopCalendarCode, "Flushing Method"::"Pick + Manual", IsSubcontracting, UnitCostCalculation::Time, '');
        WorkCenter.Get(WorkCenterNo);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM>', WorkDate()));
    end;

    local procedure CreateWorkCenter(var WorkCenterNo: Code[20]; ShopCalendarCode: Code[10]; FlushingMethod: Enum "Flushing Method"; IsSubcontracting: Boolean;
                                                                                                                 UnitCostCalc: Option;
                                                                                                                 CurrencyCode: Code[10])
    var
        GenProductPostingGroup: Record "Gen. Product Posting Group";
        VATPostingSetup: Record "VAT Posting Setup";
        Vendor: Record Vendor;
        WorkCenter: Record "Work Center";
    begin
        LibraryMfgManagement.CreateWorkCenterWithFixedCost(WorkCenter, ShopCalendarCode, 0);

        WorkCenter.Validate("Flushing Method", FlushingMethod);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Validate("Indirect Cost %", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Overhead Rate", LibraryRandom.RandDec(5, 1));
        WorkCenter.Validate("Unit Cost Calculation", UnitCostCalc);

        if IsSubcontracting then begin
            LibraryERM.FindVATPostingSetup(VATPostingSetup, VATPostingSetup."VAT Calculation Type"::"Normal VAT");
            GenProductPostingGroup.FindFirst();
            GenProductPostingGroup.Validate("Def. VAT Prod. Posting Group", VATPostingSetup."VAT Prod. Posting Group");
            GenProductPostingGroup.Modify(true);
            WorkCenter.Validate("Subcontractor No.", LibraryMfgManagement.CreateSubcontractorWithCurrency(CurrencyCode));

            WorkCenter."Subcontractor No." := Vendor."No.";
        end;
        WorkCenter.Modify(true);
        WorkCenterNo := WorkCenter."No.";
    end;

    procedure CreateItemWithoutBOMAndRouting(BomNo: Code[20]; RoutingNo: Code[20]): Code[20]
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // Create item with specified BOM and Routing (empty for NothingPresent scenario)
        ItemNo := LibraryInventory.CreateItemNo();
        Item.Get(ItemNo);
        Item."Production BOM No." := BomNo;
        Item."Routing No." := RoutingNo;
        Item.Modify();
        exit(ItemNo);
    end;

    procedure CreatePurchaseLineWithSubcontractingVendor(var PurchLine: Record "Purchase Line"; ItemNo: Code[20])
    var
        Location, VendorLocation : Record Location;
        PurchaseHeader: Record "Purchase Header";
        Vendor: Record Vendor;
    begin
        // Create locations
        LibraryWarehouse.CreateLocation(Location);
        LibraryWarehouse.CreateLocation(VendorLocation);

        // Create vendor with subcontracting location
        LibraryPurchase.CreateVendor(Vendor);
        Vendor."Subcontr. Location Code" := VendorLocation.Code;
        Vendor.Modify();

        // Create purchase order with purchase line
        LibraryPurchase.CreatePurchaseOrderWithLocation(PurchaseHeader, Vendor."No.", Location.Code);
        LibraryPurchase.CreatePurchaseLine(PurchLine, PurchaseHeader, PurchLine.Type::Item, ItemNo, LibraryRandom.RandIntInRange(1, 10));
        PurchLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(10, 100, 2));
        PurchLine.Validate("Expected Receipt Date", WorkDate());
        PurchLine.Modify(true);
    end;

    procedure CreateBOMWithTwoLines(): Code[20]
    var
        ComponentItem1: Record Item;
        ComponentItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";

    begin
        // Create two component items
        LibraryInventory.CreateItem(ComponentItem1);
        LibraryInventory.CreateItem(ComponentItem2);

        // Create BOM header
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem1."Base Unit of Measure");

        // Create first BOM line
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem1."No.", 1);

        // Create second BOM line
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem2."No.", 2);

        ProductionBOMHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());

        // Certify the BOM
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);

        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateRoutingWithTwoLines(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
    begin
        // Create two work centers
        CreateAndCalculateNeededWorkCenter(WorkCenter1, false);
        CreateAndCalculateNeededWorkCenter(WorkCenter2, true);

        // Create routing header
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        // Create first routing line
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter1."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Modify(true);

        // Create second routing line
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter2."No.");
        RoutingLine.Validate("Setup Time", 15);
        RoutingLine.Validate("Run Time", 8);
        RoutingLine.Modify(true);

        RoutingHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());

        // Certify the routing
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);

        exit(RoutingHeader."No.");
    end;

    procedure CreateItemWithBOMAndRouting(BOMNo: Code[20]; RoutingNo: Code[20]): Code[20]
    var
        Item: Record Item;
        ItemNo: Code[20];
    begin
        // Create item with specified BOM and Routing
        ItemNo := LibraryInventory.CreateItemNo();
        Item.Get(ItemNo);
        Item."Production BOM No." := BOMNo;
        Item."Routing No." := RoutingNo;
        Item.Modify();
        exit(ItemNo);
    end;

    procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        // Create a location and return its code
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    procedure CreateStockkeepingUnit(var StockkeepingUnit: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10])
    begin
        // Create a stockkeeping unit for the given item and location
        StockkeepingUnit.Init();
        StockkeepingUnit."Location Code" := LocationCode;
        StockkeepingUnit."Item No." := ItemNo;
        StockkeepingUnit."Variant Code" := '';
        StockkeepingUnit.Insert(true);
    end;

    procedure CreateBOMVersionWithTwoLines(BOMNo: Code[20]; VersionCode: Code[20])
    var
        ComponentItem1: Record Item;
        ComponentItem2: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        // Create two component items
        LibraryInventory.CreateItem(ComponentItem1);
        LibraryInventory.CreateItem(ComponentItem2);

        // Create BOM version
        LibraryManufacturing.CreateProductionBOMVersion(ProductionBOMVersion, BOMNo, VersionCode, ComponentItem1."Base Unit of Measure");

        // Get the BOM header for creating lines
        ProductionBOMHeader.Get(BOMNo);

        // Create first BOM line for version
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, VersionCode, ProductionBOMLine.Type::Item, ComponentItem1."No.", 1);

        // Create second BOM line for version
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, VersionCode, ProductionBOMLine.Type::Item, ComponentItem2."No.", 2);

        // Certify the BOM version
        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    procedure CreateRoutingVersionWithTwoLines(RoutingNo: Code[20]; VersionCode: Code[20])
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
    begin
        // Create two work centers
        CreateAndCalculateNeededWorkCenter(WorkCenter1, false);
        CreateAndCalculateNeededWorkCenter(WorkCenter2, true);

        // Create routing version
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingNo, VersionCode);

        // Get the routing header for creating lines
        RoutingHeader.Get(RoutingNo);

        // Create first routing line for version
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, VersionCode, '10', RoutingLine.Type::"Work Center", WorkCenter1."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Modify(true);

        // Create second routing line for version
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, VersionCode, '20', RoutingLine.Type::"Work Center", WorkCenter2."No.");
        RoutingLine.Validate("Setup Time", 15);
        RoutingLine.Validate("Run Time", 8);
        RoutingLine.Modify(true);

        // Certify the routing version
        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
    end;
}