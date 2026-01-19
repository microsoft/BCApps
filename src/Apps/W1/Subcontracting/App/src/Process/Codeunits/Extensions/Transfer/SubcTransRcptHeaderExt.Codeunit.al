// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001542 "Subc. Trans Rcpt Header Ext"
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Header", OnAfterCopyFromTransferHeader, '', false, false)]
    local procedure OnAfterCopyFromTransferHeader(var TransferReceiptHeader: Record "Transfer Receipt Header"; TransferHeader: Record "Transfer Header")
    begin
        TransferReceiptHeader."Source Type" := TransferHeader."Source Type";
        TransferReceiptHeader."Source Subtype" := TransferHeader."Source Subtype";
        TransferReceiptHeader."Source ID" := TransferHeader."Source ID";
        TransferReceiptHeader."Source Ref. No." := TransferHeader."Source Ref. No.";
        TransferReceiptHeader."Return Order" := TransferHeader."Return Order";
        TransferReceiptHeader."Subcontr. Purch. Order No." := TransferHeader."Subcontr. Purch. Order No.";
        TransferReceiptHeader."Subcontr. PO Line No." := TransferHeader."Subcontr. PO Line No.";
    end;
}