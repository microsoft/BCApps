// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Defines the currency posting options for G/L accounts when dealing with source currencies.
/// Determines how the system handles currency restrictions for account postings.
/// </summary>
enum 590 "G/L Source Currency Posting"
{
    Extensible = true;

    /// <summary>
    /// No specific currency restriction is applied to the account.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// The account can accept postings in multiple different currencies.
    /// </summary>
    value(1; "Multiple Currencies") { Caption = 'Multiple Currencies'; }
    /// <summary>
    /// The account can only accept postings in the same currency once a currency is established.
    /// </summary>
    value(2; "Same Currency") { Caption = 'Same Currency'; }
    /// <summary>
    /// The account can only accept postings in the local currency (LCY).
    /// </summary>
    value(3; "LCY Only") { Caption = 'LCY Only'; }
}
