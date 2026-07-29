// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Inventory.Transfer;

pageextension 11389 "Warehouse Manager RC NL" extends "Warehouse Manager Role Center"
{
    actions
    {
        addafter("Whse. - Shipment")
        {
            action("CMR - Transfer Shipment")
            {
                ApplicationArea = Warehouse;
                Caption = 'CMR - Transfer Shipment';
                RunObject = report "CMR - Transfer Shipment";
                ToolTip = 'Run the CMR - Transfer Shipment report to print the CMR for transfer shipments.';
            }
        }
    }
}