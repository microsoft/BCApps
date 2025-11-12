// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

page 7606 "Customized Calendar Entries"
{
    Caption = 'Customized Calendar Entries';
    DataCaptionExpression = Rec.GetCaption();
    PageType = ListPlus;
    SourceTable = "Customized Calendar Entry";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Source Type"; Rec."Source Type")
                {
                    ApplicationArea = Suite;
                    Caption = 'Source Type';
                    DrillDown = false;
                    ToolTip = 'Specifies whether this customized calendar entry was set up for your company, a customer, vendor, location, shipping agent, or a service.';
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Base Calendar Code';
                    Lookup = true;
                    ToolTip = 'Specifies which base calendar was used as the basis for this customized calendar.';
                }
            }
            part(CustomizedCalendarEntries; "Customized Cal. Entries Subfm")
            {
                ApplicationArea = Suite;
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Maintain Customized Calendar Changes")
                {
                    ApplicationArea = Suite;
                    Caption = '&Maintain Customized Calendar Changes';
                    Image = Edit;
                    RunObject = Page "Customized Calendar Changes";
                    RunPageLink = "Source Type" = field("Source Type"),
                                  "Source Code" = field(filter("Source Code")),
                                  "Additional Source Code" = field("Additional Source Code"),
                                  "Base Calendar Code" = field("Base Calendar Code");
                    ToolTip = 'View or edit a customized calendar. You would typically enter any nonworking days that you want to apply to a calendar that you are setting up, to change their status from working to nonworking. You can also use this window to edit a base calendar that has already been set up.';
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        CurrPage.CustomizedCalendarEntries.PAGE.SetCalendarSource(Rec);
    end;
}

