// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Attribute;
using Microsoft.Inventory.Item.Catalog;
using System.Text;

page 5401 "Item Variants"
{
    Caption = 'Item Variants';
    DataCaptionFields = "Item No.";
    PageType = List;
    CardPageId = "Item Variant Card";
    SourceTable = "Item Variant";

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
                field(Blocked; Rec.Blocked)
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Sales Blocked"; Rec."Sales Blocked")
                {
                    ApplicationArea = Basic, Suite;
                }
                field("Service Blocked"; Rec."Service Blocked")
                {
                    ApplicationArea = Service;
                }
                field("Purchasing Blocked"; Rec."Purchasing Blocked")
                {
                    ApplicationArea = Basic, Suite;
                }
            }
        }
        area(factboxes)
        {
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
            }
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
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Variant';

                actionref(ItemReferences_Promoted; "Item Refe&rences")
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
            group("V&ariant")
            {
                Caption = 'V&ariant';
                Image = ItemVariant;
                action(Translations)
                {
                    ApplicationArea = Planning;
                    Caption = 'Translations';
                    Image = Translations;
                    RunObject = Page "Item Translations";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field(Code);
                    ToolTip = 'View or edit translated item descriptions. Translated item descriptions are automatically inserted on documents according to the language code.';
                }
                action("Item Refe&rences")
                {
                    AccessByPermission = TableData "Item Reference" = R;
                    ApplicationArea = Suite, ItemReferences;
                    Caption = 'Item References';
                    Image = Change;
                    RunObject = Page "Item Reference Entries";
                    RunPageLink = "Item No." = field("Item No."),
                                  "Variant Code" = field(Code);
                    Scope = Repeater;
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

    procedure GetSelectionFilter(): Text
    var
        ItemVariant: Record "Item Variant";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(ItemVariant);
        exit(SelectionFilterManagement.GetSelectionFilterForItemVariant(ItemVariant));
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.ItemAttributesFactBox.Page.LoadItemVariantAttributesData(Rec."Item No.", Rec.Code);
    end;

    trigger OnFindRecord(Which: Text): Boolean
    var
        Found: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindRecord(Rec, Which, CrossColumnSearchFilter, Found, IsHandled);
        if IsHandled then
            exit(Found);

        exit(Rec.Find(Which));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindRecord(var Rec: Record "Item Variant"; Which: Text; var CrossColumnSearchFilter: Text; var Found: Boolean; var IsHandled: Boolean)
    begin
    end;

    var
        CrossColumnSearchFilter: Text;
}

