// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;

query 5842 "Residual Amount - Items"
{
    QueryType = Normal;
    Access = Internal;
    DataAccessIntent = ReadOnly;
    ReadState = ReadUncommitted;

    elements
    {
        dataitem(Item; Item)
        {
            DataItemTableFilter = "Cost Is Adjusted" = const(true);

            filter(Inventory; Inventory)
            {
                ColumnFilter = Inventory = const(0);
            }
            column(Item_No; "No.")
            {
            }
            dataitem(Value_Entry; "Value Entry")
            {
                DataItemLink = "Item No." = Item."No.";
                SqlJoinType = InnerJoin;

                column(Cost_Amount_Actual; "Cost Amount (Actual)")
                {
                    Method = Sum;
                }
                column(Cost_Amount_Expected; "Cost Amount (Expected)")
                {
                    Method = Sum;
                }
            }
        }
    }
}