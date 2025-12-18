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
        TransferShipmentHeader."Qlty. Inspection No." := TransferHeader."Qlty. Inspection No.";
        TransferShipmentHeader."Qlty. Re-inspection No." := TransferHeader."Qlty. Re-inspection No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", 'OnBeforeTransRcptHeaderInsert', '', true, true)]
    local procedure HandleOnBeforeTransRcptHeaderInsert(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferReceiptHeader."Qlty. Inspection No." := TransferHeader."Qlty. Inspection No.";
        TransferReceiptHeader."Qlty. Re-inspection No." := TransferHeader."Qlty. Re-inspection No.";
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Transfer", 'OnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert', '', true, true)]
    local procedure HandleOnInsertDirectTransHeaderOnBeforeDirectTransHeaderInsert(var DirectTransHeader: Record "Direct Trans. Header"; TransferHeader: Record "Transfer Header")
    begin
        DirectTransHeader."Qlty. Inspection No." := TransferHeader."Qlty. Inspection No.";
        DirectTransHeader."Qlty. Re-inspection No." := TransferHeader."Qlty. Re-inspection No.";
    end;
}
