// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Analysis;

using Microsoft.Inventory.Ledger;

query 5833 "Item to Value Entries"
{
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ItemLedgEntry; "Item Ledger Entry")
        {
            column(Entry_No_; "Entry No.")
            {

            }
            filter(Positive; Positive)
            {

            }
            filter(Item_No; "Item No.")
            {

            }
            filter(Posting_Date; "Posting Date")
            {

            }
            filter(Entry_Type; "Entry Type")
            {

            }
            filter(Remaining_Quantity; "Remaining Quantity")
            {

            }
            filter(Quantity; Quantity)
            {

            }
            filter(Expiration_Date; "Expiration Date")
            {

            }
            dataitem(Value_Entry; "Value Entry")
            {
                DataItemLink = "Item Ledger Entry No." = ItemLedgEntry."Entry No.";
                SqlJoinType = InnerJoin;

                filter(Value_Entry_Type; "Entry Type")
                {

                }
                column(Cost_Amount__Actual_; "Cost Amount (Actual)")
                {
                    Method = Sum;
                }
                column(Cost_Amount__Expected; "Cost Amount (Expected)")
                {
                    Method = Sum;
                }
                column(Sales_Amount__Actual_; "Sales Amount (Actual)")
                {
                    Method = Sum;
                }
                column(Sales_Amount__Expected; "Sales Amount (Expected)")
                {
                    Method = Sum;
                }
                column(Invoiced_Quantity; "Invoiced Quantity")
                {
                    Method = Sum;
                }
            }

        }
    }
}