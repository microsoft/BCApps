// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

using System.AI;

interface "Expense Agent Quota"
{
    Access = Internal;

    procedure IsTrialStarted(): Boolean;
    procedure GetRemainingTrialQuota(): Integer;
    procedure TrialQuotaAvailable(): Boolean;
    procedure CanConsumePaidQuota(): Boolean;
    procedure CanConsumePaidQuota(ConsumptionEntraPrincipalId: Guid): Boolean;
    procedure IsConsumptionLogged(UniqueId: Text[1024]): Boolean;
    procedure ReportTrialConsumption(ConsumptionId: Guid; Quota: Integer);
    procedure LogConsumption(Usage: Integer; CopilotQuotaUsageType: Enum "Copilot Quota Usage Type"; ActionsSummary: Text[1024]; ActionsDescription: Text; UniqueId: Text[1024]; ExcludeFromBilling: Boolean);
    procedure RecordConsumption(ConsumptionId: Guid; ConsumptionSessionId: Guid; InteractionId: Guid; ConsumptionUsagePayload: Text; ConsumptionEntraPrincipalId: Guid; ConsumptionEntraPrincipalDisplayName: Text; Description: Text; IsFeatureTrial: Boolean);
}
