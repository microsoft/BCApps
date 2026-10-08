#if not CLEAN27
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

query 9152 "My Items"
{
    Caption = 'My Items';
    ObsoleteReason = 'Not used, replaced by Costing Overview functionality';
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';

    elements
    {
        dataitem(My_Item; "My Item")
        {
            filter(User_ID; "User ID")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            dataitem(Prod_Order_Line; Microsoft.Manufacturing.Document."Prod. Order Line")
            {
                DataItemLink = "Item No." = My_Item."Item No.";
                filter(Date_Filter; "Date Filter")
                {
                }
                column(Status; Status)
                {
                }
                column(Remaining_Quantity; "Remaining Quantity")
                {
                }
            }
        }
    }

    trigger OnBeforeOpen()
    begin
        SetRange(User_ID, UserId);
    end;
}
#endif
