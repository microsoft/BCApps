// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Sales.Customer;

/// <summary>
/// Aggregates Detailed Cust. Ledger Entry "Debit Amount (LCY)" and "Credit Amount (LCY)" with a
/// single database query grouped by Customer No. Use instead of per-customer CalcFields on Customer
/// "Debit Amount (LCY)"/"Credit Amount (LCY)" when iterating customers in reports.
/// </summary>
query 35 "Customer Debit Credit Amount"
{
    Caption = 'Customer Debit Credit Amount';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Detailed_Cust_Ledg_Entry; "Detailed Cust. Ledg. Entry")
        {
            column(Customer_No; "Customer No.")
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
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = Detailed_Cust_Ledg_Entry."Customer No.";
                SqlJoinType = InnerJoin;

                filter(Customer_Posting_Group; "Customer Posting Group")
                {
                }
            }
        }
    }
}
