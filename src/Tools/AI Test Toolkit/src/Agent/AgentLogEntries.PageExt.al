// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

pageextension 149030 "Agent Log Entries" extends "AIT Log Entries"
{
    layout
    {
        addafter("Tokens Consumed")
        {
            field("Copilot Credits"; CopilotCredits)
            {
                ApplicationArea = All;
                AutoFormatType = 0;
                Caption = 'Copilot credits';
                ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks for this log entry.';
                Editable = false;
                Visible = IsAgentTestType;
            }
            field("Agent Task IDs"; AgentTaskIDs)
            {
                ApplicationArea = All;
                Caption = 'Agent tasks';
                ToolTip = 'Specifies the comma-separated list of Agent Task IDs related to this log entry.';
                Editable = false;
                Visible = IsAgentTestType;

                trigger OnDrillDown()
                var
                    AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
                begin
                    AgentTestContextImpl.OpenAgentTaskList(AgentTaskIDs);
                end;
            }
        }
    }

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        CopilotCredits: Decimal;
        AgentTaskIDs: Text;
        IsAgentTestType: Boolean;

    trigger OnAfterGetRecord()
    begin
        UpdateAgentTaskMetrics();
    end;

    local procedure UpdateAgentTaskMetrics()
    begin
        IsAgentTestType := AgentTestContextImpl.IsAgentTestType(Rec."Test Suite Code");
        CopilotCredits := AgentTestContextImpl.GetCopilotCreditsForLogEntry(Rec."Entry No.");
        AgentTaskIDs := AgentTestContextImpl.GetAgentTaskIDsForLogEntry(Rec."Entry No.");
    end;
}
