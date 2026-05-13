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
        ItemJournalLine."Subc. Prod. Order No." := TransferReceiptLine."Subc. Prod. Order No.";
        ItemJournalLine."Subc. Prod. Order Line No." := TransferReceiptLine."Subc. Prod. Order Line No.";
        ItemJournalLine."Source No." := TransferReceiptHeader."Source ID";
        ItemJournalLine."Source Type" := TransferReceiptHeader."Subc. Source Type";
        ItemJournalLine."Prod. Order Comp. Line No." := TransferReceiptLine."Subc. Prod. Ord. Comp Line No.";
        ItemJournalLine."Subc. Purch. Order No." := TransferReceiptLine."Subc. Purch. Order No.";
        ItemJournalLine."Subc. Purch. Order Line No." := TransferReceiptLine."Subc. Purch. Order Line No.";
        ItemJournalLine."Subc. Operation No." := TransferReceiptLine."Subc. Operation No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnBeforeInsertTransRcptLine, '', false, false)]
    local procedure OnBeforeInsertTransRcptLine(var TransRcptLine: Record "Transfer Receipt Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
        TransRcptLine."Subc. Purch. Order No." := TransLine."Subc. Purch. Order No.";
        TransRcptLine."Subc. Purch. Order Line No." := TransLine."Subc. Purch. Order Line No.";
        TransRcptLine."Subc. Prod. Order No." := TransLine."Subc. Prod. Order No.";
        TransRcptLine."Subc. Prod. Order Line No." := TransLine."Subc. Prod. Order Line No.";
        TransRcptLine."Subc. Prod. Ord. Comp Line No." := TransLine."Subc. Prod. Ord. Comp Line No.";
        TransRcptLine."Subc. Return Order" := TransLine."Subc. Return Order";
        TransRcptLine."Subc. Routing No." := TransLine."Subc. Routing No.";
        TransRcptLine."Subc. Routing Reference No." := TransLine."Subc. Routing Reference No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnCheckTransLine, '', false, false)]
    local procedure OnCheckTransLine(TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; Location: Record Location; WhseReceive: Boolean)
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        if (TransferLine."Subc. Prod. Order No." = '') or (TransferLine."Subc. Prod. Order Line No." = 0) or (TransferLine."Subc. Prod. Ord. Comp Line No." = 0) then
            exit;

        if not ProdOrderComponent.Get(ProdOrderComponent.Status::Released, TransferLine."Subc. Prod. Order No.", TransferLine."Subc. Prod. Order Line No.", TransferLine."Subc. Prod. Ord. Comp Line No.") then
            exit;

        if Location.Code <> ProdOrderComponent."Location Code" then begin
            ProdOrderComponent.Validate("Location Code", Location.Code);
            ProdOrderComponent.Modify();
        end;
    end;
}