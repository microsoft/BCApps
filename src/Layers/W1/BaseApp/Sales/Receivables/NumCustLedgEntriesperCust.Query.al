// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Receivables;

using Microsoft.Sales.Customer;

query 1312 "Num CustLedgEntries per Cust"
{
    Caption = 'Num CustLedgEntries per Cust';

    elements
    {
        dataitem(Cust_Ledger_Entry; "Cust. Ledger Entry")
        {
            column(Customer_No; "Customer No.")
            {
            }
            column(OpenValue; Open)
            {
            }
            dataitem(Customer; Customer)
            {
                DataItemLink = "No." = Cust_Ledger_Entry."Customer No.";
                SqlJoinType = InnerJoin;
                column(Count_)
                {
                    Method = Count;
                }
            }
        }
    }
}

