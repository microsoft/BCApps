// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

page 766 "Acc. Sched. Chart SubPage"
{
    Caption = 'Acc. Sched. Chart SubPage';
    DeleteAllowed = false;
    InsertAllowed = false;
    PageType = ListPart;
    SourceTable = "Acc. Sched. Chart Setup Line";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Account Schedule Line No."; Rec."Account Schedule Line No.")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the number of the account schedule line that the chart is based on.';
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
                    Visible = false;
                }
                field("Measure Name"; Rec."Measure Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the account schedule columns or lines that the measures on the y-axis in the specific chart are based on.';
                }
                field("Chart Type"; Rec."Chart Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies how the account schedule values are represented graphically in the chart.';
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
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Image = EditLines;
                ToolTip = 'Edit the chart.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                    AccSchedChartLine: Page "Acc. Sched. Chart Line";
                    AccSchedChartMatrix: Page "Acc. Sched. Chart Matrix";
                begin
                    SetFilters(AccSchedChartSetupLine);
                    AccSchedChartSetupLine.SetRange("Chart Type");
                    case AccountSchedulesChartSetup."Base X-Axis on" of
                        AccountSchedulesChartSetup."Base X-Axis on"::Period:
                            if IsMeasure then begin
                                AccSchedChartMatrix.SetFilters(AccountSchedulesChartSetup);
                                AccSchedChartMatrix.RunModal();
                            end;
                        AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Line",
                        AccountSchedulesChartSetup."Base X-Axis on"::"Acc. Sched. Column":
                            begin
                                if IsMeasure then
                                    AccSchedChartLine.SetViewAsMeasure(true)
                                else
                                    AccSchedChartLine.SetViewAsMeasure(false);
                                AccSchedChartLine.SetTableView(AccSchedChartSetupLine);
                                AccSchedChartLine.RunModal();
                            end;
                    end;

                    CurrPage.Update();
                end;
            }
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                var
                    AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line";
                begin
                    CurrPage.SetSelectionFilter(AccSchedChartSetupLine);
                    AccSchedChartSetupLine.ModifyAll("Chart Type", Rec."Chart Type"::" ");
                    CurrPage.Update();
                end;
            }
            action("Reset to default Setup")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Reset to Default Setup';
                Image = Refresh;
                ToolTip = 'Undo your change and return to the default setup.';

                trigger OnAction()
                begin
                    AccountSchedulesChartSetup.RefreshLines(false);
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
        AccountSchedulesChartSetup: Record "Account Schedules Chart Setup";
        IsMeasure: Boolean;

    procedure SetViewAsMeasure(Value: Boolean)
    begin
        IsMeasure := Value;
    end;

    local procedure SetFilters(var AccSchedChartSetupLine: Record "Acc. Sched. Chart Setup Line")
    begin
        AccSchedChartSetupLine.Reset();
        if IsMeasure then
            AccountSchedulesChartSetup.SetLinkToMeasureLines(AccSchedChartSetupLine)
        else
            AccountSchedulesChartSetup.SetLinkToDimensionLines(AccSchedChartSetupLine);
        AccSchedChartSetupLine.SetFilter("Chart Type", '<>%1', AccSchedChartSetupLine."Chart Type"::" ");
    end;

    procedure SetSetupRec(var NewAccountSchedulesChartSetup: Record "Account Schedules Chart Setup")
    begin
        AccountSchedulesChartSetup := NewAccountSchedulesChartSetup;
    end;
}

