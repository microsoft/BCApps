// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;

codeunit 7040 "Price Asset - All" implements "Price Asset"
{
    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(false)
    end;

    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
    end;

    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
        PriceListLine.SetRange("Asset No.", '');
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
    end;
}