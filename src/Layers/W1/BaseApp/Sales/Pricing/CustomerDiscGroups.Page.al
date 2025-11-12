// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Pricing;

using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using System.Text;

page 512 "Customer Disc. Groups"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Customer Disc. Groups';
    PageType = List;
    SourceTable = "Customer Discount Group";
    UsageCategory = Administration;
    AdditionalSearchTerms = 'Customer Discount Groups';

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a code for the customer discount group.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description for the customer discount group.';
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
            group("Cust. &Disc. Groups")
            {
                Caption = 'Cust. &Disc. Groups';
                Image = Group;
                action(SalesLineDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales &Line Discounts';
                    Image = SalesLineDisc;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the sales line discounts that are available. These discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';

                    trigger OnAction()
                    var
                        SalesLineDiscount: Record "Sales Line Discount";
                    begin
                        SalesLineDiscount.SetCurrentKey("Sales Type", "Sales Code");
                        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::"Customer Disc. Group");
                        SalesLineDiscount.SetRange("Sales Code", Rec.Code);
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action(PriceLists)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = SalesLineDisc;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists with discounts for products that you sell to customers that belong to the customer discount group.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec);
                    end;
                }
                action(DiscountLines)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = SalesLineDisc;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales discounts for products that you sell to customers that belong to the customer discount group.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, "Price Amount Type"::Discount);
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
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 3.';
                actionref(SalesLineDiscounts_Promoted; SalesLineDiscounts)
                {
                }
                actionref(PriceLists_Promoted; PriceLists)
                {
                }
                actionref(DiscountLines_Promoted; DiscountLines)
                {
                }
            }
        }
    }
    trigger OnOpenPage()
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        ExtendedPriceEnabled: Boolean;

    procedure GetSelectionFilter(): Text
    var
        CustDiscGr: Record "Customer Discount Group";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(CustDiscGr);
        exit(SelectionFilterManagement.GetSelectionFilterForCustomerDiscountGroup(CustDiscGr));
    end;
}

