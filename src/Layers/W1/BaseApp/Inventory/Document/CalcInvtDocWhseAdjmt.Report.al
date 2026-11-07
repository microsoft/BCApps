// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Document;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Counting.Journal;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Ledger;
using System.Utilities;

report 6562 "Calc. Invt. Doc. Whse. Adjmt."
{
    Caption = 'Calc. Invt. Doc. Whse. Adjmt.';
    ProcessingOnly = true;

    dataset
    {
        dataitem(Item; Item)
        {
            DataItemTableView = sorting("No.");
            RequestFilterFields = "No.", "Location Filter", "Variant Filter";
            dataitem("Integer"; "Integer")
            {
                DataItemTableView = sorting(Number) where(Number = const(1));

                trigger OnAfterGetRecord()
                begin
                    WhseEntry.SetRange("Location Code", InvtDocHeader."Location Code");
                    WhseEntry.SetRange("Bin Code", InvtDocHeader."Whse. Adj. Bin Code");
                    if WhseEntry.FindSet() then
                        repeat
                            if WhseEntry."Qty. (Base)" <> 0 then begin
                                TempInventoryBuffer.Reset();
                                TempInventoryBuffer.SetRange("Item No.", WhseEntry."Item No.");
                                TempInventoryBuffer.SetRange("Variant Code", WhseEntry."Variant Code");
                                TempInventoryBuffer.SetRange("Location Code", WhseEntry."Location Code");
                                TempInventoryBuffer.SetRange("Bin Code", WhseEntry."Bin Code");
                                if WhseEntry."Lot No." <> '' then
                                    TempInventoryBuffer.SetRange("Lot No.", WhseEntry."Lot No.");
                                if WhseEntry."Serial No." <> '' then
                                    TempInventoryBuffer.SetRange("Serial No.", WhseEntry."Serial No.");
                                if TempInventoryBuffer.FindFirst() then begin
                                    TempInventoryBuffer.Quantity := TempInventoryBuffer.Quantity + WhseEntry."Qty. (Base)";
                                    TempInventoryBuffer.Modify();
                                end else begin
                                    TempInventoryBuffer."Item No." := WhseEntry."Item No.";
                                    TempInventoryBuffer."Variant Code" := WhseEntry."Variant Code";
                                    TempInventoryBuffer."Location Code" := WhseEntry."Location Code";
                                    TempInventoryBuffer."Bin Code" := WhseEntry."Bin Code";
                                    TempInventoryBuffer."Lot No." := WhseEntry."Lot No.";
                                    TempInventoryBuffer."Serial No." := WhseEntry."Serial No.";
                                    TempInventoryBuffer.Quantity := WhseEntry."Qty. (Base)";
                                    TempInventoryBuffer.Insert();
                                end;
                            end;
                        until WhseEntry.Next() = 0;
                end;

                trigger OnPostDataItem()
                begin
                    TempInventoryBuffer.Reset();
                    TempInventoryBuffer.SetCurrentKey("Location Code", "Variant Code", Quantity);
                    if TempInventoryBuffer.FindSet() then
                        repeat
                            if TempInventoryBuffer."Location Code" <> '' then
                                TempInventoryBuffer.SetRange("Location Code", TempInventoryBuffer."Location Code");
                            TempInventoryBuffer.SetRange("Variant Code", TempInventoryBuffer."Variant Code");

                            case InvtDocHeader."Document Type" of
                                InvtDocHeader."Document Type"::Receipt:
                                    begin
                                        TempInventoryBuffer.SetFilter(Quantity, '>0');
                                        TempInventoryBuffer.CalcSums(Quantity);
                                        WhseQty := -TempInventoryBuffer.Quantity;
                                        if WhseQty <> 0 then begin
                                            TempInventoryBuffer.FindFirst();
                                            InsertInvtDocLine(
                                              TempInventoryBuffer."Item No.", TempInventoryBuffer."Variant Code", TempInventoryBuffer."Location Code",
                                              WhseQty, Item."Base Unit of Measure",
                                              InvtDocLine."Document Type"::Shipment);
                                        end;
                                    end;
                                InvtDocHeader."Document Type"::Shipment:
                                    begin
                                        TempInventoryBuffer.SetFilter(Quantity, '<0');
                                        TempInventoryBuffer.CalcSums(Quantity);
                                        WhseQty := -TempInventoryBuffer.Quantity;
                                        if WhseQty <> 0 then begin
                                            TempInventoryBuffer.FindFirst();
                                            InsertInvtDocLine(
                                              TempInventoryBuffer."Item No.", TempInventoryBuffer."Variant Code", TempInventoryBuffer."Location Code",
                                              WhseQty, Item."Base Unit of Measure",
                                              InvtDocLine."Document Type"::Shipment);
                                        end;
                                    end;
                            end;

                            TempInventoryBuffer.SetRange(Quantity);
                            TempInventoryBuffer.FindLast();
                            TempInventoryBuffer.SetRange("Location Code");
                            TempInventoryBuffer.SetRange("Variant Code");
                        until TempInventoryBuffer.Next() = 0;
                    TempInventoryBuffer.Reset();
                    TempInventoryBuffer.DeleteAll();
                end;

                trigger OnPreDataItem()
                begin
                    Clear(Location);
                    WhseEntry.Reset();
                    WhseEntry.SetCurrentKey("Item No.", "Bin Code", "Location Code", "Variant Code");
                    WhseEntry.Ascending(false);
                    WhseEntry.SetRange("Item No.", Item."No.");
                    Item.CopyFilter("Variant Filter", WhseEntry."Variant Code");

                    if WhseEntry.IsEmpty() then
                        CurrReport.Break();

                    TempInventoryBuffer.Reset();
                    TempInventoryBuffer.DeleteAll();

                    WhseQty := 0;
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not HideValidationDialog then
                    Window.Update();
            end;

            trigger OnPreDataItem()
            begin
                NextLineNo := 0;

                if not HideValidationDialog then
                    Window.Open(ProcessingItemsTxt, Item."No.");

                if GetFilter("Location Filter") <> '' then
                    ByLocation := true;
            end;
        }
    }

    requestpage
    {
        Caption = 'Calculate Inventory';
        SaveValues = true;

        layout
        {
        }

        actions
        {
        }
    }

    labels
    {
    }

    trigger OnInitReport()
    begin
        ByLocation := true;
        ByBin := false;
    end;

    var
        InvtDocHeader: Record "Invt. Document Header";
        InvtDocLine: Record "Invt. Document Line";
        WhseEntry: Record "Warehouse Entry";
        Location: Record Location;
        SourceCodeSetup: Record "Source Code Setup";
        TempInventoryBuffer: Record "Inventory Buffer" temporary;
        Window: Dialog;
        WhseQty: Decimal;
        NextLineNo: Integer;
        ByLocation: Boolean;
        ByBin: Boolean;
        ZeroQty: Boolean;
        HideValidationDialog: Boolean;
        ProcessingItemsTxt: Label 'Processing items    #1##########', Comment = '#1 - item counter';

    procedure SetInvtDocHeader(var NewInvtDocHeader: Record "Invt. Document Header")
    begin
        InvtDocHeader := NewInvtDocHeader;
        InvtDocHeader.TestField("Location Code");
        Location.Get(InvtDocHeader."Location Code");
        Location.TestField("Directed Put-away and Pick", true);
        Item.SetRange("Location Filter", InvtDocHeader."Location Code");
        InvtDocHeader.TestField("Whse. Adj. Bin Code");
    end;

    procedure InsertInvtDocLine(ItemNo: Code[20]; VariantCode2: Code[10]; LocationCode2: Code[10]; Quantity2: Decimal; UOM2: Code[10]; EntryType2: Enum "Invt. Doc. Document Type")
    var
        Location2: Record Location;
        WhseEntry2: Record "Warehouse Entry";
        WhseEntry3: Record "Warehouse Entry";
        ReservEntry: Record "Reservation Entry";
        CreateReservEntry: Codeunit "Create Reserv. Entry";
    begin
        if NextLineNo = 0 then begin
            InvtDocLine.LockTable();
            InvtDocLine.SetRange("Document Type", InvtDocLine."Document Type");
            InvtDocLine.SetRange("Document No.", InvtDocLine."Document No.");
            if InvtDocLine.FindLast() then
                NextLineNo := InvtDocLine."Line No.";

            SourceCodeSetup.Get();
        end;
        NextLineNo := NextLineNo + 10000;

        if Quantity2 <> 0 then begin
            InvtDocLine.Init();
            InvtDocLine."Line No." := NextLineNo;
            InvtDocLine.Validate("Posting Date", InvtDocHeader."Posting Date");
            InvtDocLine.Validate("Document Type", InvtDocHeader."Document Type");
            InvtDocLine.Validate("Document No.", InvtDocHeader."No.");
            InvtDocLine.Validate("Item No.", ItemNo);
            InvtDocLine.Validate("Variant Code", VariantCode2);
            InvtDocLine.Validate("Location Code", LocationCode2);
            if InvtDocHeader."Document Type" = InvtDocHeader."Document Type"::Receipt then
                InvtDocLine.Validate("Source Code", SourceCodeSetup."Invt. Receipt")
            else
                InvtDocLine.Validate("Source Code", SourceCodeSetup."Invt. Shipment");
            InvtDocLine.Validate("Unit of Measure Code", UOM2);
            if LocationCode2 <> '' then
                Location2.Get(LocationCode2);
            InvtDocLine.Validate(Quantity, Abs(Quantity2));
            InvtDocLine.Insert(true);

            if Location2.Code <> '' then
                if Location2."Directed Put-away and Pick" then begin
                    WhseEntry2.SetCurrentKey(
                      "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code",
                      "Lot No.", "Serial No.", "Entry Type");
                    WhseEntry2.SetRange("Item No.", InvtDocLine."Item No.");
                    WhseEntry2.SetRange("Bin Code", Location2."Adjustment Bin Code");
                    WhseEntry2.SetRange("Location Code", InvtDocLine."Location Code");
                    WhseEntry2.SetRange("Variant Code", InvtDocLine."Variant Code");
                    WhseEntry2.SetRange("Unit of Measure Code", InvtDocLine."Unit of Measure Code");
                    WhseEntry2.SetRange("Entry Type", EntryType2);
                    if WhseEntry2.FindSet() then
                        repeat
                            WhseEntry2.SetRange("Lot No.", WhseEntry2."Lot No.");
                            WhseEntry2.SetRange("Serial No.", WhseEntry2."Serial No.");
                            WhseEntry2.CalcSums("Qty. (Base)");

                            WhseEntry3.SetCurrentKey(
                              "Item No.", "Bin Code", "Location Code", "Variant Code", "Unit of Measure Code",
                              "Lot No.", "Serial No.", "Entry Type");
                            WhseEntry3.CopyFilters(WhseEntry2);
                            case EntryType2 of
                                EntryType2::Receipt:
                                    WhseEntry3.SetRange("Entry Type", WhseEntry3."Entry Type"::"Negative Adjmt.");
                                EntryType2::Shipment:
                                    WhseEntry3.SetRange("Entry Type", WhseEntry3."Entry Type"::"Positive Adjmt.");
                            end;
                            WhseEntry3.CalcSums("Qty. (Base)");
                            if Abs(WhseEntry3."Qty. (Base)") > Abs(WhseEntry2."Qty. (Base)") then
                                WhseEntry2."Qty. (Base)" := 0
                            else
                                WhseEntry2."Qty. (Base)" := WhseEntry2."Qty. (Base)" + WhseEntry3."Qty. (Base)";

                            if WhseEntry2."Qty. (Base)" <> 0 then begin
                                ReservEntry.CopyTrackingFromWhseEntry(WhseEntry2);
                                CreateReservEntry.CreateReservEntryFor(
                                  Database::"Item Journal Line", InvtDocLine."Document Type".AsInteger(), InvtDocLine."Document No.", '', 0, InvtDocLine."Line No.",
                                  InvtDocLine."Qty. per Unit of Measure", Abs(WhseEntry2.Quantity), Abs(WhseEntry2."Qty. (Base)"), ReservEntry);
                                CreateReservEntry.CreateEntry(
                                  InvtDocLine."Item No.", InvtDocLine."Variant Code", InvtDocLine."Location Code", InvtDocLine.Description, 0D, 0D, 0, "Reservation Status"::Prospect);
                            end;
                            WhseEntry2.FindLast();
                            WhseEntry2.ClearTrackingFilter();
                        until WhseEntry2.Next() = 0;
                end;
        end;
    end;

    procedure InitializeRequest(NewZeroQty: Boolean; NewByLocation: Boolean; NewByBin: Boolean)
    begin
        ZeroQty := NewZeroQty;
        ByLocation := NewByLocation;
        ByBin := NewByBin;
    end;

    procedure SetHideValidationDialog(NewHideValidationDialog: Boolean)
    begin
        HideValidationDialog := NewHideValidationDialog;
    end;
}

