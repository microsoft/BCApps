// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.SFTPClient;

permissionset 9762 "SFTP Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'SFTP Admin';

    Permissions =
        codeunit "Dotnet SFTP Client" = X,
        codeunit "Dotnet SFTP File" = X,
        codeunit "SFTP Client Implementation" = X,
        codeunit "SFTP Client" = X,
        codeunit "SFTP Operation Response" = X,
        page "SFTP Client - Debug" = X,
        page "SFTP Folder Content" = X,
        table "SFTP Folder Content" = X,
        tabledata "SFTP Folder Content" = RIMD;
}