// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001551 "Subc. WhsePostReceipt Ext"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"TransferOrder-Post Receipt", OnAfterTransRcptLineModify, '', false, false)]
    local procedure OnAfterTransRcptLineModify(var TransferReceiptLine: Record "Transfer Receipt Line"; TransferLine: Record "Transfer Line"; CommitIsSuppressed: Boolean)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        SubcontractingManagement.TransferReservationEntryFromPstTransferLineToProdOrderComp(TransferReceiptLine);
    end;
}