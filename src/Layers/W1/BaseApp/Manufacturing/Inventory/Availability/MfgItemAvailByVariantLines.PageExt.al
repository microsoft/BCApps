// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Manufacturing.Document;

pageextension 99000775 "Mfg. ItemAvailByVariantLines" extends "Item Avail. by Variant Lines"
{
    layout
    {
        addafter(QtyAvailable)
        {
#pragma warning disable AA0100
            field("Item.""Scheduled Receipt (Qty.)"""; Item."Scheduled Receipt (Qty.)")
#pragma warning restore AA0100
            {
                ApplicationArea = Planning;
                Caption = 'Scheduled Receipt (Qty.)';
                DecimalPlaces = 0 : 5;
                Editable = false;
                ToolTip = 'Specifies how many units of the item are scheduled for production orders. The program automatically calculates and updates the contents of the field, using the Remaining Quantity field on production order lines.';
                Visible = false;

                trigger OnDrillDown()
                var
                    ProdOrderAvailabilityMgt: Codeunit "Prod. Order Availability Mgt.";
                begin
                    ProdOrderAvailabilityMgt.ShowSchedReceipt(Item);
                end;
            }
#pragma warning disable AA0100
            field("Item.""Scheduled Need (Qty.)"""; Item."Qty. on Component Lines")
#pragma warning restore AA0100
            {
                ApplicationArea = Planning;
                Caption = 'Qty. on Component Lines';
                ToolTip = 'Specifies the sum of items from planned production orders.';
                Visible = false;

                trigger OnDrillDown()
                var
                    ProdOrderAvailabilityMgt: Codeunit "Prod. Order Availability Mgt.";
                begin
                    ProdOrderAvailabilityMgt.ShowSchedNeed(Item);
                end;
            }
        }
    }
}