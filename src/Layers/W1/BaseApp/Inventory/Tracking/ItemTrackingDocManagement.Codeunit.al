// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Document;
using Microsoft.Inventory.History;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;

codeunit 6503 "Item Tracking Doc. Management"
{

    trigger OnRun()
    begin
    end;

    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        RetrieveAsmItemTracking: Boolean;

        CountingRecordsMsg: Label 'Counting records...';
        TableNotSupportedErr: Label 'Table %1 is not supported.', Comment = '%1 - table number';
        CreateTrackingSpecQst: Label 'This function create tracking specification from reservation entries. Continue?';

    procedure AddTempRecordToSet(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; SignFactor: Integer)
    var
        TempItemLedgEntry2: Record "Item Ledger Entry" temporary;
    begin
        if SignFactor <> 1 then begin
            TempItemLedgEntry.Quantity *= SignFactor;
            TempItemLedgEntry."Remaining Quantity" *= SignFactor;
            TempItemLedgEntry."Invoiced Quantity" *= SignFactor;
            OnAddTempRecordToSetOnAfterApplySignFactor(TempItemLedgEntry, SignFactor);
        end;
        ItemTrackingMgt.RetrieveAppliedExpirationDate(TempItemLedgEntry);
        OnAddTempRecordToSetOnAfterRetrieveAppliedExpirationDate(TempItemLedgEntry);
        TempItemLedgEntry2 := TempItemLedgEntry;
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.SetTrackingFilterFromItemLedgEntry(TempItemLedgEntry2);
        TempItemLedgEntry.SetRange("Warranty Date", TempItemLedgEntry2."Warranty Date");
        TempItemLedgEntry.SetRange("Expiration Date", TempItemLedgEntry2."Expiration Date");
        OnAddTempRecordToSetOnAfterTempItemLedgEntrySetFilters(TempItemLedgEntry, TempItemLedgEntry2);
        if TempItemLedgEntry.FindFirst() then begin
            TempItemLedgEntry.Quantity += TempItemLedgEntry2.Quantity;
            TempItemLedgEntry."Remaining Quantity" += TempItemLedgEntry2."Remaining Quantity";
            TempItemLedgEntry."Invoiced Quantity" += TempItemLedgEntry2."Invoiced Quantity";
            OnAddTempRecordToSetOnBeforeTempItemLedgEntryModify(TempItemLedgEntry, TempItemLedgEntry2);
            TempItemLedgEntry.Modify();
        end else
            TempItemLedgEntry.Insert();

        OnAfterAddTempRecordToSet(TempItemLedgEntry, TempItemLedgEntry2, SignFactor);
        TempItemLedgEntry.Reset();
    end;

    procedure CollectItemTrkgPerPostedDocLine(var TempReservEntry: Record "Reservation Entry" temporary; var TempItemLedgEntry: Record "Item Ledger Entry" temporary; FromPurchase: Boolean; DocNo: Code[20]; LineNo: Integer)
    var
        ItemLedgEntry: Record "Item Ledger Entry";
    begin
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();

        TempReservEntry.Reset();
        TempReservEntry.SetCurrentKey("Source ID", "Source Ref. No.");
        TempReservEntry.SetRange("Source ID", DocNo);
        TempReservEntry.SetRange("Source Ref. No.", LineNo);
        if TempReservEntry.FindSet() then
            repeat
                ItemLedgEntry.Get(TempReservEntry."Item Ledger Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                if TempReservEntry."Reservation Status" = "Reservation Status"::Prospect then
                    TempItemLedgEntry."Entry No." := -TempItemLedgEntry."Entry No.";
                if FromPurchase then
                    TempItemLedgEntry."Remaining Quantity" := TempReservEntry."Quantity (Base)"
                else
                    TempItemLedgEntry."Shipped Qty. Not Returned" := TempReservEntry."Quantity (Base)";
                TempItemLedgEntry."Document No." := TempReservEntry."Source ID";
                TempItemLedgEntry."Document Line No." := TempReservEntry."Source Ref. No.";
                OnCollectItemTrkgPerPostedDocLineOnBeforeTempItemLedgEntryInsert(TempItemLedgEntry, TempReservEntry, ItemLedgEntry, FromPurchase);
                TempItemLedgEntry.Insert();
            until TempReservEntry.Next() = 0;
    end;

    procedure CopyItemLedgerEntriesToTemp(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var FromItemLedgEntry: Record "Item Ledger Entry")
    begin
        TempItemLedgEntry.Reset();
        TempItemLedgEntry.DeleteAll();
        if FromItemLedgEntry.FindSet() then
            repeat
                TempItemLedgEntry := FromItemLedgEntry;
                AddTempRecordToSet(TempItemLedgEntry, 1);
            until FromItemLedgEntry.Next() = 0;

        TempItemLedgEntry.Reset();
    end;

    local procedure FillTrackingSpecBuffer(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100]; ItemNo: Code[20]; VariantCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"; Qty: Decimal; Correction: Boolean)
    var
        LastEntryNo: Integer;
    begin
        TempTrackingSpecBuffer.Reset();
        LastEntryNo := TempTrackingSpecBuffer.GetLastEntryNo();

        if ItemTrackingExistsInBuffer(TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, ItemTrackingSetup) then begin
            TempTrackingSpecBuffer."Quantity (Base)" += Abs(Qty);
            TempTrackingSpecBuffer.Modify();
        end else begin
            LastEntryNo += 1;
            InitTrackingSpecBuffer(
                TempTrackingSpecBuffer, LastEntryNo, Type, Subtype, ID, BatchName,
                ProdOrderLine, RefNo, Description, ItemNo, VariantCode, ItemTrackingSetup, Correction);
            TempTrackingSpecBuffer."Quantity (Base)" := Abs(Qty);
            TempTrackingSpecBuffer.Insert();
        end;
    end;

    procedure FillTrackingSpecBufferFromILE(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        // creates a new record in TempTrackingSpecBuffer (used for Posted Shipments/Receipts/Invoices)

        if TempItemLedgEntry.FindSet() then
            repeat
                if TempItemLedgEntry.TrackingExists() then begin
                    ItemTrackingSetup.CopyTrackingFromItemLedgerEntry(TempItemLedgEntry);
                    FillTrackingSpecBuffer(
                        TempTrackingSpecBuffer, Type, Subtype, ID, BatchName,
                        ProdOrderLine, RefNo, Description, TempItemLedgEntry."Item No.", TempItemLedgEntry."Variant Code",
                        ItemTrackingSetup, TempItemLedgEntry.Quantity, TempItemLedgEntry.Correction);
                    OnAfterFillTrackingSpecBufferFromItemLedgEntry(TempTrackingSpecBuffer, TempItemLedgEntry);
                end;
            until TempItemLedgEntry.Next() = 0;
    end;

    procedure FindReservEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        ReservEntry: Record "Reservation Entry";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        // finds Item Tracking for Quote, Order, Invoice, Credit Memo, Return Order

        ReservEntry.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        ReservEntry.SetSourceFilter(BatchName, ProdOrderLine);
        if ReservEntry.FindSet() then
            repeat
                if ReservEntry.TrackingExists() then begin
                    ItemTrackingSetup.CopyTrackingFromReservEntry(ReservEntry);
                    FillTrackingSpecBuffer(
                        TempTrackingSpecBuffer, Type, Subtype, ID, BatchName,
                        ProdOrderLine, RefNo, Description, ReservEntry."Item No.", ReservEntry."Variant Code",
                        ItemTrackingSetup, ReservEntry."Quantity (Base)", ReservEntry.Correction);
                    OnAfterFillTrackingSpecBufferFromReservEntry(TempTrackingSpecBuffer, ReservEntry);
                end;
            until ReservEntry.Next() = 0;
    end;

    procedure FindTrackingEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        TrackingSpec: Record "Tracking Specification";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        // finds Item Tracking for Quote, Order, Invoice, Credit Memo, Return Order when shipped/received

        TrackingSpec.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        TrackingSpec.SetSourceFilter(BatchName, ProdOrderLine);
        if TrackingSpec.FindSet() then
            repeat
                if TrackingSpec.TrackingExists() then begin
                    ItemTrackingSetup.CopyTrackingFromTrackingSpec(TrackingSpec);
                    FillTrackingSpecBuffer(
                        TempTrackingSpecBuffer, Type, Subtype, ID, BatchName,
                        ProdOrderLine, RefNo, Description, TrackingSpec."Item No.", TrackingSpec."Variant Code",
                        ItemTrackingSetup, TrackingSpec."Quantity (Base)", TrackingSpec.Correction);
                    OnAfterFillTrackingSpecBufferFromTrackingEntries(TempTrackingSpecBuffer, TrackingSpec);
                end;
            until TrackingSpec.Next() = 0;
    end;

    procedure FindShptRcptEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        // finds Item Tracking for Posted Shipments/Receipts

        RetrieveEntriesFromShptRcpt(TempItemLedgEntry, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo);
        FillTrackingSpecBufferFromILE(
          TempItemLedgEntry, TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, Description);

        TempTrackingSpecBuffer.Reset();
    end;

    procedure FindInvoiceEntries(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100])
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        InvoiceRowID: Text[250];
    begin
        InvoiceRowID := ItemTrackingMgt.ComposeRowID(Type, Subtype, ID, BatchName, ProdOrderLine, RefNo);
        RetrieveEntriesFromPostedInvoice(TempItemLedgEntry, InvoiceRowID);
        FillTrackingSpecBufferFromILE(
          TempItemLedgEntry, TempTrackingSpecBuffer, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo, Description);

        TempTrackingSpecBuffer.Reset();
    end;

    local procedure InitTrackingSpecBuffer(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; EntryNo: Integer; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; Description: Text[100]; ItemNo: Code[20]; VariantCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup"; Correction: Boolean)
    begin
        // initializes a new record for TempTrackingSpecBuffer

        TempTrackingSpecBuffer.Init();
        TempTrackingSpecBuffer."Source Type" := Type;
        TempTrackingSpecBuffer."Entry No." := EntryNo;
        TempTrackingSpecBuffer."Item No." := ItemNo;
        TempTrackingSpecBuffer."Variant Code" := VariantCode;
        TempTrackingSpecBuffer.Description := Description;
        TempTrackingSpecBuffer."Source Subtype" := Subtype;
        TempTrackingSpecBuffer."Source ID" := ID;
        TempTrackingSpecBuffer."Source Batch Name" := BatchName;
        TempTrackingSpecBuffer."Source Prod. Order Line" := ProdOrderLine;
        TempTrackingSpecBuffer."Source Ref. No." := RefNo;
        TempTrackingSpecBuffer.CopyTrackingFromItemTrackingSetup(ItemTrackingSetup);
        TempTrackingSpecBuffer.Correction := Correction;
    end;

    local procedure ItemTrackingExistsInBuffer(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer; ItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        // searches after existing record in TempTrackingSpecBuffer
        TempTrackingSpecBuffer.SetSourceFilter(Type, Subtype, ID, RefNo, true);
        TempTrackingSpecBuffer.SetSourceFilter(BatchName, ProdOrderLine);
        TempTrackingSpecBuffer.SetTrackingFilterFromItemTrackingSetup(ItemTrackingSetup);
        OnItemTrackingExistsInBufferOnAfterTempTrackingSpecBufferSetFilters(TempTrackingSpecBuffer);
        if not TempTrackingSpecBuffer.IsEmpty() then begin
            TempTrackingSpecBuffer.FindFirst();
            exit(true);
        end;
        exit(false);
    end;

    procedure RetrieveDocumentItemTracking(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceType: Integer; SourceSubType: Option): Integer
    var
        Found: Boolean;
        IsHandled: Boolean;
    begin
        // retrieves Item Tracking for Purchase Header, Sales Header, Sales Shipment Header, Sales Invoice Header
        TempTrackingSpecBuffer.DeleteAll();

        IsHandled := false;
        OnBeforeRetrieveDocumentItemTracking(TempTrackingSpecBuffer, SourceID, SourceType, SourceSubType, IsHandled);
        if not IsHandled then
            case SourceType of
                Database::"Purchase Header":
                    RetrieveTrackingPurchase(TempTrackingSpecBuffer, SourceID, SourceSubType);
                Database::"Sales Header":
                    RetrieveTrackingSales(TempTrackingSpecBuffer, SourceID, SourceSubType);
                Database::"Purch. Rcpt. Header":
                    RetrieveTrackingPurchaseReceipt(TempTrackingSpecBuffer, SourceID);
                Database::"Sales Shipment Header":
                    RetrieveTrackingSalesShipment(TempTrackingSpecBuffer, SourceID);
                Database::"Sales Invoice Header":
                    RetrieveTrackingSalesInvoice(TempTrackingSpecBuffer, SourceID);
                Database::"Sales Cr.Memo Header":
                    RetrieveTrackingSalesCrMemoHeader(TempTrackingSpecBuffer, SourceID);
                Database::"Purch. Inv. Header":
                    RetrieveTrackingPurhInvHeader(TempTrackingSpecBuffer, SourceID);
                Database::"Purch. Cr. Memo Hdr.":
                    RetrieveTrackingPurchCrMemoHeader(TempTrackingSpecBuffer, SourceID);
                else begin
                    OnRetrieveDocumentItemTracking(TempTrackingSpecBuffer, SourceID, Found, SourceType, SourceSubType, RetrieveAsmItemTracking);
                    if not Found then
                        Error(TableNotSupportedErr, SourceType);
                end;
            end;

        TempTrackingSpecBuffer.Reset();
        exit(TempTrackingSpecBuffer.Count);
    end;

    procedure RetrieveEntriesFromShptRcpt(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer)
    var
        ItemEntryRelation: Record "Item Entry Relation";
        ItemLedgEntry: Record "Item Ledger Entry";
        SignFactor: Integer;
    begin
        // retrieves a data set of Item Ledger Entries (Posted Shipments/Receipts)
        ItemEntryRelation.SetCurrentKey("Source ID", "Source Type");
        ItemEntryRelation.SetRange("Source Type", Type);
        ItemEntryRelation.SetRange("Source Subtype", Subtype);
        ItemEntryRelation.SetRange("Source ID", ID);
        ItemEntryRelation.SetRange("Source Batch Name", BatchName);
        ItemEntryRelation.SetRange("Source Prod. Order Line", ProdOrderLine);
        ItemEntryRelation.SetRange("Source Ref. No.", RefNo);
        if ItemEntryRelation.FindSet() then begin
            SignFactor := TableSignFactor(Type);
            repeat
                ItemLedgEntry.Get(ItemEntryRelation."Item Entry No.");
                TempItemLedgEntry := ItemLedgEntry;
                AddTempRecordToSet(TempItemLedgEntry, SignFactor);
            until ItemEntryRelation.Next() = 0;
        end;
    end;

    procedure RetrieveEntriesFromPostedInvoice(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; InvoiceRowID: Text[250])
    var
        ValueEntryRelation: Record "Value Entry Relation";
        ValueEntry: Record "Value Entry";
        ItemLedgEntry: Record "Item Ledger Entry";
        SignFactor: Integer;
    begin
        // retrieves a data set of Item Ledger Entries (Posted Invoices)
        ValueEntryRelation.SetCurrentKey("Source RowId");
        ValueEntryRelation.SetRange("Source RowId", InvoiceRowID);
        if ValueEntryRelation.Find('-') then begin
            SignFactor := TableSignFactor2(InvoiceRowID);
            repeat
                ValueEntry.Get(ValueEntryRelation."Value Entry No.");
                if ValueEntry."Item Ledger Entry Type" in
                   [ValueEntry."Item Ledger Entry Type"::Purchase,
                    ValueEntry."Item Ledger Entry Type"::Sale,
                    ValueEntry."Item Ledger Entry Type"::"Positive Adjmt.",
                    ValueEntry."Item Ledger Entry Type"::"Negative Adjmt."]
                then begin
                    ItemLedgEntry.Get(ValueEntry."Item Ledger Entry No.");
                    TempItemLedgEntry := ItemLedgEntry;
                    TempItemLedgEntry.Quantity := ValueEntry."Invoiced Quantity";
                    OnRetrieveEntriesFromPostedInvOnBeforeAddTempRecordToSet(TempItemLedgEntry, ValueEntry);
                    if TempItemLedgEntry.Quantity <> 0 then
                        AddTempRecordToSet(TempItemLedgEntry, SignFactor);
                end;
            until ValueEntryRelation.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingPurchase(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceSubType: Option)
    var
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchaseLine.SetRange("Document Type", SourceSubType);
        PurchaseLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingPurchaseOnAfterSetFilters(PurchaseLine, SourceID, SourceSubType);
        if not PurchaseLine.IsEmpty() then begin
            PurchaseLine.FindSet();
            repeat
                if (PurchaseLine.Type = PurchaseLine.Type::Item) and
                   (PurchaseLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchaseLine."No.") then
                        Descr := Item.Description;
                    FindReservEntries(
                        TempTrackingSpecBuffer, Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(),
                        PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", Descr);
                    FindTrackingEntries(
                        TempTrackingSpecBuffer, Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(),
                        PurchaseLine."Document No.", '', 0, PurchaseLine."Line No.", Descr);
                end;
            until PurchaseLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingPurchaseReceipt(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        PurchRcptLine: Record "Purch. Rcpt. Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchRcptLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingPurchaseReceiptOnAfterSetFilters(PurchRcptLine, SourceID);
        if PurchRcptLine.FindSet() then
            repeat
                if (PurchRcptLine.Type = PurchRcptLine.Type::Item) and
                   (PurchRcptLine."No." <> '') and
                   (PurchRcptLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchRcptLine."No.") then
                        Descr := Item.Description;
                    FindShptRcptEntries(
                      TempTrackingSpecBuffer,
                      Database::"Purch. Rcpt. Line", 0, PurchRcptLine."Document No.", '', 0, PurchRcptLine."Line No.", Descr);
                end;
            until PurchRcptLine.Next() = 0;
    end;

    local procedure RetrieveTrackingSales(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceSubType: Option)
    var
        SalesLine: Record "Sales Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesLine.SetRange("Document Type", SourceSubType);
        SalesLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingSalesOnAfterSetFilters(SalesLine, SourceID, SourceSubType);
        if not SalesLine.IsEmpty() then begin
            SalesLine.FindSet();
            repeat
                if (SalesLine.Type = SalesLine.Type::Item) and
                   (SalesLine."No." <> '') and
                   (SalesLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesLine."No.") then
                        Descr := Item.Description;
                    FindReservEntries(
                        TempTrackingSpecBuffer, Database::"Sales Line", SalesLine."Document Type".AsInteger(),
                        SalesLine."Document No.", '', 0, SalesLine."Line No.", Descr);
                    FindTrackingEntries(
                        TempTrackingSpecBuffer, Database::"Sales Line", SalesLine."Document Type".AsInteger(),
                        SalesLine."Document No.", '', 0, SalesLine."Line No.", Descr);
                end;
            until SalesLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingSalesShipment(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        SalesShipmentLine: Record "Sales Shipment Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesShipmentLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingSalesShipmentOnAfterSetFilters(SalesShipmentLine, SourceID);
        if not SalesShipmentLine.IsEmpty() then begin
            SalesShipmentLine.FindSet();
            repeat
                if (SalesShipmentLine.Type = SalesShipmentLine.Type::Item) and
                   (SalesShipmentLine."No." <> '') and
                   (SalesShipmentLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesShipmentLine."No.") then
                        Descr := Item.Description;
                    FindShptRcptEntries(
                        TempTrackingSpecBuffer,
                        Database::"Sales Shipment Line", 0, SalesShipmentLine."Document No.", '', 0, SalesShipmentLine."Line No.", Descr);
                    if RetrieveAsmItemTracking then
                        OnRetrieveTrackingSalesShipmentForAssembly(SalesShipmentLine, TempTrackingSpecBuffer);
                end;
            until SalesShipmentLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingSalesInvoice(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        SalesInvoiceLine: Record "Sales Invoice Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesInvoiceLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingSalesInvoiceOnAfterSetFilters(SalesInvoiceLine, SourceID);
        if not SalesInvoiceLine.IsEmpty() then begin
            SalesInvoiceLine.FindSet();
            repeat
                if (SalesInvoiceLine.Type = SalesInvoiceLine.Type::Item) and
                   (SalesInvoiceLine."No." <> '') and
                   (SalesInvoiceLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesInvoiceLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      Database::"Sales Invoice Line", 0, SalesInvoiceLine."Document No.", '', 0, SalesInvoiceLine."Line No.", Descr);
                end;
            until SalesInvoiceLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingSalesCrMemoHeader(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        SalesCrMLine: Record "Sales Cr.Memo Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        SalesCrMLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingSalesCrMemoHeaderOnAfterSetFilters(SalesCrMLine, SourceID);
        if not SalesCrMLine.IsEmpty() then begin
            SalesCrMLine.FindSet();
            repeat
                if (SalesCrMLine.Type = SalesCrMLine.Type::Item) and
                   (SalesCrMLine."No." <> '') and
                   (SalesCrMLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(SalesCrMLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      Database::"Sales Cr.Memo Line", 0, SalesCrMLine."Document No.", '', 0, SalesCrMLine."Line No.", Descr);
                end;
            until SalesCrMLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingPurhInvHeader(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        PurchInvLine: Record "Purch. Inv. Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchInvLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingPurhInvHeaderOnAfterSetFilters(PurchInvLine, SourceID);
        if not PurchInvLine.IsEmpty() then begin
            PurchInvLine.FindSet();
            repeat
                if (PurchInvLine.Type = PurchInvLine.Type::Item) and
                   (PurchInvLine."No." <> '') and
                   (PurchInvLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchInvLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      Database::"Purch. Inv. Line", 0, PurchInvLine."Document No.", '', 0, PurchInvLine."Line No.", Descr);
                end;
            until PurchInvLine.Next() = 0;
        end;
    end;

    local procedure RetrieveTrackingPurchCrMemoHeader(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20])
    var
        PurchCrMLine: Record "Purch. Cr. Memo Line";
        Item: Record Item;
        Descr: Text[100];
    begin
        PurchCrMLine.SetRange("Document No.", SourceID);
        OnRetrieveTrackingPurchCrMemoHeaderOnAfterSetFilters(PurchCrMLine, SourceID);
        if not PurchCrMLine.IsEmpty() then begin
            PurchCrMLine.FindSet();
            repeat
                if (PurchCrMLine.Type = PurchCrMLine.Type::Item) and
                   (PurchCrMLine."No." <> '') and
                   (PurchCrMLine."Quantity (Base)" <> 0)
                then begin
                    if Item.Get(PurchCrMLine."No.") then
                        Descr := Item.Description;
                    FindInvoiceEntries(TempTrackingSpecBuffer,
                      Database::"Purch. Cr. Memo Line", 0, PurchCrMLine."Document No.", '', 0, PurchCrMLine."Line No.", Descr);
                end;
            until PurchCrMLine.Next() = 0;
        end;
    end;

    procedure SetRetrieveAsmItemTracking(RetrieveAsmItemTracking2: Boolean)
    begin
        RetrieveAsmItemTracking := RetrieveAsmItemTracking2;
    end;

    procedure ShowItemTrackingForInvoiceLine(InvoiceRowID: Text[250]): Boolean
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        RetrieveEntriesFromPostedInvoice(TempItemLedgEntry, InvoiceRowID);
        if not TempItemLedgEntry.IsEmpty() then begin
            PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
            exit(true);
        end;
        exit(false);
    end;

    procedure ShowItemTrackingForEntity(SourceType: Integer; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10]; ItemTrackingSetup: Record "Item Tracking Setup")
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Item: Record Item;
        Window: Dialog;
    begin
        // Used when calling Item Tracking from Item, Stockkeeping Unit, Customer, Vendor and information card:
        Window.Open(CountingRecordsMsg);

        if SourceNo <> '' then begin
            ItemLedgEntry.SetCurrentKey("Source Type", "Source No.", "Item No.", "Variant Code");
            ItemLedgEntry.SetRange("Source No.", SourceNo);
            ItemLedgEntry.SetRange("Source Type", SourceType);
        end else
            ItemLedgEntry.SetCurrentKey("Item No.", Open, "Variant Code");

        if LocationCode <> '' then
            ItemLedgEntry.SetRange("Location Code", LocationCode);

        if ItemNo <> '' then begin
            Item.Get(ItemNo);
            Item.TestField("Item Tracking Code");
            ItemLedgEntry.SetRange("Item No.", ItemNo);
        end;

        if SourceType = 0 then
            ItemLedgEntry.SetRange("Variant Code", VariantCode);

        ItemLedgEntry.SetTrackingFilterFromItemTrackingSetupIfNotBlank(ItemTrackingSetup);
        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry.TrackingExists() then begin
                    TempItemLedgEntry := ItemLedgEntry;
                    OnShowItemTrackingForEntityOnBeforeTempItemLedgEntryInsert(TempItemLedgEntry, Item);
                    TempItemLedgEntry.Insert();
                end
            until ItemLedgEntry.Next() = 0;

        Window.Close();
        PAGE.RunModal(PAGE::"Item Tracking Entries", TempItemLedgEntry);
    end;

    procedure ShowItemTrackingForEntity(SourceType: Integer; SourceNo: Code[20]; ItemNo: Code[20]; VariantCode: Code[20]; LocationCode: Code[10])
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        ShowItemTrackingForEntity(SourceType, SourceNo, ItemNo, VariantCode, LocationCode, DummyItemTrackingSetup);
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit Mfg. Item Tracking Mgt.', '27.0')]
    procedure ShowItemTrackingForProdOrderComp(Type: Integer; ID: Code[20]; ProdOrderLine: Integer; RefNo: Integer): Boolean
    var
        MfgItemTrackingMgt: Codeunit "Mfg. Item Tracking Mgt.";
    begin
        exit(MfgItemTrackingMgt.ShowItemTrackingForProdOrderComp(Type, ID, ProdOrderLine, RefNo));
    end;
#endif

    internal procedure ShowItemTrackingForJobPlanningLine(Type: Integer; ID: Code[20]; RefNo: Integer): Boolean
    var
        ItemLedgEntry: Record "Item Ledger Entry";
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
        Window: Dialog;
    begin
        Window.Open(CountingRecordsMsg);
        ItemLedgEntry.SetLoadFields("Serial No.", "Lot No.", "Package No.");
        ItemLedgEntry.SetCurrentKey("Order Type", "Job No.", "Order Line No.", "Entry Type");
        ItemLedgEntry.SetRange("Order Type", ItemLedgEntry."Order Type"::" ");
        ItemLedgEntry.SetRange("Job No.", ID);
        ItemLedgEntry.SetRange("Order Line No.", RefNo);

        if Type = Database::"Job Planning Line" then
            ItemLedgEntry.SetRange("Entry Type", ItemLedgEntry."Entry Type"::"Negative Adjmt.")
        else
            exit(false);

        if ItemLedgEntry.FindSet() then
            repeat
                if ItemLedgEntry.TrackingExists() then begin
                    TempItemLedgEntry := ItemLedgEntry;
                    TempItemLedgEntry.Insert();
                end
            until ItemLedgEntry.Next() = 0;
        Window.Close();
        if TempItemLedgEntry.IsEmpty() then
            exit(false);

        PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
        exit(true);
    end;

    procedure ShowItemTrackingForShptRcptLine(Type: Integer; Subtype: Integer; ID: Code[20]; BatchName: Code[10]; ProdOrderLine: Integer; RefNo: Integer): Boolean
    var
        TempItemLedgEntry: Record "Item Ledger Entry" temporary;
    begin
        RetrieveEntriesFromShptRcpt(TempItemLedgEntry, Type, Subtype, ID, BatchName, ProdOrderLine, RefNo);
        if not TempItemLedgEntry.IsEmpty() then begin
            PAGE.RunModal(PAGE::"Posted Item Tracking Lines", TempItemLedgEntry);
            exit(true);
        end;
        exit(false);
    end;

    procedure TableSignFactor(TableNo: Integer): Integer
    var
        Sign: Integer;
    begin
        if TableNo in [
                       Database::"Sales Line",
                       Database::"Sales Shipment Line",
                       Database::"Sales Invoice Line",
                       Database::"Purch. Cr. Memo Line",
                       Database::"Transfer Shipment Line",
                       Database::"Return Shipment Line",
                       Database::"Invt. Shipment Line",
                       Database::"Planning Component"]
        then
            exit(-1);

        OnAfterTableSignFactor(TableNo, Sign);
        if Sign <> 0 then
            exit(Sign);

        exit(1);
    end;

    local procedure TableSignFactor2(RowID: Text[250]): Integer
    var
        TableNo: Integer;
    begin
        RowID := DelChr(RowID, '<', '"');
        RowID := CopyStr(RowID, 1, StrPos(RowID, '"') - 1);
        if Evaluate(TableNo, RowID) then
            exit(TableSignFactor(TableNo));

        exit(1);
    end;

    procedure CreateTrackingInfo(TableID: Integer; DocumentType: Integer; DocumentNo: Code[20])
    var
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        SerialNoInfo: Record "Serial No. Information";
        LotNoInfo: Record "Lot No. Information";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        Inbound: Boolean;
    begin
        RetrieveDocumentItemTracking(TempTrackingSpecification, DocumentNo, TableID, DocumentType);

        Inbound := TableSignFactor(DocumentType) > 0;
        if TempTrackingSpecification.FindSet() then
            repeat
                Item.Get(TempTrackingSpecification."Item No.");
                ItemTrackingCode.Get(Item."Item Tracking Code");
                if ((Inbound and ItemTrackingCode."SN Info. Inbound Must Exist") or
                    (not Inbound and ItemTrackingCode."SN Info. Outbound Must Exist")) and (TempTrackingSpecification."Serial No." <> '')
                then
                    if not SerialNoInfo.Get(TempTrackingSpecification."Item No.", TempTrackingSpecification."Variant Code", TempTrackingSpecification."Serial No.") then begin
                        SerialNoInfo.Init();
                        SerialNoInfo."Item No." := TempTrackingSpecification."Item No.";
                        SerialNoInfo."Variant Code" := TempTrackingSpecification."Variant Code";
                        SerialNoInfo."Serial No." := TempTrackingSpecification."Serial No.";
                        SerialNoInfo.Insert();
                    end;
                if ((Inbound and ItemTrackingCode."Lot Info. Inbound Must Exist") or
                    (not Inbound and ItemTrackingCode."Lot Info. Outbound Must Exist")) and (TempTrackingSpecification."Lot No." <> '')
                then
                    if not LotNoInfo.Get(TempTrackingSpecification."Item No.", TempTrackingSpecification."Variant Code", TempTrackingSpecification."Lot No.") then begin
                        LotNoInfo.Init();
                        LotNoInfo."Item No." := TempTrackingSpecification."Item No.";
                        LotNoInfo."Variant Code" := TempTrackingSpecification."Variant Code";
                        LotNoInfo."Lot No." := TempTrackingSpecification."Lot No.";
                        LotNoInfo.Insert();
                    end;
                OnCreateTrackingInformationOnAfterTrackingSpecLoop(TempTrackingSpecification, ItemTrackingCode, Inbound);
            until TempTrackingSpecification.Next() = 0;
    end;

    local procedure CreateLineTrkgFromReservation(ItemNo: Code[20]; Type: Integer; Subtype: Integer; DocNo: Code[20]; LineNo: Integer)
    var
        ReservEntryFor: Record "Reservation Entry";
        ReservEntryFrom: Record "Reservation Entry";
        Item: Record Item;
        ItemTrackingCode: Record "Item Tracking Code";
        ItemTrackingSetup: Record "Item Tracking Setup";
    begin
        Item.Get(ItemNo);
        if Item."Item Tracking Code" <> '' then begin
            ItemTrackingCode.Code := Item."Item Tracking Code";
            ItemTrackingMgt.GetItemTrackingSetup(
                ItemTrackingCode, Enum::"Item Ledger Entry Type"::" ", false, ItemTrackingSetup);
            if ItemTrackingSetup.TrackingRequired() then begin
                ReservEntryFor.Reset();
                ReservEntryFor.SetSourceFilter(Type, Subtype, DocNo, LineNo, true);
                if ReservEntryFor.FindSet() then
                    repeat
                        ReservEntryFrom.Get(ReservEntryFor."Entry No.", not ReservEntryFor.Positive);
                        ReservEntryFor.CopyTrackingFromReservEntry(ReservEntryFrom);
                        ReservEntryFor.UpdateItemTracking();
                        ReservEntryFor.Modify();
                    until ReservEntryFor.Next() = 0;
            end;
        end;
    end;

    procedure CopyDocTrkgFromReservation(SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; HideDialog: Boolean)
    var
        SalesLine: Record "Sales Line";
        TransLine: Record "Transfer Line";
        InvtDocLine: Record "Invt. Document Line";
    begin
        if not HideDialog then
            if not Confirm(CreateTrackingSpecQst, true) then
                exit;

        case SourceType of
            Database::"Sales Header":
                begin
                    SalesLine.SetRange("Document Type", SourceSubtype);
                    SalesLine.SetRange("Document No.", SourceID);
                    SalesLine.SetRange(Type, SalesLine.Type::Item);
                    if SalesLine.FindSet() then
                        repeat
                            CreateLineTrkgFromReservation(
                              SalesLine."No.", Database::"Sales Line", SourceSubtype, SourceID, SalesLine."Line No.");
                        until SalesLine.Next() = 0;
                end;
            Database::"Transfer Header":
                begin
                    TransLine.SetRange("Document No.", SourceID);
                    if TransLine.FindSet() then
                        repeat
                            CreateLineTrkgFromReservation(
                              TransLine."Item No.", Database::"Transfer Line", SourceSubtype, SourceID, TransLine."Line No.")
                        until TransLine.Next() = 0;
                end;
            Database::"Invt. Document Header":
                begin
                    InvtDocLine.SetRange("Document No.", SourceID);
                    if InvtDocLine.FindSet() then
                        repeat
                            CreateLineTrkgFromReservation(
                              InvtDocLine."Item No.", Database::"Invt. Document Line", SourceSubtype, SourceID, InvtDocLine."Line No.");
                        until InvtDocLine.Next() = 0;
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddTempRecordToSetOnAfterTempItemLedgEntrySetFilters(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; TempItemLedgEntry2: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddTempRecordToSetOnAfterApplySignFactor(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; SignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddTempRecordToSetOnBeforeTempItemLedgEntryModify(var TempItemLedgEntry: Record "Item Ledger Entry" temporary; TempItemLedgEntry2: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAddTempRecordToSetOnAfterRetrieveAppliedExpirationDate(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAddTempRecordToSet(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempItemLedgerEntry2: Record "Item Ledger Entry" temporary; SignFactor: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTrackingSpecBufferFromItemLedgEntry(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TempItemLedgerEntry: Record "Item Ledger Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTrackingSpecBufferFromReservEntry(var TempTrackingSpecification: Record "Tracking Specification" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFillTrackingSpecBufferFromTrackingEntries(var TempTrackingSpecification: Record "Tracking Specification" temporary; var TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRetrieveDocumentItemTracking(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; SourceType: Integer; SourceSubType: Option; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRetrieveDocumentItemTracking(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary; SourceID: Code[20]; var Found: Boolean; SourceType: Integer; SourceSubType: Option; RetrieveAsmItemTracking: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveEntriesFromPostedInvOnBeforeAddTempRecordToSet(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; ValueEntry: Record "Value Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingPurchaseOnAfterSetFilters(var PurchaseLine: Record "Purchase Line"; SourceID: Code[20]; SourceSubType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingPurchaseReceiptOnAfterSetFilters(var PurchRcptLine: Record "Purch. Rcpt. Line"; SourceID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingPurchCrMemoHeaderOnAfterSetFilters(var PurchCrMemoLine: Record "Purch. Cr. Memo Line"; SourceID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingPurhInvHeaderOnAfterSetFilters(var PurchInvLine: Record "Purch. Inv. Line"; SourceID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingSalesOnAfterSetFilters(var SalesLine: Record "Sales Line"; SourceID: Code[20]; SourceSubType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingSalesCrMemoHeaderOnAfterSetFilters(var SalesCrMemoLine: Record "Sales Cr.Memo Line"; SourceID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingSalesInvoiceOnAfterSetFilters(var SalesInvoiceLine: Record "Sales Invoice Line"; SourceID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRetrieveTrackingSalesShipmentOnAfterSetFilters(var SalesShipmentLine: Record "Sales Shipment Line"; SourceID: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectItemTrkgPerPostedDocLineOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; var TempReservationEntry: Record "Reservation Entry" temporary; ItemLedgerEntry: Record "Item Ledger Entry"; FromPurchase: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTrackingInformationOnAfterTrackingSpecLoop(TrackingSpecification: Record "Tracking Specification"; ItemTrackingCode: Record "Item Tracking Code"; Inbound: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackingExistsInBufferOnAfterTempTrackingSpecBufferSetFilters(var TempTrackingSpecBuffer: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowItemTrackingForEntityOnBeforeTempItemLedgEntryInsert(var TempItemLedgerEntry: Record "Item Ledger Entry" temporary; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTableSignFactor(TableNo: Integer; var Sign: Integer);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnRetrieveTrackingSalesShipmentForAssembly(SalesShipmentLine: Record "Sales Shipment Line"; var TempTrackingSpecBuffer: Record "Tracking Specification" temporary)
    begin
    end;
}

