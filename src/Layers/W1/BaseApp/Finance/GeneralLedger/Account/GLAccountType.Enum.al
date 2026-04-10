// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Account;

/// <summary>
/// Defines the structural types of general ledger accounts for chart of accounts hierarchy and posting capabilities.
/// Determines which accounts can receive direct postings and which are used for organizational structure.
/// </summary>
enum 16 "G/L Account Type"
{
    AssignmentCompatibility = true;
    Extensible = false;

    /// <summary>
    /// Account that accepts direct transaction postings and maintains balance information.
    /// </summary>
    value(0; Posting)
    {
        Caption = 'Posting';
    }
    /// <summary>
    /// Organizational account used for grouping related accounts in the chart of accounts display.
    /// </summary>
    value(1; Heading)
    {
        Caption = 'Heading';
    }
    /// <summary>
    /// Account that calculates totals from underlying accounts based on totaling range specification.
    /// </summary>
    value(2; Total)
    {
        Caption = 'Total';
    }
    /// <summary>
    /// Starting marker for a totaling range defining the beginning of accounts to be included in calculations.
    /// </summary>
    value(3; "Begin-Total")
    {
        Caption = 'Begin-Total';
    }
    /// <summary>
    /// Ending marker for a totaling range that performs the actual total calculation of accounts from Begin-Total.
    /// </summary>
    value(4; "End-Total")
    {
        Caption = 'End-Total';
    }
}
