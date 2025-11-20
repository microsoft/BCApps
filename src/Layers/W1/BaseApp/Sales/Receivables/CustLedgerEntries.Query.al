// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Sales.Customer;

query 262 "Cust. Ledger Entries"
{
    Caption = 'Cust. Ledger Entries';

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Transaction_No; "Transaction No.")
            {
            }
            column(Customer_No; "Customer No.")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Due_Date; "Due Date")
            {
            }
            column(Pmt_Discount_Date; "Pmt. Discount Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Salesperson_Code; "Salesperson Code")
            {
            }
            column(Source_Code; "Source Code")
            {
            }
            column(Reason_Code; "Reason Code")
            {
            }
            column(IC_Partner_Code; "IC Partner Code")
            {
            }
            column(Open; Open)
            {
            }
            column(Currency_Code; "Currency Code")
            {
            }
            column(Amount; Amount)
            {
            }
            column(Debit_Amount; "Debit Amount")
            {
            }
            column(Credit_Amount; "Credit Amount")
            {
            }
            column(Remaining_Amount; "Remaining Amount")
            {
            }
            column(Amount_LCY; "Amount (LCY)")
            {
            }
            column(Debit_Amount_LCY; "Debit Amount (LCY)")
            {
            }
            column(Credit_Amount_LCY; "Credit Amount (LCY)")
            {
            }
            column(Remaining_Amt_LCY; "Remaining Amt. (LCY)")
            {
            }
            column(Original_Amt_LCY; "Original Amt. (LCY)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = Cust_Ledger_Entry."Customer No.";
                column(Customer_Name; Name)
                {
                }
            }
        }
    }
}

