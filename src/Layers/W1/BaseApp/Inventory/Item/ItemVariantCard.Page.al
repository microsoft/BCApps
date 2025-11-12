// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Catalog;

page 5405 "Item Variant Card"
{
    Caption = 'Item Variant Card';
    PageType = Card;
    RefreshOnActivate = true;
    UsageCategory = None;
    SourceTable = "Item Variant";

    layout
    {
        area(Content)
        {
            group(ItemVariant)
            {
                Caption = 'Item Variant';
                field("Item No."; Rec."Item No.")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the number of the item card from which you opened the Item Variant Translations window.';
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies a code to identify the variant.';
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies text that describes the item variant.';
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    ToolTip = 'Specifies the item variant in more detail than the Description field.';
                    Visible = false;
                }
                group(BlockedGroup)
                {
                    ShowCaption = false;
                    field(Blocked; Rec.Blocked)
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the related record is blocked from being posted in transactions, for example an item variant that is placed in quarantine.';
                    }
                    field("Sales Blocked"; Rec."Sales Blocked")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the item variant cannot be entered on sales documents, except return orders and credit memos, and journals.';
                    }
                    field("Service Blocked"; Rec."Service Blocked")
                    {
                        ApplicationArea = Service;
                        ToolTip = 'Specifies that the item variant cannot be entered on service items, service contracts and service documents, except credit memos.';
                    }
                    field("Purchasing Blocked"; Rec."Purchasing Blocked")
                    {
                        ApplicationArea = Planning;
                        ToolTip = 'Specifies that the item variant cannot be entered on purchase documents, except return orders and credit memos, and journals.';
                    }
                }
            }
        }
        area(factboxes)
        {
            systempart(LinksPart; Links)
            {
                ApplicationArea = RecordLinks;
                Visible = false;
            }
            systempart(NotesPart; Notes)
            {
                ApplicationArea = Notes;
                Visible = false;
            }
        }
    }

    actions
    {
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Variant';

                actionref(ItemReferences_Promoted; "Item References")
                {
                }
                actionref(Translation_Promoted; Translations)
                {
                }
            }
        }
        area(navigation)
        {
            group("Variant")
            {
                Caption = 'Variant';
                Image = ItemVariant;
                action(Translations)
                {
                    ApplicationArea = Planning;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = field("Item No."), "Variant Code" = field(Code);
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                action("Item References")
                {
                    AccessByPermission = TableData "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    Caption = 'Item References';
                    Image = Change;
                    RunObject = Page "Item Reference Entries";
                    RunPageLink = "Item No." = field("Item No."), "Variant Code" = field(Code);
                    ToolTip = 'Set up a customer''s or vendor''s own identification of the selected item variant.';
                }
            }
        }
    }
}

