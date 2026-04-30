// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Manufacturing.Document;

codeunit 99001540 "Subc. TransOrderPostRcpt Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnBeforePostItemJournalLine, '', false, false)]
    local procedure OnBeforePostItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferReceiptHeader: Record "Transfer Receipt Header"; TransferReceiptLine: Record "Transfer Receipt Line"; CommitIsSuppressed: Boolean)
    begin
        ItemJournalLine."Prod. Order No." := TransferReceiptLine."Prod. Order No.";
        ItemJournalLine."Prod. Order Line No." := TransferReceiptLine."Prod. Order Line No.";
        ItemJournalLine."Source No." := TransferReceiptHeader."Source ID";
        ItemJournalLine."Source Type" := TransferReceiptHeader."Source Type";
        ItemJournalLine."Prod. Order Comp. Line No." := TransferReceiptLine."Prod. Order Comp. Line No.";
        ItemJournalLine."Subcontr. Purch. Order No." := TransferReceiptLine."Subcontr. Purch. Order No.";
        ItemJournalLine."Subcontr. PO Line No." := TransferReceiptLine."Subcontr. PO Line No.";
        ItemJournalLine."Subc. Operation No." := TransferReceiptLine."Operation No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnBeforeInsertTransRcptLine, '', false, false)]
    local procedure OnBeforeInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
        TransRcptLine."Subcontr. Purch. Order No." := TransLine."Subcontr. Purch. Order No.";
        TransRcptLine."Subcontr. PO Line No." := TransLine."Subcontr. PO Line No.";
        TransRcptLine."Prod. Order No." := TransLine."Prod. Order No.";
        TransRcptLine."Prod. Order Line No." := TransLine."Prod. Order Line No.";
        TransRcptLine."Prod. Order Comp. Line No." := TransLine."Prod. Order Comp. Line No.";
        TransRcptLine."Return Order" := TransLine."Return Order";
        TransRcptLine."Routing No." := TransLine."Routing No.";
        TransRcptLine."Routing Reference No." := TransLine."Routing Reference No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnCheckTransLine, '', false, false)]
    local procedure OnCheckTransLine(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if (TransferLine."Prod. Order No." = '') or (TransferLine."Prod. Order Line No." = 0) or (TransferLine."Prod. Order Comp. Line No." = 0) then
            exit;

        if not ProdOrderComponent.Get(ProdOrderComponent.Status::Released, TransferLine."Prod. Order No.", TransferLine."Prod. Order Line No.", TransferLine."Prod. Order Comp. Line No.") then
            exit;

        if Location.Code <> ProdOrderComponent."Location Code" then begin
            ProdOrderComponent.Validate("Location Code", Location.Code);
            ProdOrderComponent.Modify();
        end;
    end;
}