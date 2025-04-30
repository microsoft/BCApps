// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

using System.Telemetry;

codeunit 9455 "External File Storage Impl."
{
    Access = Internal;
    InherentPermissions = X;
    InherentEntitlements = X;

    var
        TempCurrFileAccount: Record "File Account" temporary;
        FileSystemConnector: Interface "External File Storage Connector";
        IsInitialized: Boolean;

    procedure Initialize(Scenario: Enum "File Scenario")
    var
        TempFileAccount: Record "File Account" temporary;
        FeatureTelemetry: Codeunit "Feature Telemetry";
        FileScenarioMgt: Codeunit "File Scenario";
        NoFileAccountFoundErr: Label 'No default file account defined.';
    begin
        if not FileScenarioMgt.GetFileAccount(Scenario, TempFileAccount) then
            Error(NoFileAccountFoundErr);

        Initialize(TempFileAccount);

        FeatureTelemetry.LogUptake('0000OPO', 'External File Storage', Enum::"Feature Uptake Status"::Used);
    end;

    procedure Initialize(TempFileAccount: Record "File Account" temporary)
    begin
        TempCurrFileAccount := TempFileAccount;
        FileSystemConnector := TempFileAccount.Connector;
        IsInitialized := true;
    end;

    procedure ListFiles(Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.ListFiles(TempCurrFileAccount."Account Id", Path, FilePaginationData, TempFileAccountContent);
    end;

    procedure GetFile(Path: Text; Stream: InStream)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.GetFile(TempCurrFileAccount."Account Id", Path, Stream);
    end;

    procedure CreateFile(Path: Text; Stream: InStream)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.CreateFile(TempCurrFileAccount."Account Id", Path, Stream);
    end;

    procedure CopyFile(SourcePath: Text; TargetPath: Text)
    begin
        CheckInitialization();
        CheckPath(SourcePath);
        CheckPath(TargetPath);
        FileSystemConnector.CopyFile(TempCurrFileAccount."Account Id", SourcePath, TargetPath);
    end;

    procedure MoveFile(SourcePath: Text; TargetPath: Text)
    begin
        CheckInitialization();
        CheckPath(SourcePath);
        CheckPath(TargetPath);
        FileSystemConnector.MoveFile(TempCurrFileAccount."Account Id", SourcePath, TargetPath);
    end;

    procedure FileExists(Path: Text): Boolean
    begin
        CheckInitialization();
        CheckPath(Path);
        exit(FileSystemConnector.FileExists(TempCurrFileAccount."Account Id", Path));
    end;

    procedure DeleteFile(Path: Text)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.DeleteFile(TempCurrFileAccount."Account Id", Path);
    end;

    procedure ListDirectories(Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.ListDirectories(TempCurrFileAccount."Account Id", Path, FilePaginationData, TempFileAccountContent);
    end;

    procedure CreateDirectory(Path: Text)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.CreateDirectory(TempCurrFileAccount."Account Id", Path);
    end;

    procedure DirectoryExists(Path: Text): Boolean
    begin
        CheckInitialization();
        CheckPath(Path);
        exit(FileSystemConnector.DirectoryExists(TempCurrFileAccount."Account Id", Path));
    end;

    procedure DeleteDirectory(Path: Text)
    begin
        CheckInitialization();
        CheckPath(Path);
        FileSystemConnector.DeleteDirectory(TempCurrFileAccount."Account Id", Path);
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
        TempFileAccountContent: Record "File Account Content" temporary;
        StorageBrowser: Page "Storage Browser";
    begin
        CheckInitialization();
        CheckPath(Path);

        StorageBrowser.SetPageCaption(DialogTitle);
        StorageBrowser.SetFileAccount(TempCurrFileAccount);
        StorageBrowser.EnableDirectoryLookupMode(Path);
        if StorageBrowser.RunModal() <> Action::LookupOK then
            exit('');

        StorageBrowser.GetRecord(TempFileAccountContent);
        if TempFileAccountContent.Type <> TempFileAccountContent.Type::Directory then
            exit('');

        exit(CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name));
    end;

    procedure SelectAndGetFilePath(Path: Text; FileFilter: Text; DialogTitle: Text): Text
    var
        TempFileAccountContent: Record "File Account Content" temporary;
        StorageBrowser: Page "Storage Browser";
    begin
        CheckInitialization();
        CheckPath(Path);

        StorageBrowser.SetPageCaption(DialogTitle);
        StorageBrowser.SetFileAccount(TempCurrFileAccount);
        StorageBrowser.EnableFileLookupMode(Path, FileFilter);
        if StorageBrowser.RunModal() <> Action::LookupOK then
            exit('');

        StorageBrowser.GetRecord(TempFileAccountContent);
        if TempFileAccountContent.Type <> TempFileAccountContent.Type::File then
            exit('');

        exit(CombinePath(TempFileAccountContent."Parent Directory", TempFileAccountContent.Name));
    end;

    procedure SaveFile(Path: Text; FileNameSuggestion: Text; FileExtension: Text; DialogTitle: Text): Text
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
        StorageBrowser.SetFileAccount(TempCurrFileAccount);
        StorageBrowser.EnableSaveFileLookupMode(Path, FileNameSuggestion, FileExtension);
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
        FileAccountImpl.BrowseAccount(TempCurrFileAccount);
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