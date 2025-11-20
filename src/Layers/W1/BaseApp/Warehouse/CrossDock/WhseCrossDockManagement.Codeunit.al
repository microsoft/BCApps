// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Warehouse.CrossDock;

using Microsoft.Foundation.UOM;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.Location;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;
using Microsoft.Warehouse.Document;
using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;
using Microsoft.Warehouse.Request;
using Microsoft.Warehouse.Structure;

codeunit 5780 "Whse. Cross-Dock Management"
{

    trigger OnRun()
    begin
    end;

    var
        PurchaseLine: Record "Purchase Line";
        WhseManagement: Codeunit "Whse. Management";
        UOMMgt: Codeunit "Unit of Measure Management";
        SourceType2: Integer;
        UseCrossDocking: Boolean;
        TemplateName: Code[10];
        NameNo: Code[20];
        GlobalLocationCode: Code[10];

    procedure GetUseCrossDock(var UseCrossDock: Boolean; LocationCode: Code[10]; ItemNo: Code[20])
    var
        Item: Record Item;
        StockkeepingUnit: Record "Stockkeeping Unit";
        Location: Record Location;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeGetUseCrossDock(ItemNo, UseCrossDock, IsHandled);
        if IsHandled then
            exit;

        Location.Get(LocationCode);
        Item.Get(ItemNo);
        if StockkeepingUnit.Get(LocationCode, ItemNo) then
            Item."Use Cross-Docking" := StockkeepingUnit."Use Cross-Docking";

        if Item."Use Cross-Docking" and Location."Use Cross-Docking" then
            UseCrossDock := true
        else
            UseCrossDock := false;
    end;

    procedure CalculateCrossDockLines(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    var
        TempWarehouseReceiptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempWarehouseReceiptLineWithSpecOrder: Record "Warehouse Receipt Line" temporary;
        TempItemVariant: Record "Item Variant" temporary;
    begin
        SetTemplate(NewTemplateName, NewNameNo, NewLocationCode);
        if TemplateName <> '' then
            exit;

        OnCalculateCrossDockLinesOnAfterSetTemplate(WhseCrossDockOpportunity, NewTemplateName, NewNameNo, NewLocationCode);

        SeparateWhseRcptLinesWthSpecOrder(TempWarehouseReceiptLineNoSpecOrder, TempWarehouseReceiptLineWithSpecOrder, TempItemVariant);
        FilterCrossDockOpp(WhseCrossDockOpportunity);
        CalcCrossDockWithoutSpecOrder(WhseCrossDockOpportunity, TempWarehouseReceiptLineNoSpecOrder, TempItemVariant);
        CalcCrossDockForSpecialOrder(WhseCrossDockOpportunity, TempWarehouseReceiptLineWithSpecOrder);

        OnAfterCalculateCrossDockLines(WhseCrossDockOpportunity, NewTemplateName, NewNameNo, NewLocationCode);
    end;

    local procedure CalcCrossDockForSpecialOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
    begin
        if TempWarehouseReceiptLine.Find('-') then
            repeat
                WarehouseReceiptLine.Get(TempWarehouseReceiptLine."No.", TempWarehouseReceiptLine."Line No.");
                WhseCrossDockOpportunity.SetRange("Source Line No.", TempWarehouseReceiptLine."Line No.");
                WhseCrossDockOpportunity.DeleteAll();
                GetSourceLine(TempWarehouseReceiptLine."Source Type", TempWarehouseReceiptLine."Source Subtype", TempWarehouseReceiptLine."Source No.", TempWarehouseReceiptLine."Source Line No.");
                CalculateCrossDock(
                  WhseCrossDockOpportunity, TempWarehouseReceiptLine."Item No.", TempWarehouseReceiptLine."Variant Code", GlobalLocationCode,
                  RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, TempWarehouseReceiptLine."Line No.");

                UpdateQtyToCrossDock(
                  WarehouseReceiptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);
            until TempWarehouseReceiptLine.Next() = 0;
    end;

    local procedure CalcCrossDockWithoutSpecOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var TempWarehouseReceiptLine: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        QtyToCrossDockBase: Decimal;
        QtyOnCrossDockBase: Decimal;
        RemainingNeededQtyBase: Decimal;
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        NewItemVariant: Boolean;
    begin
        if TempItemVariant.FindSet() then begin
            FilterWhseRcptLine(TempWarehouseReceiptLine);
            repeat
                NewItemVariant := true;
                TempWarehouseReceiptLine.SetRange("Item No.", TempItemVariant."Item No.");
                TempWarehouseReceiptLine.SetRange("Variant Code", TempItemVariant.Code);
                if TempWarehouseReceiptLine.Find('-') then
                    repeat
                        WarehouseReceiptLine.Get(TempWarehouseReceiptLine."No.", TempWarehouseReceiptLine."Line No.");
                        WhseCrossDockOpportunity.SetRange("Source Line No.", TempWarehouseReceiptLine."Line No.");
                        WhseCrossDockOpportunity.DeleteAll();
                        if NewItemVariant then begin
                            GetSourceLine(TempWarehouseReceiptLine."Source Type", TempWarehouseReceiptLine."Source Subtype", TempWarehouseReceiptLine."Source No.", TempWarehouseReceiptLine."Source Line No.");
                            CalculateCrossDock(
                              WhseCrossDockOpportunity, TempWarehouseReceiptLine."Item No.", TempWarehouseReceiptLine."Variant Code", GlobalLocationCode,
                              RemainingNeededQtyBase, QtyOnPickBase, QtyPickedBase, TempWarehouseReceiptLine."Line No.");
                        end;
                        if NewItemVariant or (RemainingNeededQtyBase <> 0) then
                            UpdateQtyToCrossDock(
                              WarehouseReceiptLine, RemainingNeededQtyBase, QtyToCrossDockBase, QtyOnCrossDockBase);

                        NewItemVariant := false;
                    until (TempWarehouseReceiptLine.Next() = 0) or (RemainingNeededQtyBase = 0);
            until TempItemVariant.Next() = 0;
        end;
    end;

    procedure CalcRemainingNeededQtyBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; QtyToHandleBase: Decimal) RemainingNeededQtyBase: Decimal
    var
        Dummy: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcRemainingNeededQtyBase(PurchaseLine, ItemNo, VariantCode, GlobalLocationCode, QtyOnCrossDockBase, QtyToCrossDockBase, QtyNeededBase, QtyToHandleBase, RemainingNeededQtyBase, IsHandled);
        if IsHandled then
            exit(RemainingNeededQtyBase);

        CalcCrossDockedItems(ItemNo, VariantCode, '', GlobalLocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(GlobalLocationCode, ItemNo, VariantCode);
        OnCalcRemainingNeededQtyBaseOnAfterCalcQtyOnCrossDockBase(ItemNo, VariantCode, QtyNeededBase, HasSpecialOrder(), QtyOnCrossDockBase, GlobalLocationCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then begin
            RemainingNeededQtyBase := QtyToCrossDockBase - QtyToHandleBase;
            QtyToCrossDockBase := QtyToHandleBase
        end else
            RemainingNeededQtyBase := 0;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    procedure CalculateCrossDockLine(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; var QtyNeededBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal; LineNo: Integer; QtyToHandleBase: Decimal)
    var
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        Dummy: Decimal;
    begin
        FilterCrossDockOpp(WhseCrossDockOpportunity);
        WhseCrossDockOpportunity.SetRange("Source Line No.", LineNo);
        WhseCrossDockOpportunity.DeleteAll();

        CalculateCrossDock(
          WhseCrossDockOpportunity, ItemNo, VariantCode, GlobalLocationCode, QtyNeededBase, QtyOnPickBase, QtyPickedBase, LineNo);

        CalcCrossDockedItems(ItemNo, VariantCode, '', GlobalLocationCode, Dummy, QtyOnCrossDockBase);
        QtyOnCrossDockBase += CalcCrossDockReceivedNotCrossDocked(GlobalLocationCode, ItemNo, VariantCode);
        OnCalculateCrossDockLineOnAfterCalcQtyOnCrossDockBase(ItemNo, VariantCode, QtyNeededBase, HasSpecialOrder(), QtyOnCrossDockBase, GlobalLocationCode);

        QtyToCrossDockBase := QtyNeededBase - QtyOnCrossDockBase;
        if QtyToHandleBase < QtyToCrossDockBase then
            QtyToCrossDockBase := QtyToHandleBase;
        if QtyToCrossDockBase < 0 then
            QtyToCrossDockBase := 0;
    end;

    local procedure CalculateCrossDock(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyNeededSumBase: Decimal; var QtyOnPickSumBase: Decimal; var QtyPickedSumBase: Decimal; LineNo: Integer)
    var
        Location: Record Location;
        QtyOnPick: Decimal;
        QtyPicked: Decimal;
        CrossDockDate: Date;
    begin
        Location.Get(LocationCode);
        if Format(Location."Cross-Dock Due Date Calc.") <> '' then
            CrossDockDate := CalcDate(Location."Cross-Dock Due Date Calc.", WorkDate())
        else
            CrossDockDate := WorkDate();

        OnCalculateCrossDockOnAfterAssignCrossDocDate(
            WhseCrossDockOpportunity, CrossDockDate, ItemNo, VariantCode, LocationCode,
            QtyNeededSumBase, QtyOnPickSumBase, QtyPickedSumBase, LineNo, TemplateName, NameNo);

        CalcCrossDockToSalesOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        CalcCrossDockToTransferOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        OnCalcCrossDockToProdOrderComponent(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        OnCalcCrossDockToServiceOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);

        WhseCrossDockOpportunity.CalcSums("Qty. Needed (Base)", "Pick Qty. (Base)", "Picked Qty. (Base)");
        QtyNeededSumBase := WhseCrossDockOpportunity."Qty. Needed (Base)";
        QtyOnPickSumBase := WhseCrossDockOpportunity."Pick Qty. (Base)";
        QtyPickedSumBase := WhseCrossDockOpportunity."Picked Qty. (Base)";
    end;

    procedure InsertCrossDockOpp(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; SourceType: Integer; SourceSubType: Integer; SourceNo: Code[20]; SourceLineNo: Integer; SourceSubLineNo: Integer; QtyOutstanding: Decimal; QtyOutstandingBase: Decimal; QtyOnPick: Decimal; QtyOnPickBase: Decimal; QtyPicked: Decimal; QtyPickedBase: Decimal; UOMCode: Code[10]; QtyPerUOM: Decimal; DueDate: Date; ItemNo: Code[20]; VariantCode: Code[10]; LineNo: Integer)
    var
        IsHandled: Boolean;
    begin
        OnBeforeInsertCrossDockOpp(SourceType);

        if HasSpecialOrder() and (SourceType <> Database::"Sales Line") then
            exit;

        if (QtyOutstandingBase - QtyOnPickBase - QtyPickedBase) <= 0 then
            exit;

        OnInsertCrossDockOppOnBeforeInitWhseCrossDockOpp(SourceType);

        WhseCrossDockOpportunity.Init();
        WhseCrossDockOpportunity."Source Template Name" := TemplateName;
        WhseCrossDockOpportunity."Source Name/No." := NameNo;
        WhseCrossDockOpportunity."Source Line No." := LineNo;
        WhseCrossDockOpportunity."Line No." := WhseCrossDockOpportunity."Line No." + 10000;
        WhseCrossDockOpportunity."To Source Type" := SourceType;
        WhseCrossDockOpportunity."To Source Subtype" := SourceSubType;
        WhseCrossDockOpportunity."To Source No." := SourceNo;
        WhseCrossDockOpportunity."To Source Line No." := SourceLineNo;
        WhseCrossDockOpportunity."To Source Subline No." := SourceSubLineNo;
        WhseCrossDockOpportunity."To Source Document" :=
            WhseManagement.GetSourceDocumentType(WhseCrossDockOpportunity."To Source Type", WhseCrossDockOpportunity."To Source Subtype").AsInteger();
        WhseCrossDockOpportunity."Due Date" := DueDate;
        WhseCrossDockOpportunity."To-Src. Unit of Measure Code" := UOMCode;
        WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas." := QtyPerUOM;
        WhseCrossDockOpportunity."Item No." := ItemNo;
        WhseCrossDockOpportunity."Variant Code" := VariantCode;
        WhseCrossDockOpportunity."Location Code" := GlobalLocationCode;

        SubtractExistingCrossDockOppQtysToSource(WhseCrossDockOpportunity);

        OnInsertCrossDockLineOnBeforeCalculateQtyNeeded(QtyOutstanding, QtyOutstandingBase);

        WhseCrossDockOpportunity."Qty. Needed (Base)" := Maximum(WhseCrossDockOpportunity."Qty. Needed (Base)" + QtyOutstandingBase - QtyOnPickBase - QtyPickedBase, 0);
        WhseCrossDockOpportunity."Qty. Needed" := Maximum(WhseCrossDockOpportunity."Qty. Needed" + QtyOutstanding - QtyOnPick - QtyPicked, 0);

        WhseCrossDockOpportunity."Pick Qty. (Base)" := Maximum(WhseCrossDockOpportunity."Pick Qty. (Base)" + QtyOnPickBase, 0);
        WhseCrossDockOpportunity."Pick Qty." := Maximum(WhseCrossDockOpportunity."Pick Qty." + QtyOnPick, 0);

        WhseCrossDockOpportunity."Picked Qty. (Base)" := Maximum(WhseCrossDockOpportunity."Picked Qty. (Base)" + QtyPickedBase, 0);
        WhseCrossDockOpportunity."Picked Qty." := Maximum(WhseCrossDockOpportunity."Picked Qty." + QtyPicked, 0);

        IsHandled := false;
        OnBeforeCrossDockOppInsert(WhseCrossDockOpportunity, QtyPerUOM, NameNo, LineNo, IsHandled);
        if not IsHandled then
            WhseCrossDockOpportunity.Insert();
    end;

    procedure ShowCrossDock(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; SourceTemplateName: Code[10]; SourceNameNo: Code[20]; SourceLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10])
    var
        ReceiptLine: Record "Warehouse Receipt Line";
        CrossDockForm: Page "Cross-Dock Opportunities";
        QtyToCrossDock: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeShowCrossDock(WhseCrossDockOpportunity, SourceTemplateName, SourceNameNo, SourceLineNo, LocationCode, ItemNo, VariantCode, IsHandled);
        if IsHandled then
            exit;

        WhseCrossDockOpportunity.FilterGroup(2);
        WhseCrossDockOpportunity.SetRange("Source Template Name", SourceTemplateName);
        WhseCrossDockOpportunity.SetRange("Source Name/No.", SourceNameNo);
        WhseCrossDockOpportunity.SetRange("Item No.", ItemNo);
        WhseCrossDockOpportunity.SetRange("Location Code", LocationCode);
        WhseCrossDockOpportunity.FilterGroup(0);
        ReceiptLine.Get(SourceNameNo, SourceLineNo);
        CrossDockForm.SetValues(ItemNo, VariantCode, LocationCode, SourceTemplateName, SourceNameNo, SourceLineNo,
          ReceiptLine."Unit of Measure Code", ReceiptLine."Qty. per Unit of Measure");
        CrossDockForm.LookupMode(true);
        CrossDockForm.SetTableView(WhseCrossDockOpportunity);
        if CrossDockForm.RunModal() = ACTION::LookupOK then begin
            ReceiptLine.Get(SourceNameNo, SourceLineNo);
            CrossDockForm.GetValues(QtyToCrossDock);
            QtyToCrossDock := QtyToCrossDock / ReceiptLine."Qty. per Unit of Measure";
            if ReceiptLine."Qty. to Receive" < QtyToCrossDock then
                QtyToCrossDock := ReceiptLine."Qty. to Receive";
            ReceiptLine.Validate("Qty. to Cross-Dock", QtyToCrossDock);
            ReceiptLine.Modify();
            OnShowCrossDockOnAfterReceiptLineModify(ReceiptLine);
        end;
    end;

    procedure CalcCrossDockedItems(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; var QtyCrossDockedUOMBase: Decimal; var QtyCrossDockedAllUOMBase: Decimal)
    var
        BinContent: Record "Bin Content";
        QtyAvailToPickBase: Decimal;
    begin
        QtyCrossDockedUOMBase := 0;
        QtyCrossDockedAllUOMBase := 0;
        BinContent.Reset();
        BinContent.SetRange("Location Code", LocationCode);
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetRange("Cross-Dock Bin", true);
        OnCalcCrossDockedItemsOnAfterSetBinContentFilters(BinContent);
        if BinContent.Find('-') then
            repeat
                QtyAvailToPickBase := BinContent.CalcQtyAvailToPick(0);
                if BinContent."Unit of Measure Code" = UOMCode then
                    QtyCrossDockedUOMBase := QtyCrossDockedUOMBase + QtyAvailToPickBase;
                QtyCrossDockedAllUOMBase := QtyCrossDockedAllUOMBase + QtyAvailToPickBase;
            until BinContent.Next() = 0;
    end;

    procedure CalcCrossDockReceivedNotCrossDocked(LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]) ReceivedNotCrossDockedQty: Decimal
    var
        PostedWhseReceiptLine: Record "Posted Whse. Receipt Line";
        ReceivedCrossDockedQty: Decimal;
    begin
        ReceivedNotCrossDockedQty := 0;

        PostedWhseReceiptLine.SetRange("Location Code", LocationCode);
        PostedWhseReceiptLine.SetRange("Item No.", ItemNo);
        PostedWhseReceiptLine.SetRange("Variant Code", VariantCode);
        PostedWhseReceiptLine.SetFilter(Status, '%1|%2', PostedWhseReceiptLine.Status::" ", PostedWhseReceiptLine.Status::"Partially Put Away");
        PostedWhseReceiptLine.SetFilter("Cross-Dock Bin Code", '<>%1', '');
        OnCalcCrossDockReceivedNotCrossDockedOnAfterPostedWhseReceiptLineSetFilters(PostedWhseReceiptLine);
        if PostedWhseReceiptLine.FindSet() then
            repeat
                // calculate received, yet not put-away quantity, that is assumed to be put-away in a cross-dock bin
                ReceivedCrossDockedQty := CalcCrossDockedQtyInPostedReceipt(PostedWhseReceiptLine);
                ReceivedNotCrossDockedQty +=
                  Minimum(
                    Maximum(PostedWhseReceiptLine."Qty. Cross-Docked (Base)" - ReceivedCrossDockedQty, 0),
                    PostedWhseReceiptLine."Qty. (Base)" - PostedWhseReceiptLine."Qty. Put Away (Base)");
            until PostedWhseReceiptLine.Next() = 0;
    end;

    procedure ShowBinContentsCrossDocked(ItemNo: Code[20]; VariantCode: Code[10]; UOMCode: Code[10]; LocationCode: Code[10]; FilterOnUOM: Boolean)
    var
        BinContent: Record "Bin Content";
        BinContentList: Page "Bin Contents List";
    begin
        BinContent.SetRange("Item No.", ItemNo);
        BinContent.SetRange("Variant Code", VariantCode);
        BinContent.SetRange("Cross-Dock Bin", true);
        if FilterOnUOM then
            BinContent.SetRange("Unit of Measure Code", UOMCode);
        BinContentList.SetTableView(BinContent);
        BinContentList.Initialize(LocationCode);
        BinContentList.RunModal();
        Clear(BinContentList);
    end;

    local procedure GetSourceLine(SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
        if SourceType = Database::"Purchase Line" then begin
            PurchaseLine.Get(SourceSubtype, SourceNo, SourceLineNo);
            SourceType2 := SourceType;
        end;

        OnAfterGetSourceLine(SourceType, SourceSubtype, SourceNo, SourceLineNo);
    end;

    procedure CalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal)
    var
        WarehouseShipmentLine: Record "Warehouse Shipment Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalculatePickQty(SourceType, SourceSubtype, SourceNo, SourceLineNo, Qty, QtyBase, OutstandingQty,
            OutstandingQtyBase, QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, IsHandled);
        if not IsHandled then begin
            QtyOnPickBase := 0;
            QtyPickedBase := 0;
            WarehouseShipmentLine.Reset();
            WarehouseShipmentLine.SetCurrentKey("Source Type", "Source Subtype", "Source No.", "Source Line No.");
            WarehouseShipmentLine.SetRange("Source Type", SourceType);
            WarehouseShipmentLine.SetRange("Source Subtype", SourceSubtype);
            WarehouseShipmentLine.SetRange("Source No.", SourceNo);
            WarehouseShipmentLine.SetRange("Source Line No.", SourceLineNo);
            if WarehouseShipmentLine.Find('-') then
                repeat
                    WarehouseShipmentLine.CalcFields("Pick Qty. (Base)", "Pick Qty.");
                    QtyOnPick := QtyOnPick + WarehouseShipmentLine."Pick Qty.";
                    QtyOnPickBase := QtyOnPickBase + WarehouseShipmentLine."Pick Qty. (Base)";
                    QtyPicked := QtyPicked + WarehouseShipmentLine."Qty. Picked";
                    QtyPickedBase := QtyPickedBase + WarehouseShipmentLine."Qty. Picked (Base)";
                until WarehouseShipmentLine.Next() = 0;
            if QtyPickedBase = 0 then begin
                QtyPicked := Qty - OutstandingQty;
                QtyPickedBase := QtyBase - OutstandingQtyBase;
            end;
        end;

        OnAfterCalculatePickQty(
            SourceType, SourceSubtype, SourceNo, SourceLineNo, Qty, QtyBase, OutstandingQty,
            OutstandingQtyBase, QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase);
    end;

    procedure SetTemplate(NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    begin
        TemplateName := NewTemplateName;
        NameNo := NewNameNo;
        GlobalLocationCode := NewLocationCode;
    end;

    local procedure SeparateWhseRcptLinesWthSpecOrder(var TempWarehouseReceiptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary; var TempWarehouseReceiptLineWithSpecOrder: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary)
    var
        WarehouseReceiptLine: Record "Warehouse Receipt Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSeparateWhseRcptLinesWthSpecOrder(TempWarehouseReceiptLineNoSpecOrder, TempWarehouseReceiptLineWithSpecOrder, TempItemVariant, PurchaseLine, SourceType2, NameNo, GlobalLocationCode, IsHandled);
        if IsHandled then
            exit;

        FilterWhseRcptLine(WarehouseReceiptLine);
        if WarehouseReceiptLine.FindSet() then
            repeat
                GetSourceLine(WarehouseReceiptLine."Source Type", WarehouseReceiptLine."Source Subtype", WarehouseReceiptLine."Source No.", WarehouseReceiptLine."Source Line No.");
                if HasSpecialOrder() then begin
                    TempWarehouseReceiptLineWithSpecOrder := WarehouseReceiptLine;
                    TempWarehouseReceiptLineWithSpecOrder.Insert();
                end else begin
                    TempWarehouseReceiptLineNoSpecOrder := WarehouseReceiptLine;
                    TempWarehouseReceiptLineNoSpecOrder.Insert();
                    InsertToItemList(WarehouseReceiptLine, TempItemVariant);
                end;
            until WarehouseReceiptLine.Next() = 0;
    end;

    local procedure InsertToItemList(WarehouseReceiptLine: Record "Warehouse Receipt Line"; var TempItemVariant: Record "Item Variant" temporary)
    begin
        TempItemVariant.Init();
        TempItemVariant."Item No." := WarehouseReceiptLine."Item No.";
        TempItemVariant.Code := WarehouseReceiptLine."Variant Code";
        if TempItemVariant.Insert() then;
    end;

    local procedure FilterWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
        WarehouseReceiptLine.SetRange("No.", NameNo);
        WarehouseReceiptLine.SetRange("Location Code", GlobalLocationCode);
        WarehouseReceiptLine.SetFilter("Qty. to Receive", '>0');

        OnAfterFilterWhseRcptLine(WarehouseReceiptLine, NameNo, GlobalLocationCode);
    end;

    procedure FilterCrossDockOpp(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity")
    begin
        WhseCrossDockOpportunity.SetRange("Source Template Name", TemplateName);
        WhseCrossDockOpportunity.SetRange("Source Name/No.", NameNo);
        WhseCrossDockOpportunity.SetRange("Location Code", GlobalLocationCode);

        OnAfterFilterCrossDockOpp(WhseCrossDockOpportunity);
    end;

    local procedure UpdateQtyToCrossDock(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var RemainingNeededQtyBase: Decimal; var QtyToCrossDockBase: Decimal; var QtyOnCrossDockBase: Decimal)
    var
        RunGetUseCrossDoc, IsHandled : Boolean;
    begin
        RunGetUseCrossDoc := true;
        OnBeforeUpdateQtyToCrossDock(UseCrossDocking, WarehouseReceiptLine, RunGetUseCrossDoc);
        if RunGetUseCrossDoc then
            GetUseCrossDock(UseCrossDocking, WarehouseReceiptLine."Location Code", WarehouseReceiptLine."Item No.");
        if not UseCrossDocking then
            exit;

        RemainingNeededQtyBase :=
            CalcRemainingNeededQtyBase(
                WarehouseReceiptLine."Item No.", WarehouseReceiptLine."Variant Code", RemainingNeededQtyBase,
                QtyToCrossDockBase, QtyOnCrossDockBase, WarehouseReceiptLine."Qty. to Receive (Base)");

        IsHandled := false;
        OnUpdateQtyToCrossDockOnBeforeValidateQtyToCrossDock(WarehouseReceiptLine, IsHandled);
        if not IsHandled then begin
            WarehouseReceiptLine.Validate("Qty. to Cross-Dock", Round(QtyToCrossDockBase / WarehouseReceiptLine."Qty. per Unit of Measure", UOMMgt.QtyRndPrecision()));
            WarehouseReceiptLine."Qty. to Cross-Dock (Base)" := QtyToCrossDockBase;
            WarehouseReceiptLine.Modify();
        end;

        OnAfterUpdateQtyToCrossDock(WarehouseReceiptLine);
    end;

    local procedure HasSpecialOrder(): Boolean
    begin
        exit((SourceType2 = Database::"Purchase Line") and PurchaseLine."Special Order");
    end;

    local procedure SubtractExistingCrossDockOppQtysToSource(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity")
    var
        ExistingWhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity";
    begin
        ExistingWhseCrossDockOpportunity.SetRange("To Source Type", WhseCrossDockOpportunity."To Source Type");
        ExistingWhseCrossDockOpportunity.SetRange("To Source Subtype", WhseCrossDockOpportunity."To Source Subtype");
        ExistingWhseCrossDockOpportunity.SetRange("To Source No.", WhseCrossDockOpportunity."To Source No.");
        ExistingWhseCrossDockOpportunity.SetRange("To Source Line No.", WhseCrossDockOpportunity."To Source Line No.");
        ExistingWhseCrossDockOpportunity.SetRange("To Source Subline No.", WhseCrossDockOpportunity."To Source Subline No.");
        ExistingWhseCrossDockOpportunity.SetRange("Item No.", WhseCrossDockOpportunity."Item No.");
        ExistingWhseCrossDockOpportunity.SetRange("Variant Code", WhseCrossDockOpportunity."Variant Code");
        ExistingWhseCrossDockOpportunity.CalcSums(ExistingWhseCrossDockOpportunity."Qty. to Cross-Dock (Base)", ExistingWhseCrossDockOpportunity."Pick Qty. (Base)", ExistingWhseCrossDockOpportunity."Picked Qty. (Base)");

        WhseCrossDockOpportunity."Qty. Needed" :=
          -Round(ExistingWhseCrossDockOpportunity."Qty. to Cross-Dock (Base)" / WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
        WhseCrossDockOpportunity."Qty. Needed (Base)" := -ExistingWhseCrossDockOpportunity."Qty. to Cross-Dock (Base)";
        WhseCrossDockOpportunity."Pick Qty." :=
          -Round(ExistingWhseCrossDockOpportunity."Pick Qty. (Base)" / WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
        WhseCrossDockOpportunity."Pick Qty. (Base)" := -ExistingWhseCrossDockOpportunity."Pick Qty. (Base)";
        WhseCrossDockOpportunity."Picked Qty." :=
          -Round(ExistingWhseCrossDockOpportunity."Picked Qty. (Base)" / WhseCrossDockOpportunity."To-Src. Qty. per Unit of Meas.", UOMMgt.QtyRndPrecision());
        WhseCrossDockOpportunity."Picked Qty. (Base)" := -ExistingWhseCrossDockOpportunity."Picked Qty. (Base)";
    end;

    procedure CalcCrossDockedQtyInPostedReceipt(PostedWhseReceiptLine: Record "Posted Whse. Receipt Line"): Decimal
    var
        WarehouseEntry: Record "Warehouse Entry";
    begin
        WarehouseEntry.SetRange("Whse. Document Type", WarehouseEntry."Whse. Document Type"::Receipt);
        WarehouseEntry.SetRange("Whse. Document No.", PostedWhseReceiptLine."No.");
        WarehouseEntry.SetRange("Whse. Document Line No.", PostedWhseReceiptLine."Line No.");
        WarehouseEntry.SetFilter("Bin Code", PostedWhseReceiptLine."Cross-Dock Bin Code");
        WarehouseEntry.CalcSums("Qty. (Base)");
        exit(WarehouseEntry."Qty. (Base)");
    end;

    local procedure CalcCrossDockToSalesOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        SalesLine: Record "Sales Line";
        WarehouseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCrossDockToSalesOrder(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, QtyOnPick, QtyPicked, LineNo, SourceType2, PurchaseLine, IsHandled);
        if not IsHandled then begin
            SalesLine.SetRange("Document Type", SalesLine."Document Type"::Order);
            SalesLine.SetRange(Type, "Sales Line Type"::Item);
            SalesLine.SetRange("No.", ItemNo);
            SalesLine.SetRange("Variant Code", VariantCode);
            SalesLine.SetRange("Drop Shipment", false);
            SalesLine.SetRange("Location Code", LocationCode);
            SalesLine.SetRange("Shipment Date", 0D, CrossDockDate);
            SalesLine.SetFilter("Outstanding Qty. (Base)", '>0');
            if HasSpecialOrder() then begin
                SalesLine.SetRange("Document No.", PurchaseLine."Special Order Sales No.");
                SalesLine.SetRange("Line No.", PurchaseLine."Special Order Sales Line No.");
            end else
                SalesLine.SetRange("Special Order", false);
            OnCalcCrossDockToSalesOrderOnAfterSalesLineSetFilters(SalesLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo, NameNo);
            if SalesLine.Find('-') then
                repeat
                    if WarehouseRequest.Get(WarehouseRequest.Type::Outbound, SalesLine."Location Code", Database::"Sales Line", SalesLine."Document Type", SalesLine."Document No.") and
                            (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released)
                        then begin
                        CalculatePickQty(
                        Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.",
                            QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, SalesLine.Quantity, SalesLine."Quantity (Base)",
                            SalesLine."Outstanding Quantity", SalesLine."Outstanding Qty. (Base)");
                        OnCalcCrossDockToSalesOrderOnBeforeInsertCrossDockLine(SalesLine);
                        InsertCrossDockOpp(
                            WhseCrossDockOpportunity,
                        Database::"Sales Line", SalesLine."Document Type".AsInteger(), SalesLine."Document No.", SalesLine."Line No.", 0,
                            SalesLine.Quantity, SalesLine."Quantity (Base)", QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                            SalesLine."Unit of Measure Code", SalesLine."Qty. per Unit of Measure", SalesLine."Shipment Date",
                            SalesLine."No.", SalesLine."Variant Code", LineNo);
                    end;
                    OnCalcCrossDockToSalesOrderOnAfterLoopIteration(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo, WarehouseRequest, SalesLine);
                until SalesLine.Next() = 0;
        end;

        OnAfterCalcCrossDockToSalesOrder(WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
    end;

    local procedure CalcCrossDockToTransferOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    var
        TransferLine: Record "Transfer Line";
        WarehouseRequest: Record "Warehouse Request";
        QtyOnPickBase: Decimal;
        QtyPickedBase: Decimal;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCalcCrossDockToTransferOrder(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, LineNo, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetRange("Transfer-from Code", LocationCode);
        TransferLine.SetRange(Status, TransferLine.Status::Released);
        TransferLine.SetRange("Derived From Line No.", 0);
        TransferLine.SetRange("Item No.", ItemNo);
        TransferLine.SetRange("Variant Code", VariantCode);
        TransferLine.SetRange("Shipment Date", 0D, CrossDockDate);
        TransferLine.SetFilter("Outstanding Qty. (Base)", '>0');
        OnCalcCrossDockToTransferOrderOnAfterTransferLineSetFilters(TransferLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
        if TransferLine.Find('-') then
            repeat
                if WarehouseRequest.Get(
                    WarehouseRequest.Type::Outbound, TransferLine."Transfer-from Code", Database::"Transfer Line", 0, TransferLine."Document No.") and
                    (WarehouseRequest."Document Status" = WarehouseRequest."Document Status"::Released)
                then begin
                    CalculatePickQty(
                        Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase, TransferLine.Quantity, TransferLine."Quantity (Base)",
                        TransferLine."Outstanding Quantity", TransferLine."Outstanding Qty. (Base)");
                    OnCalcCrossDockToTransferOrderOnBeforeInsertCrossDockLine(TransferLine, WhseCrossDockOpportunity, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
                    InsertCrossDockOpp(
                        WhseCrossDockOpportunity,
                        Database::"Transfer Line", 0, TransferLine."Document No.", TransferLine."Line No.", 0,
                        TransferLine.Quantity, TransferLine."Quantity (Base)",
                        QtyOnPick, QtyOnPickBase, QtyPicked, QtyPickedBase,
                        TransferLine."Unit of Measure Code", TransferLine."Qty. per Unit of Measure", TransferLine."Shipment Date",
                        TransferLine."Item No.", TransferLine."Variant Code", LineNo);
                end;
            until TransferLine.Next() = 0;
    end;

    local procedure Maximum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 >= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    local procedure Minimum(Value1: Decimal; Value2: Decimal): Decimal
    begin
        if Value1 <= Value2 then
            exit(Value1);
        exit(Value2);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalculatePickQty(SourceType: Integer; SourceSubtype: Integer; SourceNo: Code[20]; SourceLineNo: Integer; Qty: Decimal; QtyBase: Decimal; OutstandingQty: Decimal; OutstandingQtyBase: Decimal; var QtyOnPick: Decimal; var QtyOnPickBase: Decimal; var QtyPicked: Decimal; var QtyPickedBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalculateCrossDockLines(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterCalcCrossDockToSalesOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterGetSourceLine(SourceType: Option; SourceSubtype: Option; SourceNo: Code[20]; SourceLineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterCrossDockOpp(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnAfterUpdateQtyToCrossDock(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCrossDockToTransferOrder(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCrossDockOppInsert(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; QtyPerUOM: Decimal; NameNo: Code[20]; LineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnShowCrossDockOnAfterReceiptLineModify(var WarehouseReceiptLine: Record "Warehouse Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetUseCrossDock(ItemNo: Code[20]; var UseCrossDock: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToSalesOrderOnBeforeInsertCrossDockLine(SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcCrossDockToSalesOrderOnAfterLoopIteration(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; WarehouseRequest: Record "Warehouse Request"; SalesLine: Record "Sales Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcCrossDockToSalesOrderOnAfterSalesLineSetFilters(var SalesLine: Record "Sales Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer; NameNo: Code[20])
    begin
    end;

#if not CLEAN25
    internal procedure RunOnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
        OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComp);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit ProdOrderWarehouseMgt', '25.0')]
    local procedure OnCalcCrossDockToProdOrderComponentOnBeforeInsertCrossDockLine(ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
        OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(ServiceLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit ServiceWarehouseMgt', '25.0')]
    local procedure OnCalcCrossDockToServiceOrderOnAfterServiceLineSetFilters(var ServiceLine: Record Microsoft.Service.Document."Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
        OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit ServiceWarehouseMgt', '25.0')]
    local procedure OnCalcCrossDockToServiceOrderOnAfterInsertCrossDockLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;
#endif

#if not CLEAN25
    internal procedure RunOnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
        OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine, WhseCrossDockOpp, QtyOnPick, QtyPicked, ItemNo, VariantCode, LocationCode, CrossDockDate, LineNo);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit ServiceWarehouseMgt', '25.0')]
    local procedure OnCalcCrossDockToServiceOrderOnBeforeInsertCrossDockLine(ServiceLine: Record Microsoft.Service.Document."Service Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToTransferOrderOnAfterTransferLineSetFilters(var TransferLine: Record "Transfer Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockToTransferOrderOnBeforeInsertCrossDockLine(TransferLine: Record "Transfer Line"; var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalculateCrossDockOnAfterAssignCrossDocDate(var WhseCrossDockOpp: Record "Whse. Cross-Dock Opportunity"; var CrossDockDate: Date; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyNeededSumBase: Decimal; var QtyOnPickSumBase: Decimal; var QtyPickedSumBase: Decimal; LineNo: Integer; TemplateName: Code[10]; NameNo: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcRemainingNeededQtyBaseOnAfterCalcQtyOnCrossDockBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; SpecialOrder: Boolean; var QtyOnCrossDockBase: Decimal; LocationCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateCrossDockLineOnAfterCalcQtyOnCrossDockBase(ItemNo: Code[20]; VariantCode: Code[10]; QtyNeededBase: Decimal; SpecialOrder: Boolean; var QtyOnCrossDockBase: Decimal; LocationCode: Code[20])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCrossDockLineOnBeforeCalculateQtyNeeded(var QtyOutstanding: Decimal; var QtyOutstandingBase: Decimal)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnUpdateQtyToCrossDockOnBeforeValidateQtyToCrossDock(WhseRcptLine: Record "Warehouse Receipt Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcRemainingNeededQtyBase(PurchaseLine: Record "Purchase Line"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; var QtyOnCrossDockBase: Decimal; var QtyToCrossDockBase: Decimal; QtyNeededBase: Decimal; QtyToHandleBase: Decimal; var RemainingNeededQtyBase: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCrossDockOpp(var SourceType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertCrossDockOppOnBeforeInitWhseCrossDockOpp(var SourceType: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeShowCrossDock(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; SourceTemplateName: Code[10]; SourceNameNo: Code[20]; SourceLineNo: Integer; LocationCode: Code[10]; ItemNo: Code[20]; VariantCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSeparateWhseRcptLinesWthSpecOrder(var TempWarehouseReceiptLineNoSpecOrder: Record "Warehouse Receipt Line" temporary; var TempWarehouseReceiptLineWthSpecOrder: Record "Warehouse Receipt Line" temporary; var TempItemVariant: Record "Item Variant" temporary; var PurchaseLine: Record "Purchase Line"; var SourceType2: Integer; NameNo: Code[20]; LocationCode: Code[10]; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcCrossDockToSalesOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; var QtyOnPick: Decimal; var QtyPicked: Decimal; LineNo: Integer; SourceType2: Integer; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;

#if not CLEAN25
    internal procedure RunOnBeforeCalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; var QtyOnPick: Decimal; var QtyPicked: Decimal; LineNo: Integer; var IsHandled: Boolean)
    begin
        OnBeforeCalcCrossDockToServiceOrder(WhseCrossDockOpportunity, ItemNo, VariantCode, LocationCode, CrossDockDate, QtyOnPick, QtyPicked, LineNo, SourceType2, PurchaseLine, IsHandled);
    end;

    [IntegrationEvent(false, false)]
    [Obsolete('Replaced by same event in codeunit ServiceWarehouseMgt', '25.0')]
    local procedure OnBeforeCalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; var QtyOnPick: Decimal; var QtyPicked: Decimal; LineNo: Integer; SourceType2: Integer; PurchaseLine: Record "Purchase Line"; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(true, false)]
    local procedure OnCalcCrossDockToProdOrderComponent(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnCalcCrossDockToServiceOrder(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; var QtyOnPick: Decimal; var QtyPicked: Decimal; ItemNo: Code[20]; VariantCode: Code[10]; LocationCode: Code[10]; CrossDockDate: Date; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterFilterWhseRcptLine(var WarehouseReceiptLine: Record "Warehouse Receipt Line"; NameNo: Code[20]; LocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalculateCrossDockLinesOnAfterSetTemplate(var WhseCrossDockOpportunity: Record "Whse. Cross-Dock Opportunity"; NewTemplateName: Code[10]; NewNameNo: Code[20]; NewLocationCode: Code[10])
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockedItemsOnAfterSetBinContentFilters(var BinContent: Record "Bin Content")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCalcCrossDockReceivedNotCrossDockedOnAfterPostedWhseReceiptLineSetFilters(var PostedWhseReceiptLine: Record "Posted Whse. Receipt Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateQtyToCrossDock(var UseCrossDock: Boolean; var WarehouseReceiptLine: Record "Warehouse Receipt Line"; var RunGetUseCrossDoc: Boolean)
    begin
    end;
}

