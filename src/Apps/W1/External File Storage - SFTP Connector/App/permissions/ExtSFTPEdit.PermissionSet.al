#if not CLEAN29
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.ExternalFileStorage;

#pragma warning disable AL0432, AS0105
permissionset 4621 "Ext. SFTP - Edit"
{
    Access = Public;
    Assignable = false;
    Caption = 'SFTP - Edit';
    ObsoleteReason = 'The SFTP connector has been removed because platform hardening prevents support for SFTP connections.';
    ObsoleteState = Pending;
    ObsoleteTag = '29.0';
    IncludedPermissionSets = "Ext. SFTP - Read";

    Permissions =
        tabledata "Ext. SFTP Account" = imd;
}
#pragma warning restore AL0432, AS0105
#endif
