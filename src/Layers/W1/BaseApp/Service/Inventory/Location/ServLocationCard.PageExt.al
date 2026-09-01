// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

using Microsoft.Service.Resources;

pageextension 6458 "Serv. Location Card" extends "Location Card"
{
    actions
    {
        addafter("Warehouse Employees")
        {
            action("&Resource Locations")
            {
                ApplicationArea = Location;
                Caption = '&Resource Locations';
                Image = Resource;
                RunObject = Page "Resource Locations";
                RunPageLink = "Location Code" = field(Code);
                ToolTip = 'View or edit information about where resources are located. In this window, you can assign resources to locations.';
            }
        }
        addafter("Online Map_Promoted")
        {
            actionref("&Resource Locations_Promoted"; "&Resource Locations")
            {
            }
        }
    }
}
