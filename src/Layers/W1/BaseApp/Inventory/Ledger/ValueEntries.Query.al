// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

using Microsoft.Inventory.Item;

query 266 "Value Entries"
{
    Caption = 'Value Entries';

    elements
    {
        dataitem(Value_Entry; "Value Entry")
        {
            column(Entry_No; "Entry No.")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            column(Item_Ledger_Entry_No; "Item Ledger Entry No.")
            {
            }
            column(Item_Ledger_Entry_Type; "Item Ledger Entry Type")
            {
            }
            column(Item_Ledger_Entry_Quantity; "Item Ledger Entry Quantity")
            {
            }
            column(Posting_Date; "Posting Date")
            {
            }
            column(Valuation_Date; "Valuation Date")
            {
            }
            column(Document_Date; "Document Date")
            {
            }
            column(Document_Type; "Document Type")
            {
            }
            column(Document_No; "Document No.")
            {
            }
            column(Gen_Bus_Posting_Group; "Gen. Bus. Posting Group")
            {
            }
            column(Gen_Prod_Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Source_Code; "Source Code")
            {
            }
            column(Reason_Code; "Reason Code")
            {
            }
            column(Job_No; "Job No.")
            {
            }
            column(Job_Task_No; "Job Task No.")
            {
            }
            column(Job_Ledger_Entry_No; "Job Ledger Entry No.")
            {
            }
            column(Valued_Quantity; "Valued Quantity")
            {
            }
            column(Invoiced_Quantity; "Invoiced Quantity")
            {
            }
            column(Cost_per_Unit; "Cost per Unit")
            {
            }
            column(Cost_Posted_to_G_L; "Cost Posted to G/L")
            {
            }
            column(Expected_Cost; "Expected Cost")
            {
            }
            column(Cost_Amount_Actual; "Cost Amount (Actual)")
            {
            }
            column(Cost_Amount_Expected; "Cost Amount (Expected)")
            {
            }
            column(Cost_Amount_Non_Invtbl; "Cost Amount (Non-Invtbl.)")
            {
            }
            column(Sales_Amount_Actual; "Sales Amount (Actual)")
            {
            }
            column(Sales_Amount_Expected; "Sales Amount (Expected)")
            {
            }
            column(Purchase_Amount_Actual; "Purchase Amount (Actual)")
            {
            }
            column(Purchase_Amount_Expected; "Purchase Amount (Expected)")
            {
            }
            column(Dimension_Set_ID; "Dimension Set ID")
            {
            }
            dataitem(Item; Item)
            {
                DataItemLink = "No." = Value_Entry."Item No.";
                column(Item_Description; Description)
                {
                }
            }
        }
    }
}

