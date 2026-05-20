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
    /// <summary>
    /// Sales return order header document type for sales return order processing.
    /// </summary>
    value(22; "Sales Return Order") { Caption = 'Sales Return Order'; }
    /// <summary>
    /// Sales return order line document type for individual sales return order line items.
    /// </summary>
    value(23; "Sales Return Order Line") { Caption = 'Sales Return Order Line'; }
    /// <summary>
    /// Blanket purchase order header document type for blanket purchase order processing.
    /// </summary>
    value(24; "Blanket Purchase Order") { Caption = 'Blanket Purchase Order'; }
    /// <summary>
    /// Blanket purchase order line document type for individual blanket purchase order line items.
    /// </summary>
    value(25; "Blanket Purchase Order Line") { Caption = 'Blanket Purchase Order Line'; }
    /// <summary>
    /// Blanket sales order header document type for blanket sales order processing.
    /// </summary>
    value(26; "Blanket Sales Order") { Caption = 'Blanket Sales Order'; }
    /// <summary>
    /// Blanket sales order line document type for individual blanket sales order line items.
    /// </summary>
    value(27; "Blanket Sales Order Line") { Caption = 'Blanket Sales Order Line'; }
    /// <summary>
    /// Transfer order header document type for transfer order processing.
    /// </summary>
    value(28; "Transfer Order") { Caption = 'Transfer Order'; }
    /// <summary>
    /// Transfer order line document type for individual transfer order line items.
    /// </summary>
    value(29; "Transfer Order Line") { Caption = 'Transfer Order Line'; }
    /// <summary>
    /// Transfer shipment header document type for posted transfer shipment processing.
    /// </summary>
    value(30; "Transfer Shipment") { Caption = 'Transfer Shipment'; }
    /// <summary>
    /// Transfer shipment line document type for individual posted transfer shipment line items.
    /// </summary>
    value(31; "Transfer Shipment Line") { Caption = 'Transfer Shipment Line'; }
    /// <summary>
    /// Transfer receipt header document type for posted transfer receipt processing.
    /// </summary>
    value(32; "Transfer Receipt") { Caption = 'Transfer Receipt'; }
    /// <summary>
    /// Transfer receipt line document type for individual posted transfer receipt line items.
    /// </summary>
    value(33; "Transfer Receipt Line") { Caption = 'Transfer Receipt Line'; }
    /// <summary>
    /// Posted direct transfer header document type for posted direct transfer processing.
    /// </summary>
    value(34; "Posted Direct Transfer") { Caption = 'Posted Direct Transfer'; }
    /// <summary>
    /// Posted direct transfer line document type for individual posted direct transfer line items.
    /// </summary>
    value(35; "Posted Direct Transfer Line") { Caption = 'Posted Direct Transfer Line'; }
    /// <summary>
    /// Sales quote archive header document type for archived sales quote processing.
    /// </summary>
    value(36; "Sales Quote Archive") { Caption = 'Sales Quote Archive'; }
    /// <summary>
    /// Sales quote archive line document type for individual archived sales quote line items.
    /// </summary>
    value(37; "Sales Quote Archive Line") { Caption = 'Sales Quote Archive Line'; }
    /// <summary>
    /// Sales order archive header document type for archived sales order processing.
    /// </summary>
    value(38; "Sales Order Archive") { Caption = 'Sales Order Archive'; }
    /// <summary>
    /// Sales order archive line document type for individual archived sales order line items.
    /// </summary>
    value(39; "Sales Order Archive Line") { Caption = 'Sales Order Archive Line'; }
    /// <summary>
    /// Purchase quote archive header document type for archived purchase quote processing.
    /// </summary>
    value(40; "Purchase Quote Archive") { Caption = 'Purchase Quote Archive'; }
    /// <summary>
    /// Purchase quote archive line document type for individual archived purchase quote line items.
    /// </summary>
    value(41; "Purchase Quote Archive Line") { Caption = 'Purchase Quote Archive Line'; }
    /// <summary>
    /// Purchase order archive header document type for archived purchase order processing.
    /// </summary>
    value(42; "Purchase Order Archive") { Caption = 'Purchase Order Archive'; }
    /// <summary>
    /// Purchase order archive line document type for individual archived purchase order line items.
    /// </summary>
    value(43; "Purchase Order Archive Line") { Caption = 'Purchase Order Archive Line'; }
    /// <summary>
    /// Sales return order archive header document type for archived sales return order processing.
    /// </summary>
    value(44; "Sales Return Order Archive") { Caption = 'Sales Return Order Archive'; }
    /// <summary>
    /// Sales return order archive line document type for individual archived sales return order line items.
    /// </summary>
    value(45; "Sales Return Order Archive Line") { Caption = 'Sales Return Order Archive Line'; }
    /// <summary>
    /// Purchase return order archive header document type for archived purchase return order processing.
    /// </summary>
    value(46; "Purchase Return Order Archive") { Caption = 'Purchase Return Order Archive'; }
    /// <summary>
    /// Purchase return order archive line document type for individual archived purchase return order line items.
    /// </summary>
    value(47; "Purchase Return Order Archive Line") { Caption = 'Purchase Return Order Archive Line'; }
    /// <summary>
    /// Assembly order header document type for assembly order processing.
    /// </summary>
    value(48; "Assembly Order") { Caption = 'Assembly Order'; }
    /// <summary>
    /// Assembly order line document type for individual assembly order line items.
    /// </summary>
    value(49; "Assembly Order Line") { Caption = 'Assembly Order Line'; }
    /// <summary>
    /// Posted assembly order header document type for posted assembly order processing.
    /// </summary>
    value(50; "Posted Assembly Order") { Caption = 'Posted Assembly Order'; }
    /// <summary>
    /// Posted assembly order line document type for individual posted assembly order line items.
    /// </summary>
    value(51; "Posted Assembly Order Line") { Caption = 'Posted Assembly Order Line'; }
    /// <summary>
    /// Sales blanket order archive header document type for archived sales blanket order processing.
    /// </summary>
    value(52; "Sales Blanket Order Archive") { Caption = 'Sales Blanket Order Archive'; }
    /// <summary>
    /// Sales blanket order archive line document type for individual archived sales blanket order line items.
    /// </summary>
    value(53; "Sales Blanket Order Archive Line") { Caption = 'Sales Blanket Order Archive Line'; }
    /// <summary>
    /// Purchase blanket order archive header document type for archived purchase blanket order processing.
    /// </summary>
    value(54; "Purchase Blanket Order Archive") { Caption = 'Purchase Blanket Order Archive'; }
    /// <summary>
    /// Purchase blanket order archive line document type for individual archived purchase blanket order line items.
    /// </summary>
    value(55; "Purchase Blanket Order Archive Line") { Caption = 'Purchase Blanket Order Archive Line'; }
    /// <summary>
    /// Physical inventory order header document type for physical inventory order processing.
    /// </summary>
    value(56; "Physical Inventory Order") { Caption = 'Physical Inventory Order'; }
    /// <summary>
    /// Physical inventory order line document type for individual physical inventory order line items.
    /// </summary>
    value(57; "Physical Inventory Order Line") { Caption = 'Physical Inventory Order Line'; }
    /// <summary>
    /// Posted physical inventory order header document type for posted physical inventory order processing.
    /// </summary>
    value(58; "Posted Physical Inventory Order") { Caption = 'Posted Physical Inventory Order'; }
    /// <summary>
    /// Posted physical inventory order line document type for individual posted physical inventory order line items.
    /// </summary>
    value(59; "Posted Physical Inventory Order Line") { Caption = 'Posted Physical Inventory Order Line'; }
    /// <summary>
    /// Inventory shipment header document type for inventory shipment processing.
    /// </summary>
    value(60; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    /// <summary>
    /// Inventory shipment line document type for individual inventory shipment line items.
    /// </summary>
    value(61; "Inventory Shipment Line") { Caption = 'Inventory Shipment Line'; }
    /// <summary>
    /// Inventory receipt header document type for inventory receipt processing.
    /// </summary>
    value(62; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    /// <summary>
    /// Inventory receipt line document type for individual inventory receipt line items.
    /// </summary>
    value(63; "Inventory Receipt Line") { Caption = 'Inventory Receipt Line'; }
    /// <summary>
    /// Posted inventory shipment header document type for posted inventory shipment processing.
    /// </summary>
    value(64; "Posted Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
    /// <summary>
    /// Posted inventory shipment line document type for individual posted inventory shipment line items.
    /// </summary>
    value(65; "Posted Inventory Shipment Line") { Caption = 'Posted Inventory Shipment Line'; }
    /// <summary>
    /// Posted inventory receipt header document type for posted inventory receipt processing.
    /// </summary>
    value(66; "Posted Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    /// <summary>
    /// Posted inventory receipt line document type for individual posted inventory receipt line items.
    /// </summary>
    value(67; "Posted Inventory Receipt Line") { Caption = 'Posted Inventory Receipt Line'; }
    /// <summary>
    /// Purchase return order header document type for purchase return order processing.
    /// </summary>
    value(68; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    /// <summary>
    /// Purchase return order line document type for individual purchase return order line items.
    /// </summary>
    value(69; "Purchase Return Order Line") { Caption = 'Purchase Return Order Line'; }
    /// <summary>
    /// Purchase quote header document type for purchase quote processing.
    /// </summary>
    value(70; "Purchase Quote") { Caption = 'Purchase Quote'; }
    /// <summary>
    /// Purchase quote line document type for individual purchase quote line items.
    /// </summary>
    value(71; "Purchase Quote Line") { Caption = 'Purchase Quote Line'; }
}
