// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.SFTPClient;

using System;
using System.SFTPClient;

codeunit 139075 "Mock SFTP Client" implements "ISFTP Client"
{
    Access = Internal;

    var
        IsConnectedVar: Boolean;
        ShouldFailConnect: Boolean;
        ExceptionTypeToReturn: Enum "SFTP Exception Type";
        ExceptionMessageToReturn: Text;
        WorkingDirectoryVar: Text;
        SHA256Fingerprint: Text;
        TrustedServer: Boolean;
        FilesExist: Dictionary of [Text, Boolean];
        FilesContent: Dictionary of [Text, List of [Text]];
        FingerprintsSHA256: List of [Text];
        FingerprintsMD5: List of [Text];

    procedure SetShouldFailConnect(NewShouldFailConnect: Boolean)
    begin
        ShouldFailConnect := NewShouldFailConnect;
    end;

    procedure SetExceptionToReturn(NewExceptionType: Enum "SFTP Exception Type"; NewExceptionMessage: Text)
    begin
        ExceptionTypeToReturn := NewExceptionType;
        ExceptionMessageToReturn := NewExceptionMessage;
    end;

    procedure SetWorkingDirectoryInternal(NewWorkingDirectory: Text)
    begin
        WorkingDirectoryVar := NewWorkingDirectory;
    end;

    procedure SetHostKeyFingerprintSHA256(NewSHA256Fingerprint: Text)
    begin
        SHA256Fingerprint := NewSHA256Fingerprint;
    end;

    procedure SetSHA256Fingerprints(FingerPrints: List of [Text])
    begin
        FingerprintsSHA256 := FingerPrints;
    end;

    procedure SetMD5Fingerprints(FingerPrints: List of [Text])
    begin
        FingerprintsMD5 := FingerPrints;
    end;

    procedure AddFile(Path: Text; Content: Text)
    var
        ContentList: List of [Text];
    begin
        FilesExist.Add(Path, true);

        if FilesContent.ContainsKey(Path) then
            FilesContent.Remove(Path);

        ContentList.Add(Content);
        FilesContent.Add(Path, ContentList);
    end;

    procedure RemoveFile(Path: Text)
    begin
        if FilesExist.ContainsKey(Path) then
            FilesExist.Remove(Path);

        if FilesContent.ContainsKey(Path) then
            FilesContent.Remove(Path);
    end;

    // Interface implementation
    procedure Connect(): Boolean
    begin
        if ShouldFailConnect then
            exit(false);

        // Simulate fingerprint validation like DotnetSFTPClient
        TrustedServer := false;
        if SHA256Fingerprint = '' then
            SHA256Fingerprint := '5Vot7f2reXMzE6IR9GKiDCOz/bNf3lA0qYnBQzRgObo=';

        if FingerprintsSHA256.Contains(SHA256Fingerprint) then
            TrustedServer := true;

        if not TrustedServer then begin
            ExceptionTypeToReturn := Enum::"SFTP Exception Type"::"Untrusted Server Exception";
            ExceptionMessageToReturn := 'Server fingerprint not trusted';
            exit(false);
        end;

        IsConnectedVar := true;
        exit(true);
    end;

    procedure GetOperationException(var ExceptionType: Enum "SFTP Exception Type"; var ExceptionMessage: Text; var ServerFingerprintSHA256Param: Text)
    begin
        ExceptionType := ExceptionTypeToReturn;
        ExceptionMessage := ExceptionMessageToReturn;
        ServerFingerprintSHA256Param := SHA256Fingerprint;
    end;

    procedure Disconnect()
    begin
        IsConnectedVar := false;
    end;

    procedure IsConnected(): Boolean
    begin
        exit(IsConnectedVar);
    end;

    procedure Exists(Path: Text; var ExistResult: Boolean): Boolean
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        if FilesExist.ContainsKey(Path) then
            ExistResult := FilesExist.Get(Path)
        else
            ExistResult := false;

        exit(true);
    end;

    procedure Delete(Path: Text): Boolean
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        RemoveFile(Path);
        exit(true);
    end;

    procedure WorkingDirectory(var Result: Text): Boolean
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        Result := WorkingDirectoryVar;
        exit(true);
    end;

    procedure SetWorkingDirectory(Path: Text): Boolean
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        WorkingDirectoryVar := Path;
        exit(true);
    end;

    procedure SftpClient(Host: Text; Port: Integer; UserName: Text; Password: SecretText): Boolean
    begin
        exit(Connect());
    end;

    procedure SftpClient(Host: Text; Port: Integer; UserName: Text; PrivateKey: InStream): Boolean
    begin
        exit(Connect());
    end;

    procedure SftpClient(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText): Boolean
    begin
        exit(Connect());
    end;

    procedure ListDirectory(Path: Text; var Result: List of [Interface "ISFTP File"]): Boolean
    var
        MockSFTPFile: Codeunit "Mock SFTP File";
        FilePaths: List of [Text];
        FilePath: Text;
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        FilePaths := FilesExist.Keys;

        foreach FilePath in FilePaths do
            if FilePath.StartsWith(Path) then begin
                MockSFTPFile.Initialize(FilePath, false, 100, CreateDateTime(20260101D, 010000T));
                Result.Add(MockSFTPFile);
            end;

        exit(true);
    end;

    procedure ReadAllBytes(Path: Text; var Bytes: Dotnet Array): Boolean
    var
        Encoding: DotNet Encoding;
        ContentList: List of [Text];
        Content: Text;
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        if not FilesContent.ContainsKey(Path) then
            exit(false);

        ContentList := FilesContent.Get(Path);

        if ContentList.Count > 0 then begin
            ContentList.Get(1, Content);
            Bytes := Encoding.UTF8().GetBytes(Content);
        end;

        exit(true);
    end;

    procedure WriteAllBytes(Path: Text; Bytes: Dotnet Array): Boolean
    var
        Encoding: DotNet Encoding;
        ContentList: List of [Text];
        Content: Text;
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        Content := Encoding.UTF8().GetString(Bytes);

        FilesExist.Add(Path, true);

        if FilesContent.ContainsKey(Path) then
            FilesContent.Remove(Path);

        ContentList.Add(Content);
        FilesContent.Add(Path, ContentList);

        exit(true);
    end;

    procedure Get(Path: Text; var Result: Interface "ISFTP File"): Boolean
    var
        MockSFTPFile: Codeunit "Mock SFTP File";
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        if FilesExist.ContainsKey(Path) and FilesExist.Get(Path) then begin
            MockSFTPFile.Initialize(Path, false, 100, CreateDateTime(20260101D, 010000T));
            Result := MockSFTPFile;
            exit(true);
        end;

        exit(false);
    end;

    procedure CreateDirectory(Path: Text): Boolean
    begin
        if not IsConnectedVar then
            exit(false);

        if ExceptionTypeToReturn <> "SFTP Exception Type"::None then
            exit(false);

        if FilesExist.ContainsKey(Path) then
            exit(true);

        FilesExist.Add(Path, true);
        exit(true);
    end;
}