// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;
using System.Environment.Consumption;

codeunit 4333 "Agent Consumption Overview"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = r,
                  tabledata "User AI Consumption Data" = r;

    /// <summary>
    /// Gets the total Copilot credits consumed by the agent task.
    /// </summary>
    /// <param name="TaskId">The ID of the agent task to get consumed credits for.</param>
    /// <returns>The total Copilot credits consumed by the agent task.</returns>
    procedure GetCopilotCreditsConsumed(TaskId: BigInteger): Decimal
    var
        UserAIConsumptionData: Record "User AI Consumption Data";
    begin
        UserAIConsumptionData.SetRange("Agent Task Id", TaskId);
        UserAIConsumptionData.CalcSums("Copilot Credits");
        exit(UserAIConsumptionData."Copilot Credits");
    end;

    /// <summary>
    /// Opens the agent consumption overview page for the specified agent.
    /// </summary>
    /// <param name="AgentUserSecurityId">The agent user security ID.</param>
    procedure OpenAgentConsumptionOverview(AgentUserSecurityId: Guid)
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
    begin
        AgentTaskConsumption.SetRange("Agent User Security ID", AgentUserSecurityId);
        Page.Run(Page::"Agent Consumption Overview", AgentTaskConsumption);
    end;

    /// <summary>
    /// Opens the agent consumption overview page for the specified agent task.
    /// </summary>
    /// <param name="TaskId">The ID of the agent task.</param>
    procedure OpenAgentTaskConsumptionOverview(TaskId: BigInteger)
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
    begin
        AgentTaskConsumption.SetRange("Task ID", TaskId);
        Page.Run(Page::"Agent Consumption Overview", AgentTaskConsumption);
    end;

    /// <summary>
    /// Opens the agent consumption overview page for the agent tasks matching the specified filter.
    /// </summary>
    /// <param name="TaskIDFilter">The filter for the agent task IDs.</param>
    procedure OpenAgentTaskConsumptionOverview(TaskIDFilter: Text)
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
        AgentConsumptionOverview: Page "Agent Consumption Overview";
    begin
        AgentTaskConsumption.SetFilter("Task ID", TaskIDFilter);
        AgentConsumptionOverview.SetTableView(AgentTaskConsumption);
        AgentConsumptionOverview.Run();
    end;
}