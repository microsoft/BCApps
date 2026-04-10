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
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Starting Time"; Rec."Starting Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    Visible = false;
                }
                field("Ending Time"; Rec."Ending Time")
                {
                    ApplicationArea = Manufacturing;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Manufacturing;
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                }
                field(Updated; Rec.Updated)
                {
                    ApplicationArea = Manufacturing;
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

