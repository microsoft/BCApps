// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Projects.Project.Job;
using Microsoft.Projects.Project.Planning;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Availability;
using Microsoft.Warehouse.Comment;
using Microsoft.Warehouse.InternalDocument;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;
using Microsoft.Warehouse.Tracking;
using Microsoft.Warehouse.Worksheet;
using System.Telemetry;

codeunit 7322 "Create Inventory Pick/Movement"
{
    Permissions = TableData "Whse. Item Tracking Line" = rimd;
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        OnBeforeOnRun(Rec);
        CurrWarehouseActivityHeader := Rec;
        Code();
        Rec := CurrWarehouseActivityHeader;
    end;

    var
        CurrWarehouseRequest: Record "Warehouse Request";
        CurrWarehouseActivityHeader: Record "Warehouse Activity Header";
        CurrLocation: Record Location;
        CurrItem: Record Item;
        CurrBin: Record Bin;
        CurrStockKeepingUnit: Record "Stockkeeping Unit";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        TempInternalMovementLine: Record "Internal Movement Line" temporary;
        TempReservationEntry: Record "Reservation Entry" temporary;
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WMSManagement: Codeunit "WMS Management";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SourceDocRecordRef: RecordRef;
        SourceDocRecordVar: Variant;
        ReservedFromStock: Enum "Reservation From Stock";
        VendorDocNo: Code[35];
        FromBinCode: Code[20];
        ExpiredItemMessageText: Text[100];
        PostingDate: Date;
        NextLineNo: Integer;
        LastTempHandlingSpecNo: Integer;
        ATOInvtMovementsCreated: Integer;
        TotalATOInvtMovementsToBeCreated: Integer;
        HideDialog: Boolean;
        CheckLineExist: Boolean;
        AutoCreation: Boolean;
        LineCreated: Boolean;
        CompleteShipment: Boolean;
        PrintDocument: Boolean;
        ShowError: Boolean;
        IsInvtMovement: Boolean;
        IsBlankInvtMovement: Boolean;
        ApplySourceFilters: Boolean;
        HasExpiredItems: Boolean;
        SuppressCommit: Boolean;
        HideDialogForTracking: Boolean;
        NothingToHandleMsg: Label 'There is nothing to handle.';
        QtyNotSufficientOnSalesErr: Label 'Quantity available to pick is not sufficient to fulfill shipping advise %1 for sales line with Document Type %2, Document No. %3, Line No. %4.', Comment = '%1=Shipping advise no., %2=Document Type, %3=Document No., %4=Line No.';
        QtyNotSufficientOnTransferErr: Label 'Quantity available to pick is not sufficient to fulfill shipping advise %1 for transfer line with Document No. %2, Line No. %3.', Comment = '%1=Shipping advise no., %2=Document No., %3=Line No.';
        ActivityCreatedMsg: Label '%1 activity number %2 has been created.', Comment = '%1=Warehouse Activity Type,%2=Warehouse Activity number';
        TrackingNotFullyAppliedMsg: Label '%1 activity number %2 has been created.\\Item tracking lines cannot be fully applied.', Comment = '%1=Warehouse Activity Type,%2=Warehouse Activity No.';
        CreateInvtMvmtQst: Label 'Do you want to create Inventory Movement?';
        BinPolicyTelemetryCategoryTok: Label 'Bin Policy', Locked = true;
        DefaultBinPickPolicyTelemetryTok: Label 'Default Bin Pick Policy in used for inventory pick.', Locked = true;
        RankingBinPickPolicyTelemetryTok: Label 'Bin Ranking Bin Pick Policy in used for inventory pick.', Locked = true;
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    local procedure "Code"()
    var
        IsHandled: Boolean;
        SuppressMessage: Boolean;
    begin
        CurrWarehouseActivityHeader.TestField("No.");
        CurrWarehouseActivityHeader.TestField("Location Code");

        if not HideDialog then
            if not GetWhseRequest(CurrWarehouseRequest) then
                exit;

        IsHandled := false;
        OnBeforeCreatePickOrMoveLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, IsHandled, HideDialog, IsInvtMovement, IsBlankInvtMovement, CompleteShipment);
        if IsHandled then
            exit;

        if not GetSourceDocHeader() then
            exit;

        UpdateWhseActivHeader(CurrWarehouseRequest);

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                CreatePickOrMoveFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                CreatePickOrMoveFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Order":
                CreatePickOrMoveFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                CreatePickOrMoveFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                CreatePickOrMoveFromTransfer(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Job Usage":
                CreatePickOrMoveFromJobPlanning(SourceDocRecordVar);
            else
                OnCreatePickOrMoveFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, LineCreated, CurrWarehouseActivityHeader, CurrLocation, HideDialog,
                    CompleteShipment, CheckLineExist, IsInvtMovement, WarehouseSourceFilter, ApplySourceFilters, ReservedFromStock, SourceDocRecordVar);
        end;

        SuppressMessage := false;
        IsHandled := false;
        OnCodeOnAfterCreatePickOrMoveLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, AutoCreation, SuppressMessage, IsHandled);
        if IsHandled then
            exit;

        if LineCreated then
            ModifyWarehouseActivityHeader(CurrWarehouseActivityHeader, CurrWarehouseRequest)
        else
            if not AutoCreation then
                if not SuppressMessage then
                    Message(NothingToHandleMsg + ExpiredItemMessageText);

        OnAfterCreateInventoryPickMovement(CurrWarehouseRequest, LineCreated, CurrWarehouseActivityHeader);
    end;

    local procedure ModifyWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request")
    begin
        OnBeforeModifyWarehouseActivityHeader(WarehouseActivityHeader, WarehouseRequest, CurrLocation);
        WarehouseActivityHeader.Modify();
    end;

    local procedure GetWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        WarehouseRequest.FilterGroup := 2;
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        if CurrWarehouseActivityHeader."Source Document" <> CurrWarehouseActivityHeader."Source Document"::" " then
            WarehouseRequest.SetRange("Source Document", CurrWarehouseActivityHeader."Source Document")
        else
            if CurrWarehouseActivityHeader.Type = CurrWarehouseActivityHeader.Type::"Invt. Movement" then
                WarehouseRequest.SetFilter("Source Document", '%1|%2|%3|%4',
                  CurrWarehouseActivityHeader."Source Document"::"Prod. Consumption",
                  CurrWarehouseActivityHeader."Source Document"::"Prod. Output",
                  CurrWarehouseActivityHeader."Source Document"::"Assembly Consumption",
                  CurrWarehouseActivityHeader."Source Document"::"Job Usage");
        if CurrWarehouseActivityHeader."Source No." <> '' then
            WarehouseRequest.SetRange("Source No.", CurrWarehouseActivityHeader."Source No.");
        WarehouseRequest.SetRange("Completely Handled", false);
        WarehouseRequest.FilterGroup := 0;

        IsHandled := false;
        OnGetWhseRequestOnBeforeSourceDocumentsRun(WarehouseRequest, CurrWarehouseActivityHeader, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PAGE.RunModal(PAGE::"Source Documents", WarehouseRequest, WarehouseRequest."Source No.") = ACTION::LookupOK then
            exit(true);
    end;

    local procedure GetSourceDocHeader(): Boolean
    var
        Job: Record Job;
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        IsHandled: Boolean;
        RecordExists: Boolean;
    begin
        IsHandled := false;
        RecordExists := true;
        OnBeforeGetSourceDocHeader(CurrWarehouseRequest, IsHandled, RecordExists);
        if IsHandled then
            exit(RecordExists);

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                begin
                    RecordExists := PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, CurrWarehouseRequest."Source No.");
                    PostingDate := PurchaseHeader."Posting Date";
                    VendorDocNo := PurchaseHeader."Vendor Invoice No.";
                    SourceDocRecordVar := PurchaseHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                begin
                    RecordExists := PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", CurrWarehouseRequest."Source No.");
                    PostingDate := PurchaseHeader."Posting Date";
                    VendorDocNo := PurchaseHeader."Vendor Cr. Memo No.";
                    SourceDocRecordVar := PurchaseHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Sales Order":
                begin
                    RecordExists := SalesHeader.Get(SalesHeader."Document Type"::Order, CurrWarehouseRequest."Source No.");
                    PostingDate := SalesHeader."Posting Date";
                    SourceDocRecordVar := SalesHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                begin
                    RecordExists := SalesHeader.Get(SalesHeader."Document Type"::"Return Order", CurrWarehouseRequest."Source No.");
                    PostingDate := SalesHeader."Posting Date";
                    SourceDocRecordVar := SalesHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                begin
                    RecordExists := TransferHeader.Get(CurrWarehouseRequest."Source No.");
                    PostingDate := TransferHeader."Posting Date";
                    SourceDocRecordVar := TransferHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Job Usage":
                begin
                    RecordExists := Job.Get(CurrWarehouseRequest."Source No.");
                    SourceDocRecordVar := Job;
                end;
            else
                OnGetSourceDocHeaderFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, PostingDate, VendorDocNo, RecordExists, SourceDocRecordVar);
        end;
        OnAfterGetSourceDocHeader(CurrWarehouseRequest, PostingDate, VendorDocNo);

        exit(RecordExists);
    end;

    local procedure UpdateWhseActivHeader(WarehouseRequest: Record "Warehouse Request")
    begin
        if CurrWarehouseActivityHeader."Source Document" = CurrWarehouseActivityHeader."Source Document"::" " then begin
            CurrWarehouseActivityHeader."Source Document" := WarehouseRequest."Source Document";
            CurrWarehouseActivityHeader."Source Type" := WarehouseRequest."Source Type";
            CurrWarehouseActivityHeader."Source Subtype" := WarehouseRequest."Source Subtype";
        end else
            CurrWarehouseActivityHeader.TestField("Source Document", WarehouseRequest."Source Document");
        if CurrWarehouseActivityHeader."Source No." = '' then
            CurrWarehouseActivityHeader."Source No." := WarehouseRequest."Source No."
        else
            CurrWarehouseActivityHeader.TestField("Source No.", WarehouseRequest."Source No.");

        CurrWarehouseActivityHeader."Destination Type" := WarehouseRequest."Destination Type";
        CurrWarehouseActivityHeader."Destination No." := WarehouseRequest."Destination No.";
        CurrWarehouseActivityHeader."External Document No." := WarehouseRequest."External Document No.";
        CurrWarehouseActivityHeader."Shipment Date" := WarehouseRequest."Shipment Date";
        CurrWarehouseActivityHeader."Posting Date" := PostingDate;
        CurrWarehouseActivityHeader."External Document No.2" := VendorDocNo;
        GetLocation(WarehouseRequest."Location Code");

        OnAfterUpdateWhseActivHeader(CurrWarehouseActivityHeader, WarehouseRequest, CurrLocation);
    end;

    procedure SetSourceDocDetailsFilter(var WarehouseSourceFilter2: Record "Warehouse Source Filter")
    begin
        if WarehouseSourceFilter2.GetFilters() <> '' then begin
            ApplySourceFilters := true;
            WarehouseSourceFilter.Reset();
            WarehouseSourceFilter.CopyFilters(WarehouseSourceFilter2);
        end;
    end;

    local procedure CreatePickOrMoveFromPurchase(PurchaseHeaderVar: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        PurchaseHeader := PurchaseHeaderVar;

        if not SetFilterPurchLine(PurchaseLine, PurchaseHeader) then begin
            RaiseNothingToHandleMessage();
            exit;
        end;

        FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePickOrMoveLineFromPurchaseLoop(CurrWarehouseActivityHeader, PurchaseHeader, IsHandled, PurchaseLine);

            if not IsHandled and PurchaseLine.IsInventoriableItem() and CanPickPurchaseLine(PurchaseLine) then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, 0) then begin
                    NewWarehouseActivityLine.Init();
                    NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                    NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                    if CurrLocation."Bin Mandatory" then
                        NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                    NewWarehouseActivityLine.SetSource(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0);
                    NewWarehouseActivityLine."Location Code" := PurchaseLine."Location Code";
                    NewWarehouseActivityLine."Bin Code" := PurchaseLine."Bin Code";
                    NewWarehouseActivityLine."Item No." := PurchaseLine."No.";
                    NewWarehouseActivityLine."Variant Code" := PurchaseLine."Variant Code";
                    NewWarehouseActivityLine."Unit of Measure Code" := PurchaseLine."Unit of Measure Code";
                    NewWarehouseActivityLine."Qty. per Unit of Measure" := PurchaseLine."Qty. per Unit of Measure";
                    NewWarehouseActivityLine."Qty. Rounding Precision" := PurchaseLine."Qty. Rounding Precision";
                    NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := PurchaseLine."Qty. Rounding Precision (Base)";
                    NewWarehouseActivityLine.Description := PurchaseLine.Description;
                    NewWarehouseActivityLine."Description 2" := PurchaseLine."Description 2";
                    NewWarehouseActivityLine."Due Date" := PurchaseLine."Expected Receipt Date";
                    NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Vendor;
                    NewWarehouseActivityLine."Destination No." := PurchaseHeader."Buy-from Vendor No.";
                    if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then begin
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Purchase Order";
                        RemQtyToPickBase := -PurchaseLine."Qty. to Receive (Base)";
                    end else begin
                        NewWarehouseActivityLine."Source Document" :=
                          NewWarehouseActivityLine."Source Document"::"Purchase Return Order";
                        RemQtyToPickBase := PurchaseLine."Return Qty. to Ship (Base)";
                    end;
                    OnBeforeNewWhseActivLineInsertFromPurchase(NewWarehouseActivityLine, PurchaseLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                    PurchaseLine.CalcFields(PurchaseLine."Reserved Quantity");
                    CreatePickOrMoveLine(
                      NewWarehouseActivityLine, RemQtyToPickBase, PurchaseLine."Outstanding Qty. (Base)", PurchaseLine."Reserved Quantity" <> 0);
                end;
        until PurchaseLine.Next() = 0;
    end;

    local procedure SetFilterPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if CurrLocation.RequireShipment(CurrWarehouseRequest."Location Code") then
            exit(false);

        PurchaseLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Drop Shipment", false);
        if not CheckLineExist then
            PurchaseLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            PurchaseLine.SetFilter("Qty. to Receive", '<%1', 0)
        else
            PurchaseLine.SetFilter("Return Qty. to Ship", '>%1', 0);

        if ApplySourceFilters then begin
            PurchaseLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            PurchaseLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            PurchaseLine.SetFilter("Planned Receipt Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnBeforeFindPurchLine(PurchaseLine, PurchaseHeader, CurrWarehouseActivityHeader);
        exit(PurchaseLine.Find('-'));
    end;

    local procedure CreatePickOrMoveFromSales(SalesHeaderVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVar;

        OnBeforeCreatePickOrMoveFromSales(CurrWarehouseActivityHeader, SalesHeader, AutoCreation, HideDialog, SalesLine);
        if not SetFilterSalesLine(SalesLine, SalesHeader) then begin
            RaiseNothingToHandleMessage();
            exit;
        end;
        CompleteShipment := true;

        FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePickOrMoveLineFromSalesLoop(CurrWarehouseActivityHeader, SalesHeader, IsHandled, SalesLine);
            if not IsHandled and CanPickSalesLine(SalesLine) then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, 0) then begin
                    NewWarehouseActivityLine.Init();
                    NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                    NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                    if CurrLocation."Bin Mandatory" then
                        NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                    NewWarehouseActivityLine.SetSource(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0);
                    NewWarehouseActivityLine."Location Code" := SalesLine."Location Code";
                    NewWarehouseActivityLine."Bin Code" := SalesLine."Bin Code";
                    NewWarehouseActivityLine."Item No." := SalesLine."No.";
                    NewWarehouseActivityLine."Variant Code" := SalesLine."Variant Code";
                    NewWarehouseActivityLine."Unit of Measure Code" := SalesLine."Unit of Measure Code";
                    NewWarehouseActivityLine."Qty. per Unit of Measure" := SalesLine."Qty. per Unit of Measure";
                    NewWarehouseActivityLine."Qty. Rounding Precision" := SalesLine."Qty. Rounding Precision";
                    NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := SalesLine."Qty. Rounding Precision (Base)";
                    NewWarehouseActivityLine.Description := SalesLine.Description;
                    NewWarehouseActivityLine."Description 2" := SalesLine."Description 2";
                    NewWarehouseActivityLine."Due Date" := SalesLine."Planned Shipment Date";
                    NewWarehouseActivityLine."Shipping Advice" := SalesHeader."Shipping Advice";
                    NewWarehouseActivityLine."Shipping Agent Code" := SalesLine."Shipping Agent Code";
                    NewWarehouseActivityLine."Shipping Agent Service Code" := SalesLine."Shipping Agent Service Code";
                    NewWarehouseActivityLine."Shipment Method Code" := SalesHeader."Shipment Method Code";
                    NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Customer;
                    NewWarehouseActivityLine."Destination No." := SalesHeader."Sell-to Customer No.";

                    if SalesLine."Document Type" = SalesLine."Document Type"::Order then begin
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Order";
                        RemQtyToPickBase := SalesLine."Qty. to Ship (Base)";
                    end else begin
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Return Order";
                        RemQtyToPickBase := -SalesLine."Return Qty. to Receive (Base)";
                    end;
                    OnBeforeNewWhseActivLineInsertFromSales(NewWarehouseActivityLine, SalesLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                    SalesLine.CalcFields(SalesLine."Reserved Quantity");
                    CreatePickOrMoveLine(
                      NewWarehouseActivityLine, RemQtyToPickBase, SalesLine."Outstanding Qty. (Base)", SalesLine."Reserved Quantity" <> 0);
                    OnCreatePickOrMoveFromSalesOnAfterCreatePickOrMoveLine(NewWarehouseActivityLine, SalesLine, CurrWarehouseActivityHeader, ShowError, AutoCreation, LineCreated);
                    CorrectQtyRounding(SalesLine, CurrWarehouseActivityHeader);
                    if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Complete then begin
                        if RemQtyToPickBase < 0 then begin
                            if AutoCreation then begin
                                if CurrWarehouseActivityHeader.Delete(true) then
                                    LineCreated := false;
                                exit;
                            end;
                            Error(QtyNotSufficientOnSalesErr, SalesHeader."Shipping Advice", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
                        end;
                        if (RemQtyToPickBase = 0) and not CompleteShipment then begin
                            if ShowError then
                                Error(QtyNotSufficientOnSalesErr, SalesHeader."Shipping Advice", SalesLine."Document Type", SalesLine."Document No.", SalesLine."Line No.");
                            if CurrWarehouseActivityHeader.Delete(true) then;
                            LineCreated := false;
                            exit;
                        end;
                    end;
                end;
        until SalesLine.Next() = 0;
        OnAfterCreatePickOrMoveFromSales(CurrWarehouseActivityHeader, AutoCreation, HideDialog, LineCreated, IsInvtMovement, IsBlankInvtMovement);
    end;

    local procedure CanPickSalesLine(var SalesLine: Record "Sales Line"): Boolean
    begin
        exit(
          SalesLine.CheckIfSalesLineMeetsReservedFromStockSetting(Abs(SalesLine."Outstanding Qty. (Base)"), ReservedFromStock));
    end;

    local procedure CanPickPurchaseLine(var PurchaseLine: Record "Purchase Line"): Boolean
    begin
        exit(
          PurchaseLine.CheckIfPurchaseLineMeetsReservedFromStockSetting(Abs(PurchaseLine."Outstanding Qty. (Base)"), ReservedFromStock));
    end;

    local procedure CanPickTransferLine(var TransferLine: Record "Transfer Line"): Boolean
    begin
        exit(
          TransferLine.CheckIfTransferLineMeetsReservedFromStockSetting(TransferLine."Outstanding Qty. (Base)", ReservedFromStock));
    end;

    local procedure CanPickJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"): Boolean
    begin
        exit(
          JobPlanningLine.CheckIfJobPlngLineMeetsReservedFromStockSetting(JobPlanningLine."Remaining Qty. (Base)", ReservedFromStock));
    end;

    local procedure SetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header") Result: Boolean
    begin
        if CurrLocation.RequireShipment(CurrWarehouseRequest."Location Code") then
            exit(false);

        SalesLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Drop Shipment", false);

        if not CheckLineExist then
            SalesLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesLine.SetFilter("Qty. to Ship", '>%1', 0)
        else
            SalesLine.SetFilter("Return Qty. to Receive", '<%1', 0);

        if ApplySourceFilters then begin
            SalesLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            SalesLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            SalesLine.SetFilter("Shipment Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnBeforeFindSalesLine(SalesLine, SalesHeader, CurrWarehouseActivityHeader, CurrWarehouseRequest, CheckLineExist);
        Result := SalesLine.Find('-');
        OnAfterSetFilterSalesLine(SalesLine, SalesHeader, CurrWarehouseActivityHeader, CurrWarehouseRequest, ShowError, Result);
    end;

    local procedure CreatePickOrMoveFromTransfer(TransferHeaderVar: Variant)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        TransferHeader := TransferHeaderVar;

        if not SetFilterTransferLine(TransferLine, TransferHeader) then begin
            RaiseNothingToHandleMessage();
            exit;
        end;
        CompleteShipment := true;

        FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePickOrMoveLineFromTransferLoop(CurrWarehouseActivityHeader, TransferHeader, IsHandled, TransferLine);
            if not IsHandled and CanPickTransferLine(TransferLine) then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0, 0) then begin
                    NewWarehouseActivityLine.Init();
                    NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                    NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                    if CurrLocation."Bin Mandatory" then
                        NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                    NewWarehouseActivityLine.SetSource(Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0);
                    NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Outbound Transfer";
                    NewWarehouseActivityLine."Location Code" := TransferLine."Transfer-from Code";
                    NewWarehouseActivityLine."Bin Code" := TransferLine."Transfer-from Bin Code";
                    NewWarehouseActivityLine."Item No." := TransferLine."Item No.";
                    NewWarehouseActivityLine."Variant Code" := TransferLine."Variant Code";
                    NewWarehouseActivityLine."Unit of Measure Code" := TransferLine."Unit of Measure Code";
                    NewWarehouseActivityLine."Qty. per Unit of Measure" := TransferLine."Qty. per Unit of Measure";
                    NewWarehouseActivityLine."Qty. Rounding Precision" := TransferLine."Qty. Rounding Precision";
                    NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := TransferLine."Qty. Rounding Precision (Base)";
                    NewWarehouseActivityLine.Description := TransferLine.Description;
                    NewWarehouseActivityLine."Description 2" := TransferLine."Description 2";
                    NewWarehouseActivityLine."Due Date" := TransferLine."Shipment Date";
                    NewWarehouseActivityLine."Shipping Advice" := TransferHeader."Shipping Advice";
                    NewWarehouseActivityLine."Shipping Agent Code" := TransferLine."Shipping Agent Code";
                    NewWarehouseActivityLine."Shipping Agent Service Code" := TransferLine."Shipping Agent Service Code";
                    NewWarehouseActivityLine."Shipment Method Code" := TransferHeader."Shipment Method Code";
                    NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Location;
                    NewWarehouseActivityLine."Destination No." := TransferHeader."Transfer-to Code";
                    RemQtyToPickBase := TransferLine."Qty. to Ship (Base)";
                    OnBeforeNewWhseActivLineInsertFromTransfer(NewWarehouseActivityLine, TransferLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                    TransferLine.CalcFields(TransferLine."Reserved Quantity Outbnd.");
                    CreatePickOrMoveLine(
                      NewWarehouseActivityLine, RemQtyToPickBase, TransferLine."Outstanding Qty. (Base)", TransferLine."Reserved Quantity Outbnd." <> 0);
                    OnCreatePickOrMoveFromTransferOnAfterCreatePickOrMoveLine(NewWarehouseActivityLine, TransferLine, CurrWarehouseActivityHeader, ShowError, AutoCreation, LineCreated);

                    if TransferHeader."Shipping Advice" = TransferHeader."Shipping Advice"::Complete then begin
                        if RemQtyToPickBase > 0 then begin
                            if AutoCreation then begin
                                CurrWarehouseActivityHeader.Delete(true);
                                LineCreated := false;
                                exit;
                            end;
                            Error(QtyNotSufficientOnTransferErr, TransferHeader."Shipping Advice", TransferLine."Document No.", TransferLine."Line No.");
                        end;
                        if (RemQtyToPickBase = 0) and not CompleteShipment then begin
                            if ShowError then
                                Error(QtyNotSufficientOnTransferErr, TransferHeader."Shipping Advice", TransferLine."Document No.", TransferLine."Line No.");
                            if CurrWarehouseActivityHeader.Delete(true) then;
                            LineCreated := false;
                            exit;
                        end;
                    end;
                end;
        until TransferLine.Next() = 0;
        OnAfterCreatePickOrMoveFromTransfer(CurrWarehouseActivityHeader, TransferHeader, TransferLine);
    end;

    local procedure SetFilterTransferLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"): Boolean
    begin
        if CurrLocation.RequireShipment(CurrWarehouseRequest."Location Code") then
            exit(false);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        if not CheckLineExist then
            TransferLine.SetRange("Transfer-from Code", CurrWarehouseActivityHeader."Location Code");
        TransferLine.SetFilter("Qty. to Ship", '>%1', 0);

        if ApplySourceFilters then begin
            TransferLine.SetFilter("Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            TransferLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            TransferLine.SetFilter("Shipment Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnBeforeFindTransLine(TransferLine, TransferHeader, CurrWarehouseActivityHeader);
        exit(TransferLine.Find('-'));
    end;

    local procedure CreatePickOrMoveFromJobPlanning(JobVar: Variant)
    var
        Job: Record Job;
        JobPlanningLine: Record "Job Planning Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        PickItem: Record Item;
        RemQtyToPickBase: Decimal;
    begin
        Job := JobVar;

        if not SetFilterJobPlanningLine(JobPlanningLine, Job) then begin
            RaiseNothingToHandleMessage();
            exit;
        end;

        FindNextLineNo();

        repeat
            if (JobPlanningLine."Location Code" = '') or (CurrLocation."Job Consump. Whse. Handling" = CurrLocation."Job Consump. Whse. Handling"::"Inventory Pick") then begin
                if CurrLocation."Job Consump. Whse. Handling" = CurrLocation."Job Consump. Whse. Handling"::"Inventory Pick" then
                    FeatureTelemetry.LogUsage('0000KT4', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
                if PickItem.Get(JobPlanningLine."No.") then
                    if PickItem.IsInventoriableType() and CanPickJobPlanningLine(JobPlanningLine) then
                        if not
                           NewWarehouseActivityLine.ActivityExists(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.", 0)
                        then begin
                            NewWarehouseActivityLine.Init();
                            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
                            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
                            if CurrLocation."Bin Mandatory" then
                                NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                            NewWarehouseActivityLine.SetSource(Database::Job, 0, JobPlanningLine."Job No.", JobPlanningLine."Job Contract Entry No.", JobPlanningLine."Line No.");
                            NewWarehouseActivityLine."Location Code" := JobPlanningLine."Location Code";
                            NewWarehouseActivityLine."Bin Code" := JobPlanningLine."Bin Code";
                            NewWarehouseActivityLine."Item No." := JobPlanningLine."No.";
                            NewWarehouseActivityLine."Variant Code" := JobPlanningLine."Variant Code";
                            NewWarehouseActivityLine."Unit of Measure Code" := JobPlanningLine."Unit of Measure Code";
                            NewWarehouseActivityLine."Qty. per Unit of Measure" := JobPlanningLine."Qty. per Unit of Measure";
                            NewWarehouseActivityLine."Qty. Rounding Precision" := JobPlanningLine."Qty. Rounding Precision";
                            NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := JobPlanningLine."Qty. Rounding Precision (Base)";
                            NewWarehouseActivityLine.Description := JobPlanningLine.Description;
                            NewWarehouseActivityLine."Description 2" := JobPlanningLine."Description 2";
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Job Usage";
                            NewWarehouseActivityLine."Due Date" := JobPlanningLine."Planning Due Date";
                            NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Customer;
                            Job.Get(JobPlanningLine."Job No.");
                            NewWarehouseActivityLine."Destination No." := Job."Sell-to Customer No.";
                            JobPlanningLine.CalcFields("Reserved Quantity");
                            RemQtyToPickBase := JobPlanningLine."Remaining Qty. (Base)";
                            OnBeforeNewWhseActivLineInsertFromJobPlanning(NewWarehouseActivityLine, JobPlanningLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
                            CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, JobPlanningLine."Remaining Qty. (Base)", JobPlanningLine."Reserved Quantity" <> 0);
                        end;
            end;
        until JobPlanningLine.Next() = 0;
    end;

    local procedure SetFilterJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job): Boolean
    begin
        JobPlanningLine.SetLoadFields(
            "Job No.",
            "Job Contract Entry No.",
            "Line No.",
            "Document No.",
            "Location Code",
            "Bin Code",
            "No.",
            "Variant Code",
            "Unit of Measure Code",
            "Qty. per Unit of Measure",
            "Qty. Rounding Precision",
            "Qty. Rounding Precision (Base)",
            Description,
            "Planning Due Date",
            "Job Task No.",
            "Reserved Quantity",
            "Remaining Qty. (Base)",
            "Reserved Quantity"
        );
        JobPlanningLine.SetRange("Job No.", Job."No.");
        JobPlanningLine.SetRange(Type, JobPlanningLine.Type::Item);


        if not CheckLineExist then
            JobPlanningLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        if IsInvtMovement then
            JobPlanningLine.SetFilter("Bin Code", '<>%1', '');
        JobPlanningLine.SetFilter("Remaining Qty.", '>0');

        if ApplySourceFilters then begin
            JobPlanningLine.SetFilter("Job Task No.", WarehouseSourceFilter.GetFilter("Job Task No. Filter"));
            JobPlanningLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            JobPlanningLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            JobPlanningLine.SetFilter("Planning Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnSetFilterJobPlanningLineOnBeforeJobPlanningLineFind(JobPlanningLine, Job, CurrWarehouseActivityHeader);
        exit(JobPlanningLine.Find('-'));
    end;

    procedure FindNextLineNo()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        if IsInvtMovement then
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Movement")
        else
            WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Pick");
        WarehouseActivityLine.SetRange("No.", CurrWarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindLast() then
            NextLineNo := WarehouseActivityLine."Line No." + 10000
        else
            NextLineNo := 10000;
    end;

    procedure SetHideDialog(NewHideDialogValue: Boolean)
    begin
        HideDialog := NewHideDialogValue;
    end;

    procedure SetWhseActivHeader(WhseActivHeader: Record "Warehouse Activity Header")
    begin
        CurrWarehouseActivityHeader := WhseActivHeader;
    end;

    procedure GetWhseActivHeader(var WhseActivHeader: Record "Warehouse Activity Header")
    begin
        WhseActivHeader := CurrWarehouseActivityHeader;
    end;

    procedure RunCreatePickOrMoveLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean)
    begin
        OnBeforeRunCreatePickOrMoveLine(CurrWarehouseActivityHeader, CurrWarehouseRequest);
        CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, OutstandingQtyBase, ReservationExists);
        OnAfterRunCreatePickOrMoveLine(CurrWarehouseActivityHeader, CurrWarehouseRequest);
    end;

    internal procedure CreatePickOrMoveLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ATOSalesLine: Record "Sales Line";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ATOJobPlanningLine: Record "Job Planning Line";
        QtyAvailToPickBase: Decimal;
        OriginalRemQtyToPickBase: Decimal;
        QtyRemToPickBase: Decimal;
        ITQtyToPickBase: Decimal;
        TotalITQtyToPickBase: Decimal;
        QtyToTrackBase: Decimal;
        EntriesExist: Boolean;
        ShouldInsertPickOrMoveDefaultBin: Boolean;
        IsHandled: Boolean;
    begin
        GetLocation(NewWarehouseActivityLine."Location Code");

        if ReservationExists then
            CalcRemQtyToPickOrMoveBase(NewWarehouseActivityLine, OutstandingQtyBase, RemQtyToPickBase);

        if RemQtyToPickBase <= 0 then
            exit;

        HasExpiredItems := false;
        OriginalRemQtyToPickBase := RemQtyToPickBase;

        QtyAvailToPickBase := CalcInvtAvailability(NewWarehouseActivityLine, WhseItemTrackingSetup);
        if WMSManagement.GetATOSalesLine(
             NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.",
             NewWarehouseActivityLine."Source Line No.", ATOSalesLine)
        then
            QtyAvailToPickBase += ATOSalesLine.QtyToAsmBaseOnATO();

        if WMSManagement.GetATOJobPlanningLine(
            NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source No.", NewWarehouseActivityLine."Source Line No.",
            NewWarehouseActivityLine."Source Subline No.", ATOJobPlanningLine)
        then
            QtyAvailToPickBase += ATOJobPlanningLine.QtyToAsmBaseOnATO();

        IsHandled := false;
        OnCreatePickOrMoveLineOnAfterCalcQtyAvailToPickBase(
            NewWarehouseActivityLine, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required",
            ReservationExists, RemQtyToPickBase, QtyAvailToPickBase, IsHandled);
        if not IsHandled then
            if RemQtyToPickBase > QtyAvailToPickBase then begin
                IsHandled := false;
                OnCreatePickOrMoveLineOnAfterCheckForCompleteShipment(CurrWarehouseActivityHeader, WhseItemTrackingSetup, ReservationExists, RemQtyToPickBase, QtyAvailToPickBase, IsHandled);
                if not IsHandled then
                    RemQtyToPickBase := QtyAvailToPickBase;
                CompleteShipment := false;
            end;

        if RemQtyToPickBase > 0 then begin
            if ItemTrackingManagement.GetWhseItemTrkgSetup(NewWarehouseActivityLine."Item No.", WhseItemTrackingSetup) then begin
                OnCreatePickOrMoveLineOnAfterGetWhseItemTrkgSetup(NewWarehouseActivityLine, WhseItemTrackingSetup);
                if IsBlankInvtMovement then
                    ItemTrackingManagement.SumUpItemTrackingOnlyInventoryOrATO(TempReservationEntry, TempTrackingSpecification, true, true)
                else begin
                    SetFilterReservEntry(ReservationEntry, NewWarehouseActivityLine);
                    CopyReservEntriesToTemp(TempReservationEntry, ReservationEntry);
                    if IsInvtMovement then
                        if NewWarehouseActivityLine."Source Type" = 5407 then // Database::"Prod. Order Component"
                            PrepareItemTrackingFromWhse(
                              NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.",
                              '', NewWarehouseActivityLine."Source Line No.", NewWarehouseActivityLine."Source Subline No.", 1, false)
                        else
                            PrepareItemTrackingFromWhse(
                              NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.",
                              '', 0, NewWarehouseActivityLine."Source Line No.", 1, false);
                    ItemTrackingManagement.SumUpItemTrackingOnlyInventoryOrATO(TempReservationEntry, TempTrackingSpecification, true, true);
                end;

                if PickOrMoveAccordingToFEFO(NewWarehouseActivityLine."Location Code", WhseItemTrackingSetup) or
                   PickStrictExpirationPosting(NewWarehouseActivityLine."Item No.", WhseItemTrackingSetup)
                then begin
                    QtyToTrackBase := RemQtyToPickBase;
                    if UndefinedItemTracking(QtyToTrackBase) then
                        CreateTempHandlingSpec(NewWarehouseActivityLine, QtyToTrackBase);
                end;

                TempTrackingSpecification.Reset();
                if TempTrackingSpecification.Find('-') then
                    repeat
                        ITQtyToPickBase := Abs(TempTrackingSpecification."Qty. to Handle (Base)");
                        TotalITQtyToPickBase += ITQtyToPickBase;
                        if ITQtyToPickBase > 0 then begin
                            NewWarehouseActivityLine.CopyTrackingFromSpec(TempTrackingSpecification);
                            if NewWarehouseActivityLine.TrackingExists() then
                                UpdateExpirationDate(NewWarehouseActivityLine, EntriesExist);

                            if IsInvtMovement and not IsBlankInvtMovement and not TempTrackingSpecification.Correction then
                                CheckBinContentWithToAssemblyBinCode(ITQtyToPickBase, NewWarehouseActivityLine);

                            OnCreatePickOrMoveLineFromHandlingSpec(NewWarehouseActivityLine, TempTrackingSpecification, EntriesExist);

                            if CurrLocation."Bin Mandatory" then begin
                                // find Take qty. for bin code of source line
                                if (NewWarehouseActivityLine."Bin Code" <> '') and (not IsInvtMovement or IsBlankInvtMovement) then
                                    InsertPickOrMoveBinWhseActLine(
                                      NewWarehouseActivityLine, NewWarehouseActivityLine."Bin Code", false, ITQtyToPickBase, WhseItemTrackingSetup);

                                OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeOfSourceLineHandlingSpec(NewWarehouseActivityLine, TempTrackingSpecification, WhseItemTrackingSetup, ITQtyToPickBase, CurrWarehouseActivityHeader);

                                // Invt. movement without document has to be created
                                if IsBlankInvtMovement then
                                    ITQtyToPickBase := 0;

                                // find Take qty. for default bin
                                ShouldInsertPickOrMoveDefaultBin := ITQtyToPickBase > 0;
                                OnCreatePickOrMoveLineOnAfterCalcShouldInsertPickOrMoveDefaultBin(NewWarehouseActivityLine, RemQtyToPickBase, OutstandingQtyBase, ReservationExists, ShouldInsertPickOrMoveDefaultBin);

                                case CurrLocation."Pick Bin Policy" of
                                    CurrLocation."Pick Bin Policy"::"Default Bin":
                                        begin
                                            FeatureTelemetry.LogUsage('0000KP7', BinPolicyTelemetryCategoryTok, DefaultBinPickPolicyTelemetryTok);

                                            if ShouldInsertPickOrMoveDefaultBin then
                                                InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', true, ITQtyToPickBase, WhseItemTrackingSetup);

                                            // find Take qty. for other bins
                                            if ITQtyToPickBase > 0 then
                                                InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', false, ITQtyToPickBase, WhseItemTrackingSetup);
                                        end;
                                    CurrLocation."Pick Bin Policy"::"Bin Ranking":
                                        begin
                                            FeatureTelemetry.LogUsage('0000KP8', BinPolicyTelemetryCategoryTok, RankingBinPickPolicyTelemetryTok);

                                            // find Take qty. for other bins
                                            if ITQtyToPickBase > 0 then
                                                InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', false, ITQtyToPickBase, WhseItemTrackingSetup);
                                        end;
                                    else
                                        OnInsertPickOrMoveBinWhseActivityLine(NewWarehouseActivityLine, ITQtyToPickBase);
                                end;

                                if (ITQtyToPickBase = 0) and IsInvtMovement and not IsBlankInvtMovement and
                                   not TempTrackingSpecification.Correction
                                then
                                    SynchronizeWhseItemTracking(TempTrackingSpecification);
                            end else
                                if ITQtyToPickBase > 0 then
                                    InsertShelfWhseActivLine(NewWarehouseActivityLine, ITQtyToPickBase, WhseItemTrackingSetup);

                            RemQtyToPickBase :=
                              RemQtyToPickBase + ITQtyToPickBase +
                              TempTrackingSpecification."Qty. to Handle (Base)";
                        end;
                        NewWarehouseActivityLine.ClearTracking();
                    until (TempTrackingSpecification.Next() = 0) or (RemQtyToPickBase <= 0);

                RemQtyToPickBase := Minimum(RemQtyToPickBase, OriginalRemQtyToPickBase - TotalITQtyToPickBase);
            end;

            if CurrLocation."Bin Mandatory" then begin
                // find Take qty. for bin code of source line
                OnCreatePickOrMoveLineOnBeforeCheckIfInsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, RemQtyToPickBase);
                if (RemQtyToPickBase > 0) and
                   (NewWarehouseActivityLine."Bin Code" <> '') and
                   (not IsInvtMovement or IsBlankInvtMovement) and
                   (not HasExpiredItems)
                then
                    InsertPickOrMoveBinWhseActLine(
                      NewWarehouseActivityLine, NewWarehouseActivityLine."Bin Code", false, RemQtyToPickBase, WhseItemTrackingSetup);

                OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeSourceLine(NewWarehouseActivityLine, WhseItemTrackingSetup, RemQtyToPickBase, CurrWarehouseActivityHeader);
                // Invt. movement without document has to be created
                if IsBlankInvtMovement then
                    RemQtyToPickBase := 0;

                // find Take qty. for default bin
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) and (CurrLocation."Pick Bin Policy" = CurrLocation."Pick Bin Policy"::"Default Bin") then
                    InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', true, RemQtyToPickBase, WhseItemTrackingSetup);

                // find Take qty. for other bins
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, '', false, RemQtyToPickBase, WhseItemTrackingSetup)
            end else
                if (RemQtyToPickBase > 0) and (not HasExpiredItems) then
                    InsertShelfWhseActivLine(NewWarehouseActivityLine, RemQtyToPickBase, WhseItemTrackingSetup);
        end;

        QtyRemToPickBase := OriginalRemQtyToPickBase - QtyAvailToPickBase + RemQtyToPickBase;
        if CurrLocation."Always Create Pick Line" and (QtyRemToPickBase > 0) then begin
            MakeWarehouseActivityHeader();
            MakeWarehouseActivityLine(NewWarehouseActivityLine, '', QtyRemToPickBase, QtyRemToPickBase);
        end;

        OnAfterInsertWhseActivLine(
            NewWarehouseActivityLine, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required",
            RemQtyToPickBase, CompleteShipment, ReservationExists, WhseItemTrackingSetup);
    end;

    local procedure CalcRemQtyToPickOrMoveBase(NewWarehouseActivityLine: Record "Warehouse Activity Line"; OutstandingQtyBase: Decimal; var RemQtyToPickBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        MaxQtyToPickBase: Decimal;
    begin
        MaxQtyToPickBase :=
            OutstandingQtyBase -
            WMSManagement.CalcLineReservedQtyNotonInvt(
                NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.",
                NewWarehouseActivityLine."Source Line No.", NewWarehouseActivityLine."Source Subline No.");

        if WMSManagement.GetATOSalesLine(NewWarehouseActivityLine."Source Type", NewWarehouseActivityLine."Source Subtype", NewWarehouseActivityLine."Source No.", NewWarehouseActivityLine."Source Line No.", ATOSalesLine) then
            MaxQtyToPickBase += ATOSalesLine.QtyAsmRemainingBaseOnATO();

        if RemQtyToPickBase > MaxQtyToPickBase then begin
            RemQtyToPickBase := MaxQtyToPickBase;
            if NewWarehouseActivityLine."Shipping Advice" = NewWarehouseActivityLine."Shipping Advice"::Complete then
                CompleteShipment := false;
        end;
    end;

    procedure InsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        FromBinContent: Record "Bin Content";
        QtyToPickBase: Decimal;
        QtyAvailToPickBase: Decimal;
        IsHandled: Boolean;
        RemQtyToPick: Decimal;
    begin
        IsHandled := false;
        OnBeforeInsertPickOrMoveBinWhseActLine(
            NewWarehouseActivityLine, BinCode, DefaultBin, RemQtyToPickBase, IsHandled, CurrWarehouseRequest, CurrWarehouseActivityHeader,
            IsInvtMovement, AutoCreation, PostingDate, VendorDocNo, LineCreated, NextLineNo);
        if IsHandled then
            exit;

        CreateATOPickLine(NewWarehouseActivityLine, BinCode, RemQtyToPickBase);
        if RemQtyToPickBase = 0 then
            exit;

        if DefaultBin then begin
            FromBinContent.SetCurrentKey(Default, "Bin Ranking", "Location Code", "Item No.", "Variant Code", "Bin Code");
            FromBinContent.SetRange(Default, DefaultBin)
        end else begin
            FromBinContent.SetCurrentKey("Bin Ranking");
            FromBinContent.SetAscending("Bin Ranking", false);
        end;

        FromBinContent.SetRange("Location Code", NewWarehouseActivityLine."Location Code");
        FromBinContent.SetRange("Item No.", NewWarehouseActivityLine."Item No.");
        FromBinContent.SetRange("Variant Code", NewWarehouseActivityLine."Variant Code");

        if (BinCode <> '') and not IsInvtMovement then
            FromBinContent.SetRange("Bin Code", BinCode);

        if (NewWarehouseActivityLine."Bin Code" <> '') and IsInvtMovement then
            // not movement within the same bin
            FromBinContent.SetFilter("Bin Code", '<>%1', NewWarehouseActivityLine."Bin Code");

        if IsBlankInvtMovement then begin
            // inventory movement without source document, created from Internal Movement
            if not CurrLocation."Pick According to FEFO" then
                FromBinContent.SetRange("Bin Code", FromBinCode)
            else
                if ShouldSetBinCodeForBlankInvtMovement(NewWarehouseActivityLine) then
                    FromBinContent.SetRange("Bin Code", FromBinCode);
            FromBinContent.SetRange(Default);
        end;

        FromBinContent.SetTrackingFilterFromWhseActivityLineIfNotBlank(NewWarehouseActivityLine);

        OnBeforeFindFromBinContent(FromBinContent, NewWarehouseActivityLine, FromBinCode, BinCode, IsInvtMovement, IsBlankInvtMovement, DefaultBin, WhseItemTrackingSetup, CurrWarehouseActivityHeader, CurrWarehouseRequest);
        if FromBinContent.Find('-') then
            repeat
                IsHandled := false;
                OnInsertPickOrMoveBinWhseActLineOnBeforeLoopIteration(FromBinContent, NewWarehouseActivityLine, BinCode, DefaultBin, RemQtyToPickBase, IsHandled, QtyAvailToPickBase);
                if not IsHandled then begin
                    if NewWarehouseActivityLine."Activity Type" = NewWarehouseActivityLine."Activity Type"::"Invt. Movement" then
                        QtyAvailToPickBase := FromBinContent.CalcQtyAvailToPickIncludingDedicated(0)
                    else
                        QtyAvailToPickBase := FromBinContent.CalcQtyAvailToPick(0);
                    OnInsertPickOrMoveBinWhseActLineOnAfterCalcQtyAvailToPick(QtyAvailToPickBase, FromBinContent);
                    if RemQtyToPickBase < QtyAvailToPickBase then
                        QtyAvailToPickBase := RemQtyToPickBase;

                    OnInsertPickOrMoveBinWhseActLineOnBeforeMakeHeader(RemQtyToPickBase, QtyAvailToPickBase, DefaultBin, FromBinContent);
                    if QtyAvailToPickBase > 0 then begin
                        MakeWarehouseActivityHeader();
                        if WhseItemTrackingSetup."Serial No. Required" then begin
                            QtyAvailToPickBase := Round(QtyAvailToPickBase, 1, '<');
                            QtyToPickBase := 1;
                            OnInsertPickOrMoveBinWhseActLineOnBeforeLoopMakeLine(CurrWarehouseActivityHeader, CurrWarehouseRequest, NewWarehouseActivityLine, FromBinContent, AutoCreation, QtyToPickBase);
                            RemQtyToPick := NewWarehouseActivityLine.CalcQty(RemQtyToPickBase);
                            IsHandled := false;
                            OnInsertPickOrMoveBinWhseActLineOnBeforeMakeLineWhenSNoReq(NewWarehouseActivityLine, WhseItemTrackingSetup, FromBinContent."Bin Code", QtyToPickBase, RemQtyToPickBase, QtyAvailToPickBase, IsHandled);
                            if not IsHandled then
                                repeat
                                    MakeLineWhenSNoReq(NewWarehouseActivityLine, FromBinContent."Bin Code", QtyToPickBase, RemQtyToPickBase, RemQtyToPick);
                                    QtyAvailToPickBase := QtyAvailToPickBase - QtyToPickBase;
                                until QtyAvailToPickBase <= 0;
                        end else begin
                            QtyToPickBase := QtyAvailToPickBase;
                            OnInsertPickOrMoveBinWhseActLineOnBeforeLoopMakeLine(CurrWarehouseActivityHeader, CurrWarehouseRequest, NewWarehouseActivityLine, FromBinContent, AutoCreation, QtyToPickBase);
                            repeat
                                MakeWarehouseActivityLine(NewWarehouseActivityLine, FromBinContent."Bin Code", QtyToPickBase, RemQtyToPickBase);
                                OnInsertPickOrMoveBinWhseActLineOnAfterMakeLine(QtyToPickBase, DefaultBin);
                                QtyAvailToPickBase := QtyAvailToPickBase - QtyToPickBase;
                            until QtyAvailToPickBase <= 0;
                        end;
                    end;
                end;
            until (FromBinContent.Next() = 0) or (RemQtyToPickBase = 0);
        OnAfterInsertPickOrMoveBinWhseActLine(NewWarehouseActivityLine, CurrWarehouseActivityHeader, RemQtyToPickBase)
    end;

    procedure CheckBinContentWithToAssemblyBinCode(var ITQtyToPickBase: Decimal; NewWarehouseActivityLine: Record "Warehouse Activity Line")
    var
        Location: Record Location;
        FromBinContent: Record "Bin Content";
    begin
        if ITQtyToPickBase <= 0 then
            exit;

        if not Location.Get(NewWarehouseActivityLine."Location Code") then
            exit;

        FromBinContent.SetLoadFields("Location Code", "Bin Code", "Item No.", "Variant Code", "Unit of Measure Code", "Quantity (Base)");
        FromBinContent.SetRange("Location Code", NewWarehouseActivityLine."Location Code");
        FromBinContent.SetRange("Bin Code", Location."To-Assembly Bin Code");
        FromBinContent.SetRange("Item No.", NewWarehouseActivityLine."Item No.");
        FromBinContent.SetRange("Variant Code", NewWarehouseActivityLine."Variant Code");
        FromBinContent.SetRange("Unit of Measure Code", NewWarehouseActivityLine."Unit of Measure Code");
        if FromBinContent.FindSet() then
            repeat
                FromBinContent.CalcFields("Quantity (Base)");
                if FromBinContent."Quantity (Base)" <= ITQtyToPickBase then
                    ITQtyToPickBase -= FromBinContent."Quantity (Base)";
            until FromBinContent.Next() = 0;
    end;

    procedure InsertShelfWhseActivLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; WhseItemTrackingSetup: Record "Item Tracking Setup")
    var
        QtyToPickBase: Decimal;
        RemQtyToPick: Decimal;
        IsHandled: Boolean;
    begin
        CreateATOPickLine(NewWarehouseActivityLine, '', RemQtyToPickBase);
        if RemQtyToPickBase = 0 then
            exit;

        MakeWarehouseActivityHeader();
        OnInsertShelfWhseActivLineOnAfterMakeHeader(NewWarehouseActivityLine);

        if WhseItemTrackingSetup."Serial No. Required" then begin
            IsHandled := false;
            QtyToPickBase := 0;
            OnInsertShelfWhseActivLineOnBeforeMakeShelfLineWhenSNoReq(NewWarehouseActivityLine, WhseItemTrackingSetup, QtyToPickBase, RemQtyToPickBase, IsHandled);
            if IsHandled then
                exit;

            RemQtyToPickBase := Round(RemQtyToPickBase, 1, '<');
            QtyToPickBase := 1;
            RemQtyToPick := NewWarehouseActivityLine.CalcQty(RemQtyToPickBase);
            repeat
                MakeLineWhenSNoReq(NewWarehouseActivityLine, '', QtyToPickBase, RemQtyToPickBase, RemQtyToPick);
            until RemQtyToPickBase = 0;
        end else begin
            QtyToPickBase := RemQtyToPickBase;
            repeat
                MakeWarehouseActivityLine(NewWarehouseActivityLine, '', QtyToPickBase, RemQtyToPickBase);
                OnInsertShelfWhseActivLineOnAfterMakeWarehouseActivityLine(NewWarehouseActivityLine);
            until RemQtyToPickBase = 0;
        end;
    end;

    procedure CalcInvtAvailability(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup") Result: Decimal
    var
        Item2: Record Item;
        TempWarehouseActivityLine2: Record "Warehouse Activity Line" temporary;
        WhseActivLineItemTrackingSetup: Record "Item Tracking Setup";
        WarehouseAvailabilityMgt: Codeunit "Warehouse Availability Mgt.";
        QtyAssgndtoPick: Decimal;
        LineReservedQty: Decimal;
        QtyReservedOnPickShip: Decimal;
        QtyOnDedicatedBins: Decimal;
        QtyBlocked: Decimal;
        SourceLineNo: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcInvtAvailability(WarehouseActivityLine, CurrLocation, Result, IsHandled, WhseItemTrackingSetup, IsBlankInvtMovement);
        if IsHandled then
            exit(Result);

        GetItem(WarehouseActivityLine."Item No.");
        Item2 := CurrItem;
        Item2.SetRange("Location Filter", WarehouseActivityLine."Location Code");
        Item2.SetRange("Variant Filter", WarehouseActivityLine."Variant Code");
        WhseItemTrackingSetup.SetTrackingFilterForItem(Item2);
        Item2.CalcFields(Inventory);
        if not IsBlankInvtMovement then
            Item2.CalcFields("Reserved Qty. on Inventory");

        QtyAssgndtoPick := WarehouseAvailabilityMgt.CalcQtyAssgndtoPick(CurrLocation, WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", '');

        if WarehouseActivityLine."Activity Type" <> WarehouseActivityLine."Activity Type"::"Invt. Movement" then begin // Invt. Movement from Dedicated Bin is allowed
            WhseActivLineItemTrackingSetup.CopyTrackingFromWhseActivityLine(WarehouseActivityLine);
            QtyOnDedicatedBins :=
                WarehouseAvailabilityMgt.CalcQtyOnDedicatedBins(
                    WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WhseActivLineItemTrackingSetup);
        end;

        SourceLineNo := GetSourceLineNo(WarehouseActivityLine);

        LineReservedQty :=
            WarehouseAvailabilityMgt.CalcLineReservedQtyOnInvt(
                WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                SourceLineNo, WarehouseActivityLine."Source Subline No.", true, WhseItemTrackingSetup, TempWarehouseActivityLine2);

        QtyReservedOnPickShip :=
            WarehouseAvailabilityMgt.CalcReservQtyOnPicksShips(
                WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", TempWarehouseActivityLine2);

        if CurrLocation."Bin Mandatory" then
            QtyBlocked :=
                WarehouseAvailabilityMgt.CalcQtyOnBlockedITOrOnBlockedOutbndBins(
                    WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WhseItemTrackingSetup)
        else
            QtyBlocked :=
                WarehouseAvailabilityMgt.CalcQtyOnBlockedItemTracking(
                    WarehouseActivityLine."Location Code", WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", WhseItemTrackingSetup);
        OnCalcInvtAvailabilityOnAfterCalcQtyBlocked(WarehouseActivityLine, WhseItemTrackingSetup, QtyBlocked);
        exit(
          Item2.Inventory - Abs(Item2."Reserved Qty. on Inventory") - QtyAssgndtoPick - QtyOnDedicatedBins - QtyBlocked +
          LineReservedQty + QtyReservedOnPickShip);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> CurrLocation.Code then
            if LocationCode = '' then
                CurrLocation.GetLocationSetup('', CurrLocation)
            else
                CurrLocation.Get(LocationCode);
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (CurrBin."Location Code" <> LocationCode) or
           (CurrBin.Code <> BinCode)
        then
            CurrBin.Get(LocationCode, BinCode)
    end;

    local procedure GetShelfNo(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Code[10]
    var
        StockkeepingUnit: Record "Stockkeeping Unit";
    begin
        GetItem(ItemNo);
        StockkeepingUnit.SetLoadFields("Shelf No.");
        if StockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then
            exit(StockkeepingUnit."Shelf No.");
        exit(CurrItem."Shelf No.");
    end;

    local procedure GetItem(ItemNo: Code[20])
    begin
        if ItemNo <> CurrItem."No." then
            CurrItem.Get(ItemNo);
    end;

    local procedure GetItemAndSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        if CurrItem."No." <> ItemNo then
            CurrItem.Get(ItemNo);

        if (ItemNo <> CurrStockKeepingUnit."Item No.") or
           (LocationCode <> CurrStockKeepingUnit."Location Code") or
           (VariantCode <> CurrStockKeepingUnit."Variant Code")
        then
            if not CurrStockKeepingUnit.Get(LocationCode, ItemNo, VariantCode) then
                Clear(CurrStockKeepingUnit);
    end;

    procedure SetWhseRequest(NewWarehouseRequest: Record "Warehouse Request"; NewSetHideDialog: Boolean)
    begin
        CurrWarehouseRequest := NewWarehouseRequest;
        HideDialog := NewSetHideDialog;
        LineCreated := false;
    end;

    procedure CheckSourceDoc(NewWarehouseRequest: Record "Warehouse Request"): Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        JobPlanningLine: Record "Job Planning Line";
        IsHandled: Boolean;
        Result: Boolean;
    begin
        CurrWarehouseRequest := NewWarehouseRequest;

        IsHandled := false;
        OnBeforeCheckSourceDoc(NewWarehouseRequest, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not GetSourceDocHeader() then
            exit(false);

        CheckLineExist := true;
        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                exit(SetFilterPurchLine(PurchaseLine, SourceDocRecordVar));
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                exit(SetFilterPurchLine(PurchaseLine, SourceDocRecordVar));
            CurrWarehouseRequest."Source Document"::"Sales Order":
                exit(SetFilterSalesLine(SalesLine, SourceDocRecordVar));
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                exit(SetFilterSalesLine(SalesLine, SourceDocRecordVar));
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                exit(SetFilterTransferLine(TransferLine, SourceDocRecordVar));
            CurrWarehouseRequest."Source Document"::"Job Usage":
                exit(SetFilterJobPlanningLine(JobPlanningLine, SourceDocRecordVar));
            else begin
                IsHandled := false;
                OnCheckSourceDocForWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, CurrWarehouseActivityHeader, CheckLineExist, Result, IsHandled,
                    IsInvtMovement, WarehouseSourceFilter, ApplySourceFilters, SourceDocRecordVar);
                if IsHandled then
                    exit(Result);
            end;
        end;
    end;

    procedure AutoCreatePickOrMove(var NewWarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        IsHandled: Boolean;
    begin
        CurrWarehouseActivityHeader := NewWarehouseActivityHeader;
        CheckLineExist := false;
        AutoCreation := true;
        GetLocation(CurrWarehouseRequest."Location Code");

        IsHandled := false;
        OnBeforeAutoCreatePickOrMove(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, IsHandled, HideDialog, IsInvtMovement, IsBlankInvtMovement, CompleteShipment);
        if IsHandled then
            exit;

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                CreatePickOrMoveFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                CreatePickOrMoveFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Order":
                CreatePickOrMoveFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                CreatePickOrMoveFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Outbound Transfer":
                CreatePickOrMoveFromTransfer(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Job Usage":
                CreatePickOrMoveFromJobPlanning(SourceDocRecordVar);
            else
                OnAutoCreatePickOrMoveFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, LineCreated, CurrWarehouseActivityHeader, CurrLocation,
                    HideDialog, CompleteShipment, CheckLineExist, IsInvtMovement, WarehouseSourceFilter, ApplySourceFilters,
                    ReservedFromStock, SourceDocRecordVar);
        end;

        if LineCreated then begin
            OnAutoCreatePickOrMoveOnBeforeWarehouseActivityHeaderModify(CurrWarehouseActivityHeader, CurrWarehouseRequest, CurrLocation);
            CurrWarehouseActivityHeader.Modify();
            NewWarehouseActivityHeader := CurrWarehouseActivityHeader;
        end;

        OnAfterAutoCreatePickOrMove(CurrWarehouseRequest, LineCreated, NewWarehouseActivityHeader, CurrLocation, HideDialog);
    end;

    procedure SetReportGlobals(PrintDocument2: Boolean; ShowError2: Boolean)
    begin
        PrintDocument := PrintDocument2;
        ShowError := ShowError2;
    end;

    procedure SetReportGlobals(PrintDocument2: Boolean; ShowError2: Boolean; ReservedFromStock2: Enum "Reservation From Stock")
    begin
        PrintDocument := PrintDocument2;
        ShowError := ShowError2;
        ReservedFromStock := ReservedFromStock2;
    end;

    local procedure SetFilterReservEntry(var ReservationEntry: Record "Reservation Entry"; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
        ReservationEntry.Reset();
        ReservationEntry.SetCurrentKey("Source ID", "Source Ref. No.", "Source Type", "Source Subtype", "Source Batch Name", "Source Prod. Order Line");
        ReservationEntry.SetRange("Source ID", WarehouseActivityLine."Source No.");
        if WarehouseActivityLine."Source Type" = 5407 then // Database::"Prod. Order Component"
            ReservationEntry.SetRange("Source Ref. No.", WarehouseActivityLine."Source Subline No.")
        else
            ReservationEntry.SetRange("Source Ref. No.", WarehouseActivityLine."Source Line No.");

        if WarehouseActivityLine."Source Type" = Database::Job then begin
            ReservationEntry.SetRange("Source Type", Database::"Job Planning Line");
            ReservationEntry.SetRange("Source Subtype", 2);
        end else begin
            ReservationEntry.SetRange("Source Type", WarehouseActivityLine."Source Type");
            ReservationEntry.SetRange("Source Subtype", WarehouseActivityLine."Source Subtype");
        end;

        if WarehouseActivityLine."Source Type" = 5407 then // Database::"Prod. Order Component"
            ReservationEntry.SetRange("Source Prod. Order Line", WarehouseActivityLine."Source Line No.");
        ReservationEntry.SetRange(Positive, false);
    end;

    /// <summary>
    /// Sets the global option for inventory movement status.
    /// </summary>
    /// <param name="InvtMovement">Indicates whether the operation involves inventory movement.</param>
    procedure SetInvtMovement(InvtMovement: Boolean)
    begin
        IsInvtMovement := InvtMovement;
    end;

    local procedure PickOrMoveAccordingToFEFO(LocationCode: Code[10]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    begin
        GetLocation(LocationCode);

        exit(CurrLocation."Pick According to FEFO" and WhseItemTrackingSetup.TrackingRequired());
    end;

    /// <summary>
    /// Determines and updates quantity to track.
    /// </summary>
    /// <param name="QtyToTrackBase">Quantity to track in base unit.</param>
    /// <returns>Returns 'true' if there is quantity to track, otherwise 'false'.</returns>
    procedure UndefinedItemTracking(var QtyToTrackBase: Decimal): Boolean
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
    begin
        QtyToTrackBase := QtyToTrackBase + ItemTrackedQuantity(DummyItemTrackingSetup);

        exit(QtyToTrackBase > 0);
    end;

    local procedure ItemTrackedQuantity(WhseItemTrackingSetup: Record "Item Tracking Setup"): Decimal
    var
        IsTrackingEmpty: Boolean;
    begin
        TempTrackingSpecification.Reset();
        if not WhseItemTrackingSetup.TrackingExists() then
            if TempTrackingSpecification.IsEmpty() then
                exit(0);

        if WhseItemTrackingSetup."Serial No." <> '' then begin
            TempTrackingSpecification.SetTrackingKey();
            TempTrackingSpecification.SetRange("Serial No.", WhseItemTrackingSetup."Serial No.");
            if TempTrackingSpecification.IsEmpty() then
                exit(0);

            exit(1);
        end;

        if WhseItemTrackingSetup."Lot No." <> '' then begin
            TempTrackingSpecification.SetTrackingKey();
            TempTrackingSpecification.SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
            if TempTrackingSpecification.IsEmpty() then
                exit(0);
        end;

        IsTrackingEmpty := false;
        OnItemTrackedQuantityOnAfterCheckTracking(TempTrackingSpecification, WhseItemTrackingSetup, IsTrackingEmpty);
        if IsTrackingEmpty then
            exit(0);

        TempTrackingSpecification.SetCurrentKey(
          TempTrackingSpecification."Source ID", TempTrackingSpecification."Source Type", TempTrackingSpecification."Source Subtype", TempTrackingSpecification."Source Batch Name",
          TempTrackingSpecification."Source Prod. Order Line", TempTrackingSpecification."Source Ref. No.");
        if WhseItemTrackingSetup."Lot No." <> '' then
            TempTrackingSpecification.SetRange("Lot No.", WhseItemTrackingSetup."Lot No.");
        TempTrackingSpecification.CalcSums(TempTrackingSpecification."Qty. to Handle (Base)");
        exit(TempTrackingSpecification."Qty. to Handle (Base)");
    end;

    /// <summary>
    /// Creates a temporary handling specification for a warehouse activity line.
    /// </summary>
    /// <param name="WarehouseActivityLine">Warehouse activity line for which the specification is created.</param>
    /// <param name="TotalQtyToPickBase">Total quantity to pick in base unit.</param>
    procedure CreateTempHandlingSpec(WarehouseActivityLine: Record "Warehouse Activity Line"; TotalQtyToPickBase: Decimal)
    var
        EntrySummary: Record "Entry Summary";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO";
        TotalAvailQtyToPickBase: Decimal;
        RemQtyToPickBase: Decimal;
        QtyToPickBase: Decimal;
        QtyTracked: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateTempHandlingSpec(WarehouseActivityLine, TotalQtyToPickBase, IsHandled);
        if IsHandled then
            exit;

        if CurrLocation."Bin Mandatory" then
            if not IsItemOnBins(WarehouseActivityLine) then
                exit;

        WhseItemTrackingFEFO.SetSource(
          WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
          WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.");
        OnCreateTempHandlingSpecOnAfterWhseItemTrackingFEFOSetSource(WhseItemTrackingFEFO, WarehouseActivityLine, CurrWarehouseRequest);
        WhseItemTrackingFEFO.CreateEntrySummaryFEFO(CurrLocation, WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", true);
        if WhseItemTrackingFEFO.FindFirstEntrySummaryFEFO(EntrySummary) then begin
            InitTempHandlingSpec();
            RemQtyToPickBase := TotalQtyToPickBase;
            repeat
                WhseItemTrackingSetup.CopyTrackingFromEntrySummary(EntrySummary);
                if EntrySummary."Expiration Date" <> 0D then begin
                    QtyTracked := ItemTrackedQuantity(WhseItemTrackingSetup);
                    OnCreateTempHandlingSpecOnAfterCalcQtyTracked(EntrySummary, QtyTracked, TempTrackingSpecification);
                    if not ((EntrySummary."Serial No." <> '') and (QtyTracked > 0)) then begin
                        if CurrLocation."Bin Mandatory" then
                            TotalAvailQtyToPickBase :=
                              CalcQtyAvailToPickOnBins(WarehouseActivityLine, WhseItemTrackingSetup, RemQtyToPickBase)
                        else
                            TotalAvailQtyToPickBase := CalcInvtAvailability(WarehouseActivityLine, WhseItemTrackingSetup);
                        OnCreateTempHandlingSpecOnAfterCalcTotalAvailQtyToPickBase(WarehouseActivityLine, EntrySummary, TotalAvailQtyToPickBase);

                        TotalAvailQtyToPickBase := TotalAvailQtyToPickBase - QtyTracked;
                        QtyToPickBase := 0;

                        OnAfterCalcTotalAvailQtyToPickBase(
                          WarehouseActivityLine."Item No.", WarehouseActivityLine."Variant Code", EntrySummary."Serial No.", EntrySummary."Lot No.",
                          CurrLocation.Code, '', WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
                          WarehouseActivityLine."Source Line No.", WarehouseActivityLine."Source Subline No.", RemQtyToPickBase, TotalAvailQtyToPickBase);

                        if TotalAvailQtyToPickBase > 0 then
                            if TotalAvailQtyToPickBase >= RemQtyToPickBase then begin
                                QtyToPickBase := RemQtyToPickBase;
                                RemQtyToPickBase := 0
                            end else begin
                                QtyToPickBase := TotalAvailQtyToPickBase;
                                RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
                            end;

                        if QtyToPickBase > 0 then
                            InsertTempHandlingSpec(
                              EntrySummary, WarehouseActivityLine, QtyToPickBase);
                    end;
                end;
            until not WhseItemTrackingFEFO.FindNextEntrySummaryFEFO(EntrySummary) or (RemQtyToPickBase = 0);
        end;
        HasExpiredItems := WhseItemTrackingFEFO.GetHasExpiredItems();
        ExpiredItemMessageText := WhseItemTrackingFEFO.GetResultMessageForExpiredItem();
    end;

    local procedure InitTempHandlingSpec()
    begin
        TempTrackingSpecification.Reset();
        if TempTrackingSpecification.FindLast() then
            LastTempHandlingSpecNo := TempTrackingSpecification."Entry No."
        else
            LastTempHandlingSpecNo := 0;
    end;

    local procedure InsertTempHandlingSpec(EntrySummary: Record "Entry Summary"; WarehouseActivityLine: Record "Warehouse Activity Line"; QuantityBase: Decimal)
    begin
        TempTrackingSpecification.Init();
        TempTrackingSpecification."Entry No." := LastTempHandlingSpecNo + 1;
        if WarehouseActivityLine."Source Type" = 5407 then // Database::"Prod. Order Component"
            TempTrackingSpecification.SetSource(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
              WarehouseActivityLine."Source Subline No.", '', WarehouseActivityLine."Source Line No.")
        else
            TempTrackingSpecification.SetSource(
              WarehouseActivityLine."Source Type", WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.",
              WarehouseActivityLine."Source Line No.", '', 0);
        TempTrackingSpecification."Location Code" := WarehouseActivityLine."Location Code";
        TempTrackingSpecification."Item No." := WarehouseActivityLine."Item No.";
        TempTrackingSpecification."Variant Code" := WarehouseActivityLine."Variant Code";
        TempTrackingSpecification.CopyTrackingFromEntrySummary(EntrySummary);
        TempTrackingSpecification."Expiration Date" := EntrySummary."Expiration Date";
        TempTrackingSpecification.Correction := true;
        OnInsertTempHandlingSpecOnBeforeValidateQtyBase(TempTrackingSpecification, EntrySummary);
        TempTrackingSpecification.Validate(TempTrackingSpecification."Quantity (Base)", -QuantityBase);
        TempTrackingSpecification.Insert();
        LastTempHandlingSpecNo := TempTrackingSpecification."Entry No.";
    end;

    local procedure SetFilterInternalMovement(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeader: Record "Internal Movement Header"): Boolean
    begin
        InternalMovementLine.SetRange("No.", InternalMovementHeader."No.");
        InternalMovementLine.SetFilter("Qty. (Base)", '>0');
        OnSetFilterInternalMomementOnAfterSetFilters(InternalMovementLine, InternalMovementHeader);
        exit(InternalMovementLine.Find('-'));
    end;

    local procedure SetFilterWhseWorksheetLine(var WhseWorksheetLine2: Record "Whse. Worksheet Line"; WhseWorksheetLine: Record "Whse. Worksheet Line"): Boolean
    begin
        Clear(WhseWorksheetLine2);
        WhseWorksheetLine2.SetRange("Worksheet Template Name", WhseWorksheetLine."Worksheet Template Name");
        WhseWorksheetLine2.SetRange(Name, WhseWorksheetLine.Name);
        WhseWorksheetLine2.SetRange("Location Code", WhseWorksheetLine."Location Code");
        WhseWorksheetLine2.SetFilter("Qty. (Base)", '>0');
        exit(WhseWorksheetLine2.FindSet());
    end;

    /// <summary>
    /// Creates an inventory movement document for internal warehouse activities, based on provided inventory movement header.
    /// </summary>
    /// <param name="InternalMovementHeader">Provided internal movement header.</param>
    procedure CreateInvtMvntWithoutSource(var InternalMovementHeader: Record "Internal Movement Header")
    var
        InternalMovementLine: Record "Internal Movement Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
    begin
        if not HideDialog then
            if not Confirm(CreateInvtMvmtQst, false) then
                exit;

        IsInvtMovement := true;
        IsBlankInvtMovement := true;

        InternalMovementHeader.TestField("Location Code");

        if not SetFilterInternalMovement(InternalMovementLine, InternalMovementHeader) then begin
            RaiseNothingToHandleMessage();
            exit;
        end;
        // creating Inventory Movement Header
        Clear(CurrWarehouseActivityHeader);
        CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::"Invt. Movement";
        CurrWarehouseActivityHeader.Insert(true);
        CurrWarehouseActivityHeader.Validate("Location Code", InternalMovementHeader."Location Code");
        CurrWarehouseActivityHeader.Validate("Posting Date", InternalMovementHeader."Due Date");
        CurrWarehouseActivityHeader.Validate("Assigned User ID", InternalMovementHeader."Assigned User ID");
        CurrWarehouseActivityHeader.Validate("Assignment Date", InternalMovementHeader."Assignment Date");
        CurrWarehouseActivityHeader.Validate("Assignment Time", InternalMovementHeader."Assignment Time");
        OnInvtMvntWithoutSourceOnBeforeWhseActivHeaderModify(CurrWarehouseActivityHeader, InternalMovementHeader);
        CurrWarehouseActivityHeader.Modify();

        FindNextLineNo();

        repeat
            NewWarehouseActivityLine.Init();
            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
            InternalMovementLine.TestField("Location Code");
            GetLocation(InternalMovementLine."Location Code");
            if CurrLocation."Bin Mandatory" then
                NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
            NewWarehouseActivityLine."Location Code" := InternalMovementLine."Location Code";
            InternalMovementLine.TestField("From Bin Code");
            FromBinCode := InternalMovementLine."From Bin Code";
            InternalMovementLine.TestField("To Bin Code");
            InternalMovementLine.CheckBin(InternalMovementLine."Location Code", InternalMovementLine."From Bin Code", false);
            InternalMovementLine.CheckBin(InternalMovementLine."Location Code", InternalMovementLine."To Bin Code", true);

            NewWarehouseActivityLine."Bin Code" := InternalMovementLine."To Bin Code";
            NewWarehouseActivityLine."Item No." := InternalMovementLine."Item No.";
            NewWarehouseActivityLine."Variant Code" := InternalMovementLine."Variant Code";
            NewWarehouseActivityLine."Unit of Measure Code" := InternalMovementLine."Unit of Measure Code";
            NewWarehouseActivityLine."Qty. per Unit of Measure" := InternalMovementLine."Qty. per Unit of Measure";
            NewWarehouseActivityLine.Description := InternalMovementLine.Description;
            NewWarehouseActivityLine."Due Date" := InternalMovementLine."Due Date";
            RemQtyToPickBase := InternalMovementLine."Qty. (Base)";
            OnCreateInvtMvntWithoutSourceOnAfterTransferFields(NewWarehouseActivityLine, InternalMovementLine);
            PrepareItemTrackingForInternalMovement(InternalMovementLine);
            CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, false);
        until InternalMovementLine.Next() = 0;

        if NextLineNo = 10000 then
            Error(NothingToHandleMsg);

        MoveWhseComments(InternalMovementHeader."No.", CurrWarehouseActivityHeader."No.");

        if DeleteHandledInternalMovementLines(InternalMovementHeader."No.") then begin
            InternalMovementHeader.Delete(true);
            if not HideDialog then
                Message(ActivityCreatedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");
        end else
            if not HideDialog then
                Message(TrackingNotFullyAppliedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");

        OnAfterCreateInvtMvntWithoutSource(CurrWarehouseActivityHeader, InternalMovementHeader);
    end;

    /// <summary>
    /// Creates an inventory movement document for internal warehouse activities, based on provided warehouse worksheet line.
    /// </summary>
    /// <param name="InternalMovementHeader">Provided warehouse worksheet line.</param>
    procedure CreateInvtMvntWithoutSource(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    var
        WhseWorksheetLine2: Record "Whse. Worksheet Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RelatedBin: Record Bin;
        RemQtyToPickBase: Decimal;
    begin
        if not HideDialog then
            if not Confirm(CreateInvtMvmtQst, false) then
                exit;

        IsInvtMovement := true;
        IsBlankInvtMovement := true;

        WhseWorksheetLine.TestField("Location Code");

        if not SetFilterWhseWorksheetLine(WhseWorksheetLine2, WhseWorksheetLine) then begin
            RaiseNothingToHandleMessage();
            exit;
        end;
        // creating Inventory Movement Header
        Clear(CurrWarehouseActivityHeader);
        CurrWarehouseActivityHeader.Type := CurrWarehouseActivityHeader.Type::"Invt. Movement";
        CurrWarehouseActivityHeader.Insert(true);
        CurrWarehouseActivityHeader.Validate("Location Code", WhseWorksheetLine."Location Code");
        CurrWarehouseActivityHeader.Validate("Posting Date", WhseWorksheetLine."Due Date");
        CurrWarehouseActivityHeader.Modify();

        FindNextLineNo();

        repeat
            NewWarehouseActivityLine.Init();
            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
            WhseWorksheetLine2.TestField(WhseWorksheetLine2."Location Code");
            GetLocation(WhseWorksheetLine2."Location Code");
            if CurrLocation."Bin Mandatory" then
                NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
            NewWarehouseActivityLine."Location Code" := WhseWorksheetLine2."Location Code";
            if not CurrLocation."Pick According to FEFO" then
                WhseWorksheetLine2.TestField(WhseWorksheetLine2."From Bin Code");
            FromBinCode := WhseWorksheetLine2."From Bin Code";
            WhseWorksheetLine2.TestField(WhseWorksheetLine2."To Bin Code");
            WhseWorksheetLine2.CheckBin(WhseWorksheetLine2."Location Code", WhseWorksheetLine2."From Bin Code", false);
            WhseWorksheetLine2.CheckBin(WhseWorksheetLine2."Location Code", WhseWorksheetLine2."To Bin Code", true);

            NewWarehouseActivityLine."Bin Code" := WhseWorksheetLine2."To Bin Code";
            if WhseWorksheetLine2."To Bin Code" <> '' then begin
                RelatedBin.Get(CurrLocation.Code, WhseWorksheetLine2."To Bin Code");
                NewWarehouseActivityLine."Zone Code" := RelatedBin."Zone Code";
            end;
            NewWarehouseActivityLine."Item No." := WhseWorksheetLine2."Item No.";
            NewWarehouseActivityLine."Variant Code" := WhseWorksheetLine2."Variant Code";
            NewWarehouseActivityLine."Unit of Measure Code" := WhseWorksheetLine2."Unit of Measure Code";
            NewWarehouseActivityLine."Qty. per Unit of Measure" := WhseWorksheetLine2."Qty. per Unit of Measure";
            NewWarehouseActivityLine.Description := WhseWorksheetLine2.Description;
            NewWarehouseActivityLine."Due Date" := WhseWorksheetLine2."Due Date";
            RemQtyToPickBase := WhseWorksheetLine2."Qty. (Base)";
            PrepareItemTrackingForWhseMovement(WhseWorksheetLine2);
            OnCreateInvtMvntWithoutSourceOnBeforeCreatePickOrMoveLine(NewWarehouseActivityLine, WhseWorksheetLine2);
            CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, false);
        until WhseWorksheetLine2.Next() = 0;

        if NextLineNo = 10000 then
            Error(NothingToHandleMsg);

        MoveWhseComments(WhseWorksheetLine."Whse. Document No.", CurrWarehouseActivityHeader."No.");

        if DeleteHandledWhseWorksheetLines(WhseWorksheetLine.Name, WhseWorksheetLine."Worksheet Template Name") then begin
            if not HideDialog then
                Message(ActivityCreatedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");
        end else
            if (not HideDialog) and (not HideDialogForTracking) then
                Message(TrackingNotFullyAppliedMsg, CurrWarehouseActivityHeader.Type, CurrWarehouseActivityHeader."No.");
    end;

    local procedure DeleteHandledWhseWorksheetLines(WhseWorksheetName: Code[20]; WhseWorksheetTemplateName: Code[20]): Boolean
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        if TempInternalMovementLine.IsEmpty() then
            exit(false);

        WhseWorksheetLine.SetRange(Name, WhseWorksheetName);
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWorksheetTemplateName);
        WhseWorksheetLine.FindSet();
        repeat
            TempInternalMovementLine.SetRange("Item No.", WhseWorksheetLine."Item No.");
            TempInternalMovementLine.SetRange("Variant Code", WhseWorksheetLine."Variant Code");
            TempInternalMovementLine.SetRange("Location Code", WhseWorksheetLine."Location Code");
            TempInternalMovementLine.SetRange("Unit of Measure Code", WhseWorksheetLine."Unit of Measure Code");
            TempInternalMovementLine.SetRange("From Bin Code", WhseWorksheetLine."From Bin Code");
            TempInternalMovementLine.SetRange("To Bin Code", WhseWorksheetLine."To Bin Code");
            if TempInternalMovementLine.FindFirst() then
                if WhseWorksheetLine.Quantity <= TempInternalMovementLine.Quantity then begin
                    TempInternalMovementLine.Quantity -= WhseWorksheetLine.Quantity;
                    TempInternalMovementLine."Qty. (Base)" -= WhseWorksheetLine."Qty. (Base)";
                    if TempInternalMovementLine.Quantity = 0 then
                        TempInternalMovementLine.Delete()
                    else
                        TempInternalMovementLine.Modify();
                    WhseWorksheetLine.Delete(true);
                end else begin
                    WhseWorksheetLine.Quantity -= TempInternalMovementLine.Quantity;
                    WhseWorksheetLine."Qty. (Base)" -= TempInternalMovementLine."Qty. (Base)";
                    ItemTrackingManagement.DeleteWhseItemTrkgLines(
                      Database::"Whse. Worksheet Line", 0, WhseWorksheetLine.Name, WhseWorksheetLine."Worksheet Template Name", 0, WhseWorksheetLine."Line No.", WhseWorksheetLine."Location Code", true);
                    WhseWorksheetLine.Modify(true);
                    TempInternalMovementLine.Delete();
                end;
        until WhseWorksheetLine.Next() = 0;
        exit(WhseWorksheetLine.IsEmpty);
    end;

    local procedure DeleteHandledInternalMovementLines(InternalMovementHeaderNo: Code[20]): Boolean
    var
        InternalMovementLine: Record "Internal Movement Line";
    begin
        if TempInternalMovementLine.IsEmpty() then
            exit(false);

        InternalMovementLine.SetRange("No.", InternalMovementHeaderNo);
        OnDeleteHandledInternalMovementLinesOnAfterInternalMovementLineSetFilters(InternalMovementLine, InternalMovementHeaderNo);
        InternalMovementLine.FindSet();
        repeat
            TempInternalMovementLine.SetRange("Item No.", InternalMovementLine."Item No.");
            TempInternalMovementLine.SetRange("Variant Code", InternalMovementLine."Variant Code");
            TempInternalMovementLine.SetRange("Location Code", InternalMovementLine."Location Code");
            TempInternalMovementLine.SetRange("Unit of Measure Code", InternalMovementLine."Unit of Measure Code");
            TempInternalMovementLine.SetRange("From Bin Code", InternalMovementLine."From Bin Code");
            TempInternalMovementLine.SetRange("To Bin Code", InternalMovementLine."To Bin Code");
            if TempInternalMovementLine.FindFirst() then
                if InternalMovementLine.Quantity <= TempInternalMovementLine.Quantity then begin
                    TempInternalMovementLine.Quantity -= InternalMovementLine.Quantity;
                    TempInternalMovementLine."Qty. (Base)" -= InternalMovementLine."Qty. (Base)";
                    OnDeleteHandledInternalMovementLinesOnBeforeModifyTempInternalMovementLine(
                      TempInternalMovementLine, InternalMovementLine);
                    if TempInternalMovementLine.Quantity = 0 then
                        TempInternalMovementLine.Delete()
                    else
                        TempInternalMovementLine.Modify();
                    InternalMovementLine.Delete(true);
                end else begin
                    InternalMovementLine.Quantity -= TempInternalMovementLine.Quantity;
                    InternalMovementLine."Qty. (Base)" -= TempInternalMovementLine."Qty. (Base)";
                    ItemTrackingManagement.DeleteWhseItemTrkgLines(
                      Database::"Internal Movement Line", 0, InternalMovementLine."No.", '', 0, InternalMovementLine."Line No.", InternalMovementLine."Location Code", true);
                    OnDeleteHandledInternalMovementLinesOnBeforeInternalMovementLineModify(
                      InternalMovementLine, TempInternalMovementLine);
                    InternalMovementLine.Modify(true);
                    TempInternalMovementLine.Delete();
                end;
        until InternalMovementLine.Next() = 0;
        exit(InternalMovementLine.IsEmpty);
    end;

    local procedure PrepareItemTrackingForInternalMovement(InternalMovementLine: Record "Internal Movement Line")
    begin
        // function recopies warehouse item tracking into temporary item tracking table
        // when Invt. Movement is created from Internal Movement
        TempReservationEntry.Reset();
        TempReservationEntry.DeleteAll();

        PrepareItemTrackingFromWhse(
          Database::"Internal Movement Line", 0, InternalMovementLine."No.", '', 0, InternalMovementLine."Line No.", -1, false);

        OnAfterPrepareItemTrackingForInternalMovement(InternalMovementLine, TempReservationEntry);
    end;

    local procedure PrepareItemTrackingForWhseMovement(WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
        // function recopies warehouse item tracking into temporary item tracking table
        // when Invt. Movement is created from Whse. Worksheet Line
        TempReservationEntry.Reset();
        TempReservationEntry.DeleteAll();

        PrepareItemTrackingFromWhse(
          Database::"Whse. Worksheet Line", 0, WhseWorksheetLine.Name, WhseWorksheetLine."Worksheet Template Name", 0, WhseWorksheetLine."Line No.", -1, true);
    end;

    local procedure PrepareItemTrackingFromWhse(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceBatchName: Code[20]; SourceProdOrderLine: Integer; SourceLineNo: Integer; SignFactor: Integer; FromWhseWorksheet: Boolean)
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        if TempReservationEntry.FindLast() then
            EntryNo := TempReservationEntry."Entry No.";

        WhseItemTrackingLine.SetSourceFilter(SourceType, SourceSubtype, SourceNo, SourceLineNo, true);
        if FromWhseWorksheet then
            WhseItemTrackingLine.SetRange("Source Batch Name", SourceBatchName);
        if SourceProdOrderLine <> 0 then
            WhseItemTrackingLine.SetRange("Source Prod. Order Line", SourceProdOrderLine);
        if WhseItemTrackingLine.Find('-') then
            repeat
                TempReservationEntry.TransferFields(WhseItemTrackingLine);
                EntryNo += 1;
                TempReservationEntry."Entry No." := EntryNo;
                TempReservationEntry."Reservation Status" := TempReservationEntry."Reservation Status"::Surplus;
                TempReservationEntry.Validate("Quantity (Base)", TempReservationEntry."Quantity (Base)" * SignFactor);
                TempReservationEntry.Positive := (TempReservationEntry."Quantity (Base)" > 0);
                TempReservationEntry.UpdateItemTracking();
                OnBeforeTempReservEntryInsert(TempReservationEntry, WhseItemTrackingLine);
                TempReservationEntry.Insert();
            until WhseItemTrackingLine.Next() = 0;
        OnAfterPrepareItemTrackingFromWhseIT(TempReservationEntry, EntryNo);
    end;

    /// <summary>
    /// Synchronizes warehouse item tracking information with the tracking specification.
    /// </summary>
    /// <param name="TrackingSpecification">Provided tracking specification to synchronize.</param>
    procedure SynchronizeWhseItemTracking(var TrackingSpecification: Record "Tracking Specification")
    var
        WhseItemTrackingLine: Record "Whse. Item Tracking Line";
        EntryNo: Integer;
    begin
        // documents which have defined item tracking - table 337 will have to synchronize these records with 6550 table for invt. movement
        if WhseItemTrackingLine.FindLast() then
            EntryNo := WhseItemTrackingLine."Entry No.";
        EntryNo += 1;
        Clear(WhseItemTrackingLine);
        WhseItemTrackingLine.TransferFields(TrackingSpecification);
        WhseItemTrackingLine.Validate("Quantity (Base)", Abs(WhseItemTrackingLine."Quantity (Base)"));
        WhseItemTrackingLine.Validate("Qty. to Invoice (Base)", Abs(WhseItemTrackingLine."Qty. to Invoice (Base)"));
        WhseItemTrackingLine."Entry No." := EntryNo;
        OnBeforeWhseItemTrackingLineInsert(WhseItemTrackingLine, TrackingSpecification);
        WhseItemTrackingLine.Insert();
    end;

    local procedure MoveWhseComments(DocumentNo: Code[20]; InvtMovementNo: Code[20])
    var
        WarehouseCommentLine1: Record "Warehouse Comment Line";
        WarehouseCommentLine2: Record "Warehouse Comment Line";
    begin
        WarehouseCommentLine1.SetRange("Table Name", WarehouseCommentLine1."Table Name"::"Internal Movement");
        WarehouseCommentLine1.SetRange("No.", DocumentNo);
        WarehouseCommentLine1.LockTable();

        if WarehouseCommentLine1.Find('-') then begin
            repeat
                WarehouseCommentLine2.Init();
                WarehouseCommentLine2 := WarehouseCommentLine1;
                WarehouseCommentLine2."Table Name" := WarehouseCommentLine2."Table Name"::"Whse. Activity Header";
                WarehouseCommentLine2.Type := WarehouseCommentLine1.Type::"Invt. Movement";
                WarehouseCommentLine2."No." := InvtMovementNo;
                WarehouseCommentLine2.Insert();
            until WarehouseCommentLine1.Next() = 0;
            WarehouseCommentLine1.DeleteAll();
        end;
    end;

    /// <summary>
    /// Retrieves the message text for expired items.
    /// </summary>
    /// <returns>Text message for expired items.</returns>
    procedure GetExpiredItemMessage(): Text[100]
    begin
        exit(ExpiredItemMessageText);
    end;

    /// <summary>
    /// Determines whether strict expiration posting is required for an item based on the provided item tracking setup.
    /// </summary>
    /// <param name="ItemNo">Item number to check.</param>
    /// <param name="WhseItemTrackingSetup">Item tracking setup.</param>
    /// <returns>Returns 'true' if strict expiration posting is required, otherwise 'false'.</returns>
    procedure PickStrictExpirationPosting(ItemNo: Code[20]; WhseItemTrackingSetup: Record "Item Tracking Setup"): Boolean
    var
        StrictExpirationPosting: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePickStrictExpirationPosting(
            ItemNo, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required", StrictExpirationPosting, IsHandled);
        if IsHandled then
            exit(StrictExpirationPosting);

        exit(ItemTrackingManagement.StrictExpirationPosting(ItemNo) and WhseItemTrackingSetup.TrackingRequired());
    end;

    /// <summary>
    /// Creates a warehouse activity header if auto creation is enabled and no lines have been created yet.
    /// </summary>
    procedure MakeWarehouseActivityHeader()
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeHeader(CurrWarehouseActivityHeader, AutoCreation, IsHandled);
        if IsHandled then
            exit;

        if AutoCreation and not LineCreated then begin
            CurrWarehouseActivityHeader."No." := '';
            CurrWarehouseActivityHeader.Insert(true);
            UpdateWhseActivHeader(CurrWarehouseRequest);
            NextLineNo := 10000;
            if not SuppressCommit then
                Commit();
        end;
    end;

    /// <summary>
    /// Creates a warehouse activity line based on the provided parameters and updates remaining quantity.
    /// </summary>
    /// <param name="NewWarehouseActivityLine">Warehouse activity line to be created.</param>
    /// <param name="TakeBinCode">Provided bin code.</param>
    /// <param name="QtyToPickBase">Provided quantity to pick in base unit.</param>
    /// <param name="RemQtyToPickBase">Provided remaining quantity to pick in base unit.</param>
    procedure MakeWarehouseActivityLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeMakeWarehouseActivityLine(NewWarehouseActivityLine, RemQtyToPickBase, NextLineNo, TakeBinCode, QtyToPickBase, IsInvtMovement, LineCreated, CompleteShipment, IsHandled);
        if IsHandled then
            exit;

        NewWarehouseActivityLine.Quantity := NewWarehouseActivityLine.CalcQty(QtyToPickBase);
        NewWarehouseActivityLine."Qty. (Base)" := QtyToPickBase;
        NewWarehouseActivityLine."Qty. Outstanding" := NewWarehouseActivityLine.Quantity;
        NewWarehouseActivityLine."Qty. Outstanding (Base)" := NewWarehouseActivityLine."Qty. (Base)";
        SetLineData(NewWarehouseActivityLine, TakeBinCode);
        RemQtyToPickBase := RemQtyToPickBase - QtyToPickBase;
    end;

    /// <summary>
    /// Creates a warehouse activity line when serial number is required and updates remaining quantities.
    /// </summary>
    /// <param name="NewWarehouseActivityLine">Warehouse activity line to be created.</param>
    /// <param name="TakeBinCode">Provided bin code.</param>
    /// <param name="QtyToPickBase">Provided quantity to pick in base unit.</param>
    /// <param name="RemQtyToPickBase">Provided remaining quantity to pick in base unit.</param>
    /// <param name="RemQtyToPick">Provided remaining quantity to pick.</param>
    procedure MakeLineWhenSNoReq(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal; var RemQtyToPick: Decimal)
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        CalculatedPickQty: Decimal;
    begin
        CalculatedPickQty := NewWarehouseActivityLine.CalcQty(QtyToPickBase);
        if UnitOfMeasureManagement.RoundQty(UnitOfMeasureManagement.CalcBaseQty(RemQtyToPick - CalculatedPickQty, NewWarehouseActivityLine."Qty. per Unit of Measure"), 1) = 0 then
            NewWarehouseActivityLine.Quantity := RemQtyToPick
        else
            NewWarehouseActivityLine.Quantity := CalculatedPickQty;
        NewWarehouseActivityLine."Qty. (Base)" := QtyToPickBase;
        NewWarehouseActivityLine."Qty. Outstanding" := NewWarehouseActivityLine.Quantity;
        NewWarehouseActivityLine."Qty. Outstanding (Base)" := NewWarehouseActivityLine."Qty. (Base)";
        SetLineData(NewWarehouseActivityLine, TakeBinCode);
        RemQtyToPickBase -= QtyToPickBase;
        RemQtyToPick -= NewWarehouseActivityLine.Quantity;
    end;


    local procedure SetLineData(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20])
    var
        RelatedBin: Record Bin;
        PlaceBinCode: Code[20];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetLineData(NewWarehouseActivityLine, CurrWarehouseActivityHeader, TakeBinCode, NextLineNo, CurrLocation, LineCreated, IsHandled);
        if IsHandled then
            exit;

        PlaceBinCode := NewWarehouseActivityLine."Bin Code";
        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
        NewWarehouseActivityLine."Line No." := NextLineNo;
        if CurrLocation."Bin Mandatory" then begin
            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
            NewWarehouseActivityLine."Bin Code" := TakeBinCode;
            if TakeBinCode <> '' then begin
                RelatedBin.SetLoadFields("Zone Code");
                RelatedBin.Get(NewWarehouseActivityLine."Location Code", NewWarehouseActivityLine."Bin Code");
                NewWarehouseActivityLine."Zone Code" := RelatedBin."Zone Code";
            end;
            NewWarehouseActivityLine."Special Equipment Code" := GetSpecEquipmentCode(NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Variant Code", NewWarehouseActivityLine."Location Code", TakeBinCode);
        end else
            NewWarehouseActivityLine."Shelf No." := GetShelfNo(NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Variant Code", NewWarehouseActivityLine."Location Code");
        NewWarehouseActivityLine."Qty. to Handle" := 0;
        NewWarehouseActivityLine."Qty. to Handle (Base)" := 0;
        NewWarehouseActivityLine."Qty. Rounding Precision" := 0;
        OnBeforeNewWhseActivLineInsert(NewWarehouseActivityLine, CurrWarehouseActivityHeader);
        NewWarehouseActivityLine.Insert();
        if CurrLocation."Bin Mandatory" and IsInvtMovement then begin
            // Place Action for inventory movement
            OnMakeLineOnBeforeUpdatePlaceLine(NewWarehouseActivityLine, PlaceBinCode);
            NextLineNo := NextLineNo + 10000;
            NewWarehouseActivityLine."Line No." := NextLineNo;
            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Place;
            NewWarehouseActivityLine."Bin Code" := PlaceBinCode;
            if PlaceBinCode <> '' then begin
                RelatedBin.SetLoadFields("Zone Code");
                RelatedBin.Get(NewWarehouseActivityLine."Location Code", NewWarehouseActivityLine."Bin Code");
                NewWarehouseActivityLine."Zone Code" := RelatedBin."Zone Code";
            end;
            NewWarehouseActivityLine."Special Equipment Code" := GetSpecEquipmentCode(NewWarehouseActivityLine."Item No.", NewWarehouseActivityLine."Variant Code", NewWarehouseActivityLine."Location Code", PlaceBinCode);
            NewWarehouseActivityLine.Insert();
            UpdateHandledWhseActivityLineBuffer(NewWarehouseActivityLine, TakeBinCode);
        end;
        LineCreated := true;
        NextLineNo := NextLineNo + 10000;

        OnAfterSetLineData(CurrWarehouseActivityHeader, CurrLocation, NewWarehouseActivityLine);
    end;

    /// <summary>
    /// Retrieves the special equipment code based on the provided parameters.
    /// </summary>
    /// <param name="ItemNo">Item number for which to retrieve the special equipment code.</param>
    /// <param name="VariantCode">Variant code.</param>
    /// <param name="LocationCode">Location code.</param>
    /// <param name="BinCode">Bin code.</param>
    /// <returns>Returns special equipment code.</returns>
    procedure GetSpecEquipmentCode(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; BinCode: Code[20]): Code[10]
    begin
        GetLocation(LocationCode);
        case CurrLocation."Special Equipment" of
            CurrLocation."Special Equipment"::"According to Bin":
                begin
                    GetBin(CurrLocation.Code, BinCode);
                    if CurrBin."Special Equipment Code" <> '' then
                        exit(CurrBin."Special Equipment Code");

                    GetItemAndSKU(ItemNo, LocationCode, VariantCode);
                    if CurrStockKeepingUnit."Special Equipment Code" <> '' then
                        exit(CurrStockKeepingUnit."Special Equipment Code");

                    exit(CurrItem."Special Equipment Code")
                end;
            CurrLocation."Special Equipment"::"According to SKU/Item":
                begin
                    GetItemAndSKU(ItemNo, LocationCode, VariantCode);
                    if CurrStockKeepingUnit."Special Equipment Code" <> '' then
                        exit(CurrStockKeepingUnit."Special Equipment Code");

                    if CurrItem."Special Equipment Code" <> '' then
                        exit(CurrItem."Special Equipment Code");

                    GetBin(CurrLocation.Code, BinCode);
                    exit(CurrBin."Special Equipment Code")
                end
        end
    end;

    local procedure UpdateHandledWhseActivityLineBuffer(WarehouseActivityLine: Record "Warehouse Activity Line"; TakeBinCode: Code[20])
    begin
        TempInternalMovementLine.SetRange("Item No.", WarehouseActivityLine."Item No.");
        TempInternalMovementLine.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        TempInternalMovementLine.SetRange("Location Code", WarehouseActivityLine."Location Code");
        TempInternalMovementLine.SetRange("To Bin Code", WarehouseActivityLine."Bin Code");
        TempInternalMovementLine.SetRange("From Bin Code", TakeBinCode);
        TempInternalMovementLine.SetRange("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        if TempInternalMovementLine.FindFirst() then begin
            TempInternalMovementLine.Quantity += WarehouseActivityLine.Quantity;
            TempInternalMovementLine."Qty. (Base)" += WarehouseActivityLine."Qty. (Base)";
            OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineModify(
              TempInternalMovementLine, WarehouseActivityLine);
            TempInternalMovementLine.Modify();
        end else begin
            TempInternalMovementLine."No." := WarehouseActivityLine."No.";
            TempInternalMovementLine."Line No." := WarehouseActivityLine."Line No.";
            TempInternalMovementLine."Item No." := WarehouseActivityLine."Item No.";
            TempInternalMovementLine."Variant Code" := WarehouseActivityLine."Variant Code";
            TempInternalMovementLine."Location Code" := WarehouseActivityLine."Location Code";
            TempInternalMovementLine."To Bin Code" := WarehouseActivityLine."Bin Code";
            TempInternalMovementLine."From Bin Code" := TakeBinCode;
            TempInternalMovementLine.Quantity := WarehouseActivityLine.Quantity;
            TempInternalMovementLine."Qty. (Base)" := WarehouseActivityLine."Qty. (Base)";
            TempInternalMovementLine."Unit of Measure Code" := WarehouseActivityLine."Unit of Measure Code";
            OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineInsert(
              TempInternalMovementLine, WarehouseActivityLine);
            TempInternalMovementLine.Insert();
        end;
    end;

    /// <summary>
    /// Creates a warehouse activity line for assemble-to-order operation based on the provided parameters and updates remaining quantity to pick.
    /// </summary>
    /// <param name="NewWarehouseActivityLine">Provided warehouse activity line.</param>
    /// <param name="BinCode">Provided bin code.</param>
    /// <param name="RemQtyToPickBase">Provided remaining quantity to pick in base unit.</param>
    procedure CreateATOPickLine(NewWarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; var RemQtyToPickBase: Decimal)
    var
        ATOSalesLine: Record "Sales Line";
        ATOJobPlanningLine: Record "Job Planning Line";
        ATOLink: Record Microsoft.Assembly.Document."Assemble-to-Order Link";
        AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header";
        AssemblySetup: Record Microsoft.Assembly.Setup."Assembly Setup";
        ReservationEntry: Record "Reservation Entry";
        TempTrackingSpecification1: Record "Tracking Specification" temporary;
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        QtyToAsmBase: Decimal;
        QtyToPickBase: Decimal;
    begin
        if (not IsInvtMovement) and
           (WMSManagement.GetATOSalesLine(NewWarehouseActivityLine."Source Type",
             NewWarehouseActivityLine."Source Subtype",
             NewWarehouseActivityLine."Source No.",
             NewWarehouseActivityLine."Source Line No.",
             ATOSalesLine) or
            WMSManagement.GetATOJobPlanningLine(
             NewWarehouseActivityLine."Source Type",
             NewWarehouseActivityLine."Source No.",
             NewWarehouseActivityLine."Source Line No.",
             NewWarehouseActivityLine."Source Subline No.",
             ATOJobPlanningLine))
        then begin
            if ATOLink.AsmExistsForSalesLine(ATOSalesLine) then
                ATOSalesLine.AsmToOrderExists(AssemblyHeader)
            else
                if ATOLink.AsmExistsForJobPlanningLine(ATOJobPlanningLine) then begin
                    ATOJobPlanningLine.AsmToOrderExists(AssemblyHeader);
                    AssemblyHeader.PerformManualRelease();
                end;

            if NewWarehouseActivityLine.TrackingExists() then begin
                AssemblyHeader.SetReservationFilters(ReservationEntry);
                ReservationEntry.SetTrackingFilterFromWhseActivityLine(NewWarehouseActivityLine);
                ReservationEntry.SetRange(Positive, true);
                if ItemTrackingManagement.SumUpItemTracking(ReservationEntry, TempTrackingSpecification1, true, true) then
                    QtyToAsmBase := Abs(TempTrackingSpecification1."Qty. to Handle (Base)");
            end else
                if ATOLink.Type = ATOLink.Type::Sale then
                    QtyToAsmBase := ATOSalesLine.QtyToAsmBaseOnATO()
                else
                    if ATOLink.Type = ATOLink.Type::Job then
                        QtyToAsmBase := ATOJobPlanningLine.QtyToAsmBaseOnATO();
            WhseItemTrackingSetup.CopyTrackingFromWhseActivityLine(NewWarehouseActivityLine);
            if ATOLink.Type = ATOLink.Type::Sale then
                QtyToPickBase := QtyToAsmBase - WMSManagement.CalcQtyBaseOnATOInvtPick(ATOSalesLine, WhseItemTrackingSetup)
            else
                if ATOLink.Type = ATOLink.Type::Job then
                    QtyToPickBase := QtyToAsmBase - WMSManagement.CalcQtyBaseOnATOInvtPick(ATOJobPlanningLine, WhseItemTrackingSetup);
            OnCreateATOPickLineOnAfterCalcQtyToPickBase(RemQtyToPickBase, QtyToPickBase, ATOSalesLine);
            if QtyToPickBase > 0 then begin
                MakeWarehouseActivityHeader();
                if CurrLocation."Bin Mandatory" and (BinCode = '') then
                    if ATOLink.Type = ATOLink.Type::Sale then
                        ATOSalesLine.GetATOBin(CurrLocation, BinCode)
                    else
                        if ATOLink.Type = ATOLink.Type::Job then
                            ATOJobPlanningLine.GetATOBin(CurrLocation, BinCode);
                NewWarehouseActivityLine."Assemble to Order" := true;
                MakeWarehouseActivityLine(NewWarehouseActivityLine, BinCode, QtyToPickBase, RemQtyToPickBase);

                AssemblySetup.Get();
                if AssemblySetup."Create Movements Automatically" then
                    CreateATOInventoryMovementsAutomatically(AssemblyHeader, ATOInvtMovementsCreated, TotalATOInvtMovementsToBeCreated);
            end;
        end;
        OnAfterCreateATOPickLine(QtyToPickBase, AssemblyHeader, NewWarehouseActivityLine, CurrWarehouseActivityHeader, RemQtyToPickBase);
    end;

    local procedure CreateATOInventoryMovementsAutomatically(var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; var AssemToOrdInvtMovementsCreated: Integer; var TotalAssemToOrdInvtMovementsToBeCreated: Integer)
    var
        MovementsCreated: Integer;
        TotalMovementsCreated: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateATOInventoryMovementsAutomatically(AssemblyHeader, PrintDocument, ShowError, IsHandled);
        if IsHandled then
            exit;

        AssemblyHeader.CreateInvtMovement(true, PrintDocument, ShowError, MovementsCreated, TotalMovementsCreated);
        AssemToOrdInvtMovementsCreated += MovementsCreated;
        TotalAssemToOrdInvtMovementsToBeCreated += TotalMovementsCreated;
    end;

    procedure GetATOMovementsCounters(var MovementsCreated: Integer; var TotalMovementsCreated: Integer)
    begin
        MovementsCreated := ATOInvtMovementsCreated;
        TotalMovementsCreated := TotalATOInvtMovementsToBeCreated;
    end;

    local procedure Minimum(a: Decimal; b: Decimal): Decimal
    begin
        if a < b then
            exit(a);

        exit(b);
    end;

    local procedure CalcQtyAvailToPickOnBins(WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; RemQtyToPickBase: Decimal) Result: Decimal
    var
        BinContent: Record "Bin Content";
        TotalAvailQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcQtyAvailToPickOnBins(WarehouseActivityLine, WhseItemTrackingSetup."Lot No.", WhseItemTrackingSetup."Serial No.", RemQtyToPickBase, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TotalAvailQtyToPickBase := 0;

        BinContent.SetRange("Location Code", WarehouseActivityLine."Location Code");
        if FromBinCode <> '' then
            BinContent.SetRange("Bin Code", FromBinCode);
        BinContent.SetRange("Item No.", WarehouseActivityLine."Item No.");
        BinContent.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        BinContent.SetTrackingFilterFromWhseItemTrackingSetup(WhseItemTrackingSetup);
        if BinContent.Find('-') then
            repeat
                TotalAvailQtyToPickBase += BinContent.CalcQtyAvailToPick(0);
            until (BinContent.Next() = 0) or (TotalAvailQtyToPickBase >= RemQtyToPickBase);

        exit(TotalAvailQtyToPickBase);
    end;

    local procedure IsItemOnBins(WarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        BinContent.SetRange("Location Code", WarehouseActivityLine."Location Code");
        BinContent.SetRange("Item No.", WarehouseActivityLine."Item No.");
        BinContent.SetRange("Variant Code", WarehouseActivityLine."Variant Code");
        exit(not BinContent.IsEmpty);
    end;

    /// <summary>
    /// Sets the option to suppress committing transactions to the database.
    /// </summary>
    /// <param name="NewSuppressCommit">Boolean flag indicating whether to suppress commit.</param>
    /// <remarks>
    /// When 'SuppressCommit' is set to 'true', it indicates that transaction committed to the
    /// database should be suppressed. This can be useful in scenarios where batch processing or
    /// testing requires transactions to be rolled back rather than committed permanently.
    /// </remarks>
    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    local procedure CopyReservEntriesToTemp(var TempReservationEntry1: Record "Reservation Entry" temporary; var ReservationEntry: Record "Reservation Entry")
    begin
        TempReservationEntry1.Reset();
        TempReservationEntry1.DeleteAll();

        if ReservationEntry.FindSet() then
            repeat
                TempReservationEntry1 := ReservationEntry;
                TempReservationEntry1.Insert();
            until ReservationEntry.Next() = 0;
    end;

    local procedure UpdateExpirationDate(var WarehouseActivityLine: Record "Warehouse Activity Line"; var EntriesExist: Boolean)
    var
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        ExpirationDate: Date;
    begin
        ExpirationDate := ItemTrackingMgt.ExistingExpirationDate(WarehouseActivityLine, false, EntriesExist);

        if ExpirationDate <> 0D then
            WarehouseActivityLine."Expiration Date" := ExpirationDate;
    end;

    local procedure GetSourceLineNo(WarehouseActivityLine: Record "Warehouse Activity Line"): Integer
    begin
        if WarehouseActivityLine."Source Type" <> Database::Job then
            exit(WarehouseActivityLine."Source Line No.");

        exit(-1);
    end;

    procedure SetHideDialogForTracking(NewHideDialogForTracking: Boolean)
    begin
        HideDialogForTracking := NewHideDialogForTracking;
    end;

    procedure RaiseNothingToHandleMessage()
    begin
        if not HideDialog then
            Message(NothingToHandleMsg);
    end;

    local procedure ShouldSetBinCodeForBlankInvtMovement(NewWarehouseActivityLine: Record "Warehouse Activity Line"): Boolean
    begin
        if CheckItemTrackingCodeUseExpirationDates(NewWarehouseActivityLine."Item No.") and (NewWarehouseActivityLine."Expiration Date" <> 0D) then
            exit(false);

        exit(true);
    end;

    local procedure CheckItemTrackingCodeUseExpirationDates(ItemNo: Code[20]): Boolean
    var
        Item2: Record Item;
    begin
        if ItemNo = '' then
            exit;

        Item2.SetLoadFields("Item Tracking Code");
        Item2.Get(ItemNo);
        if Item2.ItemTrackingCodeUseExpirationDates() then
            exit(true);
    end;

    local procedure CorrectQtyRounding(SalesLine: Record "Sales Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        WareHouseActivityLine: Record "Warehouse Activity Line";
        TotalQtyPicked: Decimal;
        TotalQtyOutstanding: Decimal;
        TotalPickedQuantityCalculated: Decimal;
        TotalQtyOutStandingCalculated: Decimal;
    begin
        if WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Invt. Pick" then
            exit;

        WareHouseActivityLine.SetSource(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0);
        WareHouseActivityLine.SetRange("No.", WarehouseActivityHeader."No.");
        WareHouseActivityLine.CalcSums(Quantity, "Qty. (Base)", "Qty. Outstanding", "Qty. Outstanding (Base)");
        TotalQtyPicked := WareHouseActivityLine.Quantity;
        TotalQtyOutstanding := WareHouseActivityLine."Qty. Outstanding";
        TotalPickedQuantityCalculated := Round(WareHouseActivityLine."Qty. (Base)" / SalesLine."Qty. per Unit of Measure", 0.00001);
        TotalQtyOutStandingCalculated := Round(WareHouseActivityLine."Qty. Outstanding (Base)" / SalesLine."Qty. per Unit of Measure", 0.00001);
        if TotalQtyPicked = TotalPickedQuantityCalculated then
            exit;

        if Abs(TotalPickedQuantityCalculated - TotalQtyPicked) > SalesLine."Qty. Rounding Precision" then
            exit;

        WareHouseActivityLine.FindLast();
        WareHouseActivityLine.Quantity += (TotalPickedQuantityCalculated - TotalQtyPicked);
        WareHouseActivityLine."Qty. Outstanding" += (TotalQtyOutStandingCalculated - TotalQtyOutstanding);
        WareHouseActivityLine.Modify();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoCreatePickOrMove(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateATOPickLine(QtyToPickBase: Decimal; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInventoryPickMovement(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInvtMvntWithoutSource(WhseActivHeader: Record "Warehouse Activity Header"; var InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePickOrMoveFromTransfer(var WarehouseActivityHeader: Record "Warehouse Activity Header"; TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePickOrMoveFromSales(var WarehouseActivityHeader: Record "Warehouse Activity Header"; AutoCreation: Boolean; HideDialog: Boolean; var LineCreated: Boolean; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceDocHeader(var WarehouseRequest: Record "Warehouse Request"; var PostingDate: Date; var VendorDocNo: Code[35])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean; var RemQtyToPickBase: Decimal; var CompleteShipment: Boolean; var ReservationExists: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertPickOrMoveBinWhseActLine(WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcTotalAvailQtyToPickBase(ItemNo: Code[20]; VariantNo: Code[10]; SerialNo: Code[50]; LotNo: Code[50]; LocationCode: Code[10]; BinCode: Code[20]; SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSublineNo: Integer; RemQtyToPickBase: Decimal; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItemTrackingFromWhseIT(var ReservationEntry: Record "Reservation Entry"; EntryNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrepareItemTrackingForInternalMovement(InternalMovementLine: Record "Internal Movement Line"; var ReservationEntryBuffer: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; ShowError: Boolean; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetLineData(WarehouseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; var WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeAutoCreatePickOrMove(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean; var HideDialog: Boolean; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean; var CompleteShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDoc(WarehouseRequest: Record "Warehouse Request"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeCreatePickOrMoveLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LinesCreated: Boolean; var IsHandled: Boolean; var HideDialog: Boolean; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean; var CompleteShipment: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveFromSales(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; AutoCreation: Boolean; HideDialog: Boolean; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromSalesLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SalesLine: Record "Sales Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeCreatePickOrMoveLineFromProductionLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnBeforeCreatePickOrMoveLineFromProductionLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit MfgCreateInvtPickMovement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromProductionLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateATOInventoryMovementsAutomatically(AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; PrintDocumentForATOMvmt: Boolean; ShowErrorForATOMvmt: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromPurchaseLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromTransferLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean; TransferLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeCreatePickOrMoveLineFromAssemblyLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; var IsHandled: Boolean; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
        OnBeforeCreatePickOrMoveLineFromAssemblyLoop(WarehouseActivityHeader, AssemblyHeader, IsHandled, AssemblyLine);
    end;

    [Obsolete('Moved to codeunit AsmCreateInvtPickMovement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePickOrMoveLineFromAssemblyLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; var IsHandled: Boolean; AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateTempHandlingSpec(WarehouseActivityLine: Record "Warehouse Activity Line"; var TotalQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertPickOrMoveBinWhseActLine(NewWhseActivLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; var IsHandled: Boolean; var WhseRequest: Record "Warehouse Request"; var WhseActivHeader: Record "Warehouse Activity Header"; IsInvtMovement: Boolean; AutoCreation: Boolean; PostingDate: Date; VendorDocNo: Code[35]; var LineCreated: Boolean; var NextLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsert(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromPurchase(var WarehouseActivityLine: Record "Warehouse Activity Line"; var PurchaseLine: Record "Purchase Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromSales(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SalesLine: Record "Sales Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TransferLine: Record "Transfer Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeNewWhseActivLineInsertFromAssembly(var WarehouseActivityLine: Record "Warehouse Activity Line"; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
        OnBeforeNewWhseActivLineInsertFromAssembly(WarehouseActivityLine, AssemblyLine, WarehouseActivityHeader, RemQtyToPickBase);
    end;

    [Obsolete('Moved to codeunit AsmCreateInvtPickMovement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromAssembly(var WarehouseActivityLine: Record "Warehouse Activity Line"; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeNewWhseActivLineInsertFromComp(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
        OnBeforeNewWhseActivLineInsertFromComp(WarehouseActivityLine, ProdOrderComp, WarehouseActivityHeader, RemQtyToPickBase);
    end;

    [Obsolete('Moved to codeunit MfgCreateInvtPickMovement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromComp(var WarehouseActivityLine: Record "Warehouse Activity Line"; var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOnRun(var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; CheckLineExist: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTransLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeFindAssemblyLine(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        OnBeforeFindAssemblyLine(AssemblyLine, AssemblyHeader, WarehouseActivityHeader);
    end;

    [Obsolete('Moved to codeunit AsmCreateInvtPickMovement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAssemblyLine(var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        OnBeforeFindProdOrderComp(ProdOrderComp, ProductionOrder, WarehouseActivityHeader);
    end;

    [Obsolete('Moved to codeunit MfgCreateInvtPickMovement', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocHeader(var WhseRequest: Record "Warehouse Request"; var IsHandled: Boolean; var RecordExists: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickStrictExpirationPosting(ItemNo: Code[20]; SNRequired: Boolean; LNRequired: Boolean; var StrictExpirationPosting: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindFromBinContent(var FromBinContent: Record "Bin Content"; var WarehouseActivityLine: Record "Warehouse Activity Line"; FromBinCode: Code[20]; BinCode: Code[20]; IsInvtMovement: Boolean; IsBlankInvtMovement: Boolean; DefaultBin: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeHeader(WhseActivHeader: Record "Warehouse Activity Header"; var AutoCreation: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTempReservEntryInsert(var ReservationEntry: Record "Reservation Entry"; WhseItemTrackingLine: Record "Whse. Item Tracking Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeModifyWarehouseActivityHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseItemTrackingLineInsert(var WhseItemTrackingLine: Record "Whse. Item Tracking Line"; TrackingSpecification: Record "Tracking Specification")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRunCreatePickOrMoveLine(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRunCreatePickOrMoveLine(var WhseActivHeader: Record "Warehouse Activity Header"; var WhseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcInvtAvailabilityOnAfterCalcQtyBlocked(WarehouseActivityLine: Record "Warehouse Activity Line"; ItemTrackingSetup: Record "Item Tracking Setup"; var QtyBlocked: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateATOPickLineOnAfterCalcQtyToPickBase(var RemQtyToPickBase: Decimal; var QtyToPickBase: Decimal; ATOSalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterCheckForCompleteShipment(WarehouseActivityHeader: Record "Warehouse Activity Header"; WhseItemTrackingSetup: Record "Item Tracking Setup"; ReservationExists: Boolean; var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreatePickOrMoveLineOnAfterCalcQtyAvailToPickBase(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean; ReservationExists: Boolean; var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeOfSourceLineHandlingSpec(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; TempHandlingSpecification: Record "Tracking Specification"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var ITQtyToPickBase: Decimal; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreatePickOrMoveLineOnAfterFindTakeQtyForBinCodeSourceLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; var RemQtyToPickBase: Decimal; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterGetWhseItemTrkgSetup(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveFromSalesOnAfterCreatePickOrMoveLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var SalesLine: Record "Sales Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; ShowError: Boolean; AutoCreation: Boolean; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var WhseActivHeader: Record "Warehouse Activity Header"; CheckLineExist: Boolean; var Result: Boolean; var IsHandled: Boolean; IsInvtMovement: Boolean; var WarehouseSourceFilter: Record "Warehouse Source Filter"; ApplyAdditionalSourceDocFilters: Boolean; var SourceDocRecordVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvtMvntWithoutSourceOnAfterTransferFields(var WarehouseActivityLine: Record "Warehouse Activity Line"; InternalMovementLine: Record "Internal Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineFromHandlingSpec(var WarehouseActivityLine: Record "Warehouse Activity Line"; TrackingSpecification: Record "Tracking Specification"; EntriesExist: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAutoCreatePickOrMoveFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var WhseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; HideDialog: Boolean; var CompleteShipment: Boolean; CheckLineExist: Boolean; IsInvtMovement: Boolean; var WarehouseSourceFilter: Record "Warehouse Source Filter"; ApplyAdditionalSourceDocFilters: Boolean; ReservedFromStock: Enum "Reservation From Stock"; var SourceDocRecVar: Variant);
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreatePickOrMoveFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var WhseActivityHeader: Record "Warehouse Activity Header"; Location: Record Location; HideDialog: Boolean; var CompleteShipment: Boolean; CheckLineExist: Boolean; IsInvtMovement: Boolean; var WarehouseSourceFilter: Record "Warehouse Source Filter"; ApplySourceFilters: Boolean; ReservedFromStock: Enum "Reservation From Stock"; var SourceDocRecVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempHandlingSpecOnAfterCalcTotalAvailQtyToPickBase(WhseActivLine: Record "Warehouse Activity Line"; EntrySummary: Record "Entry Summary"; var TotalAvailQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempHandlingSpecOnAfterWhseItemTrackingFEFOSetSource(var WhseItemTrackingFEFO: Codeunit "Whse. Item Tracking FEFO"; WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateTempHandlingSpecOnAfterCalcQtyTracked(EntrySummary: Record "Entry Summary"; var QuantityTracked: Decimal; var TempHandlingSpecification: Record "Tracking Specification" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreatePickOrMoveLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LinesCreated: Boolean; AutoCreation: Boolean; var SuppressMessage: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHandledInternalMovementLinesOnAfterInternalMovementLineSetFilters(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeaderNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHandledInternalMovementLinesOnBeforeInternalMovementLineModify(var InternalMovementLine: Record "Internal Movement Line"; TempInternalMovementLine: Record "Internal Movement Line" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteHandledInternalMovementLinesOnBeforeModifyTempInternalMovementLine(var TempInternalMovementLine: Record "Internal Movement Line" temporary; InternalMovementLine: Record "Internal Movement Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; VendorDocNo: Code[35]; var RecordExists: Boolean; var SourceDocRecordVar: Variant)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetWhseRequestOnBeforeSourceDocumentsRun(var WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var Result: Boolean; var IsHandled: Boolean);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTempHandlingSpecOnBeforeValidateQtyBase(var TempTrackingSpecification: Record "Tracking Specification" temporary; EntrySummary: Record "Entry Summary")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInvtMvntWithoutSourceOnBeforeWhseActivHeaderModify(var WarehouseActivityHeader: Record "Warehouse Activity Header"; InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnItemTrackedQuantityOnAfterCheckTracking(var TempHandlingSpecification: Record "Tracking Specification" temporary; WhseItemTrackingSetup: Record "Item Tracking Setup"; var IsTrackingEmpty: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnMakeLineOnBeforeUpdatePlaceLine(var NewWhseActivLine: Record "Warehouse Activity Line"; var PlaceBinCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFilterInternalMomementOnAfterSetFilters(var InternalMovementLine: Record "Internal Movement Line"; InternalMovementHeader: Record "Internal Movement Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetFilterJobPlanningLineOnBeforeJobPlanningLineFind(var JobPlanningLine: Record "Job Planning Line"; Job: Record Job; var WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineInsert(var TempInternalMovementLine: Record "Internal Movement Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateHandledWhseActivityLineBufferOnBeforeTempInternalMovementLineModify(var TempInternalMovementLine: Record "Internal Movement Line" temporary; WarehouseActivityLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeLoopMakeLine(var WhseActivHeader: Record "Warehouse Activity Header"; WhseRequest: Record "Warehouse Request"; var NewWhseActivLine: Record "Warehouse Activity Line"; FromBinContent: Record "Bin Content"; AutoCreation: Boolean; var QtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeLoopIteration(var FromBinContent: Record "Bin Content"; NewWarehouseActivityLine: Record "Warehouse Activity Line"; BinCode: Code[20]; DefaultBin: Boolean; var RemQtyToPickBase: Decimal; var IsHandled: Boolean; var QtyAvailToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnAfterCalcShouldInsertPickOrMoveDefaultBin(NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; OutstandingQtyBase: Decimal; ReservationExists: Boolean; var ShouldInsertPickOrMoveDefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnAfterCalcQtyAvailToPick(var QtyAvailToPickBase: Decimal; var FromBinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcInvtAvailability(WhseActivLine: Record "Warehouse Activity Line"; Location: Record Location; var Result: Decimal; var IsHandled: Boolean; WhseItemTrackingSetup: Record "Item Tracking Setup"; IsBlankInvtMovement: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyAvailToPickOnBins(WhseActivLine: Record "Warehouse Activity Line"; LotNo: Code[50]; SerialNo: Code[50]; RemQtyToPickBase: Decimal; var Result: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertShelfWhseActivLineOnAfterMakeHeader(var NewWhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveFromTransferOnAfterCreatePickOrMoveLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TransferLine: Record "Transfer Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; ShowError: Boolean; AutoCreation: Boolean; var LineCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAutoCreatePickOrMoveOnBeforeWarehouseActivityHeaderModify(var WarehouseActivityHeader: Record "Warehouse Activity Header"; WarehouseRequest: Record "Warehouse Request"; Location: Record Location)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeMakeHeader(var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var DefaultBin: Boolean; var FromBinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnAfterMakeLine(var QtyToPickBase: Decimal; var DefaultBin: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePickOrMoveLineOnBeforeCheckIfInsertPickOrMoveBinWhseActLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertPickOrMoveBinWhseActLineOnBeforeMakeLineWhenSNoReq(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; TakeBinCode: Code[20]; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal; var QtyAvailToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertShelfWhseActivLineOnBeforeMakeShelfLineWhenSNoReq(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; QtyToPickBase: Decimal; var RemQtyToPickBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertPickOrMoveBinWhseActivityLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeMakeWarehouseActivityLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var RemQtyToPickBase: Decimal; var NextLineNo: Integer; TakeBinCode: Code[20]; var QtyToPickBase: Decimal; IsInvtMovement: Boolean; var LineCreated: Boolean; CompleteShipment: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertShelfWhseActivLineOnAfterMakeWarehouseActivityLine(var NewWhseActivLine: Record "Warehouse Activity Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetLineData(var WarehouseActivityLine: Record "Warehouse Activity Line"; WarehouseActivityHeader: Record "Warehouse Activity Header"; TakeBinCode: Code[20]; var NextLineNo: Integer; Location: Record Location; var LineCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateInvtMvntWithoutSourceOnBeforeCreatePickOrMoveLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromJobPlanning(var WarehouseActivityLine: Record "Warehouse Activity Line"; var JobPlanningLine: Record "Job Planning Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;
}

