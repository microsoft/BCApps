// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Analysis;

using Microsoft.CRM.Opportunity;
using System.Integration;
using System.Visualization;

page 781 "Sales Pipeline Chart"
{
    Caption = 'Sales Pipeline';
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
                    SalesPipelineChartMgt.DrillDown(BusinessChartBuffer, TempSalesCycleStage);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    if not IsChartDataReady then
                        exit;

                    IsChartAddInReady := true;
                    UpdateChart(SalesCycle);
                end;

                trigger Refresh()
                begin
                    if IsChartAddInReady and IsChartDataReady then
                        UpdateChart(SalesCycle);
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(PrevSalesCycle)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Previous Sales Cycle';
                Enabled = PrevSalesCycleAvailable;
                Image = PreviousRecord;
                ToolTip = 'View the previous chart.';

                trigger OnAction()
                begin
                    SalesPipelineChartMgt.SetPrevNextSalesCycle(SalesCycle, NextSalesCycleAvailable, PrevSalesCycleAvailable, -1);
                    UpdateChart(SalesCycle);
                end;
            }
            action(NextSalesCycle)
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Next Sales Cycle';
                Enabled = NextSalesCycleAvailable;
                Image = NextRecord;
                ToolTip = 'View the next chart.';

                trigger OnAction()
                begin
                    SalesPipelineChartMgt.SetPrevNextSalesCycle(SalesCycle, NextSalesCycleAvailable, PrevSalesCycleAvailable, 1);
                    UpdateChart(SalesCycle);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        IsChartDataReady :=
          SalesPipelineChartMgt.SetDefaultSalesCycle(SalesCycle, NextSalesCycleAvailable, PrevSalesCycleAvailable);
    end;

    var
        BusinessChartBuffer: Record "Business Chart Buffer";
        SalesCycle: Record "Sales Cycle";
        TempSalesCycleStage: Record "Sales Cycle Stage" temporary;
        StatusText: Text;
        IsChartAddInReady: Boolean;
        NextSalesCycleAvailable: Boolean;
        PrevSalesCycleAvailable: Boolean;

    protected var
        SalesPipelineChartMgt: Codeunit "Sales Pipeline Chart Mgt.";
        IsChartDataReady: Boolean;

    protected procedure UpdateChart(SalesCycle: Record "Sales Cycle")
    begin
        if not IsChartAddInReady then
            exit;

        SalesPipelineChartMgt.UpdateData(BusinessChartBuffer, TempSalesCycleStage, SalesCycle);
        BusinessChartBuffer.UpdateChart(CurrPage.BusinessChart);
        UpdateStatusText(SalesCycle);
    end;

    local procedure UpdateStatusText(SalesCycle: Record "Sales Cycle")
    begin
        StatusText := SalesCycle.TableCaption + ': ' + SalesCycle.Code;
    end;
}

