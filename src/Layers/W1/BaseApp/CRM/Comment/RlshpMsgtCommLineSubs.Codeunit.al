// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Comment;

using Microsoft.CRM.Contact;

codeunit 5066 "Rlshp. Msgt. Comm. Line Subs"
{

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Table, Database::"Rlshp. Mgt. Comment Line", 'OnAfterInsertEvent', '', false, false)]
    local procedure SetContactDateTimeModifiedOnAfterCommentLineInsert(var Rec: Record "Rlshp. Mgt. Comment Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        if RunTrigger then
            TouchContact(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Rlshp. Mgt. Comment Line", 'OnAfterModifyEvent', '', false, false)]
    local procedure SetContactDateTimeModifiedOnAfterCommentLineModify(var Rec: Record "Rlshp. Mgt. Comment Line"; var xRec: Record "Rlshp. Mgt. Comment Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        if RunTrigger then
            TouchContact(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Rlshp. Mgt. Comment Line", 'OnAfterDeleteEvent', '', false, false)]
    local procedure SetContactDateTimeModifiedOnAfterCommentLineDelete(var Rec: Record "Rlshp. Mgt. Comment Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary then
            exit;
        if RunTrigger then
            TouchContact(Rec."No.");
    end;

    [EventSubscriber(ObjectType::Table, Database::"Rlshp. Mgt. Comment Line", 'OnAfterRenameEvent', '', false, false)]
    local procedure SetContactDateTimeModifiedOnAfterCommentLineRename(var Rec: Record "Rlshp. Mgt. Comment Line"; var xRec: Record "Rlshp. Mgt. Comment Line"; RunTrigger: Boolean)
    begin
        if Rec.IsTemporary() then
            exit;

        if xRec."No." = Rec."No." then
            TouchContact(Rec."No.")
        else begin
            TouchContact(Rec."No.");
            TouchContact(xRec."No.");
        end;
    end;

    local procedure TouchContact(ContactNo: Code[20])
    var
        Cont: Record Contact;
        RlshpMgtCommentLine: Record "Rlshp. Mgt. Comment Line";
    begin
        if RlshpMgtCommentLine."Table Name" = RlshpMgtCommentLine."Table Name"::Contact then
            Cont.TouchContact(ContactNo);
    end;
}

