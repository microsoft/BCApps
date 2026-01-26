// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Finance.Dimension;
using Microsoft.Inventory.Ledger;

page 5800 "Item Charges"
{
    AdditionalSearchTerms = 'fee transportation freight handling landed cost';
    ApplicationArea = ItemCharges;
    Caption = 'Item Charges';
    PageType = List;
    SourceTable = "Item Charge";
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("No."; Rec."No.")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies a description of the item charge number that you are setting up.';
                }
                field("Gen. Prod. Posting Group"; Rec."Gen. Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the item charge''s product type to link transactions made for this item charge with the appropriate general ledger account according to the general posting setup.';
                }
                field("Tax Group Code"; Rec."Tax Group Code")
                {
                    ApplicationArea = SalesTax;
                    ToolTip = 'Specifies the sales tax group code that this item charge belongs to.';
                }
                field("VAT Prod. Posting Group"; Rec."VAT Prod. Posting Group")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies the VAT specification of the involved item or resource to link transactions made for this record with the appropriate general ledger account according to the VAT posting setup.';
                }
                field("Search Description"; Rec."Search Description")
                {
                    ApplicationArea = ItemCharges;
                    ToolTip = 'Specifies text to search for when you do not know the number of the item charge.';
                }
                field("Freight/Insurance"; Rec."Freight/Insurance")
                {
                    ToolTip = 'Specifies if you require this item charge to be included for Intrastat reporting.';
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
            group("&Item Charge")
            {
                Caption = '&Item Charge';
                Image = Add;
                action("Value E&ntries")
                {
                    ApplicationArea = ItemCharges;
                    Caption = 'Value E&ntries';
                    Image = ValueLedger;
                    RunObject = Page "Value Entries";
                    RunPageLink = "Entry Type" = const("Direct Cost"),
                                  "Item Charge No." = field("No.");
                    RunPageView = sorting("Item Charge No.");
                    ShortCutKey = 'Ctrl+F7';
                    ToolTip = 'View the amounts related to item or capacity ledger entries for the record on the document or journal line.';
                }
                action(Dimensions)
                {
                    ApplicationArea = Dimensions;
                    Caption = 'Dimensions';
                    Image = Dimensions;
                    RunObject = Page "Default Dimensions";
                    RunPageLink = "Table ID" = const(5800),
                                  "No." = field("No.");
                    ShortCutKey = 'Alt+D';
                    ToolTip = 'View or edit dimensions, such as area, project, or department, that you can assign to sales and purchase documents to distribute costs and analyze transaction history.';
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
                Caption = 'Item Charge', Comment = 'Generated from the PromotedActionCategories property index 3.';

                actionref("Value E&ntries_Promoted"; "Value E&ntries")
                {
                }
                actionref(Dimensions_Promoted; Dimensions)
                {
                }
            }
        }
    }
}

