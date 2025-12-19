// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

using Microsoft.Inventory.Item;

/// <summary>
/// Codeunit Shpfy Variant Image Export (ID 30413).
/// </summary>
codeunit 30456 "Shpfy Variant Image Export"
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
        if Shop."Sync Item Images" <> Shop."Sync Item Images"::"To Shopify" then
            exit;

        if Rec."Item Variant SystemId" <> NullGuid then begin
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
            ImageExists := VariantApi.CheckShopifyVariantImageExists(Rec.Id);
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
            NewImageId := VariantApi.UpdateShopifyVariantImage(Rec, PictureGuid, CurrRecordCount, VariantImageUrls);
            JRequest.Add('id', Rec.Id);
            JRequest.Add('imageHash', Rec."Image Hash");
            JRequestData.Add(JRequest);
            if NewImageId <> 0 then
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
        VariantImageUrls: Dictionary of [BigInteger, Text];
        JRequestData: JsonArray;

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
    end;

    /// <summary>
    /// Set Record Count.
    /// </summary>
    /// <param name="RecordCount">Parameter of type Integer.</param>
    internal procedure SetRecordCount(RecordCount: Integer)
    begin
        CurrRecordCount := RecordCount;
    end;

    /// <summary>
    /// Get Request Data required to potenatial bulk operation revert.
    /// </summary>
    /// <returns>JsonArray with request data.</returns>
    internal procedure GetRequestData(): JsonArray
    begin
        exit(JRequestData);
    end;

    /// <summary>
    /// Get variant ids together with resource urls in Shopify.
    /// </summary>
    /// <returns>Dictionary of pairs of variant ids and resource urls.</returns>
    internal procedure GetVariantImageUrls(): Dictionary of [BigInteger, Text]
    begin
        exit(VariantImageUrls);
    end;

    local procedure GetPictureGuid(Item: Record Item; ItemVariant: Record "Item Variant"; ItemAsVariant: Boolean): Guid
    begin
        if ItemAsVariant then begin
            if Item.Picture.Count() > 0 then
                exit(Item.Picture.Item(1));
        end else
            if ItemVariant.Picture.Count() > 0 then
                exit(ItemVariant.Picture.Item(1));
    end;
}
