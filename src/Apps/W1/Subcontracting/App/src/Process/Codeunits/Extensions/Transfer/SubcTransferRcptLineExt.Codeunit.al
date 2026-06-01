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
        TransferReceiptLine."Subc. Purch. Order No." := TransferLine."Subc. Purch. Order No.";
        TransferReceiptLine."Subc. Purch. Order Line No." := TransferLine."Subc. Purch. Order Line No.";
        TransferReceiptLine."Subc. Prod. Order No." := TransferLine."Subc. Prod. Order No.";
        TransferReceiptLine."Subc. Prod. Order Line No." := TransferLine."Subc. Prod. Order Line No.";
        TransferReceiptLine."Subc. Prod. Ord. Comp Line No." := TransferLine."Subc. Prod. Ord. Comp Line No.";
        TransferReceiptLine."Subc. Routing No." := TransferLine."Subc. Routing No.";
        TransferReceiptLine."Subc. Routing Reference No." := TransferLine."Subc. Routing Reference No.";
        TransferReceiptLine."Subc. Work Center No." := TransferLine."Subc. Work Center No.";
        TransferReceiptLine."Subc. Operation No." := TransferLine."Subc. Operation No.";
    end;
}