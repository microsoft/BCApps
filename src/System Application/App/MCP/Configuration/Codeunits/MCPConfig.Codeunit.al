// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

codeunit 8200 "MCP Config"
{
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";

    procedure CreateConfiguration(Name: Text[100]; Description: Text[250]): Guid
    begin
        exit(MCPConfigImplementation.CreateConfiguration(Name, Description));
    end;

    procedure ActivateConfiguration(ConfigId: Guid)
    begin
        MCPConfigImplementation.ActivateConfiguration(ConfigId, true);
    end;

    procedure DeactivateConfiguration(ConfigId: Guid)
    begin
        MCPConfigImplementation.ActivateConfiguration(ConfigId, false);
    end;

    procedure DeleteConfiguration(ConfigId: Guid)
    begin
        MCPConfigImplementation.DeleteConfiguration(ConfigId);
    end;

    procedure EnableDynamicTooling(ConfigId: Guid)
    begin
        MCPConfigImplementation.EnableDynamicTooling(ConfigId, true);
    end;

    procedure DisableDynamicTooling(ConfigId: Guid)
    begin
        MCPConfigImplementation.EnableDynamicTooling(ConfigId, false);
    end;

    procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer): Guid
    begin
        exit(MCPConfigImplementation.CreateAPITool(ConfigId, APIPageId));
    end;

    procedure DeleteTool(ToolSystemId: Guid)
    begin
        MCPConfigImplementation.DeleteTool(ToolSystemId);
    end;

    procedure AllowRead(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowRead(ToolSystemId, Allow);
    end;

    procedure AllowCreate(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowCreate(ToolSystemId, Allow);
    end;

    procedure AllowModify(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowModify(ToolSystemId, Allow);
    end;

    procedure AllowDelete(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowDelete(ToolSystemId, Allow);
    end;

    procedure AllowBoundActions(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowBoundActions(ToolSystemId, Allow);
    end;
}