// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory.Transfer;

using Microsoft.Inventory.Transfer;

codeunit 20413 "Qlty. Transfer Integration"
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Shipment Header", 'OnAfterCopyFromTransferHeader', '', true, true)]
    local procedure HandleOnAfterCopyFromTransferHeader(var TransferShipmentHeader: Record "Transfer Shipment Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferShipmentHeader."Qlty. Inspection Test No." := TransferHeader."Qlty. Inspection Test No.";
        TransferShipmentHeader."Qlty. Inspection Retest No." := TransferHeader."Qlty. Inspection Retest No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', true, true)]
    local procedure HandleOnBeforeTransRcptHeaderInsert(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferReceiptHeader."Qlty. Inspection Test No." := TransferHeader."Qlty. Inspection Test No.";
        TransferReceiptHeader."Qlty. Inspection Retest No." := TransferHeader."Qlty. Inspection Retest No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", 'OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert', '', true, true)]
    local procedure HandleOnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert(var DirectTransHeader: Record "Direct Trans. Header"; TransferHeader: Record "Transfer Header")
    begin
        DirectTransHeader."Qlty. Inspection Test No." := TransferHeader."Qlty. Inspection Test No.";
        DirectTransHeader."Qlty. Inspection Retest No." := TransferHeader."Qlty. Inspection Retest No.";
    end;
}
