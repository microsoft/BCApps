// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.FileSystem;

using System.FileSystem;

codeunit 80202 "Test File System Connector" implements "File System Connector"
{
    procedure ListFiles(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var FileAccountContent: Record "File Account Content" temporary);
    begin
        FileAccountContent.Init();
        FileAccountContent.Type := FileAccountContent.Type::Directory;
        FileAccountContent.Name := 'Test Folder';
        FileAccountContent.Insert();

        FileAccountContent.Init();
        FileAccountContent.Type := FileAccountContent.Type::File;
        FileAccountContent.Name := 'Test.pdf';
        FileAccountContent.Insert();
    end;

    procedure GetFile(AccountId: Guid; Path: Text; Stream: InStream);
    begin

    end;

    procedure CreateFile(AccountId: Guid; Path: Text; Stream: InStream);
    begin

    end;

    procedure CopyFile(AccountId: Guid; SourcePath: Text; TargetPath: Text);
    begin

    end;

    procedure MoveFile(AccountId: Guid; SourcePath: Text; TargetPath: Text);
    begin

    end;

    procedure FileExists(AccountId: Guid; Path: Text): Boolean;
    begin

    end;

    procedure DeleteFile(AccountId: Guid; Path: Text);
    begin

    end;

    procedure ListDirectories(AccountId: Guid; Path: Text; FilePaginationData: Codeunit "File Pagination Data"; var FileAccountContent: Record "File Account Content" temporary);
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

    procedure GetAccounts(var Accounts: Record "File Account")
    begin
        ConnectorMock.GetAccounts(Accounts);
    end;

    procedure ShowAccountInformation(AccountId: Guid)
    begin
        Message('Showing information for account: %1', AccountId);
    end;

    procedure RegisterAccount(var FileAccount: Record "File Account"): Boolean
    var
    begin
        if ConnectorMock.FailOnRegisterAccount() then
            Error('Failed to register account');

        if ConnectorMock.UnsuccessfulRegister() then
            exit(false);

        FileAccount."Account Id" := CreateGuid();
        FileAccount.Name := 'Test account';

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
        ConnectorMock: Codeunit "Connector Mock";
}