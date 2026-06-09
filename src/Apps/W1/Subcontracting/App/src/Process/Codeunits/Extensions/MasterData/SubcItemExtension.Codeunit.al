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
    var
        SubcontractorPrice: Record "Subcontractor Price";
#if not CLEAN29
        SubcFeatureFlagHandler: Codeunit "Subc. Feature Flag Handler";
#endif
    begin
#if not CLEAN29
        if not SubcFeatureFlagHandler.IsSubcontractingEnabled() then
            exit;

#endif
        if Rec.IsTemporary() then
            exit;

        if not RunTrigger then
            exit;

        SubcontractorPrice.DeletePricesForItem(Rec."No.");
    end;
}
