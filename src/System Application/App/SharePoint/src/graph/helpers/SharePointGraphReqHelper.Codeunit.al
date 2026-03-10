// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

using System.Integration.Graph;
using System.Integration.Graph.Authorization;
using System.RestClient;
using System.Utilities;

/// <summary>
/// Provides functionality for making requests to the Microsoft Graph API for SharePoint.
/// </summary>
codeunit 9123 "SharePoint Graph Req. Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        GraphClient: Codeunit "Graph Client";
        SharePointDiagnostics: Codeunit "SharePoint Diagnostics";
        ApiVersion: Enum "Graph API Version";
        CustomBaseUrl: Text;
        MicrosoftGraphDefaultBaseUrlLbl: Label 'https://graph.microsoft.com/%1', Comment = '%1 = Graph API Version', Locked = true;
        RangeHeaderLbl: Label 'bytes=%1-%2', Locked = true;
        UntrustedUploadHostErr: Label 'Upload URL points to an untrusted host.', Locked = true;
        AllowedUploadUrlPatternLbl: Label '^https:\/\/[a-zA-Z0-9][a-zA-Z0-9\.\-]*\.(sharepoint\.com|microsoft\.com|microsoftonline\.com)(\/.*)?$', Locked = true;

    /// <summary>
    /// Initializes the Graph Request Helper with an authorization.
    /// </summary>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    procedure Initialize(GraphAuthorization: Interface "Graph Authorization")
    begin
        ApiVersion := Enum::"Graph API Version"::"v1.0";
        CustomBaseUrl := '';
        GraphClient.Initialize(ApiVersion, GraphAuthorization);
    end;

    /// <summary>
    /// Initializes the Graph Request Helper with a specific API version and authorization.
    /// </summary>
    /// <param name="NewApiVersion">The Graph API version to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    procedure Initialize(NewApiVersion: Enum "Graph API Version"; GraphAuthorization: Interface "Graph Authorization")
    begin
        ApiVersion := NewApiVersion;
        CustomBaseUrl := '';
        GraphClient.Initialize(NewApiVersion, GraphAuthorization);
    end;

    /// <summary>
    /// Initializes the Graph Request Helper with a custom base URL and authorization.
    /// </summary>
    /// <param name="NewBaseUrl">The custom base URL to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    procedure Initialize(NewBaseUrl: Text; GraphAuthorization: Interface "Graph Authorization")
    begin
        ApiVersion := Enum::"Graph API Version"::"v1.0";
        CustomBaseUrl := NewBaseUrl;
        GraphClient.Initialize(ApiVersion, GraphAuthorization);
    end;

    /// <summary>
    /// Initializes the Graph Request Helper with an HTTP client handler for testing.
    /// </summary>
    /// <param name="NewApiVersion">The Graph API version to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    /// <param name="HttpClientHandler">HTTP client handler for intercepting requests.</param>
    procedure Initialize(NewApiVersion: Enum "Graph API Version"; GraphAuthorization: Interface "Graph Authorization"; HttpClientHandler: Interface "Http Client Handler")
    begin
        ApiVersion := NewApiVersion;
        CustomBaseUrl := '';
        GraphClient.Initialize(NewApiVersion, GraphAuthorization, HttpClientHandler);
    end;

    /// <summary>
    /// Gets the base URL for Graph API calls.
    /// </summary>
    /// <returns>The base URL for Graph API requests.</returns>
    procedure GetGraphApiBaseUrl(): Text
    begin
        if CustomBaseUrl <> '' then
            exit(CustomBaseUrl);

        exit(StrSubstNo(MicrosoftGraphDefaultBaseUrlLbl, ApiVersion));
    end;

    #region GET Requests

    /// <summary>
    /// Makes a GET request to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Get(Endpoint: Text; var ResponseJson: JsonObject; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        FinalEndpoint: Text;
    begin
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Get(FinalEndpoint, GraphOptionalParameters, HttpResponseMessage);
        exit(ProcessJsonResponse(HttpResponseMessage, ResponseJson));
    end;

    /// <summary>
    /// Makes a GET request to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Get(Endpoint: Text; var ResponseJson: JsonObject): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(Get(Endpoint, ResponseJson, GraphOptionalParameters));
    end;

    /// <summary>
    /// Downloads a file from Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="TempBlob">The blob to write the file content to.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure DownloadFile(Endpoint: Text; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(DownloadFile(Endpoint, TempBlob, GraphOptionalParameters));
    end;

    /// <summary>
    /// Downloads a file from Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="TempBlob">The blob to write the file content to.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure DownloadFile(Endpoint: Text; var TempBlob: Codeunit "Temp Blob"; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        FinalEndpoint: Text;
    begin
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Get(FinalEndpoint, GraphOptionalParameters, HttpResponseMessage);
        exit(ProcessStreamResponse(HttpResponseMessage, TempBlob));
    end;

    /// <summary>
    /// Downloads a chunk of a file using HTTP Range header.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RangeStart">Starting byte position (0-based, inclusive).</param>
    /// <param name="RangeEnd">Ending byte position (0-based, inclusive).</param>
    /// <param name="TempBlob">The blob to receive the chunk content.</param>
    /// <returns>True if the chunk was downloaded successfully; otherwise false.</returns>
    procedure DownloadChunk(Endpoint: Text; RangeStart: BigInteger; RangeEnd: BigInteger; var TempBlob: Codeunit "Temp Blob"): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        FinalEndpoint: Text;
        RangeHeader: Text;
    begin
        // Set Range header: "bytes=0-104857599"
        RangeHeader := StrSubstNo(RangeHeaderLbl, RangeStart, RangeEnd);
        GraphOptionalParameters.SetRequestHeader(Enum::"Graph Request Header"::Range, RangeHeader);

        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Get(FinalEndpoint, GraphOptionalParameters, HttpResponseMessage);

        // Graph API should return 206 Partial Content for Range requests
        // But we'll accept both 200 (full content) and 206 (partial content)
        SharePointDiagnostics.SetParameters(HttpResponseMessage.GetIsSuccessStatusCode(),
            HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase(),
            TryGetRetryAfterHeaderValue(HttpResponseMessage), HttpResponseMessage.GetErrorMessage());

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            exit(false);

        exit(ProcessStreamResponse(HttpResponseMessage, TempBlob));
    end;

    #endregion

    #region POST Requests

    /// <summary>
    /// Makes a POST request to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RequestBody">The request body.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Post(Endpoint: Text; RequestBody: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(Post(Endpoint, RequestBody, GraphOptionalParameters, ResponseJson));
    end;

    /// <summary>
    /// Makes a POST request to the Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RequestBody">The request body.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Post(Endpoint: Text; RequestBody: JsonObject; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var ResponseJson: JsonObject): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        FinalEndpoint: Text;
    begin
        HttpContent.Create(RequestBody);
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Post(FinalEndpoint, GraphOptionalParameters, HttpContent, HttpResponseMessage);
        exit(ProcessJsonResponse(HttpResponseMessage, ResponseJson));
    end;

    #endregion

    #region File Upload

    /// <summary>
    /// Uploads a file to Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="FileInStream">The stream containing the file content.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure UploadFile(Endpoint: Text; FileInStream: InStream; var ResponseJson: JsonObject): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(UploadFile(Endpoint, FileInStream, GraphOptionalParameters, ResponseJson));
    end;

    /// <summary>
    /// Uploads a file to Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="FileInStream">The stream containing the file content.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure UploadFile(Endpoint: Text; FileInStream: InStream; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var ResponseJson: JsonObject): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        FinalEndpoint: Text;
    begin
        HttpContent.Create(FileInStream);
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Put(FinalEndpoint, GraphOptionalParameters, HttpContent, HttpResponseMessage);
        exit(ProcessJsonResponse(HttpResponseMessage, ResponseJson));
    end;

    #endregion

    #region Chunked File Upload

    /// <summary>
    /// Creates an upload session for chunked file upload.
    /// </summary>
    /// <param name="Endpoint">The endpoint to create the upload session.</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileSize">Size of the file in bytes.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="GraphConflictBehavior">How to handle conflicts if a file with the same name exists.</param>
    /// <param name="UploadUrlResult">The upload URL result for the session.</param>
    /// <returns>True if the upload session was created successfully; otherwise false.</returns>
    procedure CreateUploadSession(Endpoint: Text; FileName: Text; FileSize: Integer; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; GraphConflictBehavior: Enum "Graph ConflictBehavior"; var UploadUrlResult: Text): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        RequestBodyJson: JsonObject;
        ItemJson: JsonObject;
        ResponseJson: JsonObject;
        JsonToken: JsonToken;
        FinalEndpoint: Text;
    begin
        // Create request body for upload session
        ItemJson.Add('@microsoft.graph.conflictBehavior', Format(GraphConflictBehavior));
        ItemJson.Add('name', FileName);
        // Can also add description or fileSystemInfo here if needed
        RequestBodyJson.Add('item', ItemJson);

        HttpContent.Create(RequestBodyJson);
        FinalEndpoint := PrepareEndpoint(Endpoint + ':/createUploadSession', GraphOptionalParameters);
        GraphClient.Post(FinalEndpoint, GraphOptionalParameters, HttpContent, HttpResponseMessage);

        if not ProcessJsonResponse(HttpResponseMessage, ResponseJson) then
            exit(false);

        // Extract uploadUrl from the response
        if ResponseJson.Get('uploadUrl', JsonToken) then
            UploadUrlResult := JsonToken.AsValue().AsText()
        else
            exit(false);

        exit(true);
    end;

    /// <summary>
    /// Uploads a chunk of file content to an upload session.
    /// </summary>
    /// <param name="UploadUrl">The upload URL for the session.</param>
    /// <param name="ChunkContent">The content of the chunk.</param>
    /// <param name="ContentRange">The content range header value (e.g., "bytes 0-1023/5000").</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <remarks>Uses a separate RestClient instead of GraphClient because the upload URL is a complete URL and must not include the Authorization header.</remarks>
    /// <returns>True if the chunk was uploaded successfully; otherwise false.</returns>
    procedure UploadChunk(UploadUrl: Text; var ChunkContent: InStream; ContentRange: Text; var ResponseJson: JsonObject): Boolean
    var
        RestClient: Codeunit "Rest Client";
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        Clear(ResponseJson);

        // Validate that the upload URL points to a trusted Microsoft host
        if not IsAllowedUploadUrl(UploadUrl) then begin
            SharePointDiagnostics.SetParameters(false, 0, UntrustedUploadHostErr, 0, '');
            exit(false);
        end;

        // Initialize a fresh RestClient without passing any authorization
        RestClient.Initialize();

        // Create the HTTP content with our chunk
        HttpContent.Create(ChunkContent);
        HttpContent.SetHeader('Content-Range', ContentRange);
        HttpContent.SetContentTypeHeader('application/octet-stream');

        // Use direct PUT method on the upload URL
        // The UploadUrl is already a complete URL from the upload session
        HttpResponseMessage := RestClient.Put(UploadUrl, HttpContent);

        SharePointDiagnostics.SetParameters(HttpResponseMessage.GetIsSuccessStatusCode(),
            HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase(),
            TryGetRetryAfterHeaderValue(HttpResponseMessage), HttpResponseMessage.GetErrorMessage());

        if not HttpResponseMessage.GetIsSuccessStatusCode() then
            exit(false);

        ResponseJson := HttpResponseMessage.GetContent().AsJsonObject();

        exit(true);
    end;

    #endregion

    #region PUT Requests

    /// <summary>
    /// Makes a PUT request to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RequestBody">The request body.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Put(Endpoint: Text; RequestBody: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(Put(Endpoint, RequestBody, GraphOptionalParameters, ResponseJson));
    end;

    /// <summary>
    /// Makes a PUT request to the Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RequestBody">The request body.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Put(Endpoint: Text; RequestBody: JsonObject; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var ResponseJson: JsonObject): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        FinalEndpoint: Text;
    begin
        HttpContent.Create(RequestBody);
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Put(FinalEndpoint, GraphOptionalParameters, HttpContent, HttpResponseMessage);
        exit(ProcessJsonResponse(HttpResponseMessage, ResponseJson));
    end;

    /// <summary>
    /// Makes a PUT request with binary content and custom headers to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="Content">The binary content stream.</param>
    /// <param name="ContentType">The content type of the binary data.</param>
    /// <param name="AdditionalHeaders">Dictionary of additional headers to include.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure PutContent(Endpoint: Text; Content: InStream; ContentType: Text; var AdditionalHeaders: Dictionary of [Text, Text]; var ResponseJson: JsonObject): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(PutContent(Endpoint, Content, ContentType, AdditionalHeaders, GraphOptionalParameters, false, ResponseJson));
    end;

    /// <summary>
    /// Makes a PUT request with binary content and custom headers to the Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="Content">The binary content stream.</param>
    /// <param name="ContentType">The content type of the binary data.</param>
    /// <param name="AdditionalHeaders">Dictionary of additional headers to include.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="IsCompleteUrl">If true, the endpoint is treated as a complete URL and not processed further.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure PutContent(Endpoint: Text; Content: InStream; ContentType: Text; var AdditionalHeaders: Dictionary of [Text, Text]; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; IsCompleteUrl: Boolean; var ResponseJson: JsonObject): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        FinalEndpoint: Text;
        HeaderKey: Text;
    begin
        HttpContent.Create(Content);
        HttpContent.SetContentTypeHeader(ContentType);

        // Add any additional headers
        foreach HeaderKey in AdditionalHeaders.Keys() do
            HttpContent.SetHeader(HeaderKey, AdditionalHeaders.Get(HeaderKey));

        if IsCompleteUrl then
            FinalEndpoint := Endpoint
        else
            FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);

        GraphClient.Put(FinalEndpoint, GraphOptionalParameters, HttpContent, HttpResponseMessage);
        exit(ProcessJsonResponse(HttpResponseMessage, ResponseJson));
    end;

    #endregion

    #region PATCH Requests

    /// <summary>
    /// Makes a PATCH request to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RequestBody">The request body.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Patch(Endpoint: Text; RequestBody: JsonObject; var ResponseJson: JsonObject): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(Patch(Endpoint, RequestBody, GraphOptionalParameters, ResponseJson));
    end;

    /// <summary>
    /// Makes a PATCH request to the Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="RequestBody">The request body.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="ResponseJson">The JSON response.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Patch(Endpoint: Text; RequestBody: JsonObject; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var ResponseJson: JsonObject): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        FinalEndpoint: Text;
    begin
        HttpContent.Create(RequestBody);
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Patch(FinalEndpoint, GraphOptionalParameters, HttpContent, HttpResponseMessage);
        exit(ProcessJsonResponse(HttpResponseMessage, ResponseJson));
    end;

    #endregion

    #region DELETE Requests

    /// <summary>
    /// Makes a DELETE request to the Microsoft Graph API.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Delete(Endpoint: Text): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(Delete(Endpoint, GraphOptionalParameters));
    end;

    /// <summary>
    /// Makes a DELETE request to the Microsoft Graph API with optional parameters.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure Delete(Endpoint: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        FinalEndpoint: Text;
    begin
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);
        GraphClient.Delete(FinalEndpoint, GraphOptionalParameters, HttpResponseMessage);
        exit(ProcessResponse(HttpResponseMessage));
    end;

    #endregion

    #region Pagination

    /// <summary>
    /// Makes a GET request to the Microsoft Graph API with pagination support and returns all pages automatically.
    /// </summary>
    /// <param name="Endpoint">The endpoint to request.</param>
    /// <param name="GraphOptionalParameters">Optional parameters for the request.</param>
    /// <param name="JsonArray">The JSON array containing all results from all pages.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    procedure GetAllPages(Endpoint: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"; var JsonArray: JsonArray): Boolean
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        FinalEndpoint: Text;
    begin
        FinalEndpoint := PrepareEndpoint(Endpoint, GraphOptionalParameters);

        if not GraphClient.GetAllPages(FinalEndpoint, GraphOptionalParameters, HttpResponseMessage, JsonArray) then begin
            SharePointDiagnostics.SetParameters(HttpResponseMessage.GetIsSuccessStatusCode(),
                HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase(),
                TryGetRetryAfterHeaderValue(HttpResponseMessage), HttpResponseMessage.GetErrorMessage());
            exit(false);
        end;

        SharePointDiagnostics.SetParameters(HttpResponseMessage.GetIsSuccessStatusCode(),
            HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase(),
            TryGetRetryAfterHeaderValue(HttpResponseMessage), HttpResponseMessage.GetErrorMessage());

        exit(true);
    end;

    #endregion

    #region Helpers

    /// <summary>
    /// Configures conflict behavior in optional parameters
    /// </summary>
    /// <param name="GraphOptionalParameters">Optional parameters to configure</param>
    /// <param name="ConflictBehavior">The desired conflict behavior</param>
    procedure ConfigureConflictBehavior(var GraphOptionalParameters: Codeunit "Graph Optional Parameters"; ConflictBehavior: Enum "Graph ConflictBehavior")
    begin
        GraphOptionalParameters.SetMicrosftGraphConflictBehavior(ConflictBehavior);
    end;

    /// <summary>
    /// Returns detailed information on last API call.
    /// </summary>
    /// <returns>Codeunit holding http response status, reason phrase, headers and possible error information for the last API call</returns>
    procedure GetDiagnostics(): Interface "HTTP Diagnostics"
    begin
        exit(SharePointDiagnostics);
    end;

    /// <summary>
    /// Prepares the endpoint for a request by adding optional parameters.
    /// </summary>
    /// <param name="Endpoint">The base endpoint.</param>
    /// <param name="GraphOptionalParameters">Optional parameters to add to the endpoint.</param>
    /// <returns>The final endpoint with optional parameters.</returns>
    local procedure PrepareEndpoint(Endpoint: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Text
    var
        SharePointGraphUriBuilder: Codeunit "Sharepoint Graph Uri Builder";
    begin
        exit(SharePointGraphUriBuilder.AddOptionalParametersToEndpoint(Endpoint, GraphOptionalParameters));
    end;

    /// <summary>
    /// Common response processing - sets diagnostics and checks for success status
    /// </summary>
    /// <param name="HttpResponseMessage">The HTTP response message to process</param>
    /// <returns>True if the response is successful; otherwise false</returns>
    local procedure ProcessResponse(HttpResponseMessage: Codeunit "Http Response Message"): Boolean
    begin
        SharePointDiagnostics.SetParameters(HttpResponseMessage.GetIsSuccessStatusCode(),
            HttpResponseMessage.GetHttpStatusCode(), HttpResponseMessage.GetReasonPhrase(),
            TryGetRetryAfterHeaderValue(HttpResponseMessage), HttpResponseMessage.GetErrorMessage());

        exit(HttpResponseMessage.GetIsSuccessStatusCode());
    end;

    /// <summary>
    /// Processes an HTTP response and extracts the JSON content.
    /// </summary>
    /// <param name="HttpResponseMessage">The HTTP response message.</param>
    /// <param name="ResponseJson">The JSON response to populate.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    local procedure ProcessJsonResponse(HttpResponseMessage: Codeunit "Http Response Message"; var ResponseJson: JsonObject): Boolean
    begin
        if not ProcessResponse(HttpResponseMessage) then
            exit(false);

        ResponseJson := HttpResponseMessage.GetContent().AsJsonObject();
        exit(true);
    end;

    /// <summary>
    /// Processes an HTTP response and extracts the stream content.
    /// </summary>
    /// <param name="HttpResponseMessage">The HTTP response message.</param>
    /// <param name="TempBlob">The blob to populate with the response content.</param>
    /// <returns>True if the request was successful; otherwise false.</returns>
    local procedure ProcessStreamResponse(HttpResponseMessage: Codeunit "Http Response Message"; var TempBlob: Codeunit "Temp Blob"): Boolean
    begin
        if not ProcessResponse(HttpResponseMessage) then
            exit(false);

        TempBlob := HttpResponseMessage.GetContent().AsBlob();

        exit(true);
    end;

    local procedure IsAllowedUploadUrl(Url: Text): Boolean
    var
        Uri: Codeunit Uri;
    begin
        exit(Uri.IsValidURIPattern(Url, AllowedUploadUrlPatternLbl));
    end;

    local procedure TryGetRetryAfterHeaderValue(HttpResponseMessage: Codeunit "Http Response Message") RetryAfterAsInteger: Integer
    var
        Values: array[1] of Text;
    begin
        if not HttpResponseMessage.GetHeaders().GetValues('Retry-After', Values) then
            exit;

        //Since the HTTP Diagnostics interface expects an integer in Retry-After, we must convert the header to a number.
        //At the same time, the HTTP specification states that there may be a date there.
        if not Evaluate(RetryAfterAsInteger, Values[1]) then
            exit(0);
    end;

    #endregion
}