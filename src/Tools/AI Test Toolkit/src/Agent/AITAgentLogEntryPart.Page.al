// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

page 149050 "AIT Agent Log Entry Part"
{
    Caption = 'Agent Details';
    PageType = CardPart;
    Editable = false;
    SourceTable = "AIT Log Entry";

    layout
    {
        area(Content)
        {
            field("Agent Task IDs"; AgentTaskIDs)
            {
                ApplicationArea = All;
                Caption = 'Agent Tasks Executed';
                ToolTip = 'Specifies the comma-separated list of Agent Task IDs related to this log entry.';

                trigger OnDrillDown()
                begin
                    AgentTestContextImpl.OpenAgentTaskList(AgentTaskIDs);
                end;
            }
            field("Copilot Credits"; CopilotCredits)
            {
                ApplicationArea = All;
                AutoFormatType = 0;
                Caption = 'Copilot Credits Consumed';
                ToolTip = 'Specifies the total Copilot Credits consumed by the Agent Tasks for this log entry.';

                trigger OnDrillDown()
                begin
                    AgentTestContextImpl.OpenAgentConsumptionOverview(AgentTaskIDs);
                end;
            }
        }
    }

    var
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        CopilotCredits: Decimal;
        AgentTaskIDs: Text;

    trigger OnAfterGetRecord()
    begin
        CopilotCredits := AgentTestContextImpl.GetCopilotCreditsForLogEntry(Rec."Entry No.");
        AgentTaskIDs := AgentTestContextImpl.GetAgentTaskIDsForLogEntry(Rec."Entry No.");
    end;
}
