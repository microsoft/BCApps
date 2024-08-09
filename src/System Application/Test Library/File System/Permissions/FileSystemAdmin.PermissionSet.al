// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.FileSystem;

using System.FileSystem;

permissionset 80200 "File System Admin"
{
    Assignable = true;
    IncludedPermissionSets = "File System - Admin";

    // Include Test Tables
    Permissions =
        tabledata "Test File Connector Setup" = RIMD,
        tabledata "Test File Account" = RIMD;
}