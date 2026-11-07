// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.Worksheet;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Tracking;
using Microsoft.Warehouse.Structure;

codeunit 7308 Replenishment
{

    trigger OnRun()
    begin
    end;

    var
        Bin: Record Bin;
        BinType: Record "Bin Type";
        TempWhseWkshLine: Record "Whse. Worksheet Line" temporary;
        ItemUnitOfMeasure: Record "Item Unit of Measure";
        Location: Record Location;
        UOMMgt: Codeunit "Unit of Measure Management";
        WhseWkshTemplateName: Code[10];
        WhseWkshName: Code[10];
        LocationCode: Code[10];
        RemainQtyToReplenishBase: Decimal;
        NextLineNo: Integer;
        DoNotFillQtytoHandle: Boolean;
        MustNotBeErr: Label 'must not be %1.', Comment = '%1 - field value';

    procedure ReplenishBin(ToBinContent: Record "Bin Content"; AllowBreakBulk: Boolean)
    var
        ExcludedQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeReplenishBin(ToBinContent, IsHandled, RemainQtyToReplenishBase, AllowBreakBulk);
        if IsHandled then
            exit;

        if not ToBinContent.Fixed then
            ToBinContent.FieldError(Fixed, StrSubstNo(MustNotBeErr, ToBinContent.FieldCaption(Fixed)));

        if BinBlockedInbound(ToBinContent."Location Code", ToBinContent."Bin Code") then
            Bin.FieldError("Block Movement", StrSubstNo(MustNotBeErr, Bin."Block Movement"));

        ExcludedQtyBase := 0;
        OnReplenishBinOnAfterAssignExcludedQtyBase(ToBinContent, ExcludedQtyBase);
        if not ToBinContent.NeedToReplenish(ExcludedQtyBase) then
            exit;

        RemainQtyToReplenishBase := ToBinContent.CalcQtyToReplenish(ExcludedQtyBase);
        if RemainQtyToReplenishBase <= 0 then
            exit;

        FindReplenishmtBin(ToBinContent, AllowBreakBulk);
    end;

    procedure FindReplenishmtBin(ToBinContent: Record "Bin Content"; AllowBreakBulk: Boolean)
    var
        FromBinContent: Record "Bin Content";
        WhseWkshLine2: Record "Whse. Worksheet Line";
        QtyAvailToTakeBase: Decimal;
        MovementQtyBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFindReplenishmtBin(
            TempWhseWkshLine, ToBinContent, AllowBreakBulk, NextLineNo,
            WhseWkshTemplateName, WhseWkshName, LocationCode, DoNotFillQtytoHandle, RemainQtyToReplenishBase, IsHandled);
        if IsHandled then
            exit;

        FromBinContent.Reset();
        FromBinContent.SetCurrentKey(
            "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin",
            "Qty. per Unit of Measure", "Bin Ranking");
        FromBinContent.Ascending(false);
        FromBinContent.SetRange("Location Code", ToBinContent."Location Code");
        FromBinContent.SetRange("Item No.", ToBinContent."Item No.");
        FromBinContent.SetRange("Variant Code", ToBinContent."Variant Code");
        FromBinContent.SetRange("Cross-Dock Bin", false);
        FromBinContent.SetRange("Qty. per Unit of Measure", ToBinContent."Qty. per Unit of Measure");
        FromBinContent.SetFilter("Bin Ranking", '<%1', ToBinContent."Bin Ranking");
        OnFindReplenishmtBinOnAfterFromBinContentSetFilters(FromBinContent, ToBinContent);
        if FromBinContent.Find('-') then begin
            WhseWkshLine2.Copy(TempWhseWkshLine);
            TempWhseWkshLine.SetCurrentKey(
                "Item No.", "From Bin Code", "Location Code", "Variant Code", "From Unit of Measure Code");
            TempWhseWkshLine.SetRange("Item No.", FromBinContent."Item No.");
            TempWhseWkshLine.SetRange("Location Code", FromBinContent."Location Code");
            TempWhseWkshLine.SetRange("Variant Code", FromBinContent."Variant Code");
            repeat
                IsHandled := false;
                OnFindReplenishmtBinOnBeforeCalcQtyAvailToTakeBase(FromBinContent, IsHandled);
                if not IsHandled then
                    if UseForReplenishment(FromBinContent) then begin
                        QtyAvailToTakeBase := FromBinContent.CalcQtyAvailToTake(0);
                        TempWhseWkshLine.SetRange("From Bin Code", FromBinContent."Bin Code");
                        TempWhseWkshLine.SetRange("From Unit of Measure Code", FromBinContent."Unit of Measure Code");
                        TempWhseWkshLine.CalcSums("Qty. (Base)");
                        QtyAvailToTakeBase := QtyAvailToTakeBase - TempWhseWkshLine."Qty. (Base)";

                        if QtyAvailToTakeBase > 0 then begin
                            if QtyAvailToTakeBase < RemainQtyToReplenishBase then
                                MovementQtyBase := QtyAvailToTakeBase
                            else
                                MovementQtyBase := RemainQtyToReplenishBase;
                            CreateWhseWkshLine(ToBinContent, FromBinContent, MovementQtyBase);
                            RemainQtyToReplenishBase := RemainQtyToReplenishBase - MovementQtyBase;
                        end;
                    end;
            until (FromBinContent.Next() = 0) or (RemainQtyToReplenishBase = 0);
            TempWhseWkshLine.Copy(WhseWkshLine2);
        end;

        if AllowBreakBulk then
            if RemainQtyToReplenishBase > 0 then
                FindBreakbulkBin(ToBinContent);
    end;

    procedure SetRemainQtyToReplenishBase(NewRemainQtyToReplenishBase: Decimal)
    begin
        RemainQtyToReplenishBase := NewRemainQtyToReplenishBase;
    end;

    procedure FindBreakbulkBin(ToBinContent: Record "Bin Content")
    var
        FromBinContent: Record "Bin Content";
        WhseWkshLine2: Record "Whse. Worksheet Line";
        QtyAvailToTakeBase: Decimal;
        MovementQtyBase: Decimal;
        SkipItemUnitOfMeasure: Boolean;
    begin
        ItemUnitOfMeasure.Reset();
        ItemUnitOfMeasure.SetCurrentKey("Item No.", "Qty. per Unit of Measure");
        ItemUnitOfMeasure.SetRange("Item No.", ToBinContent."Item No.");
        ItemUnitOfMeasure.SetFilter(
          "Qty. per Unit of Measure", '>%1', ToBinContent."Qty. per Unit of Measure");
        if ItemUnitOfMeasure.Find('-') then
            repeat
                FromBinContent.Reset();
                FromBinContent.SetCurrentKey(
                  "Location Code", "Item No.", "Variant Code", "Cross-Dock Bin",
                  "Qty. per Unit of Measure", "Bin Ranking");
                FromBinContent.SetRange("Location Code", ToBinContent."Location Code");
                FromBinContent.SetRange("Item No.", ToBinContent."Item No.");
                FromBinContent.SetRange("Variant Code", ToBinContent."Variant Code");
                FromBinContent.SetRange("Cross-Dock Bin", false);
                FromBinContent.SetRange(
                  "Qty. per Unit of Measure", ItemUnitOfMeasure."Qty. per Unit of Measure");
                FromBinContent.SetFilter("Bin Ranking", '<%1', ToBinContent."Bin Ranking");
                FromBinContent.Ascending(false);
                SkipItemUnitOfMeasure := false;
                OnFindBreakbulkBinOnAfterFromBinContentSetFilters(FromBinContent, ToBinContent, ItemUnitOfMeasure, SkipItemUnitOfMeasure);
                if not SkipItemUnitOfMeasure then
                    if FromBinContent.Find('-') then begin
                        WhseWkshLine2.Copy(TempWhseWkshLine);
                        TempWhseWkshLine.SetCurrentKey(
                          "Item No.", "From Bin Code", "Location Code", "Variant Code", "From Unit of Measure Code");
                        TempWhseWkshLine.SetRange("Item No.", FromBinContent."Item No.");
                        TempWhseWkshLine.SetRange("Location Code", FromBinContent."Location Code");
                        TempWhseWkshLine.SetRange("Variant Code", FromBinContent."Variant Code");
                        repeat
                            if UseForReplenishment(FromBinContent) then begin
                                QtyAvailToTakeBase := FromBinContent.CalcQtyAvailToTake(0);
                                TempWhseWkshLine.SetRange("From Bin Code", FromBinContent."Bin Code");
                                TempWhseWkshLine.SetRange("From Unit of Measure Code", FromBinContent."Unit of Measure Code");
                                TempWhseWkshLine.CalcSums("Qty. (Base)");
                                QtyAvailToTakeBase := QtyAvailToTakeBase - TempWhseWkshLine."Qty. (Base)";

                                if QtyAvailToTakeBase > 0 then begin
                                    MovementQtyBase := QtyAvailToTakeBase;
                                    if RemainQtyToReplenishBase < MovementQtyBase then
                                        MovementQtyBase := RemainQtyToReplenishBase;
                                    CreateWhseWkshLine(ToBinContent, FromBinContent, MovementQtyBase);
                                    RemainQtyToReplenishBase := RemainQtyToReplenishBase - MovementQtyBase;
                                end;
                            end;
                        until (FromBinContent.Next() = 0) or (RemainQtyToReplenishBase = 0);
                        TempWhseWkshLine.Copy(WhseWkshLine2);
                    end;
            until (ItemUnitOfMeasure.Next() = 0) or (RemainQtyToReplenishBase = 0);
    end;

    procedure CreateWhseWkshLine(ToBinContent: Record "Bin Content"; FromBinContent: Record "Bin Content"; MovementQtyBase: Decimal)
    begin
        TempWhseWkshLine.Init();
        TempWhseWkshLine."Worksheet Template Name" := WhseWkshTemplateName;
        TempWhseWkshLine.Name := WhseWkshName;
        TempWhseWkshLine."Location Code" := LocationCode;
        TempWhseWkshLine."Line No." := NextLineNo;
        TempWhseWkshLine."From Bin Code" := FromBinContent."Bin Code";
        TempWhseWkshLine."From Zone Code" := FromBinContent."Zone Code";
        TempWhseWkshLine."From Unit of Measure Code" := FromBinContent."Unit of Measure Code";
        TempWhseWkshLine."Qty. per From Unit of Measure" := FromBinContent."Qty. per Unit of Measure";
        TempWhseWkshLine."To Bin Code" := ToBinContent."Bin Code";
        TempWhseWkshLine."To Zone Code" := ToBinContent."Zone Code";
        TempWhseWkshLine."Unit of Measure Code" := ToBinContent."Unit of Measure Code";
        TempWhseWkshLine."Qty. per Unit of Measure" := ToBinContent."Qty. per Unit of Measure";
        TempWhseWkshLine."Item No." := ToBinContent."Item No.";
        TempWhseWkshLine.Validate("Variant Code", ToBinContent."Variant Code");
        TempWhseWkshLine.Validate(Quantity, Round(MovementQtyBase / ToBinContent."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));

        TempWhseWkshLine."Qty. (Base)" := MovementQtyBase;
        TempWhseWkshLine."Qty. Outstanding (Base)" := MovementQtyBase;
        TempWhseWkshLine."Qty. to Handle (Base)" := MovementQtyBase;

        TempWhseWkshLine."Whse. Document Type" := TempWhseWkshLine."Whse. Document Type"::"Whse. Mov.-Worksheet";
        TempWhseWkshLine."Whse. Document No." := WhseWkshName;
        TempWhseWkshLine."Whse. Document Line No." := TempWhseWkshLine."Line No.";
        OnCreateWhseWkshLineOnBeforeInsertTempWhseWkshLine(TempWhseWkshLine, ToBinContent);
        TempWhseWkshLine.Insert();

        NextLineNo := NextLineNo + 10000;
    end;

    procedure GetTempWhseWkshLine(var TempWhseWorksheetLineOut: Record "Whse. Worksheet Line" temporary)
    begin
        TempWhseWorksheetLineOut.Reset();
        TempWhseWorksheetLineOut.Copy(TempWhseWkshLine, true);
    end;

    procedure InsertWhseWkshLine() Result: Boolean
    var
        WhseWkshLine: Record "Whse. Worksheet Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertWhseWkshLine(TempWhseWkshLine, DoNotFillQtytoHandle, Result, IsHandled);
        if IsHandled then
            exit(Result);

        TempWhseWkshLine.Reset();
        TempWhseWkshLine.SetFilter(Quantity, '>0');
        if TempWhseWkshLine.Find('-') then begin
            repeat
                WhseWkshLine.Init();
                WhseWkshLine := TempWhseWkshLine;
                if DoNotFillQtytoHandle then begin
                    WhseWkshLine."Qty. to Handle" := 0;
                    WhseWkshLine."Qty. to Handle (Base)" := 0;
                end;
                if PickAccordingToFEFO(TempWhseWkshLine."Item No.", TempWhseWkshLine."Variant Code") then begin
                    WhseWkshLine."From Zone Code" := '';
                    WhseWkshLine."From Bin Code" := '';
                end;
                WhseWkshLine.Insert();
                OnInsertWhseWkshLineOnAfterWhseWkshLineInsert(WhseWkshLine);
            until TempWhseWkshLine.Next() = 0;
            exit(true);
        end;
        exit(false);
    end;

    local procedure BinBlockedInbound(LocationCode2: Code[10]; BinCode2: Code[20]) Blocked: Boolean
    begin
        GetBin(LocationCode2, BinCode2);
        Blocked := Bin."Block Movement" in
          [Bin."Block Movement"::Inbound, Bin."Block Movement"::All];
        exit(Blocked);
    end;

    procedure UseForReplenishment(FromBinContent: Record "Bin Content"): Boolean
    begin
        if FromBinContent."Block Movement" in
           [FromBinContent."Block Movement"::Outbound,
            FromBinContent."Block Movement"::All]
        then
            exit(false);

        GetBinType(FromBinContent."Bin Type Code");
        exit(not (BinType.Receive or BinType.Ship));
    end;

    local procedure GetBinType(BinTypeCode: Code[10])
    begin
        if BinTypeCode = '' then begin
            Clear(BinType);
            BinType.Init();
        end else
            if BinType.Code <> BinTypeCode then
                BinType.Get(BinTypeCode);
    end;

    local procedure GetBin(LocationCode2: Code[10]; BinCode2: Code[20])
    begin
        if (Bin."Location Code" <> LocationCode2) or
           (Bin.Code <> BinCode2)
        then
            Bin.Get(LocationCode2, BinCode2);
    end;

    procedure SetWhseWorksheet(WhseWkshTemplateName2: Code[10]; WhseWkshName2: Code[10]; LocationCode2: Code[10]; DoNotFillQtytoHandle2: Boolean)
    var
        WhseWorksheetLine: Record "Whse. Worksheet Line";
    begin
        TempWhseWkshLine.DeleteAll();
        WhseWorksheetLine.SetRange("Worksheet Template Name", WhseWkshTemplateName2);
        WhseWorksheetLine.SetRange(Name, WhseWkshName2);
        WhseWorksheetLine.SetRange("Location Code", LocationCode2);
        OnSetWhseWorksheetOnAfterWhseWorksheetLineSetFilters(WhseWorksheetLine);
        if WhseWorksheetLine.FindLast() then
            NextLineNo := WhseWorksheetLine."Line No." + 10000
        else
            NextLineNo := 10000;

        WhseWkshTemplateName := WhseWkshTemplateName2;
        WhseWkshName := WhseWkshName2;
        LocationCode := LocationCode2;
        Location.Get(LocationCode);
        DoNotFillQtytoHandle := DoNotFillQtytoHandle2;
    end;

    local procedure PickAccordingToFEFO(ItemNo: Code[20]; VariantCode: Code[10]): Boolean
    var
        DummyItemTrackingSetup: Record "Item Tracking Setup";
        ItemTrackingMgt: Codeunit "Item Tracking Management";
        EntriesExist: Boolean;
        IsHandled: Boolean;
        Result: Boolean;
    begin
        IsHandled := false;
        OnBeforePickAccordingToFEFO(Location, ItemNo, VariantCode, Result, IsHandled);
        if IsHandled then
            exit(Result);

        if not Location."Pick According to FEFO" then
            exit(false);

        if not ItemTrackingMgt.GetWhseItemTrkgSetup(ItemNo) then
            exit(false);

        if Location."Directed Put-away and Pick" or (Location."Require Receive" and Location."Require Shipment") then
            if ItemTrackingMgt.ExistingExpirationDate(ItemNo, VariantCode, DummyItemTrackingSetup, false, EntriesExist) <> 0D then
                exit(true);

        if ItemTrackingMgt.WhseExistingExpirationDate(ItemNo, VariantCode, Location, DummyItemTrackingSetup, EntriesExist) <> 0D then
            exit(true);

        exit(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePickAccordingToFEFO(Location: Record Location; ItemNo: Code[20]; VariantCode: Code[10]; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCreateWhseWkshLineOnBeforeInsertTempWhseWkshLine(var TempWhseWkshLine: Record "Whse. Worksheet Line" temporary; var ToBinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindReplenishmtBinOnAfterFromBinContentSetFilters(var FromBinContent: Record "Bin Content"; var ToBinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertWhseWkshLineOnAfterWhseWkshLineInsert(var WhseWkshLine: Record "Whse. Worksheet Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindReplenishmtBinOnBeforeCalcQtyAvailToTakeBase(FromBinContent: Record "Bin Content"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertWhseWkshLine(var TempWhseWkshLine: Record "Whse. Worksheet Line" temporary; DoNotFillQtytoHandle: Boolean; var Result: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReplenishmtBin(var TempWhseWkshLine: Record "Whse. Worksheet Line" temporary; ToBinContent: Record "Bin Content"; AllowBreakBulk: Boolean; var NextLineNo: Integer; WhseWkshTemplateName: Code[10]; WhseWkshName: Code[10]; LocationCode: Code[10]; DoNotFillQtytoHandle: Boolean; RemainQtyToReplenishBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnReplenishBinOnAfterAssignExcludedQtyBase(ToBinContent: Record "Bin Content"; var ExcludedQtyBase: Decimal)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnBeforeReplenishBin(ToBinContent: Record "Bin Content"; var IsHandled: Boolean; RemainQtyToReplenishBase: Decimal; AllowBreakBulk: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindBreakbulkBinOnAfterFromBinContentSetFilters(var FromBinContent: Record "Bin Content"; var ToBinContent: Record "Bin Content"; ItemUnitOfMeasure: Record "Item Unit of Measure"; var SkipItemUnitOfMeasure: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSetWhseWorksheetOnAfterWhseWorksheetLineSetFilters(var WhseWorksheetLine: Record "Whse. Worksheet Line")
    begin
    end;
}

