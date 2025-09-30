// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Environment;

page 8351 "MCP Config Card"
{
    ApplicationArea = All;
    PageType = Card;
    SourceTable = "MCP Configuration";
    Caption = 'MCP Configuration';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

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
                    ToolTip = 'Specifies whether to enable dynamic tool mode for this MCP configuration. When enabled, clients can search for tools within the configuration dynamically.';
                    Editable = not IsDefault;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QE7', StrSubstNo(SettingConfigurationEnableDynamicToolModeLbl, Rec.SystemId, Rec.EnableDynamicToolMode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
                    end;
                }
                field(AllowReadOnlyAPIDiscovery; Rec.AllowReadOnlyAPIDiscovery)
                {
                    ToolTip = 'Specifies whether to allow access to all read-only objects for this MCP configuration.';
                    Editable = not IsDefault;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('', StrSubstNo(SettingConfigurationAllowReadOnlyAPIDiscoveryLbl, Rec.SystemId, Rec.AllowReadOnlyAPIDiscovery), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
                    end;
                }
                field(AllowProdChanges; Rec.AllowProdChanges)
                {
                    ToolTip = 'Specifies whether to allow production changes for this MCP configuration. When disabled, create, modify, and delete operations in production environments are restricted.';
                    Visible = not IsSandbox;

                    trigger OnValidate()
                    begin
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

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsSandbox := EnvironmentInformation.IsSandbox();
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsSandbox: Boolean;
        IsDefault: Boolean;
        SettingConfigurationActiveLbl: Label 'Setting MCP configuration %1 Active to %2', Comment = '%1 - configuration ID, %2 - active', Locked = true;
        SettingConfigurationEnableDynamicToolModeLbl: Label 'Setting MCP configuration %1 EnableDynamicToolMode to %2', Comment = '%1 - configuration ID, %2 - enable dynamic tool mode', Locked = true;
        SettingConfigurationAllowProdChangesLbl: Label 'Setting MCP configuration %1 AllowProdChanges to %2', Comment = '%1 - configuration ID, %2 - allow production changes', Locked = true;
        SettingConfigurationAllowReadOnlyAPIDiscoveryLbl: Label 'Setting MCP configuration %1 AllowReadOnlyAPIDiscovery to %2', Comment = '%1 - configuration ID, %2 - allow read-only API discovery', Locked = true;
}