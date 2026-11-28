// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Agents;

using System.AI;

codeunit 4333 "Agent Consumption Overview"
{
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Agent Task" = r;

    /// <summary>
    /// Gets credits consumed by the agent task in the selected monetization generation.
    /// </summary>
    /// <param name="TaskId">The ID of the agent task to get consumed credits for.</param>
    /// <returns>Completed credits in the selected generation. Use GetTaskConsumption to inspect pending pricing.</returns>
    procedure GetCopilotCreditsConsumed(TaskId: BigInteger): Decimal
    var
        Credits: Decimal;
        PricingPending: Boolean;
    begin
        GetTaskConsumption(TaskId, Credits, PricingPending);
        exit(Credits);
    end;

    /// <summary>
    /// Gets credits in the selected generation and indicates incomplete V2 pricing.
    /// </summary>
    procedure GetTaskConsumption(TaskId: BigInteger; var Credits: Decimal; var PricingPending: Boolean)
    var
        CopilotQuota: Codeunit "Copilot Quota";
        NoTaskAccessErr: Label 'The agent task is unavailable or you do not have permission to view its consumption.';
    begin
        Credits := 0;
        PricingPending := false;
        if TaskId = 0 then
            exit;

        if CopilotQuota.IsNewMonetizationEnabled() then begin
            if not TryGetAIConsumption(TaskId, CopyStr(CompanyName(), 1, 30), Credits, PricingPending) then
                Error(NoTaskAccessErr);
            exit;
        end;

        Credits := GetLegacyCopilotCreditsConsumed(TaskId);
    end;

    /// <summary>
    /// Gets historical V1 credits without combining them with V2 AI credits.
    /// </summary>
    procedure GetLegacyCopilotCreditsConsumed(TaskId: BigInteger): Decimal
    var
        AgentUtilities: Codeunit "Agent Utilities";
    begin
        if TaskId = 0 then
            exit(0);
        exit(AgentUtilities.GetConsumedCopilotCredits(TaskId));
    end;

    /// <summary>
    /// Reads completed V2 task credits and indicates incomplete pricing.
    /// Returns false if the task is unavailable or inaccessible; callers must retain existing accounting in that case.
    /// No entries yet is treated as incomplete pricing, not finalized zero consumption.
    /// The authorized virtual task provider supports only the current session company.
    /// </summary>
    procedure TryGetAIConsumption(TaskId: BigInteger; TaskCompany: Text[30]; var Credits: Decimal; var PricingPending: Boolean): Boolean
    var
        HasEntries: Boolean;
    begin
        exit(TryGetAIConsumption(TaskId, TaskCompany, Credits, PricingPending, HasEntries));
    end;

    /// <summary>
    /// Reads V2 task consumption and distinguishes a missing ledger from completed zero-cost entries.
    /// </summary>
    procedure TryGetAIConsumption(TaskId: BigInteger; TaskCompany: Text[30]; var Credits: Decimal; var PricingPending: Boolean; var HasEntries: Boolean): Boolean
    var
        Consumption: Codeunit "Agent AI Consumption";
        CopilotQuota: Codeunit "Copilot Quota";
        DisabledErr: Label 'The new AI monetization integration is not enabled.';
    begin
        if not CopilotQuota.IsNewMonetizationEnabled() then
            Error(DisabledErr);
        exit(Consumption.TryGetTaskCredits(TaskId, TaskCompany, Credits, PricingPending, HasEntries));
    end;

    /// <summary>
    /// Opens the agent consumption overview page for the specified agent.
    /// </summary>
    /// <param name="AgentUserSecurityId">The agent user security ID.</param>
    procedure OpenAgentConsumptionOverview(AgentUserSecurityId: Guid)
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
        CopilotQuota: Codeunit "Copilot Quota";
        Overview: Page "Agent AI Consumption Overview";
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then begin
            Overview.SetContext('', AgentUserSecurityId);
            Overview.Run();
            exit;
        end;

        AgentTaskConsumption.SetRange("Agent User Security ID", AgentUserSecurityId);
        Page.Run(Page::"Agent Consumption Overview", AgentTaskConsumption);
    end;

    /// <summary>
    /// Opens the agent consumption overview page for the specified agent task.
    /// </summary>
    /// <param name="TaskId">The ID of the agent task.</param>
    procedure OpenAgentTaskConsumptionOverview(TaskId: BigInteger)
    begin
        OpenAgentTaskConsumptionOverview(Format(TaskId, 0, 9));
    end;

    /// <summary>
    /// Opens the agent consumption overview page for the agent tasks matching the specified filter.
    /// </summary>
    /// <param name="TaskIDFilter">The filter for the agent task IDs.</param>
    procedure OpenAgentTaskConsumptionOverview(TaskIDFilter: Text)
    var
        AgentTaskConsumption: Record "Agent Task Consumption";
        AgentConsumptionOverview: Page "Agent Consumption Overview";
        Overview: Page "Agent AI Consumption Overview";
        CopilotQuota: Codeunit "Copilot Quota";
        AgentUserId: Guid;
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then begin
            Overview.SetContext(TaskIDFilter, AgentUserId);
            Overview.Run();
            exit;
        end;

        AgentTaskConsumption.SetFilter("Task ID", TaskIDFilter);
        AgentConsumptionOverview.SetTableView(AgentTaskConsumption);
        AgentConsumptionOverview.Run();
    end;
}