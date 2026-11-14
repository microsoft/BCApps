// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Codeunit that exposes functionality related to Copilot Quota, such as logging quota usage
/// </summary>
/// <remarks>
/// During migration, callers must log the same consumption using both the V1 and V2 consumption pipelines.
/// The platform selects the active pipeline and switches to V2 on the configured activation date.
/// </remarks>
codeunit 7785 "Copilot Quota"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotQuotaImpl: Codeunit "Copilot Quota Impl.";

#if not CLEAN30
    /// <summary>
    /// Try function to log usage of Copilot quota in the system. This function is only available for Microsoft Copilot features.
    /// </summary>
    /// <param name="CopilotCapability">The Copilot Capability to log usage for.</param>
    /// <param name="Usage">The usage to log.</param>
    /// <param name="CopilotQuotaUsageType">The type of Copilot Quota to log.</param>
    /// <remarks>Uses the V1 consumption pipeline.</remarks>
    [TryFunction]
    [Scope('OnPrem')]
    [Obsolete('Use LogAgentUserAIConsumption instead.', '30.0')]
    procedure TryLogQuotaUsage(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type")
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
#pragma warning disable AL0432
        CopilotQuotaImpl.LogQuotaUsage(CopilotCapability, Usage, CopilotQuotaUsageType, CallerModuleInfo);
#pragma warning restore AL0432
    end;
#endif

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
    /// <remarks>Uses the V1 consumption pipeline. During migration, also call RecordAIConsumption for the same consumption.</remarks>
    [Scope('OnPrem')]
    procedure LogAgentUserAIConsumption(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; AgentTaskID: BigInteger; ActionsCharged: Text[1024]; Description: Text; UniqueID: Text[1024])
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotQuotaImpl.LogAgentUserAIConsumption(CopilotCapability, Usage, CopilotQuotaUsageType, CallerModuleInfo, AgentTaskID, ActionsCharged, Description, UniqueID, false);
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
    /// <param name="ExcludeFromBilling">If true, the usage will be logged but excluded from billing.</param>
    /// <remarks>Uses the V1 consumption pipeline. During migration, also call RecordAIConsumption for the same consumption.</remarks>
    [Scope('OnPrem')]
    procedure LogAgentUserAIConsumption(CopilotCapability: Enum "Copilot Capability"; Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; AgentTaskID: BigInteger; ActionsCharged: Text[1024]; Description: Text; UniqueID: Text[1024]; ExcludeFromBilling: Boolean)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotQuotaImpl.LogAgentUserAIConsumption(CopilotCapability, Usage, CopilotQuotaUsageType, CallerModuleInfo, AgentTaskID, ActionsCharged, Description, UniqueID, ExcludeFromBilling);
    end;

    /// <summary>
    /// Records AI consumption using the V2 consumption pipeline.
    /// </summary>
    /// <param name="CopilotCapability">The Copilot capability that consumed AI resources. Its enum name identifies the billing resource.</param>
    /// <param name="ConsumptionId">The idempotency key for the consumption entry. Reuse this ID when retrying the same consumption.</param>
    /// <param name="ConsumptionSessionId">The logical consumption session ID, such as the ID of an agent conversation.</param>
    /// <param name="InteractionId">The interaction ID, such as the ID of a turn in an agent conversation.</param>
    /// <param name="CorrelationId">The operation correlation ID for end-to-end diagnostics.</param>
    /// <param name="ConsumptionUsagePayload">The JSON text containing the structured consumption usage dimensions.</param>
    /// <param name="ConsumptionEntraPrincipalId">The Entra principal to which consumption is attributed. Leave this ID and the display name empty to request identity lookup.</param>
    /// <param name="ConsumptionEntraPrincipalDisplayName">The principal display name. It must be nonblank when a principal ID is supplied.</param>
    /// <param name="AgentTaskId">The related agent task ID, or zero when not applicable.</param>
    /// <param name="Metadata">Optional metadata about the consumption. Pass blank text when not applicable.</param>
    /// <param name="Description">An optional description of the consumed work. Pass blank text when not applicable.</param>
    /// <param name="IsFeatureTrial">Whether this consumption belongs to a feature trial.</param>
    /// <remarks>Uses the V2 consumption pipeline. During migration, also call LogAgentUserAIConsumption for the same consumption.</remarks>
    [Scope('OnPrem')]
    procedure RecordAIConsumption(CopilotCapability: Enum "Copilot Capability"; ConsumptionId: Guid; ConsumptionSessionId: Guid; InteractionId: Guid; CorrelationId: Guid; ConsumptionUsagePayload: Text; ConsumptionEntraPrincipalId: Guid; ConsumptionEntraPrincipalDisplayName: Text; AgentTaskId: BigInteger; Metadata: Text; Description: Text; IsFeatureTrial: Boolean)
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        CopilotQuotaImpl.RecordAIConsumption(CopilotCapability, ConsumptionId, ConsumptionSessionId, InteractionId, CorrelationId, ConsumptionUsagePayload, ConsumptionEntraPrincipalId, ConsumptionEntraPrincipalDisplayName, AgentTaskId, Metadata, Description, IsFeatureTrial, CallerModuleInfo);
    end;

    /// <summary>
    /// Checks if AI consumption with the given ConsumptionId has been recorded in the V2 consumption ledger.
    /// </summary>
    /// <param name="ConsumptionId">The idempotency key supplied when recording V2 consumption.</param>
    /// <returns>True if the V2 consumption entry exists; otherwise, false.</returns>
    /// <remarks>Checks consumption recorded through the V2 consumption pipeline only.</remarks>
    [Scope('OnPrem')]
    procedure IsAIConsumptionRecorded(ConsumptionId: Guid): Boolean
    begin
        exit(CopilotQuotaImpl.IsAIConsumptionRecorded(ConsumptionId));
    end;

    /// <summary>
    /// Checks if the Agent usage with the given UniqueID has already been logged.
    /// </summary>
    /// <param name="UniqueID">A unique identifier for this log entry. Parameter is mandatory. This value is used to avoid double charging. Platform will check if we have the entry already logged and will not double charge. If you want to charge always use CreateGuid() or a strategy that will always issue a charge.</param>
    /// <returns>True if the usage has already been logged, false otherwise.</returns>
    /// <remarks>Checks consumption logged through the V1 consumption pipeline only.</remarks>
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
    /// <remarks>Checks both V1 and V2 consumption quota and returns true if either pipeline allows consumption.</remarks>
    procedure CanConsume(): Boolean
    begin
        exit(CopilotQuotaImpl.CanConsume());
    end;
}