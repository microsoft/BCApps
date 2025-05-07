// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

using System.Integration.Graph;
using System.Integration.Graph.Authorization;
using System.Utilities;

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
        SharePointGraphParser: Codeunit "SharePoint Graph Parser";
        SharePointGraphUriBuilder: Codeunit "SharePoint Graph Uri Builder";
        SharePointDiagnostics: Codeunit "SharePoint Diagnostics";
        SiteId: Text;
        SharePointUrl: Text;
        DefaultDriveId: Text;
        IsInitialized: Boolean;
        NotInitializedErr: Label 'SharePoint Graph Client is not initialized. Call Initialize first.';
        InvalidSharePointUrlErr: Label 'Invalid SharePoint URL ''%1''.', Comment = '%1 = URL string';
        RetrieveSiteInfoErr: Label 'Failed to retrieve SharePoint site information from Graph API. %1', Comment = '%1 = Error message';
        DefaultListTemplateLbl: Label 'genericList', Locked = true;

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
    /// Common initialization logic shared by all Initialize overloads.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    local procedure InitializeCommon(NewSharePointUrl: Text)
    begin
        SharePointUrl := NewSharePointUrl;
        GetSiteIdFromUrl(NewSharePointUrl);
        SharePointGraphUriBuilder.Initialize(SiteId, SharePointGraphRequestHelper);
        GetDefaultDriveId();
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
            Error(RetrieveSiteInfoErr, SharePointDiagnostics.GetResponseReasonPhrase());

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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetLists(var GraphLists: Record "SharePoint Graph List" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetLists(var GraphLists: Record "SharePoint Graph List" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetListsEndpoint(), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseListCollection(JsonResponse, GraphLists) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseListCollection(JsonResponse, GraphLists) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Gets a SharePoint list by ID.
    /// </summary>
    /// <param name="ListId">ID of the list to retrieve.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetList(ListId: Text; var GraphList: Record "SharePoint Graph List" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetList(ListId: Text; var GraphList: Record "SharePoint Graph List" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetListEndpoint(ListId), JsonResponse, GraphOptionalParameters) then
            exit(false);

        GraphList.Init();
        SharePointGraphParser.ParseListItem(JsonResponse, GraphList);
        GraphList.Insert();

        exit(true);
    end;

    /// <summary>
    /// Creates a new SharePoint list.
    /// </summary>
    /// <param name="DisplayName">Display name for the list.</param>
    /// <param name="Description">Description for the list.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure CreateList(DisplayName: Text; Description: Text; var GraphList: Record "SharePoint Graph List" temporary): Boolean
    begin
        exit(CreateList(DisplayName, DefaultListTemplateLbl, Description, GraphList));
    end;

    /// <summary>
    /// Creates a new SharePoint list.
    /// </summary>
    /// <param name="DisplayName">Display name for the list.</param>
    /// <param name="ListTemplate">Template for the list (genericList, documentLibrary, etc.)</param>
    /// <param name="Description">Description for the list.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure CreateList(DisplayName: Text; ListTemplate: Text; Description: Text; var GraphList: Record "SharePoint Graph List" temporary): Boolean
    var
        JsonResponse: JsonObject;
        RequestJsonObj: JsonObject;
        ListJsonObj: JsonObject;
    begin
        EnsureInitialized();

        // Create the request body with list properties
        RequestJsonObj.Add('displayName', DisplayName);
        RequestJsonObj.Add('description', Description);

        // Add list template
        ListJsonObj.Add('template', ListTemplate);
        RequestJsonObj.Add('list', ListJsonObj);

        // Post the request to create the list
        if not SharePointGraphRequestHelper.Post(SharePointGraphUriBuilder.GetListsEndpoint(), RequestJsonObj, JsonResponse) then
            exit(false);

        GraphList.Init();
        SharePointGraphParser.ParseListItem(JsonResponse, GraphList);
        GraphList.Insert();

        exit(true);
    end;

    #endregion

    #region List Items

    /// <summary>
    /// Gets items from a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="GraphListItems">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetListItems(ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetListItems(ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetListItemsEndpoint(ListId), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseListItemCollection(JsonResponse, ListId, GraphListItems) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseListItemCollection(JsonResponse, ListId, GraphListItems) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Creates a new item in a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="FieldsJsonObject">JSON object containing the fields for the new item.</param>
    /// <param name="GraphListItem">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure CreateListItem(ListId: Text; FieldsJsonObject: JsonObject; var GraphListItem: Record "SharePoint Graph List Item" temporary): Boolean
    var
        JsonResponse: JsonObject;
        RequestJsonObj: JsonObject;
    begin
        EnsureInitialized();

        // Create the request body with fields
        RequestJsonObj.Add('fields', FieldsJsonObject);

        // Post the request to create the item
        if not SharePointGraphRequestHelper.Post(SharePointGraphUriBuilder.GetCreateListItemEndpoint(ListId), RequestJsonObj, JsonResponse) then
            exit(false);

        GraphListItem.Init();
        GraphListItem.ListId := CopyStr(ListId, 1, MaxStrLen(GraphListItem.ListId));
        SharePointGraphParser.ParseListItemDetail(JsonResponse, GraphListItem);
        GraphListItem.Insert();

        exit(true);
    end;

    /// <summary>
    /// Creates a new item in a SharePoint list with a simple title.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="Title">Title for the new item.</param>
    /// <param name="GraphListItem">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure CreateListItem(ListId: Text; Title: Text; var GraphListItem: Record "SharePoint Graph List Item" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDefaultDrive(var DriveId: Text): Boolean
    begin
        EnsureInitialized();
        DriveId := DefaultDriveId;
        exit(DriveId <> '');
    end;

    /// <summary>
    /// Gets all drives (document libraries) available on the site with detailed information.
    /// </summary>
    /// <param name="GraphDrives">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDrives(var GraphDrives: Record "SharePoint Graph Drive" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDrives(var GraphDrives: Record "SharePoint Graph Drive" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDrivesEndpoint(), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseDriveCollection(JsonResponse, GraphDrives) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseDriveCollection(JsonResponse, GraphDrives) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Gets a drive (document library) by ID with detailed information.
    /// </summary>
    /// <param name="DriveId">ID of the drive to retrieve.</param>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDrive(DriveId: Text; var GraphDrive: Record "SharePoint Graph Drive" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDrive(DriveId: Text; var GraphDrive: Record "SharePoint Graph Drive" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        DriveEndpoint: Text;
    begin
        EnsureInitialized();

        // Construct drive endpoint for specific drive ID
        DriveEndpoint := SharePointGraphUriBuilder.GetSiteEndpoint() + '/drives/' + DriveId;

        if not SharePointGraphRequestHelper.Get(DriveEndpoint, JsonResponse, GraphOptionalParameters) then
            exit(false);

        GraphDrive.Init();
        SharePointGraphParser.ParseDriveDetail(JsonResponse, GraphDrive);
        GraphDrive.Insert();

        exit(true);
    end;

    /// <summary>
    /// Gets the default document library (drive) for the site with detailed information.
    /// </summary>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDefaultDrive(var GraphDrive: Record "SharePoint Graph Drive" temporary): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveEndpoint(), JsonResponse, GraphOptionalParameters) then
            exit(false);

        GraphDrive.Init();
        SharePointGraphParser.ParseDriveDetail(JsonResponse, GraphDrive);
        GraphDrive.Insert();

        exit(true);
    end;

    /// <summary>
    /// Gets items in the root folder of the default drive.
    /// </summary>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetRootItems(var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetRootItems(GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets children of a folder by the folder's ID.
    /// </summary>
    /// <param name="FolderId">ID of the folder.</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetFolderItems(FolderId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetFolderItems(FolderId, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items from a path in the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetItemsByPath(FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetItemsByPath(FolderPath, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a file or folder by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to retrieve.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDriveItem(ItemId: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDriveItemByPath(ItemPath: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Boolean
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDriveItemByPath(ItemPath: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();

        // Remove leading slash if present
        if ItemPath.StartsWith('/') then
            ItemPath := CopyStr(ItemPath, 2);

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveItemByPathEndpoint(ItemPath), JsonResponse, GraphOptionalParameters) then
            exit(false);

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(DefaultDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem);
        GraphDriveItem.Insert();

        exit(true);
    end;

    /// <summary>
    /// Gets a file or folder by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to retrieve.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetDriveItem(ItemId: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveItemByIdEndpoint(ItemId), JsonResponse, GraphOptionalParameters) then
            exit(false);

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(DefaultDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem);
        GraphDriveItem.Insert();

        exit(true);
    end;

    /// <summary>
    /// Gets items from a path in the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetItemsByPath(FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        // Handle empty path as root
        if FolderPath = '' then
            exit(GetRootItems(GraphDriveItems, GraphOptionalParameters));

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveItemChildrenByPathEndpoint(FolderPath), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DefaultDriveId, GraphDriveItems) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DefaultDriveId, GraphDriveItems) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Gets children of a folder by the folder's ID.
    /// </summary>
    /// <param name="FolderId">ID of the folder.</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetFolderItems(FolderId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveItemChildrenByIdEndpoint(FolderId), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DefaultDriveId, GraphDriveItems) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DefaultDriveId, GraphDriveItems) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Gets items in the root folder of the default drive.
    /// </summary>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetRootItems(var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetDriveRootChildrenEndpoint(), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DefaultDriveId, GraphDriveItems) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DefaultDriveId, GraphDriveItems) then
                exit(false);
        end;

        exit(true);
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
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; var FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        JsonResponse: JsonObject;
        EffectiveDriveId: Text;
    begin
        EnsureInitialized();

        // Use default drive ID if none specified
        if DriveId = '' then
            EffectiveDriveId := DefaultDriveId
        else
            EffectiveDriveId := DriveId;

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        // Configure conflict behavior
        SharePointGraphRequestHelper.ConfigureConflictBehavior(GraphOptionalParameters, ConflictBehavior);

        // Put the file content in the specific drive
        if not SharePointGraphRequestHelper.UploadFile(SharePointGraphUriBuilder.GetSpecificDriveUploadEndpoint(EffectiveDriveId, FolderPath, FileName), FileInStream, GraphOptionalParameters, JsonResponse) then
            exit(false);

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(EffectiveDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem);
        GraphDriveItem.Insert();

        exit(true);
    end;

    /// <summary>
    /// Uploads a file to a folder in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; var FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Boolean
    begin
        exit(UploadFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem, Enum::"Graph ConflictBehavior"::Fail));
    end;

    /// <summary>
    /// Creates a new folder in a specific drive (document library) with specified conflict behavior.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a folder with the same name exists</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure CreateFolder(DriveId: Text; FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        JsonResponse: JsonObject;
        RequestJsonObj: JsonObject;
        FolderJsonObj: JsonObject;
        Endpoint: Text;
        EffectiveDriveId: Text;
    begin
        EnsureInitialized();

        // Use default drive ID if none specified
        if DriveId = '' then
            EffectiveDriveId := DefaultDriveId
        else
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
        if not SharePointGraphRequestHelper.Post(Endpoint, RequestJsonObj, GraphOptionalParameters, JsonResponse) then
            exit(false);

        GraphDriveItem.Init();
        GraphDriveItem.DriveId := CopyStr(EffectiveDriveId, 1, MaxStrLen(GraphDriveItem.DriveId));
        SharePointGraphParser.ParseDriveItemDetail(JsonResponse, GraphDriveItem);
        GraphDriveItem.Insert();

        exit(true);
    end;

    /// <summary>
    /// Creates a new folder in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure CreateFolder(DriveId: Text; FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Boolean
    begin
        exit(CreateFolder(DriveId, FolderPath, FolderName, GraphDriveItem, Enum::"Graph ConflictBehavior"::Fail));
    end;

    /// <summary>
    /// Downloads a file.
    /// </summary>
    /// <param name="ItemId">ID of the file to download.</param>
    /// <param name="FileInStream">InStream to receive the file content.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure DownloadFile(ItemId: Text; var FileInStream: InStream): Boolean
    begin
        EnsureInitialized();
        exit(SharePointGraphRequestHelper.DownloadFile(SharePointGraphUriBuilder.GetDriveItemContentByIdEndpoint(ItemId), FileInStream));
    end;

    /// <summary>
    /// Downloads a file by path.
    /// </summary>
    /// <param name="FilePath">Path to the file (e.g., 'Documents/file.docx').</param>
    /// <param name="FileInStream">InStream to receive the file content.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure DownloadFileByPath(FilePath: Text; var FileInStream: InStream): Boolean
    begin
        EnsureInitialized();

        // Remove leading slash if present
        if FilePath.StartsWith('/') then
            FilePath := CopyStr(FilePath, 2);

        exit(SharePointGraphRequestHelper.DownloadFile(SharePointGraphUriBuilder.GetDriveItemContentByPathEndpoint(FilePath), FileInStream));
    end;

    /// <summary>
    /// Gets items from a path in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetItemsByPathInDrive(DriveId: Text; FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetItemsByPathInDrive(DriveId, FolderPath, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items from a path in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetItemsByPathInDrive(DriveId: Text; FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if DriveId = '' then
            exit(GetItemsByPath(FolderPath, GraphDriveItems, GraphOptionalParameters));

        // Handle empty path as root
        if FolderPath = '' then
            exit(GetRootItemsInDrive(DriveId, GraphDriveItems, GraphOptionalParameters));

        // Remove leading slash if present
        if FolderPath.StartsWith('/') then
            FolderPath := CopyStr(FolderPath, 2);

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetSpecificDriveItemChildrenByPathEndpoint(DriveId, FolderPath), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DriveId, GraphDriveItems) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DriveId, GraphDriveItems) then
                exit(false);
        end;

        exit(true);
    end;

    /// <summary>
    /// Gets items in the root folder of a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetRootItemsInDrive(DriveId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
    begin
        exit(GetRootItemsInDrive(DriveId, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items in the root folder of a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>True if the operation was successful; otherwise - false.</returns>
    procedure GetRootItemsInDrive(DriveId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        JsonResponse: JsonObject;
        NextLink: Text;
    begin
        EnsureInitialized();

        if DriveId = '' then
            exit(GetRootItems(GraphDriveItems, GraphOptionalParameters));

        if not SharePointGraphRequestHelper.Get(SharePointGraphUriBuilder.GetSpecificDriveRootChildrenEndpoint(DriveId), JsonResponse, GraphOptionalParameters) then
            exit(false);

        if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DriveId, GraphDriveItems) then
            exit(false);

        // Handle pagination
        while SharePointGraphParser.ExtractNextLink(JsonResponse, NextLink) do begin
            Clear(JsonResponse);

            if not SharePointGraphRequestHelper.GetNextPage(NextLink, JsonResponse) then
                exit(false);

            if not SharePointGraphParser.ParseDriveItemCollection(JsonResponse, DriveId, GraphDriveItems) then
                exit(false);
        end;

        exit(true);
    end;

    #endregion

    /// <summary>
    /// Returns detailed information on last API call.
    /// </summary>
    /// <returns>Codeunit holding http response status, reason phrase, headers and possible error information for the last API call</returns>
    procedure GetDiagnostics(): Interface "HTTP Diagnostics"
    begin
        exit(SharePointDiagnostics);
    end;
}