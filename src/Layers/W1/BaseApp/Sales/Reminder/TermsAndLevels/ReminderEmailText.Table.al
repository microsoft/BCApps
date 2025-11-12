// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

using System.Globalization;
using System.Reflection;

table 503 "Reminder Email Text"
{
    Caption = 'Reminder Email Text';
    DataCaptionFields = "Language Code", "Source Type", Subject;
    LookupPageID = "Reminder Email Text";

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
        field(4; Subject; Text[128])
        {
            Caption = 'Subject';
            DataClassification = CustomerContent;
        }
        field(5; Greeting; Text[128])
        {
            Caption = 'Greeting';
            DataClassification = CustomerContent;
        }
        field(6; "Body Text"; Blob)
        {
            Caption = 'Body Text';
            DataClassification = CustomerContent;
        }
        field(7; Closing; Text[128])
        {
            Caption = 'Closing';
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

    procedure SetBodyText(value: Text; var ReminderEmailText: Record "Reminder Email Text")
    begin
        ReminderEmailText.SetBodyText(value);
    end;

    procedure GetBodyText(): Text
    begin
        exit(GetBodyText(Rec));
    end;

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

