#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Requisition;
using Microsoft.Manufacturing.WorkCenter;

codeunit 12153 SubcontractingPricesMgt
{
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    trigger OnRun()
    begin
    end;

    var
        GLSetup: Record "General Ledger Setup";
        SubcontractorPrices: Record "Subcontractor Prices";
        PricelistUOM: Code[10];
        PricelistQtyPerUOM: Decimal;
        PricelistQty: Decimal;
        PricelistCost: Decimal;
        DirectCost: Decimal;


    procedure GetRoutingPricelistCost(var InSubcPrices: Record "Subcontractor Prices"; WorkCenter: Record "Work Center"; var DirUnitCost: Decimal; var IndirCostPct: Decimal; var OvhdRate: Decimal; var UnitCost: Decimal; var UnitCostCalculation: Enum "Unit Cost Calculation Type"; QtyUoM: Decimal; ProdQtyPerUom: Decimal; QtyBase: Decimal)
    begin
        PricelistQtyPerUOM := 0;
        PricelistQty := 0;
        PricelistCost := 0;
        DirectCost := 0;
        PricelistUOM := '';

        UnitCostCalculation := WorkCenter."Unit Cost Calculation";
        IndirCostPct := WorkCenter."Indirect Cost %";
        OvhdRate := WorkCenter."Overhead Rate";
        if WorkCenter."Specific Unit Cost" then
            DirUnitCost := (UnitCost - OvhdRate) / (1 + IndirCostPct / 100)
        else begin
            DirUnitCost := WorkCenter."Direct Unit Cost";
            UnitCost := WorkCenter."Unit Cost";
        end;

        if InSubcPrices."Start Date" = 0D then
            InSubcPrices."Start Date" := WorkDate();

        SubcontractorPrices.Reset();
        SubcontractorPrices.SetRange("Vendor No.", InSubcPrices."Vendor No.");
        SubcontractorPrices.SetFilter("Work Center No.", '%1|%2', InSubcPrices."Work Center No.", '');
        SubcontractorPrices.SetRange("Standard Task Code", InSubcPrices."Standard Task Code");
        SubcontractorPrices.SetFilter("Item No.", '%1|%2', InSubcPrices."Item No.", '');
        SubcontractorPrices.SetRange("Start Date", 0D, InSubcPrices."Start Date");
        SubcontractorPrices.SetFilter("End Date", '>=%1|%2', InSubcPrices."Start Date", 0D);
        OnRoutingPricelistCostOnAfterSetFilters(SubcontractorPrices, InSubcPrices, WorkCenter);
        if SubcontractorPrices.FindLast() then begin
            if SubcontractorPrices."Unit of Measure Code" = InSubcPrices."Unit of Measure Code" then begin
                PricelistQtyPerUOM := ProdQtyPerUom;
                PricelistQty := QtyUoM;
                PricelistUOM := SubcontractorPrices."Unit of Measure Code";
            end else
                GetUOMPrice(InSubcPrices."Item No.", QtyBase);

            GetPriceByUOM();
            if PricelistCost <> 0 then begin
                ConvertPriceToUOM(InSubcPrices."Unit of Measure Code", ProdQtyPerUom);
                if SubcontractorPrices."Currency Code" <> '' then
                    ConvertPriceFromCurrency(SubcontractorPrices."Currency Code", InSubcPrices."Start Date");
                GLSetup.Get();
                DirectCost := Round(DirectCost, GLSetup."Unit-Amount Rounding Precision");
                DirUnitCost := DirectCost;
                UnitCost := (DirUnitCost * (1 + IndirCostPct / 100) + OvhdRate);
            end;
        end;
    end;

    [Scope('OnPrem')]
    procedure GetUOMPrice(ItemNo: Code[20]; QtyBase: Decimal)
    var
        Item: Record Item;
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        Item.Get(ItemNo);
        PricelistQtyPerUOM := UOMMgt.GetQtyPerUnitOfMeasure(Item, SubcontractorPrices."Unit of Measure Code");

        if (PricelistQtyPerUOM = 1) and (SubcontractorPrices."Unit of Measure Code" = '') then
            PricelistUOM := Item."Base Unit of Measure"
        else
            PricelistUOM := SubcontractorPrices."Unit of Measure Code";

        PricelistQty := QtyBase / PricelistQtyPerUOM;
    end;

    [Scope('OnPrem')]
    procedure GetPriceByUOM()
    begin
        SubcontractorPrices.SetRange("Minimum Quantity", 0, PricelistQty);
        SubcontractorPrices.SetRange("Unit of Measure Code", SubcontractorPrices."Unit of Measure Code");
        if SubcontractorPrices.FindLast() then begin
            PricelistCost := SubcontractorPrices."Direct Unit Cost";
            if PricelistCost <> 0 then
                if (PricelistCost * PricelistQty) < SubcontractorPrices."Minimum Amount" then
                    PricelistCost := SubcontractorPrices."Minimum Amount" / PricelistQty;
        end;
    end;

    [Scope('OnPrem')]
    procedure ConvertPriceToUOM(ProdUOM: Code[10]; ProdQtyPerUoM: Decimal)
    begin
        if ProdUOM <> PricelistUOM then begin
            DirectCost := PricelistCost / PricelistQtyPerUOM;
            DirectCost := DirectCost * ProdQtyPerUoM;
        end else
            DirectCost := PricelistCost;
    end;

    [Scope('OnPrem')]
    procedure ConvertPriceToCurrency(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(CurrencyCode);
        DirectCost := CurrExchRate.ExchangeAmtLCYToFCY(
            WorkDate(), CurrencyCode, DirectCost,
            CurrExchRate.ExchangeRate(WorkDate(), CurrencyCode));
        Currency.TestField("Unit-Amount Rounding Precision");
        DirectCost := Round(PricelistCost, Currency."Unit-Amount Rounding Precision");
    end;

    [Scope('OnPrem')]
    procedure ConvertPriceFromCurrency(CurrencyCode: Code[10]; OrderDate: Date)
    var
        Currency: Record Currency;
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        Currency.Get(CurrencyCode);
        DirectCost := CurrExchRate.ExchangeAmtFCYToLCY(
            OrderDate, CurrencyCode, DirectCost,
            CurrExchRate.ExchangeRate(OrderDate, CurrencyCode));
    end;

    procedure GetSubcPriceForReqLine(var ReqLine: Record "Requisition Line"; FixedUOM: Code[10])
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
        OrderDate: Date;
    begin
        PricelistQtyPerUOM := 0;
        PricelistQty := 0;
        PricelistCost := 0;
        DirectCost := 0;
        PricelistUOM := '';

        OrderDate := ReqLine."Order Date";
        if OrderDate = 0D then
            OrderDate := WorkDate();

        SubcontractorPrices.SetRange("Vendor No.", ReqLine."Vendor No.");
        SubcontractorPrices.SetFilter("Work Center No.", '%1|%2', ReqLine."Work Center No.", '');
        SubcontractorPrices.SetRange("Standard Task Code", ReqLine."Standard Task Code");
        SubcontractorPrices.SetRange("Variant Code", ReqLine."Variant Code");
        SubcontractorPrices.SetFilter("Item No.", '%1|%2', ReqLine."No.", '');
        SubcontractorPrices.SetRange("Start Date", 0D, OrderDate);
        SubcontractorPrices.SetFilter("End Date", '>=%1|%2', OrderDate, 0D);
        SubcontractorPrices.SetFilter("Currency Code", '%1|%2', ReqLine."Currency Code", '');
        if FixedUOM <> '' then
            SubcontractorPrices.SetRange("Unit of Measure Code", FixedUOM);
        OnGetSubcPriceForReqLineOnAfterSetFilters(SubcontractorPrices, ReqLine);

        if SubcontractorPrices.FindLast() then begin
            if SubcontractorPrices."Unit of Measure Code" = ReqLine."Unit of Measure Code" then begin
                PricelistQtyPerUOM := ReqLine.GetQtyForUOM();
                PricelistQty := ReqLine.Quantity;
                PricelistUOM := ReqLine."Unit of Measure Code";
            end else
                GetUOMPrice(ReqLine."No.", ReqLine.GetQtyBase());

            GetPriceByUOM();
            if PricelistCost <> 0 then begin
                ConvertPriceToUOM(ReqLine."Unit of Measure Code", ReqLine.GetQtyForUOM());
                if (ReqLine."Currency Code" <> '') and
                   (ReqLine."Currency Code" <> SubcontractorPrices."Currency Code")
                then
                    ConvertPriceToCurrency(ReqLine."Currency Code")
                else begin
                    GLSetup.Get();
                    DirectCost := Round(DirectCost, GLSetup."Unit-Amount Rounding Precision");
                end;
            end;
        end else begin
            if FixedUOM <> '' then begin
                SubcontractorPrices."Unit of Measure Code" := FixedUOM;
                PricelistUOM := FixedUOM;
                GetUOMPrice(ReqLine."No.", ReqLine.GetQtyBase());
            end;
            if ProdOrderRtngLine.Get(
                ProdOrderRtngLine.Status::Released, ReqLine."Prod. Order No.", ReqLine."Routing Reference No.", ReqLine."Routing No.", ReqLine."Operation No.")
            then begin
                ProdOrderRtngLine.TestField(Type, ProdOrderRtngLine.Type::"Work Center");
                DirectCost := ProdOrderRtngLine."Direct Unit Cost";
            end;
        end;
        ReqLine."Direct Unit Cost" := DirectCost;
        ReqLine."Pricelist Cost" := PricelistCost;
        ReqLine."UoM for Pricelist" := PricelistUOM;
        ReqLine."Base UM Qty/Pricelist UM Qty" := PricelistQtyPerUOM;
        if ReqLine."Base UM Qty/Pricelist UM Qty" = 0 then
            ReqLine."Base UM Qty/Pricelist UM Qty" := 1;
        if ReqLine."Unit of Measure Code" = ReqLine."UoM for Pricelist" then
            ReqLine."Pricelist UM Qty/Base UM Qty" := ReqLine.Quantity
        else
            ReqLine."Pricelist UM Qty/Base UM Qty" := ReqLine.GetQtyBase() / ReqLine."Base UM Qty/Pricelist UM Qty";
        if ReqLine."Pricelist UM Qty/Base UM Qty" = 0 then
            ReqLine."Pricelist UM Qty/Base UM Qty" := 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSubcPriceForReqLineOnAfterSetFilters(var SubcontractorPrices: Record "Subcontractor Prices"; var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRoutingPricelistCostOnAfterSetFilters(var SubcontractorPrices: Record "Subcontractor Prices"; var InSubcPrices: Record "Subcontractor Prices"; WorkCenter: Record "Work Center")
    begin
    end;
}
#endif
