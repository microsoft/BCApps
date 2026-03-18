// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.BOM;

using Microsoft.Inventory.Item;

codeunit 52 "BOM-BOM Component"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Component", 'OnAfterInsertEvent', '', false, false)]
    local procedure UpdateParentItemReplenishmentSystemOnAfterInsertBOMComponent(var Rec: Record "BOM Component"; RunTrigger: Boolean)
    begin
        TryUpdateParentItemReplenishmentSystem(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Component", 'OnAfterDeleteEvent', '', false, false)]
    local procedure UpdateParentItemReplenishmentSystemOnAfterDeleteBOMComponent(var Rec: Record "BOM Component"; RunTrigger: Boolean)
    begin
        if RunTrigger then
            TryUpdateParentItemReplenishmentSystem(Rec);
    end;

    [EventSubscriber(ObjectType::Table, Database::"BOM Component", 'OnAfterRenameEvent', '', false, false)]
    local procedure UpdateParentItemReplenishmentSystemOnAfterRenameBOMComponent(var Rec: Record "BOM Component"; var xRec: Record "BOM Component"; RunTrigger: Boolean)
    begin
        if (Rec."Parent Item No." <> xRec."Parent Item No.") and RunTrigger then begin
            TryUpdateParentItemReplenishmentSystem(Rec);
            TryUpdateParentItemReplenishmentSystem(xRec);
        end
    end;

    local procedure TryUpdateParentItemReplenishmentSystem(var BOMComponent: Record "BOM Component")
    var
        Item: Record Item;
    begin
        if BOMComponent.IsTemporary then
            exit;
        if Item.Get(BOMComponent."Parent Item No.") then
            if Item.UpdateReplenishmentSystem() then
                Item.Modify(true);
    end;
}

