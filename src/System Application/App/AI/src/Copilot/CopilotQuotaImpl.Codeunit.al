// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

codeunit 7786 "Copilot Quota Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        InvalidUsageTypeErr: Label 'The value "%1" is not a valid Copilot Quota Usage Type.', Comment = '%1=a value such as "AI response" or "5"';
        CapabilityNotRegisteredTelemetryMsg: Label 'Capability "%1" is not registered in the system but is logging usage.', Locked = true;
        LoggingUsageTelemetryMsg: Label 'Capability "%1" is logging %2 usage of type %3.', Locked = true;

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
        ALCopilotQuotaDetails: Dotnet ALCopilotQuotaDetails;
        UnableToRetrieveQuotaDetailsLbl: Label 'Unable to retrieve quota details for tenant', locked = true;
        IsTenantAllowedToConsumeQuotaLbl: Label 'Is tenant allowed to consume quota: %1', locked = true, Comment = '%1 = true/false';
    begin
        ALCopilotQuotaDetails := ALCopilotFunctions.GetCopilotQuotaDetails();

        if IsNull(ALCopilotQuotaDetails) then begin
            Session.LogMessage('0000P7N', UnableToRetrieveQuotaDetailsLbl, Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory());
            exit(false);
        end;

        Session.LogMessage('0000P7O', StrSubstNo(IsTenantAllowedToConsumeQuotaLbl, Format(ALCopilotQuotaDetails.CanConsume())), Verbosity::Normal, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'category', CopilotCapabilityImpl.GetCopilotCategory());

        exit(ALCopilotQuotaDetails.CanConsume());
    end;

    procedure LogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo)
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotCapability: DotNet ALCopilotCapability;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000OSL', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('0000OSM', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
            CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogCopilotQuotaUsage(AlCopilotCapability, Usage, AlCopilotUsageType);
    end;

    procedure LogAgentUserAIConsumption(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo; AgentTaskID: BigInteger; ActionsCharged: Text[1024]; Description: Text; UniqueID: Text[1024])
    var
        AlCopilotCapability: DotNet ALCopilotCapability;
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('0000QIY', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('0000QIZ', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

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
            UniqueID
        );
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