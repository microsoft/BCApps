// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines how amounts are calculated and displayed in account schedule reporting.
/// Controls whether to show net amounts or split into debit/credit components for analysis.
/// </summary>
enum 333 "Account Schedule Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Shows the net amount (debits minus credits) for account balances and transactions.
    /// </summary>
    value(0; "Net Amount")
    {
        Caption = 'Net Amount';
    }
    /// <summary>
    /// Shows only debit amounts, filtering out credit transactions for focused analysis.
    /// </summary>
    value(1; "Debit Amount")
    {
        Caption = 'Debit Amount';
    }
    /// <summary>
    /// Shows only credit amounts, filtering out debit transactions for focused analysis.
    /// </summary>
    value(2; "Credit Amount")
    {
        Caption = 'Credit Amount';
    }
}
