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
        VersionNotValidErr: Label 'The API version is not valid for the selected tool.';
        MCPConfigurationCreatedLbl: Label 'MCP Configuration created', Locked = true;
        MCPConfigurationModifiedLbl: Label 'MCP Configuration modified', Locked = true;
        MCPConfigurationDeletedLbl: Label 'MCP Configuration deleted', Locked = true;
        MCPConfigurationAuditCreatedLbl: Label 'MCP Configuration %1 created by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        MCPConfigurationAuditModifiedLbl: Label 'MCP Configuration %1 modified by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        MCPConfigurationAuditDeletedLbl: Label 'MCP Configuration %1 deleted by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        InvalidConfigurationWarningLbl: Label 'The configuration is invalid and may not work as expected. Do you want to review warnings before activating?';
        ConfigValidLbl: Label 'No warnings found. The configuration is valid.';
        ConnectionStringLbl: Label '%1 Connection String', Comment = '%1 - configuration name';
        MCPUrlProdLbl: Label 'https://mcp.businesscentral.dynamics.com', Locked = true;
        MCPUrlTIELbl: Label 'https://mcp.businesscentral.dynamics-tie.com', Locked = true;
        MCPPrefixProdLbl: Label 'businesscentral', Locked = true;
        MCPPrefixTIELbl: Label 'businesscentral-tie', Locked = true;
        VSCodeAppNameLbl: Label 'VS Code', Locked = true;
        VSCodeAppDescriptionLbl: Label 'Visual Studio Code', Locked = true;
        VSCodeClientIdLbl: Label 'aebc6443-996d-45c2-90f0-388ff96faa56', Locked = true;
        ExportFileNameTxt: Label 'MCPConfig_%1_%2.json', Locked = true, Comment = '%1 = config name, %2 = date';
        ExportTitleTxt: Label 'Export Configuration';
        ImportTitleTxt: Label 'Import Configuration';
        JsonFilterTxt: Label 'JSON Files (*.json)|*.json';
        InvalidJsonErr: Label 'The selected file is not a valid configuration file.';
        ConfigNameExistsMsg: Label 'A configuration with the name ''%1'' already exists. Please provide a different name.', Comment = '%1 = configuration name';

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

    internal procedure IsDefaultConfiguration(MCPConfiguration: Record "MCP Configuration"): Boolean
    begin
        exit(MCPConfiguration.Name = '');
    end;

    internal procedure IsConfigurationActive(ConfigId: Guid): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if MCPConfiguration.GetBySystemId(ConfigId) then
            exit(MCPConfiguration.Active);
        exit(false);
    end;

    internal procedure ValidateConfiguration(var MCPConfiguration: Record "MCP Configuration"; OnActivate: Boolean)
    var
        MCPConfigurationWarning: Record "MCP Config Warning";
    begin
        // Raise warning if any issues found
        if not FindWarningsForConfiguration(MCPConfiguration.SystemId, MCPConfigurationWarning) then begin
            if not OnActivate then
                Message(ConfigValidLbl);
            exit;
        end;

        if OnActivate then
            if not Confirm(InvalidConfigurationWarningLbl) then
                exit;

        MCPConfiguration.Active := false;
        Page.Run(Page::"MCP Config Warning List", MCPConfigurationWarning);
    end;

    internal procedure FindWarningsForConfiguration(ConfigId: Guid; var MCPConfigurationWarning: Record "MCP Config Warning"): Boolean
    var
        IMCPConfigWarning: Interface "MCP Config Warning";
        MCPConfigWarningType: Enum "MCP Config Warning Type";
        WarningImplementations: List of [Integer];
        WarningImplementation: Integer;
        EntryNo: Integer;
    begin
        if MCPConfigurationWarning.FindLast() then
            EntryNo := MCPConfigurationWarning."Entry No." + 1
        else
            EntryNo := 1;

        WarningImplementations := MCPConfigWarningType.Ordinals();
        foreach WarningImplementation in WarningImplementations do begin
            IMCPConfigWarning := "MCP Config Warning Type".FromInteger(WarningImplementation);
            IMCPConfigWarning.CheckForWarnings(ConfigId, MCPConfigurationWarning, EntryNo);
        end;

        exit(not MCPConfigurationWarning.IsEmpty());
    end;

    internal procedure GetWarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    var
        IMCPConfigWarning: Interface "MCP Config Warning";
    begin
        IMCPConfigWarning := MCPConfigWarning."Warning Type";
        exit(IMCPConfigWarning.WarningMessage(MCPConfigWarning));
    end;

    internal procedure GetRecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    var
        IMCPConfigWarning: Interface "MCP Config Warning";
    begin
        IMCPConfigWarning := MCPConfigWarning."Warning Type";
        exit(IMCPConfigWarning.RecommendedAction(MCPConfigWarning));
    end;

    internal procedure ApplyRecommendedActions(var MCPConfigWarning: Record "MCP Config Warning")
    begin
        if not MCPConfigWarning.FindSet() then
            exit;

        repeat
            ApplyRecommendedAction(MCPConfigWarning);
        until MCPConfigWarning.Next() = 0;
    end;

    internal procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    var
        IMCPConfigWarning: Interface "MCP Config Warning";
    begin
        IMCPConfigWarning := MCPConfigWarning."Warning Type";
        IMCPConfigWarning.ApplyRecommendedAction(MCPConfigWarning);
    end;
    #endregion

    #region Tools
    internal procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer; ValidateAPIPublisher: Boolean): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
        PageMetadata: Record "Page Metadata";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(ToolsCannotBeAddedToDefaultConfigErr);

        PageMetadata := ValidateAPITool(APIPageId, ValidateAPIPublisher);

        MCPConfigurationTool.ID := ConfigId;
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Page;
        MCPConfigurationTool."Object ID" := APIPageId;
        MCPConfigurationTool."Allow Read" := true;
        MCPConfigurationTool."API Version" := GetHighestAPIVersion(PageMetadata);
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

    internal procedure ValidateAPITool(PageId: Integer; ValidateAPIPublisher: Boolean): Record "Page Metadata"
    var
        PageMetadata: Record "Page Metadata";
    begin
        if not PageMetadata.Get(PageId) then
            Error(PageNotFoundErr);

        if PageMetadata.PageType <> PageMetadata.PageType::API then
            Error(InvalidPageTypeErr);

        if not ValidateAPIPublisher then
            exit(PageMetadata);

        if PageMetadata.APIPublisher = 'microsoft' then
            Error(InvalidAPIVersionErr);

        if PageMetadata."AL Namespace" = 'Microsoft.API.V1' then
            Error(InvalidAPIVersionErr);

        exit(PageMetadata);
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

    internal procedure CheckAPIToolExists(ConfigId: Guid; PageId: Integer): Boolean
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

    internal procedure LoadSystemTools(var MCPSystemTool: Record "MCP System Tool")
    var
        MCPUtilities: Codeunit "MCP Utilities";
        SystemTools: Dictionary of [Text, Text];
        ToolName: Text;
    begin
        MCPSystemTool.Reset();
        MCPSystemTool.DeleteAll();

        SystemTools := MCPUtilities.GetSystemToolsInDynamicMode();
        foreach ToolName in SystemTools.Keys() do
            InsertSystemTool(MCPSystemTool, CopyStr(ToolName, 1, MaxStrLen(MCPSystemTool."Tool Name")), CopyStr(SystemTools.Get(ToolName), 1, MaxStrLen(MCPSystemTool."Tool Description")));
    end;

    local procedure InsertSystemTool(var MCPSystemTool: Record "MCP System Tool"; ToolName: Text[100]; ToolDescription: Text[250])
    begin
        MCPSystemTool."Tool Name" := ToolName;
        MCPSystemTool."Tool Description" := ToolDescription;
        MCPSystemTool.Insert();
    end;

    internal procedure ValidateAPIVersion(ObjectId: Integer; APIVersion: Text)
    var
        PageMetadata: Record "Page Metadata";
        Versions: List of [Text];
    begin
        if not PageMetadata.Get(ObjectId) then
            exit;

        Versions := PageMetadata.APIVersion.Split(',');
        if not Versions.Contains(APIVersion) then
            Error(VersionNotValidErr);
    end;

    internal procedure LookupAPIVersions(PageId: Integer; var APIVersion: Text[30])
    var
        PageMetadata: Record "Page Metadata";
        MCPAPIVersion: Record "MCP API Version";
        Versions: List of [Text];
        Version: Text[30];
    begin
        if not PageMetadata.Get(PageId) then
            exit;

        Versions := PageMetadata.APIVersion.Split(',');
        foreach Version in Versions do begin
            MCPAPIVersion."API Version" := Version;
            MCPAPIVersion.Insert();
        end;

        if Page.RunModal(Page::"MCP API Version Lookup", MCPAPIVersion) = Action::LookupOK then
            APIVersion := MCPAPIVersion."API Version";
    end;

    internal procedure GetHighestAPIVersion(PageMetadata: Record "Page Metadata"): Text[30]
    var
        Versions: List of [Text];
        Version: Text;
        HighestVersion: Text;
        HighestMajor: Integer;
        HighestMinor: Integer;
        CurrentMajor: Integer;
        CurrentMinor: Integer;
    begin
        if PageMetadata.APIVersion = '' then
            exit('');

        Versions := PageMetadata.APIVersion.Split(',');

        if Versions.Count() = 1 then
            exit(CopyStr(Versions.Get(1), 1, 30));

        HighestMajor := -1;
        HighestMinor := -1;

        foreach Version in Versions do
            if TryParseVersion(Version, CurrentMajor, CurrentMinor) then
                if (CurrentMajor > HighestMajor) or ((CurrentMajor = HighestMajor) and (CurrentMinor > HighestMinor)) then begin
                    HighestMajor := CurrentMajor;
                    HighestMinor := CurrentMinor;
                    HighestVersion := Version;
                end;

        exit(CopyStr(HighestVersion, 1, 30));
    end;

    local procedure TryParseVersion(Version: Text; var Major: Integer; var Minor: Integer): Boolean
    var
        VersionParts: List of [Text];
        VersionNumber: Text;
    begin
        // 'beta' is treated as lowest priority
        if Version.ToLower() = 'beta' then begin
            Major := -1;
            Minor := -1;
            exit(true);
        end;

        // Expected format: vMajor.Minor (e.g., v1.0, v2.0)
        if not Version.StartsWith('v') then
            exit(false);

        VersionNumber := Version.Substring(2); // Remove 'v'
        VersionParts := VersionNumber.Split('.');

        if VersionParts.Count() <> 2 then
            exit(false);

        if not Evaluate(Major, VersionParts.Get(1)) then
            exit(false);

        if not Evaluate(Minor, VersionParts.Get(2)) then
            exit(false);

        exit(true);
    end;
    #endregion

    #region Connection String
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
        JsonBuilder.AppendLine('"' + MCPPrefix + '": {');
        JsonBuilder.AppendLine('  "url": "' + MCPUrl + '",');
        JsonBuilder.AppendLine('  "type": "http",');
        JsonBuilder.AppendLine('  "headers": {');
        JsonBuilder.AppendLine('    "TenantId": "' + TenantId + '",');
        JsonBuilder.AppendLine('    "EnvironmentName": "' + EnvironmentName + '",');
        JsonBuilder.AppendLine('    "Company": "' + Company + '",');
        JsonBuilder.AppendLine('    "ConfigurationName": "' + ConfigurationName + '"');
        JsonBuilder.AppendLine('  }');
        JsonBuilder.AppendLine('}');
        exit(JsonBuilder.ToText());
    end;

    internal procedure CreateEntraApplication(Name: Text[100]; Description: Text[250]; ClientId: Guid)
    var
        MCPEntraApplication: Record "MCP Entra Application";
    begin
        MCPEntraApplication.Name := Name;
        MCPEntraApplication.Description := Description;
        MCPEntraApplication."Client ID" := ClientId;
        MCPEntraApplication.Insert();
    end;

    internal procedure DeleteEntraApplication(Name: Text[100])
    var
        MCPEntraApplication: Record "MCP Entra Application";
    begin
        if not MCPEntraApplication.Get(Name) then
            exit;

        MCPEntraApplication.Delete();
    end;
    #endregion

    #region Export/Import
    internal procedure ExportConfigurationToFile(ConfigId: Guid; ConfigName: Text[100])
    var
        TempBlob: Codeunit "Temp Blob";
        OutStream: OutStream;
        InStream: InStream;
        FileName: Text;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        ExportConfiguration(ConfigId, OutStream);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        FileName := StrSubstNo(ExportFileNameTxt, ConfigName, Format(Today(), 0, '<Year4>-<Month,2>-<Day,2>'));
        DownloadFromStream(InStream, ExportTitleTxt, '', JsonFilterTxt, FileName);
    end;

    internal procedure ImportConfigurationFromFile()
    var
        MCPConfiguration: Record "MCP Configuration";
        TempBlob: Codeunit "Temp Blob";
        MCPCopyConfig: Page "MCP Copy Config";
        InStream: InStream;
        OutStream: OutStream;
        FileName: Text;
        ConfigName: Text[100];
        ConfigDescription: Text[250];
    begin
        if not UploadIntoStream(ImportTitleTxt, '', JsonFilterTxt, FileName, InStream) then
            exit;

        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        CopyStream(OutStream, InStream);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);

        if not GetConfigFromJson(InStream, ConfigName, ConfigDescription) then
            Error(InvalidJsonErr);

        MCPConfiguration.SetRange(Name, ConfigName);
        if not MCPConfiguration.IsEmpty() then begin
            MCPCopyConfig.SetConfigName(ConfigName);
            MCPCopyConfig.SetConfigDescription(ConfigDescription);
            MCPCopyConfig.SetInstructionMessage(StrSubstNo(ConfigNameExistsMsg, ConfigName));
            MCPCopyConfig.LookupMode := true;
            if MCPCopyConfig.RunModal() <> Action::LookupOK then
                exit;
            ConfigName := MCPCopyConfig.GetConfigName();
            ConfigDescription := MCPCopyConfig.GetConfigDescription();
        end;

        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        ImportConfiguration(InStream, ConfigName, ConfigDescription);
    end;

    internal procedure ExportConfiguration(ConfigId: Guid; var OutStream: OutStream)
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ConfigJson: JsonObject;
        ToolsArray: JsonArray;
        ToolJson: JsonObject;
        OutputText: Text;
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        ConfigJson.Add('name', MCPConfiguration.Name);
        ConfigJson.Add('description', MCPConfiguration.Description);
        ConfigJson.Add('enableDynamicToolMode', MCPConfiguration.EnableDynamicToolMode);
        ConfigJson.Add('discoverReadOnlyObjects', MCPConfiguration.DiscoverReadOnlyObjects);
        ConfigJson.Add('allowProdChanges', MCPConfiguration.AllowProdChanges);

        MCPConfigurationTool.SetRange(ID, ConfigId);
        if MCPConfigurationTool.FindSet() then
            repeat
                Clear(ToolJson);
                ToolJson.Add('objectType', Format(MCPConfigurationTool."Object Type"));
                ToolJson.Add('objectId', MCPConfigurationTool."Object ID");
                ToolJson.Add('allowRead', MCPConfigurationTool."Allow Read");
                ToolJson.Add('allowCreate', MCPConfigurationTool."Allow Create");
                ToolJson.Add('allowModify', MCPConfigurationTool."Allow Modify");
                ToolJson.Add('allowDelete', MCPConfigurationTool."Allow Delete");
                ToolJson.Add('allowBoundActions', MCPConfigurationTool."Allow Bound Actions");
                ToolsArray.Add(ToolJson);
            until MCPConfigurationTool.Next() = 0;

        ConfigJson.Add('tools', ToolsArray);
        ConfigJson.WriteTo(OutputText);
        OutStream.WriteText(OutputText);
    end;

    local procedure GetConfigFromJson(var InStream: InStream; var ConfigName: Text[100]; var ConfigDescription: Text[250]): Boolean
    var
        ConfigJson: JsonObject;
        JsonToken: JsonToken;
        InputText: Text;
    begin
        InStream.ReadText(InputText);
        if not ConfigJson.ReadFrom(InputText) then
            exit(false);

        if not ConfigJson.Get('name', JsonToken) then
            exit(false);

        ConfigName := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(ConfigName));

        if ConfigJson.Get('description', JsonToken) then
            ConfigDescription := CopyStr(JsonToken.AsValue().AsText(), 1, MaxStrLen(ConfigDescription));

        exit(true);
    end;

    internal procedure ImportConfiguration(var InStream: InStream; NewName: Text[100]; NewDescription: Text[250]): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        ConfigJson: JsonObject;
        ToolsArray: JsonArray;
        ToolToken: JsonToken;
        InputText: Text;
    begin
        InStream.ReadText(InputText);
        if not ConfigJson.ReadFrom(InputText) then
            exit;

        MCPConfiguration.Name := NewName;
        MCPConfiguration.Description := NewDescription;
        MCPConfiguration.Active := false;

        if ConfigJson.Contains('enableDynamicToolMode') then
            MCPConfiguration.EnableDynamicToolMode := ConfigJson.GetBoolean('enableDynamicToolMode');

        if ConfigJson.Contains('discoverReadOnlyObjects') then
            MCPConfiguration.DiscoverReadOnlyObjects := ConfigJson.GetBoolean('discoverReadOnlyObjects');

        if ConfigJson.Contains('allowProdChanges') then
            MCPConfiguration.AllowProdChanges := ConfigJson.GetBoolean('allowProdChanges');

        MCPConfiguration.Insert();
        LogConfigurationCreated(MCPConfiguration);

        if ConfigJson.Contains('tools') then begin
            ToolsArray := ConfigJson.GetArray('tools');
            foreach ToolToken in ToolsArray do
                ImportTool(MCPConfiguration.SystemId, ToolToken.AsObject());
        end;

        exit(MCPConfiguration.SystemId);
    end;

    local procedure ImportTool(ConfigId: Guid; ToolJson: JsonObject)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        ObjectTypeText: Text;
    begin
        MCPConfigurationTool.Init();
        MCPConfigurationTool.ID := ConfigId;

        if ToolJson.Contains('objectType') then begin
            ObjectTypeText := ToolJson.GetText('objectType');
            if ObjectTypeText = 'Page' then
                MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Page;
        end;

        if ToolJson.Contains('objectId') then
            MCPConfigurationTool."Object ID" := ToolJson.GetInteger('objectId');

        if ToolJson.Contains('allowRead') then
            MCPConfigurationTool."Allow Read" := ToolJson.GetBoolean('allowRead');

        if ToolJson.Contains('allowCreate') then
            MCPConfigurationTool."Allow Create" := ToolJson.GetBoolean('allowCreate');

        if ToolJson.Contains('allowModify') then
            MCPConfigurationTool."Allow Modify" := ToolJson.GetBoolean('allowModify');

        if ToolJson.Contains('allowDelete') then
            MCPConfigurationTool."Allow Delete" := ToolJson.GetBoolean('allowDelete');

        if ToolJson.Contains('allowBoundActions') then
            MCPConfigurationTool."Allow Bound Actions" := ToolJson.GetBoolean('allowBoundActions');

        MCPConfigurationTool.Insert();
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
        Dimensions.Add('Category', GetTelemetryCategory());
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
        Dimensions.Add('Category', GetTelemetryCategory());
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
