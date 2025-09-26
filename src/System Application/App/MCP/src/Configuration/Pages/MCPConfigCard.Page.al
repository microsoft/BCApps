// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Environment;

page 8351 "MCP Config Card"
{
    ApplicationArea = All;
    PageType = Card;
    SourceTable = "MCP Configuration";
    Caption = 'MCP Configuration';
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;

    layout
    {
        area(Content)
        {
            group(Control1)
            {
                Caption = 'General';
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
                field(EnableDynamicToolMode; Rec.EnableDynamicToolMode)
                {
                    ToolTip = 'Specifies whether to enable dynamic tool mode for this MCP configuration. When enabled, clients can search for tools dynamically.';
                }
                field(AllowProdChanges; Rec.AllowProdChanges)
                {
                    ToolTip = 'Specifies whether to allow production changes for this MCP configuration. When disabled, create, modify, and delete operations in production environments are restricted.';
                    Visible = not IsSandbox;
                }
            }
            part(ToolList; "MCP Config Tool List")
            {
                ApplicationArea = All;
                SubPageLink = ID = field(SystemId);
                UpdatePropagation = Both;
            }
        }
    }

    actions
    {
        area(Creation)
        {
            action(Copy)
            {
                Caption = 'Copy';
                ToolTip = 'Creates a copy of the current MCP configuration, including its tools and permissions.';
                Image = Copy;

                trigger OnAction()
                begin
                    MCPConfigImplementation.CopyConfiguration(Rec.SystemId);
                end;
            }
        }
        area(Promoted)
        {
            actionref(Promoted_Copy; Copy) { }
        }
    }

    trigger OnOpenPage()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        IsSandbox := EnvironmentInformation.IsSandbox();
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsSandbox: Boolean;
}