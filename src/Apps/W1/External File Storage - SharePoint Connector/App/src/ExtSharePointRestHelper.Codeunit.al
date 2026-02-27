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
codeunit 4582 "Ext. SharePoint REST Helper"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Ext. SharePoint Account" = rimd;


    #region File Operations

    internal procedure ListFiles(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        SharePointFile: Record "SharePoint File";
        SharePointClient: Codeunit "SharePoint Client";
        OriginalPath: Text;
    begin
        OriginalPath := Path;
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if not SharePointClient.GetFolderFilesByServerRelativeUrl(Path, SharePointFile) then
            ShowError(SharePointClient);

        FilePaginationData.SetEndOfListing(true);

        if not SharePointFile.FindSet() then
            exit;

        repeat
            TempFileAccountContent.Init();
            TempFileAccountContent.Name := SharePointFile.Name;
            TempFileAccountContent.Type := TempFileAccountContent.Type::"File";
            TempFileAccountContent."Parent Directory" := CopyStr(OriginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
            TempFileAccountContent.Insert();
        until SharePointFile.Next() = 0;
    end;

    internal procedure GetFile(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; Stream: InStream)
    var
        SharePointClient: Codeunit "SharePoint Client";
        Content: HttpContent;
        TempBlobStream: InStream;
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);

        if not SharePointClient.DownloadFileContentByServerRelativeUrl(Path, TempBlobStream) then
            ShowError(SharePointClient);

        // Platform fix: For some reason the Stream from DownloadFileContentByServerRelativeUrl dies after leaving the interface
        Content.WriteFrom(TempBlobStream);
        Content.ReadAs(Stream);
    end;

    internal procedure CreateFile(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; Stream: InStream)
    var
        SharePointFile: Record "SharePoint File";
        SharePointClient: Codeunit "SharePoint Client";
        ParentPath, FileName : Text;
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        SplitPath(Path, ParentPath, FileName);
        if SharePointClient.AddFileToFolder(ParentPath, FileName, Stream, SharePointFile, false) then
            exit;

        ShowError(SharePointClient);
    end;

    internal procedure CopyFile(SharePointAccount: Record "Ext. SharePoint Account"; SourcePath: Text; TargetPath: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        Stream: InStream;
    begin
        TempBlob.CreateInStream(Stream);

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
        SharePointFile: Record "SharePoint File";
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if not SharePointClient.GetFolderFilesByServerRelativeUrl(GetParentPath(Path), SharePointFile) then
            ShowError(SharePointClient);

        SharePointFile.SetRange(Name, GetFileName(Path));
        exit(not SharePointFile.IsEmpty());
    end;

    internal procedure DeleteFile(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text)
    var
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if SharePointClient.DeleteFileByServerRelativeUrl(Path) then
            exit;

        ShowError(SharePointClient);
    end;

    #endregion

    #region Directory Operations

    internal procedure ListDirectories(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    var
        SharePointFolder: Record "SharePoint Folder";
        SharePointClient: Codeunit "SharePoint Client";
        OriginalPath: Text;
    begin
        OriginalPath := Path;
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if not SharePointClient.GetSubFoldersByServerRelativeUrl(Path, SharePointFolder) then
            ShowError(SharePointClient);

        FilePaginationData.SetEndOfListing(true);

        if not SharePointFolder.FindSet() then
            exit;

        repeat
            TempFileAccountContent.Init();
            TempFileAccountContent.Name := SharePointFolder.Name;
            TempFileAccountContent.Type := TempFileAccountContent.Type::Directory;
            TempFileAccountContent."Parent Directory" := CopyStr(OriginalPath, 1, MaxStrLen(TempFileAccountContent."Parent Directory"));
            TempFileAccountContent.Insert();
        until SharePointFolder.Next() = 0;
    end;

    internal procedure CreateDirectory(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text)
    var
        SharePointFolder: Record "SharePoint Folder";
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if SharePointClient.CreateFolder(Path, SharePointFolder) then
            exit;

        ShowError(SharePointClient);
    end;

    internal procedure DirectoryExists(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text) Result: Boolean
    var
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);

        Result := SharePointClient.FolderExistsByServerRelativeUrl(Path);

        if not SharePointClient.GetDiagnostics().IsSuccessStatusCode() then
            ShowError(SharePointClient);
    end;

    internal procedure DeleteDirectory(SharePointAccount: Record "Ext. SharePoint Account"; Path: Text)
    var
        SharePointClient: Codeunit "SharePoint Client";
    begin
        InitPath(SharePointAccount, Path);
        InitSharePointClient(SharePointAccount, SharePointClient);
        if SharePointClient.DeleteFolderByServerRelativeUrl(Path) then
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
    begin
        if (Path.TrimEnd(PathSeparator()).Contains(PathSeparator())) then
            ParentPath := Path.TrimEnd(PathSeparator()).Substring(1, Path.LastIndexOf(PathSeparator()));
    end;

    local procedure GetFileName(Path: Text) FileName: Text
    begin
        if (Path.TrimEnd(PathSeparator()).Contains(PathSeparator())) then
            FileName := Path.TrimEnd(PathSeparator()).Substring(Path.LastIndexOf(PathSeparator()) + 1);
    end;

    local procedure InitPath(SharePointAccount: Record "Ext. SharePoint Account"; var Path: Text)
    begin
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

    local procedure SplitPath(Path: Text; var ParentPath: Text; var FileName: Text)
    begin
        ParentPath := Path.TrimEnd(PathSeparator()).Substring(1, Path.LastIndexOf(PathSeparator()));
        FileName := Path.TrimEnd(PathSeparator()).Substring(Path.LastIndexOf(PathSeparator()) + 1);
    end;

    #endregion
}
