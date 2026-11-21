// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;
using System.AI;
using System.Security.Encryption;

codeunit 6969 "Expense Consumption Handler"
{
    Access = Internal;
    Permissions = tabledata "Expense Agent Env. Consumption" = i;

    var
        ExpenseAuditSubscribers: Codeunit "Expense Audit Subscribers";
        QuotaProvider: Interface "Expense Agent Quota";
        IsQuotaProviderSet: Boolean;
        LogQuotaStartedTelemetryMsg: Label 'Started logging AI quota usage for Expense Agent. Trying to log %1 %2. Copilot Quota already exists: %3. Expense Agent Consumption already exists: %4. Trial available: %5.', Locked = true;
        PolicyEvaluationTrialSkippedTelemetryMsg: Label 'Skipped incrementing the Expense Agent feature trial for a policy evaluation operation.', Locked = true;
        UniqueIdTooLongTelemetryErr: Label 'Unique ID is for Expense Agent charge is too long. This leads to truncation, which in turn can lead to missing charging/billing.', Locked = true;

    internal procedure ValidateConsumptionJson(AiConsumptionRequestJson: JsonObject): Boolean
    var
        CopilotQuota: Codeunit "Copilot Quota";
        V1Json: JsonObject;
        TempToken: JsonToken;
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            exit(ValidateMeasuredConsumption(AiConsumptionRequestJson));

        if not AiConsumptionRequestJson.Get('model', TempToken) or not TempToken.IsObject() then
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
        CopilotQuota: Codeunit "Copilot Quota";
        UniqueId: Text[1024];
        IsTrial: Boolean;
        MeasuredUsageRequiredErr: Label 'New monetization requires measured AI usage and conversation context. Use the measured consumption endpoint.';
        MeasuredOperationErr: Label 'This operation was already recorded using new monetization and cannot be recorded again using legacy monetization.';
    begin
        if CopilotQuota.IsNewMonetizationEnabled() then
            Error(MeasuredUsageRequiredErr);

        UniqueId := MakeUniqueId(ConsumptionSourceType, ConsumptionSourceSystemId, Operation);
        IsTrial := TrialQuotaAvailable();

        Session.LogMessage('0000W42', StrSubstNo(LogQuotaStartedTelemetryMsg, Usage, CopilotQuotaUsageType, QuotaProvider.IsConsumptionLogged(UniqueId), ExpenseAgentEnvConsumption.Get(UniqueId), IsTrial),
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
            ExpenseAgentEnvConsumption."Is Feature Trial" := IsTrial;
            ExpenseAgentEnvConsumption.Insert();
        end else begin
            if ExpenseAgentEnvConsumption."New Monetization" then
                Error(MeasuredOperationErr);
            IsTrial := ExpenseAgentEnvConsumption."Is Feature Trial";
        end;

        // Increment the trial count if this is a trial consumption.
        // Notice platform allows over-reporting trials, so the tenant can use a little
        // more credit without issues (we don't need to use locks or similar)
        if IsTrial then
            IncrementTrial(ExpenseAgentEnvConsumption.SystemId, Operation)
        else
            QuotaProvider.LogPaidConsumption(Usage, CopilotQuotaUsageType, ActionsSummary, ActionsDescription, UniqueId);

        exit(ExpenseAgentEnvConsumption.SystemId);
    end;

    internal procedure LogAIConsumption(AiConsumptionRequestJson: JsonObject; SessionId: Guid; InteractionId: Guid; PrincipalId: Guid; ActionsSummary: Text; ConsumptionSourceType: Enum "Expense Agent Cons. Source"; ConsumptionSourceSystemId: Guid; Operation: Code[50]; ExpenseUserNo: Code[20]): Guid
    var
        Consumption: Record "Expense Agent Env. Consumption";
        CopilotQuota: Codeunit "Copilot Quota";
        Payload: JsonObject;
        DimensionToken: JsonToken;
        DimensionNames: List of [Text];
        DimensionName: Text;
        CorrelationId: Guid;
        PayloadText: Text;
        DescriptionStream: OutStream;
        LegacyOperationErr: Label 'This operation was already recorded using legacy monetization and cannot be recorded again using new monetization.';
    begin
        if not CopilotQuota.IsNewMonetizationEnabled() then
            exit(LogAIConsumption(AiConsumptionRequestJson, ActionsSummary, ConsumptionSourceType, ConsumptionSourceSystemId, Operation, ExpenseUserNo));

        Consumption.ReadIsolation := IsolationLevel::UpdLock;
        if not Consumption.Get(MakeUniqueId(ConsumptionSourceType, ConsumptionSourceSystemId, Operation)) then begin
            Consumption.Init();
            Consumption."Consumption Unique ID" := MakeUniqueId(ConsumptionSourceType, ConsumptionSourceSystemId, Operation);
            Consumption."Expense User No." := ExpenseUserNo;
            Consumption."Consumption Source Type" := ConsumptionSourceType;
            Consumption."Consumption Source System ID" := ConsumptionSourceSystemId;
            Consumption."Consumption Source Operation" := Operation;
            Consumption."Is Feature Trial" := TrialQuotaAvailable();
            Consumption."New Monetization" := true;
            Consumption."AI Source Company" := CopyStr(CompanyName(), 1, MaxStrLen(Consumption."AI Source Company"));
            Consumption."AI Consumption ID" := GetMeasuredConsumptionId(Consumption."Consumption Unique ID");
            Consumption."AI Description".CreateOutStream(DescriptionStream, TextEncoding::UTF8);
            DescriptionStream.WriteText(ActionsSummary);
            Consumption.Insert();
        end;
        if not Consumption."New Monetization" then
            Error(LegacyOperationErr);

        Evaluate(CorrelationId, AiConsumptionRequestJson.GetText('correlationId'));
        DimensionNames.Add('model');
        DimensionNames.Add('tools');
        DimensionNames.Add('rai');
        DimensionNames.Add('infra');
        DimensionNames.Add('orchestrator');
        foreach DimensionName in DimensionNames do
            if AiConsumptionRequestJson.Get(DimensionName, DimensionToken) then
                Payload.Add(DimensionName, DimensionToken);
        Payload.WriteTo(PayloadText);
        CopilotQuota.RecordAIConsumption(Consumption."AI Consumption ID", SessionId, InteractionId, CorrelationId, 'Expense Agent',
            PayloadText, PrincipalId, CopyStr(AiConsumptionRequestJson.GetText('principalDisplayName'), 1, 256), 0, '', ActionsSummary, Consumption."Is Feature Trial");

        if Consumption."Is Feature Trial" then
            IncrementTrial(Consumption."AI Consumption ID", Operation);

        exit(Consumption.SystemId);
    end;

    internal procedure GetMeasuredConsumptionId(UniqueId: Text[1024]) ConsumptionId: Guid
    var
        CryptographyManagement: Codeunit "Cryptography Management";
        HashAlgorithm: Option MD5,SHA1,SHA256,SHA384,SHA512;
        Hash: Text;
    begin
        // The separate platform transaction can survive rollback of the companion insert.
        // Derive identity from the business operation, not a new companion SystemId on each retry.
        Hash := CryptographyManagement.GenerateHash('ExpenseAgent:AIConsumption:V2:' + UniqueId, HashAlgorithm::SHA256);
        Evaluate(ConsumptionId, StrSubstNo('%1-%2-%3-%4-%5', CopyStr(Hash, 1, 8), CopyStr(Hash, 9, 4), CopyStr(Hash, 13, 4), CopyStr(Hash, 17, 4), CopyStr(Hash, 21, 12)));
    end;

    local procedure ValidateMeasuredConsumption(Request: JsonObject): Boolean
    var
        Model: JsonObject;
        Token: JsonToken;
        CorrelationId: Guid;
        Quantity: Decimal;
        FieldName: Text;
        TokenFields: List of [Text];
    begin
        if not Request.Get('model', Token) then
            exit(false);
        if not Token.IsObject() then
            exit(false);
        Model := Token.AsObject();
        if not Model.Get('modelResolvedName', Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        if Token.AsValue().AsText().Trim() = '' then
            exit(false);

        TokenFields.Add('inputTokenCount');
        TokenFields.Add('outputTokenCount');
        TokenFields.Add('promptCacheReadTokenCount');
        TokenFields.Add('promptCacheCreationTokenCount');
        foreach FieldName in TokenFields do begin
            if not Model.Get(FieldName, Token) then
                exit(false);
            if not Token.IsValue() then
                exit(false);
            if Token.AsValue().IsNull() then
                exit(false);
            if not Evaluate(Quantity, Token.AsValue().AsText(), 9) then
                exit(false);
            if Quantity < 0 then
                exit(false);
        end;

        if not Request.Get('correlationId', Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        if not Evaluate(CorrelationId, Token.AsValue().AsText()) then
            exit(false);
        if IsNullGuid(CorrelationId) then
            exit(false);
        if not Request.Get('principalDisplayName', Token) then
            exit(false);
        if not Token.IsValue() then
            exit(false);
        if Token.AsValue().IsNull() then
            exit(false);
        exit(Token.AsValue().AsText().Trim() <> '');
    end;

    internal procedure LogAIConsumption(
        AiConsumptionRequestJson: JsonObject;
        ActionsSummary: Text;
        ConsumptionSourceType: Enum "Expense Agent Cons. Source";
        ConsumptionSourceSystemId: Guid;
        Operation: Code[50];
        ExpenseUserNo: Code[20]): Guid
    var
        V1Json: JsonObject;
        Usage: Integer;
        CopilotQuotaUsageType: Enum "Copilot Quota Usage Type";
    begin
        V1Json := AiConsumptionRequestJson.GetObject('v1');
        Usage := V1Json.GetInteger('usage', false);
        Evaluate(CopilotQuotaUsageType, V1Json.GetText('usageType', false));

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
    var
        OperationText: Text;
    begin
        // We only count expense processing. If the trial is still active, policy evals are for free.

        OperationText := Operation; // Code types do not support startswith
        if OperationText.StartsWith('PE:') then begin
            Session.LogMessage('0000W43', PolicyEvaluationTrialSkippedTelemetryMsg,
                Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', ExpenseAuditSubscribers.TelemetryCategory());
            exit;
        end;

        InitializeQuotaProvider();
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