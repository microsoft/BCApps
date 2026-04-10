// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Inventory.Location;
using Microsoft.Manufacturing.Setup;
using Microsoft.Warehouse.Request;

codeunit 5774 "Whse.-Production Release"
{

    trigger OnRun()
    begin
    end;

    var
        Location: Record Location;
        WarehouseRequest: Record "Warehouse Request";
        WhsePickRequest: Record "Whse. Pick Request";
        ProdOrderComp: Record "Prod. Order Component";

    procedure Release(ProductionOrder: Record "Production Order")
    var
#if not CLEAN26
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
        LocationCode2: Code[10];
        CurrentSignFactor: Integer;
        OldSignFactor: Integer;
    begin
        if ProductionOrder.Status <> ProductionOrder.Status::Released then
            exit;

        OnBeforeReleaseWhseProdOrder(ProductionOrder);

        LocationCode2 := '';
        OldSignFactor := 0;
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp.SetRange(Status, ProductionOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProductionOrder."No.");
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ProdOrderComp.SetFilter(
              "Flushing Method",
              '%1|%2|%3|%4',
              ProdOrderComp."Flushing Method"::Manual,
              ProdOrderComp."Flushing Method"::"Pick + Manual",
              ProdOrderComp."Flushing Method"::"Pick + Forward",
              ProdOrderComp."Flushing Method"::"Pick + Backward")
        else
#endif
            ProdOrderComp.SetFilter(
              "Flushing Method",
              '%1|%2|%3',
              ProdOrderComp."Flushing Method"::"Pick + Manual",
              ProdOrderComp."Flushing Method"::"Pick + Forward",
              ProdOrderComp."Flushing Method"::"Pick + Backward");
        ProdOrderComp.SetRange("Planning Level Code", 0);
        ProdOrderComp.SetFilter("Remaining Quantity", '<>0');
        OnReleaseOnBeforeLoopProdOrderComponent(ProductionOrder, ProdOrderComp);
        if ProdOrderComp.Find('-') then
            CreateWarehouseRequest(ProdOrderComp, ProductionOrder);
        repeat
            CurrentSignFactor := SignFactor(ProdOrderComp.Quantity);
            if (ProdOrderComp."Location Code" <> LocationCode2) or
               (CurrentSignFactor <> OldSignFactor)
            then
                CreateWarehouseRequest(ProdOrderComp, ProductionOrder);
            LocationCode2 := ProdOrderComp."Location Code";
            OldSignFactor := CurrentSignFactor;
        until ProdOrderComp.Next() = 0;

        OnAfterRelease(ProductionOrder);
    end;

    local procedure CreateWarehouseRequest(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrder: Record "Production Order")
    var
        ProdOrderComp2: Record "Prod. Order Component";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
    begin
        GetLocation(ProdOrderComponent."Location Code");
        if ((not Location."Require Pick") and (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"No Warehouse Handling")) then
            exit;

        if (ProdOrderComponent."Flushing Method" = ProdOrderComponent."Flushing Method"::"Pick + Forward") and
           (ProdOrderComponent."Routing Link Code" = '')
        then
            exit;

        ProdOrderComp2.Copy(ProdOrderComponent);
        ProdOrderComp2.SetRange("Location Code", ProdOrderComponent."Location Code");
        ProdOrderComp2.SetRange("Unit of Measure Code", '');
        if ProdOrderComp2.FindFirst() then
            ProdOrderComp2.TestField("Unit of Measure Code");

        if Location."Prod. Consump. Whse. Handling" in [Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)", Enum::"Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"] then begin
            if ProdOrderComponent."Remaining Quantity" > 0 then begin
                WhsePickRequest.Init();
                WhsePickRequest."Document Type" := WhsePickRequest."Document Type"::Production;
                WhsePickRequest."Document Subtype" := ProdOrderComponent.Status.AsInteger();
                WhsePickRequest."Document No." := ProdOrderComponent."Prod. Order No.";
                WhsePickRequest.Status := WhsePickRequest.Status::Released;
                WhsePickRequest."Location Code" := ProdOrderComponent."Location Code";
                WhsePickRequest."Completely Picked" :=
                    ProdOrderCompletelyPicked(
                        ProdOrderComponent."Location Code", ProdOrder."No.", ProdOrder.Status, ProdOrderComponent."Line No.");
                if WhsePickRequest."Completely Picked" and (not ProdOrderComponent."Completely Picked") then
                    WhsePickRequest."Completely Picked" := false;
                OnBeforeCreateWhsePickRequest(WhsePickRequest, ProdOrderComponent, ProdOrder);
                if not WhsePickRequest.Insert() then
                    WhsePickRequest.Modify();
            end
        end else begin
            WarehouseRequest.Init();
            if ProdOrderComponent."Remaining Quantity" > 0 then
                WarehouseRequest.Type := WarehouseRequest.Type::Outbound
            else
                WarehouseRequest.Type := WarehouseRequest.Type::Inbound;
            WarehouseRequest."Location Code" := ProdOrderComponent."Location Code";
            WarehouseRequest."Source Type" := Database::"Prod. Order Component";
            WarehouseRequest."Source No." := ProdOrderComponent."Prod. Order No.";
            WarehouseRequest."Source Subtype" := ProdOrderComponent.Status.AsInteger();
            WarehouseRequest."Source Document" := WarehouseRequest."Source Document"::"Prod. Consumption";
            WarehouseRequest."Document Status" := WarehouseRequest."Document Status"::Released;
            ProdOrderWarehouseMgt.SetDestinationType(ProdOrder, WarehouseRequest);
            WarehouseRequest."Destination No." := ProdOrder."Source No.";
            WarehouseRequest."Completely Handled" :=
              ProdOrderCompletelyHandled(ProdOrder, ProdOrderComponent."Location Code");
            OnBeforeCreateWhseRequest(WarehouseRequest, ProdOrderComponent, ProdOrder);
            if not WarehouseRequest.Insert() then
                WarehouseRequest.Modify();
        end;
    end;

    procedure ReleaseLine(var ProdOrderComponent: Record "Prod. Order Component"; var OldProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrder: Record "Production Order";
        WarehouseRequestLocal: Record "Warehouse Request";
        WhsePickRequestLocal: Record "Whse. Pick Request";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        IsHandled: Boolean;
    begin
        OnBeforeReleaseLine(ProdOrderComponent, OldProdOrderComponent, IsHandled);
        if IsHandled then
            exit;

        GetLocation(ProdOrderComponent."Location Code");
        if Location."Prod. Consump. Whse. Handling" in [Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement",
                                                        Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (optional)"]
        then
            if ProdOrderComponent."Remaining Quantity" <> 0 then begin
                if ProdOrderComponent."Remaining Quantity" > 0 then
                    WarehouseRequestLocal.Type := WarehouseRequestLocal.Type::Outbound
                else
                    WarehouseRequestLocal.Type := WarehouseRequestLocal.Type::Inbound;
                ProdOrder.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.");
                WarehouseRequestLocal.Init();
                WarehouseRequestLocal."Location Code" := ProdOrderComponent."Location Code";
                WarehouseRequestLocal."Source Type" := Database::"Prod. Order Component";
                WarehouseRequestLocal."Source No." := ProdOrderComponent."Prod. Order No.";
                WarehouseRequestLocal."Source Subtype" := ProdOrderComponent.Status.AsInteger();
                WarehouseRequestLocal."Source Document" := WarehouseRequestLocal."Source Document"::"Prod. Consumption";
                WarehouseRequestLocal."Document Status" := WarehouseRequestLocal."Document Status"::Released;
                ProdOrderWarehouseMgt.SetDestinationType(ProdOrder, WarehouseRequestLocal);
                OnBeforeWarehouseRequestUpdate(WarehouseRequestLocal, ProdOrderComponent);
                if not WarehouseRequestLocal.Insert() then
                    WarehouseRequestLocal.Modify();
            end;

        if Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Warehouse Pick (mandatory)" then
            if ProdOrderComponent."Remaining Quantity" > 0 then begin
                WhsePickRequestLocal.Init();
                WhsePickRequestLocal."Document Type" := WhsePickRequestLocal."Document Type"::Production;
                WhsePickRequestLocal."Document Subtype" := ProdOrderComponent.Status.AsInteger();
                WhsePickRequestLocal."Document No." := ProdOrderComponent."Prod. Order No.";
                WhsePickRequestLocal.Status := WhsePickRequestLocal.Status::Released;
                WhsePickRequestLocal."Completely Picked" :=
                  ProdOrderCompletelyPicked(ProdOrderComponent."Location Code", ProdOrderComponent."Prod. Order No.", ProdOrderComponent.Status, ProdOrderComponent."Line No.");
                if WhsePickRequestLocal."Completely Picked" and (not ProdOrderComponent."Completely Picked") then
                    WhsePickRequestLocal."Completely Picked" := false;
                WhsePickRequestLocal."Location Code" := ProdOrderComponent."Location Code";
                OnBeforeCreateWhsePickRequest(WhsePickRequestLocal, ProdOrderComponent, ProdOrder);
                if not WhsePickRequestLocal.Insert() then
                    WhsePickRequestLocal.Modify();
            end;

        if (ProdOrderComponent."Line No." = OldProdOrderComponent."Line No.") and
           ((ProdOrderComponent."Location Code" <> OldProdOrderComponent."Location Code") or
            (ProdOrderComponent."Remaining Quantity" <= 0))
        then
            DeleteLine(OldProdOrderComponent);
    end;

    procedure DeleteLine(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderComponent2: Record "Prod. Order Component";
#if not CLEAN26
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
        KeepWarehouseRequest: Boolean;
    begin
        KeepWarehouseRequest := false;
        GetLocation(ProdOrderComponent."Location Code");
        ProdOrderComponent2.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComponent2.SetRange(Status, ProdOrderComponent.Status);
        ProdOrderComponent2.SetRange("Prod. Order No.", ProdOrderComponent."Prod. Order No.");
        ProdOrderComponent2.SetRange("Location Code", ProdOrderComponent."Location Code");
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ProdOrderComponent2.SetFilter(
              "Flushing Method", '%1|%2|%3|%4',
              ProdOrderComponent2."Flushing Method"::Manual,
              ProdOrderComponent2."Flushing Method"::"Pick + Manual",
              ProdOrderComponent2."Flushing Method"::"Pick + Forward",
              ProdOrderComponent2."Flushing Method"::"Pick + Backward")
        else
#endif
            ProdOrderComponent2.SetFilter(
              "Flushing Method", '%1|%2|%3',
              ProdOrderComponent2."Flushing Method"::"Pick + Manual",
              ProdOrderComponent2."Flushing Method"::"Pick + Forward",
              ProdOrderComponent2."Flushing Method"::"Pick + Backward");
        ProdOrderComponent2.SetRange("Planning Level Code", 0);
        ProdOrderComponent2.SetFilter("Remaining Quantity", '<>0');
        OnDeleteLineOnBeforeLoopProdOrderComponent(ProdOrderComponent, ProdOrderComponent2);
        if ProdOrderComponent2.Find('-') then
            repeat
                if ((ProdOrderComponent2.Status <> ProdOrderComponent.Status) or
                    (ProdOrderComponent2."Prod. Order No." <> ProdOrderComponent."Prod. Order No.") or
                    (ProdOrderComponent2."Prod. Order Line No." <> ProdOrderComponent."Prod. Order Line No.") or
                    (ProdOrderComponent2."Line No." <> ProdOrderComponent."Line No.")) and
                   ((not ProdOrderComponent2."Completely Picked") or
                    (Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"No Warehouse Handling"))
                then
                    KeepWarehouseRequest := true;
            until (ProdOrderComponent2.Next() = 0) or KeepWarehouseRequest;

        if not KeepWarehouseRequest then
            if Location."Prod. Consump. Whse. Handling" = Location."Prod. Consump. Whse. Handling"::"Inventory Pick/Movement" then
                DeleteWarehouseRequest(ProdOrderComponent, false)
            else
                DeleteWhsePickRequest(ProdOrderComponent, false);

        OnAfterDeleteLine(ProdOrderComponent);
    end;

    local procedure DeleteWhsePickRequest(ProdOrderComponent: Record "Prod. Order Component"; DeleteAllWhsePickRqst: Boolean)
    var
        WhsePickRequestLocal: Record "Whse. Pick Request";
    begin
        WhsePickRequestLocal.SetRange("Document Type", WhsePickRequestLocal."Document Type"::Production);
        WhsePickRequestLocal.SetRange("Document No.", ProdOrderComponent."Prod. Order No.");
        if not DeleteAllWhsePickRqst then begin
            WhsePickRequestLocal.SetRange("Document Subtype", ProdOrderComponent.Status);
            WhsePickRequestLocal.SetRange("Location Code", ProdOrderComponent."Location Code");
        end;
        if not WhsePickRequestLocal.IsEmpty() then
            WhsePickRequestLocal.DeleteAll(true);
    end;

    local procedure DeleteWarehouseRequest(ProdOrderComponent: Record "Prod. Order Component"; DeleteAllWhseRqst: Boolean)
    var
        WarehouseRequest2: Record "Warehouse Request";
    begin
        if not DeleteAllWhseRqst then
            case true of
                ProdOrderComponent."Remaining Quantity" > 0:
                    WarehouseRequest2.SetRange(Type, WarehouseRequest.Type::Outbound);
                ProdOrderComponent."Remaining Quantity" < 0:
                    WarehouseRequest2.SetRange(Type, WarehouseRequest.Type::Inbound);
                ProdOrderComponent."Remaining Quantity" = 0:
                    exit;
            end;
        WarehouseRequest2.SetRange("Source Type", Database::"Prod. Order Component");
        WarehouseRequest2.SetRange("Source No.", ProdOrderComponent."Prod. Order No.");
        if not DeleteAllWhseRqst then begin
            WarehouseRequest2.SetRange("Source Subtype", ProdOrderComponent.Status);
            WarehouseRequest2.SetRange("Location Code", ProdOrderComponent."Location Code");
        end;
        if not WarehouseRequest2.IsEmpty() then
            WarehouseRequest2.DeleteAll(true);
    end;

    procedure FinishedDelete(var ProdOrder: Record "Production Order")
    begin
        ProdOrderComp.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComp.SetRange(Status, ProdOrder.Status);
        ProdOrderComp.SetRange("Prod. Order No.", ProdOrder."No.");
        if ProdOrderComp.Find('-') then begin
            DeleteWhsePickRequest(ProdOrderComp, true);
            DeleteWarehouseRequest(ProdOrderComp, true);
        end;
    end;

    local procedure ProdOrderCompletelyPicked(LocationCode: Code[10]; ProdOrderNo: Code[20]; ProductionOrderStatus: Enum "Production Order Status"; CompLineNo: Integer): Boolean
    var
        ProdOrderComponent2: Record "Prod. Order Component";
#if not CLEAN26
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
        OnBeforeProdOrderCompletelyPicked(LocationCode, ProdOrderNo, ProductionOrderStatus, CompLineNo, ProdOrderComp);

        ProdOrderComponent2.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComponent2.SetRange(Status, ProductionOrderStatus);
        ProdOrderComponent2.SetRange("Prod. Order No.", ProdOrderNo);
        ProdOrderComponent2.SetRange("Location Code", LocationCode);
        ProdOrderComponent2.SetFilter("Line No.", '<>%1', CompLineNo);
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ProdOrderComponent2.SetFilter("Flushing Method", '%1|%2', ProdOrderComp."Flushing Method"::Manual, ProdOrderComp."Flushing Method"::"Pick + Manual")
        else
#endif
        ProdOrderComponent2.SetRange("Flushing Method", ProdOrderComp."Flushing Method"::"Pick + Manual");
        ProdOrderComponent2.SetRange("Planning Level Code", 0);
        ProdOrderComponent2.SetRange("Completely Picked", false);
        exit(ProdOrderComponent2.IsEmpty());
    end;

    local procedure ProdOrderCompletelyHandled(ProductionOrder: Record "Production Order"; LocationCode: Code[10]): Boolean
    var
        ProdOrderComponent: Record "Prod. Order Component";
#if not CLEAN26
        ManufacturingSetup: Record "Manufacturing Setup";
#endif
    begin
        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Location Code");
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderComponent.SetRange("Location Code", LocationCode);
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ProdOrderComponent.SetFilter(
              "Flushing Method", '%1|%2|%3|%4',
              ProdOrderComponent."Flushing Method"::Manual,
              ProdOrderComponent."Flushing Method"::"Pick + Manual",
              ProdOrderComponent."Flushing Method"::"Pick + Forward",
              ProdOrderComponent."Flushing Method"::"Pick + Backward")
        else
#endif
            ProdOrderComponent.SetFilter(
              "Flushing Method", '%1|%2|%3',
              ProdOrderComponent."Flushing Method"::"Pick + Manual",
              ProdOrderComponent."Flushing Method"::"Pick + Forward",
              ProdOrderComponent."Flushing Method"::"Pick + Backward");
        ProdOrderComponent.SetRange("Planning Level Code", 0);
        ProdOrderComponent.SetFilter("Remaining Quantity", '<>0');
        exit(ProdOrderComponent.IsEmpty());
    end;

    local procedure GetLocation(LocationCode: Code[10])
    begin
        if LocationCode <> Location.Code then
            if LocationCode = '' then begin
                Location.GetLocationSetup(LocationCode, Location);
                Location.Code := '';
            end else
                Location.Get(LocationCode);

        OnAfterGetLocation(Location, LocationCode);
    end;

    local procedure SignFactor(Quantity: Decimal): Integer
    begin
        if Quantity > 0 then
            exit(1);
        exit(-1);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteLine(var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterRelease(var ProductionOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhseRequest(var WarehouseRequest: Record "Warehouse Request"; ProdOrderComp: Record "Prod. Order Component"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreateWhsePickRequest(var WhsePickRequest: Record "Whse. Pick Request"; ProdOrderComp: Record "Prod. Order Component"; ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseLine(var ProdOrderComp: Record "Prod. Order Component"; var OldProdOrderComp: Record "Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeReleaseWhseProdOrder(var ProdOrder: Record "Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeWarehouseRequestUpdate(var WarehouseRequest: Record "Warehouse Request"; ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeProdOrderCompletelyPicked(var LocationCode: Code[10]; var ProdOrderNo: Code[20]; var ProductionOrderStatus: Enum "Production Order Status"; var CompLineNo: Integer; var ProdOrderComponent: Record "Prod. Order Component");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReleaseOnBeforeLoopProdOrderComponent(var ProductionOrder: Record "Production Order"; var ProdOrderComponent: Record "Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnDeleteLineOnBeforeLoopProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var ProdOrderComponent2: Record "Prod. Order Component")
    begin
    end;
}

