// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4339 "Archived Agents"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = Agent;
    Caption = 'Archived Agents';
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
            repeater(Main)
            {
                field(UserName; Rec."User Name")
                {
                    Caption = 'User Name';
                }
                field(DisplayName; Rec."Display Name")
                {
                    Caption = 'Display Name';
                }
                field(AgentType; Rec."Agent Metadata Provider")
                {
                    Caption = 'Agent type';
                }
                field(State; Rec.State)
                {
                    Caption = 'State';
                }
                field(Substate; Rec.Substate)
                {
                    Caption = 'Substate';
                    ToolTip = 'Specifies whether the agent is archived.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        AgentUtilities.BlockPageFromBeingOpenedByAgent();
        Rec.SetRange(Substate, Rec.Substate::Archived);
    end;
}
