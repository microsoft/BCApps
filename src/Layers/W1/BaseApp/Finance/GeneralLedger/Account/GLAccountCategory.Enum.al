// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Primary financial statement categories for general ledger accounts used in automated financial reporting.
/// Determines whether accounts appear on Balance Sheet or Income Statement and their reporting classification.
/// </summary>
enum 15 "G/L Account Category"
{
    Extensible = false;
    AssignmentCompatibility = true;

    /// <summary>
    /// Unspecified category for accounts that have not been classified.
    /// </summary>
    value(0; " ")
    {
        Caption = ' ';
    }
    /// <summary>
    /// Balance sheet category for accounts representing resources owned by the organization.
    /// </summary>
    value(1; Assets)
    {
        Caption = 'Assets';
    }
    /// <summary>
    /// Balance sheet category for accounts representing debts and obligations owed by the organization.
    /// </summary>
    value(2; Liabilities)
    {
        Caption = 'Liabilities';
    }
    /// <summary>
    /// Balance sheet category for accounts representing owner's equity and retained earnings.
    /// </summary>
    value(3; Equity)
    {
        Caption = 'Equity';
    }
    /// <summary>
    /// Income statement category for accounts representing revenue and sales income.
    /// </summary>
    value(4; "Income")
    {
        Caption = 'Income';
    }
    /// <summary>
    /// Income statement category for accounts representing direct costs associated with producing goods sold.
    /// </summary>
    value(5; "Cost of Goods Sold")
    {
        Caption = 'Cost of Goods Sold';
    }
    /// <summary>
    /// Income statement category for accounts representing operating expenses and overhead costs.
    /// </summary>
    value(6; "Expense")
    {
        Caption = 'Expense';
    }
}
