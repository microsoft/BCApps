// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.MCP;

using System.MCP;
using System.Reflection;

codeunit 130131 "MCP Config Test Library"
{
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";

    procedure LookupAPITools(var PageMetadata: Record "Page Metadata"): Boolean
    begin
        exit(MCPConfigImplementation.LookupAPITools(PageMetadata));
    end;

    procedure AddToolsByAPIGroup(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddToolsByAPIGroup(ConfigId);
    end;

    procedure AddStandardAPITools(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddStandardAPITools(ConfigId);
    end;

    procedure LookupAPIPublishers(var APIPublisher: Text)
    begin
        MCPConfigImplementation.LookupAPIPublishers(APIPublisher);
    end;

    procedure LookupAPIGroups(APIPublisher: Text; var APIGroup: Text)
    begin
        MCPConfigImplementation.LookupAPIGroups(APIPublisher, APIGroup);
    end;
}