// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Reports;

pageextension 99000770 "Mfg. Warehouse Manager RC" extends "Warehouse Manager Role Center"
{
    actions
    {
        addafter("Transfer Orders")
        {
            action("Released Prod. Orders")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Prod. Orders';
                RunObject = page "Released Production Orders";
            }
        }
        addafter("Shipments")
        {
            action("Released Prod. Orders1")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Released Prod. Orders';
                RunObject = page "Released Production Orders";
            }
        }
        addafter("Whse. Shipment Status")
        {
            action("Prod. Order - Mat. Requisition")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. Order - Mat. Requisition';
                RunObject = report "Prod. Order - Mat. Requisition";
            }
            action("Prod. Order - Picking List")
            {
                ApplicationArea = Warehouse, Manufacturing;
                Caption = 'Prod. Order Picking List';
                RunObject = report "Prod. Order - Picking List";
            }
            action("Subcontractor - Dispatch List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontractor Dispatch List';
                RunObject = report "Subcontractor - Dispatch List";
            }
        }
        addafter("Whse. Shipment Status1")
        {
            action("Prod. Order - Picking List1")
            {
                ApplicationArea = Warehouse, Manufacturing;
                Caption = 'Prod. Order Picking List';
                RunObject = report "Prod. Order - Picking List";
            }
        }
    }
}