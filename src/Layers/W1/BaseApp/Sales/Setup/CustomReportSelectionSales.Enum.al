// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Setup;

/// <summary>
/// Defines the sales document types available for customer-specific report selections, including quotes, invoices, credit memos, and shipments.
/// </summary>
enum 9657 "Custom Report Selection Sales"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies a custom report selection for sales quote documents.
    /// </summary>
    value(0; "Quote") { Caption = 'Quote'; }
    /// <summary>
    /// Specifies a custom report selection for sales order confirmation documents.
    /// </summary>
    value(1; "Confirmation Order") { Caption = 'Confirmation Order'; }
    /// <summary>
    /// Specifies a custom report selection for sales invoice documents.
    /// </summary>
    value(2; "Invoice") { Caption = 'Invoice'; }
    /// <summary>
    /// Specifies a custom report selection for sales credit memo documents.
    /// </summary>
    value(3; "Credit Memo") { Caption = 'Credit Memo'; }
    /// <summary>
    /// Specifies a custom report selection for customer statement documents.
    /// </summary>
    value(4; "Customer Statement") { Caption = 'Customer Statement'; }
    /// <summary>
    /// Specifies a custom report selection for project quote documents.
    /// </summary>
    value(5; "Job Quote") { Caption = 'Project Quote'; }
    /// <summary>
    /// Specifies a custom report selection for customer reminder documents.
    /// </summary>
    value(6; "Reminder") { Caption = 'Reminder'; }
    /// <summary>
    /// Specifies a custom report selection for sales shipment documents.
    /// </summary>
    value(7; "Shipment") { Caption = 'Shipment'; }
    /// <summary>
    /// Specifies a custom report selection for pro forma invoice documents.
    /// </summary>
    value(8; "Pro Forma Invoice") { Caption = 'Pro Forma Invoice'; }
}
