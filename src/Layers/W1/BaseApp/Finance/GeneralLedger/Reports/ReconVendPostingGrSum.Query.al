// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.GeneralLedger.Reports;

using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Vendor;

/// <summary>
/// Aggregates Detailed Vendor Ledger Entry amounts in a single SQL round-trip by JOINing to Vendor
/// for entries with a blank "Posting Group" (legacy/upgraded data). Used by report 33 "Reconcile
/// Cust. and Vend. Accs" to attribute historical detail entries to the vendor's current master
/// "Vendor Posting Group" without iterating vendors in AL.
/// </summary>
query 34 "Recon. Vend. Posting Gr. Sum"
{
    Caption = 'Reconcile Vendor Posting Group Sum';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    Access = Internal;

    elements
    {
        dataitem(DtldVendLedgEntry; "Detailed Vendor Ledg. Entry")
        {
            column(EntryType; "Entry Type")
            {
            }
            filter(PostingDate; "Posting Date")
            {
            }
            filter(PostingGroup; "Posting Group")
            {
            }
            column(SumAmountLCY; "Amount (LCY)")
            {
                Method = Sum;
            }
            column(SumCreditAmountLCY; "Credit Amount (LCY)")
            {
                Method = Sum;
            }
            column(SumDebitAmountLCY; "Debit Amount (LCY)")
            {
                Method = Sum;
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "No." = DtldVendLedgEntry."Vendor No.";
                SqlJoinType = InnerJoin;

                filter(VendorPostingGroup; "Vendor Posting Group")
                {
                }
            }
        }
    }
}
