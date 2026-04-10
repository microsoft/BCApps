// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the source document types available when copying sales documents.
/// </summary>
enum 6236 "Sales Document Type From"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies an unposted sales quote as the source document for copying.
    /// </summary>
    value(0; "Quote") { Caption = 'Quote'; }
    /// <summary>
    /// Specifies an unposted blanket sales order as the source document for copying.
    /// </summary>
    value(1; "Blanket Order") { Caption = 'Blanket Order'; }
    /// <summary>
    /// Specifies an unposted sales order as the source document for copying.
    /// </summary>
    value(2; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Specifies an unposted sales invoice as the source document for copying.
    /// </summary>
    value(3; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Specifies an unposted sales return order as the source document for copying.
    /// </summary>
    value(4; "Return Order") { Caption = 'Return Order'; }
    /// <summary>
    /// Specifies an unposted sales credit memo as the source document for copying.
    /// </summary>
    value(5; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Specifies a posted sales shipment as the source document for copying.
    /// </summary>
    value(6; "Posted Shipment") { Caption = 'Posted Shipment'; }
    /// <summary>
    /// Specifies a posted sales invoice as the source document for copying.
    /// </summary>
    value(7; "Posted Invoice") { Caption = 'Posted Invoice'; }
    /// <summary>
    /// Specifies a posted sales return receipt as the source document for copying.
    /// </summary>
    value(8; "Posted Return Receipt") { Caption = 'Posted Return Receipt'; }
    /// <summary>
    /// Specifies a posted sales credit memo as the source document for copying.
    /// </summary>
    value(9; "Posted Credit Memo") { Caption = 'Posted Credit Memo'; }
    /// <summary>
    /// Specifies an archived sales quote as the source document for copying.
    /// </summary>
    value(10; "Arch. Quote") { Caption = 'Arch. Quote'; }
    /// <summary>
    /// Specifies an archived sales order as the source document for copying.
    /// </summary>
    value(11; "Arch. Order") { Caption = 'Arch. Order'; }
    /// <summary>
    /// Specifies an archived blanket sales order as the source document for copying.
    /// </summary>
    value(12; "Arch. Blanket Order") { Caption = 'Arch. Blanket Order'; }
    /// <summary>
    /// Specifies an archived sales return order as the source document for copying.
    /// </summary>
    value(13; "Arch. Return Order") { Caption = 'Arch. Return Order'; }
}
