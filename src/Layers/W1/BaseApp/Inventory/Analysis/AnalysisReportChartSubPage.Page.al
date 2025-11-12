// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 778 "Analysis Report Chart SubPage"
{
    Caption = 'Analysis Report Chart SubPage';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Analysis Report Chart Line";

    layout
    {
        area(content)
        {
            repeater(Group)
            {
                field("Analysis Line Template Name"; Rec."Analysis Line Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Original Measure Name"; Rec."Original Measure Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the analysis report columns or lines that you select to insert in the Analysis Report Chart Setup window.';
                    Visible = false;
                }
                field("Measure Name"; Rec."Measure Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the analysis report columns or lines that the measures on the y-axis in the specific chart are based on.';
                }
                field("Chart Type"; Rec."Chart Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how the analysis report values are represented graphically in the specific chart.';
                    Visible = IsMeasure;

                    trigger OnValidate()
                    begin
                        if Rec."Chart Type" = Rec."Chart Type"::" " then
                            CurrPage.Update();
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                ApplicationArea = Suite;
                Caption = 'Edit';
                Image = EditLines;
                ToolTip = 'Edit the chart.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartLinePage: Page "Analysis Report Chart Line";
                    AnalysisReportChartMatrix: Page "Analysis Report Chart Matrix";
                begin
                    SetFilters(AnalysisReportChartLine);
                    AnalysisReportChartLine.SetRange("Chart Type");
                    case AnalysisReportChartSetup."Base X-Axis on" of
                        AnalysisReportChartSetup."Base X-Axis on"::Period:
                            if IsMeasure then begin
                                AnalysisReportChartMatrix.SetFilters(AnalysisReportChartSetup);
                                AnalysisReportChartMatrix.RunModal();
                            end;
                        AnalysisReportChartSetup."Base X-Axis on"::Line,
                        AnalysisReportChartSetup."Base X-Axis on"::Column:
                            begin
                                if IsMeasure then
                                    AnalysisReportChartLinePage.SetViewAsMeasure(true)
                                else
                                    AnalysisReportChartLinePage.SetViewAsMeasure(false);
                                AnalysisReportChartLinePage.SetTableView(AnalysisReportChartLine);
                                AnalysisReportChartLinePage.RunModal();
                            end;
                    end;

                    CurrPage.Update();
                end;
            }
            action(Delete)
            {
                ApplicationArea = Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                begin
                    CurrPage.SetSelectionFilter(AnalysisReportChartLine);
                    AnalysisReportChartLine.ModifyAll("Chart Type", Rec."Chart Type"::" ");
                    CurrPage.Update();
                end;
            }
            action("Reset to default setup")
            {
                ApplicationArea = Suite;
                Caption = 'Reset to Default Setup';
                Image = Refresh;
                ToolTip = 'Undo your change and return to the default setup.';

                trigger OnAction()
                begin
                    AnalysisReportChartSetup.RefreshLines(false);
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        SetFilters(Rec);
        exit(Rec.FindSet());
    end;

    var
        AnalysisReportChartSetup: Record "Analysis Report Chart Setup";
        IsMeasure: Boolean;

    procedure SetViewAsMeasure(Value: Boolean)
    begin
        IsMeasure := Value;
    end;

    local procedure SetFilters(var AnalysisReportChartLine: Record "Analysis Report Chart Line")
    begin
        AnalysisReportChartLine.Reset();
        if IsMeasure then
            AnalysisReportChartSetup.SetLinkToMeasureLines(AnalysisReportChartLine)
        else
            AnalysisReportChartSetup.SetLinkToDimensionLines(AnalysisReportChartLine);
        AnalysisReportChartLine.SetFilter("Chart Type", '<>%1', AnalysisReportChartLine."Chart Type"::" ");
    end;

    procedure SetSetupRec(var NewAnalysisReportChartSetup: Record "Analysis Report Chart Setup")
    begin
        AnalysisReportChartSetup := NewAnalysisReportChartSetup;
    end;
}

