// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Azure.Storage.Files;

using System.Azure.Storage.Files;

/// <summary>
/// Provides functionality for initializing or resetting azure storage accounts file shares.
/// </summary>
codeunit 132519 "AFS Init. Test Storage"
{
    Access = Internal;

    var
        AFSGetTestStorageAuth: Codeunit "AFS Get Test Storage Auth.";
        FileShareNameTxt: Label 'filesharename', Locked = true;
        StorageAccountNameTxt: Label 'storageaccountname', Locked = true;
        AccessKeyTxt: Label 'base64accountkey', Locked = true;

    procedure ClearFileShare(): Text
    var
        TempAFSDirectoryContent: Record "AFS Directory Content";
        AFSFileClient: Codeunit "AFS File Client";
        Visited: List of [Text];
    begin
        AFSFileClient.Initialize(GetStorageAccountName(), GetFileShareName(), AFSGetTestStorageAuth.GetDefaultAccountSAS());
        AFSFileClient.ListDirectory('', TempAFSDirectoryContent);
        if not TempAFSDirectoryContent.FindSet() then
            exit;
        DeleteDirectoryRecursive(AFSFileClient, TempAFSDirectoryContent, Visited);
    end;

    local procedure DeleteDirectoryRecursive(var AFSFileClient: Codeunit "AFS File Client"; var TempAFSDirectoryContent: Record "AFS Directory Content"; var Visited: List of [Text])
    var
        TempAFSDirectoryContentLocal: Record "AFS Directory Content";
    begin
        if not TempAFSDirectoryContent.FindSet() then
            exit;
        repeat
            if not Visited.Contains(TempAFSDirectoryContent."Full Name") then
                if TempAFSDirectoryContent."Resource Type" = TempAFSDirectoryContent."Resource Type"::File then
                    AFSFileClient.DeleteFile(TempAFSDirectoryContent."Full Name")
                else begin
                    AFSFileClient.ListDirectory(TempAFSDirectoryContent."Full Name", TempAFSDirectoryContentLocal);
                    Visited.Add(TempAFSDirectoryContent."Full Name");
                    DeleteDirectoryRecursive(AFSFileClient, TempAFSDirectoryContentLocal, Visited);
                    AFSFileClient.DeleteDirectory(TempAFSDirectoryContent."Full Name");
                    Visited.Remove(TempAFSDirectoryContent."Full Name");
                end;
        until TempAFSDirectoryContent.Next() = 0;
    end;

    /// <summary>
    /// Gets storage account name.
    /// </summary>
    /// <returns>Storage account name</returns>
    procedure GetStorageAccountName(): Text
    begin
        exit(StorageAccountNameTxt);
    end;

    /// <summary>
    /// Gets file share name.
    /// </summary>
    /// <returns>File share name</returns>
    procedure GetFileShareName(): Text
    begin
        exit(FileShareNameTxt);
    end;

    /// <summary>
    /// Gets storage account key.
    /// </summary>
    /// <returns>Storage account key</returns>
    procedure GetAccessKey(): Text;
    begin
        exit(AccessKeyTxt);
    end;
}