// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;

codeunit 7042 "Price Asset - Item Disc. Group" implements "Price Asset"
{
    var
        ItemDiscountGroup: Record "Item Discount Group";
        UnitofMeasure: Record "Unit of Measure";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::"Item Discount Group";
        if ItemDiscountGroup.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Asset No." := ItemDiscountGroup.Code;
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
        PriceAsset."Amount Type" := PriceAsset."Amount Type"::Discount;
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::"Item Discount Group";
        if ItemDiscountGroup.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Asset ID" := ItemDiscountGroup.SystemId;
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
        PriceAsset."Amount Type" := PriceAsset."Amount Type"::Discount;
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    var
        xPriceAsset: Record "Price Asset";
    begin
        xPriceAsset := PriceAsset;
        if ItemDiscountGroup.Get(xPriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Item Disc. Groups", ItemDiscountGroup) = ACTION::LookupOK then begin
            xPriceAsset.Validate("Asset No.", ItemDiscountGroup.Code);
            PriceAsset := xPriceAsset;
            exit(true)
        end;
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        UnitofMeasure.Get(PriceAsset."Unit of Measure Code");
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if UnitofMeasure.Get(PriceAsset."Unit of Measure Code") then;
        if Page.RunModal(Page::"Units of Measure", UnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", UnitofMeasure.Code);
            exit(true);
        end;
    end;

    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        exit(false)
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(true)
    end;

    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
    end;

    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
        PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
        PriceListLine.SetRange("Variant Code");
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    var
        NewPriceAsset: Record "Price Asset";
    begin
        if PriceAsset."Asset No." = '' then
            exit;

        PriceAssetList.SetLevel(PriceAsset.Level - 1);
        NewPriceAsset := PriceAsset;
        NewPriceAsset.Validate("Asset No.", ''); // All Item Disc Groups
        PriceAssetList.Add(NewPriceAsset);
        OnAfterPutRelatedAssetsToList(PriceAsset, PriceAssetList);
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;

    local procedure FillAdditionalFields(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Description := ItemDiscountGroup.Description;
        PriceAsset."Unit of Measure Code" := '';
        PriceAsset."Variant Code" := '';

        OnAfterFillAdditionalFields(PriceAsset, ItemDiscountGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceAsset: Record "Price Asset"; ItemDiscountGroup: Record "Item Discount Group")
    begin
    end;
}