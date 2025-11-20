// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

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
                    ToolTip = 'Specifies the account schedule name.';
                    Visible = false;
                }
                field("Account Schedule Line No."; Rec."Account Schedule Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account schedule line that the chart is based on.';
                    Visible = false;
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Column Layout Line No."; Rec."Column Layout Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the line number. This field is intended only for internal use.';
                    Visible = false;
                }
                field("Original Measure Name"; Rec."Original Measure Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account schedule columns or lines that you select to include in the Account Schedules Chart Setup window.';
                }
                field("Chart Type"; Rec."Chart Type")
                {
                    ApplicationArea = All;
                    Editable = IsMeasure;
                    ToolTip = 'Specifies how the account schedule values are represented graphically in the chart.';
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

    procedure SetViewAsMeasure(Value: Boolean)
    begin
        IsMeasure := Value;
    end;
}

