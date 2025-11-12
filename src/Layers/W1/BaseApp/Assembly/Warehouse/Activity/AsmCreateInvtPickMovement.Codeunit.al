// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Request;
using System.Telemetry;

codeunit 989 "Asm. Create Invt.Pick/Movement"
{
    var
        FeatureTelemetry: Codeunit "Feature Telemetry";
#if not CLEAN27
        CreateInventoryPickMovement: Codeunit "Create Inventory Pick/Movement";
#endif
        ProdAsmJobWhseHandlingTelemetryCategoryTok: Label 'Prod/Asm/Project Whse. Handling', Locked = true;
        ProdAsmJobWhseHandlingTelemetryTok: Label 'Prod/Asm/Project Whse. Handling in used for warehouse pick.', Locked = true;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnGetSourceDocHeaderFromWhseRequest', '', true, true)]
    local procedure OnGetSourceDocHeaderFromWhseRequest(var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecRef: RecordRef; var PostingDate: Date; var RecordExists: Boolean; var SourceDocRecordVar: Variant);
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Assembly Consumption":
                begin
                    RecordExists := AssemblyHeader.Get(WarehouseRequest."Source Subtype", WarehouseRequest."Source No.");
                    PostingDate := AssemblyHeader."Posting Date";
                    SourceDocRecordVar := AssemblyHeader;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnCheckSourceDocForWhseRequest', '', true, true)]
    local procedure OnCheckSourceDocForWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; var SourceDocRecordVar: Variant; var Result: Boolean;
        var WhseActivHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplyAdditionalSourceDocFilters: Boolean; IsInvtMovement: Boolean; var IsHandled: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Assembly Consumption":
                begin
                    Result :=
                        SetFilterAssemblyLine(
                            AssemblyLine, SourceDocRecordVar, WhseActivHeader, WarehouseSourceFilter, CheckLineExist, ApplyAdditionalSourceDocFilters, IsInvtMovement);
                    IsHandled := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnCreatePickOrMoveFromWhseRequest', '', true, true)]
    local procedure OnCreatePickOrMoveFromWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecVar: Variant;
        var WhseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplySourceFilters: Boolean; IsInvtMovement: Boolean; ReservedFromStock: Enum "Reservation From Stock";
        sender: Codeunit "Create Inventory Pick/Movement")
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Assembly Consumption":
                CreatePickOrMoveFromAssembly(
                    SourceDocRecVar, WhseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters, IsInvtMovement, ReservedFromStock, sender);
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Create Inventory Pick/Movement", 'OnAutoCreatePickOrMoveFromWhseRequest', '', true, true)]
    local procedure OnAutoCreatePickOrMoveFromWhseRequest(
        var WarehouseRequest: Record "Warehouse Request"; SourceDocRecRef: RecordRef; var LineCreated: Boolean; var SourceDocRecVar: Variant;
        var WhseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter";
        CheckLineExist: Boolean; ApplyAdditionalSourceDocFilters: Boolean; IsInvtMovement: Boolean;
        ReservedFromStock: Enum "Reservation From Stock"; var sender: Codeunit "Create Inventory Pick/Movement")
    begin
        case WarehouseRequest."Source Document" of
            WarehouseRequest."Source Document"::"Assembly Consumption":
                CreatePickOrMoveFromAssembly(
                    SourceDocRecVar, WhseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplyAdditionalSourceDocFilters, IsInvtMovement, ReservedFromStock, sender);
        end;
    end;

    local procedure CreatePickOrMoveFromAssembly(AssemblyHeaderVar: Variant; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean; IsInvtMovement: Boolean; ReservedFromStock: Enum "Reservation From Stock"; var sender: Codeunit "Create Inventory Pick/Movement")
    var
        AssemblyHeader: Record "Assembly Header";
        AssemblyLine: Record "Assembly Line";
        Location: Record Location;
        NewWarehouseActivityLine: Record "Warehouse Activity Line";
        RemQtyToPickBase: Decimal;
        IsHandled: Boolean;
    begin
        AssemblyHeader := AssemblyHeaderVar;

        if not SetFilterAssemblyLine(AssemblyLine, AssemblyHeader, WarehouseActivityHeader, WarehouseSourceFilter, CheckLineExist, ApplySourceFilters, IsInvtMovement) then begin
            sender.RaiseNothingToHandleMessage();
            exit;
        end;

        if WarehouseActivityHeader.Type <> WarehouseActivityHeader.Type::"Invt. Movement" then // no support for inventory pick on assembly
            exit;

        sender.FindNextLineNo();

        repeat
            GetLocation(Location, AssemblyLine."Location Code");
            if (AssemblyLine."Location Code" = '') or (Location."Asm. Consump. Whse. Handling" = Location."Asm. Consump. Whse. Handling"::"Inventory Movement") then begin
                if Location."Asm. Consump. Whse. Handling" = Location."Asm. Consump. Whse. Handling"::"Inventory Movement" then
                    FeatureTelemetry.LogUsage('0000KT3', ProdAsmJobWhseHandlingTelemetryCategoryTok, ProdAsmJobWhseHandlingTelemetryTok);
                IsHandled := false;
                OnBeforeCreatePickOrMoveLineFromAssemblyLoop(WarehouseActivityHeader, AssemblyHeader, IsHandled, AssemblyLine);
#if not CLEAN27
                sender.RunOnBeforeCreatePickOrMoveLineFromAssemblyLoop(WarehouseActivityHeader, AssemblyHeader, IsHandled, AssemblyLine);
