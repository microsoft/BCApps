// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.AI;

/// <summary>
/// Provides functionality for checking and reporting Copilot feature trial quota.
/// </summary>
codeunit 7755 "Copilot Feature Trial"
{
    Access = Public;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        CopilotFeatureTrialImpl: Codeunit "Copilot Feature Trial Impl.";

    /// <summary>
    /// Checks whether a feature trial has started.
    /// </summary>
    /// <param name="TrialId">The trial identifier.</param>
    /// <param name="CopilotCapability">The Copilot capability covered by the trial.</param>
    /// <returns>True if the feature trial has started; otherwise, false.</returns>
    [Scope('OnPrem')]
    procedure IsTrialStarted(TrialId: Text; CopilotCapability: Enum "Copilot Capability"): Boolean
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(CopilotFeatureTrialImpl.IsTrialStarted(TrialId, CopilotCapability, CallerModuleInfo));
    end;

    /// <summary>
    /// Gets the quota remaining for a feature trial.
    /// </summary>
    /// <param name="TrialId">The trial identifier.</param>
    /// <param name="CopilotCapability">The Copilot capability covered by the trial.</param>
    /// <returns>The quota remaining for the feature trial.</returns>
    /// <remarks>Check the return value of IsTrialStarted before calling this method. If the trial has not started, this procedure returns 0.</remarks>
    [Scope('OnPrem')]
    procedure GetQuotaRemaining(TrialId: Text; CopilotCapability: Enum "Copilot Capability"): Integer
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(CopilotFeatureTrialImpl.GetQuotaRemaining(TrialId, CopilotCapability, CallerModuleInfo));
    end;

    /// <summary>
    /// Checks whether a feature trial is not set up or has quota remaining.
    /// </summary>
    /// <param name="TrialId">The trial identifier.</param>
    /// <param name="CopilotCapability">The Copilot capability covered by the trial.</param>
    /// <returns>True if the trial quota has not been reported or has quota remaining; otherwise, false.</returns>
    [Scope('OnPrem')]
    procedure HasQuotaRemaining(TrialId: Text; CopilotCapability: Enum "Copilot Capability"): Boolean
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(CopilotFeatureTrialImpl.HasQuotaRemaining(TrialId, CopilotCapability, CallerModuleInfo));
    end;

    /// <summary>
    /// Reports a run to a feature trial whose quota is never replenished.
    /// </summary>
    /// <param name="ConsumptionId">The idempotency key for the run.</param>
    /// <param name="TrialId">The trial identifier.</param>
    /// <param name="CopilotCapability">The Copilot capability covered by the trial.</param>
    /// <param name="PaidProductionQuotaLimit">The quota limit for paid production environments.</param>
    /// <param name="PaidSandboxQuotaLimit">The quota limit for paid sandbox environments.</param>
    /// <param name="UnpaidProductionQuotaLimit">The quota limit for unpaid production environments.</param>
    /// <param name="UnpaidSandboxQuotaLimit">The quota limit for unpaid sandbox environments.</param>
    /// <param name="Metadata">Optional additional dimensions and details about the run.</param>
    /// <returns>True if the run was reported; otherwise, false.</returns>
    /// <remarks>A trial can only be non-recurring or monthly. Reporting a non-recurring run for a monthly trial causes a runtime error.</remarks>
    [Scope('OnPrem')]
    procedure ReportNonRecurringFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text): Boolean
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(CopilotFeatureTrialImpl.ReportNonRecurringFeatureTrialQuota(ConsumptionId, TrialId, CopilotCapability, PaidProductionQuotaLimit, PaidSandboxQuotaLimit, UnpaidProductionQuotaLimit, UnpaidSandboxQuotaLimit, Metadata, CallerModuleInfo));
    end;

    /// <summary>
    /// Reports a run to a feature trial whose quota is replenished monthly.
    /// </summary>
    /// <param name="ConsumptionId">The idempotency key for the run.</param>
    /// <param name="TrialId">The trial identifier.</param>
    /// <param name="CopilotCapability">The Copilot capability covered by the trial.</param>
    /// <param name="PaidProductionQuotaLimit">The quota limit for paid production environments.</param>
    /// <param name="PaidSandboxQuotaLimit">The quota limit for paid sandbox environments.</param>
    /// <param name="UnpaidProductionQuotaLimit">The quota limit for unpaid production environments.</param>
    /// <param name="UnpaidSandboxQuotaLimit">The quota limit for unpaid sandbox environments.</param>
    /// <param name="Metadata">Optional additional dimensions and details about the run.</param>
    /// <returns>True if the run was reported; otherwise, false.</returns>
    /// <remarks>A trial can only be non-recurring or monthly. Reporting a monthly run for a non-recurring trial causes a runtime error.</remarks>
    [Scope('OnPrem')]
    procedure ReportMonthlyFeatureTrialQuota(ConsumptionId: Guid; TrialId: Text; CopilotCapability: Enum "Copilot Capability"; PaidProductionQuotaLimit: Integer; PaidSandboxQuotaLimit: Integer; UnpaidProductionQuotaLimit: Integer; UnpaidSandboxQuotaLimit: Integer; Metadata: Text): Boolean
    var
        CallerModuleInfo: ModuleInfo;
    begin
        NavApp.GetCallerModuleInfo(CallerModuleInfo);
        exit(CopilotFeatureTrialImpl.ReportMonthlyFeatureTrialQuota(ConsumptionId, TrialId, CopilotCapability, PaidProductionQuotaLimit, PaidSandboxQuotaLimit, UnpaidProductionQuotaLimit, UnpaidSandboxQuotaLimit, Metadata, CallerModuleInfo));
    end;
}