// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExpenseAgent;

/// <summary>
/// Catalogue of expense-feature capabilities reported by this BC environment.
///
/// Each value is the source of truth for one boolean capability exposed via
/// the Expense Capabilities API page. Adding a value here is not enough on
/// its own — you must also add a matching branch in
/// "Expense Capabilities Provider".IsEnabled so the provider knows how
/// to derive the state.
///
/// Convention: the value emitted in the API's capabilityName
/// field is the enum value identifier.
/// Captions are Locked = true.
/// </summary>
enum 6984 "Expense Capability"
{
    Access = Internal;
    Extensible = false;
    Caption = 'Expense Capability', Locked = true;

    /// <summary>
    /// Project / task association is available on expenses
    /// </summary>
    value(0; Projects)
    {
        Caption = 'Projects', Locked = true;
    }

    /// <summary>
    /// Per diem locations query is available in the expense app
    /// </summary>
    value(1; PerDiemLocations)
    {
        Caption = 'Per Diem Locations', Locked = true;
    }

    /// <summary>
    /// Consolidated assigned-projects API (projects with nested tasks) is available
    /// </summary>
    value(2; ConsolidatedProjects)
    {
        Caption = 'Consolidated Projects', Locked = true;
    }

    /// <summary>
    /// The backend supports AI-assisted policy evaluation (soft policy flags). Reported
    /// enabled only when the admin has turned on "Evaluate Policies" in the Expense Agent
    /// Setup. A backend that predates this feature omits the value entirely, so the frontend
    /// can treat an absent capability as "backend not ready".
    /// </summary>
    value(3; AiAssistedPolicyEvaluation)
    {
        Caption = 'AI-Assisted Policy Evaluation', Locked = true;
    }
}
