// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Item;
using Microsoft.Projects.Project.Planning;

codeunit 5400 "Available Management"
{

    trigger OnRun()
    begin
    end;

    procedure ExpectedQtyOnHand(var Item: Record Item; CalcAvailable: Boolean; ExtraNetNeed: Decimal; var Available: Decimal; PlannedOrderReceiptDate: Date) ExpectedQty: Decimal
    var
        CopyOfItem: Record Item;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcExpectedQtyOnHand(Item, CalcAvailable, ExtraNetNeed, Available, PlannedOrderReceiptDate, ExpectedQty, IsHandled);
        if IsHandled then
            exit(ExpectedQty);

        CopyOfItem.Copy(Item);

        Available := 0;
        if CalcAvailable then
            Available := CalcAvailableQty(Item, true, PlannedOrderReceiptDate) - ExtraNetNeed;
        Item.Copy(CopyOfItem);

        ExpectedQty := CalcAvailableQty(Item, false, 0D) - ExtraNetNeed;

        OnAfterCalcExpectedQty(Item, CalcAvailable, ExtraNetNeed, Available, PlannedOrderReceiptDate, ExpectedQty);

        exit(ExpectedQty);
    end;

    local procedure CalcAvailableQty(var Item: Record Item; CalcAvailable: Boolean; PlannedOrderReceiptDate: Date) AvailableQty: Decimal
    var
        CopyOfItem: Record Item;
        JobPlanningLine: Record "Job Planning Line";
        ScheduledReceiptQty: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailableQty(Item, CalcAvailable, PlannedOrderReceiptDate, AvailableQty, IsHandled);
        if IsHandled then
            exit(AvailableQty);

        CopyOfItem.Copy(Item);
        CopyOfItem.SetRange("Date Filter", 0D, CopyOfItem.GetRangeMax(CopyOfItem."Date Filter"));
        CopyOfItem.CalcFields("Qty. on Purch. Order", "Trans. Ord. Receipt (Qty.)", "Qty. on Sales Return");
        OnCalcAvailableQtyOnAfterCalcFields(CopyOfItem, ScheduledReceiptQty);

        if CopyOfItem.GetFilter("Location Filter") <> '' then
            CopyOfItem.CalcFields("Qty. in Transit");

        if CalcAvailable then
            CopyOfItem.SetRange("Date Filter", 0D, PlannedOrderReceiptDate);
        CopyOfItem.CalcFields(
          "Qty. on Sales Order",
          "Trans. Ord. Shipment (Qty.)",
          "Qty. on Assembly Order",
          "Qty. on Purch. Return");

        if JobPlanningLine.ReadPermission then
            CopyOfItem.CalcFields("Qty. on Job Order");

        AvailableQty :=
          CopyOfItem.Inventory +
          CopyOfItem."Qty. on Purch. Order" -
          CopyOfItem."Qty. on Sales Order" -
          CopyOfItem.CalcQtyOnComponentLines() +
          CopyOfItem.CalcPlannedOrderReceiptQty() +
          ScheduledReceiptQty -
          CopyOfItem."Trans. Ord. Shipment (Qty.)" +
          CopyOfItem."Qty. in Transit" +
          CopyOfItem."Trans. Ord. Receipt (Qty.)" -
          CopyOfItem."Qty. on Job Order" -
          CopyOfItem."Qty. on Purch. Return" +
          CopyOfItem."Qty. on Assembly Order" +
          CopyOfItem."Qty. on Sales Return";

        OnCalcAvailableQtyOnAfterCalculation(CopyOfItem, AvailableQty);

        OnAfterCalcAvailableQty(Item, CalcAvailable, PlannedOrderReceiptDate, AvailableQty);

        exit(AvailableQty);
    end;

    procedure GetItemReorderQty(Item: Record Item; QtyAvailable: Decimal) ReorderQty: Decimal
    begin
        if Item."Reordering Policy" = Item."Reordering Policy"::" " then
            if Item."Maximum Inventory" <= 0 then begin
                if QtyAvailable > 0 then
                    QtyAvailable := 0;
                if Item."Reorder Quantity" > 0 then
                    ReorderQty :=
                      Round((Item."Reorder Point" - QtyAvailable) / Item."Reorder Quantity", 1, '>') *
                      Item."Reorder Quantity"
                else
                    ReorderQty := Item."Reorder Point" - QtyAvailable;
            end
            else
                if (Item."Reorder Point" > Item."Maximum Inventory") or
                   ((QtyAvailable + Item."Reorder Quantity") > Item."Maximum Inventory")
                then
                    ReorderQty := 0
                else
                    if Item."Reorder Quantity" > 0 then
                        ReorderQty :=
                          Round((Item."Maximum Inventory" - QtyAvailable) / Item."Reorder Quantity", 1, '<') *
                          Item."Reorder Quantity"
                    else
                        ReorderQty := Item."Maximum Inventory" - QtyAvailable
        else begin
            if Item."Reorder Point" > Item."Safety Stock Quantity" then begin
                if QtyAvailable > 0 then
                    QtyAvailable := 0;
                ReorderQty := Item."Reorder Point" - QtyAvailable
            end else
                ReorderQty := -QtyAvailable;

            if ReorderQty <= 0 then
                exit(0);

            ReorderQty := CalcReorderQty(Item, ReorderQty, QtyAvailable);
            ReorderQty += AdjustReorderQty(ReorderQty, Item);
        end;
    end;

    local procedure AdjustReorderQty(OrderQty: Decimal; Item: Record Item): Decimal
    var
        DeltaQty: Decimal;
        Rounding: Decimal;
    begin
        // Copy of AdjustReorderQty in COD 99000854 - Inventory Profile Offsetting
        // excluding logging surplus & MinQty check
        if OrderQty <= 0 then
            exit(0);

        if (Item."Maximum Order Quantity" < OrderQty) and
           (Item."Maximum Order Quantity" <> 0)
        // AND  (SKU."Maximum Order Quantity" > MinQty)
        then
            DeltaQty := Item."Maximum Order Quantity" - OrderQty
        else
            DeltaQty := 0;
        if Item."Minimum Order Quantity" > (OrderQty + DeltaQty) then
            DeltaQty := Item."Minimum Order Quantity" - OrderQty;

        if Item."Order Multiple" <> 0 then begin
            Rounding := Round(OrderQty + DeltaQty, Item."Order Multiple", '>') - (OrderQty + DeltaQty);
            DeltaQty += Rounding;
        end;
        exit(DeltaQty);
    end;

    local procedure CalcReorderQty(Item: Record Item; NeededQty: Decimal; ProjectedInventory: Decimal) QtyToOrder: Decimal
    begin
        // Copy of CalcReorderQty in COD 99000854 - Inventory Profile Offsetting
        // excluding logging surplus, resiliency errors and comments
        case Item."Reordering Policy" of
            Item."Reordering Policy"::"Maximum Qty.":
                if Item."Maximum Inventory" < Item."Reorder Point" then
                    QtyToOrder := Item."Reorder Point" - ProjectedInventory
                else
                    QtyToOrder := Item."Maximum Inventory" - ProjectedInventory;
            Item."Reordering Policy"::"Fixed Reorder Qty.":
                begin
                    Item.TestField("Reorder Quantity"); // Assertion
                    QtyToOrder := Item."Reorder Quantity";
                end;
            else
                QtyToOrder := NeededQty;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcAvailableQty(var Item: Record Item; CalcAvailable: Boolean; PlannedOrderReceiptDate: Date; var AvailableQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcExpectedQty(var Item: Record Item; CalcAvailable: Boolean; ExtraNetNeed: Decimal; var Available: Decimal; PlannedOrderReceiptDate: Date; var ExpectedQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcExpectedQtyOnHand(var Item: Record Item; CalcAvailable: Boolean; ExtraNetNeed: Decimal; var Available: Decimal; PlannedOrderReceiptDate: Date; var ExpectedQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    procedure OnBeforeCalcAvailableQty(var Item: Record Item; CalcAvailable: Boolean; PlannedOrderReceiptDate: Date; var AvailableQty: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableQtyOnAfterCalculation(var CopyOfItem: Record Item; var AvailableQty: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableQtyOnAfterCalcFields(var CopyOfItem: Record Item; var ScheduledReceiptQty: Decimal)
    begin
    end;
}

