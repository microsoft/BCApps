// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001544 "Subc. Transfer Line Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterGetTransHeader, '', false, false)]
    local procedure OnAfterGetTransHeader(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
        TransferLine."Return Order" := TransferHeader."Return Order";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if Rec.IsTemporary then
            exit;

        if not RunTrigger then
            exit;

        SubcontractingManagement.UpdateLocationCodeInProdOrderCompAfterDeleteTransferLine(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnValidateItemNoOnCopyFromTempTransLine, '', false, false)]
    local procedure OnValidateItemNoOnCopyFromTempTransLine_TransferLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line")
    begin
        CopySubFieldsFromTempTransferLineToTransferLine(TransferLine, TempTransferLine);
    end;

    local procedure CopySubFieldsFromTempTransferLineToTransferLine(var TransferLine: Record "Transfer Line"; TempTransferLine: Record "Transfer Line")
    begin
        TransferLine."Subcontr. Purch. Order No." := TempTransferLine."Subcontr. Purch. Order No.";
        TransferLine."Subcontr. PO Line No." := TempTransferLine."Subcontr. PO Line No.";
        TransferLine."Prod. Order No." := TempTransferLine."Prod. Order No.";
        TransferLine."Prod. Order Line No." := TempTransferLine."Prod. Order Line No.";
        TransferLine."Prod. Order Comp. Line No." := TempTransferLine."Prod. Order Comp. Line No.";
        TransferLine."Routing No." := TempTransferLine."Routing No.";
        TransferLine."Routing Reference No." := TempTransferLine."Routing Reference No.";
        TransferLine."Work Center No." := TempTransferLine."Work Center No.";
        TransferLine."Operation No." := TempTransferLine."Operation No.";
        TransferLine."Return Order" := TempTransferLine."Return Order";
    end;
}