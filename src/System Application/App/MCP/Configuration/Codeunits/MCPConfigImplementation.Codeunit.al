// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

codeunit 8201 "MCP Config Implementation"
{
    Access = Internal;

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
    end;

    internal procedure DeleteConfiguration(ConfigId: Guid)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        MCPConfiguration.Delete();
    end;

    internal procedure CreateAPITool(ConfigId: Guid; APIPageId: Integer): Guid
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        ValidateAPITool(APIPageId);
        MCPConfigurationTool."Config Id" := ConfigId;
        MCPConfigurationTool."Object Type" := MCPConfigurationTool."Object Type"::Page;
        MCPConfigurationTool."Object ID" := APIPageId;
        MCPConfigurationTool.Insert();
        exit(MCPConfigurationTool.SystemId);
    end;

    internal procedure EnableDynamicTooling(ConfigId: Guid; Enable: Boolean)
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if not MCPConfiguration.GetBySystemId(ConfigId) then
            exit;

        MCPConfiguration.EnableDynamicToolMode := Enable;
        MCPConfiguration.Modify();
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

        MCPConfigurationTool."Allow Create" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowModify(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        MCPConfigurationTool."Allow Modify" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowDelete(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        MCPConfigurationTool."Allow Delete" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure AllowBoundActions(ToolId: Guid; Allow: Boolean)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
    begin
        if not MCPConfigurationTool.GetBySystemId(ToolId) then
            exit;

        MCPConfigurationTool."Allow Bound Actions" := Allow;
        MCPConfigurationTool.Modify();
    end;

    internal procedure LookupAPITools(var PageId: Integer)
    var
        PageMetadata: Record "Page Metadata";
    begin
        PageMetadata.SetRange(PageMetadata.PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(PageMetadata.APIPublisher, '<>%1', 'microsoft');
        PageMetadata.SetFilter(PageMetadata."AL Namespace", '<>%1', 'Microsoft.API.V1');

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

        PageMetadata.SetRange(PageMetadata.PageType, PageMetadata.PageType::API);
        PageMetadata.SetFilter(PageMetadata.APIPublisher, APIPublisher);
        PageMetadata.SetFilter(PageMetadata.APIGroup, APIGroup);
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
}