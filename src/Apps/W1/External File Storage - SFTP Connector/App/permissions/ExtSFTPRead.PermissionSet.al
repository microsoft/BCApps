// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

permissionset 4623 "Ext. SFTP - Read"
{
    Access = Public;
    Assignable = false;
    Caption = 'SFTP - Read';
    IncludedPermissionSets = "Ext. SFTP - Objects";

    Permissions =
        tabledata "Ext. SFTP Account" = r;
}
