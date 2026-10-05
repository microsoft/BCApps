// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

codeunit 7754 "Copilot Feature Trial Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        CapabilityNotRegisteredErr: Label 'The Copilot capability ''%1'' has not been registered or was registered by another app.', Comment = '%1 is the name of the Copilot capability';
        FeatureTrialQuotaReportedTelemetryMsg: Label 'Feature trial quota report completed. The run was within quota: %1.', Locked = true;

    procedure GetFeatureTrialQuotaRemaining(TrialId: Text; CopilotCapability: Enum "Copilot Capability"; CallerModuleInfo: ModuleInfo): Boolean
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AIFeatureTrialInfo: DotNet ALAIFeatureTrialInfo;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        AIFeatureTrialInfo := ALCopilotFunctions.GetFeatureTrialQuotaRemaining(TrialId, CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));
        exit(AIFeatureTrialInfo.IsSetup() and AIFeatureTrialInfo.HasQuotaRemaining());
    end;

    procedure ReportNonRecurringFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text; CallerModuleInfo: ModuleInfo): Boolean
    var
        AIFeatureTrialRecurrenceType: DotNet ALAIFeatureTrialRecurrenceType;
    begin
        CheckCapabilityOwnership(CopilotCapability, CallerModuleInfo);
        AIFeatureTrialRecurrenceType := AIFeatureTrialRecurrenceType::None;
        exit(ReportFeatureTrialQuota(ConsumptionId, TrialId, CopilotCapability, AIFeatureTrialRecurrenceType, PaidProductionQuotaLimit, PaidSandboxQuotaLimit, UnpaidProductionQuotaLimit, UnpaidSandboxQuotaLimit, Metadata));
    end;

    procedure ReportMonthlyFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text; CallerModuleInfo: ModuleInfo): Boolean
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