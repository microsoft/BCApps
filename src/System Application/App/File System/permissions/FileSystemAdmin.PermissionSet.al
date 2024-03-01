// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.FileSystem;

permissionset 9450 "File System - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'File System - Admin';

    IncludedPermissionSets = "File System - Edit";

    Permissions =
        tabledata "File System Connector" = RIMD,
        tabledata "File System Connector Logo" = RIMD,
        tabledata "File Account Scenario" = RIMD,
        tabledata "File Scenario" = RIMD,
        tabledata "File Account Content" = RIMD;
}
