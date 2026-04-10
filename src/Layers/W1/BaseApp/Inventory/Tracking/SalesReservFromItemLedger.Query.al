// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Sales.Document;

query 523 "Sales Reserv. From Item Ledger"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(SalesHeader; "Sales Header")
        {
            DataItemTableFilter = "Document Type" = const(Order);
            column(SalesHeaderNo; "No.") { }
            dataitem(ReservEntryFor; "Reservation Entry")
            {
                DataItemLink = "Source Subtype" = SalesHeader."Document Type",
                               "Source ID" = SalesHeader."No.";
                DataItemTableFilter = "Source Type" = const(Database::"Sales Line"),
                                      Positive = const(false);
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
                column(Reserved_Quantity__Base_; "Quantity (Base)")
                {
                    ColumnFilter = Reserved_Quantity__Base_ = filter(<> 0);
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
    }
}