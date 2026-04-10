// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Defines the type of bank account reconciliation statement being processed.
/// This enum distinguishes between different reconciliation workflows and determines which
/// features and validation rules are applied during the reconciliation process.
/// </summary>
enum 1254 "Bank Acc. Rec. Stmt. Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Standard bank reconciliation process for matching bank statements with bank account ledger entries.
    /// Used for reconciling actual bank transactions with recorded book transactions to identify differences
    /// and ensure accurate bank account balances.
    /// </summary>
    value(0; "Bank Reconciliation") { Caption = 'Bank Reconciliation'; }

    /// <summary>
    /// Payment application process for matching incoming payments with outstanding customer and vendor invoices.
    /// Used specifically for processing payment files and applying them to open invoices, credit memos, and other documents.
    /// </summary>
    value(1; "Payment Application") { Caption = 'Payment Application'; }
}
