// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Sales.Receivables;

query 62 "Power BI Cust. Ledger Entries"
{
    Caption = 'Power BI Cust. Ledger Entries';

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
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
            column(Customer_Posting_Group; "Customer Posting Group")
            {
            }
            column(Sales_LCY; "Sales (LCY)")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
        }
    }
}

