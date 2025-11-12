// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Attribute;
using System.Text;

page 5730 "Item Categories"
{
    ApplicationArea = Basic, Suite;
    Caption = 'Item Categories';
    CardPageID = "Item Category Card";
    InsertAllowed = false;
    PageType = List;
    AboutTitle = 'About Item Categories';
    AboutText = 'Organize and manage item categories to group items for easier sorting and overview, assign attributes to categories, and ensure consistent classification of items across your inventory.';
    RefreshOnActivate = true;
    ShowFilter = false;
    SourceTable = "Item Category";
    SourceTableView = sorting("Presentation Order");
    UsageCategory = Administration;

    layout
    {
        area(content)
        {
            repeater(Control1)
            {
                IndentationColumn = Rec.Indentation;
                IndentationControls = "Code";
                ShowAsTree = true;
                ShowCaption = false;
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    StyleExpr = StyleTxt;
                    ToolTip = 'Specifies the code for the item category.';
                    Editable = false;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(false);
                        CurrPage.ItemAttributesFactbox.PAGE.LoadCategoryAttributesData(Rec.Code);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item category.';
                }
            }
        }
        area(factboxes)
        {
            part(ItemAttributesFactbox; "Item Attributes Factbox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attributes';
            }
        }
    }

    actions
    {
        area(creation)
        {
            action(Recalculate)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Recalculate';
                Image = Hierarchy;
                ToolTip = 'Update the tree of item categories based on recent changes.';

                trigger OnAction()
                begin
                    ItemCategoryManagement.UpdatePresentationOrder();
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Recalculate_Promoted; Recalculate)
                {
                }
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        StyleTxt := Rec.GetStyleText();
        CurrPage.ItemAttributesFactbox.PAGE.LoadCategoryAttributesData(Rec.Code);
    end;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := Rec.GetStyleText();
    end;

    trigger OnDeleteRecord(): Boolean
    begin
        StyleTxt := Rec.GetStyleText();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        StyleTxt := Rec.GetStyleText();
    end;

    trigger OnOpenPage()
    begin
        ItemCategoryManagement.CheckPresentationOrder();
    end;

    protected var
        ItemCategoryManagement: Codeunit "Item Category Management";
        StyleTxt: Text;

    procedure GetSelectionFilter(): Text
    var
        ItemCategory: Record "Item Category";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
    begin
        CurrPage.SetSelectionFilter(ItemCategory);
        exit(SelectionFilterManagement.GetSelectionFilterForItemCategory(ItemCategory));
    end;

    procedure SetSelection(var ItemCategory: Record "Item Category")
    begin
        CurrPage.SetSelectionFilter(ItemCategory);
    end;
}

