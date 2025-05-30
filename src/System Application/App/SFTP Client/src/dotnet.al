namespace System.SFTPClient;

dotnet
{
    assembly("Renci.SshNet")
    {
        Culture = 'neutral';
        PublicKeyToken = '1cee9f8bde3db106';
        type(Renci.SshNet.SftpClient; "RenciSftpClient") { }
        type(Renci.SshNet.Sftp.ISftpFile; "RenciISftpFile") { }
        type(Renci.SshNet.PrivateKeyFile; "RenciPrivateKeyFile") { }
    }
}