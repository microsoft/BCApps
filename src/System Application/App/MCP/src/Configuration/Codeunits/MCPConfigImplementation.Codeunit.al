// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Environment;
#if not CLEAN28
using System.Environment.Configuration;
#endif
using System.Reflection;

codeunit 8351 "MCP Config Implementation"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        SettingConfigurationActiveLbl: Label 'Setting MCP configuration %1 Active to %2', Comment = '%1 - configuration ID, %2 - active', Locked = true;
        SettingConfigurationAllowProdChangesLbl: Label 'Setting MCP configuration %1 AllowProdChanges to %2', Comment = '%1 - configuration ID, %2 - allow production changes', Locked = true;
        DeletedConfigurationLbl: Label 'Deleted MCP configuration %1', Comment = '%1 - configuration ID', Locked = true;
        SettingConfigurationEnableDynamicToolModeLbl: Label 'Setting MCP configuration %1 EnableDynamicToolMode to %2', Comment = '%1 - configuration ID, %2 - enable dynamic tool mode', Locked = true;

    internal procedure GetConfigurationIdByName(Name: Text[100]): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        EmptyGuid: Guid;
    begin
        if MCPConfiguration.Get(Name) then
            exit(MCPConfiguration.SystemId);

        exit(EmptyGuid);
    end;

    internal procedure CreateConfiguration(Name: Text[100]; Description: Text[250]): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        MCPConfiguration.Name := Name;
        MCPConfiguration.Description := Description;
        MCPConfiguration.Insert();
        exit(MCPConfiguration.SystemId);
    end;

    internal procedure ActivateConfiguration(ConfigId: Guid; Active: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        MCPConfiguration.Active := Active;
        MCPConfiguration.Modify();
        Session.LogMessage('0000QE9', StrSubstNo(SettingConfigurationActiveLbl, ConfigId, Active), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure AllowProdChanges(ConfigId: Guid; Allow: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        MCPConfiguration.AllowProdChanges := Allow;
        MCPConfiguration.Modify();
        Session.LogMessage('0000QEA', StrSubstNo(SettingConfigurationAllowProdChangesLbl, ConfigId, Allow), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure DeleteConfiguration(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        MCPConfiguration.Delete();
        Session.LogMessage('0000QEB', StrSubstNo(DeletedConfigurationLbl, ConfigId), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure CopyConfiguration(SourceConfigId: Guid)
    var
        MCPCopyConfig: Page "MCP Copy Config";
        ConfigName: Text[100];
        ConfigDescription: Text[250];
    begin
        MCPCopyConfig.LookupMode := true;
        if MCPCopyConfig.RunModal() <> Action::LookupOK then
            exit;

        ConfigName := MCPCopyConfig.GetConfigName();
        ConfigDescription := MCPCopyConfig.GetConfigDescription();

        CopyConfiguration(SourceConfigId, ConfigName, ConfigDescription);
    end;

    internal procedure CopyConfiguration(SourceConfigId: Guid; NewName: Text[100]; NewDescription: Text[250]): Guid
    var
        SourceMCPConfiguration: Record "MCP Configuration";
        NewMCPConfiguration: Record "MCP Configuration";
    begin
        if not SourceMCPConfiguration.GetBySystemId(SourceConfigId) then
            exit;

        NewMCPConfiguration.Copy(SourceMCPConfiguration);
        NewMCPConfiguration.Name := NewName;
        NewMCPConfiguration.Description := NewDescription;
        NewMCPConfiguration.Insert();

        CopyTools(SourceMCPConfiguration, NewMCPConfiguration);

        exit(NewMCPConfiguration.SystemId);
    end;

    local procedure CopyTools(SourceConfig: Record "MCP Configuration"; NewConfig: Record "MCP Configuration")
    var
        SourceMCPConfigurationTool: Record "MCP Configuration Tool";
        NewMCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        SourceMCPConfigurationTool.SetRange(ID, SourceConfig.SystemId);
        if not SourceMCPConfigurationTool.FindSet() then
            exit;

        repeat
            NewMCPConfigurationTool.Copy(SourceMCPConfigurationTool);
            NewMCPConfigurationTool.ID := NewConfig.SystemId;
            NewMCPConfigurationTool.Insert();
        until SourceMCPConfigurationTool.Next() = 0;
    end;

    internal procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer): Guid
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        ValidateAPITool(APIPageId);
        MCPConfigurationTool.ID := ConfigId;
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Page;
        MCPConfigurationTool."Object ID" := APIPageId;
        MCPConfigurationTool."Allow Read" := true;
        MCPConfigurationTool.Insert();
        exit(MCPConfigurationTool.SystemId);
    end;

    internal procedure GetAPIToolId(ConfigId: Guid; APIPageId: Integer): Guid
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        EmptyGuid: Guid;
    begin
        if MCPConfigurationTool.Get(ConfigId, MCPConfigurationTool."Object Type"::Page, APIPageId) then
            exit(MCPConfigurationTool.SystemId);

        exit(EmptyGuid);
    end;

    internal procedure EnableDynamicToolMode(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        MCPConfiguration.EnableDynamicToolMode := Enable;
        MCPConfiguration.Modify();
        Session.LogMessage('0000QEC', StrSubstNo(SettingConfigurationEnableDynamicToolModeLbl, ConfigId, Enable), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure DeleteTool(ToolId: Guid)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        MCPConfigurationTool.Delete();
    end;

    internal procedure AllowRead(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        MCPConfigurationTool."Allow Read" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowCreate(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        if Allow then
            CheckAllowProdChanges(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Create" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowModify(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        if Allow then
            CheckAllowProdChanges(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Modify" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowDelete(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        if Allow then
            CheckAllowProdChanges(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Delete" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowBoundActions(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        if Allow then
            CheckAllowProdChanges(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Bound Actions" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure LookupAPITools(var PageId: Integer)
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(APIPublisher, '<>%1', 'microsoft');
        PageMetadata.SetFilter("AL Namespace", '<>%1', 'Microsoft.API.V1');

        if Page.RunModal(Page::"MCP API Config Tool Lookup", PageMetadata) = Action::LookupOK then
            PageId := PageMetadata.ID;
    end;

    internal procedure ValidateAPITool(PageId: Integer)
    var
        PageMetadata: Record "Page Metadata";
        PageNotFoundErr: Label 'Page not found.';
        InvalidPageTypeErr: Label 'Only API pages are supported.';
        InvalidAPIVersionErr: Label 'Only API v2.0 pages are supported.';
    begin
        if not PageMetadata.Get(PageId) then
            Error(PageNotFoundErr);

        if PageMetadata.PageType <> PageMetadata.PageType::API then
            Error(InvalidPageTypeErr);

        if PageMetadata.APIPublisher = 'microsoft' then
            Error(InvalidAPIVersionErr);
    end;

    internal procedure AddToolsByAPIGroup(ConfigId: Guid)
    var
        PageMetadata: Record "Page Metadata";
        MCPToolsByAPIGroup: Page "MCP Tools By API Group";
        APIGroup: Text;
        APIPublisher: Text;
    begin
        MCPToolsByAPIGroup.LookupMode := true;
        if MCPToolsByAPIGroup.RunModal() <> Action::LookupOK then
            exit;

        APIGroup := MCPToolsByAPIGroup.GetAPIGroup();
        APIPublisher := MCPToolsByAPIGroup.GetAPIPublisher();

        if (APIGroup = '') or (APIPublisher = '') then
            exit;

        if APIPublisher = 'microsoft' then
            exit;

        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(APIPublisher, APIPublisher);
        PageMetadata.SetFilter(APIGroup, APIGroup);
        if not PageMetadata.FindSet() then
            exit;

        repeat
            CreateAPITool(ConfigId, PageMetadata.ID);
        until PageMetadata.Next() = 0;
    end;

    internal procedure AddStandardAPITools(ConfigId: Guid)
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(APIPublisher, '=%1', '');
        PageMetadata.SetFilter(APIGroup, '=%1', '');
        PageMetadata.SetRange(APIVersion, 'v2.0');
        if not PageMetadata.FindSet() then
            exit;

        repeat
            CreateAPITool(ConfigId, PageMetadata.ID);
        until PageMetadata.Next() = 0;
    end;

    internal procedure GetObjectCaption(ToolId: Guid): Text[100]
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        AllObjWithCaption: Record AllObjWithCaption;
        ObjectType: Option "TableData","Table",,"Report",,"Codeunit","XMLport","MenuSuite","Page","Query","System","FieldNumber",,,"PageExtension","TableExtension","Enum","EnumExtension","Profile","ProfileExtension","PermissionSet","PermissionSetExtension","ReportExtension";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit('');

        if MCPConfigurationTool."Object Type" = MCPConfigurationTool."Object Type"::Page then
            ObjectType := ObjectType::Page;

        if AllObjWithCaption.Get(ObjectType, MCPConfigurationTool."Object ID") then
            exit(CopyStr(AllObjWithCaption."Object Name", 1, 100));
        exit('');
    end;

    local procedure CheckAllowProdChanges(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
        EnvironmentInformation: Codeunit "Environment Information";
        ProdChangesNotAllowedErr: Label 'Production changes are not allowed for this MCP configuration.';
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if EnvironmentInformation.IsSandbox() then
            exit;

        if not MCPConfiguration.AllowProdChanges then
            Error(ProdChangesNotAllowedErr);
    end;

#if not CLEAN28
    internal procedure IsFeatureEnabled(): Boolean
    var
        FeatureManagementFacade: Codeunit "Feature Management Facade";
        EnableMcpAccessTok: Label 'EnableMcpAccess', Locked = true;
    begin
        exit(FeatureManagementFacade.IsEnabled(EnableMcpAccessTok));
    end;
#endif

    internal procedure GetTelemetryCategory(): Text[50]
    begin
        exit('MCP');
    end;
}