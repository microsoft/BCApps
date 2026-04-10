// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines display options for column layout values in account schedule reports.
/// Controls when column values are shown based on their sign and magnitude in financial reporting.
/// </summary>
/// <remarks>
/// Used by Column Layout table to control value display behavior in account schedule calculations.
/// Supports conditional formatting for positive, negative, and zero values in financial reports.
/// </remarks>
enum 334 "Column Layout Show"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Always displays column values regardless of sign or magnitude.
    /// </summary>
    value(0; "Always") { Caption = 'Always'; }

    /// <summary>
    /// Never displays column values, effectively hiding the column content.
    /// </summary>
    value(1; "Never") { Caption = 'Never'; }

    /// <summary>
    /// Displays column values only when they are positive, zero values shown as blank.
    /// </summary>
    value(2; "When Positive") { Caption = 'When Positive'; }

    /// <summary>
    /// Displays column values only when they are negative, zero values shown as blank.
    /// </summary>
    value(3; "When Negative") { Caption = 'When Negative'; }
}
