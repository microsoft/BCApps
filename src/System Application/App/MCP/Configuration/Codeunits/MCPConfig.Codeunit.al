// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

/// <summary>
/// Provides public API for managing MCP configurations and tools, including creation, activation, deletion, and permissions.
/// </summary>
codeunit 8200 "MCP Config"
{
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";

    /// <summary>
    /// Creates a new MCP configuration with the specified name and description.
    /// </summary>
    /// <param name="Name">The name of the configuration.</param>
    /// <param name="Description">The description of the configuration.</param>
    /// <returns>The SystemId (GUID) of the created configuration.</returns>
    procedure CreateConfiguration(Name: Text[100]; Description: Text[250]): Guid
    begin
        exit(MCPConfigImplementation.CreateConfiguration(Name, Description));
    end;

    /// <summary>
    /// Activates the specified MCP configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration to activate.</param>
    procedure ActivateConfiguration(ConfigId: Guid)
    begin
        MCPConfigImplementation.ActivateConfiguration(ConfigId, true);
    end;

    /// <summary>
    /// Deactivates the specified MCP configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration to deactivate.</param>
    procedure DeactivateConfiguration(ConfigId: Guid)
    begin
        MCPConfigImplementation.ActivateConfiguration(ConfigId, false);
    end;

    /// <summary>
    /// Deletes the specified MCP configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration to delete.</param>
    procedure DeleteConfiguration(ConfigId: Guid)
    begin
        MCPConfigImplementation.DeleteConfiguration(ConfigId);
    end;

    /// <summary>
    /// Enables dynamic tooling for the specified configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    procedure EnableDynamicTooling(ConfigId: Guid)
    begin
        MCPConfigImplementation.EnableDynamicTooling(ConfigId, true);
    end;

    /// <summary>
    /// Disables dynamic tooling for the specified configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    procedure DisableDynamicTooling(ConfigId: Guid)
    begin
        MCPConfigImplementation.EnableDynamicTooling(ConfigId, false);
    end;

    /// <summary>
    /// Creates a new API tool for the specified configuration and API page.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    /// <param name="APIPageId">The ID of the API page.</param>
    /// <returns>The SystemId (GUID) of the created tool.</returns>
    procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer): Guid
    begin
        exit(MCPConfigImplementation.CreateAPITool(ConfigId, APIPageId));
    end;

    /// <summary>
    /// Deletes the specified tool from the configuration.
    /// </summary>
    /// <param name="ToolSystemId">The SystemId (GUID) of the tool to delete.</param>
    procedure DeleteTool(ToolSystemId: Guid)
    begin
        MCPConfigImplementation.DeleteTool(ToolSystemId);
    end;

    /// <summary>
    /// Sets the read permission for the specified tool.
    /// </summary>
    /// <param name="ToolSystemId">The SystemId (GUID) of the tool.</param>
    /// <param name="Allow">True to allow read, false to disallow.</param>
    procedure AllowRead(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowRead(ToolSystemId, Allow);
    end;

    /// <summary>
    /// Sets the create permission for the specified tool.
    /// </summary>
    /// <param name="ToolSystemId">The SystemId (GUID) of the tool.</param>
    /// <param name="Allow">True to allow create, false to disallow.</param>
    procedure AllowCreate(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowCreate(ToolSystemId, Allow);
    end;

    /// <summary>
    /// Sets the modify permission for the specified tool.
    /// </summary>
    /// <param name="ToolSystemId">The SystemId (GUID) of the tool.</param>
    /// <param name="Allow">True to allow modify, false to disallow.</param>
    procedure AllowModify(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowModify(ToolSystemId, Allow);
    end;

    /// <summary>
    /// Sets the delete permission for the specified tool.
    /// </summary>
    /// <param name="ToolSystemId">The SystemId (GUID) of the tool.</param>
    /// <param name="Allow">True to allow delete, false to disallow.</param>
    procedure AllowDelete(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowDelete(ToolSystemId, Allow);
    end;

    /// <summary>
    /// Sets the bound actions permission for the specified tool.
    /// </summary>
    /// <param name="ToolSystemId">The SystemId (GUID) of the tool.</param>
    /// <param name="Allow">True to allow bound actions, false to disallow.</param>
    procedure AllowBoundActions(ToolSystemId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowBoundActions(ToolSystemId, Allow);
    end;
}