// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Foundation.Enums;

/// <summary>
/// Parameter table for analysis by dimensions functionality storing user selections and filter criteria.
/// Contains all configuration settings for multi-dimensional analysis reports and matrix displays.
/// </summary>
table 361 "Analysis by Dim. Parameters"
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Analysis view code linking to the analysis view configuration used for this analysis.
        /// Determines available dimensions, accounts, and aggregation settings.
        /// </summary>
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            TableRelation = "Analysis View";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension option for matrix row display determining what data appears on rows.
        /// Controls the vertical dimension breakdown in analysis by dimensions reports.
        /// </summary>
        field(3; "Line Dim Option"; Enum "Analysis Dimension Option")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension option for matrix column display determining what data appears on columns.
        /// Controls the horizontal dimension breakdown in analysis by dimensions reports.
        /// </summary>
        field(4; "Column Dim Option"; Enum "Analysis Dimension Option")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date filter expression for period-based analysis and transaction filtering.
        /// Limits analysis to specific date ranges and period boundaries.
        /// </summary>
        field(5; "Date Filter"; Text[250])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account filter for limiting analysis to specific G/L accounts or Cash Flow accounts.
        /// Supports complex filter expressions for account range selection.
        /// </summary>
        field(6; "Account Filter"; Text[250])
        {
            Caption = 'Account Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Business unit filter for consolidation analysis limiting to specific business units.
        /// Used in multi-company scenarios for consolidated financial analysis.
        /// </summary>
        field(7; "Bus. Unit Filter"; Text[250])
        {
            Caption = 'Business Unit Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Cash flow forecast filter for limiting analysis to specific forecast scenarios.
        /// Used when analyzing cash flow account source data with multiple forecasts.
        /// </summary>
        field(8; "Cash Flow Forecast Filter"; Text[250])
        {
            Caption = 'Cash Flow Forecast Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Budget filter for limiting analysis to specific G/L budget names.
        /// Enables budget vs actual comparisons for selected budget scenarios only.
        /// </summary>
        field(9; "Budget Filter"; Text[250])
        {
            Caption = 'Budget Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// First dimension value filter for dimension-based analysis restrictions.
        /// Limits analysis to specific dimension 1 values based on analysis view setup.
        /// </summary>
        field(10; "Dimension 1 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Second dimension value filter for dimension-based analysis restrictions.
        /// Limits analysis to specific dimension 2 values based on analysis view setup.
        /// </summary>
        field(11; "Dimension 2 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Third dimension value filter for dimension-based analysis restrictions.
        /// Limits analysis to specific dimension 3 values based on analysis view setup.
        /// </summary>
        field(12; "Dimension 3 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Fourth dimension value filter for dimension-based analysis restrictions.
        /// Limits analysis to specific dimension 4 values based on analysis view setup.
        /// </summary>
        field(13; "Dimension 4 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether to show actual amounts, budget amounts, or variance in analysis.
        /// Determines the primary data display mode for budget vs actual comparison.
        /// </summary>
        field(20; "Show Actual/Budgets"; Enum "Analysis Show Amount Type")
        {
            Caption = 'Show';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies which amount field to display in the analysis matrix cells.
        /// Controls whether to show net change, balance at date, debit/credit amounts, etc.
        /// </summary>
        field(21; "Show Amount Field"; Enum "Analysis Show Amount Field")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether closing entries are included or excluded from analysis.
        /// Determines if year-end closing transactions should be part of the analysis data.
        /// </summary>
        field(22; "Closing Entries"; Option)
        {
            Caption = 'Closing Entries';
            OptionCaption = 'Include,Exclude';
            OptionMembers = Include,Exclude;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Rounding factor for amount display in analysis reports and matrix views.
        /// Controls the precision and scale of amounts shown (1, 1000, 1000000, etc.).
        /// </summary>
        field(23; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether amounts should be displayed in additional reporting currency.
        /// Enables multi-currency analysis using the additional reporting currency setup.
        /// </summary>
        field(24; "Show In Add. Currency"; Boolean)
        {
            Caption = 'Show Amounts in Add. Reporting Currency';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether column names are displayed in matrix reports.
        /// Enables or disables column header display for better readability.
        /// </summary>
        field(25; "Show Column Name"; Boolean)
        {
            Caption = 'Show Column Name';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Indicates whether amounts should be displayed with opposite sign.
        /// Useful for converting debits to credits or changing sign conventions.
        /// </summary>
        field(26; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Period type for time-based analysis and matrix column generation.
        /// Controls the granularity of period-based analysis (Day, Week, Month, etc.).
        /// </summary>
        field(30; "Period Type"; Enum "Analysis Period Type")
        {
            Caption = 'View by';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Column set identifier for matrix navigation and column position tracking.
        /// Maintains the current position in multi-column analysis displays.
        /// </summary>
        field(31; "Column Set"; Text[250])
        {
            Caption = 'Column Set';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Amount type for balance analysis determining the calculation method.
        /// Controls whether to show net change, balance at date, or movement amounts.
        /// </summary>
        field(33; "Amount Type"; Enum "Analysis Amount Type")
        {
            Caption = 'View as';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Account source type determining whether to analyze G/L or Cash Flow accounts.
        /// Controls the data source and available dimensions for analysis processing.
        /// </summary>
        field(34; "Analysis Account Source"; Enum "Analysis Account Source")
        {
            Caption = 'Analysis Account Source';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key("Key 1"; "Analysis View Code")
        {
            Clustered = true;
        }
    }

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;

    /// <summary>
    /// Gets the minimum date from the date filter expression for period boundary calculations.
    /// Provides the starting date for analysis range validation and period setup.
    /// </summary>
    /// <returns>Minimum date from the date filter or zero date if no filter is set</returns>
    procedure GetRangeMinDateFilter(): Date
    var
        TempGLAccount: Record "G/L Account" temporary;
    begin
        if "Date Filter" <> '' then begin
            TempGLAccount.SetFilter("Date Filter", "Date Filter");
            exit(TempGLAccount.GetRangeMin("Date Filter"));
        end;
    end;
}
