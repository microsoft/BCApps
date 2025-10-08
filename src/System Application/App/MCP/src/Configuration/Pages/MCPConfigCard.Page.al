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
                    ToolTip = 'Specifies the name of the MCP configuration.';
                    Editable = not IsDefault;
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the MCP configuration.';
                    Editable = not IsDefault;
                }
                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies whether the MCP configuration is active.';
                    Editable = not IsDefault;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QE6', StrSubstNo(SettingConfigurationActiveLbl, Rec.SystemId, Rec.Active), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
                    end;
                }
                field(EnableDynamicToolMode; Rec.EnableDynamicToolMode)
                {
                    Caption = 'Dynamic Tool Mode';
                    ToolTip = 'Specifies whether to enable dynamic tool mode for this MCP configuration. When enabled, clients can search for tools within the configuration dynamically.';
                    Editable = not IsDefault;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QE7', StrSubstNo(SettingConfigurationEnableDynamicToolModeLbl, Rec.SystemId, Rec.EnableDynamicToolMode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());

                        if not Rec.EnableDynamicToolMode then
                            Rec.DiscoverReadOnlyObjects := false;
                    end;
                }
                field(DiscoverReadOnlyObjects; Rec.DiscoverReadOnlyObjects)
                {
                    Caption = 'Discover Additional Objects';
                    ToolTip = 'Specifies whether to allow discovery of read-only objects not defined in the configuration. Only supported with dynamic tool mode.';
                    Editable = not IsDefault and Rec.EnableDynamicToolMode;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QGJ', StrSubstNo(SettingConfigurationDiscoverReadOnlyObjectsLbl, Rec.SystemId, Rec.DiscoverReadOnlyObjects), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
                    end;
                }
                field(AllowProdChanges; Rec.AllowProdChanges)
                {
                    Caption = 'Allow Create/Update/Delete Tools';
                    ToolTip = 'Specifies whether to allow create, update and delete tools for this MCP configuration.';

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                        Session.LogMessage('0000QE8', StrSubstNo(SettingConfigurationAllowProdChangesLbl, Rec.SystemId, Rec.AllowProdChanges), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
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
        area(Promoted)
        {
            actionref(Promoted_Copy; Copy) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsDefault := MCPConfigImplementation.IsDefaultConfiguration(Rec);
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsDefault: Boolean;
        SettingConfigurationActiveLbl: Label 'Setting MCP configuration %1 Active to %2', Comment = '%1 - configuration ID, %2 - active', Locked = true;
        SettingConfigurationEnableDynamicToolModeLbl: Label 'Setting MCP configuration %1 EnableDynamicToolMode to %2', Comment = '%1 - configuration ID, %2 - enable dynamic tool mode', Locked = true;
        SettingConfigurationAllowProdChangesLbl: Label 'Setting MCP configuration %1 AllowProdChanges to %2', Comment = '%1 - configuration ID, %2 - allow production changes', Locked = true;
        SettingConfigurationDiscoverReadOnlyObjectsLbl: Label 'Setting MCP configuration %1 DiscoverReadOnlyObjects to %2', Comment = '%1 - configuration ID, %2 - allow read-only API discovery', Locked = true;
}