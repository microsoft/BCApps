// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

table 99001500 "Subcontractor Price"
{
    AllowInCustomizations = AsReadOnly;
    Caption = 'Subcontractor Price';
    DataClassification = CustomerContent;
    DrillDownPageId = "Subcontractor Prices";
    LookupPageId = "Subcontractor Prices";

    fields
    {
        field(1; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            NotBlank = true;
            TableRelation = Vendor;

            trigger OnValidate()
            var
                Vendor: Record Vendor;
            begin
                if Vendor.Get("Vendor No.") then
                    "Currency Code" := Vendor."Currency Code";
            end;
        }
        field(2; "Item No."; Code[20])
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
        field(3; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            NotBlank = true;
            TableRelation = "Work Center"."No." where("Subcontractor No." = filter(<> ''));
        }
        field(4; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";
        }
        field(6; "Starting Date"; Date)
        {
            Caption = 'Starting Date';
            trigger OnValidate()
            var
                InvalidStartingDateErr: Label '%1 cannot be after %2', Comment = '%1=Field Caption for starting date, %2=Field Caption for ending date';
            begin
                if ("Starting Date" > "Ending Date") and ("Ending Date" <> 0D) then
                    Error(InvalidStartingDateErr, FieldCaption("Starting Date"), FieldCaption("Ending Date"));
            end;
        }
        field(7; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(8; "Minimum Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
        field(9; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(10; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;
        }
        field(20; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            MinValue = 0;
        }
        field(30; "Ending Date"; Date)
        {
            Caption = 'Ending Date';
            trigger OnValidate()
            begin
                Validate("Starting Date");
            end;
        }
    }
    keys
    {
        key(PK; "Vendor No.", "Item No.", "Work Center No.", "Variant Code", "Standard Task Code", "Starting Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code")
        {
            Clustered = true;
        }
        key(Key01; "Vendor No.", "Item No.", "Starting Date", "Currency Code", "Unit of Measure Code", "Minimum Quantity")
        {
        }
        key(Key02; "Vendor No.", "Item No.", "Work Center No.", "Variant Code", "Unit of Measure Code", "Currency Code")
        {
        }
    }
    fieldgroups
    {
        fieldgroup(Brick; "Work Center No.", "Vendor No.", "Item No.", "Starting Date", "Direct Unit Cost", "Ending Date")
        {
        }
        fieldgroup(DropDown; "Work Center No.", "Vendor No.", "Item No.", "Starting Date", "Direct Unit Cost", "Ending Date")
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

    procedure CopySubcontractorPriceToVendorsSubcontractorPrice(var SubcontractorPrice: Record "Subcontractor Price"; VendNo: Code[20]; WorkCenterNo: Code[20])
    var
        NewSubcontractorPrice: Record "Subcontractor Price";
    begin
        if SubcontractorPrice.FindSet() then
            repeat
                NewSubcontractorPrice := SubcontractorPrice;
                NewSubcontractorPrice."Vendor No." := VendNo;
                NewSubcontractorPrice."Work Center No." := WorkCenterNo;
                if NewSubcontractorPrice.Insert() then;
            until SubcontractorPrice.Next() = 0;
    end;

}