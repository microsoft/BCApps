// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

page 99000772 "Capacity Absence"
{
    Caption = 'Capacity Absence';
    DataCaptionExpression = Rec.Caption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Calendar Absence Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(Date; Rec.Date)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date associated with this absence entry.';
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the starting time of the absence entry.';
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the ending time of the absence entry.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the description for the absence entry, for example, holiday or vacation"';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity of the absence entry, which was planned for this work center or machine center.';
                }
                field(Updated; Rec.Updated)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the calendar has been updated with this absence entry.';
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
        area(navigation)
        {
            group("&Absence")
            {
                Caption = '&Absence';
                Image = Absence;
                action(Update)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Update';
                    Image = Refresh;
                    ToolTip = 'Update the calendar with any new absence entries.';

                    trigger OnAction()
                    var
                        CalendarAbsenceEntry: Record "Calendar Absence Entry";
                    begin
                        CalendarAbsenceEntry.Copy(Rec);
                        CalendarAbsenceEntry.SetRange(Updated, false);
                        if CalendarAbsenceEntry.Find() then
                            CalAbsenceMgt.UpdateAbsence(CalendarAbsenceEntry);
                    end;
                }
            }
        }
    }

    var
        CalAbsenceMgt: Codeunit "Calendar Absence Management";
}

