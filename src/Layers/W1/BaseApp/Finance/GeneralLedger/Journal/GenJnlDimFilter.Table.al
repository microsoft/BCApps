// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

using Microsoft.Finance.Dimension;

/// <summary>
/// Stores dimension filtering criteria for general journal lines to enable dimension-based journal line analysis and reporting.
/// Provides flexible dimension-based filtering capabilities for journal line queries and reporting purposes.
/// </summary>
/// <remarks>
/// Temporary filtering table for dimension-based journal line analysis. Enables users to define dimension criteria
/// for filtering and analyzing journal entries based on specific dimension value combinations.
/// Key features: Multi-dimensional filtering support, journal line association, dimension value validation.
/// Integration: Used with dimension analysis tools and journal reporting functions for enhanced filtering capabilities.
/// </remarks>
table 357 "Gen. Jnl. Dim. Filter"
{
    Caption = 'Gen. Jnl. Dim. Filter';
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Journal template name for the filtered journal lines.
        /// </summary>
        field(1; "Journal Template Name"; Code[10])
        {
            Caption = 'Journal Template Name';
            TableRelation = "Gen. Journal Template";
        }
        /// <summary>
        /// Journal batch name containing the lines to be filtered.
        /// </summary>
        field(2; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
            TableRelation = "Gen. Journal Batch".Name where("Journal Template Name" = field("Journal Template Name"));
        }
        /// <summary>
        /// Specific journal line number for line-specific dimension filtering.
        /// </summary>
        field(3; "Journal Line No."; Integer)
        {
            Caption = 'Journal Line No.';
            TableRelation = "Gen. Journal Line"."Line No." where("Journal Template Name" = field("Journal Template Name"),
                                                                 "Journal Batch Name" = field("Journal Batch Name"));
        }
        /// <summary>
        /// Dimension code to be used as filtering criteria.
        /// </summary>
        field(4; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            ToolTip = 'Specifies the code for the dimension.';
            TableRelation = Dimension;
        }
        /// <summary>
        /// Filter expression for dimension values to include in the filtering criteria.
        /// </summary>
        field(5; "Dimension Value Filter"; Text[250])
        {
            Caption = 'Dimension Value Filter';
            ToolTip = 'Specifies the filter for the dimension values.';
        }
    }

    keys
    {
        key(Key1; "Journal Template Name", "Journal Batch Name", "Journal Line No.", "Dimension Code")
        {
            Clustered = true;
        }
    }
}
