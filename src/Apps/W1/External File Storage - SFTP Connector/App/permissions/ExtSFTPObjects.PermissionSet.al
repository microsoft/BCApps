// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

permissionset 4622 "Ext. SFTP - Objects"
{
    Access = Public;
    Assignable = false;
    Caption = 'SFTP - Objects';
    Permissions =
        table "Ext. SFTP Account" = X,
        page "Ext. SFTP Account Wizard" = X,
        page "Ext. SFTP Account" = X;
}
