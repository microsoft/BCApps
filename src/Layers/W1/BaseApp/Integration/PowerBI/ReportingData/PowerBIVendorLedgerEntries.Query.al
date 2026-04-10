// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Purchases.Payables;

query 63 "Power BI Vendor Ledger Entries"
{
    Caption = 'Power BI Vendor Ledger Entries';

    elements
    {
        dataitem(Vendor_Ledger_Entry; "Vendor Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Due_Date; "Due Date")
            {
            }
            column(Remaining_Amt_LCY; "Remaining Amt. (LCY)")
            {
            }
            column(Open; Open)
            {
            }
        }
    }
}

