// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Catalog;

using Microsoft.Foundation.Comment;
using Microsoft.Inventory.Item.Substitution;

page 5725 "Catalog Item Card"
{
    Caption = 'Catalog Item Card';
    PageType = Card;
    SourceTable = "Nonstock Item";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Entry No."; Rec."Entry No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;

                    trigger OnAssistEdit()
                    begin
                        if Rec.AssistEdit() then
                            CurrPage.Update();
                    end;
                }
                field("Manufacturer Code"; Rec."Manufacturer Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Vendor No."; Rec."Vendor No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Vendor Item No."; Rec."Vendor Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Unit of Measure"; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Last Date Modified"; Rec."Last Date Modified")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
            group(Invoicing)
            {
                Caption = 'Invoicing';
                field("Published Cost"; Rec."Published Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Negotiated Cost"; Rec."Negotiated Cost")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Additional;
                }
                field("Unit Price"; Rec."Unit Price")
                {
                    ApplicationArea = Basic, Suite;
                    Importance = Promoted;
                }
                field("Gross Weight"; Rec."Gross Weight")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Net Weight"; Rec."Net Weight")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Bar Code"; Rec."Bar Code")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Item Templ. Code"; Rec."Item Templ. Code")
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
                    ToolTip = ' View or edit substitute items that are set up to be traded instead of the item in case it is not available.';
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
        area(processing)
        {
            group("F&unctions")
            {
                Caption = 'F&unctions';
                Image = "Action";
                action("&Create Item")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = '&Create Item';
                    Image = NewItemNonStock;
                    ToolTip = 'Convert the catalog item card to a normal item card, according to an item template that you choose.';

                    trigger OnAction()
                    begin
                        CatalogItemMgt.NonstockAutoItem(Rec);
                    end;
                }
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref("&Create Item_Promoted"; "&Create Item")
                {
                }
            }
        }
    }

    var
        CatalogItemMgt: Codeunit "Catalog Item Management";
}

