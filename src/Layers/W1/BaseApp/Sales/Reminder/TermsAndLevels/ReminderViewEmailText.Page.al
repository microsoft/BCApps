// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 843 "Reminder View Email Text"
{
    PageType = ListPart;
    SourceTable = "Reminder Email Text";
    Caption = 'Email Text';
    Editable = false;
    DeleteAllowed = false;
    InsertAllowed = false;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                ShowCaption = false;
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = All;
                    Caption = 'Language Code';
                    ToolTip = 'Specifies the language code for the text communications.';
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    Caption = 'Subject';
                    ToolTip = 'Specifies the subject of the generated email.';
                }
                field(Greeting; Rec.Greeting)
                {
                    ApplicationArea = All;
                    Caption = 'Greeting';
                    ToolTip = 'Specifies the first lines at the beginning of the email';
                }
                field("Body Text Editor"; Rec.GetBodyText())
                {
                    ApplicationArea = All;
                    Caption = 'Body Text';
                    ToolTip = 'Specifies the main text of the email, which is the text between the greeting and the closing';
                }
                field(Closing; Rec.Closing)
                {
                    ApplicationArea = All;
                    Caption = 'Closing';
                    ToolTip = 'Specifies the last lines at the end of the email.';
                }
            }
        }
    }
}