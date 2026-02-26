// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestLibraries.Agents;

using System.Agents;
using System.TestTools.AITestToolkit;

pageextension 149034 "Agent Test Suite" extends "AIT Test Suite"
{
    layout
    {
        addafter("Test Runner Id")
        {
            field(TestSuiteAgent; AgentUserName)
            {
                Visible = IsAgentTestType;
                ApplicationArea = All;
                Caption = 'Agent';
                ToolTip = 'Specifies the agent to be used by the tests.';

                trigger OnValidate()
                begin
                    ValidateAgentName();
                end;

                trigger OnAssistEdit()
                begin
                    LookupAgent();
                end;
            }
        }
        addlast("Latest Run")
        {
            field("Copilot Credits"; CopilotCredits)
            {
                Visible = IsAgentTestType;
                ApplicationArea = All;
                AutoFormatType = 0;
                Editable = false;
                Caption = 'Copilot credits';
                ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks in the current version.';
            }
            field("Agent Task Count"; AgentTaskCount)
            {
                Visible = IsAgentTestType;
                ApplicationArea = All;
                Editable = false;
                Caption = 'Agent tasks';
                ToolTip = 'Specifies the number of Agent Tasks related to the current version.';

                trigger OnDrillDown()
                begin
                    AgentTestContextImpl.OpenAgentTaskList(AgentTaskIDs);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAgentTaskMetrics();
        UpdateAgentUserName();
    end;

    local procedure UpdateAgentTaskMetrics()
    begin
        IsAgentTestType := AgentTestContextImpl.IsAgentTestType(Rec.Code);
        CopilotCredits := AgentTestContextImpl.GetCopilotCredits(Rec.Code, Rec.Version, '', 0);
        AgentTaskIDs := AgentTestContextImpl.GetAgentTaskIDs(Rec.Code, Rec.Version, '', 0);
        AgentTaskCount := AgentTestContextImpl.GetAgentTaskCount(AgentTaskIDs);
    end;

    local procedure UpdateAgentUserName()
    var
        Agent: Codeunit Agent;
    begin
        AgentUserName := '';

        if IsNullGuid(Rec."Agent User Security ID") then
            exit;

        AgentUserName := Agent.GetUserName(Rec."Agent User Security ID");
    end;

    local procedure LookupAgent()
    var
        AgentSetup: Codeunit "Agent Setup";
        Agent: Codeunit Agent;
        AgentUserSecurityId: Guid;
    begin
        if not AgentSetup.OpenAgentLookup(AgentUserSecurityId) then
            exit;
        Rec."Agent User Security ID" := AgentUserSecurityId;
        AgentUserName := Agent.GetUserName(AgentUserSecurityId);
        Rec.Modify();
    end;

    local procedure ValidateAgentName()
    var
        AgentSetup: Codeunit "Agent Setup";
    begin
        if AgentUserName = '' then begin
            Clear(Rec."Agent User Security ID");
            Rec.Modify();
            exit;
        end;

        if not AgentSetup.FindAgentByUserName(AgentUserName, Rec."Agent User Security ID") then
            Error(AgentWithNameNotFoundErr, AgentUserName);

        Rec.Modify();
    end;

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        CopilotCredits: Decimal;
        AgentTaskIDs: Text;
        AgentTaskCount: Integer;
        IsAgentTestType: Boolean;
        AgentUserName: Code[50];
        AgentWithNameNotFoundErr: Label 'An agent with the name %1 was not found.', Comment = '%1 - The name of the agent.';
}