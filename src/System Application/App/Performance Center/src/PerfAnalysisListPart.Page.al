// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Embeddable list of Performance Analysis records, used inside the Performance Center hub.
/// </summary>
page 5488 "Perf. Analysis List Part"
{
    Caption = 'Performance Analyses';
    PageType = ListPart;
    ApplicationArea = All;
    SourceTable = "Performance Analysis";
    CardPageId = "Perf. Analysis Card";
    Editable = false;
    Permissions = tabledata "Performance Analysis" = R;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Title"; Rec."Title")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the title of the performance analysis.';
                }
                field("State"; Rec."State")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the current state of the performance analysis.';
                    StyleExpr = StateStyle;
                }
                field("Requested By User Name"; Rec."Requested By User Name")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies who requested this performance analysis.';
                }
                field("Requested At"; Rec."Requested At")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies when the analysis was requested.';
                }
                field("Scenario Activity Type"; Rec."Scenario Activity Type")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the scenario the analysis covers.';
                }
            }
        }
    }

    var
        StateStyle: Text;

    trigger OnAfterGetRecord()
    begin
        Rec.CalcFields("Requested By User Name");
        case Rec."State" of
            Rec."State"::Concluded:
                StateStyle := 'Favorable';
            Rec."State"::Failed,
            Rec."State"::Cancelled:
                StateStyle := 'Unfavorable';
            Rec."State"::Capturing,
            Rec."State"::AiFiltering,
            Rec."State"::AiAnalyzing:
                StateStyle := 'Ambiguous';
            else
                StateStyle := 'Standard';
        end;
    end;
}
