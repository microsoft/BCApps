// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;

query 7321 "Summarized Stock By Item Trkg."
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Item_Ledger_Entry; "Item Ledger Entry")
        {

            column(Serial_No_; "Serial No.")
            {

            }
            column(Lot_No_; "Lot No.")
            {

            }
            column(Package_No_; "Package No.")
            {

            }
            column(Expiration_Date; "Expiration Date")
            {

            }
            column(Remaining_Quantity; "Remaining Quantity")
            {
                Method = Sum;
            }
            filter(Item_No_; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Location_Code; "Location Code") { }
            filter(Unit_of_Measure_Code; "Unit of Measure Code") { }
            filter(Open; Open) { }
            filter(Positive; Positive) { }
        }
    }

    internal procedure SetSKUFilters(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        SetRange(Item_No_, ItemNo);
        SetRange(Variant_Code, VariantCode);
        SetRange(Location_Code, LocationCode);
    end;

    internal procedure GetItemTrackingSetup(var ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        ItemTrackingSetup."Serial No." := Serial_No_;
        ItemTrackingSetup."Lot No." := Lot_No_;
        ItemTrackingSetup."Package No." := Package_No_;
    end;
}
