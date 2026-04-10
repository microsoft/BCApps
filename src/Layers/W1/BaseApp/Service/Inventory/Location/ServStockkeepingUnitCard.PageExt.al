// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Location;

pageextension 6454 "Serv. Stockkeeping Unit Card" extends "Stockkeeping Unit Card"
{
    layout
    {
        addafter("Qty. on Sales Order")
        {
            field("Qty. on Service Order"; Rec."Qty. on Service Order")
            {
                ApplicationArea = Service;
                ToolTip = 'Specifies how many item units are reserved for service orders, which is how many units are listed on outstanding service order lines.';
            }
        }
    }
}
