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
/// Provides functionality for interacting with SharePoint through Microsoft Graph API.
/// </summary>
/// <remarks>
/// Each procedure documents the required Microsoft Graph application permission (Sites.Read.All, Sites.ReadWrite.All, or Sites.Manage.All).
/// Alternatively, the Sites.Selected permission can be used to restrict access to specific sites. With Sites.Selected, the actual access level
/// is determined by the role (read, write, fullcontrol) granted per-site via the /sites/{siteId}/permissions endpoint.
/// </remarks>
codeunit 9119 "SharePoint Graph Client"
{
    Access = Public;

    var
        SharePointGraphClientImpl: Codeunit "SharePoint Graph Client Impl.";

    #region Initialization

    /// <summary>
    /// Initializes SharePoint Graph client.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure Initialize(NewSharePointUrl: Text; GraphAuthorization: Interface "Graph Authorization")
    begin
        SharePointGraphClientImpl.Initialize(NewSharePointUrl, GraphAuthorization);
    end;

    /// <summary>
    /// Initializes SharePoint Graph client with a specific API version.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="ApiVersion">The Graph API version to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure Initialize(NewSharePointUrl: Text; ApiVersion: Enum "Graph API Version"; GraphAuthorization: Interface "Graph Authorization")
    begin
        SharePointGraphClientImpl.Initialize(NewSharePointUrl, ApiVersion, GraphAuthorization);
    end;

    /// <summary>
    /// Initializes SharePoint Graph client with a custom base URL.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="BaseUrl">The custom base URL for Graph API.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure Initialize(NewSharePointUrl: Text; BaseUrl: Text; GraphAuthorization: Interface "Graph Authorization")
    begin
        SharePointGraphClientImpl.Initialize(NewSharePointUrl, BaseUrl, GraphAuthorization);
    end;

    /// <summary>
    /// Initializes SharePoint Graph client with an HTTP client handler.
    /// </summary>
    /// <param name="NewSharePointUrl">SharePoint site URL.</param>
    /// <param name="ApiVersion">The Graph API version to use.</param>
    /// <param name="GraphAuthorization">The Graph API authorization to use.</param>
    /// <param name="HttpClientHandler">HTTP client handler for intercepting requests.</param>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure Initialize(NewSharePointUrl: Text; ApiVersion: Enum "Graph API Version"; GraphAuthorization: Interface "Graph Authorization"; HttpClientHandler: Interface "Http Client Handler")
    begin
        SharePointGraphClientImpl.Initialize(NewSharePointUrl, ApiVersion, GraphAuthorization, HttpClientHandler);
    end;

    #endregion

    #region Lists

    /// <summary>
    /// Gets all lists from the SharePoint site.
    /// </summary>
    /// <param name="GraphLists">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetLists(var GraphLists: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetLists(GraphLists));
    end;

    /// <summary>
    /// Gets all lists from the SharePoint site.
    /// </summary>
    /// <param name="GraphLists">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetLists(var GraphLists: Record "SharePoint Graph List" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetLists(GraphLists, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a SharePoint list by ID.
    /// </summary>
    /// <param name="ListId">ID of the list to retrieve.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetList(ListId: Text; var GraphList: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetList(ListId, GraphList));
    end;

    /// <summary>
    /// Gets a SharePoint list by ID.
    /// </summary>
    /// <param name="ListId">ID of the list to retrieve.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetList(ListId: Text; var GraphList: Record "SharePoint Graph List" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetList(ListId, GraphList, GraphOptionalParameters));
    end;

    /// <summary>
    /// Creates a new SharePoint list.
    /// </summary>
    /// <param name="DisplayName">Display name for the list.</param>
    /// <param name="Description">Description for the list.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Manage.All</remarks>
    procedure CreateList(DisplayName: Text; Description: Text; var GraphList: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateList(DisplayName, Description, GraphList));
    end;

    /// <summary>
    /// Creates a new SharePoint list.
    /// </summary>
    /// <param name="DisplayName">Display name for the list.</param>
    /// <param name="ListTemplate">Template for the list (genericList, documentLibrary, etc.)</param>
    /// <param name="Description">Description for the list.</param>
    /// <param name="GraphList">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Manage.All</remarks>
    procedure CreateList(DisplayName: Text; ListTemplate: Text; Description: Text; var GraphList: Record "SharePoint Graph List" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateList(DisplayName, ListTemplate, Description, GraphList));
    end;

    #endregion

    #region List Items

    /// <summary>
    /// Gets items from a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="GraphListItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetListItems(ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetListItems(ListId, GraphListItems));
    end;

    /// <summary>
    /// Gets items from a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="GraphListItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetListItems(ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetListItems(ListId, GraphListItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Creates a new item in a SharePoint list.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="FieldsJsonObject">JSON object containing the fields for the new item.</param>
    /// <param name="GraphListItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure CreateListItem(ListId: Text; FieldsJsonObject: JsonObject; var GraphListItem: Record "SharePoint Graph List Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateListItem(ListId, FieldsJsonObject, GraphListItem));
    end;

    /// <summary>
    /// Creates a new item in a SharePoint list with a simple title.
    /// </summary>
    /// <param name="ListId">ID of the list.</param>
    /// <param name="Title">Title for the new item.</param>
    /// <param name="GraphListItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure CreateListItem(ListId: Text; Title: Text; var GraphListItem: Record "SharePoint Graph List Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateListItem(ListId, Title, GraphListItem));
    end;

    #endregion

    #region Drive and Items

    /// <summary>
    /// Gets the default document library (drive) for the site.
    /// </summary>
    /// <param name="DriveId">ID of the default drive.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDefaultDrive(var DriveId: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDefaultDrive(DriveId));
    end;

    /// <summary>
    /// Gets all drives (document libraries) available on the site with detailed information.
    /// </summary>
    /// <param name="GraphDrives">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDrives(var GraphDrives: Record "SharePoint Graph Drive" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDrives(GraphDrives));
    end;

    /// <summary>
    /// Gets all drives (document libraries) available on the site with detailed information.
    /// </summary>
    /// <param name="GraphDrives">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDrives(var GraphDrives: Record "SharePoint Graph Drive" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDrives(GraphDrives, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a drive (document library) by ID with detailed information.
    /// </summary>
    /// <param name="DriveId">ID of the drive to retrieve.</param>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDrive(DriveId: Text; var GraphDrive: Record "SharePoint Graph Drive" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDrive(DriveId, GraphDrive));
    end;

    /// <summary>
    /// Gets a drive (document library) by ID with detailed information.
    /// </summary>
    /// <param name="DriveId">ID of the drive to retrieve.</param>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDrive(DriveId: Text; var GraphDrive: Record "SharePoint Graph Drive" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDrive(DriveId, GraphDrive, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets the default document library (drive) for the site with detailed information.
    /// </summary>
    /// <param name="GraphDrive">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDefaultDrive(var GraphDrive: Record "SharePoint Graph Drive" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDefaultDrive(GraphDrive));
    end;

    /// <summary>
    /// Gets items in the root folder of the default drive.
    /// </summary>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetRootItems(var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetRootItems(GraphDriveItems));
    end;

    /// <summary>
    /// Gets items in the root folder of the default drive.
    /// </summary>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetRootItems(var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetRootItems(GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets children of a folder by the folder's ID.
    /// </summary>
    /// <param name="FolderId">ID of the folder.</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetFolderItems(FolderId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetFolderItems(FolderId, GraphDriveItems));
    end;

    /// <summary>
    /// Gets children of a folder by the folder's ID.
    /// </summary>
    /// <param name="FolderId">ID of the folder.</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetFolderItems(FolderId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetFolderItems(FolderId, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets items from a path in the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetItemsByPath(FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetItemsByPath(FolderPath, GraphDriveItems));
    end;

    /// <summary>
    /// Gets items from a path in the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents/Folder1').</param>
    /// <param name="GraphDriveItems">Collection of the result (temporary record).</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetItemsByPath(FolderPath: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetItemsByPath(FolderPath, GraphDriveItems, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a file or folder by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to retrieve.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDriveItem(ItemId: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDriveItem(ItemId, GraphDriveItem));
    end;

    /// <summary>
    /// Gets a file or folder by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to retrieve.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDriveItem(ItemId: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDriveItem(ItemId, GraphDriveItem, GraphOptionalParameters));
    end;

    /// <summary>
    /// Gets a file or folder by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx').</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDriveItemByPath(ItemPath: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDriveItemByPath(ItemPath, GraphDriveItem));
    end;

    /// <summary>
    /// Gets a file or folder by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx').</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="GraphOptionalParameters">A wrapper for optional header and query parameters.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure GetDriveItemByPath(ItemPath: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.GetDriveItemByPath(ItemPath, GraphDriveItem, GraphOptionalParameters));
    end;

    /// <summary>
    /// Creates a new folder.
    /// </summary>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure CreateFolder(FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateFolder('', FolderPath, FolderName, GraphDriveItem));
    end;

    /// <summary>
    /// Creates a new folder with specified conflict behavior.
    /// </summary>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a folder with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure CreateFolder(FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateFolder('', FolderPath, FolderName, GraphDriveItem, ConflictBehavior));
    end;

    /// <summary>
    /// Creates a new folder in a specific drive (document library).
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path where to create the folder (e.g., 'Documents').</param>
    /// <param name="FolderName">Name of the new folder.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure CreateFolder(DriveId: Text; FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateFolder(DriveId, FolderPath, FolderName, GraphDriveItem));
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
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure CreateFolder(DriveId: Text; FolderPath: Text; FolderName: Text; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CreateFolder(DriveId, FolderPath, FolderName, GraphDriveItem, ConflictBehavior));
    end;

    /// <summary>
    /// Uploads a file to a folder on the default drive.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadFile(FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadFile('', FolderPath, FileName, FileInStream, GraphDriveItem));
    end;

    /// <summary>
    /// Uploads a file to a folder on the default drive with specified conflict behavior.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a file with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadFile(FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadFile('', FolderPath, FileName, FileInStream, GraphDriveItem, ConflictBehavior));
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
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem));
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
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem, ConflictBehavior));
    end;

    /// <summary>
    /// Downloads a file.
    /// </summary>
    /// <param name="ItemId">ID of the file to download.</param>
    /// <param name="TempBlob">TempBlob to receive the file content.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure DownloadFile(ItemId: Text; var TempBlob: Codeunit "Temp Blob"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.DownloadFile(ItemId, TempBlob));
    end;

    /// <summary>
    /// Downloads a file by path.
    /// </summary>
    /// <param name="FilePath">Path to the file (e.g., 'Documents/file.docx').</param>
    /// <param name="TempBlob">TempBlob to receive the file content.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure DownloadFileByPath(FilePath: Text; var TempBlob: Codeunit "Temp Blob"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.DownloadFileByPath(FilePath, TempBlob));
    end;

    /// <summary>
    /// Downloads a large file using chunked download for files larger than Business Central's 150MB HTTP response limit.
    /// </summary>
    /// <param name="ItemId">ID of the file to download.</param>
    /// <param name="TempBlob">TempBlob to receive the file content.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All. Uses 100MB chunks to stay under the 150MB limit. Any chunk failure will fail the entire download.</remarks>
    procedure DownloadLargeFile(ItemId: Text; var TempBlob: Codeunit "Temp Blob"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.DownloadLargeFile(ItemId, TempBlob));
    end;

    /// <summary>
    /// Downloads a large file by path using chunked download for files larger than Business Central's 150MB HTTP response limit.
    /// </summary>
    /// <param name="FilePath">Path to the file (e.g., 'Documents/file.docx').</param>
    /// <param name="TempBlob">Blob to receive the file content.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All. Uses 100MB chunks to stay under the 150MB limit. Any chunk failure will fail the entire download.</remarks>
    procedure DownloadLargeFileByPath(FilePath: Text; var TempBlob: Codeunit "Temp Blob"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.DownloadLargeFileByPath(FilePath, TempBlob));
    end;

    /// <summary>
    /// Uploads a large file to a folder on the default drive using chunked upload for improved performance and reliability.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadLargeFile(FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadLargeFile('', FolderPath, FileName, FileInStream, GraphDriveItem));
    end;

    /// <summary>
    /// Uploads a large file to a folder on the default drive using chunked upload with specified conflict behavior.
    /// </summary>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a file with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadLargeFile(FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadLargeFile('', FolderPath, FileName, FileInStream, GraphDriveItem, ConflictBehavior));
    end;

    /// <summary>
    /// Uploads a large file to a folder in a specific drive (document library) using chunked upload.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadLargeFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadLargeFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem));
    end;

    /// <summary>
    /// Uploads a large file to a folder in a specific drive (document library) using chunked upload with specified conflict behavior.
    /// </summary>
    /// <param name="DriveId">ID of the drive (document library).</param>
    /// <param name="FolderPath">Path to the folder (e.g., 'Documents').</param>
    /// <param name="FileName">Name of the file to upload.</param>
    /// <param name="FileInStream">Content of the file.</param>
    /// <param name="GraphDriveItem">Record to store the result.</param>
    /// <param name="ConflictBehavior">How to handle conflicts if a file with the same name exists</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All</remarks>
    procedure UploadLargeFile(DriveId: Text; FolderPath: Text; FileName: Text; FileInStream: InStream; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary; ConflictBehavior: Enum "Graph ConflictBehavior"): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.UploadLargeFile(DriveId, FolderPath, FileName, FileInStream, GraphDriveItem, ConflictBehavior));
    end;

    /// <summary>
    /// Deletes a drive item (file or folder) by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to delete.</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All. Returns success even if the item doesn't exist (404 is treated as success).</remarks>
    procedure DeleteItem(ItemId: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.DeleteItem(ItemId));
    end;

    /// <summary>
    /// Deletes a drive item (file or folder) by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx' or 'Documents/folder').</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All. Returns success even if the item doesn't exist (404 is treated as success).</remarks>
    procedure DeleteItemByPath(ItemPath: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.DeleteItemByPath(ItemPath));
    end;

    /// <summary>
    /// Checks if a drive item (file or folder) exists by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to check.</param>
    /// <param name="Exists">True if the item exists, false if it doesn't exist (404).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure ItemExists(ItemId: Text; var Exists: Boolean): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.ItemExists(ItemId, Exists));
    end;

    /// <summary>
    /// Checks if a drive item (file or folder) exists by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx' or 'Documents/folder').</param>
    /// <param name="Exists">True if the item exists, false if it doesn't exist (404).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.Read.All</remarks>
    procedure ItemExistsByPath(ItemPath: Text; var Exists: Boolean): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.ItemExistsByPath(ItemPath, Exists));
    end;

    /// <summary>
    /// Copies a drive item (file or folder) to a new location by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to copy.</param>
    /// <param name="TargetFolderId">ID of the target folder.</param>
    /// <param name="NewName">New name for the copied item (optional - leave empty to keep original name).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All. This is an asynchronous operation. The copy happens in the background.</remarks>
    procedure CopyItem(ItemId: Text; TargetFolderId: Text; NewName: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CopyItem(ItemId, TargetFolderId, NewName));
    end;

    /// <summary>
    /// Copies a drive item (file or folder) to a new location by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx').</param>
    /// <param name="TargetFolderPath">Path to the target folder (e.g., 'Documents/Archive').</param>
    /// <param name="NewName">New name for the copied item (optional - leave empty to keep original name).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All. This is an asynchronous operation. The copy happens in the background.</remarks>
    procedure CopyItemByPath(ItemPath: Text; TargetFolderPath: Text; NewName: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.CopyItemByPath(ItemPath, TargetFolderPath, NewName));
    end;

    /// <summary>
    /// Moves a drive item (file or folder) to a new location by ID.
    /// </summary>
    /// <param name="ItemId">ID of the item to move.</param>
    /// <param name="TargetFolderId">ID of the target folder (leave empty to only rename).</param>
    /// <param name="NewName">New name for the moved item (leave empty to keep original name).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All. At least one of TargetFolderId or NewName must be provided.</remarks>
    procedure MoveItem(ItemId: Text; TargetFolderId: Text; NewName: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.MoveItem(ItemId, TargetFolderId, NewName));
    end;

    /// <summary>
    /// Moves a drive item (file or folder) to a new location by path.
    /// </summary>
    /// <param name="ItemPath">Path to the item (e.g., 'Documents/file.docx').</param>
    /// <param name="TargetFolderPath">Path to the target folder (leave empty to only rename).</param>
    /// <param name="NewName">New name for the moved item (leave empty to keep original name).</param>
    /// <returns>An operation response object containing the result of the operation.</returns>
    /// <remarks>Required Microsoft Graph permission: Sites.ReadWrite.All. At least one of TargetFolderPath or NewName must be provided.</remarks>
    procedure MoveItemByPath(ItemPath: Text; TargetFolderPath: Text; NewName: Text): Codeunit "SharePoint Graph Response"
    begin
        exit(SharePointGraphClientImpl.MoveItemByPath(ItemPath, TargetFolderPath, NewName));
    end;

    #endregion

    /// <summary>
    /// Creates an OData query to filter items in SharePoint
    /// </summary>
    /// <param name="GraphOptionalParameters">The optional parameters to configure</param>
    /// <param name="Filter">The OData filter expression</param>
    /// <remarks>Use this for $filter OData queries</remarks>
    procedure SetODataFilter(var GraphOptionalParameters: Codeunit "Graph Optional Parameters"; Filter: Text)
    begin
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::Filter, Filter);
    end;

    /// <summary>
    /// Creates an OData query to select specific fields from items in SharePoint
    /// </summary>
    /// <param name="GraphOptionalParameters">The optional parameters to configure</param>
    /// <param name="Select">The fields to select (comma-separated)</param>
    /// <remarks>Use this for $select OData queries</remarks>
    procedure SetODataSelect(var GraphOptionalParameters: Codeunit "Graph Optional Parameters"; Select: Text)
    begin
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::Select, Select);
    end;

    /// <summary>
    /// Creates an OData query to expand related entities in SharePoint
    /// </summary>
    /// <param name="GraphOptionalParameters">The optional parameters to configure</param>
    /// <param name="Expand">The entities to expand (comma-separated)</param>
    /// <remarks>Use this for $expand OData queries</remarks>
    procedure SetODataExpand(var GraphOptionalParameters: Codeunit "Graph Optional Parameters"; Expand: Text)
    begin
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::Expand, Expand);
    end;

    /// <summary>
    /// Creates an OData query to order results in SharePoint
    /// </summary>
    /// <param name="GraphOptionalParameters">The optional parameters to configure</param>
    /// <param name="OrderBy">The fields to order by (e.g. "displayName asc")</param>
    /// <remarks>Use this for $orderby OData queries</remarks>
    procedure SetODataOrderBy(var GraphOptionalParameters: Codeunit "Graph Optional Parameters"; OrderBy: Text)
    begin
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::OrderBy, OrderBy);
    end;

    /// <summary>
    /// Returns detailed information on last API call.
    /// </summary>
    /// <returns>Codeunit holding http response status, reason phrase, headers and possible error information for the last API call</returns>
    procedure GetDiagnostics(): Interface "HTTP Diagnostics"
    begin
        exit(SharePointGraphClientImpl.GetDiagnostics());
    end;

    /// <summary>
    /// Sets the site ID directly for testing purposes.
    /// </summary>
    /// <param name="SiteId">The site ID to set.</param>
    internal procedure SetSiteIdForTesting(SiteId: Text)
    begin
        SharePointGraphClientImpl.SetSiteIdForTesting(SiteId);
    end;

    /// <summary>
    /// Sets the default drive ID directly for testing purposes.
    /// </summary>
    /// <param name="DefaultDriveId">The default drive ID to set.</param>
    internal procedure SetDefaultDriveIdForTesting(DefaultDriveId: Text)
    begin
        SharePointGraphClientImpl.SetDefaultDriveIdForTesting(DefaultDriveId);
    end;
}