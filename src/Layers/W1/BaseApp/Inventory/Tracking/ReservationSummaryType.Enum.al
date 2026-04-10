// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

enum 338 "Reservation Summary Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(1; "Item Ledger Entry") { Caption = 'Item Ledger Entry'; }
    value(11; "Purchase Quote") { Caption = 'Purchase Quote'; }
    value(12; "Purchase Order") { Caption = 'Purchase Order'; }
    value(16; "Purchase Return Order") { Caption = 'Purchase Return Order'; }
    value(21; "Requisition Line") { Caption = 'Requisition Line'; }
    value(31; "Sales Quote") { Caption = 'Sales Quote'; }
    value(32; "Sales Order") { Caption = 'Sales Order'; }
    value(36; "Sales Return Order") { Caption = 'Sales Return Order'; }
    value(41; "Item Journal Purchase") { Caption = 'Item Journal Purchase'; }
    value(51; "Job Journal Usage") { Caption = 'Project Journal Usage'; }
    value(61; "Simulated Production Order") { Caption = 'Simulated Production Order'; }
    value(62; "Planned Production Order") { Caption = 'Planned Production Order'; }
    value(63; "Firm Planned Production Order") { Caption = 'Firm Planned Production Order'; }
    value(64; "Released Production Order") { Caption = 'Released Production Order'; }
    value(71; "Simulated Prod. Order Comp.") { Caption = 'Simulated Prod. Order Comp.'; }
    value(72; "Planned Prod. Order Comp.") { Caption = 'Planned Prod. Order Comp.'; }
    value(73; "Firm Planned Prod. Order Comp.") { Caption = 'Firm Planned Prod. Order Comp.'; }
    value(74; "Released Prod. Order Comp.") { Caption = 'Released Prod. Order Comp.'; }
    value(101; "Transfer Shipment") { Caption = 'Transfer Shipment'; }
    value(102; "Transfer Receipt") { Caption = 'Transfer Receipt'; }
    value(131; "Job Planning Planned") { Caption = 'Project Planning Planned'; }
    value(132; "Job Planning Quote") { Caption = 'Project Planning Quote'; }
    value(133; "Job Planning Order") { Caption = 'Project Planning Order'; }
    value(141; "Assembly Quote Header") { Caption = 'Assembly Quote Header'; }
    value(142; "Assembly Order Header") { Caption = 'Assembly Order Header'; }
    value(151; "Assembly Quote Line") { Caption = 'Assembly Quote Line'; }
    value(152; "Assembly Order Line") { Caption = 'Assembly Order Line'; }
    value(161; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(162; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(6500; "Item Tracking Line") { Caption = 'Item Tracking Line'; }

}
