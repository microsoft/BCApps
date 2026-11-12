// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Integration.Sharepoint;
using System.Utilities;

/// <summary>
/// Helper implementation for SharePoint file operations using SharePoint REST API.
/// This codeunit contains the actual REST API logic, called by the main connector based on account settings.
/// </summary>
codeunit 4609 "Ext. SharePoint REST Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Ext. SharePoint Account" = r;

    var
        TestSharePointAuthorization: Interface "SharePoint Authorization";
        UseTestSharePointAuthorization: Boolean;

    #region File Operations

    internal procedure ListFiles(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        TempSharePointFile: Record "SharePoint File";
        SharePointClient: Codeunit "SharePoint Client";
        OriginalPath: Text;
    begin
        OriginalPath := Path;
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if not SharePointClient.GetFolderFilesByServerRelativePath(Path, TempSharePointFile) then
            ShowError(SharePointClient);

        FilePaginationData.SetEndOfListing(true);

        if not TempSharePointFile.FindSet() then
            exit;

        repeat
            TempFileAccountContent.Init();
            TempFileAccountContent.Name := TempSharePointFile.Name;
            TempFileAccountContent.Type := TempFileAccountContent.Type::"File";
            TempFileAccountContent."Parent Directory" := CopyStr(OriginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
            TempFileAccountContent.Insert();
        until TempSharePointFile.Next() = 0;
    end;

    internal procedure GetFile(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; Stream: InStream)
    var
        SharePointClient: Codeunit "SharePoint Client";
        Content: HttpContent;
        TempBlobStream: InStream;
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);

        if not SharePointClient.DownloadFileContentByServerRelativePath(Path, TempBlobStream) then
            ShowError(SharePointClient);

        // Platform fix: For some reason the Stream from DownloadFileContentByServerRelativeUrl dies after leaving the interface
        Content.WriteFrom(TempBlobStream);
        Content.ReadAs(Stream);
    end;

    internal procedure CreateFile(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; Stream: InStream)
    var
        TempSharePointFile: Record "SharePoint File";
        SharePointClient: Codeunit "SharePoint Client";
        ParentPath, FileName : Text;
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        SplitPath(Path, ParentPath, FileName);
        if SharePointClient.AddFileToFolderByServerRelativePath(ParentPath, FileName, Stream, TempSharePointFile, false) then
            exit;

        ShowError(SharePointClient);
    end;

    internal procedure CopyFile(SharePointAccount: Record "Ext. SharePoint Account"; SourcePath: Text; TargetPath: Text)
    var
        Stream: InStream;
    begin
        GetFile(SharePointAccount, SourcePath, Stream);
        CreateFile(SharePointAccount, TargetPath, Stream);
    end;

    internal procedure MoveFile(SharePointAccount: Record "Ext. SharePoint Account"; SourcePath: Text; TargetPath: Text)
    var
        Stream: InStream;
    begin
        GetFile(SharePointAccount, SourcePath, Stream);
        CreateFile(SharePointAccount, TargetPath, Stream);
        DeleteFile(SharePointAccount, SourcePath);
    end;

    internal procedure FileExists(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text): Boolean
    var
        TempSharePointFile: Record "SharePoint File";
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if not SharePointClient.GetFolderFilesByServerRelativePath(GetParentPath(Path), TempSharePointFile) then
            ShowError(SharePointClient);

        TempSharePointFile.SetRange(Name, GetFileName(Path));
        exit(not TempSharePointFile.IsEmpty());
    end;

    internal procedure DeleteFile(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text)
    var
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if SharePointClient.DeleteFileByServerRelativePath(Path) then
            exit;

        ShowError(SharePointClient);
    end;

    #endregion

    #region Directory Operations

    internal procedure ListDirectories(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        TempSharePointFolder: Record "SharePoint Folder";
        SharePointClient: Codeunit "SharePoint Client";
        OriginalPath: Text;
    begin
        OriginalPath := Path;
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if not SharePointClient.GetSubFoldersByServerRelativePath(Path, TempSharePointFolder) then
            ShowError(SharePointClient);

        FilePaginationData.SetEndOfListing(true);

        if not TempSharePointFolder.FindSet() then
            exit;

        repeat
            TempFileAccountContent.Init();
            TempFileAccountContent.Name := TempSharePointFolder.Name;
            TempFileAccountContent.Type := TempFileAccountContent.Type::Directory;
            TempFileAccountContent."Parent Directory" := CopyStr(OriginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
            TempFileAccountContent.Insert();
        until TempSharePointFolder.Next() = 0;
    end;

    internal procedure CreateDirectory(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text)
    var
        TempSharePointFolder: Record "SharePoint Folder";
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if SharePointClient.CreateFolderByServerRelativePath(Path, TempSharePointFolder) then
            exit;

        ShowError(SharePointClient);
    end;

    internal procedure DirectoryExists(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text) Result: Boolean
    var
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);

        Result := SharePointClient.FolderExistsByServerRelativePath(Path);

        if not SharePointClient.GetDiagnostics().IsSuccessStatusCode() then
            ShowError(SharePointClient);
    end;

    internal procedure DeleteDirectory(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text)
    var
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if SharePointClient.DeleteFolderByServerRelativePath(Path) then
            exit;

        ShowError(SharePointClient);
    end;

    #endregion

    #region Helper Methods

    local procedure InitSharePointClient(SharePointAccount: Record "Ext. SharePoint Account"; var SharePointClient: Codeunit "SharePoint Client")
    var
        SharePointAuth: Codeunit "SharePoint Auth.";
        SharePointAuthorization: Interface "SharePoint Authorization";
        Scopes: List of [Text];
        AccountDisabledErr: Label 'The account "%1" is disabled.', Comment = '%1 - Account Name';
    begin
        if SharePointAccount.Disabled then
            Error(AccountDisabledErr, SharePointAccount.Name);

        Scopes.Add('00000003-0000-0ff1-ce00-000000000000/.default');

        // Tests inject a mock authorization because acquiring a token requires a real Entra ID app registration.
        if UseTestSharePointAuthorization then
            SharePointAuthorization := TestSharePointAuthorization
        else
            case SharePointAccount."Authentication Type" of
                Enum::"Ext. SharePoint Auth Type"::"Client Secret":
                    SharePointAuthorization := SharePointAuth.CreateAuthorizationCode(
                        Format(SharePointAccount."Tenant Id", 0, 4),
                        Format(SharePointAccount."Client Id", 0, 4),
                        SharePointAccount.GetClientSecret(SharePointAccount."Client Secret Key"),
                        Scopes);
                Enum::"Ext. SharePoint Auth Type"::Certificate:
                    SharePointAuthorization := SharePointAuth.CreateClientCredentials(
                        Format(SharePointAccount."Tenant Id", 0, 4),
                        Format(SharePointAccount."Client Id", 0, 4),
                        SharePointAccount.GetCertificate(SharePointAccount."Certificate Key"),
                        SharePointAccount.GetCertificatePassword(SharePointAccount."Certificate Password Key"),
                        Scopes);
            end;

        SharePointClient.Initialize(SharePointAccount."SharePoint Url", SharePointAuthorization);
    end;

    /// <summary>
    /// Injects a mock authorization so tests can exercise the REST API flow without acquiring a real token.
    /// Token acquisition goes through the platform OAuth stack and cannot be intercepted by test HTTP handlers.
    /// </summary>
    internal procedure SetAuthorizationForTest(NewSharePointAuthorization: Interface "SharePoint Authorization")
    begin
        TestSharePointAuthorization := NewSharePointAuthorization;
        UseTestSharePointAuthorization := true;
    end;

    local procedure PathSeparator(): Text
    begin
        exit('/');
    end;

    local procedure ShowError(var SharePointClient: Codeunit "SharePoint Client")
    var
        ErrorOccurredErr: Label 'An error occurred.\%1', Comment = '%1 - Error message from SharePoint';
    begin
        Error(ErrorOccurredErr, SharePointClient.GetDiagnostics().GetErrorMessage());
    end;

    local procedure GetParentPath(Path: Text) ParentPath: Text
    var
        FileName: Text;
    begin
        SplitPath(Path, ParentPath, FileName);
    end;

    local procedure GetFileName(Path: Text) FileName: Text
    var
        ParentPath: Text;
    begin
        SplitPath(Path, ParentPath, FileName);
    end;

    local procedure InitPath(SharePointAccount: Record "Ext. SharePoint Account"; var Path: Text)
    var
        Uri: Codeunit Uri;
        BaseFolderPath: Text;
        SitePath: Text;
    begin
        // Extract site path from SharePoint URL
        SitePath := GetSitePathFromUrl(SharePointAccount."SharePoint Url");

        BaseFolderPath := SharePointAccount."Base Relative Folder Path";
        if SharePointAccount."REST Base Folder Path Format" = Enum::"Ext. SharePoint Path Format"::URL then
            BaseFolderPath := Uri.UnescapeDataString(BaseFolderPath);

        // Decode URL-derived configuration only; attachment paths may contain literal percent sequences.
        Path := CombinePath(BaseFolderPath, Path);

        // Ensure path starts with forward slash
        if not Path.StartsWith('/') then
            Path := '/' + Path;

        // Prepend site path if it exists and path doesn't already include it
        if (SitePath <> '') and (Path <> SitePath) and (not Path.StartsWith(SitePath + '/')) then
            Path := SitePath + Path;

        // SharePoint returns 404 for GetFolderByServerRelativePath(decodedurl='.../Folder/'), so drop any trailing separator.
        // Directory paths such as 'A/' (produced by the Storage Browser '..' navigation) must resolve to '.../A'.
        Path := Path.TrimEnd(PathSeparator());
        if Path = '' then
            Path := PathSeparator();
    end;

    local procedure GetSitePathFromUrl(SharePointUrl: Text): Text
    var
        Uri: Codeunit Uri;
        PathSegment: Text;
    begin
        Uri.Init(SharePointUrl);
        PathSegment := Uri.UnescapeDataString(Uri.GetAbsolutePath());

        // Remove trailing slash if present
        if PathSegment.EndsWith('/') then
            PathSegment := PathSegment.TrimEnd('/');

        exit(PathSegment);
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

    local procedure SplitPath(Path: Text; var ParentPath: Text; var FileName: Text)
    var
        TrimmedPath: Text;
        SeparatorPosition: Integer;
    begin
        // The parent folder must not end with a separator: GetFolderByServerRelativePath(decodedurl='.../') returns 404.
        TrimmedPath := Path.TrimEnd(PathSeparator());
        SeparatorPosition := TrimmedPath.LastIndexOf(PathSeparator());
        if SeparatorPosition = 0 then begin
            ParentPath := '';
            FileName := TrimmedPath;
            exit;
        end;

        // Trim the parent as well, so a doubled separator before the file name ('.../Folder//file.txt') still resolves to '.../Folder'.
        ParentPath := CopyStr(TrimmedPath, 1, SeparatorPosition - 1).TrimEnd(PathSeparator());
        if ParentPath = '' then
            ParentPath := PathSeparator();
        FileName := TrimmedPath.Substring(SeparatorPosition + 1);
    end;

    #endregion
}
