// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Resources;

using Microsoft.Foundation.Calendar;
using Microsoft.Foundation.Company;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Service.Setup;

page 6013 "Resource Capacity Settings"
{
    Caption = 'Resource Capacity Settings';
    PageType = Card;
    SourceTable = Resource;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(StartDate; StartDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Starting Date';
                    ToolTip = 'Specifies the starting date for the time period for which you want to change capacity.';
                }
                field(EndDate; EndDate)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Ending Date';
                    ToolTip = 'Specifies the end date relating to the resource capacity.';

                    trigger OnValidate()
                    begin
                        if StartDate > EndDate then
                            Error(Text000);
                    end;
                }
                field(WorkTemplateCode; WorkTemplateCode)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Work-Hour Template';
                    LookupPageID = "Work-Hour Templates";
                    TableRelation = "Work-Hour Template";
                    ToolTip = 'Specifies the number of hours in the work week: 30, 36, or 40.';

                    trigger OnValidate()
                    begin
                        if WorkTemplateRec.Get(WorkTemplateCode) then;
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Monday"; WorkTemplateRec.Monday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Monday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of work-hours on Monday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Tuesday"; WorkTemplateRec.Tuesday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Tuesday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of work-hours on Tuesday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Wednesday"; WorkTemplateRec.Wednesday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Wednesday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of work-hours on Wednesday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Thursday"; WorkTemplateRec.Thursday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Thursday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of work-hours on Thursday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Friday"; WorkTemplateRec.Friday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Friday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the work-hour schedule for Friday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Saturday"; WorkTemplateRec.Saturday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Saturday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of work-hours on Friday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field("WorkTemplateRec.Sunday"; WorkTemplateRec.Sunday)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Sunday';
                    MaxValue = 24;
                    MinValue = 0;
                    ToolTip = 'Specifies the number of work-hours on Saturday.';

                    trigger OnValidate()
                    begin
                        SumWeekTotal();
                    end;
                }
                field(WeekTotal; WeekTotal)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Week Total';
                    DecimalPlaces = 0 : 5;
                    Editable = false;
                    ToolTip = 'Specifies the total number of hours for the week. The total is calculated automatically.';
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
        area(processing)
        {
            action(UpdateCapacity)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Update &Capacity';
                Image = Approve;
                ToolTip = 'Update the capacity based on the changes you have made in the window.';

                trigger OnAction()
                var
                    CustomizedCalendarChange: Record "Customized Calendar Change";
                    NewCapacity: Decimal;
                begin
                    if StartDate = 0D then
                        Error(Text002);

                    if EndDate = 0D then
                        Error(Text003);

                    if not Confirm(Text004, false, Rec.TableCaption(), Rec."No.") then
                        exit;

                    SetCalendar(CustomizedCalendarChange);

                    ResCapacityEntry.Reset();
                    ResCapacityEntry.SetCurrentKey("Resource No.", Date);
                    ResCapacityEntry.SetRange("Resource No.", Rec."No.");
                    TempDate := StartDate;
                    ChangedDays := 0;
                    repeat
                        Holiday := CalendarMgmt.IsNonworkingDay(TempDate, CustomizedCalendarChange);

                        ResCapacityEntry.SetRange(Date, TempDate);
                        ResCapacityEntry.CalcSums(Capacity);
                        TempCapacity := ResCapacityEntry.Capacity;

                        if Holiday then
                            NewCapacity := TempCapacity
                        else
                            NewCapacity := TempCapacity - SelectCapacity(CustomizedCalendarChange);

                        if NewCapacity <> 0 then begin
                            ResCapacityEntry2.Reset();
                            if ResCapacityEntry2.FindLast() then;
                            LastEntry := ResCapacityEntry2."Entry No." + 1;
                            ResCapacityEntry2.Init();
                            ResCapacityEntry2."Entry No." := LastEntry;
                            ResCapacityEntry2.Capacity := -NewCapacity;
                            ResCapacityEntry2."Resource No." := Rec."No.";
                            ResCapacityEntry2."Resource Group No." := Rec."Resource Group No.";
                            ResCapacityEntry2.Date := TempDate;
                            if ResCapacityEntry2.Insert(true) then;
                            ChangedDays := ChangedDays + 1;
                        end;
                        TempDate := TempDate + 1;
                    until TempDate > EndDate;
                    Commit();
                    if ChangedDays > 1 then
                        Message(Text006, ChangedDays)
                    else
                        if ChangedDays = 1 then
                            Message(Text007, ChangedDays)
                        else
                            Message(Text008);
                    CurrPage.Close();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(UpdateCapacity_Promoted; UpdateCapacity)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if not WorkTemplateRec.Get(WorkTemplateCode) and (Rec."No." <> xRec."No.") then
            Clear(WorkTemplateRec);
        SumWeekTotal();
    end;

    trigger OnOpenPage()
    begin
        StartDate := 0D;
        EndDate := 0D;
        WorkTemplateCode := '';
    end;

    var
        WorkTemplateRec: Record "Work-Hour Template";
        ResCapacityEntry: Record "Res. Capacity Entry";
        CompanyInformation: Record "Company Information";
        ResCapacityEntry2: Record "Res. Capacity Entry";
        CalendarMgmt: Codeunit "Calendar Management";
        WorkTemplateCode: Code[10];
        StartDate: Date;
        EndDate: Date;
        WeekTotal: Decimal;
        TempDate: Date;
        TempCapacity: Decimal;
        ChangedDays: Integer;
        LastEntry: Decimal;
        Holiday: Boolean;

#pragma warning disable AA0074
        Text000: Label 'The starting date is later than the ending date.';
        Text002: Label 'You must fill in the Starting Date field.';
        Text003: Label 'You must fill in the Ending Date field.';
#pragma warning disable AA0470
        Text004: Label 'Do you want to change the capacity for %1 %2?', Comment = 'Do you want to change the capacity for NO No.?';
        Text006: Label 'The capacity for %1 days was changed successfully.';
        Text007: Label 'The capacity for %1 day was changed successfully.';
#pragma warning restore AA0470
        Text008: Label 'The capacity change was unsuccessful.';
#pragma warning restore AA0074

    local procedure SelectCapacity(var CustomizedCalendarChange: Record "Customized Calendar Change") Hours: Decimal
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSelectCapacity(TempDate, CustomizedCalendarChange, WorkTemplateRec, Hours, IsHandled);
        if IsHandled then
            exit(Hours);

        case Date2DWY(TempDate, 1) of
            1:
                Hours := WorkTemplateRec.Monday;
            2:
                Hours := WorkTemplateRec.Tuesday;
            3:
                Hours := WorkTemplateRec.Wednesday;
            4:
                Hours := WorkTemplateRec.Thursday;
            5:
                Hours := WorkTemplateRec.Friday;
            6:
                Hours := WorkTemplateRec.Saturday;
            7:
                Hours := WorkTemplateRec.Sunday;
        end;
    end;

    local procedure SetCalendar(var CustomizedCalendarChange: Record "Customized Calendar Change")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetCalendar(Rec, CustomizedCalendarChange, IsHandled);
        if IsHandled then
            exit;

        if CompanyInformation.Get() then begin
            CompanyInformation.TestField("Base Calendar Code");
            CalendarMgmt.SetSource(CompanyInformation, CustomizedCalendarChange);
        end;
    end;

    local procedure SumWeekTotal()
    begin
        WeekTotal := WorkTemplateRec.Monday + WorkTemplateRec.Tuesday + WorkTemplateRec.Wednesday +
          WorkTemplateRec.Thursday + WorkTemplateRec.Friday + WorkTemplateRec.Saturday + WorkTemplateRec.Sunday;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetCalendar(var Resource: Record Resource; var CustomizedCalendarChange: Record "Customized Calendar Change"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSelectCapacity(TempDate: Date; var CustomizedCalendarChange: Record "Customized Calendar Change"; var WorkTemplateRec: Record "Work-Hour Template"; var Hours: Decimal; var IsHandled: Boolean)
    begin
    end;
}

