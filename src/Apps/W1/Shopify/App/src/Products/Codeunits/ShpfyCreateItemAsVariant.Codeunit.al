// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item;

codeunit 30343 "Shpfy Create Item As Variant"
{
    TableNo = Item;
    Access = Internal;

    var
        Shop: Record "Shpfy Shop";
        ShopifyProduct: Record "Shpfy Product";
        CreateProduct: Codeunit "Shpfy Create Product";
        VariantApi: Codeunit "Shpfy Variant API";
        ProductApi: Codeunit "Shpfy Product API";
        Events: Codeunit "Shpfy Product Events";
        OptionId: BigInteger;
        OptionName: Text;

    trigger OnRun()
    begin
        CreateVariantFromItem(Rec);
    end;

    /// <summary>
    /// Creates a variant from a given item and adds it to the parent product.
    /// </summary>
    /// <param name="Item">The item to be added as a variant.</param>
    internal procedure CreateVariantFromItem(var Item: Record "Item")
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ProductOptions: Dictionary of [Integer, Text];
        ExistingProductOptionValues: Dictionary of [Text, Text];
        ProductOptionIndex: Integer;
        VariantOptionTok: Label 'Variant', Locked = true;
        TitleOptionTok: Label 'Title', Locked = true;
    begin
        if Item.SystemId = ShopifyProduct."Item SystemId" then
            exit;

        CreateProduct.CreateTempShopifyVariantFromItem(Item, TempShopifyVariant);
        TempShopifyVariant.Title := Item."No.";

        if not ShopifyProduct."Has Variants" and (OptionName = TitleOptionTok) then begin
            // Shopify automatically deletes the default variant (Title) when adding a new one so first we need to update the default variant to have a different name (Variant)
            UpdateProductOption(VariantOptionTok);
            TempShopifyVariant."Option 1 Name" := VariantOptionTok;
        end else
            TempShopifyVariant."Option 1 Name" := CopyStr(OptionName, 1, MaxStrLen(TempShopifyVariant."Option 1 Name"));
        TempShopifyVariant."Option 1 Value" := Item."No.";


        if ShopifyProduct."Has Variants" and (OptionName <> VariantOptionTok) then begin
            CollectExistingProductVariantOptions(ProductOptions, ExistingProductOptionValues);

            for ProductOptionIndex := 1 to ProductOptions.Count() do
                if not AssignProductOptionValuesToTempProductVariant(TempShopifyVariant, Item, ProductOptions, ProductOptionIndex) then
                    exit;

            if not CheckProdOptionsCombinationUnique(TempShopifyVariant, ExistingProductOptionValues, Item) then
                exit;
        end;

        Events.OnAfterCreateTempShopifyVariant(Item, TempShopifyVariant);
        TempShopifyVariant.Modify();

        if VariantApi.AddProductVariant(TempShopifyVariant, ShopifyProduct.Id, "Shpfy Variant Create Strategy"::DEFAULT) then begin
            ShopifyProduct."Has Variants" := true;
            ShopifyProduct.Modify(true);
        end;
    end;

    local procedure CollectExistingProductVariantOptions(var ProductOptions: Dictionary of [Integer, Text]; var ExistingProductOptionValues: Dictionary of [Text, Text])
    var
        ShopifyVariant: Record "Shpfy Variant";
        ItemAttribute: Record "Item Attribute";
        CombinationKey: Text;
    begin
        ShopifyVariant.SetRange("Product Id", ShopifyProduct.Id);
        if ShopifyVariant.FindSet() then
            repeat
                CombinationKey := BuildCombinationKey(
                    ShopifyVariant."Option 1 Name", ShopifyVariant."Option 1 Value",
                    ShopifyVariant."Option 2 Name", ShopifyVariant."Option 2 Value",
                    ShopifyVariant."Option 3 Name", ShopifyVariant."Option 3 Value");

                if not ExistingProductOptionValues.ContainsKey(CombinationKey) then
                    ExistingProductOptionValues.Add(CombinationKey, ShopifyVariant."Variant Code");
            until ShopifyVariant.Next() = 0;

        if ShopifyVariant."Option 1 Name" <> '' then begin
            ItemAttribute.SetRange(Name, ShopifyVariant."Option 1 Name");
            if ItemAttribute.FindFirst() then
                ProductOptions.Add(ItemAttribute.ID, ShopifyVariant."Option 1 Name");
        end;
        if ShopifyVariant."Option 2 Name" <> '' then begin
            ItemAttribute.SetRange(Name, ShopifyVariant."Option 2 Name");
            if ItemAttribute.FindFirst() then
                ProductOptions.Add(ItemAttribute.ID, ShopifyVariant."Option 2 Name");
        end;
        if ShopifyVariant."Option 3 Name" <> '' then begin
            ItemAttribute.SetRange(Name, ShopifyVariant."Option 3 Name");
            if ItemAttribute.FindFirst() then
                ProductOptions.Add(ItemAttribute.ID, ShopifyVariant."Option 3 Name");
        end;
    end;

    local procedure BuildCombinationKey(Option1Name: Text; Option1Value: Text; Option2Name: Text; Option2Value: Text; Option3Name: Text; Option3Value: Text): Text
    var
        CombinationKey: Text;
        KeyPartTok: Label '%1:%2|', Locked = true;
    begin
        if Option1Name <> '' then
            CombinationKey += StrSubstNo(KeyPartTok, Option1Name, Option1Value);
        if Option2Name <> '' then
            CombinationKey += StrSubstNo(KeyPartTok, Option2Name, Option2Value);
        if Option3Name <> '' then
            CombinationKey += StrSubstNo(KeyPartTok, Option3Name, Option3Value);

        exit(CombinationKey);
    end;

    local procedure AssignProductOptionValuesToTempProductVariant(var TempShopifyVariant: Record "Shpfy Variant" temporary; Item: Record "Item"; ProductOptions: Dictionary of [Integer, Text]; ProductOptionIndex: Integer): Boolean
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        ItemWithoutRequiredAttributeErr: Label 'Item %1 cannot be added as a product variant because it does not have required attributes.', Comment = '%1 = Item No.';
        ItemWithoutRequiredAttributeValueErr: Label 'Item %1 cannot be added as a product variant because it does not have a value for the required attributes.', Comment = '%1 = Item No.';
    begin
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ProductOptions.Keys.Get(ProductOptionIndex));
        if ItemAttributeValueMapping.FindFirst() then begin
            if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then begin
                ItemAttributeValue.CalcFields("Attribute Name");
                CreateProduct.AssignProductOptionValues(TempShopifyVariant, ProductOptionIndex, ItemAttributeValue."Attribute Name", ItemAttributeValue.Value);
            end else begin
                SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(ItemWithoutRequiredAttributeValueErr, Item."No."), Shop);
                exit(false);
            end;
        end else begin
            SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(ItemWithoutRequiredAttributeErr, Item."No."), Shop);
            exit(false);
        end;

        exit(true);
    end;

    local procedure CheckProdOptionsCombinationUnique(var TempShopifyVariant: Record "Shpfy Variant" temporary; ExistingProductOptionValues: Dictionary of [Text, Text]; Item: Record "Item"): Boolean
    var
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        CombinationKey: Text;
        DuplicateCombinationErr: Label 'Item %1 cannot be added as a product variant because another variant already has the same option values.', Comment = '%1 = Item No.';
    begin
        CombinationKey := BuildCombinationKey(
            TempShopifyVariant."Option 1 Name", TempShopifyVariant."Option 1 Value",
            TempShopifyVariant."Option 2 Name", TempShopifyVariant."Option 2 Value",
            TempShopifyVariant."Option 3 Name", TempShopifyVariant."Option 3 Value");

        if ExistingProductOptionValues.ContainsKey(CombinationKey) then begin
            SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(DuplicateCombinationErr, Item."No."), Shop);
            exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Checks if items can be added as variants to the product. The items cannot be added as variants if:
    /// - The product has more than one option.
    /// - The UoM as Variant setting is enabled.
    /// </summary>
    internal procedure CheckProductAndShopSettings()
    var
        CommunicationMgt: Codeunit "Shpfy Communication Mgt.";
        Options: Dictionary of [Text, Text];
        UOMAsVariantEnabledErr: Label 'Items cannot be added as variants to a product with the "%1" setting enabled for this store.', Comment = '%1 - UoM as Variant field caption';
    begin
        if Shop."UoM as Variant" then
            Error(UOMAsVariantEnabledErr, Shop.FieldCaption("UoM as Variant"));

        Options := ProductApi.GetProductOptions(ShopifyProduct.Id);

        OptionId := CommunicationMgt.GetIdOfGId(Options.Keys.Get(1));
        OptionName := Options.Values.Get(1);
    end;

    /// <summary>
    /// Sets the parent product to which the variant will be added.
    /// </summary>
    /// <param name="ShopifyProductId">The parent Shopify product ID.</param>
    internal procedure SetParentProduct(ShopifyProductId: BigInteger)
    begin
        ShopifyProduct.Get(ShopifyProductId);
        SetShop(ShopifyProduct."Shop Code");
    end;

    local procedure UpdateProductOption(NewOptionName: Text)
    begin
        ProductApi.UpdateProductOption(ShopifyProduct.Id, OptionId, NewOptionName);
        OptionName := NewOptionName;
    end;

    local procedure SetShop(ShopCode: Code[20])
    begin
        Shop.Get(ShopCode);
        VariantApi.SetShop(Shop);
        ProductApi.SetShop(Shop);
        CreateProduct.SetShop(Shop);
    end;

}