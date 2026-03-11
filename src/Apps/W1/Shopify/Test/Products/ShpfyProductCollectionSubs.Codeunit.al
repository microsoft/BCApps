// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139555 "Shpfy Product Collection Subs."
{
    EventSubscriberInstance = Manual;

    var
        PublishProductGraphQueryTxt: Text;
        ProductCreateGraphQueryTxt: Text;
        JEdges: JsonArray;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", OnClientSend, '', true, false)]
    local procedure OnClientSend(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    begin
        MakeResponse(HttpRequestMessage, HttpResponseMessage);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Shpfy Communication Events", OnGetContent, '', true, false)]
    local procedure OnGetContent(HttpResponseMessage: HttpResponseMessage; var Response: Text)
    begin
        HttpResponseMessage.Content.ReadAs(Response);
    end;

    local procedure MakeResponse(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    var
        GQLProductCollections: Codeunit "Shpfy GQL CustProdCollections";
        Uri: Text;
        GraphQlQuery: Text;
        PublishProductTok: Label '{"query":"mutation {publishablePublish(id: \"gid://shopify/Product/', locked = true;
        ProductCreateTok: Label '{"query":"mutation {productCreate(', locked = true;
        VariantCreateTok: Label '{"query":"mutation { productVariantsBulkCreate(', locked = true;
        GraphQLCmdTok: Label '/graphql.json', Locked = true;
    begin
        case HttpRequestMessage.Method of
            'POST':
                begin
                    Uri := HttpRequestMessage.GetRequestUri();
                    if Uri.EndsWith(GraphQLCmdTok) then
                        if HttpRequestMessage.Content.ReadAs(GraphQlQuery) then
                            case true of
                                GraphQlQuery.Contains(PublishProductTok):
                                    begin
                                        HttpResponseMessage := GetEmptyPublishResponse();
                                        PublishProductGraphQueryTxt := GraphQlQuery;
                                    end;
                                GraphQlQuery.Contains(ProductCreateTok):
                                    begin
                                        HttpResponseMessage := GetCreateProductResponse();
                                        ProductCreateGraphQueryTxt := GraphQlQuery;
                                    end;
                                GraphQlQuery = GQLProductCollections.GetGraphQL():
                                    HttpResponseMessage := GetProductCollectionsResponse();
                                GraphQlQuery.Contains(VariantCreateTok):
                                    HttpResponseMessage := GetCreatedVariantResponse();
                            end;
                end;
        end;
    end;

    local procedure GetEmptyPublishResponse(): HttpResponseMessage;
    var
        HttpResponseMessage: HttpResponseMessage;
        BodyTxt: Text;
        ResInStream: InStream;
        ResponseFilePathTok: Label 'Products/EmptyPublishResponse.txt', Locked = true;
    begin
        NavApp.GetResource(ResponseFilePathTok, ResInStream, TextEncoding::UTF8);
        ResInStream.ReadText(BodyTxt);
        HttpResponseMessage.Content.WriteFrom(BodyTxt);
        exit(HttpResponseMessage);
    end;

    local procedure GetCreateProductResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
        BodyTxt: Text;
        ResInStream: InStream;
        ResponseFilePathTok: Label 'Products/CreatedProductResponse.txt', Locked = true;
    begin
        NavApp.GetResource(ResponseFilePathTok, ResInStream, TextEncoding::UTF8);
        ResInStream.ReadText(BodyTxt);
        HttpResponseMessage.Content.WriteFrom(BodyTxt);
        exit(HttpResponseMessage);
    end;

    local procedure GetCreatedVariantResponse(): HttpResponseMessage;
    var
        Any: Codeunit Any;
        NewVariantId: BigInteger;
        HttpResponseMessage: HttpResponseMessage;
        BodyTxt: Text;
        ResInStream: InStream;
        responseFilePathTok: Label 'Products/CreatedVariantResponse.txt', Locked = true;
    begin
        Any.SetDefaultSeed();
        NewVariantId := Any.IntegerInRange(100000, 999999);
        NavApp.GetResource(responseFilePathTok, ResInStream, TextEncoding::UTF8);
        ResInStream.ReadText(BodyTxt);
        HttpResponseMessage.Content.WriteFrom(StrSubstNo(BodyTxt, NewVariantId));
        exit(HttpResponseMessage);
    end;

    local procedure GetProductCollectionsResponse(): HttpResponseMessage
    var
        HttpResponseMessage: HttpResponseMessage;
        BodyTxt: Text;
        EdgesTxt: Text;
        GetProductCollectionsResponseTok: Label '{ "data": { "collections": { "edges": %1 } }}', Locked = true;
    begin
        JEdges.WriteTo(EdgesTxt);
        BodyTxt := StrSubstNo(GetProductCollectionsResponseTok, EdgesTxt);
        HttpResponseMessage.Content.WriteFrom(BodyTxt);
        exit(HttpResponseMessage);
    end;

    internal procedure GetPublishProductGraphQueryTxt(): Text
    begin
        exit(PublishProductGraphQueryTxt);
    end;

    internal procedure GetProductCreateGraphQueryTxt(): Text
    begin
        exit(ProductCreateGraphQueryTxt);
    end;

    internal procedure SetJEdges(NewJEdges: JsonArray)
    begin
        JEdges := NewJEdges;
    end;
}