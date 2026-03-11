// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.SFTPClient;

enum 9760 "SFTP Exception Type"
{
    Extensible = false;
    Access = Public;

    value(0; None)
    {
        Caption = 'No Exception';
    }
    value(1; "Generic Exception")
    {
        Caption = 'Generic Exception';
    }
    value(2; "Socket Exception")
    {
        Caption = 'Socket Exception';
    }
    value(3; "Invalid Operation Exception")
    {
        Caption = 'Invalid Operation Exception';
    }
    value(4; "SSH Connection Exception")
    {
        Caption = 'SSH Connection Exception';
    }
    value(5; "SSH Authentication Exception")
    {
        Caption = 'SSH Authentication Exception';
    }
    value(6; "SFTP Path Not Found Exception")
    {
        Caption = 'SFTP Path Not Found Exception';
    }
    value(7; "Untrusted Server Exception")
    {
        Caption = 'Untrusted Server Exception';
    }
}