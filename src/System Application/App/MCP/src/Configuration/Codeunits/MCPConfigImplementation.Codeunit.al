// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

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
        DefaultConfigCannotBeDeactivatedErr: Label 'The default configuration cannot be deactivated.';
        DefaultConfigCannotBeDeletedErr: Label 'The default configuration cannot be deleted.';
        DynamicToolModeCannotBeDisabledErr: Label 'Dynamic tool mode cannot be disabled for the default configuration.';
        DiscoverReadOnlyObjectsCannotBeDisabledErr: Label 'Access to all read-only objects cannot be disabled for the default configuration.';
        CreateUpdateDeleteNotAllowedErr: Label 'Create, update and delete tools are not allowed for this MCP configuration.';
        ToolsCannotBeAddedToDefaultConfigErr: Label 'Tools cannot be added to the default configuration.';
        PageNotFoundErr: Label 'Page not found.';
        InvalidPageTypeErr: Label 'Only API pages are supported.';
        InvalidAPIVersionErr: Label 'Only API v2.0 pages are supported.';
        DefaultMCPConfigurationDescriptionLbl: Label 'Default MCP configuration';
        DynamicToolModeRequiredErr: Label 'Dynamic tool mode needs to be enabled to discover read-only objects.';
        SettingConfigurationActiveLbl: Label 'Setting MCP configuration %1 Active to %2', Comment = '%1 - configuration ID, %2 - active', Locked = true;
        SettingConfigurationAllowProdChangesLbl: Label 'Setting MCP configuration %1 AllowProdChanges to %2', Comment = '%1 - configuration ID, %2 - allow production changes', Locked = true;
        DeletedConfigurationLbl: Label 'Deleted MCP configuration %1', Comment = '%1 - configuration ID', Locked = true;
        SettingConfigurationEnableDynamicToolModeLbl: Label 'Setting MCP configuration %1 EnableDynamicToolMode to %2', Comment = '%1 - configuration ID, %2 - enable dynamic tool mode', Locked = true;
        SettingConfigurationDiscoverReadOnlyObjectsLbl: Label 'Setting MCP configuration %1 DiscoverReadOnlyObjects to %2', Comment = '%1 - configuration ID, %2 - allow read-only API discovery', Locked = true;

    #region Configurations
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

        if not Active and IsDefaultConfiguration(MCPConfiguration) then
            Error(DefaultConfigCannotBeDeactivatedErr);

        MCPConfiguration.Active := Active;
        MCPConfiguration.Modify();
        Session.LogMessage('0000QE9', StrSubstNo(SettingConfigurationActiveLbl, ConfigId, Active), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure AllowCreateUpdateDeleteTools(ConfigId: Guid; Allow: Boolean)
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

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(DefaultConfigCannotBeDeletedErr);

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

    internal procedure EnableDynamicToolMode(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if not Enable and IsDefaultConfiguration(MCPConfiguration) then
            Error(DynamicToolModeCannotBeDisabledErr);

        MCPConfiguration.EnableDynamicToolMode := Enable;
        if not Enable then
            MCPConfiguration.DiscoverReadOnlyObjects := false;
        MCPConfiguration.Modify();
        Session.LogMessage('0000QEC', StrSubstNo(SettingConfigurationEnableDynamicToolModeLbl, ConfigId, Enable), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    internal procedure EnableDiscoverReadOnlyObjects(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if not Enable and IsDefaultConfiguration(MCPConfiguration) then
            Error(DiscoverReadOnlyObjectsCannotBeDisabledErr);

        if Enable and not MCPConfiguration.EnableDynamicToolMode then
            Error(DynamicToolModeRequiredErr);

        MCPConfiguration.DiscoverReadOnlyObjects := Enable;
        MCPConfiguration.Modify();
        Session.LogMessage('0000QED', StrSubstNo(SettingConfigurationDiscoverReadOnlyObjectsLbl, ConfigId, Enable), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', GetTelemetryCategory());
    end;

    local procedure CheckAllowCreateUpdateDeleteTools(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if not MCPConfiguration.AllowProdChanges then
            Error(CreateUpdateDeleteNotAllowedErr);
    end;

    internal procedure CreateDefaultConfiguration()
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not IsNullGuid(GetConfigurationIdByName('')) then
            exit;

        MCPConfiguration.Name := '';
        MCPConfiguration.Description := DefaultMCPConfigurationDescriptionLbl;
        MCPConfiguration.Active := true;
        MCPConfiguration.EnableDynamicToolMode := true;
        MCPConfiguration.DiscoverReadOnlyObjects := true;
        MCPConfiguration.AllowProdChanges := true;
        MCPConfiguration.Insert();
    end;

    internal procedure IsDefaultConfiguration(MCPConfiguration: Record "MCP Configuration"): Boolean
    begin
        exit(MCPConfiguration.Name = '');
    end;
    #endregion

    #region Tools
    internal procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(ToolsCannotBeAddedToDefaultConfigErr);

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
            CheckAllowCreateUpdateDeleteTools(MCPConfigurationTool.ID);

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
            CheckAllowCreateUpdateDeleteTools(MCPConfigurationTool.ID);

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
            CheckAllowCreateUpdateDeleteTools(MCPConfigurationTool.ID);

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
            CheckAllowCreateUpdateDeleteTools(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Bound Actions" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure LookupAPITools(var PageMetadata: Record "Page Metadata"): Boolean
    var
        MCPAPIConfigToolLookup: Page "MCP API Config Tool Lookup";
    begin
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(APIPublisher, '<>%1', 'microsoft');
        PageMetadata.SetFilter("AL Namespace", '<>%1', 'Microsoft.API.V1');

        MCPAPIConfigToolLookup.LookupMode := true;
        MCPAPIConfigToolLookup.SetTableView(PageMetadata);
        if MCPAPIConfigToolLookup.RunModal() <> Action::LookupOK then
            exit(false);

        MCPAPIConfigToolLookup.SetSelectionFilter(PageMetadata);
        exit(true);
    end;

    internal procedure GetAPIPublishers(var MCPAPIPublisherGroup: Record "MCP API Publisher Group")
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetLoadFields(PageType, APIPublisher, APIGroup);
        PageMetadata.SetRange(PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(APIPublisher, '<>%1&<>%2', '', 'microsoft');
        if not PageMetadata.FindSet() then
            exit;

        repeat
            if MCPAPIPublisherGroup.Get(PageMetadata.APIPublisher, PageMetadata.APIGroup) then
                continue;
            MCPAPIPublisherGroup."API Publisher" := PageMetadata.APIPublisher;
            MCPAPIPublisherGroup."API Group" := PageMetadata.APIGroup;
            MCPAPIPublisherGroup.Insert();
        until PageMetadata.Next() = 0;
    end;

    internal procedure LookupAPIPublisher(var MCPAPIPublisherGroup: Record "MCP API Publisher Group"; var APIPublisher: Text; var APIGroup: Text)
    begin
        if Page.RunModal(Page::"MCP API Publisher Lookup", MCPAPIPublisherGroup) = Action::LookupOK then begin
            APIPublisher := MCPAPIPublisherGroup."API Publisher";
            APIGroup := MCPAPIPublisherGroup."API Group";
        end;
    end;

    internal procedure LookupAPIGroup(var MCPAPIPublisherGroup: Record "MCP API Publisher Group"; APIPublisher: Text; var APIGroup: Text)
    begin
        MCPAPIPublisherGroup.SetRange("API Publisher", APIPublisher);
        if MCPAPIPublisherGroup.IsEmpty() then
            exit;

        if Page.RunModal(Page::"MCP API Publisher Lookup", MCPAPIPublisherGroup) = Action::LookupOK then
            APIGroup := MCPAPIPublisherGroup."API Group";
    end;

    internal procedure ValidateAPITool(PageId: Integer)
    var
        PageMetadata: Record "Page Metadata";
    begin
        if not PageMetadata.Get(PageId) then
            Error(PageNotFoundErr);

        if PageMetadata.PageType <> PageMetadata.PageType::API then
            Error(InvalidPageTypeErr);

        if PageMetadata.APIPublisher = 'microsoft' then
            Error(InvalidAPIVersionErr);

        if PageMetadata."AL Namespace" = 'Microsoft.API.V1' then
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
    #endregion

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
