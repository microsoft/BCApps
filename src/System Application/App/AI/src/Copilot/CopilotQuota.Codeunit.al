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
    /// Log usage of Agent functionality. This function is only available for Microsoft Agents.
    /// Function will call the platform to log the usage of the agents. Charging will be handled by the platform afterwards.
    /// </summary>
    /// <param name="CopilotCapability">The Copilot Capability to log usage for.</param>
    /// <param name="Usage">The usage to log.</param>
    /// <param name="CopilotQuotaUsageType">The type of Copilot Quota to log.</param>
    /// <param name="AgentTaskID">The unique identifier of the Agent task.</param>
    /// <param name="ActionsCharged">The actions that were charged for this usage. This should be a short text, for example Quote Operation, Processed E-Document and etc...</param>
    /// <param name="Description">A description of the usage. This text is providing the additional information to ActionsCharged, for example specifying which operation was done on which quote or which e-document was processed.</param>
    /// <param name="UniqueID">A unique identifier for this log entry. Parameter is mandatory. This value is used to avoid double charging. Platform will check if we have the entry already logged and will not double charge. If you want to charge always use CreateGuid() or a strategy that will always issue a charge.</param>
    [Scope('OnPrem')]
    procedure LogAgentUserAIConsumption(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; AgentTaskID: BigInteger; ActionsCharged: Text[1024]; Description: Text; UniqueID: Text[1024])
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotQuotaImpl.LogAgentUserAIConsumption(CopilotCapability, Usage, CopilotQuotaUsageType, CallerModuleInfo, AgentTaskID, ActionsCharged, Description, UniqueID);
    end;

    /// <summary>
    /// Checks if the Agent usage with the given UniqueID has already been logged.
    /// </summary>
    /// <param name="UniqueID">A unique identifier for this log entry. Parameter is mandatory. This value is used to avoid double charging. Platform will check if we have the entry already logged and will not double charge. If you want to charge always use CreateGuid() or a strategy that will always issue a charge.</param>
    /// <returns>True if the usage has already been logged, false otherwise.</returns>
    [Scope('OnPrem')]
    procedure IsAgentUserAIConsumptionLogged(UniqueID: Text[1024]): Boolean
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(CopilotQuotaImpl.IsAgentUserAIConsumptionLogged(UniqueID));
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