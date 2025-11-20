// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Activity;

using Microsoft.Foundation.AuditCodes;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Journal;
using Microsoft.Inventory.Posting;
using Microsoft.Manufacturing.Document;
using Microsoft.Warehouse.Journal;

codeunit 99000766 "Mfg. Whse. Activity Post"
{
#if not CLEAN27
    var
        WhseActivityPost: Codeunit "Whse.-Activity-Post";
#endif

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnPostProdConsumption', '', false, false)]
    local procedure OnPostProdConsumption(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20])
    var
        ProdOrder: Record "Production Order";
        WhseProductionRelease: Codeunit "Whse.-Production Release";
    begin
        PostConsumption(ProdOrder, WarehouseActivityHeader, TempWhseActivLine, PostedSourceType, PostedSourceSubType, PostedSourceNo);
        WhseProductionRelease.Release(ProdOrder);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnPostProdOutput', '', false, false)]
    local procedure OnPostProdOutput(var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20])
    var
        ProdOrder: Record "Production Order";
        WhseOutputProdRelease: Codeunit "Whse.-Output Prod. Release";
    begin
        PostOutput(ProdOrder, WarehouseActivityHeader, TempWhseActivLine, PostedSourceType, PostedSourceSubType, PostedSourceNo);
        WhseOutputProdRelease.Release(ProdOrder);
    end;

    local procedure PostConsumption(var ProdOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20])
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        TempWhseActivLine.Reset();
        TempWhseActivLine.Find('-');
        ProdOrder.Get(TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.");
        repeat
            ProdOrderComp.Get(TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.", TempWhseActivLine."Source Line No.", TempWhseActivLine."Source Subline No.");
            PostConsumptionLine(ProdOrder, ProdOrderComp, TempWhseActivLine, WarehouseActivityHeader);
        until TempWhseActivLine.Next() = 0;

        PostedSourceType := TempWhseActivLine."Source Type";
        PostedSourceSubType := TempWhseActivLine."Source Subtype";
        PostedSourceNo := TempWhseActivLine."Source No.";

        OnAfterPostConsumption(ProdOrder, WarehouseActivityHeader, TempWhseActivLine, PostedSourceType, PostedSourceSubType, PostedSourceNo);
    end;

    local procedure PostConsumptionLine(ProdOrder: Record "Production Order"; ProdOrderComp: Record "Prod. Order Component"; var WarehouseActivityLine: Record "Warehouse Activity Line" temporary; var WarehouseActivityHeader: Record "Warehouse Activity Header")
    var
        Item: Record Item;
        ItemJnlLine: Record "Item Journal Line";
        ProdOrderLine: Record "Prod. Order Line";
        SourceCodeSetup: Record "Source Code Setup";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
    begin
        ProdOrderLine.Get(WarehouseActivityLine."Source Subtype", WarehouseActivityLine."Source No.", WarehouseActivityLine."Source Line No.");
        ItemJnlLine.Init();
        SourceCodeSetup.Get();
        OnPostConsumptionLineOnAfterInitItemJournalLine(ItemJnlLine, SourceCodeSetup);
#if not CLEAN27
        WhseActivityPost.RunOnPostConsumptionLineOnAfterInitItemJournalLine(ItemJnlLine, SourceCodeSetup);
#endif
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Consumption);
        ItemJnlLine.Validate("Posting Date", WarehouseActivityHeader."Posting Date");
        ItemJnlLine."Source No." := ProdOrderLine."Item No.";
        ItemJnlLine."Source Type" := ItemJnlLine."Source Type"::Item;
        ItemJnlLine."Document No." := ProdOrder."No.";
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Item No.", WarehouseActivityLine."Item No.");
        if ItemJnlLine."Unit of Measure Code" <> WarehouseActivityLine."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        ItemJnlLine.Validate("Prod. Order Comp. Line No.", ProdOrderComp."Line No.");
        ItemJnlLine."Qty. per Unit of Measure" := WarehouseActivityLine."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := WarehouseActivityLine."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := WarehouseActivityLine."Qty. Rounding Precision (Base)";
        ItemJnlLine.Description := WarehouseActivityLine.Description;
        if WarehouseActivityLine."Activity Type" = WarehouseActivityLine."Activity Type"::"Invt. Pick" then
            ItemJnlLine.Validate(Quantity, WarehouseActivityLine."Qty. to Handle")
        else
            ItemJnlLine.Validate(Quantity, -WarehouseActivityLine."Qty. to Handle");
        ItemJnlLine.Validate("Unit Cost", ProdOrderComp."Unit Cost");
        ItemJnlLine."Location Code" := WarehouseActivityLine."Location Code";
        ItemJnlLine."Bin Code" := WarehouseActivityLine."Bin Code";
        ItemJnlLine."Variant Code" := WarehouseActivityLine."Variant Code";
        ItemJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
        ItemJnlLine."Gen. Bus. Posting Group" := ProdOrder."Gen. Bus. Posting Group";
        Item.Get(WarehouseActivityLine."Item No.");
        ItemJnlLine."Gen. Prod. Posting Group" := Item."Gen. Prod. Posting Group";
        OnPostConsumptionLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, WarehouseActivityLine, SourceCodeSetup);
