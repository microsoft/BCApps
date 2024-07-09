// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

permissionset 149030 "AI Test Toolkit"
{
    Caption = 'Business Central AI Test Toolkit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "AI Test Toolkit - View";

    Permissions = tabledata "Test Input" = RIMD,
                  tabledata "Test Method Line" = RIMD;
}