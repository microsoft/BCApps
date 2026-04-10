// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Defines which primary financial statement an account appears on for reporting and year-end closing purposes.
/// Controls whether account balances are closed at year-end or carried forward to the next period.
/// </summary>
enum 20 "G/L Account Report Type"
{
    AssignmentCompatibility = true;
    Extensible = true;

    /// <summary>
    /// Account appears on Income Statement and balance is closed to retained earnings at year-end.
    /// </summary>
    value(0; "Income Statement") { Caption = 'Income Statement'; }
    /// <summary>
    /// Account appears on Balance Sheet and balance is carried forward to the next fiscal year.
    /// </summary>
    value(1; "Balance Sheet") { Caption = 'Balance Sheet'; }
}