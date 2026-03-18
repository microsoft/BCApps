// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Ledger;

query 7345 "Avail Qty. (Base) In QC Bins"
{
    Caption = 'Avail Qty. (Base) In QC Bins';

    elements
    {
        dataitem(Location; Location)
        {
            DataItemTableFilter = "Directed Put-away and Pick" = const(true);
            dataitem(Warehouse_Entry; "Warehouse Entry")
            {
                DataItemLink = "Location Code" = Location.Code;
                SqlJoinType = InnerJoin;
                column(Location_Code; "Location Code")
                {
                }
                filter(Item_No; "Item No.")
                {
                }
                filter(Variant_Code; "Variant Code")
                {
                }
                filter(Dedicated; Dedicated)
                {
                }
                column(Bin_Type_Code; "Bin Type Code")
                {
                }
                column(Sum_Qty_Base; "Qty. (Base)")
                {
                    ColumnFilter = Sum_Qty_Base = filter(> 0);
                    Method = Sum;
                }
                dataitem(Bin_Type; "Bin Type")
                {
                    DataItemLink = Code = Warehouse_Entry."Bin Type Code";
                    SqlJoinType = InnerJoin;
                    DataItemTableFilter = Receive = const(false), Ship = const(false), Pick = const(false);
                    dataitem(Bin_Content; "Bin Content")
                    {
                        DataItemLink = "Location Code" = Warehouse_Entry."Location Code", "Bin Code" = Warehouse_Entry."Bin Code", "Item No." = Warehouse_Entry."Item No.", "Variant Code" = Warehouse_Entry."Variant Code", "Unit of Measure Code" = Warehouse_Entry."Unit of Measure Code";
                        SqlJoinType = InnerJoin;
                        DataItemTableFilter = "Block Movement" = filter(' ' | Inbound);
                    }
                }
            }
        }
    }
}

