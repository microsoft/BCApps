// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.TestStability;

using System.TestLibraries.Utilities;
using System.TestTools.TestRunner;

permissionset 130482 "Test Stability Exec"
{
    Assignable = true;
    IncludedPermissionSets = "Test Runner - Exec";

    Permissions = tabledata "Test Configuration" = RIMD,
                  table "Test Configuration" = X,
                  codeunit "Test Configuration Mgt" = X,
                  codeunit "Test Configuration Context" = X,
                  codeunit "Test Configuration Runner" = X,
                  codeunit "Seed Test Config. Provider" = X,
                  codeunit "WorkDate Test Config. Prov." = X,
                  codeunit "Any Configuration" = X,
                  codeunit Any = X,
                  codeunit "Library - Random" = X,
                  page "Test Configurations" = X,
                  page "Test Configuration Card" = X;
}
