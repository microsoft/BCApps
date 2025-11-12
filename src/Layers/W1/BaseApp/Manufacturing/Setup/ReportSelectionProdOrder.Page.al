// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 99000917 "Report Selection - Prod. Order"
{
    ApplicationArea = Manufacturing;
    Caption = 'Report Selections Production Order';
    AdditionalSearchTerms = 'Report Selections Manufacturing';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Manufacturing;
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Manufacturing;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Manufacturing;
                    LookupPageID = Objects;
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Manufacturing;
                    DrillDown = false;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
    }

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        InitUsageFilter();
        SetUsageFilter(false);
    end;

    var
        ReportUsage2: Enum "Report Selection Usage Prod.";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Prod."::"Job Card":
                Rec.SetRange(Usage, Rec.Usage::M1);
            "Report Selection Usage Prod."::"Mat. & Requisition":
                Rec.SetRange(Usage, Rec.Usage::M2);
            "Report Selection Usage Prod."::"Shortage List":
                Rec.SetRange(Usage, Rec.Usage::M3);
            "Report Selection Usage Prod."::"Gantt Chart":
                Rec.SetRange(Usage, Rec.Usage::M4);
            "Report Selection Usage Prod."::"Prod. Order":
                Rec.SetRange(Usage, Rec.Usage::"Prod.Order");
            "Report Selection Usage Prod."::"Prod. Output Item Label":
                Rec.SetRange(Usage, Rec.Usage::"Prod. Output Item Label");
        end;
        OnSetUsageFilterOnAfterSetFiltersByReportUsage(Rec, ReportUsage2);
        Rec.FilterGroup(0);
        CurrPage.Update();
    end;

    local procedure InitUsageFilter()
    var
        NewReportUsage: Enum "Report Selection Usage";
    begin
        if Rec.GetFilter(Usage) <> '' then begin
            if Evaluate(NewReportUsage, Rec.GetFilter(Usage)) then
                case NewReportUsage of
                    NewReportUsage::"M1":
                        ReportUsage2 := "Report Selection Usage Prod."::"Job Card";
                    NewReportUsage::"M2":
                        ReportUsage2 := "Report Selection Usage Prod."::"Mat. & Requisition";
                    NewReportUsage::"M3":
                        ReportUsage2 := "Report Selection Usage Prod."::"Shortage List";
                    NewReportUsage::"M4":
                        ReportUsage2 := "Report Selection Usage Prod."::"Gantt Chart";
                    NewReportUsage::"Prod.Order":
                        ReportUsage2 := "Report Selection Usage Prod."::"Prod. Order";
                    NewReportUsage::"Prod. Output Item Label":
                        ReportUsage2 := "Report Selection Usage Prod."::"Prod. Output Item Label";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Prod.")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Prod.")
    begin
    end;
}

