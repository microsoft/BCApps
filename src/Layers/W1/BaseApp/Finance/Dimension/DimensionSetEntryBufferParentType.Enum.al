// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Dimension;

#pragma warning disable AL0659
/// <summary>
/// Defines the types of parent records that can have associated dimension set entry buffers.
/// Used to identify the source document or transaction type when working with temporary dimension data.
/// </summary>
/// <remarks>
/// Enables dimension buffer management across multiple business document types and ledger entries.
/// Supports sales, purchase, journal, and posted document dimension tracking in temporary buffer scenarios.
/// Extensible for custom document types requiring dimension buffer functionality.
/// </remarks>
enum 136 "Dimension Set Entry Buffer Parent Type"
#pragma warning restore AL0659
{
    Extensible = true;

    /// <summary>
    /// No parent record type specified.
    /// </summary>
    value(0; " ") { Caption = ' '; }
    /// <summary>
    /// Journal line document type for general journal entries.
    /// </summary>
    value(1; "Journal Line") { Caption = 'Journal Line'; }
    /// <summary>
    /// Sales order header document type for sales order processing.
    /// </summary>
    value(2; "Sales Order") { Caption = 'Sales Order'; }
    /// <summary>
    /// Sales order line document type for individual sales order line items.
    /// </summary>
    value(3; "Sales Order Line") { Caption = 'Sales Order Line'; }
    /// <summary>
    /// Sales quote header document type for sales quotation processing.
    /// </summary>
    value(4; "Sales Quote") { Caption = 'Sales Quote'; }
    /// <summary>
    /// Sales quote line document type for individual sales quote line items.
    /// </summary>
    value(5; "Sales Quote Line") { Caption = 'Sales Quote Line'; }
    /// <summary>
    /// Sales credit memo header document type for sales credit processing.
    /// </summary>
    value(6; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    /// <summary>
    /// Sales credit memo line document type for individual credit memo line items.
    /// </summary>
    value(7; "Sales Credit Memo Line") { Caption = 'Sales Credit Memo Line'; }
    /// <summary>
    /// Sales invoice header document type for sales invoice processing.
    /// </summary>
    value(8; "Sales Invoice") { Caption = 'Sales Invoice'; }
    /// <summary>
    /// Sales invoice line document type for individual sales invoice line items.
    /// </summary>
    value(9; "Sales Invoice Line") { Caption = 'Sales Invoice Line'; }
    /// <summary>
    /// Purchase invoice header document type for purchase invoice processing.
    /// </summary>
    value(10; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    /// <summary>
    /// Purchase invoice line document type for individual purchase invoice line items.
    /// </summary>
    value(11; "Purchase Invoice Line") { Caption = 'Purchase Invoice Line'; }
    /// <summary>
    /// General ledger entry type for posted financial transactions.
    /// </summary>
    value(12; "General Ledger Entry") { Caption = 'General Ledger Entry'; }
    /// <summary>
    /// Time registration entry type for time tracking and resource management.
    /// </summary>
    value(13; "Time Registration Entry") { Caption = 'Time Registration Entry'; }
    /// <summary>
    /// Sales shipment header document type for posted sales shipments.
    /// </summary>
    value(14; "Sales Shipment") { Caption = 'Sales Shipment'; }
    /// <summary>
    /// Sales shipment line document type for individual posted sales shipment line items.
    /// </summary>
    value(15; "Sales Shipment Line") { Caption = 'Sales Shipment Line'; }
    /// <summary>
    /// Purchase receipt header document type for posted purchase receipts.
    /// </summary>
    value(16; "Purchase Receipt") { Caption = 'Purchase Receipt'; }
    /// <summary>
    /// Purchase receipt line document type for individual posted purchase receipt line items.
    /// </summary>
    value(17; "Purchase Receipt Line") { Caption = 'Purchase Receipt Line'; }
    /// <summary>
    /// Purchase order header document type for purchase order processing.
    /// </summary>
    value(18; "Purchase Order") { Caption = 'Purchase Order'; }
    /// <summary>
    /// Purchase order line document type for individual purchase order line items.
    /// </summary>
    value(19; "Purchase Order Line") { Caption = 'Purchase Order Line'; }
    /// <summary>
    /// Purchase credit memo header document type for purchase credit processing.
    /// </summary>
    value(20; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    /// <summary>
    /// Purchase credit memo line document type for individual purchase credit memo line items.
    /// </summary>
    value(21; "Purchase Credit Memo Line") { Caption = 'Purchase Credit Memo Line'; }
}
