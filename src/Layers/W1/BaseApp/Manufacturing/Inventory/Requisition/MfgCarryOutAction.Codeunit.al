// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Inventory.Item;
using Microsoft.Foundation.Navigate;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Tracking;
using Microsoft.Manufacturing.Document;
using Microsoft.Manufacturing.Setup;
using Microsoft.Manufacturing.ProductionBOM;
using Microsoft.Manufacturing.WorkCenter;
using Microsoft.Manufacturing.MachineCenter;
using Microsoft.Manufacturing.Routing;

codeunit 99000818 "Mfg. Carry Out Action"
{
    Permissions = TableData "Prod. Order Capacity Need" = rid;

    var
#if not CLEAN27
        CarryOutAction: Codeunit "Carry Out Action";
#endif
        CalculateProdOrder: Codeunit "Calculate Prod. Order";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        PrintOrder: Boolean;
        CouldNotChangeSupplyTxt: Label 'The supply type could not be changed in order %1, order line %2.', Comment = '%1 - Production Order No. or Assembly Header No. or Purchase Header No., %2 - Production Order Line or Assembly Line No. or Purchase Line No.';
        ProdBomErr: Label 'The maximum number of BOM levels %1, was exceeded. The process stopped at %2 %3.', Comment = '%1 = max number of levels; %2 = BOM Type; %3 = BOM No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnTrySourceTypeForProduction', '', false, false)]
    local procedure OnTrySourceType(var RequisitionLine: Record "Requisition Line"; TryChoice: Option; TryWkshTempl: Code[10]; TryWkshName: Code[10]; var ProductionExist: Boolean; var TempDocumentEntry: Record "Document Entry" temporary; sender: Codeunit "Carry Out Action")
    begin
        ProductionExist := CarryOutActionsFromProdOrder(RequisitionLine, Enum::"Planning Create Prod. Order".FromInteger(TryChoice), TryWkshTempl, TryWkshName, TempDocumentEntry, sender);
    end;

    procedure CarryOutActionsFromProdOrder(RequisitionLine: Record "Requisition Line"; ProdOrderChoice: Enum "Planning Create Prod. Order"; ProdWkshTempl: Code[10]; ProdWkshName: Code[10]; var TempDocumentEntry: Record "Document Entry" temporary; var sender: Codeunit "Carry Out Action"): Boolean
    begin
        PrintOrder := ProdOrderChoice = ProdOrderChoice::"Firm Planned & Print";
        OnCarryOutActionsFromProdOrderOnAfterCalcPrintOrder(PrintOrder, ProdOrderChoice.AsInteger());
#if not CLEAN27
        CarryOutAction.RunOnCarryOutActionsFromProdOrderOnAfterCalcPrintOrder(PrintOrder, ProdOrderChoice.AsInteger());
#endif

        case RequisitionLine."Action Message" of
            RequisitionLine."Action Message"::New:
                if ProdOrderChoice = ProdOrderChoice::"Copy to Req. Wksh" then
                    sender.CarryOutToReqWksh(RequisitionLine, ProdWkshTempl, ProdWkshName)
                else
                    InsertProductionOrder(RequisitionLine, ProdOrderChoice, TempDocumentEntry);
            RequisitionLine."Action Message"::"Change Qty.",
          RequisitionLine."Action Message"::Reschedule,
          RequisitionLine."Action Message"::"Resched. & Chg. Qty.":
                exit(ProdOrderChgAndReshedule(RequisitionLine));
            RequisitionLine."Action Message"::Cancel:
                DeleteProdOrderLines(RequisitionLine);
        end;
        exit(true);
    end;

    procedure ProdOrderChgAndReshedule(RequisitionLine: Record "Requisition Line"): Boolean
    var
        ProdOrderLine: Record "Prod. Order Line";
        PlanningComponent: Record "Planning Component";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderComponent: Record "Prod. Order Component";
        ProductionOrder: Record "Production Order";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        MfgReservCheckDateConfl: Codeunit "Mfg. ReservCheckDateConfl";
    begin
        RequisitionLine.TestField(RequisitionLine."Ref. Order Type", RequisitionLine."Ref. Order Type"::"Prod. Order");
        ProdOrderLine.LockTable();
        if ProdOrderLine.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.") then begin
            ProdOrderCapacityNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
            ProdOrderCapacityNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            ProdOrderCapacityNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            ProdOrderCapacityNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            ProdOrderCapacityNeed.DeleteAll();
            ProdOrderLine.BlockDynamicTracking(true);
            ProdOrderLine.Validate(Quantity, RequisitionLine.Quantity);
            OnProdOrderChgAndResheduleOnAfterValidateQuantity(ProdOrderLine, RequisitionLine);
#if not CLEAN27
            CarryOutAction.RunOnProdOrderChgAndResheduleOnAfterValidateQuantity(ProdOrderLine, RequisitionLine);
