// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Azure.Identity;
using System.Environment;
#if not CLEAN28
using System.Environment.Configuration;
#endif
using System.Reflection;
using System.Utilities;

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
        MCPConfigurationCreatedLbl: Label 'MCP Configuration created', Locked = true;
        MCPConfigurationModifiedLbl: Label 'MCP Configuration modified', Locked = true;
        MCPConfigurationDeletedLbl: Label 'MCP Configuration deleted', Locked = true;
        MCPConfigurationAuditCreatedLbl: Label 'MCP Configuration %1 created by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        MCPConfigurationAuditModifiedLbl: Label 'MCP Configuration %1 modified by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        MCPConfigurationAuditDeletedLbl: Label 'MCP Configuration %1 deleted by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        ConnectionStringLbl: Label '%1 Connection String', Comment = '%1 - configuration name';
        MCPUrlProdLbl: Label 'https://mcp.businesscentral.dynamics.com', Locked = true;
        MCPUrlTIELbl: Label 'https://mcp.businesscentral.dynamics-tie.com', Locked = true;
        MCPPrefixProdLbl: Label 'businesscentral', Locked = true;
        MCPPrefixTIELbl: Label 'businesscentral-tie', Locked = true;
        VSCodeAppNameLbl: Label 'VS Code', Locked = true;
        VSCodeAppDescriptionLbl: Label 'Visual Studio Code';
        VSCodeClientIdLbl: Label 'aebc6443-996d-45c2-90f0-388ff96faa56', Locked = true;

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
        LogConfigurationCreated(MCPConfiguration);
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

    end;

    internal procedure AllowCreateUpdateDeleteTools(ConfigId: Guid; Allow: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
        xMCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        xMCPConfiguration := MCPConfiguration;

        if not Allow then
            DisableCreateUpdateDeleteToolsInConfig(ConfigId);

        MCPConfiguration.AllowProdChanges := Allow;
        MCPConfiguration.Modify();
        LogConfigurationModified(MCPConfiguration, xMCPConfiguration);
    end;

    internal procedure DisableCreateUpdateDeleteToolsInConfig(ConfigId: Guid)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        MCPConfigurationTool.SetRange(ID, ConfigId);
        if MCPConfigurationTool.IsEmpty() then
            exit;

        MCPConfigurationTool.ModifyAll("Allow Create", false);
        MCPConfigurationTool.ModifyAll("Allow Modify", false);
        MCPConfigurationTool.ModifyAll("Allow Delete", false);
        MCPConfigurationTool.ModifyAll("Allow Bound Actions", false);
    end;

    internal procedure DeleteConfiguration(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(DefaultConfigCannotBeDeletedErr);

        LogConfigurationDeleted(MCPConfiguration);
        MCPConfiguration.Delete();
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

        LogConfigurationCreated(NewMCPConfiguration);
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
        xMCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        xMCPConfiguration := MCPConfiguration;

        if not Enable and IsDefaultConfiguration(MCPConfiguration) then
            Error(DynamicToolModeCannotBeDisabledErr);

        MCPConfiguration.EnableDynamicToolMode := Enable;
        if not Enable then
            MCPConfiguration.DiscoverReadOnlyObjects := false;
        MCPConfiguration.Modify();
        LogConfigurationModified(MCPConfiguration, xMCPConfiguration);
    end;

    internal procedure EnableDiscoverReadOnlyObjects(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
        xMCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        xMCPConfiguration := MCPConfiguration;

        if not Enable and IsDefaultConfiguration(MCPConfiguration) then
            Error(DiscoverReadOnlyObjectsCannotBeDisabledErr);

        if Enable and not MCPConfiguration.EnableDynamicToolMode then
            Error(DynamicToolModeRequiredErr);

        MCPConfiguration.DiscoverReadOnlyObjects := Enable;
        MCPConfiguration.Modify();
        LogConfigurationModified(MCPConfiguration, xMCPConfiguration);
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

    internal procedure CreateVSCodeEntraApplication()
    var
        MCPEntraApplication: Record "MCP Entra Application";
    begin
        if MCPEntraApplication.Get(VSCodeAppNameLbl) then
            exit;

        MCPEntraApplication.Name := VSCodeAppNameLbl;
        MCPEntraApplication.Description := VSCodeAppDescriptionLbl;
        Evaluate(MCPEntraApplication."Client ID", VSCodeClientIdLbl);
        MCPEntraApplication.Insert();
    end;

    internal procedure IsDefaultConfiguration(MCPConfiguration: Record "MCP Configuration"): Boolean
    begin
        exit(MCPConfiguration.Name = '');
    end;
    #endregion

    #region Tools
    internal procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer; ValidateAPIPublisher: Boolean): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(ToolsCannotBeAddedToDefaultConfigErr);

        ValidateAPITool(APIPageId, ValidateAPIPublisher);

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

    internal procedure ValidateAPITool(PageId: Integer; ValidateAPIPublisher: Boolean)
    var
        PageMetadata: Record "Page Metadata";
    begin
        if not PageMetadata.Get(PageId) then
            Error(PageNotFoundErr);

        if PageMetadata.PageType <> PageMetadata.PageType::API then
            Error(InvalidPageTypeErr);

        if not ValidateAPIPublisher then
            exit;

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
            if CheckAPIToolExists(ConfigId, PageMetadata.ID) then
                continue;
            CreateAPITool(ConfigId, PageMetadata.ID, false);
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
            if CheckAPIToolExists(ConfigId, PageMetadata.ID) then
                continue;
            CreateAPITool(ConfigId, PageMetadata.ID, false);
        until PageMetadata.Next() = 0;
    end;

    local procedure CheckAPIToolExists(ConfigId: Guid; PageId: Integer): Boolean
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        MCPConfigurationTool.SetRange(ID, ConfigId);
        MCPConfigurationTool.SetRange("Object Type", MCPConfigurationTool."Object Type"::Page);
        MCPConfigurationTool.SetRange("Object ID", PageId);
        exit(not MCPConfigurationTool.IsEmpty());
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

    #region Connection String
    internal procedure ShowConnectionString(ConfigurationName: Text[100])
    var
        MCPConnectionString: Page "MCP Connection String";
        ConnectionString: Text;
    begin
        ConnectionString := GenerateConnectionString(ConfigurationName);
        MCPConnectionString.SetConnectionString(ConnectionString, ConfigurationName);
        MCPConnectionString.Caption(StrSubstNo(ConnectionStringLbl, ConfigurationName));
        MCPConnectionString.RunModal();
    end;

    internal procedure GenerateConnectionString(ConfigurationName: Text[100]): Text
    var
        AzureADTenant: Codeunit "Azure AD Tenant";
        EnvironmentInformation: Codeunit "Environment Information";
        MCPUrl: Text;
        MCPPrefix: Text;
        TenantId: Text;
        EnvironmentName: Text;
        Company: Text;
    begin
        GetMCPUrlAndPrefix(MCPUrl, MCPPrefix);
        TenantId := AzureADTenant.GetAadTenantId();
        EnvironmentName := EnvironmentInformation.GetEnvironmentName();
        Company := CompanyName();

        exit(BuildConnectionStringJson(MCPPrefix, MCPUrl, TenantId, EnvironmentName, Company, ConfigurationName));
    end;

    local procedure GetMCPUrlAndPrefix(var MCPUrl: Text; var MCPPrefix: Text)
    begin
        if IsTIEEnvironment() then begin
            MCPUrl := MCPUrlTIELbl;
            MCPPrefix := MCPPrefixTIELbl;
        end else begin
            MCPUrl := MCPUrlProdLbl;
            MCPPrefix := MCPPrefixProdLbl;
        end;
    end;

    local procedure IsTIEEnvironment(): Boolean
    var
        Uri: Codeunit Uri;
    begin
        exit(Uri.AreURIsHaveSameHost(GetUrl(ClientType::Web), 'https://businesscentral.dynamics-tie.com'));
    end;

    local procedure BuildConnectionStringJson(MCPPrefix: Text; MCPUrl: Text; TenantId: Text; EnvironmentName: Text; Company: Text; ConfigurationName: Text[100]): Text
    var
        JsonBuilder: TextBuilder;
    begin
        JsonBuilder.AppendLine('{');
        JsonBuilder.AppendLine('  "' + MCPPrefix + '": {');
        JsonBuilder.AppendLine('    "url": "' + MCPUrl + '",');
        JsonBuilder.AppendLine('    "type": "http",');
        JsonBuilder.AppendLine('    "headers": {');
        JsonBuilder.AppendLine('      "TenantId": "' + TenantId + '",');
        JsonBuilder.AppendLine('      "EnvironmentName": "' + EnvironmentName + '",');
        JsonBuilder.AppendLine('      "Company": "' + Company + '",');
        JsonBuilder.AppendLine('      "ConfigurationName": "' + ConfigurationName + '"');
        JsonBuilder.AppendLine('    }');
        JsonBuilder.AppendLine('  }');
        JsonBuilder.AppendLine('}');
        exit(JsonBuilder.ToText());
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

    local procedure GetDimensions(MCPConfiguration: Record "MCP Configuration") Dimensions: Dictionary of [Text, Text]
    begin
        Dimensions.Add('MCPConfigurationName', MCPConfiguration.Name);
        Dimensions.Add('Active', Format(MCPConfiguration.Active));
        Dimensions.Add('UnblockEditTools', Format(MCPConfiguration.AllowProdChanges));
        Dimensions.Add('DynamicToolMode', Format(MCPConfiguration.EnableDynamicToolMode));
        Dimensions.Add('DiscoverReadOnlyObjects', Format(MCPConfiguration.DiscoverReadOnlyObjects));
    end;

    internal procedure GetTelemetryCategory(): Text[50]
    begin
        exit('MCP');
    end;

    internal procedure LogConfigurationCreated(MCPConfiguration: Record "MCP Configuration")
    begin
        Session.LogMessage('0000R0Q', MCPConfigurationCreatedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetDimensions(MCPConfiguration));
        Session.LogAuditMessage(StrSubstNo(MCPConfigurationAuditCreatedLbl, MCPConfiguration.Name, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;

    internal procedure LogConfigurationModified(MCPConfiguration: Record "MCP Configuration"; xMCPConfiguration: Record "MCP Configuration")
    var
        Dimensions: Dictionary of [Text, Text];
    begin
        Dimensions.Add('MCPConfigurationName', MCPConfiguration.Name);
        if MCPConfiguration.Active <> xMCPConfiguration.Active then begin
            Dimensions.Add('OldActive', Format(xMCPConfiguration.Active));
            Dimensions.Add('NewActive', Format(MCPConfiguration.Active));
        end;
        if MCPConfiguration.AllowProdChanges <> xMCPConfiguration.AllowProdChanges then begin
            Dimensions.Add('OldUnblockEditTools', Format(xMCPConfiguration.AllowProdChanges));
            Dimensions.Add('NewUnblockEditTools', Format(MCPConfiguration.AllowProdChanges));
        end;
        if MCPConfiguration.EnableDynamicToolMode <> xMCPConfiguration.EnableDynamicToolMode then begin
            Dimensions.Add('OldDynamicToolMode', Format(xMCPConfiguration.EnableDynamicToolMode));
            Dimensions.Add('NewDynamicToolMode', Format(MCPConfiguration.EnableDynamicToolMode));
        end;
        if MCPConfiguration.DiscoverReadOnlyObjects <> xMCPConfiguration.DiscoverReadOnlyObjects then begin
            Dimensions.Add('OldDiscoverReadOnlyObjects', Format(xMCPConfiguration.DiscoverReadOnlyObjects));
            Dimensions.Add('NewDiscoverReadOnlyObjects', Format(MCPConfiguration.DiscoverReadOnlyObjects));
        end;
        Session.LogMessage('0000QE9', MCPConfigurationModifiedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        Session.LogAuditMessage(StrSubstNo(MCPConfigurationAuditModifiedLbl, MCPConfiguration.Name, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;

    internal procedure LogConfigurationDeleted(MCPConfiguration: Record "MCP Configuration")
    begin
        Session.LogMessage('0000QEB', MCPConfigurationDeletedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetDimensions(MCPConfiguration));
        Session.LogAuditMessage(StrSubstNo(MCPConfigurationAuditDeletedLbl, MCPConfiguration.Name, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;
}
