// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Project.Analysis;

using Microsoft.Projects.Project.Job;
using System.Integration;
using System.Visualization;

page 730 "Job Act to Bud Cost Chart"
{
    Caption = 'Project Act to Bud Cost Chart';
    PageType = CardPart;
    SourceTable = Job;

    layout
    {
        area(content)
        {
            usercontrol(Chart; BusinessChart)
            {
                ApplicationArea = Jobs;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    BusChartBuf.SetDrillDownIndexes(Point);
                    JobChartMgt.DataPointClicked(BusChartBuf, TempJob);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    ChartIsReady := true;
                    UpdateChart(DefaultChartType());
                end;

                trigger Refresh()
                begin
                    if ChartIsReady then
                        UpdateChart(CurrentChartType);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            group(Options)
            {
                Caption = 'Options';
                group("Chart Type")
                {
                    Caption = 'Chart Type';
                    action(Default)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Default';
                        ToolTip = 'Select the default graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(DefaultChartType());
                        end;
                    }
                    action(Column)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Column';
                        ToolTip = 'Select the column graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(Enum::"Business Chart Type"::Column);
                        end;
                    }
                    action(Line)
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Line';
                        ToolTip = 'Select the line graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(Enum::"Business Chart Type"::Line);
                        end;
                    }
                    action("Stacked Column")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Stacked Column';
                        ToolTip = 'Select the stacked column graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(Enum::"Business Chart Type"::StackedColumn);
                        end;
                    }
                    action("Stacked Area")
                    {
                        ApplicationArea = Jobs;
                        Caption = 'Stacked Area';
                        ToolTip = 'Select the stacked area graphing option for this chart.';

                        trigger OnAction()
                        begin
                            UpdateChart(Enum::"Business Chart Type"::StackedArea);
                        end;
                    }
                }
            }
        }
    }

    var
        BusChartBuf: Record "Business Chart Buffer";
        TempJob: Record Job temporary;
        JobChartMgt: Codeunit "Job Chart Mgt";
        ChartIsReady: Boolean;
        CurrentChartType: Enum "Business Chart Type";

    local procedure UpdateChart(NewChartType: Enum "Business Chart Type")
    begin
        if not ChartIsReady then
            exit;

        JobChartMgt.CreateChart(BusChartBuf, TempJob, NewChartType, Enum::"Job Chart Type"::"Actual to Budget Cost");
        BusChartBuf.UpdateChart(CurrPage.Chart);
        CurrentChartType := NewChartType;
    end;

    local procedure DefaultChartType(): Enum "Business Chart Type"
    begin
        exit(Enum::"Business Chart Type"::Column);
    end;
}

