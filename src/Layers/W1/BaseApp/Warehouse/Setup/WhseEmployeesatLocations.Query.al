// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Setup;

using Microsoft.Inventory.Location;

query 7301 "Whse. Employees at Locations"
{
    Caption = 'Whse. Employees at Locations';

    elements
    {
        dataitem(Location; Location)
        {
            column("Code"; "Code")
            {
            }
            column(Bin_Mandatory; "Bin Mandatory")
            {
            }
            column(Directed_Put_away_and_Pick; "Directed Put-away and Pick")
            {
            }
            dataitem(Warehouse_Employee; "Warehouse Employee")
            {
                DataItemLink = "Location Code" = Location.Code;
                column(User_ID; "User ID")
                {
                }
                column(Default; Default)
                {
                }
            }
        }
    }
}

