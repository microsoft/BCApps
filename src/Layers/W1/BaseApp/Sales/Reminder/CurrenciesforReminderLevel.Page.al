// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Reminder;

page 478 "Currencies for Reminder Level"
{
    Caption = 'Currencies for Reminder Level';
    PageType = List;
    SourceTable = "Currency for Reminder Level";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Currency Code"; Rec."Currency Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code for the currency in which you want to set up additional fees for reminders.';
                }
                field("Additional Fee"; Rec."Additional Fee")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the amount of the additional fee in foreign currency that will be added on the reminder.';
                }
                field("Add. Fee per Line"; Rec."Add. Fee per Line")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies that the fee is distributed on individual reminder lines.';
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }
}

