#if not CLEANSCHEMA30
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Finance.Currency;
using Microsoft.Inventory.Item;
using Microsoft.Manufacturing.Routing;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Purchases.Vendor;

table 12152 "Subcontractor Prices"
{
    Caption = 'Subcontractor Prices';
#if not CLEAN27
    LookupPageID = "Subcontracting Prices";
#endif
    DataClassification = CustomerContent;
    ObsoleteReason = 'Preparation for replacement by Subcontracting app';
#if not CLEAN27
    ObsoleteState = Pending;
    ObsoleteTag = '27.0';
#else
    ObsoleteState = Removed;
    ObsoleteTag = '30.0';
#endif

    fields
    {
        field(1; "Work Center No."; Code[20])
        {
            Caption = 'Work Center No.';
            TableRelation = "Work Center"."No." where("Subcontractor No." = filter(<> ''));
        }
        field(2; "Vendor No."; Code[20])
        {
            Caption = 'Vendor No.';
            TableRelation = Vendor;
            ValidateTableRelation = true;
#if not CLEAN27
            trigger OnValidate()
            begin
                if Vendor.Get("Vendor No.") then
                    "Currency Code" := Vendor."Currency Code";
            end;
#endif
        }
        field(3; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
#if not CLEAN27
            trigger OnValidate()
            begin
                if "Item No." <> xRec."Item No." then begin
                    "Unit of Measure Code" := '';
                    "Variant Code" := '';
                end;
            end;
#endif
        }
        field(4; "Currency Code"; Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(5; "Standard Task Code"; Code[10])
        {
            Caption = 'Standard Task Code';
            TableRelation = "Standard Task";
        }
        field(6; "Start Date"; Date)
        {
            Caption = 'Start Date';
#if not CLEAN27
            trigger OnValidate()
            begin
                if ("Start Date" > "End Date") and ("End Date" <> 0D) then
                    Error(InvalidStartDateErr);
            end;
#endif
        }
        field(7; "End Date"; Date)
        {
            Caption = 'End Date';
#if not CLEAN27
            trigger OnValidate()
            begin
                Validate("Start Date");
            end;
#endif
        }
        field(8; "Direct Unit Cost"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
            MinValue = 0;
        }
        field(9; "Minimum Amount"; Decimal)
        {
            AutoFormatExpression = Rec."Currency Code";
            AutoFormatType = 1;
            Caption = 'Minimum Amount';
            MinValue = 0;
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(11; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(12; "Minimum Quantity"; Decimal)
        {
            Caption = 'Minimum Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
        }
    }

    keys
    {
        key(Key1; "Vendor No.", "Item No.", "Standard Task Code", "Work Center No.", "Variant Code", "Start Date", "Unit of Measure Code", "Minimum Quantity", "Currency Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
#if not CLEAN27
    var
        Vendor: Record Vendor;
        InvalidStartDateErr: Label 'The Start Date cannot be after the End Date.';
#endif
}
#endif
