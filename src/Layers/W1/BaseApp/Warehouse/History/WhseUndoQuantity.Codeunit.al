// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.History;

using Microsoft.Assembly.History;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;

codeunit 7320 "Whse. Undo Quantity"
{
    Permissions = TableData "Whse. Item Entry Relation" = md,
                  TableData "Posted Whse. Shipment Line" = rimd;
    TableNo = "Item Journal Line";

    trigger OnRun()
    begin
    end;

    var
        WhseJnlRegisterLine: Codeunit "Whse. Jnl.-Register Line";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'Assertion failed, %1.';
#pragma warning restore AA0470
        Text001: Label 'There is not enough space to insert correction lines.';
#pragma warning restore AA0074

    procedure InsertTempWhseJnlLine(ItemJnlLine: Record "Item Journal Line"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; RefDoc: Integer; var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var NextLineNo: Integer)
    var
        WarehouseEntry: Record "Warehouse Entry";
        WhseManagement: Codeunit "Whse. Management";
        WMSManagement: Codeunit "WMS Management";
    begin
        WarehouseEntry.SetSourceFilter(SourceType, SourceSubType, SourceNo, SourceLineNo, true);
        WarehouseEntry.SetRange("Reference No.", ItemJnlLine."Document No.");
        WarehouseEntry.SetRange("Item No.", ItemJnlLine."Item No.");
        OnInsertTempWhseJnlLineOnAfterWhseEntrySetFilters(ItemJnlLine, SourceType, SourceSubType, SourceNo, SourceLineNo, RefDoc, WarehouseEntry);
        if WarehouseEntry.Find('+') then
            repeat
                TempWhseJnlLine.Init();
                OnInsertTempWhseJnlLineOnAfterTempWhseJnlLineInit(ItemJnlLine, WarehouseEntry, TempWhseJnlLine);
                if WarehouseEntry."Entry Type" = WarehouseEntry."Entry Type"::"Positive Adjmt." then
                    ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Negative Adjmt."
                else
                    ItemJnlLine."Entry Type" := ItemJnlLine."Entry Type"::"Positive Adjmt.";
                ItemJnlLine.Quantity := Abs(WarehouseEntry.Quantity);
                ItemJnlLine."Quantity (Base)" := Abs(WarehouseEntry."Qty. (Base)");
                ItemJnlLine."Qty. per Unit of Measure" := WarehouseEntry."Qty. per Unit of Measure";
                OnInsertTempWhseJnlLineOnBeforeCreateWhseJnlLine(ItemJnlLine);
                WMSManagement.CreateWhseJnlLine(ItemJnlLine, 0, TempWhseJnlLine, false);
                TempWhseJnlLine.SetSource(SourceType, SourceSubType, SourceNo, SourceLineNo, 0);
                TempWhseJnlLine."Source Document" :=
                  WhseManagement.GetWhseJnlSourceDocument(TempWhseJnlLine."Source Type", TempWhseJnlLine."Source Subtype");
                TempWhseJnlLine."Reference Document" := Enum::"Whse. Reference Document Type".FromInteger(RefDoc);
                TempWhseJnlLine."Reference No." := ItemJnlLine."Document No.";
                TempWhseJnlLine."Location Code" := ItemJnlLine."Location Code";
                TempWhseJnlLine."Zone Code" := WarehouseEntry."Zone Code";
                TempWhseJnlLine."Bin Code" := WarehouseEntry."Bin Code";
                TempWhseJnlLine.SetWhseDocument(WarehouseEntry."Whse. Document Type", WarehouseEntry."Whse. Document No.", 0);
                TempWhseJnlLine."Unit of Measure Code" := WarehouseEntry."Unit of Measure Code";
                TempWhseJnlLine."Line No." := NextLineNo;
                TempWhseJnlLine.CopyTrackingFromWhseEntry(WarehouseEntry);
                TempWhseJnlLine."Expiration Date" := WarehouseEntry."Expiration Date";
                if ItemJnlLine."Entry Type" = ItemJnlLine."Entry Type"::"Negative Adjmt." then begin
                    TempWhseJnlLine."From Zone Code" := TempWhseJnlLine."Zone Code";
                    TempWhseJnlLine."From Bin Code" := TempWhseJnlLine."Bin Code";
                end else begin
                    TempWhseJnlLine."To Zone Code" := TempWhseJnlLine."Zone Code";
                    TempWhseJnlLine."To Bin Code" := TempWhseJnlLine."Bin Code";
                end;
                OnBeforeTempWhseJnlLineInsert(TempWhseJnlLine, WarehouseEntry, ItemJnlLine);
                TempWhseJnlLine.Insert();
                NextLineNo := TempWhseJnlLine."Line No." + 10000;
            until WarehouseEntry.Next(-1) = 0;
    end;

    procedure PostTempWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
        PostTempWhseJnlLineCache(TempWhseJnlLine, WhseJnlRegisterLine);
    end;

    procedure PostTempWhseJnlLineCache(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary; var WhseJnlRegLine: Codeunit "Whse. Jnl.-Register Line")
    begin
        OnBeforePostTempWhseJnlLine(TempWhseJnlLine);
        if TempWhseJnlLine.Find('-') then
            repeat
                OnPostTempWhseJnlLineCacheOnBeforeRegisterWhseJnlLine(TempWhseJnlLine);
                WhseJnlRegLine.RegisterWhseJnlLine(TempWhseJnlLine);
            until TempWhseJnlLine.Next() = 0;

        OnAfterPostTempWhseJnlLineCache(TempWhseJnlLine);
    end;

    procedure UndoPostedWhseRcptLine(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        PostedWhseRcptLine.TestField("Source Type");
        InsertPostedWhseRcptLine(PostedWhseRcptLine);
        DeleteWhsePutAwayRequest(PostedWhseRcptLine);
        DeleteWhseItemEntryRelationRcpt(PostedWhseRcptLine);

        OnAfterUndoPostedWhseRcptLine(PostedWhseRcptLine);
    end;

    procedure UndoPostedWhseShptLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
        PostedWhseShptLine.TestField("Source Type");
        InsertPostedWhseShptLine(PostedWhseShptLine);
        DeleteWhsePickRequest(PostedWhseShptLine);
        DeleteWhseItemEntryRelationShpt(PostedWhseShptLine);

        OnAfterUndoPostedWhseShptLine(PostedWhseShptLine);
    end;

    procedure UpdateRcptSourceDocLines(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        UpdateWhseRcptLine(PostedWhseRcptLine);
        UpdateWhseRequestRcpt(PostedWhseRcptLine);
    end;

    procedure UpdateShptSourceDocLines(var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
        UpdateWhseShptLine(PostedWhseShptLine);
        UpdateWhseRequestShpt(PostedWhseShptLine);
    end;

    procedure FindPostedWhseRcptLine(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; UndoType: Integer; UndoID: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer) Ok: Boolean
    var
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPostedWhseRcptLine(PostedWhseRcptLine, UndoType, UndoID, SourceType, SourceSubtype, SourceID, SourceRefNo, Ok, IsHandled);
        if IsHandled then
            exit(Ok);

        if not PostedWhseRcptLine.ReadPermission then
            exit;
        PostedWhseRcptLine.Reset();
        case UndoType of
            Database::"Purch. Rcpt. Line":
                PostedWhseRcptLine.SetRange("Posted Source Document", PostedWhseRcptLine."Posted Source Document"::"Posted Receipt");
            Database::"Return Receipt Line":
                PostedWhseRcptLine.SetRange("Posted Source Document", PostedWhseRcptLine."Posted Source Document"::"Posted Return Receipt");
            else
                exit;
        end;
        WhseManagement.SetSourceFilterForPostedWhseRcptLine(PostedWhseRcptLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        PostedWhseRcptLine.SetRange("Posted Source No.", UndoID);
        OnFindPostedWhseRcptLineOnAfterSetFilters(PostedWhseRcptLine);
        if PostedWhseRcptLine.FindFirst() then begin
            if PostedWhseRcptLine.Count > 1 then
                Error(Text000, PostedWhseRcptLine.TableCaption);
            // Assert: only one posted line.
            Ok := true;
        end;
    end;

    procedure FindPostedWhseShptLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; UndoType: Integer; UndoID: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer) Ok: Boolean
    var
        PostedWhseShptLine2: Record "Posted Whse. Shipment Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindPostedWhseShptLine(PostedWhseShptLine, UndoType, UndoID, SourceType, SourceSubtype, SourceID, SourceRefNo, Ok, IsHandled);
        if IsHandled then
            exit(Ok);

        if not PostedWhseShptLine.ReadPermission then
            exit;
        PostedWhseShptLine.Reset();
        case true of
            IsShipmentLine(UndoType):
                PostedWhseShptLine.SetRange("Posted Source Document", PostedWhseShptLine."Posted Source Document"::"Posted Shipment");
            UndoType = Database::"Return Shipment Line":
                PostedWhseShptLine.SetRange("Posted Source Document", PostedWhseShptLine."Posted Source Document"::"Posted Return Shipment");
            UndoType = Database::"Transfer Shipment Line":
                PostedWhseShptLine.SetRange("Posted Source Document", PostedWhseShptLine."Posted Source Document"::"Posted Transfer Shipment");
            else
                exit;
        end;
        WhseManagement.SetSourceFilterForPostedWhseShptLine(PostedWhseShptLine, SourceType, SourceSubtype, SourceID, SourceRefNo, true);
        PostedWhseShptLine.SetRange("Posted Source No.", UndoID);
        OnFindPostedWhseShptLineOnAfterSetFilters(PostedWhseShptLine);
        if PostedWhseShptLine.FindFirst() then begin
            PostedWhseShptLine2.CopyFilters(PostedWhseShptLine);
            PostedWhseShptLine2.SetFilter("No.", '<>%1', PostedWhseShptLine."No.");
            PostedWhseShptLine2.SetFilter("Line No.", '<>%1', PostedWhseShptLine."Line No.");
            if not PostedWhseShptLine2.IsEmpty() and not IsATO(UndoType, UndoID, SourceRefNo) then
                Error(Text000, PostedWhseShptLine.TableCaption);
            // Assert: only one posted line.
            Ok := true;
        end;
    end;

    local procedure IsShipmentLine(UndoType: Integer) IsSalesShipment: Boolean
    begin
        IsSalesShipment := UndoType = Database::"Sales Shipment Line";
        OnAfterIsShipmentLine(UndoType, IsSalesShipment);
    end;

    local procedure InsertPostedWhseRcptLine(OldPostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        NewPostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        LineSpacing: Integer;
    begin
        OldPostedWhseRcptLine."Qty. Put Away" := OldPostedWhseRcptLine.Quantity;
        OldPostedWhseRcptLine."Qty. Put Away (Base)" := OldPostedWhseRcptLine."Qty. (Base)";
        OnBeforeOldPostedWhseRcptLineModify(OldPostedWhseRcptLine);
        OldPostedWhseRcptLine.Modify();

        NewPostedWhseRcptLine.SetRange("No.", OldPostedWhseRcptLine."No.");
        NewPostedWhseRcptLine."No." := OldPostedWhseRcptLine."No.";
        NewPostedWhseRcptLine."Line No." := OldPostedWhseRcptLine."Line No.";
        NewPostedWhseRcptLine.Find('=');

        LineSpacing := GetWhseRcptLineSpacing(OldPostedWhseRcptLine, NewPostedWhseRcptLine);

        NewPostedWhseRcptLine.Reset();
        NewPostedWhseRcptLine.Init();
        NewPostedWhseRcptLine.Copy(OldPostedWhseRcptLine);
        NewPostedWhseRcptLine."Line No." := OldPostedWhseRcptLine."Line No." + LineSpacing;
        NewPostedWhseRcptLine.Quantity := -OldPostedWhseRcptLine.Quantity;
        NewPostedWhseRcptLine."Qty. (Base)" := -OldPostedWhseRcptLine."Qty. (Base)";
        NewPostedWhseRcptLine."Qty. Put Away" := -OldPostedWhseRcptLine."Qty. Put Away";
        NewPostedWhseRcptLine."Qty. Put Away (Base)" := -OldPostedWhseRcptLine."Qty. Put Away (Base)";
        NewPostedWhseRcptLine.Status := NewPostedWhseRcptLine.Status::"Completely Put Away";
        OnBeforePostedWhseRcptLineInsert(NewPostedWhseRcptLine, OldPostedWhseRcptLine, LineSpacing);
        NewPostedWhseRcptLine.Insert();

        OldPostedWhseRcptLine.Status := OldPostedWhseRcptLine.Status::"Completely Put Away";
        OldPostedWhseRcptLine.Modify();
    end;

    local procedure GetWhseRcptLineSpacing(OldPostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var NewPostedWhseRcptLine: Record "Posted Whse. Receipt Line") LineSpacing: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetWhseRcptLineSpacing(OldPostedWhseRcptLine, NewPostedWhseRcptLine, LineSpacing, IsHandled);
        if IsHandled then
            exit(LineSpacing);

        if NewPostedWhseRcptLine.Find('>') then begin
            LineSpacing := (NewPostedWhseRcptLine."Line No." - OldPostedWhseRcptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text001);
        end else
            LineSpacing := 10000;
    end;

    procedure InsertPostedWhseShptLine(OldPostedWhseShptLine: Record "Posted Whse. Shipment Line")
    var
        NewPostedWhseShptLine: Record "Posted Whse. Shipment Line";
        LineSpacing: Integer;
    begin
        NewPostedWhseShptLine.SetRange("No.", OldPostedWhseShptLine."No.");
        NewPostedWhseShptLine."No." := OldPostedWhseShptLine."No.";
        NewPostedWhseShptLine."Line No." := OldPostedWhseShptLine."Line No.";
        NewPostedWhseShptLine.Find('=');

        LineSpacing := GetWhseShptLineSpacing(OldPostedWhseShptLine, NewPostedWhseShptLine);

        NewPostedWhseShptLine.Reset();
        NewPostedWhseShptLine.Init();
        NewPostedWhseShptLine.Copy(OldPostedWhseShptLine);
        NewPostedWhseShptLine."Line No." := OldPostedWhseShptLine."Line No." + LineSpacing;
        NewPostedWhseShptLine.Quantity := -OldPostedWhseShptLine.Quantity;
        NewPostedWhseShptLine."Qty. (Base)" := -OldPostedWhseShptLine."Qty. (Base)";
        OnBeforePostedWhseShptLineInsert(NewPostedWhseShptLine, OldPostedWhseShptLine, LineSpacing);
        NewPostedWhseShptLine.Insert();
    end;

    local procedure GetWhseShptLineSpacing(OldPostedWhseShptLine: Record "Posted Whse. Shipment Line"; var NewPostedWhseShptLine: Record "Posted Whse. Shipment Line") LineSpacing: Integer
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetWhseShptLineSpacing(OldPostedWhseShptLine, NewPostedWhseShptLine, LineSpacing, IsHandled);
        if IsHandled then
            exit(LineSpacing);

        if NewPostedWhseShptLine.Find('>') then begin
            LineSpacing := (NewPostedWhseShptLine."Line No." - OldPostedWhseShptLine."Line No.") div 2;
            if LineSpacing = 0 then
                Error(Text001);
        end else
            LineSpacing := 10000;
    end;

    local procedure DeleteWhsePutAwayRequest(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        WhsePutAwayRequest: Record "Whse. Put-away Request";
    begin
        PostedWhseReceiptLine.SetRange("No.", PostedWhseRcptLine."No.");
        PostedWhseReceiptLine.CalcSums("Qty. Put Away");
        if PostedWhseReceiptLine."Qty. (Base)" = 0 then begin
            WhsePutAwayRequest.SetRange("Document Type", WhsePutAwayRequest."Document Type"::Receipt);
            WhsePutAwayRequest.SetRange("Document No.", PostedWhseRcptLine."No.");
            WhsePutAwayRequest.DeleteAll();
        end;
    end;

    local procedure DeleteWhsePickRequest(var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    var
        PostedWhseShipmentLine: Record "Posted Whse. Shipment Line";
        WhsePickRequest: Record "Whse. Pick Request";
    begin
        PostedWhseShipmentLine.SetRange("No.", PostedWhseShptLine."No.");
        PostedWhseShipmentLine.CalcSums("Qty. (Base)");
        if PostedWhseShipmentLine."Qty. (Base)" = 0 then begin
            WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
            WhsePickRequest.SetRange("Document No.", PostedWhseShptLine."No.");
            if not WhsePickRequest.IsEmpty() then
                WhsePickRequest.DeleteAll();
        end;
    end;

    local procedure UpdateWhseRcptLine(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        WhseRcptHeader: Record "Warehouse Receipt Header";
        WhseRcptLine: Record "Warehouse Receipt Line";
        WhseManagement: Codeunit "Whse. Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseRcptLine(PostedWhseRcptLine, IsHandled);
        if IsHandled then
            exit;

        WhseManagement.SetSourceFilterForWhseRcptLine(WhseRcptLine, PostedWhseRcptLine."Source Type", PostedWhseRcptLine."Source Subtype", PostedWhseRcptLine."Source No.", PostedWhseRcptLine."Source Line No.", true);
        if WhseRcptLine.FindFirst() then begin
            WhseRcptLine.Validate("Qty. Received", WhseRcptLine."Qty. Received" - PostedWhseRcptLine.Quantity);
            WhseRcptLine.Validate("Qty. Outstanding", WhseRcptLine."Qty. Outstanding" + PostedWhseRcptLine.Quantity);
            if WhseRcptLine."Qty. Received" = 0 then begin
                WhseRcptLine.Status := WhseRcptLine.Status::" ";
                WhseRcptHeader.Get(WhseRcptLine."No.");
                WhseRcptHeader."Document Status" := WhseRcptHeader."Document Status"::" ";
                WhseRcptHeader.Modify();
            end;
            OnBeforeWhseRcptLineModify(WhseRcptLine, PostedWhseRcptLine);
            WhseRcptLine.Modify();
        end;

        OnAfterUpdateWhseRcptLine(PostedWhseRcptLine, WhseRcptLine);
    end;

    local procedure UpdateWhseShptLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        WhseShptLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseShptLine(PostedWhseShptLine, IsHandled);
        if IsHandled then
            exit;

        WhseShptLine.SetSourceFilter(PostedWhseShptLine."Source Type", PostedWhseShptLine."Source Subtype", PostedWhseShptLine."Source No.", PostedWhseShptLine."Source Line No.", true);
        if WhseShptLine.FindFirst() then begin
            if WhseShptLine."Qty. Shipped" <> 0 then begin
                WhseShptLine.Validate("Qty. Shipped", WhseShptLine."Qty. Shipped" - PostedWhseShptLine.Quantity);
                WhseShptLine.Validate("Qty. Outstanding", WhseShptLine."Qty. Outstanding" + PostedWhseShptLine.Quantity);
            end else
                WhseShptLine.Validate(Quantity, WhseShptLine.Quantity + PostedWhseShptLine.Quantity);

            if WhseShptLine."Qty. Shipped" = 0 then begin
                WhseShptLine.Status := WhseShptLine.Status::" ";
                WhseShptHeader.Get(WhseShptLine."No.");
                WhseShptHeader."Document Status" := WhseShptHeader."Document Status"::" ";
                WhseShptHeader.Modify();
            end;
            OnBeforeWhseShptLineModify(WhseShptLine, PostedWhseShptLine);
            WhseShptLine.Modify();
        end;
    end;

    local procedure DeleteWhseItemEntryRelationRcpt(NewPostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    begin
        DeleteWhseItemEntryRelation(Database::"Posted Whse. Receipt Line", NewPostedWhseRcptLine."No.", NewPostedWhseRcptLine."Line No.");
    end;

    local procedure DeleteWhseItemEntryRelationShpt(NewPostedWhseShptLine: Record "Posted Whse. Shipment Line")
    begin
        DeleteWhseItemEntryRelation(Database::"Posted Whse. Shipment Line", NewPostedWhseShptLine."No.", NewPostedWhseShptLine."Line No.");
    end;

    local procedure DeleteWhseItemEntryRelation(SourceType: Integer; SourceNo: Code[20]; SourceLineNo: Integer)
    var
        WhseItemEntryRelation: Record "Whse. Item Entry Relation";
    begin
        WhseItemEntryRelation.SetSourceFilter(SourceType, 0, SourceNo, SourceLineNo, true);
        WhseItemEntryRelation.DeleteAll();
    end;

    local procedure UpdateWhseRequestRcpt(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line")
    var
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
    begin
        case PostedWhseRcptLine."Source Type" of
            Database::"Purchase Line":
                begin
                    PurchLine.Get(PostedWhseRcptLine."Source Subtype", PostedWhseRcptLine."Source No.", PostedWhseRcptLine."Source Line No.");
                    if not (PurchLine."Quantity Received" < PurchLine.Quantity) then
                        exit;
                end;
            Database::"Sales Line":
                begin
                    SalesLine.Get(PostedWhseRcptLine."Source Subtype", PostedWhseRcptLine."Source No.", PostedWhseRcptLine."Source Line No.");
                    if not (SalesLine."Return Qty. Received" < SalesLine.Quantity) then
                        exit;
                end;
        end;
        UpdateWhseRequest(PostedWhseRcptLine."Source Type", PostedWhseRcptLine."Source Subtype", PostedWhseRcptLine."Source No.", PostedWhseRcptLine."Location Code");

        OnAfterUpdateWhseRequestRcpt(PostedWhseRcptLine);
    end;

    local procedure UpdateWhseRequestShpt(var PostedWhseShptLine: Record "Posted Whse. Shipment Line")
    var
        PurchLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateWhseRequestShpt(PostedWhseShptLine, IsHandled);
        if IsHandled then
            exit;

        case PostedWhseShptLine."Source Type" of
            Database::"Sales Line":
                begin
                    SalesLine.Get(PostedWhseShptLine."Source Subtype", PostedWhseShptLine."Source No.", PostedWhseShptLine."Source Line No.");
                    if not (SalesLine."Quantity Shipped" < SalesLine.Quantity) then
                        exit;
                end;
            Database::"Purchase Line":
                begin
                    PurchLine.Get(PostedWhseShptLine."Source Subtype", PostedWhseShptLine."Source No.", PostedWhseShptLine."Source Line No.");
                    if not (PurchLine."Return Qty. Shipped" < PurchLine.Quantity) then
                        exit;
                end;
            Database::"Transfer Line":
                begin
                    TransferLine.Get(PostedWhseShptLine."Source No.", PostedWhseShptLine."Source Line No.");
                    if not (TransferLine."Quantity Shipped" < TransferLine.Quantity) then
                        exit;
                end;
        end;
        UpdateWhseRequest(PostedWhseShptLine."Source Type", PostedWhseShptLine."Source Subtype", PostedWhseShptLine."Source No.", PostedWhseShptLine."Location Code");

        OnAfterUpdateWhseRequestShpt(PostedWhseShptLine);
    end;

    local procedure UpdateWhseRequest(SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; LocationCode: Code[10])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange("Source Type", SourceType);
        WarehouseRequest.SetRange("Source Subtype", SourceSubType);
        WarehouseRequest.SetRange("Source No.", SourceNo);
        WarehouseRequest.SetRange("Location Code", LocationCode);
        if WarehouseRequest.FindFirst() and WarehouseRequest."Completely Handled" then begin
            WarehouseRequest."Completely Handled" := false;
            WarehouseRequest.Modify();
        end;
    end;

    local procedure IsATO(UndoType: Integer; UndoID: Code[20]; SourceRefNo: Integer): Boolean
    var
        PostedATOLink: Record "Posted Assemble-to-Order Link";
    begin
        if UndoType = Database::"Sales Shipment Line" then begin
            PostedATOLink.SetRange("Document Type", PostedATOLink."Document Type"::"Sales Shipment");
            PostedATOLink.SetRange("Document No.", UndoID);
            PostedATOLink.SetRange("Document Line No.", SourceRefNo);
            exit(not PostedATOLink.IsEmpty);
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostTempWhseJnlLineCache(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoPostedWhseRcptLine(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUndoPostedWhseShptLine(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseRequestRcpt(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseRequestShpt(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWhseShptLineSpacing(OldPostedWhseShptLine: Record "Posted Whse. Shipment Line"; var NewPostedWhseShptLine: Record "Posted Whse. Shipment Line"; var LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetWhseRcptLineSpacing(OldPostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var NewPostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var LineSpacing: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPostedWhseRcptLine(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; UndoType: Integer; UndoID: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var Ok: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPostedWhseShptLine(var PostedWhseShptLine: Record "Posted Whse. Shipment Line"; UndoType: Integer; UndoID: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceID: Code[20]; SourceRefNo: Integer; var Ok: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOldPostedWhseRcptLineModify(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostTempWhseJnlLine(var TempWhseJnlLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseRcptLineInsert(var NewPostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; OldPostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePostedWhseShptLineInsert(var NewPostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; OldPostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; LineSpacing: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempWhseJnlLineInsert(var WarehouseJournalLine: Record "Warehouse Journal Line"; WarehouseEntry: Record "Warehouse Entry"; ItemJournalLine: Record "Item Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseRequestShpt(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseRcptLineModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseShptLineModify(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPostedWhseRcptLineOnAfterSetFilters(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindPostedWhseShptLineOnAfterSetFilters(var PostedWhseShipmentLine: Record "Posted Whse. Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseRcptLine(var PostedWhseRcptLine: Record "Posted Whse. Receipt Line"; var WhseRcptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempWhseJnlLineOnAfterWhseEntrySetFilters(ItemJnlLine: Record "Item Journal Line"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; RefDoc: Integer; var WhseEntry: Record "Warehouse Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempWhseJnlLineOnAfterTempWhseJnlLineInit(var ItemJnlLine: Record "Item Journal Line"; var WarehouseEntry: Record "Warehouse Entry"; var WarehouseJournalLine: Record "Warehouse Journal Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostTempWhseJnlLineCacheOnBeforeRegisterWhseJnlLine(var TempWarehouseJournalLine: Record "Warehouse Journal Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseRcptLine(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateWhseShptLine(PostedWhseShipmentLine: Record "Posted Whse. Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterIsShipmentLine(UndoType: Integer; var IsShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempWhseJnlLineOnBeforeCreateWhseJnlLine(var ItemJournalLine: Record "Item Journal Line")
    begin
    end;
}

