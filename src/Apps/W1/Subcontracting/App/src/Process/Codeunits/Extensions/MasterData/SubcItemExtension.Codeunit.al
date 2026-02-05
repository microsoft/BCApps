// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;

codeunit 99001532 "Subc. Item Extension"
{
    [EventSubscriber(ObjectType::Table, Database::Item, OnAfterDeleteEvent, '', false, false)]
    local procedure OnAfterDeleteItem(var Rec: Record Item; RunTrigger: Boolean)
    begin
        DeleteRelatedSubcontractorPrices(Rec, RunTrigger);
    end;

    local procedure DeleteRelatedSubcontractorPrices(var Item: Record Item; RunTrigger: Boolean)
    var
        SubcontractorPrice: Record "Subcontractor Price";
    begin
        if not Item.IsTemporary() then
            if RunTrigger then begin
                SubcontractorPrice.SetCurrentKey("Item No.");
                SubcontractorPrice.SetRange("Item No.", Item."No.");
                if not SubcontractorPrice.IsEmpty() then
                    SubcontractorPrice.DeleteAll(true);
            end;
    end;
}
