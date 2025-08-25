// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;
using System.Environment;

/// <summary>
/// Codeunit Shpfy Variant Image Export (ID 30413).
/// </summary>
codeunit 30413 "Shpfy Variant Image Export"
{
    Access = Internal;
    Permissions = tabledata Item = r;
    TableNo = "Shpfy Variant";

    trigger OnRun()
    var
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        Product: Record "Shpfy Product";
        HashCalc: Codeunit "Shpfy Hash";
        NewImageId: BigInteger;
        Hash: Integer;
        ImageExists: Boolean;
        JRequest: JsonObject;
        ItemAsVariant: Boolean;
        PictureGuid: Guid;
    begin
        if this.Shop."Sync Item Images" <> this.Shop."Sync Item Images"::"To Shopify" then
            exit;

        if Rec."Item Variant SystemId" <> this.NullGuid then begin
            if ItemVariant.GetBySystemId(Rec."Item Variant SystemId") then
                Hash := HashCalc.CalcItemVariantImageHash(ItemVariant);
        end else begin
            Product.Get(Rec."Product Id");
            if Rec."Item SystemId" <> Product."Item SystemId" then
                if Item.GetBySystemId(Rec."Item SystemId") then begin
                    Hash := HashCalc.CalcItemImageHash(Item);
                    ItemAsVariant := true;
                end;
        end;

        if (Hash = Rec."Image Hash") then
            exit;

        PictureGuid := GetPictureGuid(Item, ItemVariant, ItemAsVariant);

        if Rec."Image Id" <> 0 then begin
            ImageExists := this.VariantApi.CheckShopifyVariantImageExists(Rec.Id);
            if not ImageExists then
                Rec."Image Id" := 0;
        end;

        if not ImageExists then begin
            NewImageId := VariantApi.CreateShopifyVariantImage(Rec, PictureGuid);

            if NewImageId <> Rec."Image Id" then
                Rec."Image Id" := NewImageId;
            Rec."Image Hash" := Hash;
            Rec.Modify(false);
        end else begin
            NewImageId := VariantApi.UpdateShopifyVariantImage(Rec, PictureGuid, this.CurrRecordCount, this.VariantImageUrls);
            JRequest.Add('id', Rec.Id);
            JRequest.Add('imageHash', Rec."Image Hash");
            this.JRequestData.Add(JRequest);
            Rec."Image Id" := NewImageId;
            Rec."Image Hash" := Hash;
            Rec.Modify(false);
        end;
    end;

    var
        Shop: Record "Shpfy Shop";
        ProductApi: Codeunit "Shpfy Product API";
        VariantApi: Codeunit "Shpfy Variant API";
        CurrRecordCount: Integer;
        NullGuid: Guid;
        ParametersList: List of [Dictionary of [Text, Text]];
        VariantImageUrls: Dictionary of [BigInteger, Text];
        BulkOperationInput: TextBuilder;
        JRequestData: JsonArray;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="Code">Parameter of type Code[20].</param>
    internal procedure SetShop(Code: Code[20])
    begin
        if (this.Shop.Code <> Code) then begin
            Clear(this.Shop);
            this.Shop.Get(Code);
            this.SetShop(this.Shop);
        end;
    end;

    /// <summary> 
    /// Set Shop.
    /// </summary>
    /// <param name="ShopifyShop">Parameter of type Record "Shopify Shop".</param>
    internal procedure SetShop(ShopifyShop: Record "Shpfy Shop")
    begin
        this.Shop := ShopifyShop;
        this.ProductApi.SetShop(this.Shop);
        this.VariantApi.SetShop(this.Shop);
    end;

    /// <summary>
    /// Set Record Count.
    /// </summary>
    /// <param name="RecordCount">Parameter of type Integer.</param>
    internal procedure SetRecordCount(RecordCount: Integer)
    begin
        this.CurrRecordCount := RecordCount;
    end;

    /// <summary>
    /// Get Bulk Operation Input.
    /// </summary>
    /// <returns>TextBuilder type containing the bulk operation input.</returns>
    internal procedure GetBulkOperationInput(): TextBuilder
    begin
        exit(this.BulkOperationInput);
    end;

    /// <summary>
    /// Get variant ids together with resource urls in Shopify.
    /// </summary>
    /// <returns>Dictionary of pairs of variant ids and resource urls.</returns>
    internal procedure GetVariantImageUrls(): Dictionary of [BigInteger, Text]
    begin
        exit(this.VariantImageUrls);
    end;

    local procedure GetPictureGuid(Item: Record Item; ItemVariant: Record "Item Variant"; ItemAsVariant: Boolean): Guid
    begin
        if ItemAsVariant then begin
            if Item.Picture.Count > 0 then
                exit(Item.Picture.Item(1));
        end else
            if ItemVariant.Picture.Count > 0 then
                exit(ItemVariant.Picture.Item(1));
    end;

    local procedure UpdateShopifyVariantImage(Variant: Record "Shpfy Variant"; PictureGuid: Guid): BigInteger
    var
        TenantMedia: Record "Tenant Media";
        NewImageId: BigInteger;
    begin
        if TenantMedia.Get(PictureGuid) then begin
            NewImageId := this.ProductApi.AddImageToProduct(Variant."Product Id", TenantMedia);
            this.VariantApi.SetVariantImage(Variant, NewImageId);
            exit(NewImageId);
        end;
    end;
}