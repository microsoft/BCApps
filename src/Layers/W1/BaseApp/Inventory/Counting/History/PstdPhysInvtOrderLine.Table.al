// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Counting.History;

using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Counting.Tracking;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

table 5880 "Pstd. Phys. Invt. Order Line"
{
    Caption = 'Pstd. Phys. Invt. Order Line';
    DrillDownPageID = "Posted Phys. Invt. Order Lines";
    LookupPageID = "Posted Phys. Invt. Order Lines";
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Document No."; Code[20])
        {
            Caption = 'Document No.';
            TableRelation = "Pstd. Phys. Invt. Order Hdr";
        }
        field(2; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(12; "On Recording Lines"; Boolean)
        {
            Caption = 'On Recording Lines';
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
        field(30; Description; Text[100])
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
        field(53; "Use Item Tracking"; Boolean)
        {
            Caption = 'Use Item Tracking';
        }
        field(54; "Qty. Exp. Tracking (Base)"; Decimal)
        {
            CalcFormula = sum("Pstd.Exp.Invt.Order.Tracking"."Quantity (Base)" where("Order No" = field("Document No."),
                                                                                      "Order Line No." = field("Line No.")));
            Caption = 'Qty. Exp. Item Tracking (Base)';
            DecimalPlaces = 0 : 5;
            Editable = false;
            FieldClass = FlowField;
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
        field(76; "Without Difference"; Boolean)
        {
            Caption = 'Without Difference';
            Editable = false;
        }
        field(80; "Recorded Without Order"; Boolean)
        {
            Caption = 'Recorded Without Order';
            Editable = false;
        }
        field(90; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';

            trigger OnLookup()
            begin
                DimManagement.LookupDimValueCode(1, "Shortcut Dimension 1 Code");
            end;
        }
        field(91; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';

            trigger OnLookup()
            begin
                DimManagement.LookupDimValueCode(2, "Shortcut Dimension 2 Code");
            end;
        }
        field(100; "Shelf No."; Code[10])
        {
            Caption = 'Shelf No.';
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
        field(130; "Intern Item Track. Pos. Qut."; Integer)
        {
            Caption = 'Intern Item Track. Pos. Qut.';
            Editable = false;
        }
        field(131; "Intern Item Track. Neg. Qut."; Integer)
        {
            Caption = 'Intern Item Track. Neg. Qut.';
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
        field(5704; "Item Category Code"; Code[20])
        {
            Caption = 'Item Category Code';
            TableRelation = "Item Category";
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
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Document No.", "Entry Type", "Without Difference")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking";
    begin
        PstdExpInvtOrderTracking.Reset();
        PstdExpInvtOrderTracking.SetRange("Order No", "Document No.");
        PstdExpInvtOrderTracking.SetRange("Order Line No.", "Line No.");
        PstdExpInvtOrderTracking.DeleteAll();
    end;

    var
        DimManagement: Codeunit DimensionManagement;

    procedure EmptyLine(): Boolean
    begin
        exit(
          ("Item No." = '') and
          ("Variant Code" = '') and
          ("Location Code" = '') and
          ("Bin Code" = ''));
    end;

    procedure ShowDimensions()
    begin
        DimManagement.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2 %3', TableCaption(), "Document No.", "Line No."));
    end;

    procedure ShowPostPhysInvtRecordingLines()
    var
        PstdPhysInvtRecordLine: Record "Pstd. Phys. Invt. Record Line";
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");

        PstdPhysInvtRecordLine.Reset();
        PstdPhysInvtRecordLine.SetCurrentKey("Order No.", "Order Line No.");
        PstdPhysInvtRecordLine.SetRange("Order No.", "Document No.");
        PstdPhysInvtRecordLine.SetRange("Order Line No.", "Line No.");
        PAGE.RunModal(0, PstdPhysInvtRecordLine);
    end;

    procedure ShowPostedItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");

        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(
          DATABASE::"Pstd. Phys. Invt. Order Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure ShowPostExpPhysInvtTrackLines()
    var
        PstdExpInvtOrderTracking: Record "Pstd.Exp.Invt.Order.Tracking";
    begin
        if EmptyLine() then
            exit;

        TestField("Item No.");

        PstdExpInvtOrderTracking.Reset();
        PstdExpInvtOrderTracking.Reset();
        PstdExpInvtOrderTracking.SetRange("Order No", "Document No.");
        PstdExpInvtOrderTracking.SetRange("Order Line No.", "Line No.");
        Page.RunModal(0, PstdExpInvtOrderTracking);
    end;
}

