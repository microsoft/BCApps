// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Defines source types for general journal entries indicating the origin or context of journal transactions.
/// Used for categorizing journal entries by their business source or transaction origin.
/// </summary>
/// <remarks>
/// Source type classification for journal entry categorization and reporting purposes.
/// Extensible enum allowing custom source types via extensions for specialized business scenarios.
/// Standard values: Customer, Vendor, Bank Account, Fixed Asset, IC Partner, Employee transactions.
/// Usage: Applied to source code setup and journal line classification for audit and reporting.
/// </remarks>
enum 82 "Gen. Journal Source Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Blank source type for general or unspecified journal entries.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Customer-related journal entries including sales transactions and customer adjustments.
    /// </summary>
    value(1; "Customer") { Caption = 'Customer'; }
    /// <summary>
    /// Vendor-related journal entries including purchase transactions and vendor adjustments.
    /// </summary>
    value(2; "Vendor") { Caption = 'Vendor'; }
    /// <summary>
    /// Bank account transactions including deposits, withdrawals, and bank reconciliation entries.
    /// </summary>
    value(3; "Bank Account") { Caption = 'Bank Account'; }
    /// <summary>
    /// Fixed asset transactions including acquisitions, disposals, and depreciation entries.
    /// </summary>
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
    /// <summary>
    /// Intercompany partner transactions for multi-company and intercompany eliminations.
    /// </summary>
    value(5; "IC Partner") { Caption = 'IC Partner'; }
    /// <summary>
    /// Employee-related transactions including expense reimbursements and payroll adjustments.
    /// </summary>
    value(6; "Employee") { Caption = 'Employee'; }
}
