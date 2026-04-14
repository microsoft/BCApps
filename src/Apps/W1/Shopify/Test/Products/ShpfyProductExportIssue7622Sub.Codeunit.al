// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;

codeunit 139614 "Shpfy Product Export 7622 Sub"
{
    EventSubscriberInstance = Manual;

    var
        ProductVariantCreateCount: Integer;
        LastCreatedVariantId: BigInteger;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", 'OnClientSend', '', true, false)]
    local procedure OnClientSend(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    begin
        MakeResponse(HttpRequestMessage, HttpResponseMessage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", 'OnGetContent', '', true, false)]
    local procedure OnGetContent(HttpResponseMessage: HttpResponseMessage; var Response: Text)
    begin
        HttpResponseMessage.Content.ReadAs(Response);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Product Events", 'OnBeforeSendAddShopifyProductVariant', '', true, false)]
    local procedure OnBeforeSendAddShopifyProductVariant(ShopifyShop: Record "Shpfy Shop"; var ShopifyVariant: Record "Shpfy Variant")
    begin
        ProductVariantCreateCount += 1;
    end;

    local procedure MakeResponse(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    var
        Uri: Text;
        GraphQlQuery: Text;
    begin
        if HttpRequestMessage.Method <> 'POST' then
            exit;

        Uri := HttpRequestMessage.GetRequestUri();
        if not Uri.EndsWith('/graphql.json') then
            exit;

        if not HttpRequestMessage.Content.ReadAs(GraphQlQuery) then
            exit;

        case true of
            GraphQlQuery.Contains('productVariantsBulkCreate('):
                HttpResponseMessage := GetProductVariantCreateResponse();
            GraphQlQuery.Contains('productVariantsBulkUpdate('):
                HttpResponseMessage := GetProductVariantUpdateResponse();
            GraphQlQuery.Contains('productUpdate(product:'):
                HttpResponseMessage := GetProductUpdateResponse();
            else
                HttpResponseMessage := GetDefaultGraphQlResponse();
        end;
    end;

    local procedure GetProductVariantCreateResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
        Body: Text;
    begin
        LastCreatedVariantId += 1;
        if LastCreatedVariantId = 1 then
            LastCreatedVariantId := 900001;

        Body := StrSubstNo('{"data":{"productVariantsBulkCreate":{"productVariants":[{"legacyResourceId":%1,"createdAt":"2026-01-01T00:00:00Z","updatedAt":"2026-01-01T00:00:00Z"}],"userErrors":[]}}}', LastCreatedVariantId);
        HttpResponseMessage.Content.WriteFrom(Body);
        exit(HttpResponseMessage);
    end;

    local procedure GetProductVariantUpdateResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
        Body: Text;
    begin
        Body := '{"data":{"productVariantsBulkUpdate":{"productVariants":[],"userErrors":[]}}}';
        HttpResponseMessage.Content.WriteFrom(Body);
        exit(HttpResponseMessage);
    end;

    local procedure GetProductUpdateResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
        Body: Text;
    begin
        Body := '{"data":{"productUpdate":{"product":{"id":"gid://shopify/Product/1","onlineStoreUrl":"","onlineStorePreviewUrl":"","updatedAt":"2026-01-01T00:00:00Z"},"userErrors":[]}}}';
        HttpResponseMessage.Content.WriteFrom(Body);
        exit(HttpResponseMessage);
    end;

    local procedure GetDefaultGraphQlResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
    begin
        HttpResponseMessage.Content.WriteFrom('{"data":{}}');
        exit(HttpResponseMessage);
    end;

    internal procedure ResetCounters()
    begin
        ProductVariantCreateCount := 0;
        LastCreatedVariantId := 0;
    end;

    internal procedure GetProductVariantCreateCount(): Integer
    begin
        exit(ProductVariantCreateCount);
    end;
}
