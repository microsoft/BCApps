// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Pricing;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;

table 1315 "Purch. Price Line Disc. Buff."
{
    Caption = 'Purch. Price Line Disc. Buff.';
    DataClassification = CustomerContent;

    fields
    {
        field(3; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            DataClassification = SystemMetadata;
            TableRelation = Currency;
        }
        field(4; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            DataClassification = SystemMetadata;
        }
        field(5; "Line Discount %"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Line Discount %';
            DataClassification = SystemMetadata;
            MaxValue = 100;
            MinValue = 0;
        }
        field(6; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(14; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DataClassification = SystemMetadata;
            MinValue = 0;
        }
        field(15; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            DataClassification = SystemMetadata;
        }
        field(1300; "Line Type"; Option)
        {
            Caption = 'Line Type';
            DataClassification = SystemMetadata;
            OptionCaption = ' ,Purchase Line Discount,Purchase Price';
            OptionMembers = " ","Purchase Line Discount","Purchase Price";
        }
        field(1301; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(1303; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            DataClassification = SystemMetadata;
            Editable = false;
        }
        field(5400; "Unit of Measure Code"; Code[20])
        {
            Caption = 'Unit of Measure Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Unit of Measure";
        }
        field(5700; "Variant Code"; Code[20])
        {
            Caption = 'Variant Code';
            DataClassification = SystemMetadata;
            TableRelation = "Item Variant";
        }
    }

    keys
    {
        key(Key1; "Line Type", "Starting Date", "Currency Code", "Variant Code", "Unit of Measure Code", "Minimum Quantity", "Item No.", "Vendor No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    procedure LoadDataForItem(Item: Record Item)
    var
        PurchasePrice: Record "Purchase Price";
        PurchaseLineDiscount: Record "Purchase Line Discount";
    begin
        Reset();
        DeleteAll();

        "Item No." := Item."No.";

        PurchasePrice.SetRange("Item No.", "Item No.");
        LoadPurchasePrice(PurchasePrice);

        PurchaseLineDiscount.SetRange("Item No.", "Item No.");
        LoadPurchaseLineDiscount(PurchaseLineDiscount);

        if FindFirst() then;
    end;

    local procedure LoadPurchaseLineDiscount(var PurchaseLineDiscount: Record "Purchase Line Discount")
    begin
        if PurchaseLineDiscount.FindSet() then
            repeat
                Init();
                "Line Type" := "Line Type"::"Purchase Line Discount";

                "Starting Date" := PurchaseLineDiscount."Starting Date";
                "Minimum Quantity" := PurchaseLineDiscount."Minimum Quantity";
                "Unit of Measure Code" := PurchaseLineDiscount."Unit of Measure Code";

                "Line Discount %" := PurchaseLineDiscount."Line Discount %";
                "Currency Code" := PurchaseLineDiscount."Currency Code";
                "Ending Date" := PurchaseLineDiscount."Ending Date";
                "Variant Code" := PurchaseLineDiscount."Variant Code";
                "Vendor No." := PurchaseLineDiscount."Vendor No.";
                Insert();
            until PurchaseLineDiscount.Next() = 0;
    end;

    local procedure LoadPurchasePrice(var PurchasePrice: Record "Purchase Price")
    begin
        if PurchasePrice.FindSet() then
            repeat
                Init();
                "Line Type" := "Line Type"::"Purchase Price";

                "Starting Date" := PurchasePrice."Starting Date";
                "Minimum Quantity" := PurchasePrice."Minimum Quantity";
                "Unit of Measure Code" := PurchasePrice."Unit of Measure Code";
                "Direct Unit Cost" := PurchasePrice."Direct Unit Cost";
                "Currency Code" := PurchasePrice."Currency Code";
                "Ending Date" := PurchasePrice."Ending Date";
                "Variant Code" := PurchasePrice."Variant Code";
                "Vendor No." := PurchasePrice."Vendor No.";

                Insert();
            until PurchasePrice.Next() = 0;
    end;

    procedure ItemHasLines(Item: Record Item): Boolean
    var
        PurchaseLineDiscount: Record "Purchase Line Discount";
        PurchasePrice: Record "Purchase Price";
    begin
        Reset();

        "Item No." := Item."No.";

        PurchasePrice.SetRange("Item No.", "Item No.");
        if not PurchasePrice.IsEmpty() then
            exit(true);

        PurchaseLineDiscount.SetRange("Item No.", "Item No.");
        if not PurchaseLineDiscount.IsEmpty() then
            exit(true);

        exit(false);
    end;
}
