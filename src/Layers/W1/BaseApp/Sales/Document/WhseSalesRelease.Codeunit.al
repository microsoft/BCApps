// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 5771 "Whse.-Sales Release"
{
    Permissions = TableData "Warehouse Request" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WarehouseRequest: Record "Warehouse Request";
        OldLocationCode: Code[10];
        First: Boolean;

    procedure Release(SalesHeader: Record "Sales Header")
    var
        SalesLine: Record "Sales Line";
        WhseType: Enum "Warehouse Request Type";
        OldWhseType: Enum "Warehouse Request Type";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeRelease(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnBeforeReleaseSetWhseRequestSourceDocument(SalesHeader, WarehouseRequest, IsHandled);
        if not IsHandled then
            case SalesHeader."Document Type" of
                "Sales Document Type"::Order:
                    WarehouseRequest."Source Document" := "Warehouse Request Source Document"::"Sales Order";
                "Sales Document Type"::"Return Order":
                    WarehouseRequest."Source Document" := "Warehouse Request Source Document"::"Sales Return Order";
                else
                    exit;
            end;

        SalesLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SalesHeader."No.");
        SalesLine.SetRange(Type, SalesLine.Type::Item);
        SalesLine.SetRange("Drop Shipment", false);
        SalesLine.SetRange("Job No.", '');
        OnAfterReleaseSetFilters(SalesLine, SalesHeader);
        if SalesLine.FindSet() then begin
            First := true;
            repeat
                if SalesLine.IsInventoriableItem() then begin
                    if ((SalesHeader."Document Type" = "Sales Document Type"::Order) and (SalesLine.Quantity >= 0)) or
                        ((SalesHeader."Document Type" = "Sales Document Type"::"Return Order") and (SalesLine.Quantity < 0))
                    then
                        WhseType := WhseType::Outbound
                    else
                        WhseType := WhseType::Inbound;

                    OnReleaseOnBeforeCreateWhseRequest(SalesLine, OldWhseType, WhseType, First, SalesHeader);

                    if First or (SalesLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                        CreateWarehouseRequest(SalesHeader, SalesLine, WhseType, WarehouseRequest);

                    OnAfterReleaseOnAfterCreateWhseRequest(
                        SalesHeader, SalesLine, WhseType.AsInteger(), First, OldWhseType.AsInteger(), OldLocationCode);

                    First := false;
                    OldLocationCode := SalesLine."Location Code";
                    OldWhseType := WhseType;
                end;
            until SalesLine.Next() = 0;
        end;

        OnReleaseOnAfterCreateWhseRequest(SalesHeader, SalesLine);

        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest.SetRange("Document Status", SalesHeader.Status::Open);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.DeleteAll(true);

        OnAfterRelease(SalesHeader);
    end;

    procedure Reopen(SalesHeader: Record "Sales Header")
    var
        WarehouseRequest2: Record "Warehouse Request";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopen(SalesHeader, IsHandled);
        if IsHandled then
            exit;

        IsHandled := false;
        OnBeforeReopenSetWhseRequestSourceDocument(SalesHeader, WarehouseRequest2, IsHandled);

        WarehouseRequest2.Reset();
        WarehouseRequest2.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        if IsHandled then
            WarehouseRequest2.SetRange(Type, WarehouseRequest2.Type);
        WarehouseRequest2.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest2.SetRange("Document Status", SalesHeader.Status::Released);
        if not WarehouseRequest2.IsEmpty() then
            WarehouseRequest2.ModifyAll("Document Status", WarehouseRequest2."Document Status"::Open);

        OnAfterReopen(SalesHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(SalesHeader: Record "Sales Header")
    begin
        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetSourceFilter(DATABASE::"Sales Line", SalesHeader."Document Type".AsInteger(), SalesHeader."No.");
        WarehouseRequest.SetRange("Document Status", SalesHeader.Status::Released);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("External Document No.", SalesHeader."External Document No.");
    end;

    procedure CreateWarehouseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Enum "Warehouse Request Type"; var WarehouseRequest: Record "Warehouse Request")
    var
        SalesLine2: Record "Sales Line";
        IsHandled: Boolean;
    begin
        OnBeforeCreateWarehouseRequest(SalesHeader, SalesLine, WhseType, IsHandled);
        if not IsHandled then
            if ShouldCreateWarehouseRequest(WhseType, SalesLine."Location Code") then begin
                SalesLine2.Copy(SalesLine);
                SalesLine2.SetRange("Location Code", SalesLine."Location Code");
                SalesLine2.SetRange("Unit of Measure Code", '');
                if SalesLine2.FindFirst() then
                    SalesLine2.TestField("Unit of Measure Code");

                WarehouseRequest.Type := WhseType;
                WarehouseRequest."Source Type" := DATABASE::"Sales Line";
                WarehouseRequest."Source Subtype" := SalesHeader."Document Type".AsInteger();
                WarehouseRequest."Source No." := SalesHeader."No.";
                WarehouseRequest."Shipment Method Code" := SalesHeader."Shipment Method Code";
                WarehouseRequest."Shipping Agent Code" := SalesHeader."Shipping Agent Code";
                WarehouseRequest."Shipping Agent Service Code" := SalesHeader."Shipping Agent Service Code";
                WarehouseRequest."Shipping Advice" := SalesHeader."Shipping Advice";
                WarehouseRequest."Document Status" := SalesHeader.Status::Released.AsInteger();
                WarehouseRequest."Location Code" := SalesLine."Location Code";
                WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Customer;
                WarehouseRequest."Destination No." := SalesHeader."Sell-to Customer No.";
                WarehouseRequest."External Document No." := SalesHeader."External Document No.";
                if WhseType = WhseType::Inbound then
                    WarehouseRequest."Expected Receipt Date" := SalesHeader."Shipment Date"
                else
                    WarehouseRequest."Shipment Date" := SalesHeader."Shipment Date";
                SalesHeader.SetRange("Location Filter", SalesLine."Location Code");
                SalesHeader.CalcFields("Completely Shipped");
                WarehouseRequest."Completely Handled" := SalesHeader."Completely Shipped";
                OnBeforeCreateWhseRequest(WarehouseRequest, SalesHeader, SalesLine, WhseType.AsInteger());
                if not WarehouseRequest.Insert() then
                    WarehouseRequest.Modify();
                OnAfterCreateWhseRequest(WarehouseRequest, SalesHeader, SalesLine, WhseType.AsInteger());
            end;
    end;

    local procedure ShouldCreateWarehouseRequest(WhseType: Enum "Warehouse Request Type"; LocationCode: Code[10]) ShouldCreate: Boolean
    var
        Location: Record Location;
    begin
        if LocationCode <> '' then
            Location.Get(LocationCode);
        ShouldCreate :=
           ((WhseType = "Warehouse Request Type"::Outbound) and
            (Location.RequireShipment(LocationCode) or
             Location.RequirePicking(LocationCode))) or
           ((WhseType = "Warehouse Request Type"::Inbound) and
            (Location.RequireReceive(LocationCode) or
             Location.RequirePutaway(LocationCode)));

        OnAfterShouldCreateWarehouseRequest(Location, ShouldCreate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRequest(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WhseRqst: Record "Warehouse Request"; var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSetFilters(var SalesLine: Record "Sales Line"; SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseOnAfterCreateWhseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Option; First: Boolean; OldWhseType: Option; OldLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateWarehouseRequest(Location: Record Location; var ShouldCreate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseSetWhseRequestSourceDocument(var SalesHeader: Record "Sales Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var SalesHeader: Record "Sales Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopenSetWhseRequestSourceDocument(var SalesHeader: Record "Sales Header"; var WarehouseRequest: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnBeforeCreateWhseRequest(var SalesLine: Record "Sales Line"; OldWhseType: Enum "Warehouse Request Type"; WhseType: Enum "Warehouse Request Type"; var First: Boolean; var SalesHeader: Record "Sales Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterCreateWhseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWarehouseRequest(var SalesHeader: Record "Sales Header"; var SalesLine: Record "Sales Line"; WhseType: Enum "Warehouse Request Type"; var IsHandled: Boolean)
    begin
    end;
}

