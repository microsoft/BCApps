// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

enum 8350 "MCP Config Warning Type" implements "MCP Config Warning"
{
    Access = Public;
    Extensible = false;

    value(0; "Missing Object")
    {
        Caption = 'Missing Object';
        Implementation = "MCP Config Warning" = "MCP Config Missing Object";
    }
    value(1; "Missing Parent Object")
    {
        Caption = 'Missing Parent Object';
        Implementation = "MCP Config Warning" = "MCP Config Missing Parent";
    }
    value(2; "Missing Read Tool")
    {
        Caption = 'Missing Read Tool';
        Implementation = "MCP Config Warning" = "MCP Config Missing Read Tool";
    }
}
