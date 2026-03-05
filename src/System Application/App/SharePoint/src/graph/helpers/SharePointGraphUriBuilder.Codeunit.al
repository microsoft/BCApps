// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

using System.Integration.Graph;
using System.Utilities;

/// <summary>
/// Provides functionality to build URIs for the Microsoft Graph API for SharePoint.
/// </summary>
codeunit 9121 "SharePoint Graph Uri Builder"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SharePointGraphReqHelper: Codeunit "SharePoint Graph Req. Helper";
        SiteId: Text;
        SiteLbl: Label '/sites/%1', Locked = true;
        ListsLbl: Label '/sites/%1/lists', Locked = true;
        ListByIdLbl: Label '/sites/%1/lists/%2', Locked = true;
        ListItemsLbl: Label '/sites/%1/lists/%2/items', Locked = true;
        CreateListItemLbl: Label '/sites/%1/lists/%2/items', Locked = true;
        SiteByHostAndPathLbl: Label '/sites/%1:%2', Locked = true;
        DriveLbl: Label '/sites/%1/drive', Locked = true;
        DrivesLbl: Label '/sites/%1/drives', Locked = true;
        DriveRootLbl: Label '/sites/%1/drive/root', Locked = true;
        DriveRootChildrenLbl: Label '/sites/%1/drive/root/children', Locked = true;
        DriveRootItemByPathLbl: Label '/sites/%1/drive/root:/%2', Locked = true;
        DriveItemByIdLbl: Label '/sites/%1/drive/items/%2', Locked = true;
        DriveItemChildrenLbl: Label '/sites/%1/drive/items/%2/children', Locked = true;
        DriveItemContentLbl: Label '/sites/%1/drive/items/%2/content', Locked = true;
        DriveItemContentByPathLbl: Label '/sites/%1/drive/root:/%2:/content', Locked = true;
        DriveItemChildrenByPathLbl: Label '/sites/%1/drive/root:/%2:/children', Locked = true;
        SpecificDriveRootLbl: Label '/sites/%1/drives/%2/root', Locked = true;
        SpecificDriveRootChildrenLbl: Label '/sites/%1/drives/%2/root/children', Locked = true;
        SpecificDriveItemChildrenByPathLbl: Label '/sites/%1/drives/%2/root:/%3:/children', Locked = true;
        SpecificDriveItemContentByPathLbl: Label '/sites/%1/drives/%2/root:/%3:/content', Locked = true;
        SpecificDriveLbl: Label '/sites/%1/drives/%2', Locked = true;
        CopyItemLbl: Label '/sites/%1/drive/items/%2/copy', Locked = true;

    /// <summary>
    /// Initializes the Graph URI Builder with a specific request helper.
    /// </summary>
    /// <param name="NewSiteId">The SharePoint site ID.</param>
    /// <param name="NewRequestHelper">The SharePoint Graph Request Helper to use.</param>
    procedure Initialize(NewSiteId: Text; NewRequestHelper: Codeunit "SharePoint Graph Req. Helper")
    begin
        SiteId := NewSiteId;
        SharePointGraphReqHelper := NewRequestHelper;
    end;

    /// <summary>
    /// Gets the endpoint for getting a site by hostname and path.
    /// </summary>
    /// <param name="HostName">The hostname (e.g., contoso.sharepoint.com).</param>
    /// <param name="RelativePath">The relative path (e.g., /sites/Marketing).</param>
    /// <returns>The endpoint.</returns>
    procedure GetSiteByHostAndPathEndpoint(HostName: Text; RelativePath: Text): Text
    begin
        exit(StrSubstNo(SiteByHostAndPathLbl, EscapeDataString(HostName), RelativePath));
    end;

    /// <summary>
    /// Gets the endpoint for getting a site.
    /// </summary>
    /// <returns>The endpoint.</returns>
    procedure GetSiteEndpoint(): Text
    begin
        exit(StrSubstNo(SiteLbl, SiteId));
    end;

    /// <summary>
    /// Gets the endpoint for getting all lists.
    /// </summary>
    /// <returns>The endpoint.</returns>
    procedure GetListsEndpoint(): Text
    begin
        exit(StrSubstNo(ListsLbl, SiteId));
    end;

    /// <summary>
    /// Gets the endpoint for getting a list by ID.
    /// </summary>
    /// <param name="ListId">The list ID.</param>
    /// <returns>The endpoint.</returns>
    procedure GetListEndpoint(ListId: Text): Text
    begin
        exit(StrSubstNo(ListByIdLbl, SiteId, EscapeDataString(ListId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting items in a list.
    /// </summary>
    /// <param name="ListId">The list ID.</param>
    /// <returns>The endpoint.</returns>
    procedure GetListItemsEndpoint(ListId: Text): Text
    begin
        exit(StrSubstNo(ListItemsLbl, SiteId, EscapeDataString(ListId)));
    end;

    /// <summary>
    /// Gets the endpoint for creating an item in a list.
    /// </summary>
    /// <param name="ListId">The list ID.</param>
    /// <returns>The endpoint.</returns>
    procedure GetCreateListItemEndpoint(ListId: Text): Text
    begin
        exit(StrSubstNo(CreateListItemLbl, SiteId, EscapeDataString(ListId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the default drive.
    /// </summary>
    /// <returns>The endpoint.</returns>
    procedure GetDriveEndpoint(): Text
    begin
        exit(StrSubstNo(DriveLbl, SiteId));
    end;

    /// <summary>
    /// Gets the endpoint for getting all drives.
    /// </summary>
    /// <returns>The endpoint.</returns>
    procedure GetDrivesEndpoint(): Text
    begin
        exit(StrSubstNo(DrivesLbl, SiteId));
    end;

    /// <summary>
    /// Gets the endpoint for getting the root of the default drive.
    /// </summary>
    /// <returns>The endpoint.</returns>
    procedure GetDriveRootEndpoint(): Text
    begin
        exit(StrSubstNo(DriveRootLbl, SiteId));
    end;

    /// <summary>
    /// Gets the endpoint for getting the children of the root folder.
    /// </summary>
    /// <returns>The endpoint.</returns>
    procedure GetDriveRootChildrenEndpoint(): Text
    begin
        exit(StrSubstNo(DriveRootChildrenLbl, SiteId));
    end;

    /// <summary>
    /// Gets the endpoint for getting an item by path.
    /// </summary>
    /// <param name="ItemPath">The path to the item.</param>
    /// <returns>The endpoint.</returns>
    procedure GetDriveItemByPathEndpoint(ItemPath: Text): Text
    begin
        exit(StrSubstNo(DriveRootItemByPathLbl, SiteId, EscapePathSegments(ItemPath)));
    end;

    /// <summary>
    /// Gets the endpoint for getting an item by ID.
    /// </summary>
    /// <param name="ItemId">The item ID.</param>
    /// <returns>The endpoint.</returns>
    procedure GetDriveItemByIdEndpoint(ItemId: Text): Text
    begin
        exit(StrSubstNo(DriveItemByIdLbl, SiteId, EscapeDataString(ItemId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the children of an item by ID.
    /// </summary>
    /// <param name="ItemId">The item ID.</param>
    /// <returns>The endpoint.</returns>
    procedure GetDriveItemChildrenByIdEndpoint(ItemId: Text): Text
    begin
        exit(StrSubstNo(DriveItemChildrenLbl, SiteId, EscapeDataString(ItemId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the children of an item by path.
    /// </summary>
    /// <param name="ItemPath">The path to the item.</param>
    /// <returns>The endpoint.</returns>
    procedure GetDriveItemChildrenByPathEndpoint(ItemPath: Text): Text
    begin
        exit(StrSubstNo(DriveItemChildrenByPathLbl, SiteId, EscapePathSegments(ItemPath)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the content of an item by ID.
    /// </summary>
    /// <param name="ItemId">The item ID.</param>
    /// <returns>The endpoint.</returns>
    procedure GetDriveItemContentByIdEndpoint(ItemId: Text): Text
    begin
        exit(StrSubstNo(DriveItemContentLbl, SiteId, EscapeDataString(ItemId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the content of an item by path.
    /// </summary>
    /// <param name="ItemPath">The path to the item.</param>
    /// <returns>The endpoint.</returns>
    procedure GetDriveItemContentByPathEndpoint(ItemPath: Text): Text
    begin
        exit(StrSubstNo(DriveItemContentByPathLbl, SiteId, EscapePathSegments(ItemPath)));
    end;

    /// <summary>
    /// Gets the endpoint for uploading content to an item.
    /// </summary>
    /// <param name="FolderPath">The path to the folder.</param>
    /// <param name="FileName">The name of the file.</param>
    /// <returns>The endpoint.</returns>
    procedure GetUploadEndpoint(FolderPath: Text; FileName: Text): Text
    var
        ItemPath: Text;
    begin
        if FolderPath = '' then
            ItemPath := EscapeDataString(FileName)
        else
            ItemPath := EscapePathSegments(FolderPath) + '/' + EscapeDataString(FileName);

        exit(StrSubstNo(DriveItemContentByPathLbl, SiteId, ItemPath));
    end;

    /// <summary>
    /// Adds OData query parameters to an endpoint
    /// </summary>
    /// <param name="BaseEndpoint">The base endpoint URL</param>
    /// <param name="GraphOptionalParameters">Optional parameters including OData parameters</param>
    /// <returns>The endpoint with OData parameters if applicable</returns>
    procedure AddOptionalParametersToEndpoint(BaseEndpoint: Text; GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Text
    var
        UriBuilder: Codeunit "Uri Builder";
        Uri: Codeunit Uri;
        ODataParameters: Dictionary of [Text, Text];
        QueryParameters: Dictionary of [Text, Text];
        ParameterKey: Text;
        FinalUri: Text;
        AbsoluteUrl: Text;
        BaseUrl: Text;
    begin
        // If no parameters, return original endpoint
        if not HasParameters(GraphOptionalParameters) then
            exit(BaseEndpoint);

        // Get the appropriate Graph API base URL
        BaseUrl := GetGraphApiBaseUrl();

        // Ensure we have an absolute URL before initializing the Uri
        if IsRelativePath(BaseEndpoint) then
            AbsoluteUrl := BaseUrl + BaseEndpoint
        else
            AbsoluteUrl := BaseEndpoint;

        // Initialize URI with absolute URL
        Uri.Init(AbsoluteUrl);
        UriBuilder.Init(Uri.GetAbsoluteUri());

        // Add OData query parameters
        ODataParameters := GraphOptionalParameters.GetODataQueryParameters();
        foreach ParameterKey in ODataParameters.Keys() do
            UriBuilder.AddODataQueryParameter(ParameterKey, ODataParameters.Get(ParameterKey));

        // Add regular query parameters
        QueryParameters := GraphOptionalParameters.GetQueryParameters();
        foreach ParameterKey in QueryParameters.Keys() do
            UriBuilder.AddQueryParameter(ParameterKey, QueryParameters.Get(ParameterKey));

        // Get final URI
        UriBuilder.GetUri(Uri);
        FinalUri := Uri.GetAbsoluteUri();

        // If the original endpoint was relative, strip the base URL to return a relative path
        if IsRelativePath(BaseEndpoint) then
            FinalUri := ReplaceString(FinalUri, BaseUrl, '');

        exit(FinalUri);
    end;

    local procedure HasParameters(GraphOptionalParameters: Codeunit "Graph Optional Parameters"): Boolean
    var
        ODataParameters: Dictionary of [Text, Text];
        QueryParameters: Dictionary of [Text, Text];
    begin
        ODataParameters := GraphOptionalParameters.GetODataQueryParameters();
        QueryParameters := GraphOptionalParameters.GetQueryParameters();
        exit((ODataParameters.Count() > 0) or (QueryParameters.Count() > 0));
    end;

    local procedure IsRelativePath(Path: Text): Boolean
    begin
        exit(Path.StartsWith('/'));
    end;

    local procedure ReplaceString(String: Text; OldSubString: Text; NewSubString: Text): Text
    begin
        exit(String.Replace(OldSubString, NewSubString));
    end;

    local procedure GetGraphApiBaseUrl(): Text
    begin
        exit(SharePointGraphReqHelper.GetGraphApiBaseUrl());
    end;

    /// <summary>
    /// Gets the endpoint for getting the root of a specific drive.
    /// </summary>
    /// <param name="DriveId">The ID of the drive.</param>
    /// <returns>The endpoint.</returns>
    procedure GetSpecificDriveRootEndpoint(DriveId: Text): Text
    begin
        exit(StrSubstNo(SpecificDriveRootLbl, SiteId, EscapeDataString(DriveId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the children of the root folder of a specific drive.
    /// </summary>
    /// <param name="DriveId">The ID of the drive.</param>
    /// <returns>The endpoint.</returns>
    procedure GetSpecificDriveRootChildrenEndpoint(DriveId: Text): Text
    begin
        exit(StrSubstNo(SpecificDriveRootChildrenLbl, SiteId, EscapeDataString(DriveId)));
    end;

    /// <summary>
    /// Gets the endpoint for getting the children of an item by path in a specific drive.
    /// </summary>
    /// <param name="DriveId">The ID of the drive.</param>
    /// <param name="ItemPath">The path to the item.</param>
    /// <returns>The endpoint.</returns>
    procedure GetSpecificDriveItemChildrenByPathEndpoint(DriveId: Text; ItemPath: Text): Text
    begin
        exit(StrSubstNo(SpecificDriveItemChildrenByPathLbl, SiteId, EscapeDataString(DriveId), EscapePathSegments(ItemPath)));
    end;

    /// <summary>
    /// Gets the endpoint for uploading content to an item in a specific drive.
    /// </summary>
    /// <param name="DriveId">The ID of the drive.</param>
    /// <param name="FolderPath">The path to the folder.</param>
    /// <param name="FileName">The name of the file.</param>
    /// <returns>The endpoint.</returns>
    procedure GetSpecificDriveUploadEndpoint(DriveId: Text; FolderPath: Text; FileName: Text): Text
    var
        ItemPath: Text;
    begin
        if FolderPath = '' then
            ItemPath := EscapeDataString(FileName)
        else
            ItemPath := EscapePathSegments(FolderPath) + '/' + EscapeDataString(FileName);

        exit(StrSubstNo(SpecificDriveItemContentByPathLbl, SiteId, EscapeDataString(DriveId), ItemPath));
    end;

    /// <summary>
    /// Gets the endpoint for getting a specific drive by ID.
    /// </summary>
    /// <param name="DriveId">The ID of the drive.</param>
    /// <returns>The endpoint.</returns>
    procedure GetSpecificDriveEndpoint(DriveId: Text): Text
    begin
        exit(StrSubstNo(SpecificDriveLbl, SiteId, EscapeDataString(DriveId)));
    end;

    /// <summary>
    /// Gets the endpoint for copying a drive item.
    /// </summary>
    /// <param name="ItemId">The ID of the item to copy.</param>
    /// <returns>The endpoint.</returns>
    procedure GetCopyItemEndpoint(ItemId: Text): Text
    begin
        exit(StrSubstNo(CopyItemLbl, SiteId, EscapeDataString(ItemId)));
    end;

    local procedure EscapeDataString(TextToEscape: Text): Text
    var
        Uri: Codeunit Uri;
    begin
        exit(Uri.EscapeDataString(TextToEscape));
    end;

    local procedure EscapePathSegments(PathToEscape: Text): Text
    var
        Uri: Codeunit Uri;
        Segments: List of [Text];
        Segment: Text;
        Result: Text;
        i: Integer;
    begin
        PathToEscape := PathToEscape.TrimStart('/');
        Segments := PathToEscape.Split('/');
        for i := 1 to Segments.Count() do begin
            Segments.Get(i, Segment);
            if i > 1 then
                Result += '/';
            Result += Uri.EscapeDataString(Segment);
        end;
        exit(Result);
    end;

}