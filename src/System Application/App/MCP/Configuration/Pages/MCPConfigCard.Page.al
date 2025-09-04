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
                    ToolTip = 'Specifies the unique identifier for the MCP configuration. Use this ID to setup your MCP clients.';
                }
                field(Name; Rec.Name)
                {
                    ToolTip = 'Specifies the name of the MCP configuration.';
                }
                field(Description; Rec.Description)
                {
                    ToolTip = 'Specifies the description of the MCP configuration.';
                }
                field(Active; Rec.Active)
                {
                    ToolTip = 'Specifies whether the MCP configuration is active.';
                }
                field(UseToolSearchMode; Rec.UseToolSearchMode)
                {
                    ToolTip = 'Specifies whether to enable tool search mode for this MCP configuration. When enabled, clients can search for tools dynamically.';
                }
                field(AllowProdChanges; Rec.AllowProdChanges)
                {
                    ToolTip = 'Specifies whether to allow production changes for this MCP configuration. When disabled, create, modify, and delete operations in production environments are restricted.';
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