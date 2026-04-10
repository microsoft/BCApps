// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Journal;

/// <summary>
/// Defines account types available for intercompany general journal line entries.
/// Controls account classification and validation rules for intercompany transaction posting.
/// </summary>
/// <remarks>
/// Standard values: G/L Account, Bank Account.
/// Extensible via enum extensions for custom intercompany account types.
/// </remarks>
enum 84 "IC Journal Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;
    /// <summary>
    /// General ledger account for intercompany balance sheet and income statement transactions.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Bank account for intercompany cash and financial instrument transactions.
    /// </summary>
    value(1; "Bank Account") { Caption = 'Bank Account'; }
}
