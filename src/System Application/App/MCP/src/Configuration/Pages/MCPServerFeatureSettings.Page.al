// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8369 "MCP Server Feature Settings"
{
    Caption = 'Server Feature Settings';
    PageType = StandardDialog;
    ApplicationArea = All;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Settings)
            {
                ShowCaption = false;

                field(DiscoverReadOnlyObjects; DiscoverReadOnlyObjectsLocal)
                {
                    Caption = 'Discover Read-Only Objects';
                    ToolTip = 'Specifies whether to allow discovery of read-only objects not defined in the configuration.';
                    Visible = Feature = Feature::"Dynamic Tool Mode";
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
        }
    }

    trigger OnOpenPage()
    var
        ParentConfig: Record "MCP Configuration";
    begin
        if ParentConfig.GetBySystemId(ConfigSystemId) then
            DiscoverReadOnlyObjectsLocal := ParentConfig.DiscoverReadOnlyObjects;
        UpdateCaption();
    end;

    var
        ConfigSystemId: Guid;
        Feature: Enum "MCP Server Feature";
        DiscoverReadOnlyObjectsLocal: Boolean;

    internal procedure SetContext(NewConfigSystemId: Guid; NewFeature: Enum "MCP Server Feature")
    begin
        ConfigSystemId := NewConfigSystemId;
        Feature := NewFeature;
    end;

    internal procedure SaveChanges()
    var
        ParentConfig: Record "MCP Configuration";
    begin
        case Feature of
            Feature::"Dynamic Tool Mode":
                begin
                    if not ParentConfig.GetBySystemId(ConfigSystemId) then
                        exit;
                    ParentConfig.DiscoverReadOnlyObjects := DiscoverReadOnlyObjectsLocal;
                    ParentConfig.Modify(true);
                end;
        end;
    end;

    local procedure UpdateCaption()
    var
        SettingsForLbl: Label '%1 Settings', Comment = '%1 = the name of the server feature';
    begin
        CurrPage.Caption(StrSubstNo(SettingsForLbl, Format(Feature)));
    end;
}
