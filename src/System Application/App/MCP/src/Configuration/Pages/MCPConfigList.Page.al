// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

#if not CLEAN28
using System.Environment.Configuration;
#endif

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
                field(EnableDynamicToolMode; Rec.EnableDynamicToolMode)
                {
                    ToolTip = 'Specifies whether to enable dynamic tool mode for this MCP configuration. When enabled, clients can search for tools within the configuration dynamically.';
                }
                field(DiscoverReadOnlyObjects; Rec.DiscoverReadOnlyObjects)
                {
                    ToolTip = 'Specifies whether to allow discovery of read-only objects not defined in the configuration. Only supported with dynamic tool mode.';
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
                var
                    MCPConfigImplementation: Codeunit "MCP Config Implementation";
                begin
                    MCPConfigImplementation.CopyConfiguration(Rec.SystemId);
                end;
            }
        }
        area(Processing)
        {
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
                    var
                        MCPConfigImplementation: Codeunit "MCP Config Implementation";
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
                    var
                        MCPConfigImplementation: Codeunit "MCP Config Implementation";
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
                    var
                        MCPConfigImplementation: Codeunit "MCP Config Implementation";
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
            group(Promoted_Advanced)
            {
                Caption = 'Advanced';

                actionref(Promoted_GenerateConnectionString; GenerateConnectionString) { }
                actionref(Promoted_MCPEntraApplications; MCPEntraApplications) { }
                actionref(Promoted_ExportConfiguration; ExportConfiguration) { }
                actionref(Promoted_ImportConfiguration; ImportConfiguration) { }
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

#if not CLEAN28
    trigger OnOpenPage()
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        FeatureNotEnabledErrorInfo: ErrorInfo;
    begin
        if MCPConfigImplementation.IsFeatureEnabled() then
            exit;

        FeatureNotEnabledErrorInfo.Message := FeatureNotEnabledErr;
        FeatureNotEnabledErrorInfo.AddNavigationAction(GoToFeatureManagementLbl);
        FeatureNotEnabledErrorInfo.PageNo := Page::"Feature Management";
        Error(FeatureNotEnabledErrorInfo);
    end;

    var
        FeatureNotEnabledErr: Label 'MCP server feature is not enabled. Please contact your system administrator to enable the feature.';
        GoToFeatureManagementLbl: Label 'Go to Feature Management';
#endif

}