// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Task;

using Microsoft.CRM.Interaction;
using Microsoft.CRM.Setup;
using System.Globalization;

table 5196 "To-do Interaction Language"
{
    Caption = 'Task Interaction Language';
    DataClassification = CustomerContent;
    LookupPageID = "Task Interaction Languages";

    fields
    {
        field(1; "To-do No."; Code[20])
        {
            Caption = 'Task No.';
            TableRelation = "To-do";
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            TableRelation = Language;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Attachment No."; Integer)
        {
            Caption = 'Attachment No.';
            TableRelation = Attachment;
        }
    }

    keys
    {
        key(Key1; "To-do No.", "Language Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        RemoveAttachment(false);
    end;

    var
        CreateProcessCanceledMsg: Label 'You have canceled the create process.';
        ReplaceExistingAttachmentQst: Label 'Replace existing attachment?';
        ImportProcessCanceledMsg: Label 'You have canceled the import process.';
        CannotCreateAttachmentsHereErr: Label 'You cannot create attachments here.';

    [Scope('OnPrem')]
    procedure CreateAttachment(PageNotEditable: Boolean): Boolean
    var
        Attachment: Record Attachment;
    begin
        if PageNotEditable then
            Error(CannotCreateAttachmentsHereErr);
        if "Attachment No." <> 0 then begin
            if Attachment.Get("Attachment No.") then
                Attachment.TestField("Read Only", false);
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
        end;

        Error(CreateProcessCanceledMsg);
    end;

    [Scope('OnPrem')]
    procedure OpenAttachment(PageNotEditable: Boolean)
    var
        Attachment: Record Attachment;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenAttachment(Rec, PageNotEditable, IsHandled);
        if IsHandled then
            exit;

        if "Attachment No." = 0 then
            exit;
        Attachment.Get("Attachment No.");
        if PageNotEditable then
            Attachment."Read Only" := true;
        Attachment.OpenAttachment("To-do No." + ' ' + Description, false, "Language Code");
    end;

    [Scope('OnPrem')]
    procedure CopyFromAttachment()
    var
        TaskInteractionLanguage: Record "To-do Interaction Language";
        Attachment: Record Attachment;
        AttachmentManagement: Codeunit AttachmentManagement;
        NewAttachNo: Integer;
    begin
        if Attachment.Get("Attachment No.") then
            Attachment.TestField("Read Only", false);

        if "Attachment No." <> 0 then begin
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
            RemoveAttachment(false);
            "Attachment No." := 0;
            Modify();
            Commit();
        end;

        TaskInteractionLanguage.SetFilter("Attachment No.", '<>%1', 0);
        if PAGE.RunModal(0, TaskInteractionLanguage) = ACTION::LookupOK then begin
            NewAttachNo := AttachmentManagement.InsertAttachment(TaskInteractionLanguage."Attachment No.");
            if NewAttachNo <> 0 then begin
                "Attachment No." := NewAttachNo;
                Modify();
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure ImportAttachment()
    var
        Attachment: Record Attachment;
        TempAttachment: Record Attachment temporary;
        MarketingSetup: Record "Marketing Setup";
        AttachmentManagement: Codeunit AttachmentManagement;
        FileName: Text;
    begin
        if "Attachment No." <> 0 then begin
            if Attachment.Get("Attachment No.") then
                Attachment.TestField("Read Only", false);
            if not Confirm(ReplaceExistingAttachmentQst, false) then
                exit;
        end;

        Clear(TempAttachment);
        if TempAttachment.ImportAttachmentFromClientFile('', true, false) then begin
            if "Attachment No." = 0 then
                Attachment.Get(AttachmentManagement.InsertAttachment(0))
            else
                Attachment.Get("Attachment No.");
            TempAttachment."No." := Attachment."No.";
            TempAttachment."Storage Pointer" := Attachment."Storage Pointer";
            TempAttachment.WizSaveAttachment();
            MarketingSetup.Get();
            if MarketingSetup."Attachment Storage Type" = MarketingSetup."Attachment Storage Type"::"Disk File" then
                if TempAttachment."No." <> 0 then begin
                    FileName := TempAttachment.ConstDiskFileName();
                    if FileName <> '' then
                        Attachment.ExportAttachmentToServerFile(FileName);
                end;

            OnImportAttachmentOnAfterExportAttachmentToServerFile(Rec, Attachment, TempAttachment, MarketingSetup, FileName);

            Attachment."Storage Type" := TempAttachment."Storage Type";
            Attachment."Storage Pointer" := TempAttachment."Storage Pointer";
            Attachment."Attachment File" := TempAttachment."Attachment File";
            Attachment."File Extension" := TempAttachment."File Extension";
            Attachment.Modify();
            "Attachment No." := Attachment."No.";
            Modify();
        end else
            Error(ImportProcessCanceledMsg);
    end;

    [Scope('OnPrem')]
    procedure ExportAttachment()
    var
        Attachment: Record Attachment;
        FileName: Text[1024];
    begin
        if Attachment.Get("Attachment No.") then begin
            OnBeforeExportAttachmentToClientFile(Attachment);
            Attachment.ExportAttachmentToClientFile(FileName);
        end;
    end;

    [Scope('OnPrem')]
    procedure RemoveAttachment(Prompt: Boolean): Boolean
    var
        Attachment: Record Attachment;
    begin
        if Attachment.Get("Attachment No.") then
            if Attachment.RemoveAttachment(Prompt) then begin
                "Attachment No." := 0;
                Modify();
                exit(true);
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeExportAttachmentToClientFile(var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAttachment(var TodoInteractionLanguage: Record "To-do Interaction Language"; var PageNotEditable: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportAttachmentOnAfterExportAttachmentToServerFile(var TodoInteractionLanguage: Record "To-do Interaction Language"; var Attachment: Record Attachment; var TempAttachment: Record Attachment temporary; var MarketingSetup: Record "Marketing Setup"; var FileName: Text)
    begin
    end;
}

