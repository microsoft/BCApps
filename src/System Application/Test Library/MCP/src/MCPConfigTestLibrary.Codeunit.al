// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

using System.MCP;

codeunit 130131 "MCP Config Test Library"
{
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";

    procedure LookupAPITools(var PageId: Integer)
    begin
        MCPConfigImplementation.LookupAPITools(PageId);
    end;

    procedure AddToolsByAPIGroup(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddToolsByAPIGroup(ConfigId);
    end;

    procedure AddStandardAPITools(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddStandardAPITools(ConfigId);
    end;
}