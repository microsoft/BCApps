// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.CRM.Campaign;

using Microsoft.CRM.Comment;
using Microsoft.CRM.Opportunity;
using Microsoft.CRM.Reports;
using Microsoft.CRM.Segment;
using Microsoft.CRM.Task;
using Microsoft.Finance.Dimension;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Sales.Pricing;

page 5086 "Campaign Card"
{
    Caption = 'Campaign Card';
    PageType = Card;
    PopulateAllFields = true;
    SourceTable = Campaign;

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit(xRec) then
                            CurrPage.Update();
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the description of the campaign.';
                }
                field("Status Code"; Rec."Status Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the status code for the campaign.';
                }
                field("Starting Date"; Rec."Starting Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date on which the campaign is valid. There are certain rules for how dates should be entered.';
                }
                field("Ending Date"; Rec."Ending Date")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the last day on which this campaign is valid.';
                }
                field("Salesperson Code"; Rec."Salesperson Code")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the code of the salesperson responsible for the campaign.';
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies the date when the campaign card was last modified. This field is not editable.';
                }
                field(Activated; Rec.Activated)
                {
                    ApplicationArea = RelationshipMgmt;
                    ToolTip = 'Specifies if a sales lines price discount has been activated. After you set up a campaign and create segments for it, you can create discounts for targeted audiences.';
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Global Dimension 1 Code"; Rec."Global Dimension 1 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
                }
                field("Global Dimension 2 Code"; Rec."Global Dimension 2 Code")
                {
                    ApplicationArea = Dimensions;
                    ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
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
                Visible = true;
            }
        }
    }

    actions
    {
        area(navigation)
        {
            group("C&ampaign")
            {
                Caption = 'C&ampaign';
                Image = Campaign;
                action("E&ntries")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'E&ntries';
                    Image = Entries;
                    RunObject = Page "Campaign Entries";
                    RunPageLink = "Campaign No." = field("No.");
                    RunPageView = sorting("Campaign No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View all the entries linked to the campaign. In this window, you cannot manually create new campaign entries.';
                }
                action("Co&mments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Rlshp. Mgt. Comment Sheet";
                    RunPageLink = "Table Name" = const(Campaign),
                                  "No." = field("No."),
                                  "Sub No." = const(0);
                    ToolTip = 'View or add comments for the record.';
                }
                action(Statistics)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Statistics';
                    Image = Statistics;
                    RunObject = Page "Campaign Statistics";
                    RunPageLink = "No." = field("No.");
                    ShortCutKey = 'F7';
                    ToolTip = 'View key figures concerning your campaign.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5071),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
                }
                action("T&asks")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'T&asks';
                    Image = TaskList;
                    RunObject = Page "Task List";
                    RunPageLink = "Campaign No." = field("No."),
                                  "System To-do Type" = filter(Organizer);
                    RunPageView = sorting("Campaign No.");
                    ToolTip = 'View tasks for the campaign.';
                }
                action("S&egments")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'S&egments';
                    Image = Segment;
                    RunObject = Page "Segment List";
                    RunPageLink = "Campaign No." = field("No.");
                    RunPageView = sorting("Campaign No.");
                    ToolTip = 'View a list of all the open segments. Open segments are those for which the interaction has not been logged yet.';
                }
                action("Oppo&rtunities")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Oppo&rtunities';
                    Image = OpportunitiesList;
                    RunObject = Page "Opportunity List";
                    RunPageLink = "Campaign No." = field("No.");
                    RunPageView = sorting("Campaign No.");
                    ToolTip = 'View opportunities for the campaign.';
                }
                action("Sales &Prices")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Prices';
                    Image = SalesPrices;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'Define how to set up sales price agreements. These sales prices can be for individual customers, for a group of customers, for all customers, or for a campaign.';

                    trigger OnAction()
                    var
                        SalesPrice: Record "Sales Price";
                    begin
                        SalesPrice.SetCurrentKey("Sales Type", "Sales Code");
                        SalesPrice.SetRange("Sales Type", SalesPrice."Sales Type"::Campaign);
                        SalesPrice.SetRange("Sales Code", Rec."No.");
                        Page.Run(Page::"Sales Prices", SalesPrice);
                    end;
                }
                action("Sales &Line Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = 'Sales &Line Discounts';
                    Image = SalesLineDisc;
                    Visible = not ExtendedPriceEnabled;
                    ToolTip = 'View the sales line discounts that are available. These discount agreements can be for individual customers, for a group of customers, for all customers or for a campaign.';

                    trigger OnAction()
                    var
                        SalesLineDiscount: Record "Sales Line Discount";
                    begin
                        SalesLineDiscount.SetCurrentKey("Sales Type", "Sales Code");
                        SalesLineDiscount.SetRange("Sales Type", SalesLineDiscount."Sales Type"::Campaign);
                        SalesLineDiscount.SetRange("Sales Code", Rec."No.");
                        Page.Run(Page::"Sales Line Discounts", SalesLineDiscount);
                    end;
                }
                action(PriceLists)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Price Lists';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lists for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, Enum::"Price Type"::Sale, Enum::"Price Amount Type"::Any);
                    end;
                }
                action(PriceLines)
                {
                    AccessByPermission = TableData "Sales Price Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Prices';
                    Image = Price;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up sales price lines for products that you sell to the customer. A product price is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Price);
                    end;
                }
                action(DiscountLines)
                {
                    AccessByPermission = TableData "Sales Discount Access" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Sales Discounts';
                    Image = LineDiscount;
                    Visible = ExtendedPriceEnabled;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceSource: Record "Price Source";
                        PriceUXManagement: Codeunit "Price UX Management";
                    begin
                        Rec.ToPriceSource(PriceSource);
                        PriceUXManagement.ShowPriceListLines(PriceSource, Enum::"Price Amount Type"::Discount);
                    end;
                }
                action(PriceListsDiscounts)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Price Lists (Discounts)';
                    Image = LineDiscount;
                    Visible = false;
                    ToolTip = 'View or set up different discounts for products that you sell to the customer. A product line discount is automatically granted on invoice lines when the specified criteria are met, such as customer, quantity, or ending date.';

                    trigger OnAction()
                    var
                        PriceUXManagement: Codeunit "Price UX Management";
                        AmountType: Enum "Price Amount Type";
                        PriceType: Enum "Price Type";
                    begin
                        PriceUXManagement.ShowPriceLists(Rec, PriceType::Sale, AmountType::Discount);
                    end;
                }
            }
        }
        area(processing)
        {
            group(Functions)
            {
                Caption = 'F&unctions';
                Image = "Action";
                action(ActivateSalesPricesLineDisc)
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Activate Sales Prices/Line Discounts';
                    Image = ActivateDiscounts;
                    ToolTip = 'Activate discounts that are associated with the campaign.';

                    trigger OnAction()
                    begin
                        CampaignMgmt.ActivateCampaign(Rec);
                    end;
                }
                action("&Deactivate Sales Prices/Line Discounts")
                {
                    ApplicationArea = RelationshipMgmt;
                    Caption = '&Deactivate Sales Prices/Line Discounts';
                    Image = DeactivateDiscounts;
                    ToolTip = 'Deactivate discounts that are associated with the campaign.';

                    trigger OnAction()
                    begin
                        CampaignMgmt.DeactivateCampaign(Rec, true);
                    end;
                }
            }
        }
        area(reporting)
        {
            action("Campaign Details")
            {
                ApplicationArea = RelationshipMgmt;
                Caption = 'Campaign Details';
                Image = "Report";
                RunObject = Report "Campaign - Details";
                ToolTip = 'Show detailed information about the campaign.';
            }
        }
        area(Promoted)
        {
            group(Category_Category4)
            {
                Caption = 'Campaign', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref(Dimensions_Promoted; Dimensions)
                {
                }
                actionref(Statistics_Promoted; Statistics)
                {
                }
                actionref("Co&mments_Promoted"; "Co&mments")
                {
                }
                actionref("S&egments_Promoted"; "S&egments")
                {
                }
                actionref("Oppo&rtunities_Promoted"; "Oppo&rtunities")
                {
                }
            }
            group(Category_Category5)
            {
                Caption = 'Navigate', Comment = 'Generated from the PromotedActionCategories property index 4.';

                actionref(PriceListsDiscounts_Promoted; PriceListsDiscounts)
                {
                }
            }
            group(Category_Category6)
            {
                Caption = 'Prices & Discounts', Comment = 'Generated from the PromotedActionCategories property index 5.';

                actionref("Sales &Prices_Promoted"; "Sales &Prices")
                {
                }
                actionref(ActivateSalesPricesLineDisc_Promoted; ActivateSalesPricesLineDisc)
                {
                }
                actionref(PriceLines_Promoted; PriceLines)
                {
                }
                actionref(PriceLists_Promoted; PriceLists)
                {
                }
                actionref("Sales &Line Discounts_Promoted"; "Sales &Line Discounts")
                {
                }
                actionref(DiscountLines_Promoted; DiscountLines)
                {
                }
                actionref("&Deactivate Sales Prices/Line Discounts_Promoted"; "&Deactivate Sales Prices/Line Discounts")
                {
                }
            }
            group(Category_Report)
            {
                Caption = 'Report', Comment = 'Generated from the PromotedActionCategories property index 2.';
            }
        }
    }

    trigger OnOpenPage()
    begin
        ExtendedPriceEnabled := PriceCalculationMgt.IsExtendedPriceCalculationEnabled();
    end;

    var
        CampaignMgmt: Codeunit "Campaign Target Group Mgt";
        PriceCalculationMgt: Codeunit "Price Calculation Mgt.";
        ExtendedPriceEnabled: Boolean;
}

