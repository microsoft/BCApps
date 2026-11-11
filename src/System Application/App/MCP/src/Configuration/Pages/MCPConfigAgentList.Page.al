// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Agents;
using System.Security.AccessControl;

page 8378 "MCP Config Agent List"
{
    Caption = 'Available Agents';
    ApplicationArea = All;
    PageType = ListPart;
    SourceTable = "MCP Configuration Agent";
    InsertAllowed = false;
    Extensible = false;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata User = r;

    layout
    {
        area(Content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field(AgentUserName; AgentUserName)
                {
                    Caption = 'Agent User Name';
                    Editable = false;
                    ToolTip = 'Specifies the user name of the configured agent.';
                }
                field("Agent Name"; Rec."Agent Name")
                {
                    Editable = false;
                    ToolTip = 'Specifies the name of the configured agent.';
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

    trigger OnAfterGetRecord()
    var
        User: Record User;
    begin
        Clear(AgentUserName);
        if User.Get(Rec."Agent ID") then
            AgentUserName := User."User Name";
    end;

    internal procedure SetConfigActive(IsActive: Boolean)
    begin
        IsConfigActive := IsActive;
        CurrPage.Editable(not IsConfigActive);
    end;

    var
        MCPConfig: Codeunit "MCP Config";
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        AgentUserName: Code[50];
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
                if IsNullGuid(MCPConfig.GetAgentToolId(Rec.ID, SelectedAgent."User Security ID")) then
                    MCPConfig.CreateAgentTool(Rec.ID, SelectedAgent."User Security ID");
            until SelectedAgent.Next() = 0;
        CurrPage.Update();
    end;
}
