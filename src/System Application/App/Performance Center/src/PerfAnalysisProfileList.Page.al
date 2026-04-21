// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Tooling;

/// <summary>
/// Shows the captured profiles for a Performance Analysis with the AI relevance score
/// and reason. The user can override the "Marked Relevant" flag.
/// </summary>
page 8427 "Perf. Analysis Profile List"
{
    Caption = 'Captured profiles';
    PageType = List;
    ApplicationArea = All;
    SourceTable = "Performance Analysis Line";
    Editable = true;
    Permissions = tabledata "Performance Analysis Line" = RM;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field("Line No."; Rec."Line No.")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies the index of this profile in the analysis.';
                }
                field("Profile Created At"; Rec."Profile Created At")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies when this profile was captured.';
                }
                field("Ai Relevance Score"; Rec."Ai Relevance Score")
                {
                    ApplicationArea = All;
                    Editable = false;
                    AutoFormatType = 0;
                    ToolTip = 'Specifies the AI-assigned relevance (0 to 1) for this profile.';
                }
                field("Ai Reason"; Rec."Ai Reason")
                {
                    ApplicationArea = All;
                    Editable = false;
                    ToolTip = 'Specifies why the AI flagged this profile.';
                }
                field("Marked Relevant"; Rec."Marked Relevant")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies whether this profile is considered relevant. You can override the AI here.';
                }
            }
        }
    }

    /// <summary>
    /// Filters this page to the analysis' captured profiles.
    /// </summary>
    procedure SetAnalysis(var Analysis: Record "Performance Analysis")
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("Analysis Id", Analysis."Id");
        Rec.FilterGroup(0);
    end;
}
