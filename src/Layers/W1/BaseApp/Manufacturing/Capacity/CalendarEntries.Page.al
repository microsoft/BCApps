// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

page 99000759 "Calendar Entries"
{
    Caption = 'Calendar Entries';
    DataCaptionExpression = Rec.Caption();
    DelayedInsert = true;
    PageType = List;
    SourceTable = "Calendar Entry";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Capacity Type"; Rec."Capacity Type")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the type of capacity for the calendar entry.';
                }
                field("No."; Rec."No.")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Date; CurrDate)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Date';
                    ToolTip = 'Specifies the date when this capacity refers to.';
                    Visible = false;

                    trigger OnValidate()
                    begin
                        Rec.Validate(Date, CurrDate);
                        CurrPage.Update(true);
                    end;
                }
                field("Work Shift Code"; Rec."Work Shift Code")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies code for the work shift that the capacity refers to.';
                }
                field("Starting Date-Time"; Rec."Starting Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the starting time, which are combined in a format called "starting date-time".';

                    trigger OnValidate()
                    begin
                        Rec.GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);
                        Rec.Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Starting Time"; StartingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Starting Time';
                    ToolTip = 'Specifies the starting time of this calendar entry.';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Starting Time", StartingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Date-Time"; Rec."Ending Date-Time")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the date and the ending time, which are combined in a format called "ending date-time".';

                    trigger OnValidate()
                    begin
                        Rec.GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);
                        Rec.Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field("Ending Time"; EndingTime)
                {
                    ApplicationArea = Manufacturing;
                    Caption = 'Ending Time';
                    ToolTip = 'Specifies the ending time of this calendar entry.';
                    Visible = DateAndTimeFieldVisible;

                    trigger OnValidate()
                    begin
                        Rec.Validate("Ending Time", EndingTime);
                        CurrPage.Update(true);
                    end;
                }
                field(Efficiency; Rec.Efficiency)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the efficiency of this calendar entry.';
                }
                field(Capacity; Rec.Capacity)
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the capacity of this calendar entry.';
                }
                field("Capacity (Total)"; Rec."Capacity (Total)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the total capacity of this calendar entry.';
                }
                field("Capacity (Effective)"; Rec."Capacity (Effective)")
                {
                    ApplicationArea = Manufacturing;
                    ToolTip = 'Specifies the effective capacity of this calendar entry.';
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

    trigger OnAfterGetRecord()
    begin
        Rec.GetStartingEndingDateAndTime(StartingTime, EndingTime, CurrDate);
    end;

    trigger OnInit()
    begin
        DateAndTimeFieldVisible := false;
    end;

    trigger OnOpenPage()
    begin
        DateAndTimeFieldVisible := false;
    end;

    var
        StartingTime: Time;
        EndingTime: Time;
        CurrDate: Date;
        DateAndTimeFieldVisible: Boolean;
}

