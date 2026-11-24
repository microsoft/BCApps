// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.AI;

codeunit 6913 "Expense Agent Quota Impl." implements "Expense Agent Quota"
{
    Access = Internal;

    var
        CopilotQuota: Codeunit "Copilot Quota";
        CopilotFeatureTrial: Codeunit "Copilot Feature Trial";
        ExpenseAgentFeatureTrialIdTok: Label 'ExpenseAgentTrial', Locked = true;

    procedure IsTrialStarted(): Boolean
    begin
        exit(CopilotFeatureTrial.IsTrialStarted(ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent"));
    end;

    procedure GetRemainingTrialQuota(): Integer
    begin
        exit(CopilotFeatureTrial.GetQuotaRemaining(ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent"));
    end;

    procedure TrialQuotaAvailable(): Boolean
    begin
        exit(CopilotFeatureTrial.HasQuotaRemaining(ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent"));
    end;

    procedure CanConsumePaidQuota(): Boolean
    begin
        exit(CopilotQuota.CanConsume());
    end;

    [NonDebuggable]
    procedure CanConsumePaidQuota(ConsumptionEntraPrincipalId: Guid): Boolean
    begin
        exit(CopilotQuota.CanConsume(ConsumptionEntraPrincipalId));
    end;

    procedure IsConsumptionLogged(UniqueId: Text[1024]): Boolean
    begin
        exit(CopilotQuota.IsAgentUserAIConsumptionLogged(UniqueId));
    end;

    procedure ReportTrialConsumption(ConsumptionId: Guid; Quota: Integer)
    begin
        CopilotFeatureTrial.ReportNonRecurringFeatureTrialQuota(ConsumptionId, ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent",
            Quota, Quota, Quota, Quota, '');
    end;

    [NonDebuggable]
    procedure LogConsumption(Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; ActionsSummary: Text[1024]; ActionsDescription: Text; UniqueId: Text[1024]; ExcludeFromBilling: Boolean)
    begin
        CopilotQuota.LogAgentUserAIConsumption(
            Enum::"Copilot Capability"::"Expense Agent",
            Usage,
            CopilotQuotaUsageType,
            0, // We have no Agent Task ID
            ActionsSummary,
            ActionsDescription,
            UniqueId,
            ExcludeFromBilling);
    end;

    [NonDebuggable]
    procedure RecordConsumption(ConsumptionId: Guid; ConsumptionSessionId: Guid; InteractionId: Guid; ConsumptionUsagePayload: Text; ConsumptionEntraPrincipalId: Guid; ConsumptionEntraPrincipalDisplayName: Text; Description: Text; IsFeatureTrial: Boolean)
    begin
        CopilotQuota.RecordAIConsumption(
            Enum::"Copilot Capability"::"Expense Agent",
            ConsumptionId,
            ConsumptionSessionId,
            InteractionId,
            ConsumptionId,
            ConsumptionUsagePayload,
            ConsumptionEntraPrincipalId,
            ConsumptionEntraPrincipalDisplayName,
            0,
            '',
            Description,
            IsFeatureTrial);
    end;
}
