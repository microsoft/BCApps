// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Dimension;

/// <summary>
/// Stores dimension filter definitions for analysis views to restrict data analysis to specific dimension values.
/// Enables analysis views to include only relevant dimension combinations for focused reporting.
/// </summary>
/// <remarks>
/// Each filter record represents a dimension-specific filter for an analysis view.
/// Analysis view updates apply these filters to include only matching dimension set entries.
/// </remarks>
table 364 "Analysis View Filter"
{
    Caption = 'Analysis View Filter';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Analysis view code that this filter applies to.
        /// Links to the Analysis View table for filter association.
        /// </summary>
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Analysis View";
        }
        /// <summary>
        /// Dimension code that this filter constrains (e.g., DEPARTMENT, PROJECT).
        /// Specifies which dimension to apply the value filter to during analysis view processing.
        /// </summary>
        field(2; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            ToolTip = 'Specifies the dimension that the analysis view is based on.';
            NotBlank = true;
            TableRelation = Dimension;
        }
        /// <summary>
        /// Dimension value filter expression to restrict analysis view data.
        /// Supports standard filter expressions including ranges and wildcards for dimension value selection.
        /// </summary>
        field(3; "Dimension Value Filter"; Code[250])
        {
            Caption = 'Dimension Value Filter';
            ToolTip = 'Specifies the dimension value that the analysis view is based on.';
            TableRelation = "Dimension Value".Code where("Dimension Code" = field("Dimension Code"));
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(Key1; "Analysis View Code", "Dimension Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisView.Get("Analysis View Code");
        AnalysisView.TestField(Blocked, false);
        AnalysisView.ValidateDelete(AnalysisViewFilter.FieldCaption("Dimension Code"));
        AnalysisView.AnalysisViewReset();
        AnalysisView.Modify();
    end;

    trigger OnInsert()
    begin
        ValidateModifyFilter();
    end;

    trigger OnModify()
    begin
        ValidateModifyFilter();
    end;

    trigger OnRename()
    begin
        Error(Text000, TableCaption);
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'You can''t rename an %1.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    local procedure ValidateModifyFilter()
    var
        AnalysisView: Record "Analysis View";
        AnalysisViewFilter: Record "Analysis View Filter";
    begin
        AnalysisView.Get("Analysis View Code");
        AnalysisView.TestField(Blocked, false);
        if (AnalysisView."Last Entry No." <> 0) and (xRec."Dimension Code" <> "Dimension Code")
        then begin
            AnalysisView.ValidateDelete(AnalysisViewFilter.FieldCaption("Dimension Code"));
            AnalysisView.AnalysisViewReset();
            "Dimension Value Filter" := '';
            AnalysisView.Modify();
        end;
        if (AnalysisView."Last Entry No." <> 0) and (xRec."Dimension Value Filter" <> "Dimension Value Filter")
        then begin
            AnalysisView.ValidateDelete(AnalysisViewFilter.FieldCaption("Dimension Value Filter"));
            AnalysisView.AnalysisViewReset();
            AnalysisView.Modify();
        end;
    end;
}

