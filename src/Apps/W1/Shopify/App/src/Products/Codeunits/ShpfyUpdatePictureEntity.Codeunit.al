// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Integration.Entity;
using Microsoft.Inventory.Item;

/// <summary>
/// Codeunit Shpfy Update Picture Entity (ID 30412).
/// </summary>
codeunit 30455 "Shpfy Update Picture Entity"
{
    [EventSubscriber(ObjectType::Table, Database::"Picture Entity", OnGetDefaultMediaDescriptionElseCase, '', false, false)]
    local procedure OnGetDefaultMediaDescriptionElseCase(ParentRecordRef: RecordRef; var MediaDescription: Text; var IsHandled: Boolean)
    var
        ItemVariant: Record "Item Variant";
        PictureEntity: Record "Picture Entity";
        MediaExtensionWithNumFullNameTxt: Label '%1 %2 %3.%4', Comment = '%1 - Item No., %2 - Item Variant Code, %3 - Item Variant Description, %4 - File Extension', Locked = true;
    begin
        if ParentRecordRef.Number = Database::"Item Variant" then begin
            ParentRecordRef.SetTable(ItemVariant);
            MediaDescription := StrSubstNo(MediaExtensionWithNumFullNameTxt, ItemVariant."Item No.", ItemVariant.Code, ItemVariant.Description, PictureEntity.GetDefaultExtension());
            IsHandled := true;
        end;
    end;
}
