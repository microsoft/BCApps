// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Availability;

using Microsoft.Inventory.Tracking;

query 7314 CalcRsvQtyOnPicksShipsWithIT
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;
    elements
    {
        dataitem(ReservEntry; "Reservation Entry")
        {
            column(Quantity__Base_; "Quantity (Base)")
            {

            }
            column(Source_Type; "Source Type")
            {

            }
            column(Source_Subtype; "Source Subtype")
            {

            }
            column(Source_ID; "Source ID")
            {

            }
            column(Source_Batch_Name; "Source Batch Name")
            {

            }
            column(Source_Prod__Order_Line; "Source Prod. Order Line")
            {

            }
            column(Source_Ref__No_; "Source Ref. No.")
            {

            }
            filter(Item_No_; "Item No.")
            {

            }
            filter(Variant_Code; "Variant Code")
            {

            }
            filter(Location_Code; "Location Code")
            {

            }
            filter(Reservation_Status; "Reservation Status")
            {

            }
            filter(Positive; Positive)
            {

            }
            filter(Item_Tracking; "Item Tracking")
            {

            }
            dataitem(PositiveReservationEntry; "Reservation Entry")
            {
                DataItemLink = "Entry No." = ReservEntry."Entry No.";
                SqlJoinType = InnerJoin;

                filter(Positive_2; Positive)
                {

                }
                filter(Source_Type_2; "Source Type")
                {

                }
                filter(Serial_No_; "Serial No.")
                {

                }
                filter(Lot_No_; "Lot No.")
                {

                }
                filter(Package_No_; "Package No.")
                {

                }
            }
        }
    }

}
