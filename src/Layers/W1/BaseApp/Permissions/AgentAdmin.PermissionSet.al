// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

permissionset 4305 "Agent - Admin"
{
    Assignable = true;
    Caption = 'Agent administrator';
    IncludedPermissionSets = "D365 Agent";
    Permissions =
        system "Configure All Agents" = X,
        system "Create Custom Agent" = X;
}