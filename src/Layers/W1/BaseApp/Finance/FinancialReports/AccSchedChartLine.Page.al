// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Provides line-based interface for configuring account schedule chart setup lines.
/// Enables detailed configuration of chart data series including measure names and visualization types.
/// </summary>
/// <remarks>
/// Primary functionality: Chart line configuration, measure and dimension setup for visualization.
/// Integration: Links with Account Schedule Chart Setup and chart type management.
/// Extensibility: Standard page extension patterns for additional chart configuration options.
/// </remarks>
page 765 "Acc. Sched. Chart Line"
{
    Caption = 'Acc. Sched. Chart Line';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = List;
    SourceTable = "Acc. Sched. Chart Setup Line";

    layout
    {
        area(content)
        {
            repeater(General)
            {
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Account Schedule Line No."; Rec."Account Schedule Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Column Layout Line No."; Rec."Column Layout Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Original Measure Name"; Rec."Original Measure Name")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Chart Type"; Rec."Chart Type")
                {
                    ApplicationArea = All;
                    Editable = IsMeasure;
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
                            Rec."Chart Type" := Rec.GetDefaultAccSchedChartType()
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
                ApplicationArea = Basic, Suite;
                Caption = 'Select All';
                Image = AllLines;
                ToolTip = 'Select all lines.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
                begin
                    AccSchedChartSetupLine.Copy(Rec);
                    AccSchedChartManagement.SelectAll(AccSchedChartSetupLine, IsMeasure);
                end;
            }
            action(ShowNone)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Deselect All';
                Image = CancelAllLines;
                ToolTip = 'Unselect all lines.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartManagement: Codeunit "Acc. Sched. Chart Management";
                begin
                    AccSchedChartSetupLine.Copy(Rec);
                    AccSchedChartManagement.DeselectAll(AccSchedChartSetupLine, IsMeasure);
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

    /// <summary>
    /// Sets the view mode for chart lines to display as measures or dimensions.
    /// Controls how chart setup lines are interpreted and displayed in the interface.
    /// </summary>
    /// <param name="Value">True to view as measures, false to view as dimensions</param>
    procedure SetViewAsMeasure(Value: Boolean)
    begin
        IsMeasure := Value;
    end;
}

