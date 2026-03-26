// ------------------------------------------------------------------------------------------------
// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information.
// ------------------------------------------------------------------------------------------------

namespace OpenSource.Shopify.ExternalURL;

using Microsoft.Integration.Shopify;
using Microsoft.Inventory.Item;

codeunit 50102 "Shpfy External URL Sub."
{
    Access = Internal;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", OnBeforeUpdateProductMetafields, '', false, false)]
    local procedure OnBeforeUpdateProductMetafields(ProductId: BigInteger)
    var
        Product: Record "Shpfy Product";
        Variant: Record "Shpfy Variant";
        Shop: Record "Shpfy Shop";
        Item: Record Item;
        ItemVariant: Record "Item Variant";
        ExternalURL: Codeunit "Shpfy External URL";
        ItemNo: Code[20];
        VariantCode: Code[10];
    begin
        if not Product.Get(ProductId) then
            exit;

        if not Shop.Get(Product."Shop Code") then
            exit;

        if Shop."Product URL Template" = '' then
            exit;

        if Item.GetBySystemId(Product."Item SystemId") then
            ItemNo := Item."No."
        else
            ItemNo := '';

        Variant.SetRange("Product Id", ProductId);
        if Variant.FindSet() then
            repeat
                VariantCode := '';
                if not IsNullGuid(Variant."Item Variant SystemId") then
                    if ItemVariant.GetBySystemId(Variant."Item Variant SystemId") then
                        VariantCode := ItemVariant.Code;

                ExternalURL.UpdateVariantExternalURL(Variant, Product, ItemNo, VariantCode, Shop);
            until Variant.Next() = 0;
    end;
}
