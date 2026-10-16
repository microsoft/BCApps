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
        PaidConsumptionIds: List of [Text];
        RemainingTrialQuota: Integer;
        PaidQuotaAvailable: Boolean;
        PaidQuotaCheckCount: Integer;
        TrialReportCount: Integer;
        PaidReportCount: Integer;
        LastTrialConsumptionId: Guid;
        LastTrialQuota: Integer;

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

    procedure IsConsumptionLogged(UniqueId: Text[1024]): Boolean
    begin
        exit(PaidConsumptionIds.Contains(UniqueId));
    end;

    procedure ReportTrialConsumption(ConsumptionId: Guid; Quota: Integer)
    begin
        TrialReportCount += 1;
        LastTrialConsumptionId := ConsumptionId;
        LastTrialQuota := Quota;
        if not TrialConsumptionIds.Contains(ConsumptionId) then begin
            TrialConsumptionIds.Add(ConsumptionId);
            RemainingTrialQuota -= 1;
        end;
    end;

    procedure LogPaidConsumption(Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; ActionsSummary: Text[1024]; ActionsDescription: Text; UniqueId: Text[1024])
    begin
        PaidReportCount += 1;
        if not PaidConsumptionIds.Contains(UniqueId) then
            PaidConsumptionIds.Add(UniqueId);
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
