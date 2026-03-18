// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Item;

query 5902 RemQtyBaseInvtItemServiceLine
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in service lines.', Locked = true;

    elements
    {
        dataitem(Service_Line; "Service Line")
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
                DataItemLink = "No." = Service_Line."No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetServiceLineFilter(ServiceHeader: Record "Service Header")
    begin
        SetRange(Document_No_, ServiceHeader."No.");
        SetRange(Document_Type, ServiceHeader."Document Type");
    end;
}