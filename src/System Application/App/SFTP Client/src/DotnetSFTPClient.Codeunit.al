// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

using System;

codeunit 9760 "Dotnet SFTP Client" implements "ISFTP Client"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        RenciSFTPClient: DotNet RenciSftpClient;
        LastOperationSuccessful: Boolean;

    procedure Disconnect()
    begin
        RenciSFTPClient.Disconnect();
    end;

    procedure IsConnected(): Boolean
    begin
        exit(RenciSFTPClient.IsConnected());
    end;

    procedure Exists(Path: Text; var ExistResult: Boolean): Boolean
    begin
        LastOperationSuccessful := InternalExists(Path, ExistResult);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalExists(Path: Text; var ExistResult: Boolean)
    begin
        ExistResult := RenciSFTPClient.Exists(Path);
    end;

    procedure Delete(Path: Text): Boolean
    begin
        LastOperationSuccessful := InternalDelete(Path);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalDelete(Path: Text)
    begin
        RenciSFTPClient.Delete(Path);
    end;

    procedure WorkingDirectory(var Result: Text): Boolean
    begin
        LastOperationSuccessful := InternalWorkingDirectory(Result);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalWorkingDirectory(var Result: Text)
    begin
        Result := RenciSFTPClient.WorkingDirectory;
    end;

    [NonDebuggable]
    procedure SftpClient(Host: Text; Port: Integer; UserName: Text; Password: SecretText): Boolean
    begin
        RenciSFTPClient := RenciSftpClient.SftpClient(Host, Port, UserName, Password.Unwrap());
        LastOperationSuccessful := InternalConnect();
        exit(LastOperationSuccessful);
    end;

    procedure SftpClient(Host: Text; Port: Integer; UserName: Text; PrivateKey: InStream): Boolean
    var
        PrivateKeyFile: DotNet RenciPrivateKeyFile;
        Arr: DotNet Array;
    begin
        PrivateKeyFile := PrivateKeyFile.PrivateKeyFile(PrivateKey);
        Arr := Arr.CreateInstance(GetDotNetType(PrivateKeyFile), 1);
        Arr.SetValue(PrivateKeyFile, 0);
        RenciSftpClient := RenciSftpClient.SftpClient(Host, Port, Username, Arr);
        LastOperationSuccessful := InternalConnect();
        exit(LastOperationSuccessful);
    end;

    [NonDebuggable]
    procedure SftpClient(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText): Boolean
    var
        PrivateKeyFile: DotNet RenciPrivateKeyFile;
        Arr: DotNet Array;
    begin
        PrivateKeyFile := PrivateKeyFile.PrivateKeyFile(PrivateKey, Passphrase.Unwrap());
        Arr := Arr.CreateInstance(GetDotNetType(PrivateKeyFile), 1);
        Arr.SetValue(PrivateKeyFile, 0);
        RenciSftpClient := RenciSftpClient.SftpClient(HostName, Port, Username, Arr);
        LastOperationSuccessful := InternalConnect();
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalConnect()
    begin
        RenciSFTPClient.Connect();
    end;

    procedure ListDirectory(Path: Text; var Result: List of [Interface "ISFTP File"]): Boolean
    var
        IEnumerable: DotNet IEnumerable;
        RenciISftpFile: DotNet "RenciISftpFile";
    begin
        LastOperationSuccessful := InternalListDirectory(Path, IEnumerable);
        if not LastOperationSuccessful then
            exit(false);
        foreach RenciISftpFile in IEnumerable do
            Result.Add(GetAlISFTPFile(RenciISftpFile));
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalListDirectory(Path: Text; var IEnumerable: DotNet IEnumerable)
    begin
        IEnumerable := RenciSFTPClient.ListDirectory(Path);
    end;

    local procedure GetAlISFTPFile(RenciISftpFile: DotNet "RenciISftpFile"): Interface "ISFTP File"
    var
        Result: Codeunit "Dotnet SFTP File";
    begin
        Result.SetFile(RenciISftpFile);
        exit(Result);
    end;

    procedure ReadAllBytes(Path: Text; Bytes: Dotnet Array): Boolean
    begin
        LastOperationSuccessful := InternalReadAllBytes(Path, Bytes);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalReadAllBytes(Path: Text; Bytes: Dotnet Array)
    begin
        Bytes := RenciSFTPClient.ReadAllBytes(Path);
    end;

    procedure WriteAllBytes(Path: Text; Bytes: Dotnet Array): Boolean
    begin
        LastOperationSuccessful := InternalWriteAllBytes(Path, Bytes);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalWriteAllBytes(Path: Text; Bytes: Dotnet Array)
    begin
        RenciSFTPClient.WriteAllBytes(Path, Bytes);
    end;

    procedure Get(Path: Text; var Result: Interface "ISFTP File"): Boolean
    var
        DotnetImplementationResult: Codeunit "Dotnet SFTP File";
    begin
        LastOperationSuccessful := InternalGetFile(Path, DotnetImplementationResult);
        if not LastOperationSuccessful then
            exit(false);
        Result := DotnetImplementationResult;
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalGetFile(Path: Text; var Result: Codeunit "Dotnet SFTP File")
    begin
        Result.SetFile(RenciSFTPClient.Get(Path));
    end;

    procedure GetOperationException(var ExceptionType: Enum "SFTP Exception Type"; var ExceptionMessage: Text)
    var
        SocketException: DotNet SocketException;
        InvalidOperationException: DotNet InvalidOperationException;
        SshConnectionException: DotNet SshConnectionException;
        SshAuthenticationException: DotNet SshAuthenticationException;
        SftpPathNotFoundException: DotNet SftpPathNotFoundException;
        OuterException: DotNet Exception;
        BaseException: Dotnet Exception;
        BaseExceptionType: DotNet Type;
    begin
        ExceptionType := ExceptionType::None;
        if LastOperationSuccessful then
            exit;
        OuterException := GetLastErrorObject();
        BaseException := OuterException.GetBaseException();
        BaseExceptionType := BaseException.GetType();
        ExceptionMessage := BaseException.Message;
        if BaseExceptionType.Equals(GetDotNetType(SocketException)) then begin
            ExceptionType := ExceptionType::"Socket Exception";
            exit;
        end;
        if BaseExceptionType.Equals(GetDotNetType(InvalidOperationException)) then begin
            ExceptionType := ExceptionType::"Invalid Operation Exception";
            exit;
        end;
        if BaseExceptionType.Equals(GetDotNetType(SshConnectionException)) then begin
            ExceptionType := ExceptionType::"SSH Connection Exception";
            exit;
        end;
        if BaseExceptionType.Equals(GetDotNetType(SshAuthenticationException)) then begin
            ExceptionType := ExceptionType::"SSH Authentication Exception";
            exit;
        end;
        if BaseExceptionType.Equals(GetDotNetType(SftpPathNotFoundException)) then begin
            ExceptionType := ExceptionType::"SFTP Path Not Found Exception";
            exit;
        end;
        ExceptionType := ExceptionType::"Generic Exception";
    end;

    procedure SetWorkingDirectory(Path: Text): Boolean
    begin
        LastOperationSuccessful := InternalSetWorkingDirectory(Path);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalSetWorkingDirectory(Path: Text)
    begin
        RenciSFTPClient.ChangeDirectory(Path);
    end;

    procedure CreateDirectory(Path: Text): Boolean
    begin
        LastOperationSuccessful := InternalCreateDirectory(Path);
        exit(LastOperationSuccessful);
    end;

    [TryFunction]
    local procedure InternalCreateDirectory(Path: Text)
    begin
        RenciSFTPClient.CreateDirectory(Path);
    end;
}