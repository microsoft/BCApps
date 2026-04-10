// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;

permissionset 135810 "File Storage Admin"
{
    Assignable = true;
    IncludedPermissionSets = "File Storage - Admin";

    // Include Test Tables
    Permissions =
        tabledata "Test File Connector Setup" = RIMD,
        tabledata "Test File Account" = RIMD;
}