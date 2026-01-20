// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Inventory.Item;

pageextension 99001519 "Subc. Item List" extends "Item List"
{
    actions
    {
        addafter(PurchPriceLists)
        {
            action("Subcontractor Prices")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontractor Prices';
                Image = Price;
                RunObject = page "Subcontractor Prices";
                RunPageLink = "Item No." = field("No.");
                RunPageView = sorting("Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Starting Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code");
                ToolTip = 'Set up different prices for the item in subcontracting.';
            }
        }
    }
}