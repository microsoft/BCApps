// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;

query 7316 CalcQtyOnBlockedITOnLNQuery
{
    QueryType = Normal;
    Access = Public;
    DataAccessIntent = ReadOnly;
    elements
    {
        dataitem(Lot_No__Information; "Lot No. Information")
        {
            filter(Item_No_; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Blocked; Blocked) { }
            column(Lot_No_; "Lot No.") { }

            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Lot No." = Lot_No__Information."Lot No.";
                SqlJoinType = InnerJoin;

                filter(ILE_Item_No_; "Item No.") { }
                filter(ILE_Variant_Code; "Variant Code") { }
                filter(ILE_Location_Code; "Location Code") { }
                column(Package_No_; "Package No.") { }

                column(Quantity; Quantity)
                {
                    Method = Sum;
                }
            }
        }
    }

    procedure SetItemTrackingFilter(ItemTrackingSetup: Record "Item Tracking Setup")
    begin
        if ItemTrackingSetup."Lot No." <> '' then
            SetRange(Lot_No_, ItemTrackingSetup."Lot No.");
    end;
}
