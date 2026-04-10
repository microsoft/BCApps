// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;

codeunit 7041 "Price Asset - Item" implements "Price Asset"
{
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";

    procedure GetNo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::Item;
        if Item.GetBySystemId(PriceAsset."Asset ID") then begin
            PriceAsset."Asset No." := Item."No.";
            PriceAsset."Variant Code" := '';
            FillAdditionalFields(PriceAsset);
        end else
            if ItemVariant.GetBySystemId(PriceAsset."Asset ID") then begin
                PriceAsset."Table Id" := Database::"Item Variant";
                PriceAsset."Asset No." := ItemVariant."Item No.";
                PriceAsset."Variant Code" := ItemVariant.Code;
                FillAdditionalFields(PriceAsset);
            end else
                PriceAsset.InitAsset();
    end;

    procedure GetId(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Table Id" := Database::Item;
        if PriceAsset."Variant Code" = '' then begin
            if Item.Get(PriceAsset."Asset No.") then begin
                PriceAsset."Asset ID" := Item.SystemId;
                FillAdditionalFields(PriceAsset);
            end else
                PriceAsset.InitAsset();
        end else
            if Item.Get(PriceAsset."Asset No.") and
                ItemVariant.Get(PriceAsset."Asset No.", PriceAsset."Variant Code")
            then begin
                PriceAsset."Table Id" := Database::"Item Variant";
                PriceAsset."Asset ID" := ItemVariant.SystemId;
                FillAdditionalFields(PriceAsset);
            end else
                if not ClearVariantIfNotBelongsToItem(PriceAsset) then
                    PriceAsset.InitAsset();
    end;

    procedure IsLookupOK(var PriceAsset: Record "Price Asset"): Boolean
    var
        xPriceAsset: Record "Price Asset";
    begin
        OnBeforeIsLookupOK(PriceAsset, Item);
        xPriceAsset := PriceAsset;
        if Item.Get(xPriceAsset."Asset No.") then;
        if Page.RunModal(Page::"Item Lookup", Item) = ACTION::LookupOK then begin
            xPriceAsset.Validate("Asset No.", Item."No.");
            PriceAsset := xPriceAsset;
            exit(true);
        end;
    end;

    procedure ValidateUnitOfMeasure(var PriceAsset: Record "Price Asset"): Boolean
    begin
        ItemUnitofMeasure.SetLoadFields("Item No.", Code);
        ItemUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code");
    end;

    procedure IsLookupUnitOfMeasureOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ItemUnitofMeasure.Get(PriceAsset."Asset No.", PriceAsset."Unit of Measure Code") then;
        ItemUnitofMeasure.SetRange("Item No.", PriceAsset."Asset No.");
        if Page.RunModal(Page::"Item Units of Measure", ItemUnitofMeasure) = ACTION::LookupOK then begin
            PriceAsset.Validate("Unit of Measure Code", ItemUnitofMeasure.Code);
            exit(true);
        end;
    end;

    procedure IsLookupVariantOK(var PriceAsset: Record "Price Asset"): Boolean
    begin
        if ItemVariant.Get(PriceAsset."Asset No.", PriceAsset."Variant Code") then;
        ItemVariant.SetRange("Item No.", PriceAsset."Asset No.");
        if Page.RunModal(Page::"Item Variants", ItemVariant) = ACTION::LookupOK then begin
            PriceAsset.Validate("Variant Code", ItemVariant.Code);
            exit(true);
        end;
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        exit(true)
    end;

    procedure FillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
        Item.Get(PriceCalculationBuffer."Asset No.");
        PriceListLine."VAT Prod. Posting Group" := Item."VAT Prod. Posting Group";
        PriceListLine."Unit of Measure Code" := '';
        PriceListLine."Currency Code" := '';
        if AmountType <> AmountType::Discount then
            case PriceCalculationBuffer."Price Type" of
                PriceCalculationBuffer."Price Type"::Sale:
                    begin
                        PriceListLine."VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";
                        PriceListLine."Price Includes VAT" := Item."Price Includes VAT";
                        PriceListLine."Unit Price" := Item."Unit Price";
                    end;
                PriceCalculationBuffer."Price Type"::Purchase:
                    begin
                        PriceListLine."Price Includes VAT" := false;
                        CopyCostFromSKU(PriceCalculationBuffer, Item."Last Direct Cost");
                        PriceListLine."Direct Unit Cost" := Item."Last Direct Cost";
                    end;
            end;
        OnAfterFillBestLine(PriceCalculationBuffer, AmountType, PriceListLine);
    end;

    local procedure CopyCostFromSKU(PriceCalculationBuffer: Record "Price Calculation Buffer"; var UnitCost: Decimal)
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        StockkeepingUnit.SetLoadFields("Last Direct Cost");
        if StockkeepingUnit.Get(PriceCalculationBuffer."Location Code", PriceCalculationBuffer."Asset No.", PriceCalculationBuffer."Variant Code") then
            if StockkeepingUnit."Last Direct Cost" <> 0 then
                UnitCost := StockkeepingUnit."Last Direct Cost";
    end;

    procedure FilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceListLine.SetRange("Asset Type", PriceAsset."Asset Type");
        PriceListLine.SetRange("Asset No.", PriceAsset."Asset No.");
        PriceListLine.SetFilter("Variant Code", '%1|%2', PriceAsset."Variant Code", '');
        OnAfterFilterPriceLines(PriceAsset, PriceListLine, Result);
    end;

    procedure PutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    var
        NewPriceAsset: Record "Price Asset";
    begin
        if PriceAsset."Asset No." = '' then
            exit;

        Item.Get(PriceAsset."Asset No.");
        if Item."Item Disc. Group" <> '' then begin
            PriceAssetList.SetLevel(PriceAsset.Level);
            PriceAssetList.Add(PriceAsset."Asset Type"::"Item Discount Group", Item."Item Disc. Group");
        end;
        PriceAssetList.SetLevel(PriceAsset.Level - 1);
        NewPriceAsset := PriceAsset;
        NewPriceAsset.Validate("Asset No.", ''); // All Items
        PriceAssetList.Add(NewPriceAsset);

        OnAfterPutRelatedAssetsToList(PriceAsset, PriceAssetList);
    end;

    procedure FillFromBuffer(var PriceAsset: Record "Price Asset"; PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAsset.NewEntry(PriceCalculationBuffer."Asset Type", PriceAsset.Level);
        PriceAsset.Validate("Asset No.", PriceCalculationBuffer."Asset No.");
        PriceAsset.Validate("Variant Code", PriceCalculationBuffer."Variant Code");
        PriceAsset."Unit of Measure Code" := PriceCalculationBuffer."Unit of Measure Code";
        OnAfterFillFromBuffer(PriceAsset, PriceCalculationBuffer);
    end;

    local procedure FillAdditionalFields(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Unit of Measure Code" := GetUnitOfMeasure(PriceAsset."Price Type");
        if PriceAsset."Variant Code" = '' then
            PriceAsset.Description := Item.Description
        else
            PriceAsset.Description := ItemVariant.Description;
        case PriceAsset."Price Type" of
            PriceAsset."Price Type"::Sale:
                begin
                    PriceAsset."Allow Invoice Disc." := Item."Allow Invoice Disc.";
                    PriceAsset."Price Includes VAT" := Item."Price Includes VAT";
                    PriceAsset."VAT Bus. Posting Gr. (Price)" := Item."VAT Bus. Posting Gr. (Price)";

                    PriceAsset."Unit Price" := Item."Unit Price";
                end;
            PriceAsset."Price Type"::Purchase:
                begin
                    PriceAsset."Allow Invoice Disc." := Item."Allow Invoice Disc.";

                    PriceAsset."Unit Price" := Item."Last Direct Cost";
                end;
        end;

        OnAfterFillAdditionalFields(PriceAsset, Item, ItemVariant);
    end;

    local procedure GetUnitOfMeasure(PriceType: Enum "Price Type"): Code[10]
    begin
        case PriceType of
            PriceType::Any:
                exit(Item."Base Unit of Measure");
            PriceType::Purchase:
                exit(Item."Purch. Unit of Measure");
            PriceType::Sale:
                exit(Item."Sales Unit of Measure");
        end;
    end;

    local procedure ClearVariantIfNotBelongsToItem(var PriceAsset: Record "Price Asset"): Boolean
    var
        ItemVar: Record "Item Variant";
    begin
        if (PriceAsset."Asset Type" <> PriceAsset."Asset Type"::Item) or (PriceAsset."Variant Code" = '') or (PriceAsset."Asset No." = '') then
            exit;

        ItemVar.SetRange("Item No.", PriceAsset."Asset No.");
        ItemVar.SetRange(Code, PriceAsset."Variant Code");
        if not ItemVar.IsEmpty() then
            exit;

        if Item.Get(PriceAsset."Asset No.") then begin
            PriceAsset."Asset ID" := Item.SystemId;
            PriceAsset."Variant Code" := '';
            FillAdditionalFields(PriceAsset);
            exit(true);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillBestLine(PriceCalculationBuffer: Record "Price Calculation Buffer"; AmountType: Enum "Price Amount Type"; var PriceListLine: Record "Price List Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterPriceLines(PriceAsset: Record "Price Asset"; var PriceListLine: Record "Price List Line"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPutRelatedAssetsToList(PriceAsset: Record "Price Asset"; var PriceAssetList: Codeunit "Price Asset List")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillAdditionalFields(var PriceAsset: Record "Price Asset"; Item: Record Item; ItemVariant: Record "Item Variant")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeIsLookupOK(PriceAsset: Record "Price Asset"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillFromBuffer(var PriceAsset: Record "Price Asset"; var PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
    end;
}