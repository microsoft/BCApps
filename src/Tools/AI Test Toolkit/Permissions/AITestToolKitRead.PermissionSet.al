// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

permissionset 149033 "AI Test Toolkit - Read"
{
    Access = Internal;

    IncludedPermissionSets = "AI Test Toolkit - Obj";

    Permissions = tabledata "AIT Test Suite" = R,
        tabledata "AIT Test Method Line" = R,
        tabledata "AIT Log Entry" = R;
}