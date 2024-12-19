// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;

codeunit 135814 "Test File Storage Connector" implements "External File Storage Connector"
{
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
}