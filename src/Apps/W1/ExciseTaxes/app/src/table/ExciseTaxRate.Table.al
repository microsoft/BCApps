// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.ExciseTaxes;

using Microsoft.FixedAssets.FixedAsset;
using Microsoft.Inventory.Item;
using Microsoft.Sustainability.ExciseTax;

table 7416 "Excise Tax Rate"
{
    Caption = 'Excise Duty Rate';
    DataClassification = CustomerContent;
    LookupPageId = "Excise Tax Rates";
    DrillDownPageId = "Excise Tax Rates";

    fields
    {
        field(1; "Excise Tax Type Code"; Code[20])
        {
            Caption = 'Excise Tax Type Code';
            TableRelation = "Excise Tax Type".Code;
            NotBlank = true;
        }
        field(2; "Source Type"; Enum "Excise Source Type")
        {
            Caption = 'Source Type';
            NotBlank = true;

            trigger OnValidate()
            begin
                if "Source Type" <> "Source Type"::Item then
                    "Item Category Code" := '';
            end;
        }
        field(3; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Item)) Item
            else
            if ("Source Type" = const("Fixed Asset")) "Fixed Asset";

            trigger OnLookup()
            begin
                case "Source Type" of
                    "Source Type"::Item:
                        LookupItem();
                    "Source Type"::"Fixed Asset":
                        LookupFixedAsset();
                end;
            end;

            trigger OnValidate()
            begin
                if "Source No." <> '' then
                    ValidateSourceNo();
            end;
        }
        field(4; "Excise Duty"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Excise Duty Rate';
            DecimalPlaces = 2 : 5;
            MinValue = 0;

            trigger OnValidate()
            begin
                if ("Excise Duty" <> 0) and ("Excise Calculation Type" = "Excise Calculation Type"::"Ad valorem") then
                    Error(FieldNotAllowedForCalcTypeErr, FieldCaption("Excise Duty"), FieldCaption("Excise Calculation Type"), "Excise Calculation Type");
            end;
        }
        field(5; "Effective From Date"; Date)
        {
            Caption = 'Effective From Date';
            NotBlank = true;
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Excise Calculation Type"; Enum "Excise Calculation Type")
        {
            Caption = 'Excise Calculation Type';

            trigger OnValidate()
            begin
                case "Excise Calculation Type" of
                    "Excise Calculation Type"::"Specific per Unit":
                        "Excise Duty %" := 0;
                    "Excise Calculation Type"::"Ad valorem":
                        "Excise Duty" := 0;
                end;
            end;
        }
        field(9; "Excise Duty %"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Excise Duty %';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            MaxValue = 1000;

            trigger OnValidate()
            begin
                if ("Excise Duty %" <> 0) and ("Excise Calculation Type" = "Excise Calculation Type"::"Specific per Unit") then
                    Error(FieldNotAllowedForCalcTypeErr, FieldCaption("Excise Duty %"), FieldCaption("Excise Calculation Type"), "Excise Calculation Type");
            end;
        }
        field(10; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category".Code;

            trigger OnValidate()
            begin
                if "Item Category Code" <> '' then
                    TestField("Source Type", "Source Type"::Item);
            end;
        }
    }

    keys
    {
        key(Key1; "Excise Tax Type Code", "Source Type", "Source No.", "Item Category Code", "Effective From Date")
        {
            Clustered = true;
        }
        key(Key2; "Excise Tax Type Code")
        {
        }
    }

    trigger OnInsert()
    begin
        ValidateMandatoryFields();
    end;

    trigger OnModify()
    begin
        ValidateMandatoryFields();
    end;

    var
        ItemDoesNotExistErr: Label 'Item %1 does not exist.', Comment = '%1 = Item No.';
        FixedAssetDoesNotExistErr: Label 'Fixed Asset %1 does not exist.', Comment = '%1 = Fixed Asset No.';
        FieldNotAllowedForCalcTypeErr: Label 'You cannot specify %1 when %2 is %3.', Comment = '%1 = Caption of the field being set, %2 = Excise Calculation Type field caption, %3 = Excise Calculation Type value';

    local procedure ValidateMandatoryFields()
    begin
        TestField("Excise Tax Type Code");
        TestField("Source Type");
        TestField("Effective From Date");
        if "Source No." <> '' then
            ValidateSourceNo();
        if "Source Type" <> "Source Type"::Item then
            TestField("Item Category Code", '');
    end;

    local procedure ValidateSourceNo()
    var
        Item: Record Item;
        FixedAsset: Record "Fixed Asset";
    begin
        case "Source Type" of
            "Source Type"::Item:
                if not Item.Get("Source No.") then
                    Error(ItemDoesNotExistErr, "Source No.");
            "Source Type"::"Fixed Asset":
                if not FixedAsset.Get("Source No.") then
                    Error(FixedAssetDoesNotExistErr, "Source No.");
        end;
    end;

    local procedure LookupItem()
    var
        Item: Record Item;
    begin
        if Page.RunModal(Page::"Item List", Item) = Action::LookupOK then
            "Source No." := Item."No.";
    end;

    local procedure LookupFixedAsset()
    var
        FixedAsset: Record "Fixed Asset";
    begin
        if Page.RunModal(Page::"Fixed Asset List", FixedAsset) = Action::LookupOK then
            "Source No." := FixedAsset."No.";
    end;

    /// <summary>
    /// Loads the rate line that applies to the given source, from the most specific match to the rate that applies to every source of that type.
    /// </summary>
    procedure GetEffectiveExciseRate(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; ItemCategoryCode: Code[20]; EffectiveDate: Date): Boolean
    begin
        if SourceType <> "Excise Source Type"::Item then
            ItemCategoryCode := '';

        if (SourceNo <> '') and (ItemCategoryCode <> '') then
            if FindExciseRate(TaxTypeCode, SourceType, SourceNo, ItemCategoryCode, EffectiveDate) then
                exit(true);

        if SourceNo <> '' then
            if FindExciseRate(TaxTypeCode, SourceType, SourceNo, '', EffectiveDate) then
                exit(true);

        if ItemCategoryCode <> '' then
            if FindExciseRate(TaxTypeCode, SourceType, '', ItemCategoryCode, EffectiveDate) then
                exit(true);

        exit(FindExciseRate(TaxTypeCode, SourceType, '', '', EffectiveDate));
    end;

    local procedure FindExciseRate(TaxTypeCode: Code[20]; SourceType: Enum "Excise Source Type"; SourceNo: Code[20]; ItemCategoryCode: Code[20]; EffectiveDate: Date): Boolean
    var
        ExciseTaxRate: Record "Excise Tax Rate";
    begin
        ExciseTaxRate.SetCurrentKey("Excise Tax Type Code", "Source Type", "Source No.", "Item Category Code", "Effective From Date");
        ExciseTaxRate.SetRange("Excise Tax Type Code", TaxTypeCode);
        ExciseTaxRate.SetRange("Source Type", SourceType);
        ExciseTaxRate.SetRange("Source No.", SourceNo);
        ExciseTaxRate.SetRange("Item Category Code", ItemCategoryCode);
        ExciseTaxRate.SetFilter("Effective From Date", '<=%1', EffectiveDate);
        if not ExciseTaxRate.FindLast() then
            exit(false);

        Rec := ExciseTaxRate;
        exit(true);
    end;

    procedure ConvertSustSourceTypeToExciseSourceType(SustSourceType: Enum "Sust. Excise Jnl. Source Type"): Enum "Excise Source Type"
    begin
        case SustSourceType of
            "Sust. Excise Jnl. Source Type"::Item:
                exit("Excise Source Type"::Item);
            "Sust. Excise Jnl. Source Type"::"Fixed Asset":
                exit("Excise Source Type"::"Fixed Asset");
        end;

        exit("Excise Source Type"::" ");
    end;
}
