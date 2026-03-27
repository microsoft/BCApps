// ------------------------------------------------------------------------------------------------
// This file is licensed under the MIT License.
// See the LICENSE file in the project root for more information.
// ------------------------------------------------------------------------------------------------

namespace OpenSource.Shopify.ExternalURL;

using Microsoft.Integration.Shopify;

codeunit 50101 "Shpfy External URL"
{
    Access = Internal;

    procedure ResolveProductURL(Variant: Record "Shpfy Variant"; Product: Record "Shpfy Product"; ItemNo: Code[20]; VariantCode: Code[10]; Shop: Record "Shpfy Shop"): Text
    var
        Url: Text;
    begin
        // Priority 1: Per-variant override
        if Variant."Product URL" <> '' then
            exit(Variant."Product URL");

        // Priority 2: Template from shop
        if Shop."Product URL Template" <> '' then begin
            Url := Shop."Product URL Template";
            Url := Url.Replace('{item-no}', ItemNo);
            Url := Url.Replace('{variant-code}', VariantCode);
            Url := Url.Replace('{sku}', Variant.SKU);
            Url := Url.Replace('{barcode}', Variant.Barcode);
            Url := Url.Replace('{shopify-product-id}', Format(Product.Id));
            Url := Url.Replace('{shopify-variant-id}', Format(Variant.Id));
            exit(Url);
        end;

        exit('');
    end;

    procedure UpdateVariantExternalURL(Variant: Record "Shpfy Variant"; Product: Record "Shpfy Product"; ItemNo: Code[20]; VariantCode: Code[10]; Shop: Record "Shpfy Shop")
    var
        Metafield: Record "Shpfy Metafield";
        ResolvedUrl: Text;
    begin
        ResolvedUrl := ResolveProductURL(Variant, Product, ItemNo, VariantCode, Shop);
        if (ResolvedUrl = '') or (Variant.Id = 0) then
            exit;

        Metafield.SetRange("Parent Table No.", Database::"Shpfy Variant");
        Metafield.SetRange("Owner Id", Variant.Id);
        Metafield.SetRange(Namespace, 'shopify');
        Metafield.SetRange(Name, 'external_url');
        if Metafield.FindFirst() then begin
            if Metafield.Value <> CopyStr(ResolvedUrl, 1, MaxStrLen(Metafield.Value)) then begin
                Metafield.Value := CopyStr(ResolvedUrl, 1, MaxStrLen(Metafield.Value));
                Metafield.Modify(true);
            end;
        end else begin
            Metafield.Init();
            Metafield."Parent Table No." := Database::"Shpfy Variant";
            Metafield."Owner Id" := Variant.Id;
            Metafield.Namespace := 'shopify';
            Metafield.Name := 'external_url';
            Metafield.Value := CopyStr(ResolvedUrl, 1, MaxStrLen(Metafield.Value));
            Metafield.Type := Metafield.Type::url;
            Metafield."Owner Type" := Metafield."Owner Type"::ProductVariant;
            Metafield.Insert(true);
        end;
    end;
}
