// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;

page 149050 "AIT Agent Log Entry Part"
{
    Caption = 'Agent Details';
    PageType = ListPart;
    Editable = false;
    SourceTable = "Agent Task Log";

    layout
    {
        area(Content)
        {
            repeater(Tasks)
            {
                field("Agent Task ID"; Rec."Agent Task ID")
                {
                    Caption = 'Task ID';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the Agent Task ID.';

                    trigger OnDrillDown()
                    begin
                        AgentTestContextImpl.OpenAgentTaskList(Format(Rec."Agent Task ID"));
                    end;
                }
                field(NumberOfStepsDone; NumberOfStepsDone)
                {
                    Caption = 'Steps Done';
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of steps that have been done for the specific task.';

                    trigger OnDrillDown()
                    begin
                        AgentTask.OpenAgentTaskLogEntries(Rec."Agent Task ID");
                    end;
                }
                field("Copilot Credits"; CopilotCredits)
                {
                    ApplicationArea = All;
                    AutoFormatType = 0;
                    Caption = 'Copilot Credits';
                    ToolTip = 'Specifies the Copilot Credits consumed by this Agent Task.';

                    trigger OnDrillDown()
                    begin
                        AgentConsumptionOverview.OpenAgentTaskConsumptionOverview(Rec."Agent Task ID");
                    end;
                }
            }
        }
    }

    var
        AgentConsumptionOverview: Codeunit "Agent Consumption Overview";
        AgentTask: Codeunit "Agent Task";
        AgentTestContextImpl: Codeunit "Agent Test Context Impl.";
        CopilotCredits: Decimal;
        NumberOfStepsDone: Integer;

    trigger OnAfterGetRecord()
    begin
        CopilotCredits := AgentConsumptionOverview.GetCopilotCreditsConsumed(Rec."Agent Task ID");
        NumberOfStepsDone := AgentTask.GetStepsDoneCount(Rec."Agent Task ID");
    end;
}
