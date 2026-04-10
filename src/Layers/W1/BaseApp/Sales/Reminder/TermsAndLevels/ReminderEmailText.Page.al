// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays a summary of email text configurations for reminder documents as a card part.
/// </summary>
page 834 "Reminder Email Text"
{
    Caption = 'Email Texts';
    PageType = CardPart;
    SourceTable = "Reminder Email Text";
    Editable = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(SubjectGroup)
            {
                ShowCaption = false;
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    Importance = Promoted;
                    Caption = 'Subject';
                }
            }
            group(GreetingGroup)
            {
                Caption = 'Greeting';
                field(Greeting; Rec.Greeting)
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Caption = 'Greeting';
                    ShowCaption = false;
                    ToolTip = 'Specifies the first lines at the beginning of the email.';
                }
            }
            group(BodyTextGroup)
            {
                ShowCaption = false;
                field("Body Text Editor"; EmailBody)
                {
                    MultiLine = true;
                    ApplicationArea = All;
                    ExtendedDatatype = RichContent;
                    StyleExpr = false;
                    Caption = 'Body Text';
                    ToolTip = 'Specifies the main text of the email, which appears between the greeting and the closing.';

                    trigger OnValidate()
                    begin
                        Rec.SetBodyText(EmailBody);
                    end;
                }
            }
            group(ClosingGroup)
            {
                Caption = 'Closing';
                field(Closing; Rec.Closing)
                {
                    ApplicationArea = All;
                    Importance = Additional;
                    Caption = 'Closing';
                    ShowCaption = false;
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if LanguageCode = '' then
            exit;

        if not Rec.Get(Rec.Id, LanguageCode) then
            Error(NoAttachmentTextFoundErr, LanguageCode);

        EmailBody := Rec.GetBodyText();
    end;

    trigger OnInit()
    begin
        EmailBody := '';
    end;

    var
        EmailBody: Text;
        LanguageCode: Code[10];
        NoAttachmentTextFoundErr: Label 'No attachment text found for the selected language %1.', Comment = '%1 = Language code';

    internal procedure SetSourceData(SelectedLanguageCode: Code[10])
    begin
        LanguageCode := SelectedLanguageCode;
    end;
}