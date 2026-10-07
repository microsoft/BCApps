// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

pageextension 6474 "Serv. ItemAvailbyLocationLines" extends "Item Avail. by Location Lines"
{
    layout
    {
        addafter("Item.""Qty. on Sales Order""")
        {
#pragma warning disable AA0100
            field("Item.""Qty. on Service Order"""; Item."Qty. on Service Order")
#pragma warning restore AA0100
            {
                ApplicationArea = Service;
                Caption = 'Qty. on Service Order';
                DecimalPlaces = 0 : 5;
                ToolTip = 'Specifies how many units of the item are allocated to service orders, meaning listed on outstanding service order lines.';
                Visible = false;

                trigger OnDrillDown()
                var
                    ServAvailabilityMgt: Codeunit Microsoft.Service.Document."Serv. Availability Mgt.";
                begin
                    SetItemFilter();
                    ServAvailabilityMgt.ShowServiceLines(Item);
                end;
            }
        }
    }
}
