// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Deferral;

/// <summary>
/// Defines the calculation methods available for distributing deferred amounts across periods.
/// Determines how the total deferral amount is split among the scheduled recognition periods.
/// </summary>
enum 1700 "Deferral Calculation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Distributes amounts proportionally based on period length with adjustments for partial periods.
    /// </summary>
    value(0; "Straight-Line") { Caption = 'Straight-Line'; }
    /// <summary>
    /// Distributes the total amount equally across all periods regardless of period length.
    /// </summary>
    value(1; "Equal per Period") { Caption = 'Equal per Period'; }
    /// <summary>
    /// Distributes amounts based on the actual number of days in each accounting period.
    /// </summary>
    value(2; "Days per Period") { Caption = 'Days per Period'; }
    /// <summary>
    /// Allows manual specification of amounts for each period in the deferral schedule.
    /// </summary>
    value(3; "User-Defined") { Caption = 'User-Defined'; }
}
