// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Foundation.ExtendedText;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Purchases.Vendor;
using System.Text;

/// <summary>
/// Codeunit Shpfy Product Export (ID 30178).
/// </summary>
codeunit 30178 "Shpfy Product Export"
{
    Access = Internal;
    Permissions =
        tabledata "Extended Text Header" = r,
        tabledata "Extended Text Line" = r,
        tabledata Item = rim,
        tabledata "Item Attr. Value Translation" = r,
        tabledata "Item Attribute" = r,
        tabledata "Item Attribute Translation" = r,
        tabledata "Item Attribute Value" = r,
        tabledata "Item Attribute Value Mapping" = r,
        tabledata "Item Var. Attr. Value Mapping" = r,
        tabledata "Item Category" = r,
        tabledata "Item Reference" = r,
        tabledata "Item Unit of Measure" = rim,
        tabledata "Item Variant" = rim,
        tabledata Vendor = r;
    TableNo = "Shpfy Shop";

    trigger OnRun()
    var
        ShopifyProduct: Record "Shpfy Product";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        VariantId: BigInteger;
    begin
        ShopifyProduct.SetFilter("Item SystemId", '<>%1', NullGuid);
        ShopifyProduct.SetFilter("Shop Code", Rec.GetFilter(Code));

        ProductEvents.OnAfterProductsToSynchronizeFiltersSet(ShopifyProduct, Shop, OnlyUpdatePrice);

        RecordCount := ShopifyProduct.Count();
        if ShopifyProduct.FindSet(false) then
            repeat
                SetShop(ShopifyProduct."Shop Code");
                if Shop."Can Update Shopify Products" or OnlyUpdatePrice then
                    UpdateProductData(ShopifyProduct.Id);
            until ShopifyProduct.Next() = 0;

        if OnlyUpdatePrice then
            if BulkOperationInput.Length > 0 then
                if not BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::UpdateProductPrice, BulkOperationInput.ToText(), JRequestData) then
                    foreach VariantId in GraphQueryList.Keys do
                        if not VariantAPI.UpdateProductPrice(GraphQueryList.Get(VariantId)) then
                            RevertVariantChanges(VariantId);
    end;

    var
        Shop: Record "Shpfy Shop";
        ProductApi: Codeunit "Shpfy Product API";
        ProductEvents: Codeunit "Shpfy Product Events";
        ProductPriceCalc: Codeunit "Shpfy Product Price Calc.";
        VariantApi: Codeunit "Shpfy Variant API";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        OnlyUpdatePrice: Boolean;
        RecordCount: Integer;
        NullGuid: Guid;
        BulkOperationInput: TextBuilder;
        GraphQueryList: Dictionary of [BigInteger, TextBuilder];
        JRequestData: JsonArray;
        VariantPriceCalcSkippedLbl: Label 'Variant price is not synchronized because the %1 is blocked or sales blocked.', Comment = '%1 - item or item variant.';
        ItemIsBlockedLbl: Label 'Item is blocked.';
        ItemIsDraftLbl: Label 'Shopify product is in draft status.';
        ItemIsArchivedLbl: Label 'Shopify product is archived.';
        ItemVariantIsBlockedLbl: Label 'Item variant is blocked or sales blocked.';
        ItemLbl: Label 'item';
        ItemVariantLbl: Label 'item variant';

    /// <summary> 
    /// Creates html body for a product from extended text, marketing text and attributes.
    /// </summary>
    /// <param name="ItemNo">Item number.</param>
    /// <param name="LanguageCode">Language code to look for translations.</param>
    /// <returns>Product body html.</returns>
    internal procedure CreateProductBody(ItemNo: Code[20]; LanguageCode: Code[10]) ProductBodyHtml: Text
    var
        Item: Record Item;
        EntityText: Codeunit "Entity Text";
        EntityTextScenario: Enum "Entity Text Scenario";
        IsHandled: Boolean;
        MarketingText: Text;
        Result: TextBuilder;
    begin
        ProductEvents.OnBeforeCreateProductBodyHtml(ItemNo, Shop, ProductBodyHtml, IsHandled, LanguageCode);
        if not IsHandled then begin
            if Shop."Sync Item Extended Text" then
                AddExtendTextHtml(ItemNo, Result, LanguageCode);

            if Shop."Sync Item Marketing Text" then
                if LanguageCode = Shop."Language Code" then
                    if Item.Get(ItemNo) then begin
                        MarketingText := EntityText.GetText(Database::Item, Item.SystemId, EntityTextScenario::"Marketing Text");
                        if MarketingText <> '' then begin
                            Result.Append('<div class="productDescription">');
                            Result.Append(MarketingText);
                            Result.Append('</div>');
                            Result.Append('<br>');
                        end
                    end;

            if Shop."Sync Item Attributes" then
                AddAtributeHtml(ItemNo, Result, LanguageCode);

            ProductBodyHtml := Result.ToText();
        end;
        ProductEvents.OnAfterCreateProductbodyHtml(ItemNo, Shop, ProductBodyHtml, LanguageCode);
    end;

    local procedure AddExtendTextHtml(ItemNo: Code[20]; Result: TextBuilder; LanguageCode: Code[10])
    var
        ExtendedTextHeader: Record "Extended Text Header";
        ExtendedTextLine: Record "Extended Text Line";
    begin
        ExtendedTextHeader.SetRange("Table Name", ExtendedTextHeader."Table Name"::Item);
        ExtendedTextHeader.SetRange("No.", ItemNo);
        ExtendedTextHeader.SetFilter("Language Code", '%1|%2', '', LanguageCode);
        ExtendedTextHeader.SetRange("Starting Date", 0D, Today());
        ExtendedTextHeader.SetFilter("Ending Date", '%1|%2..', 0D, Today());
        if ExtendedTextHeader.FindSet() then begin
            result.Append('<div class="productDescription">');
            repeat
                if (ExtendedTextHeader."Language Code" = LanguageCode) or ExtendedTextHeader."All Language Codes" then begin
                    ExtendedTextLine.SetRange("Table Name", ExtendedTextHeader."Table Name");
                    ExtendedTextLine.SetRange("No.", ExtendedTextHeader."No.");
                    ExtendedTextLine.SetRange("Language Code", ExtendedTextHeader."Language Code");
                    ExtendedTextLine.SetRange("Text No.", ExtendedTextHeader."Text No.");
                    if ExtendedTextLine.FindSet() then begin
                        Result.Append('  ');
                        repeat
                            Result.Append(ExtendedTextLine.Text);
                            if StrLen(ExtendedTextLine.Text) > 0 then
                                case ExtendedTextLine.Text[StrLen(ExtendedTextLine.Text)] of
                                    '.', '?', '!', ':':
                                        begin
                                            Result.Append('<br />');
                                            Result.Append('  ');
                                        end;
                                    '/':
                                        ;
                                    else
                                        Result.Append(' ');
                                end
                            else begin
                                Result.Append('<br />');
                                Result.Append('  ');
                            end;
                        until ExtendedTextLine.Next() = 0;
                    end;
                end;
            until ExtendedTextHeader.Next() = 0;
            result.Append('</div>');
            Result.Append('<br>');
        end;
    end;

    local procedure AddAtributeHtml(ItemNo: Code[20]; Result: TextBuilder; LanguageCode: Code[10])
    var
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
        ItemAttribute: Record "Item Attribute";
        ItemAttributeTranslation: Record "Item Attribute Translation";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        Translator: Report "Shpfy Translator";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", ItemNo);
        if ItemAttributeValueMapping.FindSet() then begin
            Result.Append('<div class="productAttributes">');
            Result.Append('  <div class="productAttributesTitle">');
            Result.Append(Translator.GetAttributeTitle(LanguageCode));
            Result.Append('  </div>');
            Result.Append('  <table>');
            repeat
                if ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID") and (not ItemAttribute.Blocked) then begin
                    Result.Append('    <tr>');
                    Result.Append('      <td class="attributeName">');
                    if ItemAttributeTranslation.Get(ItemAttributeValueMapping."Item Attribute ID", LanguageCode) then
                        Result.Append(ItemAttributeTranslation.Name)
                    else
                        Result.Append(ItemAttribute.Name);
                    Result.Append('      </td>');
                    Result.Append('      <td class="attributeValue">');
                    if ItemAttrValueTranslation.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID", LanguageCode) then
                        Result.Append(ItemAttrValueTranslation.Name)
                    else
                        if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then begin
                            Result.Append(ItemAttributeValue.Value);
                            case ItemAttribute.Type of
                                ItemAttribute.Type::Integer, ItemAttribute.Type::Decimal:
                                    begin
                                        Result.Append(' ');
                                        Result.Append(ItemAttribute."Unit of Measure");
                                    end;
                            end;
                        end;
                    Result.Append('      </td>');
                    Result.Append('    </tr>');
                end;
            until ItemAttributeValueMapping.Next() = 0;
            Result.Append('  </table>');
            Result.Append('</div>');
        end;
    end;

    /// <summary> 
    /// Create Product Variant.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemUnitofMeasure">Parameter of type Record "Item Unit of Measure".</param>
    local procedure CreateProductVariant(ProductId: BigInteger; Item: Record Item; ItemUnitofMeasure: Record "Item Unit of Measure")
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
    begin
        if OnlyUpdatePrice then
            exit;
        Clear(TempShopifyVariant);
        FillInProductVariantData(TempShopifyVariant, Item, ItemUnitofMeasure);
        TempShopifyVariant.Insert(false);
        VariantApi.AddProductVariant(TempShopifyVariant, ProductId, "Shpfy Variant Create Strategy"::DEFAULT);
    end;

    /// <summary> 
    /// Create Product Variant.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    local procedure CreateProductVariant(ProductId: BigInteger; Item: Record Item; ItemVariant: Record "Item Variant"; TempShopifyProduct: Record "Shpfy Product" temporary)
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        ItemAttributeIds: List of [Integer];
    begin
        if ItemVariant.Blocked or ItemVariant."Sales Blocked" then begin
            SkippedRecord.LogSkippedRecord(ItemVariant.RecordId, ItemVariantIsBlockedLbl, Shop);
            exit;
        end;

        if OnlyUpdatePrice then
            exit;
        Clear(TempShopifyVariant);
        FillInProductVariantData(TempShopifyVariant, Item, ItemVariant);

        GetItemAttributeIDsMarkedAsOption(Item, ItemAttributeIds);
        if ItemAttributeIds.Count() > 0 then
            if not ValidateItemAttributesAsProductOptionsForNewVariant(TempShopifyVariant, Item, ItemVariant.Code, TempShopifyProduct.Id) then
                exit;

        TempShopifyVariant.Insert(false);
        VariantApi.AddProductVariant(TempShopifyVariant, ProductId, "Shpfy Variant Create Strategy"::DEFAULT);
    end;

    /// <summary> 
    /// Create Product Variant.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    /// <param name="ItemUnitofMeasure">Parameter of type Record "Item Unit of Measure".</param>
    local procedure CreateProductVariant(ProductId: BigInteger; Item: Record Item; ItemVariant: Record "Item Variant"; ItemUnitofMeasure: Record "Item Unit of Measure")
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
    begin
        if ItemVariant.Blocked or ItemVariant."Sales Blocked" then begin
            SkippedRecord.LogSkippedRecord(ItemVariant.RecordId, ItemVariantIsBlockedLbl, Shop);
            exit;
        end;

        Clear(TempShopifyVariant);
        FillInProductVariantData(TempShopifyVariant, Item, ItemVariant, ItemUnitofMeasure);
        TempShopifyVariant.Insert(false);
        VariantApi.AddProductVariant(TempShopifyVariant, ProductId, "Shpfy Variant Create Strategy"::DEFAULT);
    end;


    /// <summary> 
    /// Fill In Product Fields.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ShopifyProduct">Parameter of type Record "Shopify Product".</param>
    internal procedure FillInProductFields(Item: Record Item; var ShopifyProduct: Record "Shpfy Product")
    var
        ItemTranslation: Record "Item Translation";
        IsHandled: Boolean;
        Title: Text;
    begin
        if OnlyUpdatePrice then
            exit;
        ItemTranslation.SetRange("Item No.", Item."No.");
        ItemTranslation.SetRange("Language Code", Shop."Language Code");
        ItemTranslation.SetRange("Variant Code", '');
        if ItemTranslation.FindFirst() and (ItemTranslation.Description <> '') then
            Title := RemoveTabChars(ItemTranslation.Description)
        else
            Title := RemoveTabChars(Item.Description);
        ProductEvents.OnBeforSetProductTitle(Item, Shop."Language Code", Title, IsHandled);
        if not IsHandled then begin
            ProductEvents.OnAfterSetProductTitle(Item, Shop."Language Code", Title);
            ShopifyProduct.Title := CopyStr(Title, 1, MaxStrLen(ShopifyProduct.Title));
        end;
        ShopifyProduct.Vendor := CopyStr(GetVendor(Item."Vendor No."), 1, MaxStrLen(ShopifyProduct.Vendor));
        ShopifyProduct."Product Type" := CopyStr(GetProductType(Item."Item Category Code"), 1, MaxStrLen(ShopifyProduct."Product Type"));
        ShopifyProduct.SetDescriptionHtml(CreateProductBody(Item."No.", Shop."Language Code"));
        ShopifyProduct."Tags Hash" := ShopifyProduct.CalcTagsHash();
        if Item.Blocked then
            case Shop."Action for Removed Products" of
                Shop."Action for Removed Products"::StatusToArchived:
                    ShopifyProduct.Status := ShopifyProduct.Status::Archived;
                Shop."Action for Removed Products"::StatusToDraft:
                    ShopifyProduct.Status := ShopifyProduct.Status::Draft;
            end;
        ProductEvents.OnAfterFillInShopifyProductFields(Item, ShopifyProduct);
    end;

    /// <summary> 
    /// Replace Tab with spaces.
    /// </summary>
    /// <param name="Source">Parameter of type Text.</param>
    /// <returns>Return value of type Text.</returns>
    local procedure RemoveTabChars(Source: Text): Text
    var
        Tab: Text[1];
    begin
        Tab[1] := 9;
        exit(Source.Replace(Tab, ' '));
    end;

    /// <summary> 
    /// Fill In Product Variant Data.
    /// </summary>
    /// <param name="ShopifyVariant">Parameter of type Record "Shopify Variant".</param>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemUnitofMeasure">Parameter of type Record "Item Unit of Measure".</param>
    internal procedure FillInProductVariantData(var ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemUnitofMeasure: Record "Item Unit of Measure")
    begin
        if Shop."Sync Prices" or OnlyUpdatePrice then
            if (not Item.Blocked) and (not Item."Sales Blocked") then
                ProductPriceCalc.CalcPrice(Item, '', ItemUnitofMeasure.Code, ShopifyVariant."Unit Cost", ShopifyVariant.Price, ShopifyVariant."Compare at Price")
            else
                SkippedRecord.LogSkippedRecord(ShopifyVariant.Id, Item.RecordId, StrSubstNo(VariantPriceCalcSkippedLbl, ItemLbl), Shop);
        if not OnlyUpdatePrice then begin
            ShopifyVariant."Available For Sales" := (not Item.Blocked) and (not Item."Sales Blocked");
            ShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", '', ItemUnitofMeasure.Code), 1, MaxStrLen(ShopifyVariant.Barcode));
            ShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
            case Shop."SKU Mapping" of
                Shop."SKU Mapping"::"Bar Code":
                    ShopifyVariant.SKU := ShopifyVariant.Barcode;
                Shop."SKU Mapping"::"Item No.",
                Shop."SKU Mapping"::"Item No. + Variant Code":
                    ShopifyVariant.SKU := Item."No.";
                Shop."SKU Mapping"::"Vendor Item No.":
                    ShopifyVariant.SKU := Item."Vendor Item No.";
            end;
            ShopifyVariant.Taxable := true;
            ShopifyVariant.Weight := ItemUnitofMeasure."Qty. per Unit of Measure" > 0 ? Item."Gross Weight" * ItemUnitofMeasure."Qty. per Unit of Measure" : Item."Gross Weight";
            ShopifyVariant."Option 1 Name" := Shop."Option Name for UoM";
            ShopifyVariant."Option 1 Value" := ItemUnitofMeasure.Code;
            ShopifyVariant."Shop Code" := Shop.Code;
            ShopifyVariant."Item SystemId" := Item.SystemId;
            ShopifyVariant."UoM Option Id" := 1;
        end;
    end;

    /// <summary> 
    /// Fill In Product Variant Data.
    /// </summary>
    /// <param name="ShopifyVariant">Parameter of type Record "Shopify Variant".</param>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    internal procedure FillInProductVariantData(var ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemVariant: Record "Item Variant")
    var
        Product: Record "Shpfy Product";
        ItemAsVariant: Boolean;
    begin
        if Shop."Sync Prices" or OnlyUpdatePrice then
            if Item.Blocked or Item."Sales Blocked" then
                SkippedRecord.LogSkippedRecord(ShopifyVariant.Id, Item.RecordId, StrSubstNo(VariantPriceCalcSkippedLbl, ItemLbl), Shop)
            else
                if ItemVariant.Blocked or ItemVariant."Sales Blocked" then
                    SkippedRecord.LogSkippedRecord(ShopifyVariant.Id, ItemVariant.RecordId, StrSubstNo(VariantPriceCalcSkippedLbl, ItemVariantLbl), Shop)
                else
                    ProductPriceCalc.CalcPrice(Item, ItemVariant.Code, Item."Sales Unit of Measure", ShopifyVariant."Unit Cost", ShopifyVariant.Price, ShopifyVariant."Compare at Price");
        if not OnlyUpdatePrice then begin
            if Product.Get(ShopifyVariant."Product Id") then
                if Product."Has Variants" then
                    ItemAsVariant := ShopifyVariant."Item SystemId" <> Product."Item SystemId";
            ShopifyVariant."Available For Sales" := (not Item.Blocked) and (not Item."Sales Blocked");
            ShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", ItemVariant.Code, Item."Sales Unit of Measure"), 1, MaxStrLen(ShopifyVariant.Barcode));
            if ItemAsVariant then
                ShopifyVariant.Title := Item."No."
            else
                ShopifyVariant.Title := CopyStr(RemoveTabChars(ItemVariant.Description), 1, MaxStrLen(ShopifyVariant.Title));
            ShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
            case Shop."SKU Mapping" of
                Shop."SKU Mapping"::"Bar Code":
                    ShopifyVariant.SKU := ShopifyVariant.Barcode;
                Shop."SKU Mapping"::"Item No.":
                    ShopifyVariant.SKU := Item."No.";
                Shop."SKU Mapping"::"Variant Code":
                    if ItemVariant.Code <> '' then
                        ShopifyVariant.SKU := ItemVariant.Code;
                Shop."SKU Mapping"::"Item No. + Variant Code":
                    if ItemVariant.Code <> '' then
                        ShopifyVariant.SKU := Item."No." + Shop."SKU Field Separator" + ItemVariant.Code
                    else
                        ShopifyVariant.SKU := Item."No.";
                Shop."SKU Mapping"::"Vendor Item No.":
                    ShopifyVariant.SKU := Item."Vendor Item No.";
            end;
            ShopifyVariant.Taxable := true;
            ShopifyVariant.Weight := Item."Gross Weight";
            if ShopifyVariant."Option 1 Name" = '' then
                ShopifyVariant."Option 1 Name" := 'Variant';
            if ShopifyVariant."Option 1 Name" = 'Variant' then
                if ItemAsVariant then
                    ShopifyVariant."Option 1 Value" := Item."No."
                else
                    ShopifyVariant."Option 1 Value" := ItemVariant.Code;
            ShopifyVariant."Shop Code" := Shop.Code;
            ShopifyVariant."Item SystemId" := Item.SystemId;
            ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
            ShopifyVariant."UoM Option Id" := 2;
            ProductEvents.OnAfterFillInProductVariantData(ShopifyVariant, Item, ItemVariant, Shop);
        end;
    end;

    /// <summary> 
    /// Fill In Product Variant Data.
    /// </summary>
    /// <param name="ShopifyVariant">Parameter of type Record "Shopify Variant".</param>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    /// <param name="ItemUnitofMeasure">Parameter of type Record "Item Unit of Measure".</param>
    internal procedure FillInProductVariantData(var ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemVariant: Record "Item Variant"; ItemUnitofMeasure: Record "Item Unit of Measure")
    begin
        if Shop."Sync Prices" or OnlyUpdatePrice then
            if Item.Blocked or Item."Sales Blocked" then
                SkippedRecord.LogSkippedRecord(ShopifyVariant.Id, Item.RecordId, StrSubstNo(VariantPriceCalcSkippedLbl, ItemLbl), Shop)
            else
                if ItemVariant.Blocked or ItemVariant."Sales Blocked" then
                    SkippedRecord.LogSkippedRecord(ShopifyVariant.Id, ItemVariant.RecordId, StrSubstNo(VariantPriceCalcSkippedLbl, ItemVariantLbl), Shop)
                else
                    ProductPriceCalc.CalcPrice(Item, ItemVariant.Code, ItemUnitofMeasure.Code, ShopifyVariant."Unit Cost", ShopifyVariant.Price, ShopifyVariant."Compare at Price");
        if not OnlyUpdatePrice then begin
            ShopifyVariant."Available For Sales" := (not Item.Blocked) and (not Item."Sales Blocked");
            ShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", ItemVariant.Code, ItemUnitofMeasure.Code), 1, MaxStrLen(ShopifyVariant.Barcode));
            ShopifyVariant.Title := CopyStr(RemoveTabChars(ItemVariant.Description), 1, MaxStrLen(ShopifyVariant.Title));
            ShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
            case Shop."SKU Mapping" of
                Shop."SKU Mapping"::"Bar Code":
                    ShopifyVariant.SKU := ShopifyVariant.Barcode;
                Shop."SKU Mapping"::"Item No.":
                    ShopifyVariant.SKU := Item."No.";
                Shop."SKU Mapping"::"Variant Code":
                    if ItemVariant.Code <> '' then
                        ShopifyVariant.SKU := ItemVariant.Code;
                Shop."SKU Mapping"::"Item No. + Variant Code":
                    if ItemVariant.Code <> '' then
                        ShopifyVariant.SKU := Item."No." + Shop."SKU Field Separator" + ItemVariant.Code
                    else
                        ShopifyVariant.SKU := Item."No.";
                Shop."SKU Mapping"::"Vendor Item No.":
                    ShopifyVariant.SKU := Item."Vendor Item No.";
            end;
            ShopifyVariant.Taxable := true;
            ShopifyVariant.Weight := ItemUnitofMeasure."Qty. per Unit of Measure" > 0 ? Item."Gross Weight" * ItemUnitofMeasure."Qty. per Unit of Measure" : Item."Gross Weight";
            ShopifyVariant."Option 1 Name" := 'Variant';
            ShopifyVariant."Option 1 Value" := ItemVariant.Code;
            ShopifyVariant."Option 2 Name" := Shop."Option Name for UoM";
            ShopifyVariant."Option 2 Value" := ItemUnitofMeasure.Code;
            ShopifyVariant."Shop Code" := Shop.Code;
            ShopifyVariant."Item SystemId" := Item.SystemId;
            ShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
            ShopifyVariant."UoM Option Id" := 2;
            ProductEvents.OnAfterFillInProductVariantDataFromVariant(ShopifyVariant, Item, ItemVariant, ItemUnitofMeasure, Shop);
        end;
    end;

    /// <summary> 
    /// Get Barcode.
    /// </summary>
    /// <param name="ItemNo">Parameter of type Code[20].</param>
    /// <param name="VariantCode">Parameter of type Code[10].</param>
    /// <param name="UoM">Parameter of type Code[10].</param>
    /// <returns>Return value of type Text.</returns>
    local procedure GetBarcode(ItemNo: Code[20]; VariantCode: Code[10]; UoM: Code[10]): Text;
    var
        ItemReferenceMgt: Codeunit "Shpfy Item Reference Mgt.";
    begin
        exit(ItemReferenceMgt.GetItemBarcode(ItemNo, VariantCode, UoM));
    end;

    /// <summary> 
    /// Get Product Type.
    /// </summary>
    /// <param name="ItemCategoryCode">Parameter of type Code[20].</param>
    /// <returns>Return value of type Text.</returns>
    local procedure GetProductType(ItemCategoryCode: Code[20]): Text
    var
        ItemCategory: Record "Item Category";
    begin
        if ItemCategoryCode <> '' then
            if ItemCategory.Get(ItemCategoryCode) then
                if ItemCategory.Description <> '' then
                    exit(ItemCategory.Description);
        exit(ItemCategoryCode);
    end;

    /// <summary> 
    /// Get Vendor.
    /// </summary>
    /// <param name="VendorNo">Parameter of type Code[20].</param>
    /// <returns>Return value of type Text.</returns>
    local procedure GetVendor(VendorNo: Code[20]): Text
    var
        Vendor: Record Vendor;
    begin
        if VendorNo <> '' then
            if Vendor.Get(VendorNo) then
                if Vendor.Name <> '' then
                    exit(Vendor.Name);
        exit(VendorNo);
    end;

    /// <summary> 
    /// Has Change.
    /// </summary>
    /// <param name="RecordRef1">Parameter of type RecordRef.</param>
    /// <param name="RecordRef2">Parameter of type RecordRef.</param>
    /// <returns>Return value of type Boolean.</returns>
    local procedure HasChange(var RecordRef1: RecordRef; var RecordRef2: RecordRef): Boolean
    var
        Index: Integer;
    begin
        if RecordRef1.Number = RecordRef2.Number then begin
            for Index := 1 to RecordRef1.FieldCount do
                if RecordRef1.FieldIndex(Index).Value <> RecordRef2.FieldIndex(Index).Value then
                    exit(true);
            exit(false);
        end;
        exit(false);
    end;


    internal procedure SetOnlyUpdatePriceOn()
    begin
        OnlyUpdatePrice := true;
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="Code">Parameter of type Code[20].</param>
    internal procedure SetShop(Code: Code[20])
    begin
        if (Shop.Code <> Code) then begin
            Clear(Shop);
            Shop.Get(Code);
            SetShop(Shop);
        end;
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    internal procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        Shop := ShopifyShop;
        ProductApi.SetShop(Shop);
        VariantApi.SetShop(Shop);
        ProductPriceCalc.SetShop(Shop);
    end;

    /// <summary> 
    /// Update Product Data.
    /// </summary>
    /// <param name="ProductId">Parameter of type BigInteger.</param>
    local procedure UpdateProductData(ProductId: BigInteger)
    var
        Item: Record Item;
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        TempShopifyProduct: Record "Shpfy Product" temporary;
        ShopifyVariant: Record "Shpfy Variant";
        TempCurrVariant: Record "Shpfy Variant" temporary;
        RecordRef1: RecordRef;
        RecordRef2: RecordRef;
        VariantAction: Option " ",Create,Update;
    begin
        if ShopifyProduct.Get(ProductId) and Item.GetBySystemId(ShopifyProduct."Item SystemId") then begin
            case Shop."Action for Removed Products" of
                Shop."Action for Removed Products"::StatusToArchived:
                    if Item.Blocked and (ShopifyProduct.Status = ShopifyProduct.Status::Archived) then begin
                        SkippedRecord.LogSkippedRecord(ShopifyProduct.Id, Item.RecordId, ItemIsArchivedLbl, Shop);
                        exit;
                    end;
                Shop."Action for Removed Products"::StatusToDraft:
                    if Item.Blocked and (ShopifyProduct.Status = ShopifyProduct.Status::Draft) then begin
                        SkippedRecord.LogSkippedRecord(ShopifyProduct.Id, Item.RecordId, ItemIsDraftLbl, Shop);
                        exit;
                    end;
                Shop."Action for Removed Products"::DoNothing:
                    if Item.Blocked then begin
                        SkippedRecord.LogSkippedRecord(ShopifyProduct.Id, Item.RecordId, ItemIsBlockedLbl, Shop);
                        exit;
                    end;
            end;
            TempShopifyProduct := ShopifyProduct;
            FillInProductFields(Item, ShopifyProduct);
            RecordRef1.GetTable(ShopifyProduct);
            RecordRef2.GetTable(TempShopifyProduct);
            if HasChange(RecordRef1, RecordRef2) then begin
                ShopifyProduct."Last Updated by BC" := CurrentDateTime;
                ProductApi.UpdateProduct(ShopifyProduct, TempShopifyProduct);
                ShopifyProduct.Modify();
            end;
            ShopifyVariant.SetRange("Product Id", ProductId);
            if ShopifyVariant.FindSet(false) then
                repeat
                    if not IsNullGuid(ShopifyVariant."Item SystemId") then
                        if Item.GetBySystemId(ShopifyVariant."Item SystemId") then begin
                            Clear(ItemVariant);
                            if not IsNullGuid((ShopifyVariant."Item Variant SystemId")) then
                                if ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId") then;
                            Clear(ItemUnitofMeasure);
                            if Shop."UoM as Variant" then begin
                                case ShopifyVariant."UoM Option Id" of
                                    1:
                                        if ItemUnitofMeasure.Get(Item."No.", ShopifyVariant."Option 1 Value") then
                                            ;
                                    2:
                                        if ItemUnitofMeasure.Get(Item."No.", ShopifyVariant."Option 2 Value") then
                                            ;
                                    3:
                                        if ItemUnitofMeasure.Get(Item."No.", ShopifyVariant."Option 3 Value") then
                                            ;
                                end;
                                UpdateProductVariant(ShopifyVariant, Item, ItemVariant, ItemUnitofMeasure, TempCurrVariant);
                            end else
                                UpdateProductVariant(ShopifyVariant, Item, ItemVariant, TempCurrVariant);
                        end;
                until ShopifyVariant.Next() = 0;
            ItemVariant.SetRange("Item No.", Item."No.");
            ItemUnitofMeasure.SetRange("Item No.", Item."No.");
            if ItemVariant.FindSet(false) then
                repeat
                    VariantAction := VariantAction::" ";
                    Clear(ShopifyVariant);
                    ShopifyVariant.SetRange("Product Id", ProductId);
                    ShopifyVariant.SetRange("Item Variant SystemId", ItemVariant.SystemId);
                    if Shop."UoM as Variant" then begin
                        if ItemUnitofMeasure.FindSet(false) then
                            repeat
                                ShopifyVariant.SetRange("Option 2 Name", Shop."Option Name for UoM");
                                ShopifyVariant.SetRange("Option 2 Value", ItemUnitofMeasure.Code);
                                if ShopifyVariant.FindFirst() then begin
                                    VariantAction := VariantAction::Update;
                                    ShopifyVariant.SetRange("Option 2 Name");
                                    ShopifyVariant.SetRange("Option 2 Value");
                                end else begin
                                    ShopifyVariant.SetRange("Option 2 Name");
                                    ShopifyVariant.SetRange("Option 2 Value");
                                    ShopifyVariant.SetRange("Option 1 Name", Shop."Option Name for UoM");
                                    ShopifyVariant.SetRange("Option 1 Value", ItemUnitofMeasure.Code);
                                    if ShopifyVariant.FindFirst() then begin
                                        VariantAction := VariantAction::Update;
                                        ShopifyVariant.SetRange("Option 1 Name");
                                        ShopifyVariant.SetRange("Option 1 Value");
                                    end else begin
                                        ShopifyVariant.SetRange("Option 1 Name");
                                        ShopifyVariant.SetRange("Option 1 Value");
                                        ShopifyVariant.SetRange("Option 3 Name", Shop."Option Name for UoM");
                                        ShopifyVariant.SetRange("Option 3 Value", ItemUnitofMeasure.Code);
                                        if ShopifyVariant.FindFirst() then begin
                                            VariantAction := VariantAction::Update;
                                            ShopifyVariant.SetRange("Option 3 Name");
                                            ShopifyVariant.SetRange("Option 3 Value");
                                        end else begin
                                            ShopifyVariant.SetRange("Option 3 Name");
                                            ShopifyVariant.SetRange("Option 3 Value");
                                            VariantAction := VariantAction::Create;
                                        end;
                                    end;
                                end;
                                case VariantAction of
                                    VariantAction::Create:
                                        CreateProductVariant(ProductId, Item, ItemVariant, ItemUnitofMeasure);
                                    VariantAction::Update:
                                        UpdateProductVariant(ShopifyVariant, Item, ItemVariant, ItemUnitofMeasure, TempCurrVariant);
                                end;
                            until ItemUnitofMeasure.Next() = 0;
                    end else
                        if ShopifyVariant.FindFirst() then
                            UpdateProductVariant(ShopifyVariant, Item, ItemVariant, TempCurrVariant)
                        else
                            CreateProductVariant(ProductId, Item, ItemVariant, TempShopifyProduct);
                until ItemVariant.Next() = 0
            else begin
                Clear(ShopifyVariant);
                ShopifyVariant.SetRange("Product Id", ProductId);
                ShopifyVariant.SetRange("Item Variant SystemId");
                if Shop."UoM as Variant" then
                    if ItemUnitofMeasure.FindSet(false) then
                        repeat
                            ShopifyVariant.SetRange("Option 1 Name", Shop."Option Name for UoM");
                            ShopifyVariant.SetRange("Option 1 Value", ItemUnitofMeasure.Code);
                            if ShopifyVariant.FindFirst() then begin
                                VariantAction := VariantAction::Update;
                                ShopifyVariant.SetRange("Option 1 Name");
                                ShopifyVariant.SetRange("Option 1 Value");
                            end else begin
                                ShopifyVariant.SetRange("Option 1 Name");
                                ShopifyVariant.SetRange("Option 1 Value");
                                ShopifyVariant.SetRange("Option 2 Name", Shop."Option Name for UoM");
                                ShopifyVariant.SetRange("Option 2 Value", ItemUnitofMeasure.Code);
                                if ShopifyVariant.FindFirst() then begin
                                    VariantAction := VariantAction::Update;
                                    ShopifyVariant.SetRange("Option 2 Name");
                                    ShopifyVariant.SetRange("Option 2 Value");
                                end else begin
                                    ShopifyVariant.SetRange("Option 2 Name");
                                    ShopifyVariant.SetRange("Option 2 Value");
                                    ShopifyVariant.SetRange("Option 3 Name", Shop."Option Name for UoM");
                                    ShopifyVariant.SetRange("Option 3 Value", ItemUnitofMeasure.Code);
                                    if ShopifyVariant.FindFirst() then begin
                                        VariantAction := VariantAction::Update;
                                        ShopifyVariant.SetRange("Option 3 Name");
                                        ShopifyVariant.SetRange("Option 3 Value");
                                    end else begin
                                        ShopifyVariant.SetRange("Option 3 Name");
                                        ShopifyVariant.SetRange("Option 3 Value");
                                        VariantAction := VariantAction::Create;
                                    end;
                                end;
                            end;
                            case VariantAction of
                                VariantAction::Create:
                                    CreateProductVariant(ProductId, Item, ItemUnitofMeasure);
                                VariantAction::Update:
                                    UpdateProductVariant(ShopifyVariant, Item, ItemUnitofMeasure, TempCurrVariant);
                            end;
                        until ItemUnitofMeasure.Next() = 0;
            end;

            if not TempCurrVariant.IsEmpty() then
                VariantApi.UpdateProductVariants(TempCurrVariant);

            if Shop."Product Metafields To Shopify" then
                UpdateMetafields(ShopifyProduct.Id);
            UpdateProductTranslations(ShopifyProduct.Id, Item)
        end;
    end;

    local procedure UpdateMetafields(ProductId: BigInteger)
    var
        ShpfyVariant: Record "Shpfy Variant";
        Metafields: Codeunit "Shpfy Metafields";
    begin
        if OnlyUpdatePrice then
            exit;

        ProductEvents.OnBeforeUpdateProductMetafields(ProductId);

        Metafields.SyncMetafieldsToShopify(Database::"Shpfy Product", ProductId, Shop.Code);

        ShpfyVariant.SetRange("Product Id", ProductId);
        ShpfyVariant.ReadIsolation := IsolationLevel::ReadCommitted;
        if ShpfyVariant.FindSet() then
            repeat
                Metafields.SyncMetafieldsToShopify(Database::"Shpfy Variant", ShpfyVariant.Id, Shop.Code);
            until ShpfyVariant.Next() = 0;
    end;

    /// <summary> 
    /// Updates a product variant in Shopify. Used when item variant does not exist in BC, but variants per UoM are maintained in Shopify.
    /// </summary>
    /// <param name="ShopifyVariant">Shopify variant to update.</param>
    /// <param name="Item">Item where information is taken from.</param>
    /// <param name="ItemUnitofMeasure">Item unit of measure where information is taken from.</param>
    local procedure UpdateProductVariant(ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemUnitofMeasure: Record "Item Unit of Measure"; var TempCurrVariant: Record "Shpfy Variant" temporary)
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
    begin
        Clear(TempShopifyVariant);
        TempShopifyVariant := ShopifyVariant;
        FillInProductVariantData(ShopifyVariant, Item, ItemUnitofMeasure);
        if OnlyUpdatePrice then
            VariantApi.UpdateProductPrice(ShopifyVariant, TempShopifyVariant, BulkOperationInput, GraphQueryList, RecordCount, JRequestData)
        else
            if TempCurrVariant.Get(ShopifyVariant.Id) then begin
                TempCurrVariant := ShopifyVariant;
                TempCurrVariant.Modify();
            end else begin
                TempCurrVariant := ShopifyVariant;
                TempCurrVariant.Insert();
            end;
    end;

    /// <summary> 
    /// Updates a Product Variant in Shopify. Used when variants per UoM are not maintained in Shopify.
    /// </summary>
    /// <param name="ShopifyVariant">Parameter of type Record "Shopify Variant".</param>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    local procedure UpdateProductVariant(var ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemVariant: Record "Item Variant"; var TempCurrVariant: Record "Shpfy Variant" temporary)
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
    begin
        Clear(TempShopifyVariant);
        TempShopifyVariant := ShopifyVariant;
        FillInProductVariantData(ShopifyVariant, Item, ItemVariant);
        if OnlyUpdatePrice then
            VariantApi.UpdateProductPrice(ShopifyVariant, TempShopifyVariant, BulkOperationInput, GraphQueryList, RecordCount, JRequestData)
        else
            if TempCurrVariant.Get(ShopifyVariant.Id) then begin
                TempCurrVariant := ShopifyVariant;
                TempCurrVariant.Modify();
            end else begin
                TempCurrVariant := ShopifyVariant;
                TempCurrVariant.Insert();
            end;
    end;

    /// <summary> 
    /// Update a Product Variant in Shopify. Used when item variant exists in BC and variants per UoM are maintained in Shopify.
    /// </summary>
    /// <param name="ShopifyVariant">Parameter of type Record "Shopify Variant".</param>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    /// <param name="ItemUnitofMeasure">Parameter of type Record "Item Unit of Measure".</param>
    local procedure UpdateProductVariant(ShopifyVariant: Record "Shpfy Variant"; Item: Record Item; ItemVariant: Record "Item Variant"; ItemUnitofMeasure: Record "Item Unit of Measure"; var TempCurrVariant: Record "Shpfy Variant" temporary)
    var
        TempShopifyVariant: Record "Shpfy Variant" temporary;
    begin
        Clear(TempShopifyVariant);
        TempShopifyVariant := ShopifyVariant;
        FillInProductVariantData(ShopifyVariant, Item, ItemVariant, ItemUnitofMeasure);
        if OnlyUpdatePrice then
            VariantApi.UpdateProductPrice(ShopifyVariant, TempShopifyVariant, BulkOperationInput, GraphQueryList, RecordCount, JRequestData)
        else
            if TempCurrVariant.Get(ShopifyVariant.Id) then begin
                TempCurrVariant := ShopifyVariant;
                TempCurrVariant.Modify();
            end else begin
                TempCurrVariant := ShopifyVariant;
                TempCurrVariant.Insert();
            end;
    end;

    local procedure RevertVariantChanges(VariantId: BigInteger)
    var
        ShopifyVariant: Record "Shpfy Variant";
        JRequest: JsonToken;
        JVariant: JsonObject;
    begin
        foreach JRequest in JRequestData do begin
            JVariant := JRequest.AsObject();
            if JVariant.GetBigInteger('id') = VariantId then begin
                if ShopifyVariant.Get(VariantId) then begin
                    ShopifyVariant.Price := JVariant.GetDecimal('price');
                    ShopifyVariant."Compare at Price" := JVariant.GetDecimal('compareAtPrice');
                    ShopifyVariant."Updated At" := JVariant.GetDateTime('updatedAt');
                    ShopifyVariant."Unit Cost" := JVariant.GetDecimal('unitCost');
                    ShopifyVariant.Modify();
                end;
                exit;
            end;
        end;
    end;

    #region Translations
    internal procedure UpdateProductTranslations(ProductId: BigInteger; Item: Record Item)
    var
        TempTranslation: Record "Shpfy Translation" temporary;
        TranslationAPI: Codeunit "Shpfy Translation API";
    begin
        if OnlyUpdatePrice then
            exit;

        TempTranslation."Resource Type" := TempTranslation."Resource Type"::Product;
        TempTranslation."Resource ID" := ProductId;

        CollectTranslations(Item, TempTranslation, TempTranslation."Resource Type");
        TranslationAPI.CreateOrUpdateTranslations(TempTranslation);
    end;

    local procedure CollectTranslations(RecVariant: Variant; var TempTranslation: Record "Shpfy Translation" temporary; ICreateTranslation: Interface "Shpfy ICreate Translation")
    var
        ShopifyLanguage: Record "Shpfy Language";
        TranslationAPI: Codeunit "Shpfy Translation API";
        Digests: Dictionary of [Text, Text];
    begin
        ShopifyLanguage.SetRange("Shop Code", Shop.Code);
        ShopifyLanguage.SetRange("Sync Translations", true);
        if ShopifyLanguage.IsEmpty() then
            exit;

        Digests := TranslationAPI.RetrieveTranslatableContentDigests(TempTranslation."Resource Type", TempTranslation."Resource ID");

        if ShopifyLanguage.FindSet() then
            repeat
                ICreateTranslation.CreateTranslation(RecVariant, ShopifyLanguage, TempTranslation, Digests);
            until ShopifyLanguage.Next() = 0;
    end;
    #endregion

    #region Shopify Product Options as Item/Variant Attributes 
    /// <summary> 
    /// Checks if item/item variant attributes marked as "As Option" are compatible to be used as product options in Shopify.
    /// </summary>  
    /// <param name="Item">The item to check.</param>
    /// <returns>True if the item attributes are compatible, false otherwise.</returns>
    internal procedure CheckItemAttributesCompatibleForProductOptions(Item: Record Item): Boolean
    var
        ItemAttributeIds: List of [Integer];
        SkippedReason: Text[250];
        TooManyAttributesAsOptionErr: Label 'Item %1 has %2 attributes marked as "As Option". Shopify supports a maximum of 3 product options.', Comment = '%1 = Item No., %2 = Number of attributes';
        DuplicateOptionCombinationErr: Label 'Item %1 has duplicate item variant attribute value combinations. Each variant must have a unique combination of option values.', Comment = '%1 = Item No.';
    begin
        if Shop."UoM as Variant" then
            exit(true);

        GetItemAttributeIDsMarkedAsOption(Item, ItemAttributeIds);

        if ItemAttributeIds.Count() = 0 then
            exit(true);

        if ItemAttributeIds.Count() > 3 then begin
            SkippedRecord.LogSkippedRecord(Item.RecordId, StrSubstNo(TooManyAttributesAsOptionErr, Item."No.", ItemAttributeIds.Count()), Shop);
            exit(false);
        end;

        if CheckMissingItemAttributeValues(Item, ItemAttributeIds, SkippedReason) then begin
            SkippedRecord.LogSkippedRecord(Item.RecordId, SkippedReason, Shop);
            exit(false);
        end;

        if CheckProductOptionDuplicatesExists(Item, ItemAttributeIds) then begin
            SkippedRecord.LogSkippedRecord(Item.RecordId, StrSubstNo(DuplicateOptionCombinationErr, Item."No."), Shop);
            exit(false);
        end;

        exit(true);
    end;

    internal procedure GetItemAttributeIDsMarkedAsOption(Item: Record Item; var ItemAttributeIds: List of [Integer])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.SetLoadFields("Item Attribute ID");
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", Item."No.");
        if ItemAttributeValueMapping.FindSet() then
            repeat
                if ItemAttribute.Get(ItemAttributeValueMapping."Item Attribute ID") then
                    if (not ItemAttribute.Blocked) and (ItemAttribute."Shpfy Incl. in Product Sync" = ItemAttribute."Shpfy Incl. in Product Sync"::"As Option") then
                        if not ItemAttributeIds.Contains(ItemAttribute.ID) then
                            ItemAttributeIds.Add(ItemAttribute.ID);
            until ItemAttributeValueMapping.Next() = 0;
    end;

    local procedure CheckProductOptionDuplicatesExists(Item: Record Item; ItemAttributeIds: List of [Integer]): Boolean
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemVariant: Record "Item Variant";
        ItemVarAttrValueMapping: Record "Item Var. Attr. Value Mapping";
        VariantCombinations: Dictionary of [Text, Code[10]];
        CombinationKey: Text;
        VariantCode: Code[10];
        AttributeId: Integer;
        CombinationKeyTok: Label '%1:%2|', Locked = true, Comment = '%1 = Attribute ID, %2 = Attribute Value';
    begin
        ItemVariant.SetRange("Item No.", Item."No.");
        if not ItemVariant.FindSet() then
            exit(false);

        repeat
            VariantCode := ItemVariant.Code;

            CombinationKey := '';
            foreach AttributeId in ItemAttributeIds do begin
                ItemVarAttrValueMapping.SetRange("Item No.", Item."No.");
                ItemVarAttrValueMapping.SetRange("Variant Code", VariantCode);
                ItemVarAttrValueMapping.SetRange("Item Attribute ID", AttributeId);
                if ItemVarAttrValueMapping.FindFirst() then
                    if ItemAttributeValue.Get(ItemVarAttrValueMapping."Item Attribute ID", ItemVarAttrValueMapping."Item Attribute Value ID") then
                        CombinationKey += StrSubstNo(CombinationKeyTok, ItemAttributeValue."Attribute ID", ItemAttributeValue.Value);
            end;

            if CombinationKey <> '' then
                if VariantCombinations.ContainsKey(CombinationKey) then
                    exit(true)
                else
                    VariantCombinations.Add(CombinationKey, VariantCode);
        until ItemVariant.Next() = 0;
    end;

    local procedure CheckMissingItemAttributeValues(Item: Record Item; ItemAttributeIds: List of [Integer]; var SkippedReason: Text[250]): Boolean
    var
        ItemAttribute: Record "Item Attribute";
        ItemVariant: Record "Item Variant";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVarAttrValueMapping: Record "Item Var. Attr. Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
        AttributeId: Integer;
        MissingVariantCode: Code[10];
        MissingAttributeName: Text[250];
        MissingAttributeErr: Label 'Item %1 Variant %2 is missing an attribute "%3". All item variants must have must have item attributes marked as "As Option".', Comment = '%1 = Item No., %2 = Variant Code, %3 = Attribute Name';
        MissingItemAttributeValueErr: Label 'Item %1 is missing a value for attribute "%2". Item must have values for attributes marked as "As Option".', Comment = '%1 = Item No., %2 = Attribute Name';
        MissingItemVarAttributeValueErr: Label 'Item %1 Variant %2 is missing a value for attribute "%3". All item variants must have values for attributes marked as "As Option".', Comment = '%1 = Item No., %2 = Variant Code, %3 = Attribute Name';
    begin
        ItemVariant.SetRange("Item No.", Item."No.");
        if ItemVariant.FindSet() then
            repeat
                foreach AttributeId in ItemAttributeIds do begin
                    ItemVarAttrValueMapping.SetRange("Item No.", Item."No.");
                    ItemVarAttrValueMapping.SetRange("Variant Code", ItemVariant.Code);
                    ItemVarAttrValueMapping.SetRange("Item Attribute ID", AttributeId);
                    if not ItemVarAttrValueMapping.FindFirst() then begin
                        MissingVariantCode := ItemVariant.Code;
                        if ItemAttribute.Get(AttributeId) then
                            MissingAttributeName := ItemAttribute.Name;
                        SkippedReason := StrSubstNo(MissingAttributeErr, Item."No.", MissingVariantCode, MissingAttributeName);
                        exit(true);
                    end else
                        if ItemAttributeValue.Get(ItemVarAttrValueMapping."Item Attribute ID", ItemVarAttrValueMapping."Item Attribute Value ID") then
                            if ItemAttributeValue.Value = '' then begin
                                MissingVariantCode := ItemVariant.Code;
                                if ItemAttribute.Get(AttributeId) then
                                    MissingAttributeName := ItemAttribute.Name;
                                SkippedReason := StrSubstNo(MissingItemVarAttributeValueErr, Item."No.", MissingVariantCode, MissingAttributeName);
                                exit(true);
                            end;
                end;
            until ItemVariant.Next() = 0
        else
            foreach AttributeId in ItemAttributeIds do begin
                ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
                ItemAttributeValueMapping.SetRange("No.", Item."No.");
                ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeId);
                if ItemAttributeValueMapping.FindFirst() then
                    if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                        if ItemAttributeValue.Value = '' then begin
                            if ItemAttribute.Get(AttributeId) then
                                MissingAttributeName := ItemAttribute.Name;
                            SkippedReason := StrSubstNo(MissingItemAttributeValueErr, Item."No.", MissingAttributeName);
                            exit(true);
                        end;
            end;
    end;

    /// <summary> 
    /// Fills product options for Shopify variants based on item attributes marked as "As Option".
    /// </summary>
    /// <param name="Item">The item to process.</param>
    /// <param name="TempShopifyVariant">Parameter of Shopify Variants to fill.</param>
    /// <param name="TempShopifyProduct">Parameter of Shopify Product.</param>
    internal procedure FillProductOptionsForShopifyVariants(Item: Record Item; var TempShopifyVariant: Record "Shpfy Variant" temporary; var TempShopifyProduct: Record "Shpfy Product" temporary)
    var
        ItemVariant: Record "Item Variant";
        ItemAttributeIds: List of [Integer];
        VariantCode: Code[10];
    begin
        if Shop."UoM as Variant" then
            exit;

        GetItemAttributeIDsMarkedAsOption(Item, ItemAttributeIds);

        if ItemAttributeIds.Count() = 0 then
            exit;

        if TempShopifyVariant.FindSet() then
            repeat
                VariantCode := '';
                if not IsNullGuid(TempShopifyVariant."Item Variant SystemId") then
                    if ItemVariant.GetBySystemId(TempShopifyVariant."Item Variant SystemId") then
                        VariantCode := ItemVariant.Code;

                FillProductOptionsFromItemAttributes(Item."No.", VariantCode, ItemAttributeIds, TempShopifyVariant);
                TempShopifyVariant.Modify(false);
            until TempShopifyVariant.Next() = 0;

        TempShopifyProduct."Has Variants" := true;
    end;

    local procedure FillProductOptionsFromItemAttributes(ItemNo: Code[20]; VariantCode: Code[10]; ItemAttributeIds: List of [Integer]; var TempShopifyVariant: Record "Shpfy Variant" temporary)
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVarAttrValueMapping: Record "Item Var. Attr. Value Mapping";
        OptionIndex: Integer;
        AttributeId: Integer;
    begin
        OptionIndex := 1;
        foreach AttributeId in ItemAttributeIds do
            if ItemAttribute.Get(AttributeId) then begin
                if VariantCode <> '' then begin
                    ItemVarAttrValueMapping.SetRange("Item No.", ItemNo);
                    ItemVarAttrValueMapping.SetRange("Variant Code", VariantCode);
                    ItemVarAttrValueMapping.SetRange("Item Attribute ID", AttributeId);
                    if ItemVarAttrValueMapping.FindFirst() then
                        if ItemAttributeValue.Get(ItemVarAttrValueMapping."Item Attribute ID", ItemVarAttrValueMapping."Item Attribute Value ID") then
                            AssignProductOptionValues(TempShopifyVariant, OptionIndex, ItemAttribute.Name, ItemAttributeValue.Value);
                end else begin
                    ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
                    ItemAttributeValueMapping.SetRange("No.", ItemNo);
                    ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeId);
                    if ItemAttributeValueMapping.FindFirst() then
                        if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                            AssignProductOptionValues(TempShopifyVariant, OptionIndex, ItemAttribute.Name, ItemAttributeValue.Value);
                end;
                OptionIndex += 1;
            end;
    end;

    local procedure AssignProductOptionValues(var TempShopifyVariant: Record "Shpfy Variant" temporary; OptionIndex: Integer; AttributeName: Text[250]; AttributeValue: Text[250])
    begin
        case OptionIndex of
            1:
                begin
                    TempShopifyVariant."Option 1 Name" := CopyStr(AttributeName, 1, MaxStrLen(TempShopifyVariant."Option 1 Name"));
                    TempShopifyVariant."Option 1 Value" := CopyStr(AttributeValue, 1, MaxStrLen(TempShopifyVariant."Option 1 Value"));
                end;
            2:
                begin
                    TempShopifyVariant."Option 2 Name" := CopyStr(AttributeName, 1, MaxStrLen(TempShopifyVariant."Option 2 Name"));
                    TempShopifyVariant."Option 2 Value" := CopyStr(AttributeValue, 1, MaxStrLen(TempShopifyVariant."Option 2 Value"));
                end;
            3:
                begin
                    TempShopifyVariant."Option 3 Name" := CopyStr(AttributeName, 1, MaxStrLen(TempShopifyVariant."Option 3 Name"));
                    TempShopifyVariant."Option 3 Value" := CopyStr(AttributeValue, 1, MaxStrLen(TempShopifyVariant."Option 3 Value"));
                end;
        end;
    end;


    /// <summary> 
    /// Validates item attributes and prepares temporary Shopify variant by assigning product option values from Item/Item Variant.
    /// </summary>
    /// <param name="TempShopifyVariant">Parameter of type Record "Shpfy Variant" temporary.</param>
    /// <param name="Item">Parameter of type Record Item.</param>   
    /// <param name="ItemVariant">Parameter of type Record "Item Variant".</param>
    /// <param name="ShopifyProductId">Parameter of type BigInteger.</param>
    internal procedure ValidateItemAttributesAsProductOptionsForNewVariant(var TempShopifyVariant: Record "Shpfy Variant" temporary; Item: Record Item; ItemVariantCode: Code[10]; ShopifyProductId: BigInteger): Boolean
    var
        ProductOptions: Dictionary of [Integer, Text];
        ExistingProductOptionValues: Dictionary of [Text, Text];
        ProductOptionIndex: Integer;
    begin
        if Shop."UoM as Variant" then
            exit(true);

        CollectExistingProductVariantOptionValues(ProductOptions, ExistingProductOptionValues, ShopifyProductId);

        for ProductOptionIndex := 1 to ProductOptions.Count() do
            if not AssignProductOptionValuesToTempProductVariant(TempShopifyVariant, Item, ItemVariantCode, ProductOptions, ProductOptionIndex) then
                exit(false);

        if not CheckProductOptionsCombinationUnique(TempShopifyVariant, ExistingProductOptionValues, Item, ItemVariantCode) then
            exit(false);

        exit(true);
    end;

    local procedure CollectExistingProductVariantOptionValues(var ProductOptions: Dictionary of [Integer, Text]; var ExistingProductOptionValues: Dictionary of [Text, Text]; ShopifyProductId: BigInteger)
    var
        ShopifyVariant: Record "Shpfy Variant";
        ItemAttribute: Record "Item Attribute";
        CombinationKey: Text;
    begin
        ShopifyVariant.SetAutoCalcFields("Variant Code");
        ShopifyVariant.SetRange("Product Id", ShopifyProductId);
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
        KeyPartTok: Label '%1:%2|', Locked = true, Comment = '%1 = Option Name, %2 = Option Value';
    begin
        if Option1Name <> '' then
            CombinationKey += StrSubstNo(KeyPartTok, Option1Name, Option1Value);
        if Option2Name <> '' then
            CombinationKey += StrSubstNo(KeyPartTok, Option2Name, Option2Value);
        if Option3Name <> '' then
            CombinationKey += StrSubstNo(KeyPartTok, Option3Name, Option3Value);

        exit(CombinationKey);
    end;

    local procedure AssignProductOptionValuesToTempProductVariant(var TempShopifyVariant: Record "Shpfy Variant" temporary; Item: Record "Item"; ItemVariantCode: Code[10]; ProductOptions: Dictionary of [Integer, Text]; ProductOptionIndex: Integer): Boolean
    var
        ItemVariant: Record "Item Variant";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVarAttrValueMapping: Record "Item Var. Attr. Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemWithoutRequiredAttributeErr: Label 'Item %1 cannot be added as a product variant because it does not have required attributes.', Comment = '%1 = Item No.';
        ItemWithoutRequiredAttributeValueErr: Label 'Item %1 cannot be added as a product variant because it does not have a value for the required attributes.', Comment = '%1 = Item No.';
        ItemVariantWithoutRequiredAttributeErr: Label 'Item Variant %1 cannot be added as a product variant because it does not have required attributes.', Comment = '%1 = Item No.';
        ItemVariantWithoutRequiredAttributeValueErr: Label 'Item Variant %1 cannot be added as a product variant because it does not have a value for the required attributes.', Comment = '%1 = Item No.';
    begin
        ItemVariant.SetRange("Item No.", Item."No.");
        ItemVariant.SetRange("Code", ItemVariantCode);
        if ItemVariant.FindFirst() then begin
            ItemVarAttrValueMapping.SetRange("Item No.", Item."No.");
            ItemVarAttrValueMapping.SetRange("Variant Code", ItemVariant."Code");
            ItemVarAttrValueMapping.SetRange("Item Attribute ID", ProductOptions.Keys.Get(ProductOptionIndex));
            if ItemVarAttrValueMapping.FindFirst() then begin
                if ItemAttributeValue.Get(ItemVarAttrValueMapping."Item Attribute ID", ItemVarAttrValueMapping."Item Attribute Value ID") then begin
                    ItemAttributeValue.CalcFields("Attribute Name");
                    AssignProductOptionValues(TempShopifyVariant, ProductOptionIndex, ItemAttributeValue."Attribute Name", ItemAttributeValue.Value);
                end else begin
                    SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(ItemVariantWithoutRequiredAttributeValueErr, Item."No."), Shop);
                    exit(false);
                end;
            end else begin
                SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(ItemVariantWithoutRequiredAttributeErr, Item."No."), Shop);
                exit(false);
            end;
        end else begin
            ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
            ItemAttributeValueMapping.SetRange("No.", Item."No.");
            ItemAttributeValueMapping.SetRange("Item Attribute ID", ProductOptions.Keys.Get(ProductOptionIndex));
            if ItemAttributeValueMapping.FindFirst() then begin
                if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then begin
                    ItemAttributeValue.CalcFields("Attribute Name");
                    AssignProductOptionValues(TempShopifyVariant, ProductOptionIndex, ItemAttributeValue."Attribute Name", ItemAttributeValue.Value);
                end else begin
                    SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(ItemWithoutRequiredAttributeValueErr, Item."No."), Shop);
                    exit(false);
                end;
            end else begin
                SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(ItemWithoutRequiredAttributeErr, Item."No."), Shop);
                exit(false);
            end;
        end;

        exit(true);
    end;

    local procedure CheckProductOptionsCombinationUnique(var TempShopifyVariant: Record "Shpfy Variant" temporary; ExistingProductOptionValues: Dictionary of [Text, Text]; Item: Record "Item"; ItemVariantCode: Code[10]): Boolean
    var
        ItemVariant: Record "Item Variant";
        CombinationKey: Text;
        DuplicateItemCombinationErr: Label 'Item %1 cannot be added as a product variant because another variant already has the same option values.', Comment = '%1 = Item No.';
        DuplicateItemVarCombinationErr: Label 'Item %1 cannot be added as a product variant because another variant already has the same option values.', Comment = '%1 = Item No.';
    begin
        CombinationKey := BuildCombinationKey(
            TempShopifyVariant."Option 1 Name", TempShopifyVariant."Option 1 Value",
            TempShopifyVariant."Option 2 Name", TempShopifyVariant."Option 2 Value",
            TempShopifyVariant."Option 3 Name", TempShopifyVariant."Option 3 Value");

        if ExistingProductOptionValues.ContainsKey(CombinationKey) then begin
            if ItemVariant.Get(Item."No.", ItemVariantCode) then
                SkippedRecord.LogSkippedRecord(ItemVariant.RecordId(), StrSubstNo(DuplicateItemVarCombinationErr, Item."No."), Shop)
            else
                SkippedRecord.LogSkippedRecord(Item.RecordId(), StrSubstNo(DuplicateItemCombinationErr, Item."No."), Shop);
            exit(false);
        end;

        exit(true);
    end;
    #endregion
}
