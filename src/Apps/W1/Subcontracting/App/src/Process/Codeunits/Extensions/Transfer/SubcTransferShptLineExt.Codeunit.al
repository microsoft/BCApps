// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001537 "Subc. Transfer Shpt Line Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Line", OnAfterCopyFromTransferLine, '', false, false)]
    local procedure OnAfterCopyFromTransferLine_T5745(var TransferShipmentLine: Record "Transfer Shipment Line"; TransferLine: Record "Transfer Line")
    begin
        TransferShipmentLine."Subcontr. Purch. Order No." := TransferLine."Subcontr. Purch. Order No.";
        TransferShipmentLine."Subcontr. PO Line No." := TransferLine."Subcontr. PO Line No.";
        TransferShipmentLine."Prod. Order No." := TransferLine."Prod. Order No.";
        TransferShipmentLine."Prod. Order Line No." := TransferLine."Prod. Order Line No.";
        TransferShipmentLine."Prod. Order Comp. Line No." := TransferLine."Prod. Order Comp. Line No.";
        TransferShipmentLine."Routing No." := TransferLine."Routing No.";
        TransferShipmentLine."Routing Reference No." := TransferLine."Routing Reference No.";
        TransferShipmentLine."Work Center No." := TransferLine."Work Center No.";
        TransferShipmentLine."Operation No." := TransferLine."Operation No.";
    end;
}