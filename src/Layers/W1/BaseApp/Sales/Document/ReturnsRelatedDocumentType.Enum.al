// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

/// <summary>
/// Defines the types of documents that can be linked to return orders.
/// </summary>
enum 6670 "Returns Related Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies a sales order document as the related document type.
    /// </summary>
    value(0; "Sales Order") { Caption = 'Sales Order'; }
    /// <summary>
    /// Specifies a sales invoice document as the related document type.
    /// </summary>
    value(1; "Sales Invoice") { Caption = 'Sales Invoice'; }
    /// <summary>
    /// Specifies a sales return order document as the related document type.
    /// </summary>
    value(2; "Sales Return Order") { Caption = 'Sales Return Order'; }
    /// <summary>
    /// Specifies a sales credit memo document as the related document type.
    /// </summary>
    value(3; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    /// <summary>
    /// Specifies a purchase order document as the related document type.
    /// </summary>
    value(4; "Purchase Order") { Caption = 'Purchase Order'; }
    /// <summary>
    /// Specifies a purchase invoice document as the related document type.
    /// </summary>
    value(5; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    /// <summary>
    /// Specifies a purchase return order document as the related document type.
    /// </summary>
    value(6; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    /// <summary>
    /// Specifies a purchase credit memo document as the related document type.
    /// </summary>
    value(7; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
}
