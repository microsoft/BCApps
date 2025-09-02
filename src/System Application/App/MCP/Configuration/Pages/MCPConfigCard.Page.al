// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

page 8201 "MCP Config Card"
{
    ApplicationArea = All;
    PageType = Card;
    SourceTable = "MCP Configuration";
    Caption = 'MCP Configuration';
    Extensible = false;

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                Caption = 'General';
                field(SystemId; Rec.SystemId)
                {
                    Caption = 'Id';
                    Editable = false;
                    ToolTip = 'Specifies the unique identifier for the MCP configuration.';
                }
                field(Name; Rec.Name)
                {
                }
                field(Description; Rec.Description)
                {
                }
                field(Active; Rec.Active)
                {
                }
                field(EnableDynamicToolMode; Rec.EnableDynamicToolMode)
                {
                }
            }
            part(ToolList; "MCP Config Tool List")
            {
                ApplicationArea = All;
                SubPageLink = "Config Id" = field(SystemId);
                UpdatePropagation = Both;
            }
        }
    }
}