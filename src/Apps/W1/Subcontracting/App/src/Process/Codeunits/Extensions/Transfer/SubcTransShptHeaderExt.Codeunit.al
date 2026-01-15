// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001543 "Subc. Trans Shpt Header Ext"
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", OnAfterCopyFromTransferHeader, '', false, false)]
    local procedure OnAfterCopyFromTransferHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferShipmentHeader."Source Type" := TransferHeader."Source Type";
        TransferShipmentHeader."Source Subtype" := TransferHeader."Source Subtype";
        TransferShipmentHeader."Source ID" := TransferHeader."Source ID";
        TransferShipmentHeader."Source Ref. No." := TransferHeader."Source Ref. No.";
        TransferShipmentHeader."Return Order" := TransferHeader."Return Order";
        TransferShipmentHeader."Subcontr. Purch. Order No." := TransferHeader."Subcontr. Purch. Order No.";
        TransferShipmentHeader."Subcontr. PO Line No." := TransferHeader."Subcontr. PO Line No.";
    end;
}