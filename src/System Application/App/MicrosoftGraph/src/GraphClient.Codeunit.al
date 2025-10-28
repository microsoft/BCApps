// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Integration.Graph;

using System.Integration.Graph.Authorization;
using System.RestClient;

/// <summary>
/// Exposes functionality to query Microsoft Graph Api
/// </summary>
codeunit 9350 "Graph Client"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GraphClientImpl: Codeunit "Graph Client Impl.";

    /// <summary>
    /// Initializes Microsoft Graph client.
    /// </summary>
    /// <remarks>Should be called before any GET,PATCH,POST,DELTE request</remarks>
    /// <param name="GraphAPIVersion">API Version to use.</param>
    /// <param name="GraphAuthorizationInstance">The authorization to use.</param>
    procedure Initialize(GraphAPIVersion: Enum "Graph API Version"; GraphAuthorizationInstance: Interface "Graph Authorization")
    begin
        GraphClientImpl.Initialize(GraphAPIVersion, GraphAuthorizationInstance);
    end;

    /// <summary>
    /// Initializes Microsoft Graph client.
    /// </summary>
    /// <remarks>Should be called before any GET,PATCH,POST,DELTE request</remarks>
    /// <param name="GraphAPIVersion">API Version to use.</param>
    /// <param name="GraphAuthorizationInstance">The authorization to use.</param>
    /// <param name="HttpClientHandlerInstance">The authorization to use.</param>
    procedure Initialize(GraphAPIVersion: Enum "Graph API Version"; GraphAuthorizationInstance: Interface "Graph Authorization"; HttpClientHandlerInstance: Interface "Http Client Handler")
    begin
        GraphClientImpl.Initialize(GraphAPIVersion, GraphAuthorizationInstance, HttpClientHandlerInstance);
    end;

    /// <summary>
    /// The base URL to use when constructing the final request URI.
    /// If not set, the base URL is https://graph.microsoft.com . 
    /// </summary>
    /// <remarks>It's optional to set the BaseUrl.</remarks>
    /// <param name="BaseUrl">A valid URL string</param>
    procedure SetBaseUrl(BaseUrl: Text)
    begin
        GraphClientImpl.SetBaseUrl(BaseUrl);
    end;


    /// <summary>
    /// Get any request to the microsoft graph API
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="RelativeUriToResource">A relativ uri including the resource segments</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure Get(RelativeUriToResource: Text; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.Get(RelativeUriToResource, HttpResponseMessage));
    end;

    /// <summary>
    /// Get any request to the microsoft graph API
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="RelativeUriToResource">A relativ uri including the resource segment</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure Get(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.Get(RelativeUriToResource, GraphOptionalParameters, HttpResponseMessage));
    end;

    /// <summary>
    /// Post any request to the microsoft graph API
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="RelativeUriToResource">A relativ uri including the resource segment</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="RequestHttpContent">The HttpContent object for the request.</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure Post(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; RequestHttpContent: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.Post(RelativeUriToResource, GraphOptionalParameters, RequestHttpContent, HttpResponseMessage));
    end;

    /// <summary>
    /// Patch any request to the microsoft graph API
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="RelativeUriToResource">A relativ uri including the resource segment</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="RequestHttpContent">The HttpContent object for the request.</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure Patch(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; RequestHttpContent: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.Patch(RelativeUriToResource, GraphOptionalParameters, RequestHttpContent, HttpResponseMessage));
    end;

    /// <summary>
    /// Put any request to the microsoft graph API
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="RelativeUriToResource">A relativ uri including the resource segment</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="RequestHttpContent">The HttpContent object for the request.</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure Put(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; RequestHttpContent: Codeunit "Http Content"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.Put(RelativeUriToResource, GraphOptionalParameters, RequestHttpContent, HttpResponseMessage));
    end;

    /// <summary>
    /// Send a DELETE request to the microsoft graph API
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="RelativeUriToResource">A relativ uri to the resource - e.g. /users/{id|userPrincipalName}.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure Delete(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.Delete(RelativeUriToResource, GraphOptionalParameters, HttpResponseMessage));
    end;

    #region Pagination Support

    /// <summary>
    /// Get any request to the microsoft graph API with pagination support
    /// </summary>
    /// <remarks>Does not require UI interaction. This method handles pagination automatically.</remarks>
    /// <param name="RelativeUriToResource">A relative uri including the resource segments</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="GraphPaginationData">The pagination data object to track pagination state</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure GetWithPagination(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var GraphPaginationData: Codeunit "Graph Pagination Data"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.GetWithPagination(RelativeUriToResource, GraphOptionalParameters, GraphPaginationData, HttpResponseMessage));
    end;

    /// <summary>
    /// Get the next page of results using pagination data
    /// </summary>
    /// <remarks>Does not require UI interaction.</remarks>
    /// <param name="GraphPaginationData">The pagination data object containing the next link</param>
    /// <param name="HttpResponseMessage">The response message object.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure GetNextPage(var GraphPaginationData: Codeunit "Graph Pagination Data"; var HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        exit(GraphClientImpl.GetNextPage(GraphPaginationData, HttpResponseMessage));
    end;

    /// <summary>
    /// Get all pages of results automatically
    /// </summary>
    /// <remarks>Does not require UI interaction. This method fetches all pages automatically and returns the combined results.</remarks>
    /// <param name="RelativeUriToResource">A relative uri including the resource segments</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <param name="HttpResponseMessage">The last response message object.</param>
    /// <param name="JsonResults">A JSON array containing all results from all pages</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    /// <error>Authentication failed.</error>
    procedure GetAllPages(RelativeUriToResource: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var HttpResponseMessage: Codeunit "Http Response Message"; var JsonResults: JsonArray): Boolean
    begin
        exit(GraphClientImpl.GetAllPages(RelativeUriToResource, GraphOptionalParameters, HttpResponseMessage, JsonResults));
    end;

    #endregion
}