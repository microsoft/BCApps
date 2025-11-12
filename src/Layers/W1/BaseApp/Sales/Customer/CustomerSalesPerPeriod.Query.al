// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Customer;

using Microsoft.Sales.Receivables;

query 3 "Customer Sales per Period"
{
    QueryType = Normal;

    elements
    {
        dataitem(CustomerLedgerEntry; "Cust. Ledger Entry")
        {
            SqlJoinType = LeftOuterJoin;

            filter(CustomerNo; "Customer No.")
            {
            }
            filter(PostingDate; "Posting Date")
            {
            }
            column(SalesLCY; "Sales (LCY)")
            {
                method = Sum;
            }
            column(ProfitLCY; "Profit (LCY)")
            {
                method = Sum;
            }
        }
    }
}