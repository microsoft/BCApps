// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.FinancialReports;
using System.Integration;
using System.Visualization;

page 762 "Finance Performance"
{
    Caption = 'Finance Performance';
    PageType = CardPart;
    SourceTable = "Business Chart Buffer";

    layout
    {
        area(content)
        {
            field("Status Text"; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status Text';
                Enabled = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = true;
                ToolTip = 'Specifies the status of the chart.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    Rec.SetDrillDownIndexes(Point);
                    AccSchedChartManagement.DrillDown(Rec, AccountSchedulesChartSetup);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    UpdateChart(Period::" ");
                end;

                trigger Refresh()
                begin
                    if IsChartAddInReady then begin
                        Rec.InitializePeriodFilter(0D, 0D);
                        UpdateChart(Period::" ");
                    end;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(SelectChart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Chart';
                Image = SelectChart;
                ToolTip = 'Select the analysis report that the chart will be based on.';

                trigger OnAction()
                var
                    AccountSchedulesChartSetup2: Record "Account Schedules Chart Setup";
                begin
                    AccountSchedulesChartSetup2.SetFilter("User ID", '%1|%2', UserId, '');
                    AccountSchedulesChartSetup2 := AccountSchedulesChartSetup;
                    if PAGE.RunModal(0, AccountSchedulesChartSetup2) = ACTION::LookupOK then begin
                        AccountSchedulesChartSetup := AccountSchedulesChartSetup2;
                        Rec.InitializePeriodFilter(0D, 0D);
                        UpdateChart(Period::" ");
                    end;
                end;
            }
            action(PreviousChart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Chart';
                Image = PreviousRecord;
                ToolTip = 'View the previous chart.';

                trigger OnAction()
                begin
                    if StatusText <> '' then
                        MoveAndUpdateChart(Period::" ", -1)
                end;
            }
            action(NextChart)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Chart';
                Image = NextRecord;
                ToolTip = 'View the next chart.';

                trigger OnAction()
                begin
                    if StatusText <> '' then
                        MoveAndUpdateChart(Period::" ", 1)
                end;
            }
            separator(Action5)
            {
            }
            group(PeriodLength)
            {
                Caption = 'Period Length';
                Image = Period;
                action(Day)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Day';
                    ToolTip = 'Each stack covers one day.';

                    trigger OnAction()
                    begin
                        AccountSchedulesChartSetup.SetPeriodLength(AccountSchedulesChartSetup."Period Length"::Day);
                        UpdateChart(Period::" ");
                    end;
                }
                action(Week)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Week';
                    ToolTip = 'Each stack except for the last stack covers one week. The last stack contains data from the start of the week until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        AccountSchedulesChartSetup.SetPeriodLength(AccountSchedulesChartSetup."Period Length"::Week);
                        UpdateChart(Period::" ");
                    end;
                }
                action(Month)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Month';
                    ToolTip = 'Each stack except for the last stack covers one month. The last stack contains data from the start of the month until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        AccountSchedulesChartSetup.SetPeriodLength(AccountSchedulesChartSetup."Period Length"::Month);
                        UpdateChart(Period::" ");
                    end;
                }
                action(Quarter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quarter';
                    ToolTip = 'Each stack except for the last stack covers one quarter. The last stack contains data from the start of the quarter until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        AccountSchedulesChartSetup.SetPeriodLength(AccountSchedulesChartSetup."Period Length"::Quarter);
                        UpdateChart(Period::" ");
                    end;
                }
                action(Year)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    ToolTip = 'Each stack except for the last stack covers one year. The last stack contains data from the start of the year until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        AccountSchedulesChartSetup.SetPeriodLength(AccountSchedulesChartSetup."Period Length"::Year);
                        UpdateChart(Period::" ");
                    end;
                }
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    UpdateChart(Period::Previous);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    UpdateChart(Period::Next);
                end;
            }
            separator(Action7)
            {
            }
            action(ChartInformation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart Information';
                Image = AboutNav;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                begin
                    if StatusText = '' then
                        exit;
                    if AccountSchedulesChartSetup.Description = '' then
                        Message(NoDescriptionMsg)
                    else
                        Message(AccountSchedulesChartSetup.Description);
                end;
            }
        }
    }

    var
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
        StatusText: Text[250];
        Period: Option " ",Next,Previous;
#pragma warning disable AA0074
        Text001: Label '%1 | %2 (Updated %3)', Comment = '%1 Account Schedule Chart Setup Name, %2 Period Length, %3 Current time';
        Text002: Label '%1 | %2..%3 | %4 (Updated %5)', Comment = '%1 Account Schedule Chart Setup Name, %2 = Start Date, %3 = End Date, %4 Period Length, %5 Current time';
#pragma warning restore AA0074
        NoDescriptionMsg: Label 'A description was not specified for this chart.';
        IsChartAddInReady: Boolean;

    local procedure UpdateChart(Period: Option ,Next,Previous)
    begin
        MoveAndUpdateChart(Period, 0);
    end;

    local procedure MoveAndUpdateChart(Period: Option ,Next,Previous; Move: Integer)
    begin
        if not IsChartAddInReady then
            exit;
        AccSchedChartManagement.GetSetupRecordset(AccountSchedulesChartSetup, AccountSchedulesChartSetup.Name, Move);
        AccSchedChartManagement.UpdateData(Rec, Period, AccountSchedulesChartSetup);
        Rec.UpdateChart(CurrPage.BusinessChart);
        StatusText := GetCurrentSelectionText(Rec."Period Filter Start Date", Rec."Period Filter End Date");
    end;

    local procedure GetCurrentSelectionText(FromDate: Date; ToDate: Date): Text[100]
    begin
        case AccountSchedulesChartSetup."Base X-Axis on" of
            AccountSchedulesChartSetup."Base X-Axis on"::Period:
                exit(StrSubstNo(Text001, AccountSchedulesChartSetup.Name, AccountSchedulesChartSetup."Period Length", Time));
            AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
              AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                exit(StrSubstNo(Text002, AccountSchedulesChartSetup.Name, FromDate, ToDate, AccountSchedulesChartSetup."Period Length", Time));
        end;
    end;
}

