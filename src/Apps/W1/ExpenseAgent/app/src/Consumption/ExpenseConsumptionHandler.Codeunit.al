// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.AI;

codeunit 6969 "Expense Consumption Handler"
{
    Access = Internal;
    Permissions = tabledata "Expense Agent Env. Consumption" = i;

    var
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        CopilotQuota: Codeunit "Copilot Quota";
        CopilotFeatureTrial: Codeunit "Copilot Feature Trial";
        ExpenseAgentFeatureTrialIdTok: Label 'ExpenseAgentTrial', Locked = true;
        LogQuotaStartedTelemetryMsg: Label 'Started logging AI quota usage for Expense Agent. Trying to log %1 %2. Copilot Quota already exists: %3. Expense Agent Consumption already exists: %4. Trial available: %5.', Locked = true;
        UniqueIdTooLongTelemetryErr: Label 'Unique ID is for Expense Agent charge is too long. This leads to truncation, which in turn can lead to missing charging/billing.', Locked = true;

    internal procedure ValidateConsumptionJson(AiConsumptionRequestJson: JsonObject): Boolean
    var
        TempToken: JsonToken;
    begin
        if not AiConsumptionRequestJson.Get('model', TempToken) or not TempToken.IsObject() then
            exit(false);
        if not AiConsumptionRequestJson.Get('v1', TempToken) or not TempToken.IsObject() then
            exit(false);

        exit(true);
    end;

    internal procedure LogAIConsumption(
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
        ActionsSummary: Text[1024];
        ActionsDescription: Text;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        Operation: Code[50];
        ExpenseUserNo: Code[20]): Guid
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        UniqueId: Text[1024];
        IsTrial: Boolean;
    begin
        UniqueId := MakeUniqueId(ConsumptionSourceType, ConsumptionSourceSystemId, Operation);
        IsTrial := TrialAvailable();

        Session.LogMessage('0000ROU', StrSubstNo(LogQuotaStartedTelemetryMsg, Usage, CopilotQuotaUsageType, CopilotQuota.IsAgentUserAIConsumptionLogged(UniqueId), ExpenseAgentEnvConsumption.Get(UniqueId), IsTrial),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());

        // LogAgentUserAiConsumption is idempotent, and so should be inserting in the companion table
        ExpenseAgentEnvConsumption.ReadIsolation := IsolationLevel::UpdLock;
        if not ExpenseAgentEnvConsumption.Get(UniqueId) then begin
            ExpenseAgentEnvConsumption.Init();
            ExpenseAgentEnvConsumption."Consumption Unique ID" := UniqueId;
            ExpenseAgentEnvConsumption."Expense User No." := ExpenseUserNo;
            ExpenseAgentEnvConsumption."Consumption Source Type" := ConsumptionSourceType;
            ExpenseAgentEnvConsumption."Consumption Source System ID" := ConsumptionSourceSystemId;
            ExpenseAgentEnvConsumption."Consumption Source Operation" := Operation;
            ExpenseAgentEnvConsumption.IsFeatureTrial := IsTrial;
            ExpenseAgentEnvConsumption.Insert();
        end;

        // Increment the trial count if this is a trial consumption.
        // Notice platform allows over-reporting trials, so the tenant can use a little
        // more credit without issues (we don't need to use locks or similar)
        if IsTrial then
            IncrementTrial(ExpenseAgentEnvConsumption.SystemId, Operation)
        else
            CopilotQuota.LogAgentUserAIConsumption(
                Enum::"Copilot Capability"::"Expense Agent",
                Usage,
                CopilotQuotaUsageType,
                0, // We have no Agent Task ID
                ActionsSummary,
                ActionsDescription,
                UniqueId);

        exit(ExpenseAgentEnvConsumption.SystemId);
    end;

    internal procedure LogAIConsumption(
        AiConsumptionRequestJson: JsonObject;
        ActionsSummary: Text;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        Operation: Code[50];
        ExpenseUserNo: Code[20]): Guid
    var
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
    begin
        Usage := AiConsumptionRequestJson.GetInteger('usage', false);
        Evaluate(CopilotQuotaUsageType, AiConsumptionRequestJson.GetText('usageType', false));

        exit(LogAIConsumption(Usage, CopilotQuotaUsageType,
            Truncate(ActionsSummary), ActionsSummary, ConsumptionSourceType, ConsumptionSourceSystemId, Operation, ExpenseUserNo));
    end;

    local procedure Truncate(TextToTruncate: Text): Text[1024]
    begin
        if StrLen(TextToTruncate) > 1024 then
            exit(CopyStr(TextToTruncate, 1, 1024 - 3) + '...')
        else
            exit(CopyStr(TextToTruncate, 1, 1024));
    end;

    internal procedure GetRemainingFeatureTrialQuota(): Integer
    begin
        if not CopilotFeatureTrial.IsTrialStarted(ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent") then
            exit(TrialQuota());

        exit(CopilotFeatureTrial.GetQuotaRemaining(ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent"));
    end;

    local procedure TrialAvailable(): Boolean
    begin
        exit(CopilotFeatureTrial.HasQuotaRemaining(ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent"));
    end;

    local procedure IncrementTrial(ConsumptionId: Guid; Operation: Code[50])
    begin
        if Operation = 'TODO policy eval' then
            exit; // We only count expense processing

        CopilotFeatureTrial.ReportNonRecurringFeatureTrialQuota(ConsumptionId, ExpenseAgentFeatureTrialIdTok, Enum::"Copilot Capability"::"Expense Agent",
            TrialQuota(), TrialQuota(), TrialQuota(), TrialQuota(), '');
    end;

    internal procedure TrialQuota(): Integer
    begin
        exit(50);
    end;

    internal procedure CanConsume(): Boolean
    begin
        exit(CopilotQuota.CanConsume());
    end;

    local procedure MakeUniqueId(ConsumptionSourceType: Enum "Expense Agent Cons. Source"; ConsumptionSourceSystemId: Guid; Operation: Code[50]) UniqueId: Text[1024]
    var
        TempUniqueId: Text;
    begin
        TempUniqueId := StrSubstNo('%1-%2-%3-%4',
            Enum::"Copilot Capability"::"Expense Agent",
            Format(ConsumptionSourceType, 0, 9),
            Format(ConsumptionSourceSystemId, 0, 9),
            Format(Operation, 0, 9));

        TempUniqueId := UpperCase(TempUniqueId);
        if StrLen(TempUniqueId) > MaxStrLen(UniqueId) then
            Session.LogMessage('0000ROV', UniqueIdTooLongTelemetryErr,
                Verbosity::Error, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());

        exit(CopyStr(TempUniqueId, 1, MaxStrLen(UniqueId)));
    end;
}