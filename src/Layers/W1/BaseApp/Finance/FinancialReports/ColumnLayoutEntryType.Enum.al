// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.FinancialReports;

/// <summary>
/// Defines data source types for column layout calculations in financial reports.
/// Controls whether columns use actual or budget entries for amount calculations.
/// </summary>
enum 332 "Column Layout Entry Type"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Uses actual posted general ledger entries for column calculations.
    /// </summary>
    value(0; "Entries")
    {
        Caption = 'Entries';
    }
    /// <summary>
    /// Uses budget entries for column calculations and comparisons.
    /// </summary>
    value(1; "Budget Entries")
    {
        Caption = 'Budget Entries';
    }
}
