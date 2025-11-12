// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Document;

codeunit 5750 "Whse.-Create Source Document"
{

    trigger OnRun()
    begin
    end;

    internal procedure CreateShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    var
        Item: Record Item;
    begin
        Item."No." := WarehouseShipmentLine."Item No.";
        Item.ItemSKUGet(Item, WarehouseShipmentLine."Location Code", WarehouseShipmentLine."Variant Code");
        WarehouseShipmentLine."Shelf No." := Item."Shelf No.";
        OnBeforeWhseShptLineInsert(WarehouseShipmentLine);
        WarehouseShipmentLine.Insert();
        OnAfterWhseShptLineInsert(WarehouseShipmentLine);
        WarehouseShipmentLine.CreateWhseItemTrackingLines();

        OnAfterCreateShptLine(WarehouseShipmentLine);
    end;

    internal procedure SetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; Qty: Decimal; QtyBase: Decimal)
    var
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQtysOnShptLine(WarehouseShipmentLine, Qty, QtyBase, IsHandled);
        if not IsHandled then begin
            WarehouseShipmentLine.Quantity := Qty;
            WarehouseShipmentLine."Qty. (Base)" := QtyBase;
            WarehouseShipmentLine.InitOutstandingQtys();
            WarehouseShipmentLine.CheckSourceDocLineQty();
            if Location.Get(WarehouseShipmentLine."Location Code") then
                WarehouseShipmentLine.CheckBin(0, 0);
        end;

        OnAfterSetQtysOnShptLine(WarehouseShipmentLine, Qty, QtyBase);
    end;

    internal procedure CreateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    var
        Item: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateReceiptLine(WarehouseReceiptLine, IsHandled);
        if IsHandled then
            exit;

        Item."No." := WarehouseReceiptLine."Item No.";
        Item.ItemSKUGet(Item, WarehouseReceiptLine."Location Code", WarehouseReceiptLine."Variant Code");
        WarehouseReceiptLine."Shelf No." := Item."Shelf No.";
        WarehouseReceiptLine.Status := WarehouseReceiptLine.GetLineStatus();
        OnBeforeWhseReceiptLineInsert(WarehouseReceiptLine);
        WarehouseReceiptLine.Insert();
        OnAfterWhseReceiptLineInsert(WarehouseReceiptLine);
    end;

    internal procedure SetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetQtysOnRcptLine(WarehouseReceiptLine, Qty, QtyBase, IsHandled);
        if IsHandled then
            exit;

        WarehouseReceiptLine.Quantity := Qty;
        WarehouseReceiptLine."Qty. (Base)" := QtyBase;
        WarehouseReceiptLine.InitOutstandingQtys();

        OnAfterSetQtysOnRcptLine(WarehouseReceiptLine, Qty, QtyBase);
    end;

    internal procedure UpdateShipmentLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateShptLine(WarehouseShipmentLine, WarehouseShipmentHeader, IsHandled);
        if IsHandled then
            exit;

        if WarehouseShipmentHeader."Zone Code" <> '' then
            WarehouseShipmentLine.Validate("Zone Code", WarehouseShipmentHeader."Zone Code");
        if WarehouseShipmentHeader."Bin Code" <> '' then
            WarehouseShipmentLine.Validate("Bin Code", WarehouseShipmentHeader."Bin Code");
    end;

    internal procedure UpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader, IsHandled);
        if not IsHandled then begin
            if WarehouseReceiptHeader."Zone Code" <> '' then
                WarehouseReceiptLine.Validate("Zone Code", WarehouseReceiptHeader."Zone Code");
            if WarehouseReceiptHeader."Bin Code" <> '' then
                WarehouseReceiptLine.Validate("Bin Code", WarehouseReceiptHeader."Bin Code");
            if WarehouseReceiptHeader."Cross-Dock Zone Code" <> '' then
                WarehouseReceiptLine.Validate("Cross-Dock Zone Code", WarehouseReceiptHeader."Cross-Dock Zone Code");
            if WarehouseReceiptHeader."Cross-Dock Bin Code" <> '' then
                WarehouseReceiptLine.Validate("Cross-Dock Bin Code", WarehouseReceiptHeader."Cross-Dock Bin Code");
            OnAfterUpdateReceiptLine(WarehouseReceiptLine, WarehouseReceiptHeader);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; Qty: Decimal; QtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseReceiptLineInsert(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhseShptLineInsert(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateReceiptLine(var WhseReceiptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseReceiptLineInsert(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineInsert(var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetQtysOnRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var Qty: Decimal; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateReceiptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; WarehouseReceiptHeader: Record "Warehouse Receipt Header");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; var QtyBase: Decimal)
    begin
    end;
}
