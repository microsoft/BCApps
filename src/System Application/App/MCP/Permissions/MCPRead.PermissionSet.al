// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

permissionset 8351 "MCP - Read"
{
    Access = Internal;
    Assignable = false;
    Caption = 'MCP - Read';

    IncludedPermissionSets = "MCP - Objects";

    Permissions = tabledata "MCP Configuration" = R,
                  tabledata "MCP Configuration Tool" = R;
}