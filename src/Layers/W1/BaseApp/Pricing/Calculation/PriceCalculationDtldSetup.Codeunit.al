// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;

codeunit 7004 "Price Calculation Dtld. Setup"
{
    procedure FindSetup(var DtldPriceCalcSetup: Record "Dtld. Price Calculation Setup") Result: Boolean;
    var
        IsHandled: Boolean;
    begin
        OnBeforeFindSetup(DtldPriceCalcSetup, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not DtldSetupExists(DtldPriceCalcSetup.Type) then
            exit(false);
        if FindDtldSetup(
            DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group", DtldPriceCalcSetup."Source No.",
            DtldPriceCalcSetup."Asset Type", DtldPriceCalcSetup."Asset No.")
        then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group", DtldPriceCalcSetup."Source No.", DtldPriceCalcSetup."Asset Type", '') then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group", DtldPriceCalcSetup."Source No.", DtldPriceCalcSetup."Asset Type"::" ", '') then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group", '', DtldPriceCalcSetup."Asset Type", DtldPriceCalcSetup."Asset No.") then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group", '', DtldPriceCalcSetup."Asset Type", '') then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group", '', DtldPriceCalcSetup."Asset Type"::" ", '') then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group"::All, '', DtldPriceCalcSetup."Asset Type", DtldPriceCalcSetup."Asset No.") then
            exit(true);
        if FindDtldSetup(DtldPriceCalcSetup, DtldPriceCalcSetup."Source Group"::All, '', DtldPriceCalcSetup."Asset Type", '') then
            exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSetup(var DtldPriceCalcSetup: Record "Dtld. Price Calculation Setup"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    local procedure FindDtldSetup(var ResultDtldPriceCalcSetup: Record "Dtld. Price Calculation Setup"; SourceGroup: Enum "Price Source Group"; SourceNo: Code[20]; AssetType: enum "Price Asset Type"; AssetNo: Code[20]): Boolean;
    var
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        DtldPriceCalculationSetup.Reset();
        DtldPriceCalculationSetup.SetRange(Enabled, true);
        DtldPriceCalculationSetup.SetRange(Method, ResultDtldPriceCalcSetup.Method);
        DtldPriceCalculationSetup.SetRange(Type, ResultDtldPriceCalcSetup.Type);
        DtldPriceCalculationSetup.SetRange("Asset Type", AssetType);
        DtldPriceCalculationSetup.SetRange("Asset No.", AssetNo);
        DtldPriceCalculationSetup.SetRange("Source Group", SourceGroup);
        DtldPriceCalculationSetup.SetRange("Source No.", SourceNo);
        if DtldPriceCalculationSetup.FindFirst() then begin
            ResultDtldPriceCalcSetup := DtldPriceCalculationSetup;
            exit(true);
        end;
        exit(false);
    end;

    local procedure DtldSetupExists(PriceType: Enum "Price Type"): Boolean;
    var
        DtldPriceCalculationSetup: Record "Dtld. Price Calculation Setup";
    begin
        DtldPriceCalculationSetup.Reset();
        DtldPriceCalculationSetup.SetRange(Enabled, true);
        DtldPriceCalculationSetup.SetRange(Type, PriceType);
        exit(not DtldPriceCalculationSetup.IsEmpty());
    end;
}