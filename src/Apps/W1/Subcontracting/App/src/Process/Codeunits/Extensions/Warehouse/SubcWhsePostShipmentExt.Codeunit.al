// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Request;

codeunit 99001563 "Subc. WhsePostShipment Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Warehouse Mgt.", OnBeforeCheckIfTransLine2ShipmentLine, '', false, false)]
    local procedure HandleWipTransferOnBeforeCheckIfTransLine2ShipmentLine(var TransferLine: Record "Transfer Line"; var IsHandled: Boolean; var ReturnValue: Boolean)
    var
        Location: Record Location;
    begin
        if TransferLine."Transfer WIP Item" then begin
            if Location.GetLocationSetup(TransferLine."Transfer-from Code", Location) then
                if Location."Use As In-Transit" then
                    exit;

            TransferLine.CalcFields("Whse Outbnd. Otsdg. Qty");
            ReturnValue := TransferLine."Outstanding Quantity" > TransferLine."Whse Outbnd. Otsdg. Qty";
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Create Source Document", OnBeforeSetQtysOnShptLine, '', false, false)]
    local procedure HandleWipTransferOnBeforeSetQtysOnShptLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; var QtyBase: Decimal; var IsHandled: Boolean)
    begin
        if WarehouseShipmentLine."Transfer WIP Item" then
            WarehouseShipmentLine.Validate("Qty. Picked", Qty);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Transfer Warehouse Mgt.", OnFromTransLine2ShptLineOnAfterInitNewLine, '', false, false)]
    local procedure HandleWipTransferOnFromTransLine2ShptLineOnAfterInitNewLine(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; TransferLine: Record "Transfer Line"; var IsHandled: Boolean)
    begin
        WarehouseShipmentLine."Transfer WIP Item" := TransferLine."Transfer WIP Item";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", OnBeforeValidateQuantityIsBalanced, '', false, false)]
    local procedure HandleWipTransferOnBeforeValidateQuantityIsBalanced(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean; xWarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
        if WarehouseShipmentLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", OnBeforeOpenItemTrackingLines, '', false, false)]
    local procedure HandleWipTransferOnBeforeOpenItemTrackingLines(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    var
        NoWIPItemTrackingAllowedErr: Label 'Item tracking is not supported for WIP item transfers.';
    begin
        if WarehouseShipmentLine."Transfer WIP Item" then
            Error(NoWIPItemTrackingAllowedErr);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", OnBeforeCalcBaseQty, '', false, false)]
    local procedure HandleWipTransferOnBeforeCalcBaseQty(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var Qty: Decimal; FromFieldName: Text; ToFieldName: Text; var SuppressQtyPerUoMTestfield: Boolean)
    begin
        if WarehouseShipmentLine."Transfer WIP Item" then
            SuppressQtyPerUoMTestfield := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Post Shipment", OnBeforePostWhseJnlLine, '', false, false)]
    local procedure HandleWipTransferOnBeforePostWhseJnlLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; var IsHandled: Boolean)
    begin
        if PostedWhseShipmentLine."Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Shipment Line", OnBeforeValidateQtyToShipBase, '', false, false)]
    local procedure HandleWipTransferOnBeforeValidateQtyToShipBase(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; xWarehouseShipmentLine: Record "Warehouse Shipment Line"; CallingFieldNo: Integer; var IsHandled: Boolean)
    var
        Location: Record Location;
    begin
        if not WarehouseShipmentLine."Transfer WIP Item" then
            exit;
        Location.SetLoadFields("Require Pick");
        Location.Get(WarehouseShipmentLine."Location Code");
        if Location."Require Pick" then
            WarehouseShipmentLine.Validate("Qty. to Ship", WarehouseShipmentLine."Qty. Picked" - WarehouseShipmentLine."Qty. Shipped")
        else
            WarehouseShipmentLine.Validate("Qty. to Ship", WarehouseShipmentLine."Qty. Outstanding");
        IsHandled := true;
    end;
}