// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

/// <summary>
/// Manages language translations for reminder terms note text to support multi-language reminders.
/// </summary>
page 1052 "Reminder Terms Translation"
{
    Caption = 'Reminder Terms Translation';
    DataCaptionExpression = PageCaptionText;
    SourceTable = "Reminder Terms Translation";

    layout
    {
        area(content)
        {
            repeater(Control1004)
            {
                ShowCaption = false;
                field("Reminder Terms Code"; Rec."Reminder Terms Code")
                {
                    ApplicationArea = Suite;
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Suite;
                }
                field("Note About Line Fee on Report"; Rec."Note About Line Fee on Report")
                {
                    ApplicationArea = Suite;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnOpenPage()
    begin
        PageCaptionText := Rec."Reminder Terms Code";
    end;

    var
        PageCaptionText: Text;
}

