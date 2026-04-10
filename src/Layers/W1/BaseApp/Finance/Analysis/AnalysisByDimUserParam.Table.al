// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

using Microsoft.Foundation.Enums;

/// <summary>
/// Stores user-specific parameters for analysis by dimensions page configurations.
/// Enables personalization of analysis view settings and filters for individual users and pages.
/// </summary>
/// <remarks>
/// User preferences are stored per Analysis View Code, User ID, and Page ID combination.
/// Provides persistence for analysis parameters including dimension options, filters, and display settings.
/// </remarks>
table 727 "Analysis by Dim. User Param."
{
    DataClassification = SystemMetadata;

    fields
    {
        /// <summary>
        /// Analysis view code identifying the specific analysis view configuration.
        /// Links to the Analysis View table for analysis definition and dimension setup.
        /// </summary>
        field(1; "Analysis View Code"; Code[10])
        {
            Caption = 'Analysis View Code';
            TableRelation = "Analysis View";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension option for row display in analysis matrix (Account, Period, Dimension 1-4).
        /// Controls what data is displayed in rows of the analysis by dimensions matrix.
        /// </summary>
        field(3; "Line Dim Option"; Enum "Analysis Dimension Option")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Dimension option for column display in analysis matrix (Account, Period, Dimension 1-4).
        /// Controls what data is displayed in columns of the analysis by dimensions matrix.
        /// </summary>
        field(4; "Column Dim Option"; Enum "Analysis Dimension Option")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Date range filter for restricting analysis to specific time periods.
        /// Enables period-based filtering for analysis by dimensions reports.
        /// </summary>
        field(5; "Date Filter"; Text[250])
        {
            Caption = 'Date Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// G/L account filter for restricting analysis to specific account ranges.
        /// Limits analysis data to specified general ledger accounts.
        /// </summary>
        field(6; "Account Filter"; Text[250])
        {
            Caption = 'Account Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Business unit filter for restricting analysis to specific business units.
        /// Enables organizational-level filtering for multi-company analysis scenarios.
        /// </summary>
        field(7; "Bus. Unit Filter"; Text[250])
        {
            Caption = 'Business Unit Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Cash flow forecast filter for cash flow analysis scenarios.
        /// Restricts cash flow analysis to specific forecast entries.
        /// </summary>
        field(8; "Cash Flow Forecast Filter"; Text[250])
        {
            Caption = 'Cash Flow Forecast Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Budget name filter for restricting analysis to specific budget entries.
        /// Enables budget vs actual comparisons for selected budget scenarios.
        /// </summary>
        field(9; "Budget Filter"; Text[250])
        {
            Caption = 'Budget Filter';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter for Dimension 1 values to restrict analysis to specific dimension value ranges.
        /// </summary>
        field(10; "Dimension 1 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter for Dimension 2 values to restrict analysis to specific dimension value ranges.
        /// </summary>
        field(11; "Dimension 2 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter for Dimension 3 values to restrict analysis to specific dimension value ranges.
        /// </summary>
        field(12; "Dimension 3 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Filter for Dimension 4 values to restrict analysis to specific dimension value ranges.
        /// </summary>
        field(13; "Dimension 4 Filter"; Text[250])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Determines whether to show actual amounts, budget amounts, or variance in the analysis.
        /// </summary>
        field(20; "Show Actual/Budgets"; Enum "Analysis Show Amount Type")
        {
            Caption = 'Show';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies which amount field type to display in the analysis (Net Change, Balance at Date, etc.).
        /// </summary>
        field(21; "Show Amount Field"; Enum "Analysis Show Amount Field")
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether closing entries are included or excluded from the analysis calculations.
        /// </summary>
        field(22; "Closing Entries"; Option)
        {
            Caption = 'Closing Entries';
            OptionCaption = 'Include,Exclude';
            OptionMembers = Include,Exclude;
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Rounding factor applied to amounts in the analysis display for better readability.
        /// </summary>
        field(23; "Rounding Factor"; Enum "Analysis Rounding Factor")
        {
            Caption = 'Rounding Factor';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// When enabled, shows amounts in additional reporting currency instead of local currency.
        /// </summary>
        field(24; "Show In Add. Currency"; Boolean)
        {
            Caption = 'Show Amounts in Add. Reporting Currency';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Controls whether column names are displayed in the matrix analysis view.
        /// </summary>
        field(25; "Show Column Name"; Boolean)
        {
            Caption = 'Show Column Name';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// When enabled, displays amounts with opposite signs (positive becomes negative and vice versa).
        /// </summary>
        field(26; "Show Opposite Sign"; Boolean)
        {
            Caption = 'Show Opposite Sign';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Defines the period type for organizing data in the analysis (Day, Week, Month, Quarter, Year, Accounting Period).
        /// </summary>
        field(30; "Period Type"; Option)
        {
            Caption = 'View by';
            OptionCaption = 'Day,Week,Month,Quarter,Year,Accounting Period';
            OptionMembers = Day,Week,Month,Quarter,Year,"Accounting Period";
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Specifies the column set definition for matrix display configuration.
        /// </summary>
        field(31; "Column Set"; Text[250])
        {
            Caption = 'Column Set';
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Determines the amount calculation type - either Net Change or Balance at Date.
        /// </summary>
        field(33; "Amount Type"; Option)
        {
            Caption = 'View as';
            OptionCaption = 'Net Change,Balance at Date';
            OptionMembers = "Net Change","Balance at Date";
            DataClassification = SystemMetadata;
        }
        field(1000; "User ID"; Code[50])
        {
            DataClassification = SystemMetadata;
        }
        /// <summary>
        /// Page ID for associating parameter settings with specific analysis pages.
        /// </summary>
        field(1001; "Page ID"; Integer)
        {
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; "User ID", "Page ID")
        {
            Clustered = true;
        }
    }

    /// <summary>
    /// Loads saved user parameters into analysis parameters for the specified page.
    /// Retrieves user-specific settings and transfers them to the analysis parameters record.
    /// </summary>
    /// <param name="AnalysisByDimParameters">Analysis parameters record to receive loaded settings</param>
    /// <param name="PageId">Page ID to identify which parameter set to load</param>
    procedure Load(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; PageId: Integer)
    begin
        case PageId of
            Page::"Analysis by Dimensions":
                LoadForAnalysisByDimensions(AnalysisByDimParameters);
            Page::"G/L Balance by Dimension":
                LoadForGLBalanceByDimension(AnalysisByDimParameters);
        end;
    end;

    local procedure LoadForGLBalanceByDimension(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    begin
        AnalysisByDimParameters.Init();
        if Get(UserId(), Page::"G/L Balance by Dimension") then
            AnalysisByDimParameters.TransferFields(Rec);
        AnalysisByDimParameters.Insert();
    end;

    local procedure LoadForAnalysisByDimensions(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters")
    var
        SavedAnalysisViewCode: Code[10];
        AccountsFilter: Text[250];
    begin
        AccountsFilter := AnalysisByDimParameters."Account Filter";
        if AnalysisByDimParameters."Analysis View Code" <> '' then begin
            SavedAnalysisViewCode := AnalysisByDimParameters."Analysis View Code";
            if Get(UserId(), Page::"Analysis by Dimensions") then begin
                AnalysisByDimParameters.TransferFields(Rec);
                if AccountsFilter <> '' then
                    AnalysisByDimParameters."Account Filter" := AccountsFilter;
                AnalysisByDimParameters."Analysis View Code" := SavedAnalysisViewCode;
            end;
            AnalysisByDimParameters.Modify();
        end else begin
            AnalysisByDimParameters.Init();
            if Get(UserId(), Page::"Analysis by Dimensions") then begin
                AnalysisByDimParameters.TransferFields(Rec);
                if AccountsFilter <> '' then
                    AnalysisByDimParameters."Account Filter" := AccountsFilter;
            end;
            AnalysisByDimParameters.Insert();
        end;
    end;

    /// <summary>
    /// Saves current analysis parameters as user-specific settings for the specified page.
    /// Stores analysis configuration for future use by the current user on the specified page.
    /// </summary>
    /// <param name="AnalysisByDimParameters">Analysis parameters record containing settings to save</param>
    /// <param name="PageId">Page ID to identify which parameter set to save</param>
    procedure Save(var AnalysisByDimParameters: Record "Analysis by Dim. Parameters"; PageId: Integer)
    var
        CurrUserId: Code[50];
    begin
        CurrUserId := CopyStr(UserId(), 1, MaxStrLen("User ID"));
        if Get(CurrUserId, PageId) then begin
            TransferFields(AnalysisByDimParameters);
            Modify();
        end else begin
            Init();
            TransferFields(AnalysisByDimParameters);
            "User ID" := CurrUserId;
            "Page ID" := PageId;
            Insert();
        end;
    end;
}
