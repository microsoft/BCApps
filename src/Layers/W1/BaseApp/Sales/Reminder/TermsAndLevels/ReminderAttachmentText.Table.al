// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;

/// <summary>
/// Stores language-specific text configurations for reminder PDF attachment documents by source type.
/// </summary>
table 502 "Reminder Attachment Text"
{
    Caption = 'Reminder Attachment Text';
    DataCaptionFields = "Language Code", "Source Type", "File Name";
    LookupPageID = "Reminder Attachment Text";

    fields
    {
        /// <summary>
        /// Specifies the unique identifier for this attachment text configuration.
        /// </summary>
        field(1; Id; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the language code for this attachment text configuration.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language code of the beginning and ending lines.';
            NotBlank = true;
            TableRelation = Language;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies whether this text is linked to reminder terms or a specific reminder level.
        /// </summary>
        field(3; "Source Type"; Enum "Reminder Text Source Type")
        {
            Caption = 'Source Type';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the file name for the generated reminder PDF attachment.
        /// </summary>
        field(4; "File Name"; Text[100])
        {
            Caption = 'File Name';
            ToolTip = 'Specifies the file name of the attachment.';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Contains the text that appears at the beginning of the reminder attachment.
        /// </summary>
        field(5; "Beginning Line"; Text[100])
        {
            Caption = 'Beginning Line';
            DataClassification = CustomerContent;
#if not CLEAN27
            ObsoleteReason = 'To support the use of multiple lines, this field will be replaced by the Reminder Attachment Text Line table.';
            ObsoleteState = Pending;
#pragma warning disable AS0074
            ObsoleteTag = '27.0';
#pragma warning restore AS0074
#else
            ObsoleteReason = 'To support the use of multiple lines, this is replaced by Reminder Attachment Text Line table.';
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
        /// <summary>
        /// Specifies the description text for inline fees shown on the reminder attachment.
        /// </summary>
        field(6; "Inline Fee Description"; Text[100])
        {
            Caption = 'Inline Fee Description';
            ToolTip = 'Specifies the description line that will appear in the attachment along side the fee.';
            DataClassification = CustomerContent;
        }
#if not CLEANSCHEMA29
        /// <summary>
        /// Contains the text that appears at the end of the reminder attachment.
        /// </summary>
        field(7; "Ending Line"; Text[100])
        {
            Caption = 'Ending Line';
            DataClassification = CustomerContent;
#if not CLEAN27
            ObsoleteReason = 'To support the use of multiple lines, this field will be replaced by the Reminder Attachment Text Line table.';
            ObsoleteState = Pending;
#pragma warning disable AS0074
            ObsoleteTag = '27.0';
#pragma warning restore AS0074
#else
            ObsoleteReason = 'To support the use of multiple lines, this is replaced by Reminder Attachment Text Line table.';
            ObsoleteState = Removed;
            ObsoleteTag = '29.0';
#endif
        }
#endif
        /// <summary>
        /// Indicates whether beginning text lines exist for this attachment configuration.
        /// </summary>
        field(10; "Beginning Lines"; Boolean)
        {
            CalcFormula = exist("Reminder Attachment Text Line"
                                where(Id = field(Id),
                                      "Language Code" = field("Language Code"),
                                      Position = const("Beginning Line")));
            Caption = 'Beginning Line';
            ToolTip = 'Shows if there are beginning lines for the current language.';
            Editable = false;
            FieldClass = FlowField;
        }
        /// <summary>
        /// Indicates whether ending text lines exist for this attachment configuration.
        /// </summary>
        field(11; "Ending Lines"; Boolean)
        {
            CalcFormula = exist("Reminder Attachment Text Line"
                                where(Id = field(Id),
                                      "Language Code" = field("Language Code"),
                                      Position = const("Ending Line")));
            Caption = 'Ending Line';
            ToolTip = 'Shows if there are ending lines for the current language.';
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

    /// <summary>
    /// Creates a new reminder attachment text record for the user's language with default content.
    /// </summary>
    /// <param name="SelectedId">The ID of the reminder attachment text group.</param>
    /// <param name="SourceType">The source type (Reminder Term or Reminder Level).</param>
    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; SourceType: Enum "Reminder Text Source Type")
    var
        Language: Codeunit Language;
    begin
        SetDefaultContentForNewLanguage(SelectedId, Language.GetUserLanguageCode(), SourceType);
    end;

    /// <summary>
    /// Creates a new reminder attachment text record for the specified language with default content.
    /// </summary>
    /// <param name="SelectedId">The ID of the reminder attachment text group.</param>
    /// <param name="LanguageCode">The language code for the new record.</param>
    /// <param name="SourceType">The source type (Reminder Term or Reminder Level).</param>
    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type")
    var
        EmptyGuid: Guid;
    begin
        SetDefaultContentForNewLanguage(SelectedId, LanguageCode, SourceType, EmptyGuid);
    end;

    /// <summary>
    /// Creates a new reminder attachment text record for the specified language and links it to the source record.
    /// </summary>
    /// <param name="SelectedId">The ID of the reminder attachment text group.</param>
    /// <param name="LanguageCode">The language code for the new record.</param>
    /// <param name="SourceType">The source type (Reminder Term or Reminder Level).</param>
    /// <param name="SelectedSystemId">The system ID of the source record to link to.</param>
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

