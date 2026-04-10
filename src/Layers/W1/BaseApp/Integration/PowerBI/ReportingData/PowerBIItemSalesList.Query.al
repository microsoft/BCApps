// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Integration.PowerBI;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

query 57 "Power BI Item Sales List"
{
    Caption = 'Power BI Item Sales List';

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
            dataitem(Value_Entry; "Value Entry")
            {
                DataItemLink = "Item No." = Item."No.";
                DataItemTableFilter = "Item Ledger Entry Type" = const(Sale);
                column(Sales_Post_Date; "Posting Date")
                {
                }
                column(Sold_Quantity; "Invoiced Quantity")
                {
                    ReverseSign = true;
                }
                column(Sales_Entry_No; "Entry No.")
                {
                }
            }
        }
    }
}

