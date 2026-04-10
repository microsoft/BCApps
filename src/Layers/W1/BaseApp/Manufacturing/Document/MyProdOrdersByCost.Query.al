// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;

query 5403 "My Prod. Orders - By Cost"
{
    Caption = 'My Prod. Orders - By Cost';
    OrderBy = descending(Cost_of_Open_Production_Orders);

    elements
    {
        dataitem(My_Item; "My Item")
        {
            filter(User_ID; "User ID")
            {
            }
            dataitem(Prod_Order_Line; "Prod. Order Line")
            {
                DataItemLink = "Item No." = My_Item."Item No.";
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

    trigger OnBeforeOpen()
    begin
        SetRange(User_ID, UserId);
    end;
}

