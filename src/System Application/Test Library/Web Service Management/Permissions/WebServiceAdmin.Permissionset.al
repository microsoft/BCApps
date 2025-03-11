// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Integration;

using System.Integration;
using System.Environment.Configuration;

permissionset 139043 "Web Service Admin"
{
    Assignable = true;

    IncludedPermissionSets = "Web Service Management - Admin";

    Permissions = tabledata "Feature Key" = RIMD;
}