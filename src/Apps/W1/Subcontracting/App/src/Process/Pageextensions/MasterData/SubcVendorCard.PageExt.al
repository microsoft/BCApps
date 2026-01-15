// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Purchases.Vendor;

pageextension 99001516 "Subc. Vendor Card" extends "Vendor Card"
{
    layout
    {
        addafter("Location Code")
        {
            field("Subcontr. Location Code"; Rec."Subcontr. Location Code")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the subcontracting location where items from the vendor must be received by default after having performed an outside work .';
            }
            field("Linked to Work Center"; Rec."Linked to Work Center")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies if a work center is related to the vendor.';
            }
            field("Work Center No."; Rec."Work Center No.")
            {
                ApplicationArea = Manufacturing;
                ToolTip = 'Specifies the work center for purchase provision related to the vendor.';
            }
        }
    }
    actions
    {
        addafter("Prepa&yment Percentages")
        {
            action("Subcontractor Prices")
            {
                ApplicationArea = Manufacturing;
                Caption = 'Subcontractor Prices';
                Image = Price;
                RunObject = page "Subcontractor Prices";
                RunPageLink = "Vendor No." = field("No.");
                RunPageView = sorting("Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Starting Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code");
                ToolTip = 'Set up different prices for the vendor in subcontracting.';
            }
        }
    }
}