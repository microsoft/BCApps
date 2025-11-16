// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

using System.Integration.Graph;
using System.Integration.Graph.Authorization;
using System.Utilities;
using System.RestClient;

/// <summary>
/// Provides functionality for interacting with SharePoint through Microsoft Graph API.
/// This implementation uses native Graph API concepts and models.
/// </summary>
codeunit 9120 "SharePoint Graph Client Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SharePointGraphRequestHelper: Codeunit "SharePoint Graph Req. Helper";
        SharePointGraphParser: Codeunit "Sharepoint Graph Parser";
        SharePointGraphUriBuilder: Codeunit "Sharepoint Graph Uri Builder";
        SiteId: Text;
        SharePointUrl: Text;
        DefaultDriveId: Text;
        IsInitialized: Boolean;
        NotInitializedErr: Label 'SharePoint Graph Client is not initialized. Call Initialize first.';
        InvalidSharePointUrlErr: Label 'Invalid SharePoint URL ''%1''.', Comment = '%1 = URL string';
        RetrieveSiteInfoErr: Label 'Failed to retrieve SharePoint site information from Graph API. %1', Comment = '%1 = Error message';
        ContentRangeHeaderLbl: Label 'bytes %1-%2/%3', Locked = true, Comment = '%1 = Start Bytes, %2 = End Bytes, %3 = Total Bytes';
        FailedToRetrieveListsErr: Label 'Failed to retrieve lists: %1', Comment = '%1 = Error message';
        FailedToParseListsErr: Label 'Failed to parse lists collection from response';
        FailedToRetrieveListErr: Label 'Failed to retrieve list: %1', Comment = '%1 = Error message';
        FailedToParseListErr: Label 'Failed to parse list details from response';
        InvalidListIdErr: Label 'List ID cannot be empty';
        InvalidDisplayNameErr: Label 'Display name cannot be empty';
        FailedToCreateListErr: Label 'Failed to create list: %1', Comment = '%1 = Error message';
        FailedToParseCreatedListErr: Label 'Failed to parse created list details from response';
        FailedToRetrieveListItemsErr: Label 'Failed to retrieve list items: %1', Comment = '%1 = Error message';
        FailedToParseListItemsErr: Label 'Failed to parse list items collection from response';
        FailedToCreateListItemErr: Label 'Failed to create list item: %1', Comment = '%1 = Error message';
        FailedToParseCreatedListItemErr: Label 'Failed to parse created list item details from response';
        NoDefaultDriveIdErr: Label 'Default drive ID is not available. Please check the SharePoint site.';
        FailedToRetrieveDefaultDriveErr: Label 'Failed to retrieve default drive: %1', Comment = '%1 = Error message';
        FailedToRetrieveDrivesErr: Label 'Failed to retrieve drives: %1', Comment = '%1 = Error message';
        FailedToParseDrivesErr: Label 'Failed to parse drives collection from response';
        FailedToRetrieveDriveErr: Label 'Failed to retrieve drive: %1', Comment = '%1 = Error message';
        FailedToParseDriveErr: Label 'Failed to parse drive details from response';
        InvalidDriveIdErr: Label 'Drive ID cannot be empty';
        FailedToRetrieveRootItemsErr: Label 'Failed to retrieve root items: %1', Comment = '%1 = Error message';
        FailedToParseRootItemsErr: Label 'Failed to parse root items collection from response';
        InvalidFolderIdErr: Label 'Folder ID cannot be empty';
        FailedToRetrieveFolderItemsErr: Label 'Failed to retrieve folder items: %1', Comment = '%1 = Error message';
        FailedToParseFolderItemsErr: Label 'Failed to parse folder items collection from response';
        FailedToRetrieveItemsByPathErr: Label 'Failed to retrieve items by path: %1', Comment = '%1 = Error message';
        FailedToParseItemsByPathErr: Label 'Failed to parse items collection from response';
        InvalidItemIdErr: Label 'Item ID cannot be empty';
        FailedToRetrieveDriveItemErr: Label 'Failed to retrieve drive item: %1', Comment = '%1 = Error message';
        FailedToParseDriveItemErr: Label 'Failed to parse drive item details from response';
        InvalidItemPathErr: Label 'Item path cannot be empty';
        FailedToRetrieveDriveItemByPathErr: Label 'Failed to retrieve drive item by path: %1', Comment = '%1 = Error message';
        FailedToParseDriveItemByPathErr: Label 'Failed to parse drive item details from response';
        InvalidFolderNameErr: Label 'Folder name cannot be empty';
        FailedToCreateFolderErr: Label 'Failed to create folder: %1', Comment = '%1 = Error message';
        FailedToParseCreatedFolderErr: Label 'Failed to parse created folder details from response';
        InvalidFileNameErr: Label 'File name cannot be empty';
        FailedToUploadFileErr: Label 'Failed to upload file: %1', Comment = '%1 = Error message';
        FailedToParseUploadedFileErr: Label 'Failed to parse uploaded file details from response';
        InvalidFileSizeErr: Label 'File size must be greater than 0';
        FailedToCreateUploadSessionErr: Label 'Failed to create upload session: %1', Comment = '%1 = Error message';
        FailedToUploadChunkErr: Label 'Failed to upload file chunk: %1', Comment = '%1 = Error message';
        NoUploadResponseErr: Label 'No response received from chunked upload';
        FailedToParseChunkedUploadErr: Label 'Failed to parse chunked upload response';
        FailedToDownloadFileErr: Label 'Failed to download file: %1', Comment = '%1 = Error message';
        InvalidFilePathErr: Label 'File path cannot be empty';
        FailedToDownloadFileByPathErr: Label 'Failed to download file by path: %1', Comment = '%1 = Error message';

    #region Initialization

    /// <summary>
    /// Initializes SharePoint Graph client.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    procedure Initialize(NewSharePointUrl: Text; GraphAuthorization: Interface "Graph Authorization")
    begin
        SharePointGraphRequestHelper.Initialize(GraphAuthorization);
        InitializeCommon(NewSharePointUrl);
    end;

    /// <summary>
    /// Initializes SharePoint Graph client with a specific API version.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="ApiVersion">The Graph API version to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    procedure Initialize(NewSharePointUrl: Text; ApiVersion: Enum "Graph API Version"; GraphAuthorization: Interface "Graph Authorization")
    begin
        SharePointGraphRequestHelper.Initialize(ApiVersion, GraphAuthorization);
        InitializeCommon(NewSharePointUrl);
    end;

    /// <summary>
    /// Initializes SharePoint Graph client with a custom base URL.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="BaseUrl">The custom base URL for Graph API.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    procedure Initialize(NewSharePointUrl: Text; BaseUrl: Text; GraphAuthorization: Interface "Graph Authorization")
    begin
        SharePointGraphRequestHelper.Initialize(BaseUrl, GraphAuthorization);
        InitializeCommon(NewSharePointUrl);
    end;

    /// <summary>
    /// Initializes SharePoint Graph client with an HTTP client handler for testing.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="ApiVersion">The Graph API version to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    /// <param name="HttpClientHandler">HTTP client handler for intercepting requests.</param>
    procedure Initialize(NewSharePointUrl: Text; ApiVersion: Enum "Graph API Version"; GraphAuthorization: Interface "Graph Authorization"; HttpClientHandler: Interface "Http Client Handler")
    begin
        SharePointGraphRequestHelper.Initialize(ApiVersion, GraphAuthorization, HttpClientHandler);
        InitializeCommon(NewSharePointUrl);
    end;

    /// <summary>
    /// Common initialization logic shared by all Initialize overloads.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    local procedure InitializeCommon(NewSharePointUrl: Text)
    begin
        // If we have a new URL, clear the cached IDs so they'll be re-acquired
        if SharePointUrl <> NewSharePointUrl then begin
            SharePointUrl := NewSharePointUrl;
            SiteId := '';
            DefaultDriveId := '';
        end;
        IsInitialized := true;
    end;

    local procedure GetSiteIdFromUrl(Url: Text)
    var
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
        HostName: Text;
        RelativePath: Text;
        Endpoint: Text;
    begin
        // Extract hostname and relative path from the URL
        HostName := ExtractHostName(Url);
        RelativePath := ExtractRelativePath(Url);

        if (HostName = '') or (RelativePath = '') then
            Error(InvalidSharePointUrlErr, Url);

        // Build the Graph endpoint to get site information
        Endpoint := SharePointGraphUriBuilder.GetSiteByHostAndPathEndpoint(HostName, RelativePath);

        if not SharePointGraphRequestHelper.Get(Endpoint, JsonResponse) then
            Error(RetrieveSiteInfoErr, SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase());

        if JsonResponse.Get('id', JsonToken) then
            SiteId := JsonToken.AsValue().AsText();
    end;

    local procedure GetDefaultDriveId()
    var
        JsonResponse: JsonObject;
        JsonToken: JsonToken;
    begin
        if SiteId = '' then
            exit;

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveEndpoint(), JsonResponse) then
            exit;

        if JsonResponse.Get('id', JsonToken) then
            DefaultDriveId := JsonToken.AsValue().AsText();
    end;

    local procedure ExtractHostName(Url: Text): Text
    var
        UriBuilder: Codeunit "Uri Builder";
    begin
        UriBuilder.Init(Url);
        exit(UriBuilder.GetHost()); // Returns contoso.sharepoint.com
    end;

    local procedure ExtractRelativePath(Url: Text): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Path: Text;
    begin
        UriBuilder.Init(Url);

        // Azure AD / Graph requires the path to start with '/'
        Path := UriBuilder.GetPath();

        // Guarantee at least '/'
        if Path = '' then
            Path := '/';

        exit(Path);
    end;

    local procedure EnsureInitialized()
    begin
        if not IsInitialized then
            Error(NotInitializedErr);
    end;

    #endregion

    #region Lists

    /// <summary>
    /// Gets all lists from the SharePoint site.
    /// </summary>
    /// <param name="GraphLists">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetLists(var GraphLists: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetLists(GraphLists, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets all lists from the SharePoint site.
    /// </summary>
    /// <param name="GraphLists">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetLists(var GraphLists: Record "SharePoint Graph List" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonArray: JsonArray;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Use Graph pagination to get all pages automatically
        if not SharePointGraphRequestHelper.GetAllPages(SharePointGraphUriBuilder.GetListsEndpoint(), GraphOptionalParameters, JsonArray) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveListsErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Parse the combined results from all pages
        if not SharePointGraphParser.ParseListCollection(JsonArray, GraphLists) then begin
            SharePointGraphResponse.SetError(FailedToParseListsErr);
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets a SharePoint list by ID.
    /// </summary>
    /// <param name="ListId">ID of the list to retrieve.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetList(ListId: Text; var GraphList: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetList(ListId, GraphList, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a SharePoint list by ID.
    /// </summary>
    /// <param name="ListId">ID of the list to retrieve.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetList(ListId: Text; var GraphList: Record "SharePoint Graph List" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if ListId = '' then begin
            SharePointGraphResponse.SetError(InvalidListIdErr);
            exit(SharePointGraphResponse);
        end;

        // Make the API request
        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetListEndpoint(ListId), JsonResponse, GraphOptionalParameters) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveListErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphList.Init();
        if not SharePointGraphParser.ParseListItem(JsonResponse, GraphList) then begin
            SharePointGraphResponse.SetError(FailedToParseListErr);
            exit(SharePointGraphResponse);
        end;
        GraphList.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Creates a new SharePoint list.
    /// </summary>
    /// <param name="DisplayName">Display name for the list.</param>
    /// <param name="Description">Description for the list.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure CreateList(DisplayName: Text; Description: Text; var GraphList: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(CreateList(DisplayName, 'genericList', Description, GraphList));
    end;

    /// <summary>
    /// Creates a new SharePoint list.
    /// </summary>
    /// <param name="DisplayName">Display name for the list.</param>
    /// <param name="ListTemplate">Template for the list (genericList, documentLibrary, etc.)</param>
    /// <param name="Description">Description for the list.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure CreateList(DisplayName: Text; ListTemplate: Text; Description: Text; var GraphList: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonResponse: JsonObject;
        RequestJsonObj: JsonObject;
        ListJsonObj: JsonObject;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if DisplayName = '' then begin
            SharePointGraphResponse.SetError(InvalidDisplayNameErr);
            exit(SharePointGraphResponse);
        end;

        // Create the request body with list properties
        RequestJsonObj.Add('displayName', DisplayName);
        RequestJsonObj.Add('description', Description);

        // Add list template
        ListJsonObj.Add('template', ListTemplate);
        RequestJsonObj.Add('list', ListJsonObj);

        // Post the request to create the list
        if not SharePointGraphRequestHelper.Post(SharePointGraphUriBuilder.GetListsEndpoint(), RequestJsonObj, JsonResponse) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToCreateListErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphList.Init();
        if not SharePointGraphParser.ParseListItem(JsonResponse, GraphList) then begin
            SharePointGraphResponse.SetError(FailedToParseCreatedListErr);
            exit(SharePointGraphResponse);
        end;
        GraphList.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    #endregion

    #region List Items

    /// <summary>
    /// Gets items from a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="GraphListItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetListItems(ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetListItems(ListId, GraphListItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items from a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="GraphListItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetListItems(ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonArray: JsonArray;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if ListId = '' then begin
            SharePointGraphResponse.SetError(InvalidListIdErr);
            exit(SharePointGraphResponse);
        end;

        // Use Graph pagination to get all pages automatically
        if not SharePointGraphRequestHelper.GetAllPages(SharePointGraphUriBuilder.GetListItemsEndpoint(ListId), GraphOptionalParameters, JsonArray) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveListItemsErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Parse the combined results from all pages
        if not SharePointGraphParser.ParseListItemCollection(JsonArray, ListId, GraphListItems) then begin
            SharePointGraphResponse.SetError(FailedToParseListItemsErr);
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Creates a new item in a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="FieldsJsonObject">JSON object containing the fields for the new item.</param>
    /// <param name="GraphListItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure CreateListItem(ListId: Text; FieldsJsonObject: JsonObject; var GraphListItem: Record "SharePoint Graph List Item" temporary): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonResponse: JsonObject;
        RequestJsonObj: JsonObject;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if ListId = '' then begin
            SharePointGraphResponse.SetError(InvalidListIdErr);
            exit(SharePointGraphResponse);
        end;

        // Create the request body with fields
        RequestJsonObj.Add('fields', FieldsJsonObject);

        // Post the request to create the item
        if not SharePointGraphRequestHelper.Post(SharePointGraphUriBuilder.GetCreateListItemEndpoint(ListId), RequestJsonObj, JsonResponse) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToCreateListItemErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphListItem.Init();
        GraphListItem.ListId := CopyStr(ListId, 1, MaxStrLen(GraphListItem.ListId));
        if not SharePointGraphParser.ParseListItemDetail(JsonResponse, GraphListItem) then begin
            SharePointGraphResponse.SetError(FailedToParseCreatedListItemErr);
            exit(SharePointGraphResponse);
        end;
        GraphListItem.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Creates a new item in a SharePoint list with a simple title.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="Title">Title for the new item.</param>
    /// <param name="GraphListItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure CreateListItem(ListId: Text; Title: Text; var GraphListItem: Record "SharePoint Graph List Item" temporary): Codeunit "SharePoint Graph Response"
    var
        FieldsJsonObject: JsonObject;
    begin
        FieldsJsonObject.Add('Title', Title);
        exit(CreateListItem(ListId, FieldsJsonObject, GraphListItem));
    end;

    #endregion

    #region Drive and Items

    /// <summary>
    /// Gets the default document library (drive) for the site.
    /// </summary>
    /// <param name="DriveId">ID of the default drive.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDefaultDrive(var DriveId: Text): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        EnsureInitialized();
        EnsureSiteId();
        EnsureDefaultDriveId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Get default drive ID if not already cached
        if DefaultDriveId = '' then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveDefaultDriveErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        DriveId := DefaultDriveId;
        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets all drives (document libraries) available on the site with detailed information.
    /// </summary>
    /// <param name="GraphDrives">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDrives(var GraphDrives: Record "SharePoint Graph Drive" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetDrives(GraphDrives, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets all drives (document libraries) available on the site with detailed information.
    /// </summary>
    /// <param name="GraphDrives">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDrives(var GraphDrives: Record "SharePoint Graph Drive" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonArray: JsonArray;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Use Graph pagination to get all pages automatically
        if not SharePointGraphRequestHelper.GetAllPages(SharePointGraphUriBuilder.GetDrivesEndpoint(), GraphOptionalParameters, JsonArray) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveDrivesErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Parse the combined results from all pages
        if not SharePointGraphParser.ParseDriveCollection(JsonArray, GraphDrives) then begin
            SharePointGraphResponse.SetError(FailedToParseDrivesErr);
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets a drive (document library) by ID with detailed information.
    /// </summary>
    /// <param name="DriveId">ID of the drive to retrieve.</param>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDrive(DriveId: Text; var GraphDrive: Record "SharePoint Graph Drive" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetDrive(DriveId, GraphDrive, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a drive (document library) by ID with detailed information.
    /// </summary>
    /// <param name="DriveId">ID of the drive to retrieve.</param>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDrive(DriveId: Text; var GraphDrive: Record "SharePoint Graph Drive" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonResponse: JsonObject;
        DriveEndpoint: Text;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if DriveId = '' then begin
            SharePointGraphResponse.SetError(InvalidDriveIdErr);
            exit(SharePointGraphResponse);
        end;

        // Construct drive endpoint for specific drive ID
        DriveEndpoint := SharePointGraphUriBuilder.GetSiteEndpoint() + '/drives/' + DriveId;

        // Make the API request
        if not SharePointGraphRequestHelper.Get(DriveEndpoint, JsonResponse, GraphOptionalParameters) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveDriveErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphDrive.Init();
        if not SharePointGraphParser.ParseDriveDetail(JsonResponse, GraphDrive) then begin
            SharePointGraphResponse.SetError(FailedToParseDriveErr);
            exit(SharePointGraphResponse);
        end;
        GraphDrive.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets the default document library (drive) for the site with detailed information.
    /// </summary>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDefaultDrive(var GraphDrive: Record "SharePoint Graph Drive" temporary): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Make the API request
        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveEndpoint(), JsonResponse, GraphOptionalParameters) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveDefaultDriveErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphDrive.Init();
        if not SharePointGraphParser.ParseDriveDetail(JsonResponse, GraphDrive) then begin
            SharePointGraphResponse.SetError(FailedToParseDriveErr);
            exit(SharePointGraphResponse);
        end;
        GraphDrive.Insert();

        // Update DefaultDriveId while we're at it
        DefaultDriveId := CopyStr(GraphDrive.Id, 1, MaxStrLen(DefaultDriveId));

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets items in the root folder of the default drive.
    /// </summary>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetRootItems(var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetRootItems(GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items in the root folder of the default drive.
    /// </summary>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetRootItems(var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonArray: JsonArray;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Ensure we have Default Drive ID
        EnsureDefaultDriveId();
        if DefaultDriveId = '' then begin
            SharePointGraphResponse.SetError(NoDefaultDriveIdErr);
            exit(SharePointGraphResponse);
        end;

        // Use Graph pagination to get all pages automatically
        if not SharePointGraphRequestHelper.GetAllPages(SharePointGraphUriBuilder.GetDriveRootChildrenEndpoint(), GraphOptionalParameters, JsonArray) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveRootItemsErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Parse the combined results from all pages
        if not SharePointGraphParser.ParseDriveItemCollection(JsonArray, DefaultDriveId, GraphDriveItems) then begin
            SharePointGraphResponse.SetError(FailedToParseRootItemsErr);
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets children of a folder by the folder's ID.
    /// </summary>
    /// <param name="FolderId">ID of the folder.</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetFolderItems(FolderId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetFolderItems(FolderId, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets children of a folder by the folder's ID.
    /// </summary>
    /// <param name="FolderId">ID of the folder.</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetFolderItems(FolderId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonArray: JsonArray;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if FolderId = '' then begin
            SharePointGraphResponse.SetError(InvalidFolderIdErr);
            exit(SharePointGraphResponse);
        end;

        // Ensure we have Default Drive ID
        EnsureDefaultDriveId();
        if DefaultDriveId = '' then begin
            SharePointGraphResponse.SetError(NoDefaultDriveIdErr);
            exit(SharePointGraphResponse);
        end;

        // Use Graph pagination to get all pages automatically
        if not SharePointGraphRequestHelper.GetAllPages(SharePointGraphUriBuilder.GetDriveItemChildrenByIdEndpoint(FolderId), GraphOptionalParameters, JsonArray) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveFolderItemsErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Parse the combined results from all pages
        if not SharePointGraphParser.ParseDriveItemCollection(JsonArray, DefaultDriveId, GraphDriveItems) then begin
            SharePointGraphResponse.SetError(FailedToParseFolderItemsErr);
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets items from a path in the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetItemsByPath(FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetItemsByPath(FolderPath, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items from a path in the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetItemsByPath(FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonArray: JsonArray;
    begin
        EnsureInitialized();
        EnsureSiteId();
        EnsureDefaultDriveId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Handle empty path as root
        if FolderPath = '' then
            exit(GetRootItems(GraphDriveItems, GraphOptionalParameters));

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        // Use Graph pagination to get all pages automatically
        if not SharePointGraphRequestHelper.GetAllPages(SharePointGraphUriBuilder.GetDriveItemChildrenByPathEndpoint(FolderPath), GraphOptionalParameters, JsonArray) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveItemsByPathErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Parse the combined results from all pages
        if not SharePointGraphParser.ParseDriveItemCollection(JsonArray, DefaultDriveId, GraphDriveItems) then begin
            SharePointGraphResponse.SetError(FailedToParseItemsByPathErr);
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Uploads a file to a folder in a specific drive (document library) with specified conflict behavior.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a file with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        JsonResponse: JsonObject;
        EffectiveDriveId: Text;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if FileName = '' then begin
            SharePointGraphResponse.SetError(InvalidFileNameErr);
            exit(SharePointGraphResponse);
        end;

        // Use default drive ID if none specified
        if DriveId = '' then begin
            EnsureDefaultDriveId();
            EffectiveDriveId := DefaultDriveId;
        end else
            EffectiveDriveId := DriveId;

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        // Configure conflict behavior
        SharePointGraphRequestHelper.ConfigureConflictBehavior(GraphOptionalParameters, ConflictBehavior);

        // Put the file content in the specific drive
        if not SharePointGraphRequestHelper.UploadFile(SharePointGraphUriBuilder.GetSpecificDriveUploadEndpoint(EffectiveDriveId, FolderPath, FileName), FileInStream, GraphOptionalParameters, JsonResponse) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToUploadFileErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(EffectiveDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        if not SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem) then begin
            SharePointGraphResponse.SetError(FailedToParseUploadedFileErr);
            exit(SharePointGraphResponse);
        end;
        GraphDriveItem.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Uploads a file to a folder in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(UploadFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem, Enum::"Graph ConflictBehavior"::Replace));
    end;

    /// <summary>
    /// Uploads a large file to a folder on SharePoint using chunked upload for better performance and reliability.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library), or empty for default drive.</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure UploadLargeFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphConflictBehavior: Enum "Graph ConflictBehavior";
    begin
        exit(UploadLargeFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem, GraphConflictBehavior::Replace));
    end;

    /// <summary>
    /// Uploads a large file to a folder on SharePoint using chunked upload with specified conflict behavior.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library), or empty for default drive.</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a file with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure UploadLargeFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        TempBlob: Codeunit "Temp Blob";
        ChunkInStream: InStream;
        ChunkOutStream: OutStream;
        JsonResponse: JsonObject;
        CompleteResponseJson: JsonObject;
        Endpoint: Text;
        UploadUrl: Text;
        ContentRange: Text;
        EffectiveDriveId: Text;
        FileSize: Integer;
        ChunkSize: Integer;
        BytesInChunk: Integer;
        TotalBytesRead: Integer;
        MinChunkSize: Integer;
        ChunkMultiple: Integer;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if FileName = '' then begin
            SharePointGraphResponse.SetError(InvalidFileNameErr);
            exit(SharePointGraphResponse);
        end;

        // Use default drive ID if none specified
        if DriveId = '' then begin
            EnsureDefaultDriveId();
            if DefaultDriveId = '' then begin
                SharePointGraphResponse.SetError(NoDefaultDriveIdErr);
                exit(SharePointGraphResponse);
            end;
            EffectiveDriveId := DefaultDriveId;
        end else
            EffectiveDriveId := DriveId;

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        // Configure conflict behavior
        SharePointGraphRequestHelper.ConfigureConflictBehavior(GraphOptionalParameters, ConflictBehavior);

        // Prepare the upload session endpoint
        if EffectiveDriveId = DefaultDriveId then
            Endpoint := SharePointGraphUriBuilder.GetDriveItemByPathEndpoint(FolderPath + '/' + FileName)
        else
            Endpoint := SharePointGraphUriBuilder.GetSpecificDriveUploadEndpoint(EffectiveDriveId, FolderPath, FileName);

        FileSize := FileInStream.Length();
        if FileSize <= 0 then begin
            SharePointGraphResponse.SetError(InvalidFileSizeErr);
            exit(SharePointGraphResponse);
        end;

        // Create upload session
        if not SharePointGraphRequestHelper.CreateUploadSession(Endpoint, FileName, FileSize, GraphOptionalParameters, ConflictBehavior, UploadUrl) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToCreateUploadSessionErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        // Microsoft requires chunks to be multiples of 320 KiB (327,680 bytes)
        ChunkMultiple := 320 * 1024; // 320 KiB
        MinChunkSize := ChunkMultiple; // Minimum allowed size

        // Use 4 MB chunks as recommended by Microsoft for optimum performance
        ChunkSize := 4 * 1024 * 1024; // 4 MB

        // Ensure chunk size is a multiple of 320 KiB
        ChunkSize := Round(ChunkSize / ChunkMultiple, 1, '<') * ChunkMultiple;

        // For small files, use at least the minimum size but ensure it doesn't exceed file size
        if FileSize < ChunkSize then
            ChunkSize := MinChunkSize;

        // Reset the stream position to beginning
        FileInStream.ResetPosition();
        TotalBytesRead := 0;

        // Read and upload chunks until the entire file is uploaded
        while TotalBytesRead < FileSize do begin
            // Clear temp blob for new chunk
            Clear(TempBlob);
            TempBlob.CreateOutStream(ChunkOutStream);

            // Determine bytes to copy in this chunk
            BytesInChunk := ChunkSize;
            if (FileSize - TotalBytesRead) < ChunkSize then
                // For the last chunk, ensure it's still a multiple of 320 KiB unless it's the final remainder
                if (FileSize - TotalBytesRead) > MinChunkSize then
                    BytesInChunk := Round((FileSize - TotalBytesRead) / ChunkMultiple, 1, '<') * ChunkMultiple
                else
                    BytesInChunk := FileSize - TotalBytesRead;

            // Copy directly from source stream into the chunk stream
            CopyStream(ChunkOutStream, FileInStream, BytesInChunk);

            // Prepare content range header - must follow format "bytes startPosition-endPosition/totalSize"
            ContentRange := StrSubstNo(ContentRangeHeaderLbl,
                            TotalBytesRead,
                            TotalBytesRead + BytesInChunk - 1,
                            FileSize);

            // Get the input stream for the chunk
            TempBlob.CreateInStream(ChunkInStream);

            // Upload the chunk - use the exact URL returned from the upload session without modification
            if not SharePointGraphRequestHelper.UploadChunk(UploadUrl, ChunkInStream, ContentRange, JsonResponse) then begin
                SharePointGraphResponse.SetError(StrSubstNo(FailedToUploadChunkErr,
                    SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
                exit(SharePointGraphResponse);
            end;

            // Check if upload is complete (last chunk response will contain the item details)
            if JsonResponse.Contains('id') then
                CompleteResponseJson := JsonResponse;

            // Update total bytes read
            TotalBytesRead += BytesInChunk;
        end;

        if not CompleteResponseJson.Contains('id') then begin
            SharePointGraphResponse.SetError(NoUploadResponseErr);
            exit(SharePointGraphResponse);
        end;

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(EffectiveDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        if not SharePointGraphParser.ParseDriveItemDetail(CompleteResponseJson, GraphDriveItem) then begin
            SharePointGraphResponse.SetError(FailedToParseChunkedUploadErr);
            exit(SharePointGraphResponse);
        end;
        GraphDriveItem.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Creates a new folder in a specific drive (document library) with specified conflict behavior.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a folder with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure CreateFolder(DriveId: Text; FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        JsonResponse: JsonObject;
        RequestJsonObj: JsonObject;
        FolderJsonObj: JsonObject;
        Endpoint: Text;
        EffectiveDriveId: Text;
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if FolderName = '' then begin
            SharePointGraphResponse.SetError(InvalidFolderNameErr);
            exit(SharePointGraphResponse);
        end;

        // Use default drive ID if none specified
        if DriveId = '' then begin
            EnsureDefaultDriveId();
            EffectiveDriveId := DefaultDriveId;
        end else
            EffectiveDriveId := DriveId;

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        // Create the request body with folder properties
        RequestJsonObj.Add('name', FolderName);
        RequestJsonObj.Add('folder', FolderJsonObj);

        // Configure conflict behavior
        SharePointGraphRequestHelper.ConfigureConflictBehavior(GraphOptionalParameters, ConflictBehavior);

        // Set endpoint for creating folder in specific drive
        if FolderPath = '' then
            Endpoint := SharePointGraphUriBuilder.GetSpecificDriveRootChildrenEndpoint(EffectiveDriveId)
        else
            Endpoint := SharePointGraphUriBuilder.GetSpecificDriveItemChildrenByPathEndpoint(EffectiveDriveId, FolderPath);

        // Post the request to create the folder
        if not SharePointGraphRequestHelper.Post(Endpoint, RequestJsonObj, GraphOptionalParameters, JsonResponse) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToCreateFolderErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(EffectiveDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        if not SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem) then begin
            SharePointGraphResponse.SetError(FailedToParseCreatedFolderErr);
            exit(SharePointGraphResponse);
        end;
        GraphDriveItem.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Creates a new folder in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure CreateFolder(DriveId: Text; FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(CreateFolder(DriveId, FolderPath, FolderName, GraphDriveItem, Enum::"Graph ConflictBehavior"::Fail));
    end;

    /// <summary>
    /// Downloads a file.
    /// </summary>
    /// <param name="ItemId">ID of the file to download.</param>
    /// <param name="FileInStream">InStream to receive the file content.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure DownloadFile(ItemId: Text; var FileInStream: InStream): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if ItemId = '' then begin
            SharePointGraphResponse.SetError(InvalidItemIdErr);
            exit(SharePointGraphResponse);
        end;

        // Make the API request
        if not SharePointGraphRequestHelper.DownloadFile(SharePointGraphUriBuilder.GetDriveItemContentByIdEndpoint(ItemId), FileInStream) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToDownloadFileErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Downloads a file by path.
    /// </summary>
    /// <param name="FilePath">Path to the file (e.g., 'Documents/file.docx').</param>
    /// <param name="FileInStream">InStream to receive the file content.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure DownloadFileByPath(FilePath: Text; var FileInStream: InStream): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
    begin
        EnsureInitialized();
        EnsureSiteId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if FilePath = '' then begin
            SharePointGraphResponse.SetError(InvalidFilePathErr);
            exit(SharePointGraphResponse);
        end;

        // Remove leading slash if present
        if FilePath.StartsWith('/') then
            FilePath := CopyStr(FilePath, 2);

        // Make the API request
        if not SharePointGraphRequestHelper.DownloadFile(SharePointGraphUriBuilder.GetDriveItemContentByPathEndpoint(FilePath), FileInStream) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToDownloadFileByPathErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets a file or folder by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to retrieve.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDriveItem(ItemId: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetDriveItem(ItemId, GraphDriveItem, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a file or folder by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx').</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDriveItemByPath(ItemPath: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetDriveItemByPath(ItemPath, GraphDriveItem, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a file or folder by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx').</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDriveItemByPath(ItemPath: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();
        EnsureSiteId();
        EnsureDefaultDriveId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if ItemPath = '' then begin
            SharePointGraphResponse.SetError(InvalidItemPathErr);
            exit(SharePointGraphResponse);
        end;

        // Remove leading slash if present
        if ItemPath.StartsWith('/') then
            ItemPath := CopyStr(ItemPath, 2);

        // Make the API request
        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveItemByPathEndpoint(ItemPath), JsonResponse, GraphOptionalParameters) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveDriveItemByPathErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(DefaultDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        if not SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem) then begin
            SharePointGraphResponse.SetError(FailedToParseDriveItemByPathErr);
            exit(SharePointGraphResponse);
        end;
        GraphDriveItem.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    /// <summary>
    /// Gets a file or folder by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to retrieve.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    procedure GetDriveItem(ItemId: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    var
        SharePointGraphResponse: Codeunit "SharePoint Graph Response";
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();
        EnsureSiteId();
        EnsureDefaultDriveId();

        SharePointGraphResponse.SetRequestHelper(SharePointGraphRequestHelper);

        // Validate input
        if ItemId = '' then begin
            SharePointGraphResponse.SetError(InvalidItemIdErr);
            exit(SharePointGraphResponse);
        end;

        // Make the API request
        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveItemByIdEndpoint(ItemId), JsonResponse, GraphOptionalParameters) then begin
            SharePointGraphResponse.SetError(StrSubstNo(FailedToRetrieveDriveItemErr,
                SharePointGraphRequestHelper.GetDiagnostics().GetResponseReasonPhrase()));
            exit(SharePointGraphResponse);
        end;

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(DefaultDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        if not SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem) then begin
            SharePointGraphResponse.SetError(FailedToParseDriveItemErr);
            exit(SharePointGraphResponse);
        end;
        GraphDriveItem.Insert();

        SharePointGraphResponse.SetSuccess();
        exit(SharePointGraphResponse);
    end;

    #endregion

    /// <summary>
    /// Returns detailed information on last API call.
    /// </summary>
    /// <returns>Codeunit holding http response status, reason phrase, headers and possible error information for the last API call</returns>
    procedure GetDiagnostics(): Interface "HTTP Diagnostics"
    begin
        exit(SharePointGraphRequestHelper.GetDiagnostics());
    end;

    /// <summary>
    /// Sets the site ID directly for testing purposes.
    /// </summary>
    /// <param name="NewSiteId">The site ID to set.</param>
    internal procedure SetSiteIdForTesting(NewSiteId: Text)
    begin
        SiteId := NewSiteId;
        SharePointGraphUriBuilder.Initialize(SiteId, SharePointGraphRequestHelper);
    end;

    /// <summary>
    /// Sets the default drive ID directly for testing purposes.
    /// </summary>
    /// <param name="NewDefaultDriveId">The default drive ID to set.</param>
    internal procedure SetDefaultDriveIdForTesting(NewDefaultDriveId: Text)
    begin
        DefaultDriveId := NewDefaultDriveId;
    end;

    // Add this method to lazily load the default drive ID
    local procedure EnsureDefaultDriveId()
    begin
        if DefaultDriveId = '' then
            GetDefaultDriveId();
    end;

    // Add method to lazily load the site ID
    local procedure EnsureSiteId()
    begin
        if SiteId = '' then begin
            GetSiteIdFromUrl(SharePointUrl);
            SharePointGraphUriBuilder.Initialize(SiteId, SharePointGraphRequestHelper);
        end;
    end;
}