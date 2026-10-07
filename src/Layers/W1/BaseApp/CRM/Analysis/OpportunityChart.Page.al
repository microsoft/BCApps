// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Analysis;

using Microsoft.CRM.Opportunity;
using System.Integration;
using System.Utilities;
using System.Visualization;

page 782 "Opportunity Chart"
{
    Caption = 'Opportunities';
    PageType = CardPart;

    layout
    {
        area(content)
        {
            field(StatusText; StatusText)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Status Text';
                Enabled = false;
                ShowCaption = false;
                Style = StrongAccent;
                StyleExpr = true;
                ToolTip = 'Specifies the status of the chart.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = RelationshipMgmt;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    BusinessChartBuffer.SetDrillDownIndexes(Point);
                    OppChartMgt.DrillDown(BusinessChartBuffer, Period, Opportunity.Status.AsInteger());
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    IsChartAddInReady := true;
                    UpdateChart(Period, Opportunity);
                end;

                trigger Refresh()
                begin
                    if IsChartAddInReady then
                        UpdateChart(Period, Opportunity);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Opportunity)
            {
                Caption = 'Opportunity';
                Image = SelectChart;
                action(NotStarted)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Not Started';
                    ToolTip = 'View opportunities not started.';

                    trigger OnAction()
                    begin
                        Opportunity.Status := Opportunity.Status::"Not Started";
                        UpdateChart(Period, Opportunity);
                    end;
                }
                action(InProgress)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'In Progress';
                    ToolTip = 'View opportunities in progress.';

                    trigger OnAction()
                    begin
                        Opportunity.Status := Opportunity.Status::"In Progress";
                        UpdateChart(Period, Opportunity);
                    end;
                }
                action(Won)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Won';
                    ToolTip = 'View opportunities won.';

                    trigger OnAction()
                    begin
                        Opportunity.Status := Opportunity.Status::Won;
                        UpdateChart(Period, Opportunity);
                    end;
                }
                action(Lost)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Lost';
                    ToolTip = 'View opportunities lost.';

                    trigger OnAction()
                    begin
                        Opportunity.Status := Opportunity.Status::Lost;
                        UpdateChart(Period, Opportunity);
                    end;
                }
            }
            group(Period)
            {
                Caption = 'Period';
                Image = Period;
                action(Day)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Day';
                    ToolTip = 'View the day.';

                    trigger OnAction()
                    begin
                        Period."Period Type" := Period."Period Type"::Date;
                        SetPeriodAndUpdateChart(Period);
                    end;
                }
                action(Week)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Week';
                    ToolTip = 'View the week.';

                    trigger OnAction()
                    begin
                        Period."Period Type" := Period."Period Type"::Week;
                        SetPeriodAndUpdateChart(Period);
                    end;
                }
                action(Month)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Month';
                    ToolTip = 'View the month.';

                    trigger OnAction()
                    begin
                        Period."Period Type" := Period."Period Type"::Month;
                        SetPeriodAndUpdateChart(Period);
                    end;
                }
                action(Quarter)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Quarter';
                    ToolTip = 'View the quarter.';

                    trigger OnAction()
                    begin
                        Period."Period Type" := Period."Period Type"::Quarter;
                        SetPeriodAndUpdateChart(Period);
                    end;
                }
                action(Year)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Year';
                    ToolTip = 'View the year.';

                    trigger OnAction()
                    begin
                        Period."Period Type" := Period."Period Type"::Year;
                        SetPeriodAndUpdateChart(Period);
                    end;
                }
            }
            action(PrevPeriod)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Previous Period';
                Image = PreviousRecord;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    OppChartMgt.SetPrevPeriod(Period);
                    UpdateChart(Period, Opportunity);
                end;
            }
            action(NextPeriod)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Next Period';
                Image = NextRecord;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    OppChartMgt.SetNextPeriod(Period);
                    UpdateChart(Period, Opportunity);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        OppChartMgt.SetDefaultOppStatus(Opportunity);
        OppChartMgt.SetDefaultPeriod(Period);
    end;

    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        Opportunity: Record Opportunity;
        Period: Record Date;
        OppChartMgt: Codeunit "Opportunity Chart Mgt.";
        StatusText: Text;
        IsChartAddInReady: Boolean;

    local procedure SetPeriodAndUpdateChart(var Period: Record Date)
    begin
        OppChartMgt.SetPeriodRange(Period);
        UpdateChart(Period, Opportunity);
    end;

    local procedure UpdateChart(Period: Record Date; Opportunity: Record Opportunity)
    begin
        if not IsChartAddInReady then
            exit;

        OppChartMgt.UpdateData(BusinessChartBuffer, Period, Opportunity.Status.AsInteger());
        BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
        UpdateStatusText(Period, Opportunity);
    end;

    local procedure UpdateStatusText(Period: Record Date; Opportunity: Record Opportunity)
    begin
        StatusText := Format(Opportunity.Status) + ' | ' + Format(Period."Period Type") + ' | ';
        case Opportunity.Status of
            Opportunity.Status::"Not Started",
          Opportunity.Status::"In Progress":
                StatusText += ' .. ' + Format(Period."Period End");
            Opportunity.Status::Won,
          Opportunity.Status::Lost:
                StatusText += Format(Period."Period Start") + ' .. ' + Format(Period."Period End")
        end;
    end;
}

