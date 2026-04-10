// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Purchases.Pricing;

page 298 "Vendor Item List"
{
    Caption = 'Vendor Item List';
    DataCaptionFields = "Vendor No.";
    PageType = List;
    SourceTable = "Item Vendor";

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Suite;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Suite;
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Suite;
                }
            }
        }
        area(factboxes)
        {
            systempart(Control1900383207; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(Control1905767507; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("Vendor Item")
            {
                Caption = 'Vendor Item';
                Image = Item;
                action("Purch. Prices")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purch. Prices';
                    Image = Price;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Vendor No." = field("Vendor No.");
                    RunPageView = sorting("Item No.", "Vendor No.");
                    ToolTip = 'Define purchase price agreements with vendors for specific items.';
                }
                action("Purch. Line Discounts")
                {
                    ApplicationArea = Suite;
                    Caption = 'Purch. Line Discounts';
                    Image = LineDiscount;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Vendor No." = field("Vendor No.");
                    ToolTip = 'Define purchase line discounts with vendors. For example, you may get for a line discount if you buy items from a vendor in large quantities.';
                }
            }
        }
    }
}

