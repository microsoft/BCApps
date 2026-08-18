// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8365 "MCP System Tool List"
{
    Caption = 'System Tools';
    ApplicationArea = All;
    PageType = ListPart;
    SourceTable = "MCP System Tool";
    SourceTableTemporary = true;
    SourceTableView = sorting("Server Feature", "Tool Name");
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Tool Name"; Rec."Tool Name") { }
                field("Tool Description"; Rec."Tool Description") { }
            }
        }
    }

    internal procedure Reload(ConfigSystemId: Guid)
    var
        ServerFeature: Interface "MCP Server Features";
        ServerFeatureEnum: Enum "MCP Server Feature";
        FeatureImplementations: List of [Integer];
        FeatureImplementation: Integer;
    begin
        Rec.Reset();
        Rec.DeleteAll();
        FeatureImplementations := ServerFeatureEnum.Ordinals();
        foreach FeatureImplementation in FeatureImplementations do begin
            ServerFeature := "MCP Server Feature".FromInteger(FeatureImplementation);
            if ServerFeature.IsActive(ConfigSystemId) then
                ServerFeature.LoadSystemTools(Rec);
        end;
        if Rec.FindFirst() then;
    end;
}
