// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

codeunit 99000757 "Update Prod. Order Cost"
{

    trigger OnRun()
    begin
    end;

    var
        ProdOrderComp: Record "Prod. Order Component";

    procedure ModifySourceLineCost(ReservEntry: Record "Reservation Entry"; UnitCost: Decimal)
    begin
        if UnitCost = 0 then
            exit;

        if not ReservEntry.Get(ReservEntry."Entry No.", not ReservEntry.Positive) then
            exit;

        ReservEntry.UpdateSourceCost(UnitCost);
    end;

    local procedure SumTrackingCosts(var ReservEntry: Record "Reservation Entry"; var TotalUnitCost: Decimal; var TotalCostQty: Decimal; Item: Record Item)
    begin
        TotalUnitCost := 0;
        TotalCostQty := 0;

        repeat
            ProdOrderComp.Get(
              ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.");
            if ProdOrderComp."Qty. per Unit of Measure" <> 0 then
                TotalUnitCost += Item."Unit Cost" * ReservEntry.Quantity;
            TotalCostQty += ReservEntry.Quantity;
        until ReservEntry.Next() = 0;
    end;

    procedure UpdateUnitCostOnProdOrder(var ProdOrderLine: Record "Prod. Order Line"; MultipleLevels: Boolean; UpdateReservation: Boolean)
    var
        Item: Record Item;
        ProdOrderComp: Record "Prod. Order Component";
        ReservEntry: Record "Reservation Entry";
        TotalCostQty: Decimal;
        TotalUnitCost: Decimal;
        UnitCost: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateUnitCostOnProdOrder(ProdOrderLine, MultipleLevels, UpdateReservation, IsHandled);
        if IsHandled then
            exit;

        if not Item.Get(ProdOrderLine."Item No.") then
            exit;

        if Item."Costing Method".AsInteger() > Item."Costing Method"::Average.AsInteger() then
            exit;

        ProdOrderComp.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComp.SetRange("Prod. Order Line No.", ProdOrderLine."Line No.");

        if ProdOrderComp.Find('-') then
            repeat
                TotalCostQty := 0;
                TotalUnitCost := 0;
                Item.Get(ProdOrderComp."Item No.");
                OnUpdateUnitCostOnProdOrderOnAfterGetProdOrderCompItem(ProdOrderLine, ProdOrderComp, Item);
                if Item."Costing Method".AsInteger() <= Item."Costing Method"::Average.AsInteger() then begin
                    ReservEntry."Source Type" := Database::"Prod. Order Component";
                    ReservEntry.InitSortingAndFilters(true);
                    ProdOrderComp.SetReservationFilters(ReservEntry);
                    if ReservEntry.Find('-') then
                        SumTrackingCosts(ReservEntry, TotalUnitCost, TotalCostQty, Item);
                    ProdOrderComp.CalcFields("Reserved Qty. (Base)");
                    UpdateTotalUnitCostOnProdOrder(ProdOrderComp, Item, TotalUnitCost);
                    TotalCostQty :=
                      TotalCostQty +
                      (ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)");
                    if TotalCostQty <> 0 then begin
                        UnitCost := TotalUnitCost / TotalCostQty * ProdOrderComp."Qty. per Unit of Measure";
                        if ProdOrderComp."Unit Cost" <> UnitCost then begin
                            ProdOrderComp.Validate("Unit Cost", UnitCost);
                            ProdOrderComp.Modify();
                        end;
                    end;
                end;
            until ProdOrderComp.Next() = 0;

        ProdOrderLine.CalcFields(
          "Expected Operation Cost Amt.",
          "Total Exp. Oper. Output (Qty.)",
          "Expected Component Cost Amt.");

        if ProdOrderLine."Total Exp. Oper. Output (Qty.)" <> 0 then
            ProdOrderLine."Expected Operation Cost Amt." :=
              Round(
                ProdOrderLine."Expected Operation Cost Amt." /
                ProdOrderLine."Total Exp. Oper. Output (Qty.)" *
                ProdOrderLine.Quantity);

        OnUpdateUnitCostOnProdOrderOnBeforeValidateUnitCost(ProdOrderLine);
        ProdOrderLine.Validate(
          "Unit Cost",
          (ProdOrderLine."Expected Operation Cost Amt." + ProdOrderLine."Expected Component Cost Amt.") / ProdOrderLine.Quantity);

        OnUpdateUnitCostOnProdOrderOnAfterValidateUnitCost(ProdOrderLine);

        ProdOrderLine.Modify();
        if UpdateReservation then begin
            ReservEntry.Reset();
            ReservEntry."Source Type" := Database::"Prod. Order Line";
            ReservEntry.InitSortingAndFilters(false);
            ProdOrderLine.SetReservationFilters(ReservEntry);
            if ProdOrderLine."Qty. per Unit of Measure" <> 0 then
                UnitCost := Round(ProdOrderLine."Unit Cost" / ProdOrderLine."Qty. per Unit of Measure", 0.00001)
            else
                UnitCost := ProdOrderLine."Unit Cost";
            if ReservEntry.Find('-') then
                repeat
                    ModifySourceLineCost(ReservEntry, UnitCost);
                until ReservEntry.Next() = 0;
        end;
    end;

    local procedure UpdateTotalUnitCostOnProdOrder(var ProdOrderComp: Record "Prod. Order Component"; Item: Record Item; var TotalUnitCost: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateTotalUnitCostOnProdOrder(ProdOrderComp, TotalUnitCost, IsHandled);
        if IsHandled then
            exit;

        TotalUnitCost :=
            TotalUnitCost +
            (Item."Unit Cost" *
            (ProdOrderComp."Expected Qty. (Base)" - ProdOrderComp."Reserved Qty. (Base)"));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateUnitCostOnProdOrder(var ProdOrderLine: Record "Prod. Order Line"; MultipleLevels: Boolean; UpdateReservation: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateTotalUnitCostOnProdOrder(var ProdOrderComp: Record "Prod. Order Component"; var TotalUnitCost: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnProdOrderOnAfterValidateUnitCost(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnProdOrderOnAfterGetProdOrderCompItem(ProdOrderLine: Record "Prod. Order Line"; ProdOrderComp: Record "Prod. Order Component"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateUnitCostOnProdOrderOnBeforeValidateUnitCost(var ProdOrderLine: Record "Prod. Order Line")
    begin
    end;
}

