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

    procedure LookupAPIPageTools(var PageMetadata: Record "Page Metadata"): Boolean
    begin
        exit(MCPConfigImplementation.LookupAPIPageTools(PageMetadata));
    end;

    procedure AddToolsByAPIGroup(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddToolsByAPIGroup(ConfigId);
    end;

    procedure AddStandardAPITools(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddStandardAPITools(ConfigId);
    end;

    procedure LookupAPIQueryTools(var QueryMetadata: Record "Query Metadata"): Boolean
    begin
        exit(MCPConfigImplementation.LookupAPIQueryTools(QueryMetadata));
    end;

    procedure LookupAPIPublisher(var APIPublisher: Text; var APIGroup: Text)
    var
        MCPAPIPublisherGroup: Record "MCP API Publisher Group";
    begin
        MCPConfigImplementation.GetAPIPublishers(MCPAPIPublisherGroup);
        MCPConfigImplementation.LookupAPIPublisher(MCPAPIPublisherGroup, APIPublisher, APIGroup);
    end;

    procedure LookupAPIGroup(APIPublisher: Text; var APIGroup: Text)
    var
        MCPAPIPublisherGroup: Record "MCP API Publisher Group";
    begin
        MCPConfigImplementation.GetAPIPublishers(MCPAPIPublisherGroup);
        MCPConfigImplementation.LookupAPIGroup(MCPAPIPublisherGroup, APIPublisher, APIGroup);
    end;

    procedure GetHighestAPIPageVersion(PageMetadata: Record "Page Metadata"): Text[30]
    begin
        exit(MCPConfigImplementation.GetHighestAPIPageVersion(PageMetadata));
    end;
}