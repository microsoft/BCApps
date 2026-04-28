// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.SFTPClient;

permissionset 9762 "SFTP - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'SFTP - Admin';
    ObsoleteReason = 'The SFTP module is deprecated because platform hardening will prevent support for SFTP connections.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';

    Permissions =
        page "SFTP Folder Content" = X;
}
