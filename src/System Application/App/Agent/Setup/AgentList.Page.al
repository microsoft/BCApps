// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

page 4316 "Agent List"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Agent";
    Caption = 'Agents (Preview)';
    CardPageId = "Agent Card";
    AdditionalSearchTerms = 'Agent, Agents, Copilot, Automation, AI';
    Editable = false;
    InsertAllowed = false;
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
                field(State; Rec.State)
                {
                    Caption = 'State';
                }
            }
        }
    }
    actions
    {
        area(Processing)
        {
            action(AgentSetup)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Setup';
                ToolTip = 'Set up the agent';
                Image = SetupLines;

                trigger OnAction()
                var
                    Agent: Codeunit Agent;
                begin
                    if Rec.IsEmpty() then
                        Error(NoAgentSetupErr);

                    Agent.OpenSetupPageId(Rec."Agent Metadata Provider", Rec."User Security ID");
                    CurrPage.Update(false);
                end;
            }
            action(AgentTasks)
            {
                ApplicationArea = All;
                Caption = 'Agent Tasks';
                ToolTip = 'View agent tasks';
                Image = Log;

                trigger OnAction()
                var
                    AgentTask: Record "Agent Task";
                begin
                    if Rec.IsEmpty() then
                        Error(NoAgentSetupErr);
                    AgentTask.SetRange("Agent User Security ID", Rec."User Security ID");
                    Page.Run(Page::"Agent Task List", AgentTask);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                actionref(AgentSetup_Promoted; AgentSetup)
                {
                }
                actionref(AgentTasks_Promoted; AgentTasks)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        AgentImpl: Codeunit "Agent Impl.";
        AgentSessionImpl: Codeunit "Agent Session Impl.";
        AgentMetadataProvider: Enum "Agent Metadata Provider";
    begin
        AgentSessionImpl.BlockPageFromBeingOpenedByAgent();
        // Check if there are any agents available
        if AgentMetadataProvider.Names().Count() = 0 then
            AgentImpl.ShowNoAgentsAvailableNotification();
    end;

    var
        NoAgentSetupErr: Label 'No agents have been setup. You must set up an agent first.';
}