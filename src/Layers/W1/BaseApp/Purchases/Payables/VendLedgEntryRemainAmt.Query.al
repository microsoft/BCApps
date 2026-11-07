// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

query 25 "Vend. Ledg. Entry Remain. Amt."
{
    Caption = 'Vend. Ledg. Entry Remain. Amt.';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Vendor_Ledger_Entry; "Vendor Ledger Entry")
        {
            filter(Document_Type; "Document Type")
            {
            }
            filter(IsOpen; Open)
            {
            }
            filter(Due_Date; "Due Date")
            {
            }
            filter(Vendor_No; "Vendor No.")
            {
            }
            filter(Vendor_Posting_Group; "Vendor Posting Group")
            {
            }
            column(Sum_Remaining_Amt_LCY; "Remaining Amt. (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

