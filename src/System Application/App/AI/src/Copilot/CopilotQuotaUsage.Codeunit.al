// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// The Copilot Capability codeunit is used to register, modify, and delete Copilot capabilities.
/// </summary>
codeunit 7773 "Copilot Quota Usage"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotQuotaUsageImpl: Codeunit "Copilot Quota Usage Impl";

    /// <summary>
    /// 
    /// </summary>
    /// <param name="CopilotCapability"></param>
    /// <returns></returns>
    [TryFunction]
    [Scope('OnPrem')]
    procedure TryLogQuotaUsage(CopilotCapability: Enum "Copilot Capability")
    var
        ALCopilotFunctions: DotNet ALCopilotFunctions;
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotQuotaUsageImpl.LogQuotaUsage(CopilotCapability, CallerModuleInfo);
    end;
}