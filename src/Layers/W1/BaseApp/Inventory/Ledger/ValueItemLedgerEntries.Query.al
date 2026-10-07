// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

query 1316 "Value Item Ledger Entries"
{
    Caption = 'Value Item Ledger Entries';

    elements
    {
        dataitem(Value_Entry; "Value Entry")
        {
            filter(Value_Entry_Type; "Entry Type")
            {
            }
            filter(Value_Entry_Invoiced_Qty; "Invoiced Quantity")
            {
            }
            filter(Value_Entry_Doc_Type; "Document Type")
            {
            }
            column(Value_Entry_Doc_No; "Document No.")
            {
            }
            column(Value_Entry_Doc_Line_No; "Document Line No.")
            {
            }
            dataitem(ItemLedgEntry; "Item Ledger Entry")
            {
                DataItemLink = "Entry No." = Value_Entry."Item Ledger Entry No.";
                SqlJoinType = InnerJoin;
                column(Item_Ledg_Document_No; "Document No.")
                {
                }
                column(Item_Ledg_Document_Line_No; "Document Line No.")
                {
                }
                filter(Item_Ledg_Document_Type; "Document Type")
                {
                }
                filter(Item_Ledg_Invoice_Quantity; "Invoiced Quantity")
                {
                }
            }
        }
    }
}
