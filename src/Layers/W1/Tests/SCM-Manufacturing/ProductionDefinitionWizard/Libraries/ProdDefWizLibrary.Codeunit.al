// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Test;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Capacity;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Sales.Document;
using Microsoft.Sales.Customer;

codeunit 137420 "Prod. Def. Wiz. Library"
{
    var
        LibraryERM: Codeunit "Library - ERM";
        LibraryInventory: Codeunit "Library - Inventory";
        LibraryManufacturing: Codeunit "Library - Manufacturing";
        LibrarySales: Codeunit "Library - Sales";
        LibraryWarehouse: Codeunit "Library - Warehouse";
        LibraryRandom: Codeunit "Library - Random";

    procedure CreateItemWithBOMAndRouting(BOMNo: Code[20]; RoutingNo: Code[20]): Code[20]
    var
        Item: Record Item;
    begin
        LibraryInventory.CreateItem(Item);
        Item.Validate("Replenishment System", Item."Replenishment System"::"Prod. Order");
        Item.Validate("Production BOM No.", BOMNo);
        Item.Validate("Routing No.", RoutingNo);
        Item.Modify(true);
        exit(Item."No.");
    end;

    procedure CreateBOM(NumberOfLines: Integer): Code[20]
    var
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        i: Integer;
    begin
        LibraryInventory.CreateItem(ComponentItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        for i := 1 to NumberOfLines do begin
            LibraryInventory.CreateItem(ComponentItem);
            LibraryManufacturing.CreateProductionBOMLine(
                ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", i);
        end;
        ProductionBOMHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateBOMVersionAndCertify(BOMNo: Code[20]; VersionCode: Code[20]; StartingDate: Date)
    var
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMVersion: Record "Production BOM Version";
    begin
        ProductionBOMHeader.Get(BOMNo);
        LibraryInventory.CreateItem(ComponentItem);
        LibraryManufacturing.CreateProductionBOMVersion(
            ProductionBOMVersion, BOMNo, VersionCode, ComponentItem."Base Unit of Measure");
        ProductionBOMVersion."Starting Date" := StartingDate;
        ProductionBOMVersion.Modify();

        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, VersionCode, ProductionBOMLine.Type::Item, ComponentItem."No.", 1);

        ProductionBOMVersion.Validate(Status, ProductionBOMVersion.Status::Certified);
        ProductionBOMVersion.Modify(true);
    end;

    procedure CreateBOMWithoutVersionNos(): Code[20]
    var
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ComponentItem);
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        // Intentionally leave Version Nos. blank
        ProductionBOMHeader."Version Nos." := '';
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateRoutingWithoutVersionNos(): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateAndCalculateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Modify(true);
        // Intentionally leave Version Nos. blank
        RoutingHeader."Version Nos." := '';
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    procedure CreateAndCalculateWorkCenter(var WorkCenter: Record "Work Center")
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        ShopCalendarCode: Code[10];
    begin
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        ShopCalendarCode := LibraryManufacturing.UpdateShopCalendarWorkingDays();
        LibraryManufacturing.CreateWorkCenter(WorkCenter);
        WorkCenter.Validate("Unit of Measure Code", CapacityUnitOfMeasure.Code);
        WorkCenter.Validate("Shop Calendar Code", ShopCalendarCode);
        WorkCenter.Validate("Direct Unit Cost", LibraryRandom.RandDec(10, 2));
        WorkCenter.Modify(true);
        LibraryManufacturing.CalculateWorkCenterCalendar(WorkCenter, CalcDate('<-CY-1Y>', WorkDate()), CalcDate('<CM+1M>', WorkDate()));
    end;

    procedure CreateRoutingWithSingleLine(var WorkCenterNo: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateAndCalculateWorkCenter(WorkCenter);
        WorkCenterNo := WorkCenter."No.";

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Modify(true);

        RoutingHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    procedure CreateRoutingWithTwoLines(var WorkCenter1No: Code[20]; var WorkCenter2No: Code[20]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
    begin
        CreateAndCalculateWorkCenter(WorkCenter1);
        CreateAndCalculateWorkCenter(WorkCenter2);
        WorkCenter1No := WorkCenter1."No.";
        WorkCenter2No := WorkCenter2."No.";

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter1."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Modify(true);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter2."No.");
        RoutingLine.Validate("Setup Time", 15);
        RoutingLine.Validate("Run Time", 8);
        RoutingLine.Modify(true);

        RoutingHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    procedure CreateRoutingVersionAndCertify(RoutingNo: Code[20]; VersionCode: Code[20]; StartingDate: Date)
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        RoutingVersion: Record "Routing Version";
        WorkCenter: Record "Work Center";
    begin
        RoutingHeader.Get(RoutingNo);
        CreateAndCalculateWorkCenter(WorkCenter);
        LibraryManufacturing.CreateRoutingVersion(RoutingVersion, RoutingNo, VersionCode);
        RoutingVersion."Starting Date" := StartingDate;
        RoutingVersion.Modify();

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, VersionCode, '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Modify(true);

        RoutingVersion.Validate(Status, RoutingVersion.Status::Certified);
        RoutingVersion.Modify(true);
    end;

    procedure CreateLocationCode(): Code[10]
    var
        Location: Record Location;
    begin
        LibraryWarehouse.CreateLocation(Location);
        exit(Location.Code);
    end;

    procedure CreateStockkeepingUnitWithBOMAndRouting(var SKU: Record "Stockkeeping Unit"; ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10]; BOMNo: Code[20]; RoutingNo: Code[20])
    begin
        SKU.Init();
        SKU."Item No." := ItemNo;
        SKU."Location Code" := LocationCode;
        SKU."Variant Code" := VariantCode;
        SKU.Insert(true);
        SKU.Validate("Production BOM No.", BOMNo);
        SKU.Validate("Routing No.", RoutingNo);
        SKU.Modify(true);
    end;

    procedure CreateVariantForItem(ItemNo: Code[20]): Code[10]
    var
        ItemVariant: Record "Item Variant";
    begin
        LibraryInventory.CreateItemVariant(ItemVariant, ItemNo);
        exit(ItemVariant.Code);
    end;

    procedure CreateSalesLine(var SalesLine: Record "Sales Line"; ItemNo: Code[20]; Qty: Decimal; LocationCode: Code[10]; VariantCode: Code[10]; ShipmentDate: Date)
    var
        Customer: Record Customer;
        SalesHeader: Record "Sales Header";
    begin
        LibrarySales.CreateCustomer(Customer);
        LibrarySales.CreateSalesHeader(SalesHeader, SalesHeader."Document Type"::Order, Customer."No.");
        LibrarySales.CreateSalesLine(SalesLine, SalesHeader, SalesLine.Type::Item, ItemNo, Qty);
        SalesLine.Validate("Location Code", LocationCode);
        if VariantCode <> '' then
            SalesLine.Validate("Variant Code", VariantCode);
        if ShipmentDate <> 0D then
            SalesLine.Validate("Shipment Date", ShipmentDate);
        SalesLine.Modify(true);
    end;

    procedure CreatePartialReservationForSalesLine(var SalesLine: Record "Sales Line"; QtyToReserve: Decimal)
    var
        ReservEntry: Record "Reservation Entry";
        NextEntryNo: Integer;
    begin
        if ReservEntry.FindLast() then
            NextEntryNo := ReservEntry."Entry No." + 1
        else
            NextEntryNo := 1;

        // Supply side (positive) – linked to a fictitious item ledger entry
        ReservEntry.Init();
        ReservEntry."Entry No." := NextEntryNo;
        ReservEntry."Item No." := SalesLine."No.";
        ReservEntry."Location Code" := SalesLine."Location Code";
        ReservEntry.Quantity := QtyToReserve;
        ReservEntry."Quantity (Base)" := QtyToReserve;
        ReservEntry.Positive := true;
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Reservation;
        ReservEntry."Source Type" := Database::"Item Ledger Entry";
        ReservEntry."Source Subtype" := 0;
        ReservEntry."Source ID" := '';
        ReservEntry."Source Ref. No." := 0;
        ReservEntry.Insert();

        // Demand side (negative) – linked to the sales line
        ReservEntry.Init();
        ReservEntry."Entry No." := NextEntryNo + 1;
        ReservEntry."Item No." := SalesLine."No.";
        ReservEntry."Location Code" := SalesLine."Location Code";
        ReservEntry.Quantity := -QtyToReserve;
        ReservEntry."Quantity (Base)" := -QtyToReserve;
        ReservEntry.Positive := false;
        ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Reservation;
        ReservEntry."Source Type" := Database::"Sales Line";
        ReservEntry."Source Subtype" := SalesLine."Document Type".AsInteger();
        ReservEntry."Source ID" := SalesLine."Document No.";
        ReservEntry."Source Ref. No." := SalesLine."Line No.";
        ReservEntry.Insert();
    end;

    procedure CreateBOMWithComponentAndDescription2(var ComponentItemNo: Code[20]; Desc2: Text[50]): Code[20]
    var
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItemNo := ComponentItem."No.";
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItem."No.", 1);
        ProductionBOMLine.Validate("Description 2", Desc2);
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateRoutingWithSingleLineAndDescription2(var WorkCenterNo: Code[20]; Desc2: Text[50]): Code[20]
    var
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter: Record "Work Center";
    begin
        CreateAndCalculateWorkCenter(WorkCenter);
        WorkCenterNo := WorkCenter."No.";
        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);
        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Validate("Description 2", CopyStr(Desc2, 1, MaxStrLen(RoutingLine."Description 2")));
        RoutingLine.Modify(true);
        RoutingHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

    procedure CreateItemWithSalesUOMMultiplier(BOMNo: Code[20]; RoutingNo: Code[20]; AltUOMMultiplier: Decimal; var ItemNo: Code[20]; var AltUOMCode: Code[10])
    var
        Item: Record Item;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        UnitOfMeasure: Record "Unit of Measure";
    begin
        LibraryInventory.CreateUnitOfMeasureCode(UnitOfMeasure);
        ItemNo := CreateItemWithBOMAndRouting(BOMNo, RoutingNo);
        Item.Get(ItemNo);
        LibraryInventory.CreateItemUnitOfMeasure(ItemUnitOfMeasure, ItemNo, UnitOfMeasure.Code, AltUOMMultiplier);
        AltUOMCode := ItemUnitOfMeasure.Code;
        Item.Validate("Sales Unit of Measure", AltUOMCode);
        Item.Modify(true);
    end;

    procedure CreateItemWithLotTracking(BOMNo: Code[20]; RoutingNo: Code[20]): Code[20]
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
    begin
        ItemTrackingCode.Init();
        ItemTrackingCode.Code := CopyStr('LOT' + Format(LibraryRandom.RandIntInRange(1000, 9999)), 1, 10);
        ItemTrackingCode."Lot Sales Outbound Tracking" := true;
        ItemTrackingCode."Lot Manuf. Inbound Tracking" := true;
        ItemTrackingCode.Insert(true);
        Item.Get(CreateItemWithBOMAndRouting(BOMNo, RoutingNo));
        Item.Validate("Item Tracking Code", ItemTrackingCode.Code);
        Item.Modify(true);
        exit(Item."No.");
    end;

    procedure CreateBOMWithComponentVariant(var ComponentItemNo: Code[20]; var ComponentVariantCode: Code[10]): Code[20]
    var
        ComponentItem: Record Item;
        ComponentVariant: Record "Item Variant";
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItemNo := ComponentItem."No.";
        LibraryInventory.CreateItemVariant(ComponentVariant, ComponentItemNo);
        ComponentVariantCode := ComponentVariant.Code;

        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo, 1);
        ProductionBOMLine.Validate("Variant Code", ComponentVariantCode);
        ProductionBOMLine.Modify(true);

        ProductionBOMHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateBOMWithDimensionalFields(var ComponentItemNo: Code[20]): Code[20]
    var
        ComponentItem: Record Item;
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
    begin
        LibraryInventory.CreateItem(ComponentItem);
        ComponentItemNo := ComponentItem."No.";
        LibraryManufacturing.CreateProductionBOMHeader(ProductionBOMHeader, ComponentItem."Base Unit of Measure");
        LibraryManufacturing.CreateProductionBOMLine(
            ProductionBOMHeader, ProductionBOMLine, '', ProductionBOMLine.Type::Item, ComponentItemNo, 1);
        ProductionBOMLine.Validate("Calculation Formula", ProductionBOMLine."Calculation Formula"::"Fixed Quantity");
        ProductionBOMLine.Validate("Scrap %", 5);
        ProductionBOMLine."Length" := 2;
        ProductionBOMLine."Width" := 3;
        ProductionBOMLine."Weight" := 4;
        ProductionBOMLine."Depth" := 1;
        ProductionBOMLine.Modify(true);
        ProductionBOMHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        ProductionBOMHeader.Validate(Status, ProductionBOMHeader.Status::Certified);
        ProductionBOMHeader.Modify(true);
        exit(ProductionBOMHeader."No.");
    end;

    procedure CreateRoutingWithTwoLinesAndExtendedFields(var WorkCenter1No: Code[20]; var WorkCenter2No: Code[20]; var CapUOMCode: Code[10]): Code[20]
    var
        CapacityUnitOfMeasure: Record "Capacity Unit of Measure";
        RoutingHeader: Record "Routing Header";
        RoutingLine: Record "Routing Line";
        WorkCenter1: Record "Work Center";
        WorkCenter2: Record "Work Center";
    begin
        CreateAndCalculateWorkCenter(WorkCenter1);
        CreateAndCalculateWorkCenter(WorkCenter2);
        WorkCenter1No := WorkCenter1."No.";
        WorkCenter2No := WorkCenter2."No.";
        LibraryManufacturing.CreateCapacityUnitOfMeasure(CapacityUnitOfMeasure, "Capacity Unit of Measure"::Minutes);
        CapUOMCode := CapacityUnitOfMeasure.Code;

        LibraryManufacturing.CreateRoutingHeader(RoutingHeader, RoutingHeader.Type::Serial);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '10', RoutingLine.Type::"Work Center", WorkCenter1."No.");
        RoutingLine.Validate("Setup Time", 10);
        RoutingLine.Validate("Run Time", 5);
        RoutingLine.Validate("Setup Time Unit of Meas. Code", CapUOMCode);
        RoutingLine.Validate("Run Time Unit of Meas. Code", CapUOMCode);
        RoutingLine.Validate("Wait Time Unit of Meas. Code", CapUOMCode);
        RoutingLine.Validate("Move Time Unit of Meas. Code", CapUOMCode);
        RoutingLine."Fixed Scrap Quantity" := 3;
        RoutingLine."Scrap Factor %" := 10;
        RoutingLine."Send-Ahead Quantity" := 5;
        RoutingLine."Concurrent Capacities" := 2;
        RoutingLine."Lot Size" := 1;
        RoutingLine.Modify(true);

        LibraryManufacturing.CreateRoutingLine(
            RoutingHeader, RoutingLine, '', '20', RoutingLine.Type::"Work Center", WorkCenter2."No.");
        RoutingLine.Validate("Setup Time", 15);
        RoutingLine.Validate("Run Time", 8);
        RoutingLine.Modify(true);

        RoutingHeader.Validate("Version Nos.", LibraryERM.CreateNoSeriesCode());
        RoutingHeader.Validate(Status, RoutingHeader.Status::Certified);
        RoutingHeader.Modify(true);
        exit(RoutingHeader."No.");
    end;

}