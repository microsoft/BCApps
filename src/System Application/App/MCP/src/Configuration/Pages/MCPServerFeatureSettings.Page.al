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
                    Caption = 'Discover Additional Read-Only Objects';
                    ToolTip = 'Specifies whether to allow discovery of read-only objects not defined in the configuration.';
                    Visible = Feature = Feature::"Dynamic Tool Mode";
                }
                // MOCK: page-local stand-ins for the AL Query Tools sub-settings until the platform
                // adds real fields on MCP Configuration. Reset every time the dialog opens.
                field(MaxRowsPerQuery; MaxRowsPerQueryLocal)
                {
                    Caption = 'Maximum Rows per Query';
                    ToolTip = 'Specifies the maximum number of rows a single AL query may return.';
                    Visible = Feature = Feature::"AL Query Tools";
                }
                field(QueryTimeoutSeconds; QueryTimeoutSecondsLocal)
                {
                    Caption = 'Query Timeout (seconds)';
                    ToolTip = 'Specifies the maximum execution time for a single AL query, in seconds.';
                    Visible = Feature = Feature::"AL Query Tools";
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
        if MaxRowsPerQueryLocal = 0 then
            MaxRowsPerQueryLocal := 10000;
        if QueryTimeoutSecondsLocal = 0 then
            QueryTimeoutSecondsLocal := 30;
        UpdateCaption();
    end;

    var
        ConfigSystemId: Guid;
        Feature: Enum "MCP Server Feature";
        DiscoverReadOnlyObjectsLocal: Boolean;
        MaxRowsPerQueryLocal: Integer;
        QueryTimeoutSecondsLocal: Integer;

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
            Feature::"API Tools":
                ;
            Feature::"AL Query Tools":
                ;
        // MOCK: nothing to persist for AL Query Tools while its sub-settings are page-local.
        // When the platform-side fields land, write the locals back here via the facade, e.g.:
        //   MCPConfig.SetALQueryMaxRowsPerQuery(ConfigSystemId, MaxRowsPerQueryLocal);
        //   MCPConfig.SetALQueryTimeoutSeconds(ConfigSystemId, QueryTimeoutSecondsLocal);
        end;
    end;

    local procedure UpdateCaption()
    var
        SettingsForLbl: Label '%1 Settings', Comment = '%1 = the name of the server feature';
    begin
        CurrPage.Caption(StrSubstNo(SettingsForLbl, Format(Feature)));
    end;
}
