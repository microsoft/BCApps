// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Displays a read-only view of email text configurations as a subpage part.
/// </summary>
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
                }
                field(Subject; Rec.Subject)
                {
                    ApplicationArea = All;
                    Caption = 'Subject';
                }
                field(Greeting; Rec.Greeting)
                {
                    ApplicationArea = All;
                    Caption = 'Greeting';
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
                }
            }
        }
    }
}