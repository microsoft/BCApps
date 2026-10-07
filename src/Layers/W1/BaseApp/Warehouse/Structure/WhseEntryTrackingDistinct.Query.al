// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Structure;

using Microsoft.Warehouse.Ledger;

query 7346 "Whse. Entry Tracking Distinct"
{
    Caption = 'Warehouse Entry Tracking Distinct';
    OrderBy = ascending(Item_No_, Bin_Code, Location_Code, Variant_Code, Unit_of_Measure_Code, Lot_No_, Serial_No_, Package_No_);

    elements
    {
        dataitem(Warehouse_Entry; "Warehouse Entry")
        {
            column(Item_No_; "Item No.")
            {
            }
            column(Bin_Code; "Bin Code")
            {
            }
            column(Location_Code; "Location Code")
            {
            }
            column(Variant_Code; "Variant Code")
            {
            }
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
            }
            column(Serial_No_; "Serial No.")
            {
            }
            column(Lot_No_; "Lot No.")
            {
            }
            column(Package_No_; "Package No.")
            {
            }
            column(Count)
            {
                Method = Count;
            }
        }
    }
}