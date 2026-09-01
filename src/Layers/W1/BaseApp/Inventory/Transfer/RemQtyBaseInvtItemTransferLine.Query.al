// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Item;

query 5741 RemQtyBaseInvtItemTransferLine
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in transfer lines.', Locked = true;

    elements
    {
        dataitem(Transfer_Line; "Transfer Line")
        {
            filter(Document_No_; "Document No.")
            {
            }
            column(Outstanding_Qty___Base_; "Outstanding Qty. (Base)")
            {
                Method = Sum;
            }
            dataitem(Item; Item)
            {
                SqlJoinType = InnerJoin;
                DataItemLink = "No." = Transfer_Line."Item No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetTransferLineFilter(TransferHeader: Record "Transfer Header")
    begin
        SetRange(Document_No_, TransferHeader."No.");
    end;
}