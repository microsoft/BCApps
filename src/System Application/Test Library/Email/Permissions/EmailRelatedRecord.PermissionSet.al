// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Email;

using System.Email;

permissionset 134685 "Email Related Record"
{
    Assignable = true;
    IncludedPermissionSets = "Email - Edit";

    // Include Test Tables
    Permissions =
        tabledata "Email Related Record Test" = RIMD,
        tabledata "Test Email Account" = RIMD, // Needed for the Record to get passed in Library Assert
        tabledata "Test Email Connector Setup" = RIMD;
}