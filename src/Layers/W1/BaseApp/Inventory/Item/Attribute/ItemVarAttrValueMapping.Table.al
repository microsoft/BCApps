// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;

table 7507 "Item Var. Attr. Value Mapping"
{
    Caption = 'Item Variant Attribute Value Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
            NotBlank = true;
        }
        field(2; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
            NotBlank = true;
        }
        field(3; "Item Attribute ID"; Integer)
        {
            Caption = 'Item Attribute ID';
            TableRelation = "Item Attribute";
            NotBlank = true;
        }
        field(4; "Item Attribute Value ID"; Integer)
        {
            Caption = 'Item Attribute Value ID';
            TableRelation = "Item Attribute Value".ID;
            NotBlank = true;
        }
        field(8; "Inherited-From Table ID"; Integer)
        {
            Caption = 'Inherited-From Table ID';
        }
        field(9; "Inherited-From Key Value"; Code[20])
        {
            Caption = 'Inherited-From Key Value';
        }
    }

    keys
    {
        key(Key1; "Item No.", "Variant Code", "Item Attribute ID")
        {
            Clustered = true;
        }
        key(Key2; "Item Attribute ID", "Item Attribute Value ID")
        {
        }
    }

    trigger OnDelete()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        ItemAttribute.Get("Item Attribute ID");
        if ItemAttribute.Type = ItemAttribute.Type::Option then
            exit;

        if not ItemAttributeValue.Get("Item Attribute ID", "Item Attribute Value ID") then
            exit;

        ItemVariantAttributeValueMapping.SetRange("Item Attribute ID", "Item Attribute ID");
        ItemVariantAttributeValueMapping.SetRange("Item Attribute Value ID", "Item Attribute Value ID");
        if ItemVariantAttributeValueMapping.Count <> 1 then
            exit;

        ItemAttributeValueMapping.SetRange("Item Attribute ID", "Item Attribute ID");
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", "Item Attribute Value ID");
        if not ItemAttributeValueMapping.IsEmpty() then
            exit;

        ItemVariantAttributeValueMapping := Rec;
        if ItemVariantAttributeValueMapping.Find() then
            ItemAttributeValue.Delete();
    end;

    trigger OnInsert()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if "Item Attribute Value ID" <> 0 then
            ItemAttributeValue.Get("Item Attribute ID", "Item Attribute Value ID");
    end;

    procedure RenameItemVariantAttributeMapping(PrevItemNo: Code[20]; PrevVariantCode: Code[10]; NewItemNo: Code[20]; NewVariantCode: Code[10])
    var
        ItemVariantAttributeValueMapping: Record "Item Var. Attr. Value Mapping";
    begin
        SetRange("Item No.", PrevItemNo);
        SetRange("Variant Code", PrevVariantCode);
        if FindSet() then
            repeat
                ItemVariantAttributeValueMapping := Rec;
                ItemVariantAttributeValueMapping.Rename(NewItemNo, NewVariantCode, "Item Attribute ID");
            until Next() = 0;
    end;
}