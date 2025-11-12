// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Asset;

using Microsoft.Finance.VAT.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Calculation;
using Microsoft.Pricing.PriceList;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 7003 "Price Asset"
{
    TableType = Temporary;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            DataClassification = SystemMetadata;
        }
        field(2; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                VerifyConsistentAssetType();
                InitAsset();
                ValidateAssetNo();
            end;
        }
        field(3; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Asset No." = '' then
                    InitAsset()
                else
                    ValidateAssetNo();
            end;
        }
        field(4; "Asset ID"; Guid)
        {
            Caption = 'Product Id';
            DataClassification = SystemMetadata;
            trigger OnValidate()
            begin
                if IsNullGuid("Asset ID") then
                    InitAsset()
                else begin
                    PriceAssetInterface := "Asset Type";
                    PriceAssetInterface.GetNo(Rec);
                end;
            end;
        }
        field(5; Level; Integer)
        {
            Caption = 'Level';
            DataClassification = SystemMetadata;
        }
        field(6; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            begin
                if "Variant Code" <> '' then begin
                    TestField("Asset Type", "Asset Type"::Item);
                    TestField("Asset No.");
                end;
                ValidateAssetNo();
            end;
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;

            trigger OnValidate()
            var
                ItemUnitofMeasure: Record "Item Unit of Measure";
                ResourceUnitofMeasure: Record "Resource Unit of Measure";
                UnitofMeasure: Record "Unit of Measure";
                IsHandled: Boolean;
            begin
                IsHandled := false;
                OnBeforeValidateUnitOfMeasureCode(Rec, IsHandled);
                if IsHandled then
                    exit;

                if "Unit of Measure Code" <> '' then
                    case "Asset Type" of
                        "Asset Type"::Item:
                            begin
                                TestField("Asset No.");
                                ItemUnitofMeasure.Get("Asset No.", "Unit of Measure Code");
                            end;
                        "Asset Type"::Resource:
                            begin
                                TestField("Asset No.");
                                ResourceUnitofMeasure.Get("Asset No.", "Unit of Measure Code");
                            end;
                        "Asset Type"::"Resource Group":
                            begin
                                TestField("Asset No.");
                                UnitofMeasure.Get("Unit of Measure Code");
                            end;
                        else
                            Error(AssetTypeForUOMErr);
                    end;
            end;
        }
        field(8; "Price Type"; Enum "Price Type")
        {
            Caption = 'Price Type';
            DataClassification = SystemMetadata;
        }
        field(9; "Table Id"; Integer)
        {
            Caption = 'Table Id';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(16; "Amount Type"; Enum "Price Amount Type")
        {
            Caption = 'Amount Type';
            DataClassification = SystemMetadata;
        }
        field(17; "Unit Price"; Decimal)
        {
            Caption = 'Unit Price';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(18; "Unit Price 2"; Decimal)
        {
            Caption = 'Unit Price 2';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(22; "Allow Invoice Disc."; Boolean)
        {
            Caption = 'Allow Invoice Disc.';
            DataClassification = SystemMetadata;
        }
        field(23; "Price Includes VAT"; Boolean)
        {
            Caption = 'Price Includes VAT';
            DataClassification = SystemMetadata;
        }
        field(24; "VAT Bus. Posting Gr. (Price)"; Code[20])
        {
            Caption = 'VAT Bus. Posting Gr. (Price)';
            DataClassification = SystemMetadata;
            TableRelation = "VAT Business Posting Group";
        }
        field(25; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            DataClassification = SystemMetadata;
            TableRelation = "Work Type";

            trigger OnValidate()
            var
                Resource: Record Resource;
                WorkType: Record "Work Type";
            begin
                if not ("Asset Type" in ["Asset Type"::Resource, "Asset Type"::"Resource Group"]) then
                    TestField("Asset Type", "Asset Type"::Resource);

                if WorkType.Get("Work Type Code") and (WorkType."Unit of Measure Code" <> '') then
                    "Unit of Measure Code" := WorkType."Unit of Measure Code"
                else
                    if ("Asset Type" = "Asset Type"::Resource) and ("Asset No." <> '') then begin
                        Resource.Get("Asset No.");
                        "Unit of Measure Code" := Resource."Base Unit of Measure";
                    end;
            end;
        }
        field(29; Description; Text[100])
        {
            Caption = 'Description';
            DataClassification = CustomerContent;
        }
    }

    keys
    {
        key(PK; "Entry No.")
        {
        }
    }

    var
        PriceAssetInterface: Interface "Price Asset";
        AssetTypeForUOMErr: Label 'Product Type must be equal to Item or Resource.';

    trigger OnInsert()
    begin
        "Entry No." := GetLastEntryNo() + 1;
    end;

    procedure NewEntry(AssetType: Enum "Price Asset Type"; NewLevel: Integer)
    begin
        Init();
        Level := NewLevel;
        Validate("Asset Type", AssetType);
    end;

    local procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure InitAsset()
    begin
        Clear("Asset ID");
        "Asset No." := '';
        Description := '';
        "Unit of Measure Code" := '';
        "Amount Type" := "Amount Type"::Any;

        OnAfterInitAsset(Rec);
    end;

    procedure IsAssetNoRequired(): Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        exit(PriceAssetInterface.IsAssetNoRequired());
    end;

    procedure LookupNo() Result: Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.IsLookupOK(Rec);
    end;

    procedure LookupVariantCode() Result: Boolean;
    begin
        TestField("Asset Type", "Asset Type"::Item);
        TestField("Asset No.");
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.IsLookupVariantOK(Rec);
    end;

    procedure LookupUnitofMeasure() Result: Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.IsLookupUnitOfMeasureOK(Rec);
    end;

    procedure FilterPriceLines(var PriceListLine: Record "Price List Line") Result: Boolean;
    begin
        PriceAssetInterface := "Asset Type";
        Result := PriceAssetInterface.FilterPriceLines(Rec, PriceListLine);
    end;

    procedure PutRelatedAssetsToList(var PriceAssetList: Codeunit "Price Asset List"): Integer;
    begin
        PriceAssetInterface := "Asset Type";
        PriceAssetInterface.PutRelatedAssetsToList(Rec, PriceAssetList);
        exit(PriceAssetList.Count());
    end;

    procedure FillFromBuffer(PriceCalculationBuffer: Record "Price Calculation Buffer")
    begin
        PriceAssetInterface := PriceCalculationBuffer."Asset Type";
        PriceAssetInterface.FillFromBuffer(Rec, PriceCalculationBuffer);
    end;

    procedure ValidateAssetNo()
    begin
        PriceAssetInterface := "Asset Type";
        PriceAssetInterface.GetId(Rec)
    end;

    // Could be a method in the Price Asset interface
    local procedure VerifyConsistentAssetType()
    begin
        if IsVerifyConsistentAssetTypeHandled() then
            exit;
        if "Price Type" = "Price Type"::Purchase then
            if "Asset Type" = "Asset Type"::"Item Discount Group" then
                FieldError("Asset Type");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitAsset(var PriceAsset: Record "Price Asset")
    begin
    end;

    local procedure IsVerifyConsistentAssetTypeHandled() IsHandled: Boolean;
    begin
        OnBeforeVerifyConsistentAssetType(Rec, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeValidateUnitOfMeasureCode(var PriceAsset: Record "Price Asset"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeVerifyConsistentAssetType(var PriceAsset: Record "Price Asset"; var IsHandled: Boolean)
    begin
    end;
}