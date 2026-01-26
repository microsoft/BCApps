// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Journal;

/// <summary>
/// Defines document types for general journal entries that control posting behavior and validation rules.
/// Determines how transactions are processed and affects downstream document creation and reporting.
/// </summary>
enum 6 "Gen. Journal Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Blank document type for general transactions without specific document classification.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Payment document type for outbound payment transactions.
    /// </summary>
    value(1; "Payment") { Caption = 'Payment'; }
    /// <summary>
    /// Invoice document type for billing transactions that create receivables or payables.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Credit memo document type for crediting transactions that reduce receivables or payables.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Finance charge memo document type for applying financial charges to customer accounts.
    /// </summary>
    value(4; "Finance Charge Memo") { Caption = 'Finance Charge Memo'; }
    /// <summary>
    /// Reminder document type for customer payment reminder transactions.
    /// </summary>
    value(5; "Reminder") { Caption = 'Reminder'; }
    /// <summary>
    /// Refund document type for inbound refund transactions.
    /// </summary>
    value(6; "Refund") { Caption = 'Refund'; }
    value(10; "Dishonored") { Caption = 'Dishonored'; }
}
