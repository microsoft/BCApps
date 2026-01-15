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
                field(Name; Rec.Name)
                {
                    Editable = not IsDefault and not Rec.Active;
                }
                field(Description; Rec.Description)
                {
                    Editable = not IsDefault and not Rec.Active;
                    MultiLine = true;
                }
                field(Active; Rec.Active)
                {
                    Editable = not IsDefault;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QE6', StrSubstNo(SettingConfigurationActiveLbl, Rec.SystemId, Rec.Active), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());

                        if Rec.Active then
                            MCPConfigImplementation.ValidateConfiguration(Rec, true);
                    end;
                }
                field(EnableDynamicToolMode; Rec.EnableDynamicToolMode)
                {
                    Editable = not IsDefault and not Rec.Active;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QE7', StrSubstNo(SettingConfigurationEnableDynamicToolModeLbl, Rec.SystemId, Rec.EnableDynamicToolMode), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());

                        if not Rec.EnableDynamicToolMode then
                            Rec.DiscoverReadOnlyObjects := false;

                        GetToolModeDescription();
                        CurrPage.Update();
                    end;
                }
                field(DiscoverReadOnlyObjects; Rec.DiscoverReadOnlyObjects)
                {
                    Editable = not IsDefault and Rec.EnableDynamicToolMode and not Rec.Active;

                    trigger OnValidate()
                    begin
                        Session.LogMessage('0000QGJ', StrSubstNo(SettingConfigurationDiscoverReadOnlyObjectsLbl, Rec.SystemId, Rec.DiscoverReadOnlyObjects), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
                    end;
                }
                field(AllowProdChanges; Rec.AllowProdChanges)
                {
                    Editable = not IsDefault and not Rec.Active;

                    trigger OnValidate()
                    begin
                        if not Rec.AllowProdChanges then
                            MCPConfigImplementation.DisableCreateUpdateDeleteToolsInConfig(Rec.SystemId);
                        CurrPage.Update();
                        Session.LogMessage('0000QE8', StrSubstNo(SettingConfigurationAllowProdChangesLbl, Rec.SystemId, Rec.AllowProdChanges), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', MCPConfigImplementation.GetTelemetryCategory());
                    end;
                }
            }
            group(Control2)
            {
                Caption = 'Tool Modes';
                ShowCaption = false;

                field(ToolMode; ToolModeLbl)
                {
                    ApplicationArea = All;
                    Editable = false;
                    Caption = 'Tool Mode';
                    ShowCaption = false;
                    MultiLine = true;
                }
            }
            part(SystemToolList; "MCP System Tool List")
            {
                ApplicationArea = All;
                Visible = not IsDefault and Rec.EnableDynamicToolMode;
                Editable = false;
            }
            part(ToolList; "MCP Config Tool List")
            {
                ApplicationArea = All;
                SubPageLink = ID = field(SystemId);
                UpdatePropagation = Both;
                Visible = not IsDefault;
                Editable = not Rec.Active;
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
        }
        area(Promoted)
        {
            actionref(Promoted_Copy; Copy) { }
            actionref(Promoted_Validate; Validate) { }
        }
    }

    trigger OnAfterGetRecord()
    begin
        IsDefault := MCPConfigImplementation.IsDefaultConfiguration(Rec);
        GetToolModeDescription();
    end;

    trigger OnNewRecord(BelowxRec: Boolean)
    begin
        ToolModeLbl := StaticToolModeLbl;
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsDefault: Boolean;
        SettingConfigurationActiveLbl: Label 'Setting MCP configuration %1 Active to %2', Comment = '%1 - configuration ID, %2 - active', Locked = true;
        SettingConfigurationEnableDynamicToolModeLbl: Label 'Setting MCP configuration %1 EnableDynamicToolMode to %2', Comment = '%1 - configuration ID, %2 - enable dynamic tool mode', Locked = true;
        SettingConfigurationAllowProdChangesLbl: Label 'Setting MCP configuration %1 AllowProdChanges to %2', Comment = '%1 - configuration ID, %2 - allow production changes', Locked = true;
        SettingConfigurationDiscoverReadOnlyObjectsLbl: Label 'Setting MCP configuration %1 DiscoverReadOnlyObjects to %2', Comment = '%1 - configuration ID, %2 - allow read-only API discovery', Locked = true;
        ToolModeLbl: Text;
        StaticToolModeLbl: Label 'In Static Tool Mode, objects in the available tools will be directly exposed to clients. You can manage these tools by adding, modifying, or removing them from the configuration.';
        DynamicToolModeLbl: Label 'In Dynamic Tool Mode, only system tools will be exposed to clients. Objects within the available tools can be discovered, described and invoked dynamically using system tools. You can enable dynamic discovery of any read-only object outside of the available tools using Discover Additional Objects setting.';

    local procedure GetToolModeDescription(): Text
    begin
        ToolModeLbl := Rec.EnableDynamicToolMode ? DynamicToolModeLbl : StaticToolModeLbl;
    end;
}