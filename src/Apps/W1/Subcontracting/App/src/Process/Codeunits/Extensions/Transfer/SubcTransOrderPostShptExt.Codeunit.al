// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Transfer;

codeunit 99001539 "Subc. TransOrderPostShpt Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnAfterCreateItemJnlLine, '', false, false)]
    local procedure OnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; TransferLine: Record "Transfer Line"; TransferShipmentHeader: Record "Transfer Shipment Header"; TransferShipmentLine: Record "Transfer Shipment Line")
    begin
        ItemJournalLine."Subc. Prod. Order No." := TransferShipmentLine."Subc. Prod. Order No.";
        ItemJournalLine."Subc. Prod. Order Line No." := TransferShipmentLine."Subc. Prod. Order Line No.";
        ItemJournalLine."Source No." := TransferShipmentHeader."Source ID";
        ItemJournalLine."Source Type" := TransferShipmentHeader."Source Type";
        ItemJournalLine."Prod. Order Comp. Line No." := TransferShipmentLine."Subc. Prod. Ord. Comp Line No.";
        ItemJournalLine."Subc. Purch. Order No." := TransferShipmentLine."Subc. Purch. Order No.";
        ItemJournalLine."Subc. Purch. Order Line No." := TransferShipmentLine."Subc. Purch. Order Line No.";
        ItemJournalLine."Subc. Operation No." := TransferLine."Subc. Operation No."
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnBeforeInsertTransShptLine, '', false, false)]
    local procedure OnBeforeInsertTransShptLine(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
        TransShptLine."Subc. Purch. Order No." := TransLine."Subc. Purch. Order No.";
        TransShptLine."Subc. Purch. Order Line No." := TransLine."Subc. Purch. Order Line No.";
        TransShptLine."Subc. Prod. Order No." := TransLine."Subc. Prod. Order No.";
        TransShptLine."Subc. Prod. Order Line No." := TransLine."Subc. Prod. Order Line No.";
        TransShptLine."Subc. Prod. Ord. Comp Line No." := TransLine."Subc. Prod. Ord. Comp Line No.";
        TransShptLine."Subc. Return Order" := TransLine."Subc. Return Order";
        TransShptLine."Subc. Routing No." := TransLine."Subc. Routing No.";
        TransShptLine."Subc. Routing Reference No." := TransLine."Subc. Routing Reference No.";
    end;
}