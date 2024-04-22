// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

using System.RestClient;

codeunit 9354 "Graph Request Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RestClient: Codeunit "Rest Client";

    procedure SetRestClient(var NewRestClient: Codeunit "Rest Client")
    begin
        RestClient := NewRestClient;
    end;

    procedure Get(GraphUriBuilder: Codeunit "Graph Uri Builder"; GraphOptionalParameters: Codeunit "Graph Optional Parameters") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        PrepareRestClient(GraphOptionalParameters);
        HttpResponseMessage := RestClient.Get(GraphUriBuilder.GetUri());
    end;

    procedure Post(GraphUriBuilder: Codeunit "Graph Uri Builder"; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; HttpContent: Codeunit "Http Content") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        HttpResponseMessage := SendRequest(Enum::"Http Method"::POST, GraphUriBuilder, GraphOptionalParameters, HttpContent);
    end;

    procedure Patch(GraphUriBuilder: Codeunit "Graph Uri Builder"; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; HttpContent: Codeunit "Http Content") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        HttpResponseMessage := SendRequest(Enum::"Http Method"::PATCH, GraphUriBuilder, GraphOptionalParameters, HttpContent);
    end;

    procedure Put(GraphUriBuilder: Codeunit "Graph Uri Builder"; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; HttpContent: Codeunit "Http Content") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        HttpResponseMessage := SendRequest(Enum::"Http Method"::PUT, GraphUriBuilder, GraphOptionalParameters, HttpContent);
    end;

    procedure Delete(GraphUriBuilder: Codeunit "Graph Uri Builder"; GraphOptionalParameters: Codeunit "Graph Optional Parameters") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        PrepareRestClient(GraphOptionalParameters);
        HttpResponseMessage := RestClient.Delete(GraphUriBuilder.GetUri());
    end;

    local procedure PrepareRestClient(GraphOptionalParameters: Codeunit "Graph Optional Parameters")
    var
        RequestHeaders: Dictionary of [Text, Text];
        RequestHeaderName: Text;
    begin
        RequestHeaders := GraphOptionalParameters.GetRequestHeaders();
        foreach RequestHeaderName in RequestHeaders.Keys() do
            RestClient.SetDefaultRequestHeader(RequestHeaderName, RequestHeaders.Get(RequestHeaderName));
    end;

    local procedure SendRequest(HttpMethod: Enum "Http Method"; GraphUriBuilder: Codeunit "Graph Uri Builder"; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; HttpContent: Codeunit "Http Content") HttpResponseMessage: Codeunit "Http Response Message"
    begin
        PrepareRestClient(GraphOptionalParameters);
        HttpResponseMessage := RestClient.Send(HttpMethod, GraphUriBuilder.GetUri(), HttpContent);
    end;
}