// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.RoleCenters;

using Microsoft.Finance.ReceivablesPayables;
using System.Integration;
using System.Visualization;

page 9059 "Acc. Payable Performance"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Payable Performance';
    PageType = CardPart;
    DeleteAllowed = false;

    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            field("Status Text"; StatusText)
            {
                Caption = 'Status Text';
                Editable = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = true;
                ToolTip = 'Specifies the status of the resource, such as Completed.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                trigger DataPointClicked(Point: JsonObject)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(Point);
                    PayablePerformance.DataPointClicked(BusinessChartBuffer, SelectedPayablePerformanceChart);
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    PayablePerformance.AddinReady(SelectedPayablePerformanceChart, BusinessChartBuffer);
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
                Caption = 'Select Chart';
                Image = SelectChart;
                ToolTip = 'Change the chart that is displayed. You can choose from several charts that show data for different performance indicators.';

                trigger OnAction()
                begin
                    PayablePerformance.SelectChart(BusinessChartBuffer, SelectedPayablePerformanceChart);
                    InitializeSelectedChart();
                end;
            }
            action("Previous Chart")
            {
                Caption = 'Previous Chart';
                Image = PreviousSet;
                ToolTip = 'View the previous chart.';

                trigger OnAction()
                begin
                    SelectedPayablePerformanceChart.SetRange(Enabled, true);
                    if SelectedPayablePerformanceChart.Next(-1) = 0 then
                        if not SelectedPayablePerformanceChart.FindLast() then
                            exit;
                    InitializeSelectedChart();
                end;
            }
            action("Next Chart")
            {
                Caption = 'Next Chart';
                Image = NextSet;
                ToolTip = 'View the next chart.';

                trigger OnAction()
                begin
                    SelectedPayablePerformanceChart.SetRange(Enabled, true);
                    if SelectedPayablePerformanceChart.Next() = 0 then
                        if not SelectedPayablePerformanceChart.FindFirst() then
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
                Caption = 'Previous Period';
                Enabled = PreviousNextActionEnabled;
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    PayablePerformance.UpdateChart(SelectedPayablePerformanceChart, BusinessChartBuffer, Period::Previous);
                    BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
                end;
            }
            action(NextPeriod)
            {
                Caption = 'Next Period';
                Enabled = PreviousNextActionEnabled;
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    PayablePerformance.UpdateChart(SelectedPayablePerformanceChart, BusinessChartBuffer, Period::Next);
                    BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
                end;
            }
            action(ChartInformation)
            {
                Caption = 'Chart Information';
                Image = AboutNav;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                var
                    Description: Text;
                begin
                    if StatusText = '' then
                        exit;

                    Description := PayablePerformance.ChartDescription(SelectedPayablePerformanceChart);
                    if Description = '' then
                        Message(NoDescriptionMsg)
                    else
                        Message(Description);
                end;
            }
        }
    }

    var
        SelectedPayablePerformanceChart: Record "Acc. Payable Performance Chart";
        BusinessChartBuffer: Record "Business Chart Buffer";
        PayablePerformance: Codeunit "Acc. Payable Performance";
        StatusText: Text;
        Period: Option " ",Next,Previous;
        PreviousNextActionEnabled: Boolean;
        NoDescriptionMsg: Label 'A description was not specified for this chart.';
        IsChartAddInReady: Boolean;

    trigger OnOpenPage()
    var
        LastUsedChart: Record "Last Used Chart";
    begin
        BusinessChartBuffer.Initialize();
        if LastUsedChart.Get(UserId) then
            if SelectedPayablePerformanceChart.Get(LastUsedChart."Code Unit ID", LastUsedChart."Chart Name") then;

        InitializeSelectedChart();
    end;

    local procedure InitializeSelectedChart()
    var
        ErrorText: Text;
    begin
        PayablePerformance.SetDefaultPeriodLength(SelectedPayablePerformanceChart, BusinessChartBuffer);
        BindSubscription(PayablePerformance);
        if not PayablePerformance.UpdateChartSafe(SelectedPayablePerformanceChart, BusinessChartBuffer, Period::" ", ErrorText) then begin
            UnbindSubscription(PayablePerformance);
            StatusText := ErrorText;
            exit;
        end;
        UnbindSubscription(PayablePerformance);
        PayablePerformance.UpdateStatusText(SelectedPayablePerformanceChart, BusinessChartBuffer, StatusText);
        UpdateChart();
    end;

    local procedure SetPeriodAndUpdateChart(NewPeriodLength: Option)
    begin
        PayablePerformance.SetPeriodLength(SelectedPayablePerformanceChart, BusinessChartBuffer, NewPeriodLength, false);
        PayablePerformance.UpdateChart(SelectedPayablePerformanceChart, BusinessChartBuffer, Period::" ");
        PayablePerformance.UpdateStatusText(SelectedPayablePerformanceChart, BusinessChartBuffer, StatusText);
        UpdateChart();
    end;

    local procedure UpdateChart()
    begin
        if not IsChartAddInReady then
            exit;

        BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
    end;
}
