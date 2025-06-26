// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

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
        type(Renci.SshNet.Common.SshConnectionException; "SshConnectionException") { }
        type(Renci.SshNet.Common.SshAuthenticationException; "SshAuthenticationException") { }
        type(Renci.SshNet.Common.SftpPathNotFoundException; "SftpPathNotFoundException") { }
    }
    assembly("netstandard")
    {
        type(System.Net.Sockets.SocketException; "SocketException") { }
        type(System.InvalidOperationException; "InvalidOperationException") { }
    }
}