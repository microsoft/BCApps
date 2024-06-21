// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

permissionset 149034 "AI Test Toolkit - View"
{
    Access = Internal;
    Assignable = false;

    IncludedPermissionSets = "AI Test Toolkit - Read";

    Permissions = tabledata "AIT Test Suite" = IMD,
        tabledata "AIT Test Method Line" = IMD,
        tabledata "AIT Log Entry" = IMD;
}