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

    procedure LookupAPIObjects(): Boolean
    var
        TempMCPAPIObjectBuffer: Record "MCP API Object Buffer";
    begin
        exit(MCPConfigImplementation.LookupAPIObjects(TempMCPAPIObjectBuffer));
    end;

    procedure AddToolsByAPIGroup(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddToolsByAPIGroup(ConfigId);
    end;

    procedure AddStandardAPITools(ConfigId: Guid)
    begin
        MCPConfigImplementation.AddStandardAPITools(ConfigId);
    end;

    procedure LookupAPIPublisher(var APIPublisher: Text; var APIGroup: Text)
    var
        TempMCPAPIPublisherGroup: Record "MCP API Publisher Group";
    begin
        MCPConfigImplementation.GetAPIPublishers(TempMCPAPIPublisherGroup);
        MCPConfigImplementation.LookupAPIPublisher(TempMCPAPIPublisherGroup, APIPublisher, APIGroup);
    end;

    procedure LookupAPIGroup(APIPublisher: Text; var APIGroup: Text)
    var
        TempMCPAPIPublisherGroup: Record "MCP API Publisher Group";
    begin
        MCPConfigImplementation.GetAPIPublishers(TempMCPAPIPublisherGroup);
        MCPConfigImplementation.LookupAPIGroup(TempMCPAPIPublisherGroup, APIPublisher, APIGroup);
    end;

    procedure GetHighestAPIPageVersion(PageMetadata: Record "Page Metadata"): Text[30]
    begin
        exit(MCPConfigImplementation.GetHighestAPIPageVersion(PageMetadata));
    end;

    procedure GenerateConnectionString(ConfigurationName: Text[100]): Text
    begin
        exit(MCPConfigImplementation.GenerateConnectionString(ConfigurationName));
    end;

    procedure EncodeForMCPHeaderIfNonAscii(Value: Text): Text
    begin
        exit(MCPConfigImplementation.EncodeForMCPHeaderIfNonAscii(Value));
    end;
}