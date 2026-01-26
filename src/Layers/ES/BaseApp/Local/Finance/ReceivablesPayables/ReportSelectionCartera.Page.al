// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.ReceivablesPayables;

using System.Globalization;
using System.Reflection;

page 7000045 "Report Selection - Cartera"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Cartera Report Selections';
    PageType = Worksheet;
    SaveValues = true;
    SourceTable = "Cartera Report Selections";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            field(ReportUsage2; ReportUsage2)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Usage';
                ToolTip = 'Specifies the business purpose of the report.';

                trigger OnValidate()
                begin
                    SetUsageFilter();
                    ReportUsage2OnAfterValidate();
                end;
            }
            repeater(Control1)
            {
                ShowCaption = false;
                field(Sequence; Rec.Sequence)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the order number or the sequence in which you want to print this report.';
                }
                field("Report ID"; Rec."Report ID")
                {
                    ApplicationArea = Basic, Suite;
                    LookupPageID = Objects;
                    ToolTip = 'Specifies the number of the report to be printed.';
                }
                field("Report Name"; Rec."Report Name")
                {
                    ApplicationArea = Basic, Suite;
                    DrillDown = false;
                    ToolTip = 'Specifies the number of the report you want to print.';
                }
            }
        }
    }

    actions
    {
    }

    trigger OnAfterGetRecord()
    begin
        ObjTransl.TranslateObject(ObjTransl."Object Type"::Report, Rec."Report ID");
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        Rec.NewRecord();
    end;

    trigger OnOpenPage()
    begin
        SetUsageFilter();
    end;

    var
        ObjTransl: Record "Object Translation";
        ReportUsage2: Enum "Report Selection Usage Cartera";

    local procedure SetUsageFilter()
    begin
        Rec.FilterGroup(2);
        case ReportUsage2 of
            "Report Selection Usage Cartera"::"Bill Group":
                Rec.SetRange(Usage, Rec.Usage::"Bill Group");
            "Report Selection Usage Cartera"::"Posted Bill Group":
                Rec.SetRange(Usage, Rec.Usage::"Posted Bill Group");
            "Report Selection Usage Cartera"::"Closed Bill Group":
                Rec.SetRange(Usage, Rec.Usage::"Closed Bill Group");
            "Report Selection Usage Cartera"::Bill:
                Rec.SetRange(Usage, Rec.Usage::Bill);
            "Report Selection Usage Cartera"::"Bill Group - Test":
                Rec.SetRange(Usage, Rec.Usage::"Bill Group - Test");
            "Report Selection Usage Cartera"::"Payment Order":
                Rec.SetRange(Usage, Rec.Usage::"Payment Order");
            "Report Selection Usage Cartera"::"Posted Payment Order":
                Rec.SetRange(Usage, Rec.Usage::"Posted Payment Order");
            "Report Selection Usage Cartera"::"Payment Order - Test":
                Rec.SetRange(Usage, Rec.Usage::"Payment Order - Test");
            "Report Selection Usage Cartera"::"Closed Payment Order":
                Rec.SetRange(Usage, Rec.Usage::"Closed Payment Order");
        end;
        Rec.FilterGroup(0);
    end;

    local procedure ReportUsage2OnAfterValidate()
    begin
        CurrPage.Update();
    end;
}

