// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Journal;

codeunit 99001510 "Sub. ItemJnlCheckExt"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Mfg. Item Jnl. Check Line", OnBeforeCheckSubcontracting, '', false, false)]
    local procedure OnBeforeCheckSubcontracting(var ItemJournalLine: Record "Item Journal Line"; var IsHandled: Boolean)
    var
        SubcontractingMgmt: Codeunit "Subcontracting Management";
    begin
        if not IsHandled then
            IsHandled := SubcontractingMgmt.HandleCommonWorkCenter(ItemJournalLine);
    end;
}