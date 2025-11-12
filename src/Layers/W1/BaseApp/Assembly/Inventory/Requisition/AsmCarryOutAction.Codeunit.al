// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Assembly.Document;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Item;
using Microsoft.Inventory.BOM;
using Microsoft.Foundation.Navigate;

codeunit 945 "Asm. Carry Out Action"
{
    var
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        PlngComponentReserve: Codeunit "Plng. Component-Reserve";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        ReservationManagement: Codeunit "Reservation Management";
        AsmReservCheckDateConfl: Codeunit "Asm. ReservCheckDateConfl";
#if not CLEAN27
        CarryOutAction: Codeunit "Carry Out Action";
#endif
        PrintOrder: Boolean;
        CouldNotChangeSupplyTxt: Label 'The supply type could not be changed in order %1, order line %2.', Comment = '%1 - Production Order No. or Assembly Header No. or Purchase Header No., %2 - Production Order Line or Assembly Line No. or Purchase Line No.';

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Carry Out Action", 'OnTrySourceTypeForAssembly', '', false, false)]
    local procedure OnTrySourceType(var RequisitionLine: Record "Requisition Line"; TryChoice: Option; var AssemblyExist: Boolean; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        AssemblyExist := CarryOutActionsFromAssemblyOrder(RequisitionLine, Enum::"Planning Create Assembly Order".FromInteger(TryChoice), TempDocumentEntry);
    end;

    internal procedure CarryOutActionsFromAssemblyOrder(RequisitionLine: Record "Requisition Line"; AsmOrderChoice: Enum "Planning Create Assembly Order"; var TempDocumentEntry: Record "Document Entry" temporary): Boolean
    var
        AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header";
    begin
        PrintOrder := AsmOrderChoice = AsmOrderChoice::"Make Assembly Orders & Print";
        OnCarryOutActionsFromAssemblyOrderOnAfterCalcPrintOrder(PrintOrder, AsmOrderChoice);
#if not CLEAN27
        CarryOutAction.RunOnCarryOutActionsFromAssemblyOrderOnAfterCalcPrintOrder(PrintOrder, AsmOrderChoice);
#endif
        case RequisitionLine."Action Message" of
            RequisitionLine."Action Message"::New:
                InsertAsmHeader(RequisitionLine, AssemblyHeader, TempDocumentEntry);
            RequisitionLine."Action Message"::"Change Qty.",
          RequisitionLine."Action Message"::Reschedule,
          RequisitionLine."Action Message"::"Resched. & Chg. Qty.":
                exit(AsmOrderChgAndReshedule(RequisitionLine));
            RequisitionLine."Action Message"::Cancel:
                DeleteAssemblyOrderLines(RequisitionLine);
        end;
        exit(true);
    end;

    internal procedure InsertAsmHeader(RequisitionLine: Record "Requisition Line"; var AssemblyHeader: Record "Assembly Header"; var TempDocumentEntry: Record "Document Entry" temporary)
    var
        Item: Record Item;
    begin
        Item.Get(RequisitionLine."No.");
        AssemblyHeader.Init();
        AssemblyHeader."Document Type" := AssemblyHeader."Document Type"::Order;
        OnInsertAsmHeaderOnBeforeAsmHeaderInsert(AssemblyHeader, RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnInsertAsmHeaderOnBeforeAsmHeaderInsert(AssemblyHeader, RequisitionLine);
#endif        
        AssemblyHeader.Insert(true);
        OnInsertAsmHeaderOnAfterAsmHeaderInsert(AssemblyHeader, RequisitionLine);
#if not CLEAN27
        CarryOutAction.RunOnInsertAsmHeaderOnAfterAsmHeaderInsert(AssemblyHeader, RequisitionLine);
#endif
        AssemblyHeader.SetWarningsOff();
        AssemblyHeader.Validate("Item No.", RequisitionLine."No.");
        AssemblyHeader.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        AssemblyHeader.Description := RequisitionLine.Description;
        AssemblyHeader."Description 2" := RequisitionLine."Description 2";
        AssemblyHeader."Variant Code" := RequisitionLine."Variant Code";
        AssemblyHeader."Location Code" := RequisitionLine."Location Code";
        AssemblyHeader."Inventory Posting Group" := Item."Inventory Posting Group";
        AssemblyHeader.Validate("Unit Cost", RequisitionLine."Unit Cost");
        AssemblyHeader."Due Date" := RequisitionLine."Due Date";
        AssemblyHeader."Starting Date" := RequisitionLine."Starting Date";
        AssemblyHeader."Ending Date" := RequisitionLine."Ending Date";

        AssemblyHeader.Quantity := RequisitionLine.Quantity;
        AssemblyHeader."Quantity (Base)" := RequisitionLine."Quantity (Base)";
        AssemblyHeader.InitRemainingQty();
        AssemblyHeader.InitQtyToAssemble();
        if RequisitionLine."Bin Code" <> '' then
            AssemblyHeader."Bin Code" := RequisitionLine."Bin Code"
        else
            AssemblyHeader.GetDefaultBin();

        AssemblyHeader."Planning Flexibility" := RequisitionLine."Planning Flexibility";
        AssemblyHeader."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
        AssemblyHeader."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
        AssemblyHeader."Dimension Set ID" := RequisitionLine."Dimension Set ID";
        AssemblyHeaderReserve.TransferPlanningLineToAsmHdr(RequisitionLine, AssemblyHeader, RequisitionLine."Net Quantity (Base)", false);
        if RequisitionLine.Reserve then
            ReserveBindingOrderToAsm(AssemblyHeader, RequisitionLine);
        AssemblyHeader.Modify();

        TransferAsmPlanningComp(RequisitionLine, AssemblyHeader);

        AddResourceComponents(RequisitionLine, AssemblyHeader);

        OnAfterInsertAsmHeader(RequisitionLine, AssemblyHeader);
#if not CLEAN27
        CarryOutAction.RunOnAfterInsertAsmHeader(RequisitionLine, AssemblyHeader);
#endif
        CollectAsmOrderForPrinting(AssemblyHeader);

        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::Microsoft.Assembly.Document."Assembly Header";
        TempDocumentEntry."Document Type" := AssemblyHeader."Document Type"::Order;
        TempDocumentEntry."Document No." := AssemblyHeader."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();
    end;

    internal procedure AsmOrderChgAndReshedule(RequisitionLine: Record "Requisition Line"): Boolean
    var
        AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header";
        PlanningComponent: Record "Planning Component";
        AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line";
        AssemblyLineReserve: Codeunit Microsoft.Assembly.Document."Assembly Line-Reserve";
    begin
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Assembly);
        AssemblyHeader.LockTable();
        if AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, RequisitionLine."Ref. Order No.") then begin
            AssemblyHeader.SetWarningsOff();
            AssemblyHeader.Validate(Quantity, RequisitionLine.Quantity);
            AssemblyHeader.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            AssemblyHeader.Validate("Due Date", RequisitionLine."Due Date");
            OnAsmOrderChgAndResheduleOnBeforeAsmHeaderModify(RequisitionLine, AssemblyHeader);
#if not CLEAN27
            CarryOutAction.RunOnAsmOrderChgAndResheduleOnBeforeAsmHeaderModify(RequisitionLine, AssemblyHeader);
#endif
            AssemblyHeader.Modify(true);
            AssemblyHeaderReserve.TransferPlanningLineToAsmHdr(RequisitionLine, AssemblyHeader, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(AssemblyHeader);
            ReservationManagement.DeleteReservEntries(false, AssemblyHeader."Remaining Quantity (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(AssemblyHeader."Remaining Quantity (Base)");

            PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
            PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
            PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
            if PlanningComponent.Find('-') then
                repeat
                    if AssemblyLine.Get(AssemblyHeader."Document Type", AssemblyHeader."No.", PlanningComponent."Line No.") then begin
                        AssemblyLineReserve.TransferPlanningCompToAsmLine(PlanningComponent, AssemblyLine, 0, true);
                        PlngComponentReserve.UpdateDerivedTracking(PlanningComponent);
                        ReservationManagement.SetReservSource(AssemblyLine);
                        ReservationManagement.DeleteReservEntries(false, AssemblyLine."Remaining Quantity (Base)");
                        ReservationManagement.ClearSurplus();
                        ReservationManagement.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
                        AsmReservCheckDateConfl.AssemblyLineCheck(AssemblyLine, false);
                    end else
                        PlanningComponent.Delete(true);
                until PlanningComponent.Next() = 0;

            if PrintOrder then
                CollectAsmOrderForPrinting(AssemblyHeader);
        end else begin
            Message(StrSubstNo(CouldNotChangeSupplyTxt, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No."));
            exit(false);
        end;
        exit(true);
    end;

    local procedure CollectAsmOrderForPrinting(var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
        OnCollectAsmOrderForPrinting(AssemblyHeader);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCollectAsmOrderForPrinting(var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;

    internal procedure TransferAsmPlanningComp(RequisitionLine: Record "Requisition Line"; AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    var
        AssemblyLine: Record "Assembly Line";
        PlanningComponent: Record "Planning Component";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                AssemblyLine.Init();
                AssemblyLine."Document Type" := AssemblyHeader."Document Type";
                AssemblyLine."Document No." := AssemblyHeader."No.";
                AssemblyLine."Line No." := PlanningComponent."Line No.";
                AssemblyLine.Type := AssemblyLine.Type::Item;
                AssemblyLine."Dimension Set ID" := PlanningComponent."Dimension Set ID";
                AssemblyLine.Validate("No.", PlanningComponent."Item No.");
                AssemblyLine.Description := PlanningComponent.Description;
                AssemblyLine."Unit of Measure Code" := PlanningComponent."Unit of Measure Code";
                AssemblyLine."Qty. Rounding Precision" := PlanningComponent."Qty. Rounding Precision";
                AssemblyLine."Qty. Rounding Precision (Base)" := PlanningComponent."Qty. Rounding Precision (Base)";
                AssemblyLine."Lead-Time Offset" := PlanningComponent."Lead-Time Offset";
                AssemblyLine.Position := PlanningComponent.Position;
                AssemblyLine."Position 2" := PlanningComponent."Position 2";
                AssemblyLine."Position 3" := PlanningComponent."Position 3";
                AssemblyLine."Variant Code" := PlanningComponent."Variant Code";
                AssemblyLine."Location Code" := PlanningComponent."Location Code";

                AssemblyLine."Quantity per" := PlanningComponent."Quantity per";
                AssemblyLine."Qty. per Unit of Measure" := PlanningComponent."Qty. per Unit of Measure";
                AssemblyLine.Quantity := PlanningComponent."Expected Quantity";
                AssemblyLine."Quantity (Base)" := PlanningComponent."Expected Quantity (Base)";
                AssemblyLine.InitRemainingQty();
                AssemblyLine.InitQtyToConsume();
                if PlanningComponent."Bin Code" <> '' then
                    AssemblyLine."Bin Code" := PlanningComponent."Bin Code"
                else
                    AssemblyLine.GetDefaultBin();

                AssemblyLine."Due Date" := PlanningComponent."Due Date";
                AssemblyLine."Unit Cost" := PlanningComponent."Unit Cost";
                AssemblyLine."Variant Code" := PlanningComponent."Variant Code";
                AssemblyLine."Cost Amount" := PlanningComponent."Cost Amount";

                AssemblyLine."Shortcut Dimension 1 Code" := PlanningComponent."Shortcut Dimension 1 Code";
                AssemblyLine."Shortcut Dimension 2 Code" := PlanningComponent."Shortcut Dimension 2 Code";

                OnAfterTransferAsmPlanningComp(PlanningComponent, AssemblyLine);
#if not CLEAN27
                CarryOutAction.RunOnAfterTransferAsmPlanningComp(PlanningComponent, AssemblyLine);
#endif
                AssemblyLine.Insert();

                AssemblyLineReserve.TransferPlanningCompToAsmLine(PlanningComponent, AssemblyLine, 0, true);
                AssemblyLine.AutoReserve();
                ReservationManagement.SetReservSource(AssemblyLine);
                ReservationManagement.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
            until PlanningComponent.Next() = 0;
    end;

    internal procedure ReserveBindingOrderToAsm(var AssemblyHeader: Record "Assembly Header"; var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        AssemblyHeader.CalcFields("Reserved Quantity", "Reserved Qty. (Base)");
        if AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)" >
           RequisitionLine."Demand Quantity (Base)"
        then begin
            ReservQty := RequisitionLine."Demand Quantity";
            ReservQtyBase := RequisitionLine."Demand Quantity (Base)";
        end else begin
            ReservQty := AssemblyHeader."Remaining Quantity" - AssemblyHeader."Reserved Quantity";
            ReservQtyBase := AssemblyHeader."Remaining Quantity (Base)" - AssemblyHeader."Reserved Qty. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::Microsoft.Assembly.Document."Assembly Header", AssemblyHeader."Document Type".AsInteger(), AssemblyHeader."No.", '', 0, 0,
            AssemblyHeader."Variant Code", AssemblyHeader."Location Code", AssemblyHeader."Qty. per Unit of Measure");

        RequisitionLine.ReserveBindingOrder(
            TrackingSpecification, AssemblyHeader.Description, AssemblyHeader."Due Date", ReservQty, ReservQtyBase, true);

        AssemblyHeader.Modify();
    end;

    local procedure AddResourceComponents(RequisitionLine: Record "Requisition Line"; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    var
        BOMComponent: Record "BOM Component";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeAddResourceComponents(RequisitionLine, AssemblyHeader, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeAddResourceComponents(RequisitionLine, AssemblyHeader, IsHandled);
#endif
        if IsHandled then
            exit;

        BOMComponent.SetRange("Parent Item No.", RequisitionLine."No.");
        BOMComponent.SetRange(Type, BOMComponent.Type::Resource);
        if BOMComponent.Find('-') then
            repeat
                AssemblyHeader.AddBOMLine(BOMComponent);
            until BOMComponent.Next() = 0;
    end;

    local procedure DeleteAssemblyOrderLines(RequisitionLine: Record "Requisition Line")
    var
        AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteAssemblyLines(RequisitionLine, IsHandled);
#if not CLEAN27
        CarryOutAction.RunOnBeforeDeleteAssemblyLines(RequisitionLine, IsHandled);
#endif
        if IsHandled then
            exit;

        AssemblyHeader.Get(AssemblyHeader."Document Type"::Order, RequisitionLine."Ref. Order No.");
        AssemblyHeader.Delete(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromAssemblyOrderOnAfterCalcPrintOrder(var PrintOrder: Boolean; AsmOrderChoice: Enum "Planning Create Assembly Order")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteAssemblyLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmHeaderOnBeforeAsmHeaderInsert(var AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; ReqLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertAsmHeaderOnAfterAsmHeaderInsert(var AsmHeader: Record Microsoft.Assembly.Document."Assembly Header"; ReqLine: Record "Requisition Line");
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertAsmHeader(var ReqLine: Record "Requisition Line"; var AsmHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAsmOrderChgAndResheduleOnBeforeAsmHeaderModify(var ReqLine: Record "Requisition Line"; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterTransferAsmPlanningComp(var PlanningComponent: Record "Planning Component"; var AssemblyLine: Record Microsoft.Assembly.Document."Assembly Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeAddResourceComponents(RequisitionLine: Record "Requisition Line"; var AssemblyHeader: Record Microsoft.Assembly.Document."Assembly Header"; var IsHandled: Boolean)
    begin
    end;
}