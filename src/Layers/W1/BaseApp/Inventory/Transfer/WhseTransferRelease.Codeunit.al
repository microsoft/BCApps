// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Transfer;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 5773 "Whse.-Transfer Release"
{

    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WhseManagement: Codeunit "Whse. Management";
        CalledFromTransferOrder: Boolean;

    procedure Release(TransferHeader: Record "Transfer Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        OnBeforeRelease(TransferHeader);

        InitializeWhseRequest(WarehouseRequest, TransferHeader, TransferHeader.Status::Released);

        if ShouldCreateInboundWhseRequest(TransferHeader."Transfer-to Code") then
            CreateInboundWhseRequest(WarehouseRequest, TransferHeader);
        if ShouldCreateOutboundWhseRequest(TransferHeader."Transfer-from Code") then
            CreateOutboundWhseRequest(WarehouseRequest, TransferHeader);

        DeleteOpenWhseRequest(TransferHeader."No.");

        OnAfterRelease(TransferHeader);
    end;

    procedure Reopen(TransferHeader: Record "Transfer Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        OnBeforeReopen(TransferHeader);

        if WarehouseRequest.Get("Warehouse Request Type"::Inbound, TransferHeader."Transfer-to Code", DATABASE::"Transfer Line", 1, TransferHeader."No.") then begin
            WarehouseRequest."Document Status" := TransferHeader.Status::Open;
            WarehouseRequest.Modify();
        end;
        if WarehouseRequest.Get("Warehouse Request Type"::Outbound, TransferHeader."Transfer-from Code", DATABASE::"Transfer Line", 0, TransferHeader."No.") then begin
            WarehouseRequest."Document Status" := TransferHeader.Status::Open;
            WarehouseRequest.Modify();
        end;

        OnAfterReopen(TransferHeader);
    end;

    [Scope('OnPrem')]
    procedure UpdateExternalDocNoForReleasedOrder(TransferHeader: Record "Transfer Header")
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        if WarehouseRequest.Get("Warehouse Request Type"::Inbound, TransferHeader."Transfer-to Code", DATABASE::"Transfer Line", 1, TransferHeader."No.") then begin
            WarehouseRequest."External Document No." := TransferHeader."External Document No.";
            WarehouseRequest.Modify();
        end;
        if WarehouseRequest.Get("Warehouse Request Type"::Outbound, TransferHeader."Transfer-from Code", DATABASE::"Transfer Line", 0, TransferHeader."No.") then begin
            WarehouseRequest."External Document No." := TransferHeader."External Document No.";
            WarehouseRequest.Modify();
        end;
    end;

    procedure InitializeWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header"; DocumentStatus: Option)
    begin
        WarehouseRequest."Source Type" := DATABASE::"Transfer Line";
        WarehouseRequest."Source No." := TransferHeader."No.";
        WarehouseRequest."Document Status" := DocumentStatus;
        WarehouseRequest."Destination Type" := WarehouseRequest."Destination Type"::Location;
        WarehouseRequest."External Document No." := TransferHeader."External Document No.";
    end;

    procedure CreateInboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
        CheckUnitOfMeasureCode(TransferHeader."No.");
        TransferHeader.SetRange("Location Filter", TransferHeader."Transfer-to Code");
        TransferHeader.CalcFields("Completely Received");

        WarehouseRequest.Type := WarehouseRequest.Type::Inbound;
        WarehouseRequest."Source Subtype" := 1;
        WarehouseRequest."Source Document" := WhseManagement.GetWhseRqstSourceDocument(WarehouseRequest."Source Type", WarehouseRequest."Source Subtype");
        WarehouseRequest."Expected Receipt Date" := TransferHeader."Receipt Date";
        WarehouseRequest."Location Code" := TransferHeader."Transfer-to Code";
        WarehouseRequest."Completely Handled" := TransferHeader."Completely Received";
        WarehouseRequest."Shipment Method Code" := TransferHeader."Shipment Method Code";
        WarehouseRequest."Shipping Agent Code" := TransferHeader."Shipping Agent Code";
        WarehouseRequest."Shipping Agent Service Code" := TransferHeader."Shipping Agent Service Code";
        WarehouseRequest."Destination No." := TransferHeader."Transfer-to Code";
        OnBeforeCreateWhseRequest(WarehouseRequest, TransferHeader);
        if CalledFromTransferOrder then begin
            if WarehouseRequest.Modify() then;
        end else
            if not WarehouseRequest.Insert() then
                WarehouseRequest.Modify();

        OnAfterCreateInboundWhseRequest(WarehouseRequest, TransferHeader);
    end;

    procedure CreateOutboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
        CheckUnitOfMeasureCode(TransferHeader."No.");
        TransferHeader.SetRange("Location Filter", TransferHeader."Transfer-from Code");
        TransferHeader.CalcFields("Completely Shipped");

        WarehouseRequest.Type := WarehouseRequest.Type::Outbound;
        WarehouseRequest."Source Subtype" := 0;
        WarehouseRequest."Source Document" := WhseManagement.GetWhseRqstSourceDocument(WarehouseRequest."Source Type", WarehouseRequest."Source Subtype");
        WarehouseRequest."Location Code" := TransferHeader."Transfer-from Code";
        WarehouseRequest."Completely Handled" := TransferHeader."Completely Shipped";
        WarehouseRequest."Shipment Method Code" := TransferHeader."Shipment Method Code";
        WarehouseRequest."Shipping Agent Code" := TransferHeader."Shipping Agent Code";
        WarehouseRequest."Shipping Agent Service Code" := TransferHeader."Shipping Agent Service Code";
        WarehouseRequest."Shipping Advice" := TransferHeader."Shipping Advice";
        WarehouseRequest."Shipment Date" := TransferHeader."Shipment Date";
        WarehouseRequest."Destination No." := TransferHeader."Transfer-from Code";
        OnBeforeCreateWhseRequest(WarehouseRequest, TransferHeader);
        if not WarehouseRequest.Insert() then
            WarehouseRequest.Modify();

        OnAfterCreateOutboundWhseRequest(WarehouseRequest, TransferHeader);
    end;

    local procedure DeleteOpenWhseRequest(TransferOrderNo: Code[20])
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetCurrentKey("Source Type", "Source No.");
        WarehouseRequest.SetRange("Source Type", DATABASE::"Transfer Line");
        WarehouseRequest.SetRange("Source No.", TransferOrderNo);
        WarehouseRequest.SetRange("Document Status", WarehouseRequest."Document Status"::Open);
        if not WarehouseRequest.IsEmpty() then
            WarehouseRequest.DeleteAll(true);
    end;

    procedure SetCallFromTransferOrder(CalledFromTransferOrder2: Boolean)
    begin
        CalledFromTransferOrder := CalledFromTransferOrder2;
    end;

    local procedure CheckUnitOfMeasureCode(DocumentNo: Code[20])
    var
        TransferLine: Record "Transfer Line";
    begin
        TransferLine.SetRange("Document No.", DocumentNo);
        TransferLine.SetRange("Unit of Measure Code", '');
        TransferLine.SetFilter("Item No.", '<>%1', '');
        OnCheckUnitOfMeasureCodeOnAfterTransLineSetFilters(TransferLine, DocumentNo);
        if TransferLine.FindFirst() then
            TransferLine.TestField("Unit of Measure Code");
    end;


    local procedure ShouldCreateInboundWhseRequest(LocationCode: Code[10]) ShouldCreate: Boolean
    begin
        ShouldCreate := Location.RequireReceive(LocationCode) or Location.RequirePutaway(LocationCode);

        OnAfterShouldCreateInboundWhseRequest(LocationCode, ShouldCreate);
    end;

    local procedure ShouldCreateOutboundWhseRequest(LocationCode: Code[10]) ShouldCreate: Boolean;
    begin
        ShouldCreate := Location.RequireShipment(LocationCode) or Location.RequirePicking(LocationCode);

        OnAfterShouldCreateOutboundWhseRequest(LocationCode, ShouldCreate);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateInboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateOutboundWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WarehouseRequest: Record "Warehouse Request"; TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterReopen(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReopen(var TransferHeader: Record "Transfer Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckUnitOfMeasureCodeOnAfterTransLineSetFilters(var TransLine: Record "Transfer Line"; DocumentNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateInboundWhseRequest(LocationCode: Code[20]; var ShouldCreate: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShouldCreateOutboundWhseRequest(LocationCode: Code[20]; var ShouldCreate: Boolean)
    begin
    end;
}

