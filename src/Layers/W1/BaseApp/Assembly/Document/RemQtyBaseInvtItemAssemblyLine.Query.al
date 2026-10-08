// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.Document;

using Microsoft.Inventory.Item;

query 901 RemQtyBaseInvtItemAssemblyLine
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in assembly lines.', Locked = true;

    elements
    {
        dataitem(Assembly_Line; "Assembly Line")
        {
            DataItemTableFilter = Type = const(Item);
            filter(Document_No_; "Document No.")
            {
            }
            filter(Document_Type; "Document Type")
            {
            }
            column(Remaining_Quantity__Base_; "Remaining Quantity (Base)")
            {
                Method = Sum;
            }
            dataitem(Item; Item)
            {
                SqlJoinType = InnerJoin;
                DataItemLink = "No." = Assembly_Line."No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetAssemblyLineFilter(AssemblyHeader: Record "Assembly Header")
    begin
        SetRange(Document_No_, AssemblyHeader."No.");
        SetRange(Document_Type, AssemblyHeader."Document Type");
    end;
}