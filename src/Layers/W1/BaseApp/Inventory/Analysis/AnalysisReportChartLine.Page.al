// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 777 "Analysis Report Chart Line"
{
    Caption = 'Analysis Report Chart Line';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
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
                field("Analysis Line Line No."; Rec."Analysis Line Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the analysis report line that the specific chart is based on.';
                    Visible = false;
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Analysis Column Line No."; Rec."Analysis Column Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the analysis report column that the advanced chart is based on.';
                    Visible = false;
                }
                field("Original Measure Name"; Rec."Original Measure Name")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the analysis report columns or lines that you select to insert in the Analysis Report Chart Setup window.';
                }
                field("Chart Type"; Rec."Chart Type")
                {
                    ApplicationArea = All;
                    Editable = IsMeasure;
                    ToolTip = 'Specifies how the analysis report values are represented graphically in the specific chart.';
                    Visible = IsMeasure;
                }
                field(Show; Show)
                {
                    ApplicationArea = All;
                    Caption = 'Show';
                    Editable = not IsMeasure;
                    ToolTip = 'Specifies if the selected value is shown in the window.';
                    Visible = not IsMeasure;

                    trigger OnValidate()
                    begin
                        if Show then
                            Rec."Chart Type" := Rec.GetDefaultChartType()
                        else
                            Rec."Chart Type" := Rec."Chart Type"::" ";
                    end;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Select All';
                Image = AllLines;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
                begin
                    AnalysisReportChartLine.Copy(Rec);
                    AnalysisReportChartMgt.SelectAll(AnalysisReportChartLine, IsMeasure);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = Suite;
                Caption = 'Deselect All';
                Image = CancelAllLines;
                ToolTip = 'Unselect all lines.';

                trigger OnAction()
                var
                    AnalysisReportChartLine: Record "Analysis Report Chart Line";
                    AnalysisReportChartMgt: Codeunit "Analysis Report Chart Mgt.";
                begin
                    AnalysisReportChartLine.Copy(Rec);
                    AnalysisReportChartMgt.DeselectAll(AnalysisReportChartLine, IsMeasure);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowAll_Promoted; ShowAll)
                {
                }
                actionref(ShowNone_Promoted; ShowNone)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Show := Rec."Chart Type" <> Rec."Chart Type"::" ";
    end;

    var
        Show: Boolean;
        IsMeasure: Boolean;

    procedure SetViewAsMeasure(Value: Boolean)
    begin
        IsMeasure := Value;
    end;
}

