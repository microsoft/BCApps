// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Item;

query 39 RemQtyBaseInvtItemPurchaseLine
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in purchase lines.', Locked = true;

    elements
    {
        dataitem(Purchase_Line; "Purchase Line")
        {
            DataItemTableFilter = Type = const(Item);
            filter(Document_No_; "Document No.")
            {
            }
            filter(Document_Type; "Document Type")
            {
            }
            column(Outstanding_Qty___Base_; "Outstanding Qty. (Base)")
            {
                Method = Sum;
            }
            dataitem(Item; Item)
            {
                SqlJoinType = InnerJoin;
                DataItemLink = "No." = Purchase_Line."No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetPurchaseLineFilter(PurchaseHeader: Record "Purchase Header")
    begin
        SetRange(Document_No_, PurchaseHeader."No.");
        SetRange(Document_Type, PurchaseHeader."Document Type");
    end;
}