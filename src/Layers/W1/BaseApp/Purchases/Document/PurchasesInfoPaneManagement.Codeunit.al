// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Foundation.Enums;
using Microsoft.Inventory.Availability;
using Microsoft.Inventory.Item;

codeunit 7181 "Purchases Info-Pane Management"
{

    trigger OnRun()
    begin
    end;

    var
        Item: Record Item;

    procedure CalcAvailability(var PurchLine: Record "Purchase Line"): Decimal
    var
        AvailableToPromise: Codeunit "Available to Promise";
        GrossRequirement: Decimal;
        ScheduledReceipt: Decimal;
        AvailableQuantity: Decimal;
        PeriodType: Enum "Analysis Period Type";
        AvailabilityDate: Date;
        LookaheadDateformula: DateFormula;
        IsHandled: Boolean;
    begin
        if GetItem(PurchLine) then begin
            if PurchLine."Expected Receipt Date" <> 0D then
                AvailabilityDate := PurchLine."Expected Receipt Date"
            else
                AvailabilityDate := WorkDate();

            Item.Reset();
            Item.SetRange("Date Filter", 0D, AvailabilityDate);
            Item.SetRange("Variant Filter", PurchLine."Variant Code");
            Item.SetRange("Location Filter", PurchLine."Location Code");
            Item.SetRange("Drop Shipment Filter", false);

            IsHandled := false;
            OnBeforeCalcAvailability(Item, PurchLine, AvailableQuantity, IsHandled);
            if IsHandled then
                exit(AvailableQuantity);

            exit(
              AvailableToPromise.CalcQtyAvailabletoPromise(
                Item,
                GrossRequirement,
                ScheduledReceipt,
                AvailabilityDate,
                PeriodType,
                LookaheadDateformula));
        end;
    end;

    procedure CalcNoOfPurchasePrices(var PurchLine: Record "Purchase Line"): Integer
    begin
        exit(PurchLine.CountPrice(true));
    end;

    procedure CalcNoOfPurchLineDisc(var PurchLine: Record "Purchase Line"): Integer
    begin
        exit(PurchLine.CountDiscount(true));
    end;

    local procedure GetItem(var PurchLine: Record "Purchase Line"): Boolean
    var
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetItemOnPurchasesInfoPaneManagement(PurchLine, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if (PurchLine.Type <> PurchLine.Type::Item) or (PurchLine."No." = '') then
            exit(false);

        if PurchLine."No." <> Item."No." then
            Item.Get(PurchLine."No.");
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcAvailability(var Item: Record Item; PurchaseLine: Record "Purchase Line"; var AvailableQuantity: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetItemOnPurchasesInfoPaneManagement(var PurchaseLine: Record "Purchase Line"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;
}

