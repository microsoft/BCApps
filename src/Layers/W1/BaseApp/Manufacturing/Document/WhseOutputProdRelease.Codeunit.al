// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Location;
using Microsoft.Warehouse.Request;

codeunit 7325 "Whse.-Output Prod. Release"
{
    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WhseRqst: Record "Warehouse Request";
        ProdOrderLine: Record "Prod. Order Line";
        WhseRqstCreated: Boolean;

    procedure Release(ProdHeader: Record "Production Order"): Boolean
    var
        LocationCode2: Code[10];
    begin
        WhseRqstCreated := false;
        if ProdHeader.Status <> ProdHeader.Status::Released then
            exit;

        OnBeforeRelease(ProdHeader);
        LocationCode2 := '';
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.");
        ProdOrderLine.SetRange(Status, ProdHeader.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdHeader."No.");
        if ProdOrderLine.Find('-') then
            repeat
                if ProdOrderLine."Location Code" <> LocationCode2 then
                    CreateWarehouseRequest(ProdOrderLine, ProdHeader);
                LocationCode2 := ProdOrderLine."Location Code";
            until ProdOrderLine.Next() = 0;
        exit(WhseRqstCreated);
    end;

    local procedure CreateWarehouseRequest(var ProdOrderLine: Record "Prod. Order Line"; var ProdOrder: Record "Production Order")
    var
        ProdOrderLine2: Record "Prod. Order Line";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
    begin
        GetLocation(ProdOrderLine."Location Code");
        if Location.Code <> '' then
            if Location."Prod. Output Whse. Handling" <> Location."Prod. Output Whse. Handling"::"Inventory Put-away" then
                exit;

        ProdOrderLine2.Copy(ProdOrderLine);
        ProdOrderLine2.SetRange("Location Code", ProdOrderLine."Location Code");
        ProdOrderLine2.SetRange("Unit of Measure Code", '');
        if ProdOrderLine2.FindFirst() then
            ProdOrderLine2.TestField("Unit of Measure Code");

        WhseRqst.Init();
        WhseRqst.Type := WhseRqst.Type::Inbound;
        WhseRqst."Location Code" := ProdOrderLine."Location Code";
        WhseRqst."Source Type" := Database::"Prod. Order Line";
        WhseRqst."Source No." := ProdOrderLine."Prod. Order No.";
        WhseRqst."Source Subtype" := ProdOrderLine.Status.AsInteger();
        WhseRqst."Source Document" := WhseRqst."Source Document"::"Prod. Output";
        WhseRqst."Document Status" := WhseRqst."Document Status"::Released;
        WhseRqst."Completely Handled" := ProdOrderCompletelyHandled(ProdOrder, ProdOrderLine."Location Code");
        ProdOrderWarehouseMgt.SetDestinationType(ProdOrder, WhseRqst);
        OnBeforeWhseRequestInsert(WhseRqst, ProdOrderLine, ProdOrder);
        if not WhseRqst.Insert() then
            WhseRqst.Modify();

        WhseRqstCreated := true;

        OnAfterCreateWhseRqst(ProdOrder, ProdOrderLine, WhseRqst);
    end;

    procedure DeleteLine(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderLine2: Record "Prod. Order Line";
        KeepWarehouseRequest: Boolean;
    begin
        KeepWarehouseRequest := false;
        GetLocation(ProdOrderLine2."Location Code");
        if (Location."Prod. Output Whse. Handling" = Location."Prod. Output Whse. Handling"::"Inventory Put-away") and (not Location."Directed Put-away and Pick") then begin
            ProdOrderLine2.Reset();
            ProdOrderLine2.SetRange(Status, ProdOrderLine.Status);
            ProdOrderLine2.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
            ProdOrderLine2.SetRange("Location Code", ProdOrderLine."Location Code");
            if ProdOrderLine2.Find('-') then
                repeat
                    if ((ProdOrderLine2.Status <> ProdOrderLine.Status) or
                        (ProdOrderLine2."Prod. Order No." <> ProdOrderLine."Prod. Order No.") or
                        (ProdOrderLine2."Line No." <> ProdOrderLine."Line No.")) and
                       (ProdOrderLine2."Remaining Quantity" <> 0)
                    then
                        KeepWarehouseRequest := true;
                until (ProdOrderLine2.Next() = 0) or KeepWarehouseRequest;
        end;

        if not KeepWarehouseRequest then
            DeleteWarehouseRequest(ProdOrderLine, false);

        OnAfterDeleteLine(ProdOrderLine, KeepWarehouseRequest);
    end;

    local procedure DeleteWarehouseRequest(ProdOrderLine: Record "Prod. Order Line"; DeleteAllWhseRqst: Boolean)
    var
        WarehouseRequest: Record "Warehouse Request";
    begin
        WarehouseRequest.SetRange(Type, WarehouseRequest.Type::Inbound);
        WarehouseRequest.SetRange("Source Type", Database::"Prod. Order Line");
        WarehouseRequest.SetRange("Source No.", ProdOrderLine."Prod. Order No.");
        if not DeleteAllWhseRqst then begin
            WarehouseRequest.SetRange("Source Subtype", ProdOrderLine.Status);
            WarehouseRequest.SetRange("Location Code", ProdOrderLine."Location Code");
        end;
        WarehouseRequest.DeleteAll(true);
    end;

    procedure FinishedDelete(var ProdHeader: Record "Production Order")
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.");
        ProdOrderLine.SetRange(Status, ProdHeader.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdHeader."No.");
        if ProdOrderLine.Find('-') then
            DeleteWarehouseRequest(ProdOrderLine, true);
    end;

    local procedure ProdOrderCompletelyHandled(ProdOrder: Record "Production Order"; LocationCode: Code[10]): Boolean
    var
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        ProdOrderLine2.SetRange(Status, ProdOrder.Status);
        ProdOrderLine2.SetRange("Prod. Order No.", ProdOrder."No.");
        ProdOrderLine2.SetRange("Location Code", LocationCode);
        ProdOrderLine2.SetFilter("Remaining Quantity", '<>0');
        exit(ProdOrderLine2.IsEmpty());
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then
                Location.GetLocationSetup(LocationCode, Location)
            else
                Location.Get(LocationCode);
    end;

    procedure CheckWhseRqst(ProductionOrder: Record "Production Order"): Boolean
    var
        ProdOrderLine2: Record "Prod. Order Line";
    begin
        WhseRqstCreated := true;
        ProdOrderLine2.SetCurrentKey(Status, "Prod. Order No.");
        ProdOrderLine2.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine2.SetRange("Prod. Order No.", ProductionOrder."No.");
        if ProdOrderLine2.Find('-') then
            repeat
                GetLocation(ProdOrderLine2."Location Code");
                if Location.Code <> '' then
                    if Location."Prod. Output Whse. Handling" <> Location."Prod. Output Whse. Handling"::"Inventory Put-away" then
                        WhseRqstCreated := false
                    else
                        if not WhseRqst.Get(
                             WhseRqst.Type::Inbound,
                             ProdOrderLine2."Location Code",
                             Database::"Prod. Order Line",
                             ProdOrderLine2.Status,
                             ProdOrderLine2."Prod. Order No.")
                        then
                            WhseRqstCreated := false;
                OnAfterCheckWhseRqstProdOrderLine(ProdOrderLine2, WhseRqst, WhseRqstCreated);
            until (ProdOrderLine2.Next() = 0) or not WhseRqstCreated;
        exit(WhseRqstCreated);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCheckWhseRqstProdOrderLine(ProdOrderLine: Record "Prod. Order Line"; WhseRequest: Record "Warehouse Request"; var WhseRequestCreated: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCreateWhseRqst(var ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; var WarehouseRequest: Record "Warehouse Request")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteLine(ProdOrderLine: Record "Prod. Order Line"; KeepWhseRqst: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeRelease(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWhseRequestInsert(var WarehouseRequest: Record "Warehouse Request"; ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order")
    begin
    end;
}

