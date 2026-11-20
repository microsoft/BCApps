// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Security.AccessControl;

permissionset 130487 "PM TEST RUNNER READ"
{
    Assignable = true;
    IncludedPermissionSets = "All Objects";
    Permissions = tabledata "AL Test Suite" = R;
}
