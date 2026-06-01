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
        TransferShipmentLine."Subc. Purch. Order No." := TransferLine."Subc. Purch. Order No.";
        TransferShipmentLine."Subc. Purch. Order Line No." := TransferLine."Subc. Purch. Order Line No.";
        TransferShipmentLine."Subc. Prod. Order No." := TransferLine."Subc. Prod. Order No.";
        TransferShipmentLine."Subc. Prod. Order Line No." := TransferLine."Subc. Prod. Order Line No.";
        TransferShipmentLine."Subc. Prod. Ord. Comp Line No." := TransferLine."Subc. Prod. Ord. Comp Line No.";
        TransferShipmentLine."Subc. Routing No." := TransferLine."Subc. Routing No.";
        TransferShipmentLine."Subc. Routing Reference No." := TransferLine."Subc. Routing Reference No.";
        TransferShipmentLine."Subc. Work Center No." := TransferLine."Subc. Work Center No.";
        TransferShipmentLine."Subc. Operation No." := TransferLine."Subc. Operation No.";
    end;
}