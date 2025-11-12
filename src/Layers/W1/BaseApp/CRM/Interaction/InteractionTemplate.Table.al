// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Interaction;

using Microsoft.CRM.Campaign;
using System.Integration.Word;

table 5064 "Interaction Template"
{
    Caption = 'Interaction Template';
    DataClassification = CustomerContent;
    LookupPageID = "Interaction Templates";
    ReplicateData = true;

    fields
    {
        field(1; "Code"; Code[10])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Interaction Group Code"; Code[10])
        {
            Caption = 'Interaction Group Code';
            NotBlank = true;
            TableRelation = "Interaction Group";
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(4; "Unit Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 2;
            Caption = 'Unit Cost (LCY)';
            MinValue = 0;
        }
        field(5; "Unit Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Unit Duration (Min.)';
            DecimalPlaces = 0 : 0;
            MinValue = 0;
        }
        field(6; "Information Flow"; Option)
        {
            Caption = 'Information Flow';
            OptionCaption = ' ,Outbound,Inbound';
            OptionMembers = " ",Outbound,Inbound;
        }
        field(7; "Initiated By"; Option)
        {
            Caption = 'Initiated By';
            OptionCaption = ' ,Us,Them';
            OptionMembers = " ",Us,Them;
        }
        field(8; "Attachment No."; Integer)
        {
            CalcFormula = lookup("Interaction Tmpl. Language"."Attachment No." where("Interaction Template Code" = field(Code),
                                                                                      "Language Code" = field("Language Code (Default)")));
            Caption = 'Attachment No.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(9; "Campaign No."; Code[20])
        {
            Caption = 'Campaign No.';
            TableRelation = Campaign;
        }
        field(10; "Campaign Target"; Boolean)
        {
            Caption = 'Campaign Target';
        }
        field(11; "Campaign Response"; Boolean)
        {
            Caption = 'Campaign Response';
        }
        field(12; "Correspondence Type (Default)"; Enum "Correspondence Type")
        {
            Caption = 'Correspondence Type (Default)';
            InitValue = Email;

            trigger OnValidate()
            var
                Attachment: Record Attachment;
            begin
                if not Attachment.Get("Attachment No.") then
                    exit;
            end;
        }
        field(13; "Date Filter"; Date)
        {
            Caption = 'Date Filter';
            FieldClass = FlowFilter;
        }
        field(14; "No. of Interactions"; Integer)
        {
            CalcFormula = count("Interaction Log Entry" where("Interaction Template Code" = field(Code),
                                                               Canceled = const(false),
                                                               Date = field("Date Filter"),
                                                               Postponed = const(false)));
            Caption = 'No. of Interactions';
            Editable = false;
            FieldClass = FlowField;
        }
        field(15; "Cost (LCY)"; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            CalcFormula = sum("Interaction Log Entry"."Cost (LCY)" where("Interaction Template Code" = field(Code),
                                                                          Canceled = const(false),
                                                                          Date = field("Date Filter"),
                                                                          Postponed = const(false)));
            Caption = 'Cost (LCY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(16; "Duration (Min.)"; Decimal)
        {
            AutoFormatType = 0;
            CalcFormula = sum("Interaction Log Entry"."Duration (Min.)" where("Interaction Template Code" = field(Code),
                                                                               Canceled = const(false),
                                                                               Date = field("Date Filter"),
                                                                               Postponed = const(false)));
            Caption = 'Duration (Min.)';
            DecimalPlaces = 0 : 0;
            Editable = false;
            FieldClass = FlowField;
        }
        field(17; "Language Code (Default)"; Code[10])
        {
            Caption = 'Language Code (Default)';
            TableRelation = "Interaction Tmpl. Language"."Language Code" where("Interaction Template Code" = field(Code));

            trigger OnValidate()
            var
                InteractTmplLanguage: Record "Interaction Tmpl. Language";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateLanguageCodeDefault(Rec, xRec, IsHandled);
                if IsHandled then
                    exit;

                if not InteractTmplLanguage.Get(Code, "Language Code (Default)") then
                    if Confirm(Text004, true, InteractTmplLanguage.TableCaption(), "Language Code (Default)") then begin
                        InteractTmplLanguage.Init();
                        InteractTmplLanguage."Interaction Template Code" := Code;
                        InteractTmplLanguage."Language Code" := "Language Code (Default)";
                        InteractTmplLanguage.Description := Description;
                        InteractTmplLanguage.Insert();
                    end else
                        Error('');

                if (InteractTmplLanguage."Custom Layout Code" <> '') or (InteractTmplLanguage."Report Layout Name" <> '') then
                    "Wizard Action" := "Wizard Action"::Merge
                else
                    if "Wizard Action" = "Wizard Action"::Merge then
                        "Wizard Action" := "Wizard Action"::" ";

                if InteractTmplLanguage."Word Template Code" <> '' then
                    "Word Template Code" := InteractTmplLanguage."Word Template Code"
                else
                    "Word Template Code" := '';

                CalcFields("Attachment No.");
            end;
        }
        field(18; "Wizard Action"; Enum "Interaction Template Wizard Action")
        {
            Caption = 'Wizard Action';

            trigger OnValidate()
            var
                InteractionTmplLanguage: Record "Interaction Tmpl. Language";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateWizardAction(Rec, IsHandled);
                if IsHandled then
                    exit;

                if InteractionTmplLanguage.Get(Code, "Language Code (Default)") then begin
                    Rec.CalcFields("Attachment No.");
                    if (((InteractionTmplLanguage."Custom Layout Code" <> '') or (InteractionTmplLanguage."Report Layout Name" <> '')) and ("Wizard Action" <> "Wizard Action"::Merge) and ("Word Template Code" = '')) or
                       ((InteractionTmplLanguage."Custom Layout Code" = '') and (InteractionTmplLanguage."Report Layout Name" = '') and ("Wizard Action" = "Wizard Action"::Merge) and ("Word Template Code" = '')) or
                       (("Word Template Code" <> '') and ("Wizard Action" = "Wizard Action"::Import)) or
                       (("Attachment No." = 0) and ("Word Template Code" = '') and ("Wizard Action" = "Wizard Action"::Merge))
                    then
                        Error(Text003, FieldCaption("Wizard Action"), "Wizard Action", TableCaption(), Code);
                end
            end;
        }
        field(19; "Ignore Contact Corres. Type"; Boolean)
        {
            Caption = 'Ignore Contact Corres. Type';
        }
        field(20; "Word Template Code"; Code[30])
        {
            TableRelation = "Word Template".Code where("Table ID" = const(Database::"Interaction Merge Data"));

            trigger OnValidate()
            var
                InteractTmplLanguage: Record "Interaction Tmpl. Language";
            begin
                if Rec."Attachment No." <> 0 then
                    if Confirm(RemoveAttachmentQst) then
                        RemoveAttachment()
                    else begin
                        Rec."Word Template Code" := '';
                        exit;
                    end;

                if "Word Template Code" <> '' then
                    if "Wizard Action" = "Wizard Action"::Import then
                        Error(WordTemplateCodeCannotBeSetForImportActionErr, FieldCaption("Word Template Code"), "Word Template Code", FieldCaption("Wizard Action"), "Wizard Action");

                if InteractTmplLanguage.Get(Rec.Code, Rec."Language Code (Default)") then begin
                    InteractTmplLanguage."Word Template Code" := Rec."Word Template Code";
                    InteractTmplLanguage.Modify();
                end else begin
                    InteractTmplLanguage.Init();
                    InteractTmplLanguage."Interaction Template Code" := Rec.Code;
                    InteractTmplLanguage."Language Code" := Rec."Language Code (Default)";
                    InteractTmplLanguage.Description := Rec.Description;
                    InteractTmplLanguage."Word Template Code" := Rec."Word Template Code";
                    InteractTmplLanguage.Insert();
                end;
            end;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Interaction Group Code")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Code", Description, "Information Flow", "Attachment No.")
        {
        }
    }

    trigger OnDelete()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        InteractionTmplLanguage.SetRange("Interaction Template Code", Code);
        InteractionTmplLanguage.DeleteAll(true);
    end;

    local procedure RemoveAttachment()
    var
        InteractionTmplLanguage: Record "Interaction Tmpl. Language";
    begin
        if InteractionTmplLanguage.Get(Code, "Language Code (Default)") then
            InteractionTmplLanguage.RemoveAttachment(false);
    end;

    var
#pragma warning disable AA0074
        Text003: Label '%1 = %2 can not be specified for %3 %4.', Comment = '%1 = Wizard Action caption, %2= Wizard Action, %3 = Interaction Template, %4 = Code ';
#pragma warning disable AA0470
        Text004: Label 'Do you want to create %1 %2?';
#pragma warning restore AA0470
#pragma warning restore AA0074
        WordTemplateCodeCannotBeSetForImportActionErr: Label '%1 = %2 can not be specified for %3 %4.', Comment = '%1 = Word Template Code caption, %2= Word Template Code, %3 = Wizard Action, %4 = Action';
        RemoveAttachmentQst: Label 'You cannot use a Word template when an attachment is specified. Do you want to remove the attachment?';

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateWizardAction(var InteractionTemplate: Record "Interaction Template"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateLanguageCodeDefault(var InteractionTemplate: Record "Interaction Template"; var xInteractionTemplate: Record "Interaction Template"; var IsHandled: Boolean)
    begin
    end;
}
