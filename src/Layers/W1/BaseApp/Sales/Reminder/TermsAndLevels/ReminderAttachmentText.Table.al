// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;

table 502 "Reminder Attachment Text"
{
    Caption = 'Reminder Attachment Text';
    DataCaptionFields = "Language Code", "Source Type", "File Name";
    LookupPageID = "Reminder Attachment Text";

    fields
    {
        field(1; Id; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            NotBlank = true;
            TableRelation = Language;
            DataClassification = SystemMetadata;
        }
        field(3; "Source Type"; Enum "Reminder Text Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        field(4; "File Name"; Text[100])
        {
            Caption = 'File Name';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA28
        field(5; "Beginning Line"; Text[100])
        {
            Caption = 'Beginning Line';
            DataClassification = CustomerContent;
#if not CLEAN26
            ObsoleteReason = 'To support the use of multiple lines, this field will be replaced by the Reminder Attachment Text Line table.';
            ObsoleteState = Pending;
#pragma warning disable AS0074
            ObsoleteTag = '26.0';
#pragma warning restore AS0074
#else
            ObsoleteReason = 'To support the use of multiple lines, this is replaced by Reminder Attachment Text Line table.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#endif
        }
#endif
        field(6; "Inline Fee Description"; Text[100])
        {
            Caption = 'Inline Fee Description';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA28
        field(7; "Ending Line"; Text[100])
        {
            Caption = 'Ending Line';
            DataClassification = CustomerContent;
#if not CLEAN26
            ObsoleteReason = 'To support the use of multiple lines, this field will be replaced by the Reminder Attachment Text Line table.';
            ObsoleteState = Pending;
#pragma warning disable AS0074
            ObsoleteTag = '26.0';
#pragma warning restore AS0074
#else
            ObsoleteReason = 'To support the use of multiple lines, this is replaced by Reminder Attachment Text Line table.';
            ObsoleteState = Removed;
            ObsoleteTag = '28.0';
#endif
        }
#endif
        field(10; "Beginning Lines"; Boolean)
        {
            CalcFormula = exist("Reminder Attachment Text Line"
                                where(Id = field(Id),
                                      "Language Code" = field("Language Code"),
                                      Position = const("Beginning Line")));
            Caption = 'Beginning Line';
            Editable = false;
            FieldClass = FlowField;
        }
        field(11; "Ending Lines"; Boolean)
        {
            CalcFormula = exist("Reminder Attachment Text Line"
                                where(Id = field(Id),
                                      "Language Code" = field("Language Code"),
                                      Position = const("Ending Line")));
            Caption = 'Ending Line';
            Editable = false;
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; Id, "Language Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin
        if IsNullGuid(Rec.Id) then
            Error(MissingIDErr);

        if Rec."Language Code" = '' then
            Error(MissingLanguageCodeErr);
    end;

    trigger OnDelete()
    var
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        OnlyOneLanguage: Boolean;
        EmptyGuid: Guid;
    begin
        DeleteReminderAttachmentTextLines(Rec);
        ReminderAttachmentText.SetRange(Id, Rec.Id);
        OnlyOneLanguage := ReminderAttachmentText.Count() <= 1;

        if not OnlyOneLanguage then
            exit;

        case Rec."Source Type" of
            "Reminder Text Source Type"::"Reminder Term":
                begin
                    ReminderTerms.SetRange("Reminder Attachment Text", Rec.Id);
                    ReminderTerms.FindFirst();
                    ReminderTerms."Reminder Attachment Text" := EmptyGuid;
                    ReminderTerms.Modify(true);
                end;
            "Reminder Text Source Type"::"Reminder Level":
                begin
                    ReminderLevel.SetRange("Reminder Attachment Text", Rec.Id);
                    ReminderLevel.FindFirst();
                    ReminderLevel."Reminder Attachment Text" := EmptyGuid;
                    ReminderLevel.Modify(true);
                end;
        end;
    end;

    var
        DefaultFileNameLbl: Label 'Reminder';
        MissingIDErr: Label 'A reminder attachment text cannot be created without an ID.';
        MissingLanguageCodeErr: Label 'A reminder attachment text cannot be created without a language code.';
        AlreadyExistsSelectedLanguageErr: Label 'There is already a reminder attachment text for the selected language %1. Remove the existing personalization before setting the default communication for that language.', Comment = '%1 = Language Code';

    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; SourceType: Enum "Reminder Text Source Type")
    var
        Language: Codeunit Language;
    begin
        SetDefaultContentForNewLanguage(SelectedId, Language.GetUserLanguageCode(), SourceType);
    end;

    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type")
    var
        EmptyGuid: Guid;
    begin
        SetDefaultContentForNewLanguage(SelectedId, LanguageCode, SourceType, EmptyGuid);
    end;

    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type"; SelectedSystemId: Guid)
    var
        ExistingReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderAttachmentText: Record "Reminder Attachment Text";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        Language: Codeunit Language;
        CurrentGlobalLanguage: Integer;
    begin
        if ExistingReminderAttachmentText.Get(SelectedId, LanguageCode) then
            Error(AlreadyExistsSelectedLanguageErr, LanguageCode);

        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(Language.GetLanguageId(LanguageCode));
        ReminderAttachmentText.Id := SelectedId;
        ReminderAttachmentText."Language Code" := LanguageCode;
        ReminderAttachmentText."File Name" := DefaultFileNameLbl;
        ReminderAttachmentText."Source Type" := SourceType;
        ReminderAttachmentText.Insert(true);
        GlobalLanguage(CurrentGlobalLanguage);

        if IsNullGuid(SelectedSystemId) then
            exit;

        case SourceType of
            "Reminder Text Source Type"::"Reminder Term":
                begin
                    ReminderTerms.SetRange(SystemId, SelectedSystemId);
                    if ReminderTerms.FindFirst() then begin
                        ReminderTerms."Reminder Attachment Text" := SelectedId;
                        ReminderTerms.Modify(true);
                    end;
                end;
            "Reminder Text Source Type"::"Reminder Level":
                begin
                    ReminderLevel.SetRange(SystemId, SelectedSystemId);
                    if ReminderLevel.FindFirst() then begin
                        ReminderLevel."Reminder Attachment Text" := SelectedId;
                        ReminderLevel.Modify(true);
                    end;
                end;
        end;
    end;

    internal procedure DeleteReminderAttachmentTextLines(ReminderAttachmentText: Record "Reminder Attachment Text")
    var
        ReminderAttachmentTextLine: Record "Reminder Attachment Text Line";
    begin
        ReminderAttachmentTextLine.SetRange(Id, ReminderAttachmentText.Id);
        ReminderAttachmentTextLine.SetRange("Language Code", ReminderAttachmentText."Language Code");
        if ReminderAttachmentTextLine.IsEmpty() then
            exit;

        ReminderAttachmentTextLine.DeleteAll();
    end;
}