#endif
                if not IsHandled and CanPickAssemblyLine(AssemblyLine, ReservedFromStock) then
                    if not
                       NewWarehouseActivityLine.ActivityExists(Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", 0, 0)
                    then begin
                        NewWarehouseActivityLine.Init();
                        NewWarehouseActivityLine."Activity Type" := WarehouseActivityHeader.Type;
                        NewWarehouseActivityLine."No." := WarehouseActivityHeader."No.";
                        if Location."Bin Mandatory" then
                            NewWarehouseActivityLine."Action Type" := NewWarehouseActivityLine."Action Type"::Take;
                        NewWarehouseActivityLine.SetSource(Database::"Assembly Line", AssemblyLine."Document Type".AsInteger(), AssemblyLine."Document No.", AssemblyLine."Line No.", 0);
                        NewWarehouseActivityLine."Location Code" := AssemblyLine."Location Code";
                        NewWarehouseActivityLine."Bin Code" := AssemblyLine."Bin Code";
                        NewWarehouseActivityLine."Item No." := AssemblyLine."No.";
                        NewWarehouseActivityLine."Variant Code" := AssemblyLine."Variant Code";
                        NewWarehouseActivityLine."Unit of Measure Code" := AssemblyLine."Unit of Measure Code";
                        NewWarehouseActivityLine."Qty. per Unit of Measure" := AssemblyLine."Qty. per Unit of Measure";
                        NewWarehouseActivityLine."Qty. Rounding Precision" := AssemblyLine."Qty. Rounding Precision";
                        NewWarehouseActivityLine."Qty. Rounding Precision (Base)" := AssemblyLine."Qty. Rounding Precision (Base)";
                        NewWarehouseActivityLine.Description := AssemblyLine.Description;
                        NewWarehouseActivityLine."Source Document" := NewWarehouseActivityLine."Source Document"::"Assembly Consumption";
                        NewWarehouseActivityLine."Due Date" := AssemblyLine."Due Date";
                        NewWarehouseActivityLine."Destination Type" := NewWarehouseActivityLine."Destination Type"::Item;
                        NewWarehouseActivityLine."Destination No." := AssemblyHeader."Item No.";
                        RemQtyToPickBase := AssemblyLine."Quantity (Base)" - AssemblyLine."Remaining Quantity (Base)" +
                        AssemblyLine."Quantity to Consume (Base)" - AssemblyLine."Qty. Picked (Base)";
                        OnBeforeNewWhseActivLineInsertFromAssembly(NewWarehouseActivityLine, AssemblyLine, WarehouseActivityHeader, RemQtyToPickBase);
#if not CLEAN27
                        sender.RunOnBeforeNewWhseActivLineInsertFromAssembly(NewWarehouseActivityLine, AssemblyLine, WarehouseActivityHeader, RemQtyToPickBase);
#endif
                        AssemblyLine.CalcFields(AssemblyLine."Reserved Quantity");
                        sender.CreatePickOrMoveLine(NewWarehouseActivityLine, RemQtyToPickBase, RemQtyToPickBase, AssemblyLine."Reserved Quantity" <> 0);
                    end;
            end;
        until AssemblyLine.Next() = 0;
    end;

    local procedure SetFilterAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseSourceFilter: Record "Warehouse Source Filter"; CheckLineExist: Boolean; ApplySourceFilters: Boolean; IsInvtMovement: Boolean): Boolean
    begin
        AssemblyLine.SetRange(AssemblyLine."Document Type", AssemblyHeader."Document Type");
        AssemblyLine.SetRange(AssemblyLine."Document No.", AssemblyHeader."No.");
        AssemblyLine.SetRange(AssemblyLine.Type, AssemblyLine.Type::Item);
        if not CheckLineExist then
            AssemblyLine.SetRange(AssemblyLine."Location Code", WarehouseActivityHeader."Location Code");
        if IsInvtMovement then
            AssemblyLine.SetFilter(AssemblyLine."Bin Code", '<>%1', '');
        AssemblyLine.SetFilter(AssemblyLine."Remaining Quantity", '>0');

        if ApplySourceFilters then begin
            AssemblyLine.SetFilter(AssemblyLine."No.", WarehouseSourceFilter.GetFilter("Item No. Filter"));
            AssemblyLine.SetFilter(AssemblyLine."Variant Code", WarehouseSourceFilter.GetFilter("Variant Code Filter"));
            AssemblyLine.SetFilter(AssemblyLine."Due Date", WarehouseSourceFilter.GetFilter("Shipment Date Filter"));
        end;

        OnBeforeFindAssemblyLine(AssemblyLine, AssemblyHeader, WarehouseActivityHeader);
#if not CLEAN27
        CreateInventoryPickMovement.RunOnBeforeFindAssemblyLine(AssemblyLine, AssemblyHeader, WarehouseActivityHeader);
#endif
        exit(AssemblyLine.Find('-'));
    end;

    local procedure CanPickAssemblyLine(var AssemblyLine: Record "Assembly Line"; ReservedFromStock: Enum "Reservation From Stock"): Boolean
    begin
        exit(
          AssemblyLine.CheckIfAssemblyLineMeetsReservedFromStockSetting(AssemblyLine."Remaining Quantity (Base)", ReservedFromStock));
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
    local procedure OnBeforeCreatePickOrMoveLineFromAssemblyLoop(var WarehouseActivityHeader: Record "Warehouse Activity Header"; AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean; AssemblyLine: Record "Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeNewWhseActivLineInsertFromAssembly(var WarehouseActivityLine: Record "Warehouse Activity Line"; var AssemblyLine: Record "Assembly Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var RemQtyToPickBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindAssemblyLine(var AssemblyLine: Record "Assembly Line"; AssemblyHeader: Record "Assembly Header"; WarehouseActivityHeader: Record "Warehouse Activity Header")
    begin
    end;
}