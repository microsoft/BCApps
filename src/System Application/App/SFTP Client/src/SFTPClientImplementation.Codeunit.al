// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

using System;
using System.Utilities;

codeunit 9763 "SFTP Client Implementation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    procedure Initialize(Host: Text; Port: Integer; UserName: Text; Password: SecretText): Codeunit "SFTP Operation Response"
    begin
        InitializeSFTPInterface();
        ISFTPClient.SetSHA256Fingerprints(HostkeyFingerprintsSHA256);
        ISFTPClient.SetMD5Fingerprints(HostkeyFingerprintsMD5);
        if not ISFTPClient.SftpClient(Host, Port, UserName, Password) then
            exit(ParseException());
    end;

    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream): Codeunit "SFTP Operation Response"
    begin
        InitializeSFTPInterface();
        ISFTPClient.SetSHA256Fingerprints(HostkeyFingerprintsSHA256);
        ISFTPClient.SetMD5Fingerprints(HostkeyFingerprintsMD5);
        if not ISFTPClient.SftpClient(HostName, Port, Username, PrivateKey) then
            exit(ParseException());
    end;

    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText): Codeunit "SFTP Operation Response"
    begin
        InitializeSFTPInterface();
        ISFTPClient.SetSHA256Fingerprints(HostkeyFingerprintsSHA256);
        ISFTPClient.SetMD5Fingerprints(HostkeyFingerprintsMD5);
        if not ISFTPClient.SftpClient(HostName, Port, Username, PrivateKey, Passphrase) then
            exit(ParseException());
    end;

    local procedure InitializeSFTPInterface()
    var
        DotnetSFTPClient: Codeunit "Dotnet SFTP Client";
    begin
        if ISFTPClientSet then
            exit;
        ISFTPClient := DotnetSFTPClient;
    end;

    procedure AddFingerPrintSHA256(Fingerprint: Text)
    begin
        HostkeyFingerprintsSHA256.Add(Fingerprint);
    end;

    procedure AddFingerPrintMD5(Fingerprint: Text)
    begin
        HostkeyFingerprintsMD5.Add(Fingerprint);
    end;

    local procedure ParseException() Result: Codeunit "SFTP Operation Response"
    var
        SocketExceptionLbl: Label 'Socket connection to the SSH server or proxy server could not be established, or an error occurred while resolving the hostname.';
        InvalidOperationExceptionLbl: Label 'The client is already connected.';
        SshConnectionExceptionLbl: Label 'Client is not connected.';
        SshAuthenticationExceptionLbl: Label 'Authentication of SSH session failed.';
        SftpPathNotFoundExceptionLbl: Label 'The specified path is invalid, or its directory was not found on the remote host.';
        ServerFingerprintNotTrustedLbl: Label 'The server''s host key fingerprint %1 is not trusted.', Comment = '%1 is the SHA256 fingerprint of the server''s host key';
        ExceptionType: Enum "SFTP Exception Type";
        ExceptionMessage: Text;
        ServerFingerprintSHA256: Text;
    begin
        ISFTPClient.GetOperationException(ExceptionType, ExceptionMessage, ServerFingerprintSHA256);
        Result.SetExceptionType(ExceptionType);
        case ExceptionType of
            ExceptionType::"Socket Exception":
                Result.SetError(SocketExceptionLbl);
            ExceptionType::"Invalid Operation Exception":
                Result.SetError(InvalidOperationExceptionLbl);
            ExceptionType::"SSH Connection Exception":
                Result.SetError(SshConnectionExceptionLbl);
            ExceptionType::"SSH Authentication Exception":
                Result.SetError(SshAuthenticationExceptionLbl);
            ExceptionType::"SFTP Path Not Found Exception":
                Result.SetError(SftpPathNotFoundExceptionLbl);
            ExceptionType::"Untrusted Server Exception":
                Result.SetError(StrSubstNo(ServerFingerprintNotTrustedLbl, ServerFingerprintSHA256));
            ExceptionType::"Generic Exception": // Catch-all for any other exceptions
                Result.SetError(ExceptionMessage);
        end;
        exit(Result);
    end;

    procedure Disconnect()
    begin
        if not ISFTPClient.IsConnected() then
            exit;
        ISFTPClient.Disconnect();
    end;

    procedure ListFiles(Path: Text; var FileList: List of [Interface "ISFTP File"]): Codeunit "SFTP Operation Response"
    begin
        if not ISFTPClient.ListDirectory(Path, FileList) then
            exit(ParseException());
    end;

    procedure ListFiles(Path: Text; var FileList: Record "SFTP Folder Content"): Codeunit "SFTP Operation Response"
    var
        Files: List of [Interface "ISFTP File"];
        ISftpFile: Interface "ISFTP File";
        Index: Integer;
    begin
        if not ISFTPClient.ListDirectory(Path, Files) then
            exit(ParseException());
        FileList.DeleteAll();
        Index := 1;
        foreach ISftpFile in Files do begin
            FileList.Init();
            FileList."Entry No." := Index;
            FileList.Name := CopyStr(ISftpFile.Name(), 1, MaxStrLen(FileList.Name));
            FileList."Full Name" := CopyStr(ISftpFile.FullName(), 1, MaxStrLen(FileList."Full Name"));
            FileList."Is Directory" := ISftpFile.IsDirectory();
            FileList.Length := ISftpFile.Length();
            FileList."Last Write Time" := ISftpFile.LastWriteTime();
            FileList.Insert();
            Index += 1;
        end;
    end;

    procedure GetFileAsStream(Path: Text; var InStream: InStream) Result: Codeunit "SFTP Operation Response"
    var
        TempBlob: Codeunit "Temp Blob";
        MemoryStream: DotNet MemoryStream;
        Arr: DotNet Array;
    begin
        if not ISFTPClient.ReadAllBytes(Path, Arr) then
            exit(ParseException());
        MemoryStream := MemoryStream.MemoryStream(Arr);
        CopyStream(TempBlob.CreateOutStream(), MemoryStream);
        Result.SetTempBlob(TempBlob);
        Result.GetResponseStream(InStream);
    end;

    procedure PutFileStream(Path: Text; var SourceInStream: InStream): Codeunit "SFTP Operation Response"
    var
        MemoryStream: DotNet MemoryStream;
    begin
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, SourceInStream);
        if not ISFTPClient.WriteAllBytes(Path, MemoryStream.ToArray()) then
            exit(ParseException());
    end;

    procedure DeleteFile(Path: Text): Codeunit "SFTP Operation Response"
    begin
        if not ISFTPClient.Delete(Path) then
            exit(ParseException());
    end;

    procedure FileExists(Path: Text; var Result: Boolean): Codeunit "SFTP Operation Response"
    begin
        if not ISFTPClient.Exists(Path, Result) then
            exit(ParseException());
    end;

    procedure MoveFile(SourcePath: Text; DestinationPath: Text): Codeunit "SFTP Operation Response"
    var
        ISFTPFile: Interface "ISFTP File";
    begin
        if not ISFTPClient.Get(SourcePath, ISFTPFile) then
            exit(ParseException());
        if not ISFTPFile.MoveTo(DestinationPath) then
            exit(ParseException());
    end;

    procedure GetWorkingDirectory(var Result: Text): Codeunit "SFTP Operation Response"
    begin
        if not ISFTPClient.WorkingDirectory(Result) then
            exit(ParseException());
    end;

    procedure SetWorkingDirectory(Path: Text): Codeunit "SFTP Operation Response"
    begin
        if not ISFTPClient.SetWorkingDirectory(Path) then
            exit(ParseException());
    end;

    procedure CreateDirectory(Path: Text): Codeunit "SFTP Operation Response"
    begin
        if not ISFTPClient.CreateDirectory(Path) then
            exit(ParseException());
    end;

    procedure IsConnected(): Boolean
    begin
        exit(ISFTPClient.IsConnected());
    end;

    procedure SetISFTPClient(NewISFTPClient: Interface "ISFTP Client")
    begin
        ISFTPClient := NewISFTPClient;
        ISFTPClientSet := true;
    end;

    var
        ISFTPClient: Interface "ISFTP Client";
        HostkeyFingerprintsSHA256: List of [Text];
        HostkeyFingerprintsMD5: List of [Text];
        ISFTPClientSet: Boolean;
}