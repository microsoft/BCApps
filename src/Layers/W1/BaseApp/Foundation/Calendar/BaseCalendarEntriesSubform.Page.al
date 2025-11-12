// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Calendar;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Period;
using System.Utilities;

page 7604 "Base Calendar Entries Subform"
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
                field(CurrentCalendarCode; Rec."Base Calendar Code")
                {
                    ApplicationArea = Suite;
                    Caption = 'Base Calendar Code';
                    Editable = false;
                    ToolTip = 'Specifies which base calendar was used as the basis.';
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
                        UpdateBaseCalendarChanges();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Suite;
                    Caption = 'Description';
                    ToolTip = 'Specifies the description of the entry to be applied.';

                    trigger OnValidate()
                    begin
                        UpdateBaseCalendarChanges();
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
        OnOpenPageOnAfterFilterDateRecord(Rec, DateRec);
    end;

    var
        DateRec: Record Date;
        CurrCalendarChange: Record "Customized Calendar Change";
        PeriodPageMgt: Codeunit PeriodPageManagement;
        CalendarMgmt: Codeunit "Calendar Management";

    local procedure FindLine(TargetDate: Date) FoundLine: Boolean;
    begin
        Rec.Reset();
        Rec.SetRange(Date, TargetDate);
        FoundLine := Rec.FindFirst();
        Rec.Reset();
    end;

    local procedure InsertLine(): Boolean;
    begin
        if CurrCalendarChange.IsBlankSource() then
            exit;
        Rec := CurrCalendarChange;
        Rec.Date := DateRec."Period Start";
        Rec.Day := DateRec."Period No.";
        CalendarMgmt.CheckDateStatus(Rec);
        exit(Rec.Insert());
    end;

    procedure SetCalendarSource(BaseCalendar: Record "Base Calendar")
    begin
        Rec.DeleteAll();
        CalendarMgmt.SetSource(BaseCalendar, CurrCalendarChange);
        CurrPage.Update();
    end;

    procedure UpdateBaseCalendarChanges()
    var
        BaseCalendarChange: Record "Base Calendar Change";
    begin
        BaseCalendarChange.Reset();
        BaseCalendarChange.SetRange("Base Calendar Code", Rec."Base Calendar Code");
        BaseCalendarChange.SetRange(Date, Rec.Date);
        if BaseCalendarChange.FindFirst() then
            BaseCalendarChange.Delete();
        BaseCalendarChange.Init();
        BaseCalendarChange."Base Calendar Code" := Rec."Base Calendar Code";
        BaseCalendarChange.Date := Rec.Date;
        BaseCalendarChange.Description := Rec.Description;
        BaseCalendarChange.Nonworking := Rec.Nonworking;
        BaseCalendarChange.Day := Rec.Day;
        OnUpdateBaseCalendarChanges(BaseCalendarChange, Rec);
        BaseCalendarChange.Insert();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateBaseCalendarChanges(var BaseCalendarChange: Record "Base Calendar Change"; var CustCalendarChange: Record "Customized Calendar Change")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenPageOnAfterFilterDateRecord(var CustomizedCalendarChange: Record "Customized Calendar Change"; var DateRec: Record Date)
    begin
    end;
}

