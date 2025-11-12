// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Picture;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Item.Attribute;

page 7499 "Item From Picture-Attrib Part"
{
    Caption = 'Item Attribute Values';
    DelayedInsert = true;
    LinksAllowed = false;
    PageType = ListPart;
    SourceTable = "Item Attribute Value Selection";
    SourceTableTemporary = true;

    layout
    {
        area(content)
        {
            repeater(AttributesRepeater)
            {
                ShowCaption = false;
                field(AttributeNameField; Rec."Attribute Name")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Attribute';
                    ToolTip = 'Specifies the item attribute.';
                    TableRelation = "Item Attribute".Name where(Blocked = const(false));

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttribute: Record "Item Attribute";
                    begin
                        if xRec."Attribute Name" <> '' then begin
                            xRec.FindItemAttributeByName(ItemAttribute);
                            ItemAttribute.RemoveUnusedArbitraryValues();
                        end;

                        if not Rec.FindAttributeValue(ItemAttributeValue) then
                            Rec.InsertItemAttributeValue(ItemAttributeValue, Rec);
                    end;
                }
                field(AttributeValueField; Rec.Value)
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Value';
                    ToolTip = 'Specifies the value of the item attribute.';
                    TableRelation = if ("Attribute Type" = const(Option)) "Item Attribute Value".Value where("Attribute ID" = field("Attribute ID"),
                                                                                                            Blocked = const(false));

                    trigger OnValidate()
                    var
                        ItemAttributeValue: Record "Item Attribute Value";
                        ItemAttribute: Record "Item Attribute";
                    begin
                        if not Rec.FindAttributeValue(ItemAttributeValue) then
                            Rec.InsertItemAttributeValue(ItemAttributeValue, Rec);

                        if ItemAttribute.Get(Rec."Attribute ID") then
                            if ItemAttribute.Type <> ItemAttribute.Type::Option then
                                if xRec.FindAttributeValue(ItemAttributeValue) then
                                    if not ItemAttributeValue.HasBeenUsed() then
                                        ItemAttributeValue.Delete();
                    end;
                }
                field(UnitOfMeasureField; Rec."Unit of Measure")
                {
                    ApplicationArea = Basic, Suite;
                    ToolTip = 'Specifies the name of the item or resource''s unit of measure, such as piece or hour.';
                    Editable = false;
                }
            }
        }
    }

    trigger OnModifyRecord(): Boolean
    begin
        UserEdited := true;
    end;

    trigger OnInsertRecord(BelowxRec: Boolean): Boolean
    begin
        UserEdited := true;
    end;

    var
        ItemFromPicture: Codeunit "Item From Picture";
        GlobalCategoryCode: Code[20];
        UserEdited: Boolean;
        ConfirmCategoryChangeTxt: Label 'This will change the new item category from "%1" to "%2", and will reset the item attributes.\\ Do you want to continue?', Comment = '%1, %2: two category names, for example "furniture" and "kitchen appliances"';

    procedure LoadAttributesFromCategory(CategoryCode: Code[20])
    var
        TempItemAttributeValue: Record "Item Attribute Value" temporary;
    begin
        if CategoryCode = GlobalCategoryCode then
            exit;

        GlobalCategoryCode := CategoryCode;

        if GlobalCategoryCode = '' then
            exit;

        if UserEdited then
            if not Confirm(StrSubstNo(ConfirmCategoryChangeTxt, GlobalCategoryCode, CategoryCode)) then
                Error('');

        Rec.DeleteAll();

        PopulateFromCategoryHierarchy(GlobalCategoryCode, TempItemAttributeValue);

        Rec.PopulateItemAttributeValueSelection(TempItemAttributeValue, DATABASE::"Item Category", GlobalCategoryCode);
    end;

    local procedure PopulateFromCategoryHierarchy(CategoryCode: Code[20]; var TempItemAttributeValue: Record "Item Attribute Value")
    var
        ItemCategory: Record "Item Category";
    begin
        repeat
            PopulateFromCategory(CategoryCode, TempItemAttributeValue);
            if ItemCategory.Get(CategoryCode) then
                CategoryCode := ItemCategory."Parent Category";
        until CategoryCode = '';
    end;

    local procedure PopulateFromCategory(CategoryCode: Code[20]; var TempItemAttributeValue: Record "Item Attribute Value")
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");

        ItemAttributeValueMapping.SetRange("No.", CategoryCode);
        if ItemAttributeValueMapping.FindSet() then
            repeat
                ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID");
                TempItemAttributeValue.TransferFields(ItemAttributeValue);
                if TempItemAttributeValue.Insert() then;
            until ItemAttributeValueMapping.Next() = 0;
    end;

    procedure ClearValues()
    begin
        ItemFromPicture.ClearAttributeValues(Rec);
    end;

    procedure SaveValues(Item: Record Item)
    begin
        ItemFromPicture.SaveAttributeValues(Rec, Item);
    end;
}
