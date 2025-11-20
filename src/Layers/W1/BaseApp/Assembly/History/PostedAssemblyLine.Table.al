// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Assembly.History;

using Microsoft.Assembly.Comment;
using Microsoft.Finance.Dimension;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Inventory.BOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Resource;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Request;

table 911 "Posted Assembly Line"
{
    Caption = 'Posted Assembly Line';
    DrillDownPageID = "Posted Assembly Order Subform";
    LookupPageID = "Posted Assembly Order Subform";
    DataClassification = CustomerContent;

    fields
    {
        field(2; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(3; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(8; "Order No."; Code[20])
        {
            Caption = 'Order No.';
        }
        field(9; "Order Line No."; Integer)
        {
            Caption = 'Order Line No.';
        }
        field(10; Type; Enum "BOM Component Type")
        {
            Caption = 'Type';
        }
        field(11; "No."; Code[20])
        {
            Caption = 'No.';
            TableRelation = if (Type = const(Item)) Item
            else
            if (Type = const(Resource)) Resource;
        }
        field(12; "Variant Code"; Code[10])
        {
            Caption = 'Variant Code';
            TableRelation = if (Type = const(Item)) "Item Variant".Code where("Item No." = field("No."),
                                                                               Code = field("Variant Code"));
        }
        field(13; Description; Text[100])
        {
            Caption = 'Description';
        }
        field(14; "Description 2"; Text[50])
        {
            Caption = 'Description 2';
        }
        field(18; "Lead-Time Offset"; DateFormula)
        {
            Caption = 'Lead-Time Offset';
        }
        field(19; "Resource Usage Type"; Option)
        {
            Caption = 'Resource Usage Type';
            OptionCaption = ' ,Direct,Fixed';
            OptionMembers = " ",Direct,"Fixed";
        }
        field(20; "Location Code"; Code[10])
        {
            Caption = 'Location Code';
            TableRelation = Location where("Use As In-Transit" = const(false));
        }
        field(21; "Shortcut Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,2,1';
            Caption = 'Shortcut Dimension 1 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(1));
        }
        field(22; "Shortcut Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,2,2';
            Caption = 'Shortcut Dimension 2 Code';
            TableRelation = "Dimension Value".Code where("Global Dimension No." = const(2));
        }
        field(23; "Bin Code"; Code[20])
        {
            AccessByPermission = TableData "Warehouse Source Filter" = R;
            Caption = 'Bin Code';
        }
        field(25; Position; Code[10])
        {
            Caption = 'Position';
        }
        field(26; "Position 2"; Code[10])
        {
            Caption = 'Position 2';
        }
        field(27; "Position 3"; Code[10])
        {
            Caption = 'Position 3';
        }
        field(39; "Item Shpt. Entry No."; Integer)
        {
            Caption = 'Item Shpt. Entry No.';
        }
        field(40; Quantity; Decimal)
        {
            Caption = 'Quantity';
            DecimalPlaces = 0 : 5;
            MinValue = 0;
            AutoFormatType = 0;
        }
        field(41; "Quantity (Base)"; Decimal)
        {
            Caption = 'Quantity (Base)';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(52; "Due Date"; Date)
        {
            Caption = 'Due Date';
        }
        field(60; "Quantity per"; Decimal)
        {
            Caption = 'Quantity per';
            DecimalPlaces = 0 : 5;
            AutoFormatType = 0;
        }
        field(61; "Qty. per Unit of Measure"; Decimal)
        {
            Caption = 'Qty. per Unit of Measure';
            DecimalPlaces = 0 : 5;
            Editable = false;
            AutoFormatType = 0;
        }
        field(62; "Inventory Posting Group"; Code[20])
        {
            Caption = 'Inventory Posting Group';
            TableRelation = "Inventory Posting Group";
        }
        field(63; "Gen. Prod. Posting Group"; Code[20])
        {
            Caption = 'Gen. Prod. Posting Group';
            TableRelation = "Gen. Product Posting Group";
        }
        field(64; "Gen. Bus. Posting Group"; Code[20])
        {
            Caption = 'Gen. Bus. Posting Group';
            TableRelation = "Gen. Business Posting Group";
        }
        field(65; "Unit Cost"; Decimal)
        {
            AutoFormatType = 2;
            AutoFormatExpression = '';
            Caption = 'Unit Cost';
        }
        field(67; "Cost Amount"; Decimal)
        {
            AutoFormatType = 1;
            AutoFormatExpression = '';
            Caption = 'Cost Amount';
            Editable = false;
        }
        field(80; "Unit of Measure Code"; Code[10])
        {
            Caption = 'Unit of Measure Code';
            TableRelation = if (Type = const(Item)) "Item Unit of Measure".Code where("Item No." = field("No."))
            else
            if (Type = const(Resource)) "Resource Unit of Measure".Code where("Resource No." = field("No."));
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
    }

    keys
    {
        key(Key1; "Document No.", "Line No.")
        {
            Clustered = true;
        }
        key(Key2; "Order No.", "Order Line No.")
        {
        }
        key(Key3; Type, "No.")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AssemblyCommentLine: Record "Assembly Comment Line";
    begin
        AssemblyCommentLine.SetRange("Document Type", AssemblyCommentLine."Document Type"::"Posted Assembly");
        AssemblyCommentLine.SetRange("Document No.", "Document No.");
        AssemblyCommentLine.SetRange("Document Line No.", "Line No.");
        if not AssemblyCommentLine.IsEmpty() then
            AssemblyCommentLine.DeleteAll();
    end;

    procedure ShowDimensions()
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.ShowDimensionSet("Dimension Set ID", StrSubstNo('%1 %2', TableCaption(), "Document No."));
    end;

    procedure ShowItemTrackingLines()
    var
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowItemTrackingLines(Rec, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingDocMgt.ShowItemTrackingForShptRcptLine(DATABASE::"Posted Assembly Line", 0, "Document No.", '', 0, "Line No.");
    end;

    procedure ShowShortcutDimCode(var ShortcutDimCode: array[8] of Code[20])
    var
        DimMgt: Codeunit DimensionManagement;
    begin
        DimMgt.GetShortcutDimensions(Rec."Dimension Set ID", ShortcutDimCode);
    end;

    procedure GetAssemblyLinesForDocument(var TempPostedAssemblyLine: Record "Posted Assembly Line" temporary; ValueEntryDocType: Enum "Item Ledger Document Type"; DocNo: Code[20]; DocLineNo: Integer)
    var
        ValueEntry: Record "Value Entry";
        ItemLedgerEntry: Record "Item Ledger Entry";
        PostedAsmHeader: Record "Posted Assembly Header";
        PostedAsmLine: Record "Posted Assembly Line";
        SalesShipmentLine: Record "Sales Shipment Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        TempPostedAssemblyLine.Reset();
        TempPostedAssemblyLine.DeleteAll();

        ValueEntry.SetRange("Document Type", ValueEntryDocType);
        ValueEntry.SetRange("Document No.", DocNo);
        ValueEntry.SetRange("Document Line No.", DocLineNo);
        ValueEntry.SetFilter("Item Ledger Entry No.", '<>%1', 0);
        if not ValueEntry.FindSet() then
            exit;
        repeat
            ItemLedgerEntry.Get(ValueEntry."Item Ledger Entry No.");
            TempItemLedgerEntry := ItemLedgerEntry;
            if TempItemLedgerEntry.Insert() then;
        until ValueEntry.Next() = 0;

        if TempItemLedgerEntry.FindSet() then
            repeat
                if TempItemLedgerEntry."Document Type" = TempItemLedgerEntry."Document Type"::"Sales Shipment" then begin
                    SalesShipmentLine.Get(TempItemLedgerEntry."Document No.", TempItemLedgerEntry."Document Line No.");
                    if SalesShipmentLine.AsmToShipmentExists(PostedAsmHeader) then begin
                        PostedAsmLine.SetRange("Document No.", PostedAsmHeader."No.");
                        if PostedAsmLine.FindSet() then
                            repeat
                                TempPostedAssemblyLine.SetRange(Type, PostedAsmLine.Type);
                                TempPostedAssemblyLine.SetRange("No.", PostedAsmLine."No.");
                                TempPostedAssemblyLine.SetRange("Variant Code", PostedAsmLine."Variant Code");
                                TempPostedAssemblyLine.SetRange(Description, PostedAsmLine.Description);
                                TempPostedAssemblyLine.SetRange("Unit of Measure Code", PostedAsmLine."Unit of Measure Code");
                                if TempPostedAssemblyLine.FindFirst() then begin
                                    TempPostedAssemblyLine.Quantity += PostedAsmLine.Quantity;
                                    TempPostedAssemblyLine.Modify();
                                end else begin
                                    TempPostedAssemblyLine := PostedAsmLine;
                                    TempPostedAssemblyLine.Insert();
                                end;
                            until PostedAsmLine.Next() = 0;
                    end;
                end;
            until TempItemLedgerEntry.Next() = 0;

        TempPostedAssemblyLine.Reset();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowItemTrackingLines(var PostedAssemblyLine: Record "Posted Assembly Line"; var IsHandled: Boolean)
    begin
    end;
}
