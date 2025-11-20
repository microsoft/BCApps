// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

page 7603 "Customized Calendar Changes"
{
    Caption = 'Customized Calendar Changes';
    DataCaptionExpression = Rec.GetCaption();
    PageType = List;
    SourceTable = "Customized Calendar Change";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source type, such as company, for this entry.';
                    Visible = false;
                }
                field("Source Code"; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the source code that specifies where the entry was created.';
                    Visible = false;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies which base calendar was used as the basis for this customized calendar.';
                    Visible = false;
                }
                field("Recurring System"; Rec."Recurring System")
                {
                    ApplicationArea = Suite;
                    Caption = 'Recurring System';
                    ToolTip = 'Specifies a date or day as a recurring nonworking or working day.';
                }
                field(Date; Rec.Date)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the date associated with this customized calendar entry.';
                }
                field(Day; Rec.Day)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the day of the week associated with this entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies a description of this entry.';
                }
                field(Nonworking; Rec.Nonworking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Nonworking';
                    ToolTip = 'Specifies that the day is not a working day.';
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

