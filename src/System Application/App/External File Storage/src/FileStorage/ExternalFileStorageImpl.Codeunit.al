// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

codeunit 9455 "External File Storage Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        CurrFileAccount: Record "File Account";
        FileSystemConnector: Interface "External File Storage Connector";
        IsInitialized: Boolean;

    procedure Initialize(Scenario: Enum "File Scenario")
    var
        FileAccount: Record "File Account";
        FileScenarioMgt: Codeunit "File Scenario";
        NoFileAccountFoundErr: Label 'No default file account defined.';
    begin
        if not FileScenarioMgt.GetFileAccount(Scenario, FileAccount) then
            Error(NoFileAccountFoundErr);

        Initialize(FileAccount);
    end;

    procedure Initialize(FileAccount: Record "File Account")
    begin
        CurrFileAccount := FileAccount;
        FileSystemConnector := FileAccount.Connector;
        IsInitialized := true;
    end;

    procedure ListFiles(Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var FileAccountContent: Record "File Account Content" temporary)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.ListFiles(CurrFileAccount."Account Id", Path, FilePaginationData, FileAccountContent);
    end;

    procedure GetFile(Path: Text; Stream: InStream)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.GetFile(CurrFileAccount."Account Id", Path, Stream);
    end;

    procedure CreateFile(Path: Text; Stream: InStream)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.CreateFile(CurrFileAccount."Account Id", Path, Stream);
    end;

    procedure CopyFile(SourcePath: Text; TargetPath: Text)
    begin
        CheckInitialization();
        CheckPath(SourcePath);
        CheckPath(TargetPath);
        FileSystemConnector.CopyFile(CurrFileAccount."Account Id", SourcePath, TargetPath);
    end;

    procedure MoveFile(SourcePath: Text; TargetPath: Text)
    begin
        CheckInitialization();
        CheckPath(SourcePath);
        CheckPath(TargetPath);
        FileSystemConnector.MoveFile(CurrFileAccount."Account Id", SourcePath, TargetPath);
    end;

    procedure FileExists(Path: Text): Boolean
    begin
        CheckInitialization();
        CheckPath(Path);
        exit(FileSystemConnector.FileExists(CurrFileAccount."Account Id", Path));
    end;

    procedure DeleteFile(Path: Text)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.DeleteFile(CurrFileAccount."Account Id", Path);
    end;

    procedure ListDirectories(Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var FileAccountContent: Record "File Account Content" temporary)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.ListDirectories(CurrFileAccount."Account Id", Path, FilePaginationData, FileAccountContent);
    end;

    procedure CreateDirectory(Path: Text)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.CreateDirectory(CurrFileAccount."Account Id", Path);
    end;

    procedure DirectoryExists(Path: Text): Boolean
    begin
        CheckInitialization();
        CheckPath(Path);
        exit(FileSystemConnector.DirectoryExists(CurrFileAccount."Account Id", Path));
    end;

    procedure DeleteDirectory(Path: Text)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.DeleteDirectory(CurrFileAccount."Account Id", Path);
    end;

    procedure PathSeparator(): Text
    begin
        exit('/');
    end;

    procedure CombinePath(Path: Text; ChildPath: Text): Text
    begin
        if Path = '' then
            exit(ChildPath);

        if not Path.EndsWith(PathSeparator()) then
            Path += PathSeparator();

        exit(Path + ChildPath);
    end;

    procedure GetParentPath(Path: Text) ParentPath: Text
    begin
        Path := Path.TrimEnd(PathSeparator());
        if Path.TrimEnd(PathSeparator()).Contains(PathSeparator()) then
            ParentPath := Path.Substring(1, Path.LastIndexOf(PathSeparator()));
    end;

    procedure SelectAndGetFolderPath(Path: Text; DialogTitle: Text): Text
    var
        FileAccountContent: Record "File Account Content";
        StorageBrowser: Page "Storage Browser";
    begin
        CheckInitialization();
        CheckPath(Path);

        StorageBrowser.SetPageCaption(DialogTitle);
        StorageBrowser.SetFileAccount(CurrFileAccount);
        StorageBrowser.EnableDirectoryLookupMode(Path);
        if StorageBrowser.RunModal() <> Action::LookupOK then
            exit('');

        StorageBrowser.GetRecord(FileAccountContent);
        if FileAccountContent.Type <> FileAccountContent.Type::Directory then
            exit('');

        exit(CombinePath(FileAccountContent."Parent Directory", FileAccountContent.Name));
    end;

    procedure SelectAndGetFilePath(Path: Text; FileFilter: Text; DialogTitle: Text): Text
    var
        FileAccountContent: Record "File Account Content";
        StorageBrowser: Page "Storage Browser";
    begin
        CheckInitialization();
        CheckPath(Path);

        StorageBrowser.SetPageCaption(DialogTitle);
        StorageBrowser.SetFileAccount(CurrFileAccount);
        StorageBrowser.EnableFileLookupMode(Path, FileFilter);
        if StorageBrowser.RunModal() <> Action::LookupOK then
            exit('');

        StorageBrowser.GetRecord(FileAccountContent);
        if FileAccountContent.Type <> FileAccountContent.Type::File then
            exit('');

        exit(CombinePath(FileAccountContent."Parent Directory", FileAccountContent.Name));
    end;

    procedure SaveFile(Path: Text; FileExtension: Text; DialogTitle: Text): Text
    var
        StorageBrowser: Page "Storage Browser";
        FileName, FileNameWithExtension : Text;
        PleaseProvideFileExtensionErr: Label 'Please provide a valid file extension.';
        FileNameTok: Label '%1.%2', Locked = true;
    begin
        CheckInitialization();
        CheckPath(Path);

        if FileExtension = '' then
            Error(PleaseProvideFileExtensionErr);

        StorageBrowser.SetPageCaption(DialogTitle);
        StorageBrowser.SetFileAccount(CurrFileAccount);
        StorageBrowser.EnableSaveFileLookupMode(Path, FileExtension);
        if StorageBrowser.RunModal() <> Action::LookupOK then
            exit('');

        FileName := StorageBrowser.GetFileName();
        if FileName = '' then
            exit('');

        FileNameWithExtension := StrSubstNo(FileNameTok, FileName, FileExtension);
        exit(CombinePath(StorageBrowser.GetCurrentDirectory(), FileNameWithExtension));
    end;

    procedure BrowseAccount()
    var
        FileAccountImpl: Codeunit "File Account Impl.";
    begin
        CheckInitialization();
        FileAccountImpl.BrowseAccount(CurrFileAccount);
    end;

    local procedure CheckInitialization()
    var
        NotInitializedErr: Label 'Please call Initialize() first.';
    begin
        if IsInitialized then
            exit;

        Error(NotInitializedErr);
    end;

    local procedure CheckPath(Path: Text)
    var
        InvalidChar: Char;
        PathCannotStartWithSlashErr: Label 'The path %1 can not start with /.', Comment = '%1 - Path';
        InvalidChars: Text;

    begin
        if Path.StartsWith('/') then
            Error(PathCannotStartWithSlashErr, Path);

        InvalidChars := '"''<>\|';
        foreach InvalidChar in InvalidChars do
            CheckPath(Path, InvalidChar);
    end;

    local procedure CheckPath(Path: Text; InvalidChar: Char)
    var
        InvalidPathErr: Label 'The path %1 contains the invalid character %2.', Comment = '%1 - Path, %2 - Invalid Character';
    begin
        if Path.Contains(InvalidChar) then
            Error(InvalidPathErr, Path, InvalidChar);
    end;
}