// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Agents;

permissionset 8352 "MCP - Admin"
{
    Access = Public;
    Assignable = true;
    Caption = 'MCP - Admin';

    IncludedPermissionSets = "MCP - Read";

    Permissions = tabledata Agent = R,
                  tabledata "MCP Entra Application" = IMD,
                  tabledata "MCP Configuration" = IMD,
                  tabledata "MCP Configuration Agent" = IMD,
                  tabledata "MCP Configuration Tool" = IMD;
}