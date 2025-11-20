// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Reporting;

using Microsoft.Foundation.Reporting;
using System.Reflection;
using System.Telemetry;

page 584 "Report Selection - VAT Stmt."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selections VAT';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Tasks;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field(ReportUsage2; ReportUsage2)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Usage';
                    ToolTip = 'Specifies the report object that must run when you print.';

                    trigger OnValidate()
                    begin
                        SetUsageFilter();
                        ReportUsage2OnAfterValidate();
                    end;
                }
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies where a report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the ID of the report that prints for this document type.';
                }
                field("Report Name"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the name of the report that prints for this document type.';
                }
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
        FeatureTelemetry.LogUptake('0001Q0A', VatReportTok, Enum::"Feature Uptake Status"::Discovered);
        SetUsageFilter();
    end;

    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
        ReportUsage2: Enum "Report Selection Usage VAT";
        VatReportTok: Label 'DACH VAT Report', Locked = true;

    local procedure SetUsageFilter()
    begin
        Rec.FilterGroup(2);
        case ReportUsage2 of
            ReportUsage2::"VAT Statement":
                Rec.SetRange(Usage, Rec.Usage::"VAT Statement");
            ReportUsage2::"Sales VAT Adv. Not. Acc":
                Rec.SetRange(Usage, Rec.Usage::"Sales VAT Acc. Proof");
            ReportUsage2::"VAT Statement Schedule":
                Rec.SetRange(Usage, Rec.Usage::"VAT Statement Schedule");
        end;
        Rec.FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

