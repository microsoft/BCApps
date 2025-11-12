// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using Microsoft.Inventory.Item;
using System.Globalization;
using System.IO;

table 7501 "Item Attribute Value"
{
    Caption = 'Item Attribute Value';
    DataCaptionFields = Value;
    LookupPageID = "Item Attribute Values";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Attribute ID"; Integer)
        {
            Caption = 'Attribute ID';
            NotBlank = true;
            TableRelation = "Item Attribute".ID where(Blocked = const(false));
        }
        field(2; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
        }
        field(3; Value; Text[250])
        {
            Caption = 'Value';

            trigger OnValidate()
            var
                ItemAttribute: Record "Item Attribute";
            begin
                if xRec.Value = Value then
                    exit;

                TestField(Value);
                if HasBeenUsed() then
                    if not Confirm(RenameUsedAttributeValueQst) then
                        Error('');

                CheckValueUniqueness(Rec, Value);
                DeleteTranslationsConditionally(xRec, Value);

                ItemAttribute.Get("Attribute ID");
                if IsNumeric(ItemAttribute) then
                    Evaluate("Numeric Value", Value);
                if ItemAttribute.Type = ItemAttribute.Type::Date then
                    Evaluate("Date Value", Value);
            end;
        }
        field(4; "Numeric Value"; Decimal)
        {
            BlankZero = true;
            Caption = 'Numeric Value';

            trigger OnValidate()
            var
                ItemAttribute: Record "Item Attribute";
            begin
                if xRec."Numeric Value" = "Numeric Value" then
                    exit;

                ItemAttribute.Get("Attribute ID");
                if IsNumeric(ItemAttribute) then
                    Validate(Value, Format("Numeric Value", 0, 9));
            end;
        }
        field(5; "Date Value"; Date)
        {
            Caption = 'Date Value';

            trigger OnValidate()
            var
                ItemAttribute: Record "Item Attribute";
            begin
                if xRec."Date Value" = "Date Value" then
                    exit;

                ItemAttribute.Get("Attribute ID");
                if ItemAttribute.Type = ItemAttribute.Type::Date then
                    Validate(Value, Format("Date Value"));
            end;
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(10; "Attribute Name"; Text[250])
        {
            CalcFormula = lookup("Item Attribute".Name where(ID = field("Attribute ID")));
            Caption = 'Attribute Name';
            FieldClass = FlowField;
        }
    }

    keys
    {
        key(Key1; "Attribute ID", ID)
        {
            Clustered = true;
        }
        key(Key2; Value)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Value)
        {
        }
        fieldgroup(Brick; "Attribute Name", Value)
        {
        }
    }

    trigger OnDelete()
    var
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        if HasBeenUsed() then
            if not Confirm(DeleteUsedAttributeValueQst) then
                Error('');
        ItemAttributeValueMapping.SetRange("Item Attribute ID", "Attribute ID");
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ID);
        ItemAttributeValueMapping.DeleteAll();

        ItemAttrValueTranslation.SetRange("Attribute ID", "Attribute ID");
        ItemAttrValueTranslation.SetRange(ID, ID);
        ItemAttrValueTranslation.DeleteAll();
    end;

    var
        TransformationRule: Record "Transformation Rule";

        NameAlreadyExistsErr: Label 'The item attribute value with value ''%1'' already exists.', Comment = '%1 - arbitrary name';
        ReuseValueTranslationsQst: Label 'There are translations for item attribute value ''%1''.\\Do you want to reuse these translations for the new value ''%2''?', Comment = '%1 - arbitrary name,%2 - arbitrary name';
        DeleteUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item.\\Are you sure you want to delete it?';
        RenameUsedAttributeValueQst: Label 'This item attribute value has been assigned to at least one item.\\Are you sure you want to rename it?';
        CategoryStructureNotValidErr: Label 'The item category structure is not valid. The category %1 is a parent of itself or any of its children.', Comment = '%1 - Category Name';

    procedure LookupAttributeValue(AttributeID: Integer; var AttributeValueID: Integer)
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValues: Page "Item Attribute Values";
    begin
        ItemAttributeValue.SetRange("Attribute ID", AttributeID);
        ItemAttributeValues.LookupMode := true;
        ItemAttributeValues.SetTableView(ItemAttributeValue);
        if ItemAttributeValue.Get(AttributeID, AttributeValueID) then
            ItemAttributeValues.SetRecord(ItemAttributeValue);
        if ItemAttributeValues.RunModal() = ACTION::LookupOK then begin
            ItemAttributeValues.GetRecord(ItemAttributeValue);
            AttributeValueID := ItemAttributeValue.ID;
        end;
    end;

    procedure GetAttributeNameInCurrentLanguage(): Text[250]
    var
        ItemAttribute: Record "Item Attribute";
    begin
        if ItemAttribute.Get("Attribute ID") then
            exit(ItemAttribute.GetNameInCurrentLanguage());
        exit('');
    end;

    procedure GetValueInCurrentLanguage() ValueTxt: Text[250]
    var
        ItemAttribute: Record "Item Attribute";
    begin
        ValueTxt := GetValueInCurrentLanguageWithoutUnitOfMeasure();

        if ItemAttribute.Get("Attribute ID") then
            case ItemAttribute.Type of
                ItemAttribute.Type::Integer,
              ItemAttribute.Type::Decimal:
                    if ValueTxt <> '' then
                        exit(AppendUnitOfMeasure(ValueTxt, ItemAttribute));
            end;

        OnAfterGetValueInCurrentLanguage(Rec, ValueTxt);
    end;

    procedure GetValueInCurrentLanguageWithoutUnitOfMeasure(): Text[250]
    var
        ItemAttribute: Record "Item Attribute";
    begin
        if ItemAttribute.Get("Attribute ID") then
            case ItemAttribute.Type of
                ItemAttribute.Type::Option:
                    exit(GetTranslatedName(GlobalLanguage));
                ItemAttribute.Type::Text:
                    exit(Value);
                ItemAttribute.Type::Integer:
                    if Value <> '' then
                        exit(Format(Value));
                ItemAttribute.Type::Decimal:
                    if Value <> '' then
                        exit(Format("Numeric Value"));
                ItemAttribute.Type::Date:
                    exit(Format("Date Value"));
                else begin
                    OnGetValueInCurrentLanguage(ItemAttribute, Rec);
                    exit(Value);
                end;
            end;
        exit('');
    end;

    procedure GetTranslatedName(LanguageID: Integer): Text[250]
    var
        Language: Codeunit Language;
        LanguageCode: Code[10];
    begin
        LanguageCode := Language.GetLanguageCode(LanguageID);
        if LanguageCode <> '' then
            exit(GetTranslatedNameByLanguageCode(LanguageCode));
        exit(Value);
    end;

    procedure GetTranslatedNameByLanguageCode(LanguageCode: Code[10]): Text[250]
    var
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
    begin
        if not ItemAttrValueTranslation.Get("Attribute ID", ID, LanguageCode) then
            exit(Value);
        exit(ItemAttrValueTranslation.Name);
    end;

    local procedure CheckValueUniqueness(ItemAttributeValue: Record "Item Attribute Value"; NameToCheck: Text[250])
    begin
        ItemAttributeValue.SetRange("Attribute ID", "Attribute ID");
        ItemAttributeValue.SetFilter(ID, '<>%1', ItemAttributeValue.ID);
        ItemAttributeValue.SetRange(Value, NameToCheck);
        if not ItemAttributeValue.IsEmpty() then
            Error(NameAlreadyExistsErr, NameToCheck);
    end;

    local procedure DeleteTranslationsConditionally(ItemAttributeValue: Record "Item Attribute Value"; NameToCheck: Text[250])
    var
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
    begin
        if (ItemAttributeValue.Value <> '') and (ItemAttributeValue.Value <> NameToCheck) then begin
            ItemAttrValueTranslation.SetRange("Attribute ID", "Attribute ID");
            ItemAttrValueTranslation.SetRange(ID, ID);
            if not ItemAttrValueTranslation.IsEmpty() then
                if not Confirm(StrSubstNo(ReuseValueTranslationsQst, ItemAttributeValue.Value, NameToCheck)) then
                    ItemAttrValueTranslation.DeleteAll();
        end;
    end;

    local procedure AppendUnitOfMeasure(String: Text; ItemAttribute: Record "Item Attribute"): Text
    begin
        if ItemAttribute."Unit of Measure" <> '' then
            exit(StrSubstNo('%1 %2', String, Format(ItemAttribute."Unit of Measure")));
        exit(String);
    end;

    procedure HasBeenUsed(): Boolean
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        AttributeHasBeenUsed: Boolean;
    begin
        ItemAttributeValueMapping.SetRange("Item Attribute ID", "Attribute ID");
        ItemAttributeValueMapping.SetRange("Item Attribute Value ID", ID);
        AttributeHasBeenUsed := not ItemAttributeValueMapping.IsEmpty();
        OnAfterHasBeenUsed(Rec, AttributeHasBeenUsed);
        exit(AttributeHasBeenUsed);
    end;

    procedure SetValueFilter(var ItemAttribute: Record "Item Attribute"; FilterText: Text)
    var
        IndexOfOrCondition: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetValueFilter(Rec, ItemAttribute, FilterText, IsHandled);
        if IsHandled then
            exit;

        SetRange("Numeric Value");
        SetRange(Value);

        if IsNumeric(ItemAttribute) then begin
            SetFilter("Numeric Value", FilterText);
            exit;
        end;

        if ItemAttribute.Type = ItemAttribute.Type::Text then
            if (StrPos(FilterText, '*') = 0) and (StrPos(FilterText, '''') = 0) then begin
                FilterText := StrSubstNo('@*%1*', LowerCase(FilterText));
                IndexOfOrCondition := StrPos(FilterText, '|');
                if IndexOfOrCondition > 0 then begin
                    TransformationRule.Init();
                    TransformationRule."Find Value" := '|';
                    TransformationRule."Replace Value" := '*|@*';
                    TransformationRule."Transformation Type" := TransformationRule."Transformation Type"::Replace;
                    FilterText := TransformationRule.TransformText(FilterText);
                end
            end;

        if ItemAttribute.Type = ItemAttribute.Type::Date then
            if FilterText <> '' then begin
                SetFilter("Date Value", FilterText);
                exit;
            end;

        SetFilter(Value, FilterText);
    end;

    local procedure IsNumeric(var ItemAttribute: Record "Item Attribute"): Boolean
    begin
        exit(ItemAttribute.Type in [ItemAttribute.Type::Integer, ItemAttribute.Type::Decimal]);
    end;

    procedure LoadItemAttributesFactBoxData(KeyValue: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        Reset();
        DeleteAll();
        ItemAttributeValueMapping.SetRange("Table ID", Database::Item);
        ItemAttributeValueMapping.SetRange("No.", KeyValue);
        if ItemAttributeValueMapping.FindSet() then
            repeat
                if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then begin
                    TransferFields(ItemAttributeValue);
                    OnLoadItemAttributesFactBoxDataOnBeforeInsert(ItemAttributeValueMapping, Rec);
                    Insert();
                end
            until ItemAttributeValueMapping.Next() = 0;
    end;

    procedure LoadCategoryAttributesFactBoxData(CategoryCode: Code[20])
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttributeValue: Record "Item Attribute Value";
        ItemCategory: Record "Item Category";
        Categories: List of [Code[20]];
    begin
        Reset();
        DeleteAll();
        if CategoryCode = '' then
            exit;
        ItemAttributeValueMapping.SetRange("Table ID", Database::"Item Category");
        repeat
            if not Categories.Contains(CategoryCode) then
                Categories.Add(CategoryCode)
            else
                Error(CategoryStructureNotValidErr, CategoryCode);

            ItemAttributeValueMapping.SetRange("No.", CategoryCode);
            if ItemAttributeValueMapping.FindSet() then
                repeat
                    if ItemAttributeValue.Get(ItemAttributeValueMapping."Item Attribute ID", ItemAttributeValueMapping."Item Attribute Value ID") then
                        if not AttributeExists(ItemAttributeValue."Attribute ID") then begin
                            TransferFields(ItemAttributeValue);
                            OnLoadItemAttributesFactBoxDataOnBeforeInsert(ItemAttributeValueMapping, Rec);
                            Insert();
                        end;
                until ItemAttributeValueMapping.Next() = 0;
            if ItemCategory.Get(CategoryCode) then
                CategoryCode := ItemCategory."Parent Category"
            else
                CategoryCode := '';
        until CategoryCode = '';
    end;

    procedure AttributeExists(AttributeID: Integer) AttribExist: Boolean
    begin
        SetRange("Attribute ID", AttributeID);
        AttribExist := not IsEmpty();
        Reset();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetValueInCurrentLanguage(ItemAttributeValue: Record "Item Attribute Value"; var ValueTxt: Text[250])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasBeenUsed(ItemAttributeValue: Record "Item Attribute Value"; var AttributeHasBeenUsed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetValueFilter(var ItemAttributeValue: Record "Item Attribute Value"; ItemAttribute: Record "Item Attribute"; FilterText: Text; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetValueInCurrentLanguage(ItemAttribute: Record "Item Attribute"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLoadItemAttributesFactBoxDataOnBeforeInsert(var ItemAttributeValueMapping: Record "Item Attribute Value Mapping"; var ItemAttributeValue: Record "Item Attribute Value")
    begin
    end;
}

