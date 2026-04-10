// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Inventory.Tracking;

query 7320 CalcQtyInReservEntry
{
    QueryType = Normal;
    Access = Public;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Reservation_Entry; "Reservation Entry")
        {
            filter(Source_Type; "Source Type") { }
            filter(Source_Subtype; "Source Subtype") { }
            filter(Reservation_Status; "Reservation Status") { }
            column(Location_Code; "Location Code") { }
            column(Item_No_; "Item No.") { }
            column(Variant_Code; "Variant Code") { }
            column(Serial_No_; "Serial No.") { }
            column(Lot_No_; "Lot No.") { }
            column(Package_No_; "Package No.") { }
            column(Quantity__Base_; "Quantity (Base)")
            {
                Method = Sum;
            }
        }
    }

    procedure SetTrackingFilterFromWhseItemTrackingSetupIfRequired(WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if WhseItemTrackingSetup."Serial No." <> '' then
            if WhseItemTrackingSetup."Serial No. Required" then
                SetRange(Serial_No_, WhseItemTrackingSetup."Serial No.")
            else
                SetFilter(Serial_No_, '%1|%2', WhseItemTrackingSetup."Serial No.", '');

        if WhseItemTrackingSetup."Lot No." <> '' then
            if WhseItemTrackingSetup."Lot No. Required" then
                SetRange(Lot_No_, WhseItemTrackingSetup."Lot No.")
            else
                SetFilter(Lot_No_, '%1|%2', WhseItemTrackingSetup."Lot No.", '');

        if WhseItemTrackingSetup."Package No." <> '' then
            if WhseItemTrackingSetup."Package No. Required" then
                SetRange(Package_No_, WhseItemTrackingSetup."Package No.")
            else
                SetFilter(Package_No_, '%1|%2', WhseItemTrackingSetup."Package No.", '');
    end;
}
