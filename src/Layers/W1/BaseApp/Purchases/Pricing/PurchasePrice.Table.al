// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Purchases.Vendor;

table 7012 "Purchase Price"
{
    Caption = 'Purchase Price';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            NotBlank = true;
            TableRelation = Item;

            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Unit of Measure Code" := '';
                    "Variant Code" := '';
                end;
            end;
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            begin
                if Vend.Get("Vendor No.") then
                    "Currency Code" := Vend."Currency Code";
            end;
        }
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';

            trigger OnValidate()
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(Text000, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
            end;
        }
        field(5; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';

            trigger OnValidate()
            begin
                Validate("Starting Date");
            end;
        }
        field(5400; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(5700; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
    }

    keys
    {
        key(Key1; "Item No.", "Vendor No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
            Clustered = true;
        }
        key(Key2; "Vendor No.", "Item No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Item No.", "Vendor No.", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
    }

    trigger OnInsert()
    begin
        TestField("Vendor No.");
        TestField("Item No.");
    end;

    trigger OnRename()
    begin
        TestField("Vendor No.");
        TestField("Item No.");
    end;

    var
        Vend: Record Vendor;
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label '%1 cannot be after %2';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CopyPurchPriceToVendorsPurchPrice(var PurchPrice: Record "Purchase Price"; VendNo: Code[20])
    var
        NewPurchasePrice: Record "Purchase Price";
    begin
        if PurchPrice.FindSet() then
            repeat
                NewPurchasePrice := PurchPrice;
                NewPurchasePrice."Vendor No." := VendNo;
                OnBeforeNewPurchasePriceInsert(NewPurchasePrice, PurchPrice);
                if NewPurchasePrice.Insert() then;
            until PurchPrice.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewPurchasePriceInsert(var NewPurchasePrice: Record "Purchase Price"; PurchasePrice: Record "Purchase Price")
    begin
    end;
}
