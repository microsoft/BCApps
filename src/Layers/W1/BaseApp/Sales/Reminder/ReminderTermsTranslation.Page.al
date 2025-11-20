// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

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
                    ToolTip = 'Specifies translation of reminder terms so that customers are reminded in their own language.';
                    Visible = false;
                }
                field("Language Code"; Rec."Language Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the language that is used when translating specified text on documents to foreign business partner, such as an item description on an order confirmation.';
                }
                field("Note About Line Fee on Report"; Rec."Note About Line Fee on Report")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that any notes about line fees will be added to the reminder.';
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

