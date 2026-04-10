// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

/// <summary>
/// Calculates the sum of sales amounts in local currency from customer ledger entries, with filters for document type, open status, and posting date.
/// </summary>
query 1310 "Cust. Ledg. Entry Sales"
{
    Caption = 'Cust. Ledg. Entry Sales';
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            filter(Document_Type; "Document Type")
            {
            }
            filter(IsOpen; Open)
            {
            }
            filter(Customer_No; "Customer No.")
            {
            }
            filter(Posting_Date; "Posting Date")
            {
            }
            column(Sum_Sales_LCY; "Sales (LCY)")
            {
                Method = Sum;
            }
        }
    }
}

