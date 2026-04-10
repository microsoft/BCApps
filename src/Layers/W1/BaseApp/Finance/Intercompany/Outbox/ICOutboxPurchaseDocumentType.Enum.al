// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Intercompany.Outbox;

/// <summary>
/// Defines document types for intercompany outbox purchase transactions.
/// Controls purchase document classification and processing rules for outbound intercompany communications.
/// </summary>
/// <remarks>
/// Standard values: Order, Invoice, Credit Memo, Return Order.
/// Extensible via enum extensions for custom purchase document types in intercompany scenarios.
/// </remarks>
#pragma warning disable AL0659
enum 429 "IC Outbox Purchase Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Purchase order document for intercompany procurement and vendor order processing.
    /// </summary>
    value(0; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Purchase invoice document for intercompany vendor billing and expense recognition.
    /// </summary>
    value(1; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Purchase credit memo document for intercompany vendor billing corrections and return processing.
    /// </summary>
    value(2; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Purchase return order document for intercompany goods return and vendor reversal processing.
    /// </summary>
    value(3; "Return Order") { Caption = 'Return Order'; }
}
