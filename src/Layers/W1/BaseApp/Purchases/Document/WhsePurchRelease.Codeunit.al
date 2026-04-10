// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 5772 "Whse.-Purch. Release"
{
    Permissions = TableData "Warehouse Request" = rimd;

    trigger OnRun()
    begin
    end;

    var
        WarehouseRequest: Record "Warehouse Request";
        OldLocationCode: Code[10];
        First: Boolean;

    procedure Release(PurchaseHeader: Record "Purchase Header")
    var
        PurchaseLine: Record "Purchase Line";
        WhseType: Enum "Warehouse Request Type";
        OldWhseType: Enum "Warehouse Request Type";
        IsHandled: Boolean;
        DoCreateWhseRequest: Boolean;
    begin
        IsHandled := false;
        OnBeforeRelease(PurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Purchase Order";
            PurchaseHeader."Document Type"::"Return Order":
                WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Purchase Return Order";
            else
                exit;
        end;

        PurchaseLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
        PurchaseLine.SetRange(Type, PurchaseLine.Type::Item);
        PurchaseLine.SetRange("Drop Shipment", false);
        if PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order" then
            PurchaseLine.SetRange("Job No.", '');
        OnAfterReleaseSetFilters(PurchaseLine, PurchaseHeader);
        if PurchaseLine.FindSet() then begin
            First := true;
            repeat
                DoCreateWhseRequest := PurchaseLine.IsInventoriableItem() and not PurchaseLine.IsWorkCenter();
                OnReleaseOnBeforeCreateWhseRequest(PurchaseLine, DoCreateWhseRequest);
                if DoCreateWhseRequest then begin
                    if ((PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::Order) and (PurchaseLine.Quantity >= 0)) or
                        ((PurchaseHeader."Document Type" = PurchaseHeader."Document Type"::"Return Order") and (PurchaseLine.Quantity < 0))
                    then
                        WhseType := WhseType::Inbound
                    else
                        WhseType := WhseType::Outbound;
                    OnReleaseOnAfterSetWhseType(PurchaseHeader, PurchaseLine, WhseType);
                    if First or (PurchaseLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                        CreateWarehouseRequest(PurchaseHeader, PurchaseLine, WhseType);

                    OnReleaseOnAfterCreateWhseRequest(PurchaseHeader, PurchaseLine, WhseType.AsInteger());

                    First := false;
                    OldLocationCode := PurchaseLine."Location Code";
                    OldWhseType := WhseType;
                end;
            until PurchaseLine.Next() = 0;
        end;

        FilterWarehouseRequest(WarehouseRequest, PurchaseHeader, WarehouseRequest."Document Status"::Open);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.DeleteAll(true);

        OnAfterRelease(PurchaseHeader);
    end;

    procedure Reopen(PurchaseHeader: Record "Purchase Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReopen(PurchaseHeader, WarehouseRequest, IsHandled);
        if IsHandled then
            exit;

        FilterWarehouseRequest(WarehouseRequest, PurchaseHeader, WarehouseRequest."Document Status"::Released);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("Document Status", WarehouseRequest."Document Status"::Open);

        OnAfterReopen(PurchaseHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(PurchaseHeader: Record "Purchase Header")
    begin
        FilterWarehouseRequest(WarehouseRequest, PurchaseHeader, WarehouseRequest."Document Status"::Released);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("External Document No.", PurchaseHeader."Vendor Shipment No.");
    end;

    procedure CreateWarehouseRequest(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; WhseType: Enum "Warehouse Request Type")
    var
        PurchaseLine2: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        OnBeforeProcedureCreateWhseRequest(PurchaseHeader, PurchaseLine, WhseType, IsHandled);
        if not IsHandled then
            if ShouldCreateWarehouseRequest(WhseType, PurchaseLine."Location Code") then begin
                PurchaseLine2.Copy(PurchaseLine);
                PurchaseLine2.SetRange("Location Code", PurchaseLine."Location Code");
                PurchaseLine2.SetRange("Unit of Measure Code", '');
                if PurchaseLine2.FindFirst() then
                    PurchaseLine2.TestField("Unit of Measure Code");

                WarehouseRequest.Type := WhseType;
                WarehouseRequest."Source Type" := DATABASE::"Purchase Line";
                WarehouseRequest."Source Subtype" := PurchaseHeader."Document Type".AsInteger();
                WarehouseRequest."Source No." := PurchaseHeader."No.";
                WarehouseRequest."Shipment Method Code" := PurchaseHeader."Shipment Method Code";
                WarehouseRequest."Document Status" := PurchaseHeader.Status::Released.AsInteger();
                WarehouseRequest."Location Code" := PurchaseLine."Location Code";
                WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Vendor;
                WarehouseRequest."Destination No." := PurchaseHeader."Buy-from Vendor No.";
                WarehouseRequest."External Document No." := PurchaseHeader."Vendor Shipment No.";
                if WhseType = WhseType::Inbound then
                    WarehouseRequest."Expected Receipt Date" := PurchaseHeader."Expected Receipt Date"
                else
                    WarehouseRequest."Shipment Date" := PurchaseHeader."Expected Receipt Date";
                PurchaseHeader.SetRange("Location Filter", PurchaseLine."Location Code");
                PurchaseHeader.CalcFields("Completely Received");
                WarehouseRequest."Completely Handled" := PurchaseHeader."Completely Received";
                OnBeforeCreateWhseRequest(WarehouseRequest, PurchaseHeader, PurchaseLine, WhseType.AsInteger());
                if not WarehouseRequest.Insert() then
                    WarehouseRequest.Modify();

                OnAfterCreateWhseRqst(WarehouseRequest, PurchaseHeader, PurchaseLine, WhseType.AsInteger());
            end;
    end;

    local procedure FilterWarehouseRequest(var WarehouseRequest2: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header"; DocumentStatus: Option)
    begin
        WarehouseRequest2.Reset();
        WarehouseRequest2.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest2.SetRange("Source Type", DATABASE::"Purchase Line");
        WarehouseRequest2.SetRange("Source Subtype", PurchaseHeader."Document Type");
        WarehouseRequest2.SetRange("Source No.", PurchaseHeader."No.");
        WarehouseRequest2.SetRange("Document Status", DocumentStatus);

        OnAfterFilterWarehouseRequest(WarehouseRequest2, PurchaseHeader, DocumentStatus);
    end;

    local procedure ShouldCreateWarehouseRequest(WhseType: Enum "Warehouse Request Type"; LocationCode: Code[10]) ShouldCreate: Boolean;
    var
        Location: Record Location;
    begin
        if LocationCode <> '' then
            Location.Get(LocationCode);
        ShouldCreate :=
           ((WhseType = WhseType::Outbound) and
            (Location.RequireShipment(LocationCode) or
             Location.RequirePicking(LocationCode))) or
           ((WhseType = WhseType::Inbound) and
            (Location.RequireReceive(LocationCode) or
             Location.RequirePutaway(LocationCode)));

        OnAfterShouldCreateWarehouseRequest(Location, ShouldCreate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRqst(var WhseRqst: Record "Warehouse Request"; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterWarehouseRequest(var WarehouseRequest: Record "Warehouse Request"; PurchaseHeader: Record "Purchase Header"; DocumentStatus: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WhseRqst: Record "Warehouse Request"; var PurchHeader: Record "Purchase Header"; var PurchLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSetFilters(var PurchaseLine: Record "Purchase Line"; PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var PurchaseHeader: Record "Purchase Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var PurchaseHeader: Record "Purchase Header"; var WhseRqst: Record "Warehouse Request"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterCreateWhseRequest(PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; WhseType: Option Inbound,Outbound)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterSetWhseType(PurchaseHeader: Record "Purchase Header"; PurchaseLine: Record "Purchase Line"; var WarehouseRequestType: Enum "Warehouse Request Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateWarehouseRequest(Location: Record Location; var ShouldCreate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProcedureCreateWhseRequest(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; WhseType: Enum "Warehouse Request Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnBeforeCreateWhseRequest(var PurchaseLine: Record "Purchase Line"; var DoCreateWhseRequest: Boolean)
    begin
    end;
}

