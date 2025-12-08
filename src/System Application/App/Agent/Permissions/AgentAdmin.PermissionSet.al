// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

using System.Agents;

/// <summary>
/// Provides admin access to the agent functionality. 
/// </summary>
permissionset 4305 "Agent - Admin"
{
    Assignable = true;
    Caption = 'Agent administrator';
    IncludedPermissionSets = "D365 Agent";
    Permissions =
        tabledata Agent = RIMD,
        system "Configure All Agents" = X,
        system "Create Custom Agent" = X;
}