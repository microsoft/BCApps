// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Pricing.Calculation;

using Microsoft.Finance.GeneralLedger.Account;
using Microsoft.Inventory.Item;
using Microsoft.Pricing.Asset;
using Microsoft.Pricing.PriceList;
using Microsoft.Pricing.Source;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;

table 7008 "Dtld. Price Calculation Setup"
{
    Caption = 'Detailed Price Calculation Setup';
    DrillDownPageID = "Dtld. Price Calculation Setup";
    LookupPageID = "Dtld. Price Calculation Setup";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer)
        {
            AutoIncrement = true;
        }
        field(2; "Setup Code"; Code[100])
        {
            TableRelation = "Price Calculation Setup".Code where(Enabled = const(true));

            trigger OnValidate()
            var
                PriceCalculationSetup: Record "Price Calculation Setup";
            begin
                PriceCalculationSetup.Get("Setup Code");
                Type := PriceCalculationSetup.Type;
                Method := PriceCalculationSetup.Method;
                Implementation := PriceCalculationSetup.Implementation;
                "Group Id" := PriceCalculationSetup."Group Id";
                Validate("Asset Type", PriceCalculationSetup."Asset Type");
                Enabled := true;
            end;
        }
        field(3; Method; Enum "Price Calculation Method")
        {
            Editable = false;
        }
        field(4; Type; Enum "Price Type")
        {
            Editable = false;
        }
        field(5; "Asset Type"; Enum "Price Asset Type")
        {
            Caption = 'Product Type';
            Editable = false;

            trigger OnValidate()
            begin
                if "Asset Type" <> xRec."Asset Type" then
                    SetAssetNo('');
            end;
        }
        field(6; "Asset No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                xRec.CopyTo(PriceAsset);
                PriceAsset.Validate("Asset No.", "Asset No.");
                CopyFrom(PriceAsset);
                "Product No." := "Asset No.";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceAsset);
                if PriceAsset.LookupNo() then
                    CopyFrom(PriceAsset);
            end;
        }
        field(7; "Source Group"; Enum "Price Source Group")
        {
            Caption = 'Assign-to Group';
            DataClassification = CustomerContent;

            trigger OnValidate()
            begin
                if "Source Group" <> xRec."Source Group" then begin
                    Validate("Source Type", "Source Group".AsInteger());
                    SetSourceNo('');
                end;
            end;
        }

        field(8; "Source Type"; Enum "Price Source Type")
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to Type';
            Editable = false;
            trigger OnValidate()
            begin
                VerifySourceType();
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source Type", "Source Type");
                CopyFrom(PriceSource);
            end;
        }
        field(9; "Source No."; Code[20])
        {
            DataClassification = CustomerContent;
            Caption = 'Assign-to No.';
            trigger OnValidate()
            begin
                xRec.CopyTo(PriceSource);
                PriceSource.Validate("Source No.", "Source No.");
                CopyFrom(PriceSource);
                "Assign-to No." := "Source No.";
            end;

            trigger OnLookup()
            begin
                CopyTo(PriceSource);
                PriceSource.LookupNo();
                CopyFrom(PriceSource);
            end;
        }
        field(10; Implementation; Enum "Price Calculation Handler")
        {
            Editable = false;
        }
        field(11; "Group Id"; Code[100])
        {
            DataClassification = SystemMetadata;
        }
        field(12; Enabled; Boolean)
        {
        }
        field(13; "Product No."; Code[20])
        {
            Caption = 'Product No.';
            DataClassification = CustomerContent;
            TableRelation = if ("Asset Type" = const(Item)) Item where("No." = field("Product No."))
            else
            if ("Asset Type" = const("G/L Account")) "G/L Account"
            else
            if ("Asset Type" = const(Resource)) Resource
            else
            if ("Asset Type" = const("Resource Group")) "Resource Group"
            else
            if ("Asset Type" = const("Item Discount Group")) "Item Discount Group";
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Asset No.", "Product No.");
            end;
        }
        field(14; "Assign-to No."; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = if ("Source Type" = const(Customer)) Customer
            else
            if ("Source Type" = const(Job)) Job
            else
            if ("Source Type" = const(Vendor)) Vendor;
            ValidateTableRelation = false;

            trigger OnValidate()
            begin
                Validate("Source No.", "Assign-to No.");
            end;
        }
    }
    keys
    {
        key(PK; "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Group Id", Enabled)
        {
        }
    }

    trigger OnInsert()
    begin
        Enabled := true;
    end;

    protected var
        PriceAsset: Record "Price Asset";
        PriceSource: Record "Price Source";

    var
        NotSupportedSourceTypeErr: label 'Not supported source type %1 for the source group %2.',
            Comment = '%1 - source type value, %2 - source group value';

    local procedure CopyFrom(PriceAsset: Record "Price Asset")
    begin
        "Asset Type" := PriceAsset."Asset Type";
        SetAssetNo(PriceAsset."Asset No.");
    end;

    local procedure CopyFrom(PriceSource: Record "Price Source")
    begin
        "Source Type" := PriceSource."Source Type";
        SetSourceNo(PriceSource."Source No.");
    end;

    procedure CopyTo(var PriceAsset: Record "Price Asset")
    begin
        PriceAsset."Asset Type" := "Asset Type";
        PriceAsset."Asset No." := "Asset No.";
    end;

    procedure CopyTo(var PriceSource: Record "Price Source")
    begin
        PriceSource."Source Type" := "Source Type";
        PriceSource."Source No." := "Source No.";
    end;

    local procedure SetAssetNo(AssetNo: Code[20])
    begin
        "Asset No." := AssetNo;
        "Product No." := AssetNo;
    end;

    local procedure SetSourceNo(SourceNo: Code[20])
    begin
        "Source No." := SourceNo;
        "Assign-to No." := SourceNo;
    end;

    local procedure VerifySourceType()
    var
        PriceSourceGroup: Interface "Price Source Group";
    begin
        PriceSourceGroup := "Source Group";
        if not PriceSourceGroup.IsSourceTypeSupported("Source Type") then
            Error(NotSupportedSourceTypeErr, "Source Type", "Source Group");
    end;
}

