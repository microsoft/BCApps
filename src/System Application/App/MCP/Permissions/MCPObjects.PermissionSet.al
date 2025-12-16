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

    Permissions = codeunit "MCP Config" = X,
                  codeunit "MCP Config Implementation" = X,
                  codeunit "MCP Config Missing Object" = X,
                  codeunit "MCP Config Missing Parent" = X,
                  page "MCP API Config Tool Lookup" = X,
                  page "MCP API Publisher Lookup" = X,
                  page "MCP Config Card" = X,
                  page "MCP Config List" = X,
                  page "MCP Config Tool List" = X,
                  page "MCP Config Warning List" = X,
                  page "MCP Copy Config" = X,
                  page "MCP System Tool List" = X,
                  page "MCP Tools By API Group" = X,
                  table "MCP API Publisher Group" = X,
                  table "MCP Config Warning" = X,
                  table "MCP System Tool" = X;
}