// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the primary sales document types used throughout the sales process.
/// </summary>
enum 36 "Sales Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies a sales quote document used for preliminary offers to customers.
    /// </summary>
    value(0; "Quote") { Caption = 'Quote'; }
    /// <summary>
    /// Specifies a sales order document that confirms a sale to a customer.
    /// </summary>
    value(1; "Order") { Caption = 'Order'; }
    /// <summary>
    /// Specifies a sales invoice document used to bill customers for goods or services.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Specifies a sales credit memo document used to credit customers for returned goods or corrections.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Specifies a blanket sales order document used for framework agreements with recurring deliveries.
    /// </summary>
    value(4; "Blanket Order") { Caption = 'Blanket Order'; }
    /// <summary>
    /// Specifies a sales return order document used to process goods returned by customers.
    /// </summary>
    value(5; "Return Order") { Caption = 'Return Order'; }
}
