// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines calculation types for column layouts in financial reports.
/// Determines period calculation method and date range for column amount calculations.
/// </summary>
enum 331 "Column Layout Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Custom formula calculation referencing other columns or expressions.
    /// </summary>
    value(0; "Formula")
    {
        Caption = 'Formula';
    }
    /// <summary>
    /// Net change amount for the specified period range.
    /// </summary>
    value(1; "Net Change")
    {
        Caption = 'Net Change';
    }
    /// <summary>
    /// Balance as of the specified date including all prior transactions.
    /// </summary>
    value(2; "Balance at Date")
    {
        Caption = 'Balance at Date';
    }
    /// <summary>
    /// Opening balance at the start of the fiscal year.
    /// </summary>
    value(3; "Beginning Balance")
    {
        Caption = 'Beginning Balance';
    }
    /// <summary>
    /// Cumulative amount from fiscal year start to current date.
    /// </summary>
    value(4; "Year to Date")
    {
        Caption = 'Year to Date';
    }
    /// <summary>
    /// Projected amount for remaining fiscal year periods.
    /// </summary>
    value(5; "Rest of Fiscal Year")
    {
        Caption = 'Rest of Fiscal Year';
    }
    /// <summary>
    /// Total amount for complete fiscal year period.
    /// </summary>
    value(6; "Entire Fiscal Year")
    {
        Caption = 'Entire Fiscal Year';
    }
    /// <summary>
    /// Cumulative amount from month start to current date.
    /// </summary>
    value(7; "Month to Date")
    {
        Caption = 'Month to Date';
    }
}
