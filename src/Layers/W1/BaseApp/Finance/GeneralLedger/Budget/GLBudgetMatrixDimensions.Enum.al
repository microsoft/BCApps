// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Budget;

/// <summary>
/// Defines dimension types available for budget matrix analysis and Excel integration layouts.
/// Controls how budget data is organized and displayed in matrix formats for multi-dimensional analysis.
/// </summary>
/// <remarks>
/// Usage: Budget matrix page layouts, Excel export column structures, and analysis view configurations.
/// Extension: Support for additional dimension types through Extensible = true property.
/// Integration: Used by budget analysis pages and reports for dynamic column generation.
/// </remarks>
enum 114 "G/L Budget Matrix Dimensions"
{
    AssignmentCompatibility = true;
    Extensible = true;

    /// <summary>
    /// G/L Account dimension for displaying budget data organized by chart of accounts structure.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Period dimension for displaying budget data organized by time periods (months, quarters, years).
    /// </summary>
    value(1; "Period") { Caption = 'Period'; }
    /// <summary>
    /// Business Unit dimension for displaying budget data organized by organizational units.
    /// </summary>
    value(2; "Business Unit") { Caption = 'Business Unit'; }
    /// <summary>
    /// Global Dimension 1 for displaying budget data organized by the first company-wide dimension.
    /// </summary>
    value(3; "Global Dimension 1") { Caption = 'Global Dimension 1'; }
    /// <summary>
    /// Global Dimension 2 for displaying budget data organized by the second company-wide dimension.
    /// </summary>
    value(4; "Global Dimension 2") { Caption = 'Global Dimension 2'; }
    /// <summary>
    /// Budget Dimension 1 for displaying budget data organized by the first budget-specific dimension.
    /// </summary>
    value(5; "Budget Dimension 1") { Caption = 'Budget Dimension 1'; }
    /// <summary>
    /// Budget Dimension 2 for displaying budget data organized by the second budget-specific dimension.
    /// </summary>
    value(6; "Budget Dimension 2") { Caption = 'Budget Dimension 2'; }
    /// <summary>
    /// Budget Dimension 3 for displaying budget data organized by the third budget-specific dimension.
    /// </summary>
    value(7; "Budget Dimension 3") { Caption = 'Budget Dimension 3'; }
    /// <summary>
    /// Budget Dimension 4 for displaying budget data organized by the fourth budget-specific dimension.
    /// </summary>
    value(8; "Budget Dimension 4") { Caption = 'Budget Dimension 4'; }
    /// <summary>
    /// Undefined dimension type used as default or placeholder in matrix configurations.
    /// </summary>
    value(99; "Undefined") { Caption = ''; }
}
