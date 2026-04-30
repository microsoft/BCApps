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
        ItemJournalLine."Prod. Order No." := TransferShipmentLine."Prod. Order No.";
        ItemJournalLine."Prod. Order Line No." := TransferShipmentLine."Prod. Order Line No.";
        ItemJournalLine."Source No." := TransferShipmentHeader."Source ID";
        ItemJournalLine."Source Type" := TransferShipmentHeader."Source Type";
        ItemJournalLine."Prod. Order Comp. Line No." := TransferShipmentLine."Prod. Order Comp. Line No.";
        ItemJournalLine."Subcontr. Purch. Order No." := TransferShipmentLine."Subcontr. Purch. Order No.";
        ItemJournalLine."Subcontr. PO Line No." := TransferShipmentLine."Subcontr. PO Line No.";
        ItemJournalLine."Subc. Operation No." := TransferLine."Operation No."
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Shipment", OnBeforeInsertTransShptLine, '', false, false)]
    local procedure OnBeforeInsertTransShptLine(var TransShptLine: Record "Transfer Shipment Line"; TransLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    begin
        TransShptLine."Subcontr. Purch. Order No." := TransLine."Subcontr. Purch. Order No.";
        TransShptLine."Subcontr. PO Line No." := TransLine."Subcontr. PO Line No.";
        TransShptLine."Prod. Order No." := TransLine."Prod. Order No.";
        TransShptLine."Prod. Order Line No." := TransLine."Prod. Order Line No.";
        TransShptLine."Prod. Order Comp. Line No." := TransLine."Prod. Order Comp. Line No.";
        TransShptLine."Return Order" := TransLine."Return Order";
        TransShptLine."Routing No." := TransLine."Routing No.";
        TransShptLine."Routing Reference No." := TransLine."Routing Reference No.";
    end;
}