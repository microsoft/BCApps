// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;
using System.Utilities;

codeunit 135814 "Test File Storage Connector" implements "External File Storage Connector", "External File Storage Context"
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
        TempBlobStream: InStream;
        FileIndex: Integer;
    begin
        GetFileCallCount += 1;
        LastReadAccountId := AccountId;
        LastReadPath := Path;
        if FailOnGetFile then
            Error(FailedToGetFileErr);
        if HasReadbackStream then begin
            ReadbackBlob.CreateInStream(Stream);
            exit;
        end;

        if not StoreFileContent then
            exit;

        if not StoredFileIndexes.Get(Format(AccountId) + Path, FileIndex) then
            Error(FileNotFoundErr, Path);

        StoredFileContents.Get(FileIndex, TempBlob);
        TempBlob.CreateInStream(TempBlobStream);
        // Keep the stream alive across the connector interface, as the production connectors do.
        Content.WriteFrom(TempBlobStream);
        Content.ReadAs(Stream);
    end;

    procedure CreateFile(AccountId: Guid; Path: Text; Stream: InStream);
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
    begin
        CreateFileCallCount += 1;
        if not StoreFileContent then
            exit;

        if FileConnectorMock.FailOnSend() then
            Error(FailedToCreateFileErr);

        TempBlob.CreateOutStream(OutStream);
        CopyStream(OutStream, Stream);
        StoredFileContents.Add(TempBlob);
        StoredFileIndexes.Set(Format(AccountId) + Path, StoredFileContents.Count());
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
        if not StoreFileContent then
            exit(false);

        exit(StoredFileIndexes.ContainsKey(Format(AccountId) + Path));
    end;

    procedure DeleteFile(AccountId: Guid; Path: Text);
    begin
        // The platform invokes connector callbacks inside a TryFunction, so we cannot
        // Modify() a table from here. Stash the path in a SingleInstance global instead.
        LastDeletedFilePath := Path;
        if StoreFileContent then
            if StoredFileIndexes.ContainsKey(Format(AccountId) + Path) then
                StoredFileIndexes.Remove(Format(AccountId) + Path);
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

    procedure GetDestinationContext(AccountId: Guid; LockAccount: Boolean; var DestinationDescriptor: Text; var ChangeGeneration: BigInteger): Boolean
    var
        Account: Record "Test File Account";
        Descriptor: JsonObject;
    begin
        if not ContextEnabled then
            exit(false);
        if LockAccount then
            Account.ReadIsolation(IsolationLevel::UpdLock);
        if not Account.Get(AccountId) then
            exit(false);
        Descriptor.Add('version', 1);
        Descriptor.Add('testAccount', Format(AccountId));
        Descriptor.WriteTo(DestinationDescriptor);
        ChangeGeneration := Account.SystemRowVersion;
        exit(true);
    end;

    internal procedure ConfigureReadback(Content: Text)
    var
        OutStream: OutStream;
    begin
        Clear(ReadbackBlob);
        ReadbackBlob.CreateOutStream(OutStream);
        if Content <> '' then
            OutStream.WriteText(Content);
        HasReadbackStream := true;
    end;

    internal procedure EnableContext(Enabled: Boolean)
    begin
        ContextEnabled := Enabled;
    end;

    internal procedure ResetReadback()
    begin
        Clear(ReadbackBlob);
        Clear(HasReadbackStream);
        Clear(ContextEnabled);
        Clear(GetFileCallCount);
        Clear(CreateFileCallCount);
        Clear(LastReadAccountId);
        Clear(LastReadPath);
    end;

    internal procedure GetReadbackCallCount(): Integer
    begin
        exit(GetFileCallCount);
    end;

    internal procedure GetCreateFileCallCount(): Integer
    begin
        exit(CreateFileCallCount);
    end;

    internal procedure GetLastReadAccountId(): Guid
    begin
        exit(LastReadAccountId);
    end;

    internal procedure GetLastReadPath(): Text
    begin
        exit(LastReadPath);
    end;

    internal procedure SetStoreFileContent(NewStoreFileContent: Boolean)
    begin
        StoreFileContent := NewStoreFileContent;
        Clear(StoredFileContents);
        Clear(StoredFileIndexes);
        Clear(ReadbackBlob);
        Clear(HasReadbackStream);
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
        ReadbackBlob: Codeunit "Temp Blob";
        StoredFileContents: Codeunit "Temp Blob List";
        StoredFileIndexes: Dictionary of [Text, Integer];
        FailOnGetFile: Boolean;
        StoreFileContent: Boolean;
        FileExistsCallCount: Integer;
        LastDeletedFilePath: Text;
        FailedToGetFileErr: Label 'Failed to get file.';
        HasReadbackStream: Boolean;
        ContextEnabled: Boolean;
        GetFileCallCount: Integer;
        CreateFileCallCount: Integer;
        LastReadAccountId: Guid;
        LastReadPath: Text;
        FailedToCreateFileErr: Label 'Failed to create file.';
        FileNotFoundErr: Label 'The file %1 does not exist.', Comment = '%1 = File path';
}