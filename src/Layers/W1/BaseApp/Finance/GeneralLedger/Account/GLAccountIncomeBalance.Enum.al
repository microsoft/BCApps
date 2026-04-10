// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Determines which primary financial statement an account appears on for reporting purposes.
/// Controls whether account balances are carried forward or closed at year-end.
/// </summary>
enum 18 "G/L Account Income/Balance"
{
    AssignmentCompatibility = true;
    Extensible = false;

    /// <summary>
    /// Unspecified financial statement classification.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Account appears on Income Statement and is closed to retained earnings at year-end.
    /// </summary>
    value(1; "Income Statement") { Caption = 'Income Statement'; }
    /// <summary>
    /// Account appears on Balance Sheet and balances are carried forward to the next fiscal year.
    /// </summary>
    value(2; "Balance Sheet") { Caption = 'Balance Sheet'; }
}
