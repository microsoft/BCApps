// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Azure.Identity;
using System.Environment;
using System.Feedback;
using System.Integration;
using System.Reflection;
using System.Text;
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
        QueryNotFoundErr: Label 'Query not found.';
        CodeunitNotFoundErr: Label 'Codeunit not found.';
        InvalidPageTypeErr: Label 'Only API pages are supported.';
        InvalidQueryTypeErr: Label 'Only API queries are supported.';
        InvalidCodeunitTypeErr: Label 'Only API codeunits are supported.';
        InvalidAPIVersionErr: Label 'Only API v2.0 objects are supported.';
        APIToolNotSupportedErr: Label 'This API page is not available for MCP configuration.';
        DefaultMCPConfigurationDescriptionLbl: Label 'Default MCP configuration';
        DesignatedDefaultCannotBeDeactivatedErr: Label 'The designated default configuration cannot be deactivated. Clear the default designation first.';
        ConfigurationMustBeActiveErr: Label 'Only active configurations can be set as the default.';
        DynamicToolModeRequiredErr: Label 'Dynamic tool mode needs to be enabled to discover read-only objects.';
        APIToolsRequiredForDynamicErr: Label 'API Tools must be enabled before Dynamic Tool Mode can be enabled.';
        VersionNotValidErr: Label 'The API version is not valid for the selected tool.';
        MCPConfigurationCreatedLbl: Label 'MCP Configuration created', Locked = true;
        MCPConfigurationModifiedLbl: Label 'MCP Configuration modified', Locked = true;
        MCPConfigurationDeletedLbl: Label 'MCP Configuration deleted', Locked = true;
        MCPConfigurationAuditCreatedLbl: Label 'MCP Configuration %1 created by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        MCPConfigurationAuditModifiedLbl: Label 'MCP Configuration %1 modified by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        MCPConfigurationAuditDeletedLbl: Label 'MCP Configuration %1 deleted by user %2 in company %3', Comment = '%1 - configuration name, %2 - user security ID, %3 - company name', Locked = true;
        InvalidConfigurationWarningLbl: Label 'The configuration is invalid and may not work as expected. Do you want to review warnings before activating?';
        ConfigValidLbl: Label 'No warnings found. The configuration is valid.';
        MCPDefaultConfigDesignatedLbl: Label 'MCP default configuration designated', Locked = true;
        ConnectionStringLbl: Label '%1 Connection String', Comment = '%1 - configuration name';
        MCPUrlProdLbl: Label 'https://mcp.businesscentral.dynamics.com', Locked = true;
        MCPUrlTIELbl: Label 'https://mcp.businesscentral.dynamics-tie.com', Locked = true;
        MCPPrefixProdLbl: Label 'businesscentral', Locked = true;
        MCPPrefixTIELbl: Label 'businesscentral-tie', Locked = true;
        MCPPrefixOnPremLbl: Label 'businesscentral-onprem', Locked = true;
        MCPOnPremSuffixLbl: Label '/mcp', Locked = true;
        ApiSuffixLbl: Label '/api', Locked = true;
        VSCodeAppNameLbl: Label 'VS Code', Locked = true;
        VSCodeAppDescriptionLbl: Label 'Visual Studio Code', Locked = true;
        VSCodeClientIdLbl: Label 'aebc6443-996d-45c2-90f0-388ff96faa56', Locked = true;
        ExportFileNameTxt: Label 'MCPConfig_%1_%2.json', Locked = true, Comment = '%1 = config name, %2 = date';
        ExportTitleTxt: Label 'Export Configuration';
        ImportTitleTxt: Label 'Import Configuration';
        JsonFilterTxt: Label 'JSON Files (*.json)|*.json';
        InvalidJsonErr: Label 'The selected file is not a valid configuration file.';
        ConfigNameExistsMsg: Label 'A configuration with the name ''%1'' already exists. Please provide a different name.', Comment = '%1 = configuration name';
        ConfigurationNotFoundErr: Label 'The MCP configuration was not found.';
        MCPServerFeedbackConfirmQst: Label 'We noticed you no longer have any active configurations. Could you share what made you decide to stop using the MCP server? Your feedback helps us improve the experience.';
        MCPServerFeedbackQst: Label 'What could we do to improve the MCP server experience?';
        NoActiveConfigsFeedbackTxt: Label 'No active configs feedback triggered', Locked = true;
        GeneralFeedbackTxt: Label 'General MCP feedback triggered', Locked = true;

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
            Error(ConfigurationNotFoundErr);

        if not Active and IsDefaultConfiguration(MCPConfiguration) then
            Error(DefaultConfigCannotBeDeactivatedErr);

        if not Active and IsDesignatedDefaultConfiguration(MCPConfiguration) then
            Error(DesignatedDefaultCannotBeDeactivatedErr);

        MCPConfiguration.Active := Active;
        MCPConfiguration.Modify();

    end;

    internal procedure AllowCreateUpdateDeleteTools(ConfigId: Guid; Allow: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
        xMCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);

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
        MCPConfigurationTool.SetRange("Object Type", MCPConfigurationTool."Object Type"::Page);
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
            Error(ConfigurationNotFoundErr);

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(DefaultConfigCannotBeDeletedErr);

        if IsDesignatedDefaultConfiguration(MCPConfiguration) then
            MarkSystemDefaultAsDefault();

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
            Error(ConfigurationNotFoundErr);

        NewMCPConfiguration.Copy(SourceMCPConfiguration);
        NewMCPConfiguration.Name := NewName;
        NewMCPConfiguration.Description := NewDescription;
        NewMCPConfiguration.Default := false;
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
            Error(ConfigurationNotFoundErr);

        xMCPConfiguration := MCPConfiguration;

        if not Enable and IsDefaultConfiguration(MCPConfiguration) then
            Error(DynamicToolModeCannotBeDisabledErr);

        if Enable and not IsAPIToolsEnabled(ConfigId) then
            Error(APIToolsRequiredForDynamicErr);

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
            Error(ConfigurationNotFoundErr);

        xMCPConfiguration := MCPConfiguration;

        if not Enable and IsDefaultConfiguration(MCPConfiguration) then
            Error(DiscoverReadOnlyObjectsCannotBeDisabledErr);

        if Enable and not MCPConfiguration.EnableDynamicToolMode then
            Error(DynamicToolModeRequiredErr);

        MCPConfiguration.DiscoverReadOnlyObjects := Enable;
        MCPConfiguration.Modify();
        LogConfigurationModified(MCPConfiguration, xMCPConfiguration);
    end;

    internal procedure EnableAPITools(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
        xMCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);
        xMCPConfiguration := MCPConfiguration;
        MCPConfiguration.EnableApiTools := Enable;
        if not Enable then begin
            // Dynamic Tool Mode requires API Tools, so disabling API Tools cascades it off
            // (mirroring how disabling Dynamic Tool Mode clears Discover Read-Only Objects).
            MCPConfiguration.EnableDynamicToolMode := false;
            MCPConfiguration.DiscoverReadOnlyObjects := false;
        end;
        MCPConfiguration.Modify();
        LogConfigurationModified(MCPConfiguration, xMCPConfiguration);
    end;

    internal procedure EnableDataQueryTools(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
        xMCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);
        xMCPConfiguration := MCPConfiguration;
        MCPConfiguration.EnableAlQueryTools := Enable;
        MCPConfiguration.Modify();
        LogConfigurationModified(MCPConfiguration, xMCPConfiguration);
    end;

    internal procedure IsAPIToolsEnabled(ConfigId: Guid): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            MCPConfiguration.Init(); // not persisted yet (new config): reflect the table default (InitValue)
        exit(MCPConfiguration.EnableApiTools);
    end;

    internal procedure IsDataQueryToolsEnabled(ConfigId: Guid): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            MCPConfiguration.Init(); // not persisted yet (new config): reflect the table default (InitValue)
        exit(MCPConfiguration.EnableAlQueryTools);
    end;

    local procedure CheckAllowCreateUpdateDeleteTools(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);

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
        MCPConfiguration.Default := true;
        MCPConfiguration.Insert();
    end;

    internal procedure IsDefaultConfiguration(MCPConfiguration: Record "MCP Configuration"): Boolean
    begin
        exit(MCPConfiguration.Name = '');
    end;

    internal procedure IsDesignatedDefaultConfiguration(MCPConfiguration: Record "MCP Configuration"): Boolean
    begin
        exit(MCPConfiguration.Default);
    end;

    internal procedure SetAsDefaultConfiguration(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
        PreviousDefault: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);

        if not MCPConfiguration.Active then
            Error(ConfigurationMustBeActiveErr);

        PreviousDefault.SetRange(Default, true);
        PreviousDefault.ModifyAll(Default, false);

        MCPConfiguration.Default := true;
        MCPConfiguration.Modify();

        Session.LogMessage('0000R0R', MCPDefaultConfigDesignatedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetDimensions(MCPConfiguration));
    end;

    internal procedure ClearDefaultConfiguration()
    var
        MCPConfiguration: Record "MCP Configuration";
        SystemDefault: Record "MCP Configuration";
    begin
        MCPConfiguration.SetRange(Default, true);
        MCPConfiguration.SetFilter(Name, '<>%1', '');
        MCPConfiguration.ModifyAll(Default, false);

        if SystemDefault.Get('') then begin
            SystemDefault.Default := true;
            SystemDefault.Modify();
        end;
    end;

    local procedure MarkSystemDefaultAsDefault()
    var
        SystemDefault: Record "MCP Configuration";
    begin
        if not SystemDefault.Get('') then
            exit;

        SystemDefault.Default := true;
        SystemDefault.Modify();
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
        TempMCPConfigurationWarning: Record "MCP Config Warning";
    begin
        // Raise warning if any issues found
        if not FindWarningsForConfiguration(MCPConfiguration.SystemId, TempMCPConfigurationWarning) then begin
            if not OnActivate then
                Message(ConfigValidLbl);
            exit;
        end;

        if OnActivate then
            if not Confirm(InvalidConfigurationWarningLbl) then
                exit;

        MCPConfiguration.Active := false;
        Page.Run(Page::"MCP Config Warning List", TempMCPConfigurationWarning);
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
    internal procedure CreateAPIPageTool(ConfigId: Guid; APIPageId: Integer; ValidateAPIPublisher: Boolean): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(ToolsCannotBeAddedToDefaultConfigErr);

        ValidateAPIPageTool(APIPageId, ValidateAPIPublisher);

        MCPConfigurationTool.ID := ConfigId;
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Page;
        MCPConfigurationTool."Object ID" := APIPageId;
        MCPConfigurationTool."Allow Read" := true;
        MCPConfigurationTool."API Version" := GetHighestAPIPageVersion(APIPageId);
        MCPConfigurationTool.Insert();
        exit(MCPConfigurationTool.SystemId);
    end;

    internal procedure GetAPIToolId(ConfigId: Guid; ObjectId: Integer; ObjectType: Option): Guid
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        EmptyGuid: Guid;
    begin
        if MCPConfigurationTool.Get(ConfigId, ObjectType, ObjectId) then
            exit(MCPConfigurationTool.SystemId);

        exit(EmptyGuid);
    end;

    internal procedure CreateAPIQueryTool(ConfigId: Guid; QueryAPIId: Integer): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(ToolsCannotBeAddedToDefaultConfigErr);

        ValidateAPIQueryTool(QueryAPIId);

        MCPConfigurationTool.ID := ConfigId;
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Query;
        MCPConfigurationTool."Object ID" := QueryAPIId;
        MCPConfigurationTool."Allow Read" := true;
        MCPConfigurationTool."API Version" := GetHighestAPIQueryVersion(QueryAPIId);
        MCPConfigurationTool.Insert();
        exit(MCPConfigurationTool.SystemId);
    end;

    internal procedure CreateAPICodeunitTool(ConfigId: Guid; CodeunitAPIId: Integer): Guid
    var
        MCPConfiguration: Record "MCP Configuration";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            Error(ConfigurationNotFoundErr);

        if IsDefaultConfiguration(MCPConfiguration) then
            Error(ToolsCannotBeAddedToDefaultConfigErr);

        ValidateAPICodeunitTool(CodeunitAPIId);

        MCPConfigurationTool.ID := ConfigId;
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Codeunit;
        MCPConfigurationTool."Object ID" := CodeunitAPIId;
        MCPConfigurationTool."Allow Bound Actions" := true;
        MCPConfigurationTool."API Version" := GetHighestAPICodeunitVersion(CodeunitAPIId);
        MCPConfigurationTool.Insert();
        exit(MCPConfigurationTool.SystemId);
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

        if MCPConfigurationTool."Object Type" = MCPConfigurationTool."Object Type"::Codeunit then
            exit; // Read is not applicable for codeunit tools

        MCPConfigurationTool."Allow Read" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowCreate(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        if MCPConfigurationTool."Object Type" in [MCPConfigurationTool."Object Type"::Query, MCPConfigurationTool."Object Type"::Codeunit] then
            exit; // Create is not applicable for query or codeunit tools

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

        if MCPConfigurationTool."Object Type" in [MCPConfigurationTool."Object Type"::Query, MCPConfigurationTool."Object Type"::Codeunit] then
            exit; // Modify is not applicable for query or codeunit tools

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

        if MCPConfigurationTool."Object Type" in [MCPConfigurationTool."Object Type"::Query, MCPConfigurationTool."Object Type"::Codeunit] then
            exit; // Delete is not applicable for query or codeunit tools

        if Allow then
            CheckAllowCreateUpdateDeleteTools(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Delete" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowActions(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        if MCPConfigurationTool."Object Type" = MCPConfigurationTool."Object Type"::Query then
            exit; // Actions are not applicable for query tools

        if Allow then
            CheckAllowCreateUpdateDeleteTools(MCPConfigurationTool.ID);

        MCPConfigurationTool."Allow Bound Actions" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure LookupAPIObjects(var SelectedObjects: Record "MCP API Object Buffer"; ObjectType: Option; TypeFilter: Boolean): Boolean
    var
        TempMCPAPIObjectBuffer: Record "MCP API Object Buffer";
        MCPAPIObjectLookup: Page "MCP API Object Lookup";
    begin
        PopulateAPIObjects(TempMCPAPIObjectBuffer);
        if TempMCPAPIObjectBuffer.IsEmpty() then
            exit(false);

        MCPAPIObjectLookup.SetObjects(TempMCPAPIObjectBuffer);
        if TypeFilter then
            TempMCPAPIObjectBuffer.SetRange("Object Type", ObjectType);
        MCPAPIObjectLookup.SetTableView(TempMCPAPIObjectBuffer);
        MCPAPIObjectLookup.LookupMode := true;
        if MCPAPIObjectLookup.RunModal() <> Action::LookupOK then
            exit(false);

        MCPAPIObjectLookup.GetSelectedObjects(SelectedObjects);
        exit(not SelectedObjects.IsEmpty());
    end;

    local procedure PopulateAPIObjects(var MCPAPIObjectBuffer: Record "MCP API Object Buffer")
    var
        ApiWebService: Record "Api Web Service";
    begin
        MCPAPIObjectBuffer.Reset();
        MCPAPIObjectBuffer.DeleteAll();

        // API pages
        SetAPIPageFilters(ApiWebService);
        AddAPIObjectsFromWebService(ApiWebService, MCPAPIObjectBuffer, MCPAPIObjectBuffer."Object Type"::Page, true);

        // API queries
        Clear(ApiWebService);
        SetAPIQueryFilters(ApiWebService);
        AddAPIObjectsFromWebService(ApiWebService, MCPAPIObjectBuffer, MCPAPIObjectBuffer."Object Type"::Query, false);

        // API codeunits
        Clear(ApiWebService);
        SetAPICodeunitFilters(ApiWebService);
        AddAPIObjectsFromWebService(ApiWebService, MCPAPIObjectBuffer, MCPAPIObjectBuffer."Object Type"::Codeunit, false);
    end;

    local procedure AddAPIObjectsFromWebService(var ApiWebService: Record "Api Web Service"; var MCPAPIObjectBuffer: Record "MCP API Object Buffer"; BufferObjectType: Option; ExcludeMicrosoftBeta: Boolean)
    begin
        if not ApiWebService.FindSet() then
            exit;

        repeat
            if not (ExcludeMicrosoftBeta and IsMicrosoftBetaAPI(ApiWebService)) then
                if MCPAPIObjectBuffer.Get(BufferObjectType, ApiWebService."Object ID") then begin
                    MCPAPIObjectBuffer."API Version" := CopyStr(MCPAPIObjectBuffer."API Version" + ',' + ApiWebService.Version, 1, MaxStrLen(MCPAPIObjectBuffer."API Version"));
                    MCPAPIObjectBuffer.Modify();
                end else begin
                    MCPAPIObjectBuffer.Init();
                    MCPAPIObjectBuffer."Object Type" := BufferObjectType;
                    MCPAPIObjectBuffer."Object ID" := ApiWebService."Object ID";
                    MCPAPIObjectBuffer.Name := CopyStr(ApiWebService."Object Name", 1, MaxStrLen(MCPAPIObjectBuffer.Name));
                    MCPAPIObjectBuffer."Entity Name" := CopyStr(ApiWebService."Service Name", 1, MaxStrLen(MCPAPIObjectBuffer."Entity Name"));
                    MCPAPIObjectBuffer."API Publisher" := CopyStr(ApiWebService.Publisher, 1, MaxStrLen(MCPAPIObjectBuffer."API Publisher"));
                    MCPAPIObjectBuffer."API Group" := CopyStr(ApiWebService.Group, 1, MaxStrLen(MCPAPIObjectBuffer."API Group"));
                    MCPAPIObjectBuffer."API Version" := CopyStr(ApiWebService.Version, 1, MaxStrLen(MCPAPIObjectBuffer."API Version"));
                    MCPAPIObjectBuffer.Insert();
                end;
        until ApiWebService.Next() = 0;
    end;

    local procedure SetAPIPageFilters(var ApiWebService: Record "Api Web Service")
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        ApiWebService.SetRange(Published, true);
        ApiWebService.SetFilter("AL Namespace", '<>%1', 'Microsoft.API.V1');
    end;

    local procedure SetAPIQueryFilters(var ApiWebService: Record "Api Web Service")
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Query);
        ApiWebService.SetRange(Published, true);
        ApiWebService.SetFilter("AL Namespace", '<>%1', 'Microsoft.API.V1');
        ApiWebService.SetFilter("Object ID", '<>%1&<>%2', 5480, 5481); // Exclude beta customer and vendor queries from Base Application, as they are already part of API v2.0
    end;

    local procedure SetAPICodeunitFilters(var ApiWebService: Record "Api Web Service")
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Codeunit);
        ApiWebService.SetRange(Published, true);
    end;

    local procedure IsMicrosoftBetaAPI(var ApiWebService: Record "Api Web Service"): Boolean
    begin
        exit((ApiWebService.Version = 'beta') and (ApiWebService.Publisher in ['microsoft', '']));
    end;

    internal procedure GetAPIPublishers(var MCPAPIPublisherGroup: Record "MCP API Publisher Group")
    begin
        GetAPIPagePublishers(MCPAPIPublisherGroup);
        GetAPIQueryPublishers(MCPAPIPublisherGroup);
        GetAPICodeunitPublishers(MCPAPIPublisherGroup);
    end;

    local procedure GetAPIPagePublishers(var MCPAPIPublisherGroup: Record "MCP API Publisher Group")
    var
        ApiWebService: Record "Api Web Service";
    begin
        SetAPIPageFilters(ApiWebService);
        ApiWebService.SetFilter(Publisher, '<>%1', '');

        if not ApiWebService.FindSet() then
            exit;

        repeat
            if IsMicrosoftBetaAPI(ApiWebService) then
                continue;
            if MCPAPIPublisherGroup.Get(ApiWebService.Publisher, ApiWebService.Group) then
                continue;
            MCPAPIPublisherGroup."API Publisher" := ApiWebService.Publisher;
            MCPAPIPublisherGroup."API Group" := ApiWebService.Group;
            MCPAPIPublisherGroup.Insert();
        until ApiWebService.Next() = 0;
    end;

    local procedure GetAPIQueryPublishers(var MCPAPIPublisherGroup: Record "MCP API Publisher Group")
    var
        ApiWebService: Record "Api Web Service";
    begin
        SetAPIQueryFilters(ApiWebService);
        ApiWebService.SetFilter(Publisher, '<>%1', '');

        if not ApiWebService.FindSet() then
            exit;

        repeat
            if MCPAPIPublisherGroup.Get(ApiWebService.Publisher, ApiWebService.Group) then
                continue;
            MCPAPIPublisherGroup."API Publisher" := ApiWebService.Publisher;
            MCPAPIPublisherGroup."API Group" := ApiWebService.Group;
            MCPAPIPublisherGroup.Insert();
        until ApiWebService.Next() = 0;
    end;

    local procedure GetAPICodeunitPublishers(var MCPAPIPublisherGroup: Record "MCP API Publisher Group")
    var
        ApiWebService: Record "Api Web Service";
    begin
        SetAPICodeunitFilters(ApiWebService);
        ApiWebService.SetFilter(Publisher, '<>%1', '');

        if not ApiWebService.FindSet() then
            exit;

        repeat
            if MCPAPIPublisherGroup.Get(ApiWebService.Publisher, ApiWebService.Group) then
                continue;
            MCPAPIPublisherGroup."API Publisher" := ApiWebService.Publisher;
            MCPAPIPublisherGroup."API Group" := ApiWebService.Group;
            MCPAPIPublisherGroup.Insert();
        until ApiWebService.Next() = 0;
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

    internal procedure ResolvePublisherForGroup(var MCPAPIPublisherGroup: Record "MCP API Publisher Group"; var APIPublisher: Text; APIGroupValue: Text)
    begin
        if APIGroupValue = '' then begin
            APIPublisher := '';
            exit;
        end;

        MCPAPIPublisherGroup.Reset();
        MCPAPIPublisherGroup.SetRange("API Group", APIGroupValue);

        if not MCPAPIPublisherGroup.FindSet() then begin
            APIPublisher := '';
            exit;
        end;

        if MCPAPIPublisherGroup.Count() = 1 then begin
            APIPublisher := MCPAPIPublisherGroup."API Publisher";
            exit;
        end;

        if Page.RunModal(Page::"MCP API Publisher Lookup", MCPAPIPublisherGroup) = Action::LookupOK then
            APIPublisher := MCPAPIPublisherGroup."API Publisher";
    end;

    internal procedure ValidateAPIPageTool(PageId: Integer; ValidateAPIPublisher: Boolean)
    var
        ApiWebService: Record "Api Web Service";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Page, PageId) then
            Error(PageNotFoundErr);

        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        ApiWebService.SetRange("Object ID", PageId);
        ApiWebService.SetRange(Published, true);
        if not ApiWebService.FindFirst() then
            Error(InvalidPageTypeErr);

        if not ValidateAPIPublisher then
            exit;

        if ApiWebService."AL Namespace" = 'Microsoft.API.V1' then
            Error(APIToolNotSupportedErr);

        if ApiWebService.Publisher in ['microsoft', ''] then begin
            ApiWebService.SetFilter(Version, '<>%1', 'beta');
            if ApiWebService.IsEmpty() then
                Error(APIToolNotSupportedErr);
        end;
    end;

    internal procedure ValidateAPIQueryTool(QueryId: Integer)
    var
        ApiWebService: Record "Api Web Service";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Query, QueryId) then
            Error(QueryNotFoundErr);

        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Query);
        ApiWebService.SetRange("Object ID", QueryId);
        ApiWebService.SetRange(Published, true);
        if not ApiWebService.FindFirst() then
            Error(InvalidQueryTypeErr);

        if ApiWebService."AL Namespace" = 'Microsoft.API.V1' then
            Error(InvalidAPIVersionErr);
    end;

    internal procedure ValidateAPICodeunitTool(CodeunitId: Integer)
    var
        ApiWebService: Record "Api Web Service";
        AllObjWithCaption: Record AllObjWithCaption;
    begin
        if not AllObjWithCaption.Get(AllObjWithCaption."Object Type"::Codeunit, CodeunitId) then
            Error(CodeunitNotFoundErr);

        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Codeunit);
        ApiWebService.SetRange("Object ID", CodeunitId);
        ApiWebService.SetRange(Published, true);
        if ApiWebService.IsEmpty() then
            Error(InvalidCodeunitTypeErr);
    end;

    internal procedure AddToolsByAPIGroup(ConfigId: Guid)
    var
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

        AddAPIPageTools(ConfigId, APIPublisher, APIGroup);
        AddAPIQueryTools(ConfigId, APIPublisher, APIGroup);
        AddAPICodeunitTools(ConfigId, APIPublisher, APIGroup);
    end;

    local procedure AddAPIPageTools(ConfigId: Guid; APIPublisher: Text; APIGroup: Text)
    var
        ApiWebService: Record "Api Web Service";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        SetAPIPageFilters(ApiWebService);
        ApiWebService.SetRange(Publisher, APIPublisher);
        ApiWebService.SetRange(Group, APIGroup);

        if not ApiWebService.FindSet() then
            exit;

        repeat
            if IsMicrosoftBetaAPI(ApiWebService) then
                continue;
            if not CheckAPIToolExists(ConfigId, ApiWebService."Object ID", MCPConfigurationTool."Object Type"::Page) then
                CreateAPIPageTool(ConfigId, ApiWebService."Object ID", false);
        until ApiWebService.Next() = 0;
    end;

    local procedure AddAPIQueryTools(ConfigId: Guid; APIPublisher: Text; APIGroup: Text)
    var
        ApiWebService: Record "Api Web Service";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        SetAPIQueryFilters(ApiWebService);
        ApiWebService.SetRange(Publisher, APIPublisher);
        ApiWebService.SetRange(Group, APIGroup);

        if not ApiWebService.FindSet() then
            exit;

        repeat
            if not CheckAPIToolExists(ConfigId, ApiWebService."Object ID", MCPConfigurationTool."Object Type"::Query) then
                CreateAPIQueryTool(ConfigId, ApiWebService."Object ID");
        until ApiWebService.Next() = 0;
    end;

    local procedure AddAPICodeunitTools(ConfigId: Guid; APIPublisher: Text; APIGroup: Text)
    var
        ApiWebService: Record "Api Web Service";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        SetAPICodeunitFilters(ApiWebService);
        ApiWebService.SetRange(Publisher, APIPublisher);
        ApiWebService.SetRange(Group, APIGroup);

        if not ApiWebService.FindSet() then
            exit;

        repeat
            if not CheckAPIToolExists(ConfigId, ApiWebService."Object ID", MCPConfigurationTool."Object Type"::Codeunit) then
                CreateAPICodeunitTool(ConfigId, ApiWebService."Object ID");
        until ApiWebService.Next() = 0;
    end;

    internal procedure AddStandardAPITools(ConfigId: Guid)
    var
        ApiWebService: Record "Api Web Service";
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        SetAPIPageFilters(ApiWebService);
        ApiWebService.SetRange(Publisher, '');
        ApiWebService.SetRange(Group, '');
        ApiWebService.SetRange(Version, 'v2.0');
        if ApiWebService.FindSet() then
            repeat
                if not CheckAPIToolExists(ConfigId, ApiWebService."Object ID", MCPConfigurationTool."Object Type"::Page) then
                    CreateAPIPageTool(ConfigId, ApiWebService."Object ID", false);
            until ApiWebService.Next() = 0;

        Clear(ApiWebService);
        SetAPIQueryFilters(ApiWebService);
        ApiWebService.SetRange(Publisher, '');
        ApiWebService.SetRange(Group, '');
        ApiWebService.SetRange(Version, 'v2.0');
        if ApiWebService.FindSet() then
            repeat
                if not CheckAPIToolExists(ConfigId, ApiWebService."Object ID", MCPConfigurationTool."Object Type"::Query) then
                    CreateAPIQueryTool(ConfigId, ApiWebService."Object ID");
            until ApiWebService.Next() = 0;
    end;

    internal procedure CheckAPIToolExists(ConfigId: Guid; ObjectId: Integer; ObjectType: Option): Boolean
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        MCPConfigurationTool.SetRange(ID, ConfigId);
        MCPConfigurationTool.SetRange("Object Type", ObjectType);
        MCPConfigurationTool.SetRange("Object ID", ObjectId);
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

        case MCPConfigurationTool."Object Type" of
            MCPConfigurationTool."Object Type"::Page:
                ObjectType := ObjectType::Page;
            MCPConfigurationTool."Object Type"::Query:
                ObjectType := ObjectType::Query;
            MCPConfigurationTool."Object Type"::Codeunit:
                ObjectType := ObjectType::Codeunit;
        end;

        if AllObjWithCaption.Get(ObjectType, MCPConfigurationTool."Object ID") then
            exit(CopyStr(AllObjWithCaption.Name, 1, 100));
        exit('');
    end;

    internal procedure ValidateAPIPageVersion(ObjectId: Integer; APIVersion: Text)
    var
        ApiWebService: Record "Api Web Service";
        Versions: List of [Text];
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        Versions := CollectAPIObjectVersions(ApiWebService, ObjectId, true);
        if Versions.Count() = 0 then
            exit;

        if not Versions.Contains(APIVersion) then
            Error(VersionNotValidErr);
    end;

    internal procedure ValidateAPIQueryVersion(ObjectId: Integer; APIVersion: Text)
    var
        ApiWebService: Record "Api Web Service";
        Versions: List of [Text];
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Query);
        Versions := CollectAPIObjectVersions(ApiWebService, ObjectId, false);
        if Versions.Count() = 0 then
            exit;

        if not Versions.Contains(APIVersion) then
            Error(VersionNotValidErr);
    end;

    internal procedure ValidateAPICodeunitVersion(ObjectId: Integer; APIVersion: Text)
    var
        ApiWebService: Record "Api Web Service";
        Versions: List of [Text];
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Codeunit);
        Versions := CollectAPIObjectVersions(ApiWebService, ObjectId, false);
        if Versions.Count() = 0 then
            exit;

        if not Versions.Contains(APIVersion) then
            Error(VersionNotValidErr);
    end;

    internal procedure LookupAPIPageVersions(PageId: Integer; var APIVersion: Text[30])
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        LookupAPIObjectVersions(ApiWebService, PageId, APIVersion, true);
    end;

    internal procedure LookupAPIQueryVersions(QueryId: Integer; var APIVersion: Text[30])
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Query);
        LookupAPIObjectVersions(ApiWebService, QueryId, APIVersion, false);
    end;

    internal procedure LookupAPICodeunitVersions(CodeunitId: Integer; var APIVersion: Text[30])
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Codeunit);
        LookupAPIObjectVersions(ApiWebService, CodeunitId, APIVersion, false);
    end;

    internal procedure GetHighestAPIPageVersion(PageId: Integer): Text[30]
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        exit(GetHighestAPIObjectVersion(ApiWebService, PageId, true));
    end;

    internal procedure GetHighestAPIQueryVersion(QueryId: Integer): Text[30]
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Query);
        exit(GetHighestAPIObjectVersion(ApiWebService, QueryId, false));
    end;

    internal procedure GetHighestAPICodeunitVersion(CodeunitId: Integer): Text[30]
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Codeunit);
        exit(GetHighestAPIObjectVersion(ApiWebService, CodeunitId, false));
    end;

    internal procedure IsAPIPage(PageId: Integer): Boolean
    var
        ApiWebService: Record "Api Web Service";
    begin
        ApiWebService.SetRange("Object Type", ApiWebService."Object Type"::Page);
        ApiWebService.SetRange("Object ID", PageId);
        ApiWebService.SetRange(Published, true);
        exit(not ApiWebService.IsEmpty());
    end;

    local procedure GetHighestAPIObjectVersion(var ApiWebService: Record "Api Web Service"; ObjectId: Integer; ExcludeMicrosoftBeta: Boolean): Text[30]
    var
        Versions: List of [Text];
    begin
        Versions := CollectAPIObjectVersions(ApiWebService, ObjectId, ExcludeMicrosoftBeta);
        if Versions.Count() = 0 then
            exit('');

        exit(GetHighestVersion(Versions));
    end;

    local procedure LookupAPIObjectVersions(var ApiWebService: Record "Api Web Service"; ObjectId: Integer; var APIVersion: Text[30]; ExcludeMicrosoftBeta: Boolean)
    var
        TempMCPAPIVersion: Record "MCP API Version";
        Versions: List of [Text];
        VersionText: Text;
    begin
        Versions := CollectAPIObjectVersions(ApiWebService, ObjectId, ExcludeMicrosoftBeta);
        foreach VersionText in Versions do begin
            TempMCPAPIVersion."API Version" := CopyStr(VersionText, 1, MaxStrLen(TempMCPAPIVersion."API Version"));
            if TempMCPAPIVersion.Insert() then;
        end;

        if Page.RunModal(Page::"MCP API Version Lookup", TempMCPAPIVersion) = Action::LookupOK then
            APIVersion := TempMCPAPIVersion."API Version";
    end;

    local procedure CollectAPIObjectVersions(var ApiWebService: Record "Api Web Service"; ObjectId: Integer; ExcludeMicrosoftBeta: Boolean): List of [Text]
    var
        Versions: List of [Text];
    begin
        ApiWebService.SetRange("Object ID", ObjectId);
        ApiWebService.SetRange(Published, true);
        if ApiWebService.FindSet() then
            repeat
                if not (ExcludeMicrosoftBeta and IsMicrosoftBetaAPI(ApiWebService)) then
                    Versions.Add(ApiWebService.Version);
            until ApiWebService.Next() = 0;
        exit(Versions);
    end;

    local procedure GetHighestVersion(Versions: List of [Text]): Text[30]
    var
        Version: Text;
        HighestVersion: Text;
        HighestMajor: Integer;
        HighestMinor: Integer;
        CurrentMajor: Integer;
        CurrentMinor: Integer;
    begin
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
        IsSaaS: Boolean;
    begin
        IsSaaS := EnvironmentInformation.IsSaaS();
        Company := CompanyName();

        GetMCPUrlAndPrefix(MCPUrl, MCPPrefix, IsSaaS);

        if IsSaaS then begin
            TenantId := AzureADTenant.GetAadTenantId();
            EnvironmentName := EnvironmentInformation.GetEnvironmentName();
        end;

        exit(BuildConnectionStringJson(MCPPrefix, MCPUrl, TenantId, EnvironmentName, Company, ConfigurationName, IsSaaS));
    end;

    local procedure GetMCPUrlAndPrefix(var MCPUrl: Text; var MCPPrefix: Text; IsSaaS: Boolean)
    var
        BaseUrl: Text;
    begin
        if not IsSaaS then begin
            BaseUrl := GetUrl(ClientType::Api).TrimEnd('/');
            if BaseUrl.EndsWith(ApiSuffixLbl) then
                BaseUrl := BaseUrl.Substring(1, StrLen(BaseUrl) - StrLen(ApiSuffixLbl));
            MCPUrl := BaseUrl + MCPOnPremSuffixLbl;
            MCPPrefix := MCPPrefixOnPremLbl;
            exit;
        end;

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

    local procedure BuildConnectionStringJson(MCPPrefix: Text; MCPUrl: Text; TenantId: Text; EnvironmentName: Text; Company: Text; ConfigurationName: Text[100]; IsSaaS: Boolean): Text
    var
        JsonBuilder: TextBuilder;
    begin
        JsonBuilder.AppendLine('"' + MCPPrefix + '": {');
        JsonBuilder.AppendLine('  "url": "' + MCPUrl + '",');
        JsonBuilder.AppendLine('  "type": "http",');
        JsonBuilder.AppendLine('  "headers": {');
        if IsSaaS then begin
            JsonBuilder.AppendLine('    "TenantId": "' + TenantId + '",');
            JsonBuilder.AppendLine('    "EnvironmentName": "' + EnvironmentName + '",');
        end;
        // Company and ConfigurationName are the only header values the customer can populate
        // with non-ASCII characters. The MCP server detects the "=?base64?<value>?=" wrapper
        // and decodes the UTF-8 bytes; ASCII values are emitted unchanged to remain
        // backward-compatible with existing client configurations.
        JsonBuilder.AppendLine('    "Company": "' + EncodeForMCPHeaderIfNonAscii(Company) + '",');
        JsonBuilder.AppendLine('    "ConfigurationName": "' + EncodeForMCPHeaderIfNonAscii(ConfigurationName) + '"');
        JsonBuilder.AppendLine('  }');
        JsonBuilder.AppendLine('}');
        exit(JsonBuilder.ToText());
    end;

    internal procedure EncodeForMCPHeaderIfNonAscii(Value: Text): Text
    var
        Base64Convert: Codeunit "Base64 Convert";
        Regex: Codeunit Regex;
    begin
        if not Regex.IsMatch(Value, '[^\x00-\x7F]') then
            exit(Value);

        exit('=?base64?' + Base64Convert.ToBase64(Value, TextEncoding::UTF8) + '?=');
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
            Error(ConfigurationNotFoundErr);

        ConfigJson.Add('name', MCPConfiguration.Name);
        ConfigJson.Add('description', MCPConfiguration.Description);
        ConfigJson.Add('enableDynamicToolMode', MCPConfiguration.EnableDynamicToolMode);
        ConfigJson.Add('discoverReadOnlyObjects', MCPConfiguration.DiscoverReadOnlyObjects);
        ConfigJson.Add('allowProdChanges', MCPConfiguration.AllowProdChanges);
        ConfigJson.Add('enableApiTools', MCPConfiguration.EnableApiTools);
        ConfigJson.Add('enableAlQueryTools', MCPConfiguration.EnableAlQueryTools);

        MCPConfigurationTool.SetRange(ID, ConfigId);
        if MCPConfigurationTool.FindSet() then
            repeat
                Clear(ToolJson);
                ToolJson.Add('objectType', Format(MCPConfigurationTool."Object Type"));
                ToolJson.Add('objectId', MCPConfigurationTool."Object ID");
                ToolJson.Add('apiVersion', MCPConfigurationTool."API Version");
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

        if ConfigJson.Contains('enableApiTools') then
            MCPConfiguration.EnableApiTools := ConfigJson.GetBoolean('enableApiTools');

        if ConfigJson.Contains('enableAlQueryTools') then
            MCPConfiguration.EnableAlQueryTools := ConfigJson.GetBoolean('enableAlQueryTools');

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
            if ObjectTypeText = 'Query' then
                MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Query;
            if ObjectTypeText = 'Codeunit' then
                MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Codeunit;
        end;

        if ToolJson.Contains('objectId') then
            MCPConfigurationTool."Object ID" := ToolJson.GetInteger('objectId');

        if ToolJson.Contains('apiVersion') then
            MCPConfigurationTool."API Version" := CopyStr(ToolJson.GetText('apiVersion'), 1, MaxStrLen(MCPConfigurationTool."API Version"));

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

    #region Feedback
    internal procedure TriggerNoActiveConfigsFeedback()
    var
        Feedback: Codeunit "Microsoft User Feedback";
    begin
        if not Confirm(MCPServerFeedbackConfirmQst, true) then
            exit;

        Feedback.WithCustomQuestion(MCPServerFeedbackQst, MCPServerFeedbackQst).WithCustomQuestionType(Enum::FeedbackQuestionType::Text);
        Feedback.RequestDislikeFeedback('MCP Server', 'MCPServer', 'Model Context Protocol (MCP) Server');

        Session.LogMessage('0000RTR', NoActiveConfigsFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', GetTelemetryCategory());
    end;

    internal procedure TriggerGeneralFeedback()
    var
        Feedback: Codeunit "Microsoft User Feedback";
    begin
        Feedback.RequestFeedback('MCP Server', 'MCPServer', 'Model Context Protocol (MCP) Server');

        Session.LogMessage('0000RTS', GeneralFeedbackTxt, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, 'Category', GetTelemetryCategory());
    end;

    internal procedure HasNoActiveConfigurations(): Boolean
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        MCPConfiguration.SetRange(Active, true);
        MCPConfiguration.SetFilter(Name, '<>%1', '');
        exit(MCPConfiguration.IsEmpty());
    end;
    #endregion Feedback

    #region Telemetry
    local procedure GetDimensions(MCPConfiguration: Record "MCP Configuration") Dimensions: Dictionary of [Text, Text]
    begin
        Dimensions.Add('Category', GetTelemetryCategory());
        Dimensions.Add('MCPConfigurationName', MCPConfiguration.Name);
        Dimensions.Add('Active', Format(MCPConfiguration.Active));
        Dimensions.Add('IsDesignatedDefault', Format(MCPConfiguration.Default));
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
        if MCPConfiguration.EnableApiTools <> xMCPConfiguration.EnableApiTools then begin
            Dimensions.Add('OldApiTools', Format(xMCPConfiguration.EnableApiTools));
            Dimensions.Add('NewApiTools', Format(MCPConfiguration.EnableApiTools));
        end;
        if MCPConfiguration.EnableAlQueryTools <> xMCPConfiguration.EnableAlQueryTools then begin
            Dimensions.Add('OldDataQueryTools', Format(xMCPConfiguration.EnableAlQueryTools));
            Dimensions.Add('NewDataQueryTools', Format(MCPConfiguration.EnableAlQueryTools));
        end;
        Session.LogMessage('0000QE9', MCPConfigurationModifiedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, Dimensions);
        Session.LogAuditMessage(StrSubstNo(MCPConfigurationAuditModifiedLbl, MCPConfiguration.Name, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;

    internal procedure LogConfigurationDeleted(MCPConfiguration: Record "MCP Configuration")
    begin
        Session.LogMessage('0000QEB', MCPConfigurationDeletedLbl, Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::All, GetDimensions(MCPConfiguration));
        Session.LogAuditMessage(StrSubstNo(MCPConfigurationAuditDeletedLbl, MCPConfiguration.Name, UserSecurityId(), CompanyName()), SecurityOperationResult::Success, AuditCategory::ApplicationManagement, 3, 0);
    end;
    #endregion
}