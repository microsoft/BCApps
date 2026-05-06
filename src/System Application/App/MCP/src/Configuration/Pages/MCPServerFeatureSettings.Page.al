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

                // MOCK: page-local placeholders for AL Query Server settings. The real fields belong on
                // MCP Configuration once the platform adds them. Remove this group when that happens.
                field(MaxRowsPerQuery; MaxRowsPerQueryLocal)
                {
                    Caption = 'Maximum Rows per Query';
                    ToolTip = 'Specifies the maximum number of rows a single AL query may return.';
                    Visible = Feature = Feature::"AL Query Server";
                }
                field(QueryTimeoutSeconds; QueryTimeoutSecondsLocal)
                {
                    Caption = 'Query Timeout (seconds)';
                    ToolTip = 'Specifies the maximum execution time for a single AL query, in seconds.';
                    Visible = Feature = Feature::"AL Query Server";
                }
                field(AllowedObjectScope; AllowedObjectScopeLocal)
                {
                    Caption = 'Allowed Object Scope';
                    OptionCaption = 'All Read-Only Objects,Configured API Tools Only,Custom...';
                    ToolTip = 'Specifies which objects the AL Query server may read.';
                    Visible = Feature = Feature::"AL Query Server";
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        if MaxRowsPerQueryLocal = 0 then
            MaxRowsPerQueryLocal := 10000;
        if QueryTimeoutSecondsLocal = 0 then
            QueryTimeoutSecondsLocal := 30;
        UpdateCaption();
    end;

    var
        ConfigSystemId: Guid;
        Feature: Enum "MCP Server Feature";
        // MOCK: page-local mock storage. Resets each time the dialog is opened. Replace with real
        // MCP Configuration fields once the platform supplies them, then drop these locals.
        MaxRowsPerQueryLocal: Integer;
        QueryTimeoutSecondsLocal: Integer;
        AllowedObjectScopeLocal: Option "All Read-Only Objects","Configured API Tools Only","Custom...";

    internal procedure SetContext(NewConfigSystemId: Guid; NewFeature: Enum "MCP Server Feature")
    begin
        ConfigSystemId := NewConfigSystemId;
        Feature := NewFeature;
    end;

    internal procedure SaveChanges()
    begin
        // MOCK: nothing to persist while AL Query settings are page-local. Hook real writes here when
        // the platform-side fields land (e.g., ParentConfig.GetBySystemId + Modify per feature).
        case Feature of
            Feature::"AL Query Server":
                ;
        end;
    end;

    local procedure UpdateCaption()
    var
        SettingsForLbl: Label '%1 Settings', Comment = '%1 = the name of the server feature';
    begin
        CurrPage.Caption(StrSubstNo(SettingsForLbl, Format(Feature)));
    end;
}
