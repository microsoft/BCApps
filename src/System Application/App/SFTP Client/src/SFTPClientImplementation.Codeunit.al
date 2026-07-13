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

    [NonDebuggable]
    procedure Initialize(Host: Text; Port: Integer; UserName: Text; Password: SecretText): Codeunit "SFTP Operation Response"
    begin
        InitializeSFTPInterface();
        ISFTPClient.SetSHA256Fingerprints(HostkeyFingerprintsSHA256);
        if not ISFTPClient.SftpClient(Host, Port, UserName, Password) then
            exit(ParseException());
    end;

    [NonDebuggable]
    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream): Codeunit "SFTP Operation Response"
    begin
        InitializeSFTPInterface();
        ISFTPClient.SetSHA256Fingerprints(HostkeyFingerprintsSHA256);
        if not ISFTPClient.SftpClient(HostName, Port, Username, PrivateKey) then
            exit(ParseException());
    end;

    [NonDebuggable]
    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText): Codeunit "SFTP Operation Response"
    begin
        InitializeSFTPInterface();
        ISFTPClient.SetSHA256Fingerprints(HostkeyFingerprintsSHA256);
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

    local procedure ParseException() Result: Codeunit "SFTP Operation Response"
    var
        SocketExceptionLbl: Label 'Socket connection to the SSH server or proxy server could not be established, or an error occurred while resolving the hostname.';
        InvalidOperationExceptionLbl: Label 'The client is already connected.';
        SshConnectionExceptionLbl: Label 'Client is not connected.';
        SshAuthenticationExceptionLbl: Label 'Authentication of SSH session failed.';
        SftpPathNotFoundExceptionLbl: Label 'The specified path is invalid, or its directory was not found on the remote host.';
        ServerFingerprintNotTrustedLbl: Label 'The server''s host key fingerprint %1 is not trusted.', Comment = '%1 is the SHA256 fingerprint of the server''s host key';
        GenericExceptionLbl: Label 'An unexpected error occurred during the SFTP operation.';
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
            ExceptionType::"Generic Exception": // Catch-all for any other exceptions - return a generic message to avoid leaking raw server/.NET exception details to callers
                Result.SetError(GenericExceptionLbl);
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

    [NonDebuggable]
    procedure GetFileAsStream(Path: Text; var InStream: InStream) Result: Codeunit "SFTP Operation Response"
    var
        TempBlob: Codeunit "Temp Blob";
        MemoryStream: DotNet MemoryStream;
        Arr: DotNet Array;
        FileSizeBytes: BigInteger;
        DownloadTok: Label 'Download', Locked = true;
    begin
        if not ISFTPClient.ReadAllBytes(Path, Arr) then
            exit(ParseException());
        FileSizeBytes := Arr.Length;
        LogFileSizeTelemetry(DownloadTok, FileSizeBytes, FileSizeBytes <= GetMaxFileSizeInBytes());
        if FileSizeBytes > GetMaxFileSizeInBytes() then
            exit(FileTooLargeResponse(FileSizeBytes));
        MemoryStream := MemoryStream.MemoryStream(Arr);
        CopyStream(TempBlob.CreateOutStream(), MemoryStream);
        Result.SetTempBlob(TempBlob);
        Result.GetResponseStream(InStream);
    end;

    [NonDebuggable]
    procedure PutFileStream(Path: Text; var SourceInStream: InStream) Result: Codeunit "SFTP Operation Response"
    var
        MemoryStream: DotNet MemoryStream;
        FileSizeBytes: BigInteger;
        UploadTok: Label 'Upload', Locked = true;
    begin
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, SourceInStream);
        FileSizeBytes := MemoryStream.Length;
        LogFileSizeTelemetry(UploadTok, FileSizeBytes, FileSizeBytes <= GetMaxFileSizeInBytes());
        if FileSizeBytes > GetMaxFileSizeInBytes() then
            exit(FileTooLargeResponse(FileSizeBytes));
        if not ISFTPClient.WriteAllBytes(Path, MemoryStream.ToArray()) then
            exit(ParseException());
    end;

    local procedure GetMaxFileSizeInBytes(): Integer
    begin
        // 25 MB (25 * 1024 * 1024) - current platform limitation. Telemetry is emitted for every transfer so the limit can be reassessed.
        if MaxFileSizeOverrideSet then
            exit(MaxFileSizeOverride);
        exit(26214400);
    end;

    internal procedure SetMaxFileSizeInBytes(NewMaxFileSizeInBytes: Integer)
    begin
        MaxFileSizeOverride := NewMaxFileSizeInBytes;
        MaxFileSizeOverrideSet := true;
    end;

    local procedure FileTooLargeResponse(FileSizeBytes: BigInteger) Result: Codeunit "SFTP Operation Response"
    var
        FileTooLargeErr: Label 'The file size of %1 bytes exceeds the maximum allowed size of %2 bytes.', Comment = '%1 is the actual file size in bytes, %2 is the maximum allowed size in bytes';
    begin
        Result.SetExceptionType(Enum::"SFTP Exception Type"::"File Too Large Exception");
        Result.SetError(StrSubstNo(FileTooLargeErr, FileSizeBytes, GetMaxFileSizeInBytes()));
        exit(Result);
    end;

    local procedure LogFileSizeTelemetry(Operation: Text; FileSizeBytes: BigInteger; WithinLimit: Boolean)
    var
        Dimensions: Dictionary of [Text, Text];
        TelemetryVerbosity: Verbosity;
        FileSizeTelemetryMsg: Label 'SFTP file transfer size measured.', Locked = true;
        CategoryTok: Label 'SFTP Client', Locked = true;
    begin
        Dimensions.Add('Category', CategoryTok);
        Dimensions.Add('Operation', Operation);
        Dimensions.Add('FileSizeBytes', Format(FileSizeBytes));
        Dimensions.Add('LimitBytes', Format(GetMaxFileSizeInBytes()));
        Dimensions.Add('WithinLimit', Format(WithinLimit, 0, 9));
        if WithinLimit then
            TelemetryVerbosity := Verbosity::Normal
        else
            TelemetryVerbosity := Verbosity::Warning;
        Session.LogMessage('SFTP-0001', FileSizeTelemetryMsg, TelemetryVerbosity, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, Dimensions);
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
        ISFTPClientSet: Boolean;
        MaxFileSizeOverride: Integer;
        MaxFileSizeOverrideSet: Boolean;
}