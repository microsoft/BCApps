// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

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
                }
                field(objectName; MCPConfigImplementation.GetObjectCaption(Rec.SystemId))
                {
                    Caption = 'Object Name';
                    Editable = false;
                }
                field(allowRead; Rec."Allow Read")
                {
                    Caption = 'Allow Read';
                }
                field(allowCreate; Rec."Allow Create")
                {
                    Caption = 'Allow Create';
                }
                field(allowModify; Rec."Allow Modify")
                {
                    Caption = 'Allow Modify';
                }
                field(allowDelete; Rec."Allow Delete")
                {
                    Caption = 'Allow Delete';
                }
                field(allowBoundActions; Rec."Allow Bound Actions")
                {
                    Caption = 'Allow Bound Actions';
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

    local procedure CheckConfigurationNotActive()
    var
        MCPConfiguration: Record "MCP Configuration";
    begin
        if MCPConfiguration.GetBySystemId(Rec.ID) then
            if MCPConfiguration.Active then
                Error(CannotModifyToolsActiveConfigErr);
    end;
}
