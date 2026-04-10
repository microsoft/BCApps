// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

/// <summary>
/// Defines document types for intercompany outbox sales transactions.
/// Controls sales document classification and processing rules for outbound intercompany communications.
/// </summary>
/// <remarks>
/// Standard values: Order, Invoice, Credit Memo, Return Order.
/// Extensible via enum extensions for custom sales document types in intercompany scenarios.
/// </remarks>
enum 427 "IC Outbox Sales Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Sales order document for intercompany order processing and fulfillment.
    /// </summary>
    value(0; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Sales invoice document for intercompany billing and revenue recognition.
    /// </summary>
    value(1; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Sales credit memo document for intercompany billing corrections and returns processing.
    /// </summary>
    value(2; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Sales return order document for intercompany goods return and reversal processing.
    /// </summary>
    value(3; "Return Order") { Caption = 'Return Order'; }
}
