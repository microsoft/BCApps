// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Environment.Consumption;

codeunit 7786 "Copilot Quota Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "AI Consumption Log Entry" = r;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        InvalidUsageTypeErr: Label 'The value "%1" is not a valid Copilot Quota Usage Type.', Comment = '%1=a value such as "AI response" or "5"';
        CapabilityNotRegisteredTelemetryMsg: Label 'Capability "%1" is not registered in the system but is logging usage.', Locked = true;
        LoggingUsageTelemetryMsg: Label 'Capability "%1" is logging %2 usage of type %3, excluded from billing: %4.', Locked = true;

    trigger OnRun()
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        ALCopilotQuotaDetails: Dotnet ALCopilotQuotaDetails;
        Results: Dictionary of [Text, Text];
    begin
        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();

        if IsNull(ALCopilotQuotaDetails) then
            exit;

        Results.Add('CanConsume', Format(ALCopilotQuotaDetails.CanConsume()));
        Results.Add('HasSetupBilling', Format(ALCopilotQuotaDetails.HasSetupBilling()));
        Results.Add('QuotaUsedPercentage', Format(ALCopilotQuotaDetails.QuotaUsedPercentage()));

        Page.SetBackgroundTaskResult(Results);
    end;

    procedure CanConsume(): Boolean
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AIConsumptionQuotaResult: DotNet ALAIConsumptionQuotaResult;
#if not CLEAN30
        ALCopilotQuotaDetails: Dotnet ALCopilotQuotaDetails;
#endif
        CanConsumeQuota: Boolean;
        UnableToRetrieveQuotaDetailsLbl: Label 'Unable to retrieve quota details for tenant', locked = true;
        IsTenantAllowedToConsumeQuotaLbl: Label 'Is tenant allowed to consume quota: %1', locked = true, Comment = '%1 = true/false';
    begin
#if not CLEAN30
        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();

        if IsNull(ALCopilotQuotaDetails) then
            Session.LogMessage('0000P7N', UnableToRetrieveQuotaDetailsLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory())
        else
            CanConsumeQuota := ALCopilotQuotaDetails.CanConsume();
#endif

        AIConsumptionQuotaResult := ALCopilotFunctions.GetAIConsumptionQuota();
        if IsNull(AIConsumptionQuotaResult) then
            Session.LogMessage('0000P7N', UnableToRetrieveQuotaDetailsLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory())
        else
            CanConsumeQuota := CanConsumeQuota or AIConsumptionQuotaResult.CanConsume();

        Session.LogMessage('0000P7O', StrSubstNo(IsTenantAllowedToConsumeQuotaLbl, Format(CanConsumeQuota)), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory());

        exit(CanConsumeQuota);
    end;

#if not CLEAN30
    [Obsolete('Use LogAgentUserAIConsumption instead.', '30.0')]
    procedure LogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotCapability: DotNet ALCopilotCapability;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000OSL', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('0000OSM', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType, false), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
            CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogCopilotQuotaUsage(AlCopilotCapability, Usage, AlCopilotUsageType);
    end;
#endif

    procedure LogAgentUserAIConsumption(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo; AgentTaskID: BigInteger; ActionsCharged: Text[1024]; Description: Text; UniqueID: Text[1024]; ExcludeFromBilling: Boolean)
    var
        AlCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000QIY', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('0000QIZ', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType, ExcludeFromBilling), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
                 CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogAgentUserAIConsumptionAsync(
            ALCopilotCapability,
            AgentTaskID,
            ActionsCharged,
            Description,
            AlCopilotUsageType,
            Usage,
            UniqueID,
            ExcludeFromBilling
        );
    end;

    procedure RecordAIConsumption(CopilotCapability: Enum "Copilot Capability"; ConsumptionId: Guid; ConsumptionSessionId: Guid; InteractionId: Guid; CorrelationId: Guid; ConsumptionUsagePayload: Text; ConsumptionEntraPrincipalId: Guid; ConsumptionEntraPrincipalDisplayName: Text; AgentTaskId: BigInteger; Metadata: Text; Description: Text; IsFeatureTrial: Boolean; CallerModuleInfo: ModuleInfo)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AgentPublisherType: DotNet ALAgentPublisherType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000QIY', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        if CallerModuleInfo.Publisher() = 'Microsoft' then
            AgentPublisherType := AgentPublisherType::FirstParty
        else
            AgentPublisherType := AgentPublisherType::ThirdParty;

        ALCopilotFunctions.RecordAIConsumption(
            ConsumptionId,
            ConsumptionSessionId,
            InteractionId,
            CorrelationId,
            CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability),
            AgentPublisherType,
            CallerModuleInfo.Id(),
            ConsumptionUsagePayload,
            ConsumptionEntraPrincipalId,
            ConsumptionEntraPrincipalDisplayName,
            AgentTaskId,
            Metadata,
            Description,
            IsFeatureTrial);
    end;

    procedure IsAIConsumptionRecorded(ConsumptionId: Guid): Boolean
    var
        AIConsumptionLogEntry: Record "AI Consumption Log Entry";
    begin
        exit(AIConsumptionLogEntry.GetBySystemId(ConsumptionId));
    end;

    procedure IsAgentUserAIConsumptionLogged(UniqueID: Text[1024]): Boolean
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
    begin
        exit(ALCopilotFunctions.IsAgentUserAIConsumptionLogged(UniqueID));
    end;

    local procedure UsageTypeToDotnetUsageType(CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; var AlCopilotUsageType: DotNet AlCopilotUsageType)
    begin
        case CopilotQuotaUsageType of
            CopilotQuotaUsageType::"Generative AI Answer":
                AlCopilotUsageType := AlCopilotUsageType::GenAIAnswer;
            CopilotQuotaUsageType::"Autonomous Action":
                AlCopilotUsageType := AlCopilotUsageType::AutonomousAction;
            else
                Error(InvalidUsageTypeErr, CopilotQuotaUsageType);
        end;
    end;
}