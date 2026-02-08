// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

permissionset 4621 "Ext. SFTP - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'SFTP - Edit';
    IncludedPermissionSets = "Ext. SFTP - Read";

    Permissions =
        tabledata "Ext. SFTP Account" = imd;
}
