// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.Analysis;

/// <summary>
/// Defines the source of accounts for analysis views to determine data source and processing logic.
/// Controls whether analysis views process G/L entries or cash flow forecast entries.
/// </summary>
enum 7133 "Analysis Account Source"
{
    Extensible = true;
    AssignmentCompatibility = true;

    /// <summary>
    /// Use G/L accounts as the source for analysis view data from general ledger entries.
    /// </summary>
    value(0; "G/L Account") { Caption = 'G/L Account'; }
    /// <summary>
    /// Use cash flow accounts as the source for analysis view data from cash flow forecast entries.
    /// </summary>
    value(1; "Cash Flow Account") { Caption = 'Cash Flow Account'; }
}
