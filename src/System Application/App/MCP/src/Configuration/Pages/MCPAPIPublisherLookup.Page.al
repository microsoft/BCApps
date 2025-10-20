// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8356 "MCP API Publisher Lookup"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "MCP API Publisher Group";
    Caption = 'API Publishers';
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
                field("API Publisher"; Rec."API Publisher")
                {
                    Caption = 'API Publisher';
                    ToolTip = 'Specifies the API publisher.';
                }
                field("API Group"; Rec."API Group")
                {
                    Caption = 'API Group';
                    ToolTip = 'Specifies the API group.';
                }
            }
        }
    }
}