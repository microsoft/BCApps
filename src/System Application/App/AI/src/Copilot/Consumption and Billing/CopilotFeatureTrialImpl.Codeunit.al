// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;
using System;

codeunit 7754 "Copilot Feature Trial Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        CapabilityNotRegisteredErr: Label 'The Copilot capability ''%1'' has not been registered or was registered by another app.', Comment = '%1 is the name of the Copilot capability';
        ConsumptionIdMustBeSpecifiedErr: Label 'The consumption ID must be specified.';
        TrialIdMustBeSpecifiedErr: Label 'The trial ID must be specified.';
        QuotaLimitsMustBeNonNegativeErr: Label 'All trial quota limits must be non-negative.';
        FeatureTrialQuotaRetrievedTelemetryMsg: Label 'Feature trial quota retrieved. Is set up: %1. Quota limit: %2. Quota consumed: %3. Quota remaining: %4. Expires at: %5. Is expired: %6. Has quota remaining: %7. ', Locked = true;
        FeatureTrialQuotaLimitsTelemetryMsg: Label 'Paid production quota limit: %1. Paid sandbox quota limit: %2. Unpaid production quota limit: %3. Unpaid sandbox quota limit: %4.', Locked = true;
        FeatureTrialQuotaReportedTelemetryMsg: Label 'Feature trial quota report completed. The run was within quota: %1.', Locked = true;

    internal procedure IsTrialStarted(TrialId: Text; CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AIFeatureTrialInfo: DotNet ALAIFeatureTrialInfo;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        if TrialId.Trim() = '' then
            Error(TrialIdMustBeSpecifiedErr);
        AIFeatureTrialInfo := ALCopilotFunctions.GetFeatureTrialQuotaRemaining(TrialId, CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));
        LogFeatureTrialQuotaRetrieved(AIFeatureTrialInfo);
        exit(AIFeatureTrialInfo.IsSetup());
    end;

    internal procedure GetQuotaRemaining(TrialId: Text; CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Integer
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AIFeatureTrialInfo: DotNet ALAIFeatureTrialInfo;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        if TrialId.Trim() = '' then
            Error(TrialIdMustBeSpecifiedErr);
        AIFeatureTrialInfo := ALCopilotFunctions.GetFeatureTrialQuotaRemaining(TrialId, CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));
        LogFeatureTrialQuotaRetrieved(AIFeatureTrialInfo);
        exit(CalculateQuotaRemaining(AIFeatureTrialInfo));
    end;

    internal procedure HasQuotaRemaining(TrialId: Text; CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AIFeatureTrialInfo: DotNet ALAIFeatureTrialInfo;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        if TrialId.Trim() = '' then
            Error(TrialIdMustBeSpecifiedErr);
        AIFeatureTrialInfo := ALCopilotFunctions.GetFeatureTrialQuotaRemaining(TrialId, CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));
        LogFeatureTrialQuotaRetrieved(AIFeatureTrialInfo);
        exit(not AIFeatureTrialInfo.IsSetup() or AIFeatureTrialInfo.HasQuotaRemaining());
    end;

    local procedure LogFeatureTrialQuotaRetrieved(AIFeatureTrialInfo: DotNet ALAIFeatureTrialInfo)
    begin
        Session.LogMessage(
            '0000VVK',
            StrSubstNo(FeatureTrialQuotaRetrievedTelemetryMsg, AIFeatureTrialInfo.IsSetup(), AIFeatureTrialInfo.QuotaLimit(), AIFeatureTrialInfo.QuotaConsumed(), CalculateQuotaRemaining(AIFeatureTrialInfo), AIFeatureTrialInfo.ExpiresAt(), AIFeatureTrialInfo.IsExpired(), AIFeatureTrialInfo.HasQuotaRemaining()) +
            StrSubstNo(FeatureTrialQuotaLimitsTelemetryMsg, AIFeatureTrialInfo.PaidProductionQuotaLimit(), AIFeatureTrialInfo.PaidSandboxQuotaLimit(), AIFeatureTrialInfo.UnpaidProductionQuotaLimit(), AIFeatureTrialInfo.UnpaidSandboxQuotaLimit()),
            Verbosity::Normal,
            DataClassification::SystemMetadata,
            TelemetryScope::ExtensionPublisher,
            'Category',
            CopilotCapabilityImpl.GetCopilotCategory());
    end;

    local procedure CalculateQuotaRemaining(AIFeatureTrialInfo: DotNet ALAIFeatureTrialInfo): Integer
    var
        QuotaRemaining: Integer;
    begin
        QuotaRemaining := AIFeatureTrialInfo.QuotaLimit() - AIFeatureTrialInfo.QuotaConsumed();
        if QuotaRemaining < 0 then
            exit(0);
        exit(QuotaRemaining);
    end;

    internal procedure ReportNonRecurringFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text; CallerModuleInfo: ModuleInfo): Boolean
    var
        AIFeatureTrialRecurrenceType: DotNet ALAIFeatureTrialRecurrenceType;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        AIFeatureTrialRecurrenceType := AIFeatureTrialRecurrenceType::None;
        exit(ReportFeatureTrialQuota(ConsumptionId, TrialId, CopilotCapability, AIFeatureTrialRecurrenceType, PaidProductionQuotaLimit, PaidSandboxQuotaLimit, UnpaidProductionQuotaLimit, UnpaidSandboxQuotaLimit, Metadata));
    end;

    internal procedure ReportMonthlyFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text; CallerModuleInfo: ModuleInfo): Boolean
    var
        AIFeatureTrialRecurrenceType: DotNet ALAIFeatureTrialRecurrenceType;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        AIFeatureTrialRecurrenceType := AIFeatureTrialRecurrenceType::Monthly;
        exit(ReportFeatureTrialQuota(ConsumptionId, TrialId, CopilotCapability, AIFeatureTrialRecurrenceType, PaidProductionQuotaLimit, PaidSandboxQuotaLimit, UnpaidProductionQuotaLimit, UnpaidSandboxQuotaLimit, Metadata));
    end;

    local procedure ReportFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; AIFeatureTrialRecurrenceType: DotNet ALAIFeatureTrialRecurrenceType; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text): Boolean
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AIFeatureTrialReportResult: DotNet ALAIFeatureTrialReportResult;
    begin
        if IsNullGuid(ConsumptionId) then
            Error(ConsumptionIdMustBeSpecifiedErr);
        if TrialId.Trim() = '' then
            Error(TrialIdMustBeSpecifiedErr);
        if PaidProductionQuotaLimit < 0 then
            Error(QuotaLimitsMustBeNonNegativeErr);
        if PaidSandboxQuotaLimit < 0 then
            Error(QuotaLimitsMustBeNonNegativeErr);
        if UnpaidProductionQuotaLimit < 0 then
            Error(QuotaLimitsMustBeNonNegativeErr);
        if UnpaidSandboxQuotaLimit < 0 then
            Error(QuotaLimitsMustBeNonNegativeErr);

        AIFeatureTrialReportResult := ALCopilotFunctions.ReportFeatureTrialQuota(
            ConsumptionId,
            TrialId,
            CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability),
            AIFeatureTrialRecurrenceType,
            PaidProductionQuotaLimit,
            PaidSandboxQuotaLimit,
            UnpaidProductionQuotaLimit,
            UnpaidSandboxQuotaLimit,
            0DT,
            Metadata);

        Session.LogMessage('0000VUW', StrSubstNo(FeatureTrialQuotaReportedTelemetryMsg, AIFeatureTrialReportResult.IsWithinQuota()), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        exit(AIFeatureTrialReportResult.IsReported());
    end;

    local procedure CheckCapabilityOwnership(CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo)
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Error(CapabilityNotRegisteredErr, CopilotCapability);
    end;
}