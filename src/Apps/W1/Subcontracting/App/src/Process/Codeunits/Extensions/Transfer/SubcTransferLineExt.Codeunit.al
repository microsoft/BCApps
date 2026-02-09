// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001544 "Subc. Transfer Line Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterGetTransHeader, '', false, false)]
    local procedure OnAfterGetTransHeader(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
        TransferLine."Return Order" := TransferHeader."Return Order";
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Line", OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteEvent(var Rec: Record "Transfer Line"; RunTrigger: Boolean)
    var
        SubcontractingManagement: Codeunit "Subcontracting Management";
    begin
        if not Rec.IsTemporary() then
            if RunTrigger then
                SubcontractingManagement.UpdateLocationCodeInProdOrderCompAfterDeleteTransferLine(Rec);
    end;
}