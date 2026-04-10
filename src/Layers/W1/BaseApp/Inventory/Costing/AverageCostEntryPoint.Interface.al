// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing;

using Microsoft.Inventory.Ledger;
using System.Utilities;

interface "Average Cost Entry Point"
{
    /// <summary>
    /// The method find latest valuation date. 
    /// </summary>
    /// <param name="ItemLedgerEntry">Set Item Ledger Entry with data for search filters.</param>
    /// <param name="ValueEntry">Set Value Entry record which provide original Valuation Date for the search.</param>
    procedure GetMaxValuationDate(ItemLedgerEntry: Record "Item Ledger Entry"; ValueEntry: Record "Value Entry"): Date

    /// <summary>
    /// The method find valuation period for posting date. 
    /// </summary>
    /// <param name="CalendarPeriod">Date record for valuation period.</param>
    /// <param name="PostingDate">Set Posting Date for the search.</param>
    procedure GetValuationPeriod(var CalendarPeriod: Record Date; PostingDate: Date)

    /// <summary>
    /// The method delete average cost adjustment buffer records for selected Item and from Valuation Date. 
    /// </summary>
    /// <param name="ItemNo">Set Item No. fo filtering buffer records. Use blank value to skip this filter.</param>
    /// <param name="FromValuationDate">Set the filter from Valuation Date. Use 0D to skip this filter.</param>
    procedure DeleteBuffer(ItemNo: Code[20]; FromValuationDate: Date)

    /// <summary>
    /// The method check is all ledger entries have been adjusted for selected item and before ending date. 
    /// </summary>
    /// <param name="ItemNo">Set Item No. fo filtering buffer records. Use blank value to skip this filter.</param>
    /// <param name="EndingDate">Set the filter before Ending Date. Use 0D to skip this filter.</param>
    procedure IsEntriesAdjusted(ItemNo: Code[20]; EndingDate: Date): Boolean

    /// <summary>
    /// The method lock average cost adjustment buffer table. 
    /// </summary>
    procedure LockBuffer()

    /// <summary>
    /// The method update average cost adjustment buffer table based on data in value entry. 
    /// </summary>
    /// <param name="ValueEntry">Set parameter Value Entry with data for update.</param>
    procedure UpdateValuationDate(ValueEntry: Record "Value Entry")
}
