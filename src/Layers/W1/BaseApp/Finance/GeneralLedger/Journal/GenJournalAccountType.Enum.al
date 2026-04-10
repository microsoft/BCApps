// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Defines the types of accounts available for journal line postings in general journal entries.
/// Controls validation rules and posting behavior based on the selected account type.
/// </summary>
enum 81 "Gen. Journal Account Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// General ledger account posting type for direct G/L transactions.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Customer account type for accounts receivable transactions.
    /// </summary>
    value(1; "Customer") { Caption = 'Customer'; }
    /// <summary>
    /// Vendor account type for accounts payable transactions.
    /// </summary>
    value(2; "Vendor") { Caption = 'Vendor'; }
    /// <summary>
    /// Bank account type for cash and banking transactions.
    /// </summary>
    value(3; "Bank Account") { Caption = 'Bank Account'; }
    /// <summary>
    /// Fixed asset account type for asset acquisition, disposal, and depreciation transactions.
    /// </summary>
    value(4; "Fixed Asset") { Caption = 'Fixed Asset'; }
    /// <summary>
    /// Intercompany partner account type for intercompany transactions.
    /// </summary>
    value(5; "IC Partner") { Caption = 'IC Partner'; }
    /// <summary>
    /// Employee account type for employee-related financial transactions.
    /// </summary>
    value(6; "Employee") { Caption = 'Employee'; }
    /// <summary>
    /// Allocation account type for distributing amounts across multiple dimensions or accounts.
    /// </summary>
    value(10; "Allocation Account") { Caption = 'Allocation Account'; }
}
