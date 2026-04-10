// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines visibility conditions for account schedule lines based on calculation results and balance criteria.
/// Controls when account schedule lines are displayed in reports and financial statements.
/// </summary>
/// <remarks>
/// Extensible enum enabling conditional display of account schedule rows based on data values.
/// Supports various visibility rules including zero-value filtering and balance-based conditions
/// for cleaner financial report presentation and enhanced readability.
/// </remarks>
enum 851 "Acc. Schedule Line Show"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Always displays the account schedule line regardless of calculated values.
    /// </summary>
    value(0; "Yes")
    {
        Caption = 'Yes';
    }
    /// <summary>
    /// Never displays the account schedule line, effectively hiding it from reports.
    /// </summary>
    value(1; "No")
    {
        Caption = 'No';
    }
    /// <summary>
    /// Displays the account schedule line only if at least one column contains a non-zero value.
    /// </summary>
    value(2; "If Any Column Not Zero")
    {
        Caption = 'If Any Column Not Zero';
    }
    /// <summary>
    /// Displays the account schedule line only when the calculated balance is positive.
    /// </summary>
    value(3; "When Positive Balance")
    {
        Caption = 'When Positive Balance';
    }
    /// <summary>
    /// Displays the account schedule line only when the calculated balance is negative.
    /// </summary>
    value(4; "When Negative Balance")
    {
        Caption = 'When Negative Balance';
    }
}
