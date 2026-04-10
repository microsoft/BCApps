// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;

query 7315 CalcQtyOnBlockedITOnSNQuery
{
    QueryType = Normal;
    Access = Public;
    DataAccessIntent = ReadOnly;
    elements
    {
        dataitem(Serial_No__Information; "Serial No. Information")
        {
            filter(Item_No_; "Item No.") { }
            filter(Variant_Code; "Variant Code") { }
            filter(Blocked; Blocked) { }
            filter(Serial_No_; "Serial No.") { }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Serial No." = Serial_No__Information."Serial No.";
                SqlJoinType = InnerJoin;

                filter(ILE_Item_No_; "Item No.") { }
                filter(ILE_Variant_Code; "Variant Code") { }
                filter(ILE_Location_Code; "Location Code") { }
                column(Lot_No_; "Lot No.") { }
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
        if ItemTrackingSetup."Serial No." <> '' then
            SetRange(Serial_No_, ItemTrackingSetup."Serial No.");
    end;
}
