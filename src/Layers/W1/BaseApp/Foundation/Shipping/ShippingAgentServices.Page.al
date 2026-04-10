// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Shipping;

using Microsoft.Foundation.Calendar;

page 5790 "Shipping Agent Services"
{
    Caption = 'Shipping Agent Services';
    DataCaptionFields = "Shipping Agent Code";
    PageType = List;
    SourceTable = "Shipping Agent Services";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                }
                field("Shipping Time"; Rec."Shipping Time")
                {
                    ApplicationArea = Suite;
                }
                field("Base Calendar Code"; Rec."Base Calendar Code")
                {
                    ApplicationArea = Warehouse;
                    DrillDown = false;
                }
                field(CustomizedCalendar; format(CalendarMgmt.CustomizedChangesExist(Rec)))
                {
                    ApplicationArea = Warehouse;
                    Caption = 'Customized Calendar';
                    ToolTip = 'Specifies if you have set up a customized calendar for the shipping agent.';

                    trigger OnDrillDown()
                    begin
                        CurrPage.SaveRecord();
                        Rec.TestField("Base Calendar Code");
                        CalendarMgmt.ShowCustomizedCalendar(Rec);
                    end;
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

    var
        CalendarMgmt: Codeunit "Calendar Management";
}

