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
        InvalidUsageTypeErr: Label 'The value "%1" is not a valid Copilot Quota Usage Type.', Comment = '%1=a value such as "AI response" or "5"';
        CapabilityNotRegisteredTelemetryMsg: Label 'Capability "%1" is not registered in the system but is logging usage.', Locked = true;
        LoggingUsageTelemetryMsg: Label 'Capability "%1" is logging %2 usage of type %3.', Locked = true;

    [Scope('OnPrem')]
    procedure LogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo)
    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotCapability: DotNet ALCopilotCapability;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        if not CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo) then
            Session.LogMessage('', StrSubstNo(CapabilityNotRegisteredTelemetryMsg, CopilotCapability), Verbosity::Warning, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        Session.LogMessage('', StrSubstNo(LoggingUsageTelemetryMsg, CopilotCapability, Usage, CopilotQuotaUsageType), Verbosity::Verbose, DataClassification::SystemMetadata, TelemetryScope::ExtensionPublisher, 'Category', CopilotCapabilityImpl.GetCopilotCategory());

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
            CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogCopilotQuotaUsage(AlCopilotCapability, Usage, AlCopilotUsageType);
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