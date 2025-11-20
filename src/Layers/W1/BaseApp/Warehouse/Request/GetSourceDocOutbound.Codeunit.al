// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using Microsoft.Warehouse.Worksheet;
using System.Text;
using System.Reflection;

codeunit 5752 "Get Source Doc. Outbound"
{

    trigger OnRun()
    begin
    end;

    var
        GetSourceDocuments: Report "Get Source Documents";

#pragma warning disable AA0074
#pragma warning disable AA0470
        Text001: Label 'If %1 is %2 in %3 no. %4, then all associated lines where type is %5 must use the same location.';
        Text002: Label 'The warehouse shipment was not created because the Shipping Advice field is set to Complete, and item no. %1 is not available in location code %2.\\You can create the warehouse shipment by either changing the Shipping Advice field to Partial in %3 no. %4 or by manually filling in the warehouse shipment document.';
        Text003: Label 'The warehouse shipment was not created because an open warehouse shipment exists for the Sales Header and Shipping Advice is %1.\\You must add the item(s) as new line(s) to the existing warehouse shipment or change Shipping Advice to Partial.';
#pragma warning restore AA0470
#pragma warning restore AA0074

    procedure CreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        WhseShptHeader: Record "Warehouse Shipment Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest, Result, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit(Result);

        if WarehouseRequest.IsEmpty() then
            exit(false);

        Clear(GetSourceDocuments);
        OnCreateWhseShipmentHeaderFromWhseRequestOnAfterClearGetSourceDocuments(WarehouseRequest, GetSourceDocuments);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        GetSourceDocuments.RunModal();

        GetSourceDocuments.GetLastShptHeader(WhseShptHeader);
        OnAfterCreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest, WhseShptHeader);

        exit(true);
    end;

    procedure GetOutboundDocs(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhseGetSourceFilter: Record "Warehouse Source Filter";
        WhseSourceFilterSelection: Page "Filters to Get Source Docs.";
    begin
        WhseShptHeader.Find();
        WhseSourceFilterSelection.SetOneCreatedShptHeader(WhseShptHeader);
        WhseGetSourceFilter.FilterGroup(2);
        WhseGetSourceFilter.SetRange(Type, WhseGetSourceFilter.Type::Outbound);
        WhseGetSourceFilter.FilterGroup(0);
        WhseSourceFilterSelection.SetTableView(WhseGetSourceFilter);
        WhseSourceFilterSelection.RunModal();

        OnGetOutboundDocsOnBeforeUpdateShipmentHeaderStatus(WhseShptHeader);
        UpdateShipmentHeaderStatus(WhseShptHeader);

        OnAfterGetOutboundDocs(WhseShptHeader);
    end;

    procedure GetSingleOutboundDoc(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WarehouseRequest: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        OnBeforeGetSingleOutboundDoc(WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        Clear(GetSourceDocuments);
        WhseShptHeader.Find();

        WarehouseRequest.FilterGroup(2);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetRange("Location Code", WhseShptHeader."Location Code");
        OnGetSingleOutboundDocOnSetFilterGroupFilters(WarehouseRequest, WhseShptHeader);
        WarehouseRequest.FilterGroup(0);
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        WarehouseRequest.SetRange("Completely Handled", false);
        OnGetSingleOutboundDocOnAfterSetFilters(WarehouseRequest, WhseShptHeader);

        GetSourceDocForHeader(WhseShptHeader, WarehouseRequest);

        UpdateShipmentHeaderStatus(WhseShptHeader);

        OnAfterGetSingleOutboundDoc(WhseShptHeader);
    end;

    local procedure GetSourceDocForHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request")
    var
        SourceDocSelection: Page "Source Documents";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocForHeader(WarehouseShipmentHeader, WarehouseRequest, IsHandled);
        if IsHandled then
            exit;

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WarehouseRequest);
        if SourceDocSelection.RunModal() <> ACTION::LookupOK then
            exit;
        SourceDocSelection.GetResult(WarehouseRequest);

        GetSourceDocuments.SetOneCreatedShptHeader(WarehouseShipmentHeader);
        GetSourceDocuments.SetSkipBlocked(true);
        GetSourceDocuments.UseRequestPage(false);
        WarehouseRequest.SetRange("Location Code", WarehouseShipmentHeader."Location Code");
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.RunModal();
    end;

    procedure CreateFromSalesOrder(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromSalesOrder(SalesHeader, IsHandled);
        if not IsHandled then
            ShowResult(CreateFromSalesOrderHideDialog(SalesHeader));
    end;

    procedure CreateFromSalesOrderHideDialog(SalesHeader: Record "Sales Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        if not SalesHeader.IsApprovedForPosting() then
            exit(false);

        FindWarehouseRequestForSalesOrder(WarehouseRequest, SalesHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest));
    end;

    procedure CreateFromPurchaseReturnOrder(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateFromPurchaseReturnOrder(PurchaseHeader, IsHandled);
        if not IsHandled then
            ShowResult(CreateFromPurchReturnOrderHideDialog(PurchaseHeader));
    end;

    procedure CreateFromPurchReturnOrderHideDialog(PurchaseHeader: Record "Purchase Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindWarehouseRequestForPurchReturnOrder(WarehouseRequest, PurchaseHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest));
    end;

    procedure CreateFromOutbndTransferOrder(TransHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCreateFromOutbndTransferOrder(TransHeader, IsHandled);
        if not IsHandled then
            ShowResult(CreateFromOutbndTransferOrderHideDialog(TransHeader));
    end;

    procedure CreateFromOutbndTransferOrderHideDialog(TransHeader: Record "Transfer Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindWarehouseRequestForOutbndTransferOrder(WarehouseRequest, TransHeader);
        exit(CreateWhseShipmentHeaderFromWhseRequest(WarehouseRequest));
    end;

#if not CLEAN25
    [Obsolete('Moved to codeunit ServGetSourceDocOutbound', '25.0')]
    procedure CreateFromServiceOrder(ServiceHeader: Record Microsoft.Service.Document."Service Header")
    var
        ServGetSourceDocOutbound: Codeunit "Serv. Get Source Doc. Outbound";
    begin
        ServGetSourceDocOutbound.CreateFromServiceOrder(ServiceHeader);
    end;
#endif

#if not CLEAN25
    [Obsolete('Moved to codeunit ServGetSourceDocOutbound', '25.0')]
    procedure CreateFromServiceOrderHideDialog(ServiceHeader: Record Microsoft.Service.Document."Service Header"): Boolean
    var
        ServGetSourceDocOutbound: Codeunit "Serv. Get Source Doc. Outbound";
    begin
        exit(ServGetSourceDocOutbound.CreateFromServiceOrderHideDialog(ServiceHeader));
    end;
#endif

    procedure GetSingleWhsePickDoc(CurrentWhseWkshTemplate: Code[10]; CurrentWhseWkshName: Code[10]; LocationCode: Code[10])
    var
        PickWkshName: Record "Whse. Worksheet Name";
        WhsePickRequest: Record "Whse. Pick Request";
        GetWhseSourceDocuments: Report "Get Outbound Source Documents";
        WhsePickDocSelection: Page "Pick Selection";
    begin
        PickWkshName.Get(CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);

        WhsePickRequest.FilterGroup(2);
        WhsePickRequest.SetRange(Status, WhsePickRequest.Status::Released);
        WhsePickRequest.SetRange("Completely Picked", false);
        WhsePickRequest.SetRange("Location Code", LocationCode);
        OnGetSingleWhsePickDocOnWhsePickRqstSetFilters(WhsePickRequest, CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);
        WhsePickRequest.FilterGroup(0);

        WhsePickDocSelection.LookupMode(true);
        WhsePickDocSelection.SetTableView(WhsePickRequest);
        if WhsePickDocSelection.RunModal() <> ACTION::LookupOK then
            exit;
        WhsePickDocSelection.GetResult(WhsePickRequest);

        GetWhseSourceDocuments.SetPickWkshName(
          CurrentWhseWkshTemplate, CurrentWhseWkshName, LocationCode);
        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePickRequest);
        GetWhseSourceDocuments.RunModal();
    end;

    procedure CheckSalesHeader(SalesHeader: Record "Sales Header"; ShowError: Boolean) Result: Boolean
    var
        SalesLine: Record "Sales Line";
    begin
        OnBeforeCheckSalesHeader(SalesHeader, ShowError);

        if SalesHeader."Shipping Advice" = SalesHeader."Shipping Advice"::Partial then
            exit(false);

        SalesLine.SetCurrentKey("Document Type", Type, "No.", "Variant Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        OnCheckSalesHeaderOnAfterSetLineFilters(SalesLine, SalesHeader);
        CheckSalesHeaderMarkSalesLines(SalesHeader, SalesLine);

        exit(CheckSalesLines(SalesHeader, SalesLine, ShowError));
    end;

    local procedure CheckSalesLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowError: Boolean) Result: Boolean
    var
        CurrItemVariant: Record "Item Variant";
        SalesOrder: Page "Sales Order";
        QtyOutstandingBase: Decimal;
        RecordNo: Integer;
        TotalNoOfRecords: Integer;
        LocationCode: Code[10];
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesLines(SalesHeader, SalesLine, ShowError, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if SalesLine.FindSet() then begin
            LocationCode := SalesLine."Location Code";
            SetItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code");
            TotalNoOfRecords := SalesLine.Count();
            repeat
                RecordNo += 1;

                if SalesLine."Location Code" <> LocationCode then begin
                    if ShowError then
                        Error(Text001, SalesHeader.FieldCaption(SalesHeader."Shipping Advice"), SalesHeader."Shipping Advice",
                          SalesOrder.Caption, SalesHeader."No.", SalesLine.Type);
                    exit(true);
                end;

                if EqualItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code") then
                    QtyOutstandingBase += SalesLine."Outstanding Qty. (Base)"
                else begin
                    if CheckSalesHeaderOnBeforeCheckAvailability(SalesHeader, SalesLine, ShowError, Result) then
                        exit(Result);

                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, SalesLine."Location Code",
                         SalesOrder.Caption(), Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", ShowError)
                    then
                        exit(true);
                    SetItemVariant(CurrItemVariant, SalesLine."No.", SalesLine."Variant Code");
                    if CheckSalesHeaderOnAfterSetItemVariant(Result) then
                        exit(Result);
                    QtyOutstandingBase := SalesLine."Outstanding Qty. (Base)";
                end;
                if RecordNo = TotalNoOfRecords then begin
                    // last record
                    if CheckSalesHeaderOnBeforeCheckAvailability(SalesHeader, SalesLine, ShowError, Result) then
                        exit(Result);

                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, SalesLine."Location Code",
                         SalesOrder.Caption(), Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.", ShowError)
                    then
                        exit(true);
                end;
            until SalesLine.Next() = 0;
            // sorted by item
        end;
    end;

    local procedure CheckSalesHeaderMarkSalesLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckSalesHeaderMarkSalesLines(SalesLine, SalesHeader, IsHandled);
        if IsHandled then
            exit;

        if SalesLine.FindSet() then
            repeat
                if SalesLine.IsInventoriableItem() then
                    SalesLine.Mark(true);
            until SalesLine.Next() = 0;
        SalesLine.MarkedOnly(true);
    end;

    local procedure CheckSalesHeaderOnAfterSetItemVariant(var Result: Boolean) IsHandled: Boolean
    begin
        OnCheckSalesHeaderOnAfterSetItemVariant(Result, IsHandled);
    end;

    local procedure CheckSalesHeaderOnBeforeCheckAvailability(SalesHeader: Record "Sales Header"; SalesLine: record "Sales Line"; ShowError: Boolean; var Result: Boolean) IsHandled: Boolean
    begin
        OnCheckSalesHeaderOnBeforeCheckAvailability(SalesHeader, SalesLine, ShowError, Result, IsHandled);
    end;

    procedure CheckTransferHeader(TransferHeader: Record "Transfer Header"; ShowError: Boolean): Boolean
    var
        TransferLine: Record "Transfer Line";
        CurrItemVariant: Record "Item Variant";
        TransferOrder: Page "Transfer Order";
        QtyOutstandingBase: Decimal;
        RecordNo: Integer;
        TotalNoOfRecords: Integer;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckTransferHeader(TransferHeader, ShowError, IsHandled);
        if IsHandled then
            exit;

        if TransferHeader."Shipping Advice" = TransferHeader."Shipping Advice"::Partial then
            exit(false);

        TransferLine.SetCurrentKey("Item No.");
        TransferLine.SetRange("Document No.", TransferHeader."No.");
        OnCheckTransferHeaderOnAfterSetLineFilters(TransferLine, TransferHeader);
        if TransferLine.FindSet() then begin
            SetItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code");
            TotalNoOfRecords := TransferLine.Count();
            repeat
                RecordNo += 1;
                if EqualItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code") then
                    QtyOutstandingBase += TransferLine."Outstanding Qty. (Base)"
                else begin
                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, TransferLine."Transfer-from Code",
                         TransferOrder.Caption(), Database::"Transfer Line", 0, TransferHeader."No.", ShowError)
                    then
                        // outbound
                        exit(true);
                    SetItemVariant(CurrItemVariant, TransferLine."Item No.", TransferLine."Variant Code");
                    QtyOutstandingBase := TransferLine."Outstanding Qty. (Base)";
                end;
                if RecordNo = TotalNoOfRecords then
                    // last record
                    if CheckAvailability(
                         CurrItemVariant, QtyOutstandingBase, TransferLine."Transfer-from Code",
                         TransferOrder.Caption(), Database::"Transfer Line", 0, TransferHeader."No.", ShowError)
                    then
                        // outbound
                        exit(true);
            until TransferLine.Next() = 0;
            // sorted by item
        end;
    end;

    procedure CheckAvailability(CurrItemVariant: Record "Item Variant"; QtyBaseNeeded: Decimal; LocationCode: Code[10]; FormCaption: Text[1024]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; ShowError: Boolean): Boolean
    var
        Item: Record Item;
        ReservEntry: Record "Reservation Entry";
        ReservEntry2: Record "Reservation Entry";
        QtyReservedForOrder: Decimal;
        IsHandled: Boolean;
        Result: Boolean;
        NotAvailable: Boolean;
        ErrorMessage: Text;
    begin
        IsHandled := false;
        OnBeforeCheckAvailability(
          CurrItemVariant, QtyBaseNeeded, LocationCode, FormCaption, SourceType, SourceSubType, SourceID, ShowError, Result, IsHandled);
        if IsHandled then
            exit(Result);

        Item.Get(CurrItemVariant."Item No.");
        Item.SetRange("Location Filter", LocationCode);
        Item.SetRange("Variant Filter", CurrItemVariant.Code);
        Item.CalcFields(Inventory, "Reserved Qty. on Inventory");
        // find qty reserved for this order
        ReservEntry.SetSourceFilter(SourceType, SourceSubType, SourceID, -1, true);
        ReservEntry.SetRange("Item No.", CurrItemVariant."Item No.");
        ReservEntry.SetRange("Location Code", LocationCode);
        ReservEntry.SetRange("Variant Code", CurrItemVariant.Code);
        ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Reservation);
        if ReservEntry.FindSet() then
            repeat
                ReservEntry2.Get(ReservEntry."Entry No.", not ReservEntry.Positive);
                QtyReservedForOrder += ReservEntry2."Quantity (Base)";
            until ReservEntry.Next() = 0;

        NotAvailable := Item.Inventory - (Item."Reserved Qty. on Inventory" - QtyReservedForOrder) < QtyBaseNeeded;
        ErrorMessage := StrSubstNo(Text002, CurrItemVariant."Item No.", LocationCode, FormCaption, SourceID);
        if AfterCheckAvailability(NotAvailable, ShowError, ErrorMessage, Result) then
            exit(Result);
    end;

    local procedure AfterCheckAvailability(NotAvailable: Boolean; ShowError: Boolean; ErrorMessage: Text; var Result: Boolean) IsHandled: Boolean;
    begin
        OnAfterCheckAvailability(NotAvailable, ShowError, ErrorMessage, Result, IsHandled);
        if IsHandled then
            exit(true);

        if NotAvailable then begin
            if ShowError then
                Error(ErrorMessage);
            exit(true);
        end;
    end;

    local procedure OpenWarehouseShipmentPage()
    var
        WarehouseShipmentHeader: Record "Warehouse Shipment Header";
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeOpenWarehouseShipmentPage(GetSourceDocuments, IsHandled);
        if IsHandled then
            exit;

        GetSourceDocuments.GetCreatedShptHeaders(WarehouseShipmentHeader);
        WarehouseShipmentHeader.MarkedOnly(true);
        WarehouseShipmentHeader.FindSet();
        repeat
            WMSManagement.CheckUserIsWhseEmployeeForLocation(WarehouseShipmentHeader."Location Code", true);
        until WarehouseShipmentHeader.Next() = 0;
        case WarehouseShipmentHeader.Count() of
            1:
                Page.Run(Page::"Warehouse Shipment", WarehouseShipmentHeader);
            else
                Page.Run(Page::"Warehouse Shipment List", WarehouseShipmentHeader);
        end;
    end;

    procedure GetRequireShipRqst(var WarehouseRequest: Record "Warehouse Request")
    var
        Location: Record Location;
        LocationList: List of [Code[20]];
        LocationCodeFilter: Text;
        IsHandled: Boolean;
        BlankLocationExists: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRequireShipRqst(WarehouseRequest, IsHandled);
        if IsHandled then
            exit;

        if WarehouseRequest.FindSet() then begin
            repeat
                if Location.RequireShipment(WarehouseRequest."Location Code") then begin
                    if WarehouseRequest."Location Code" = '' then
                        BlankLocationExists := true;
                    if not LocationList.Contains(WarehouseRequest."Location Code") then
                        LocationList.Add(WarehouseRequest."Location Code");
                end;
            until WarehouseRequest.Next() = 0;

            GenerateLocationCodeFilter(LocationList, LocationCodeFilter, BlankLocationExists);

            WarehouseRequest.SetFilter("Location Code", LocationCodeFilter);
        end;
    end;

    local procedure SetItemVariant(var CurrItemVariant: Record "Item Variant"; ItemNo: Code[20]; VariantCode: Code[10])
    begin
        CurrItemVariant."Item No." := ItemNo;
        CurrItemVariant.Code := VariantCode;
    end;

    local procedure EqualItemVariant(CurrItemVariant: Record "Item Variant"; ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    begin
        exit((CurrItemVariant."Item No." = ItemNo) and (CurrItemVariant.Code = VariantCode));
    end;

    procedure FindWarehouseRequestForSalesOrder(var WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
        CheckWhseShipmentConflict(SalesHeader);
        CheckSalesHeader(SalesHeader, true);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetSourceFilter(Database::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        OnFindWarehouseRequestForSalesOrderOnAfterWhseRqstSetFilters(WarehouseRequest, SalesHeader);
        GetRequireShipRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForSalesOrder(WarehouseRequest, SalesHeader);
    end;

    local procedure FindWarehouseRequestForPurchReturnOrder(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetSourceFilter(Database::"Purchase Line", PurchaseHeader."Document Type".AsInteger(), PurchaseHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        OnFindWarehouseRequestForPurchReturnOrderOnAfterWhseRqstSetFilters(WarehouseRequest, PurchaseHeader);
        GetRequireShipRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForPurchReturnOrder(WarehouseRequest, PurchaseHeader);
    end;

    local procedure FindWarehouseRequestForOutbndTransferOrder(var WarehouseRequest: Record "Warehouse Request"; TransHeader: Record "Transfer Header")
    begin
        TransHeader.TestField(Status, TransHeader.Status::Released);
        CheckTransferHeader(TransHeader, true);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Outbound);
        WarehouseRequest.SetSourceFilter(Database::"Transfer Line", 0, TransHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        OnFindWarehouseRequestForOutbndTransferOrderOnAfterWhseRqstSetFilters(WarehouseRequest, TransHeader);
        GetRequireShipRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForOutbndTransferOrder(WarehouseRequest, TransHeader);
    end;

    local procedure CheckWhseShipmentConflict(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckWhseShipmentConflict(SalesHeader, IsHandled);
        if not IsHandled then
            if SalesHeader.WhseShipmentConflict(SalesHeader."Document Type", SalesHeader."No.", SalesHeader."Shipping Advice") then
                Error(Text003, Format(SalesHeader."Shipping Advice"));
    end;

    local procedure UpdateShipmentHeaderStatus(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
        WarehouseShipmentHeader.Find();
        WarehouseShipmentHeader."Document Status" := WarehouseShipmentHeader.GetShipmentStatus(0);
        WarehouseShipmentHeader.Modify();
    end;

    procedure ShowResult(WhseShipmentCreated: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowResult(WhseShipmentCreated, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit;

        GetSourceDocuments.ShowShipmentDialog();
        if WhseShipmentCreated then
            OpenWarehouseShipmentPage();
    end;

    local procedure GenerateLocationCodeFilter(LocationList: List of [Code[20]]; var LocationCodeFilter: Text; BlankLocationExists: Boolean)
    var
        TypeHelper: Codeunit "Type Helper";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        LocationFilter: Code[20];
        WarehouseLocationAddToFilter: TextBuilder;
    begin
        if LocationList.Count() >= (TypeHelper.GetMaxNumberOfParametersInSQLQuery() - 100) then
            exit;

        if LocationList.Count() = 0 then
            exit;

        foreach LocationFilter in LocationList do begin
            if WarehouseLocationAddToFilter.Length() > 0 then
                WarehouseLocationAddToFilter.Append('|');
            WarehouseLocationAddToFilter.Append(SelectionFilterManagement.AddQuotes(LocationFilter));
        end;

        LocationCodeFilter := WarehouseLocationAddToFilter.ToText();

        if BlankLocationExists then
            if LocationCodeFilter = '' then
                LocationCodeFilter := ''''''
            else
                LocationCodeFilter += '|' + '''''';
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckAvailability(NotAvailable: Boolean; ShowError: Boolean; ErrorMessage: Text; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForSalesOrder(var WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForPurchReturnOrder(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForOutbndTransferOrder(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnAfterFindWarehouseRequestForServiceOrder(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnAfterFindWarehouseRequestForServiceOrder(WarehouseRequest, ServiceHeader);
    end;

    [Obsolete('Moved to codeunit ServGetSourceDocOutbound', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForServiceOrder(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetOutboundDocs(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSingleOutboundDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckAvailability(CurrItemVariant: Record "Item Variant"; QtyBaseNeeded: Decimal; LocationCode: Code[10]; FormCaption: Text[1024]; SourceType: Integer; SourceSubType: Integer; SourceID: Code[20]; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesHeader(var SalesHeader: Record "Sales Header"; var ShowError: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesLines(SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckTransferHeader(var TransferHeader: Record "Transfer Header"; var ShowError: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromPurchaseReturnOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromOutbndTransferOrder(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromSalesOrder(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCreateFromServiceOrder(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnBeforeCreateFromServiceOrder(ServiceHeader);
    end;

    [Obsolete('Moved to codeunit ServGetSourceDocOutbound', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromServiceOrder(var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseShipmentHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var Rusult: Boolean; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseShipmentHeaderFromWhseRequestOnAfterClearGetSourceDocuments(var WarehouseRequest: Record "Warehouse Request"; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeOpenWarehouseShipmentPage(var GetSourceDocuments: Report "Get Source Documents"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckSalesHeaderMarkSalesLines(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocForHeader(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRequireShipRqst(var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnAfterSetLineFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnAfterSetItemVariant(var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckSalesHeaderOnBeforeCheckAvailability(SalesHeader: Record "Sales Header"; SalesLine: record "Sales Line"; ShowError: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckTransferHeaderOnAfterSetLineFilters(var TransferLine: Record "Transfer Line"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSingleOutboundDoc(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowResult(WhseShipmentCreated: Boolean; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForPurchReturnOrderOnAfterWhseRqstSetFilters(var WhseRqst: Record "Warehouse Request"; var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForSalesOrderOnAfterWhseRqstSetFilters(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForOutbndTransferOrderOnAfterWhseRqstSetFilters(var WhseRqst: Record "Warehouse Request"; var TransferOrder: Record "Transfer Header")
    begin
    end;

#if not CLEAN25
    internal procedure RunOnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
        OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(WarehouseRequest, ServiceHeader);
    end;

    [Obsolete('Moved to codeunit ServGetSourceDocOutbound', '25.0')]
    [IntegrationEvent(false, false)]
    local procedure OnFindWarehouseRequestForServiceOrderOnAfterSetWhseRqstFilters(var WarehouseRequest: Record "Warehouse Request"; var ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleWhsePickDocOnWhsePickRqstSetFilters(var WhsePickRequest: Record "Whse. Pick Request"; CurrentWhseWkshTemplate: Code[10]; CurrentWhseWkshName: Code[10]; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleOutboundDocOnSetFilterGroupFilters(var WhseRqst: Record "Warehouse Request"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleOutboundDocOnAfterSetFilters(var WhseRqst: Record "Warehouse Request"; WhseShptHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseShipmentConflict(SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetOutboundDocsOnBeforeUpdateShipmentHeaderStatus(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;
}

