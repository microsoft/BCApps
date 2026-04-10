// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the document types that item charges can be applied to in sales transactions.
/// </summary>
enum 5809 "Sales Applies-to Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies a sales quote document for applying item charges.
    /// </summary>
    value(0; "Quote") { Caption = 'Quote'; }
    /// <summary>
    /// Specifies a sales order document for applying item charges.
    /// </summary>
    value(1; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Specifies a sales invoice document for applying item charges.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Specifies a sales credit memo document for applying item charges.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Specifies a blanket sales order document for applying item charges.
    /// </summary>
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
    /// <summary>
    /// Specifies a sales return order document for applying item charges.
    /// </summary>
    value(5; "Return Order") { Caption = 'Return Order'; }
    /// <summary>
    /// Specifies a posted sales shipment document for applying item charges.
    /// </summary>
    value(6; "Shipment") { Caption = 'Shipment'; }
    /// <summary>
    /// Specifies a posted sales return receipt document for applying item charges.
    /// </summary>
    value(7; "Return Receipt") { Caption = 'Return Receipt'; }
}
