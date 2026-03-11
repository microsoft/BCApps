// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.QualityManagement.Integration.Inventory;

using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;

/// <summary>
/// Aggregate item ledger entry quantities grouped by location for non-bin-mandatory locations.
/// </summary>
query 20402 "Qlty. Item Ledger By Location"
{
    QueryType = Normal;
    DataAccessIntent = ReadOnly;

    elements
    {
        dataitem(Location; Location)
        {
            filter(Location_Bin_Mandatory; "Bin Mandatory")
            {
            }
            column(Location_Code; Code)
            {
            }
            dataitem(Item_Ledger_Entry; "Item Ledger Entry")
            {
                DataItemLink = "Location Code" = Location.Code;
                SqlJoinType = InnerJoin;

                filter(Item_Ledger_Entry_Item_No; "Item No.")
                {
                }
                filter(Item_Ledger_Entry_Variant_Code; "Variant Code")
                {
                }
                filter(Item_Ledger_Entry_Lot_No; "Lot No.")
                {
                }
                filter(Item_Ledger_Entry_Serial_No; "Serial No.")
                {
                }
                filter(Item_Ledger_Entry_Package_No; "Package No.")
                {
                }
                column(Item_Ledger_Entry_Sum_Quantity; Quantity)
                {
                    ColumnFilter = Item_Ledger_Entry_Sum_Quantity = filter(<> 0);
                    Method = Sum;
                }
            }
        }
    }
}
