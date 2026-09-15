// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.InventoryDocument;

codeunit 20573 "Subc. Invt. Pick Ext"
{
    // WIP Item transfer lines intentionally have Qty. per Unit of Measure = 0. An Inventory Pick
    // still records the informational bin selection, but its base quantities must remain zero.
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", OnBeforeNewWhseActivLineInsertFromTransfer, '', false, false)]
    local procedure SetNonBaseQtyForWipItemTransferLine_OnBeforeNewWhseActivLineInsertFromTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TransferLine: Record "Transfer Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
        if not TransferLine."Transfer WIP Item" then
            exit;

        RemQtyToPickBase := TransferLine.CalcBaseQty(TransferLine."Qty. to Ship");
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", OnBeforeCreatePickOrMoveLineWithZeroBaseQty, '', false, false)]
    local procedure CreateWipItemPickLineWithZeroBaseQty_OnBeforeCreatePickOrMoveLineWithZeroBaseQty(WarehouseActivityLine: Record "Warehouse Activity Line"; var CreateLineWithZeroBaseQty: Boolean)
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            CreateLineWithZeroBaseQty := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", OnAfterCalcPickOrMoveLineQuantity, '', false, false)]
    local procedure SetNonBaseQtyForWipItemPickLine_OnAfterCalcPickOrMoveLineQuantity(WarehouseActivityLine: Record "Warehouse Activity Line"; QtyToPickBase: Decimal; var QtyToPick: Decimal)
    var
        TransferLine: Record "Transfer Line";
    begin
        if not WarehouseActivityLine."Subc. Transfer WIP Item" then
            exit;

        TransferLine.SetLoadFields("Qty. to Ship");
        TransferLine.Get(WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
        QtyToPick := TransferLine."Qty. to Ship";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeFindBinContent, '', false, false)]
    local procedure SkipBinContentLookupForWipItemPickLine_OnBeforeFindBinContent(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", OnBeforeGetSpecEquipmentCode, '', false, false)]
    local procedure AllowBlankBinForWipItemPickLine_OnBeforeGetSpecEquipmentCode(WarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20]; var AllowBlankBin: Boolean)
    begin
        if not WarehouseActivityLine."Subc. Transfer WIP Item" then
            exit;
        if TakeBinCode <> '' then
            exit;

        AllowBlankBin := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeValidateQtyToHandle, '', false, false)]
    local procedure AllowNonBaseQtyToHandleForWipItemPickLine_OnBeforeValidateQtyToHandle(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Table, Database::"Warehouse Activity Line", OnBeforeAutofillQtyToHandleLine, '', false, false)]
    local procedure SetNonBaseQtyToHandleForWipItemPickLine_OnBeforeAutofillQtyToHandleLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    var
        TransferLine: Record "Transfer Line";
    begin
        if not WarehouseActivityLine."Subc. Transfer WIP Item" then
            exit;
        if not (WarehouseActivityLine."Activity Type" in [WarehouseActivityLine."Activity Type"::Pick, WarehouseActivityLine."Activity Type"::"Invt. Pick"]) then
            exit;

        TransferLine.SetLoadFields("Qty. to Ship");
        TransferLine.Get(WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
        WarehouseActivityLine.Validate("Qty. to Handle", TransferLine."Qty. to Ship");
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforeCheckWarehouseActivityLine, '', false, false)]
    local procedure SkipPhysicalChecksForWipItemPickLine_OnBeforeCheckWarehouseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; var IsHandled: Boolean)
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforePostedInvtPickLineValidateQuantity, '', false, false)]
    local procedure KeepPostedWipItemPickLineBaseQtyZero_OnBeforePostedInvtPickLineValidateQuantity(var PostedInvtPickLine: Record "Posted Invt. Pick Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
        if not WarehouseActivityLine."Subc. Transfer WIP Item" then
            exit;

        PostedInvtPickLine.Quantity := WarehouseActivityLine."Qty. to Handle";
        PostedInvtPickLine."Qty. (Base)" := 0;
        IsHandled := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", OnBeforeWhseActivLineDelete, '', false, false)]
    local procedure DeleteCompletedWipItemPickLine_OnBeforeWhseActivLineDelete(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ForceDelete: Boolean; HideDialog: Boolean)
    begin
        if WarehouseActivityLine."Subc. Transfer WIP Item" then
            ForceDelete := true;
    end;
}