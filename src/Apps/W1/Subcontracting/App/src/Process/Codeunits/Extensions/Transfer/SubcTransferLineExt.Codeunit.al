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
        TransferLine."Subc. Return Order" := TransferHeader."Subc. Return Order";
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
        TransferLine."Subc. Purch. Order No." := TempTransferLine."Subc. Purch. Order No.";
        TransferLine."Subc. Purch. Order Line No." := TempTransferLine."Subc. Purch. Order Line No.";
        TransferLine."Subc. Prod. Order No." := TempTransferLine."Subc. Prod. Order No.";
        TransferLine."Subc. Prod. Order Line No." := TempTransferLine."Subc. Prod. Order Line No.";
        TransferLine."Subc. Prod. Ord. Comp Line No." := TempTransferLine."Subc. Prod. Ord. Comp Line No.";
        TransferLine."Subc. Routing No." := TempTransferLine."Subc. Routing No.";
        TransferLine."Subc. Routing Reference No." := TempTransferLine."Subc. Routing Reference No.";
        TransferLine."Subc. Work Center No." := TempTransferLine."Subc. Work Center No.";
        TransferLine."Subc. Operation No." := TempTransferLine."Subc. Operation No.";
        TransferLine."Subc. Return Order" := TempTransferLine."Subc. Return Order";
    end;
}