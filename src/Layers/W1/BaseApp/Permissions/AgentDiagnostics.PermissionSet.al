// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Security.AccessControl;

permissionset 4306 "Agent - Diagnostics"
{
    Assignable = true;
    Caption = 'Agent Diagnostics';
    IncludedPermissionSets = "D365 Agent";
    Permissions = system "Troubleshoot All Agents" = X;
}