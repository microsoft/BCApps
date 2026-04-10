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

/// <summary>
/// Provides availability calculations and item information for sales document factboxes.
/// </summary>
codeunit 7171 "Sales Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;
        AvailableToPromise: Codeunit "Available to Promise";
        UOMMgt: Codeunit "Unit of Measure Management";

    /// <summary>
    /// Calculates the available quantity to promise for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to calculate availability for.</param>
    /// <returns>The available quantity in the sales line's unit of measure.</returns>
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

    /// <summary>
    /// Calculates the availability date based on the shipment date or work date.
    /// </summary>
    /// <param name="SalesLine">The sales line to get the date from.</param>
    /// <returns>The shipment date if specified, otherwise the work date.</returns>
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

    /// <summary>
    /// Calculates the available inventory for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to calculate for.</param>
    /// <returns>The available inventory in the sales line's unit of measure.</returns>
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

    /// <summary>
    /// Calculates the scheduled receipt quantity for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to calculate for.</param>
    /// <returns>The scheduled receipt quantity in the sales line's unit of measure.</returns>
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

    /// <summary>
    /// Calculates the gross requirement for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to calculate for.</param>
    /// <returns>The gross requirement in the sales line's unit of measure.</returns>
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

    /// <summary>
    /// Calculates the reserved receipt for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to calculate for.</param>
    /// <returns>The reserved receipt in the sales line's unit of measure.</returns>
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

    /// <summary>
    /// Calculates the reserved requirement for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to calculate for.</param>
    /// <returns>The reserved requirement in the sales line's unit of measure.</returns>
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

    /// <summary>
    /// Gets the reservation from stock state for the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <returns>None, Partial, or Full depending on reservation status.</returns>
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

    /// <summary>
    /// Calculates the number of item substitutes available for the sales line item.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <returns>The number of substitutes.</returns>
    procedure CalcNoOfSubstitutions(var SalesLine: Record "Sales Line"): Integer
    begin
        if GetItem(SalesLine) then begin
            Item.CalcFields("No. of Substitutes");
            exit(Item."No. of Substitutes");
        end;
    end;

    /// <summary>
    /// Calculates the number of sales prices available for the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <returns>The number of available prices.</returns>
    procedure CalcNoOfSalesPrices(var SalesLine: Record "Sales Line"): Integer
    begin
        exit(SalesLine.CountPrice(true));
    end;

    /// <summary>
    /// Calculates the number of sales line discounts available for the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to check.</param>
    /// <returns>The number of available line discounts.</returns>
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

    /// <summary>
    /// Opens the Item Card page for the item on the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line containing the item to look up.</param>
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

    /// <summary>
    /// Resets the cached item number in the Available to Promise codeunit.
    /// </summary>
    procedure ResetItemNo()
    begin
        AvailableToPromise.ResetItemNo();
    end;

    /// <summary>
    /// Gets the item record for the sales line.
    /// </summary>
    /// <param name="SalesLine">The sales line to get the item for.</param>
    /// <returns>True if the item was found, otherwise false.</returns>
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

