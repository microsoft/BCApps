// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;

query 5402 "Top-10 Prod. Orders - by Cost"
{
    Caption = 'Top-10 Prod. Orders - by Cost';
    OrderBy = descending(Cost_of_Open_Production_Orders);
    TopNumberOfRows = 10;

    elements
    {
        dataitem(Prod_Order_Line; "Prod. Order Line")
        {
            DataItemTableFilter = Status = filter(Planned | "Firm Planned" | Released);
            column(Item_No; "Item No.")
            {
            }
            column(Status; Status)
            {
            }
            column(Sum_Remaining_Quantity; "Remaining Quantity")
            {
                Method = Sum;
            }
            dataitem(Item; Item)
            {
                DataItemLink = "No." = Prod_Order_Line."Item No.";
                column(Cost_of_Open_Production_Orders; "Cost of Open Production Orders")
                {
                }
            }
        }
    }
}

