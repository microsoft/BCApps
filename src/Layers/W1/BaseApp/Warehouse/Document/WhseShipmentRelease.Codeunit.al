// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Document;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Activity;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Worksheet;

codeunit 7310 "Whse.-Shipment Release"
{

    trigger OnRun()
    begin
    end;

    var
#pragma warning disable AA0074
#pragma warning disable AA0470
        Text000: Label 'There is nothing to release for %1 %2.';
#pragma warning restore AA0470
        Text001: Label 'You cannot reopen the shipment because warehouse worksheet lines exist that must first be handled or deleted.';
        Text002: Label 'You cannot reopen the shipment because warehouse activity lines exist that must first be handled or deleted.';
#pragma warning restore AA0074
        SuppressCommit: Boolean;

    procedure Release(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        Location: Record Location;
        Location2: Record Location;
        WhsePickRequest: Record "Whse. Pick Request";
        WhseShptLine: Record "Warehouse Shipment Line";
        ATOLink: Record "Assemble-to-Order Link";
        AsmLine: Record "Assembly Line";
    begin
        if WhseShptHeader.Status = WhseShptHeader.Status::Released then
            exit;

        OnBeforeRelease(WhseShptHeader);

        WhseShptLine.SetRange("No.", WhseShptHeader."No.");
        WhseShptLine.SetFilter(Quantity, '<>0');

        CheckWhseShptLinesNotEmpty(WhseShptHeader, WhseShptLine);

        if WhseShptHeader."Location Code" <> '' then
            Location.Get(WhseShptHeader."Location Code");

        repeat
            WhseShptLine.TestField("Item No.");
            WhseShptLine.TestField("Unit of Measure Code");
            OnReleaseOnAfterWhseShptLineTestField(WhseShptLine, Location);
            if Location."Directed Put-away and Pick" then
                WhseShptLine.TestField("Zone Code");
            if Location."Bin Mandatory" then begin
                WhseShptLine.TestField("Bin Code");
                if WhseShptLine."Assemble to Order" then begin
                    ATOLink.AsmExistsForWhseShptLine(WhseShptLine);
                    AsmLine.SetCurrentKey("Document Type", "Document No.", Type);
                    AsmLine.SetRange("Document Type", ATOLink."Assembly Document Type");
                    AsmLine.SetRange("Document No.", ATOLink."Assembly Document No.");
                    AsmLine.SetRange(Type, AsmLine.Type::Item);
                    if AsmLine.FindSet() then
                        repeat
                            if AsmLine."Location Code" = Location.Code then
                                Location2 := Location
                            else
                                if (AsmLine."Location Code" <> '') and (Location2.Code <> AsmLine."Location Code") then
                                    Location2.Get(AsmLine."Location Code");

                            if (AsmLine."Location Code" <> '') and Location2."Bin Mandatory" then
                                if AsmLine.IsInventoriableItem() then
                                    if AsmLine.CalcQtyToPickBase() > 0 then
                                        AsmLine.TestField("Bin Code");
                        until AsmLine.Next() = 0;
                end;
            end;
        until WhseShptLine.Next() = 0;

        OnAfterTestWhseShptLine(WhseShptHeader, WhseShptLine);

        WhseShptHeader.Status := WhseShptHeader.Status::Released;
        WhseShptHeader.Modify();

        OnAfterReleaseWarehouseShipment(WhseShptHeader);

        CreateWhsePickRequest(WhseShptHeader);

        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        WhsePickRequest.SetRange("Document No.", WhseShptHeader."No.");
        WhsePickRequest.SetRange(Status, WhseShptHeader.Status::Open);
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.DeleteAll(true);
        if not SuppressCommit then
            Commit();

        OnAfterRelease(WhseShptHeader, WhseShptLine);
    end;

    procedure Reopen(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhsePickRequest: Record "Whse. Pick Request";
        PickWkshLine: Record "Whse. Worksheet Line";
        WhseActivLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        if WhseShptHeader.Status = WhseShptHeader.Status::Open then
            exit;

        IsHandled := false;
        OnBeforeReopen(WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        PickWkshLine.SetCurrentKey("Whse. Document Type", "Whse. Document No.");
        PickWkshLine.SetRange("Whse. Document Type", PickWkshLine."Whse. Document Type"::Shipment);
        PickWkshLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
        if not PickWkshLine.IsEmpty() then
            Error(Text001);

        WhseActivLine.SetCurrentKey("Whse. Document No.", "Whse. Document Type", "Activity Type");
        WhseActivLine.SetRange("Whse. Document No.", WhseShptHeader."No.");
        WhseActivLine.SetRange("Whse. Document Type", WhseActivLine."Whse. Document Type"::Shipment);
        WhseActivLine.SetRange("Activity Type", WhseActivLine."Activity Type"::Pick);
        if not WhseActivLine.IsEmpty() then
            Error(Text002);

        WhsePickRequest.SetRange("Document Type", WhsePickRequest."Document Type"::Shipment);
        WhsePickRequest.SetRange("Document No.", WhseShptHeader."No.");
        WhsePickRequest.SetRange(Status, WhseShptHeader.Status::Released);
        if not WhsePickRequest.IsEmpty() then
            WhsePickRequest.ModifyAll(Status, WhsePickRequest.Status::Open);

        WhseShptHeader.Status := WhseShptHeader.Status::Open;
        WhseShptHeader.Modify();

        OnAfterReopen(WhseShptHeader);
    end;

    local procedure CreateWhsePickRequest(var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        WhsePickRequest: Record "Whse. Pick Request";
        Location: Record Location;
    begin
        if Location.RequirePicking(WhseShptHeader."Location Code") then begin
            WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Shipment;
            WhsePickRequest."Document No." := WhseShptHeader."No.";
            WhsePickRequest.Status := WhseShptHeader.Status;
            WhsePickRequest."Location Code" := WhseShptHeader."Location Code";
            WhsePickRequest."Zone Code" := WhseShptHeader."Zone Code";
            WhsePickRequest."Bin Code" := WhseShptHeader."Bin Code";
            WhseShptHeader.CalcFields("Completely Picked");
            WhsePickRequest."Completely Picked" := WhseShptHeader."Completely Picked";
            WhsePickRequestInsert(WhsePickRequest, WhseShptHeader);
        end;
    end;

    local procedure WhsePickRequestInsert(var WhsePickRequest: Record "Whse. Pick Request"; var WhseShptHeader: Record "Warehouse Shipment Header")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeWhsePickRequestInsert(WhsePickRequest, WhseShptHeader, IsHandled);
        if IsHandled then
            exit;

        if not WhsePickRequest.Insert() then
            WhsePickRequest.Modify();
        OnAfterWhsePickRequestInsert(WhsePickRequest);
    end;

    local procedure CheckWhseShptLinesNotEmpty(WhseShptHeader: Record "Warehouse Shipment Header"; var WhseShptLine: Record "Warehouse Shipment Line")
    var
        IsHandled: Boolean;
    begin
        OnBeforeCheckWhseShptLinesNotEmpty(WhseShptHeader, WhseShptLine, IsHandled);
        if IsHandled then
            exit;

        if not WhseShptLine.Find('-') then
            Error(Text000, WhseShptHeader.TableCaption(), WhseShptHeader."No.");
    end;

    procedure SetSuppressCommit(NewSuppressCommit: Boolean)
    begin
        SuppressCommit := NewSuppressCommit;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReleaseWarehouseShipment(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTestWhseShptLine(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterWhsePickRequestInsert(var WhsePickRequest: Record "Whse. Pick Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var WarehouseShipmentHeader: Record "Warehouse Shipment Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhsePickRequestInsert(var WhsePickRequest: Record "Whse. Pick Request"; WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckWhseShptLinesNotEmpty(WarehouseShipmentHeader: Record "Warehouse Shipment Header"; var WarehouseShipmentLine: Record "Warehouse Shipment Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnAfterWhseShptLineTestField(var WarehouseShipmentLine: Record "Warehouse Shipment Line"; Location: Record Location)
    begin
    end;
}

