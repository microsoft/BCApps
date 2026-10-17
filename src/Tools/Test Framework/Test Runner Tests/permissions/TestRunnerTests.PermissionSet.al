// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestRunner;

using System.TestLibraries.Security.AccessControl;
using System.TestLibraries.Utilities;

permissionset 130482 "Test Runner Tests"
{
    Assignable = true;
    IncludedPermissionSets = "Test Runner - Exec";

    Permissions = codeunit "Test Input Placeholder Tests" = X,
        codeunit "Test Input Lifecycle Tests" = X,
        codeunit "Test Input Lifecycle Events" = X,
        codeunit "Test Input Rollback Probe" = X,
        codeunit "Test Input Date Tests" = X,
        codeunit "Library Assert" = X,
        codeunit "Permissions Mock" = X;
}
