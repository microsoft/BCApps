// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8350 "MCP Config List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Lists;
    SourceTable = "MCP Configuration";
    CardPageId = "MCP Config Card";
    Caption = 'Model Context Protocol (MCP) Server Configurations';
    Editable = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    AnalysisModeEnabled = false;
    SourceTableView = where(Name = filter(<> ''));
    AboutTitle = 'About model context protocol (MCP) server configurations';
    AboutText = 'Get an overview of MCP configurations. You can create multiple configurations to suit different use cases. Each configuration can have its own set of tools and permissions, allowing for flexible management.';

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the MCP configuration.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the MCP configuration.';
                }
                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies whether the MCP configuration is active.';
                }
                field(Default; Rec.Default)
                {
                    ToolTip = 'Specifies whether this configuration is the default. The default configuration is used when no configuration is specified by a connection. Clear this field to remove the default designation, in which case the system reverts to built-in default configuration.';
                    Editable = false;
                }
                field(APITools; Rec.EnableApiTools)
                {
                    Caption = 'API Tools';
                    ToolTip = 'Specifies whether the API Tools feature is enabled for this configuration.';
                    Editable = false;
                }
                field(DataQueryTools; Rec.EnableAlQueryTools)
                {
                    Caption = 'Data Query Tools';
                    ToolTip = 'Specifies whether the Data Query Tools feature is enabled for this configuration.';
                    Editable = false;
                }
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
                Scope = Repeater;

                trigger OnAction()
                begin
                    MCPConfigImplementation.CopyConfiguration(Rec.SystemId);
                end;
            }
        }
        area(Processing)
        {
            action(SetAsDefault)
            {
                Caption = 'Set as Default';
                ToolTip = 'Set this configuration as the default. It will be used when no configuration is specified by a connection.';
                Image = Approve;
                AccessByPermission = tabledata "MCP Configuration" = M;
                Scope = Repeater;
                Enabled = not Rec.Default;

                trigger OnAction()
                var
                    MCPConfigImplementation: Codeunit "MCP Config Implementation";
                begin
                    MCPConfigImplementation.SetAsDefaultConfiguration(Rec.SystemId);
                    CurrPage.Update(false);
                end;
            }
            action(ClearDefault)
            {
                Caption = 'Clear Default';
                ToolTip = 'Remove the default designation from this configuration. The system will revert to built-in default settings.';
                Image = Undo;
                AccessByPermission = tabledata "MCP Configuration" = M;
                Scope = Repeater;
                Enabled = Rec.Default;

                trigger OnAction()
                var
                    MCPConfigImplementation: Codeunit "MCP Config Implementation";
                begin
                    MCPConfigImplementation.ClearDefaultConfiguration();
                    CurrPage.Update(false);
                end;
            }
            action(GiveFeedback)
            {
                Caption = 'Give Feedback';
                ToolTip = 'Share your feedback about the MCP server experience.';
                Image = Comment;

                trigger OnAction()
                begin
                    MCPConfigImplementation.TriggerGeneralFeedback();
                end;
            }
            group(Advanced)
            {
                Caption = 'Advanced';
                Image = Setup;

                action(GenerateConnectionString)
                {
                    Caption = 'Connection String';
                    ToolTip = 'Generate a connection string for this MCP configuration to use in your MCP client.';
                    Image = Link;
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        MCPConfigImplementation.ShowConnectionString(Rec.Name);
                    end;
                }
                action(MCPEntraApplications)
                {
                    Caption = 'Entra Applications';
                    ToolTip = 'View registered Entra applications and their Client IDs for MCP client configuration.';
                    Image = Setup;
                    RunObject = page "MCP Entra Application List";
                }
                action(ExportConfiguration)
                {
                    Caption = 'Export';
                    ToolTip = 'Export the selected MCP configuration and its tools to a JSON file.';
                    Image = Export;
                    Scope = Repeater;

                    trigger OnAction()
                    begin
                        MCPConfigImplementation.ExportConfigurationToFile(Rec.SystemId, Rec.Name);
                    end;
                }
                action(ImportConfiguration)
                {
                    Caption = 'Import';
                    ToolTip = 'Import an MCP configuration and its tools from a JSON file.';
                    Image = Import;
                    AccessByPermission = tabledata "MCP Configuration" = IM;

                    trigger OnAction()
                    begin
                        MCPConfigImplementation.ImportConfigurationFromFile();
                        CurrPage.Update(false);
                    end;
                }
            }
        }
        area(Promoted)
        {
            actionref(Promoted_Copy; Copy) { }
            actionref(Promoted_SetAsDefault; SetAsDefault) { }
            actionref(Promoted_ClearDefault; ClearDefault) { }
            actionref(Promoted_GiveFeedback; GiveFeedback) { }
            actionref(Promoted_ExportConfiguration; ExportConfiguration) { }
            actionref(Promoted_ImportConfiguration; ImportConfiguration) { }
            group(Promoted_Advanced)
            {
                Caption = 'Advanced';

                actionref(Promoted_GenerateConnectionString; GenerateConnectionString) { }
                actionref(Promoted_MCPEntraApplications; MCPEntraApplications) { }
            }
        }
    }

    views
    {
        view(ActiveConfigurations)
        {
            Caption = 'Active configurations';
            Filters = where(Active = const(true));
        }
    }

    trigger OnOpenPage()
    var
        MCPNotifications: Codeunit "MCP Notifications";
    begin
        HadActiveConfigsOnOpen := not MCPConfigImplementation.HasNoActiveConfigurations();
        MCPNotifications.ShowFeatureDisabledIfApplicable();
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if not HadActiveConfigsOnOpen then
            exit;

        if MCPConfigImplementation.HasNoActiveConfigurations() then
            MCPConfigImplementation.TriggerNoActiveConfigsFeedback();
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        HadActiveConfigsOnOpen: Boolean;

}