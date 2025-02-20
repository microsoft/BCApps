// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

using System;
using System.Azure.Identity;
using System.Azure.KeyVault;
using System.Environment;
using System.Environment.Configuration;
using System.Globalization;
using System.Privacy;
using System.Security.User;
using System.Telemetry;

codeunit 7774 "Copilot Quota Usage Impl"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "Copilot Settings" = rimd;

    [Scope('OnPrem')]
    procedure LogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; UsageType: Enum "Copilot Quota Usage Type"; CallerModuleInfo: ModuleInfo)
    var
        CopilotCapabilityImpl: Codeunit "Copilot Capability Impl";
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        AlCopilotCapability: DotNet ALCopilotCapability;
        AlCopilotUsageType: DotNet AlCopilotUsageType;
    begin
        ALCopilotCapability := ALCopilotCapability.ALCopilotCapability(
            CallerModuleInfo.Publisher(), CallerModuleInfo.Id(), Format(CallerModuleInfo.AppVersion()), CopilotCapabilityImpl.CapabilityToEnumName(CopilotCapability));

        UsageTypeToDotnetUsageType();

        ALCopilotFunctions.LogQuotaUsage(AlCopilotCapability, Usage,);
    end;

    internal procedure UsageTypeToDotnetUsageType(var d: DotNet )
    begin

    end;
}