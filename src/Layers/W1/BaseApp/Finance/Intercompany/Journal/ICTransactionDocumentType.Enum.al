// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Journal;

/// <summary>
/// Defines document types for intercompany journal transactions with specific processing rules and validation requirements.
/// Controls document classification, numbering series assignment, and posting behavior for intercompany general journal entries.
/// </summary>
/// <remarks>
/// Standard values: blank, Payment, Invoice, Credit Memo, Refund, Order, Return Order.
/// Extensible via enum extensions for custom intercompany transaction types.
/// </remarks>
enum 414 "IC Transaction Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Empty document type for general intercompany transactions without specific classification.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Payment document for intercompany financial transfers and settlement transactions.
    /// </summary>
    value(1; "Payment") { Caption = 'Payment'; }
    /// <summary>
    /// Invoice document for intercompany billing and receivable transactions.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Credit memo document for intercompany billing corrections and refund transactions.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Refund document for intercompany payment reversals and credit settlements.
    /// </summary>
    value(4; "Refund") { Caption = 'Refund'; }
    /// <summary>
    /// Order document for intercompany purchase and sales order transactions.
    /// </summary>
    value(5; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Return order document for intercompany goods return and reversal transactions.
    /// </summary>
    value(6; "Return Order") { Caption = 'Return Order'; }
}
