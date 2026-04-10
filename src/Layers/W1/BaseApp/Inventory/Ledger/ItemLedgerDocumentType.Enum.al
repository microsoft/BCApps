// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

enum 79 "Item Ledger Document Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { }
    value(1; "Sales Shipment") { Caption = 'Sales Shipment'; }
    value(2; "Sales Invoice") { Caption = 'Sales Invoice'; }
    value(3; "Sales Return Receipt") { Caption = 'Sales Return Receipt'; }
    value(4; "Sales Credit Memo") { Caption = 'Sales Credit Memo'; }
    value(5; "Purchase Receipt") { Caption = 'Purchase Receipt'; }
    value(6; "Purchase Invoice") { Caption = 'Purchase Invoice'; }
    value(7; "Purchase Return Shipment") { Caption = 'Purchase Return Shipment'; }
    value(8; "Purchase Credit Memo") { Caption = 'Purchase Credit Memo'; }
    value(9; "Transfer Shipment") { Caption = 'Transfer Shipment'; }
    value(10; "Transfer Receipt") { Caption = 'Transfer Receipt'; }
    value(11; "Service Shipment") { Caption = 'Service Shipment'; }
    value(12; "Service Invoice") { Caption = 'Service Invoice'; }
    value(13; "Service Credit Memo") { Caption = 'Service Credit Memo'; }
    value(14; "Posted Assembly") { Caption = 'Posted Assembly'; }
    value(19; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(20; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(21; "Direct Transfer") { Caption = 'Direct Transfer'; }
}
