// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

page 775 "Analysis Report Chart Setup"
{
    Caption = 'Analysis Report Chart Setup';
    SourceTable = "Analysis Report Chart Setup";

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
                    ToolTip = 'Specifies the name of the specific chart.';

                    trigger OnValidate()
                    begin
                        SetEnabled();
                    end;
                }
                field("Analysis Report Name"; Rec."Analysis Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the analysis report that is used to generate the specific chart that is shown in, for example, the Sales Performance window.';

                    trigger OnValidate()
                    begin
                        SetEnabled();
                        Rec.SetAnalysisReportName(Rec."Analysis Report Name");
                        CurrPage.Update(false);
                    end;
                }
                field("Base X-Axis on"; Rec."Base X-Axis on")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies how the values from the selected analysis report are displayed in the specific chart.';

                    trigger OnValidate()
                    begin
                        SetEnabled();
                        Rec.SetShowPer(Rec."Base X-Axis on");
                        CurrPage.Update(false);
                    end;
                }
                field("Analysis Line Template Name"; Rec."Analysis Line Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the analysis line template that is used to generate the specific chart that is shown in, for example, the Sales Performance window.';
                }
                field("Analysis Column Template Name"; Rec."Analysis Column Template Name")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the analysis column template that is used to generate the chart that is shown in, for example, the Sales Performance window.';
                }
                group(Control8)
                {
                    ShowCaption = false;
                    field("Start Date"; Rec."Start Date")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the first date on which analysis report values are included in the chart.';
                    }
                    field("End Date"; Rec."End Date")
                    {
                        ApplicationArea = Basic, Suite;
                        Editable = IsEndDateEnabled;
                        ToolTip = 'Specifies the last date on which analysis report values are included in the chart.';
                    }
                    field("Period Length"; Rec."Period Length")
                    {
                        ApplicationArea = Basic, Suite;
                        ToolTip = 'Specifies the length of periods in the chart.';
                    }
                    field("No. of Periods"; Rec."No. of Periods")
                    {
                        ApplicationArea = Basic, Suite;
                        Enabled = IsNoOfPeriodsEnabled;
                        ToolTip = 'Specifies how many periods are shown in the chart.';
                    }
                }
            }
            group("Measures (Y-Axis)")
            {
                Caption = 'Measures (Y-Axis)';
                part(SetupYAxis; "Analysis Report Chart SubPage")
                {
                    ApplicationArea = Suite;
                    Caption = ' ';
                }
            }
            group("Dimensions (X-Axis)")
            {
                Caption = 'Dimensions (X-Axis)';
                Visible = IsXAxisVisible;
                part(SetupXAxis; "Analysis Report Chart SubPage")
                {
                    ApplicationArea = Suite;
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

