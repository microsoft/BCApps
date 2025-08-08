// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

using System.Integration.Graph.Authorization;
using System.RestClient;

codeunit 9351 "Graph Client Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;


    var
        GraphRequestHelper: Codeunit "Graph Request Helper";
        RestClient: Codeunit "Rest Client";
        GraphAPIVersion: Enum "Graph API Version";
        GraphAuthorization: Interface "Graph Authorization";
        MicrosoftGraphBaseUrl: Text;


    procedure Initialize(NewGraphAPIVersion: Enum "Graph API Version"; NewGraphAuthorization: Interface "Graph Authorization")
    begin
        GraphAPIVersion := NewGraphAPIVersion;
        GraphAuthorization := NewGraphAuthorization;
        RestClient.Initialize(GraphAuthorization.GetHttpAuthorization());
    end;

    procedure Initialize(NewGraphAPIVersion: Enum "Graph API Version"; NewGraphAuthorization: Interface "Graph Authorization"; HttpClientHandlerInstance: Interface "Http Client Handler")
    begin
        GraphAPIVersion := NewGraphAPIVersion;
        GraphAuthorization := NewGraphAuthorization;
        RestClient.Initialize(HttpClientHandlerInstance, GraphAuthorization.GetHttpAuthorization());
    end;

    procedure SetBaseUrl(BaseUrl: Text)
    begin
        MicrosoftGraphBaseUrl := BaseUrl;
    end;

    procedure Get(RelativeUriToResource: Text; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(Get(RelativeUriToResource, GraphOptionalParameters, HttpResponseMessage));
    end;

    procedure Get(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphUriBuilder: Codeunit "Graph Uri Builder";
    begin
        Clear(HttpResponseMessage);
        GraphUriBuilder.Initialize(MicrosoftGraphBaseUrl, GraphAPIVersion, RelativeUriToResource, GraphOptionalParameters.GetQueryParameters(), GraphOptionalParameters.GetODataQueryParameters());
        GraphRequestHelper.SetRestClient(RestClient);
        HttpResponseMessage := GraphRequestHelper.Get(GraphUriBuilder, GraphOptionalParameters);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure Post(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; RequestHttpContent: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphUriBuilder: Codeunit "Graph Uri Builder";
    begin
        GraphUriBuilder.Initialize(MicrosoftGraphBaseUrl, GraphAPIVersion, RelativeUriToResource, GraphOptionalParameters.GetQueryParameters(), GraphOptionalParameters.GetODataQueryParameters());
        GraphRequestHelper.SetRestClient(RestClient);
        HttpResponseMessage := GraphRequestHelper.Post(GraphUriBuilder, GraphOptionalParameters, RequestHttpContent);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure Patch(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; RequestHttpContent: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphUriBuilder: Codeunit "Graph Uri Builder";
    begin
        GraphUriBuilder.Initialize(MicrosoftGraphBaseUrl, GraphAPIVersion, RelativeUriToResource, GraphOptionalParameters.GetQueryParameters(), GraphOptionalParameters.GetODataQueryParameters());
        GraphRequestHelper.SetRestClient(RestClient);
        HttpResponseMessage := GraphRequestHelper.Patch(GraphUriBuilder, GraphOptionalParameters, RequestHttpContent);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure Put(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; RequestHttpContent: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphUriBuilder: Codeunit "Graph Uri Builder";
    begin
        GraphUriBuilder.Initialize(MicrosoftGraphBaseUrl, GraphAPIVersion, RelativeUriToResource, GraphOptionalParameters.GetQueryParameters(), GraphOptionalParameters.GetODataQueryParameters());
        GraphRequestHelper.SetRestClient(RestClient);
        HttpResponseMessage := GraphRequestHelper.Put(GraphUriBuilder, GraphOptionalParameters, RequestHttpContent);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure Delete(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphUriBuilder: Codeunit "Graph Uri Builder";
    begin
        GraphUriBuilder.Initialize(MicrosoftGraphBaseUrl, GraphAPIVersion, RelativeUriToResource);
        GraphRequestHelper.SetRestClient(RestClient);
        HttpResponseMessage := GraphRequestHelper.Delete(GraphUriBuilder, GraphOptionalParameters);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure GetWithPagination(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var GraphPaginationData: Codeunit "Graph Pagination Data"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
    begin
        // Apply page size if set
        GraphPaginationHelper.ApplyPageSize(GraphOptionalParameters, GraphPaginationData);

        // Make the request
        if not Get(RelativeUriToResource, GraphOptionalParameters, HttpResponseMessage) then
            exit(false);

        // Extract pagination data
        GraphPaginationHelper.ExtractNextLink(HttpResponseMessage, GraphPaginationData);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure GetNextPage(var GraphPaginationData: Codeunit "Graph Pagination Data"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        NextLink: Text;
    begin
        NextLink := GraphPaginationData.GetNextLink();

        if NextLink = '' then
            exit(false);

        GraphRequestHelper.SetRestClient(RestClient);
        HttpResponseMessage := GraphRequestHelper.GetByFullUrl(NextLink);

        // Update pagination data
        GraphPaginationHelper.ExtractNextLink(HttpResponseMessage, GraphPaginationData);
        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    procedure GetAllPages(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var HttpResponseMessage: Codeunit "Http Response Message"; var JsonResults: JsonArray): Boolean
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        IterationCount: Integer;
    begin
        // First request with pagination
        if not GetWithPagination(RelativeUriToResource, GraphOptionalParameters, GraphPaginationData, HttpResponseMessage) then
            exit(false);

        // Process first page
        GraphPaginationHelper.CombineValueArrays(HttpResponseMessage, JsonResults);

        // Fetch remaining pages
        while GraphPaginationData.HasMorePages() and GraphPaginationHelper.IsWithinIterationLimit(IterationCount, GraphPaginationHelper.GetMaxIterations()) do begin
            if not GetNextPage(GraphPaginationData, HttpResponseMessage) then
                exit(false);

            GraphPaginationHelper.CombineValueArrays(HttpResponseMessage, JsonResults);
        end;

        exit(true);
    end;

}

