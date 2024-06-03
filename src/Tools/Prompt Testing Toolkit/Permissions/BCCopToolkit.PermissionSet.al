// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;
using System.TestTools.TestRunner;

permissionset 149030 "BC Cop. Toolkit"
{
    Caption = 'Businss Central Copilot Test Toolkit';
    Access = Public;
    Assignable = true;

    IncludedPermissionSets = "BC Copilot Test Toolkit - Obj";

    Permissions = tabledata "BCCT Header" = RIMD,
        tabledata "BCCT Line" = RIMD,
        tabledata "BCCT Log Entry" = RIMD,
        tabledata "BCCT Dataset" = RIMD,
        tabledata "BCCT Dataset Line" = RIMD,
        tabledata "Test Input" = RIMD;
}