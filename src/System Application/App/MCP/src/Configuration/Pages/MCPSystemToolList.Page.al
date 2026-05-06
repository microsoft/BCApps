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
                field("Server Feature"; Rec."Server Feature") { }
                field("Tool Name"; Rec."Tool Name") { }
                field("Tool Description"; Rec."Tool Description") { }
            }
        }
    }

    internal procedure Reload(IncludeAPITools: Boolean; IncludeALQuery: Boolean)
    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
    begin
        MCPConfigImplementation.LoadSystemTools(Rec, IncludeAPITools, IncludeALQuery);
        if Rec.FindFirst() then;
    end;
}
