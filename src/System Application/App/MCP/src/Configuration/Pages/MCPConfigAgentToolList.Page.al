// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Agents;

page 8378 "MCP Config Agent Tool List"
{
    Caption = 'Available Agents';
    ApplicationArea = All;
    PageType = ListPart;
    SourceTable = "MCP Config Agent Tool";
    DelayedInsert = true;
    MultipleNewLines = true;
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
                field("Agent User Security ID"; Rec."Agent User Security ID")
                {
                    Editable = not IsConfigActive;
                    ToolTip = 'Specifies the security ID of the configured agent.';

                    trigger OnLookup(var Text: Text): Boolean
                    begin
                        AddAgents();
                    end;
                }
                field("Agent User Name"; Rec."Agent User Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the user name of the configured agent.';
                }
                field("Agent Display Name"; Rec."Agent Display Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the display name of the configured agent.';
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(SelectAgents)
            {
                Caption = 'Select Agents';
                Ellipsis = true;
                Image = Resource;
                ToolTip = 'Opens a lookup to select agents to add to this configuration.';
                Enabled = not IsConfigActive;

                trigger OnAction()
                begin
                    AddAgents();
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        SetConfigActive(MCPConfigImplementation.IsConfigurationActive(Rec.ID));
    end;

    internal procedure SetConfigActive(IsActive: Boolean)
    begin
        IsConfigActive := IsActive;
        CurrPage.Editable(not IsConfigActive);
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        IsConfigActive: Boolean;

    local procedure AddAgents()
    var
        SelectedAgent: Record Agent;
        MCPAgentLookup: Page "MCP Agent Lookup";
    begin
        MCPAgentLookup.LookupMode(true);
        if MCPAgentLookup.RunModal() <> Action::LookupOK then
            exit;

        MCPAgentLookup.GetSelectedAgents(SelectedAgent);
        if SelectedAgent.FindSet() then
            repeat
                MCPConfigImplementation.AddAgentTool(Rec.ID, SelectedAgent."User Security ID");
            until SelectedAgent.Next() = 0;
        if IsNullGuid(Rec."Agent User Security ID") and not IsNullGuid(Rec.SystemId) then
            Rec.Delete();
        CurrPage.Update();
    end;
}
