// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;

codeunit 7786 "Copilot Quota Usage Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Copilot Settings" = rimd;

    var
        InvalidUsageTypeErr: Label 'The value "%1" is not a valid Copilot Quota Usage Type.', Comment = '%1=a value such as "AI response"';

    [Scope('OnPrem')]
    procedure LogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo)
    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotCapability: DotNet ALCopilotCapability;
        AlCopilotUsageType: DotNet ALCopilotUsageType;
    begin
        CopilotCapabilityImpl.IsCapabilityRegistered(CopilotCapability, CallerModuleInfo);

        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
            CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType(CopilotQuotaUsageType, AlCopilotUsageType);

        ALCopilotFunctions.LogCopilotQuotaUsage(AlCopilotCapability, Usage, AlCopilotUsageType);
    end;

    internal procedure UsageTypeToDotnetUsageType(CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; var AlCopilotUsageType: DotNet AlCopilotUsageType)
    begin
        case CopilotQuotaUsageType of
            CopilotQuotaUsageType::GenAIAnswer:
                AlCopilotUsageType := AlCopilotUsageType::GenAIAnswer;
            CopilotQuotaUsageType::AutonomousAction:
                AlCopilotUsageType := AlCopilotUsageType::AutonomousAction;
            else
                Error(InvalidUsageTypeErr, CopilotQuotaUsageType);
        end;
    end;
}