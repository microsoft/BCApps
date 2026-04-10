// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

/// <summary>
/// Defines the methods used to calculate interest on overdue amounts for finance charges and reminders.
/// </summary>
enum 5 "Interest Calculation Method"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Specifies that interest is calculated based on the average daily balance over the period.
    /// </summary>
    value(0; "Average Daily Balance") { Caption = 'Average Daily Balance'; }
    /// <summary>
    /// Specifies that interest is calculated based on the total balance due at the end of the period.
    /// </summary>
    value(1; "Balance Due") { Caption = 'Balance Due'; }
}
