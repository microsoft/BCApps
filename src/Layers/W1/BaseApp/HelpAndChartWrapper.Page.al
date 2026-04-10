// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Environment;

using System.Integration;
using System.Visualization;

page 1392 "Help And Chart Wrapper"
{
    Caption = 'Business Performance';
    DeleteAllowed = false;
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field("Status Text"; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status Text';
                Editable = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = true;
                ToolTip = 'Specifies the status of the resource, such as Completed.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = Basic, Suite;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(Point);
                    ChartManagement.DataPointClicked(BusinessChartBuffer, SelectedChartDefinition);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    ChartManagement.AddinReady(SelectedChartDefinition, BusinessChartBuffer);
                    InitializeSelectedChart();
                end;

                trigger Refresh()
                begin
                    UpdateChart();
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Select Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Select Chart';
                Image = SelectChart;
                ToolTip = 'Change the chart that is displayed. You can choose from several charts that show data for different performance indicators.';

                trigger OnAction()
                begin
                    ChartManagement.SelectChart(BusinessChartBuffer, SelectedChartDefinition);
                    InitializeSelectedChart();
                end;
            }
            action("Previous Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Chart';
                Image = PreviousSet;
                ToolTip = 'View the previous chart.';

                trigger OnAction()
                begin
                    SelectedChartDefinition.SetRange(Enabled, true);
                    if SelectedChartDefinition.Next(-1) = 0 then
                        if not SelectedChartDefinition.FindLast() then
                            exit;
                    InitializeSelectedChart();
                end;
            }
            action("Next Chart")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Chart';
                Image = NextSet;
                ToolTip = 'View the next chart.';

                trigger OnAction()
                begin
                    SelectedChartDefinition.SetRange(Enabled, true);
                    if SelectedChartDefinition.Next() = 0 then
                        if not SelectedChartDefinition.FindFirst() then
                            exit;
                    InitializeSelectedChart();
                end;
            }
            group(PeriodLength)
            {
                Caption = 'Period Length';
                Image = Period;
                action(Day)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Day';
                    Image = DueDate;
                    ToolTip = 'Each stack covers one day.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Day);
                    end;
                }
                action(Week)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Week';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one week. The last stack contains data from the start of the week until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Week);
                    end;
                }
                action(Month)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Month';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one month. The last stack contains data from the start of the month until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Month);
                    end;
                }
                action(Quarter)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Quarter';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one quarter. The last stack contains data from the start of the quarter until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Quarter);
                    end;
                }
                action(Year)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Year';
                    Image = DateRange;
                    ToolTip = 'Each stack except for the last stack covers one year. The last stack contains data from the start of the year until the date that is defined by the Show option.';

                    trigger OnAction()
                    begin
                        SetPeriodAndUpdateChart(BusinessChartBuffer."Period Length"::Year);
                    end;
                }
            }
            action(PreviousPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Previous Period';
                Enabled = PreviousNextActionEnabled;
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::Previous);
                    BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Next Period';
                Enabled = PreviousNextActionEnabled;
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::Next);
                    BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
                end;
            }
            action(ChartInformation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart Information';
                Image = AboutNav;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                var
                    Description: Text;
                begin
                    if StatusText = '' then
                        exit;
                    Description := ChartManagement.ChartDescription(SelectedChartDefinition);
                    if Description = '' then
                        Message(NoDescriptionMsg)
                    else
                        Message(Description);
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        LastUsedChart: Record "Last Used Chart";
    begin
        BusinessChartBuffer.Initialize();
        if LastUsedChart.Get(UserId) then
            if SelectedChartDefinition.Get(LastUsedChart."Code Unit ID", LastUsedChart."Chart Name") then;

        InitializeSelectedChart();
    end;

    var
        SelectedChartDefinition: Record "Chart Definition";
        BusinessChartBuffer: Record "Business Chart Buffer";
        ChartManagement: Codeunit "Chart Management";
        StatusText: Text;
        Period: Option " ",Next,Previous;
        PreviousNextActionEnabled: Boolean;
        NoDescriptionMsg: Label 'A description was not specified for this chart.';
        IsChartAddInReady: Boolean;

    local procedure InitializeSelectedChart()
    var
        ErrorText: Text;
    begin
        OnBeforeInitializeSelectedChart(SelectedChartDefinition);
        ChartManagement.SetDefaultPeriodLength(SelectedChartDefinition, BusinessChartBuffer);
        BindSubscription(ChartManagement);
        if not ChartManagement.UpdateChartSafe(SelectedChartDefinition, BusinessChartBuffer, Period::" ", ErrorText) then begin
            UnbindSubscription(ChartManagement);
            StatusText := ErrorText;
            exit;
        end;
        UnbindSubscription(ChartManagement);
        PreviousNextActionEnabled := ChartManagement.UpdateNextPrevious(SelectedChartDefinition);
        ChartManagement.UpdateStatusText(SelectedChartDefinition, BusinessChartBuffer, StatusText);
        UpdateChart();
    end;

    local procedure SetPeriodAndUpdateChart(PeriodLength: Option)
    begin
        ChartManagement.SetPeriodLength(SelectedChartDefinition, BusinessChartBuffer, PeriodLength, false);
        ChartManagement.UpdateChart(SelectedChartDefinition, BusinessChartBuffer, Period::" ");
        ChartManagement.UpdateStatusText(SelectedChartDefinition, BusinessChartBuffer, StatusText);
        UpdateChart();
    end;

    local procedure UpdateChart()
    begin
        if not IsChartAddInReady then
            exit;
        BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInitializeSelectedChart(var ChartDefinition: Record "Chart Definition")
    begin
    end;
}
