// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Codeunit that exposes functionality related to Copilot Quota, such as logging quota usage
/// </summary>
codeunit 7785 "Copilot Quota"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotQuotaImpl: Codeunit "Copilot Quota Impl.";

    /// <summary>
    /// Try function to log usage of Copilot quota in the system. This function is only available for Microsoft Copilot features.
    /// </summary>
    /// <param name="CopilotCapability">The Copilot Capability to log usage for.</param>
    /// <param name="Usage">The usage to log.</param>
    /// <param name="CopilotQuotaUsageType">The type of Copilot Quota to log.</param>
    [TryFunction]
    [Scope('OnPrem')]
    procedure TryLogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotQuotaImpl.LogQuotaUsage(CopilotCapability, Usage, CopilotQuotaUsageType, CallerModuleInfo);
    end;

    /// <summary>
    /// Checks if the tenant is allowed to consume Copilot quota.
    /// </summary>
    /// <returns>True if allowed, false otherwise.</returns>
    procedure CanConsume(): Boolean
    begin
        exit(CopilotQuotaImpl.CanConsume());
    end;
}