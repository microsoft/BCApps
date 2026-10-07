// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

pageextension 99000767 "Mfg. Item Availability Lines" extends "Item Availability Lines"
{
    layout
    {
        addafter(QtyAvailable)
        {
#pragma warning disable AA0100
            field("Item.""Scheduled Receipt (Qty.)"""; Rec."Scheduled Receipt (Qty.)")
#pragma warning restore AA0100
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Scheduled Receipt (Qty.)';
                DecimalPlaces = 0 : 5;
                DrillDown = true;
                ToolTip = 'Specifies how many units of the item are scheduled for production orders. The program automatically calculates and updates the contents of the field, using the Remaining Quantity field on production order lines.';
                Visible = false;

                trigger OnDrillDown()
                var
                    ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
                begin
                    ProdOrderAvailabilityMgt.ShowSchedReceipt(Item);
                end;
            }
#pragma warning disable AA0100
            field("Item.""Scheduled Need (Qty.)"""; Rec."Scheduled Issue (Qty.)")
#pragma warning restore AA0100
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Scheduled Issue (Qty.)';
                DecimalPlaces = 0 : 5;
                DrillDown = true;
                ToolTip = 'Specifies the sum of items from planned production orders.';
                Visible = false;

                trigger OnDrillDown()
                var
                    ProdOrderAvailabilityMgt: Codeunit Microsoft.Manufacturing.Document."Prod. Order Availability Mgt.";
                begin
                    ProdOrderAvailabilityMgt.ShowSchedNeed(Item);
                end;
            }
        }        
    }
}