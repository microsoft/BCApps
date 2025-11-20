// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

table 7506 "Filter Item Attributes Buffer"
{
    Caption = 'Filter Item Attributes Buffer';
    ReplicateData = false;
    Description = 'This table is used by the Filter Item By Attribute feature. It should only be used as temporary.';
    DataClassification = CustomerContent;

    fields
    {
        field(1; Attribute; Text[250])
        {
            Caption = 'Attribute';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ItemAttribute: Record "Item Attribute";
            begin
                if not FindItemAttributeCaseInsensitive(ItemAttribute) then
                    Error(AttributeDoesntExistErr, Attribute);
                CheckForDuplicate();
                AdjustAttributeName(ItemAttribute);
            end;
        }
        field(2; Value; Text[250])
        {
            Caption = 'Value';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ItemAttributeValue: Record "Item Attribute Value";
                ItemAttribute: Record "Item Attribute";
            begin
                if Value <> '' then
                    if FindItemAttributeCaseSensitive(ItemAttribute) then
                        if ItemAttribute.Type = ItemAttribute.Type::Option then
                            if FindItemAttributeValueCaseInsensitive(ItemAttribute, ItemAttributeValue) then
                                AdjustAttributeValue(ItemAttributeValue);
            end;
        }
        field(3; ID; Guid)
        {
            Caption = 'ID';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(Key1; Attribute)
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        if IsNullGuid(ID) then
            ID := CreateGuid();
    end;

    var
        AttributeDoesntExistErr: Label 'The item attribute ''%1'' doesn''t exist.', Comment = '%1 - arbitrary name';
        AttributeValueAlreadySpecifiedErr: Label 'You have already specified a value for item attribute ''%1''.', Comment = '%1 - attribute name';

    procedure ValueAssistEdit()
    var
        ItemAttribute: Record "Item Attribute";
        FilterItemsAssistEdit: Page "Filter Items - AssistEdit";
    begin
        if FindItemAttributeCaseSensitive(ItemAttribute) then
            if ItemAttribute.Type = ItemAttribute.Type::Option then begin
                FilterItemsAssistEdit.SetRecord(ItemAttribute);
                Value := CopyStr(FilterItemsAssistEdit.LookupOptionValue(Value), 1, MaxStrLen(Value));
                exit;
            end;

        FilterItemsAssistEdit.SetTableView(ItemAttribute);
        FilterItemsAssistEdit.LookupMode(true);
        if FilterItemsAssistEdit.RunModal() = ACTION::LookupOK then
            Value := CopyStr(FilterItemsAssistEdit.GenerateFilter(), 1, MaxStrLen(Value));
    end;

    local procedure FindItemAttributeCaseSensitive(var ItemAttribute: Record "Item Attribute"): Boolean
    begin
        ItemAttribute.SetRange(Name, Attribute);
        exit(ItemAttribute.FindFirst());
    end;

    local procedure FindItemAttributeCaseInsensitive(var ItemAttribute: Record "Item Attribute"): Boolean
    var
        AttributeName: Text[250];
    begin
        if FindItemAttributeCaseSensitive(ItemAttribute) then
            exit(true);

        AttributeName := LowerCase(Attribute);
        ItemAttribute.SetRange(Name);
        if ItemAttribute.FindSet() then
            repeat
                if LowerCase(ItemAttribute.Name) = AttributeName then
                    exit(true);
            until ItemAttribute.Next() = 0;

        exit(false);
    end;

    local procedure FindItemAttributeValueCaseInsensitive(var ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value"): Boolean
    var
        AttributeValue: Text[250];
    begin
        ItemAttributeValue.SetRange("Attribute ID", ItemAttribute.ID);
        ItemAttributeValue.SetRange(Value, Value);
        if ItemAttributeValue.FindFirst() then
            exit(true);

        ItemAttributeValue.SetRange(Value);
        if ItemAttributeValue.FindSet() then begin
            AttributeValue := LowerCase(Value);
            repeat
                if LowerCase(ItemAttributeValue.Value) = AttributeValue then
                    exit(true);
            until ItemAttributeValue.Next() = 0;
        end;
        exit(false);
    end;

    local procedure CheckForDuplicate()
    var
        TempFilterItemAttributesBuffer: Record "Filter Item Attributes Buffer" temporary;
        AttributeName: Text[250];
    begin
        if IsEmpty() then
            exit;
        AttributeName := LowerCase(Attribute);
        TempFilterItemAttributesBuffer.Copy(Rec, true);
        if TempFilterItemAttributesBuffer.FindSet() then
            repeat
                if TempFilterItemAttributesBuffer.ID <> ID then
                    if LowerCase(TempFilterItemAttributesBuffer.Attribute) = AttributeName then
                        Error(AttributeValueAlreadySpecifiedErr, Attribute);
            until TempFilterItemAttributesBuffer.Next() = 0;
    end;

    local procedure AdjustAttributeName(var ItemAttribute: Record "Item Attribute")
    begin
        if Attribute <> ItemAttribute.Name then
            Attribute := ItemAttribute.Name;
    end;

    local procedure AdjustAttributeValue(var ItemAttributeValue: Record "Item Attribute Value")
    begin
        if Value <> ItemAttributeValue.Value then
            Value := ItemAttributeValue.Value;
    end;
}

