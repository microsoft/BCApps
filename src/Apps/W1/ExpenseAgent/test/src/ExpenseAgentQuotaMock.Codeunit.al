// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Test.ExpenseAgent;

using Microsoft.ExpenseAgent;
using System.AI;

codeunit 148332 "Expense Agent Quota Mock" implements "Expense Agent Quota"
{
    Access = Internal;

    var
        TrialConsumptionIds: List of [Guid];
        V1ConsumptionIds: List of [Text];
        V2ConsumptionIds: List of [Guid];
        V1RecordingEnabled: Boolean;
        UseV1Pipeline: Boolean;
        SkipV2Recording: Boolean;
        RemainingTrialQuota: Integer;
        PaidQuotaAvailable: Boolean;
        PaidQuotaCheckCount: Integer;
        LastPaidQuotaPrincipalId: Guid;
        TrialReportCount: Integer;
        PaidReportCount: Integer;
        LastTrialConsumptionId: Guid;
        LastTrialQuota: Integer;
        V1ReportCount: Integer;
        V2ReportCount: Integer;
        LastV1UniqueId: Text[1024];
        LastV1Usage: Integer;
        LastV1UsageType: Enum "Copilot Quota Usage Type";
        LastV1ActionsSummary: Text[1024];
        LastV1ActionsDescription: Text;
        LastV1ExcludedFromBilling: Boolean;
        LastV2ConsumptionId: Guid;
        LastV2SessionId: Guid;
        LastV2InteractionId: Guid;
        LastV2Payload: Text;
        LastV2PrincipalId: Guid;
        LastV2PrincipalDisplayName: Text;
        LastV2Description: Text;
        LastV2IsFeatureTrial: Boolean;
        FailV2Reporting: Boolean;
        FailTrialReporting: Boolean;
        V2ReportingFailedErr: Label 'V2 consumption reporting failed.', Locked = true;
        TrialReportingFailedErr: Label 'Trial consumption reporting failed.', Locked = true;

    procedure IsTrialStarted(): Boolean
    begin
        exit(TrialConsumptionIds.Count() > 0);
    end;

    procedure GetRemainingTrialQuota(): Integer
    begin
        exit(RemainingTrialQuota);
    end;

    procedure TrialQuotaAvailable(): Boolean
    begin
        exit(RemainingTrialQuota > 0);
    end;

    procedure CanConsumePaidQuota(): Boolean
    begin
        PaidQuotaCheckCount += 1;
        exit(PaidQuotaAvailable);
    end;

    procedure IsV2ConsumptionActive(): Boolean
    begin
        exit(not UseV1Pipeline);
    end;

    procedure CanConsumePaidQuota(ConsumptionEntraPrincipalId: Guid): Boolean
    begin
        LastPaidQuotaPrincipalId := ConsumptionEntraPrincipalId;
        exit(CanConsumePaidQuota());
    end;

    procedure IsConsumptionLogged(UniqueId: Text[1024]): Boolean
    begin
        exit(V1ConsumptionIds.Contains(UniqueId));
    end;

    procedure IsV2ConsumptionRecorded(ConsumptionId: Guid): Boolean
    begin
        exit(V2ConsumptionIds.Contains(ConsumptionId));
    end;

    procedure ReportTrialConsumption(ConsumptionId: Guid; Quota: Integer)
    begin
        if FailTrialReporting then
            Error(TrialReportingFailedErr);
        TrialReportCount += 1;
        LastTrialConsumptionId := ConsumptionId;
        LastTrialQuota := Quota;
        if not TrialConsumptionIds.Contains(ConsumptionId) then begin
            TrialConsumptionIds.Add(ConsumptionId);
            RemainingTrialQuota -= 1;
        end;
    end;

    procedure LogConsumption(Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; ActionsSummary: Text[1024]; ActionsDescription: Text; UniqueId: Text[1024]; ExcludeFromBilling: Boolean)
    begin
        V1ReportCount += 1;
        LastV1UniqueId := UniqueId;
        LastV1Usage := Usage;
        LastV1UsageType := CopilotQuotaUsageType;
        LastV1ActionsSummary := ActionsSummary;
        LastV1ActionsDescription := ActionsDescription;
        LastV1ExcludedFromBilling := ExcludeFromBilling;
        if V1RecordingEnabled then
            if not V1ConsumptionIds.Contains(UniqueId) then
                V1ConsumptionIds.Add(UniqueId);
        if ExcludeFromBilling then
            exit;

        PaidReportCount += 1;
    end;

    procedure RecordConsumption(ConsumptionId: Guid; ConsumptionSessionId: Guid; InteractionId: Guid; ConsumptionUsagePayload: Text; ConsumptionEntraPrincipalId: Guid; ConsumptionEntraPrincipalDisplayName: Text; Description: Text; IsFeatureTrial: Boolean)
    begin
        V2ReportCount += 1;
        LastV2ConsumptionId := ConsumptionId;
        LastV2SessionId := ConsumptionSessionId;
        LastV2InteractionId := InteractionId;
        LastV2Payload := ConsumptionUsagePayload;
        LastV2PrincipalId := ConsumptionEntraPrincipalId;
        LastV2PrincipalDisplayName := ConsumptionEntraPrincipalDisplayName;
        LastV2Description := Description;
        LastV2IsFeatureTrial := IsFeatureTrial;
        if FailV2Reporting then
            Error(V2ReportingFailedErr);
        if not SkipV2Recording then
            if not V2ConsumptionIds.Contains(ConsumptionId) then
                V2ConsumptionIds.Add(ConsumptionId);
    end;

    internal procedure SetV1RecordingEnabled(IsEnabled: Boolean)
    begin
        V1RecordingEnabled := IsEnabled;
    end;

    internal procedure SetV2ConsumptionActive(IsActive: Boolean)
    begin
        UseV1Pipeline := not IsActive;
    end;

    internal procedure SetV2RecordingEnabled(IsEnabled: Boolean)
    begin
        SkipV2Recording := not IsEnabled;
    end;

    internal procedure SetFailV2Reporting(ShouldFail: Boolean)
    begin
        FailV2Reporting := ShouldFail;
    end;

    internal procedure SetFailTrialReporting(ShouldFail: Boolean)
    begin
        FailTrialReporting := ShouldFail;
    end;

    internal procedure GetV1ReportCount(): Integer
    begin
        exit(V1ReportCount);
    end;

    internal procedure GetV2ReportCount(): Integer
    begin
        exit(V2ReportCount);
    end;

    internal procedure GetLastV1UniqueId(): Text[1024]
    begin
        exit(LastV1UniqueId);
    end;

    internal procedure GetLastV1Usage(var Usage: Integer; var CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; var ActionsSummary: Text[1024]; var ActionsDescription: Text)
    begin
        Usage := LastV1Usage;
        CopilotQuotaUsageType := LastV1UsageType;
        ActionsSummary := LastV1ActionsSummary;
        ActionsDescription := LastV1ActionsDescription;
    end;

    internal procedure GetLastV1ExcludedFromBilling(): Boolean
    begin
        exit(LastV1ExcludedFromBilling);
    end;

    internal procedure GetLastV2ConsumptionId(): Guid
    begin
        exit(LastV2ConsumptionId);
    end;

    internal procedure GetLastV2Context(var ConsumptionSessionId: Guid; var InteractionId: Guid; var ConsumptionUsagePayload: Text; var ConsumptionEntraPrincipalId: Guid; var ConsumptionEntraPrincipalDisplayName: Text; var Description: Text; var IsFeatureTrial: Boolean)
    begin
        ConsumptionSessionId := LastV2SessionId;
        InteractionId := LastV2InteractionId;
        ConsumptionUsagePayload := LastV2Payload;
        ConsumptionEntraPrincipalId := LastV2PrincipalId;
        ConsumptionEntraPrincipalDisplayName := LastV2PrincipalDisplayName;
        Description := LastV2Description;
        IsFeatureTrial := LastV2IsFeatureTrial;
    end;

    internal procedure SetTrialQuota(Quota: Integer)
    begin
        RemainingTrialQuota := Quota;
    end;

    internal procedure SetPaidQuotaAvailable(IsAvailable: Boolean)
    begin
        PaidQuotaAvailable := IsAvailable;
    end;

    internal procedure GetPaidQuotaCheckCount(): Integer
    begin
        exit(PaidQuotaCheckCount);
    end;

    internal procedure GetLastPaidQuotaPrincipalId(): Guid
    begin
        exit(LastPaidQuotaPrincipalId);
    end;

    internal procedure GetTrialReportCount(): Integer
    begin
        exit(TrialReportCount);
    end;

    internal procedure GetPaidReportCount(): Integer
    begin
        exit(PaidReportCount);
    end;

    internal procedure GetLastTrialConsumptionId(): Guid
    begin
        exit(LastTrialConsumptionId);
    end;

    internal procedure GetLastTrialQuota(): Integer
    begin
        exit(LastTrialQuota);
    end;
}
