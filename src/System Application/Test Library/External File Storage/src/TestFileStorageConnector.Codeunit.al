// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;
using System.Utilities;

codeunit 135814 "Test File Storage Connector" implements "External File Storage Connector"
{
    SingleInstance = true;

    procedure ListFiles(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary);
    begin
        TempFileAccountContent.Init();
        TempFileAccountContent.Type := TempFileAccountContent.Type::Directory;
        TempFileAccountContent.Name := 'Test Folder';
        TempFileAccountContent.Insert();

        TempFileAccountContent.Init();
        TempFileAccountContent.Type := TempFileAccountContent.Type::File;
        TempFileAccountContent.Name := 'Test.pdf';
        TempFileAccountContent.Insert();
    end;

    procedure GetFile(AccountId: Guid; Path: Text; Stream: InStream);
    var
        TempBlob: Codeunit "Temp Blob";
        Content: HttpContent;
        StoredStream: InStream;
    begin
        if FailOnGetFile then
            Error(FailedToGetFileErr);

        if not StoreFileContent then
            exit;

        if not StoredFiles.ContainsKey(GetStoredFileKey(AccountId, Path)) then
            Error(StoredFileNotFoundErr, Path);

        StoredContent.Get(StoredFiles.Get(GetStoredFileKey(AccountId, Path)), TempBlob);
        TempBlob.CreateInStream(StoredStream);
        Content.WriteFrom(StoredStream);
        Content.ReadAs(Stream);
    end;

    procedure CreateFile(AccountId: Guid; Path: Text; Stream: InStream);
    var
        TempBlob: Codeunit "Temp Blob";
        StoredStream: OutStream;
    begin
        if not StoreFileContent then
            exit;

        if FileConnectorMock.FailOnSend() then
            Error(FailedToCreateFileErr);

        TempBlob.CreateOutStream(StoredStream);
        CopyStream(StoredStream, Stream);
        StoredContent.Add(TempBlob);
        StoredFiles.Set(GetStoredFileKey(AccountId, Path), StoredContent.Count());
    end;

    procedure CopyFile(AccountId: Guid; SourcePath: Text; TargetPath: Text);
    begin
    end;

    procedure MoveFile(AccountId: Guid; SourcePath: Text; TargetPath: Text);
    begin
    end;

    procedure FileExists(AccountId: Guid; Path: Text): Boolean;
    begin
        FileExistsCallCount += 1;
        exit(StoreFileContent and StoredFiles.ContainsKey(GetStoredFileKey(AccountId, Path)));
    end;

    procedure DeleteFile(AccountId: Guid; Path: Text);
    begin
        // The platform invokes connector callbacks inside a TryFunction, so we cannot
        // Modify() a table from here. Stash the path in a SingleInstance global instead.
        LastDeletedFilePath := Path;
        if StoreFileContent then
            if StoredFiles.ContainsKey(GetStoredFileKey(AccountId, Path)) then
                StoredFiles.Remove(GetStoredFileKey(AccountId, Path));
    end;

    internal procedure GetLastDeletedPath(): Text
    begin
        exit(LastDeletedFilePath);
    end;

    internal procedure ResetLastDeletedPath()
    begin
        Clear(LastDeletedFilePath);
    end;

    internal procedure GetFileExistsCallCount(): Integer
    begin
        exit(FileExistsCallCount);
    end;

    internal procedure ResetFileExistsCallCount()
    begin
        Clear(FileExistsCallCount);
    end;

    internal procedure SetFailOnGetFile(NewFailOnGetFile: Boolean)
    begin
        FailOnGetFile := NewFailOnGetFile;
    end;

    internal procedure SetStoreFileContent(NewStoreFileContent: Boolean)
    begin
        StoreFileContent := NewStoreFileContent;
        Clear(StoredFiles);
        Clear(StoredContent);
    end;

    local procedure GetStoredFileKey(AccountId: Guid; Path: Text): Text
    begin
        exit(Format(AccountId) + Path);
    end;

    procedure ListDirectories(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var TempFileAccountContent: Record "File Account Content" temporary);
    begin
    end;

    procedure CreateDirectory(AccountId: Guid; Path: Text);
    begin
    end;

    procedure DirectoryExists(AccountId: Guid; Path: Text): Boolean;
    begin
    end;

    procedure DeleteDirectory(AccountId: Guid; Path: Text);
    begin
    end;

    procedure GetAccounts(var TempAccounts: Record "File Account" temporary)
    begin
        FileConnectorMock.GetAccounts(TempAccounts);
    end;

    procedure ShowAccountInformation(AccountId: Guid)
    begin
        Message('Showing information for account: %1', AccountId);
    end;

    procedure RegisterAccount(var TempFileAccount: Record "File Account" temporary): Boolean
    var
    begin
        if FileConnectorMock.FailOnRegisterAccount() then
            Error('Failed to register account');

        if FileConnectorMock.UnsuccessfulRegister() then
            exit(false);

        TempFileAccount."Account Id" := CreateGuid();
        TempFileAccount.Name := 'Test account';

        exit(true);
    end;

    procedure DeleteAccount(AccountId: Guid): Boolean
    var
        TestFileAccount: Record "Test File Account";
    begin
        if TestFileAccount.Get(AccountId) then
            exit(TestFileAccount.Delete());
        exit(false);
    end;

    procedure GetLogoAsBase64(): Text
    begin
    end;

    procedure GetDescription(): Text[250]
    begin
        exit('Lorem ipsum dolor sit amet, consectetur adipiscing elit. Duis ornare ante a est commodo interdum. Pellentesque eu diam maximus, faucibus neque ut, viverra leo. Praesent ullamcorper nibh ut pretium dapibus. Nullam eu dui libero. Etiam ac cursus metus.')
    end;

    var
        FileConnectorMock: Codeunit "File Connector Mock";
        StoredContent: Codeunit "Temp Blob List";
        StoredFiles: Dictionary of [Text, Integer];
        StoreFileContent: Boolean;
        FailOnGetFile: Boolean;
        FileExistsCallCount: Integer;
        LastDeletedFilePath: Text;
        FailedToGetFileErr: Label 'Failed to get file.';
        FailedToCreateFileErr: Label 'Failed to create file.';
        StoredFileNotFoundErr: Label 'The file %1 does not exist.', Comment = '%1 = Requested file path';
}