// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

pageextension 149033 "Agent Test Method Lines" extends "AIT Test Method Lines"
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
                ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks for this eval line.';
                Editable = false;
            }
            field("Agent Task Count"; AgentTaskCount)
            {
                ApplicationArea = All;
                Caption = 'Agent tasks';
                ToolTip = 'Specifies the number of Agent Tasks related to this eval line.';
                Editable = false;

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
        AgentTaskCount: Integer;

    trigger OnAfterGetRecord()
    begin
        UpdateAgentTaskMetrics();
    end;

    trigger OnAfterGetCurrRecord()
    begin
        UpdateAgentTaskMetrics();
    end;

    local procedure UpdateAgentTaskMetrics()
    var
        VersionFilter: Text;
        CurrentFilterGroup: Integer;
    begin
        CurrentFilterGroup := Rec.FilterGroup();
        Rec.FilterGroup(4);
        VersionFilter := Rec.GetFilter(Rec."Version Filter");
        Rec.FilterGroup(CurrentFilterGroup);
        CopilotCredits := AgentTestContextImpl.GetCopilotCredits(Rec."Test Suite Code", VersionFilter, '', Rec."Line No.");
        AgentTaskIDs := AgentTestContextImpl.GetAgentTaskIDs(Rec."Test Suite Code", VersionFilter, '', Rec."Line No.");
        AgentTaskCount := AgentTestContextImpl.GetAgentTaskCount(AgentTaskIDs);
    end;
}
