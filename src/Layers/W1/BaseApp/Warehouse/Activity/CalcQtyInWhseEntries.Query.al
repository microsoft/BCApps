// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Structure;

query 7318 CalcQtyInWhseEntries
{
    QueryType = Normal;
    Access = Public;
    DataAccessIntent = ReadOnly;
    OrderBy = ascending(Block_Movement);

    elements
    {
        dataitem(Warehouse_Entry; "Warehouse Entry")
        {
            column(Location_Code; "Location Code") { }
            column(Item_No_; "Item No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Unit_of_Measure_Code; "Unit of Measure Code") { }
            column(Serial_No_; "Serial No.") { }
            column(Lot_No_; "Lot No.") { }
            column(Package_No_; "Package No.") { }
            column(Bin_Type_Code; "Bin Type Code") { }
            column(Bin_Code; "Bin Code") { }
            dataitem(Bin_Content; "Bin Content")
            {
                DataItemLink = "Location Code" = Warehouse_Entry."Location Code",
                                "Bin Code" = Warehouse_Entry."Bin Code",
                                "Item No." = Warehouse_Entry."Item No.",
                                "Variant Code" = Warehouse_Entry."Variant Code",
                                "Unit of Measure Code" = Warehouse_Entry."Unit of Measure Code";
                SqlJoinType = InnerJoin;

                column(Block_Movement; "Block Movement") { }
            }
            column(Qty___Base_; "Qty. (Base)")
            {
                Method = Sum;
            }
        }
    }
}
