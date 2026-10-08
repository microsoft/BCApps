// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Costing.ActionMessage;

using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;

query 5840 "Avg. Cost Entry Points Not Adj"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    ReadState = ReadUncommitted;
    OrderBy = descending(Count);
    Caption = 'Avg. Cost Entry Points Not Adjusted';

    elements
    {
        dataitem(Avg_Cost_Adjmt_Entry_Point; "Avg. Cost Adjmt. Entry Point")
        {
            DataItemTableFilter = "Cost Is Adjusted" = const(false);

            column(Valuation_Date; "Valuation Date")
            {
            }
            column(Count)
            {
                Method = Count;
            }
            dataitem(Item; Item)
            {
                DataItemLink = "No." = Avg_Cost_Adjmt_Entry_Point."Item No.";
                DataItemTableFilter = "Excluded from Cost Adjustment" = const(false);
                SqlJoinType = InnerJoin;
            }
        }
    }
}