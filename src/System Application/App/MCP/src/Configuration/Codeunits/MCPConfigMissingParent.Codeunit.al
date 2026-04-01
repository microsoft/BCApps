// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Reflection;

codeunit 8354 "MCP Config Missing Parent" implements "MCP Config Warning"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MissingParentWarningLbl: Label 'This API page is missing parent page(s): %1', Comment = '%1 = comma-separated list of missing parent page IDs';
        MissingParentFixLbl: Label 'Add the parent API pages to the configuration.';

    procedure CheckForWarnings(ConfigId: Guid; var MCPConfigWarning: Record "MCP Config Warning"; var EntryNo: Integer)
    var
        MCPConfigurationTool: Record "MCP Configuration Tool";
        PageMetadata: Record "Page Metadata";
        MCPUtilities: Codeunit "MCP Utilities";
        PageIdVersions: Dictionary of [Integer, Text];
        ParentMCPTools: Dictionary of [Integer, List of [Integer]];
        ParentPageIds: List of [Integer];
        MissingParentIds: List of [Integer];
        PageId: Integer;
        ParentPageId: Integer;
        MissingParentsText: Text;
    begin
        // Build dictionary of page IDs and API versions from configuration tools
        MCPConfigurationTool.SetRange(ID, ConfigId);
        MCPConfigurationTool.SetRange("Object Type", MCPConfigurationTool."Object Type"::Page);
        if not MCPConfigurationTool.FindSet() then
            exit;

        repeat
            if PageMetadata.Get(MCPConfigurationTool."Object ID") then
                if PageMetadata.PageType = PageMetadata.PageType::API then
                    PageIdVersions.Add(MCPConfigurationTool."Object ID", MCPConfigurationTool."API Version");
        until MCPConfigurationTool.Next() = 0;

        // Get parent mappings from platform
        ParentMCPTools := MCPUtilities.GetParentMCPTools(PageIdVersions);

        // Check each page with parents for missing parent tools
        foreach PageId in ParentMCPTools.Keys() do begin
            ParentPageIds := ParentMCPTools.Get(PageId);
            Clear(MissingParentIds);

            // Check if each parent exists in the configuration
            foreach ParentPageId in ParentPageIds do
                if not PageIdVersions.ContainsKey(ParentPageId) then
                    MissingParentIds.Add(ParentPageId);

            // Create warning if there are missing parents
            if MissingParentIds.Count() > 0 then begin
                // Get the tool record to retrieve its SystemId
                MCPConfigurationTool.Get(ConfigId, MCPConfigurationTool."Object Type"::Page, PageId);

                MissingParentsText := FormatPageIdList(MissingParentIds);
                MCPConfigWarning."Entry No." := EntryNo;
                MCPConfigWarning."Config Id" := ConfigId;
                MCPConfigWarning."Tool Id" := MCPConfigurationTool.SystemId;
                MCPConfigWarning."Warning Type" := MCPConfigWarning."Warning Type"::"Missing Parent Object";
                MCPConfigWarning."Additional Info" := CopyStr(MissingParentsText, 1, MaxStrLen(MCPConfigWarning."Additional Info"));
                MCPConfigWarning.Insert();
                EntryNo += 1;
            end;
        end;
    end;

    procedure WarningMessage(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(StrSubstNo(MissingParentWarningLbl, MCPConfigWarning."Additional Info"));
    end;

    procedure RecommendedAction(MCPConfigWarning: Record "MCP Config Warning"): Text
    begin
        exit(MissingParentFixLbl);
    end;

    procedure ApplyRecommendedAction(var MCPConfigWarning: Record "MCP Config Warning")
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        PageIdList: List of [Text];
        PageIdText: Text;
        PageId: Integer;
    begin
        if MCPConfigWarning."Additional Info" = '' then
            exit;

        // Parse comma-separated page IDs and add each as a tool
        PageIdList := MCPConfigWarning."Additional Info".Split(',');
        foreach PageIdText in PageIdList do
            if Evaluate(PageId, PageIdText.Trim()) then
                if not MCPConfigImplementation.CheckAPIToolExists(MCPConfigWarning."Config Id", PageId) then
                    MCPConfigImplementation.CreateAPITool(MCPConfigWarning."Config Id", PageId, false);

        MCPConfigWarning.Delete();
    end;

    local procedure FormatPageIdList(PageIds: List of [Integer]): Text
    var
        PageId: Integer;
        Result: TextBuilder;
    begin
        foreach PageId in PageIds do begin
            Result.Append(Format(PageId));
            Result.Append(', ');
        end;
        exit(Result.ToText().TrimEnd(', '));
    end;
}
