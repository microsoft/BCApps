// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Setup;
using Microsoft.Foundation.Reporting;
using System.Environment;
using System.Globalization;
using System.Integration.Word;
using System.IO;
using System.Reflection;
using System.Utilities;

table 5103 "Interaction Tmpl. Language"
{
    Caption = 'Interaction Tmpl. Language';
    DataClassification = CustomerContent;
    LookupPageID = "Interact. Tmpl. Languages";

    fields
    {
        field(1; "Interaction Template Code"; Code[10])
        {
            Caption = 'Interaction Template Code';
            Editable = false;
            TableRelation = "Interaction Template";
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
        }
        field(5; "Custom Layout Code"; Code[20])
        {
            Caption = 'Custom Layout Code';
            TableRelation = "Custom Report Layout" where("Report ID" = const(Report::"Email Merge"));

            trigger OnValidate()
            begin
                if Rec."Custom Layout Code" <> '' then
                    Rec.Validate("Report Layout Name", '');
                CalcFields("Custom Layout Description");
            end;
        }
        field(6; "Custom Layout Description"; Text[250])
        {
            CalcFormula = lookup("Custom Report Layout".Description where(Code = field("Custom Layout Code")));
            Caption = 'Custom Layout Description';
            Editable = false;
            FieldClass = FlowField;
        }
        field(7; "Word Template Code"; Code[30])
        {
            DataClassification = CustomerContent;
            TableRelation = "Word Template".Code where("Language Code" = field("Language Code"), "Table ID" = const(Database::"Interaction Merge Data")); // Only Interaction Merge Data word templates with same language code are allowed
        }
        field(8; "Report Layout Name"; Text[250])
        {
            Caption = 'Report Layout Name';
            TableRelation = "Report Layout List".Name where("Report ID" = const(Report::"Email Merge"));

            trigger OnLookup()
            var
                ReportLayoutList: Record "Report Layout List";
                ReportManagement: Codeunit ReportManagement;
                Handled: Boolean;
            begin
                ReportLayoutList.SetRange("Report ID", Report::"Email Merge");
                ReportManagement.OnSelectReportLayout(ReportLayoutList, Handled);
                if not Handled then
                    exit;
                "Report Layout Name" := ReportLayoutList.Name;
                "Report Layout AppID" := ReportLayoutList."Application ID";
            end;

            trigger OnValidate()
            var
                ReportLayoutList: Record "Report Layout List";
            begin
                if "Report Layout Name" <> '' then begin
                    ReportLayoutList.SetRange(Name, "Report Layout Name");
                    ReportLayoutList.SetRange("Report ID", Report::"Email Merge");

                    if not IsNullGuid("Report Layout AppID") then
                        ReportLayoutList.SetRange("Application ID", "Report Layout AppID");
                    if not ReportLayoutList.FindFirst() then begin
                        ReportLayoutList.SetRange("Application ID");
                        ReportLayoutList.FindFirst();
                    end;
                    Rec."Report Layout AppID" := ReportLayoutList."Application ID";
                end else
                    Clear(Rec."Report Layout AppID");
            end;
        }
        field(9; "Report Layout AppID"; Guid)
        {
            Caption = 'Email Body Layout AppID';
            TableRelation = "Report Layout List"."Application ID" where("Report ID" = const(Report::"Email Merge"));
        }
    }

    keys
    {
        key(Key1; "Interaction Template Code", "Language Code")
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

    trigger OnRename()
    var
        InteractionTemplate: Record "Interaction Template";
    begin
        InteractionTemplate.Get("Interaction Template Code");
        if xRec."Language Code" <> "Language Code" then
            if InteractionTemplate."Language Code (Default)" = xRec."Language Code" then begin
                InteractionTemplate."Language Code (Default)" := "Language Code";
                InteractionTemplate.Modify();
            end;
    end;

    var
        AttachmentRecord: Record Attachment;
        ClientTypeManagement: Codeunit "Client Type Management";
#pragma warning disable AA0074
        Text000: Label 'You have canceled the create process.';
        Text001: Label 'Replace existing attachment?';
        Text002: Label 'You have canceled the import process.';
        Text005: Label 'Export Attachment';
#pragma warning restore AA0074

    procedure CreateAttachment()
    var
        Attachment: Record Attachment;
        InteractTmplLanguage: Record "Interaction Tmpl. Language";
        NewAttachNo: Integer;
        IsHandled: Boolean;
    begin
        if "Attachment No." <> 0 then begin
            if Attachment.Get("Attachment No.") then
                Attachment.TestField("Read Only", false);
            if not Confirm(Text001, false) then
                exit;
        end;

        IsHandled := false;
        OnCreateAttachmentOnAfterInitialChecks(Rec, NewAttachNo, IsHandled);
        if IsHandled then
            exit;

        if ("Custom Layout Code" = '') and ("Report Layout Name" = '') then begin
            if ClientTypeManagement.GetCurrentClientType() in [CLIENTTYPE::Web, CLIENTTYPE::Tablet, CLIENTTYPE::Phone, CLIENTTYPE::Desktop] then
                if Attachment.ImportAttachmentFromClientFile('', false, false) then
                    NewAttachNo := Attachment."No.";
        end else
            NewAttachNo := CreateHTMLCustomLayoutAttachment();

        if NewAttachNo <> 0 then begin
            if "Attachment No." <> 0 then
                RemoveAttachment(false);
            "Attachment No." := NewAttachNo;
            if InteractTmplLanguage.Get("Interaction Template Code", "Language Code") then
                Modify()
            else
                Insert();
        end else
            Error(Text000);
    end;

    procedure CreateHTMLCustomLayoutAttachment(): Integer
    var
        Attachment: Record Attachment;
    begin
        OnBeforeCreateHTMLCustomLayoutAttachment();

        Attachment.Init();
        Attachment."Storage Type" := Attachment."Storage Type"::Embedded;
        Attachment."File Extension" := 'HTML';
        Attachment.Insert(true);
        if "Custom Layout Code" <> '' then
            Attachment.WriteHTMLCustomLayoutAttachment('', "Custom Layout Code")
        else
            Attachment.WriteHTMLCustomLayoutAttachment('', "Report Layout Name");
        exit(Attachment."No.");
    end;

    procedure OpenAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." = 0 then
            exit;
        OnOpenAttachmentOnBeforeGetAttachment(Rec, Attachment);
        Attachment.Get("Attachment No.");
        OnBeforeOpenAttachment(Rec, Attachment);
        Attachment.OpenAttachment("Interaction Template Code" + ' ' + Description, false, "Language Code");
    end;

    procedure CopyFromAttachment()
    var
        InteractTmplLanguage: Record "Interaction Tmpl. Language";
        Attachment: Record Attachment;
        AttachmentManagement: Codeunit AttachmentManagement;
        NewAttachNo: Integer;
    begin
        if Attachment.Get("Attachment No.") then
            Attachment.TestField("Read Only", false);

        if "Attachment No." <> 0 then begin
            if not Confirm(Text001, false) then
                exit;
            RemoveAttachment(false);
            "Attachment No." := 0;
            Modify();
            Commit();
        end;

        InteractTmplLanguage.SetFilter("Attachment No.", '<>%1', 0);
        if PAGE.RunModal(0, InteractTmplLanguage) = ACTION::LookupOK then begin
            NewAttachNo := AttachmentManagement.InsertAttachment(InteractTmplLanguage."Attachment No.");
            if NewAttachNo <> 0 then begin
                "Attachment No." := NewAttachNo;
                Modify();
            end;
        end;
    end;

    procedure ImportAttachment()
    var
        Attachment: Record Attachment;
    begin
        if "Attachment No." <> 0 then begin
            if Attachment.Get("Attachment No.") then
                Attachment.TestField("Read Only", false);
            if not Confirm(Text001, false) then
                exit;
        end;

        if Attachment.ImportAttachmentFromClientFile('', false, false) then begin
            "Attachment No." := Attachment."No.";
            OnImportAttachmentOnBeforeModify(Attachment);
            Modify();
        end else
            Error(Text002);
    end;

    procedure ExportAttachment()
    var
        MarketingSetup: Record "Marketing Setup";
        TempBlob: Codeunit "Temp Blob";
        FileMgt: Codeunit "File Management";
        FileName: Text;
        FileFilter: Text;
        ExportToFile: Text;
    begin
        MarketingSetup.Get();
        ExportToFile := '';
        if not AttachmentRecord.Get("Attachment No.") then
            exit;

        case AttachmentRecord."Storage Type" of
            AttachmentRecord."Storage Type"::Embedded:
                begin
                    AttachmentRecord.CalcFields("Attachment File");
                    if AttachmentRecord."Attachment File".HasValue() then begin
                        FileName := "Interaction Template Code" + '.' + AttachmentRecord."File Extension";
                        TempBlob.FromRecord(AttachmentRecord, AttachmentRecord.FieldNo("Attachment File"));
                        FileMgt.BLOBExport(TempBlob, FileName, true);
                    end;
                end;
            AttachmentRecord."Storage Type"::"Disk File":
                begin
                    if MarketingSetup."Attachment Storage Type" = MarketingSetup."Attachment Storage Type"::"Disk File" then
                        MarketingSetup.TestField("Attachment Storage Location");
                    FileFilter :=
                      UpperCase(AttachmentRecord."File Extension") +
                      ' (*.' + AttachmentRecord."File Extension" + ')|*.' + AttachmentRecord."File Extension";
                    ExportToFile := "Interaction Template Code" + '.' + AttachmentRecord."File Extension";
                    FileMgt.DownloadHandler(
                      AttachmentRecord."Storage Pointer" + '\' + Format(AttachmentRecord."No.") + '.' + AttachmentRecord."File Extension",
                      Text005, '', FileFilter, ExportToFile);
                end;
            else
                OnExportAttachmentOnStorageTypeCaseElse(Rec, xRec, AttachmentRecord, MarketingSetup, ExportToFile, FileFilter, FileName);
        end;
    end;

    procedure RemoveAttachment(Prompt: Boolean)
    var
        Attachment: Record Attachment;
    begin
        if Attachment.Get("Attachment No.") then
            if Attachment.RemoveAttachment(Prompt) then begin
                "Attachment No." := 0;
                Modify();
            end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnImportAttachmentOnBeforeModify(var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateHTMLCustomLayoutAttachment()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateAttachmentOnAfterInitialChecks(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; var NewAttachNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenAttachmentOnBeforeGetAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenAttachment(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; var Attachment: Record Attachment)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnExportAttachmentOnStorageTypeCaseElse(var InteractionTmplLanguage: Record "Interaction Tmpl. Language"; xInteractionTmplLanguage: Record "Interaction Tmpl. Language"; var AttachmentRecord: Record Attachment; var MarketingSetup: Record "Marketing Setup"; var ExportToFile: Text; var FileFilter: Text; var FileName: Text)
    begin
    end;
}

