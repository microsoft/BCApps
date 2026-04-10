// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

query 52 "Power BI Item Purchase List"
{
    Caption = 'Power BI Item Purchase List';

    elements
    {
        dataitem(Item; Item)
        {
            column(Item_No; "No.")
            {
            }
            column(Search_Description; "Search Description")
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Item No." = Item."No.";
                DataItemTableFilter = "Entry Type" = const(Purchase);
                column(Purchase_Post_Date; "Posting Date")
                {
                }
                column(Purchased_Quantity; "Invoiced Quantity")
                {
                }
                column(Purchase_Entry_No; "Entry No.")
                {
                }
            }
        }
    }
}

