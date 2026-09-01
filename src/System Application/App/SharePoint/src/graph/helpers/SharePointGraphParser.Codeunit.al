// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Integration.Sharepoint;

/// <summary>
/// Provides functionality for parsing Microsoft Graph API responses for SharePoint.
/// </summary>
codeunit 9122 "SharePoint Graph Parser"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    /// <summary>
    /// Extracts the next page link from a paginated response.
    /// </summary>
    /// <param name="JsonResponse">The JSON response that might contain a next link.</param>
    /// <param name="NextLink">The extracted next link if available.</param>
    /// <returns>True if a next link was found; otherwise false.</returns>
    procedure ExtractNextLink(JsonResponse: JsonObject; var NextLink: Text): Boolean
    var
        JsonToken: JsonToken;
    begin
        if not JsonResponse.Get('@odata.nextLink', JsonToken) then
            exit(false);

        NextLink := JsonToken.AsValue().AsText();
        exit(true);
    end;

    /// <summary>
    /// Parses a JSON response into a collection of SharePoint Graph List records.
    /// </summary>
    /// <param name="JsonResponse">The JSON response to parse.</param>
    /// <param name="GraphLists">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseListCollection(JsonResponse: JsonObject; var GraphLists: Record "SharePoint Graph List" temporary): Boolean
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
    begin
        if not JsonResponse.Get('value', JsonToken) then
            exit(false);

        if not JsonToken.IsArray() then
            exit(false);

        JsonArray := JsonToken.AsArray();
        exit(ParseListCollection(JsonArray, GraphLists));
    end;

    /// <summary>
    /// Parses a JSON array into a collection of SharePoint Graph List records.
    /// </summary>
    /// <param name="JsonArray">The JSON array to parse.</param>
    /// <param name="GraphLists">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; throws an exception on failure.</returns>
    procedure ParseListCollection(JsonArray: JsonArray; var GraphLists: Record "SharePoint Graph List" temporary): Boolean
    var
        JsonToken: JsonToken;
        JsonListObject: JsonObject;
    begin
        foreach JsonToken in JsonArray do begin
            JsonListObject := JsonToken.AsObject();

            GraphLists.Init();
            if ParseListItem(JsonListObject, GraphLists) then
                GraphLists.Insert();
        end;

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON object into a SharePoint Graph List record.
    /// </summary>
    /// <param name="JsonListObject">The JSON object to parse.</param>
    /// <param name="GraphList">The record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseListItem(JsonListObject: JsonObject; var GraphList: Record "SharePoint Graph List" temporary): Boolean
    var
        JsonToken: JsonToken;
        NestedJsonToken: JsonToken;
    begin
        if not JsonListObject.Get('id', JsonToken) then
            exit(false);

        GraphList.Id := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.Id));

        if JsonListObject.Get('displayName', JsonToken) then
            GraphList.DisplayName := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.DisplayName));

        if JsonListObject.Get('name', JsonToken) then
            GraphList.Name := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.Name));

        if JsonListObject.Get('description', JsonToken) then
            GraphList.Description := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.Description));

        if JsonListObject.Get('webUrl', JsonToken) then
            GraphList.WebUrl := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.WebUrl));

        if JsonListObject.Get('list', JsonToken) then
            if JsonToken.IsObject() then
                if JsonToken.AsObject().Get('template', NestedJsonToken) then
                    GraphList.Template := CopyStr(NestedJsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.Template));

        if JsonListObject.Get('drive', JsonToken) then
            if JsonToken.IsObject() then
                if JsonToken.AsObject().Get('id', NestedJsonToken) then
                    GraphList.DriveId := CopyStr(NestedJsonToken.AsValue().AsText(), 1, MaxStrLen(GraphList.DriveId));

        if JsonListObject.Get('createdDateTime', JsonToken) then
            GraphList.CreatedDateTime := JsonToken.AsValue().AsDateTime();

        if JsonListObject.Get('lastModifiedDateTime', JsonToken) then
            GraphList.LastModifiedDateTime := JsonToken.AsValue().AsDateTime();

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON response into a collection of SharePoint Graph List Item records.
    /// </summary>
    /// <param name="JsonResponse">The JSON response to parse.</param>
    /// <param name="ListId">The ID of the list the items belong to.</param>
    /// <param name="GraphListItems">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseListItemCollection(JsonResponse: JsonObject; ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary): Boolean
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
    begin
        if not JsonResponse.Get('value', JsonToken) then
            exit(false);

        if not JsonToken.IsArray() then
            exit(false);

        JsonArray := JsonToken.AsArray();
        exit(ParseListItemCollection(JsonArray, ListId, GraphListItems));
    end;

    /// <summary>
    /// Parses a JSON array into a collection of SharePoint Graph List Item records.
    /// </summary>
    /// <param name="JsonArray">The JSON array to parse.</param>
    /// <param name="ListId">The ID of the list the items belong to.</param>
    /// <param name="GraphListItems">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseListItemCollection(JsonArray: JsonArray; ListId: Text; var GraphListItems: Record "SharePoint Graph List Item" temporary): Boolean
    var
        JsonToken: JsonToken;
        JsonItemObject: JsonObject;
    begin
        foreach JsonToken in JsonArray do begin
            JsonItemObject := JsonToken.AsObject();

            GraphListItems.Init();
            GraphListItems.ListId := CopyStr(ListId, 1, MaxStrLen(GraphListItems.Id));
            if ParseListItemDetail(JsonItemObject, GraphListItems) then
                GraphListItems.Insert();
        end;

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON object into a SharePoint Graph List Item record.
    /// </summary>
    /// <param name="JsonItemObject">The JSON object to parse.</param>
    /// <param name="GraphListItem">The record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseListItemDetail(JsonItemObject: JsonObject; var GraphListItem: Record "SharePoint Graph List Item" temporary): Boolean
    var
        JsonToken: JsonToken;
        FieldsJsonObject: JsonObject;
    begin
        if not JsonItemObject.Get('id', JsonToken) then
            exit(false);

        GraphListItem.Id := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphListItem.Id));

        if JsonItemObject.Get('contentType', JsonToken) then
            if JsonToken.IsObject() then
                if JsonToken.AsObject().Get('name', JsonToken) then
                    GraphListItem.ContentType := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphListItem.ContentType));

        if JsonItemObject.Get('webUrl', JsonToken) then
            GraphListItem.WebUrl := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphListItem.WebUrl));

        if JsonItemObject.Get('createdDateTime', JsonToken) then
            GraphListItem.CreatedDateTime := JsonToken.AsValue().AsDateTime();

        if JsonItemObject.Get('lastModifiedDateTime', JsonToken) then
            GraphListItem.LastModifiedDateTime := JsonToken.AsValue().AsDateTime();

        // Extract fields from fields property
        if JsonItemObject.Get('fields', JsonToken) then begin
            FieldsJsonObject := JsonToken.AsObject();

            // Extract title specifically
            if FieldsJsonObject.Get('Title', JsonToken) then
                GraphListItem.Title := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphListItem.Title));

            // Store all fields as JSON
            GraphListItem.SetFieldsJson(FieldsJsonObject);
        end;

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON response into a collection of SharePoint Graph Drive Item records.
    /// </summary>
    /// <param name="JsonResponse">The JSON response to parse.</param>
    /// <param name="DriveId">The ID of the drive the items belong to.</param>
    /// <param name="GraphDriveItems">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseDriveItemCollection(JsonResponse: JsonObject; DriveId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
    begin
        if not JsonResponse.Get('value', JsonToken) then
            exit(false);

        if not JsonToken.IsArray() then
            exit(false);

        JsonArray := JsonToken.AsArray();
        exit(ParseDriveItemCollection(JsonArray, DriveId, GraphDriveItems));
    end;

    /// <summary>
    /// Parses a JSON array into a collection of SharePoint Graph Drive Item records.
    /// </summary>
    /// <param name="JsonArray">The JSON array to parse.</param>
    /// <param name="DriveId">The ID of the drive the items belong to.</param>
    /// <param name="GraphDriveItems">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; throws an exception on failure.</returns>
    procedure ParseDriveItemCollection(JsonArray: JsonArray; DriveId: Text; var GraphDriveItems: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        JsonToken: JsonToken;
        JsonItemObject: JsonObject;
    begin
        foreach JsonToken in JsonArray do begin
            JsonItemObject := JsonToken.AsObject();

            GraphDriveItems.Init();
            GraphDriveItems.DriveId := CopyStr(DriveId, 1, MaxStrLen(GraphDriveItems.DriveId));
            if ParseDriveItemDetail(JsonItemObject, GraphDriveItems) then
                GraphDriveItems.Insert();
        end;

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON object into a SharePoint Graph Drive Item record.
    /// </summary>
    /// <param name="JsonItemObject">The JSON object to parse.</param>
    /// <param name="GraphDriveItem">The record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseDriveItemDetail(JsonItemObject: JsonObject; var GraphDriveItem: Record "SharePoint Graph Drive Item" temporary): Boolean
    var
        JsonToken: JsonToken;
        FileJsonObj: JsonObject;
        ParentRefJsonObj: JsonObject;
    begin
        if not JsonItemObject.Get('id', JsonToken) then
            exit(false);

        GraphDriveItem.Id := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDriveItem.Id));

        if JsonItemObject.Get('name', JsonToken) then
            GraphDriveItem.Name := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDriveItem.Name));

        // Check if item is a folder
        GraphDriveItem.IsFolder := JsonItemObject.Contains('folder');

        // Get file type if it's a file
        if JsonItemObject.Get('file', JsonToken) and JsonToken.IsObject() then begin
            FileJsonObj := JsonToken.AsObject();
            if FileJsonObj.Get('mimeType', JsonToken) then
                GraphDriveItem.FileType := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDriveItem.FileType));
        end;

        // Get parent reference
        if JsonItemObject.Get('parentReference', JsonToken) and JsonToken.IsObject() then begin
            ParentRefJsonObj := JsonToken.AsObject();
            if ParentRefJsonObj.Get('id', JsonToken) then
                GraphDriveItem.ParentId := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDriveItem.ParentId));

            if ParentRefJsonObj.Get('path', JsonToken) then
                GraphDriveItem.Path := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDriveItem.Path));
        end;

        if JsonItemObject.Get('webUrl', JsonToken) then
            GraphDriveItem.WebUrl := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDriveItem.WebUrl));

        if JsonItemObject.Get('createdDateTime', JsonToken) then
            GraphDriveItem.CreatedDateTime := JsonToken.AsValue().AsDateTime();

        if JsonItemObject.Get('lastModifiedDateTime', JsonToken) then
            GraphDriveItem.LastModifiedDateTime := JsonToken.AsValue().AsDateTime();

        if JsonItemObject.Get('size', JsonToken) then
            GraphDriveItem.Size := JsonToken.AsValue().AsBigInteger();

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON response into a collection of SharePoint Graph Drive records.
    /// </summary>
    /// <param name="JsonResponse">The JSON response to parse.</param>
    /// <param name="GraphDrives">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseDriveCollection(JsonResponse: JsonObject; var GraphDrives: Record "SharePoint Graph Drive" temporary): Boolean
    var
        JsonArray: JsonArray;
        JsonToken: JsonToken;
    begin
        if not JsonResponse.Get('value', JsonToken) then
            exit(false);

        if not JsonToken.IsArray() then
            exit(false);

        JsonArray := JsonToken.AsArray();
        exit(ParseDriveCollection(JsonArray, GraphDrives));
    end;

    /// <summary>
    /// Parses a JSON array into a collection of SharePoint Graph Drive records.
    /// </summary>
    /// <param name="JsonArray">The JSON array to parse.</param>
    /// <param name="GraphDrives">The temporary record to populate.</param>
    /// <returns>True if successfully parsed; throws an exception on failure.</returns>
    procedure ParseDriveCollection(JsonArray: JsonArray; var GraphDrives: Record "SharePoint Graph Drive" temporary): Boolean
    var
        JsonToken: JsonToken;
        JsonDriveObject: JsonObject;
    begin
        foreach JsonToken in JsonArray do begin
            JsonDriveObject := JsonToken.AsObject();

            GraphDrives.Init();
            if ParseDriveDetail(JsonDriveObject, GraphDrives) then
                GraphDrives.Insert();
        end;

        exit(true);
    end;

    /// <summary>
    /// Parses a JSON object into a SharePoint Graph Drive record.
    /// </summary>
    /// <param name="JsonDriveObject">The JSON object to parse.</param>
    /// <param name="GraphDrive">The record to populate.</param>
    /// <returns>True if successfully parsed; otherwise false.</returns>
    procedure ParseDriveDetail(JsonDriveObject: JsonObject; var GraphDrive: Record "SharePoint Graph Drive" temporary): Boolean
    var
        JsonToken: JsonToken;
        OwnerJsonObj: JsonObject;
        UserJsonObj: JsonObject;
        QuotaJsonObj: JsonObject;
    begin
        if not JsonDriveObject.Get('id', JsonToken) then
            exit(false);

        GraphDrive.Id := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.Id));

        if JsonDriveObject.Get('name', JsonToken) then
            GraphDrive.Name := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.Name));

        if JsonDriveObject.Get('driveType', JsonToken) then
            GraphDrive.DriveType := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.DriveType));

        if JsonDriveObject.Get('description', JsonToken) then
            GraphDrive.Description := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.Description));

        if JsonDriveObject.Get('webUrl', JsonToken) then
            GraphDrive.WebUrl := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.WebUrl));

        if JsonDriveObject.Get('createdDateTime', JsonToken) then
            GraphDrive.CreatedDateTime := JsonToken.AsValue().AsDateTime();

        if JsonDriveObject.Get('lastModifiedDateTime', JsonToken) then
            GraphDrive.LastModifiedDateTime := JsonToken.AsValue().AsDateTime();

        // Get owner information
        if JsonDriveObject.Get('owner', JsonToken) and JsonToken.IsObject() then begin
            OwnerJsonObj := JsonToken.AsObject();
            if OwnerJsonObj.Get('user', JsonToken) and JsonToken.IsObject() then begin
                UserJsonObj := JsonToken.AsObject();
                if UserJsonObj.Get('displayName', JsonToken) then
                    GraphDrive.OwnerName := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.OwnerName));
                if UserJsonObj.Get('email', JsonToken) then
                    GraphDrive.OwnerEmail := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.OwnerEmail));
            end;
        end;

        // Get quota information
        if JsonDriveObject.Get('quota', JsonToken) and JsonToken.IsObject() then begin
            QuotaJsonObj := JsonToken.AsObject();
            if QuotaJsonObj.Get('total', JsonToken) then
                GraphDrive.QuotaTotal := JsonToken.AsValue().AsBigInteger();
            if QuotaJsonObj.Get('used', JsonToken) then
                GraphDrive.QuotaUsed := JsonToken.AsValue().AsBigInteger();
            if QuotaJsonObj.Get('remaining', JsonToken) then
                GraphDrive.QuotaRemaining := JsonToken.AsValue().AsBigInteger();
            if QuotaJsonObj.Get('state', JsonToken) then
                GraphDrive.QuotaState := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(GraphDrive.QuotaState));
        end;

        exit(true);
    end;
}