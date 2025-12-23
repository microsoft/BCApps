// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Integration.Graph.Authorization;
using System.Integration.Sharepoint;
using System.Utilities;
using System.Integration.Graph;

/// <summary>
/// Helper implementation for SharePoint file operations using Microsoft Graph API.
/// This codeunit contains the actual Graph API logic, called by the main connector based on account settings.
/// </summary>
codeunit 4581 "Ext. SharePoint Graph Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Ext. SharePoint Account" = rimd;


    var
        SharePointGraphClient: Codeunit "SharePoint Graph Client";
        AccountDisabledErr: Label 'The account "%1" is disabled.', Comment = '%1 - Account Name';
        ErrorOccurredErr: Label 'An error occurred.\%1', Comment = '%1 - Error message from Graph API';

    #region File Operations

    internal procedure ListFiles(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        GraphDriveItem: Record "SharePoint Graph Drive Item";
        OriginalPath: Text;
    begin
        OriginalPath := Path;
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        // List children in the directory
        Path := Path.TrimEnd('/');
        if Path = '' then
            Path := '/';

        SharePointGraphClient.GetItemsByPath(Path, GraphDriveItem);

        if GraphDriveItem.FindSet() then
            repeat
                // Only include files (not folders)
                if not GraphDriveItem.IsFolder then begin
                    TempFileAccountContent.Init();
                    TempFileAccountContent.Name := GraphDriveItem.Name;
                    TempFileAccountContent.Type := TempFileAccountContent.Type::"File";
                    TempFileAccountContent."Parent Directory" := CopyStr(OriginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
                    TempFileAccountContent.Insert();
                end;
            until GraphDriveItem.Next() = 0;

        FilePaginationData.SetEndOfListing(true);
    end;

    internal procedure GetFile(AccountId: Guid; Path: Text; Stream: InStream)
    var
        TempBlob: Codeunit "Temp Blob";
        Response: Codeunit "SharePoint Graph Response";
        Content: HttpContent;
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        // Use chunked download for all files to handle >150MB files
        Response := SharePointGraphClient.DownloadLargeFileByPath(Path, TempBlob);

        if not Response.IsSuccessful() then
            ShowError(Response);

        // TempBlob is cleared after the procedure. HttpContent "hack" keeps the data.
        Content.WriteFrom(TempBlob.CreateInStream());
        Content.ReadAs(Stream);
    end;

    internal procedure CreateFile(AccountId: Guid; Path: Text; Stream: InStream)
    var
        GraphDriveItem: Record "SharePoint Graph Drive Item";
        Response: Codeunit "SharePoint Graph Response";
        FileName: Text;
        FolderPath: Text;
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        // Split path into folder and filename
        SplitPath(Path, FolderPath, FileName);

        // Use chunked upload (handles files of all sizes)
        Response := SharePointGraphClient.UploadLargeFile(FolderPath, FileName, Stream, GraphDriveItem);

        if not Response.IsSuccessful() then
            ShowError(Response);
    end;

    internal procedure CopyFile(AccountId: Guid; SourcePath: Text; TargetPath: Text)
    var
        Response: Codeunit "SharePoint Graph Response";
        FileName: Text;
        TargetFolderPath: Text;
    begin
        InitPath(AccountId, SourcePath);
        InitPath(AccountId, TargetPath);
        InitializeGraphClient(AccountId);

        // Split destination path into folder and filename
        SplitPath(TargetPath, TargetFolderPath, FileName);

        // Use native Graph API copy operation
        Response := SharePointGraphClient.CopyItemByPath(SourcePath, TargetFolderPath, FileName);

        if not Response.IsSuccessful() then
            ShowError(Response);
    end;

    internal procedure MoveFile(AccountId: Guid; SourcePath: Text; TargetPath: Text)
    var
        Response: Codeunit "SharePoint Graph Response";
        FileName: Text;
        TargetFolderPath: Text;
    begin
        InitPath(AccountId, SourcePath);
        InitPath(AccountId, TargetPath);
        InitializeGraphClient(AccountId);

        // Split destination path into folder and filename
        SplitPath(TargetPath, TargetFolderPath, FileName);

        // Use native Graph API move operation
        Response := SharePointGraphClient.MoveItemByPath(SourcePath, TargetFolderPath, FileName);

        if not Response.IsSuccessful() then
            ShowError(Response);
    end;

    internal procedure FileExists(AccountId: Guid; Path: Text): Boolean
    var
        Response: Codeunit "SharePoint Graph Response";
        Exists: Boolean;
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        Response := SharePointGraphClient.ItemExistsByPath(Path, Exists);

        if not Response.IsSuccessful() then
            ShowError(Response);

        exit(Exists);
    end;

    internal procedure DeleteFile(AccountId: Guid; Path: Text)
    var
        Response: Codeunit "SharePoint Graph Response";
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        Response := SharePointGraphClient.DeleteItemByPath(Path);

        if not Response.IsSuccessful() then
            ShowError(Response);
    end;

    #endregion

    #region Directory Operations

    internal procedure ListDirectories(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        TempGraphDriveItem: Record "SharePoint Graph Drive Item" temporary;
        OriginalPath: Text;
    begin
        OriginalPath := Path;
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        // List children in the directory
        Path := Path.TrimEnd('/');
        if Path = '' then
            Path := '/';

        SharePointGraphClient.GetItemsByPath(Path, TempGraphDriveItem);

        if TempGraphDriveItem.FindSet() then
            repeat
                // Only include folders
                if TempGraphDriveItem.IsFolder then begin
                    TempFileAccountContent.Init();
                    TempFileAccountContent.Name := TempGraphDriveItem.Name;
                    TempFileAccountContent.Type := TempFileAccountContent.Type::Directory;
                    TempFileAccountContent."Parent Directory" := CopyStr(OriginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
                    TempFileAccountContent.Insert();
                end;
            until TempGraphDriveItem.Next() = 0;

        FilePaginationData.SetEndOfListing(true);
    end;

    internal procedure CreateDirectory(AccountId: Guid; Path: Text)
    var
        GraphDriveItem: Record "SharePoint Graph Drive Item";
        Response: Codeunit "SharePoint Graph Response";
        ParentPath: Text;
        FolderName: Text;
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        // Split path into parent path and folder name
        SplitPath(Path, ParentPath, FolderName);

        Response := SharePointGraphClient.CreateFolder(ParentPath, FolderName, GraphDriveItem);

        if not Response.IsSuccessful() then
            ShowError(Response);
    end;

    internal procedure DirectoryExists(AccountId: Guid; Path: Text): Boolean
    var
        Response: Codeunit "SharePoint Graph Response";
        Exists: Boolean;
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        Response := SharePointGraphClient.ItemExistsByPath(Path, Exists);

        if not Response.IsSuccessful() then
            ShowError(Response);

        exit(Exists);
    end;

    internal procedure DeleteDirectory(AccountId: Guid; Path: Text)
    var
        Response: Codeunit "SharePoint Graph Response";
    begin
        InitPath(AccountId, Path);
        InitializeGraphClient(AccountId);

        Response := SharePointGraphClient.DeleteItemByPath(Path);

        if not Response.IsSuccessful() then
            ShowError(Response);
    end;

    #endregion

    #region Helper Methods

    local procedure InitializeGraphClient(AccountId: Guid)
    var
        SharePointAccount: Record "Ext. SharePoint Account";
        GraphAuthorization: Codeunit "Graph Authorization";
        GraphAuthInterface: Interface "Graph Authorization";
        ClientSecret: SecretText;
        Certificate: SecretText;
        CertificatePassword: SecretText;
        Scopes: List of [Text];
    begin
        // Get and validate account
        SharePointAccount.Get(AccountId);
        if SharePointAccount.Disabled then
            Error(AccountDisabledErr, SharePointAccount.Name);

        // Add required SharePoint scopes
        Scopes.Add('https://graph.microsoft.com/.default');

        // Create authorization based on authentication type
        case SharePointAccount."Authentication Type" of
            SharePointAccount."Authentication Type"::"Client Secret":
                begin
                    ClientSecret := SharePointAccount.GetClientSecret(SharePointAccount."Client Secret Key");
                    GraphAuthInterface := GraphAuthorization.CreateAuthorizationWithClientCredentials(
                        Format(SharePointAccount."Tenant Id", 0, 4),
                        Format(SharePointAccount."Client Id", 0, 4),
                        ClientSecret,
                        Scopes);
                end;
            SharePointAccount."Authentication Type"::Certificate:
                begin
                    Certificate := SharePointAccount.GetCertificate(SharePointAccount."Certificate Key");
                    CertificatePassword := SharePointAccount.GetCertificatePassword(SharePointAccount."Certificate Password Key");
                    GraphAuthInterface := GraphAuthorization.CreateAuthorizationWithClientCredentials(
                        Format(SharePointAccount."Tenant Id", 0, 4),
                        Format(SharePointAccount."Client Id", 0, 4),
                        Certificate,
                        CertificatePassword,
                        Scopes);
                end;
        end;

        // Initialize SharePoint Graph Client with Site URL and authorization
        SharePointGraphClient.Initialize(SharePointAccount."SharePoint Url", GraphAuthInterface);
    end;

    local procedure ShowError(Response: Codeunit "SharePoint Graph Response")
    begin
        Error(ErrorOccurredErr, Response.GetError());
    end;

    local procedure SplitPath(FullPath: Text; var FolderPath: Text; var ItemName: Text)
    var
        LastSlashPos: Integer;
    begin
        // Find the last slash to split path
        LastSlashPos := StrPos(ReverseString(FullPath), '/');

        if LastSlashPos = 0 then begin
            // No slash found - item is in root
            FolderPath := '/';
            ItemName := FullPath;
        end else begin
            LastSlashPos := StrLen(FullPath) - LastSlashPos + 1;
            FolderPath := CopyStr(FullPath, 1, LastSlashPos - 1);
            ItemName := CopyStr(FullPath, LastSlashPos + 1);

            if FolderPath = '' then
                FolderPath := '/';
        end;
    end;

    local procedure ReverseString(InputString: Text): Text
    var
        ReversedString: Text;
        i: Integer;
    begin
        for i := StrLen(InputString) downto 1 do
            ReversedString := ReversedString + CopyStr(InputString, i, 1);
        exit(ReversedString);
    end;

    local procedure PathSeparator(): Text
    begin
        exit('/');
    end;

    local procedure InitPath(AccountId: Guid; var Path: Text)
    var
        SharePointAccount: Record "Ext. SharePoint Account";
    begin
        SharePointAccount.Get(AccountId);
        Path := CombinePath(SharePointAccount."Base Relative Folder Path", Path);
    end;

    local procedure CombinePath(Parent: Text; Child: Text): Text
    begin
        if Parent = '' then
            exit(Child);

        if Child = '' then
            exit(Parent);

        if not Parent.EndsWith(PathSeparator()) then
            Parent += PathSeparator();

        exit(Parent + Child);
    end;

    #endregion
}
