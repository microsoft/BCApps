// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

/// <summary>
/// Codeunit Shpfy Sync Product Image (ID 30184).
/// </summary>
codeunit 30184 "Shpfy Sync Product Image"
{
    Access = Internal;
    TableNo = "Shpfy Shop";

    trigger OnRun()
    begin
        SetShop(Rec);
        case Shop."Sync Item Images" of
            Shop."Sync Item Images"::"To Shopify":
                ExportImages();
            Shop."Sync Item Images"::"From Shopify":
                ImportImages();
        end;
    end;

    var
        Shop: Record "Shpfy Shop";
        ProductImageExport: Codeunit "Shpfy Product Image Export";
        ProductEvents: Codeunit "Shpfy Product Events";
        VariantImageExport: Codeunit "Shpfy Variant Image Export";
        ProductFilter: Text;

    /// <summary> 
    /// Export Images.
    /// </summary>
    local procedure ExportImages()
    var
        ShopifyProduct: Record "Shpfy Product";
        ProductAPI: Codeunit "Shpfy Product API";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        BulkOperationType: Enum "Shpfy Bulk Operation Type";
        BulkOperationInput: TextBuilder;
        JRequestData: JsonArray;
        ParametersList: List of [Dictionary of [Text, Text]];
        Parameters: Dictionary of [Text, Text];
    begin
        ShopifyProduct.SetRange("Shop Code", Shop.Code);
        if ProductFilter <> '' then
            ShopifyProduct.SetFilter(Id, ProductFilter);
        ProductImageExport.SetRecordCount(ShopifyProduct.Count());
        if ShopifyProduct.FindSet() then
            repeat
                Commit();
                if ProductImageExport.Run(ShopifyProduct) then;
                ExportVariantsImages(ShopifyProduct.Id);
            until ShopifyProduct.Next() = 0;
        BulkOperationInput := ProductImageExport.GetBulkOperationInput();
        JRequestData := ProductImageExport.GetRequestData();
        if BulkOperationInput.Length > 0 then
            if not BulkOperationMgt.SendBulkMutation(Shop, BulkOperationType::UpdateProductImage, BulkOperationInput.ToText(), JRequestData) then begin
                ParametersList := ProductImageExport.GetParametersList();
                foreach Parameters in ParametersList do
                    if not ProductAPI.UpdateProductImage(Parameters) then
                        RevertProductImageChanges(Parameters.Get('ProductId'), JRequestData);
            end;
    end;

    local procedure ExportVariantsImages(ProductId: BigInteger)
    var
        ShopifyVariant: Record "Shpfy Variant";
        ProductApi: Codeunit "Shpfy Product API";
        VariantApi: Codeunit "Shpfy Variant API";
        BulkOperationMgt: Codeunit "Shpfy Bulk Operation Mgt.";
        IBulkOperation: Interface "Shpfy IBulk Operation";
        VariantImageUrls: Dictionary of [BigInteger, Text];
        VariantImageIds: Dictionary of [BigInteger, BigInteger];
        BulkOperationInput: TextBuilder;
        JRequestData: JsonArray;
        VariantId: BigInteger;
    begin
        ShopifyVariant.SetRange("Shop Code", Shop.Code);
        ShopifyVariant.SetRange("Product Id", ProductId);
        VariantImageExport.SetRecordCount(ShopifyVariant.Count());
        if ShopifyVariant.FindSet() then
            repeat
                if VariantImageExport.Run(ShopifyVariant) then;
            until ShopifyVariant.Next() = 0;
        VariantImageUrls := VariantImageExport.GetVariantImageUrls();
        if VariantImageUrls.Count() > 0 then begin
            IBulkOperation := Enum::"Shpfy Bulk Operation Type"::UpdateVariantImage;
            VariantImageIds := ProductApi.UpdateProductWithMultipleVariantImages(ProductId, VariantImageUrls);
            foreach VariantId in VariantImageIds.Keys() do
                BulkOperationInput.AppendLine(StrSubstNo(IBulkOperation.GetInput(), ProductId, VariantId, VariantImageIds.Get(VariantId)));
            JRequestData := VariantImageExport.GetRequestData();
            if not BulkOperationMgt.SendBulkMutation(Shop, Enum::"Shpfy Bulk Operation Type"::UpdateVariantImage, BulkOperationInput.ToText(), JRequestData) then
                foreach VariantId in VariantImageIds.Keys() do
                    if not VariantApi.SetVariantImage(ProductId, VariantId, VariantImageIds.Get(VariantId)) then
                        RevertVariantImageChanges(VariantId, JRequestData);
        end;
    end;

    /// <summary> 
    /// Import Images.
    /// </summary>
    local procedure ImportImages()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ShopifyProduct: Record "Shpfy Product";
        ShopifyVariant: Record "Shpfy Variant";
        ProductApi: Codeunit "Shpfy Product API";
        VariantApi: Codeunit "Shpfy Variant API";
        ImageId: BigInteger;
        Id: BigInteger;
        UpdatedItems: List of [Guid];
        ProductImages: Dictionary of [BigInteger, Dictionary of [BigInteger, Text]];
        ProductImageData: Dictionary of [BigInteger, Text];
        VariantImages: Dictionary of [BigInteger, Dictionary of [BigInteger, Text]];
        VariantImageData: Dictionary of [BigInteger, Text];
    begin
        ProductApi.SetShop(Shop);
        ProductApi.RetrieveShopifyProductImages(ProductImages);
        foreach Id in ProductImages.Keys do
            if ShopifyProduct.Get(Id) and Item.GetBySystemId(ShopifyProduct."Item SystemId") then begin
                ProductImageData := ProductImages.Get(Id);
                foreach ImageId in ProductImageData.Keys do
                    if ImageId <> ShopifyProduct."Image Id" then
                        if UpdateItemImage(Item, ProductImageData.Get(ImageId)) then begin
                            UpdatedItems.Add(Item.SystemId);
                            ShopifyProduct."Image Id" := ImageId;
                            ShopifyProduct.Modify();
                        end;
            end;

        VariantApi.SetShop(Shop);
        VariantApi.RetrieveShopifyProductVariantImages(VariantImages);
        foreach Id in VariantImages.Keys do
            if ShopifyVariant.Get(Id) then
                case true of
                    ItemVariant.GetBySystemId(ShopifyVariant."Item Variant SystemId"):
                        begin
                            VariantImageData := VariantImages.Get(Id);
                            if VariantImageData.Keys.Count() > 0 then
                                foreach ImageId in VariantImageData.Keys() do
                                    if ImageId <> ShopifyVariant."Image Id" then
                                        if UpdateItemVariantImage(ItemVariant, VariantImageData.Get(ImageId)) then begin
                                            ShopifyVariant."Image Id" := ImageId;
                                            ShopifyVariant.Modify(false);
                                        end;
                        end;
                    (Item.GetBySystemId(ShopifyVariant."Item SystemId")):
                        begin
                            ShopifyProduct.Get(ShopifyVariant."Product Id");
                            if ShopifyProduct."Item SystemId" = ShopifyVariant."Item SystemId" then
                                continue
                            else
                                Item.GetBySystemId(ShopifyVariant."Item SystemId");

                            VariantImageData := VariantImages.Get(Id);
                            if VariantImageData.Keys.Count() > 0 then
                                foreach ImageId in VariantImageData.Keys() do
                                    if ImageId <> ShopifyVariant."Image Id" then
                                        if UpdateItemImage(Item, VariantImageData.Get(ImageId)) then begin
                                            UpdatedItems.Add(Item.SystemId);
                                            ShopifyVariant."Image Id" := ImageId;
                                            ShopifyVariant.Modify(false);
                                        end;
                        end;
                end;
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    internal procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        Shop := ShopifyShop;
        ProductImageExport.SetShop(Shop);
        VariantImageExport.SetShop(Shop);
    end;

    /// <summary> 
    /// Update Item Image.
    /// </summary>
    /// <param name="Item">Parameter of type Record Item.</param>
    /// <param name="ImageUrl">Parameter of type Text.</param>
    /// <returns>Return value of type Boolean.</returns>
    local procedure UpdateItemImage(Item: Record Item; ImageUrl: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        InStream: InStream;
    begin
        if HttpClient.Get(ImageUrl, HttpResponseMessage) then begin
            HttpResponseMessage.Content.ReadAs(InStream);
            Clear(Item.Picture);
            Item.Picture.ImportStream(InStream, Item.Description);
            Item.Modify(true);
            ProductEvents.OnAfterUpdateItemPicture(Item, ImageUrl, InStream);
            exit(true);
        end;
    end;

    local procedure UpdateItemVariantImage(ItemVariant: Record "Item Variant"; ImageUrl: Text): Boolean
    var
        HttpClient: HttpClient;
        HttpResponseMessage: HttpResponseMessage;
        InStream: InStream;
    begin
        if HttpClient.Get(ImageUrl, HttpResponseMessage) then begin
            HttpResponseMessage.Content.ReadAs(InStream);
            Clear(ItemVariant.Picture);
            ItemVariant.Picture.ImportStream(InStream, ItemVariant.Description);
            ItemVariant.Modify(true);
            ProductEvents.OnAfterUpdateItemVariantPicture(ItemVariant, ImageUrl, InStream);
            exit(true);
        end;
    end;

    internal procedure SetProductFilter(FilterText: Text)
    begin
        ProductFilter := FilterText;
    end;

    local procedure RevertProductImageChanges(ProductId: Text; JRequestData: JsonArray)
    var
        Product: Record "Shpfy Product";
        JRequest: JsonToken;
        JProduct: JsonObject;
    begin
        foreach JRequest in JRequestData do begin
            JProduct := JRequest.AsObject();
            if Format(JProduct.GetBigInteger('id')) = ProductId then begin
                if Product.Get(JProduct.GetBigInteger('id')) then begin
                    Product."Image Hash" := JProduct.GetInteger('imageHash');
                    Product.Modify(false);
                end;
                exit;
            end;
        end;
    end;

    local procedure RevertVariantImageChanges(VariantId: BigInteger; JRequestData: JsonArray)
    var
        Variant: Record "Shpfy Variant";
        JRequest: JsonToken;
        JVariant: JsonObject;
    begin
        foreach JRequest in JRequestData do begin
            JVariant := JRequest.AsObject();
            if Format(JVariant.GetBigInteger('id')) = Format(VariantId) then begin
                if Variant.Get(JVariant.GetBigInteger('id')) then begin
                    Variant."Image Hash" := JVariant.GetInteger('imageHash');
                    Variant.Modify(false);
                end;
                exit;
            end;
        end;
    end;
}