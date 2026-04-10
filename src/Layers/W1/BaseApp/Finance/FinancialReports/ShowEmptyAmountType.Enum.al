// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Controls display formatting for empty or zero amount values in financial reports.
/// Determines visual representation when calculation results are zero or undefined.
/// </summary>
enum 25 "Show Empty Amount Type"
{
    Extensible = true;

    /// <summary>
    /// Displays empty cell with no text when amount is zero or undefined.
    /// </summary>
    value(0; Blank)
    {
        Caption = 'Blank';
    }
    /// <summary>
    /// Shows literal zero value when amount calculation results in zero.
    /// </summary>
    value(1; Zero)
    {
        Caption = 'Zero';
    }
    /// <summary>
    /// Displays dash symbol to indicate zero or unavailable amount data.
    /// </summary>
    value(2; Dash)
    {
        Caption = 'Dash';
    }
}
