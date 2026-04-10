// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.Journal;

using Microsoft.CRM.Team;
using Microsoft.Finance.Dimension;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 281 "Phys. Inventory Ledger Entry"
{
    Caption = 'Phys. Inventory Ledger Entry';
    DrillDownPageID = "Phys. Inventory Ledger Entries";
    LookupPageID = "Phys. Inventory Ledger Entries";
    Permissions = TableData "Phys. Inventory Ledger Entry" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the number of the item in the ledger entry.';
            TableRelation = Item;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the date on which you posted the Physical Inventory Journal that created this ledger entry.';
        }
        field(4; "Entry Type"; Enum "Item Ledger Entry Type")
        {
            Caption = 'Entry Type';
            ToolTip = 'Specifies the type of transaction that was posted from the Physical Inventory Journal that created the ledger entry.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number on the physical inventory ledger entry.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the item in the ledger entry.';
        }
        field(8; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            ToolTip = 'Specifies the code of the location for the item in the ledger entry.';
            TableRelation = Location;
        }
        field(9; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(12; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the difference between the quantities in the Quantity (Calculated) field and the Quantity (Physical Inventory) field for ledger entry.';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Unit Amount"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Amount';
            ToolTip = 'Specifies the amount for one unit of the item in the ledger entry.';
        }
        field(16; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
            ToolTip = 'Specifies the cost of one unit of the item or resource on the line.';
        }
        field(17; Amount; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Amount';
            ToolTip = 'Specifies the total amount for the items in the ledger entry.';
        }
        field(20; "Item Register No."; Integer)
        {
            Caption = 'Item Register No.';
            Editable = false;
            TableRelation = "Item Register";
        }
        field(21; "SIFT Bucket No."; Integer)
        {
            Caption = 'SIFT Bucket No.';
            ToolTip = 'Specifies an automatically generated number that is used by the system to enable better concurrency.';
            Editable = false;
        }
        field(22; "Salespers./Purch. Code"; Code[20])
        {
            Caption = 'Salespers./Purch. Code';
            TableRelation = "Salesperson/Purchaser";
        }
        field(24; "User ID"; Code[50])
        {
            Caption = 'User ID';
            ToolTip = 'Specifies the ID of the user who posted the entry, to be used, for example, in the change log.';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(25; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            ToolTip = 'Specifies the source code that specifies where the entry was created.';
            TableRelation = "Source Code";
        }
        field(33; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(34; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            ToolTip = 'Specifies the code for the global dimension that is linked to the record or entry for analysis purposes. Two global dimensions, typically for the company''s most important activities, are available on all cards, documents, reports, and lists.';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(45; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(46; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            ToolTip = 'Specifies the reason code, a supplementary source code that enables you to trace the entry.';
            TableRelation = "Reason Code";
        }
        field(54; "Qty. (Calculated)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Calculated)';
            DecimalPlaces = 0 : 5;
        }
        field(55; "Qty. (Phys. Inventory)"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. (Phys. Inventory)';
            DecimalPlaces = 0 : 5;
        }
        field(56; "Last Item Ledger Entry No."; Integer)
        {
            Caption = 'Last Item Ledger Entry No.';
            ToolTip = 'Specifies the number of the last item ledger entry that provided the basis for the physical inventory ledger entry.';
            TableRelation = "Item Ledger Entry";
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(64; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
            ToolTip = 'Specifies a reference to a combination of dimension values. The actual values are stored in the Dimension Set Entry table.';
            Editable = false;
            TableRelation = "Dimension Set Entry";

            trigger OnLookup()
            begin
                Rec.ShowDimensions();
            end;
        }
        field(481; "Shortcut Dimension 3 Code"; Code[20])
        {
            CaptionClass = '1,2,3';
            Caption = 'Shortcut Dimension 3 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 3, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 4, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 5, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 6, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 7, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
            ToolTip = 'Specifies the code for Shortcut Dimension 8, which is one of dimension codes that you set up in the General Ledger Setup window.';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(8)));
        }
        field(5402; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(5407; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
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
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Item No.", "Variant Code", "Location Code", "Posting Date", "SIFT Bucket No.")
        {
            SumIndexFields = Quantity;
        }
        key(Key3; "Item No.", "Variant Code", "Global Dimension 1 Code", "Global Dimension 2 Code", "Location Code", "Posting Date", "SIFT Bucket No.")
        {
            SumIndexFields = Quantity;
        }
        key(Key4; "Document No.", "Posting Date")
        {
        }
        key(Key5; "Item No.", "Phys Invt Counting Period Type", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", "Item No.", "Posting Date", "Entry Type", "Document No.")
        {
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;

    trigger OnInsert()
    begin
        Rec."SIFT Bucket No." := Rec."Item Register No." mod 5;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Phys. Inventory Ledger Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Phys. Inventory Ledger Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Phys. Inventory Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;
}

