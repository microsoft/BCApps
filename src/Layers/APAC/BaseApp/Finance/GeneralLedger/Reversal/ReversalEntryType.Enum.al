// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reversal;

/// <summary>
/// Defines the types of ledger entries that can be included in reversal operations.
/// Specifies which master table type the reversal entry corresponds to for proper routing and validation.
/// </summary>
enum 180 "Reversal Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Empty value for initialization and filtering purposes.
    /// </summary>
    value(0; " ")
    {
    }
    /// <summary>
    /// G/L Account ledger entry type for general ledger transaction reversals.
    /// </summary>
    value(1; "G/L Account")
    {
        Caption = 'G/L Account';
    }
    /// <summary>
    /// Customer ledger entry type for customer transaction reversals including payments and invoices.
    /// </summary>
    value(2; "Customer")
    {
        Caption = 'Customer';
    }
    /// <summary>
    /// Vendor ledger entry type for vendor transaction reversals including payments and invoices.
    /// </summary>
    value(3; "Vendor")
    {
        Caption = 'Vendor';
    }
    /// <summary>
    /// Bank Account ledger entry type for bank transaction reversals including deposits and checks.
    /// </summary>
    value(4; "Bank Account")
    {
        Caption = 'Bank Account';
    }
    /// <summary>
    /// Fixed Asset ledger entry type for fixed asset transaction reversals including acquisitions and disposals.
    /// </summary>
    value(5; "Fixed Asset")
    {
        Caption = 'Fixed Asset';
    }
    /// <summary>
    /// Maintenance ledger entry type for fixed asset maintenance transaction reversals.
    /// </summary>
    value(6; "Maintenance")
    {
        Caption = 'Maintenance';
    }
    /// <summary>
    /// VAT entry type for VAT transaction reversals including input and output VAT.
    /// </summary>
    value(7; "VAT")
    {
        Caption = 'VAT';
    }
    /// <summary>
    /// Employee ledger entry type for employee transaction reversals including expense reimbursements.
    /// </summary>
    value(8; "Employee")
    {
        Caption = 'Employee';
    }
    value(10; "WHT")
    {
        Caption = 'WHT';
    }
}
