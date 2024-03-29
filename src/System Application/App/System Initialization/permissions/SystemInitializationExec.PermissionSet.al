// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Environment.Configuration;

using System.Azure.Identity;

permissionset 150 "System Initialization - Exec"
{
    Access = Public;
    Assignable = false;

    IncludedPermissionSets = "AAD User Management - Exec";
}