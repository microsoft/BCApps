// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

/// <summary>
/// Provides public API for managing MCP configurations and tools, including creation, activation, deletion, and permissions.
/// </summary>
codeunit 8350 "MCP Config"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";

    /// <summary>
    /// Retrieves the SystemId (GUID) of a configuration by its name.
    /// </summary>
    /// <param name="Name">The name of the configuration.</param>
    /// <returns>The SystemId (GUID) of the configuration if found; otherwise, an empty GUID.</returns>
    procedure GetConfigurationIdByName(Name: Text[100]): Guid
    begin
        exit(MCPConfigImplementation.GetConfigurationIdByName(Name));
    end;

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
    /// <param name="Active">True to activate, false to deactivate.</param>
    procedure ActivateConfiguration(ConfigId: Guid; Active: Boolean)
    begin
        MCPConfigImplementation.ActivateConfiguration(ConfigId, Active);
    end;

    /// <summary>
    /// Allows create, update and delete tools for the specified MCP configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    /// <param name="Allow">True to allow create, update and delete tools, false to disallow.</param>
    procedure AllowCreateUpdateDeleteTools(ConfigId: Guid; Allow: Boolean)
    begin
        MCPConfigImplementation.AllowCreateUpdateDeleteTools(ConfigId, Allow);
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
    /// Copies an existing configuration to a new configuration, including its tools and permissions.
    /// </summary>
    /// <param name="SourceConfigId">The SystemId (GUID) of the configuration to copy.</param>
    /// <param name="NewName">The name of the new configuration.</param>
    /// <returns>The SystemId (GUID) of the newly created configuration.</returns>
    procedure CopyConfiguration(SourceConfigId: Guid; NewName: Text[100]; NewDescription: Text[250]): Guid
    begin
        exit(MCPConfigImplementation.CopyConfiguration(SourceConfigId, NewName, NewDescription));
    end;

    /// <summary>
    /// Enables dynamic tool mode for the specified configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    /// <param name="Enable">True to enable, false to disable.</param>
    procedure EnableDynamicToolMode(ConfigId: Guid; Enable: Boolean)
    begin
        MCPConfigImplementation.EnableDynamicToolMode(ConfigId, Enable);
    end;

    /// <summary>
    /// Enables discovery of accessible read-only objects for the specified configuration.
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    /// <param name="Enable">True to enable, false to disable.</param>
    procedure EnableDiscoverReadOnlyObjects(ConfigId: Guid; Enable: Boolean)
    begin
        MCPConfigImplementation.EnableDiscoverReadOnlyObjects(ConfigId, Enable);
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
    /// Retrieves the SystemId (GUID) of a tool by its configuration ID and API page
    /// </summary>
    /// <param name="ConfigId">The SystemId (GUID) of the configuration.</param>
    /// <param name="APIPageId">The ID of the API page.</param>
    /// <returns>The SystemId (GUID) of the tool if found; otherwise, an empty GUID.</returns>
    procedure GetAPIToolId(ConfigId: Guid; APIPageId: Integer): Guid
    begin
        exit(MCPConfigImplementation.GetAPIToolId(ConfigId, APIPageId));
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
