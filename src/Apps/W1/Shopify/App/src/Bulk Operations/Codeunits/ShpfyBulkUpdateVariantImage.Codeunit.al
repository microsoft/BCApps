// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify;

codeunit 30450 "Shpfy Bulk UpdateVariantImage" implements "Shpfy IBulk Operation"
{
    Access = Internal;

    var
        NameLbl: Label 'Update variant image';

    procedure GetGraphQL(): Text
    begin
        exit('mutation call($productId: ID!, $variants: [ProductVariantsBulkInput!]!) { productVariantsBulkUpdate(productId: $productId, variants: $variants) { productVariants {id media(first: 1, reverse: true) { edges { node { id }}}}, userErrors {field, message}}}');
    end;

    procedure GetInput(): Text
    begin
        exit('{ "productId": "gid://shopify/Product/%1", "variants": [{ "id": "gid://shopify/ProductVariant/%2", "mediaId": "gid://shopify/MediaImage/%3" }]}')
    end;

    procedure GetName(): Text[250]
    begin
        exit(NameLbl);
    end;

    procedure GetType(): Text
    begin
        exit('mutation');
    end;

    procedure RevertFailedRequests(var BulkOperation: Record "Shpfy Bulk Operation")
    begin
        exit; // No implementation needed for this operation
    end;

    procedure RevertAllRequests(var BulkOperation: Record "Shpfy Bulk Operation")
    var
        Variant: Record "Shpfy Variant";
        JRequestData: JsonArray;
        JRequest: JsonToken;
        JVariant: JsonObject;
    begin
        JRequestData := BulkOperation.GetRequestData();
        foreach JRequest in JRequestData do begin
            JVariant := JRequest.AsObject();
            if Variant.Get(JVariant.GetBigInteger('id')) then begin
                Variant."Image Hash" := JVariant.GetInteger('imageHash');
                Variant.Modify(false);
            end;
        end;
    end;
}
