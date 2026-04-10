// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.TimeSheet;

using System.Integration;
using System.Visualization;

page 972 "Time Sheet Chart"
{
    Caption = 'Time Sheets';
    PageType = CardPart;
    SourceTable = "Business Chart Buffer";

    layout
    {
        area(content)
        {
            field(StatusText; StatusText)
            {
                ApplicationArea = Jobs;
                Caption = 'Status Text';
                ShowCaption = false;
                ToolTip = 'Specifies the status of the chart.';
            }
            usercontrol(BusinessChart; BusinessChart)
            {
                ApplicationArea = Jobs;

                trigger DataPointClicked(Point: JsonObject)
                begin
                    Rec.SetDrillDownIndexes(Point);
                    TimeSheetChartMgt.DrillDown(Rec);
                end;

                trigger DataPointDoubleClicked(Point: JsonObject)
                begin
                end;

                trigger AddInReady()
                begin
                    TimeSheetChartMgt.OnOpenPage(TimeSheetChartSetup);
                    UpdateStatus();
                    IsChartAddInReady := true;
                    if IsChartDataReady then
                        UpdateChart();
                end;

                trigger Refresh()
                begin
                    if IsChartDataReady and IsChartAddInReady then begin
                        NeedsUpdate := true;
                        UpdateChart();
                    end;
                end;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action("Previous Period")
            {
                ApplicationArea = Jobs;
                Caption = 'Previous Period';
                Image = PreviousSet;
                ToolTip = 'Show the information based on the previous period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    TimeSheetChartSetup.FindPeriod(SetWanted::Previous);
                    UpdateStatus();
                end;
            }
            action("Next Period")
            {
                ApplicationArea = Jobs;
                Caption = 'Next Period';
                Image = NextSet;
                ToolTip = 'Show the information based on the next period. If you set the View by field to Day, the date filter changes to the day before.';

                trigger OnAction()
                begin
                    TimeSheetChartSetup.FindPeriod(SetWanted::Next);
                    UpdateStatus();
                end;
            }
            group("Show by")
            {
                Caption = 'Show by';
                Image = View;
                action(Status)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Status';
                    Image = "Report";
                    ToolTip = 'View the approval status of the time sheet.';

                    trigger OnAction()
                    begin
                        TimeSheetChartSetup.SetShowBy(TimeSheetChartSetup."Show by"::Status);
                        UpdateStatus();
                    end;
                }
                action(Type)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Type';
                    ToolTip = 'Specifies the chart type.';

                    trigger OnAction()
                    begin
                        TimeSheetChartSetup.SetShowBy(TimeSheetChartSetup."Show by"::Type);
                        UpdateStatus();
                    end;
                }
                action(Posted)
                {
                    ApplicationArea = Jobs;
                    Caption = 'Posted';
                    Image = PostedTimeSheet;
                    ToolTip = 'Specifies the sum of time sheet hours for posted time sheets.';

                    trigger OnAction()
                    begin
                        TimeSheetChartSetup.SetShowBy(TimeSheetChartSetup."Show by"::Posted);
                        UpdateStatus();
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateChart();
    end;

    trigger OnFindRecord(Which: Text): Boolean
    begin
        UpdateChart();
        IsChartDataReady := true;
    end;

    var
        TimeSheetChartSetup: Record "Time Sheet Chart Setup";
        OldTimeSheetChartSetup: Record "Time Sheet Chart Setup";
        TimeSheetChartMgt: Codeunit "Time Sheet Chart Mgt.";
        StatusText: Text[250];
        NeedsUpdate: Boolean;
        SetWanted: Option Previous,Next;
        IsChartDataReady: Boolean;
        IsChartAddInReady: Boolean;

    local procedure UpdateChart()
    begin
        if not NeedsUpdate then
            exit;
        if not IsChartAddInReady then
            exit;
        TimeSheetChartMgt.UpdateData(Rec);
        Rec.UpdateChart(CurrPage.BusinessChart);
        UpdateStatus();

        NeedsUpdate := false;
    end;

    local procedure UpdateStatus()
    begin
        NeedsUpdate := NeedsUpdate or IsSetupChanged();

        OldTimeSheetChartSetup := TimeSheetChartSetup;

        if NeedsUpdate then
            StatusText := TimeSheetChartSetup.GetCurrentSelectionText();
    end;

    local procedure IsSetupChanged(): Boolean
    begin
        exit(
          (OldTimeSheetChartSetup."Starting Date" <> TimeSheetChartSetup."Starting Date") or
          (OldTimeSheetChartSetup."Show by" <> TimeSheetChartSetup."Show by"));
    end;
}

