// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Sales.Receivables;
using Microsoft.Sales.Customer;

query 59 "Power BI Top Cust. Overview"
{
    Caption = 'Power BI Top Cust. Overview';

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
                Caption = 'Entry No.';
            }
            column(Posting_Date; "Posting Date")
            {
                Caption = 'Posting Date';
            }
            column(Customer_No; "Customer No.")
            {
                Caption = 'Customer No.';
            }
            column(Sales_LCY; "Sales (LCY)")
            {
                Caption = 'Sales (LCY)';
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = Cust_Ledger_Entry."Customer No.";
                column(Name; Name)
                {
                    Caption = 'Name';
                }
            }
        }
    }
}

