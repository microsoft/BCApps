// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;

/// <summary>
/// Codeunit Shpfy Create Product (ID 30174).
/// </summary>
codeunit 30174 "Shpfy Create Product"
{
    Access = Internal;
    Permissions =
        tabledata Item = r,
        tabledata "Item Attribute" = r,
        tabledata "Item Attribute Value" = r,
        tabledata "Item Attribute Value Mapping" = r,
        tabledata "Item Reference" = r,
        tabledata "Item Unit of Measure" = r,
        tabledata "Item Var. Attr. Value Mapping" = r,
        tabledata "Item Variant" = r;
    TableNo = Item;

    var
        Shop: Record "Shpfy Shop";
        ProductApi: Codeunit "Shpfy Product API";
        ProductExport: Codeunit "Shpfy Product Export";
        ProductPriceCalc: Codeunit "Shpfy Product Price Calc.";
        VariantApi: Codeunit "Shpfy Variant API";
        Events: Codeunit "Shpfy Product Events";
        Getlocations: Boolean;
        ProductId: BigInteger;
        ItemVariantIsBlockedLbl: Label 'Item variant is blocked or sales blocked.';

    trigger OnRun()
    var
        ShopifyProduct: Record "Shpfy Product";
    begin
        if Getlocations then begin
            Codeunit.Run(Codeunit::"Shpfy Sync Shop Locations", Shop);
            Commit();
            Getlocations := false;
        end;
        ShopifyProduct.SetRange("Shop Code", Shop.Code);
        ShopifyProduct.SetRange("Item SystemId", Rec.SystemId);
        if ShopifyProduct.IsEmpty then
            CreateProduct(Rec);
    end;

    /// <summary> 
    /// Create Product.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    local procedure CreateProduct(Item: Record Item)
    var
        TempShopifyProduct: Record "Shpfy Product" temporary;
        TempShopifyVariant: Record "Shpfy Variant" temporary;
        TempShopifyTag: Record "Shpfy Tag" temporary;
    begin
        if CheckProductOptionsInaccuraciesExists(Item) then
            exit;

        CreateTempProduct(Item, TempShopifyProduct, TempShopifyVariant, TempShopifyTag);
        if not VariantApi.FindShopifyProductVariant(TempShopifyProduct, TempShopifyVariant) then
            ProductId := ProductApi.CreateProduct(TempShopifyProduct, TempShopifyVariant, TempShopifyTag)
        else
            ProductId := TempShopifyProduct.Id;

        if ProductId <> 0 then
            ProductExport.UpdateProductTranslations(ProductId, Item);
    end;

    internal procedure CreateTempProduct(Item: Record Item; var TempShopifyProduct: Record "Shpfy Product" temporary; var TempShopifyVariant: Record "Shpfy Variant" temporary; var TempShopifyTag: Record "Shpfy Tag" temporary)
    var
        ItemUnitofMeasure: Record "Item Unit of Measure";
        ItemVariant: Record "Item Variant";
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        Id: Integer;
        ICreateProductStatus: Interface "Shpfy ICreateProductStatusValue";
    begin
        Clear(TempShopifyProduct);
        TempShopifyProduct."Shop Code" := Shop.Code;
        TempShopifyProduct."Item SystemId" := Item.SystemId;
        ProductExport.FillInProductFields(Item, TempShopifyProduct);
        ICreateProductStatus := Shop."Status for Created Products";
        TempShopifyProduct.Status := ICreateProductStatus.GetStatus(Item);
        ItemVariant.SetRange("Item No.", Item."No.");
        if ItemVariant.FindSet(false) then
            repeat
                if ItemVariant.Blocked or ItemVariant."Sales Blocked" then
                    SkippedRecord.LogSkippedRecord(ItemVariant.RecordId, ItemVariantIsBlockedLbl, Shop)
                else begin
                    TempShopifyProduct."Has Variants" := true;
                    if Shop."UoM as Variant" then begin
                        ItemUnitofMeasure.SetRange("Item No.", Item."No.");
                        if ItemUnitofMeasure.FindSet(false) then
                            repeat
                                Id += 1;
                                Clear(TempShopifyVariant);
                                TempShopifyVariant.Id := Id;
                                TempShopifyVariant."Available For Sales" := true;
                                TempShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", ItemVariant.Code, ItemUnitofMeasure.Code), 1, MaxStrLen(TempShopifyVariant.Barcode));
                                ProductPriceCalc.CalcPrice(Item, ItemVariant.Code, ItemUnitofMeasure.Code, TempShopifyVariant."Unit Cost", TempShopifyVariant.Price, TempShopifyVariant."Compare at Price");
                                TempShopifyVariant.Title := ItemVariant.Description;
                                TempShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
                                TempShopifyVariant.SKU := GetVariantSKU(TempShopifyVariant.Barcode, Item."No.", ItemVariant.Code, Item."Vendor Item No.");
                                TempShopifyVariant."Tax Code" := Item."Tax Group Code";
                                TempShopifyVariant.Taxable := true;
                                TempShopifyVariant.Weight := ItemUnitofMeasure."Qty. per Unit of Measure" > 0 ? Item."Gross Weight" * ItemUnitofMeasure."Qty. per Unit of Measure" : Item."Gross Weight";
                                TempShopifyVariant."Option 1 Name" := 'Variant';
                                TempShopifyVariant."Option 1 Value" := ItemVariant.Code;
                                TempShopifyVariant."Option 2 Name" := Shop."Option Name for UoM";
                                TempShopifyVariant."Option 2 Value" := ItemUnitofMeasure.Code;
                                TempShopifyVariant."Shop Code" := Shop.Code;
                                TempShopifyVariant."Item SystemId" := Item.SystemId;
                                TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
                                TempShopifyVariant."UoM Option Id" := 2;
                                TempShopifyVariant.Insert(false);
                            until ItemUnitofMeasure.Next() = 0;
                    end else begin
                        Id += 1;
                        Clear(TempShopifyVariant);
                        TempShopifyVariant.Id := Id;
                        TempShopifyVariant."Available For Sales" := true;
                        TempShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", ItemVariant.Code, Item."Sales Unit of Measure"), 1, MaxStrLen(TempShopifyVariant.Barcode));
                        ProductPriceCalc.CalcPrice(Item, ItemVariant.Code, Item."Sales Unit of Measure", TempShopifyVariant."Unit Cost", TempShopifyVariant.Price, TempShopifyVariant."Compare at Price");
                        TempShopifyVariant.Title := ItemVariant.Description;
                        TempShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
                        TempShopifyVariant.SKU := GetVariantSKU(TempShopifyVariant.Barcode, Item."No.", ItemVariant.Code, GetVendorItemNo(Item."No.", ItemVariant.Code, Item."Sales Unit of Measure"));
                        TempShopifyVariant."Tax Code" := Item."Tax Group Code";
                        TempShopifyVariant.Taxable := true;
                        TempShopifyVariant.Weight := Item."Gross Weight";
                        TempShopifyVariant."Option 1 Name" := 'Variant';
                        TempShopifyVariant."Option 1 Value" := ItemVariant.Code;
                        TempShopifyVariant."Shop Code" := Shop.Code;
                        TempShopifyVariant."Item SystemId" := Item.SystemId;
                        TempShopifyVariant."Item Variant SystemId" := ItemVariant.SystemId;
                        TempShopifyVariant.Insert(false);
                    end;
                end;
            until ItemVariant.Next() = 0
        else
            if Shop."UoM as Variant" then begin
                ItemUnitofMeasure.SetRange("Item No.", Item."No.");
                if ItemUnitofMeasure.FindSet(false) then
                    repeat
                        TempShopifyProduct."Has Variants" := true;
                        Id += 1;
                        Clear(TempShopifyVariant);
                        TempShopifyVariant.Id := Id;
                        TempShopifyVariant."Available For Sales" := true;
                        TempShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", '', ItemUnitofMeasure.Code), 1, MaxStrLen(TempShopifyVariant.Barcode));
                        ProductPriceCalc.CalcPrice(Item, '', ItemUnitofMeasure.Code, TempShopifyVariant."Unit Cost", TempShopifyVariant.Price, TempShopifyVariant."Compare at Price");
                        TempShopifyVariant.Title := Item.Description;
                        TempShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
                        TempShopifyVariant.SKU := GetVariantSKU(TempShopifyVariant.Barcode, Item."No.", '', Item."Vendor Item No.");
                        TempShopifyVariant."Tax Code" := Item."Tax Group Code";
                        TempShopifyVariant.Taxable := true;
                        TempShopifyVariant.Weight := ItemUnitofMeasure."Qty. per Unit of Measure" > 0 ? Item."Gross Weight" * ItemUnitofMeasure."Qty. per Unit of Measure" : Item."Gross Weight";
                        TempShopifyVariant."Option 1 Name" := Shop."Option Name for UoM";
                        TempShopifyVariant."Option 1 Value" := ItemUnitofMeasure.Code;
                        TempShopifyVariant."Shop Code" := Shop.Code;
                        TempShopifyVariant."Item SystemId" := Item.SystemId;
                        TempShopifyVariant."UoM Option Id" := 1;
                        TempShopifyVariant.Insert(false);
                    until ItemUnitofMeasure.Next() = 0;
            end else
                CreateTempShopifyVariantFromItem(Item, TempShopifyVariant);

        TempShopifyProduct.Insert(false);
        FillProductOptionsForShopifyVariants(Item, TempShopifyVariant);
        Events.OnAfterCreateTempShopifyProduct(Item, TempShopifyProduct, TempShopifyVariant, TempShopifyTag);
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
    /// Get Vendor Item No.
    /// </summary>
    /// <param name="ItemNo">Parameter of type Code[20].</param>
    /// <param name="VariantCode">Parameter of type Code[10].</param>
    /// <param name="UoM">Parameter of type Code[10].</param>
    /// <returns>Return value of type Code[50].</returns>
    local procedure GetVendorItemNo(ItemNo: Code[20]; VariantCode: Code[10]; UoM: Code[10]): Code[50];
    var
        Item: Record Item;
        ItemReferenceMgt: Codeunit "Shpfy Item Reference Mgt.";
    begin
        if Item.Get(ItemNo) then
            exit(ItemReferenceMgt.GetItemReference(ItemNo, VariantCode, UoM, "Item Reference Type"::Vendor, Item."Vendor No."));
    end;

    local procedure GetVariantSKU(BarCode: Text[50]; ItemNo: Text[20]; VariantCode: Text[10]; VendorItemNo: Text[50]): Text[50]
    begin
        case Shop."SKU Mapping" of
            Shop."SKU Mapping"::"Bar Code":
                exit(BarCode);
            Shop."SKU Mapping"::"Item No.":
                exit(ItemNo);
            Shop."SKU Mapping"::"Variant Code":
                if VariantCode <> '' then
                    exit(VariantCode);
            Shop."SKU Mapping"::"Item No. + Variant Code":
                if VariantCode <> '' then
                    exit(ItemNo + Shop."SKU Field Separator" + VariantCode)
                else
                    exit(ItemNo);
            Shop."SKU Mapping"::"Vendor Item No.":
                exit(VendorItemNo);
        end;
    end;

    /// <summary>
    /// Creates a temporary Shopify variant with information from an item.
    /// </summary>
    /// <param name="Item">The item to create the variant from.</param>
    /// <param name="TempShopifyVariant">The temporary Shopify variant record set where the variant will be inserted.</param>
    internal procedure CreateTempShopifyVariantFromItem(Item: Record Item; var TempShopifyVariant: Record "Shpfy Variant" temporary)
    begin
        Clear(TempShopifyVariant);
        TempShopifyVariant."Available For Sales" := true;
        TempShopifyVariant.Barcode := CopyStr(GetBarcode(Item."No.", '', Item."Sales Unit of Measure"), 1, MaxStrLen(TempShopifyVariant.Barcode));
        ProductPriceCalc.CalcPrice(Item, '', Item."Sales Unit of Measure", TempShopifyVariant."Unit Cost", TempShopifyVariant.Price, TempShopifyVariant."Compare at Price");
        TempShopifyVariant.Title := ''; // Title will be assigned to "Default Title" in Shopify as no Options are set.
        TempShopifyVariant."Inventory Policy" := Shop."Default Inventory Policy";
        TempShopifyVariant.SKU := GetVariantSKU(TempShopifyVariant.Barcode, Item."No.", '', Item."Vendor Item No.");
        TempShopifyVariant."Tax Code" := Item."Tax Group Code";
        TempShopifyVariant.Taxable := true;
        TempShopifyVariant.Weight := Item."Gross Weight";
        TempShopifyVariant."Shop Code" := Shop.Code;
        TempShopifyVariant."Item SystemId" := Item.SystemId;
        TempShopifyVariant.Insert(false);
    end;

    local procedure CheckProductOptionsInaccuraciesExists(var Item: Record Item): Boolean
    var
        SkippedRecord: Codeunit "Shpfy Skipped Record";
        ItemAttributeIds: List of [Integer];
        TooManyAttributesAsOptionErr: Label 'Item %1 has %2 attributes marked as "As Option". Shopify supports a maximum of 3 product options.', Comment = '%1 = Item No., %2 = Number of attributes';
        DuplicateOptionCombinationErr: Label 'Item %1 has duplicate item variant attribute value combinations. Each variant must have a unique combination of option values.', Comment = '%1 = Item No.';
    begin
        if Shop."UoM as Variant" then
            exit(false);

        GetItemAttributeIDsMarkedAsOption(Item, ItemAttributeIds);

        if ItemAttributeIds.Count() > 3 then begin
            SkippedRecord.LogSkippedRecord(Item.RecordId, StrSubstNo(TooManyAttributesAsOptionErr, Item."No.", ItemAttributeIds.Count()), Shop);
            exit(true);
        end;

        if CheckProductOptionDuplicatesExists(Item, ItemAttributeIds) then begin
            SkippedRecord.LogSkippedRecord(Item.RecordId, StrSubstNo(DuplicateOptionCombinationErr, Item."No."), Shop);
            exit(true);
        end;
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
        if ItemVariant.FindSet() then
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

    local procedure FillProductOptionsForShopifyVariants(Item: Record Item; var TempShopifyVariant: Record "Shpfy Variant" temporary)
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
                            AssignOptionValue(TempShopifyVariant, OptionIndex, ItemAttribute.Name, ItemAttributeValue.Value);
                end else begin
                    ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
                    ItemAttributeValueMapping.SetRange("No.", ItemNo);
                    ItemAttributeValueMapping.SetRange("Item Attribute ID", AttributeId);
                    if ItemAttributeValueMapping.FindFirst() then
                        if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                            AssignOptionValue(TempShopifyVariant, OptionIndex, ItemAttribute.Name, ItemAttributeValue.Value);
                end;
                OptionIndex += 1;
            end;
    end;

    local procedure AssignOptionValue(var TempShopifyVariant: Record "Shpfy Variant" temporary; OptionIndex: Integer; AttributeName: Text[250]; AttributeValue: Text[250])
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

    local procedure GetItemAttributeIDsMarkedAsOption(Item: Record Item; var ItemAttributeIds: List of [Integer])
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
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

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="Code">Parameter of type Code[20].</param>
    internal procedure SetShop(Code: Code[20])
    begin
        if (Code <> '') and (Shop.Code <> Code) then begin
            Clear(Shop);
            Shop.Get(Code);
            ProductApi.SetShop(Shop);
            VariantApi.SetShop(Shop);
            ProductPriceCalc.SetShop(Shop);
            ProductExport.SetShop(Shop);
            Getlocations := true;
        end;
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    internal procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        SetShop(ShopifyShop.Code);
    end;

    internal procedure GetProductId(): BigInteger
    begin
        exit(ProductId);
    end;

    internal procedure ChangeDefaultProductLocation(ErrorInfo: ErrorInfo)
    var
        ShpfyShop: Record "Shpfy Shop";
        ShopLocation: Record "Shpfy Shop Location";
    begin
        if ShpfyShop.Get(ErrorInfo.RecordId) then begin
            ShopLocation.SetRange("Shop Code", ShpfyShop.Code);
            Page.Run(Page::"Shpfy Shop Locations Mapping", ShopLocation);
        end;
    end;
}