// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Projects.Resources.Ledger;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.AuditCodes;
using Microsoft.Foundation.Enums;
using Microsoft.Foundation.NoSeries;
using Microsoft.Foundation.UOM;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using Microsoft.Utilities;
using System.Security.AccessControl;

table 203 "Res. Ledger Entry"
{
    Caption = 'Res. Ledger Entry';
    DrillDownPageID = "Resource Ledger Entries";
    LookupPageID = "Resource Ledger Entries";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer)
        {
            Caption = 'Entry No.';
        }
        field(2; "Entry Type"; Enum "Res. Journal Line Entry Type")
        {
            Caption = 'Entry Type';
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Posting Date"; Date)
        {
            Caption = 'Posting Date';
        }
        field(5; "Resource No."; Code[20])
        {
            Caption = 'Resource No.';
            TableRelation = Resource;
        }
        field(6; "Resource Group No."; Code[20])
        {
            Caption = 'Resource Group No.';
            TableRelation = "Resource Group";
        }
        field(7; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(8; "Work Type Code"; Code[10])
        {
            Caption = 'Work Type Code';
            TableRelation = "Work Type";
        }
        field(9; "Job No."; Code[20])
        {
            Caption = 'Project No.';
            TableRelation = Job;
        }
        field(10; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = "Unit of Measure";
        }
        field(11; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
        }
        field(12; "Direct Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Direct Unit Cost';
        }
        field(13; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Cost';
        }
        field(14; "Total Cost"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Cost';
        }
        field(15; "Unit Price"; Decimal)
        {
            AutoFormatType = 2;
            Caption = 'Unit Price';
        }
        field(16; "Total Price"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Total Price';
        }
        field(17; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            Caption = 'Global Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(18; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            Caption = 'Global Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(20; "User ID"; Code[50])
        {
            Caption = 'User ID';
            DataClassification = EndUserIdentifiableInformation;
            TableRelation = User."User Name";
        }
        field(21; "Source Code"; Code[10])
        {
            Caption = 'Source Code';
            TableRelation = "Source Code";
        }
        field(22; Chargeable; Boolean)
        {
            Caption = 'Chargeable';
            InitValue = true;
        }
        field(23; "Journal Batch Name"; Code[10])
        {
            Caption = 'Journal Batch Name';
        }
        field(24; "Reason Code"; Code[10])
        {
            Caption = 'Reason Code';
            TableRelation = "Reason Code";
        }
        field(25; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(26; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(27; "Document Date"; Date)
        {
            Caption = 'Document Date';
        }
        field(28; "External Document No."; Code[35])
        {
            Caption = 'External Document No.';
        }
        field(29; "No. Series"; Code[20])
        {
            Caption = 'No. Series';
            TableRelation = "No. Series";
        }
        field(30; "Source Type"; Enum "Res. Journal Line Source Type")
        {
            Caption = 'Source Type';
        }
        field(31; "Source No."; Code[20])
        {
            Caption = 'Source No.';
            TableRelation = if ("Source Type" = const(Customer)) Customer."No."
            else
            if ("Source Type" = const(Vendor)) Vendor."No.";
        }
        field(32; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
        }
        field(33; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
        }
        field(34; "Resource Register No."; Integer)
        {
            Caption = 'Resource Register No.';
            Editable = false;
            TableRelation = "Resource Register";
        }
        field(90; "Order Type"; Enum "Inventory Order Type")
        {
            Caption = 'Order Type';
        }
        field(91; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(92; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(480; "Dimension Set ID"; Integer)
        {
            Caption = 'Dimension Set ID';
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
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(3)));
        }
        field(482; "Shortcut Dimension 4 Code"; Code[20])
        {
            CaptionClass = '1,2,4';
            Caption = 'Shortcut Dimension 4 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(4)));
        }
        field(483; "Shortcut Dimension 5 Code"; Code[20])
        {
            CaptionClass = '1,2,5';
            Caption = 'Shortcut Dimension 5 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(5)));
        }
        field(484; "Shortcut Dimension 6 Code"; Code[20])
        {
            CaptionClass = '1,2,6';
            Caption = 'Shortcut Dimension 6 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(6)));
        }
        field(485; "Shortcut Dimension 7 Code"; Code[20])
        {
            CaptionClass = '1,2,7';
            Caption = 'Shortcut Dimension 7 Code';
            Editable = false;
            FieldClass = FlowField;
            CalcFormula = lookup("Dimension Set Entry"."Dimension Value Code" where("Dimension Set ID" = field("Dimension Set ID"),
                                                                                    "Global Dimension No." = const(7)));
        }
        field(486; "Shortcut Dimension 8 Code"; Code[20])
        {
            CaptionClass = '1,2,8';
            Caption = 'Shortcut Dimension 8 Code';
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
        key(Key2; "Resource No.", "Posting Date")
        {
        }
        key(Key3; "Entry Type", Chargeable, "Unit of Measure Code", "Resource No.", "Posting Date")
        {
            IncludedFields = Quantity, "Total Cost", "Total Price", "Quantity (Base)";
        }
        key(Key4; "Entry Type", Chargeable, "Unit of Measure Code", "Resource Group No.", "Posting Date")
        {
            IncludedFields = Quantity, "Total Cost", "Total Price", "Quantity (Base)";
        }
        key(Key5; "Document No.", "Posting Date")
        {
        }
        key(Key6; "Order Type", "Order No.", "Order Line No.", "Entry Type")
        {
            IncludedFields = Quantity;
        }
        key(Key7; "Source No.", "Source Type", "Entry Type", "Posting Date")
        {
            IncludedFields = "Total Cost";
        }
        key(Key8; "Job No.")
        {
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Entry No.", Description, "Entry Type", "Document No.", "Posting Date")
        {
        }
    }

    var
        DimMgt: Codeunit DimensionManagement;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Res. Ledger Entry", 'r')]
    procedure GetNextEntryNo(): Integer
    var
        SequenceNoMgt: Codeunit "Sequence No. Mgt.";
    begin
        exit(SequenceNoMgt.GetNextSeqNo(DATABASE::"Res. Ledger Entry"));
    end;

    [InherentPermissions(PermissionObjectType::TableData, Database::"Res. Ledger Entry", 'r')]
    procedure GetLastEntryNo(): Integer;
    var
        FindRecordManagement: Codeunit "Find Record Management";
    begin
        exit(FindRecordManagement.GetLastEntryIntFieldValue(Rec, FieldNo("Entry No.")))
    end;

    procedure CopyFromResJnlLine(ResJnlLine: Record "Res. Journal Line")
    begin
        "Entry Type" := ResJnlLine."Entry Type";
        "Document No." := ResJnlLine."Document No.";
        "External Document No." := ResJnlLine."External Document No.";
        "Order Type" := ResJnlLine."Order Type";
        "Order No." := ResJnlLine."Order No.";
        "Order Line No." := ResJnlLine."Order Line No.";
        "Posting Date" := ResJnlLine."Posting Date";
        "Document Date" := ResJnlLine."Document Date";
        "Resource No." := ResJnlLine."Resource No.";
        "Resource Group No." := ResJnlLine."Resource Group No.";
        Description := ResJnlLine.Description;
        "Work Type Code" := ResJnlLine."Work Type Code";
        "Job No." := ResJnlLine."Job No.";
        "Unit of Measure Code" := ResJnlLine."Unit of Measure Code";
        Quantity := ResJnlLine.Quantity;
        "Direct Unit Cost" := ResJnlLine."Direct Unit Cost";
        "Unit Cost" := ResJnlLine."Unit Cost";
        "Total Cost" := ResJnlLine."Total Cost";
        "Unit Price" := ResJnlLine."Unit Price";
        "Total Price" := ResJnlLine."Total Price";
        "Global Dimension 1 Code" := ResJnlLine."Shortcut Dimension 1 Code";
        "Global Dimension 2 Code" := ResJnlLine."Shortcut Dimension 2 Code";
        "Dimension Set ID" := ResJnlLine."Dimension Set ID";
        "Source Code" := ResJnlLine."Source Code";
        "Journal Batch Name" := ResJnlLine."Journal Batch Name";
        "Reason Code" := ResJnlLine."Reason Code";
        "Gen. Bus. Posting Group" := ResJnlLine."Gen. Bus. Posting Group";
        "Gen. Prod. Posting Group" := ResJnlLine."Gen. Prod. Posting Group";
        "No. Series" := ResJnlLine."Posting No. Series";
        "Source Type" := ResJnlLine."Source Type";
        "Source No." := ResJnlLine."Source No.";
        "Qty. per Unit of Measure" := ResJnlLine."Qty. per Unit of Measure";

        OnAfterCopyFromResJnlLine(Rec, ResJnlLine);
    end;

    procedure ShowDimensions()
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", CopyStr(StrSubstNo('%1 %2', TableCaption(), "Entry No."), 1, 250));
    end;

    [IntegrationEvent(false, false)]
    procedure OnAfterCopyFromResJnlLine(var ResLedgerEntry: Record "Res. Ledger Entry"; ResJournalLine: Record "Res. Journal Line")
    begin
    end;
}

