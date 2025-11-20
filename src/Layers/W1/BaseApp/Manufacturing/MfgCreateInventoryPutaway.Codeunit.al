// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Warehouse.Request;
using Microsoft.Manufacturing.Document;
using Microsoft.Inventory.Tracking;
using System.Telemetry;
using Microsoft.Inventory.Location;

codeunit 99000878 "Mfg. Create Inventory Put-Away"
{
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
#if not CLEAN27
        CreateInventoryPutaway: Codeunit "Create Inventory Put-away";
#endif
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Job Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Job Whse. Handling in used for creating put-away lines.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnGetSourceDocHeaderForWhseRequest', '', true, true)]
    local procedure OnGetSourceDocHeaderForWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; var VendorDocNo: Code[35]; var SourceDocRecordVar: Variant);
    var
        ProductionOrder: Record "Production Order";
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Output":
                begin
                    ProductionOrder.Get(ProductionOrder.Status::Released, WarehouseRequest."Source No.");
                    PostingDate := WorkDate();
                    SourceDocRecordVar := ProductionOrder;
                end;
            WarehouseRequest."Source Document"::"Prod. Consumption":
                begin
                    ProductionOrder.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PostingDate := WorkDate();
                    SourceDocRecordVar := ProductionOrder;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnCheckSourceDocForWhseRequest', '', true, true)]
    local procedure OnCheckSourceDocForWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecordVar: Variant; var Result: Boolean;
        var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplySourceFilters: Boolean)
    var
        ProdOrderLine: Record "Prod. Order Line";
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Output":
                Result :=
                    SetFilterProdOrderLine(
                        ProdOrderLine, SourceDocRecordVar, WarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters);
            WarehouseRequest."Source Document"::"Prod. Consumption":
                Result :=
                    SetFilterProdCompLine(
                        ProdOrderComponent, SourceDocRecordVar, WarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnCreateWarehouseActivityLineOnSetSourceDocument', '', true, true)]
    local procedure OnCreateWarehouseActivityLineOnSetSourceDocument(var WarehouseActivityLine: Record "Warehouse Activity Line"; SourceType: Integer)
    begin
        case SourceType of
            Database::"Prod. Order Line":
                WarehouseActivityLine."Source Document" := WarehouseActivityLine."Source Document"::"Prod. Output";
            Database::"Prod. Order Component":
                WarehouseActivityLine."Source Document" := WarehouseActivityLine."Source Document"::"Prod. Consumption";
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnCreatePutAwayFromWhseRequest', '', true, true)]
    local procedure OnCreatePutAwayFromWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecordVar: Variant;
        var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplySourceFilters: Boolean; sender: Codeunit "Create Inventory Put-away"; var RemQtyToPutaway: Decimal)
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Output":
                CreatePutAwayLinesFromProd(
                    SourceDocRecordVar, WarehouseActivityHeader, WarehouseSourceFilter, RemQtyToPutaway, CheckLineExist, ApplySourceFilters, sender);
            WarehouseRequest."Source Document"::"Prod. Consumption":
                CreatePutAwayLinesFromComp(
                    SourceDocRecordVar, WarehouseActivityHeader, WarehouseSourceFilter, RemQtyToPutaway, CheckLineExist, ApplySourceFilters, sender);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Put-away", 'OnAutoCreatePutAwayLinesFromWhseRequest', '', true, true)]
    local procedure OnAutoCreatePutAwayLinesFromWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecVar: Variant;
        var RemQtyToPutaway: Decimal; sender: Codeunit "Create Inventory Put-away"; var WarehouseActivityHeader: Record "Warehouse Activity Header";
        var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean)
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Prod. Output":
                CreatePutAwayLinesFromProd(
                    SourceDocRecVar, WarehouseActivityHeader, WarehouseSourceFilter, RemQtyToPutaway,
                    CheckLineExist, ApplySourceFilters, sender);
            WarehouseRequest."Source Document"::"Prod. Consumption":
                CreatePutAwayLinesFromComp(
                    SourceDocRecVar, WarehouseActivityHeader, WarehouseSourceFilter, RemQtyToPutaway,
                    CheckLineExist, ApplySourceFilters, sender);
        end;
    end;

    // Production
    local procedure CreatePutAwayLinesFromProd(
        ProductionOrderVar: Variant; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        var RemQtyToPutAway: Decimal; CheckLineExist: Boolean; ApplySourceFilters: Boolean; var sender: Codeunit "Create Inventory Put-away")
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        ProductionOrder := ProductionOrderVar;

        if not SetFilterProdOrderLine(ProdOrderLine, ProductionOrder, WarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters) then begin
            sender.GetNothingToHandleMsg();
            exit;
        end;

        sender.FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePutAwayLinesFromProdLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderLine);
