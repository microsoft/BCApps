// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Foundation.UOM;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;

codeunit 7044 "Price Asset - Resource Group" implements "Price Asset"
{
    var
        ResourceGroup: Record "Resource Group";
        UnitofMeasure: Record "Unit of Measure";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::"Resource Group";
        if ResourceGroup.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Asset No." := ResourceGroup."No.";
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::"Resource Group";
        if ResourceGroup.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Asset ID" := ResourceGroup.SystemId;
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    var
        xPriceAsset: Record "Price Asset";
    begin
        xPriceAsset := PriceAsset;
        if ResourceGroup.Get(xPriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Resource Groups", ResourceGroup) = ACTION::LookupOK then begin
            xPriceAsset.Validate("Asset No.", ResourceGroup."No.");
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
        PriceListLine.SetRange("Work Type Code", PriceAsset."Work Type Code");
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    var
        NewPriceAsset: Record "Price Asset";
    begin
        if PriceAsset."Asset No." = '' then
            exit;

        PriceAssetList.SetLevel(PriceAsset.Level - 1);
        NewPriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
        NewPriceAsset.Validate("Asset No.", ''); // All Resource Groups
        NewPriceAsset."Work Type Code" := PriceAsset."Work Type Code";
        PriceAssetList.Add(NewPriceAsset);
        OnAfterPutRelatedAssetsToList(PriceAsset, PriceAssetList);
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset."Work Type Code" := PriceCalculationBuffer."Work Type Code";
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
    end;

    local procedure FillAdditionalFields(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Description := ResourceGroup.Name;
        PriceAsset."Unit of Measure Code" := '';
        PriceAsset."Variant Code" := '';
        PriceAsset."Work Type Code" := '';

        OnAfterFillAdditionalFields(PriceAsset, ResourceGroup);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceAsset: Record "Price Asset"; ResourceGroup: Record "Resource Group")
    begin
    end;
}