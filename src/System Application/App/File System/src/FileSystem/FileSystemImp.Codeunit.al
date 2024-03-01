// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

codeunit 9455 "File System Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        FileSystemConnector: Interface "File System Connector";
        CurrFileAccount: Record "File Account";
        IsInitialized: Boolean;

    procedure Initialize(Scenario: Enum "File Scenario")
    var
        FileAccount: Record "File Account";
        FileScenario: Codeunit "File Scenario";
        NoFileAccountFoundErr: Label 'No defaut file account defined.';
    begin
        if not FileScenario.GetFileAccount(Scenario, FileAccount) then
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
        CheckPath(Path);
        CheckInitialization();
        FileSystemConnector.ListFiles(CurrFileAccount."Account Id", Path, FilePaginationData, FileAccountContent);
    end;

    procedure GetFile(Path: Text; Stream: InStream)
    begin
        CheckPath(Path);
        CheckInitialization();
        FileSystemConnector.GetFile(CurrFileAccount."Account Id", Path, Stream);
    end;

    procedure CreateFile(Path: Text; Stream: InStream)
    begin
        CheckPath(Path);
        CheckInitialization();
        FileSystemConnector.CreateFile(CurrFileAccount."Account Id", Path, Stream);
    end;


    procedure CopyFile(SourcePath: Text; TargetPath: Text)
    begin
        CheckPath(SourcePath);
        CheckPath(TargetPath);
        CheckInitialization();
        FileSystemConnector.CopyFile(CurrFileAccount."Account Id", SourcePath, TargetPath);
    end;

    procedure MoveFile(SourcePath: Text; TargetPath: Text)
    begin
        CheckPath(SourcePath);
        CheckPath(TargetPath);
        CheckInitialization();
        FileSystemConnector.MoveFile(CurrFileAccount."Account Id", SourcePath, TargetPath);
    end;

    procedure FileExists(Path: Text): Boolean
    begin
        CheckPath(Path);
        CheckInitialization();
        exit(FileSystemConnector.FileExists(CurrFileAccount."Account Id", Path));
    end;

    procedure DeleteFile(Path: Text)
    begin
        CheckPath(Path);
        CheckInitialization();
        FileSystemConnector.DeleteFile(CurrFileAccount."Account Id", Path);
    end;

    procedure ListDirectories(Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var FileAccountContent: Record "File Account Content" temporary)
    begin
        CheckPath(Path);
        CheckInitialization();
        FileSystemConnector.ListDirectories(CurrFileAccount."Account Id", Path, FilePaginationData, FileAccountContent);
    end;

    procedure CreateDirectory(Path: Text)
    begin
        CheckPath(Path);
        CheckInitialization();
        FileSystemConnector.CreateDirectory(CurrFileAccount."Account Id", Path);
    end;

    procedure DirectoryExists(Path: Text): Boolean
    begin
        CheckPath(Path);
        CheckInitialization();
        exit(FileSystemConnector.DirectoryExists(CurrFileAccount."Account Id", Path));
    end;

    procedure DeleteDirectory(Path: Text)
    begin
        CheckPath(Path);
        CheckInitialization();
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

    procedure SelectFolderUI(Path: Text; DialogTitle: Text): Text
    var
        FileAccountContent: Record "File Account Content";
        FileAccountBrowser: Page "File Account Browser";
    begin
        CheckPath(Path);
        CheckInitialization();

        FileAccountBrowser.SetPageCaption(DialogTitle);
        FileAccountBrowser.SetFileAccount(CurrFileAccount);
        FileAccountBrowser.EnableDirectoryLookupMode(Path);
        if FileAccountBrowser.RunModal() <> Action::LookupOK then
            exit('');

        FileAccountBrowser.GetRecord(FileAccountContent);
        if FileAccountContent.Type <> FileAccountContent.Type::Directory then
            exit('');

        exit(CombinePath(FileAccountContent."Parent Directory", FileAccountContent.Name));
    end;

    procedure SelectFileUI(Path: Text; FileFilter: Text; DialogTitle: Text): Text
    var
        FileAccountContent: Record "File Account Content";
        FileAccountBrowser: Page "File Account Browser";
    begin
        CheckPath(Path);
        CheckInitialization();

        FileAccountBrowser.SetPageCaption(DialogTitle);
        FileAccountBrowser.SetFileAccount(CurrFileAccount);
        FileAccountBrowser.EnableFileLookupMode(Path, FileFilter);
        if FileAccountBrowser.RunModal() <> Action::LookupOK then
            exit('');

        FileAccountBrowser.GetRecord(FileAccountContent);
        if FileAccountContent.Type <> FileAccountContent.Type::File then
            exit('');

        exit(CombinePath(FileAccountContent."Parent Directory", FileAccountContent.Name));
    end;

    procedure SaveFileUI(Path: Text; FileExtension: Text; DialogTitle: Text): Text
    var
        FileAccountContent: Record "File Account Content";
        FileAccountBrowser: Page "File Account Browser";
        FileName, FileNameWithExtenion : Text;
        PleaseProvideFileExtensionErr: Label 'Please provide a valid file extension.';
        FileNameTok: Label '%1.%2', Locked = true;
    begin
        CheckPath(Path);
        CheckInitialization();

        if FileExtension = '' then
            Error(PleaseProvideFileExtensionErr);

        FileAccountBrowser.SetPageCaption(DialogTitle);
        FileAccountBrowser.SetFileAccount(CurrFileAccount);
        FileAccountBrowser.EnableSaveFileLookupMode(Path, FileExtension);
        if FileAccountBrowser.RunModal() <> Action::LookupOK then
            exit('');

        FileName := FileAccountBrowser.GetFileName();
        if FileName = '' then
            exit('');

        FileNameWithExtenion := StrSubstNo(FileNameTok, FileName, FileExtension);
        exit(CombinePath(FileAccountBrowser.GetCurrentDirectory(), FileNameWithExtenion));
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
        NotInitializedErr: Label 'Please call Initalize() first.';
    begin
        if IsInitialized then
            exit;

        Error(NotInitializedErr);
    end;

    local procedure CheckPath(Path: Text)
    var
        InvalidChars: Text;
        InvalidChar: Char;
        PathCannotStartWithSlashErr: Label 'The path %1 can not start with /.', Comment = '%1 - Path';

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