// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Comment;

/// <summary>
/// Defines the document types that can have sales comments attached.
/// </summary>
enum 44 "Sales Comment Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Indicates that the comment is attached to a sales quote document.
    /// </summary>
    value(0; "Quote") { Caption = 'Quote'; }
    /// <summary>
    /// Indicates that the comment is attached to a sales order document.
    /// </summary>
    value(1; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Indicates that the comment is attached to a sales invoice document.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Indicates that the comment is attached to a sales credit memo document.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Indicates that the comment is attached to a blanket sales order document.
    /// </summary>
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
    /// <summary>
    /// Indicates that the comment is attached to a sales return order document.
    /// </summary>
    value(5; "Return Order") { Caption = 'Return Order'; }
    /// <summary>
    /// Indicates that the comment is attached to a posted sales shipment document.
    /// </summary>
    value(6; "Shipment") { Caption = 'Shipment'; }
    /// <summary>
    /// Indicates that the comment is attached to a posted sales invoice document.
    /// </summary>
    value(7; "Posted Invoice") { Caption = 'Posted Invoice'; }
    /// <summary>
    /// Indicates that the comment is attached to a posted sales credit memo document.
    /// </summary>
    value(8; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }
    /// <summary>
    /// Indicates that the comment is attached to a posted sales return receipt document.
    /// </summary>
    value(9; "Posted Return Receipt") { Caption = 'Posted Return Receipt'; }
}