#endif
            ProdOrderLine."Ending Time" := RequisitionLine."Ending Time";
            ProdOrderLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            ProdOrderLine.Validate("Ending Date", RequisitionLine."Ending Date");
            ProdOrderLine."Due Date" := RequisitionLine."Due Date";
            ProdOrderLine.Modify();
            ProdOrderLineReserve.TransferPlanningLineToPOLine(RequisitionLine, ProdOrderLine, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(ProdOrderLine);
            ReservationManagement.DeleteReservEntries(false, ProdOrderLine."Remaining Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
            PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            if PlanningComponent.Find('-') then
                repeat
                    if ProdOrderComponent.Get(
                            ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.", PlanningComponent."Line No.")
                    then begin
                        ProdOrderCompReserve.TransferPlanningCompToPOComp(PlanningComponent, ProdOrderComponent, 0, true);
                        PlngComponentReserve.UpdateDerivedTracking(PlanningComponent);
                        ReservationManagement.SetReservSource(ProdOrderComponent);
                        ReservationManagement.DeleteReservEntries(false, ProdOrderComponent."Remaining Qty. (Base)");
                        ReservationManagement.ClearSurplus();
                        ReservationManagement.AutoTrack(ProdOrderComponent."Remaining Qty. (Base)");
                        MfgReservCheckDateConfl.ProdOrderComponentCheck(ProdOrderComponent, false, false);
                    end else
                        PlanningComponent.Delete(true);
                until PlanningComponent.Next() = 0;

            if RequisitionLine."Planning Level" = 0 then
                if ProductionOrder.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then begin
                    ProductionOrder.Quantity := RequisitionLine.Quantity;
                    ProductionOrder."Starting Time" := RequisitionLine."Starting Time";
                    ProductionOrder."Starting Date" := RequisitionLine."Starting Date";
                    ProductionOrder."Ending Time" := RequisitionLine."Ending Time";
                    ProductionOrder."Ending Date" := RequisitionLine."Ending Date";
                    ProductionOrder."Due Date" := RequisitionLine."Due Date";
                    OnProdOrderChgAndResheduleOnBeforeProdOrderModify(ProductionOrder, ProdOrderLine, RequisitionLine);
#if not CLEAN27
                    CarryOutAction.RunOnProdOrderChgAndResheduleOnBeforeProdOrderModify(ProductionOrder, ProdOrderLine, RequisitionLine);
#endif
                    ProductionOrder.Modify();
                    FinalizeOrderHeader(ProductionOrder);
                end;
            OnAfterProdOrderChgAndReshedule(RequisitionLine, ProdOrderLine);
#if not CLEAN27
            CarryOutAction.RunOnAfterProdOrderChgAndReshedule(RequisitionLine, ProdOrderLine);
#endif
        end else begin
            Message(StrSubstNo(CouldNotChangeSupplyTxt, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No."));
            exit(false);
        end;
        exit(true);
    end;

    procedure InsertProductionOrder(RequisitionLine: Record "Requisition Line"; ProdOrderChoice: Enum "Planning Create Prod. Order"; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        ManufacturingSetup: Record "Manufacturing Setup";
        Item: Record Item;
        ProductionOrder: Record "Production Order";
        CreateProdOrderLines: Codeunit "Create Prod. Order Lines";
        Direction: Option Forward,Backward;
        HeaderExist: Boolean;
        IsHandled: Boolean;
    begin
        Item.Get(RequisitionLine."No.");
        ManufacturingSetup.Get();
        if FindTempProdOrder(RequisitionLine, TempDocumentEntry) then
            HeaderExist := ProductionOrder.Get(TempDocumentEntry."Document Type", TempDocumentEntry."Document No.");

        OnInsertProdOrderOnAfterFindTempProdOrder(RequisitionLine, ProductionOrder, HeaderExist, Item);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderOnAfterFindTempProdOrder(RequisitionLine, ProductionOrder, HeaderExist, Item);
#endif

        if not HeaderExist then begin
            case ProdOrderChoice of
                ProdOrderChoice::Planned:
                    ManufacturingSetup.TestField("Planned Order Nos.");
                ProdOrderChoice::"Firm Planned",
                ProdOrderChoice::"Firm Planned & Print":
                    ManufacturingSetup.TestField("Firm Planned Order Nos.");
                else
                    OnInsertProductionOrderOnProdOrderChoiceCaseElse(ProdOrderChoice);
            end;

            OnInsertProdOrderOnBeforeProdOrderInit(RequisitionLine);
#if not CLEAN27
            CarryOutAction.RunOnInsertProdOrderOnBeforeProdOrderInit(RequisitionLine);
#endif

            Item.CheckItemAndVariantForProdBlocked(RequisitionLine."No.", RequisitionLine."Variant Code", Item."Production Blocked"::Output);
            ProductionOrder.Init();
            if ProdOrderChoice = ProdOrderChoice::"Firm Planned & Print" then
                ProductionOrder.Status := ProductionOrder.Status::"Firm Planned"
            else begin
                IsHandled := false;
                OnInsertProdOrderOnProdOrderChoiceNotFirmPlannedPrint(ProductionOrder, ProdOrderChoice, IsHandled);
#if not CLEAN27
                CarryOutAction.RunOnInsertProdOrderOnProdOrderChoiceNotFirmPlannedPrint(ProductionOrder, ProdOrderChoice, IsHandled);
#endif
                if not IsHandled then
                    ProductionOrder.Status := Enum::"Production Order Status".FromInteger(ProdOrderChoice.AsInteger());
            end;
            ProductionOrder."No. Series" := ProductionOrder.GetNoSeriesCode();
            if ProductionOrder."No. Series" = RequisitionLine."No. Series" then
                ProductionOrder."No." := RequisitionLine."Ref. Order No.";
            OnInsertProdOrderOnBeforeProdOrderInsert(ProductionOrder, RequisitionLine);
#if not CLEAN27
            CarryOutAction.RunOnInsertProdOrderOnBeforeProdOrderInsert(ProductionOrder, RequisitionLine);
#endif
            ProductionOrder.Insert(true);
            OnInsertProdOrderOnAfterProdOrderInsert(ProductionOrder, RequisitionLine);
#if not CLEAN27
            CarryOutAction.RunOnInsertProdOrderOnAfterProdOrderInsert(ProductionOrder, RequisitionLine);
#endif
            ProductionOrder."Source Type" := ProductionOrder."Source Type"::Item;
            ProductionOrder."Source No." := RequisitionLine."No.";
            ProductionOrder.Validate(Description, RequisitionLine.Description);
            ProductionOrder."Description 2" := RequisitionLine."Description 2";
            ProductionOrder."Variant Code" := RequisitionLine."Variant Code";
            ProductionOrder."Creation Date" := Today;
            ProductionOrder."Last Date Modified" := Today;
            ProductionOrder."Inventory Posting Group" := Item."Inventory Posting Group";
            ProductionOrder."Gen. Prod. Posting Group" := RequisitionLine."Gen. Prod. Posting Group";
            ProductionOrder."Due Date" := RequisitionLine."Due Date";
            ProductionOrder."Starting Time" := RequisitionLine."Starting Time";
            ProductionOrder."Starting Date" := RequisitionLine."Starting Date";
            ProductionOrder."Ending Time" := RequisitionLine."Ending Time";
            ProductionOrder."Ending Date" := RequisitionLine."Ending Date";
            ProductionOrder."Location Code" := RequisitionLine."Location Code";
            ProductionOrder."Bin Code" := RequisitionLine."Bin Code";
            ProductionOrder."Low-Level Code" := RequisitionLine."Low-Level Code";
            ProductionOrder."Routing No." := RequisitionLine."Routing No.";
            ProductionOrder.Quantity := RequisitionLine.Quantity;
            ProductionOrder."Unit Cost" := RequisitionLine."Unit Cost";
            ProductionOrder."Cost Amount" := RequisitionLine."Cost Amount";
            ProductionOrder."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
            ProductionOrder."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
            ProductionOrder."Dimension Set ID" := RequisitionLine."Dimension Set ID";
            ProductionOrder.UpdateDatetime();
            OnInsertProdOrderWithReqLine(ProductionOrder, RequisitionLine);
#if not CLEAN27
            CarryOutAction.RunOnInsertProdOrderWithReqLine(ProductionOrder, RequisitionLine);
#endif
            ProductionOrder.Modify();
            InsertTempProdOrder(RequisitionLine, ProductionOrder, TempDocumentEntry);
        end;
        InsertProdOrderLine(RequisitionLine, ProductionOrder, Item);

        if CheckProductionOrderForStructure(ProductionOrder) then
            CreateProdOrderLines.CheckStructure(ProductionOrder.Status.AsInteger(), ProductionOrder."No.", Direction::Backward, true, false);

        OnAfterInsertProdOrder(ProductionOrder, ProdOrderChoice.AsInteger(), RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnAfterInsertProdOrder(ProductionOrder, ProdOrderChoice.AsInteger(), RequisitionLine);
#endif
    end;

    procedure InsertProdOrderLine(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; Item: Record Item)
    var
        ProdOrderLine: Record "Prod. Order Line";
        NextLineNo: Integer;
    begin
        Item.CheckItemAndVariantForProdBlocked(RequisitionLine."No.", RequisitionLine."Variant Code", Item."Production Blocked"::Output);

        ProdOrderLine.SetRange("Prod. Order No.", ProductionOrder."No.");
        ProdOrderLine.SetRange(Status, ProductionOrder.Status);
        ProdOrderLine.LockTable();
        if ProdOrderLine.FindLast() then
            NextLineNo := ProdOrderLine."Line No." + 10000
        else
            NextLineNo := 10000;

        OnInsertProdOrderLineOnBeforeProdOrderLineInit(RequisitionLine, Item);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderLineOnBeforeProdOrderLineInit(RequisitionLine, Item);
#endif
        ProdOrderLine.Init();
        ProdOrderLine.BlockDynamicTracking(true);
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Prod. Order No." := ProductionOrder."No.";
        ProdOrderLine."Line No." := NextLineNo;
        ProdOrderLine."Item No." := RequisitionLine."No.";
        ProdOrderLine.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        ProdOrderLine."Production BOM Version Code" := RequisitionLine."Production BOM Version Code";
        ProdOrderLine."Routing Version Code" := RequisitionLine."Routing Version Code";
        ProdOrderLine."Routing Type" := RequisitionLine."Routing Type";
        ProdOrderLine."Routing Reference No." := ProdOrderLine."Line No.";
        ProdOrderLine.Description := RequisitionLine.Description;
        ProdOrderLine."Description 2" := RequisitionLine."Description 2";
        ProdOrderLine."Variant Code" := RequisitionLine."Variant Code";
        ProdOrderLine."Location Code" := RequisitionLine."Location Code";
        OnInsertProdOrderLineOnBeforeGetBinCode(ProdOrderLine, RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderLineOnBeforeGetBinCode(ProdOrderLine, RequisitionLine);
#endif
        if RequisitionLine."Bin Code" <> '' then
            ProdOrderLine.Validate("Bin Code", RequisitionLine."Bin Code")
        else
            CalculateProdOrder.SetProdOrderLineBinCodeFromRoute(ProdOrderLine, ProductionOrder."Location Code", ProductionOrder."Routing No.");
        ProdOrderLine."Scrap %" := RequisitionLine."Scrap %";
        ProdOrderLine."Production BOM No." := RequisitionLine."Production BOM No.";
        ProdOrderLine."Inventory Posting Group" := Item."Inventory Posting Group";
        OnInsertProdOrderLineOnBeforeValidateUnitCost(RequisitionLine, ProductionOrder, ProdOrderLine, Item);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderLineOnBeforeValidateUnitCost(RequisitionLine, ProductionOrder, ProdOrderLine, Item);
#endif
        ProdOrderLine.Validate("Unit Cost", RequisitionLine."Unit Cost");
        ProdOrderLine."Routing No." := RequisitionLine."Routing No.";
        ProdOrderLine."Starting Time" := RequisitionLine."Starting Time";
        ProdOrderLine."Starting Date" := RequisitionLine."Starting Date";
        ProdOrderLine."Ending Time" := RequisitionLine."Ending Time";
        ProdOrderLine."Ending Date" := RequisitionLine."Ending Date";
        ProdOrderLine."Due Date" := RequisitionLine."Due Date";
        ProdOrderLine.Status := ProductionOrder.Status;
        ProdOrderLine."Planning Level Code" := RequisitionLine."Planning Level";
        ProdOrderLine."Indirect Cost %" := RequisitionLine."Indirect Cost %";
        ProdOrderLine."Overhead Rate" := RequisitionLine."Overhead Rate";
        UpdateProdOrderLineQuantity(ProdOrderLine, RequisitionLine, Item);
        if not (ProductionOrder.Status = ProductionOrder.Status::Planned) then
            ProdOrderLine."Planning Flexibility" := RequisitionLine."Planning Flexibility";
        ProdOrderLine.UpdateDatetime();
        ProdOrderLine."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
        ProdOrderLine."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
        ProdOrderLine."Dimension Set ID" := RequisitionLine."Dimension Set ID";
        OnInsertProdOrderLineWithReqLine(ProdOrderLine, RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderLineWithReqLine(ProdOrderLine, RequisitionLine);
#endif
        ProdOrderLine.Insert();
        OnInsertProdOrderLineOnAfterProdOrderLineInsert(ProdOrderLine, RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderLineOnAfterProdOrderLineInsert(ProdOrderLine, RequisitionLine);
#endif
        CalculateProdOrder.CalculateProdOrderDates(ProdOrderLine, false);

        ProdOrderLineReserve.TransferPlanningLineToPOLine(RequisitionLine, ProdOrderLine, RequisitionLine."Net Quantity (Base)", false);
        if RequisitionLine.Reserve and not (ProdOrderLine.Status = ProdOrderLine.Status::Planned) then
            ReserveBindingOrderToProd(ProdOrderLine, RequisitionLine);

        OnInsertProdOrderLineOnBeforeModifyProdOrderLine(ProdOrderLine, RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnInsertProdOrderLineOnBeforeModifyProdOrderLine(ProdOrderLine, RequisitionLine);
#endif
        ProdOrderLine.Modify();
        SetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder, ProdOrderLine, RequisitionLine, Item);
        TransferBOM(RequisitionLine, ProductionOrder, ProdOrderLine."Line No.");
        TransferCapNeed(RequisitionLine, ProductionOrder, ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.");

        if ProdOrderLine."Planning Level Code" > 0 then
            UpdateComponentLink(ProdOrderLine);

        OnAfterInsertProdOrderLine(RequisitionLine, ProductionOrder, ProdOrderLine, Item);
#if not CLEAN27
        CarryOutAction.RunOnAfterInsertProdOrderLine(RequisitionLine, ProductionOrder, ProdOrderLine, Item);
#endif
    end;

    procedure ReserveBindingOrderToProd(var ProdOrderLine: Record "Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        ProdOrderLine.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)" >
           RequisitionLine."Demand Quantity (Base)"
        then begin
            ReservQty := RequisitionLine."Demand Quantity";
            ReservQtyBase := RequisitionLine."Demand Quantity (Base)";
        end else begin
            ReservQty := ProdOrderLine."Remaining Quantity" - ProdOrderLine."Reserved Quantity";
            ReservQtyBase := ProdOrderLine."Remaining Qty. (Base)" - ProdOrderLine."Reserved Qty. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::"Prod. Order Line", ProdOrderLine.Status.AsInteger(), ProdOrderLine."Prod. Order No.", '', ProdOrderLine."Line No.", 0,
            ProdOrderLine."Variant Code", ProdOrderLine."Location Code", ProdOrderLine."Qty. per Unit of Measure");

        RequisitionLine.ReserveBindingOrder(
            TrackingSpecification, ProdOrderLine.Description, ProdOrderLine."Ending Date", ReservQty, ReservQtyBase, true);

        ProdOrderLine.Modify();
    end;

    local procedure DeleteProdOrderLines(RequisitionLine: Record "Requisition Line")
    var
        ProductionOrder: Record "Production Order";
        ProdOrderLine: Record "Prod. Order Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteProdOrderLines(RequisitionLine, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeDeleteProdOrderLines(RequisitionLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Line No.");
        ProdOrderLine.SetFilter("Item No.", '<>%1', '');
        ProdOrderLine.SetRange(Status, RequisitionLine."Ref. Order Status");
        ProdOrderLine.SetRange("Prod. Order No.", RequisitionLine."Ref. Order No.");
        if ProdOrderLine.Count in [0, 1] then begin
            if ProductionOrder.Get(RequisitionLine."Ref. Order Status", RequisitionLine."Ref. Order No.") then
                ProductionOrder.Delete(true);
        end else begin
            ProdOrderLine.SetRange("Line No.", RequisitionLine."Ref. Line No.");
            if ProdOrderLine.FindFirst() then
                ProdOrderLine.Delete(true);
        end;
    end;

    local procedure SetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder: Record "Production Order"; var ProdOrderLine: Record "Prod. Order Line"; RequisitionLine: Record "Requisition Line"; Item: Record Item)
    var
        RefreshProdOrderLine: Boolean;
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeSetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder, ProdOrderLine, RequisitionLine, Item, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeSetProdOrderLineBinCodeFromPlanningRtngLines(ProductionOrder, ProdOrderLine, RequisitionLine, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        if TransferRouting(RequisitionLine, ProductionOrder, ProdOrderLine."Routing No.", ProdOrderLine."Routing Reference No.") then begin
            RefreshProdOrderLine := false;
            OnInsertProdOrderLineOnAfterTransferRouting(ProdOrderLine, RefreshProdOrderLine);
#if not CLEAN27
            CarryOutAction.RunOnInsertProdOrderLineOnAfterTransferRouting(ProdOrderLine, RefreshProdOrderLine);
#endif
            if RefreshProdOrderLine then
                ProdOrderLine.Get(ProdOrderLine.Status, ProdOrderLine."Prod. Order No.", ProdOrderLine."Line No.");
            CalculateProdOrder.SetProdOrderLineBinCodeFromPlanningRtngLines(ProdOrderLine, RequisitionLine);
            ProdOrderLine.Modify();
        end;
    end;

    local procedure UpdateProdOrderLineQuantity(var ProdOrderLine: Record "Prod. Order Line"; RequisitionLine: Record "Requisition Line"; Item: Record Item)
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateProdOrderLineQuantity(ProdOrderLine, RequisitionLine, Item, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeUpdateProdOrderLineQuantity(ProdOrderLine, RequisitionLine, Item, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderLine.Validate(Quantity, RequisitionLine.Quantity);
    end;

    local procedure FinalizeOrderHeader(ProductionOrder: Record "Production Order")
    var
        MfgCarryOutActionPrint: Codeunit "Mfg. Carry Out Action Print";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeFinalizeOrderHeader(ProductionOrder, PrintOrder, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeFinalizeOrderHeader(ProductionOrder, PrintOrder, IsHandled);
#endif
        if IsHandled then
            exit;

        if PrintOrder then
            MfgCarryOutActionPrint.PrintProdOrder(ProductionOrder);
    end;

    procedure TransferRouting(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; RoutingRefNo: Integer): Boolean
    var
        WorkCenter: Record "Work Center";
        MachineCenter: Record "Machine Center";
        PlanningRoutingLine: Record "Planning Routing Line";
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
        ProdOrderWarehouseMgt: Codeunit "Prod. Order Warehouse Mgt.";
        FlushingMethod: Enum "Flushing Method Routing";
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningRoutingLine.Find('-') then
            repeat
                ProdOrderRoutingLine.Init();
                ProdOrderRoutingLine.Status := ProductionOrder.Status;
                ProdOrderRoutingLine."Prod. Order No." := ProductionOrder."No.";
                ProdOrderRoutingLine."Routing No." := RoutingNo;
                ProdOrderRoutingLine."Routing Reference No." := RoutingRefNo;
                ProdOrderRoutingLine.CopyFromPlanningRoutingLine(PlanningRoutingLine);
                case ProdOrderRoutingLine.Type of
                    ProdOrderRoutingLine.Type::"Work Center":
                        begin
                            WorkCenter.Get(PlanningRoutingLine."No.");
                            ProdOrderRoutingLine."Flushing Method" := WorkCenter."Flushing Method";
                        end;
                    ProdOrderRoutingLine.Type::"Machine Center":
                        begin
                            MachineCenter.Get(ProdOrderRoutingLine."No.");
                            ProdOrderRoutingLine."Flushing Method" := MachineCenter."Flushing Method";
                        end;
                end;
                ProdOrderRoutingLine."Location Code" := RequisitionLine."Location Code";
                ProdOrderRoutingLine."From-Production Bin Code" :=
                  ProdOrderWarehouseMgt.GetProdCenterBinCode(
                    PlanningRoutingLine.Type, PlanningRoutingLine."No.", RequisitionLine."Location Code", false, Enum::"Flushing Method"::Manual);

                FlushingMethod := ProdOrderRoutingLine."Flushing Method";
                if ProdOrderRoutingLine."Flushing Method" = ProdOrderRoutingLine."Flushing Method"::Manual then
                    ProdOrderRoutingLine."To-Production Bin Code" :=
                        ProdOrderWarehouseMgt.GetProdCenterBinCode(
                            PlanningRoutingLine.Type, PlanningRoutingLine."No.", RequisitionLine."Location Code", true,
                            FlushingMethod)
                else
                    ProdOrderRoutingLine."Open Shop Floor Bin Code" :=
                        ProdOrderWarehouseMgt.GetProdCenterBinCode(
                            PlanningRoutingLine.Type, PlanningRoutingLine."No.", RequisitionLine."Location Code", true,
                            FlushingMethod);

                ProdOrderRoutingLine.UpdateDatetime();
                OnAfterTransferPlanningRtngLine(PlanningRoutingLine, ProdOrderRoutingLine);
#if not CLEAN27
                CarryOutAction.RunOnAfterTransferPlanningRtngLine(PlanningRoutingLine, ProdOrderRoutingLine);
#endif
                ProdOrderRoutingLine.Insert();
                OnAfterProdOrderRtngLineInsert(ProdOrderRoutingLine, PlanningRoutingLine, ProductionOrder, RequisitionLine);
#if not CLEAN27
                CarryOutAction.RunOnAfterProdOrderRtngLineInsert(ProdOrderRoutingLine, PlanningRoutingLine, ProductionOrder, RequisitionLine);
#endif
                CalculateProdOrder.TransferTaskInfo(ProdOrderRoutingLine, RequisitionLine."Routing Version Code");
            until PlanningRoutingLine.Next() = 0;

        exit(not PlanningRoutingLine.IsEmpty);
    end;

    procedure TransferBOM(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; ProdOrderLineNo: Integer)
    var
        PlanningComponent: Record "Planning Component";
        ProdOrderComponent2: Record "Prod. Order Component";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferBOM(RequisitionLine, ProductionOrder, ProdOrderLineNo, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeTransferBOM(RequisitionLine, ProductionOrder, ProdOrderLineNo, IsHandled);
#endif
        if IsHandled then
            exit;

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                OnTransferBOMOnBeforeProdOrderComp2Init(PlanningComponent);
#if not CLEAN27
                CarryOutAction.RunOnTransferBOMOnBeforeProdOrderComp2Init(PlanningComponent);
#endif
                ProdOrderComponent2.Init();
                ProdOrderComponent2.Status := ProductionOrder.Status;
                ProdOrderComponent2."Prod. Order No." := ProductionOrder."No.";
                ProdOrderComponent2."Prod. Order Line No." := ProdOrderLineNo;
                ProdOrderComponent2.CopyFromPlanningComp(PlanningComponent);
                ProdOrderComponent2.UpdateDatetime();
                OnAfterTransferPlanningComp(PlanningComponent, ProdOrderComponent2);
#if not CLEAN27
                CarryOutAction.RunOnAfterTransferPlanningComp(PlanningComponent, ProdOrderComponent2);
#endif
                ProdOrderComponent2.Insert();
                CopyProdBOMComments(ProdOrderComponent2);
                OnTransferBOMOnAfterCopyProdBOMComments(PlanningComponent, ProdOrderComponent2);
#if not CLEAN27
                CarryOutAction.RunOnTransferBOMOnAfterCopyProdBOMComments(PlanningComponent, ProdOrderComponent2);
#endif
                ProdOrderCompReserve.TransferPlanningCompToPOComp(PlanningComponent, ProdOrderComponent2, 0, true);
                if ProdOrderComponent2.Status in [ProdOrderComponent2.Status::"Firm Planned", ProdOrderComponent2.Status::Released] then
                    ProdOrderComponent2.AutoReserve();

                ReservationManagement.SetReservSource(ProdOrderComponent2);
                ReservationManagement.AutoTrack(ProdOrderComponent2."Remaining Qty. (Base)");
            until PlanningComponent.Next() = 0;
    end;

    procedure TransferCapNeed(RequisitionLine: Record "Requisition Line"; ProductionOrder: Record "Production Order"; RoutingNo: Code[20]; RoutingRefNo: Integer)
    var
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        NewProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeTransferCapNeed(RequisitionLine, ProductionOrder, RoutingNo, RoutingRefNo, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeTransferCapNeed(RequisitionLine, ProductionOrder, RoutingNo, RoutingRefNo, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderCapacityNeed.SetCurrentKey("Worksheet Template Name", "Worksheet Batch Name", "Worksheet Line No.");
        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if ProdOrderCapacityNeed.Find('-') then
            repeat
                NewProdOrderCapacityNeed.Init();
                NewProdOrderCapacityNeed := ProdOrderCapacityNeed;
                NewProdOrderCapacityNeed."Requested Only" := false;
                NewProdOrderCapacityNeed.Status := ProductionOrder.Status;
                NewProdOrderCapacityNeed."Prod. Order No." := ProductionOrder."No.";
                NewProdOrderCapacityNeed."Routing No." := RoutingNo;
                NewProdOrderCapacityNeed."Routing Reference No." := RoutingRefNo;
                NewProdOrderCapacityNeed."Worksheet Template Name" := '';
                NewProdOrderCapacityNeed."Worksheet Batch Name" := '';
                NewProdOrderCapacityNeed."Worksheet Line No." := 0;
                NewProdOrderCapacityNeed.UpdateDatetime();
                NewProdOrderCapacityNeed.Insert();
            until ProdOrderCapacityNeed.Next() = 0;
    end;

    procedure UpdateComponentLink(ProdOrderLine: Record "Prod. Order Line")
    var
        ProdOrderComponent: Record "Prod. Order Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeUpdateComponentLink(ProdOrderLine, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeUpdateComponentLink(ProdOrderLine, IsHandled);
#endif
        if IsHandled then
            exit;

        ProdOrderComponent.SetCurrentKey(Status, "Prod. Order No.", "Prod. Order Line No.", "Item No.");
        ProdOrderComponent.SetRange(Status, ProdOrderLine.Status);
        ProdOrderComponent.SetRange("Prod. Order No.", ProdOrderLine."Prod. Order No.");
        ProdOrderComponent.SetRange("Item No.", ProdOrderLine."Item No.");
        if ProdOrderComponent.Find('-') then
            repeat
                ProdOrderComponent."Supplied-by Line No." := ProdOrderLine."Line No.";
                ProdOrderComponent.Modify();
            until ProdOrderComponent.Next() = 0;
    end;

    local procedure CopyProdBOMComments(ProdOrderComponent: Record "Prod. Order Component")
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProdOrderLine: Record "Prod. Order Line";
    begin
        ProdOrderLine.Get(ProdOrderComponent.Status, ProdOrderComponent."Prod. Order No.", ProdOrderComponent."Prod. Order Line No.");

        if not ProductionBOMHeader.Get(ProdOrderLine."Production BOM No.") then
            exit;

        ProcessProductionBOMCommentsByType(ProductionBOMHeader."No.", ProdOrderComponent, 0);
    end;

    local procedure ProcessProductionBOMCommentsByType(ProductionBOMNo: Code[20]; ProdOrderComponent: Record "Prod. Order Component"; LoopCount: Integer)
    begin
        CopyItemTypeBOMComments(ProductionBOMNo, ProdOrderComponent);
        CopyNestedBOMComments(ProductionBOMNo, ProdOrderComponent, LoopCount + 1);
    end;

    local procedure CopyItemTypeBOMComments(ProductionBOMNo: Code[20]; ProdOrderComponent: Record "Prod. Order Component")
    var
        ProductionBOMLine: Record "Production BOM Line";
        ProductionBOMCommentLine: Record "Production BOM Comment Line";
        VersionManagement: Codeunit VersionManagement;
        ActiveVersionCode: Code[20];
    begin
        ActiveVersionCode := VersionManagement.GetBOMVersion(ProductionBOMNo, WorkDate(), true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMNo);
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::Item);
        ProductionBOMLine.SetRange("No.", ProdOrderComponent."Item No.");
        ProductionBOMLine.SetRange(Position, ProdOrderComponent.Position);
        ProductionBOMLine.SetRange("Version Code", ActiveVersionCode);
        if ProductionBOMLine.FindSet() then
            repeat
                ProductionBOMCommentLine.SetRange("Production BOM No.", ProductionBOMNo);
                ProductionBOMCommentLine.SetRange("BOM Line No.", ProductionBOMLine."Line No.");
                ProductionBOMCommentLine.SetRange("Version Code", ProductionBOMLine."Version Code");
                if ProductionBOMCommentLine.FindSet() then
                    repeat
                        InsertComponentCommentFromBOM(ProductionBOMCommentLine, ProdOrderComponent);
                    until ProductionBOMCommentLine.Next() = 0;
            until ProductionBOMLine.Next() = 0;
    end;

    local procedure CopyNestedBOMComments(ProductionBOMNo: Code[20]; ProdOrderComponent: Record "Prod. Order Component"; LoopCount: Integer)
    var
        ProductionBOMHeader: Record "Production BOM Header";
        ProductionBOMLine: Record "Production BOM Line";
        VersionManagement: Codeunit VersionManagement;
        ActiveVersionCode: Code[20];
    begin
        if not ProductionBOMHeader.Get(ProductionBOMNo) then
            exit;

        if LoopCount > 50 then
            Error(ProdBomErr, 50, ProductionBOMLine.Type::"Production BOM", ProductionBOMNo);

        ActiveVersionCode := VersionManagement.GetBOMVersion(ProductionBOMHeader."No.", WorkDate(), true);

        ProductionBOMLine.SetRange("Production BOM No.", ProductionBOMHeader."No.");
        ProductionBOMLine.SetRange(Type, ProductionBOMLine.Type::"Production BOM");
        ProductionBOMLine.SetRange(Position, ProdOrderComponent.Position);
        ProductionBOMLine.SetRange("Version Code", ActiveVersionCode);
        if ProductionBOMLine.FindSet() then
            repeat
                ProcessProductionBOMCommentsByType(ProductionBOMLine."No.", ProdOrderComponent, LoopCount);
            until ProductionBOMLine.Next() = 0;
    end;

    local procedure InsertComponentCommentFromBOM(ProductionBOMCommentLine: Record "Production BOM Comment Line"; ProdOrderComponent: Record "Prod. Order Component")
    var
        ProdOrderCompCmtLine: Record "Prod. Order Comp. Cmt Line";
    begin
        ProdOrderCompCmtLine.CopyFromProdBOMComponent(ProductionBOMCommentLine, ProdOrderComponent);
        if not ProdOrderCompCmtLine.Insert() then
            ProdOrderCompCmtLine.Modify();
    end;

    local procedure InsertTempProdOrder(var RequisitionLine: Record "Requisition Line"; var NewProductionOrder: Record "Production Order"; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.SetRange("Table ID", Database::"Production Order");
        TempDocumentEntry.SetRange("Document Type", NewProductionOrder.Status);
        TempDocumentEntry.SetRange("Document No.", NewProductionOrder."No.");
        if not TempDocumentEntry.IsEmpty() then
            exit;

        TempDocumentEntry.Reset();
        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::"Production Order";
        TempDocumentEntry."Document Type" := NewProductionOrder.Status;
        TempDocumentEntry."Document No." := NewProductionOrder."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();

        if RequisitionLine."Ref. Order Status" = RequisitionLine."Ref. Order Status"::Planned then begin
            TempDocumentEntry."Ref. Document No." := RequisitionLine."Ref. Order No.";
            TempDocumentEntry.Modify();
        end;

        if PrintOrder then
#if not CLEAN27
            if RequisitionLine."Ref. Order Status" in [RequisitionLine."Ref. Order Status"::Planned, RequisitionLine."Ref. Order Status"::"Firm Planned"] then begin
                OnCollectProdOrderForPrinting(NewProductionOrder);
                CarryOutAction.RunOnCollectProdOrderForPrinting(NewProductionOrder);
            end;
#else
            if RequisitionLine."Ref. Order Status" in [RequisitionLine."Ref. Order Status"::Planned, RequisitionLine."Ref. Order Status"::"Firm Planned"] then
                OnCollectProdOrderForPrinting(NewProductionOrder);
#endif
    end;

    local procedure FindTempProdOrder(var RequisitionLine: Record "Requisition Line"; var TempDocumentEntry: Record "Document Entry" temporary): Boolean
    begin
        if RequisitionLine."Ref. Order Status" = RequisitionLine."Ref. Order Status"::Planned then begin
            TempDocumentEntry.SetRange("Ref. Document No.", RequisitionLine."Ref. Order No.");
            exit(TempDocumentEntry.FindFirst());
        end;
    end;

    local procedure CheckProductionOrderForStructure(ProductionOrder: Record "Production Order"): Boolean
    var
        Item: Record Item;
    begin
        if not Item.Get(ProductionOrder."Source No.") then
            exit(false);

        if ProductionOrder."Variant Code" = '' then
            exit(false);

        if (Item."Replenishment System" = Item."Replenishment System"::"Prod. Order") and
            (Item."Manufacturing Policy" = Item."Manufacturing Policy"::"Make-to-Order") and
            (Item."Reordering Policy" = Item."Reordering Policy"::Order) then
            exit(true);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnAfterCarryOutToReqWksh', '', false, false)]
    local procedure OnAfterCarryOutToReqWksh(var RequisitionLine: Record "Requisition Line"; RequisitionLine2: Record "Requisition Line"; ReqWkshTempName: Code[10]; ReqJournalName: Code[10]; LineNo: Integer)
    var
        PlanningRoutingLine: Record "Planning Routing Line";
        PlanningRoutingLine2: Record "Planning Routing Line";
        ProdOrderCapacityNeed: Record "Prod. Order Capacity Need";
        ProdOrderCapacityNeed2: Record "Prod. Order Capacity Need";
    begin
        PlanningRoutingLine.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningRoutingLine.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningRoutingLine.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningRoutingLine.Find('-') then
            repeat
                PlanningRoutingLine2 := PlanningRoutingLine;
                PlanningRoutingLine2."Worksheet Template Name" := ReqWkshTempName;
                PlanningRoutingLine2."Worksheet Batch Name" := ReqJournalName;
                PlanningRoutingLine2."Worksheet Line No." := LineNo;
                OnCarryOutToReqWkshOnAfterPlanningRoutingLineInsert(PlanningRoutingLine2, PlanningRoutingLine);
#if not CLEAN27
                CarryOutAction.RunOnCarryOutToReqWkshOnAfterPlanningRoutingLineInsert(PlanningRoutingLine2, PlanningRoutingLine);
#endif
                PlanningRoutingLine2.Insert();
            until PlanningRoutingLine.Next() = 0;

        ProdOrderCapacityNeed.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        ProdOrderCapacityNeed.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if ProdOrderCapacityNeed.Find('-') then
            repeat
                ProdOrderCapacityNeed2 := ProdOrderCapacityNeed;
                ProdOrderCapacityNeed2."Worksheet Template Name" := ReqWkshTempName;
                ProdOrderCapacityNeed2."Worksheet Batch Name" := ReqJournalName;
                ProdOrderCapacityNeed2."Worksheet Line No." := LineNo;
                ProdOrderCapacityNeed.Delete();
                ProdOrderCapacityNeed2.Insert();
            until ProdOrderCapacityNeed.Next() = 0;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProductionOrderOnProdOrderChoiceCaseElse(ProdOrderChoice: Enum "Planning Create Prod. Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSetProdOrderLineBinCodeFromPlanningRtngLines(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReqLine: Record "Requisition Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateProdOrderLineQuantity(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReqLine: Record "Requisition Line"; Item: Record Item; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectProdOrderForPrinting(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnBeforeProdOrderInit(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderChgAndResheduleOnBeforeProdOrderModify(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromProdOrderOnAfterCalcPrintOrder(var PrintOrder: Boolean; ProdOrderChoice: Option)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderChgAndResheduleOnAfterValidateQuantity(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderChgAndReshedule(var RequisitionLine: Record "Requisition Line"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnAfterFindTempProdOrder(var ReqLine: Record "Requisition Line"; var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var HeaderExists: Boolean; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnProdOrderChoiceNotFirmPlannedPrint(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderChoice: Enum Microsoft.Manufacturing.Document."Planning Create Prod. Order"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnBeforeProdOrderInsert(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderOnAfterProdOrderInsert(var ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderWithReqLine(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdOrder(var ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderChoice: Integer; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnBeforeProdOrderLineInit(var ReqLine: Record "Requisition Line"; var Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnBeforeGetBinCode(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnBeforeValidateUnitCost(var RequisitionLine: Record "Requisition Line"; ProductionOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineWithReqLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnAfterProdOrderLineInsert(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnInsertProdOrderLineOnBeforeModifyProdOrderLine(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertProdOrderLine(ReqLine: Record "Requisition Line"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; Item: Record Item)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteProdOrderLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertProdOrderLineOnAfterTransferRouting(var ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var RefreshProdOrderLine: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeFinalizeOrderHeader(ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningRtngLine(var PlanningRtngLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; var ProdOrderRtngLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterProdOrderRtngLineInsert(var ProdOrderRoutingLine: Record Microsoft.Manufacturing.Document."Prod. Order Routing Line"; PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferBOM(ReqLine: Record "Requisition Line"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; ProdOrderLineNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnBeforeProdOrderComp2Init(var PlanningComponent: Record "Planning Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferPlanningComp(var PlanningComponent: Record "Planning Component"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransferBOMOnAfterCopyProdBOMComments(var PlanningComponent: Record "Planning Component"; var ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeTransferCapNeed(ReqLine: Record "Requisition Line"; ProdOrder: Record Microsoft.Manufacturing.Document."Production Order"; RoutingNo: Code[20]; RoutingRefNo: Integer; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeUpdateComponentLink(ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutToReqWkshOnAfterPlanningRoutingLineInsert(var PlanningRoutingLine: Record Microsoft.Manufacturing.Routing."Planning Routing Line"; PlanningRoutingLine2: Record Microsoft.Manufacturing.Routing."Planning Routing Line")
    begin
    end;
}
