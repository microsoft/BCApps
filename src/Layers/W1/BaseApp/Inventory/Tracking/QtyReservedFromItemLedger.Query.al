// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;

query 522 "Qty. Reserved From Item Ledger"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(ReservEntryFor; "Reservation Entry")
        {
            DataItemTableFilter = Positive = const(false);

            filter(Source_Type; "Source Type") { }
            filter(Source_Subtype; "Source Subtype") { }
            filter(Source_ID; "Source ID") { }
            filter(Source_Ref__No_; "Source Ref. No.") { }
            filter(Source_Batch_Name; "Source Batch Name") { }
            filter(Source_Prod__Order_Line; "Source Prod. Order Line") { }
            filter(Item_No_; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Location_Code; "Location Code") { }
            filter(Serial_No_; "Serial No.") { }
            filter(Lot_No_; "Lot No.") { }
            filter(Package_No_; "Package No.") { }
            column(Quantity__Base_; "Quantity (Base)")
            {
                Method = Sum;
                ReverseSign = true;
            }

            dataitem(ReservEntryFrom; "Reservation Entry")
            {
                SqlJoinType = InnerJoin;
                DataItemLink = "Entry No." = ReservEntryFor."Entry No.";
                DataItemTableFilter = Positive = const(true),
                                      "Source Type" = const(Database::"Item Ledger Entry"),
                                      "Reservation Status" = const(Reservation);
            }
        }
    }

    procedure SetSourceFilter(ReservationEntry: Record "Reservation Entry")
    begin
        SetRange(Source_Type, ReservationEntry."Source Type");
        SetRange(Source_Subtype, ReservationEntry."Source Subtype");
        SetRange(Source_ID, ReservationEntry."Source ID");
        if ReservationEntry."Source Ref. No." <> 0 then
            SetRange(Source_Ref__No_, ReservationEntry."Source Ref. No.");
        SetRange(Source_Batch_Name, ReservationEntry."Source Batch Name");
        if ReservationEntry."Source Prod. Order Line" <> 0 then
            SetRange(Source_Prod__Order_Line, ReservationEntry."Source Prod. Order Line");
    end;

    procedure SetSKUFilters(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10])
    begin
        SetRange(Item_No_, ItemNo);
        SetRange(Variant_Code, VariantCode);
        SetRange(Location_Code, LocationCode);
    end;

    procedure SetTrackingFilters(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        SetRange(Serial_No_, ItemTrackingSetup."Serial No.");
        SetRange(Lot_No_, ItemTrackingSetup."Lot No.");
        SetRange(Package_No_, ItemTrackingSetup."Package No.");
    end;
}
