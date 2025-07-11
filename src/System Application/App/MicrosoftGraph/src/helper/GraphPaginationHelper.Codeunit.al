// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

using System.RestClient;

codeunit 9359 "Graph Pagination Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure ExtractNextLink(HttpResponseMessage: Codeunit "Http Response Message"; var GraphPaginationData: Codeunit "Graph Pagination Data")
    var
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        NextLink: Text;
        ResponseText: Text;
    begin
        if not HttpResponseMessage.GetIsSuccessStatusCode() then begin
            GraphPaginationData.SetNextLink('');
            exit;
        end;

        ResponseText := HttpResponseMessage.GetContent().AsText();

        // Parse JSON response
        if not ResponseJson.ReadFrom(ResponseText) then begin
            GraphPaginationData.SetNextLink('');
            exit;
        end;

        // Extract nextLink
        if ResponseJson.Get('@odata.nextLink', JsonToken) then
            NextLink := JsonToken.AsValue().AsText();

        GraphPaginationData.SetNextLink(NextLink);
    end;

    procedure ExtractValueArray(HttpResponseMessage: Codeunit "Http Response Message"; var ValueArray: JsonArray): Boolean
    var
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        ResponseText: Text;
    begin
        Clear(ValueArray);

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            exit(false);

        ResponseText := HttpResponseMessage.GetContent().AsText();

        // Parse JSON response
        if not ResponseJson.ReadFrom(ResponseText) then
            exit(false);

        // Extract value array
        if not ResponseJson.Get('value', JsonToken) then
            exit(false);

        ValueArray := JsonToken.AsArray();
        exit(true);
    end;

    procedure ApplyPageSize(var GraphOptionalParameters: Codeunit "Graph Optional Parameters"; GraphPaginationData: Codeunit "Graph Pagination Data")
    begin
        if GraphPaginationData.GetPageSize() > 0 then
            GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::top, Format(GraphPaginationData.GetPageSize()));
    end;

    procedure CombineValueArrays(HttpResponseMessage: Codeunit "Http Response Message"; var JsonResults: JsonArray): Boolean
    var
        ValueArray: JsonArray;
        JsonItem: JsonToken;
    begin
        if not ExtractValueArray(HttpResponseMessage, ValueArray) then
            exit(false);

        foreach JsonItem in ValueArray do
            JsonResults.Add(JsonItem);

        exit(true);
    end;

    procedure IsWithinIterationLimit(var IterationCount: Integer; MaxIterations: Integer): Boolean
    begin
        if IterationCount >= MaxIterations then
            exit(false);

        IterationCount += 1;

        exit(true);
    end;

    procedure GetMaxIterations(): Integer
    begin
        exit(1000); // Safety limit to prevent infinite loops
    end;
}