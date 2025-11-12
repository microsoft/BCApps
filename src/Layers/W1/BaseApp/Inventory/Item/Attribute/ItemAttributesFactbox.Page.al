// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;
using System.Environment;

page 9110 "Item Attributes Factbox"
{
    Caption = 'Item Attributes';
    DeleteAllowed = false;
    InsertAllowed = false;
    ModifyAllowed = false;
    PageType = ListPart;
    RefreshOnActivate = true;
    SourceTable = "Item Attribute Value";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(Control2)
            {
                ShowCaption = false;
                field(Attribute; Rec.GetAttributeNameInCurrentLanguage())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the name of the item attribute.';
                    Visible = TranslatedValuesVisible;
                }
                field(Value; Rec.GetValueInCurrentLanguage())
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the item attribute.';
                    Visible = TranslatedValuesVisible;
                }
                field("Attribute Name"; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the name of the item attribute.';
                    Visible = not TranslatedValuesVisible;
                }
                field(RawValue; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the item attribute.';
                    Visible = not TranslatedValuesVisible;
                }
            }
        }
    }

    actions
    {
        area(processing)
        {
            action(Edit)
            {
                AccessByPermission = TableData "Item Attribute" = R;
                ApplicationArea = Basic, Suite;
                Caption = 'Edit';
                Image = Edit;
                ToolTip = 'Edit item''s attributes, such as color, size, or other characteristics that help to describe the item.';
                Visible = IsItem;

                trigger OnAction()
                var
                    Item: Record Item;
                begin
                    if not IsItem then
                        exit;
                    if not Item.Get(ContextValue) then
                        exit;
                    PAGE.RunModal(PAGE::"Item Attribute Value Editor", Item);
                    CurrPage.SaveRecord();
                    LoadItemAttributesData(ContextValue);
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Rec.SetAutoCalcFields("Attribute Name");
        TranslatedValuesVisible := ClientTypeManagement.GetCurrentClientType() <> CLIENTTYPE::Phone;
        IsVisible := true;
        if ItemAttCode <> '' then begin
            LoadItemAttributesData(ItemAttCode);
            ItemAttCode := '';
        end;

        if CategoryAttCode <> '' then begin
            LoadCategoryAttributesData(CategoryAttCode);
            CategoryAttCode := '';
        end;
    end;

    var
        ClientTypeManagement: Codeunit "Client Type Management";

    protected var
        ContextType: Option "None",Item,Category;
        ContextValue: Code[20];
        IsItem: Boolean;
        IsVisible: Boolean;
        ItemAttCode: Code[20];
        CategoryAttCode: Code[20];
        TranslatedValuesVisible: Boolean;

    procedure LoadItemAttributesData(KeyValue: Code[20])
    begin
        if not IsVisible then begin
            ItemAttCode := KeyValue;
            exit;
        end;
        Rec.LoadItemAttributesFactBoxData(KeyValue);
        SetContext(ContextType::Item, KeyValue);
        CurrPage.Update(false);
    end;

    procedure LoadCategoryAttributesData(CategoryCode: Code[20])
    begin
        if not IsVisible then begin
            CategoryAttCode := CategoryCode;
            exit;
        end;
        Rec.LoadCategoryAttributesFactBoxData(CategoryCode);
        SetContext(ContextType::Category, CategoryCode);
        CurrPage.Update(false);
    end;

    local procedure SetContext(NewType: Option; NewValue: Code[20])
    begin
        ContextType := NewType;
        ContextValue := NewValue;
        IsItem := ContextType = ContextType::Item;
    end;
}

