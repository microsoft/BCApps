// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Foundation.Comment;
using Microsoft.Inventory.Item.Substitution;
using Microsoft.Inventory.Reports;

page 5726 "Catalog Item List"
{
    AdditionalSearchTerms = 'non-inventoriable item';
    ApplicationArea = Basic, Suite, Service;
    Caption = 'Catalog Items';
    CardPageID = "Catalog Item Card";
    Editable = false;
    MultipleNewLines = false;
    PageType = List;
    SourceTable = "Nonstock Item";
    SourceTableView = sorting("Vendor Item No.", "Manufacturer Code")
                      order(ascending);
    UsageCategory = Lists;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                ShowCaption = false;
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Visible = false;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Suite;
                }
                field("Published Cost"; Rec."Published Cost")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Negotiated Cost"; Rec."Negotiated Cost")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item Templ. Code"; Rec."Item Templ. Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bar Code"; Rec."Bar Code")
                {
                    ApplicationArea = Basic, Suite;
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
            group("Ca&talog Item")
            {
                Caption = 'Ca&talog Item';
                Image = NonStockItem;
                action("Substituti&ons")
                {
                    ApplicationArea = Suite;
                    Caption = 'Substituti&ons';
                    Image = ItemSubstitution;
                    RunObject = Page "Item Substitution Entry";
                    RunPageLink = Type = const("Nonstock Item"),
                                  "No." = field("Entry No.");
                    ToolTip = 'View or edit substitute items that are set up to be traded instead of the item in case it is not available.';
                }
                action("Co&mments")
                {
                    ApplicationArea = Comments;
                    Caption = 'Co&mments';
                    Image = ViewComments;
                    RunObject = Page "Comment Sheet";
                    RunPageLink = "Table Name" = const("Nonstock Item"),
                                  "No." = field("Entry No.");
                    ToolTip = 'View or add comments for the record.';
                }
            }
        }
        area(reporting)
        {
            action("Catalog Item Sales")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Catalog Item Sales';
                Image = "Report";
                RunObject = Report "Catalog Item Sales";
                ToolTip = 'View a list of item sales for each catalog item during a selected time period. It can be used to review a company''s sale of catalog items.';
            }
            action("Item Substitutions")
            {
                ApplicationArea = Suite;
                Caption = 'Item Substitutions';
                Image = "Report";
                //The property 'PromotedCategory' can only be set if the property 'Promoted' is set to 'true'
                //PromotedCategory = "Report";
                RunObject = Report "Item Substitutions";
                ToolTip = 'View substitute items that are set up to be sold instead of the items in the filter. A detailed overview also includes description, unit cost, quantity on hand, base unit of measure, information about interchangeability and additional conditions.';
            }
        }
        area(Promoted)
        {
            group(Category_Report)
            {
                Caption = 'Reports';

                actionref("Catalog Item Sales_Promoted"; "Catalog Item Sales")
                {
                }
            }
        }
    }
}

