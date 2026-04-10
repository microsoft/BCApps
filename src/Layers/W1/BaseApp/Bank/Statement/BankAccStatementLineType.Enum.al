// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Statement;

/// <summary>
/// Defines the type of ledger entry associated with bank account statement lines.
/// Determines the source of matching transactions for reconciliation purposes.
/// </summary>
/// <remarks>
/// Used in Bank Account Statement Line table for transaction categorization and matching logic.
/// </remarks>
enum 1249 "Bank Acc. Statement Line Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Statement line matches against bank account ledger entries for payment reconciliation.
    /// </summary>
    value(0; "Bank Account Ledger Entry") { Caption = 'Bank Account Ledger Entry'; }
    /// <summary>
    /// Statement line matches against check ledger entries for check reconciliation.
    /// </summary>
    value(1; "Check Ledger Entry") { Caption = 'Check Ledger Entry'; }
    /// <summary>
    /// Statement line represents a difference requiring adjustment entry.
    /// </summary>
    value(2; "Difference") { Caption = 'Difference'; }
}
