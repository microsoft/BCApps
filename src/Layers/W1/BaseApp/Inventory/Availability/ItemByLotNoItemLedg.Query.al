// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Ledger;

query 521 "Item By Lot No. Item Ledg."
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ItemLedgerEntry; "Item Ledger Entry")
        {
            DataItemTableFilter = "Lot No." = filter(<> ''), Open = filter(= true);
            filter(Item_No; "Item No.")
            { }
            filter(Variant_Code; "Variant Code")
            { }
            filter(Location_Code; "Location Code")
            { }

            column(Lot_No; "Lot No.")
            { }
            column(Expiration_Date; "Expiration Date")
            { }
            column(Remaining_Quantity_Sum; "Remaining Quantity")
            {
                ColumnFilter = Remaining_Quantity_Sum = filter(<> 0);
                Method = Sum;
            }
        }
    }
}
