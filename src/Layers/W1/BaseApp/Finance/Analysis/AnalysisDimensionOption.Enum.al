// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Defines dimension options for analysis matrix rows and columns in multi-dimensional reporting.
/// Controls which data dimensions are displayed in analysis views and matrix reports.
/// </summary>
enum 727 "Analysis Dimension Option"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Display G/L accounts in the analysis dimension.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Display time periods in the analysis dimension.
    /// </summary>
    value(1; "Period") { Caption = 'Period'; }
    /// <summary>
    /// Display business units in the analysis dimension.
    /// </summary>
    value(2; "Business Unit") { Caption = 'Business Unit'; }
    /// <summary>
    /// Display dimension 1 values in the analysis dimension.
    /// </summary>
    value(3; "Dimension 1") { Caption = 'Dimension 1'; }
    /// <summary>
    /// Display dimension 2 values in the analysis dimension.
    /// </summary>
    value(4; "Dimension 2") { Caption = 'Dimension 2'; }
    /// <summary>
    /// Display dimension 3 values in the analysis dimension.
    /// </summary>
    value(5; "Dimension 3") { Caption = 'Dimension 3'; }
    /// <summary>
    /// Display dimension 4 values in the analysis dimension.
    /// </summary>
    value(6; "Dimension 4") { Caption = 'Dimension 4'; }
    /// <summary>
    /// Display cash flow accounts in the analysis dimension.
    /// </summary>
    value(7; "Cash Flow Account") { Caption = 'Cash Flow Account'; }
    /// <summary>
    /// Display cash flow forecasts in the analysis dimension.
    /// </summary>
    value(8; "Cash Flow Forecast") { Caption = 'Cash Flow Forecast'; }
    /// <summary>
    /// Undefined dimension option used as default or placeholder.
    /// </summary>
    value(99; "Undefined") { Caption = 'Undefined'; }
}
