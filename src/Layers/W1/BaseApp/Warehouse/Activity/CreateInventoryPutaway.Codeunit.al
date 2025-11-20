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
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Setup;
using Microsoft.Warehouse.Structure;
using System.Telemetry;

codeunit 7321 "Create Inventory Put-away"
{
    TableNo = "Warehouse Activity Header";

    trigger OnRun()
    begin
        CurrWarehouseActivityHeader := Rec;
        Code();
        Rec := CurrWarehouseActivityHeader;
    end;

    var
        CurrWarehouseActivityHeader: Record "Warehouse Activity Header";
        CurrWarehouseRequest: Record "Warehouse Request";
        CurrLocation: Record Location;
        CurrBin: Record Bin;
        CurrItem: Record Item;
        CurrPutAwayTemplateHeader: Record "Put-away Template Header";
        CurrStockkeepingUnit: Record "Stockkeeping Unit";
        TempTrackingSpecification: Record "Tracking Specification" temporary;
        WarehouseSourceFilter: Record "Warehouse Source Filter";
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        FeatureTelemetry: Codeunit "Feature Telemetry";
        SourceDocRecordRef: RecordRef;
        SourceDocRecordVar: Variant;
        PostingDate: Date;
        VendorDocNo: Code[35];
        WarehouseClassCode: Code[10];
        RemQtyToPutAway: Decimal;
        NextLineNo: Integer;
        LineCreated: Boolean;
        ReservationFound: Boolean;
        HideDialog: Boolean;
        CheckLineExist: Boolean;
        AutoCreation: Boolean;
        ApplySourceFilters: Boolean;
        NothingToHandleMsg: Label 'Nothing to handle.';
        BinPolicyTelemetryCategoryTok: Label 'Bin Policy', Locked = true;
        DefaultBinPutawayPolicyTelemetryTok: Label 'Default Bin Put-away Policy in used for inventory put-away.', Locked = true;
        PutawayTemplateBinPickPolicyTelemetryTok: Label 'Put-away template Bin Put-away Policy in used for inventory put-away.', Locked = true;

    local procedure "Code"()
    var
        IsHandled: Boolean;
        SuppressError: Boolean;
    begin
        CurrWarehouseActivityHeader.TestField("No.");
        CurrWarehouseActivityHeader.TestField("Location Code");

        if not HideDialog then
            if not GetWhseRequest(CurrWarehouseRequest) then
                exit;

        GetSourceDocHeader();
        UpdateWhseActivHeader(CurrWarehouseRequest);

        IsHandled := false;
        OnBeforeCreatePutAwayLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, IsHandled, HideDialog);
        if IsHandled then
            exit;

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                CreatePutAwayLinesFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                CreatePutAwayLinesFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Order":
                CreatePutAwayLinesFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                CreatePutAwayLinesFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Inbound Transfer":
                CreatePutAwayLinesFromTransfer(SourceDocRecordVar);
            else
                OnCreatePutAwayFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, LineCreated, SourceDocRecordVar,
                    CurrWarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters,
                    RemQtyToPutAway);
        end;

        IsHandled := false;
        SuppressError := false;
        OnCodeOnAfterCreatePutAwayLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, AutoCreation, SuppressError, IsHandled);
        if IsHandled then
            exit;

        if LineCreated then
            CurrWarehouseActivityHeader.Modify()
        else
            if not AutoCreation then
                if not SuppressError then
                    Error(NothingToHandleMsg);

        OnAfterCreateInventoryPutaway(CurrWarehouseRequest, LineCreated, CurrWarehouseActivityHeader);
    end;

    local procedure GetWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        IsHandled: Boolean;
    begin
        WarehouseRequest.FilterGroup := 2;
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        if CurrWarehouseActivityHeader."Source Document" <> CurrWarehouseActivityHeader."Source Document"::" " then
            WarehouseRequest.SetRange("Source Document", CurrWarehouseActivityHeader."Source Document");
        if CurrWarehouseActivityHeader."Source No." <> '' then
            WarehouseRequest.SetRange("Source No.", CurrWarehouseActivityHeader."Source No.");
        WarehouseRequest.SetRange("Completely Handled", false);
        WarehouseRequest.FilterGroup := 0;

        IsHandled := false;
        OnGetWhseRequestOnAfterFilterGroup(WarehouseRequest, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if PAGE.RunModal(
             PAGE::"Source Documents", WarehouseRequest, WarehouseRequest."Source No.") = ACTION::LookupOK
        then
            exit(true);
    end;

    local procedure GetSourceDocHeader()
    var
        PurchaseHeader: Record "Purchase Header";
        SalesHeader: Record "Sales Header";
        TransferHeader: Record "Transfer Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocHeader(CurrWarehouseRequest, IsHandled);
        if IsHandled then
            exit;

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, CurrWarehouseRequest."Source No.");
                    PostingDate := PurchaseHeader."Posting Date";
                    VendorDocNo := PurchaseHeader."Vendor Invoice No.";
                    SourceDocRecordVar := PurchaseHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                begin
                    PurchaseHeader.Get(PurchaseHeader."Document Type"::"Return Order", CurrWarehouseRequest."Source No.");
                    PostingDate := PurchaseHeader."Posting Date";
                    VendorDocNo := PurchaseHeader."Vendor Cr. Memo No.";
                    SourceDocRecordVar := PurchaseHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Sales Order":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::Order, CurrWarehouseRequest."Source No.");
                    PostingDate := SalesHeader."Posting Date";
                    SourceDocRecordVar := SalesHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                begin
                    SalesHeader.Get(SalesHeader."Document Type"::"Return Order", CurrWarehouseRequest."Source No.");
                    PostingDate := SalesHeader."Posting Date";
                    SourceDocRecordVar := SalesHeader;
                end;
            CurrWarehouseRequest."Source Document"::"Inbound Transfer":
                begin
                    TransferHeader.Get(CurrWarehouseRequest."Source No.");
                    PostingDate := TransferHeader."Posting Date";
                    SourceDocRecordVar := TransferHeader;
                end;
            else
                OnGetSourceDocHeaderForWhseRequest(CurrWarehouseRequest, SourceDocRecordRef, PostingDate, VendorDocNo, SourceDocRecordVar);
        end;
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
        CurrWarehouseActivityHeader."Expected Receipt Date" := WarehouseRequest."Expected Receipt Date";
        CurrWarehouseActivityHeader."Posting Date" := PostingDate;
        CurrWarehouseActivityHeader."External Document No.2" := VendorDocNo;

        OnUpdateWhseActivHeaderOnBeforeGetLocation(WarehouseRequest, CurrWarehouseActivityHeader);
        GetLocation(WarehouseRequest."Location Code");

        OnAfterUpdateWhseActivHeader(CurrWarehouseActivityHeader, WarehouseRequest);
    end;

    procedure SetSourceDocDetailsFilter(var WarehouseSourceFilter2: Record "Warehouse Source Filter")
    begin
        if WarehouseSourceFilter2.GetFilters() <> '' then begin
            ApplySourceFilters := true;
            WarehouseSourceFilter.Reset();
            WarehouseSourceFilter.CopyFilters(WarehouseSourceFilter2);
        end;
    end;

    // Purchase 
    local procedure CreatePutAwayLinesFromPurchase(PurchaseHeaderVar: Variant)
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        PurchaseHeader := PurchaseHeaderVar;

        if not SetFilterPurchLine(PurchaseLine, PurchaseHeader) then begin
            GetNothingToHandleMsg();
            exit;
        end;

        FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePutAwayLinesFromPurchaseLoop(CurrWarehouseActivityHeader, PurchaseHeader, IsHandled, PurchaseLine);
            if not IsHandled and PurchaseLine.IsInventoriableItem() then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, 0) then begin
                    GetLocation(PurchaseLine."Location Code");

                    if PurchaseLine."Document Type" = PurchaseLine."Document Type"::Order then
                        RemQtyToPutAway := PurchaseLine."Qty. to Receive"
                    else
                        RemQtyToPutAway := -PurchaseLine."Return Qty. to Ship";
                    OnCreatePutAwayLinesFromPurchaseOnAfterSetRemQtyToPutAway(PurchaseHeader, PurchaseLine, CurrWarehouseActivityHeader, RemQtyToPutAway);

                    FindReservationFromPurchaseLine(PurchaseLine);

                    if CurrLocation."Bin Mandatory" then
                        case CurrLocation."Put-away Bin Policy" of
                            CurrLocation."Put-away Bin Policy"::"Default Bin":
                                begin
                                    FeatureTelemetry.LogUsage('0000KP3', BinPolicyTelemetryCategoryTok, DefaultBinPutawayPolicyTelemetryTok);
                                    CreatePutawayWithDefaultBinPolicy(PurchaseLine);
                                end;
                            CurrLocation."Put-away Bin Policy"::"Put-away Template":
                                begin
                                    FeatureTelemetry.LogUsage('0000KP4', BinPolicyTelemetryCategoryTok, PutawayTemplateBinPickPolicyTelemetryTok);
                                    CreatePutawayWithPutawayTemplateBinPolicy(PurchaseLine);
                                end;
                            else
                                OnCreatePutawayForPurchaseLine(PurchaseLine, RemQtyToPutAway);
                        end;

                    if (CurrLocation."Always Create Put-away Line" or not CurrLocation."Bin Mandatory") and (RemQtyToPutAway > 0) then
                        repeat
                            CreateWarehouseActivityLine(
                                Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.", 0, PurchaseLine."Location Code",
                                PurchaseLine."No.", PurchaseLine."Variant Code", PurchaseLine."Unit of Measure Code",
                                PurchaseLine."Qty. per Unit of Measure", PurchaseLine."Qty. Rounding Precision", PurchaseLine."Qty. Rounding Precision (Base)",
                                PurchaseLine.Description, PurchaseLine."Description 2", PurchaseLine."Expected Receipt Date", '', PurchaseLine);
                        until RemQtyToPutAway <= 0;
                end;
        until PurchaseLine.Next() = 0;
        OnAfterCreatePutAwayLinesFromPurchase(PurchaseHeader, CurrWarehouseActivityHeader);
    end;

    local procedure CreatePutawayWithDefaultBinPolicy(var PurchaseLineToPutaway: Record "Purchase Line")
    var
        DefaultBinCode: Code[20];
        BinCodeToUse: Code[20];
    begin
        DefaultBinCode := GetDefaultBinCode(PurchaseLineToPutaway."No.", PurchaseLineToPutaway."Variant Code", PurchaseLineToPutaway."Location Code");

        if (DefaultBinCode = '') and (PurchaseLineToPutaway."Bin Code" = '') then
            exit;

        repeat
            if PurchaseLineToPutaway."Bin Code" = '' then
                BinCodeToUse := DefaultBinCode
            else
                BinCodeToUse := PurchaseLineToPutaway."Bin Code";

            CreateWarehouseActivityLine(Database::"Purchase Line", PurchaseLineToPutaway."Document Type".AsInteger(), PurchaseLineToPutaway."Document No.", PurchaseLineToPutaway."Line No.", 0,
                PurchaseLineToPutaway."Location Code", PurchaseLineToPutaway."No.", PurchaseLineToPutaway."Variant Code", PurchaseLineToPutaway."Unit of Measure Code",
                PurchaseLineToPutaway."Qty. per Unit of Measure", PurchaseLineToPutaway."Qty. Rounding Precision", PurchaseLineToPutaway."Qty. Rounding Precision (Base)",
                PurchaseLineToPutaway.Description, PurchaseLineToPutaway."Description 2", PurchaseLineToPutaway."Expected Receipt Date", BinCodeToUse, PurchaseLineToPutaway)

        until RemQtyToPutAway <= 0;
    end;

    local procedure CreatePutawayWithPutawayTemplateBinPolicy(var PurchaseLineToPutaway: Record "Purchase Line")
    begin
        CreatePutawayWithPutawayTemplateBinPolicy(Database::"Purchase Line", PurchaseLineToPutaway."Document Type".AsInteger(), PurchaseLineToPutaway."Document No.", PurchaseLineToPutaway."Line No.", 0,
                                                            PurchaseLineToPutaway."Location Code", PurchaseLineToPutaway."Bin Code", PurchaseLineToPutaway."No.", PurchaseLineToPutaway."Variant Code", PurchaseLineToPutaway."Quantity (Base)",
                                                            PurchaseLineToPutaway."Unit of Measure Code", PurchaseLineToPutaway."Qty. per Unit of Measure", PurchaseLineToPutaway."Qty. Rounding Precision",
                                                            PurchaseLineToPutaway."Qty. Rounding Precision (Base)", PurchaseLineToPutaway.Description, PurchaseLineToPutaway."Description 2", PurchaseLineToPutaway."Expected Receipt Date");
    end;

    local procedure FindReservationFromPurchaseLine(var PurchaseLine: Record "Purchase Line")
    var
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReservationFromPurchaseLine(PurchaseLine, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingManagement.GetWhseItemTrkgSetup(PurchaseLine."No.", WhseItemTrackingSetup);
        if WhseItemTrackingSetup.TrackingRequired() then
            ReservationFound := FindReservationEntry(Database::"Purchase Line", PurchaseLine."Document Type".AsInteger(), PurchaseLine."Document No.", PurchaseLine."Line No.");
    end;

    procedure SetFilterPurchLine(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header"): Boolean
    begin
        if CurrLocation.RequireReceive(CurrWarehouseRequest."Location Code") then
            exit(false);

        PurchaseLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange("Drop Shipment", false);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            PurchaseLine.SetRange("Job No.", '');
        if not CheckLineExist then
            PurchaseLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order then
            PurchaseLine.SetFilter("Qty. to Receive", '>%1', 0)
        else
            PurchaseLine.SetFilter("Return Qty. to Ship", '<%1', 0);

        if ApplySourceFilters then begin
            PurchaseLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            PurchaseLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            PurchaseLine.SetFilter("Planned Receipt Date", WarehouseSourceFilter.GetFilter("Receipt Date Filter"));
        end;

        OnBeforeFindPurchLine(PurchaseLine, CurrWarehouseActivityHeader);

        PurchaseLine.SetLoadFields(Type, "No.", "Document Type", "Document No.", "Line No.", "Location Code", "Bin Code", "Qty. to Receive", "Return Qty. to Ship", "Variant Code",
            "Unit of Measure Code", "Qty. per Unit of Measure", "Qty. Rounding Precision", "Qty. Rounding Precision (Base)", Description, "Description 2", "Planned Receipt Date",
            "Expected Receipt Date", "Quantity (Base)", Quantity);
        exit(PurchaseLine.FindFirst());
    end;

    // Sales
    local procedure CreatePutAwayLinesFromSales(SalesHeaderVar: Variant)
    var
        SalesHeader: Record "Sales Header";
        SalesLine: Record "Sales Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        SalesHeader := SalesHeaderVar;

        if not SetFilterSalesLine(SalesLine, SalesHeader) then begin
            GetNothingToHandleMsg();
            exit;
        end;

        FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePutAwayLinesFromSalesLoop(CurrWarehouseActivityHeader, SalesHeader, IsHandled, SalesLine);
            if not IsHandled and SalesLine.IsInventoriableItem() then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0, 0) then begin
                    GetLocation(SalesLine."Location Code");
                    if SalesLine."Document Type" = SalesLine."Document Type"::Order then
                        RemQtyToPutAway := -SalesLine."Qty. to Ship"
                    else
                        RemQtyToPutAway := SalesLine."Return Qty. to Receive";

                    OnCreatePutAwayLinesFromSalesOnAfterSetRemQtyToPutAway(SalesHeader, SalesLine, CurrWarehouseActivityHeader, RemQtyToPutAway);

                    FindReservationFromSalesLine(SalesLine);

                    if CurrLocation."Bin Mandatory" then
                        case CurrLocation."Put-away Bin Policy" of
                            CurrLocation."Put-away Bin Policy"::"Default Bin":
                                CreatePutawayWithDefaultBinPolicy(SalesLine);
                            CurrLocation."Put-away Bin Policy"::"Put-away Template":
                                CreatePutawayWithPutawayTemplateBinPolicy(SalesLine);
                            else
                                OnCreatePutawayForSalesLine(SalesLine, RemQtyToPutAway);
                        end;

                    if (CurrLocation."Always Create Put-away Line" or not CurrLocation."Bin Mandatory") and (RemQtyToPutAway > 0) then
                        repeat
                            CreateWarehouseActivityLine(
                                Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0,
                                SalesLine."Location Code", SalesLine."No.", SalesLine."Variant Code", SalesLine."Unit of Measure Code",
                                SalesLine."Qty. per Unit of Measure", SalesLine."Qty. Rounding Precision", SalesLine."Qty. Rounding Precision (Base)",
                                SalesLine.Description, SalesLine."Description 2", SalesLine."Planned Shipment Date", '', SalesLine);
                        until RemQtyToPutAway <= 0;
                end;
        until SalesLine.Next() = 0;
        OnAfterCreatePutAwayLinesFromSales(SalesHeader, CurrWarehouseActivityHeader);
    end;

    local procedure CreatePutawayWithDefaultBinPolicy(var SalesLineToPutaway: Record "Sales Line")
    var
        DefaultBinCode: Code[20];
        BinCodeToUse: Code[20];
    begin
        DefaultBinCode := GetDefaultBinCode(SalesLineToPutaway."No.", SalesLineToPutaway."Variant Code", SalesLineToPutaway."Location Code");

        if (DefaultBinCode = '') and (SalesLineToPutaway."Bin Code" = '') then
            exit;

        repeat
            if SalesLineToPutaway."Bin Code" = '' then
                BinCodeToUse := DefaultBinCode
            else
                BinCodeToUse := SalesLineToPutaway."Bin Code";

            CreateWarehouseActivityLine(
                Database::"Sales Line", SalesLineToPutaway."Document Type".AsInteger(), SalesLineToPutaway."Document No.", SalesLineToPutaway."Line No.", 0,
                SalesLineToPutaway."Location Code", SalesLineToPutaway."No.", SalesLineToPutaway."Variant Code", SalesLineToPutaway."Unit of Measure Code",
                SalesLineToPutaway."Qty. per Unit of Measure", SalesLineToPutaway."Qty. Rounding Precision", SalesLineToPutaway."Qty. Rounding Precision (Base)",
                SalesLineToPutaway.Description, SalesLineToPutaway."Description 2", SalesLineToPutaway."Planned Shipment Date", BinCodeToUse, SalesLineToPutaway);

        until RemQtyToPutAway <= 0;
    end;

    local procedure CreatePutawayWithPutawayTemplateBinPolicy(var SalesLineToPutaway: Record "Sales Line")
    begin
        CreatePutawayWithPutawayTemplateBinPolicy(
            Database::"Sales Line", SalesLineToPutaway."Document Type".AsInteger(), SalesLineToPutaway."Document No.", SalesLineToPutaway."Line No.", 0,
            SalesLineToPutaway."Location Code", SalesLineToPutaway."Bin Code", SalesLineToPutaway."No.", SalesLineToPutaway."Variant Code", SalesLineToPutaway."Quantity (Base)",
            SalesLineToPutaway."Unit of Measure Code", SalesLineToPutaway."Qty. per Unit of Measure", SalesLineToPutaway."Qty. Rounding Precision",
            SalesLineToPutaway."Qty. Rounding Precision (Base)", SalesLineToPutaway.Description, SalesLineToPutaway."Description 2", SalesLineToPutaway."Planned Shipment Date");
    end;

    local procedure FindReservationFromSalesLine(var SalesLine: Record "Sales Line")
    var
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReservationFromSalesLine(SalesLine, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingManagement.GetWhseItemTrkgSetup(SalesLine."No.", WhseItemTrackingSetup);
        if WhseItemTrackingSetup.TrackingRequired() then
            ReservationFound := FindReservationEntry(Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.");
    end;

    procedure SetFilterSalesLine(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"): Boolean
    begin
        if CurrLocation.RequireReceive(CurrWarehouseRequest."Location Code") then
            exit(false);

        SalesLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange("Drop Shipment", false);
        if not CheckLineExist then
            SalesLine.SetRange("Location Code", CurrWarehouseActivityHeader."Location Code");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        if SalesHeader."Document Type" = SalesHeader."Document Type"::Order then
            SalesLine.SetFilter("Qty. to Ship", '<%1', 0)
        else
            SalesLine.SetFilter("Return Qty. to Receive", '>%1', 0);

        if ApplySourceFilters then begin
            SalesLine.SetFilter("No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            SalesLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            SalesLine.SetFilter("Shipment Date", WarehouseSourceFilter.GetFilter("Receipt Date Filter"));
        end;

        OnBeforeFindSalesLine(SalesLine, CurrWarehouseActivityHeader);

        SalesLine.SetLoadFields(Type, "No.", "Document Type", "Document No.", "Line No.", "Location Code", "Qty. to Ship", "Return Qty. to Receive", "Variant Code", "Bin Code",
                                "Unit of Measure Code", "Qty. per Unit of Measure", "Qty. Rounding Precision", "Qty. Rounding Precision (Base)", "Description", "Description 2",
                                "Planned Shipment Date", "Quantity (Base)", Quantity);
        exit(SalesLine.FindFirst());
    end;

    // Transfer
    local procedure CreatePutAwayLinesFromTransfer(TransferHeaderVar: Variant)
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        TransferHeader := TransferHeaderVar;

        if not SetFilterTransferLine(TransferLine, TransferHeader) then begin
            GetNothingToHandleMsg();
            exit;
        end;

        FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePutAwayLinesFromTransferLoop(CurrWarehouseActivityHeader, TransferHeader, IsHandled, TransferLine);
            if not IsHandled then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 0, 0) then begin
                    GetLocation(TransferLine."Transfer-to Code");

                    RemQtyToPutAway := TransferLine."Qty. to Receive";
                    OnCreatePutAwayLinesFromTransferOnAfterSetRemQtyToPutAway(TransferHeader, TransferLine, CurrWarehouseActivityHeader, RemQtyToPutAway);

                    FindReservationFromTransferLine(TransferLine);

                    if CurrLocation."Bin Mandatory" then
                        case CurrLocation."Put-away Bin Policy" of
                            CurrLocation."Put-away Bin Policy"::"Default Bin":
                                CreatePutawayWithDefaultBinPolicy(TransferLine);
                            CurrLocation."Put-away Bin Policy"::"Put-away Template":
                                CreatePutawayWithPutawayTemplateBinPolicy(TransferLine);
                            else
                                OnCreatePutawayForTransferLine(TransferLine, RemQtyToPutAway);
                        end;

                    if (CurrLocation."Always Create Put-away Line" or not CurrLocation."Bin Mandatory") and (RemQtyToPutAway > 0) then
                        repeat
                            CreateWarehouseActivityLine(
                                Database::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.", 0,
                                TransferLine."Transfer-to Code", TransferLine."Item No.", TransferLine."Variant Code", TransferLine."Unit of Measure Code",
                                TransferLine."Qty. per Unit of Measure", TransferLine."Qty. Rounding Precision", TransferLine."Qty. Rounding Precision (Base)",
                                TransferLine.Description, TransferLine."Description 2", TransferLine."Receipt Date", '', TransferLine);
                        until RemQtyToPutAway <= 0;
                end;
        until TransferLine.Next() = 0;
    end;

    local procedure CreatePutawayWithDefaultBinPolicy(var TransferLineToPutaway: Record "Transfer Line")
    var
        DefaultBinCode: Code[20];
        BinCodeToUse: Code[20];
    begin
        DefaultBinCode := GetDefaultBinCode(TransferLineToPutaway."Item No.", TransferLineToPutaway."Variant Code", TransferLineToPutaway."Transfer-to Code");

        if (DefaultBinCode = '') and (TransferLineToPutaway."Transfer-To Bin Code" = '') then
            exit;

        repeat
            if TransferLineToPutaway."Transfer-To Bin Code" = '' then
                BinCodeToUse := DefaultBinCode
            else
                BinCodeToUse := TransferLineToPutaway."Transfer-To Bin Code";

            CreateWarehouseActivityLine(
                Database::"Transfer Line", 1, TransferLineToPutaway."Document No.", TransferLineToPutaway."Line No.", 0,
                TransferLineToPutaway."Transfer-to Code", TransferLineToPutaway."Item No.", TransferLineToPutaway."Variant Code", TransferLineToPutaway."Unit of Measure Code",
                TransferLineToPutaway."Qty. per Unit of Measure", TransferLineToPutaway."Qty. Rounding Precision", TransferLineToPutaway."Qty. Rounding Precision (Base)",
                TransferLineToPutaway.Description, TransferLineToPutaway."Description 2", TransferLineToPutaway."Receipt Date", BinCodeToUse, TransferLineToPutaway)

        until RemQtyToPutAway <= 0;
    end;

    local procedure CreatePutawayWithPutawayTemplateBinPolicy(var TransferLineToPutaway: Record "Transfer Line")
    begin
        CreatePutawayWithPutawayTemplateBinPolicy(
            Database::"Transfer Line", 1, TransferLineToPutaway."Document No.", TransferLineToPutaway."Line No.", 0,
            TransferLineToPutaway."Transfer-to Code", TransferLineToPutaway."Transfer-from Bin Code", TransferLineToPutaway."Item No.", TransferLineToPutaway."Variant Code", TransferLineToPutaway."Quantity (Base)",
            TransferLineToPutaway."Unit of Measure Code", TransferLineToPutaway."Qty. per Unit of Measure", TransferLineToPutaway."Qty. Rounding Precision",
            TransferLineToPutaway."Qty. Rounding Precision (Base)", TransferLineToPutaway.Description, TransferLineToPutaway."Description 2", TransferLineToPutaway."Receipt Date");
    end;

    local procedure FindReservationFromTransferLine(var TransferLine: Record "Transfer Line")
    var
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReservationFromTransferLine(TransferLine, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
        if IsHandled then
            exit;

        ItemTrackingManagement.GetWhseItemTrkgSetup(TransferLine."Item No.", WhseItemTrackingSetup);
        if WhseItemTrackingSetup.TrackingRequired() then
            ReservationFound := FindReservationEntry(Database::"Transfer Line", 1, TransferLine."Document No.", TransferLine."Line No.");
    end;

    procedure SetFilterTransferLine(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header"): Boolean
    begin
        if CurrLocation.RequireReceive(CurrWarehouseRequest."Location Code") then
            exit(false);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        TransferLine.SetRange("Derived From Line No.", 0);
        if not CheckLineExist then
            TransferLine.SetRange("Transfer-to Code", CurrWarehouseActivityHeader."Location Code");
        TransferLine.SetFilter("Qty. to Receive", '>%1', 0);

        if ApplySourceFilters then begin
            TransferLine.SetFilter("Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            TransferLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            TransferLine.SetFilter("Receipt Date", WarehouseSourceFilter.GetFilter("Receipt Date Filter"));
        end;

        OnBeforeFindTransLine(TransferLine, CurrWarehouseActivityHeader);
        exit(TransferLine.Find('-'));
    end;

#if not CLEAN27
    [Obsolete('Moved to codeunit MfgCreateInventoiryPutaway', '27.0')]
    procedure SetFilterProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"): Boolean
    var
        MfgCreateInventoryPutaway: Codeunit "Mfg. Create Inventory Put-Away";
    begin
        exit(
            MfgCreateInventoryPutaway.SetFilterProdOrderLine(
                ProdOrderLine, ProductionOrder, CurrWarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters));
    end;
#endif

    // Helper methods
    internal procedure CreateWarehouseActivityLine(
        SourceType: Integer; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; SublineNo: Integer;
        LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; UnitOfMeasureCode: Code[10]; QtyPerUnitMeasure: Decimal;
        QtyRndingPrecision: Decimal; QtyRndingPrecisionBase: Decimal; Description: Text[100]; Description2: Text[50]; DueDate: Date;
        BinCode: Code[20]; SourceRecordVariant: Variant): Decimal
    var
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        NewWarehouseActivityLine.Init();
        NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
        NewWarehouseActivityLine."Line No." := NextLineNo;
        NewWarehouseActivityLine.SetSource(SourceType, DocumentType, DocumentNo, LineNo, SublineNo);
        NewWarehouseActivityLine."Location Code" := LocationCode;
        NewWarehouseActivityLine."Item No." := ItemNo;
        NewWarehouseActivityLine."Variant Code" := VariantCode;
        NewWarehouseActivityLine."Bin Code" := BinCode;
        if CurrLocation."Bin Mandatory" then
            NewWarehouseActivityLine.UpdateSpecialEquipment()
        else
            NewWarehouseActivityLine."Shelf No." := GetShelfNo(ItemNo, VariantCode, LocationCode);
        NewWarehouseActivityLine."Unit of Measure Code" := UnitOfMeasureCode;
        NewWarehouseActivityLine."Qty. per Unit of Measure" := QtyPerUnitMeasure;
        NewWarehouseActivityLine."Qty. Rounding Precision" := QtyRndingPrecision;
        NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := QtyRndingPrecisionBase;
        NewWarehouseActivityLine.Description := Description;
        NewWarehouseActivityLine."Description 2" := Description2;
        NewWarehouseActivityLine."Due Date" := DueDate;

        case SourceType of
            Database::"Purchase Line":
                case DocumentType of
                    Enum::"Purchase Document Type"::Order.AsInteger():
                        begin
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Purchase Order";
                            PurchaseLine.SetLoadFields(PurchaseLine."Over-Receipt Code");
                            if PurchaseLine.Get(Enum::"Purchase Document Type"::Order, DocumentNo, LineNo) then
                                NewWarehouseActivityLine."Over-Receipt Code" := PurchaseLine."Over-Receipt Code";
                        end;
                    Enum::"Purchase Document Type"::"Return Order".AsInteger():
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Purchase Return Order";
                end;
            Database::"Sales Line":
                case DocumentType of
                    Enum::"Sales Document Type"::Order.AsInteger():
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Order";
                    Enum::"Sales Document Type"::"Return Order".AsInteger():
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Return Order";
                end;
            Database::"Transfer Line":
                NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Inbound Transfer";
            else
                OnCreateWarehouseActivityLineOnSetSourceDocument(NewWarehouseActivityLine, SourceType);
        end;

        RaiseOnBeforeNewWhseActivLineInsertFromEvent(NewWarehouseActivityLine, SourceRecordVariant);

        ItemTrackingManagement.GetWhseItemTrkgSetup(ItemNo, WhseItemTrackingSetup);
        if not ReservationFound and WhseItemTrackingSetup."Serial No. Required" then
            repeat
                InsertSNWhseActivLine(NewWarehouseActivityLine);
            until RemQtyToPutAway <= 0
        else
            InsertWhseActivLine(NewWarehouseActivityLine, RemQtyToPutAway);

        exit(RemQtyToPutAway);
    end;

    local procedure CreateWarehouseActivityLine(
        SourceType: Integer; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; SublineNo: Integer; LocationCode: Code[10]; BinCode: Code[20];
        ItemNo: Code[20]; VariantCode: Code[10]; QuantityBase: Decimal; UnitOfMeasureCode: Code[10]; QtyPerUnitMeasure: Decimal; QtyRndingPrecision: Decimal;
        QtyRndingPrecisionBase: Decimal; Description: Text[100]; Description2: Text[50]; DueDate: Date; var QtyToPutAwayBase: Decimal)
    var
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        PurchaseLine: Record "Purchase Line";
        ActionType: Enum "Warehouse Action Type";
    begin
        if CurrLocation."Bin Mandatory" then
            ActionType := ActionType::Place
        else
            QtyToPutAwayBase := QuantityBase;

        if QtyToPutAwayBase > 0 then begin
            NextLineNo := NextLineNo + 10000;

            NewWarehouseActivityLine.Init();
            NewWarehouseActivityLine."Activity Type" := CurrWarehouseActivityHeader.Type;
            NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
            NewWarehouseActivityLine."Line No." := NextLineNo;
            NewWarehouseActivityLine.SetSource(SourceType, DocumentType, DocumentNo, LineNo, SublineNo);
            NewWarehouseActivityLine."Location Code" := LocationCode;
            NewWarehouseActivityLine."Item No." := ItemNo;
            NewWarehouseActivityLine."Variant Code" := VariantCode;
            NewWarehouseActivityLine."Bin Code" := BinCode;
            if CurrLocation."Bin Mandatory" then
                NewWarehouseActivityLine.UpdateSpecialEquipment()
            else
                NewWarehouseActivityLine."Shelf No." := GetShelfNo(ItemNo, VariantCode, LocationCode);
            NewWarehouseActivityLine."Unit of Measure Code" := UnitOfMeasureCode;
            NewWarehouseActivityLine."Qty. per Unit of Measure" := QtyPerUnitMeasure;
            NewWarehouseActivityLine."Qty. Rounding Precision" := QtyRndingPrecision;
            NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := QtyRndingPrecisionBase;
            NewWarehouseActivityLine.Description := Description;
            NewWarehouseActivityLine."Description 2" := Description2;
            NewWarehouseActivityLine."Due Date" := DueDate;

            case SourceType of
                Database::"Purchase Line":
                    case DocumentType of
                        Enum::"Purchase Document Type"::Order.AsInteger():
                            begin
                                NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Purchase Order";
                                PurchaseLine.SetLoadFields(PurchaseLine."Over-Receipt Code");
                                if PurchaseLine.Get(Enum::"Purchase Document Type"::Order, DocumentNo, LineNo) then
                                    NewWarehouseActivityLine."Over-Receipt Code" := PurchaseLine."Over-Receipt Code";
                            end;
                        Enum::"Purchase Document Type"::"Return Order".AsInteger():
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Purchase Return Order";
                    end;
                Database::"Sales Line":
                    case DocumentType of
                        Enum::"Sales Document Type"::Order.AsInteger():
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Order";
                        Enum::"Sales Document Type"::"Return Order".AsInteger():
                            NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Sales Return Order";
                    end;
                Database::"Transfer Line":
                    NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Inbound Transfer";
                else
                    OnCreateWarehouseActivityLineOnSetSourceDocument(NewWarehouseActivityLine, SourceType);
            end;

            if not ReservationFound and WhseItemTrackingSetup."Serial No. Required" then
                repeat
                    InsertSNWhseActivLine(NewWarehouseActivityLine);
                until RemQtyToPutAway <= 0
            else
                InsertWhseActivLine(NewWarehouseActivityLine, QtyToPutAwayBase);
        end
    end;

    internal procedure CreatePutawayWithPutawayTemplateBinPolicy(
        SourceType: Integer; DocumentType: Integer; DocumentNo: Code[20]; LineNo: Integer; SublineNo: Integer; LocationCode: Code[10]; BinCode: Code[20];
        ItemNo: Code[20]; VariantCode: Code[10]; QuantityBase: Decimal; UnitOfMeasureCode: Code[10]; QtyPerUnitMeasure: Decimal; QtyRndingPrecision: Decimal;
        QtyRndingPrecisionBase: Decimal; Description: Text[100]; Description2: Text[50]; DueDate: Date)
    var
        PutAwayTemplateLine: Record "Put-away Template Line";
        BinContent: Record "Bin Content";
        BinContentQtyBase: Decimal;
        QtyToPutAwayBase: Decimal;
    begin
        GetItemAndSKU(ItemNo, LocationCode, VariantCode);
        GetPutAwayTemplate();
        if CurrPutAwayTemplateHeader.Code = '' then
            exit;

        PutAwayTemplateLine.Reset();

        PutAwayTemplateLine.SetLoadFields("Find Empty Bin", "Find Floating Bin", "Find Fixed Bin", "Find Same Item", "Find Unit of Measure Match", "Find Bin w. Less than Min. Qty");
        PutAwayTemplateLine.SetRange("Put-away Template Code", CurrPutAwayTemplateHeader.Code);
        if not PutAwayTemplateLine.FindSet() then
            exit;

        repeat
            QtyToPutAwayBase := RemQtyToPutAway;
            if ShouldFindBinContent(PutAwayTemplateLine) then begin
                // Calc Availability per Bin Content
                if FindBinContent(LocationCode, ItemNo, VariantCode, BinContent, PutAwayTemplateLine) then
                    repeat
                        if BinContent."Bin Code" <> BinCode then begin
                            QtyToPutAwayBase := RemQtyToPutAway;

                            BinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
                            BinContentQtyBase :=
                              BinContent."Quantity (Base)" + BinContent."Put-away Quantity (Base)" + BinContent."Positive Adjmt. Qty. (Base)";
                            if (not PutAwayTemplateLine."Find Bin w. Less than Min. Qty" or
                                (BinContentQtyBase < BinContent."Min. Qty." * BinContent."Qty. per Unit of Measure")) and
                               (not PutAwayTemplateLine."Find Empty Bin" or (BinContentQtyBase <= 0))
                            then begin
                                if BinContent."Max. Qty." <> 0 then begin
                                    QtyToPutAwayBase := max(BinContent."Max. Qty." * BinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                    if QtyToPutAwayBase > RemQtyToPutAway then
                                        QtyToPutAwayBase := RemQtyToPutAway;
                                end;

                                GetBin(LocationCode, BinContent."Bin Code");
                                CreateWarehouseActivityLine(SourceType, DocumentType, DocumentNo, LineNo, SublineNo, LocationCode, BinContent."Bin Code", ItemNo, VariantCode, QuantityBase, UnitOfMeasureCode,
                                                            QtyPerUnitMeasure, QtyRndingPrecision, QtyRndingPrecisionBase, Description, Description2, DueDate, QtyToPutAwayBase);
                            end;
                        end;
                    until (BinContent.Next(-1) = 0) or (RemQtyToPutAway <= 0);
            end else
                // Calc Availability per Bin
                if FindBin(LocationCode, PutAwayTemplateLine) then
                    repeat
                        if CurrBin.Code <> BinCode then begin
                            QtyToPutAwayBase := RemQtyToPutAway;
                            if BinContent.Get(LocationCode, CurrBin.Code, ItemNo, VariantCode, UnitOfMeasureCode) then begin
                                BinContent.CalcFields("Quantity (Base)", "Put-away Quantity (Base)", "Positive Adjmt. Qty. (Base)");
                                BinContentQtyBase :=
                                  BinContent."Quantity (Base)" +
                                  BinContent."Put-away Quantity (Base)" +
                                  BinContent."Positive Adjmt. Qty. (Base)";

                                if BinContent."Max. Qty." <> 0 then begin
                                    QtyToPutAwayBase :=
                                      Max(BinContent."Max. Qty." * BinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                    if QtyToPutAwayBase > RemQtyToPutAway then
                                        QtyToPutAwayBase := RemQtyToPutAway;
                                end;
                                CreateWarehouseActivityLine(SourceType, DocumentType, DocumentNo, LineNo, SublineNo, LocationCode, CurrBin.Code, ItemNo, VariantCode, QuantityBase, UnitOfMeasureCode,
                                                            QtyPerUnitMeasure, QtyRndingPrecision, QtyRndingPrecisionBase, Description, Description2, DueDate, QtyToPutAwayBase);

                                BinContentQtyBase := BinContent.CalcQtyBase();
                                if BinContent."Max. Qty." <> 0 then begin
                                    QtyToPutAwayBase :=
                                      Max(BinContent."Max. Qty." * BinContent."Qty. per Unit of Measure" - BinContentQtyBase, 0);
                                    if QtyToPutAwayBase > RemQtyToPutAway then
                                        QtyToPutAwayBase := RemQtyToPutAway;
                                end;
                            end else
                                CreateWarehouseActivityLine(SourceType, DocumentType, DocumentNo, LineNo, SublineNo, LocationCode, CurrBin.Code, ItemNo, VariantCode, QuantityBase, UnitOfMeasureCode,
                                                            QtyPerUnitMeasure, QtyRndingPrecision, QtyRndingPrecisionBase, Description, Description2, DueDate, QtyToPutAwayBase);

                        end;
                    until (CurrBin.Next(-1) = 0) or (RemQtyToPutAway <= 0);
        until (PutAwayTemplateLine.Next() = 0) or (RemQtyToPutAway <= 0);
    end;

    local procedure RaiseOnBeforeNewWhseActivLineInsertFromEvent(var WarehouseActivityLine: Record "Warehouse Activity Line"; RecordVariant: Variant)
    var
        RecordRefToCheck: RecordRef;
    begin
        if not RecordVariant.IsRecord() then
            exit;

        RecordRefToCheck.GetTable(RecordVariant);

        case RecordRefToCheck.Number of
            Database::"Purchase Line":
                OnBeforeNewWhseActivLineInsertFromPurchase(WarehouseActivityLine, RecordVariant);
            Database::"Sales Line":
                OnBeforeNewWhseActivLineInsertFromSales(WarehouseActivityLine, RecordVariant);
            Database::"Transfer Line":
                OnBeforeNewWhseActivLineInsertFromTransfer(WarehouseActivityLine, RecordVariant);
#if not CLEAN27
            5406: // Database::"Prod. Order Line"
                OnBeforeNewWhseActivLineInsertFromProd(WarehouseActivityLine, RecordVariant);
            5407: // Database::"Prod. Order Component"
                OnBeforeNewWhseActivLineInsertFromComp(WarehouseActivityLine, RecordVariant);
#endif
            else
                OnRaiseOnBeforeNewWhseActivLineInsertFromEvent(WarehouseActivityLine, RecordVariant, RecordRefToCheck);
        end;
    end;

    local procedure ShouldFindBinContent(var PutawayTemplateLine: Record "Put-away Template Line"): Boolean
    begin
        if not (PutAwayTemplateLine."Find Empty Bin" or PutAwayTemplateLine."Find Floating Bin") or // if not needs to check Bin
               PutAwayTemplateLine."Find Fixed Bin" or
               PutAwayTemplateLine."Find Same Item" or
               PutAwayTemplateLine."Find Unit of Measure Match" or
               PutAwayTemplateLine."Find Bin w. Less than Min. Qty"
               then
            exit(true);
    end;

    local procedure FindBin(LocationCode: Code[10]; var PutAwayTemplateLine: Record "Put-away Template Line"): Boolean
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        CurrBin.Reset();
        CurrBin.SetCurrentKey("Location Code", "Warehouse Class Code", "Bin Ranking");
        CurrBin.SetRange("Location Code", LocationCode);
        CurrBin.SetRange("Warehouse Class Code", WarehouseClassCode);
        CurrBin.SetFilter("Block Movement", '%1|%2', CurrBin."Block Movement"::" ", CurrBin."Block Movement"::Outbound);
        CurrBin.SetRange("Cross-Dock Bin", false);
        if PutAwayTemplateLine."Find Empty Bin" then
            CurrBin.SetRange(Empty, true);
        if CurrBin.Find('+') then begin
            if not (PutAwayTemplateLine."Find Empty Bin" or PutAwayTemplateLine."Find Floating Bin") then
                exit(true);
            repeat
                if PutAwayTemplateLine."Find Empty Bin" then begin
                    WarehouseActivityLine.SetCurrentKey("Bin Code", "Location Code", "Action Type");
                    WarehouseActivityLine.SetRange("Bin Code", CurrBin.Code);
                    WarehouseActivityLine.SetRange("Location Code", LocationCode);
                    WarehouseActivityLine.SetRange("Action Type", WarehouseActivityLine."Action Type"::Place);
                    if WarehouseActivityLine.IsEmpty() then
                        if not PutAwayTemplateLine."Find Floating Bin" or IsFloatingBin() then
                            exit(true);
                end else
                    if IsFloatingBin() then
                        exit(true);
            until CurrBin.Next(-1) = 0;
        end;
        exit(false)
    end;

    local procedure IsFloatingBin(): Boolean
    var
        BinContent: Record "Bin Content";
    begin
        if CurrBin.Dedicated = true then
            exit(false);
        BinContent.Reset();
        BinContent.SetRange("Location Code", CurrBin."Location Code");
        BinContent.SetRange("Bin Code", CurrBin.Code);
        if BinContent.FindSet() then
            repeat
                if BinContent.Fixed or BinContent.Default then
                    exit(false);
            until BinContent.Next() = 0;
        exit(true);
    end;

    local procedure "Max"(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 >= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure GetItemAndSKU(ItemNo: Code[20]; LocationCode: Code[10]; VariantCode: Code[10])
    begin
        if CurrItem."No." <> ItemNo then begin
            CurrItem.SetLoadFields("Warehouse Class Code", "Put-away Template Code", "Shelf No.");
            CurrItem.Get(ItemNo);
            GetWarehouseClassCode();
        end;

        if (ItemNo <> CurrStockkeepingUnit."Item No.") or
           (LocationCode <> CurrStockkeepingUnit."Location Code") or
           (VariantCode <> CurrStockkeepingUnit."Variant Code")
        then begin
            CurrStockkeepingUnit.SetLoadFields("Put-away Template Code");
            if not CurrStockkeepingUnit.Get(LocationCode, ItemNo, VariantCode) then
                Clear(CurrStockkeepingUnit);
        end;
    end;

    local procedure GetWarehouseClassCode()
    begin
        WarehouseClassCode := CurrItem."Warehouse Class Code";
    end;

    local procedure GetBin(LocationCode: Code[10]; BinCode: Code[20])
    begin
        if (CurrBin."Location Code" <> LocationCode) or (CurrBin.Code <> BinCode) then
            CurrBin.Get(LocationCode, BinCode)
    end;

    local procedure GetPutAwayTemplate()
    begin
        if CurrStockkeepingUnit."Put-away Template Code" <> '' then begin
            if CurrStockkeepingUnit."Put-away Template Code" <> CurrPutAwayTemplateHeader.Code then
                if not CurrPutAwayTemplateHeader.Get(CurrStockkeepingUnit."Put-away Template Code") then
                    if (CurrItem."Put-away Template Code" <> '') and
                       (CurrItem."Put-away Template Code" <> CurrPutAwayTemplateHeader.Code)
                    then
                        if not CurrPutAwayTemplateHeader.Get(CurrItem."Put-away Template Code") then
                            if (CurrPutAwayTemplateHeader.Code <> CurrLocation."Put-away Template Code")
                            then
                                CurrPutAwayTemplateHeader.Get(CurrLocation."Put-away Template Code");
        end else
            if (CurrItem."Put-away Template Code" <> '') or
               (CurrItem."Put-away Template Code" <> CurrPutAwayTemplateHeader.Code)
            then begin
                if not CurrPutAwayTemplateHeader.Get(CurrItem."Put-away Template Code") then
                    if (CurrPutAwayTemplateHeader.Code <> CurrLocation."Put-away Template Code")
                    then
                        CurrPutAwayTemplateHeader.Get(CurrLocation."Put-away Template Code")
            end else
                if CurrPutAwayTemplateHeader.Get(CurrLocation."Put-away Template Code") then;
    end;

    internal procedure FindNextLineNo()
    var
        WarehouseActivityLine: Record "Warehouse Activity Line";
    begin
        WarehouseActivityLine.SetLoadFields("Line No.");
        WarehouseActivityLine.SetRange("Activity Type", WarehouseActivityLine."Activity Type"::"Invt. Put-away");
        WarehouseActivityLine.SetRange("No.", CurrWarehouseActivityHeader."No.");
        if WarehouseActivityLine.FindLast() then
            NextLineNo := WarehouseActivityLine."Line No." + 10000
        else
            NextLineNo := 10000;
    end;

    internal procedure FindReservationEntry(SourceType: Integer; DocType: Integer; DocNo: Code[20]; DocLineNo: Integer): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
    begin
        if SourceType in [5406, Database::"Transfer Line"] then begin // Database::"Prod. Order Line"
            ReservationEntry.SetSourceFilter(SourceType, DocType, DocNo, -1, true);
            ReservationEntry.SetRange("Source Prod. Order Line", DocLineNo)
        end else
            ReservationEntry.SetSourceFilter(SourceType, DocType, DocNo, DocLineNo, true);
        ReservationEntry.SetTrackingFilterFromWhseItemTrackingSetupNotBlankIfRequired(WhseItemTrackingSetup);
        if ReservationEntry.FindFirst() then
            if ItemTrackingManagement.SumUpItemTracking(ReservationEntry, TempTrackingSpecification, true, true) then
                exit(true);
    end;

    internal procedure SetReservationFound(NewReservationFound: Boolean)
    begin
        ReservationFound := NewReservationFound;
    end;

    local procedure InsertSNWhseActivLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertSNWhseActivLine(NewWarehouseActivityLine, WhseItemTrackingSetup, NextLineNo, ReservationFound, IsHandled, RemQtyToPutAway);
        if IsHandled then
            exit;

        NewWarehouseActivityLine."Line No." := NextLineNo;
        InsertWhseActivLine(NewWarehouseActivityLine, 1);
    end;

    procedure InsertWhseActivLine(var NewWarehouseActivityLine: Record "Warehouse Activity Line"; PutAwayQty: Decimal)
    var
        UnitOfMeasureManagement: Codeunit "Unit of Measure Management";
        CalculatedPutAway: Decimal;
        IsHandled: Boolean;
    begin
        if CurrLocation."Bin Mandatory" then
            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Place;

        NewWarehouseActivityLine."Serial No." := '';
        NewWarehouseActivityLine."Expiration Date" := 0D;
        if ReservationFound then begin
            NewWarehouseActivityLine.CopyTrackingFromSpec(TempTrackingSpecification);
            NewWarehouseActivityLine.Validate(Quantity, NewWarehouseActivityLine.CalcQty(TempTrackingSpecification."Qty. to Handle (Base)"));
            ReservationFound := false;
        end else
            if WhseItemTrackingSetup.TrackingRequired() and (TempTrackingSpecification.Next() <> 0) then begin
                NewWarehouseActivityLine.CopyTrackingFromSpec(TempTrackingSpecification);
                NewWarehouseActivityLine.Validate(Quantity, NewWarehouseActivityLine.CalcQty(TempTrackingSpecification."Qty. to Handle (Base)"));
            end else
                if WhseItemTrackingSetup."Serial No. Required" and (NewWarehouseActivityLine."Qty. per Unit of Measure" > 1) then begin
                    CalculatedPutAway := NewWarehouseActivityLine.CalcQty(PutAwayQty);
                    if UnitOfMeasureManagement.RoundQty(UnitOfMeasureManagement.CalcBaseQty(RemQtyToPutAway - CalculatedPutAway, NewWarehouseActivityLine."Qty. per Unit of Measure"), 1) = 0 then
                        NewWarehouseActivityLine.Validate(Quantity, RemQtyToPutAway)
                    else
                        NewWarehouseActivityLine.Validate(Quantity, CalculatedPutAway);
                    NewWarehouseActivityLine."Qty. (Base)" := UnitOfMeasureManagement.RoundQty(NewWarehouseActivityLine."Qty. (Base)", 1);
                    NewWarehouseActivityLine.TestField("Qty. (Base)", 1);
                end else
                    NewWarehouseActivityLine.Validate(Quantity, PutAwayQty);
        NewWarehouseActivityLine.Validate("Qty. to Handle", 0);
        OnInsertWhseActivLineOnBeforeAutoCreation(
            NewWarehouseActivityLine, TempTrackingSpecification, ReservationFound,
            WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required");

        if AutoCreation and not LineCreated then begin
            CurrWarehouseActivityHeader."No." := '';
            CurrWarehouseActivityHeader.Insert(true);
            UpdateWhseActivHeader(CurrWarehouseRequest);
            NextLineNo := 10000;
            OnInsertWhseActivLineOnBeforeCommit(NewWarehouseActivityLine, CurrWarehouseActivityHeader);
            Commit();
        end;
        NewWarehouseActivityLine."No." := CurrWarehouseActivityHeader."No.";
        NewWarehouseActivityLine."Line No." := NextLineNo;
        IsHandled := false;
        OnBeforeInsertWhseActivLine(NewWarehouseActivityLine, IsHandled);
        if not IsHandled then
            NewWarehouseActivityLine.Insert();
        OnAfterInsertWhseActivLine(NewWarehouseActivityLine, WhseItemTrackingSetup."Serial No. Required", WhseItemTrackingSetup."Lot No. Required");

        LineCreated := true;
        NextLineNo := NextLineNo + 10000;
        RemQtyToPutAway -= NewWarehouseActivityLine.Quantity;
    end;

    local procedure FindBinContent(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var BinContent: Record "Bin Content"; var PutAwayTemplateLine: Record "Put-away Template Line"): Boolean
    var
        BinContentFound: Boolean;
    begin
        BinContent.Reset();
        BinContent.SetCurrentKey("Location Code", "Warehouse Class Code", Fixed, "Bin Ranking");
        BinContent.SetRange("Location Code", LocationCode);
        GetWarehouseClassCode();
        BinContent.SetRange("Warehouse Class Code", WarehouseClassCode);
        if PutAwayTemplateLine."Find Fixed Bin" then
            BinContent.SetRange(Fixed, true)
        else
            BinContent.SetRange(Fixed, false);
        BinContent.SetFilter("Block Movement", '%1|%2', BinContent."Block Movement"::" ", BinContent."Block Movement"::Outbound);
        BinContent.SetRange("Cross-Dock Bin", false);
        if PutAwayTemplateLine."Find Same Item" then begin
            BinContent.SetCurrentKey(
              "Location Code", "Item No.", "Variant Code", "Warehouse Class Code", Fixed, "Bin Ranking");
            BinContent.SetRange("Item No.", ItemNo);
            BinContent.SetRange("Variant Code", VariantCode);
        end;
        BinContentFound := BinContent.Find('+');

        exit(BinContentFound);
    end;

    internal procedure GetDefaultBinCode(ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]): Code[20]
    var
        WMSManagement: Codeunit "WMS Management";
        BinCode: Code[20];
    begin
        GetLocation(LocationCode);
        if CurrLocation."Bin Mandatory" then
            if WMSManagement.GetDefaultBin(ItemNo, VariantCode, LocationCode, BinCode) then
                exit(BinCode);
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(CurrLocation)
        else
            if LocationCode <> CurrLocation.Code then
                CurrLocation.Get(LocationCode);
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
        if ItemNo <> CurrItem."No." then begin
            CurrItem.SetLoadFields("Warehouse Class Code", "Put-away Template Code", "Shelf No.");
            CurrItem.Get(ItemNo);
        end;
    end;

    procedure SetWhseRequest(NewWarehouseRequest: Record "Warehouse Request"; SetHideDialog: Boolean)
    begin
        CurrWarehouseRequest := NewWarehouseRequest;
        HideDialog := SetHideDialog;
        LineCreated := false;
    end;

    procedure CheckSourceDoc(NewWarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        PurchaseLine: Record "Purchase Line";
        SalesLine: Record "Sales Line";
        TransferLine: Record "Transfer Line";
        IsFound: Boolean;
        IsHandled: Boolean;
    begin
        CurrWarehouseRequest := NewWarehouseRequest;

        IsHandled := false;
        IsFound := false;
        OnBeforeCheckSourceDoc(NewWarehouseRequest, IsFound, IsHandled);
        if IsHandled then
            exit(IsFound);

        GetSourceDocHeader();
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
            CurrWarehouseRequest."Source Document"::"Inbound Transfer":
                exit(SetFilterTransferLine(TransferLine, SourceDocRecordVar));
            else
                OnCheckSourceDocForWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, SourceDocRecordVar, Result,
                    CurrWarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters);
        end;
    end;

    procedure AutoCreatePutAway(var NewWarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        IsHandled: Boolean;
    begin
        CurrWarehouseActivityHeader := NewWarehouseActivityHeader;
        CheckLineExist := false;
        AutoCreation := true;
        GetLocation(CurrWarehouseRequest."Location Code");

        IsHandled := false;
        OnBeforeAutoCreatePutAwayLines(CurrWarehouseRequest, CurrWarehouseActivityHeader, LineCreated, IsHandled, HideDialog);
        if IsHandled then
            exit;

        case CurrWarehouseRequest."Source Document" of
            CurrWarehouseRequest."Source Document"::"Purchase Order":
                CreatePutAwayLinesFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Purchase Return Order":
                CreatePutAwayLinesFromPurchase(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Order":
                CreatePutAwayLinesFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Sales Return Order":
                CreatePutAwayLinesFromSales(SourceDocRecordVar);
            CurrWarehouseRequest."Source Document"::"Inbound Transfer":
                CreatePutAwayLinesFromTransfer(SourceDocRecordVar);
            else
                OnAutoCreatePutAwayLinesFromWhseRequest(
                    CurrWarehouseRequest, SourceDocRecordRef, LineCreated, SourceDocRecordVar, RemQtyToPutAway,
                    CurrWarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters);
        end;
        if LineCreated then begin
            CurrWarehouseActivityHeader.Modify();
            NewWarehouseActivityHeader := CurrWarehouseActivityHeader;
        end;

        OnAfterAutoCreatePutAway(CurrWarehouseRequest, LineCreated, NewWarehouseActivityHeader);
    end;

    procedure GetNothingToHandleMsg()
    begin
        if not HideDialog then
            Message(NothingToHandleMsg);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterAutoCreatePutAway(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInventoryPutaway(var WarehouseRequest: Record "Warehouse Request"; LineCreated: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayLinesFromPurchase(PurchaseHeader: Record "Purchase Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreatePutAwayLinesFromSales(SalesHeader: Record "Sales Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; SNRequired: Boolean; LNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterUpdateWhseActivHeader(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAutoCreatePutAwayLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromPurchase(var WarehouseActivityLine: Record "Warehouse Activity Line"; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromSales(var WarehouseActivityLine: Record "Warehouse Activity Line"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromTransfer(var WarehouseActivityLine: Record "Warehouse Activity Line"; TransferLine: Record "Transfer Line")
    begin
    end;

#if not CLEAN27
    [Obsolete('Replaced by event OnRaiseOnBeforeNewWhseActivLineInsertFromEvent', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromProd(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

#if not CLEAN27
    [Obsolete('Replaced by event OnRaiseOnBeforeNewWhseActivLineInsertFromEvent', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromComp(var WarehouseActivityLine: Record "Warehouse Activity Line"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnRaiseOnBeforeNewWhseActivLineInsertFromEvent(var WarehouseActivityLine: Record "Warehouse Activity Line"; RecordVariant: Variant; RecordRefToCheck: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindPurchLine(var PurchaseLine: Record "Purchase Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindSalesLine(var SalesLine: Record "Sales Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindTransLine(var TransferLine: Record "Transfer Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeFindProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        OnBeforeFindProdOrderLine(ProdOrderLine, WarehouseActivityHeader);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
        OnBeforeFindProdOrderComp(ProdOrderComp, WarehouseActivityHeader);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocHeader(var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeInsertSNWhseActivLine(var WarehouseActivityLine: Record "Warehouse Activity Line"; WhseItemTrackingSetup: Record "Item Tracking Setup"; NextLineNo: Integer; var ReservationFound: Boolean; var IsHandled: Boolean; var RemQtyToPutAway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSourceDoc(WarehouseRequest: Record "Warehouse Request"; var IsFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; var IsHandled: Boolean; var HideDialog: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeCreatePutAwayLinesFromCompLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnBeforeCreatePutAwayLinesFromCompLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromCompLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeCreatePutAwayLinesFromProdLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
        OnBeforeCreatePutAwayLinesFromProdLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderLine);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromProdLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromPurchaseLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromSalesLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromTransferLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; TransferHeader: Record "Transfer Header"; var IsHandled: Boolean; TransferLine: Record "Transfer Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromPurchaseLine(var PurchLine: Record "Purchase Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromSalesLine(var SalesLine: Record "Sales Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromTransferLine(var TransferLine: Record "Transfer Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnBeforeFindReservationFromProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeFindReservationFromProdOrderLine(ProdOrderLine, WhseItemTrackingSetup, ItemTrackingMgt, ReservationFound, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnBeforeFindReservationFromProdOrderComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
        OnBeforeFindReservationFromProdOrderComponent(ProdOrderComp, WhseItemTrackingSetup, ItemTrackingMgt, ReservationFound, IsHandled);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromProdOrderComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnAutoCreatePutAwayLinesFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecVar: Variant; var RemQtyToPutaway: Decimal; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSourceDocForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var SourceDocRecordVar: Variant; var Result: Boolean; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCreatePutAwayFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecordVar: Variant; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean; var RemQtyToPutaway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCodeOnAfterCreatePutAwayLines(WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var LineCreated: Boolean; AutoCreation: Boolean; var SuppressError: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSourceDocHeaderForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; var VendorDocNo: Code[35]; var SourceDocRecordVar: Variant);
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseActivLineOnBeforeAutoCreation(var WarehouseActivityLine: Record "Warehouse Activity Line"; var TempTrackingSpecification: Record "Tracking Specification" temporary; ReservationFound: Boolean; SNRequired: Boolean; LNRequired: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseActivLineOnBeforeCommit(var WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseActivHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForPurchaseLine(var PurchaseLine: Record "Purchase Line"; var RemQtyToPutAway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForSalesLine(var SalesLine: Record "Sales Line"; var RemQtyToPutAway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForTransferLine(var TransferLine: Record "Transfer Line"; var RemQtyToPutAway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutAwayLinesFromSalesOnAfterSetRemQtyToPutAway(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPutAway: Decimal)
    begin
    end;

#if not CLEAN27
    internal procedure RunOnCreatePutawayForProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RemQtyToPutAway: Decimal)
    begin
        OnCreatePutawayForProdOrderLine(ProdOrderLine, RemQtyToPutAway);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RemQtyToPutAway: Decimal)
    begin
    end;
#endif

#if not CLEAN27
    internal procedure RunOnCreatePutawayForProdOrderComponent(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var RemQtyToPutAway: Decimal)
    begin
        OnCreatePutawayForProdOrderComponent(ProdOrderComponent, RemQtyToPutAway);
    end;

    [Obsolete('Moved to codeunit MfgCreateInventoryPutaway', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForProdOrderComponent(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var RemQtyToPutAway: Decimal)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetWhseRequestOnAfterFilterGroup(WarehouseRequest: Record "Warehouse Request"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateWhseActivHeaderOnBeforeGetLocation(var WarehouseRequest: Record "Warehouse Request"; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnCreateWarehouseActivityLineOnSetSourceDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnCreatePutAwayLinesFromTransferOnAfterSetRemQtyToPutAway(var TransferHeader: Record "Transfer Header"; var TransferLine: Record "Transfer Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPutAway: Decimal)
    begin
    end;

    [InternalEvent(false, false)]
    local procedure OnCreatePutAwayLinesFromPurchaseOnAfterSetRemQtyToPutAway(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPutAway: Decimal)
    begin
    end;
}
