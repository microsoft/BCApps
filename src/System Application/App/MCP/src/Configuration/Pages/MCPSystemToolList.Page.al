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

    trigger OnOpenPage()
    begin
        LoadSystemTools();
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsLoaded: Boolean;

    local procedure LoadSystemTools()
    begin
        if IsLoaded then
            exit;

        IsLoaded := true;
        MCPConfigImplementation.LoadSystemTools(Rec);
    end;
}