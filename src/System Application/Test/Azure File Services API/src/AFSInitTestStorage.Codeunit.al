// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Azure.Storage.Files;

using System.Azure.Storage;
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
        FileStorageBaseUrlTxt: Label 'http://127.0.0.1:10002/devstoreaccount1', Locked = true;
        StorageAccountNameTxt: Label 'devstoreaccount1', Locked = true;
        AccessKeyTxt: Label 'Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==', Locked = true;

    procedure ClearFileShare(): Text
    var
        TempAFSDirectoryContent: Record "AFS Directory Content";
        AFSFileClient: Codeunit "AFS File Client";
        Visited: List of [Text];
    begin
        EnsureFileShareExists();
        InitializeFileClient(AFSFileClient, AFSGetTestStorageAuth.GetDefaultAccountSAS());
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


    procedure InitializeFileClient(var AFSFileClient: Codeunit "AFS File Client"; Authorization: Interface "Storage Service Authorization")
    begin
        AFSFileClient.Initialize(GetStorageAccountName(), GetFileShareName(), Authorization);
        AFSFileClient.SetBaseUrl(GetFileStorageBaseUrl());
    end;

    procedure EnsureFileShareExists()
    var
        Authorization: Interface "Storage Service Authorization";
        HttpClient: HttpClient;
        HttpRequestMessage: HttpRequestMessage;
        HttpResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        CreateFileShareUriLbl: Label '%1/%2?restype=share', Locked = true;
        CouldNotCreateFileShareErr: Label 'Could not create file share %1.', Comment = '%1 = File Share Name';
    begin
        Authorization := AFSGetTestStorageAuth.GetDefaultAccountSAS(GetAccessKey());

        HttpRequestMessage.Method('PUT');
        HttpRequestMessage.SetRequestUri(StrSubstNo(CreateFileShareUriLbl, GetFileStorageBaseUrl(), GetFileShareName()));
        HttpRequestMessage.GetHeaders(Headers);
        Headers.Add('x-ms-version', '2020-10-02');
        Authorization.Authorize(HttpRequestMessage, GetStorageAccountName());

        if not HttpClient.Send(HttpRequestMessage, HttpResponseMessage) then
            Error(CouldNotCreateFileShareErr, GetFileShareName());

        if HttpResponseMessage.IsSuccessStatusCode() or (HttpResponseMessage.HttpStatusCode() = 409) then
            exit;

        Error(CouldNotCreateFileShareErr, GetFileShareName());
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
    /// Gets Azurite file storage base URL.
    /// </summary>
    /// <returns>Azurite file storage base URL</returns>
    procedure GetFileStorageBaseUrl(): Text
    begin
        exit(FileStorageBaseUrlTxt);
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