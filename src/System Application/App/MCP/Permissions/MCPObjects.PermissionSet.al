// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

permissionset 8350 "MCP - Objects"
{
    Access = Internal;
    Assignable = false;
    Caption = 'MCP - Objects';

    Permissions = table "MCP API Publisher Group" = X,
                  table "MCP Configuration" = X,
                  table "MCP Configuration Tool" = X,
                  table "MCP Entra Application" = X;
}