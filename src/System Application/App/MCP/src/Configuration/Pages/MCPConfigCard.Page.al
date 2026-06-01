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
    AboutText = 'Manage how MCP configurations are set up. Specify which APIs are available as tools, control data access permissions, and enable dynamic discovery of tools. You can also duplicate existing configurations to quickly create new setups. Configurations are read-only when activated to ensure stability.';

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                Caption = 'General';

                group(Column1)
                {
                    ShowCaption = false;

                    field(Name; Rec.Name)
                    {
                        ToolTip = 'Specifies the name of the MCP configuration.';
                        Editable = not IsDefault and not Rec.Active;
                    }
                    field(Description; Rec.Description)
                    {
                        ToolTip = 'Specifies the description of the MCP configuration.';
                        Editable = not IsDefault and not Rec.Active;
                        MultiLine = true;
                    }
                }
                group(Column2)
                {
                    ShowCaption = false;

                    field(Active; Rec.Active)
                    {
                        ToolTip = 'Specifies whether the MCP configuration is active.';
                        Editable = not IsDefault;

                        trigger OnValidate()
                        begin
                            if Rec.Active then
                                MCPConfigImplementation.ValidateConfiguration(Rec, true)
                            else
                                if Rec.Default then
                                    Error(DesignatedDefaultCannotBeDeactivatedErr);
                            RefreshSubPages();
                            CurrPage.Update();
                        end;
                    }
                    field(Default; Rec.Default)
                    {
                        Caption = 'Default';
                        ToolTip = 'Specifies whether this configuration is the default. The default configuration is used when no configuration is specified by a connection. Clear this field to remove the default designation, in which case the system reverts to built-in default configuration.';
                        Editable = not IsDefault;

                        trigger OnValidate()
                        begin
                            if Rec.Default = xRec.Default then
                                exit;

                            if Rec.Default then
                                MCPConfigImplementation.SetAsDefaultConfiguration(Rec.SystemId)
                            else
                                MCPConfigImplementation.ClearDefaultConfiguration();
                        end;
                    }
                    field(AllowProdChanges; Rec.AllowProdChanges)
                    {
                        ToolTip = 'Allows create, update and delete tools for the specified MCP configuration. Disallowing this will make the tools read-only.';
                        Editable = not IsDefault and not Rec.Active;

                        trigger OnValidate()
                        begin
                            if not Rec.AllowProdChanges then
                                MCPConfigImplementation.DisableCreateUpdateDeleteToolsInConfig(Rec.SystemId);
                            CurrPage.Update();
                        end;
                    }
                }
            }
            part(ServerFeatureList; "MCP Server Feature List")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
                Visible = not IsDefault;
                Editable = false;
            }
            part(ToolList; "MCP Config Tool List")
            {
                ApplicationArea = All;
                SubPageLink = ID = field(SystemId);
                UpdatePropagation = Both;
                Visible = not IsDefault and APIToolsActive;
                Editable = not Rec.Active;
            }
        }
        area(FactBoxes)
        {
            part(SystemToolList; "MCP System Tool List")
            {
                ApplicationArea = All;
                UpdatePropagation = Both;
                Visible = not IsDefault;
                Editable = false;
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
                AccessByPermission = tabledata "MCP Configuration" = IM;

                trigger OnAction()
                begin
                    MCPConfigImplementation.CopyConfiguration(Rec.SystemId);
                end;
            }
        }
        area(Processing)
        {
            action(Validate)
            {
                Caption = 'Validate';
                ToolTip = 'Validates the MCP configuration to ensure all settings and tools are correctly configured.';
                Image = ValidateEmailLoggingSetup;

                trigger OnAction()
                begin
                    MCPConfigImplementation.ValidateConfiguration(Rec, false);
                end;
            }
            group(Advanced)
            {
                Caption = 'Advanced';
                Image = Setup;

                action(ExportConfiguration)
                {
                    Caption = 'Export';
                    ToolTip = 'Export the selected MCP configuration and its tools to a JSON file.';
                    Image = Export;

                    trigger OnAction()
                    begin
                        MCPConfigImplementation.ExportConfigurationToFile(Rec.SystemId, Rec.Name);
                    end;
                }

                action(GenerateConnectionString)
                {
                    Caption = 'Connection String';
                    ToolTip = 'Generate a connection string for this MCP configuration to use in your MCP client.';
                    Image = Link;

                    trigger OnAction()
                    begin
                        MCPConfigImplementation.ShowConnectionString(Rec.Name);
                    end;
                }
            }
        }
        area(Promoted)
        {
            actionref(Promoted_Copy; Copy) { }
            actionref(Promoted_Validate; Validate) { }
            group(Promoted_Advanced)
            {
                Caption = 'Advanced';

                actionref(Promoted_GenerateConnectionString; GenerateConnectionString) { }
                actionref(Promoted_ExportConfiguration; ExportConfiguration) { }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsDefault := MCPConfigImplementation.IsDefaultConfiguration(Rec);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        RefreshSubPages();
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
        // MOCK: page-local driving the Available APIs sub-part visibility (a Visible property can't
        // call a method, so we cache IsActive() here in RefreshSubPages). It's fed from the API Tools
        // feature's IsActive(), which today reads the "MCP Feature Activation" stand-in table; once the
        // platform adds the real config field it flips automatically through the impl getter, so the
        // page-local itself stays — only this mock note is removed.
        APIToolsActive: Boolean;
        DesignatedDefaultCannotBeDeactivatedErr: Label 'The designated default configuration cannot be deactivated. Clear the default designation first.';

    local procedure RefreshSubPages()
    var
        ServerFeature: Interface "MCP Server Features";
    begin
        CurrPage.ServerFeatureList.Page.Reload(Rec.SystemId, not IsDefault and not Rec.Active);
        ServerFeature := "MCP Server Feature"::"API Tools";
        APIToolsActive := ServerFeature.IsActive(Rec.SystemId);
        CurrPage.SystemToolList.Page.Reload(Rec.SystemId);
        CurrPage.ToolList.Page.SetConfigActive(Rec.Active);
    end;
}
