// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Attribute;

page 5733 "Item Category Card"
{
    Caption = 'Item Category Card';
    DeleteAllowed = false;
    PageType = Card;
    RefreshOnActivate = true;
    SourceTable = "Item Category";

    layout
    {
        area(content)
        {
            group(General)
            {
                Caption = 'General';
                field("Code"; Rec.Code)
                {
                    ApplicationArea = Basic, Suite;
                    NotBlank = true;
                    ToolTip = 'Specifies the item category.';

                    trigger OnValidate()
                    begin
                        if (xRec.Code <> '') and (xRec.Code <> Rec.Code) then
                            CurrPage.Attributes.PAGE.SaveAttributes(Rec.Code);
                    end;
                }
                field(Description; Rec.Description)
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies a description of the item category.';
                }
                field("Parent Category"; Rec."Parent Category")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the item category that this item category belongs to. Item attributes that are assigned to a parent item category also apply to the child item category.';

                    trigger OnValidate()
                    begin
                        if (Rec.Code <> '') and (Rec."Parent Category" <> xRec."Parent Category") then
                            PersistCategoryAttributes();
                    end;
                }
            }
            part(Attributes; "Item Category Attributes")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Attributes';
                ShowFilter = false;
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Delete)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Delete';
                Enabled = CanDelete;
                Image = Delete;
                ToolTip = 'Delete the record.';

                trigger OnAction()
                begin
                    if Confirm(StrSubstNo(DeleteQst, Rec.Code)) then
                        Rec.Delete(true);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(Delete_Promoted; Delete)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        if Rec.Code <> '' then
            CurrPage.Attributes.PAGE.LoadAttributes(Rec.Code);

        CanDelete := not Rec.HasChildren();
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        CurrPage.Attributes.PAGE.SetItemCategoryCode(Rec.Code);
    end;

    trigger OnOpenPage()
    begin
        if Rec.Code <> '' then
            CurrPage.Attributes.PAGE.LoadAttributes(Rec.Code);
    end;

    trigger OnQueryClosePage(CloseAction: Action): Boolean
    begin
        if Rec.Code <> '' then
            CurrPage.Attributes.PAGE.SaveAttributes(Rec.Code);

        ItemCategoryManagement.CheckPresentationOrder();
    end;

    var
        ItemCategoryManagement: Codeunit "Item Category Management";
        DeleteQst: Label 'Delete %1?', Comment = '%1 - item category name';
        CanDelete: Boolean;

    local procedure PersistCategoryAttributes()
    begin
        CurrPage.Attributes.PAGE.SaveAttributes(Rec.Code);
        CurrPage.Attributes.PAGE.LoadAttributes(Rec.Code);
        CurrPage.Update(true);
    end;
}

