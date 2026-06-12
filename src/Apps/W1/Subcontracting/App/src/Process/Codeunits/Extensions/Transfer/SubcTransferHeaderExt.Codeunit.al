// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Transfer;

codeunit 99001507 "Subc. Transfer Header Ext."
{
    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", OnBeforeValidateEvent, "Transfer-from Code", false, false)]
    local procedure OnBeforeValidateTransferFromCode(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
        if Rec.IsTemporary() then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Transfer-from Code") then
            exit;

        if Rec."Transfer-from Code" = xRec."Transfer-from Code" then
            exit;

        SubcTransferManagement.CheckSubcTransferHeaderCanBeModified(Rec, Rec.FieldCaption("Transfer-from Code"));
    end;

    [EventSubscriber(ObjectType::Table, Database::"Transfer Header", OnBeforeValidateEvent, "Transfer-to Code", false, false)]
    local procedure OnBeforeValidateTransferToCode(var Rec: Record "Transfer Header"; var xRec: Record "Transfer Header"; CurrFieldNo: Integer)
    var
        SubcTransferManagement: Codeunit "Subc. Transfer Management";
    begin
        if Rec.IsTemporary() then
            exit;

        if CurrFieldNo <> Rec.FieldNo("Transfer-to Code") then
            exit;

        if Rec."Transfer-to Code" = xRec."Transfer-to Code" then
            exit;

        SubcTransferManagement.CheckSubcTransferHeaderCanBeModified(Rec, Rec.FieldCaption("Transfer-to Code"));
    end;
}
