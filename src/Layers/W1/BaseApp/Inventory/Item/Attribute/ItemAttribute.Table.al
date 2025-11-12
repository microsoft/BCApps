// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Item.Attribute;

using System.Globalization;

table 7500 "Item Attribute"
{
    Caption = 'Item Attribute';
    DataCaptionFields = Name;
    LookupPageID = "Item Attributes";
    DataClassification = CustomerContent;

    fields
    {
        field(1; ID; Integer)
        {
            AutoIncrement = true;
            Caption = 'ID';
            NotBlank = true;
        }
        field(2; Name; Text[250])
        {
            Caption = 'Name';
            NotBlank = true;

            trigger OnValidate()
            begin
                if xRec.Name = Name then
                    exit;

                TestField(Name);
                if HasBeenUsed() then
                    if not Confirm(RenameUsedAttributeQst) then
                        Error('');
                CheckNameUniqueness(Rec, Name);
                DeleteValuesAndTranslationsConditionally(xRec, Name);
            end;
        }
        field(6; Blocked; Boolean)
        {
            Caption = 'Blocked';
        }
        field(7; Type; Option)
        {
            Caption = 'Type';
            InitValue = Text;
            OptionCaption = 'Option,Text,Integer,Decimal,Date';
            OptionMembers = Option,Text,"Integer",Decimal,Date;

            trigger OnValidate()
            var
                ItemAttributeValue: Record "Item Attribute Value";
            begin
                if xRec.Type <> Type then begin
                    ItemAttributeValue.SetRange("Attribute ID", ID);
                    if not ItemAttributeValue.IsEmpty() then
                        Error(ChangingAttributeTypeErr, Name);
                end;
            end;
        }
        field(8; "Unit of Measure"; Text[30])
        {
            Caption = 'Unit of Measure';

            trigger OnValidate()
            begin
                if (xRec."Unit of Measure" <> '') and (xRec."Unit of Measure" <> "Unit of Measure") then
                    if HasBeenUsed() then
                        if not Confirm(ChangeUsedAttributeUoMQst) then
                            Error('');
            end;
        }
    }

    keys
    {
        key(Key1; ID)
        {
            Clustered = true;
        }
        key(Key2; Name)
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; Name)
        {
        }
        fieldgroup(Brick; ID, Name)
        {
        }
    }

    trigger OnDelete()
    begin
        if HasBeenUsed() then
            if not Confirm(DeleteUsedAttributeQst) then
                Error('');
        DeleteValuesAndTranslations();
    end;

    trigger OnRename()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", xRec.ID);
        if ItemAttributeValue.FindSet() then
            repeat
                ItemAttributeValue.Rename(ID, ItemAttributeValue.ID);
            until ItemAttributeValue.Next() = 0;
    end;

    trigger OnInsert()
    begin
        TestField(Name);
    end;

    var
        ItemAttributeTranslation: Record "Item Attribute Translation";
        NameAlreadyExistsErr: Label 'The item attribute with name ''%1'' already exists.', Comment = '%1 - arbitrary name';
        ReuseValueTranslationsQst: Label 'There are values and translations for item attribute ''%1''.\\Do you want to reuse them after changing the item attribute name to ''%2''?', Comment = '%1 - arbitrary name,%2 - arbitrary name';
        ChangingAttributeTypeErr: Label 'You cannot change the type of item attribute ''%1'', because it is either in use or it has predefined values.', Comment = '%1 - arbirtrary text';
        DeleteUsedAttributeQst: Label 'This item attribute has been assigned to at least one item.\\Are you sure you want to delete it?';
        RenameUsedAttributeQst: Label 'This item attribute has been assigned to at least one item.\\Are you sure you want to rename it?';
        ChangeUsedAttributeUoMQst: Label 'This item attribute has been assigned to at least one item.\\Are you sure you want to change its unit of measure?';
        ChangeToOptionQst: Label 'Predefined values can be defined only for item attributes of type Option.\\Do you want to change the type of this item attribute to Option?';

    procedure GetTranslatedName(LanguageID: Integer) TranslatedName: Text[250]
    var
        Language: Codeunit Language;
        LanguageCode: Code[10];
        IsHandled: Boolean;
    begin
        OnBeforeGetTranslatedName(Rec, LanguageID, TranslatedName, IsHandled);
        if IsHandled then
            exit(TranslatedName);

        LanguageCode := Language.GetLanguageCode(LanguageID);
        if LanguageCode <> '' then begin
            GetAttributeTranslation(LanguageCode);
            exit(ItemAttributeTranslation.Name);
        end;
        exit(Name);
    end;

    procedure GetNameInCurrentLanguage(): Text[250]
    begin
        exit(GetTranslatedName(GlobalLanguage));
    end;

    local procedure GetAttributeTranslation(LanguageCode: Code[10])
    begin
        if (ItemAttributeTranslation."Attribute ID" <> ID) or (ItemAttributeTranslation."Language Code" <> LanguageCode) then
            if not ItemAttributeTranslation.Get(ID, LanguageCode) then begin
                ItemAttributeTranslation.Init();
                ItemAttributeTranslation."Attribute ID" := ID;
                ItemAttributeTranslation."Language Code" := LanguageCode;
                ItemAttributeTranslation.Name := Name;
                OnGetAttributeTranslationOnAfterCreateNewTranslation(Rec, ItemAttributeTranslation);
            end;
    end;

    procedure GetValues() Values: Text
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if Type <> Type::Option then
            exit('');
        ItemAttributeValue.SetRange("Attribute ID", ID);
        if ItemAttributeValue.FindSet() then
            repeat
                if Values <> '' then
                    Values += ',';
                Values += ItemAttributeValue.Value;
            until ItemAttributeValue.Next() = 0;
    end;

    procedure HasBeenUsed() AttributeHasBeenUsed: Boolean
    var
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
    begin
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ID);
        AttributeHasBeenUsed := not ItemAttributeValueMapping.IsEmpty();
        OnAfterHasBeenUsed(Rec, AttributeHasBeenUsed);
    end;

    procedure RemoveUnusedArbitraryValues()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        if Type = Type::Option then
            exit;

        ItemAttributeValue.SetRange("Attribute ID", ID);
        if ItemAttributeValue.FindSet() then
            repeat
                if not ItemAttributeValue.HasBeenUsed() then
                    ItemAttributeValue.Delete();
            until ItemAttributeValue.Next() = 0;
    end;

    procedure OpenItemAttributeValues()
    var
        ItemAttributeValue: Record "Item Attribute Value";
    begin
        ItemAttributeValue.SetRange("Attribute ID", ID);
        if (Type <> Type::Option) and ItemAttributeValue.IsEmpty() then
            if Confirm(ChangeToOptionQst) then begin
                Validate(Type, Type::Option);
                Modify();
            end;

        if Type = Type::Option then
            PAGE.Run(PAGE::"Item Attribute Values", ItemAttributeValue);
    end;

    local procedure CheckNameUniqueness(ItemAttribute: Record "Item Attribute"; NameToCheck: Text[250])
    begin
        OnBeforeCheckNameUniqueness(ItemAttribute, Rec);

        ItemAttribute.SetRange(Name, NameToCheck);
        ItemAttribute.SetFilter(ID, '<>%1', ItemAttribute.ID);
        if not ItemAttribute.IsEmpty() then
            Error(NameAlreadyExistsErr, NameToCheck);
    end;

    local procedure DeleteValuesAndTranslationsConditionally(ItemAttribute: Record "Item Attribute"; NameToCheck: Text[250])
    var
        ItemAttributeTranslation: Record "Item Attribute Translation";
        ItemAttributeValue: Record "Item Attribute Value";
        ValuesOrTranslationsExist: Boolean;
    begin
        if (ItemAttribute.Name <> '') and (ItemAttribute.Name <> NameToCheck) then begin
            ItemAttributeValue.SetRange("Attribute ID", ID);
            ItemAttributeTranslation.SetRange("Attribute ID", ID);
            ValuesOrTranslationsExist := not (ItemAttributeValue.IsEmpty() and ItemAttributeTranslation.IsEmpty);
            if ValuesOrTranslationsExist then
                if not Confirm(StrSubstNo(ReuseValueTranslationsQst, ItemAttribute.Name, NameToCheck)) then
                    DeleteValuesAndTranslations();
        end;
    end;

    local procedure DeleteValuesAndTranslations()
    var
        ItemAttributeValue: Record "Item Attribute Value";
        ItemAttributeValueMapping: Record "Item Attribute Value Mapping";
        ItemAttrValueTranslation: Record "Item Attr. Value Translation";
    begin
        ItemAttributeValueMapping.SetRange("Item Attribute ID", ID);
        ItemAttributeValueMapping.DeleteAll();

        ItemAttributeValue.SetRange("Attribute ID", ID);
        ItemAttributeValue.DeleteAll();

        ItemAttributeTranslation.SetRange("Attribute ID", ID);
        ItemAttributeTranslation.DeleteAll();

        ItemAttrValueTranslation.SetRange("Attribute ID", ID);
        ItemAttrValueTranslation.DeleteAll();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterHasBeenUsed(var ItemAttribute: Record "Item Attribute"; var AttributeHasBeenUsed: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckNameUniqueness(var NewItemAttribute: Record "Item Attribute"; ItemAttribute: Record "Item Attribute")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetTranslatedName(var ItemAttribute: Record "Item Attribute"; LanguageID: Integer; var TranslatedName: Text[250]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetAttributeTranslationOnAfterCreateNewTranslation(ItemAttribute: Record "Item Attribute"; var ItemAttributeTranslation: Record "Item Attribute Translation")
    begin
    end;
}

