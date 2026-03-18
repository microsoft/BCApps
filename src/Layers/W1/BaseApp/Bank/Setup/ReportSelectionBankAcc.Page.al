// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Setup;

using Microsoft.Foundation.Reporting;
using System.Reflection;

/// <summary>
/// Worksheet page for configuring report assignments for bank account-related documents.
/// Allows users to specify which reports are used for bank statements, reconciliation, and check printing.
/// </summary>
/// <remarks>
/// Source Table: Report Selections. Provides bank-specific report selection interface.
/// Supports configuration of reports for statements, reconciliation tests, checks, and posted payment reconciliation.
/// </remarks>
page 385 "Report Selection - Bank Acc."
{
    ApplicationArea = Basic, Suite;
    Caption = 'Report Selection - Bank Account';
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
                ApplicationArea = Basic, Suite;
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
                    ApplicationArea = Basic, Suite;
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    ApplicationArea = Basic, Suite;
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
        ReportUsage2: Enum "Report Selection Usage Bank";

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if Rec.Modify() then;
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Bank"::Statement:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"B.Stmt");
            "Report Selection Usage Bank"::"Reconciliation - Test":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"B.Recon.Test");
            "Report Selection Usage Bank"::Check:
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"B.Check");
            "Report Selection Usage Bank"::"Posted Payment Reconciliation":
                Rec.SetRange(Usage, Enum::"Report Selection Usage"::"Posted Payment Reconciliation");
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
                    Enum::"Report Selection Usage"::"B.Stmt":
                        ReportUsage2 := "Report Selection Usage Bank"::Statement;
                    Enum::"Report Selection Usage"::"B.Recon.Test":
                        ReportUsage2 := "Report Selection Usage Bank"::"Reconciliation - Test";
                    Enum::"Report Selection Usage"::"B.Check":
                        ReportUsage2 := "Report Selection Usage Bank"::Check;
                    Enum::"Report Selection Usage"::"Posted Payment Reconciliation":
                        ReportUsage2 := "Report Selection Usage Bank"::"Posted Payment Reconciliation";
                    else
                        OnInitUsageFilterOnElseCase(NewReportUsage, ReportUsage2);
                end;
            Rec.SetRange(Usage);
        end;
    end;

    /// <summary>
    /// Integration event raised after setting filters on report selections based on bank usage.
    /// Enables custom filtering logic for bank-specific report selection scenarios.
    /// </summary>
    /// <param name="Rec">Report Selections record with applied filters</param>
    /// <param name="ReportUsage2">Bank-specific report usage enum value</param>
    /// <remarks>
    /// Raised from SetUsageFilter procedure after applying standard bank report usage filters.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnSetUsageFilterOnAfterSetFiltersByReportUsage(var Rec: Record "Report Selections"; ReportUsage2: Enum "Report Selection Usage Bank")
    begin
    end;

    /// <summary>
    /// Integration event raised for custom report usage mapping in bank report selection.
    /// Allows extensions to handle additional report usage types not covered by standard mapping.
    /// </summary>
    /// <param name="ReportUsage">General report usage enum value</param>
    /// <param name="ReportUsage2">Bank-specific report usage enum to be set by subscriber</param>
    /// <remarks>
    /// Raised from InitUsageFilter procedure when standard usage mapping doesn't apply.
    /// </remarks>
    [IntegrationEvent(false, false)]
    local procedure OnInitUsageFilterOnElseCase(ReportUsage: Enum "Report Selection Usage"; var ReportUsage2: Enum "Report Selection Usage Bank")
    begin
    end;
}

