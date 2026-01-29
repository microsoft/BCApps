// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8366 "MCP Config API"
{
    APIGroup = 'mcp';
    APIPublisher = 'microsoft';
    APIVersion = 'v1.0';
    EntityCaption = 'MCP Configuration';
    EntitySetCaption = 'MCP Configurations';
    DelayedInsert = true;
    EntityName = 'mcpConfiguration';
    EntitySetName = 'mcpConfigurations';
    PageType = API;
    SourceTable = "MCP Configuration";
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
                field(name; Rec.Name)
                {
                    Caption = 'Name';
                }
                field(description; Rec.Description)
                {
                    Caption = 'Description';
                }
                field(active; Rec.Active)
                {
                    Caption = 'Active';
                }
                field(dynamicToolMode; Rec.EnableDynamicToolMode)
                {
                    Caption = 'Dynamic Tool Mode';

                    trigger OnValidate()
                    begin
                        if not Rec.EnableDynamicToolMode then
                            Rec.DiscoverReadOnlyObjects := false;
                    end;
                }
                field(discoverAdditionalObjects; Rec.DiscoverReadOnlyObjects)
                {
                    Caption = 'Discover Additional Objects';

                    trigger OnValidate()
                    begin
                        if Rec.DiscoverReadOnlyObjects and not Rec.EnableDynamicToolMode then
                            Error(DynamicToolModeRequiredErr);
                    end;
                }
                field(unblockEditTools; Rec.AllowProdChanges)
                {
                    Caption = 'Unblock Edit Tools';

                    trigger OnValidate()
                    begin
                        if not Rec.AllowProdChanges then
                            MCPConfigImplementation.DisableCreateUpdateDeleteToolsInConfig(Rec.SystemId);
                    end;
                }
                field(lastModifiedDateTime; Rec.SystemModifiedAt)
                {
                    Caption = 'Last Modified Date';
                    Editable = false;
                }
                part(mcpConfigurationTools; "MCP Config Tool API")
                {
                    Caption = 'MCP Configuration Tools';
                    EntityName = 'mcpConfigurationTool';
                    EntitySetName = 'mcpConfigurationTools';
                    SubPageLink = ID = field(SystemId);
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetFilter(Name, '<>%1', '');
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        MCPConfigImplementation.LogConfigurationCreated(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        if Rec.Active then
            Error(CannotModifyActiveConfigErr);
        MCPConfigImplementation.LogConfigurationModified(Rec, xRec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        MCPConfigImplementation.LogConfigurationDeleted(Rec);
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        CannotModifyActiveConfigErr: Label 'Cannot modify an active configuration. Deactivate it first.';
        DynamicToolModeRequiredErr: Label 'Dynamic tool mode must be enabled to discover additional objects.';
}
