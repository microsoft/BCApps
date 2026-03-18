// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Warehouse.Ledger;

query 7302 "Bin Content by Item Tracking"
{
    Caption = 'Bin Content by Item Tracking';
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    AboutText = 'Calculates the total "Qty. (Base)" per bin content and item tracking dimensions. Filters on variations that have total "Qty. (Base)" <> 0.', Locked = true;

    elements
    {
        dataitem(Warehouse_Entry; "Warehouse Entry")
        {
            column(Location_Code; "Location Code")
            {
            }
            column(Bin_Code; "Bin Code")
            {
            }
            column(Item_No; "Item No.")
            {
            }
            column(Variant_Code; "Variant Code")
            {
            }
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }
            column(Lot_No; "Lot No.")
            {
            }
            column(Serial_No; "Serial No.")
            {
            }
            column(Package_No; "Package No.")
            {
            }
            column(Sum_Qty_Base; "Qty. (Base)")
            {
                ColumnFilter = Sum_Qty_Base = filter(<> 0);
                Method = Sum;
            }
        }
    }
}