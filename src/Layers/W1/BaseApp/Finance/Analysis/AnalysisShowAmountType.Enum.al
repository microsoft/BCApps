// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Defines amount types for displaying financial data in analysis reports and matrices.
/// Controls how amounts are calculated and presented in budget vs. actual comparisons.
/// </summary>
enum 747 "Analysis Show Amount Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Display actual transaction amounts from posted entries.
    /// </summary>
    value(0; "Actual Amounts") { Caption = 'Actual Amounts'; }
    /// <summary>
    /// Display budgeted amounts from budget entries.
    /// </summary>
    value(1; "Budgeted Amounts") { Caption = 'Budgeted Amounts'; }
    /// <summary>
    /// Display variance calculated as actual amounts minus budgeted amounts.
    /// </summary>
    value(2; "Variance") { Caption = 'Variance'; }
    /// <summary>
    /// Display variance percentage calculated as variance divided by budgeted amounts.
    /// </summary>
    value(3; "Variance%") { Caption = 'Variance%'; }
    /// <summary>
    /// Display index percentage calculated as actual amounts divided by budgeted amounts.
    /// </summary>
    value(4; "Index%") { Caption = 'Index%'; }
}
