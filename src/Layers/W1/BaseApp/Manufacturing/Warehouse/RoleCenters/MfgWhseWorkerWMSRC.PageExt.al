// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.RoleCenters;

using Microsoft.Manufacturing.Reports;

pageextension 99000773 "Mfg. Whse. Worker WMS RC" extends "Whse. Worker WMS Role Center"
{
    actions
    {
        addafter("Whse. P&hys. Inventory List")
        {
            action("Prod. &Order Picking List")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Prod. &Order Picking List';
                Image = "Report";
                RunObject = Report "Prod. Order - Picking List";
                ToolTip = 'View a detailed list of items that must be picked for a particular production order, from which location (and bin, if the location uses bins) they must be picked, and when the items are due for production.';
            }
        }
    }
}
