// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

query 22 "Cust. Remain. Amt. By Due Date"
{
    Caption = 'Cust. Remain. Amt. By Due Date';

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            filter(IsOpen; Open)
            {
            }
            column(Due_Date; "Due Date")
            {
            }
            column(Customer_Posting_Group; "Customer Posting Group")
            {
            }
            column(Sum_Remaining_Amt_LCY; "Remaining Amt. (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

