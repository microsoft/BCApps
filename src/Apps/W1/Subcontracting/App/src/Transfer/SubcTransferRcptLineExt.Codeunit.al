// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001538 "Subc. Transfer Rcpt Line Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Receipt Line", OnAfterCopyFromTransferLine, '', false, false)]
    local procedure OnAfterCopyFromTransferLine_T5745(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line")
    begin
        TransferReceiptLine."Subcontr. Purch. Order No." := TransferLine."Subcontr. Purch. Order No.";
        TransferReceiptLine."Subcontr. PO Line No." := TransferLine."Subcontr. PO Line No.";
        TransferReceiptLine."Prod. Order No." := TransferLine."Prod. Order No.";
        TransferReceiptLine."Prod. Order Line No." := TransferLine."Prod. Order Line No.";
        TransferReceiptLine."Prod. Order Comp. Line No." := TransferLine."Prod. Order Comp. Line No.";
        TransferReceiptLine."Routing No." := TransferLine."Routing No.";
        TransferReceiptLine."Routing Reference No." := TransferLine."Routing Reference No.";
        TransferReceiptLine."Work Center No." := TransferLine."Work Center No.";
        TransferReceiptLine."Operation No." := TransferLine."Operation No.";
    end;
}