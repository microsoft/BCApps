// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.MCP;

using System.Agents;

page 8377 "MCP Agent Lookup"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = Agent;
    Caption = 'Select Agents';
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
                field("Agent User Name"; Rec."User Name")
                {
                    Caption = 'Agent User Name';
                    ToolTip = 'Specifies the user name of the agent.';
                }
                field("Display Name"; Rec."Display Name")
                {
                    Caption = 'Display Name';
                    ToolTip = 'Specifies the display name of the agent.';
                }
                field(Company; CurrentCompanyName)
                {
                    Caption = 'Company';
                    Editable = false;
                    ToolTip = 'Specifies the company in which the agent is available.';
                }
            }
        }
    }

    trigger OnOpenPage()
    begin
        CurrentCompanyName := CopyStr(CompanyName(), 1, MaxStrLen(CurrentCompanyName));
        MCPConfigImplementation.SetEligibleAgentFilters(Rec);
    end;

    var
        MCPConfigImplementation: Codeunit "MCP Config Implementation";
        CurrentCompanyName: Text[30];

    internal procedure GetSelectedAgents(var SelectedAgent: Record Agent)
    begin
        Clear(SelectedAgent);
        CurrPage.SetSelectionFilter(SelectedAgent);
    end;
}
