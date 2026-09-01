// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Ledger;

query 5756 "Grouped Item Ledger Entries"
{
    QueryType = Normal;
    Caption = 'Grouped Item Ledger Entries';
    QueryCategory = 'Item Ledger Entries';
    OrderBy = ascending(Location_Code, Item_No, Variant_Code, Unit_of_Measure_Code, Lot_No_, Package_No_, Serial_No_);

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {
            column(Location_Code; "Location Code")
            {
                Caption = 'Location Code';
            }
            column(Item_No; "Item No.")
            {
                Caption = 'Item No.';
            }
            column(Variant_Code; "Variant Code")
            {
                Caption = 'Variant Code';
            }
            column(Unit_of_Measure_Code; "Unit of Measure Code")
            {
                Caption = 'Unit of Measure Code';
            }
            column(Serial_No_; "Serial No.")
            {
                Caption = 'Serial No.';
            }
            column(Lot_No_; "Lot No.")
            {
                Caption = 'Lot No.';
            }
            column(Package_No_; "Package No.")
            {
                Caption = 'Package No.';
            }
            column(Remaining_Quantity; "Remaining Quantity")
            {
                Caption = 'Remaining Quantity';
                Method = Sum;
            }
            filter(Open; Open)
            {
                ColumnFilter = Open = const(true);
            }
        }
    }
}
