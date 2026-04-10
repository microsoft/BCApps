// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;
using System.Reflection;

/// <summary>
/// Stores language-specific email text configurations including subject and body for reminder communications.
/// </summary>
table 503 "Reminder Email Text"
{
    Caption = 'Reminder Email Text';
    DataCaptionFields = "Language Code", "Source Type", Subject;
    LookupPageID = "Reminder Email Text";

    fields
    {
        /// <summary>
        /// Specifies the unique identifier for this email text configuration.
        /// </summary>
        field(1; Id; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the language code for this email text configuration.
        /// </summary>
        field(2; "Language Code"; Code[10])
        {
            Caption = 'Language Code';
            ToolTip = 'Specifies the language code for the text communications.';
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
        /// Specifies the email subject line for reminder communications.
        /// </summary>
        field(4; Subject; Text[128])
        {
            Caption = 'Subject';
            ToolTip = 'Specifies the subject of the generated email.';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the greeting text that appears at the start of the email body.
        /// </summary>
        field(5; Greeting; Text[128])
        {
            Caption = 'Greeting';
            ToolTip = 'Specifies the first lines at the beginning of the email';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Contains the main body text content of the reminder email.
        /// </summary>
        field(6; "Body Text"; Blob)
        {
            Caption = 'Body Text';
            DataClassification = CustomerContent;
        }
        /// <summary>
        /// Specifies the closing text that appears at the end of the email body.
        /// </summary>
        field(7; Closing; Text[128])
        {
            Caption = 'Closing';
            ToolTip = 'Specifies the last lines at the end of the email.';
            DataClassification = CustomerContent;
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
        ReminderEmailText: Record "Reminder Email Text";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        OnlyOneLanguage: Boolean;
        EmptyGuid: Guid;
    begin
        ReminderEmailText.SetRange(Id, Rec.Id);
        OnlyOneLanguage := ReminderEmailText.Count() <= 1;

        if not OnlyOneLanguage then
            exit;

        case Rec."Source Type" of
            "Reminder Text Source Type"::"Reminder Term":
                begin
                    ReminderTerms.SetRange("Reminder Email Text", Rec.Id);
                    ReminderTerms.FindFirst();
                    ReminderTerms."Reminder Email Text" := EmptyGuid;
                    ReminderTerms.Modify(true);
                end;
            "Reminder Text Source Type"::"Reminder Level":
                begin
                    ReminderLevel.SetRange("Reminder Email Text", Rec.Id);
                    ReminderLevel.FindFirst();
                    ReminderLevel."Reminder Email Text" := EmptyGuid;
                    ReminderLevel.Modify(true);
                end;
        end;
    end;

    var
        DefaultSubjectLbl: Label 'Issued Reminder';
        DefaultGreetingLbl: Label 'Hello';
        DefaultBodyTextLbl: Label 'You are receiving this email to formally notify you that payment owed by you is past due. The payment was due on %1. Enclosed is a copy of invoice with the details of remaining amount. If you have already made the payment, please disregard this email. Thank you for your business.', Comment = '%1 = The due date';
        DefaultClosingLbl: Label 'Sincerely';
        NoRecordSelectedErr: Label 'No reminder email text selected.';
        MissingIDErr: Label 'A reminder email text cannot be created without an ID.';
        MissingLanguageCodeErr: Label 'A reminder email text cannot be created without a language code.';
        AlreadyExistsSelectedLanguageErr: Label 'There is already a reminder email text for the selected language %1. Remove the existing personalization before setting the default communication for that language.', Comment = '%1 = Language Code';
        AmtDueLbl: Label 'You are receiving this email to formally notify you that payment owed by you is past due. The payment was due on %1. Enclosed is a copy of invoice with the details of remaining amount.', Comment = '%1 = A due date';
        DescriptionLbl: Label 'Description';
        BodyLbl: Label 'If you have already made the payment, please disregard this email. Thank you for your business.';

    internal procedure GetDescriptionLbl(): Text
    begin
        exit(DescriptionLbl);
    end;

    internal procedure GetAmtDueLbl(): Text
    begin
        exit(AmtDueLbl);
    end;

    internal procedure GetBodyLbl(): Text
    begin
        exit(BodyLbl);
    end;

    internal procedure GetDefaultSubjectLbl(): Text
    begin
        exit(DefaultSubjectLbl);
    end;

    internal procedure GetDefaultGreetingLbl(): Text
    begin
        exit(DefaultGreetingLbl);
    end;

    internal procedure GetDefaultBodyTextLbl(): Text
    begin
        exit(DefaultBodyTextLbl);
    end;

    internal procedure GetDefaultClosingLbl(): Text
    begin
        exit(DefaultClosingLbl);
    end;

    /// <summary>
    /// Sets the body text for the current email text record.
    /// </summary>
    /// <param name="value">The body text content to store.</param>
    procedure SetBodyText(value: Text)
    var
        WriteStream: OutStream;
    begin
        if Rec.IsEmpty() then
            Error(NoRecordSelectedErr);

        if value = '' then begin
            Clear(Rec."Body Text");
            Rec.Modify();
            exit;
        end;

        Clear(Rec."Body Text");
        Rec."Body Text".CreateOutStream(WriteStream, TextEncoding::UTF8);
        WriteStream.WriteText(value);
        Rec.Modify();
    end;

    /// <summary>
    /// Sets the body text for the specified email text record.
    /// </summary>
    /// <param name="value">The body text content to store.</param>
    /// <param name="ReminderEmailText">The email text record to update.</param>
    procedure SetBodyText(value: Text; var ReminderEmailText: Record "Reminder Email Text")
    begin
        ReminderEmailText.SetBodyText(value);
    end;

    /// <summary>
    /// Gets the body text from the current email text record.
    /// </summary>
    /// <returns>The body text content.</returns>
    procedure GetBodyText(): Text
    begin
        exit(GetBodyText(Rec));
    end;

    /// <summary>
    /// Gets the body text from the specified email text record.
    /// </summary>
    /// <param name="ReminderEmailText">The email text record to read from.</param>
    /// <returns>The body text content.</returns>
    procedure GetBodyText(var ReminderEmailText: Record "Reminder Email Text"): Text
    var
        TypeHelper: Codeunit "Type Helper";
        ReadStream: InStream;
        BodyText: Text;
    begin
        if ReminderEmailText.IsEmpty() then
            Error(NoRecordSelectedErr);

        ReminderEmailText.CalcFields("Body Text");
        if ReminderEmailText."Body Text".HasValue() then begin
            ReminderEmailText."Body Text".CreateInStream(ReadStream, TextEncoding::UTF8);
            BodyText := TypeHelper.TryReadAsTextWithSepAndFieldErrMsg(ReadStream, TypeHelper.LFSeparator(), FieldName("Body Text"));
        end
        else
            BodyText := '';
        exit(BodyText);
    end;

    /// <summary>
    /// Creates a new reminder email text record for the user's language with default content.
    /// </summary>
    /// <param name="SelectedId">The ID of the email text group.</param>
    /// <param name="SourceType">The source type (Reminder Term or Reminder Level).</param>
    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; SourceType: Enum "Reminder Text Source Type")
    var
        Language: Codeunit Language;
    begin
        SetDefaultContentForNewLanguage(SelectedId, Language.GetUserLanguageCode(), SourceType);
    end;

    /// <summary>
    /// Creates a new reminder email text record for the specified language with default content.
    /// </summary>
    /// <param name="SelectedId">The ID of the email text group.</param>
    /// <param name="LanguageCode">The language code for the new record.</param>
    /// <param name="SourceType">The source type (Reminder Term or Reminder Level).</param>
    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type")
    var
        EmptyGuid: Guid;
    begin
        SetDefaultContentForNewLanguage(SelectedId, LanguageCode, SourceType, EmptyGuid);
    end;

    /// <summary>
    /// Creates a new reminder email text record for the specified language and links it to the source record.
    /// </summary>
    /// <param name="SelectedId">The ID of the email text group.</param>
    /// <param name="LanguageCode">The language code for the new record.</param>
    /// <param name="SourceType">The source type (Reminder Term or Reminder Level).</param>
    /// <param name="SelectedSystemId">The system ID of the source record to link to.</param>
    procedure SetDefaultContentForNewLanguage(SelectedId: Guid; LanguageCode: Code[10]; SourceType: Enum "Reminder Text Source Type"; SelectedSystemId: Guid)
    var
        ExistingReminderEmailText: Record "Reminder Email Text";
        ReminderEmailText: Record "Reminder Email Text";
        ReminderTerms: Record "Reminder Terms";
        ReminderLevel: Record "Reminder Level";
        Language: Codeunit Language;
        CurrentGlobalLanguage: Integer;
    begin
        if ExistingReminderEmailText.Get(Id, LanguageCode) then
            Error(AlreadyExistsSelectedLanguageErr, LanguageCode);

        CurrentGlobalLanguage := GlobalLanguage();
        GlobalLanguage(Language.GetLanguageId(LanguageCode));
        ReminderEmailText.Id := SelectedId;
        ReminderEmailText."Language Code" := LanguageCode;
        ReminderEmailText.Subject := DefaultSubjectLbl;
        ReminderEmailText.Greeting := DefaultGreetingLbl;
        ReminderEmailText.Closing := DefaultClosingLbl;
        ReminderEmailText."Source Type" := SourceType;
        ReminderEmailText.Insert(true);
        ReminderEmailText.SetBodyText(DefaultBodyTextLbl);
        GlobalLanguage(CurrentGlobalLanguage);

        if IsNullGuid(SelectedSystemId) then
            exit;

        case SourceType of
            "Reminder Text Source Type"::"Reminder Term":
                begin
                    ReminderTerms.SetRange(SystemId, SelectedSystemId);
                    if ReminderTerms.FindFirst() then begin
                        ReminderTerms."Reminder Email Text" := SelectedId;
                        ReminderTerms.Modify(true);
                    end;
                end;
            "Reminder Text Source Type"::"Reminder Level":
                begin
                    ReminderLevel.SetRange(SystemId, SelectedSystemId);
                    if ReminderLevel.FindFirst() then begin
                        ReminderLevel."Reminder Email Text" := SelectedId;
                        ReminderLevel.Modify(true);
                    end;
                end;
        end;
    end;
}

