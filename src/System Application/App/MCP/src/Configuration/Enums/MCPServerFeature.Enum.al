// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

enum 8351 "MCP Server Feature" implements "MCP Server Features"
{
    Access = Internal;
    Extensible = false;

    value(0; "API Tools")
    {
        Caption = 'API Tools';
        Implementation = "MCP Server Features" = "MCP API Tools Feature";
    }
    value(1; "Dynamic Tool Mode")
    {
        Caption = 'Dynamic Tool Mode';
        Implementation = "MCP Server Features" = "MCP Dyn. Tool Mode Feature";
    }
    value(2; "Data Query Tools")
    {
        Caption = 'Data Query Tools (Preview)';
        Implementation = "MCP Server Features" = "MCP Data Query Tools Feature";
    }
}
