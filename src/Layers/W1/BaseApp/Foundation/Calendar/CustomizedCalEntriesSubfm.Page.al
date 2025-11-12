// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 7605 "Customized Cal. Entries Subfm"
{
    Caption = 'Lines';
    DeleteAllowed = false;
    Editable = true;
    InsertAllowed = false;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Customized Calendar Change";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(CurrSourceType; Rec."Source Type")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Source Type';
                    ToolTip = 'Specifies the source type for the calendar entry.';
                    Visible = false;
                }
                field(CurrSourceCode; Rec."Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Source Code';
                    ToolTip = 'Specifies the source code for the calendar entry.';
                    Visible = false;
                }
                field(CurrAdditionalSourceCode; Rec."Additional Source Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Additional Source Code';
                    ToolTip = 'Specifies the calendar entry.';
                    Visible = false;
                }
                field(CurrCalendarCode; Rec."Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Current Calendar Code';
                    Editable = false;
                    ToolTip = 'Specifies the calendar code.';
                    Visible = false;
                }
                field("Period Start"; Rec.Date)
                {
                    ApplicationArea = Suite;
                    Caption = 'Date';
                    Editable = false;
                    ToolTip = 'Specifies the date.';
                }
                field("Period Name"; Rec.Day)
                {
                    ApplicationArea = Suite;
                    Caption = 'Day';
                    Editable = false;
                    ToolTip = 'Specifies the day of the week.';
                }
                field(WeekNo; Date2DWY(Rec.Date, 2))
                {
                    ApplicationArea = Suite;
                    Caption = 'Week No.';
                    Editable = false;
                    ToolTip = 'Specifies the week number for the calendar entries.';
                    Visible = false;
                }
                field(Nonworking; Rec.Nonworking)
                {
                    ApplicationArea = Suite;
                    Caption = 'Nonworking';
                    Editable = true;
                    ToolTip = 'Specifies the date entry as a nonworking day. You can also remove the check mark to return the status to working day.';

                    trigger OnValidate()
                    begin
                        UpdateCusomizedCalendarChanges();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the entry to be applied.';

                    trigger OnValidate()
                    begin
                        UpdateCusomizedCalendarChanges();
                    end;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        if DateRec.Get(DateRec."Period Type"::Date, Rec.Date) then;
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        FoundDate: Boolean;
    begin
        FoundDate := PeriodPageMgt.FindDate(Which, DateRec, "Analysis Period Type"::Day);
        if not FoundDate then
            exit(false);

        if not FindLine(DateRec."Period Start") then
            exit(InsertLine());
        exit(true);
    end;

    trigger OnNextRecord(Steps: Integer): Integer
    var
        ResultSteps: Integer;
    begin
        ResultSteps := PeriodPageMgt.NextDate(Steps, DateRec, "Analysis Period Type"::Day);
        if ResultSteps = 0 then
            exit(0);

        if not FindLine(DateRec."Period Start") then
            if not InsertLine() then
                exit(0);
        exit(ResultSteps);
    end;

    trigger OnOpenPage()
    begin
        DateRec.Reset();
        DateRec.SetFilter("Period Start", '>=%1', 00000101D);
    end;

    var
        DateRec: Record Date;
        CalendarMgmt: Codeunit "Calendar Management";
        PeriodPageMgt: Codeunit PeriodPageManagement;

    protected var
        CurrCalendarChange: Record "Customized Calendar Change";

    local procedure FindLine(TargetDate: Date) FoundLine: Boolean;
    begin
        Rec.Reset();
        Rec.SetRange(Date, TargetDate);
        FoundLine := Rec.FindFirst();
        Rec.Reset();
    end;

    local procedure InsertLine(): Boolean;
    begin
        Rec := CurrCalendarChange;
        Rec.Date := DateRec."Period Start";
        Rec.Day := DateRec."Period No.";
        CalendarMgmt.CheckDateStatus(Rec);
        exit(Rec.Insert());
    end;

    procedure SetCalendarSource(CustomizedCalendarEntry: record "Customized Calendar Entry")
    begin
        CalendarMgmt.SetSource(CustomizedCalendarEntry, CurrCalendarChange);

        CurrPage.Update();
    end;

    protected procedure UpdateCusomizedCalendarChanges()
    var
        CustomizedCalendarChange: Record "Customized Calendar Change";
    begin
        CustomizedCalendarChange.Reset();
        CustomizedCalendarChange.SetRange("Source Type", Rec."Source Type");
        CustomizedCalendarChange.SetRange("Source Code", Rec."Source Code");
        CustomizedCalendarChange.SetRange("Additional Source Code", Rec."Additional Source Code");
        CustomizedCalendarChange.SetRange("Base Calendar Code", Rec."Base Calendar Code");
        CustomizedCalendarChange.SetRange("Recurring System", CustomizedCalendarChange."Recurring System"::" ");
        CustomizedCalendarChange.SetRange(Date, Rec.Date);
        if CustomizedCalendarChange.FindFirst() then
            CustomizedCalendarChange.Delete();

        if not IsInBaseCalendar() then begin
            CustomizedCalendarChange := Rec;
            OnUpdateCusomizedCalendarChanges(CustomizedCalendarChange);
            CustomizedCalendarChange.Insert();
        end;
    end;

    local procedure IsInBaseCalendar(): Boolean
    var
        BaseCalendarChange: Record "Base Calendar Change";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInBaseCalendar(Rec, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if BaseCalendarChange.Get(Rec."Base Calendar Code", Rec."Recurring System"::" ", Rec.Date, Rec.Day) then
            exit(BaseCalendarChange.Nonworking = Rec.Nonworking);

        if BaseCalendarChange.Get(Rec."Base Calendar Code", Rec."Recurring System"::"Weekly Recurring", 0D, Rec.Day) then
            exit(BaseCalendarChange.Nonworking = Rec.Nonworking);

        BaseCalendarChange.SetRange("Base Calendar Code", Rec."Base Calendar Code");
        BaseCalendarChange.SetRange(Day, BaseCalendarChange.Day::" ");
        BaseCalendarChange.SetRange("Recurring System", Rec."Recurring System"::"Annual Recurring");
        if BaseCalendarChange.Find('-') then
            repeat
                if (Date2DMY(BaseCalendarChange.Date, 2) = Date2DMY(Rec.Date, 2)) and
                   (Date2DMY(BaseCalendarChange.Date, 1) = Date2DMY(Rec.Date, 1))
                then
                    exit(BaseCalendarChange.Nonworking = Rec.Nonworking);
            until BaseCalendarChange.Next() = 0;

        exit(not CurrCalendarChange.Nonworking);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateCusomizedCalendarChanges(var CustomizedCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInBaseCalendar(var CustomizedCalendarChange: Record "Customized Calendar Change"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

