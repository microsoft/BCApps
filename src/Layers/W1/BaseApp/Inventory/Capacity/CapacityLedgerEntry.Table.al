// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Capacity;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Utilities;

table 5832 "Capacity Ledger Entry"
{
    Caption = 'Capacity Ledger Entry';
    DrillDownPageID = "Capacity Ledger Entries";
    LookupPageID = "Capacity Ledger Entries";
    Permissions = TableData "Capacity Ledger Entry" = ri;
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
            ToolTip = 'Specifies the number of the entry, as assigned from the specified number series when the entry was created.';
        }
        field(2; "No."; Code[20])
        {
            Caption = 'No.';
            ToolTip = 'Specifies the number of the involved entry or record, according to the specified number series.';
            TableRelation = if (Type = const(Resource)) Resource;
        }
        field(3; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
            ToolTip = 'Specifies the posting date of the entry.';
        }
        field(4; Type; Enum "Capacity Type Journal")
        {
            Caption = 'Type';
            ToolTip = 'Specifies the type of capacity entry.';
        }
        field(6; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            ToolTip = 'Specifies the document number of the entry.';
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
            ToolTip = 'Specifies a description of the entry.';
        }
        field(10; Quantity; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Quantity';
            ToolTip = 'Specifies the quantity of this entry, in base units of measure.';
            DecimalPlaces = 0 : 5;
        }
        field(15; "Invoiced Quantity"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Invoiced Quantity';
            DecimalPlaces = 0 : 5;
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
        field(28; "Cap. Unit of Measure Code"; Code[10])
        {
            Caption = 'Cap. Unit of Measure Code';
            ToolTip = 'Specifies the unit of measure code for the capacity usage.';
            TableRelation = "Capacity Unit of Measure";
        }
        field(29; "Qty. per Cap. Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Cap. Unit of Measure';
            DecimalPlaces = 0 : 5;
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
        field(42; "Completely Invoiced"; Boolean)
        {
            Caption = 'Completely Invoiced';
            ToolTip = 'Specifies if the entry has been fully invoiced or if more posted invoices are expected.';
        }
        field(56; "Item No."; Code[20])
        {
            Caption = 'Item No.';
            ToolTip = 'Specifies the item number.';
            TableRelation = Item;
        }
        field(57; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            ToolTip = 'Specifies the variant of the item on the line.';
            TableRelation = "Item Variant".Code where("Item No." = field("Item No."));
        }
        field(58; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Item Unit of Measure".Code where("Item No." = field("Item No."));
        }
        field(59; "Qty. per Unit of Measure"; Decimal)
        {
            AutoFormatType = 0;
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
        }
        field(60; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(61; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(71; "Direct Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                          "Entry Type" = const("Direct Cost")));
            Caption = 'Direct Cost';
            ToolTip = 'Specifies the direct cost in LCY of the quantity posting.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(72; "Overhead Cost"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            CalcFormula = sum("Value Entry"."Cost Amount (Actual)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                          "Entry Type" = const("Indirect Cost")));
            Caption = 'Overhead Cost';
            ToolTip = 'Specifies the overhead cost in LCY of the quantity posting.';
            Editable = false;
            FieldClass = FlowField;
        }
        field(76; "Direct Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual) (ACY)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                                "Entry Type" = const("Direct Cost")));
            Caption = 'Direct Cost (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(77; "Overhead Cost (ACY)"; Decimal)
        {
            AutoFormatExpression = GetAdditionalReportingCurrencyCode();
            AutoFormatType = 1;
            CalcFormula = sum("Value Entry"."Cost Amount (Actual) (ACY)" where("Capacity Ledger Entry No." = field("Entry No."),
                                                                                "Entry Type" = const("Indirect Cost")));
            Caption = 'Overhead Cost (ACY)';
            Editable = false;
            FieldClass = FlowField;
        }
        field(78; Subcontracting; Boolean)
        {
            Caption = 'Subcontracting';
        }
        field(87; Reversed; Boolean)
        {
            Caption = 'Reversed';
            ToolTip = 'Specifies if the entry has been part of a reverse transaction.';
            DataClassification = CustomerContent;
        }
        field(88; "Reversed by Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed by Entry No.';
            ToolTip = 'Specifies the number of the correcting entry that replaced the original entry in the reverse transaction.';
            DataClassification = CustomerContent;
            TableRelation = "Capacity Ledger Entry";
        }
        field(89; "Reversed Entry No."; Integer)
        {
            BlankZero = true;
            Caption = 'Reversed Entry No.';
            ToolTip = 'Specifies the number of the original entry that was undone by the reverse transaction.';
            DataClassification = CustomerContent;
            TableRelation = "Capacity Ledger Entry";
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
            ToolTip = 'Specifies which type of order the entry was created in.';
            Editable = false;
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
            ToolTip = 'Specifies the number of the order that created the entry.';
            Editable = false;
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
            ToolTip = 'Specifies the line number of the order that created the entry.';
            Editable = false;
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
    }

    keys
    {
        key(Key1; "Entry No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Posting Date")
        {
        }
        key(Key3; "Order Type", "Order No.", "Order Line No.")
        {
        }
        key(Key5; Type, "No.", "Item No.", "Posting Date")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, Type, "No.", "Posting Date", "Document No.")
        {
        }
    }

    var
        GLSetup: Record "General Ledger Setup";
        GLSetupRead: Boolean;

    trigger OnInsert()
    begin
        Rec."SIFT Bucket No." := Rec."Item Register No." mod 5;
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Capacity Ledger Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Capacity Ledger Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Capacity Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    local procedure GetAdditionalReportingCurrencyCode(): Code[10]
    begin
        if not GLSetupRead then begin
            GLSetup.Get();
            GLSetupRead := true;
        end;
        exit(GLSetup."Additional Reporting Currency");
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Entry No."));
    end;
}
