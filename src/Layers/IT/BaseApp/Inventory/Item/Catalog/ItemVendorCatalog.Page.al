// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Purchases.Pricing;

page 114 "Item Vendor Catalog"
{
    Caption = 'Item Vendor Catalog';
    DataCaptionFields = "Item No.";
    PageType = List;
    SourceTable = "Item Vendor";
    DelayedInsert = true;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the item that the alternate direct unit cost is valid for.';
                    Visible = false;
                }
                field("Variant Code"; Rec."Variant Code")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the variant of the item on the line.';
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the vendor who offers the alternate direct unit cost.';
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number that the vendor uses for this item.';
                }
                field("Lead Time Calculation"; Rec."Lead Time Calculation")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a date formula for the amount of time it takes to replenish the item.';
                }
                field("Country/Region of Origin Code"; Rec."Country/Region of Origin Code")
                {
                    ApplicationArea = Suite;
                    ToolTip = 'Specifies the country/region code of the place of origin of the item.';
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
            group("&Item Vendor")
            {
                Caption = '&Item Vendor';
                Image = Item;
                action("Purch. &Prices")
                {
                    ApplicationArea = Planning;
                    Caption = 'Purch. &Prices';
                    Image = Price;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Prices";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Vendor No." = field("Vendor No.");
                    RunPageView = sorting("Item No.", "Vendor No.");
                    ToolTip = 'Define purchase price agreements with vendors for specific items.';
                }
                action("Purch. Line &Discounts")
                {
                    ApplicationArea = Planning;
                    Caption = 'Purch. Line &Discounts';
                    Image = LineDiscount;
                    Visible = not ExtendedPriceEnabled;
                    RunObject = Page "Purchase Line Discounts";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Vendor No." = field("Vendor No.");
                    RunPageView = sorting("Item No.", "Vendor No.");
                    ToolTip = 'Define purchase line discounts with vendors. For example, you may get for a line discount if you buy items from a vendor in large quantities.';
                }
                action(Prices)
                {
                    AccessByPermission = TableData "Purchase Price Access" = R;
                    ApplicationArea = Planning;
                    Caption = 'Purchase Prices';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Define purchase price agreements with vendors for specific items.';

                    trigger OnAction()
                    begin
                        Rec.ShowPriceListLines(Enum::"Price Amount Type"::Price);
                    end;
                }
                action(Discounts)
                {
                    AccessByPermission = TableData "Purchase Discount Access" = R;
                    ApplicationArea = Planning;
                    Caption = 'Purchase Discounts';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'Define purchase line discounts with vendors. For example, you may get for a line discount if you buy items from a vendor in large quantities.';

                    trigger OnAction()
                    begin
                        Rec.ShowPriceListLines(Enum::"Price Amount Type"::Discount);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
            group(Category_Category4)
            {
                Caption = 'Prices & Discounts', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Purch. &Prices_Promoted"; "Purch. &Prices")
                {
                }
                actionref("Purch. Line &Discounts_Promoted"; "Purch. Line &Discounts")
                {
                }
                actionref(Prices_Promoted; Prices)
                {
                }
                actionref(Discounts_Promoted; Discounts)
                {
                }
            }
        }
    }

    trigger OnOpenPage()
    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        ExtendedPriceEnabled: Boolean;
}

