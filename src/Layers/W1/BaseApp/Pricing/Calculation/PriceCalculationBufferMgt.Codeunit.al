// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;

codeunit 7008 "Price Calculation Buffer Mgt."
{
    var
        PriceCalculationBuffer: Record "Price Calculation Buffer";
        PriceListLineFiltered: Record "Price List Line";
        PriceAssetList: Codeunit "Price Asset List";
        PriceSourceList: Codeunit "Price Source List";
        UnitAmountRoundingPrecision: Decimal;
        PricesInclVATErr: Label 'Prices including VAT cannot be calculated because the VAT Calculation Type field contains %1.',
            Comment = '%1 - VAT Calculation Type field value';
        GetPriceOutOfDateErr: Label 'The selected price line is not valid on the document date %1.',
            Comment = '%1 - a date value';
        GetPriceFieldMismatchErr: Label 'The %1 in the selected price line must be %2.',
            Comment = '%1 - a field caption, %2 - a value of the field';

    procedure AddAsset(AssetType: Enum "Price Asset Type"; AssetNo: Code[20])
    begin
        PriceAssetList.Add(AssetType, AssetNo);
    end;

    procedure AddSource(SourceType: Enum "Price Source Type"; ParentSourceNo: Code[20]; SourceNo: Code[20])
    begin
        PriceSourceList.Add(SourceType, ParentSourceNo, SourceNo);
    end;

    procedure AddSource(SourceType: Enum "Price Source Type"; SourceNo: Code[20])
    begin
        PriceSourceList.Add(SourceType, SourceNo);
    end;

    procedure AddSource(SourceType: Enum "Price Source Type")
    begin
        PriceSourceList.Add(SourceType);
    end;

    procedure GetAsset(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Init();
        PriceAsset.Validate("Asset Type", PriceCalculationBuffer."Asset Type");
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
        PriceAsset."Variant Code" := PriceCalculationBuffer."Variant Code";
    end;

    procedure GetAssets(var NewPriceAssetList: Codeunit "Price Asset List")
    begin
        NewPriceAssetList.Copy(PriceAssetList);
        OnAfterGetAssets(PriceCalculationBuffer, NewPriceAssetList);
    end;

    procedure GetBuffer(var ResultPriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        ResultPriceCalculationBuffer := PriceCalculationBuffer;
    end;

    procedure GetSource(SourceType: Enum "Price Source Type") SourceNo: Code[20];
    begin
        SourceNo := PriceSourceList.GetValue(SourceType);
    end;

    procedure GetSources(var TempPriceSource: Record "Price Source" temporary) Found: Boolean;
    begin
        Found := PriceSourceList.GetList(TempPriceSource);
        OnAfterGetSources(PriceCalculationBuffer, TempPriceSource, Found);
    end;

    procedure GetSources(var NewPriceSourceList: Codeunit "Price Source List")
    begin
        NewPriceSourceList.Copy(PriceSourceList);
        OnAfterGetSourcesNewPriceSourceList(PriceCalculationBuffer, NewPriceSourceList);
    end;

    procedure SetAssets(var NewPriceAssetList: Codeunit "Price Asset List")
    begin
        PriceAssetList.Copy(NewPriceAssetList);
    end;

    procedure SetSources(var NewPriceSourceList: Codeunit "Price Source List")
    begin
        PriceSourceList.Copy(NewPriceSourceList);
    end;

    procedure Set(NewPriceCalculationBuffer: Record "Price Calculation Buffer"; var PriceSourceList: Codeunit "Price Source List")
    begin
        OnBeforeSet(NewPriceCalculationBuffer);
        PriceCalculationBuffer := NewPriceCalculationBuffer;
        CalcUnitAmountRoundingPrecision();

        PriceAssetList.Init();
        PriceAssetList.Add(PriceCalculationBuffer);

        SetSources(PriceSourceList);
    end;

    local procedure CalcUnitAmountRoundingPrecision()
    var
        Currency: Record Currency;
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if PriceCalculationBuffer."Currency Code" <> '' then begin
            Currency.Get(PriceCalculationBuffer."Currency Code");
            Currency.TestField("Unit-Amount Rounding Precision");
            UnitAmountRoundingPrecision := Currency."Unit-Amount Rounding Precision";
        end else begin
            GeneralLedgerSetup.Get();
            GeneralLedgerSetup.TestField("Unit-Amount Rounding Precision");
            UnitAmountRoundingPrecision := GeneralLedgerSetup."Unit-Amount Rounding Precision";
        end;
        OnAfterCalcUnitAmountRoundingPrecision(PriceCalculationBuffer, UnitAmountRoundingPrecision);
    end;

    procedure RoundPrice(var Price: Decimal)
    begin
        Price := Round(Price, UnitAmountRoundingPrecision);
    end;

    procedure IsInMinQty(PriceListLine: Record "Price List Line") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeIsInMinQty(PriceListLine, PriceCalculationBuffer, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PriceListLine."Unit of Measure Code" = '' then
            exit(PriceListLine."Minimum Quantity" <= PriceCalculationBuffer."Qty. per Unit of Measure" * PriceCalculationBuffer.Quantity);
        exit(PriceListLine."Minimum Quantity" <= PriceCalculationBuffer.Quantity);
    end;

    procedure ConvertAmount(AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeConvertAmount(AmountType, PriceListLine, PriceCalculationBuffer, IsHandled);
        if not IsHandled then
            if AmountType <> AmountType::Discount then begin
                ConvertAmount(PriceListLine, PriceListLine."Unit Price");
                ConvertAmount(PriceListLine, PriceListLine."Unit Cost");
                ConvertAmount(PriceListLine, PriceListLine."Direct Unit Cost");
            end;
    end;

    local procedure ConvertAmount(var PriceListLine: Record "Price List Line"; var Amount: Decimal)
    begin
        if Amount = 0 then
            exit;

        ConvertAmountByTax(PriceListLine, Amount);
        ConvertAmountByUnitOfMeasure(PriceListLine, Amount);
        ConvertAmountByCurrency(PriceListLine, Amount);
        RoundPrice(Amount);

        SetLineDiscountPctForPickBestLine(PriceListLine);
    end;

    procedure ConvertAmountByTax(var PriceListLine: Record "Price List Line"; var Amount: Decimal)
    var
        VATPostingSetup: Record "VAT Posting Setup";
        IsHandled: Boolean;
    begin
        if PriceListLine."Price Includes VAT" then begin
            VATPostingSetup.Get(PriceListLine."VAT Bus. Posting Gr. (Price)", PriceCalculationBuffer."VAT Prod. Posting Group");
            IsHandled := false;
            OnConvertAmountByTaxOnAfterVATPostingSetupGet(VATPostingSetup, Amount, IsHandled, PriceCalculationBuffer);
            if IsHandled then
                exit;

            case VATPostingSetup."VAT Calculation Type" of
                VATPostingSetup."VAT Calculation Type"::"Reverse Charge VAT":
                    VATPostingSetup."VAT %" := 0;
                VATPostingSetup."VAT Calculation Type"::"Sales Tax":
                    Error(PricesInclVATErr, VATPostingSetup."VAT Calculation Type");
            end;

            case PriceCalculationBuffer."VAT Calculation Type" of
                "Tax Calculation Type"::"Normal VAT".AsInteger(),
                "Tax Calculation Type"::"Sales Tax".AsInteger(),
                "Tax Calculation Type"::"Full VAT".AsInteger():
                    if PriceCalculationBuffer."Prices Including Tax" then begin
                        if PriceCalculationBuffer."Tax %" <> VATPostingSetup."VAT %" then
                            Amount := Amount * (100 + PriceCalculationBuffer."Tax %") / (100 + VATPostingSetup."VAT %");
                    end else
                        Amount := Amount / (1 + VATPostingSetup."VAT %" / 100);
                "Tax Calculation Type"::"Reverse Charge VAT".AsInteger():
                    Amount := Amount / (1 + VATPostingSetup."VAT %" / 100);
            end;
        end else
            if PriceCalculationBuffer."Prices Including Tax" then
                if PriceCalculationBuffer."VAT Calculation Type" <> "Tax Calculation Type"::"Reverse Charge VAT".AsInteger() then
                    Amount := Amount * (1 + PriceCalculationBuffer."Tax %" / 100);
    end;

    procedure ConvertAmountByUnitOfMeasure(var PriceListLine: Record "Price List Line"; var Amount: Decimal)
    begin
        if PriceListLine."Unit of Measure Code" = '' then
            Amount := Amount * PriceCalculationBuffer."Qty. per Unit of Measure";
    end;

    procedure ConvertAmountByCurrency(var PriceListLine: Record "Price List Line"; var Amount: Decimal)
    var
        CurrExchRate: Record "Currency Exchange Rate";
    begin
        OnBeforeConvertAmountByCurrency(PriceListLine, Amount, PriceCalculationBuffer);

        if PriceCalculationBuffer."Currency Code" = '' then
            exit;

        if PriceCalculationBuffer."Calculation in LCY" then begin
            if PriceListLine."Currency Code" <> '' then
                Amount :=
                    CurrExchRate.ExchangeAmtFCYToLCY(
                        PriceCalculationBuffer."Document Date", PriceCalculationBuffer."Currency Code",
                        Amount, PriceCalculationBuffer."Currency Factor");
        end else
            if PriceListLine."Currency Code" = '' then
                Amount :=
                    CurrExchRate.ExchangeAmtLCYToFCY(
                        PriceCalculationBuffer."Document Date", PriceCalculationBuffer."Currency Code",
                        Amount, PriceCalculationBuffer."Currency Factor");
    end;

    procedure SetLineDiscountPctForPickBestLine(var PriceListLine: Record "Price List Line")
    begin
        if PriceCalculationBuffer."Allow Line Disc." and PriceListLine."Allow Line Disc." then
            PriceListLine."Line Discount %" := PriceCalculationBuffer."Line Discount %"
        else
            PriceListLine."Line Discount %" := 0;
        OnAfterSetLineDiscountPctForPickBestLine(PriceCalculationBuffer, PriceListLine);
    end;

    procedure FillBestLine(AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    var
        PriceAssetInterface: Interface "Price Asset";
    begin
        Clear(PriceListLine);
        PriceAssetInterface := PriceCalculationBuffer."Asset Type";
        PriceAssetInterface.FillBestLine(PriceCalculationBuffer, AmountType, PriceListLine);
        ConvertAmount(AmountType, PriceListLine);
        PriceListLine."Allow Line Disc." := PriceCalculationBuffer."Allow Line Disc.";
        PriceListLine."Allow Invoice Disc." := PriceCalculationBuffer."Allow Invoice Disc.";
    end;

    procedure SetFiltersOnPriceListLine(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; ShowAll: Boolean)
    begin
        PriceListLine.SetRange(Status, PriceListLine.Status::Active);
        PriceListLine.SetRange("Price Type", PriceCalculationBuffer."Price Type");
        PriceListLine.SetFilter("Amount Type", '%1|%2', AmountType, PriceListLine."Amount Type"::Any);

        PriceListLine.SetFilter("Ending Date", '%1|>=%2', 0D, PriceCalculationBuffer."Document Date");
        if not ShowAll then begin
            PriceListLine.SetFilter("Currency Code", '%1|%2', PriceCalculationBuffer."Currency Code", '');
            if PriceCalculationBuffer."Unit of Measure Code" <> '' then
                PriceListLine.SetFilter("Unit of Measure Code", '%1|%2', PriceCalculationBuffer."Unit of Measure Code", '');
            PriceListLine.SetRange("Starting Date", 0D, PriceCalculationBuffer."Document Date");
        end;
        OnAfterSetFilters(PriceListLine, AmountType, PriceCalculationBuffer, ShowAll);
        PriceListLineFiltered.CopyFilters(PriceListLine);
    end;

    procedure RestoreFilters(var PriceListLine: Record "Price List Line")
    begin
        PriceListLine.Reset();
        PriceListLine.CopyFilters(PriceListLineFiltered);
    end;

    procedure VerifySelectedLine(PriceListLine: Record "Price List Line")
    begin
        if not (PriceListLine."Currency Code" in [PriceCalculationBuffer."Currency Code", '']) then
            Error(
                GetPriceFieldMismatchErr,
                PriceListLine.FieldCaption("Currency Code"), PriceCalculationBuffer."Currency Code");

        if not (PriceListLine."Unit of Measure Code" in [PriceCalculationBuffer."Unit of Measure Code", '']) then
            Error(
                GetPriceFieldMismatchErr,
                PriceListLine.FieldCaption("Unit of Measure Code"), PriceCalculationBuffer."Unit of Measure Code");

        if PriceListLine."Starting Date" > PriceCalculationBuffer."Document Date" then
            Error(GetPriceOutOfDateErr, PriceCalculationBuffer."Document Date")
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcUnitAmountRoundingPrecision(PriceCalculationBuffer: Record "Price Calculation Buffer"; var UnitAmountRoundingPrecision: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetAssets(PriceCalculationBuffer: Record "Price Calculation Buffer"; var NewPriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSources(PriceCalculationBuffer: Record "Price Calculation Buffer"; var TempPriceSource: Record "Price Source"; var Found: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourcesNewPriceSourceList(var PriceCalculationBuffer: Record "Price Calculation Buffer"; var NewPriceSourceList: Codeunit "Price Source List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilters(var PriceListLine: Record "Price List Line"; AmountType: Enum "Price Amount Type"; var PriceCalculationBuffer: Record "Price Calculation Buffer"; ShowAll: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLineDiscountPctForPickBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertAmount(AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line"; PriceCalculationBuffer: Record "Price Calculation Buffer"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsInMinQty(PriceListLine: Record "Price List Line"; PriceCalculationBuffer: Record "Price Calculation Buffer"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSet(var PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnConvertAmountByTaxOnAfterVATPostingSetupGet(var VATPostingSetup: Record "VAT Posting Setup"; var Amount: Decimal; var IsHandled: Boolean; var PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeConvertAmountByCurrency(var PriceListLine: Record "Price List Line"; var Amount: Decimal; var PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
    end;
}