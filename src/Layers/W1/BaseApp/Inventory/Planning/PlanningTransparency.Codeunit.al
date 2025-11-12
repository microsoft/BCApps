// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Planning;

using Microsoft.Inventory.Location;
using Microsoft.Inventory.Requisition;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

codeunit 99000856 "Planning Transparency"
{

    trigger OnRun()
    begin
    end;

    var
        TempInvProfileTrack: Record "Inventory Profile Track Buffer" temporary;
        TempPlanningWarning: Record "Untracked Planning Element" temporary;
        CurrReqLine: Record "Requisition Line";
        CurrTemplateName: Code[10];
        CurrWorksheetName: Code[10];
#pragma warning disable AA0074
        Text000: Label 'Undefined';
        Text001: Label 'Demand Forecast';
        Text002: Label 'Blanket Order';
        Text003: Label 'Safety Stock Quantity';
        Text004: Label 'Reorder Point';
        Text005: Label 'Maximum Inventory';
        Text006: Label 'Reorder Quantity';
        Text007: Label 'Maximum Order Quantity';
        Text008: Label 'Minimum Order Quantity';
        Text009: Label 'Order Multiple';
        Text010: Label 'Dampener (% of Lot Size)';
        Text011: Label 'Emergency Order';
#pragma warning restore AA0074
        SequenceNo: Integer;

    procedure SetTemplAndWorksheet(TemplateName: Code[10]; WorksheetName: Code[10])
    begin
        CurrTemplateName := TemplateName;
        CurrWorksheetName := WorksheetName;
    end;

#if not CLEAN25
    [Obsolete('Replaced by procedure GetSurplusType()', '26.0')]
    procedure FindReason(var DemandInvProfile: Record "Inventory Profile") Result: Integer
    begin
        exit(GetSurplusType(DemandInvProfile).AsInteger());
    end;
#endif

    procedure GetSurplusType(var DemandInvProfile: Record "Inventory Profile") Result: Enum "Planning Surplus Type"
    var
        SurplusType: Enum "Planning Surplus Type";
#if not CLEAN26
        ResultInt: Integer;
#endif
        IsHandled: Boolean;
    begin
        IsHandled := false;
#if not CLEAN26
        OnBeforeFindReason(DemandInvProfile, ResultInt, IsHandled);
        Result := "Planning Surplus Type".FromInteger(ResultInt);
#endif
        OnBeforeGetSurplusType(DemandInvProfile, Result, IsHandled);
        if IsHandled then
            exit(Result);

        SurplusType := SurplusType::None;
        case DemandInvProfile."Source Type" of
            0:
                case DemandInvProfile."Order Relation" of
                    DemandInvProfile."Order Relation"::"Safety Stock":
                        SurplusType := SurplusType::SafetyStock;
                    DemandInvProfile."Order Relation"::"Reorder Point":
                        SurplusType := SurplusType::ReorderPoint;
                    else
                        SurplusType := SurplusType::Undefined;
                end;
            Database::"Sales Line":
                if DemandInvProfile."Source Order Status" = 4 then
                    SurplusType := SurplusType::BlanketOrder;
            else
                OnFindReasonOnAfterSetSurplusType(DemandInvProfile, SurplusType);
        end;
        exit(SurplusType);
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedure LogPlanningSurplus()', '26.0')]
    procedure LogSurplus(SupplyLineNo: Integer; DemandLineNo: Integer; SourceType: Integer; SourceID: Code[20]; Qty: Decimal; SurplusType: Option "None",Forecast,BlanketOrder,SafetyStock,ReorderPoint,MaxInventory,FixedOrderQty,MaxOrder,MinOrder,OrderMultiple,DampenerQty,PlanningFlexibility,Undefined,EmergencyOrder)
    begin
        LogPlanningSurplus(SupplyLineNo, DemandLineNo, SourceType, SourceID, Qty, "Planning Surplus Type".FromInteger(SurplusType));
    end;
#endif

    procedure LogPlanningSurplus(SupplyLineNo: Integer; DemandLineNo: Integer; SourceType: Integer; SourceID: Code[20]; Qty: Decimal; SurplusType: Enum "Planning Surplus Type")
    var
        Priority: Integer;
        IsHandled: Boolean;
    begin
        if (Qty = 0) or (SupplyLineNo = 0) then
            exit;

        case SurplusType of
            SurplusType::BlanketOrder:
                Priority := 1;
            SurplusType::Forecast:
                Priority := 1;
            SurplusType::SafetyStock:
                Priority := 1;
            SurplusType::ReorderPoint:
                Priority := 1;
            SurplusType::EmergencyOrder:
                Priority := 2;
            SurplusType::MaxInventory:
                Priority := 3;
            SurplusType::FixedOrderQty:
                Priority := 3;
            SurplusType::MaxOrder:
                Priority := 4;
            SurplusType::MinOrder:
                Priority := 5;
            SurplusType::OrderMultiple:
                Priority := 6;
            SurplusType::DampenerQty:
                Priority := 7;
            else begin
                IsHandled := false;
                OnLogSurplusOnCaseSurplusTypeElse(SupplyLineNo, DemandLineNo, SourceType, SourceID, Qty, SurplusType.AsInteger(), Priority, IsHandled);
                if not IsHandled then
                    SurplusType := SurplusType::Undefined;
            end;
        end;

        if SurplusType <> SurplusType::Undefined then begin
            TempInvProfileTrack.Init();
            TempInvProfileTrack.Priority := Priority;
            TempInvProfileTrack."Line No." := SupplyLineNo;
            TempInvProfileTrack."Demand Line No." := DemandLineNo;
            TempInvProfileTrack."Sequence No." := GetSequenceNo();
            TempInvProfileTrack."Surplus Type" := SurplusType;
            TempInvProfileTrack."Source Type" := SourceType;
            TempInvProfileTrack."Source ID" := SourceID;
            TempInvProfileTrack."Quantity Tracked" := Qty;
            OnLogSurplusOnBeforeInsertTempInvProfileTrack(TempInvProfileTrack);
            TempInvProfileTrack.Insert();
        end;
    end;

#if not CLEAN26
    [Obsolete('Replaced by procedure ModifyPlanningLog()', '26.0')]
    procedure ModifyLogEntry(SupplyLineNo: Integer; DemandLineNo: Integer; SourceType: Integer; SourceID: Code[20]; Qty: Decimal; SurplusType: Option)
    begin
        ModifyPlanningLog(SupplyLineNo, DemandLineNo, SourceType, SourceID, Qty, "Planning Surplus Type".FromInteger(SurplusType));
    end;
#endif

    procedure ModifyPlanningLog(SupplyLineNo: Integer; DemandLineNo: Integer; SourceType: Integer; SourceID: Code[20]; Qty: Decimal; SurplusType: Enum "Planning Surplus Type")
    begin
        if (Qty = 0) or (SupplyLineNo = 0) then
            exit;

        TempInvProfileTrack.SetRange("Line No.", SupplyLineNo);
        TempInvProfileTrack.SetRange("Demand Line No.", DemandLineNo);
        TempInvProfileTrack.SetRange("Surplus Type", SurplusType);
        TempInvProfileTrack.SetRange("Source Type", SourceType);
        TempInvProfileTrack.SetRange("Source ID", SourceID);
        if TempInvProfileTrack.FindLast() then begin
            TempInvProfileTrack."Quantity Tracked" += Qty;
            TempInvProfileTrack.Modify();
        end;
        TempInvProfileTrack.Reset();
    end;

    procedure CleanLog(SupplyLineNo: Integer)
    begin
        TempInvProfileTrack.SetRange("Line No.", SupplyLineNo);
        if not TempInvProfileTrack.IsEmpty() then
            TempInvProfileTrack.DeleteAll();
        TempInvProfileTrack.SetRange("Line No.");

        TempPlanningWarning.SetRange("Worksheet Line No.", SupplyLineNo);
        if not TempPlanningWarning.IsEmpty() then
            TempPlanningWarning.DeleteAll();
        TempPlanningWarning.SetRange("Worksheet Line No.");
    end;

    procedure PublishSurplus(var SupplyInvProfile: Record "Inventory Profile"; var SKU: Record "Stockkeeping Unit"; var ReqLine: Record "Requisition Line"; var ReservEntry: Record "Reservation Entry")
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
        QtyTracked: Decimal;
        QtyRemaining: Decimal;
        QtyReorder: Decimal;
        QtyMin: Decimal;
        QtyRound: Decimal;
        DampenerQty: Decimal;
        OrderSizeParticipated: Boolean;
        IsHandled: Boolean;
    begin
        TempInvProfileTrack.SetRange("Line No.", SupplyInvProfile."Line No.");

        QtyRemaining := SurplusQty(ReqLine, ReservEntry);
        QtyTracked := SupplyInvProfile."Quantity (Base)" - QtyRemaining;
        if (QtyRemaining > 0) or not TempPlanningWarning.IsEmpty() then begin
            UntrackedPlanningElement.SetRange("Worksheet Template Name", CurrTemplateName);
            UntrackedPlanningElement.SetRange("Worksheet Batch Name", CurrWorksheetName);
            UntrackedPlanningElement.SetRange("Worksheet Line No.", SupplyInvProfile."Planning Line No.");
            if not UntrackedPlanningElement.FindLast() then begin
                UntrackedPlanningElement."Worksheet Template Name" := CurrTemplateName;
                UntrackedPlanningElement."Worksheet Batch Name" := CurrWorksheetName;
                UntrackedPlanningElement."Worksheet Line No." := SupplyInvProfile."Planning Line No.";
            end;
            if QtyRemaining <= 0 then
                TempInvProfileTrack.SetFilter(TempInvProfileTrack."Warning Level", '<>%1', 0);
            if TempInvProfileTrack.FindSet() then
                repeat
                    TempInvProfileTrack.SetRange(TempInvProfileTrack.Priority, TempInvProfileTrack.Priority);
                    TempInvProfileTrack.SetRange(TempInvProfileTrack."Demand Line No.", TempInvProfileTrack."Demand Line No.");
                    UntrackedPlanningElement.Init();
                    TempInvProfileTrack.FindLast();
                    UntrackedPlanningElement."Track Quantity From" := QtyRemaining;
                    UntrackedPlanningElement."Warning Level" := TempInvProfileTrack."Warning Level";
                    case TempInvProfileTrack.Priority of
                        1:
                            begin
                                // Anticipated demand
                                TempInvProfileTrack.CalcSums(TempInvProfileTrack."Quantity Tracked");
                                if TempInvProfileTrack."Surplus Type" = TempInvProfileTrack."Surplus Type"::SafetyStock then begin
                                    UntrackedPlanningElement."Parameter Value" := SKU."Safety Stock Quantity";
                                    TempInvProfileTrack."Source ID" := SKU."Item No.";
                                end else
                                    if TempInvProfileTrack."Surplus Type" = TempInvProfileTrack."Surplus Type"::ReorderPoint then begin
                                        UntrackedPlanningElement."Parameter Value" := SKU."Reorder Point";
                                        TempInvProfileTrack."Source ID" := SKU."Item No.";
                                        TempInvProfileTrack."Quantity Tracked" := 0;
                                    end;
                                UntrackedPlanningElement."Untracked Quantity" := TempInvProfileTrack."Quantity Tracked";
                            end;
                        2:
                            // Emergency Order
                            UntrackedPlanningElement."Untracked Quantity" := TempInvProfileTrack."Quantity Tracked";
                        3:
                            begin
                                // Order size
                                QtyReorder := TempInvProfileTrack."Quantity Tracked";
                                if QtyTracked < QtyReorder then begin
                                    OrderSizeParticipated := true;
                                    UntrackedPlanningElement."Untracked Quantity" := QtyReorder - QtyTracked;
                                    case TempInvProfileTrack."Surplus Type" of
                                        TempInvProfileTrack."Surplus Type"::ReorderPoint:
                                            UntrackedPlanningElement."Parameter Value" := SKU."Reorder Point";
                                        TempInvProfileTrack."Surplus Type"::FixedOrderQty:
                                            UntrackedPlanningElement."Parameter Value" := SKU."Reorder Quantity";
                                        TempInvProfileTrack."Surplus Type"::MaxInventory:
                                            UntrackedPlanningElement."Parameter Value" := SKU."Maximum Inventory";
                                    end;
                                end else
                                    OrderSizeParticipated := false
                            end;
                        4:
                            // Maximum Order
                            if OrderSizeParticipated then begin
                                UntrackedPlanningElement."Untracked Quantity" := TempInvProfileTrack."Quantity Tracked";
                                UntrackedPlanningElement."Parameter Value" := SKU."Maximum Order Quantity";
                            end;
                        5:
                            begin
                                // Minimum Order
                                QtyMin := TempInvProfileTrack."Quantity Tracked";
                                if QtyTracked < QtyMin then
                                    UntrackedPlanningElement."Untracked Quantity" := QtyMin - QtyTracked;
                                UntrackedPlanningElement."Parameter Value" := SKU."Minimum Order Quantity";
                            end;
                        6:
                            begin
                                // Rounding
                                QtyRound := SKU."Order Multiple"
                                  - Round(SupplyInvProfile."Quantity (Base)", SKU."Order Multiple", '>')
                                  + SupplyInvProfile."Quantity (Base)";
                                if QtyRound > TempInvProfileTrack."Quantity Tracked" then
                                    QtyRound := TempInvProfileTrack."Quantity Tracked";
                                if QtyRound > QtyRemaining then
                                    QtyRound := QtyRemaining;
                                UntrackedPlanningElement."Untracked Quantity" := QtyRound;
                                UntrackedPlanningElement."Parameter Value" := SKU."Order Multiple";
                            end;
                        7:
                            begin
                                // Dampener
                                DampenerQty := TempInvProfileTrack."Quantity Tracked";
                                if DampenerQty < QtyRemaining then
                                    UntrackedPlanningElement."Untracked Quantity" := DampenerQty
                                else
                                    UntrackedPlanningElement."Untracked Quantity" := QtyRemaining;
                                UntrackedPlanningElement."Parameter Value" := DampenerQty;
                            end;
                    end;
                    if (UntrackedPlanningElement."Untracked Quantity" <> 0) or
                       (TempInvProfileTrack."Surplus Type" = TempInvProfileTrack."Surplus Type"::ReorderPoint) or
                       (TempInvProfileTrack."Warning Level" > 0)
                    then begin
                        UntrackedPlanningElement."Track Line No." += 1;
                        UntrackedPlanningElement."Item No." := SupplyInvProfile."Item No.";
                        UntrackedPlanningElement."Variant Code" := SupplyInvProfile."Variant Code";
                        UntrackedPlanningElement."Location Code" := SupplyInvProfile."Location Code";
                        UntrackedPlanningElement."Source Type" := TempInvProfileTrack."Source Type";
                        UntrackedPlanningElement."Source ID" := TempInvProfileTrack."Source ID";
                        UntrackedPlanningElement.Source := ShowSurplusReason(TempInvProfileTrack."Surplus Type");
                        QtyTracked += UntrackedPlanningElement."Untracked Quantity";
                        QtyRemaining -= UntrackedPlanningElement."Untracked Quantity";
                        UntrackedPlanningElement."Track Quantity To" := QtyRemaining;
                        TransferWarningSourceText(TempInvProfileTrack, UntrackedPlanningElement);
                        IsHandled := false;
                        OnPublishSurplusOnBeforePlanningElementInsert(UntrackedPlanningElement, IsHandled, TempInvProfileTrack);
                        if not IsHandled then
                            UntrackedPlanningElement.Insert();
                    end;
                    TempInvProfileTrack.SetRange(TempInvProfileTrack.Priority);
                    TempInvProfileTrack.SetRange(TempInvProfileTrack."Demand Line No.");
                until (TempInvProfileTrack.Next() = 0);

            if QtyRemaining > 0 then begin
                // just in case that something by accident has not been captured
                UntrackedPlanningElement.Init();
                UntrackedPlanningElement."Track Line No." += 1;
                UntrackedPlanningElement."Item No." := SupplyInvProfile."Item No.";
                UntrackedPlanningElement."Variant Code" := SupplyInvProfile."Variant Code";
                UntrackedPlanningElement."Location Code" := SupplyInvProfile."Location Code";
                UntrackedPlanningElement.Source := ShowSurplusReason(TempInvProfileTrack."Surplus Type"::Undefined);
                UntrackedPlanningElement."Track Quantity From" := QtyRemaining;
                UntrackedPlanningElement."Untracked Quantity" := QtyRemaining;
                QtyTracked += UntrackedPlanningElement."Untracked Quantity";
                QtyRemaining -= UntrackedPlanningElement."Untracked Quantity";
                UntrackedPlanningElement."Track Quantity To" := QtyRemaining;
                IsHandled := false;
                OnPublishSurplusOnBeforeExceptionPlanningElementInsert(UntrackedPlanningElement, IsHandled);
                if not IsHandled then
                    UntrackedPlanningElement.Insert();
            end;
        end;
        TempInvProfileTrack.SetRange("Line No.");
        TempInvProfileTrack.SetRange("Warning Level");
        CleanLog(SupplyInvProfile."Line No.");

        OnAfterPublishSurplus(SupplyInvProfile, SKU, ReqLine, ReservEntry);
    end;

    local procedure SurplusQty(var ReqLine: Record "Requisition Line"; var ReservEntry: Record "Reservation Entry"): Decimal
    var
        CrntReservEntry: Record "Reservation Entry";
        QtyTracked1: Decimal;
        QtyTracked2: Decimal;
    begin
        CrntReservEntry.Copy(ReservEntry);
        ReservEntry.InitSortingAndFilters(false);
        ReqLine.SetReservationFilters(ReservEntry);
        ReservEntry.SetRange("Reservation Status", "Reservation Status"::Surplus);
        ReservEntry.CalcSums("Quantity (Base)");
        QtyTracked1 := ReservEntry."Quantity (Base)";

        ReservEntry.Reset();
        if ReqLine."Action Message".AsInteger() > ReqLine."Action Message"::New.AsInteger() then begin
            case ReqLine."Ref. Order Type" of
                ReqLine."Ref. Order Type"::Purchase:
                    begin
                        ReservEntry.SetRange("Source ID", ReqLine."Ref. Order No.");
                        ReservEntry.SetRange("Source Ref. No.", ReqLine."Ref. Line No.");
                        ReservEntry.SetRange("Source Type", Database::"Purchase Line");
                        ReservEntry.SetRange("Source Subtype", 1);
                    end;
                ReqLine."Ref. Order Type"::Transfer:
                    begin
                        ReservEntry.SetRange("Source ID", ReqLine."Ref. Order No.");
                        ReservEntry.SetRange("Source Ref. No.", ReqLine."Ref. Line No.");
                        ReservEntry.SetRange("Source Type", Database::"Transfer Line");
                        ReservEntry.SetRange("Source Subtype", 1); // Inbound
                        ReservEntry.SetRange("Source Prod. Order Line", 0);
                    end;
                else
                    OnSurplusQtyOnSetReservEntryFilters(ReservEntry, ReqLine);
            end;
            ReservEntry.SetRange("Reservation Status", ReservEntry."Reservation Status"::Surplus);
            ReservEntry.CalcSums("Quantity (Base)");
            QtyTracked2 := ReservEntry."Quantity (Base)";
            ReservEntry.Reset();
        end;
        ReservEntry.Copy(CrntReservEntry);
        exit(QtyTracked1 + QtyTracked2);
    end;

    local procedure ShowSurplusReason(SurplusType: Enum "Planning Surplus Type") ReturnText: Text[50]
    begin
        case SurplusType of
            SurplusType::Forecast:
                ReturnText := Text001;
            SurplusType::BlanketOrder:
                ReturnText := Text002;
            SurplusType::SafetyStock:
                ReturnText := Text003;
            SurplusType::ReorderPoint:
                ReturnText := Text004;
            SurplusType::MaxInventory:
                ReturnText := Text005;
            SurplusType::FixedOrderQty:
                ReturnText := Text006;
            SurplusType::MaxOrder:
                ReturnText := Text007;
            SurplusType::MinOrder:
                ReturnText := Text008;
            SurplusType::OrderMultiple:
                ReturnText := Text009;
            SurplusType::DampenerQty:
                ReturnText := Text010;
            SurplusType::EmergencyOrder:
                ReturnText := Text011;
            else
                ReturnText := Text000;
        end;

        OnAfterShowSurplusReason(SurplusType.AsInteger(), ReturnText);
    end;

    procedure SetCurrReqLine(var CurrentReqLine: Record "Requisition Line")
    begin
        CurrReqLine := CurrentReqLine;
    end;

    procedure DrillDownUntrackedQty(CaptionText: Text)
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
        SurplusTrackForm: Page "Untracked Planning Elements";
    begin
        if not (CurrReqLine."Planning Line Origin" <> CurrReqLine."Planning Line Origin"::" ") then
            exit;

        UntrackedPlanningElement.SetRange("Worksheet Template Name", CurrReqLine."Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", CurrReqLine."Journal Batch Name");
        UntrackedPlanningElement.SetRange("Worksheet Line No.", CurrReqLine."Line No.");

        SurplusTrackForm.SetTableView(UntrackedPlanningElement);
        SurplusTrackForm.SetCaption(CaptionText);
        SurplusTrackForm.RunModal();
    end;

    procedure ReqLineWarningLevel(ReqLine: Record "Requisition Line") WarningLevel: Integer
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        UntrackedPlanningElement.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
        UntrackedPlanningElement.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
        UntrackedPlanningElement.SetRange("Worksheet Line No.", ReqLine."Line No.");
        UntrackedPlanningElement.SetFilter("Warning Level", '>%1', 0);
        UntrackedPlanningElement.SetLoadFields("Warning Level");
        UntrackedPlanningElement.SetCurrentKey("Warning Level");
        if UntrackedPlanningElement.FindFirst() then
            WarningLevel := UntrackedPlanningElement."Warning Level";
    end;

    procedure LogWarning(SupplyLineNo: Integer; ReqLine: Record "Requisition Line"; WarningLevel: Option; Source: Text[200]): Boolean
    var
        UntrackedPlanningElement: Record "Untracked Planning Element";
    begin
        if SupplyLineNo = 0 then begin
            UntrackedPlanningElement.SetRange("Worksheet Template Name", ReqLine."Worksheet Template Name");
            UntrackedPlanningElement.SetRange("Worksheet Batch Name", ReqLine."Journal Batch Name");
            UntrackedPlanningElement.SetRange("Worksheet Line No.", ReqLine."Line No.");
            if not UntrackedPlanningElement.FindLast() then begin
                UntrackedPlanningElement."Worksheet Template Name" := ReqLine."Worksheet Template Name";
                UntrackedPlanningElement."Worksheet Batch Name" := ReqLine."Journal Batch Name";
                UntrackedPlanningElement."Worksheet Line No." := ReqLine."Line No.";
            end;

            UntrackedPlanningElement.Init();
            UntrackedPlanningElement."Track Line No." += 1;
            UntrackedPlanningElement.Source := Source;
            UntrackedPlanningElement."Warning Level" := WarningLevel;
            UntrackedPlanningElement.Insert();
        end else begin
            TempInvProfileTrack.Init();
            TempInvProfileTrack."Line No." := SupplyLineNo;
            TempInvProfileTrack.Priority := 10;
            TempInvProfileTrack."Sequence No." := GetSequenceNo();
            TempInvProfileTrack."Demand Line No." := 0;
            TempInvProfileTrack."Surplus Type" := TempInvProfileTrack."Surplus Type"::None;
            TempInvProfileTrack."Source Type" := 0;
            TempInvProfileTrack."Source ID" := '';
            TempInvProfileTrack."Quantity Tracked" := 0;
            TempInvProfileTrack."Warning Level" := WarningLevel;
            TempInvProfileTrack.Insert();
            TempPlanningWarning.Init();
            TempPlanningWarning."Worksheet Template Name" := '';
            TempPlanningWarning."Worksheet Batch Name" := '';
            TempPlanningWarning."Worksheet Line No." := SupplyLineNo;
            TempPlanningWarning."Track Line No." := TempInvProfileTrack."Sequence No.";
            TempPlanningWarning.Source := Source;
            TempPlanningWarning.Insert();
        end;
        exit(true);
    end;

    local procedure TransferWarningSourceText(FromInvProfileTrack: Record "Inventory Profile Track Buffer" temporary; var ToUntrackedPlanningElement: Record "Untracked Planning Element")
    begin
        if FromInvProfileTrack."Warning Level" = 0 then
            exit;
        if TempPlanningWarning.Get('', '', FromInvProfileTrack."Line No.", FromInvProfileTrack."Sequence No.") then begin
            OnTransferWarningSourceTextOnBeforeSetSourceToUntrackedPlanningElement(ToUntrackedPlanningElement, TempPlanningWarning);
            ToUntrackedPlanningElement.Source := TempPlanningWarning.Source;
            TempPlanningWarning.Delete();
        end;
    end;

    local procedure GetSequenceNo(): Integer
    begin
        SequenceNo := SequenceNo + 1;
        exit(SequenceNo);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterShowSurplusReason(SurplusType: Integer; var ReturnText: Text[50])
    begin
    end;

#if not CLEAN26
    [Obsolete('Replaced by event OnBeforeGetSurplusType', '26.0')]
    [IntegrationEvent(false, false)]
    local procedure OnBeforeFindReason(var DemandInvProfile: Record "Inventory Profile"; var Result: Integer; var IsHandled: Boolean)
    begin
    end;
#endif

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGetSurplusType(var DemandInvProfile: Record "Inventory Profile"; var Result: Enum "Planning Surplus Type"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSurplusOnCaseSurplusTypeElse(SupplyLineNo: Integer; DemandLineNo: Integer; SourceType: Integer; SourceID: Code[20]; Qty: Decimal; SurplusType: Integer; var Priority: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPublishSurplusOnBeforePlanningElementInsert(var UntrackedPlanningElement: Record "Untracked Planning Element"; var IsHandled: Boolean; TempInventoryProfileTrackBuffer: Record "Inventory Profile Track Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPublishSurplusOnBeforeExceptionPlanningElementInsert(var UntrackedPlanningElement: Record "Untracked Planning Element"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPublishSurplus(var InventoryProfile: Record "Inventory Profile"; var StockkeepingUnit: Record "Stockkeeping Unit"; var RequisitionLine: Record "Requisition Line"; var ReservationEntry: Record "Reservation Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLogSurplusOnBeforeInsertTempInvProfileTrack(var TempInventoryProfileTrackBuffer: Record "Inventory Profile Track Buffer" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSurplusQtyOnSetReservEntryFilters(var ReservEntry: Record "Reservation Entry"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnFindReasonOnAfterSetSurplusType(var DemandInventoryProfile: Record "Inventory Profile"; var SurplusType: Enum "Planning Surplus Type")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferWarningSourceTextOnBeforeSetSourceToUntrackedPlanningElement(var ToUntrackedPlanningElement: Record "Untracked Planning Element"; var TempUntrackedPlanningElement: Record "Untracked Planning Element" temporary)
    begin
    end;
}