#if not CLEAN27
        WhseActivityPost.RunOnPostConsumptionLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, WarehouseActivityLine, SourceCodeSetup);
#endif
        ProdOrderCompReserve.TransferPOCompToItemJnlLineCheckILE(ProdOrderComp, ItemJnlLine, ItemJnlLine."Quantity (Base)", true);
        ItemJnlPostLine.SetCalledFromInvtPutawayPick(true);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        ProdOrderCompReserve.UpdateItemTrackingAfterPosting(ProdOrderComp);
    end;

    local procedure PostOutput(var ProdOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWhseActivLine: Record "Warehouse Activity Line" temporary; var PostedSourceType: Integer; var PostedSourceSubType: Integer; var PostedSourceNo: Code[20])
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        TempWhseActivLine.Reset();
        TempWhseActivLine.Find('-');
        ProdOrder.Get(TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.");
        repeat
            ProdOrderLine.Get(TempWhseActivLine."Source Subtype", TempWhseActivLine."Source No.", TempWhseActivLine."Source Line No.");
            PostOutputLine(ProdOrder, ProdOrderLine, WarehouseActivityHeader, TempWhseActivLine);
        until TempWhseActivLine.Next() = 0;

        PostedSourceType := TempWhseActivLine."Source Type";
        PostedSourceSubType := TempWhseActivLine."Source Subtype";
        PostedSourceNo := TempWhseActivLine."Source No.";

        OnAfterPostOutput(ProdOrder, WarehouseActivityHeader, TempWhseActivLine, PostedSourceType, PostedSourceSubType, PostedSourceNo);
    end;

    local procedure PostOutputLine(ProdOrder: Record "Production Order"; ProdOrderLine: Record "Prod. Order Line"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var WarehouseActivityLine: Record "Warehouse Activity Line")
    var
        ItemJnlLine: Record "Item Journal Line";
        SourceCodeSetup: Record "Source Code Setup";
        ItemJnlPostLine: Codeunit "Item Jnl.-Post Line";
        ReservProdOrderLine: Codeunit "Prod. Order Line-Reserve";
    begin
        ItemJnlLine.Init();
        OnPostOutputLineOnAfterItemJournalLineInit(ItemJnlLine, SourceCodeSetup);
#if not CLEAN27
        WhseActivityPost.RunOnPostOutputLineOnAfterItemJournalLineInit(ItemJnlLine, SourceCodeSetup);
#endif
        ItemJnlLine.Validate("Entry Type", ItemJnlLine."Entry Type"::Output);
        ItemJnlLine.Validate("Posting Date", WarehouseActivityHeader."Posting Date");
        ItemJnlLine."Document No." := ProdOrder."No.";
        ItemJnlLine.Validate("Order Type", ItemJnlLine."Order Type"::Production);
        ItemJnlLine.Validate("Order No.", ProdOrder."No.");
        ItemJnlLine.Validate("Order Line No.", ProdOrderLine."Line No.");
        ItemJnlLine.Validate("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ItemJnlLine.Validate("Routing No.", ProdOrderLine."Routing No.");
        ItemJnlLine.Validate("Item No.", ProdOrderLine."Item No.");
        if ItemJnlLine."Unit of Measure Code" <> WarehouseActivityLine."Unit of Measure Code" then
            ItemJnlLine.Validate("Unit of Measure Code", WarehouseActivityLine."Unit of Measure Code");
        ItemJnlLine."Qty. per Unit of Measure" := WarehouseActivityLine."Qty. per Unit of Measure";
        ItemJnlLine."Qty. Rounding Precision" := WarehouseActivityLine."Qty. Rounding Precision";
        ItemJnlLine."Qty. Rounding Precision (Base)" := WarehouseActivityLine."Qty. Rounding Precision (Base)";
        ItemJnlLine."Location Code" := WarehouseActivityLine."Location Code";
        ItemJnlLine."Bin Code" := WarehouseActivityLine."Bin Code";
        ItemJnlLine."Variant Code" := WarehouseActivityLine."Variant Code";
        ItemJnlLine.Description := WarehouseActivityLine.Description;
        if ProdOrderLine."Routing No." <> '' then
            ItemJnlLine.Validate("Operation No.", CalcLastOperationNo(ProdOrderLine));
        ItemJnlLine.Validate("Output Quantity", WarehouseActivityLine."Qty. to Handle");
        ItemJnlLine."Source Code" := SourceCodeSetup."Output Journal";
        ItemJnlLine."Dimension Set ID" := ProdOrderLine."Dimension Set ID";
        OnPostOutputLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, WarehouseActivityLine, SourceCodeSetup);
#if not CLEAN27
        WhseActivityPost.RunOnPostOutputLineOnAfterCreateItemJnlLine(ItemJnlLine, ProdOrderLine, WarehouseActivityLine, SourceCodeSetup);
#endif
        ReservProdOrderLine.TransferPOLineToItemJnlLine(
          ProdOrderLine, ItemJnlLine, ItemJnlLine."Quantity (Base)");
        ItemJnlPostLine.SetCalledFromInvtPutawayPick(true);
        ItemJnlPostLine.RunWithCheck(ItemJnlLine);
        ReservProdOrderLine.UpdateItemTrackingAfterPosting(ProdOrderLine);
    end;

    local procedure CalcLastOperationNo(ProdOrderLine: Record "Prod. Order Line"): Code[10]
    var
        ProdOrderRtngLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRtngLine.SetRange(Status, ProdOrderLine.Status);
        ProdOrderRtngLine.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderRtngLine.SetRange("Routing Reference No.", ProdOrderLine."Routing Reference No.");
        ProdOrderRtngLine.SetRange("Routing No.", ProdOrderLine."Routing No.");
        if not ProdOrderRtngLine.IsEmpty() then begin
            CheckProdOrderLine(ProdOrderLine);
            ProdOrderRtngLine.SetRange("Next Operation No.", '');
            ProdOrderRtngLine.FindLast();
            exit(ProdOrderRtngLine."Operation No.");
        end;

        exit('');
    end;

    local procedure CheckProdOrderLine(var ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderRouteManagement: Codeunit "Prod. Order Route Management";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLine(ProdOrderLine, IsHandled);
#if not CLEAN27
        WhseActivityPost.RunOnBeforeCheckProdOrderLine(ProdOrderLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderRouteManagement.Check(ProdOrderLine);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Whse.-Activity-Post", 'OnCreateWhseJnlLineOnSetReferenceDocument', '', false, false)]
    local procedure OnCreateWhseJnlLineOnSetReferenceDocument(WarehouseActivityLine: Record "Warehouse Activity Line"; var WhseJnlLine: Record "Warehouse Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
        case WarehouseActivityLine."Source Document" of
            WarehouseActivityLine."Source Document"::"Prod. Consumption":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup."Consumption Journal";
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
                end;
            WarehouseActivityLine."Source Document"::"Prod. Output":
                begin
                    WhseJnlLine."Source Code" := SourceCodeSetup."Output Journal";
                    WhseJnlLine."Reference Document" := WhseJnlLine."Reference Document"::"Prod.";
                end;
        end;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterInitItemJournalLine(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostConsumptionLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterItemJournalLineInit(var ItemJournalLine: Record "Item Journal Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPostOutputLineOnAfterCreateItemJnlLine(var ItemJournalLine: Record "Item Journal Line"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; WarehouseActivityLine: Record "Warehouse Activity Line"; SourceCodeSetup: Record "Source Code Setup")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostConsumption(var ProductionOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; PostedSourceType: Integer; PostedSourceSubType: Integer; PostedSourceNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPostOutput(var ProductionOrder: Record "Production Order"; var WarehouseActivityHeader: Record "Warehouse Activity Header"; var TempWarehouseActivityLine: Record "Warehouse Activity Line" temporary; PostedSourceType: Integer; PostedSourceSubType: Integer; PostedSourceNo: Code[20])
    begin
    end;
}
