// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.Consolidation;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.FinancialReports;
using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Finance.GeneralLedger.Budget;

/// <summary>
/// Stores aggregated budget data for analysis views with dimension breakdown.
/// Contains pre-calculated budget amounts for optimized budget vs. actual reporting and analysis.
/// </summary>
/// <remarks>
/// Analysis view budget entries are created and updated by the UpdateAnalysisView process from G/L Budget entries.
/// Each record represents aggregated budget data for a specific budget, account, business unit, date, and dimension combination.
/// Used for budget variance analysis and budget reporting in analysis views and account schedules.
/// </remarks>
table 366 "Analysis View Budget Entry"
{
    Caption = 'Analysis View Budget Entry';
    DrillDownPageID = "Analysis View Budget Entries";
    LookupPageID = "Analysis View Budget Entries";
    DataClassification = CustomerContent;

    fields
    {
        /// <summary>
        /// Analysis view code identifying the configuration used for this budget entry.
        /// Links to the Analysis View table for dimension and account settings.
        /// </summary>
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            NotBlank = true;
            TableRelation = "Analysis View";
        }
        /// <summary>
        /// Budget name identifying the source G/L Budget for this analysis entry.
        /// Links to G/L Budget Name table for budget configuration and parameters.
        /// </summary>
        field(2; "Budget Name"; Code[10])
        {
            Caption = 'Budget Name';
            TableRelation = "G/L Budget Name";
        }
        /// <summary>
        /// Business unit code for consolidation and multi-company analysis.
        /// Empty for single-company budget analysis, populated for consolidation scenarios.
        /// </summary>
        field(3; "Business Unit Code"; Code[20])
        {
            Caption = 'Business Unit Code';
            TableRelation = "Business Unit";
        }
        /// <summary>
        /// G/L account number for the budget amount aggregation.
        /// All budget entries for this account are aggregated into analysis view entries.
        /// </summary>
        field(4; "G/L Account No."; Code[20])
        {
            Caption = 'G/L Account No.';
            TableRelation = "G/L Account";
        }
        /// <summary>
        /// First dimension value code for budget analysis breakdown.
        /// Caption and available values determined by the analysis view dimension 1 setup.
        /// </summary>
        field(5; "Dimension 1 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(1);
            Caption = 'Dimension 1 Value Code';
        }
        /// <summary>
        /// Second dimension value code for budget analysis breakdown.
        /// Caption and available values determined by the analysis view dimension 2 setup.
        /// </summary>
        field(6; "Dimension 2 Value Code"; Code[20])
        {
            AccessByPermission = TableData Dimension = R;
            CaptionClass = GetCaptionClass(2);
            Caption = 'Dimension 2 Value Code';
        }
        /// <summary>
        /// Third dimension value code for budget analysis breakdown.
        /// Caption and available values determined by the analysis view dimension 3 setup.
        /// </summary>
        field(7; "Dimension 3 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(3);
            Caption = 'Dimension 3 Value Code';
        }
        /// <summary>
        /// Fourth dimension value code for budget analysis breakdown.
        /// Caption and available values determined by the analysis view dimension 4 setup.
        /// </summary>
        field(8; "Dimension 4 Value Code"; Code[20])
        {
            AccessByPermission = TableData "Dimension Combination" = R;
            CaptionClass = GetCaptionClass(4);
            Caption = 'Dimension 4 Value Code';
        }
        /// <summary>
        /// Budget posting date for period-based analysis and reporting.
        /// Used for date filtering and period aggregation in budget analysis views.
        /// </summary>
        field(9; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        /// <summary>
        /// Sequential entry number for unique identification within the analysis view.
        /// Part of the primary key to distinguish entries with identical dimension combinations.
        /// </summary>
        field(10; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        /// <summary>
        /// Budget amount aggregated from G/L budget entries for this dimension combination.
        /// Automatically formatted according to currency and amount display settings.
        /// </summary>
        field(11; Amount; Decimal)
        {
            AutoFormatExpression = '';
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(10720; "Old G/L Account No."; Code[20])
        {
            Caption = 'Old G/L Account No.';
        }
        field(10721; Updated; Boolean)
        {
            Caption = 'Updated';
        }
    }

    keys
    {
        key(Key1; "Analysis View Code", "Budget Name", "G/L Account No.", "Dimension 1 Value Code", "Dimension 2 Value Code", "Dimension 3 Value Code", "Dimension 4 Value Code", "Business Unit Code", "Posting Date", "Entry No.", "Old G/L Account No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    /// <summary>
    /// Gets the caption class for dimension fields based on analysis view configuration.
    /// Provides dynamic field captions based on the analysis view's dimension setup.
    /// </summary>
    /// <param name="AnalysisViewDimType">Dimension number (1-4) to get caption class for</param>
    /// <returns>Caption class string for dynamic field captioning</returns>
    procedure GetCaptionClass(AnalysisViewDimType: Integer): Text[250]
    var
        AnalysisViewEntry: Record "Analysis View Entry";
    begin
        AnalysisViewEntry.Init();
        AnalysisViewEntry."Analysis View Code" := "Analysis View Code";
        exit(AnalysisViewEntry.GetCaptionClass(AnalysisViewDimType));
    end;

    /// <summary>
    /// Copies dimension filters from account schedule line to analysis view budget entry.
    /// Transfers filter criteria for dimension-based budget analysis and reporting.
    /// </summary>
    /// <param name="AccSchedLine">Account schedule line containing dimension filters to copy</param>
    procedure CopyDimFilters(var AccSchedLine: Record "Acc. Schedule Line")
    begin
        AccSchedLine.CopyFilter("Dimension 1 Filter", "Dimension 1 Value Code");
        AccSchedLine.CopyFilter("Dimension 2 Filter", "Dimension 2 Value Code");
        AccSchedLine.CopyFilter("Dimension 3 Filter", "Dimension 3 Value Code");
        AccSchedLine.CopyFilter("Dimension 4 Filter", "Dimension 4 Value Code");
    end;

    /// <summary>
    /// Sets dimension filters on analysis view budget entry using text filter expressions.
    /// Applies filter criteria for all four dimensions in budget analysis queries.
    /// </summary>
    /// <param name="DimFilter1">Filter expression for dimension 1 value code</param>
    /// <param name="DimFilter2">Filter expression for dimension 2 value code</param>
    /// <param name="DimFilter3">Filter expression for dimension 3 value code</param>
    /// <param name="DimFilter4">Filter expression for dimension 4 value code</param>
    procedure SetDimFilters(DimFilter1: Text; DimFilter2: Text; DimFilter3: Text; DimFilter4: Text)
    begin
        SetFilter("Dimension 1 Value Code", DimFilter1);
        SetFilter("Dimension 2 Value Code", DimFilter2);
        SetFilter("Dimension 3 Value Code", DimFilter3);
        SetFilter("Dimension 4 Value Code", DimFilter4);
    end;
}
