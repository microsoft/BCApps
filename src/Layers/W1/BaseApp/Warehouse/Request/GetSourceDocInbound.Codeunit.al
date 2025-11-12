// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Request;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.Journal;
using System.Text;
using System.Reflection;

codeunit 5751 "Get Source Doc. Inbound"
{

    trigger OnRun()
    begin
    end;

    var
        GetSourceDocuments: Report "Get Source Documents";
        ServVendDocNo: Code[20];

    procedure SetServVendDocNo(NewServVendDocNo: Code[20]);
    begin
        ServVendDocNo := NewServVendDocNo;
    end;

    local procedure CreateWhseReceiptHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request") Result: Boolean
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateWhseReceiptHeaderFromWhseRequest(GetSourceDocuments, WarehouseRequest, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if WarehouseRequest.IsEmpty() then
            exit(false);

        Clear(GetSourceDocuments);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.SetHideDialog(true);
        OnBeforeGetSourceDocumentsRun(GetSourceDocuments, WarehouseRequest, ServVendDocNo);
        GetSourceDocuments.RunModal();

        GetSourceDocuments.GetLastReceiptHeader(WarehouseReceiptHeader);
        OnAfterCreateWhseReceiptHeaderFromWhseRequest(WarehouseReceiptHeader, WarehouseRequest, GetSourceDocuments);
        exit(true);
    end;

    procedure GetInboundDocs(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WhseGetSourceFilter: Record "Warehouse Source Filter";
        WhseSourceFilterSelection: Page "Filters to Get Source Docs.";
    begin
        WarehouseReceiptHeader.Find();
        WhseSourceFilterSelection.SetOneCreatedReceiptHeader(WarehouseReceiptHeader);
        WhseGetSourceFilter.FilterGroup(2);
        WhseGetSourceFilter.SetRange(Type, WhseGetSourceFilter.Type::Inbound);
        WhseGetSourceFilter.FilterGroup(0);
        WhseSourceFilterSelection.SetTableView(WhseGetSourceFilter);
        WhseSourceFilterSelection.RunModal();

        OnGetInboundDocsBeforeUpdateReceiptHeaderStatus(WarehouseReceiptHeader);
        UpdateReceiptHeaderStatus(WarehouseReceiptHeader);

        OnAfterGetInboundDocs(WarehouseReceiptHeader);
    end;

    procedure GetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    var
        WarehouseRequest: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        OnBeforeGetSingleInboundDoc(WarehouseReceiptHeader, IsHandled);
        if IsHandled then
            exit;

        Clear(GetSourceDocuments);
        WarehouseReceiptHeader.Find();

        SetWarehouseRequestFilters(WarehouseRequest, WarehouseReceiptHeader);

        GetSourceDocForHeader(WarehouseReceiptHeader, WarehouseRequest);

        UpdateReceiptHeaderStatus(WarehouseReceiptHeader);

        OnAfterGetSingleInboundDoc(WarehouseReceiptHeader);
    end;

    local procedure GetSourceDocForHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request")
    var
        SourceDocSelection: Page "Source Documents";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetSourceDocForHeader(WarehouseReceiptHeader, WarehouseRequest, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit;

        SourceDocSelection.LookupMode(true);
        SourceDocSelection.SetTableView(WarehouseRequest);
        if SourceDocSelection.RunModal() <> ACTION::LookupOK then
            exit;
        SourceDocSelection.GetResult(WarehouseRequest);

        GetSourceDocuments.SetOneCreatedReceiptHeader(WarehouseReceiptHeader);
        GetSourceDocuments.UseRequestPage(false);
        GetSourceDocuments.SetTableView(WarehouseRequest);
        GetSourceDocuments.RunModal();
    end;

    local procedure SetWarehouseRequestFilters(var WarehouseRequest: Record "Warehouse Request"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        WarehouseRequest.FilterGroup(2);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Location Code", WarehouseReceiptHeader."Location Code");
        WarehouseRequest.FilterGroup(0);
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        WarehouseRequest.SetRange("Completely Handled", false);

        OnAfterSetWarehouseRequestFilters(WarehouseRequest, WarehouseReceiptHeader);
    end;

    procedure CreateFromPurchOrder(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromPurchOrder(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        ShowDialog(CreateFromPurchOrderHideDialog(PurchaseHeader));
    end;

    procedure CreateFromPurchOrderHideDialog(PurchHeader: Record "Purchase Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindWarehouseRequestForPurchaseOrder(WarehouseRequest, PurchHeader);
        exit(CreateWhseReceiptHeaderFromWhseRequest(WarehouseRequest));
    end;

    procedure CreateFromSalesReturnOrder(SalesHeader: Record "Sales Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromSalesReturnOrder(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        ShowDialog(CreateFromSalesReturnOrderHideDialog(SalesHeader));
    end;

    procedure CreateFromSalesReturnOrderHideDialog(SalesHeader: Record "Sales Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindWarehouseRequestForSalesReturnOrder(WarehouseRequest, SalesHeader);
        exit(CreateWhseReceiptHeaderFromWhseRequest(WarehouseRequest));
    end;

    procedure CreateFromInbndTransferOrder(TransHeader: Record "Transfer Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCreateFromInbndTransferOrder(TransHeader, IsHandled);
        if IsHandled then
            exit;

        ShowDialog(CreateFromInbndTransferOrderHideDialog(TransHeader));
    end;

    procedure CreateFromInbndTransferOrderHideDialog(TransHeader: Record "Transfer Header"): Boolean
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        FindWarehouseRequestForInbndTransferOrder(WarehouseRequest, TransHeader);
        exit(CreateWhseReceiptHeaderFromWhseRequest(WarehouseRequest));
    end;

    procedure GetSingleWhsePutAwayDoc(CurrentWkshTemplateName: Code[10]; CurrentWkshName: Code[10]; LocationCode: Code[10])
    var
        WhsePutAwayRequest: Record "Whse. Put-away Request";
        GetWhseSourceDocuments: Report "Get Inbound Source Documents";
        WhsePutAwayDocSelection: Page "Put-away Selection";
    begin
        WhsePutAwayRequest.FilterGroup(2);
        WhsePutAwayRequest.SetRange("Completely Put Away", false);
        WhsePutAwayRequest.SetRange("Location Code", LocationCode);
        WhsePutAwayRequest.FilterGroup(0);

        WhsePutAwayDocSelection.LookupMode(true);
        WhsePutAwayDocSelection.SetTableView(WhsePutAwayRequest);
        if WhsePutAwayDocSelection.RunModal() <> ACTION::LookupOK then
            exit;

        WhsePutAwayDocSelection.GetResult(WhsePutAwayRequest);

        OnGetSingleWhsePutAwayDocOnAfterGetResultWhsePutAwayRqst(WhsePutAwayRequest);

        GetWhseSourceDocuments.SetWhseWkshName(
          CurrentWkshTemplateName, CurrentWkshName, LocationCode);

        GetWhseSourceDocuments.UseRequestPage(false);
        GetWhseSourceDocuments.SetTableView(WhsePutAwayRequest);
        GetWhseSourceDocuments.RunModal();
    end;

    procedure GetRequireReceiveRqst(var WarehouseRequest: Record "Warehouse Request")
    var
        Location: Record Location;
        LocationList: List of [Code[20]];
        LocationCodeFilter: Text;
        IsHandled: Boolean;
        BlankLocationExists: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetRequireReceiveRqst(WarehouseRequest, IsHandled);
        if IsHandled then
            exit;

        if WarehouseRequest.FindSet() then begin
            repeat
                if Location.RequireReceive(WarehouseRequest."Location Code") then begin
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

    local procedure FindWarehouseRequestForPurchaseOrder(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header")
    begin
        PurchaseHeader.TestField(Status, PurchaseHeader.Status::Released);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Type", Database::"Purchase Line");
        WarehouseRequest.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        GetRequireReceiveRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForPurchaseOrder(WarehouseRequest, PurchaseHeader);
    end;

    local procedure FindWarehouseRequestForSalesReturnOrder(var WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
        SalesHeader.TestField(Status, SalesHeader.Status::Released);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Type", Database::"Sales Line");
        WarehouseRequest.SetRange("Source Subtype", SalesHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", SalesHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        GetRequireReceiveRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForSalesReturnOrder(WarehouseRequest, SalesHeader);
    end;

    local procedure FindWarehouseRequestForInbndTransferOrder(var WarehouseRequest: Record "Warehouse Request"; TransHeader: Record "Transfer Header")
    begin
        TransHeader.TestField(Status, TransHeader.Status::Released);
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Type", Database::"Transfer Line");
        WarehouseRequest.SetRange("Source Subtype", 1);
        WarehouseRequest.SetRange("Source No.", TransHeader."No.");
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Released);
        GetRequireReceiveRqst(WarehouseRequest);

        OnAfterFindWarehouseRequestForInbndTransferOrder(WarehouseRequest, TransHeader);
    end;

    local procedure OpenWarehouseReceiptPage()
    var
        WarehouseReceiptHeader: Record "Warehouse Receipt Header";
        WMSManagement: Codeunit "WMS Management";
        IsHandled: Boolean;
    begin
        GetSourceDocuments.GetCreatedReceiptHeaders(WarehouseReceiptHeader);
        WarehouseReceiptHeader.MarkedOnly(true);
        WarehouseReceiptHeader.FindSet();
        IsHandled := false;
        OnOpenWarehouseReceiptPage(WarehouseReceiptHeader, ServVendDocNo, IsHandled, GetSourceDocuments);
        if IsHandled then
            exit;

        repeat
            WMSManagement.CheckUserIsWhseEmployeeForLocation(WarehouseReceiptHeader."Location Code", true);
        until WarehouseReceiptHeader.Next() = 0;
        case WarehouseReceiptHeader.Count() of
            1:
                Page.Run(Page::"Warehouse Receipt", WarehouseReceiptHeader);
            else
                Page.Run(Page::"Warehouse Receipts", WarehouseReceiptHeader);
        end;
    end;

    local procedure UpdateReceiptHeaderStatus(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
        WarehouseReceiptHeader.Find();
        WarehouseReceiptHeader."Document Status" := WarehouseReceiptHeader.GetHeaderStatus(0);
        WarehouseReceiptHeader.Modify();
    end;

    local procedure ShowDialog(WhseReceiptCreated: Boolean)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowDialog(GetSourceDocuments, WhseReceiptCreated, IsHandled);
        if IsHandled then
            exit;

        GetSourceDocuments.ShowReceiptDialog();
        if WhseReceiptCreated then
            OpenWarehouseReceiptPage();
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
    local procedure OnAfterCreateWhseReceiptHeaderFromWhseRequest(var WhseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request"; var GetSourceDocuments: Report "Get Source Documents");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForPurchaseOrder(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForSalesReturnOrder(var WarehouseRequest: Record "Warehouse Request"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFindWarehouseRequestForInbndTransferOrder(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetInboundDocs(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterSetWarehouseRequestFilters(var WarehouseRequest: Record "Warehouse Request"; WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromPurchOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromSalesReturnOrder(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateFromInbndTransferOrder(var TransferHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseReceiptHeaderFromWhseRequest(var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request"; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetRequireReceiveRqst(var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocForHeader(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSingleInboundDoc(var WarehouseReceiptHeader: Record "Warehouse Receipt Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowDialog(var GetSourceDocuments: Report "Get Source Documents"; var WhseReceiptCreated: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSourceDocumentsRun(var GetSourceDocuments: Report "Get Source Documents"; var WarehouseRequest: Record "Warehouse Request"; ServVendDocNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetSingleWhsePutAwayDocOnAfterGetResultWhsePutAwayRqst(var WhsePutAwayRequest: Record "Whse. Put-away Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnOpenWarehouseReceiptPage(WarehouseReceiptHeader: Record "Warehouse Receipt Header"; ServVendDocNo: Code[20]; var IsHandled: Boolean; var GetSourceDocuments: Report "Get Source Documents")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnGetInboundDocsBeforeUpdateReceiptHeaderStatus(var WarehouseReceiptHeader: Record "Warehouse Receipt Header")
    begin
    end;
}

