// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

/// <summary>
/// Defines the types of balancing accounts that can be used for payment transactions.
/// Used in payment processing to specify the account type for balancing entries.
/// </summary>
enum 96 "Payment Balance Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// General Ledger account used as balancing account for payment transactions.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Bank account used as balancing account for payment transactions.
    /// </summary>
    value(1; "Bank Account") { Caption = 'Bank Account'; }
}
