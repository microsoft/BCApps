// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Defines the types of journal templates that determine journal behavior, validation rules, and available functionality.
/// Each template type provides specialized features for different business transaction scenarios.
/// </summary>
enum 89 "Gen. Journal Template Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// General template type for all-purpose journal entries with full flexibility.
    /// </summary>
    value(0; General)
    {
        Caption = 'General';
    }
    /// <summary>
    /// Sales template type optimized for customer-related transactions and receivables.
    /// </summary>
    value(1; Sales)
    {
        Caption = 'Sales';
    }
    /// <summary>
    /// Purchases template type optimized for vendor-related transactions and payables.
    /// </summary>
    value(2; Purchases)
    {
        Caption = 'Purchases';
    }
    /// <summary>
    /// Cash receipts template type specialized for incoming payment transactions.
    /// </summary>
    value(3; "Cash Receipts")
    {
        Caption = 'Cash Receipts';
    }
    /// <summary>
    /// Payments template type specialized for outgoing payment transactions.
    /// </summary>
    value(4; Payments)
    {
        Caption = 'Payments';
    }
    /// <summary>
    /// Assets template type specialized for fixed asset transactions and depreciation.
    /// </summary>
    value(5; Assets)
    {
        Caption = 'Assets';
    }
    /// <summary>
    /// Intercompany template type for transactions between related companies.
    /// </summary>
    value(6; Intercompany)
    {
        Caption = 'Intercompany';
    }
    /// <summary>
    /// Projects template type for project-related financial transactions and cost tracking.
    /// </summary>
    value(7; Jobs)
    {
        Caption = 'Projects';
    }
}
