// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001548 "Subc. DirectTransferLine Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Direct Trans. Line", OnAfterCopyFromTransferLine, '', false, false)]
    local procedure OnAfterCopyFromTransferLine_T5745(var DirectTransLine: Record "Direct Trans. Line"; TransferLine: Record "Transfer Line")
    begin
        DirectTransLine."Subcontr. Purch. Order No." := TransferLine."Subc. Purch. Order No.";
        DirectTransLine."Subcontr. PO Line No." := TransferLine."Subc. Purch. Order Line No.";
        DirectTransLine."Prod. Order No." := TransferLine."Subc. Prod. Order No.";
        DirectTransLine."Prod. Order Line No." := TransferLine."Subc. Prod. Order Line No.";
        DirectTransLine."Prod. Order Comp. Line No." := TransferLine."Subc. Prod. Ord. Comp Line No.";
        DirectTransLine."Routing No." := TransferLine."Subc. Routing No.";
        DirectTransLine."Routing Reference No." := TransferLine."Subc. Routing Reference No.";
        DirectTransLine."Work Center No." := TransferLine."Subc. Work Center No.";
        DirectTransLine."Operation No." := TransferLine."Subc. Operation No.";
    end;
}