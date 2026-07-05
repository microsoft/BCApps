// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Service.History;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory;
using Microsoft.Inventory.Costing;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Posting;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Projects.Resources.Journal;
using Microsoft.Service.Document;
using Microsoft.Service.Ledger;
using Microsoft.Service.Posting;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Journal;
using System.Utilities;

codeunit 5819 "Undo Service Consumption Line"
{
    Permissions = TableData "Item Ledger Entry" = rm,
                  TableData "Item Application Entry" = rmd,
                  TableData "Service Line" = rimd,
                  TableData "Service Ledger Entry" = rimd,
                  TableData "Warranty Ledger Entry" = rim,
                  TableData "Service Shipment Line" = rimd,
                  TableData "Item Entry Relation" = ri;
    TableNo = "Service Shipment Line";

    trigger OnRun()
    var
        ConfirmManagement: Codeunit "Confirm Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOnRun(Rec, IsHandled);
        if IsHandled then
            exit;

        if not Rec.Find('-') then
            exit;

        if not HideDialog then
            if not ConfirmManagement.GetResponseOrDefault(Text000, true) then
                exit;

        Rec.LockTable();
        ServShptLine.Copy(Rec);
        Code();
        Rec := ServShptLine;
    end;

    var
        ServShptHeader: Record "Service Shipment Header";
        ServShptLine: Record "Service Shipment Line";
        TempGlobalItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempGlobalItemEntryRelation: Record "Item Entry Relation" temporary;
        TempTrkgItemLedgEntry: Record "Item Ledger Entry" temporary;
        TempTrkgItemLedgEntry2: Record "Item Ledger Entry" temporary;
        SourceCodeSetup: Record "Source Code Setup";
        DummyItemJnlLine: Record "Item Journal Line";
        TempWhseJnlLine: Record "Warehouse Journal Line" temporary;
        WhseUndoQty: Codeunit "Whse. Undo Quantity";
        UndoPostingMgt: Codeunit "Undo Posting Management";
        ServUndoPostingMgt: Codeunit "Serv. Undo Posting Mgt.";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ItemTrackingDocMgt: Codeunit "Item Tracking Doc. Management";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
#pragma warning disable AA0074
        Text000: Label 'Do you want to undo consumption of the selected shipment line(s)?';
        Text001: Label 'Undo quantity consumed posting...';
        Text002: Label 'There is not enough space to insert correction lines.';
#pragma warning restore AA0074
        TrackingSpecificationExists: Boolean;
        HideDialog: Boolean;
#pragma warning disable AA0074
        Text003: Label 'Checking lines...';
        Text004: Label 'You cannot undo consumption on the line because it has been already posted to Projects.';
#pragma warning disable AA0470
        Text005: Label 'You cannot undo consumption because the original service order %1 is already closed.';
#pragma warning restore AA0470
#pragma warning restore AA0074
        NextLineNo: Integer;

    procedure SetHideDialog(NewHideDialog: Boolean)
    begin
        HideDialog := NewHideDialog;
    end;

    local procedure "Code"()
    var
        ServLedgEntriesPost: Codeunit "ServLedgEntries-Post";
        Window: Dialog;
        ItemShptEntryNo: Integer;
        ServLedgEntryNo: Integer;
        WarrantyLedgEntryNo: Integer;
    begin
        Clear(ItemJnlPostLine);
        ServShptLine.SetRange(Correction, false);
        ServShptLine.Find('-');
        repeat
            if not HideDialog then
                Window.Open(Text003);
            CheckServShptLine(ServShptLine);
        until ServShptLine.Next() = 0;

        ServLedgEntriesPost.InitServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);
        ServShptLine.Find('-');
        repeat
            if ServShptLine.Quantity <> ServShptLine."Qty. Shipped Not Invoiced" then begin
                TempGlobalItemLedgEntry.Reset();
                if not TempGlobalItemLedgEntry.IsEmpty() then
                    TempGlobalItemLedgEntry.DeleteAll();
                TempGlobalItemEntryRelation.Reset();
                if not TempGlobalItemEntryRelation.IsEmpty() then
                    TempGlobalItemEntryRelation.DeleteAll();

                if not HideDialog then
                    Window.Open(Text001);

                if ServShptLine.Type = ServShptLine.Type::Item then begin
                    CollectItemLedgerEntries(ServShptLine, TempTrkgItemLedgEntry);
                    ItemShptEntryNo := PostItemJnlLine(ServShptLine, ServShptLine."Item Shpt. Entry No.",
                        ServShptLine.Quantity, ServShptLine."Quantity (Base)",
                        ServShptLine.Quantity, ServShptLine."Quantity (Base)",
                        DummyItemJnlLine."Entry Type"::"Positive Adjmt.");
                end;
                if ServShptLine.Type = ServShptLine.Type::Resource then
                    PostResourceJnlLine(ServShptLine);
                InsertCorrectiveShipmentLine(ServShptLine, ItemShptEntryNo);

                ServLedgEntriesPost.ReverseCnsmServLedgEntries(ServShptLine);
                if ServShptLine.Type in [ServShptLine.Type::Item, ServShptLine.Type::Resource] then
                    ServLedgEntriesPost.ReverseWarrantyEntry(ServShptLine);

                UpdateOrderLine(ServShptLine);
                UpdateServShptLine(ServShptLine);
                OnCodeOnAfterUpdateServShptLine(ServShptLine);
            end;
        until ServShptLine.Next() = 0;
        ServLedgEntriesPost.FinishServiceRegister(ServLedgEntryNo, WarrantyLedgEntryNo);

        MakeInventoryAdjustment();

        WhseUndoQty.PostTempWhseJnlLine(TempWhseJnlLine);

        OnAfterCode(ServShptLine);
    end;

    local procedure CheckServShptLine(var ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        ServiceLedgerEntry: Record "Service Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckServShptLine(ServShptLine, IsHandled);
        if IsHandled then
            exit;

        ServShptLine.TestField("Quantity Invoiced", 0);
        ServShptLine.TestField("Quantity Consumed");
        ServShptLine.TestField("Qty. Shipped Not Invoiced", ServShptLine.Quantity - ServShptLine."Quantity Consumed");
        // Check if there was consumption posted to jobs
        ServiceLedgerEntry.Reset();
        ServiceLedgerEntry.SetRange("Document No.", ServShptLine."Document No.");
        ServiceLedgerEntry.SetRange("Posting Date", ServShptLine."Posting Date");
        ServiceLedgerEntry.SetRange("Document Line No.", ServShptLine."Line No.");
        ServiceLedgerEntry.SetRange("Service Order No.", ServShptLine."Order No.");
        ServiceLedgerEntry.SetRange("Job Posted", true);
        if not ServiceLedgerEntry.IsEmpty() then
            Error(Text004);

        if not ServLine.Get(ServLine."Document Type"::Order, ServShptLine."Order No.", ServShptLine."Order Line No.") then
            Error(Text005, ServShptLine."Order No.");
        ServUndoPostingMgt.TestServShptLine(ServShptLine);
        if ServShptLine.Type = ServShptLine.Type::Item then begin
            UndoPostingMgt.CollectItemLedgEntries(TempItemLedgEntry, DATABASE::"Service Shipment Line",
              ServShptLine."Document No.", ServShptLine."Line No.", ServShptLine."Quantity (Base)", ServShptLine."Item Shpt. Entry No.");
            UndoPostingMgt.CheckItemLedgEntries(TempItemLedgEntry, ServShptLine."Line No.");
        end;
    end;

    local procedure CollectItemLedgerEntries(var ServShptLine: Record "Service Shipment Line"; var TempItemLedgEntry: Record "Item Ledger Entry" temporary)
    var
        FromItemLedgEntry: Record "Item Ledger Entry";
        TempTrackingSpecToTest: Record "Tracking Specification" temporary;
    begin
        ServShptLine.FilterPstdDocLnItemLedgEntries(FromItemLedgEntry);
        ItemTrackingDocMgt.CopyItemLedgerEntriesToTemp(TempItemLedgEntry, FromItemLedgEntry);
        ItemTrackingDocMgt.RetrieveDocumentItemTracking(TempTrackingSpecToTest,
          ServShptLine."Document No.", DATABASE::"Service Shipment Header", 0);   // 0 - no doctype
        TrackingSpecificationExists := (TempTrackingSpecToTest.Count <> 0);
    end;

    local procedure PostItemJnlLine(ServShptLine: Record "Service Shipment Line"; ItemEntryNo: Integer; QtyToShip: Decimal; QtyToShipBase: Decimal; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; EntryType: Enum "Item Ledger Entry Type"): Integer
    var
        ItemJnlLine: Record "Item Journal Line";
        ServiceLine: Record "Service Line";
        SignFactor: Integer;
    begin
        SourceCodeSetup.Get();
        ServShptHeader.Get(ServShptLine."Document No.");

        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := EntryType;
        ItemJnlLine."Document Line No." :=
          ServShptLine."Line No." + GetCorrectiveShptLineNoStep(ServShptLine."Document No.", ServShptLine."Line No.");

        ItemJnlLine.CopyDocumentFields(ItemJnlLine."Document Type"::"Service Shipment", ServShptHeader."No.", '', SourceCodeSetup."Service Management", '');

        ServShptHeader.CopyToItemJnlLine(ItemJnlLine);
        ServShptLine.CopyToItemJnlLineUndo(ItemJnlLine);

        ItemJnlLine.Quantity := QtyToShip;
        ItemJnlLine."Quantity (Base)" := QtyToShipBase;
        ItemJnlLine."Invoiced Quantity" := QtyToConsume;
        ItemJnlLine."Invoiced Qty. (Base)" := QtyToConsumeBase;

        ItemJnlLine.Validate(ItemJnlLine."Applies-from Entry", ItemEntryNo);

        OnAfterCopyItemJnlLineFromServShpt(ItemJnlLine, ServShptHeader, ServShptLine);

        WhseUndoQty.InsertTempWhseJnlLine(ItemJnlLine,
          DATABASE::"Service Line", ServiceLine."Document Type"::Order.AsInteger(), ServShptHeader."Order No.", ServShptLine."Order Line No.",
          TempWhseJnlLine."Reference Document"::"Posted Shipment".AsInteger(), TempWhseJnlLine, NextLineNo);

        if not TrackingSpecificationExists then begin
            ItemJnlPostLine.SetServUndoConsumption(true);
            ItemJnlPostLine.RunWithCheck(ItemJnlLine);
            OnItemJnlPostLineOnAfteItemJnlPostLineOnBeforeExit(ItemJnlLine, ServShptLine);
            exit(ItemJnlLine."Item Shpt. Entry No.");
        end;

        TempTrkgItemLedgEntry.Reset();
        if QtyToConsume <> 0 then begin
            SignFactor := 1;
            TempTrkgItemLedgEntry2.DeleteAll();
            TempTrkgItemLedgEntry.Reset();
            if TempTrkgItemLedgEntry.FindFirst() then
                repeat
                    TempTrkgItemLedgEntry2 := TempTrkgItemLedgEntry;
                    TempTrkgItemLedgEntry2.Insert();
                until TempTrkgItemLedgEntry.Next() = 0;
            InsertNewReservationEntries(ServShptLine, EntryType, SignFactor);
            PostItemJnlLineWithIT(ServShptLine, QtyToShip, QtyToShipBase, QtyToConsume, QtyToConsumeBase, SignFactor, EntryType);
        end;
        exit(0); // "Item Shpt. Entry No."
    end;

    local procedure PostResourceJnlLine(ServiceShipmentLine: Record "Service Shipment Line")
    var
        ResJournalLine: Record "Res. Journal Line";
        ResJnlPostLine: Codeunit "Res. Jnl.-Post Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePostResourceJnlLine(ServiceShipmentLine, IsHandled);
        if IsHandled then
            exit;

        SourceCodeSetup.Get();
        ServShptHeader.Get(ServiceShipmentLine."Document No.");

        ResJournalLine.Init();
        ResJournalLine.CopyDocumentFields(ServiceShipmentLine."Document No.", '', SourceCodeSetup."Service Management", ServShptHeader."No. Series");

        ServShptHeader.CopyToResJournalLine(ResJournalLine);
        ServiceShipmentLine.CopyToResJournalLine(ResJournalLine);
        ResJournalLine."Source Type" := ResJournalLine."Source Type"::Customer;
        ResJournalLine."Source No." := ServShptHeader."Customer No.";

        ResJournalLine.Quantity := -ServiceShipmentLine."Quantity Consumed";
        ResJournalLine."Unit Cost" := ServiceShipmentLine."Unit Cost (LCY)";
        ResJournalLine."Total Cost" := ServiceShipmentLine."Unit Cost (LCY)" * ResJournalLine.Quantity;
        ResJournalLine."Unit Price" := 0;
        ResJournalLine."Total Price" := 0;

        OnPostResourceJnlLineOnBeforeResJnlPostLine(ResJournalLine, ServShptHeader, ServiceShipmentLine);
        ResJnlPostLine.RunWithCheck(ResJournalLine);
    end;

    local procedure PostItemJnlLineWithIT(var ServShptLine: Record "Service Shipment Line"; QtyToShip: Decimal; QtyToShipBase: Decimal; QtyToConsume: Decimal; QtyToConsumeBase: Decimal; SignFactor: Integer; EntryType: Enum "Item Ledger Entry Type")
    var
        ItemJnlLine: Record "Item Journal Line";
        TempItemLedgerEntry: Record "Item Ledger Entry" temporary;
    begin
        ItemJnlLine.Init();
        ItemJnlLine."Entry Type" := EntryType;
        ItemJnlLine."Document Line No." :=
          ServShptLine."Line No." + GetCorrectiveShptLineNoStep(ServShptLine."Document No.", ServShptLine."Line No.");

        ItemJnlLine.CopyDocumentFields(
          ItemJnlLine."Document Type"::"Service Shipment", ServShptLine."Document No.", '', SourceCodeSetup."Service Management", '');

        ServShptHeader.CopyToItemJnlLine(ItemJnlLine);
        ServShptLine.CopyToItemJnlLineUndo(ItemJnlLine);

        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Customer;
        ItemJnlLine."Source No." := ServShptHeader."Customer No.";
        ItemJnlLine."Derived from Blanket Order" := false;
        ItemJnlLine."Item Shpt. Entry No." := 0;
        ItemJnlLine.Correction := true;

        SignFactor := 1;
        ItemJnlLine.Quantity := SignFactor * QtyToShip;
        ItemJnlLine."Invoiced Quantity" := SignFactor * QtyToConsume;
        ItemJnlLine."Quantity (Base)" := SignFactor * QtyToShipBase;
        ItemJnlLine."Invoiced Qty. (Base)" := SignFactor * QtyToConsumeBase;
        ItemJnlLine."Unit Cost" := ServShptLine."Unit Cost";

        ItemTrackingMgt.AdjustQuantityRounding(QtyToShip, ItemJnlLine.Quantity, QtyToShipBase, ItemJnlLine."Quantity (Base)");

        QtyToShip -= ItemJnlLine.Quantity;
        QtyToShipBase -= ItemJnlLine."Quantity (Base)";
        if QtyToConsume <> 0 then begin
            QtyToConsume -= ItemJnlLine.Quantity;
            QtyToConsumeBase -= ItemJnlLine."Quantity (Base)";
        end;

        OnBeforePostItemJnlLineWithIT(ItemJnlLine, ServShptLine);

        UndoPostingMgt.CollectItemLedgEntries(TempItemLedgerEntry, DATABASE::"Service Shipment Line",
          ServShptLine."Document No.", ServShptLine."Line No.", ServShptLine."Quantity (Base)",
          ServShptLine."Item Shpt. Entry No.");
        UndoPostingMgt.PostItemJnlLineAppliedToList(ItemJnlLine, TempItemLedgerEntry,
          ServShptLine.Quantity, ServShptLine."Quantity (Base)", TempGlobalItemLedgEntry, TempGlobalItemEntryRelation);
    end;

    local procedure InsertNewReservationEntries(var ServShptLine: Record "Service Shipment Line"; EntryType: Enum "Item Ledger Entry Type"; SignFactor: Integer)
    var
        ReservEntry: Record "Reservation Entry";
        TempReservEntry: Record "Reservation Entry" temporary;
        ReserveEngineMgt: Codeunit "Reservation Engine Mgt.";
    begin
        SignFactor := -SignFactor;
        if TempTrkgItemLedgEntry2.FindSet() then
            repeat
                ReservEntry.Init();
                ReservEntry."Item No." := TempTrkgItemLedgEntry2."Item No.";
                ReservEntry."Location Code" := TempTrkgItemLedgEntry2."Location Code";
                ReservEntry."Qty. per Unit of Measure" := TempTrkgItemLedgEntry2."Qty. per Unit of Measure";
                ReservEntry.CopyTrackingFromItemLedgEntry(TempTrkgItemLedgEntry2);
                ReservEntry."Variant Code" := TempTrkgItemLedgEntry2."Variant Code";
                ReservEntry."Source ID" := '';
                ReservEntry."Source Type" := DATABASE::"Item Journal Line";
                ReservEntry."Source Subtype" := EntryType.AsInteger();
                ReservEntry."Source Ref. No." := 0;
                ReservEntry."Appl.-from Item Entry" := TempTrkgItemLedgEntry2."Entry No.";
                if EntryType = DummyItemJnlLine."Entry Type"::"Positive Adjmt." then
                    ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Surplus
                else
                    ReservEntry."Reservation Status" := ReservEntry."Reservation Status"::Prospect;
                ReservEntry."Quantity Invoiced (Base)" := 0;
                ReservEntry.Validate("Quantity (Base)", -TempTrkgItemLedgEntry2.Quantity);
                ReservEntry.Positive := ReservEntry."Quantity (Base)" > 0;
                ReservEntry."Entry No." := 0;
                if ReservEntry.Positive then begin
                    ReservEntry."Warranty Date" := TempTrkgItemLedgEntry2."Warranty Date";
                    ReservEntry."Expiration Date" := TempTrkgItemLedgEntry2."Expiration Date";
                    ReservEntry."Expected Receipt Date" := ServShptLine."Posting Date"
                end else
                    ReservEntry."Shipment Date" := ServShptLine."Posting Date";
                ReservEntry.Description := ServShptLine.Description;
                ReservEntry."Creation Date" := WorkDate();
                ReservEntry."Created By" := UserId;
                ReservEntry.UpdateItemTracking();
                ReservEntry."Appl.-to Item Entry" := TempTrkgItemLedgEntry2."Entry No.";
                OnBeforeReservEntryInsert(ReservEntry, TempTrkgItemLedgEntry2);
                ReservEntry.Insert();
                TempReservEntry := ReservEntry;
                TempReservEntry.Insert();
            until TempTrkgItemLedgEntry2.Next() = 0;
        ReserveEngineMgt.UpdateOrderTracking(TempReservEntry);
    end;

    local procedure InsertNewTrackSpecifications(var CurrentServShptLine: Record "Service Shipment Line"; Balancing: Boolean)
    var
        TempSSLItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        // replace in tracking specification old item entry relation for a new one, and adjust qtys
        TempTrkgItemLedgEntry.Reset();
        if TempTrkgItemLedgEntry.FindFirst() then begin
            TempSSLItemLedgEntry.Reset();
            TempSSLItemLedgEntry.DeleteAll();
            CollectItemLedgerEntries(CurrentServShptLine, TempSSLItemLedgEntry);
            if TempSSLItemLedgEntry.FindFirst() then
                repeat
                    InsertOneNewTrackSpec(TempTrkgItemLedgEntry."Entry No.", TempSSLItemLedgEntry."Entry No.", Balancing);

                    // collect/add another value entry relation, for the future new line
                    TempGlobalItemEntryRelation."Item Entry No." := TempSSLItemLedgEntry."Entry No.";
                    TempGlobalItemEntryRelation.CopyTrackingFromItemledgEntry(TempSSLItemLedgEntry);
                    OnBeforeTempGlobalItemEntryRelationInsert(TempGlobalItemEntryRelation, TempSSLItemLedgEntry);
                    if TempGlobalItemEntryRelation.Insert() then;

                    TempSSLItemLedgEntry.Next();
                until TempTrkgItemLedgEntry.Next() = 0;
        end;
    end;

    local procedure InsertOneNewTrackSpec(OldItemShptEntryNo: Integer; NewItemShptEntryNo: Integer; Balancing: Boolean)
    var
        TrackingSpecification: Record "Tracking Specification";
        NewTrackingSpecification: Record "Tracking Specification";
        NewEntryNo: Integer;
    begin
        TrackingSpecification.Reset();
        TrackingSpecification.SetRange("Item Ledger Entry No.", OldItemShptEntryNo);
        if TrackingSpecification.FindFirst() then begin
            NewTrackingSpecification.LockTable();
            NewTrackingSpecification.Reset();
            if NewTrackingSpecification.FindLast() then
                NewEntryNo := NewTrackingSpecification."Entry No." + 1
            else
                NewEntryNo := 1;
            NewTrackingSpecification.Init();
            NewTrackingSpecification := TrackingSpecification;
            NewTrackingSpecification."Entry No." := NewEntryNo;
            NewTrackingSpecification."Item Ledger Entry No." := NewItemShptEntryNo;
            if Balancing then begin
                NewTrackingSpecification."Quantity (Base)" := -TrackingSpecification."Quantity (Base)";
                NewTrackingSpecification."Quantity Handled (Base)" := -TrackingSpecification."Quantity (Base)";
                NewTrackingSpecification."Quantity Invoiced (Base)" := -TrackingSpecification."Quantity (Base)";
            end else begin
                NewTrackingSpecification."Quantity (Base)" := TrackingSpecification."Quantity (Base)";
                NewTrackingSpecification."Quantity Handled (Base)" := TrackingSpecification."Quantity (Base)";
                NewTrackingSpecification."Quantity Invoiced (Base)" := 0;
            end;
            NewTrackingSpecification.Validate("Quantity (Base)");
            NewTrackingSpecification.Insert();
        end;
    end;

    local procedure GetCorrectiveShptLineNoStep(DocumentNo: Code[20]; LineNo: Integer) LineSpacing: Integer
    var
        TestServShptLine: Record "Service Shipment Line";
    begin
        TestServShptLine.SetRange("Document No.", DocumentNo);
        TestServShptLine."Document No." := DocumentNo;
        TestServShptLine."Line No." := LineNo;
        TestServShptLine.Find('=');

        if TestServShptLine.Find('>') then begin
            LineSpacing := (TestServShptLine."Line No." - LineNo) div 2;
            if LineSpacing = 0 then
                Error(Text002);
        end else
            LineSpacing := 10000;
    end;

    local procedure InsertCorrectiveShipmentLine(OldServiceShipmentLine: Record "Service Shipment Line"; ItemShptEntryNo: Integer)
    var
        NewServiceShipmentLine: Record "Service Shipment Line";
        LineSpacing: Integer;
    begin
        OnBeforeInsertCorrectiveShipmentLine(OldServiceShipmentLine);

        LineSpacing := GetCorrectiveShptLineNoStep(OldServiceShipmentLine."Document No.", OldServiceShipmentLine."Line No.");
        NewServiceShipmentLine.Reset();
        NewServiceShipmentLine.Init();
        NewServiceShipmentLine.Copy(OldServiceShipmentLine);
        NewServiceShipmentLine."Line No." := OldServiceShipmentLine."Line No." + LineSpacing;
        NewServiceShipmentLine."Item Shpt. Entry No." := ItemShptEntryNo;
        NewServiceShipmentLine."Appl.-to Service Entry" := OldServiceShipmentLine."Appl.-to Service Entry";
        NewServiceShipmentLine.Quantity := -OldServiceShipmentLine.Quantity;
        NewServiceShipmentLine."Quantity (Base)" := -OldServiceShipmentLine."Quantity (Base)";
        NewServiceShipmentLine."Qty. Shipped Not Invoiced" := 0;
        NewServiceShipmentLine."Qty. Shipped Not Invd. (Base)" := 0;
        NewServiceShipmentLine."Quantity Consumed" := NewServiceShipmentLine.Quantity;
        NewServiceShipmentLine."Qty. Consumed (Base)" := NewServiceShipmentLine."Quantity (Base)";
        NewServiceShipmentLine.Correction := true;

        OnInsertCorrectiveShipmentLineOnBeforeInsert(NewServiceShipmentLine, OldServiceShipmentLine);
        NewServiceShipmentLine.Insert();

        UpdateItemJnlLine(NewServiceShipmentLine, ItemShptEntryNo);
        if OldServiceShipmentLine.Type = OldServiceShipmentLine.Type::Item then begin
            InsertNewTrackSpecifications(NewServiceShipmentLine, true);
            InsertItemEntryRelation(TempGlobalItemEntryRelation, NewServiceShipmentLine);
        end;
    end;

    local procedure UpdateOrderLine(ServShptLine: Record "Service Shipment Line")
    var
        ServLine: Record "Service Line";
    begin
        ServLine.Get(ServLine."Document Type"::Order, ServShptLine."Order No.", ServShptLine."Order Line No.");
        ServUndoPostingMgt.UpdateServLineCnsm(ServLine, ServShptLine."Quantity Consumed", ServShptLine."Qty. Consumed (Base)", TempGlobalItemLedgEntry);
        OnAfterUpdateOrderLine(ServLine, ServShptLine);
    end;

    local procedure UpdateServShptLine(var PassedServShptLine: Record "Service Shipment Line")
    begin
        PassedServShptLine."Quantity Consumed" := PassedServShptLine.Quantity;
        PassedServShptLine."Qty. Consumed (Base)" := PassedServShptLine."Quantity (Base)";
        PassedServShptLine."Qty. Shipped Not Invoiced" := 0;
        PassedServShptLine."Qty. Shipped Not Invd. (Base)" := 0;
        PassedServShptLine.Correction := true;
        PassedServShptLine.Modify();
    end;

    local procedure InsertItemEntryRelation(var TempItemEntryRelation: Record "Item Entry Relation" temporary; NewServShptLine: Record "Service Shipment Line")
    var
        ItemEntryRelation: Record "Item Entry Relation";
    begin
        if TempItemEntryRelation.Find('-') then
            repeat
                ItemEntryRelation := TempItemEntryRelation;
                NewServShptLine.TransferToItemEntryRelation(ItemEntryRelation);
                ItemEntryRelation.Insert();
            until TempItemEntryRelation.Next() = 0;
        TempItemEntryRelation.DeleteAll();
    end;

    local procedure UpdateItemJnlLine(NewServShptLine: Record "Service Shipment Line"; ItemShptEntryNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        if ItemLedgEntry.Get(ItemShptEntryNo) then begin
            ItemLedgEntry."Document Line No." := NewServShptLine."Line No.";
            ItemLedgEntry.Modify();
        end;
    end;

    local procedure MakeInventoryAdjustment()
    var
        InvtSetup: Record "Inventory Setup";
        InvtAdjmtHandler: Codeunit "Inventory Adjustment Handler";
    begin
        InvtSetup.Get();
        if InvtSetup.AutomaticCostAdjmtRequired() then
            InvtAdjmtHandler.MakeInventoryAdjustment(true, InvtSetup."Automatic Cost Posting");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCode(var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCopyItemJnlLineFromServShpt(var ItemJournalLine: Record "Item Journal Line"; ServiceShipmentHeader: Record "Service Shipment Header"; ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateOrderLine(var ServiceLine: Record "Service Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckServShptLine(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostItemJnlLineWithIT(var ItemJournalLine: Record "Item Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReservEntryInsert(var ReservationEntry: Record "Reservation Entry"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempGlobalItemEntryRelationInsert(var ItemEntryRelation: Record "Item Entry Relation"; var ItemLedgerEntry: Record "Item Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterUpdateServShptLine(var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCorrectiveShipmentLine(var OldServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostResourceJnlLine(var ServiceShipmentLine: Record "Service Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemJnlPostLineOnAfteItemJnlPostLineOnBeforeExit(var ItemJournalLine: Record "Item Journal Line"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostResourceJnlLineOnBeforeResJnlPostLine(var ResJournalLine: Record "Res. Journal Line"; var ServiceShipmentHeader: Record "Service Shipment Header"; var ServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCorrectiveShipmentLineOnBeforeInsert(var NewServiceShipmentLine: Record "Service Shipment Line"; OldServiceShipmentLine: Record "Service Shipment Line")
    begin
    end;
}

