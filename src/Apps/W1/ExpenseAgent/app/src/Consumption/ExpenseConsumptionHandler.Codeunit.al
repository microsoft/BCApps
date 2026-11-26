// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.AI;

codeunit 6969 "Expense Consumption Handler"
{
    Access = Internal;
    Permissions = tabledata "Expense Agent Env. Consumption" = im;

    var
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        QuotaProvider: Interface "Expense Agent Quota";
        IsQuotaProviderSet: Boolean;
        LogQuotaStartedTelemetryMsg: Label 'Started logging AI quota usage for Expense Agent. Trying to log %1 %2. Copilot Quota already exists: %3. Expense Agent Consumption already exists: %4. Trial available: %5.', Locked = true;
        NonProcessingTrialSkippedTelemetryMsg: Label 'Skipped incrementing the Expense Agent feature trial for an operation other than PROCESS.', Locked = true;
        UniqueIdTooLongTelemetryErr: Label 'Unique ID is for Expense Agent charge is too long. This leads to truncation, which in turn can lead to missing charging/billing.', Locked = true;
        ZeroUsageSkippedTelemetryMsg: Label 'Skipped consumption reporting because the active pipeline has zero usage.', Locked = true;
        ConsumptionPendingTelemetryMsg: Label 'Consumption submission has not produced a ledger entry and remains pending.', Locked = true;
        ConsumptionAlreadyReportedTelemetryMsg: Label 'Skipped consumption reporting because the event has already been reported.', Locked = true;

    internal procedure ValidateConsumptionJson(AiConsumptionRequestJson: JsonObject): Boolean
    var
        V1Json: JsonObject;
        ModelJson: JsonObject;
        TempToken: JsonToken;
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
    begin
        if not AiConsumptionRequestJson.Get('model', TempToken) or not TempToken.IsObject() then
            exit(false);
        ModelJson := TempToken.AsObject();
        if not IsValidTokenCount(ModelJson, 'inputTokenCount') or
           not IsValidTokenCount(ModelJson, 'outputTokenCount') or
           not IsValidTokenCount(ModelJson, 'promptCacheReadTokenCount') or
           not IsValidTokenCount(ModelJson, 'promptCacheCreationTokenCount')
        then
            exit(false);
        if not AiConsumptionRequestJson.Get('v1', TempToken) or not TempToken.IsObject() then
            exit(false);
        V1Json := TempToken.AsObject();
        if not V1Json.Get('usage', TempToken) or not TempToken.IsValue() then
            exit(false);
        if TempToken.AsValue().IsNull() then
            exit(false);
        if not Evaluate(Usage, TempToken.AsValue().AsText()) then
            exit(false);
        if Usage < 0 then
            exit(false);
        if not V1Json.Get('usageType', TempToken) or not TempToken.IsValue() then
            exit(false);
        if TempToken.AsValue().IsNull() then
            exit(false);
        if not Evaluate(CopilotQuotaUsageType, TempToken.AsValue().AsText()) then
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
    begin
        if Usage = 0 then begin
            LogZeroUsage('V1');
            exit;
        end;

        GetOrCreateConsumption(ExpenseAgentEnvConsumption, Usage, CopilotQuotaUsageType,
            ConsumptionSourceType, ConsumptionSourceSystemId, Operation, ExpenseUserNo);
        if IsConsumptionReported(ExpenseAgentEnvConsumption) then
            exit(ExpenseAgentEnvConsumption.SystemId);

        Commit();
        if ExpenseAgentEnvConsumption."Is Feature Trial" then begin
            IncrementTrial(ExpenseAgentEnvConsumption.SystemId, Operation);
            MarkConsumptionReported(ExpenseAgentEnvConsumption);
        end else begin
            QuotaProvider.LogConsumption(Usage, CopilotQuotaUsageType, ActionsSummary, ActionsDescription,
                ExpenseAgentEnvConsumption."Consumption Unique ID", false);
            if QuotaProvider.IsConsumptionLogged(ExpenseAgentEnvConsumption."Consumption Unique ID") then
                MarkConsumptionReported(ExpenseAgentEnvConsumption)
            else
                LogPendingConsumption('V1');
        end;

        exit(ExpenseAgentEnvConsumption.SystemId);
    end;

    [NonDebuggable]
    internal procedure LogAIConsumptionV2(
        AiConsumptionRequestJson: JsonObject;
        ActionsSummary: Text;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        Operation: Code[50];
        ExpenseUserNo: Code[20];
        AgentConversationSessionId: Guid;
        AgentTurnInteractionId: Guid;
        ExpenseUserEntraId: Guid;
        ExpenseUserDisplayName: Text): Guid
    var
        ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption";
        ModelJson: JsonObject;
        ConsumptionUsageJson: JsonObject;
        ConsumptionUsagePayload: Text;
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
    begin
        InitializeQuotaProvider();
        ReadV1Usage(AiConsumptionRequestJson, Usage, CopilotQuotaUsageType);
        if not QuotaProvider.IsV2ConsumptionActive() then
            exit(LogAIConsumption(Usage, CopilotQuotaUsageType, Truncate(ActionsSummary), ActionsSummary,
                ConsumptionSourceType, ConsumptionSourceSystemId, Operation, ExpenseUserNo));

        ModelJson := AiConsumptionRequestJson.GetObject('model');
        if not HasModelUsage(ModelJson) then begin
            LogZeroUsage('V2');
            exit;
        end;

        ConsumptionUsageJson.Add('model', ModelJson);
        ConsumptionUsageJson.WriteTo(ConsumptionUsagePayload);
        GetOrCreateConsumption(ExpenseAgentEnvConsumption, Usage, CopilotQuotaUsageType,
            ConsumptionSourceType, ConsumptionSourceSystemId, Operation, ExpenseUserNo);
        if IsConsumptionReported(ExpenseAgentEnvConsumption) then
            exit(ExpenseAgentEnvConsumption.SystemId);

        // The platform records V2 consumption in a separate transaction. Persist its idempotency ID first.
        Commit();

        QuotaProvider.RecordConsumption(ExpenseAgentEnvConsumption.SystemId, AgentConversationSessionId,
            AgentTurnInteractionId, ConsumptionUsagePayload, ExpenseUserEntraId, ExpenseUserDisplayName,
            ActionsSummary, ExpenseAgentEnvConsumption."Is Feature Trial");

        if QuotaProvider.IsV2ConsumptionRecorded(ExpenseAgentEnvConsumption.SystemId) then begin
            if ExpenseAgentEnvConsumption."Is Feature Trial" then
                IncrementTrial(ExpenseAgentEnvConsumption.SystemId, Operation);
            MarkConsumptionReported(ExpenseAgentEnvConsumption);
        end else
            LogPendingConsumption('V2');

        exit(ExpenseAgentEnvConsumption.SystemId);
    end;

    local procedure IsValidTokenCount(ModelJson: JsonObject; FieldName: Text): Boolean
    var
        Token: JsonToken;
        TokenCount: BigInteger;
    begin
        if not ModelJson.Get(FieldName, Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        if not Evaluate(TokenCount, Token.AsValue().AsText(), 9) then
            exit(false);
        exit(TokenCount >= 0);
    end;

    local procedure HasModelUsage(ModelJson: JsonObject): Boolean
    begin
        exit((ModelJson.GetBigInteger('inputTokenCount') > 0) or
             (ModelJson.GetBigInteger('outputTokenCount') > 0) or
             (ModelJson.GetBigInteger('promptCacheReadTokenCount') > 0) or
             (ModelJson.GetBigInteger('promptCacheCreationTokenCount') > 0));
    end;

    local procedure IsConsumptionReported(var ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption"): Boolean
    begin
        if not ExpenseAgentEnvConsumption."Consumption Reported" then
            if QuotaProvider.IsConsumptionLogged(ExpenseAgentEnvConsumption."Consumption Unique ID") then
                MarkConsumptionReported(ExpenseAgentEnvConsumption)
            else
                if QuotaProvider.IsV2ConsumptionRecorded(ExpenseAgentEnvConsumption.SystemId) then begin
                    if ExpenseAgentEnvConsumption."Is Feature Trial" then
                        IncrementTrial(ExpenseAgentEnvConsumption.SystemId, ExpenseAgentEnvConsumption."Consumption Source Operation");
                    MarkConsumptionReported(ExpenseAgentEnvConsumption);
                end;

        if ExpenseAgentEnvConsumption."Consumption Reported" then
            Session.LogMessage('0000W46', ConsumptionAlreadyReportedTelemetryMsg, Verbosity::Normal,
                DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
                'Category', ExpenseAuditSubscribers.TelemetryCategory());
        exit(ExpenseAgentEnvConsumption."Consumption Reported");
    end;

    local procedure MarkConsumptionReported(var ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption")
    begin
        ExpenseAgentEnvConsumption.GetBySystemId(ExpenseAgentEnvConsumption.SystemId);
        ExpenseAgentEnvConsumption."Consumption Reported" := true;
        ExpenseAgentEnvConsumption.Modify();
    end;

    local procedure LogZeroUsage(Pipeline: Text)
    begin
        Session.LogMessage('0000W44', ZeroUsageSkippedTelemetryMsg, Verbosity::Normal,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
            'Category', ExpenseAuditSubscribers.TelemetryCategory(), 'Pipeline', Pipeline);
    end;

    local procedure LogPendingConsumption(Pipeline: Text)
    begin
        Session.LogMessage('0000W45', ConsumptionPendingTelemetryMsg, Verbosity::Warning,
            DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher,
            'Category', ExpenseAuditSubscribers.TelemetryCategory(), 'Pipeline', Pipeline);
    end;

    [NonDebuggable]
    local procedure ReadV1Usage(AiConsumptionRequestJson: JsonObject; var Usage: Integer; var CopilotQuotaUsageType: Enum "Copilot Quota Usage Type")
    var
        V1Json: JsonObject;
    begin
        V1Json := AiConsumptionRequestJson.GetObject('v1');
        Usage := V1Json.GetInteger('usage', false);
        Evaluate(CopilotQuotaUsageType, V1Json.GetText('usageType', false));
    end;

    [NonDebuggable]
    local procedure GetOrCreateConsumption(var ExpenseAgentEnvConsumption: Record "Expense Agent Env. Consumption"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; ConsumptionSourceType: Enum "Expense Agent Cons. Source"; ConsumptionSourceSystemId: Guid; Operation: Code[50]; ExpenseUserNo: Code[20])
    var
        UniqueId: Text[1024];
        IsTrial: Boolean;
    begin
        UniqueId := MakeUniqueId(ConsumptionSourceType, ConsumptionSourceSystemId, Operation);
        IsTrial := TrialQuotaAvailable();

        Session.LogMessage('0000W42', StrSubstNo(LogQuotaStartedTelemetryMsg, Usage, CopilotQuotaUsageType, QuotaProvider.IsConsumptionLogged(UniqueId), ExpenseAgentEnvConsumption.Get(UniqueId), IsTrial),
            Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());

        ExpenseAgentEnvConsumption.ReadIsolation := IsolationLevel::UpdLock;
        if ExpenseAgentEnvConsumption.Get(UniqueId) then
            exit;

        ExpenseAgentEnvConsumption.Init();
        ExpenseAgentEnvConsumption."Consumption Unique ID" := UniqueId;
        ExpenseAgentEnvConsumption."Expense User No." := ExpenseUserNo;
        ExpenseAgentEnvConsumption."Consumption Source Type" := ConsumptionSourceType;
        ExpenseAgentEnvConsumption."Consumption Source System ID" := ConsumptionSourceSystemId;
        ExpenseAgentEnvConsumption."Consumption Source Operation" := Operation;
        ExpenseAgentEnvConsumption."Is Feature Trial" := IsTrial;
        ExpenseAgentEnvConsumption."Source Company Name" := CopyStr(CompanyName(), 1, MaxStrLen(ExpenseAgentEnvConsumption."Source Company Name"));
        ExpenseAgentEnvConsumption.Insert();
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
        InitializeQuotaProvider();
        if not QuotaProvider.IsTrialStarted() then
            exit(TrialQuota());

        exit(QuotaProvider.GetRemainingTrialQuota());
    end;

    local procedure TrialQuotaAvailable(): Boolean
    begin
        InitializeQuotaProvider();
        exit(QuotaProvider.TrialQuotaAvailable());
    end;

    local procedure IncrementTrial(ConsumptionId: Guid; Operation: Code[50])
    begin
        if Operation <> 'PROCESS' then begin
            Session.LogMessage('0000W43', NonProcessingTrialSkippedTelemetryMsg,
                Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());
            exit;
        end;

        QuotaProvider.ReportTrialConsumption(ConsumptionId, TrialQuota());
    end;

    internal procedure TrialQuota(): Integer
    begin
        exit(50);
    end;

    internal procedure CanConsume(): Boolean
    begin
        if TrialQuotaAvailable() then
            exit(true);

        exit(QuotaProvider.CanConsumePaidQuota());
    end;

    [NonDebuggable]
    internal procedure CanConsume(ConsumptionEntraPrincipalId: Guid): Boolean
    begin
        if TrialQuotaAvailable() then
            exit(true);

        exit(QuotaProvider.CanConsumePaidQuota(ConsumptionEntraPrincipalId));
    end;

    internal procedure SetQuotaProvider(NewQuotaProvider: Interface "Expense Agent Quota")
    begin
        QuotaProvider := NewQuotaProvider;
        IsQuotaProviderSet := true;
    end;

    local procedure InitializeQuotaProvider()
    var
        ExpenseAgentQuotaImpl: Codeunit "Expense Agent Quota Impl.";
    begin
        if not IsQuotaProviderSet then
            SetQuotaProvider(ExpenseAgentQuotaImpl);
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