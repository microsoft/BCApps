// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

page 7607 "Base Calendar Change List"
{
    Caption = 'Base Calendar Change List';
    DataCaptionFields = "Base Calendar Code";
    Editable = false;
    PageType = List;
    SourceTable = "Base Calendar Change";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the code of the base calendar in the entry.';
                    Visible = false;
                }
                field("Recurring System"; Rec."Recurring System")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring System';
                    ToolTip = 'Specifies whether a date or day is a recurring nonworking day. It can be either Annual Recurring or Weekly Recurring.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date to change associated with the base calendar in this entry.';
                }
                field(Day; Rec.Day)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the day of the week associated with this change entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of the change in this entry.';
                }
                field(Nonworking; Rec.Nonworking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Nonworking';
                    ToolTip = 'Specifies that the date entry was defined as a nonworking day when the base calendar was set up.';
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

