// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Item;

query 37 RemQtyBaseInvtItemSalesLine
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in sales lines.', Locked = true;

    elements
    {
        dataitem(Sales_Line; "Sales Line")
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
                DataItemLink = "No." = Sales_Line."No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetSalesLineFilter(SalesHeader: Record "Sales Header")
    begin
        SetRange(Document_No_, SalesHeader."No.");
        SetRange(Document_Type, SalesHeader."Document Type");
    end;
}