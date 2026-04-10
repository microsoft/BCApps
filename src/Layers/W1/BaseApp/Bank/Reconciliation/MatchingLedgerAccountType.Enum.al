// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Reconciliation;

/// <summary>
/// Defines the types of ledger accounts that can be matched during bank reconciliation and payment application processes.
/// This enum is used to specify which type of account a bank statement line should be applied to,
/// enabling proper routing of transactions to the appropriate ledger entries for reconciliation.
/// </summary>
enum 1248 "Matching Ledger Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Customer account type for matching payments received from customers.
    /// Used when applying bank statement lines to customer ledger entries for invoice payments and credit applications.
    /// </summary>
    value(0; "Customer") { Caption = 'Customer'; }

    /// <summary>
    /// Vendor account type for matching payments made to vendors.
    /// Used when applying bank statement lines to vendor ledger entries for bill payments and credit applications.
    /// </summary>
    value(1; "Vendor") { Caption = 'Vendor'; }

    /// <summary>
    /// General Ledger account type for direct G/L account postings.
    /// Used when bank statement lines should be applied directly to G/L accounts without customer or vendor involvement.
    /// </summary>
    value(2; "G/L Account") { Caption = 'G/L Account'; }

    /// <summary>
    /// Bank account type for inter-bank transfers and bank-to-bank transactions.
    /// Used when matching transfers between different bank accounts within the same company.
    /// </summary>
    value(3; "Bank Account") { Caption = 'Bank Account'; }

    /// <summary>
    /// Employee account type for matching employee-related payments such as expense reimbursements and salary advances.
    /// Used when applying bank statement lines to employee ledger entries.
    /// </summary>
    value(4; "Employee") { Caption = 'Employee'; }
}
