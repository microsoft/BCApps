// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Tracking;

codeunit 7171 "Sales Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";

    procedure CalcAvailability(var SalesLine: Record "Sales Line"): Decimal
    var
        LookaheadDateformula: DateFormula;
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailableQuantity: Decimal;
        PeriodType: Enum "Analysis Period Type";
        IsHandled: Boolean;
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            IsHandled := false;
            OnBeforeCalcAvailability(Item, SalesLine, AvailableQuantity, IsHandled);
            if IsHandled then
                exit(AvailableQuantity);

            Evaluate(LookaheadDateformula, '<0D>');
            exit(
              ConvertQty(
                AvailableToPromise.CalcQtyAvailabletoPromise(
                  Item,
                  GrossRequirement,
                  ScheduledReceipt,
                  CalcAvailabilityDate(SalesLine),
                  PeriodType,
                  LookaheadDateformula),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcAvailabilityDate(var SalesLine: Record "Sales Line") AvailabilityDate: Date
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcAvailabilityDate(SalesLine, AvailabilityDate, IsHandled);
        if IsHandled then
            exit(AvailabilityDate);

        if SalesLine."Shipment Date" <> 0D then
            exit(SalesLine."Shipment Date");

        exit(WorkDate());
    end;

    procedure CalcAvailableInventory(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            OnCalcAvailableInventoryOnAfterSetItemFilter(Item);

            exit(
              ConvertQty(
                AvailableToPromise.CalcAvailableInventory(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcScheduledReceipt(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            OnCalcScheduledReceiptOnAfterSetItemFilter(Item);

            exit(
              ConvertQty(
                AvailableToPromise.CalcScheduledReceipt(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcGrossRequirements(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            OnCalcGrossRequirementsOnAfterSetItemFilter(Item);

            exit(
              ConvertQty(
                AvailableToPromise.CalcGrossRequirement(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcReservedRequirements(var SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            OnCalcReservedRequirementsOnAfterSetItemFilter(Item);

            exit(
              ConvertQty(
                AvailableToPromise.CalcReservedReceipt(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure CalcReservedDemand(SalesLine: Record "Sales Line"): Decimal
    begin
        if GetItem(SalesLine) then begin
            SetItemFilter(Item, SalesLine);
            OnCalcReservedDemandOnAfterSetItemFilter(Item);

            exit(
              ConvertQty(
                AvailableToPromise.CalcReservedRequirement(Item),
                SalesLine."Qty. per Unit of Measure"));
        end;
    end;

    procedure GetQtyReservedFromStockState(SalesLine: Record "Sales Line") Result: Enum "Reservation From Stock"
    var
        SalesLineReserve: Codeunit "Sales Line-Reserve";
        QtyReservedFromStock: Decimal;
    begin
        if not GetItem(SalesLine) then
            exit(Result::None);

        if Item.IsNonInventoriableType() then
            exit(Result::None);

        QtyReservedFromStock := SalesLineReserve.GetReservedQtyFromInventory(SalesLine);
        case QtyReservedFromStock of
            0:
                exit(Result::None);
            SalesLine."Outstanding Qty. (Base)":
                exit(Result::Full);
            else
                exit(Result::Partial);
        end;
    end;

    procedure CalcNoOfSubstitutions(var SalesLine: Record "Sales Line"): Integer
    begin
        if GetItem(SalesLine) then begin
            Item.CalcFields("No. of Substitutes");
            exit(Item."No. of Substitutes");
        end;
    end;

    procedure CalcNoOfSalesPrices(var SalesLine: Record "Sales Line"): Integer
    begin
        exit(SalesLine.CountPrice(true));
    end;

    procedure CalcNoOfSalesLineDisc(var SalesLine: Record "Sales Line"): Integer
    begin
        exit(SalesLine.CountDiscount(true));
    end;

    local procedure ConvertQty(Qty: Decimal; PerUoMQty: Decimal) Result: Decimal
    begin
        if PerUoMQty = 0 then
            PerUoMQty := 1;
        Result := Round(Qty / PerUoMQty, UOMMgt.QtyRndPrecision());
        OnAfterConvertQty(Qty, PerUoMQty, Result);
    end;

    procedure LookupItem(var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeLookupItem(SalesLine, Item, IsHandled);
        if IsHandled then
            exit;

        SalesLine.TestField(Type, SalesLine.Type::Item);
        SalesLine.TestField("No.");
        GetItem(SalesLine);
        PAGE.RunModal(PAGE::"Item Card", Item);
    end;

    procedure ResetItemNo()
    begin
        AvailableToPromise.ResetItemNo();
    end;

    procedure GetItem(var SalesLine: Record "Sales Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItem(SalesLine, Item, IsHandled, Result);
        if IsHandled then
            exit(Result);

        if (SalesLine.Type <> SalesLine.Type::Item) or (SalesLine."No." = '') then
            exit(false);

        if SalesLine."No." <> Item."No." then
            Item.Get(SalesLine."No.");

        exit(true);
    end;

    local procedure SetItemFilter(var Item: Record Item; var SalesLine: Record "Sales Line")
    begin
        Item.Reset();
        Item.SetRange("Date Filter", 0D, CalcAvailabilityDate(SalesLine));
        Item.SetRange("Variant Filter", SalesLine."Variant Code");
        Item.SetRange("Location Filter", SalesLine."Location Code");
        Item.SetRange("Drop Shipment Filter", SalesLine."Drop Shipment");
        OnAfterSetItemFilter(Item, SalesLine);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterConvertQty(Qty: Decimal; PerUoMQty: Decimal; var Result: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetItemFilter(var Item: Record Item; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailability(var Item: Record Item; var SalesLine: Record "Sales Line"; var AvailableQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailabilityDate(var SalesLine: Record "Sales Line"; var AvailabilityDate: Date; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItem(SalesLine: Record "Sales Line"; var Item: Record Item; var IsHandled: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeLookupItem(var SalesLine: Record "Sales Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcAvailableInventoryOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcScheduledReceiptOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcGrossRequirementsOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedDemandOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcReservedRequirementsOnAfterSetItemFilter(var Item: Record Item)
    begin
    end;
}

