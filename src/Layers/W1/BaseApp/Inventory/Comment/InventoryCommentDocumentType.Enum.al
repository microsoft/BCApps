// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Comment;

#pragma warning disable AL0659
enum 5748 "Inventory Comment Document Type"
#pragma warning restore AL0659
{
    Extensible = true;
    AssignmentCompatibility = true;

    value(0; " ") { Caption = ' '; }
    value(1; "Transfer Order") { Caption = 'Transfer Order'; }
    value(2; "Posted Transfer Shipment") { Caption = 'Posted Transfer Shipment'; }
    value(3; "Posted Transfer Receipt") { Caption = 'Posted Transfer Receipt'; }
    value(4; "Inventory Receipt") { Caption = 'Inventory Receipt'; }
    value(5; "Inventory Shipment") { Caption = 'Inventory Shipment'; }
    value(6; "Posted Inventory Receipt") { Caption = 'Posted Inventory Receipt'; }
    value(7; "Posted Inventory Shipment") { Caption = 'Posted Inventory Shipment'; }
    value(8; "Posted Direct Transfer") { Caption = 'Posted Direct Transfer'; }
}
