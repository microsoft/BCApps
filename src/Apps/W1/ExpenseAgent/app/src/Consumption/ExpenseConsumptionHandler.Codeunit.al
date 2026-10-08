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
        LogQuotaStartedTelemetryMsg: Label 'Started logging AI quota usage for Expense Agent. Trying to log %1 %2. Copilot Quota already exists: %3. Expense Agent Consumption already exists: %4.', Locked = true;
        UniqueIdTooLongTelemetryErr: Label 'Unique ID is for Expense Agent charge is too long. This leads to truncation, which in turn can lead to missing charging/billing.', Locked = true;

    internal procedure LogAIConsumption(
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
        ActionsSummary: Text[1024];
        ActionsDescription: Text;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        Operation: Code[50];
        ExpenseUserNo: Code[20]): Text[1024]
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        UniqueId: Text[1024];
    begin
        UniqueId := MakeUniqueId(ConsumptionSourceType, ConsumptionSourceSystemId, Operation);

        Session.LogMessage('0000ROU', StrSubstNo(LogQuotaStartedTelemetryMsg, Usage, CopilotQuotaUsageType, CopilotQuota.IsAgentUserAIConsumptionLogged(UniqueId), ExpenseAgentEnvConsumption.Get(UniqueId)),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());

        CopilotQuota.LogAgentUserAIConsumption(
            Enum::"Copilot Capability"::"Expense Agent",
            Usage,
            CopilotQuotaUsageType,
            0, // We have no Agent Task ID
            ActionsSummary,
            ActionsDescription,
            UniqueId);

        // LogAgentUserAiConsumption is idempotent, and so should be inserting in the companion table
        ExpenseAgentEnvConsumption.ReadIsolation := IsolationLevel::UpdLock;
        if not ExpenseAgentEnvConsumption.Get(UniqueId) then begin
            ExpenseAgentEnvConsumption.Init();
            ExpenseAgentEnvConsumption."Consumption Unique ID" := UniqueId;
            ExpenseAgentEnvConsumption."Expense User No." := ExpenseUserNo;
            ExpenseAgentEnvConsumption."Consumption Source Type" := ConsumptionSourceType;
            ExpenseAgentEnvConsumption."Consumption Source System ID" := ConsumptionSourceSystemId;
            ExpenseAgentEnvConsumption."Consumption Source Operation" := Operation;
            ExpenseAgentEnvConsumption.Insert();
        end;

        exit(UniqueId);
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
            Format(Enum::"Copilot Capability"::"Expense Agent", 0, 9),
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