// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.TestTools.AITestToolkit;

using System.Agents;
using System.AI;

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
                    CaptionClass = '3,' + Quota.GetCreditCaption();
                    ToolTip = 'Specifies the Copilot Credits consumed by this Agent Task.';

                    trigger OnDrillDown()
                    begin
                        AgentConsumptionOverview.OpenAgentTaskConsumptionOverview(Rec."Agent Task ID");
                    end;
                }
                field(PricingPending; PricingPending)
                {
                    ApplicationArea = All;
                    Caption = 'Pricing pending';
                    ToolTip = 'Specifies that AI pricing for this task is incomplete.';
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
        AgentTestConsumption: Codeunit "Agent Test Consumption";
        Quota: Codeunit "Copilot Quota";
        PricingPending: Boolean;

    trigger OnAfterGetRecord()
    begin
        PricingPending := false;
        if Rec."New Monetization" then
            AgentTestConsumption.GetTaskAIConsumption(Rec."Agent Task ID", CopyStr(CompanyName(), 1, 30), CopilotCredits, PricingPending)
        else
            CopilotCredits := AgentConsumptionOverview.GetCopilotCreditsConsumed(Rec."Agent Task ID");
        NumberOfStepsDone := AgentTask.GetStepsDoneCount(Rec."Agent Task ID");
    end;

    trigger OnOpenPage()
    begin
        Rec.FilterGroup(2);
        Rec.SetRange("New Monetization", Quota.IsNewMonetizationEnabled());
        Rec.FilterGroup(0);
    end;
}
