// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item;

using Microsoft.Inventory.Item.Attribute;

table 5722 "Item Category"
{
    Caption = 'Item Category';
    LookupPageID = "Item Categories";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code';
            NotBlank = true;
        }
        field(2; "Parent Category"; Code[20])
        {
            Caption = 'Parent Category';
            TableRelation = "Item Category";

            trigger OnValidate()
            var
                ItemCategory: Record "Item Category";
                ItemAttributeManagement: Codeunit "Item Attribute Management";
                ParentCategory: Code[20];
            begin
                ParentCategory := "Parent Category";
                while ItemCategory.Get(ParentCategory) do begin
                    if ItemCategory.Code = Code then
                        Error(CyclicInheritanceErr);
                    ParentCategory := ItemCategory."Parent Category";
                end;
                if "Parent Category" <> xRec."Parent Category" then
                    ItemAttributeManagement.UpdateCategoryAttributesAfterChangingParentCategory(Code, "Parent Category", xRec."Parent Category");
            end;
        }
        field(3; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(9; Indentation; Integer)
        {
            Caption = 'Indentation';
            MinValue = 0;
        }
        field(10; "Presentation Order"; Integer)
        {
            Caption = 'Presentation Order';
        }
        field(11; "Has Children"; Boolean)
        {
            Caption = 'Has Children';
        }
        field(12; "Last Modified Date Time"; DateTime)
        {
            Caption = 'Last Modified Date Time';
            Editable = false;
        }
    }

    keys
    {
        key(Key1; "Code")
        {
            Clustered = true;
        }
        key(Key2; "Parent Category")
        {
        }
        key(Key3; "Presentation Order")
        {
        }
        key(Key4; Indentation, Code, Description)
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        if HasChildren() then
            Error(DeleteWithChildrenErr);
        UpdateDeletedCategoryItems();
        DeleteAssignedAttributes();
    end;

    trigger OnInsert()
    begin
        TestField(Code);
        UpdateIndentation();
        ItemCategoryManagement.CalcPresentationOrder(Rec);
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnModify()
    begin
        UpdateIndentation();
        ItemCategoryManagement.CalcPresentationOrder(Rec);
        "Last Modified Date Time" := CurrentDateTime;
    end;

    trigger OnRename()
    begin
        "Presentation Order" := 0;
        "Last Modified Date Time" := CurrentDateTime;
    end;

    var
        ItemCategoryManagement: Codeunit "Item Category Management";

        CyclicInheritanceErr: Label 'An item category cannot be a parent of itself or any of its children.';
        DeleteWithChildrenErr: Label 'You cannot delete this item category because it has child item categories.';
        DeleteItemInheritedAttributesQst: Label 'One or more items belong to item category ''''%1''''.\\Do you want to delete the inherited item attributes for the items in question? ', Comment = '%1 - item category code';

    procedure HasChildren(): Boolean
    var
        ItemCategory: Record "Item Category";
    begin
        ItemCategory.SetRange("Parent Category", Code);
        exit(not ItemCategory.IsEmpty)
    end;

    procedure GetStyleText(): Text
    begin
        if Indentation = 0 then
            exit('Strong');

        if HasChildren() then
            exit('Strong');

        exit('');
    end;

    local procedure UpdateDeletedCategoryItems()
    var
        CategoryItem: Record Item;
        TempCategoryItemAttributeValue: Record "Item Attribute Value" temporary;
        ItemAttributeManagement: Codeunit "Item Attribute Management";
        DeleteItemInheritedAttributes: Boolean;
    begin
        CategoryItem.SetRange("Item Category Code", Code);
        if CategoryItem.IsEmpty() then
            exit;
        DeleteItemInheritedAttributes := Confirm(StrSubstNo(DeleteItemInheritedAttributesQst, Code));
        if DeleteItemInheritedAttributes then
            TempCategoryItemAttributeValue.LoadCategoryAttributesFactBoxData(Code);
        if CategoryItem.Find('-') then
            repeat
                CategoryItem.Validate("Item Category Code", '');
                CategoryItem.Modify();
                if DeleteItemInheritedAttributes then
                    ItemAttributeManagement.DeleteItemAttributeValueMapping(CategoryItem, TempCategoryItemAttributeValue);
            until CategoryItem.Next() = 0;
    end;

    local procedure DeleteAssignedAttributes()
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.SetRange("Table ID", DATABASE::"Item Category");
        ItemAttributeValueMapping.SetRange("No.", Code);
        ItemAttributeValueMapping.DeleteAll();
    end;

    local procedure UpdateIndentation()
    var
        ParentItemCategory: Record "Item Category";
    begin
        if ParentItemCategory.Get("Parent Category") then
            UpdateIndentationTree(ParentItemCategory.Indentation + 1)
        else
            UpdateIndentationTree(0);
    end;

    [Scope('OnPrem')]
    procedure UpdateIndentationTree(Level: Integer)
    var
        ItemCategory: Record "Item Category";
    begin
        Indentation := Level;

        ItemCategory.SetRange("Parent Category", Code);
        if ItemCategory.FindSet() then
            repeat
                ItemCategory.UpdateIndentationTree(Level + 1);
                ItemCategory.Modify();
            until ItemCategory.Next() = 0;
    end;
}
