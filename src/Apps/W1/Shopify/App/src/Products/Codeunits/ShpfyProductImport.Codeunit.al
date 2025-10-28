// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Product Import (ID 30180).
/// </summary>
codeunit 30180 "Shpfy Product Import"
{
    Access = Internal;
    trigger OnRun()
    var
        CreateItem: Codeunit "Shpfy Create Item";
        ProductMapping: Codeunit "Shpfy Product Mapping";
        UpdateItem: Codeunit "Shpfy Update Item";
        NullGuid: Guid;
        ItemCreated: Boolean;
    begin
        if ShopifyProduct.Id = 0 then
            exit;

        Clear(ShopifyVariant);
        ShopifyVariant.SetRange("Product Id", ShopifyProduct.Id);
        if ShopifyVariant.FindSet() then
            repeat
                if ProductMapping.FindMapping(ShopifyProduct, ShopifyVariant) then begin
                    if Shop."Shopify Can Update Items" then begin
                        UpdateItem.SetShop(Shop);
                        UpdateItem.Run(ShopifyVariant);
                    end;
                end else
                    if Shop."Auto Create Unknown Items" then begin
                        CreateItem.SetShop(Shop);
                        Clear(ShopifyVariant);
                        ShopifyVariant.SetRange("Product Id", ShopifyProduct.Id);
                        ShopifyVariant.SetRange("Item Variant SystemId", NullGuid);
                        if ShopifyVariant.FindSet() then
                            repeat
                                Commit();
                                ItemCreated := CreateItem.Run(ShopifyVariant);
                                SetProductConflict(ShopifyProduct.Id, ItemCreated);
                            until ShopifyVariant.Next() = 0;
                    end else
                        if CreateNewItem then
                            SetProductConflict(ShopifyProduct.Id, false, AutoCreateUnknownItemsDisabledErr);
            until ShopifyVariant.Next() = 0;
    end;

    var
        ShopifyInventoryItem: Record "Shpfy Inventory Item";
        ShopifyProduct: Record "Shpfy Product";
        Shop: Record "Shpfy Shop";
        ShopifyVariant: Record "Shpfy Variant";
        ProductApi: Codeunit "Shpfy Product API";
        VariantApi: Codeunit "Shpfy Variant API";
        CreateNewItem: Boolean;
        AutoCreateUnknownItemsDisabledErr: Label 'Auto Create Unknown Item must be enabled and an Item Template must be selected for the shop.';

    /// <summary> 
    /// Get Product.
    /// </summary>
    /// <param name="ShopifyProductResult">Parameter of type Record "Shopify Product".</param>
    internal procedure GetProduct(var ShopifyProductResult: Record "Shpfy Product")
    begin
        ShopifyProductResult := ShopifyProduct;
    end;

    /// <summary> 
    /// Set Product.
    /// </summary>
    /// <param name="Id">Parameter of type BigInteger.</param>
    internal procedure SetProduct(Id: BigInteger)
    var
        VariantId: BigInteger;
        VariantIds: Dictionary of [BigInteger, DateTime];
    begin
        if Id <> 0 then begin
            Clear(ShopifyProduct);
            ShopifyProduct.SetRange(Id, Id);
            if not ShopifyProduct.FindFirst() then begin
                ShopifyProduct.Id := Id;
                ShopifyProduct."Shop Code" := Shop.Code;
                ShopifyProduct.Insert(false);
            end;

            if ShopifyProduct."Shop Code" <> Shop.Code then begin
                ShopifyProduct."Shop Code" := Shop.Code;
                ShopifyProduct.Modify(true);
            end;

            if ProductApi.RetrieveShopifyProduct(ShopifyProduct) then begin
                VariantApi.RetrieveShopifyProductVariantIds(ShopifyProduct, VariantIds);
                ShopifyVariant.SetRange("Product Id", Id);
                foreach VariantId in VariantIds.Keys do begin
                    if not ShopifyVariant.Get(VariantId) then begin
                        ShopifyVariant.Init();
                        ShopifyVariant.Id := VariantId;
                        ShopifyVariant."Product Id" := Id;
                        ShopifyVariant."Shop Code" := ShopifyProduct."Shop Code";
                        ShopifyVariant.Insert(false);
                    end;
                    ShopifyInventoryItem.SetRange("Variant Id", VariantId);
                    if not ShopifyInventoryItem.FindSet() then
                        Clear(ShopifyInventoryItem);
                    if not VariantApi.RetrieveShopifyVariant(ShopifyProduct, ShopifyVariant, ShopifyInventoryItem) then
                        ShopifyVariant.Delete();
                end;
            end else
                ShopifyProduct.Delete();
        end;
    end;

    /// <summary> 
    /// Set Product.
    /// </summary>
    /// <param name="Product">Parameter of type Record "Shopify Product".</param>
    internal procedure SetProduct(Product: Record "Shpfy Product")
    begin
        SetProduct(Product.Id);
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="Code">Parameter of type Code[20].</param>
    internal procedure SetShop(Code: Code[20])
    begin
        Clear(Shop);
        Shop.Get(Code);
        SetShop(Shop);
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
    end;

    local procedure SetProductConflict(ProductId: BigInteger; ItemCreated: Boolean)
    begin
        SetProductConflict(ProductId, ItemCreated, '');
    end;

    local procedure SetProductConflict(ProductId: BigInteger; ItemCreated: Boolean; ErrorMessage: Text)
    var
        Product: Record "Shpfy Product";
    begin
        Product.Get(ProductId);
        if ItemCreated and not Product."Has Error" then
            exit;

        if not ItemCreated then begin
            Product.Validate("Has Error", true);

            if ErrorMessage = '' then
                ErrorMessage := GetLastErrorText();
            Product.Validate("Error Message", CopyStr(Format(Time) + ' ' + ErrorMessage, 1, MaxStrLen(Product."Error Message")));
        end else begin
            Product.Validate("Has Error", false);
            Product.Validate("Error Message", '');
        end;
        Product.Modify(true);
    end;

    internal procedure SetCreateNewItem(Value: Boolean)
    begin
        CreateNewItem := Value;
    end;
}