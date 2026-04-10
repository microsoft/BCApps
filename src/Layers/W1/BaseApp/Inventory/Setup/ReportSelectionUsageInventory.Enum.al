// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Setup;

#pragma warning disable AL0659
enum 5754 "Report Selection Usage Inventory"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; "Transfer Order") { Caption = 'Transfer Order'; }
    value(1; "Transfer Shipment") { Caption = 'Transfer Shipment'; }
    value(2; "Transfer Receipt") { Caption = 'Transfer Receipt'; }
    value(3; "Inventory Period Test") { Caption = 'Inventory Period Test'; }
    value(4; "Assembly Order") { Caption = 'Assembly Order'; }
    value(5; "Posted Assembly Order") { Caption = 'Posted Assembly Order'; }
    value(6; "Phys. Invt. Order Test") { Caption = 'Phys. Invt. Order Test'; }
    value(7; "Phys. Invt. Order") { Caption = 'Phys. Invt. Order'; }
    value(8; "Posted Phys. Invt. Order") { Caption = 'Posted Phys. Invt. Order'; }
    value(9; "Phys. Invt. Recording") { Caption = 'Phys. Invt. Recording'; }
    value(10; "Posted Phys. Invt. Recording") { Caption = 'Posted Phys. Invt. Recording'; }
    value(11; "Direct Transfer") { Caption = 'Direct Transfer'; }
    value(12; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(13; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(14; "Posted Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    value(15; "Posted Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
}
