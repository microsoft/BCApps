// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Purchases.Vendor;
using Microsoft.Purchases.Payables;

query 51 "Power BI Vendor List"
{
    Caption = 'Power BI Vendor List';

    elements
    {
        dataitem(Vendor; Vendor)
        {
            column(Vendor_No; "No.")
            {
            }
            column(Vendor_Name; Name)
            {
            }
            column(Balance_Due; "Balance Due")
            {
            }
            dataitem(Detailed_Vendor_Ledg_Entry; "Detailed Vendor Ledg. Entry")
            {
                DataItemLink = "Vendor No." = Vendor."No.";
                column(Posting_Date; "Posting Date")
                {
                }
                column(Applied_Vend_Ledger_Entry_No; "Applied Vend. Ledger Entry No.")
                {
                }
                column(Amount; Amount)
                {
                    ReverseSign = true;
                }
                column(Amount_LCY; "Amount (LCY)")
                {
                    ReverseSign = true;
                }
                column(Transaction_No; "Transaction No.")
                {
                }
                column(Entry_No; "Entry No.")
                {
                }
                column(Remaining_Pmt_Disc_Possible; "Remaining Pmt. Disc. Possible")
                {
                }
            }
        }
    }
}

