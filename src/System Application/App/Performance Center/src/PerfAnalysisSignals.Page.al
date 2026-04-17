// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Advanced-user drill-down: signal findings attached to a Performance Analysis.
/// </summary>
page 5495 "Perf. Analysis Signals"
{
    Caption = 'Performance Analysis Signals';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Performance Analysis Line";
    SourceTableView = where("Line Type" = const(Signal));
    Editable = false;
    Permissions = tabledata "Performance Analysis Line" = R;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Signal Source"; Rec."Signal Source")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies where this signal finding came from.';
                }
                field("Severity"; Rec."Severity")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the severity of the finding.';
                    StyleExpr = SeverityStyle;
                }
                field("Title"; Rec."Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a short title for the finding.';
                }
                field("Description"; Rec."Description")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the finding.';
                }
                field("Link"; Rec."Link")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies a link for more details.';
                }
            }
        }
    }

    var
        SeverityStyle: Text;

    trigger OnAfterGetRecord()
    begin
        case Rec."Severity" of
            Rec."Severity"::Critical:
                SeverityStyle := 'Unfavorable';
            Rec."Severity"::Warning:
                SeverityStyle := 'Ambiguous';
            else
                SeverityStyle := 'Standard';
        end;
    end;

    /// <summary>
    /// Filters this page to the signal lines of the given analysis.
    /// </summary>
    procedure SetAnalysis(var Analysis: Record "Performance Analysis")
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Analysis Id", Analysis."Id");
        Rec.SetRange("Line Type", Rec."Line Type"::Signal);
        Rec.FilterGroup(0);
    end;
}
