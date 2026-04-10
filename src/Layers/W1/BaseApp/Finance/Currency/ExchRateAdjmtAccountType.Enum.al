// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Currency;

/// <summary>
/// Defines the account types that can be processed during exchange rate adjustments.
/// Specifies which types of accounts are subject to currency revaluation procedures.
/// </summary>
/// <remarks>
/// Used in exchange rate adjustment processes to categorize accounts for revaluation.
/// Extensible to support additional account types for custom adjustment scenarios.
/// </remarks>
enum 596 "Exch. Rate Adjmt. Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// General ledger account for exchange rate adjustments.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Customer account requiring currency revaluation.
    /// </summary>
    value(1; "Customer") { Caption = 'Customer'; }
    /// <summary>
    /// Vendor account requiring currency revaluation.
    /// </summary>
    value(2; "Vendor") { Caption = 'Vendor'; }
    /// <summary>
    /// Bank account requiring currency revaluation.
    /// </summary>
    value(3; "Bank Account") { Caption = 'Bank Account'; }
    /// <summary>
    /// Employee account requiring currency revaluation.
    /// </summary>
    value(4; Employee) { Caption = 'Employee'; }
}
