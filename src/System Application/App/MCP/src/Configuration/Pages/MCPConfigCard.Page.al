// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8351 "MCP Config Card"
{
    ApplicationArea = All;
    PageType = Card;
    SourceTable = "MCP Configuration";
    Caption = 'Model Context Protocol (MCP) Server Configuration';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    AboutTitle = 'About model context protocol (MCP) server configuration';
    AboutText = 'Manage how MCP configurations are set up. Specify which APIs are available as tools, control data access permissions, and enable dynamic discovery of tools. You can also duplicate existing configurations to quickly create new setups.';

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                Caption = 'General';
                field(Name; Rec.Name)
                {
                    Editable = not IsDefault;
                }
                field(Description; Rec.Description)
                {
                    Editable = not IsDefault;
                    MultiLine = true;
                }
                field(Active; Rec.Active)
                {
                    Editable = not IsDefault;
                }
                field(EnableDynamicToolMode; Rec.EnableDynamicToolMode)
                {
                    Editable = not IsDefault;

                    trigger OnValidate()
                    begin
                        if not Rec.EnableDynamicToolMode then
                            Rec.DiscoverReadOnlyObjects := false;
                    end;
                }
                field(DiscoverReadOnlyObjects; Rec.DiscoverReadOnlyObjects)
                {
                    Editable = not IsDefault and Rec.EnableDynamicToolMode;
                }
                field(AllowProdChanges; Rec.AllowProdChanges)
                {
                    trigger OnValidate()
                    begin
                        if not Rec.AllowProdChanges then
                            MCPConfigImplementation.DisableCreateUpdateDeleteToolsInConfig(Rec.SystemId);
                        CurrPage.Update();
                    end;
                }
            }
            part(ToolList; "MCP Config Tool List")
            {
                ApplicationArea = All;
                SubPageLink = ID = field(SystemId);
                UpdatePropagation = Both;
                Visible = not IsDefault;
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(Copy)
            {
                Caption = 'Copy';
                ToolTip = 'Creates a copy of the current MCP configuration, including its tools and permissions.';
                Image = Copy;

                trigger OnAction()
                begin
                    MCPConfigImplementation.CopyConfiguration(Rec.SystemId);
                end;
            }
        }
        area(Processing)
        {
            action(MCPEntraApplications)
            {
                Caption = 'Entra Applications';
                ToolTip = 'View registered Entra applications and their Client IDs for MCP client configuration.';
                Image = Setup;
                RunObject = page "MCP Entra Application List";
            }
            action(GenerateConnectionString)
            {
                Caption = 'Connection String';
                ToolTip = 'Generate a connection string for this MCP configuration to use in your MCP client.';
                Image = Export;

                trigger OnAction()
                begin
                    MCPConfigImplementation.ShowConnectionString(Rec.Name);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Promoted_Copy; Copy) { }
            actionref(Promoted_MCPEntraApplications; MCPEntraApplications) { }
            actionref(Promoted_GenerateConnectionString; GenerateConnectionString) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsDefault := MCPConfigImplementation.IsDefaultConfiguration(Rec);
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        MCPConfigImplementation.LogConfigurationDeleted(Rec);
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        MCPConfigImplementation.LogConfigurationCreated(Rec);
    end;

    trigger OnModifyRecord(): Boolean
    begin
        MCPConfigImplementation.LogConfigurationModified(Rec, xRec);
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsDefault: Boolean;
}