// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CashFlow.Forecast;

using Microsoft.CashFlow.Setup;
using System.Integration;
using System.Visualization;

page 869 "Cash Flow Forecast Chart"
{
    Caption = 'Cash Flow Forecast';
    PageType = CardPart;
    ShowFilter = false;
    SourceTable = "Business Chart Buffer";

    layout
    {
        area(content)
        {
            group(Disclaimer)
            {
                Caption = ' ';
                ShowCaption = false;
                Editable = false;
                Visible = IsCashFlowSetUp;
                InstructionalText = 'AI generated suggestions may not always be accurate. Please validate results for correctness before using content provided.';
            }
            field(StatusText; StatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Status Text';
                Editable = false;
                ShowCaption = false;
                ToolTip = 'Specifies the status of the cash flow forecast.';
                Visible = IsCashFlowSetUp;
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = Basic, Suite;
                Visible = IsCashFlowSetUp;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    Rec.SetDrillDownIndexes(Point);
                    CashFlowChartMgt.DrillDown(Rec);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    CashFlowChartMgt.OnOpenPage(CashFlowChartSetup);
                    UpdateStatus();
                    IsChartAddInReady := true;
                    if IsChartDataReady then
                        UpdateChart();
                end;

                trigger Refresh()
                begin
                    NeedsUpdate := true;
                    UpdateChart();
                end;
            }
            field(NotSetupLbl; NotSetupLbl)
            {
                ApplicationArea = Basic, Suite;
                Editable = false;
                ShowCaption = false;
                Visible = not IsCashFlowSetUp;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group("Chart Options")
            {
                Caption = 'Chart Options';
                Visible = IsCashFlowSetUp;
                group(Show)
                {
                    Caption = 'Show';
                    Image = View;
                    Visible = IsCashFlowSetUp;
                    action(AccumulatedCash)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Accumulated Cash';
                        ToolTip = 'View the accumulated cash flow over a selected time period. The accumulated cash flow values are plotted in a line chart. In the line chart, the timeline is distributed along the horizontal axis, and all values are distributed along the vertical axis.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetShow(CashFlowChartSetup.Show::"Accumulated Cash");
                            UpdateStatus();
                        end;
                    }
                    action(ChangeInCash)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Change in Cash';
                        ToolTip = 'View the changed cash inflows and outflows over a selected time period. The changed cash inflows and outflows are plotted in a column chart. In the column chart, the timeline is distributed along the horizontal axis, and all values are organized along the vertical axis.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetShow(CashFlowChartSetup.Show::"Change in Cash");
                            UpdateStatus();
                        end;
                    }
                    action(Combined)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Combined';
                        ToolTip = 'View, in one chart, the accumulated cash flow and changed cash flow over a selected time period.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetShow(CashFlowChartSetup.Show::Combined);
                            UpdateStatus();
                        end;
                    }
                }
                group(StartDate)
                {
                    Caption = 'Start Date';
                    Image = Start;
                    Visible = IsCashFlowSetUp;
                    action(FisrtEntryDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'First Entry Date';
                        ToolTip = 'View when the first forecast entry was made.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetStartDate(CashFlowChartSetup."Start Date"::"First Entry Date");
                            UpdateStatus();
                        end;
                    }
                    action(WorkDate)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Working Date';
                        ToolTip = 'View the work date that the chart is based on.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetStartDate(CashFlowChartSetup."Start Date"::"Working Date");
                            UpdateStatus();
                        end;
                    }
                }
                group(PeriodLength)
                {
                    Caption = 'Period Length';
                    Image = Period;
                    Visible = IsCashFlowSetUp;
                    action(Day)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Day';
                        ToolTip = 'Each stack covers one day.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetPeriodLength(CashFlowChartSetup."Period Length"::Day);
                            UpdateStatus();
                        end;
                    }
                    action(Week)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Week';
                        ToolTip = 'Show forecast entries summed for one week.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetPeriodLength(CashFlowChartSetup."Period Length"::Week);
                            UpdateStatus();
                        end;
                    }
                    action(Month)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Month';
                        ToolTip = 'Each stack except for the last stack covers one month. The last stack contains data from the start of the month until the date that is defined by the Show option.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetPeriodLength(CashFlowChartSetup."Period Length"::Month);
                            UpdateStatus();
                        end;
                    }
                    action(Quarter)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Quarter';
                        ToolTip = 'Each stack except for the last stack covers one quarter. The last stack contains data from the start of the quarter until the date that is defined by the Show option.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetPeriodLength(CashFlowChartSetup."Period Length"::Quarter);
                            UpdateStatus();
                        end;
                    }
                    action(Year)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Year';
                        ToolTip = 'Show pending payments summed for one year. Overdue payments are shown as amounts within specific years from the due date going back five years from today''s date.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetPeriodLength(CashFlowChartSetup."Period Length"::Year);
                            UpdateStatus();
                        end;
                    }
                }
                group(GroupBy)
                {
                    Caption = 'Group By';
                    Image = Group;
                    Visible = IsCashFlowSetUp;
                    action(PosNeg)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Positive/Negative';
                        ToolTip = 'View the positive cash inflows above the horizontal axis and the negative cash outflows below the horizontal axis.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetGroupBy(CashFlowChartSetup."Group By"::"Positive/Negative");
                            UpdateStatus();
                        end;
                    }
                    action(Account)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Account No.';
                        ToolTip = 'View the related cash flow account.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetGroupBy(CashFlowChartSetup."Group By"::"Account No.");
                            UpdateStatus();
                        end;
                    }
                    action(SourceType)
                    {
                        ApplicationArea = Basic, Suite;
                        Caption = 'Source Type';
                        ToolTip = 'View the type of the source for the forecast.';

                        trigger OnAction()
                        begin
                            CashFlowChartSetup.SetGroupBy(CashFlowChartSetup."Group By"::"Source Type");
                            UpdateStatus();
                        end;
                    }
                }
            }
            group("Manual Adjustment")
            {
                Caption = 'Manual Adjustment';
                Visible = IsCashFlowSetUp;
                action("Edit Manual Revenues")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit Manual Revenues';
                    Image = CashFlow;
                    ToolTip = 'Add, edit or delete manual revenues.';
                    Visible = IsCashFlowSetUp;

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Cash Flow Manual Revenues");
                    end;
                }
                action("Edit Manual Expenses")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Edit Manual Expenses';
                    Image = CashFlow;
                    ToolTip = 'Add, edit or delete manual expenses.';
                    Visible = IsCashFlowSetUp;

                    trigger OnAction()
                    begin
                        PAGE.RunModal(PAGE::"Cash Flow Manual Expenses");
                    end;
                }
            }
            action("Open Assisted Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open Assisted Setup';
                Image = Setup;
                ToolTip = 'Opens the assisted cash flow forecast setup';
                Visible = not IsCashFlowSetUp;

                trigger OnAction()
                begin
                    PAGE.RunModal(PAGE::"Cash Flow Forecast Wizard");
                    IsCashFlowSetUp := CashFlowForecastSetupExists();
                    CurrPage.Update();
                end;
            }
            action("Recalculate Forecast")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalculate Forecast';
                Image = Refresh;
                ToolTip = 'Update the chart with values created by other users since you opened the chart.';
                Visible = IsCashFlowSetUp;

                trigger OnAction()
                begin
                    RecalculateAndUpdateChart();
                end;
            }
            action(ChartInformation)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Chart Information';
                Image = AboutNav;
                ToolTip = 'View a description of the chart.';

                trigger OnAction()
                begin
                    Message(ChartDescriptionMsg);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        UpdateChart();
        IsChartDataReady := true;
        if not IsCashFlowSetUp then
            exit(true);
    end;

    trigger OnInit()
    begin
        IsCashFlowSetUp := CashFlowForecastSetupExists();
    end;

    var
        CashFlowChartSetup: Record "Cash Flow Chart Setup";
        OldCashFlowChartSetup: Record "Cash Flow Chart Setup";
        CashFlowChartMgt: Codeunit "Cash Flow Chart Mgt.";
        StatusText: Text;
        NeedsUpdate: Boolean;
        IsChartDataReady: Boolean;
        IsChartAddInReady: Boolean;
        IsCashFlowSetUp: Boolean;
        NotSetupLbl: Label 'Cash Flow Forecast is not set up. An Assisted Setup is available for easy set up.';
        ChartDescriptionMsg: Label 'Shows the expected movement of money into or out of your company.';
        ConfirmRecalculationQst: Label 'You are about to update the information in the chart. This can take some time. Do you want to continue?';

    local procedure UpdateChart()
    begin
        if not NeedsUpdate then
            exit;
        if not IsChartAddInReady then
            exit;
        if not IsCashFlowSetUp then
            exit;

        if CashFlowChartMgt.UpdateData(Rec) then
            Rec.UpdateChart(CurrPage.BusinessChart);
        UpdateStatus();

        NeedsUpdate := false;
    end;

    local procedure UpdateStatus()
    begin
        NeedsUpdate := NeedsUpdate or IsSetupChanged();
        if not NeedsUpdate then
            exit;

        OldCashFlowChartSetup := CashFlowChartSetup;
        StatusText := CashFlowChartSetup.GetCurrentSelectionText();
    end;

    local procedure IsSetupChanged(): Boolean
    begin
        exit(
          (OldCashFlowChartSetup."Period Length" <> CashFlowChartSetup."Period Length") or
          (OldCashFlowChartSetup.Show <> CashFlowChartSetup.Show) or
          (OldCashFlowChartSetup."Start Date" <> CashFlowChartSetup."Start Date") or
          (OldCashFlowChartSetup."Group By" <> CashFlowChartSetup."Group By"));
    end;

    local procedure CashFlowForecastSetupExists(): Boolean
    var
        CashFlowSetup: Record "Cash Flow Setup";
    begin
        if not CashFlowSetup.Get() then
            exit(false);
        exit(CashFlowSetup."CF No. on Chart in Role Center" <> '');
    end;

    local procedure RecalculateAndUpdateChart()
    var
        CashFlowSetup: Record "Cash Flow Setup";
        CashFlowManagement: Codeunit "Cash Flow Management";
    begin
        if not Confirm(ConfirmRecalculationQst) then
            exit;
        CashFlowSetup.Get();
        CashFlowManagement.UpdateCashFlowForecast(CashFlowSetup."Azure AI Enabled");
        CurrPage.Update(false);

        NeedsUpdate := true;
        UpdateStatus();
    end;
}

