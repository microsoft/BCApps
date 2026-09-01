// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Availability;

using Microsoft.Inventory.Tracking;

query 520 "Item By Lot No. Res."
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Reservation_Entry; "Reservation Entry")
        {
            DataItemTableFilter = "Lot No." = filter(<> '');
            filter(Item_No; "Item No.")
            { }
            filter(Quantity__Base_; "Quantity (Base)")
            { }
            filter(Expected_Receipt_Date; "Expected Receipt Date")
            { }
            filter(Shipment_Date; "Shipment Date")
            { }
            filter(Variant_Code; "Variant Code")
            { }
            filter(Location_Code; "Location Code")
            { }

            column(Lot_No; "Lot No.")
            { }
            column(Expiration_Date; "Expiration Date")
            { }
            column(Qty_Quantity__Base_; "Quantity (Base)")
            {
                Method = Sum;
            }
        }
    }
}
