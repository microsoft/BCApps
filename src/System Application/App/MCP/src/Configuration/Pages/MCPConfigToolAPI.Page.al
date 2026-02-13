// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

page 8367 "MCP Config Tool API"
{
    APIGroup = 'mcp';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    EntityCaption = 'MCP Configuration Tool';
    EntitySetCaption = 'MCP Configuration Tools';
    DelayedInsert = true;
    EntityName = 'mcpConfigurationTool';
    EntitySetName = 'mcpConfigurationTools';
    PageType = API;
    SourceTable = "MCP Configuration Tool";
    ODataKeyFields = SystemId;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Group)
            {
                field(id; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                }
                field(configurationId; Rec.ID)
                {
                    Caption = 'Configuration Id';
                }
                field(objectType; Rec."Object Type")
                {
                    Caption = 'Object Type';
                }
                field(objectId; Rec."Object ID")
                {
                    Caption = 'Object Id';

                    trigger OnValidate()
                    var
                        PageMetadata: Record "Page Metadata";
                    begin
                        PageMetadata := MCPConfigImplementation.ValidateAPITool(Rec."Object ID", true);
                        Rec."API Version" := MCPConfigImplementation.GetHighestAPIVersion(PageMetadata);
                    end;
                }
                field(objectName; MCPConfigImplementation.GetObjectCaption(Rec.SystemId))
                {
                    Caption = 'Object Name';
                    Editable = false;
                }
                field(apiVersion; Rec."API Version")
                {
                    Caption = 'API Version';

                    trigger OnValidate()
                    begin
                        MCPConfigImplementation.ValidateAPIVersion(Rec."Object ID", Rec."API Version");
                    end;
                }
                field(allowRead; Rec."Allow Read")
                {
                    Caption = 'Allow Read';
                }
                field(allowCreate; Rec."Allow Create")
                {
                    Caption = 'Allow Create';

                    trigger OnValidate()
                    begin
                        if Rec."Allow Create" then
                            CheckAllowProdChanges();
                    end;
                }
                field(allowModify; Rec."Allow Modify")
                {
                    Caption = 'Allow Modify';

                    trigger OnValidate()
                    begin
                        if Rec."Allow Modify" then
                            CheckAllowProdChanges();
                    end;
                }
                field(allowDelete; Rec."Allow Delete")
                {
                    Caption = 'Allow Delete';

                    trigger OnValidate()
                    begin
                        if Rec."Allow Delete" then
                            CheckAllowProdChanges();
                    end;
                }
                field(allowBoundActions; Rec."Allow Bound Actions")
                {
                    Caption = 'Allow Bound Actions';

                    trigger OnValidate()
                    begin
                        if Rec."Allow Bound Actions" then
                            CheckAllowProdChanges();
                    end;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
            }
        }
    }

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CheckConfigurationNotActive();
    end;

    trigger OnModifyRecord(): Boolean
    begin
        CheckConfigurationNotActive();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        CheckConfigurationNotActive();
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        CannotModifyToolsActiveConfigErr: Label 'Cannot modify tools of an active configuration. Deactivate it first.';
        CreateUpdateDeleteNotAllowedErr: Label 'Create, update and delete tools are not allowed for this MCP configuration.';

    local procedure CheckAllowProdChanges()
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if MCPConfiguration.GetBySystemId(Rec.ID) then
            if not MCPConfiguration.AllowProdChanges then
                Error(CreateUpdateDeleteNotAllowedErr);
    end;

    local procedure CheckConfigurationNotActive()
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if MCPConfiguration.GetBySystemId(Rec.ID) then
            if MCPConfiguration.Active then
                Error(CannotModifyToolsActiveConfigErr);
    end;
}
