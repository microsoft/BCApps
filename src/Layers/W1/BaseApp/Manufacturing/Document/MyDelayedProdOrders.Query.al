// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;

query 5404 "My Delayed Prod. Orders"
{
    Caption = 'My Delayed Prod. Orders';

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
                filter(Due_Date; "Due Date")
                {
                }
                column(Sum_Remaining_Quantity; "Remaining Quantity")
                {
                    Method = Sum;
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
        SetFilter(Due_Date, '<%1', Today);
        SetRange(User_ID, UserId);
    end;
}

