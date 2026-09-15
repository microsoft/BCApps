// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Item;

query 5407 RemQtyBaseInvtItemProdOrdComp
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total remaining quantity of inventory items (in base units of measure) in production order components.', Locked = true;

    elements
    {
        dataitem(Prod__Order_Component; "Prod. Order Component")
        {
            filter(Status; Status)
            {
            }
            filter(Prod__Order_No_; "Prod. Order No.")
            {
            }
            column(Remaining_Qty___Base_; "Remaining Qty. (Base)")
            {
                Method = Sum;
            }
            dataitem(Item; Item)
            {
                SqlJoinType = InnerJoin;
                DataItemLink = "No." = Prod__Order_Component."Item No.";
                DataItemTableFilter = Type = const(Inventory);
            }

        }
    }

    procedure SetJobPlanningLineFilter(ProductionOrder: Record "Production Order")
    begin
        SetRange(Status, ProductionOrder.Status);
        SetRange(Prod__Order_No_, ProductionOrder."No.");
    end;
}