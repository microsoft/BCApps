// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

enum 8351 "MCP Server Feature" implements "MCP Feature Handler"
{
    Access = Internal;
    Extensible = false;

    value(0; "API Tools")
    {
        Caption = 'API Tools';
        Implementation = "MCP Feature Handler" = "MCP API Tools Feature";
    }
    value(1; "Dynamic Tool Mode")
    {
        Caption = 'Dynamic Tool Mode';
        Implementation = "MCP Feature Handler" = "MCP Dyn. Tool Mode Feature";
    }
    value(2; "AL Query Tools")
    {
        Caption = 'AL Query Tools (Preview)';
        Implementation = "MCP Feature Handler" = "MCP AL Query Tools Feature";
    }
}
