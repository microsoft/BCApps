// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 5770 "Whse.-Service Release"
{

    trigger OnRun()
    begin
    end;

    var
        WarehouseRequest: Record "Warehouse Request";
        ServiceLine: Record "Service Line";
        Location: Record Location;
        OldLocationCode: Code[10];
        First: Boolean;

    procedure Release(ServiceHeader: Record "Service Header")
    var
        WhseType: Enum "Warehouse Request Type";
        OldWhseType: Enum "Warehouse Request Type";
    begin
        OnBeforeRelease(ServiceHeader);

        if ServiceHeader."Document Type" <> "Service Document Type"::Order then
            exit;

        ServiceLine.SetCurrentKey("Document Type", "Document No.", "Location Code");
        ServiceLine.SetRange("Document Type", ServiceHeader."Document Type");
        ServiceLine.SetRange("Document No.", ServiceHeader."No.");
        ServiceLine.SetRange(Type, ServiceLine.Type::Item);
        ServiceLine.SetRange("Job No.", '');
        OnAfterReleaseSetFilters(ServiceLine, ServiceHeader);
        if ServiceLine.FindSet() then begin
            First := true;
            repeat
                if ServiceLine.IsInventoriableItem() then begin
                    if (ServiceHeader."Document Type" = "Service Document Type"::Order) and (ServiceLine.Quantity >= 0) then
                        WhseType := WhseType::Outbound
                    else
                        WhseType := WhseType::Inbound;

                    if First or (ServiceLine."Location Code" <> OldLocationCode) or (WhseType <> OldWhseType) then
                        CreateWarehouseRequest(ServiceHeader, ServiceLine, WhseType);

                    OnAfterCreateWhseRqst(ServiceHeader, ServiceLine, WhseType.AsInteger());

                    First := false;
                    OldLocationCode := ServiceLine."Location Code";
                    OldWhseType := WhseType;
                end;
            until ServiceLine.Next() = 0;
        end;
        SetWhseRqstFiltersByStatus(ServiceHeader, WarehouseRequest, ServiceHeader."Release Status"::Open);
        WarehouseRequest.DeleteAll(true);

        OnAfterRelease(ServiceHeader);
    end;

    procedure Reopen(ServiceHeader: Record "Service Header")
    var
        WarehouseRequest2: Record "Warehouse Request";
    begin
        OnBeforeReopen(ServiceHeader);

        WarehouseRequest2.Type := WarehouseRequest2.Type::Outbound;
        SetWhseRqstFiltersByStatus(ServiceHeader, WarehouseRequest2, ServiceHeader."Release Status"::"Released to Ship");
        WarehouseRequest2.LockTable();
        if WarehouseRequest2.FindSet() then
            repeat
                WarehouseRequest2."Document Status" := ServiceHeader."Release Status"::Open.AsInteger();
                WarehouseRequest2.Modify();
            until WarehouseRequest2.Next() = 0;

        OnAfterReopen(ServiceHeader);
    end;

    procedure CreateWarehouseRequest(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; WhseType: Enum "Warehouse Request Type")
    var
        ServiceLine2: Record "Service Line";
    begin
        if ((WhseType = WhseType::Outbound) and
            (Location.RequireShipment(ServiceLine."Location Code") or
             Location.RequirePicking(ServiceLine."Location Code"))) or
           ((WhseType = WhseType::Inbound) and
            (Location.RequireReceive(ServiceLine."Location Code") or
             Location.RequirePutaway(ServiceLine."Location Code")))
        then begin
            ServiceLine2.Copy(ServiceLine);
            ServiceLine2.SetRange("Location Code", ServiceLine."Location Code");
            ServiceLine2.SetRange("Unit of Measure Code", '');
            if ServiceLine2.FindFirst() then
                ServiceLine2.TestField("Unit of Measure Code");

            WarehouseRequest.Type := WhseType;
            WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Service Order";
            WarehouseRequest."Source Type" := DATABASE::"Service Line";
            WarehouseRequest."Source Subtype" := ServiceHeader."Document Type".AsInteger();
            WarehouseRequest."Source No." := ServiceHeader."No.";
            WarehouseRequest."Shipping Advice" := ServiceHeader."Shipping Advice";
            WarehouseRequest."Document Status" := ServiceHeader."Release Status"::"Released to Ship".AsInteger();
            WarehouseRequest."Location Code" := ServiceLine."Location Code";
            WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Customer;
            WarehouseRequest."Destination No." := ServiceHeader."Customer No.";
            WarehouseRequest."External Document No." := ServiceHeader."External Document No.";
            WarehouseRequest."Shipment Date" := ServiceLine.GetShipmentDate();
            WarehouseRequest."Shipment Method Code" := ServiceHeader."Shipment Method Code";
            WarehouseRequest."Shipping Agent Code" := ServiceHeader."Shipping Agent Code";
            WarehouseRequest."Completely Handled" := CalcCompletelyShipped(ServiceLine);
            OnBeforeCreateWhseRequest(WarehouseRequest, ServiceHeader, ServiceLine);
            if not WarehouseRequest.Insert() then
                WarehouseRequest.Modify();
        end;
    end;

    local procedure CalcCompletelyShipped(ServiceLine: Record "Service Line"): Boolean
    var
        ServiceLineWithItem: Record "Service Line";
    begin
        ServiceLineWithItem.SetRange("Document Type", ServiceLine."Document Type");
        ServiceLineWithItem.SetRange("Document No.", ServiceLine."Document No.");
        ServiceLineWithItem.SetRange("Location Code", ServiceLine."Location Code");
        ServiceLineWithItem.SetRange(Type, ServiceLineWithItem.Type::Item);
        ServiceLineWithItem.SetRange("Completely Shipped", false);
        exit(ServiceLineWithItem.IsEmpty);
    end;

    procedure UpdateExternalDocNoForReleasedOrder(ServiceHeader: Record "Service Header")
    begin
        SetWhseRqstFiltersByStatus(ServiceHeader, WarehouseRequest, ServiceHeader."Release Status"::"Released to Ship");
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.ModifyAll("External Document No.", ServiceHeader."External Document No.");
    end;

    local procedure SetWhseRqstFiltersByStatus(ServiceHeader: Record "Service Header"; var WarehouseRequest: Record "Warehouse Request"; Status: Enum "Service Doc. Release Status")
    begin
        WarehouseRequest.Reset();
        WarehouseRequest.SetCurrentKey("Source Type", "Source Subtype", "Source No.");
        WarehouseRequest.SetRange("Source Type", DATABASE::"Service Line");
        WarehouseRequest.SetRange("Source Subtype", ServiceHeader."Document Type");
        WarehouseRequest.SetRange("Source No.", ServiceHeader."No.");
        WarehouseRequest.SetRange("Document Status", Status.AsInteger());
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRqst(var ServiceHeader: Record "Service Header"; var ServiceLine: Record "Service Line"; WhseType: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseSetFilters(var ServiceLine: Record "Service Line"; ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WarehouseRequest: Record "Warehouse Request"; ServiceHeader: Record "Service Header"; ServiceLine: Record "Service Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var ServiceHeader: Record "Service Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var ServiceHeader: Record "Service Header")
    begin
    end;
}

