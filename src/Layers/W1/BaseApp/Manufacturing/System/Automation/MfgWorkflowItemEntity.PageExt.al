namespace System.Automation;

pageextension 99000830 "Mfg. Workflow - Item Entity" extends "Workflow - Item Entity"
{
    layout
    {
        addafter(preventNegativeInventory)
        {
            field(costOfOpenProductionOrders; Rec."Cost of Open Production Orders")
            {
                ApplicationArea = All;
                Caption = 'Cost of Open Production Orders', Locked = true;
            }
        }
        addafter(replenishmentSystem)
        {
            field(scheduledReceiptQty; Rec."Scheduled Receipt (Qty.)")
            {
                ApplicationArea = All;
                Caption = 'Scheduled Receipt (Qty.)', Locked = true;
            }
        }
        addafter(timeBucket)
        {
            field(reservedQtyOnProdOrder; Rec."Reserved Qty. on Prod. Order")
            {
                ApplicationArea = All;
                Caption = 'Reserved Qty. on Prod. Order', Locked = true;
            }
            field(resQtyOnProdOrderComp; Rec."Res. Qty. on Prod. Order Comp.")
            {
                ApplicationArea = All;
                Caption = 'Res. Qty. on Prod. Order Comp.', Locked = true;
            }
        }
        addafter(taxGroupId)
        {
            field(routingNumber; Rec."Routing No.")
            {
                ApplicationArea = All;
                Caption = 'Routing No.', Locked = true;
            }
            field(productionBomNumber; Rec."Production BOM No.")
            {
                ApplicationArea = All;
                Caption = 'Production BOM No.', Locked = true;
            }
        }
        addafter(planningReceiptQty)
        {
            field(plannedOrderReceiptQty; Rec."Planned Order Receipt (Qty.)")
            {
                ApplicationArea = All;
                Caption = 'Planned Order Receipt (Qty.)', Locked = true;
            }
            field(fpOrderReceiptQty; Rec."FP Order Receipt (Qty.)")
            {
                ApplicationArea = All;
                Caption = 'FP Order Receipt (Qty.)', Locked = true;
            }
            field(relOrderReceiptQty; Rec."Rel. Order Receipt (Qty.)")
            {
                ApplicationArea = All;
                Caption = 'Rel. Order Receipt (Qty.)', Locked = true;
            }
        }
        addafter(planningReleaseQty)
        {
            field(plannedOrderReleaseQty; Rec."Planned Order Release (Qty.)")
            {
                ApplicationArea = All;
                Caption = 'Planned Order Release (Qty.)', Locked = true;
            }
        }
        addafter(componentForecast)
        {
            field(qtyOnProdOrder; Rec."Qty. on Prod. Order")
            {
                ApplicationArea = All;
                Caption = 'Qty. on Prod. Order', Locked = true;
            }
            field(qtyOnComponentLines; Rec."Qty. on Component Lines")
            {
                ApplicationArea = All;
                Caption = 'Qty. on Component Lines', Locked = true;
            }
        }
    }
}