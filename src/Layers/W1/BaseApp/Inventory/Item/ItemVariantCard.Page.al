// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using Microsoft.Inventory.Item.Picture;

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
                    Visible = false;
                }
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Planning;

                    trigger OnValidate()
                    begin
                        if (xRec.Code = '') and (Rec.Code <> '') then
                            CurrPage.Update(true);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Planning;
                }
                field("Description 2"; Rec."Description 2")
                {
                    ApplicationArea = Planning;
                    Visible = false;
                }
                group(BlockedGroup)
                {
                    ShowCaption = false;
                    field(Blocked; Rec.Blocked)
                    {
                        ApplicationArea = Planning;
                    }
                    field("Sales Blocked"; Rec."Sales Blocked")
                    {
                        ApplicationArea = Planning;
                    }
                    field("Service Blocked"; Rec."Service Blocked")
                    {
                        ApplicationArea = Service;
                    }
                    field("Purchasing Blocked"; Rec."Purchasing Blocked")
                    {
                        ApplicationArea = Planning;
                    }
                }
            }
        }
        area(factboxes)
        {
            part(ItemVariantPicture; "Item Variant Picture")
            {
                ApplicationArea = All;
                Caption = 'Picture';
                SubPageLink = "Item No." = field("Item No."),
                              Code = field(Code);
            }
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
            }
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
                actionref(Attributes_Promoted; Attributes)
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
                action(Attributes)
                {
                    AccessByPermission = TableData "Item Attribute" = R;
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attributes';
                    Image = Category;
                    ToolTip = 'View or edit the item''s variant attributes, such as color, size, or other characteristics that help to describe the item variant.';

                    trigger OnAction()
                    begin
                        Page.RunModal(Page::"Item Variant Attribute Editor", Rec);
                        CurrPage.SaveRecord();
                        CurrPage.ItemAttributesFactbox.Page.LoadItemVariantAttributesData(Rec."Item No.", Rec.Code);
                    end;
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.ItemAttributesFactBox.Page.LoadItemVariantAttributesData(Rec."Item No.", Rec.Code);
    end;
}