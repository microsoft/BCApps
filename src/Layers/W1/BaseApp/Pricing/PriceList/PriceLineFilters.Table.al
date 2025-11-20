// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.PriceList;

using Microsoft.Finance.Currency;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.Source;
using Microsoft.Utilities;
using System.Reflection;
using System.Globalization;

table 7021 "Price Line Filters"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            AllowInCustomizations = Never;
            Caption = 'Primary Key';
            DataClassification = SystemMetadata;
        }
        field(2; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                PriceAsset: Record "Price Asset";
            begin
                if not "Copy Lines" then begin
                    if "Asset Type" = "Asset Type"::" " then
                        "Asset Type" := "Asset Type"::Item;
                    PriceAsset.Validate("Asset Type", "Asset Type");
                    "Table Id" := PriceAsset."Table Id";
                end;
                "Asset Filter" := '';
            end;
        }
        field(3; "Asset Filter"; Text[2048])
        {
            Caption = 'Product Filter';
            DataClassification = SystemMetadata;
        }
        field(4; "Table Id"; Integer)
        {
            Caption = 'Table Id';
            DataClassification = SystemMetadata;
        }
        field(5; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(6; "Adjustment Factor"; Decimal)
        {
            Caption = 'Adjustment Factor';
            DataClassification = SystemMetadata;
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            InitValue = 1;
        }
        field(7; "Rounding Method Code"; Code[10])
        {
            Caption = 'Rounding Method Code';
            DataClassification = SystemMetadata;
            TableRelation = "Rounding Method";
        }
        field(8; "From Price List Code"; Code[20])
        {
            Caption = 'From Price List Code';
            DataClassification = SystemMetadata;
            TableRelation = "Price List Header";

            trigger OnValidate()
            begin
                if ("From Price List Code" <> '') and ("From Price List Code" = "To Price List Code") then
                    Error(SameFromListCodeErr, FieldCaption("From Price List Code"), FieldCaption("To Price List Code"));

                "From Currency Code" := GetCurrencyCode("From Price List Code");
                "Different Currencies" := "To Currency Code" <> "From Currency Code";
            end;
        }
        field(9; "To Price List Code"; Code[20])
        {
            Caption = 'To Price List Code';
            DataClassification = SystemMetadata;
            TableRelation = "Price List Header";
        }
        field(10; "Price Type"; Enum "Price Type")
        {
            Caption = 'Price Type';
            DataClassification = SystemMetadata;
        }
        field(11; "Source Group"; Enum "Price Source Group")
        {
            Caption = 'Assign-to Group';
            DataClassification = SystemMetadata;
        }
        field(12; "Price Line Filter"; Text[2048])
        {
            Caption = 'Price Line Filter';
            DataClassification = SystemMetadata;
        }
        field(13; "From Currency Code"; Code[10])
        {
            Caption = 'From Currency Code';
            DataClassification = SystemMetadata;
        }
        field(14; "To Currency Code"; Code[10])
        {
            Caption = 'To Currency Code';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                InitRoundingPrecision("To Currency Code");
            end;
        }
        field(15; "Amount Rounding Precision"; Decimal)
        {
            Caption = 'Amount Rounding Precision';
            DataClassification = SystemMetadata;
        }
        field(16; "Exchange Rate Date"; Date)
        {
            Caption = 'Exchange Rate Date';
            DataClassification = SystemMetadata;
        }
        field(17; "Different Currencies"; Boolean)
        {
            Caption = 'Different Currencies';
            DataClassification = SystemMetadata;
        }
        field(18; "Copy Lines"; Boolean)
        {
            Caption = 'Copy Price List';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                Validate("Asset Type", "Asset Type"::" ");
                if not "Copy Lines" then
                    "From Price List Code" := '';
                Validate("From Price List Code");
            end;
        }
        field(19; Worksheet; Boolean)
        {
            Caption = 'Worksheet';
            DataClassification = SystemMetadata;
        }
        field(20; "Copy As New Lines"; Boolean)
        {
            Caption = 'Copy as new lines';
            DataClassification = SystemMetadata;
        }
        field(21; "Update Multiple Price Lists"; Boolean)
        {
            Caption = 'Update Multiple Price Lists';
            DataClassification = SystemMetadata;
        }
        field(22; "Force Defaults"; Boolean)
        {
            Caption = 'Use defaults from target';
            DataClassification = SystemMetadata;
        }
    }

    keys
    {
        key(PK; "Primary Key")
        { }
    }

    var
        SameFromListCodeErr: Label '%1 must not be the same as %2.', Comment = '%1 and %2 - captions of the fields From Price List Code and To Price List Code';

    procedure Initialize(PriceListHeader: Record "Price List Header"; CopyLines: Boolean)
    begin
        "Price Type" := PriceListHeader."Price Type";
        "Source Group" := PriceListHeader."Source Group";
        "To Price List Code" := PriceListHeader.Code;
        "Force Defaults" := not CopyLines or not PriceListHeader."Allow Updating Defaults";
        Validate("To Currency Code", PriceListHeader."Currency Code");
        "Exchange Rate Date" := WorkDate();

        Validate("Copy Lines", CopyLines);
    end;

    procedure EditAssetFilter()
    var
        ObjectTranslation: Record "Object Translation";
        PrimaryKeyField: Record "Field";
        FilterPageBuilder: FilterPageBuilder;
        TableCaptionValue: Text;
    begin
        TableCaptionValue :=
            ObjectTranslation.TranslateObject(ObjectTranslation."Object Type"::Table, "Table ID");
        FilterPageBuilder.AddTable(TableCaptionValue, "Table ID");
        if GetPrimaryKeyFields("Table Id", PrimaryKeyField) then
            repeat
                FilterPageBuilder.AddFieldNo(TableCaptionValue, PrimaryKeyField."No.")
            until PrimaryKeyField.Next() = 0;
        SetFilterByFilterPageBuilder("Asset Filter", TableCaptionValue, FilterPageBuilder);
    end;

    procedure EditPriceLineFilter()
    var
        PriceListLine: Record "Price List Line";
        FilterPageBuilder: FilterPageBuilder;
        TableCaptionValue: Text;
    begin
        TableCaptionValue := PriceListLine.TableCaption();
        FilterPageBuilder.AddTable(TableCaptionValue, Database::"Price List Line");
        FilterPageBuilder.AddFieldNo(TableCaptionValue, PriceListLine.FieldNo("Asset Type"));
        FilterPageBuilder.AddFieldNo(TableCaptionValue, PriceListLine.FieldNo("Asset No."));
        FilterPageBuilder.AddFieldNo(TableCaptionValue, PriceListLine.FieldNo("Amount Type"));
        OnEditPriceLineFilterOnAfterSetFilterPageBuilder(TableCaptionValue, PriceListLine, FilterPageBuilder);
        SetFilterByFilterPageBuilder("Price Line Filter", TableCaptionValue, FilterPageBuilder);
    end;

    local procedure GetCurrencyCode(PriceListCode: Code[20]): Code[10];
    var
        PriceListHeader: Record "Price List Header";
    begin
        if PriceListCode = '' then
            exit('');
        PriceListHeader.SetLoadFields("Currency Code");
        PriceListHeader.Get(PriceListCode);
        exit(PriceListHeader."Currency Code");
    end;

    local procedure GetPrimaryKeyFields(TableId: Integer; var PrimaryKeyField: Record "Field"): Boolean;
    begin
        PrimaryKeyField.Reset();
        PrimaryKeyField.SetRange(TableNo, TableId);
        PrimaryKeyField.Setrange(IsPartOfPrimaryKey, true);
        exit(PrimaryKeyField.FindSet());
    end;

    local procedure InitRoundingPrecision(CurrencyCode: Code[10])
    var
        Currency: Record Currency;
    begin
        if CurrencyCode = '' then begin
            Currency.Code := '';
            Currency.InitRoundingPrecision();
        end else begin
            Currency.Get(CurrencyCode);
            Currency.TestField("Unit-Amount Rounding Precision");
        end;
        "Amount Rounding Precision" := Currency."Unit-Amount Rounding Precision";
    end;

    local procedure SetFilterByFilterPageBuilder(var FilterValue: Text[2048]; TableCaptionValue: Text; var FilterPageBuilder: FilterPageBuilder)
    begin
        if FilterValue <> '' then
            FilterPageBuilder.SetView(TableCaptionValue, FilterValue);
        if FilterPageBuilder.RunModal() then
            FilterValue := CopyStr(FilterPageBuilder.GetView(TableCaptionValue, false), 1, MaxStrLen(FilterValue));
        OnAfterSetFilterByFilterPageBuilder(TableCaptionValue, FilterValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterByFilterPageBuilder(TableCaptionValue: Text; var FilterValue: Text[2048])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnEditPriceLineFilterOnAfterSetFilterPageBuilder(TableCaptionValue: Text; PriceListLine: Record "Price List Line"; var FilterPageBuilder: FilterPageBuilder)
    begin
    end;
}