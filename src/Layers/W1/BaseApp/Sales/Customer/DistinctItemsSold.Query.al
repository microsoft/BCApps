// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Sales.Customer;

using Microsoft.Inventory.Ledger;

query 1 "Distinct Items Sold"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    AboutTitle = 'Returns the distinct items sold to a customer';
    AboutText = 'This query returns the distinct items sold to a customer within a specified date range.';

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableFilter = "Entry Type" = const(Sale), "Source Type" = const(Customer);

            filter(CustomerNoFilter; "Source No.")
            {
            }
            filter(PostingDateFilter; "Posting Date")
            {
            }
            column(ItemNo; "Item No.")
            {
            }
            column(Count)
            {
                method = Count;
                Description = 'This is a dummy aggregator. The value is always 1.';
            }
        }
    }
}