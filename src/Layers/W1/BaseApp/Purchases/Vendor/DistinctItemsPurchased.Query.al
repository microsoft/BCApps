// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Purchase.Vendor;

using Microsoft.Inventory.Ledger;

query 4 "Distinct Items Purchased"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    AboutTitle = 'Returns the distinct items bought from a vendor';
    AboutText = 'This query returns the distinct items bought from a vendor within a specified date range.';

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableFilter = "Entry Type" = const(Purchase), "Source Type" = const(Vendor);

            filter(VendorNoFilter; "Source No.")
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
                Description = 'This is a dummy aggregator.';
            }
        }
    }
}