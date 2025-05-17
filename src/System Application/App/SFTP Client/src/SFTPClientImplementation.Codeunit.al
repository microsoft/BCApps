codeunit 50101 "SFTP Client Implementation"
{
    Access = Internal;

    [NonDebuggable]
    procedure Initialize(Host: Text; Port: Integer; UserName: Text; Password: SecretText)
    begin
        SFTPClient := SFTPClient.SftpClient(Host, Port, UserName, Password.Unwrap());
        TryConnecting();
    end;

    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream)
    var
        PrivateKeyFile: DotNet RenciPrivateKeyFile;
        Arr: DotNet Array;
    begin
        PrivateKeyFile := PrivateKeyFile.PrivateKeyFile(PrivateKey);
        Arr := Arr.CreateInstance(GetDotNetType(PrivateKeyFile), 1);
        Arr.SetValue(PrivateKeyFile, 0);
        SFTPClient := SFTPClient.SftpClient(HostName, Port, UserName, Arr);
        TryConnecting();
    end;

    [NonDebuggable]
    procedure Initialize(HostName: Text; Port: Integer; Username: Text; PrivateKey: InStream; Passphrase: SecretText)
    var
        PrivateKeyFile: DotNet RenciPrivateKeyFile;
        Arr: DotNet Array;
    begin
        PrivateKeyFile := PrivateKeyFile.PrivateKeyFile(PrivateKey, Passphrase.Unwrap());
        Arr := Arr.CreateInstance(GetDotNetType(PrivateKeyFile), 1);
        Arr.SetValue(PrivateKeyFile, 0);
        SFTPClient := SFTPClient.SftpClient(HostName, Port, UserName, Arr);
        TryConnecting();
    end;

    local procedure TryConnecting()
    begin
        if ConnectClient() then
            exit;
        //TODO: Handle exceptions (For example SocketException)
    end;

    [TryFunction]
    local procedure ConnectClient()
    begin
        SFTPClient.Connect();
    end;

    procedure Disconnect()
    begin
        SFTPClient.Disconnect();
    end;

    procedure ListFiles(Path: Text; var FileList: List of [Text]): Codeunit "SFTP Operation Response"
    var
        IEnumerable: DotNet IEnumerable;
        ISftpFile: DotNet RenciISftpFile;
    begin
        IEnumerable := SFTPClient.ListDirectory(Path);
        foreach ISftpFile in IEnumerable do begin
            FileList.Add(iSftpFile.Name);
        end;
    end;

    procedure GetFileAsStream(Path: Text; var InStream: InStream) Result: Codeunit "SFTP Operation Response"
    var
        TempBlob: Codeunit "Temp Blob";
        MemoryStream: Dotnet MemoryStream;
        Arr: Dotnet Array;
    begin
        Arr := SFTPClient.ReadAllBytes(Path);
        MemoryStream := MemoryStream.MemoryStream(Arr);
        CopyStream(TempBlob.CreateOutStream(), MemoryStream);
        Result.SetTempBlob(TempBlob);
        InStream := TempBlob.CreateInStream();
    end;

    procedure PutFileStream(Path: Text; var SourceInStream: InStream): Codeunit "SFTP Operation Response"
    var
        MemoryStream: Dotnet MemoryStream;
    begin
        MemoryStream := MemoryStream.MemoryStream();
        CopyStream(MemoryStream, SourceInStream);
        SFTPClient.WriteAllBytes(Path, MemoryStream.ToArray());
    end;

    procedure DeleteFile(Path: Text): Codeunit "SFTP Operation Response"
    begin
        SFTPClient.Delete(Path);
    end;

    procedure FileExists(Path: Text): Boolean
    begin
        exit(SFTPClient.Exists(Path));
    end;

    procedure MoveFile(SourcePath: Text; DestinationPath: Text): Codeunit "SFTP Operation Response"
    var
        Isftpfile: DotNet RenciISftpFile;
    begin
        Isftpfile := SFTPClient.Get(SourcePath);
        Isftpfile.MoveTo(DestinationPath);
    end;

    var
        SFTPClient: DotNet RenciSftpClient;
}