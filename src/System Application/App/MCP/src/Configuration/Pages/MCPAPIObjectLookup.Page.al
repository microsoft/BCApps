// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8376 "MCP API Object Lookup"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "MCP API Object Buffer";
    SourceTableTemporary = true;
    Caption = 'Select APIs';
    Extensible = false;
    Editable = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    DeleteAllowed = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                field("Object Type"; Rec."Object Type")
                {
                    ToolTip = 'Specifies whether the object is an API page or an API query.';
                }
                field("Object ID"; Rec."Object ID")
                {
                    ToolTip = 'Specifies the object ID.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the object.';
                }
                field("Entity Name"; Rec."Entity Name")
                {
                    ToolTip = 'Specifies the entity name of the object.';
                }
                field("API Publisher"; Rec."API Publisher")
                {
                    ToolTip = 'Specifies the API publisher of the object.';
                }
                field("API Group"; Rec."API Group")
                {
                    ToolTip = 'Specifies the API group of the object.';
                }
                field("API Version"; Rec."API Version")
                {
                    ToolTip = 'Specifies the API version of the object.';
                }
            }
        }
    }

    internal procedure SetObjects(var MCPAPIObjectBuffer: Record "MCP API Object Buffer")
    begin
        Rec.Copy(MCPAPIObjectBuffer, true);
    end;

    internal procedure GetSelectedObjects(var MCPAPIObjectBuffer: Record "MCP API Object Buffer")
    begin
        CurrPage.SetSelectionFilter(Rec);
        if Rec.FindSet() then
            repeat
                MCPAPIObjectBuffer := Rec;
                if MCPAPIObjectBuffer.Insert() then;
            until Rec.Next() = 0;
    end;
}
