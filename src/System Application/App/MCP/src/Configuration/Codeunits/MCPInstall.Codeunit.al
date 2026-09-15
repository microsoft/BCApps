// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8352 "MCP Install"
{
    Subtype = Install;
    InherentEntitlements = X;
    InherentPermissions = X;

    trigger OnInstallAppPerDatabase()
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        MCPCopilotCapReg: Codeunit "MCP Copilot Cap. Reg.";
    begin
        MCPConfigImplementation.CreateDefaultConfiguration();
        MCPConfigImplementation.CreateVSCodeEntraApplication();
        MCPCopilotCapReg.RegisterMCPCapability();
    end;
}