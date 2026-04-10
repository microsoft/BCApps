// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

query 6502 "Items With Expiration Date"
{
    Caption = 'Items With Expiration Date';

    elements
    {
        dataitem(Item; Item)
        {
            column(Item_No; "No.")
            {
            }
            filter(Item_Tracking_Code; "Item Tracking Code")
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = Item."No.";
                SqlJoinType = InnerJoin;
                filter(Expiration_Date; "Expiration Date")
                {
                }
            }
        }
    }
}

