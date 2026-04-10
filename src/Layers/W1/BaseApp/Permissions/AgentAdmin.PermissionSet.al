// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Agents;

permissionset 4305 "Agent - Admin"
{
    Assignable = true;
    Caption = 'Agent administrator';
    IncludedPermissionSets = "D365 Agent";
    Permissions =
        page "Agent Creation Control" = X,
        page "Agent Creation Control Part" = X,
        tabledata "Access Control" = RIMD,
        tabledata Agent = RIMD,
        tabledata "Agent Creation Control" = RIMD,
        system "Configure All Agents" = X,
        system "Create Custom Agent" = X;
}