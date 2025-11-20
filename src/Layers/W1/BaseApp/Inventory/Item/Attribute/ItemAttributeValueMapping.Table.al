// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;

table 7505 "Item Attribute Value Mapping"
{
    Caption = 'Item Attribute Value Mapping';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            Description = 'The table of the record to which the attribute applies (for example Database::Item or Database::"Item Category").';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            Description = 'The key of the record to which the attribute applies (the record type is specified by "Table ID").';
        }
        field(3; "Item Attribute ID"; Integer)
        {
            Caption = 'Item Attribute ID';
            TableRelation = "Item Attribute";
        }
        field(4; "Item Attribute Value ID"; Integer)
        {
            Caption = 'Item Attribute Value ID';
            TableRelation = "Item Attribute Value".ID;
        }
    }

    keys
    {
        key(Key1; "Table ID", "No.", "Item Attribute ID")
        {
            Clustered = true;
        }
        key(Key2; "Item Attribute ID", "Item Attribute Value ID")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        ItemAttribute: Record "Item Attribute";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnDelete(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemAttribute.Get("Item Attribute ID");
        if ItemAttribute.Type = ItemAttribute.Type::Option then
            exit;

        if not ItemAttributeValue.Get("Item Attribute ID", "Item Attribute Value ID") then
            exit;

        ItemAttributeValueMapping.SetRange("Item Attribute ID", "Item Attribute ID");
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", "Item Attribute Value ID");
        if ItemAttributeValueMapping.Count <> 1 then
            exit;

        ItemAttributeValueMapping := Rec;
        if ItemAttributeValueMapping.Find() then
            ItemAttributeValue.Delete();
    end;

    trigger OnInsert()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        RecRef: RecordRef;
        FieldRef: FieldRef;
    begin
        RecRef.Open("Table ID");
        FieldRef := RecRef.Field(1);
        FieldRef.SetRange("No.");
        RecRef.FindFirst();

        if "Item Attribute Value ID" <> 0 then
            ItemAttributeValue.Get("Item Attribute ID", "Item Attribute Value ID");
    end;

    procedure RenameItemAttributeValueMapping(PrevNo: Code[20]; NewNo: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        SetRange("Table ID", Database::Item);
        SetRange("No.", PrevNo);
        if FindSet() then
            repeat
                ItemAttributeValueMapping := Rec;
                ItemAttributeValueMapping.Rename("Table ID", NewNo, "Item Attribute ID");
            until Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnDelete(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var IsHandled: Boolean)
    begin
    end;
}

