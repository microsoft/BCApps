// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;

codeunit 7043 "Price Asset - Resource" implements "Price Asset"
{
    var
        Resource: Record Resource;
        ResourceUnitofMeasure: Record "Resource Unit of Measure";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::Resource;
        if Resource.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Asset No." := Resource."No.";
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::Resource;
        if Resource.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Asset ID" := Resource.SystemId;
            FillAdditionalFields(PriceAsset);
        end else
            PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    var
        xPriceAsset: Record "Price Asset";
    begin
        xPriceAsset := PriceAsset;
        if Resource.Get(xPriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Resource List", Resource) = ACTION::LookupOK then begin
            xPriceAsset.Validate("Asset No.", Resource."No.");
            PriceAsset := xPriceAsset;
            exit(true);
        end;
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        ResourceUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code");
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ResourceUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code") then;
        ResourceUnitofMeasure.SetRange("Resource No.", PriceAsset."Asset No.");
        if Page.RunModal(Page::"Resource Units of Measure", ResourceUnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", ResourceUnitofMeasure.Code);
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
        Resource.Get(PriceCalculationBuffer."Asset No.");
        PriceListLine."Currency Code" := '';
        PriceListLine."Price Type" := PriceCalculationBuffer."Price Type";
        PriceListLine."Asset Type" := PriceListLine."Asset Type"::Resource;
        PriceListLine."Asset No." := PriceCalculationBuffer."Asset No.";
        PriceListLine."Work Type Code" := PriceCalculationBuffer."Work Type Code";
        if AmountType <> AmountType::Discount then
            case PriceCalculationBuffer."Price Type" of
                PriceCalculationBuffer."Price Type"::Sale:
                    PriceListLine."Unit Price" := Resource."Unit Price";
                PriceCalculationBuffer."Price Type"::Purchase:
                    begin
                        PriceListLine."Direct Unit Cost" := Resource."Direct Unit Cost";
                        PriceListLine."Unit Cost" := Resource."Unit Cost";
                    end;
            end;
        OnAfterFillBestLine(PriceCalculationBuffer, AmountType, PriceListLine);
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

        Resource.Get(PriceAsset."Asset No.");
        if Resource."Resource Group No." <> '' then begin
            PriceAssetList.SetLevel(PriceAsset.Level - 1);
            NewPriceAsset.Validate("Asset Type", PriceAsset."Asset Type"::"Resource Group");
            NewPriceAsset.Validate("Asset No.", Resource."Resource Group No.");
            NewPriceAsset."Work Type Code" := PriceAsset."Work Type Code";
            PriceAssetList.Add(NewPriceAsset);
        end;
        PriceAssetList.SetLevel(PriceAsset.Level - 2);
        NewPriceAsset := PriceAsset;
        NewPriceAsset.Validate("Asset No.", ''); // All Resources
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

        OnAfterFillFromBuffer(PriceAsset, PriceCalculationBuffer);
    end;

    local procedure FillAdditionalFields(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset.Description := Resource.Name;
        PriceAsset."Unit of Measure Code" := Resource."Base Unit of Measure";
        PriceAsset."Work Type Code" := '';
        PriceAsset."Variant Code" := '';
        case PriceAsset."Price Type" of
            PriceAsset."Price Type"::Sale:
                PriceAsset."Unit Price" := Resource."Unit Price";
            PriceAsset."Price Type"::Purchase:
                begin
                    PriceAsset."Unit Price" := Resource."Direct Unit Cost";
                    PriceAsset."Unit Price 2" := Resource."Unit Cost";
                end;
        end;
        OnAfterFillAdditionalFields(PriceAsset, Resource);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceAsset: Record "Price Asset"; Resource: Record Resource)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
    end;
}