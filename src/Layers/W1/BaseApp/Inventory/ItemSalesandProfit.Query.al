// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory;

using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;

query 103 "Item Sales and Profit"
{
    Caption = 'Item Sales and Profit';

    elements
    {
        dataitem(Item; Item)
        {
            column(No; "No.")
            {
            }
            column(Description; Description)
            {
            }
            column(Gen_Prod_Posting_Group; "Gen. Prod. Posting Group")
            {
            }
            column(Item_Disc_Group; "Item Disc. Group")
            {
            }
            column(Item_Tracking_Code; "Item Tracking Code")
            {
            }
            column(Profit; "Profit %")
            {
            }
            column(Scrap; "Scrap %")
            {
            }
            column(Sales_Unit_of_Measure; "Sales Unit of Measure")
            {
            }
            column(Standard_Cost; "Standard Cost")
            {
            }
            column(Unit_Cost; "Unit Cost")
            {
            }
            column(Unit_Price; "Unit Price")
            {
            }
            column(Unit_Volume; "Unit Volume")
            {
            }
            column(Vendor_No; "Vendor No.")
            {
            }
            column(Purch_Unit_of_Measure; "Purch. Unit of Measure")
            {
            }
            column(COGS_LCY; "COGS (LCY)")
            {
            }
            column(Inventory; Inventory)
            {
            }
            column(Net_Change; "Net Change")
            {
            }
            column(Net_Invoiced_Qty; "Net Invoiced Qty.")
            {
            }
            column(Purchases_LCY; "Purchases (LCY)")
            {
            }
            column(Purchases_Qty; "Purchases (Qty.)")
            {
            }
            column(Sales_LCY; "Sales (LCY)")
            {
            }
            column(Sales_Qty; "Sales (Qty.)")
            {
            }
            dataitem(Vendor; Vendor)
            {
                DataItemLink = "No." = Item."Vendor No.";
                column(VendorName; Name)
                {
                }
            }
        }
    }
}

