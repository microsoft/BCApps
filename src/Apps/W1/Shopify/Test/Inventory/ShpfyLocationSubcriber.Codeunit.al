// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;

/// <summary>
/// Codeunit Shpfy Location Subcriber (ID 139587).
/// </summary>
codeunit 139587 "Shpfy Location Subcriber"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        JLocations: JsonObject;
        JLocation: JsonObject;

    internal procedure InitShopifyLocations(Locations: JsonObject; Location: JsonObject)
    begin
        JLocations := Locations;
        JLocation := Location;
    end;


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

    local procedure MakeResponse(HttpRequestMessage: HttpRequestMessage; var HttpResponseMessage: HttpResponseMessage)
    var
        Uri: Text;
        GraphQlQuery: Text;
        LocationsGraphQLCmdMsg: Label '{"query":"{ locations(first: 20, includeLegacy: true) { pageInfo { hasNextPage endCursor } nodes { legacyResourceId isActive isPrimary name fulfillmentService { id callbackUrl }}}}"}', Locked = true;
        LocationGraphQLCmdMsg: Label '{"query": "{ location(id: \"gid://shopify/Location', Locked = true;
        FulfillmentServiceUpdateGraphQLCmdMsg: Label '{"query": "mutation { fulfillmentServiceUpdate( id: \"gid://shopify/FulfillmentService', Locked = true;
        GraphQLCmdTxt: Label '/graphql.json', Locked = true;
    begin
        case HttpRequestMessage.Method of
            'POST':
                begin
                    Uri := HttpRequestMessage.GetRequestUri();
                    if Uri.EndsWith(GraphQLCmdTxt) then
                        if HttpRequestMessage.Content.ReadAs(GraphQlQuery) then begin
                            if GraphQlQuery = LocationsGraphQLCmdMsg then
                                HttpResponseMessage := GetLocationsResult();
                            if GraphQlQuery.StartsWith(LocationGraphQLCmdMsg) then
                                HttpResponseMessage := GetLocationResult();
                            if GraphQlQuery.StartsWith(FulfillmentServiceUpdateGraphQLCmdMsg) then
                                HttpResponseMessage := GetFulfillmentServiceUpdateResult();
                        end;
                end;
        end;
    end;

    local procedure GetLocationsResult(): HttpResponseMessage;
    var
        HttpResponseMessage: HttpResponseMessage;
    begin
        HttpResponseMessage.Content.WriteFrom(Format(JLocations));
        exit(HttpResponseMessage);
    end;

    local procedure GetLocationResult(): HttpResponseMessage;
    var
        HttpResponseMessage: HttpResponseMessage;
    begin
        HttpResponseMessage.Content.WriteFrom(Format(JLocation));
        exit(HttpResponseMessage);
    end;

    local procedure GetFulfillmentServiceUpdateResult(): HttpResponseMessage;
    var
        SyncShopLocations: Codeunit "Shpfy Sync Shop Locations";
        HttpResponseMessage: HttpResponseMessage;
        Body: Text;
        ResInStream: InStream;
    begin
        NavApp.GetResource('Locations/FulfillmentServiceUpdateResponse.txt', ResInStream, TextEncoding::UTF8);
        ResInStream.ReadText(Body);
        HttpResponseMessage.Content.WriteFrom(StrSubstNo(Body, SyncShopLocations.GetFulfillmentServiceCallbackUrl()));
        exit(HttpResponseMessage);
    end;

}