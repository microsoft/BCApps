// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Reports;

using Microsoft.Foundation.Reporting;
using System.Reflection;

page 20442 "Qlty. Report Selection - QM"
{
    Caption = 'Report Selection - Quality Management';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Report Selections";
    UsageCategory = Tasks;
    ApplicationArea = QualityManagement;

    layout
    {
        area(Content)
        {
            field(ReportUsage; QltyReportSelectionUsage)
            {
                Caption = 'Usage';
                ToolTip = 'Specifies which type of document the report is used for.';

                trigger OnValidate()
                begin
                    SetUsageFilter(true);
                end;
            }
            repeater(Repeater)
            {
                ShowCaption = false;

                field(Sequence; Rec.Sequence)
                {
                    ToolTip = 'Specifies a number that indicates where this report is in the printing order.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    LookupPageId = Objects;
                    ToolTip = 'Specifies the object ID of the report.';
                }
                field("Report Caption"; Rec."Report Caption")
                {
                    DrillDown = false;
                    ToolTip = 'Specifies the display name of the report.';
                }
            }
        }
        area(FactBoxes)
        {
            systempart(RecordLinks; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(RecordNotes; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    var
        QltyReportSelectionUsage: Enum "Qlty. Report Selection Usage";

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
        case QltyReportSelectionUsage of
            QltyReportSelectionUsage::"Certificate of Analysis":
                Rec.Validate("Report ID", Report::"Qlty. Certificate of Analysis");
            QltyReportSelectionUsage::"Non-Conformance":
                Rec.Validate("Report ID", Report::"Qlty. Non-Conformance");
            QltyReportSelectionUsage::"General Purpose Inspection":
                Rec.Validate("Report ID", Report::"Qlty. General Purpose Inspect.");
        end;
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter(false);
    end;

    local procedure SetUsageFilter(ModifyRec: Boolean)
    begin
        if ModifyRec then
            if IsNullGuid(Rec.SystemId) then
                Rec.Insert()
            else
                Rec.Modify();
        Rec.FilterGroup(2);

        case QltyReportSelectionUsage of
            QltyReportSelectionUsage::"Certificate of Analysis":
                Rec.SetRange(Usage, Rec."Usage"::"Quality Management - Certificate of Analysis");
            QltyReportSelectionUsage::"Non-Conformance":
                Rec.SetRange(Usage, Rec."Usage"::"Quality Management - Non-Conformance");
            QltyReportSelectionUsage::"General Purpose Inspection":
                Rec.SetRange(Usage, Rec."Usage"::"Quality Management - General Purpose Inspection");
        end;

        Rec.FilterGroup(0);
        CurrPage.Update();
    end;
}
