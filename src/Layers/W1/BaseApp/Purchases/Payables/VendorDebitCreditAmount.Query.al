// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.Purchases.Vendor;

/// <summary>
/// Aggregates Detailed Vendor Ledger Entry "Debit Amount (LCY)" and "Credit Amount (LCY)" with a
/// single database query grouped by Vendor No. Use instead of per-vendor CalcFields on Vendor
/// "Debit Amount (LCY)"/"Credit Amount (LCY)" when iterating vendors in reports.
/// </summary>
query 36 "Vendor Debit Credit Amount"
{
    Caption = 'Vendor Debit Credit Amount';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Detailed_Vendor_Ledg_Entry; "Detailed Vendor Ledg. Entry")
        {
            column(Vendor_No; "Vendor No.")
            {
            }
            filter(Entry_Type; "Entry Type")
            {
            }
            filter(Posting_Date; "Posting Date")
            {
            }
            filter(Initial_Entry_Global_Dim_1; "Initial Entry Global Dim. 1")
            {
            }
            filter(Initial_Entry_Global_Dim_2; "Initial Entry Global Dim. 2")
            {
            }
            filter(Currency_Code; "Currency Code")
            {
            }
            column(Sum_Debit_Amount_LCY; "Debit Amount (LCY)")
            {
                Method = Sum;
            }
            column(Sum_Credit_Amount_LCY; "Credit Amount (LCY)")
            {
                Method = Sum;
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "No." = Detailed_Vendor_Ledg_Entry."Vendor No.";
                SqlJoinType = InnerJoin;

                filter(Vendor_Posting_Group; "Vendor Posting Group")
                {
                }
            }
        }
    }
}
