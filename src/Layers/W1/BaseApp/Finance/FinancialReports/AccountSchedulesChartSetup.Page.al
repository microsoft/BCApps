// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Configuration interface for account schedule chart visualization settings.
/// Provides setup for chart parameters, period definitions, and visualization options.
/// </summary>
/// <remarks>
/// Primary setup page for account schedule chart functionality. Enables configuration
/// of chart data sources, period settings, axis definitions, and chart line management.
/// Integrates with chart visualization system for financial data presentation.
/// </remarks>
page 763 "Account Schedules Chart Setup"
{
    Caption = 'Financial Report Chart Setup';
    SourceTable = "Account Schedules Chart Setup";

    layout
    {
        area(content)
        {
            group(DataSource)
            {
                Caption = 'Data Source';
                field(Name; Rec.Name)
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        SetEnabled();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Account Schedule Name"; Rec."Account Schedule Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Row Definition';

                    trigger OnValidate()
                    begin
                        SetEnabled();
                        Rec.SetAccScheduleName(Rec."Account Schedule Name");
                        CurrPage.Update(false);
                    end;
                }
                field("Column Layout Name"; Rec."Column Layout Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Column Definition';

                    trigger OnValidate()
                    begin
                        SetEnabled();
                        Rec.SetColumnLayoutName(Rec."Column Layout Name");
                        CurrPage.Update(false);
                    end;
                }
                field("Base X-Axis on"; Rec."Base X-Axis on")
                {
                    ApplicationArea = Basic, Suite;

                    trigger OnValidate()
                    begin
                        SetEnabled();
                        Rec.SetShowPer(Rec."Base X-Axis on");
                        CurrPage.Update(false);
                    end;
                }
                group(Control15)
                {
                    ShowCaption = false;
                    field("Start Date"; Rec."Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the first date on which financial report values are included in the chart.';
                    }
                    field("End Date"; Rec."End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = IsEndDateEnabled;
                    }
                    field("Period Length"; Rec."Period Length")
                    {
                        ApplicationArea = Basic, Suite;
                    }
                    field("No. of Periods"; Rec."No. of Periods")
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = IsNoOfPeriodsEnabled;
                    }
                }
            }
            group("Measures (Y-Axis)")
            {
                Caption = 'Measures (Y-Axis)';
                part(SetupYAxis; "Acc. Sched. Chart SubPage")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = ' ';
                }
            }
            group("Dimensions (X-Axis)")
            {
                Caption = 'Dimensions (X-Axis)';
                Visible = IsXAxisVisible;
                part(SetupXAxis; "Acc. Sched. Chart SubPage")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = ' ';
                    Visible = IsXAxisVisible;
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        SetEnabled();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec."Start Date" := WorkDate();
        Rec."User ID" := CopyStr(UserId(), 1, MaxStrLen(Rec."User ID"));
    end;

    trigger OnOpenPage()
    begin
        SetEnabled();
    end;

    var
        IsEndDateEnabled: Boolean;
        IsNoOfPeriodsEnabled: Boolean;
        IsXAxisVisible: Boolean;

    local procedure SetEnabled()
    begin
        IsNoOfPeriodsEnabled := Rec."Base X-Axis on" = Rec."Base X-Axis on"::Period;
        IsXAxisVisible := Rec."Base X-Axis on" <> Rec."Base X-Axis on"::Period;
        IsEndDateEnabled := Rec."Base X-Axis on" <> Rec."Base X-Axis on"::Period;
        CurrPage.SetupYAxis.PAGE.SetViewAsMeasure(true);
        CurrPage.SetupYAxis.PAGE.SetSetupRec(Rec);
        CurrPage.SetupXAxis.PAGE.SetViewAsMeasure(false);
        CurrPage.SetupXAxis.PAGE.SetSetupRec(Rec);
    end;
}

