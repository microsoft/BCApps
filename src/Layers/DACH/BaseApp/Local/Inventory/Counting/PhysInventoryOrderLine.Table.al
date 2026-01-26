#if not CLEANSCHEMA27 
// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Structure;

table 5005351 "Phys. Inventory Order Line"
{
    Caption = 'Phys. Inventory Order Line';
    ObsoleteReason = 'Merged to W1';
    ObsoleteState = Removed;
    ObsoleteTag = '27.0';
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(12; "In Recording Lines"; Boolean)
        {
            Caption = 'In Recording Lines';
            Editable = false;
        }
        field(20; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            TableRelation = Item;
        }
        field(21; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(22; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location;
        }
        field(23; "Bin Code"; Code[20])
        {
            Caption = 'Bin Code';
            TableRelation = Bin.Code where("Location Code" = field("Location Code"));
        }
        field(30; Description; Text[50])
        {
            Caption = 'Description';
        }
        field(31; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(32; "Unit of Measure"; Text[50])
        {
            Caption = 'Unit of Measure';
        }
        field(40; "Base Unit of Measure Code"; Code[10])
        {
            Caption = 'Base Unit of Measure Code';
            Editable = false;
            TableRelation = "Unit of Measure";
        }
        field(50; "Qty. Expected (Base)"; Decimal)
        {
            Caption = 'Qty. Expected (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(51; "Qty. Exp. Calculated"; Boolean)
        {
            Caption = 'Qty. Exp. Calculated';
            Editable = false;
        }
#if not CLEANSCHEMA27
        field(52; "Qty. Exp. Track. Lines (Base)"; Decimal)
        {
            CalcFormula = sum("Expect. Phys. Inv. Track. Line"."Quantity (Base)" where("Order No" = field("Document No."),
                                                                                        "Order Line No." = field("Line No.")));
            Caption = 'Qty. Exp. Track. Lines (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
            ObsoleteReason = 'Merged to W1';
            ObsoleteState = Removed;
            ObsoleteTag = '27.0';
        }
#endif
        field(53; "Use Tracking Lines"; Boolean)
        {
            Caption = 'Use Tracking Lines';
            FieldClass = Normal;
        }
        field(55; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            Editable = false;
            TableRelation = "Item Ledger Entry";
        }
        field(60; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Amount';
        }
        field(62; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(70; "No. Finished Rec.-Lines"; Integer)
        {
            Caption = 'No. Finished Rec.-Lines';
            Editable = false;
        }
        field(71; "Qty. Recorded (Base)"; Decimal)
        {
            Caption = 'Qty. Recorded (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(72; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(73; "Entry Type"; Option)
        {
            Caption = 'Entry Type';
            Editable = false;
            OptionCaption = ' ,Positive Adjmt.,Negative Adjmt.';
            OptionMembers = " ","Positive Adjmt.","Negative Adjmt.";
        }
        field(74; "Pos. Qty. (Base)"; Decimal)
        {
            Caption = 'Pos. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(75; "Neg. Qty. (Base)"; Decimal)
        {
            Caption = 'Neg. Qty. (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
        }
        field(76; "Without difference"; Boolean)
        {
            Caption = 'Without difference';
            Editable = false;
        }
        field(80; "Recorded without Order"; Boolean)
        {
            Caption = 'Recorded without Order';
            Editable = false;
        }
        field(90; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(91; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(100; "Shelf/Bin No."; Code[10])
        {
            Caption = 'Shelf/Bin No.';
        }
        field(110; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(111; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(112; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            Editable = false;
            TableRelation = "Dimension Set Entry";
        }
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
        }
#if not CLEANSCHEMA25
        field(5707; "Product Group Code"; Code[10])
        {
            Caption = 'Product Group Code';
            ObsoleteReason = 'Product Groups became first level children of Item Categories.';
            ObsoleteState = Removed;
            ObsoleteTag = '25.0';
        }
#endif
        field(7380; "Phys Invt Counting Period Code"; Code[10])
        {
            Caption = 'Phys Invt Counting Period Code';
            Editable = false;
            TableRelation = "Phys. Invt. Counting Period";
        }
        field(7381; "Phys Invt Counting Period Type"; Option)
        {
            Caption = 'Phys Invt Counting Period Type';
            Editable = false;
            OptionCaption = ' ,Item,SKU';
            OptionMembers = " ",Item,SKU;
        }
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Item No.", "Variant Code", "Location Code", "Bin Code")
        {
        }
        key(Key3; "Document No.", "Entry Type", "Without difference")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Document No.", "Line No.", Description)
        {
        }
    }
}

 
#endif