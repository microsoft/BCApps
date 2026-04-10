// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Item;

query 265 "Item Ledger Entries"
{
    Caption = 'Item Ledger Entries';

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Entry_Type; "Entry Type")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            column(Item_Reference_No; "Item Reference No.")
            {
            }
            column(Lot_No; "Lot No.")
            {
            }
            column(Item_Category_Code; "Item Category Code")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Expiration_Date; "Expiration Date")
            {
            }
            column(Warranty_Date; "Warranty Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Job_No; "Job No.")
            {
            }
            column(Job_Task_No; "Job Task No.")
            {
            }
            column(Open; Open)
            {
            }
            column(Quantity; Quantity)
            {
            }
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }
            column(Qty_per_Unit_of_Measure; "Qty. per Unit of Measure")
            {
            }
            column(Remaining_Quantity; "Remaining Quantity")
            {
            }
            column(Invoiced_Quantity; "Invoiced Quantity")
            {
            }
            column(Cost_Amount_Expected; "Cost Amount (Expected)")
            {
            }
            column(Cost_Amount_Actual; "Cost Amount (Actual)")
            {
            }
            column(Cost_Amount_Non_Invtbl; "Cost Amount (Non-Invtbl.)")
            {
            }
            column(Purchase_Amount_Expected; "Purchase Amount (Expected)")
            {
            }
            column(Purchase_Amount_Actual; "Purchase Amount (Actual)")
            {
            }
            column(Sales_Amount_Expected; "Sales Amount (Expected)")
            {
            }
            column(Sales_Amount_Actual; "Sales Amount (Actual)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Item; Item)
            {
                DataItemLink = "No." = Item_Ledger_Entry."Item No.";
                column(Item_Description; Description)
                {
                }
            }
        }
    }
}