#if not CLEAN27
            CreateInventoryPutaway.RunOnBeforeCreatePutAwayLinesFromProdLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderLine);
#endif
            if not IsHandled then
                if not NewWarehouseActivityLine.ActivityExists(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0, 0) then begin
                    GetLocation(Location, ProdOrderLine."Location Code");
                    if (ProdOrderLine."Location Code" = '') or (Location."Prod. Output Whse. Handling" = Location."Prod. Output Whse. Handling"::"Inventory Put-away") then begin
                        if Location."Prod. Output Whse. Handling" = Location."Prod. Output Whse. Handling"::"Inventory Put-away" then
                            FeatureTelemetry.LogUsage('0000KSY', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
                        RemQtyToPutAway := ProdOrderLine."Remaining Quantity";

                        FindReservationFromProdOrderLine(ProdOrderLine, sender);

                        if Location."Bin Mandatory" then
                            case Location."Put-away Bin Policy" of
                                Location."Put-away Bin Policy"::"Default Bin":
                                    CreatePutawayWithDefaultBinPolicy(ProdOrderLine, RemQtyToPutAway, sender);
                                Location."Put-away Bin Policy"::"Put-away Template":
                                    CreatePutawayWithPutawayTemplateBinPolicy(ProdOrderLine, sender);
#if not CLEAN27
                                else begin
                                    OnCreatePutawayForProdOrderLine(ProdOrderLine, RemQtyToPutAway);
                                    CreateInventoryPutaway.RunOnCreatePutawayForProdOrderLine(ProdOrderLine, RemQtyToPutAway);
                                end;
#else
                                else
                                    OnCreatePutawayForProdOrderLine(ProdOrderLine, RemQtyToPutAway);
#endif
                            end;

                        if (Location."Always Create Put-away Line" or not Location."Bin Mandatory") and (RemQtyToPutAway > 0) then
                            repeat
                                RemQtyToPutAway :=
                                    sender.CreateWarehouseActivityLine(
                                        Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", 0,
                                        ProdOrderLine."Location Code", ProdOrderLine."Item No.", ProdOrderLine."Variant Code", ProdOrderLine."Unit of Measure Code",
                                        ProdOrderLine."Qty. per Unit of Measure", ProdOrderLine."Qty. Rounding Precision", ProdOrderLine."Qty. Rounding Precision (Base)",
                                        ProdOrderLine.Description, ProdOrderLine."Description 2", ProdOrderLine."Due Date", '', ProdOrderLine);
                            until RemQtyToPutAway <= 0;
                    end;
                end;
        until ProdOrderLine.Next() = 0;
    end;

    local procedure CreatePutawayWithDefaultBinPolicy(var ProdOrderLineToPutaway: Record "Prod. Order Line"; var RemQtyToPutaway: Decimal; var sender: Codeunit "Create Inventory Put-away")
    var
        DefaultBinCode: Code[20];
        BinCodeToUse: Code[20];
    begin
        DefaultBinCode := sender.GetDefaultBinCode(ProdOrderLineToPutaway."Item No.", ProdOrderLineToPutaway."Variant Code", ProdOrderLineToPutaway."Location Code");

        if (DefaultBinCode = '') and (ProdOrderLineToPutaway."Bin Code" = '') then
            exit;

        repeat
            if ProdOrderLineToPutaway."Bin Code" = '' then
                BinCodeToUse := DefaultBinCode
            else
                BinCodeToUse := ProdOrderLineToPutaway."Bin Code";

            RemQtyToPutaway :=
                sender.CreateWarehouseActivityLine(
                    Database::"Prod. Order Line", ProdOrderLineToPutaway.Status.AsInteger(), ProdOrderLineToPutaway."Prod. Order No.", ProdOrderLineToPutaway."Line No.", 0,
                    ProdOrderLineToPutaway."Location Code", ProdOrderLineToPutaway."Item No.", ProdOrderLineToPutaway."Variant Code", ProdOrderLineToPutaway."Unit of Measure Code",
                    ProdOrderLineToPutaway."Qty. per Unit of Measure", ProdOrderLineToPutaway."Qty. Rounding Precision", ProdOrderLineToPutaway."Qty. Rounding Precision (Base)",
                    ProdOrderLineToPutaway.Description, ProdOrderLineToPutaway."Description 2", ProdOrderLineToPutaway."Due Date", BinCodeToUse, ProdOrderLineToPutaway)

        until RemQtyToPutAway <= 0;
    end;

    local procedure CreatePutawayWithPutawayTemplateBinPolicy(var ProdOrderLineToPutaway: Record "Prod. Order Line"; var sender: Codeunit "Create Inventory Put-away")
    begin
        sender.CreatePutawayWithPutawayTemplateBinPolicy(
            Database::"Prod. Order Line", ProdOrderLineToPutaway.Status.AsInteger(), ProdOrderLineToPutaway."Prod. Order No.", ProdOrderLineToPutaway."Line No.", 0,
            ProdOrderLineToPutaway."Location Code", ProdOrderLineToPutaway."Bin Code", ProdOrderLineToPutaway."Item No.", ProdOrderLineToPutaway."Variant Code", ProdOrderLineToPutaway."Quantity (Base)",
            ProdOrderLineToPutaway."Unit of Measure Code", ProdOrderLineToPutaway."Qty. per Unit of Measure", ProdOrderLineToPutaway."Qty. Rounding Precision",
            ProdOrderLineToPutaway."Qty. Rounding Precision (Base)", ProdOrderLineToPutaway.Description, ProdOrderLineToPutaway."Description 2", ProdOrderLineToPutaway."Due Date");
    end;

    local procedure FindReservationFromProdOrderLine(var ProdOrderLine: Record "Prod. Order Line"; var sender: Codeunit "Create Inventory Put-away")
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ReservationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReservationFromProdOrderLine(ProdOrderLine, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
#if not CLEAN27
        CreateInventoryPutaway.RunOnBeforeFindReservationFromProdOrderLine(ProdOrderLine, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
#endif
        if IsHandled then begin
            sender.SetReservationFound(ReservationFound);
            exit;
        end;

        ItemTrackingManagement.GetWhseItemTrkgSetup(ProdOrderLine."Item No.", WhseItemTrackingSetup);
        if WhseItemTrackingSetup.TrackingRequired() then
            sender.SetReservationFound(
                sender.FindReservationEntry(Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No."));
    end;

    procedure SetFilterProdOrderLine(
        var ProdOrderLine: Record "Prod. Order Line"; ProductionOrder: Record "Production Order";
        var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplyAdditionalSourceDocFilters: Boolean): Boolean
    begin
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        if not CheckLineExist then
            ProdOrderLine.SetRange("Location Code", WarehouseActivityHeader."Location Code");
        ProdOrderLine.SetFilter("Remaining Quantity", '>%1', 0);

        if ApplyAdditionalSourceDocFilters then begin
            ProdOrderLine.SetFilter("Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            ProdOrderLine.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            ProdOrderLine.SetFilter("Due Date", WarehouseSourceFilter.GetFilter("Receipt Date Filter"));
            ProdOrderLine.SetFilter("Line No.", WarehouseSourceFilter.GetFilter("Prod. Order Line No. Filter"));
        end;

        OnBeforeFindProdOrderLine(ProdOrderLine, WarehouseActivityHeader);
#if not CLEAN27
        CreateInventoryPutaway.RunOnBeforeFindProdOrderLine(ProdOrderLine, WarehouseActivityHeader);
#endif
        exit(ProdOrderLine.Find('-'));
    end;

    // Production Component
    local procedure CreatePutAwayLinesFromComp(ProductionOrderVar: Variant; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; var RemQtyToPutaway: Decimal; CheckLineExist: Boolean; ApplySourceFilters: Boolean; var sender: Codeunit "Create Inventory Put-away")
    var
        Location: Record Location;
        ProductionOrder: Record "Production Order";
        ProdOrderComponent: Record "Prod. Order Component";
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        IsHandled: Boolean;
    begin
        ProductionOrder := ProductionOrderVar;

        if not SetFilterProdCompLine(ProdOrderComponent, ProductionOrder, WarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters) then begin
            sender.GetNothingToHandleMsg();
            exit;
        end;

        sender.FindNextLineNo();

        repeat
            IsHandled := false;
            OnBeforeCreatePutAwayLinesFromCompLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
#if not CLEAN27
            CreateInventoryPutaway.RunOnBeforeCreatePutAwayLinesFromCompLoop(WarehouseActivityHeader, ProductionOrder, IsHandled, ProdOrderComponent);
#endif
            if not IsHandled then
                if not
                   NewWarehouseActivityLine.ActivityExists(
                     Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.", 0)
                then begin
                    RemQtyToPutAway := -ProdOrderComponent."Remaining Quantity";

                    FindReservationFromProdOrderComponent(ProdOrderComponent, sender);

                    GetLocation(Location, ProdOrderComponent."Location Code");
                    if Location."Bin Mandatory" then
                        case Location."Put-away Bin Policy" of
                            Location."Put-away Bin Policy"::"Default Bin":
                                CreatePutawayWithDefaultBinPolicy(ProdOrderComponent, RemQtyToPutaway, sender);
                            Location."Put-away Bin Policy"::"Put-away Template":
                                CreatePutawayWithPutawayTemplateBinPolicy(ProdOrderComponent, sender);
#if not CLEAN27
                            else begin
                                OnCreatePutawayForProdOrderComponent(ProdOrderComponent, RemQtyToPutAway);
                                CreateInventoryPutaway.RunOnCreatePutawayForProdOrderComponent(ProdOrderComponent, RemQtyToPutAway);
                            end;
#else
                            else
                                OnCreatePutawayForProdOrderComponent(ProdOrderComponent, RemQtyToPutAway);
#endif
                        end;

                    if (Location."Always Create Put-away Line" or not Location."Bin Mandatory") and (RemQtyToPutAway > 0) then
                        repeat
                            RemQtyToPutaway :=
                                sender.CreateWarehouseActivityLine(
                                    Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.",
                                    ProdOrderComponent."Location Code", ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Unit of Measure Code",
                                    ProdOrderComponent."Qty. per Unit of Measure", ProdOrderComponent."Qty. Rounding Precision", ProdOrderComponent."Qty. Rounding Precision (Base)",
                                    ProdOrderComponent.Description, '', ProdOrderComponent."Due Date", '', ProdOrderComponent);
                        until RemQtyToPutAway <= 0;
                end;
        until ProdOrderComponent.Next() = 0;
    end;

    local procedure CreatePutawayWithDefaultBinPolicy(var ProdOrderComponent: Record "Prod. Order Component"; var RemQtyToPutaway: Decimal; var sender: Codeunit "Create Inventory Put-away")
    var
        DefaultBinCode: Code[20];
        BinCodeToUse: Code[20];
    begin
        DefaultBinCode := sender.GetDefaultBinCode(ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Location Code");

        if (DefaultBinCode = '') and (ProdOrderComponent."Bin Code" = '') then
            exit;

        repeat
            if ProdOrderComponent."Bin Code" = '' then
                BinCodeToUse := DefaultBinCode
            else
                BinCodeToUse := ProdOrderComponent."Bin Code";

            RemQtyToPutaway :=
                sender.CreateWarehouseActivityLine(
                    Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.",
                    ProdOrderComponent."Location Code", ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Unit of Measure Code",
                    ProdOrderComponent."Qty. per Unit of Measure", ProdOrderComponent."Qty. Rounding Precision", ProdOrderComponent."Qty. Rounding Precision (Base)",
                    ProdOrderComponent.Description, '', ProdOrderComponent."Due Date", BinCodeToUse, ProdOrderComponent)

        until RemQtyToPutAway <= 0;
    end;

    local procedure CreatePutawayWithPutawayTemplateBinPolicy(var ProdOrderComponent: Record "Prod. Order Component"; var sender: Codeunit "Create Inventory Put-away")
    begin
        sender.CreatePutawayWithPutawayTemplateBinPolicy(
            Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.", ProdOrderComponent."Line No.",
            ProdOrderComponent."Location Code", ProdOrderComponent."Bin Code", ProdOrderComponent."Item No.", ProdOrderComponent."Variant Code", ProdOrderComponent."Quantity (Base)",
            ProdOrderComponent."Unit of Measure Code", ProdOrderComponent."Qty. per Unit of Measure", ProdOrderComponent."Qty. Rounding Precision",
            ProdOrderComponent."Qty. Rounding Precision (Base)", ProdOrderComponent.Description, '', ProdOrderComponent."Due Date");
    end;

    local procedure FindReservationFromProdOrderComponent(var ProdOrderComponent: Record "Prod. Order Component"; var sender: Codeunit "Create Inventory Put-away")
    var
        WhseItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingManagement: Codeunit "Item Tracking Management";
        ReservationFound: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReservationFromProdOrderComponent(ProdOrderComponent, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
#if not CLEAN27
        CreateInventoryPutaway.RunOnBeforeFindReservationFromProdOrderComponent(ProdOrderComponent, WhseItemTrackingSetup, ItemTrackingManagement, ReservationFound, IsHandled);
#endif
        if IsHandled then begin
            sender.SetReservationFound(ReservationFound);
            exit;
        end;

        ItemTrackingManagement.GetWhseItemTrkgSetup(ProdOrderComponent."Item No.", WhseItemTrackingSetup);
        if WhseItemTrackingSetup.TrackingRequired() then
            sender.SetReservationFound(
                sender.FindReservationEntry(Database::"Prod. Order Component", ProdOrderComponent.Status.AsInteger(), ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Line No."));
    end;

    local procedure SetFilterProdCompLine(var ProdOrderComponent: Record "Prod. Order Component"; ProductionOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean): Boolean
#if not CLEAN26
    var
        ManufacturingSetup: Record Microsoft.Manufacturing.Setup."Manufacturing Setup";
#endif
    begin
        ProdOrderComponent.SetRange(Status, ProductionOrder.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProductionOrder."No.");
        if not CheckLineExist then
            ProdOrderComponent.SetRange("Location Code", WarehouseActivityHeader."Location Code");
#if not CLEAN26
        if not ManufacturingSetup.IsFeatureKeyFlushingMethodManualWithoutPickEnabled() then
            ProdOrderComponent.SetFilter(ProdOrderComponent."Flushing Method", '%1|%2', ProdOrderComponent."Flushing Method"::Manual, ProdOrderComponent."Flushing Method"::"Pick + Manual")
        else
#endif        
            ProdOrderComponent.SetRange("Flushing Method", ProdOrderComponent."Flushing Method"::"Pick + Manual");
        ProdOrderComponent.SetRange("Planning Level Code", 0);
        ProdOrderComponent.SetFilter("Remaining Quantity", '<0');

        if ApplySourceFilters then begin
            ProdOrderComponent.SetFilter("Item No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            ProdOrderComponent.SetFilter("Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            ProdOrderComponent.SetFilter("Due Date", WarehouseSourceFilter.GetFilter("Receipt Date Filter"));
            ProdOrderComponent.SetFilter("Prod. Order Line No.", WarehouseSourceFilter.GetFilter("Prod. Order Line No. Filter"));
        end;

        OnBeforeFindProdOrderComp(ProdOrderComponent, WarehouseActivityHeader);
#if not CLEAN27
        CreateInventoryPutaway.RunOnBeforeFindProdOrderComp(ProdOrderComponent, WarehouseActivityHeader);
#endif
        exit(ProdOrderComponent.Find('-'));
    end;

    local procedure GetLocation(var Location: Record Location; LocationCode: Code[10])
    begin
        if LocationCode = '' then
            Clear(Location)
        else
            if LocationCode <> Location.Code then
                Location.Get(LocationCode);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromProdLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCreatePutAwayLinesFromCompLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var IsHandled: Boolean; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RemQtyToPutAway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreatePutawayForProdOrderComponent(var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var RemQtyToPutAway: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReservationFromProdOrderComponent(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var WhseItemTrackingSetup: Record "Item Tracking Setup"; var ItemTrackingMgt: Codeunit "Item Tracking Management"; var ReservationFound: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindProdOrderComp(var ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
}