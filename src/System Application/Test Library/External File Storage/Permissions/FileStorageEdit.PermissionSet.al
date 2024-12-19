// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.ExternalFileStorage;

using System.ExternalFileStorage;
using System.Environment;

permissionset 135811 "File Storage Edit"
{
    Assignable = true;
    IncludedPermissionSets = "File Storage - Edit";

    // Include Test Tables
    Permissions =
        tabledata "Test File Connector Setup" = RIMD,
        tabledata "Test File Account" = RIMD,   // Needed for the Record to get passed in Library Assert
        tabledata "Scheduled Task" = rd;        // Needed for enqueue tests
}