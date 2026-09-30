// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Requisition;

using Microsoft.Foundation.Enums;
using Microsoft.Foundation.Navigate;
using Microsoft.Foundation.Reporting;
using Microsoft.Inventory.Planning;
using Microsoft.Inventory.Setup;
using Microsoft.Inventory.Tracking;
using Microsoft.Inventory.Transfer;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Setup;
using System.Text;

codeunit 99000813 "Carry Out Action"
{
    TableNo = "Requisition Line";

    trigger OnRun()
    var
        IsHandled: Boolean;
    begin
        OnBeforeRun(Rec);
        ProductionExist := true;
        AssemblyExist := true;
        case TrySourceType of
            TrySourceType::Purchase:
                CarryOutToReqWksh(Rec, TryWkshTempl, TryWkshName);
            TrySourceType::Transfer:
                CarryOutActionsFromTransOrder(Rec, Enum::"Planning Create Transfer Order".FromInteger(TryChoice), TryWkshTempl, TryWkshName);
            TrySourceType::Production:
                begin
                    IsHandled := false;
                    OnRunOnBeforeCalcProductionExist(Rec, TryChoice, TryWkshTempl, TryWkshName, ProductionExist, IsHandled);
                    if not IsHandled then
                        OnTrySourceTypeForProduction(Rec, TryChoice, TryWkshTempl, TryWkshName, ProductionExist, TempDocumentEntry);
                end;
            TrySourceType::Assembly:
                OnTrySourceTypeForAssembly(Rec, TryChoice, AssemblyExist, TempDocumentEntry);
        end;

        if Rec."Action Message" = Rec."Action Message"::Cancel then
            Rec.Delete(true);

        ReservationEntry.SetCurrentKey(
          "Source ID", "Source Ref. No.", "Source Type", "Source Subtype",
          "Source Batch Name", "Source Prod. Order Line");
        Rec.SetReservationFilters(ReservationEntry);
        ReservationEntry.DeleteAll(true);

        if not (Rec."Action Message" = Rec."Action Message"::Cancel) then begin
            Rec.BlockDynamicTracking(true);
            if TrySourceType = TrySourceType::Production then
                Rec.BlockDynamicTrackingOnComp(true);
            if ProductionExist and AssemblyExist then
                DeleteRequisitionLine(Rec);
            Rec.BlockDynamicTracking(false);
        end;
    end;

    var
        LastTransferHeader: Record "Transfer Header";
        TempTransferHeaderToPrint: Record "Transfer Header" temporary;
        ReservationEntry: Record "Reservation Entry";
        TempDocumentEntry: Record "Document Entry" temporary;
        CarryOutAction: Codeunit "Carry Out Action";
        ReservationManagement: Codeunit "Reservation Management";
        ReqLineReserve: Codeunit "Req. Line-Reserve";
        PrintOrder: Boolean;
        SplitTransferOrders: Boolean;
        ProductionExist: Boolean;
        AssemblyExist: Boolean;
        TrySourceType: Enum "Planning Create Source Type";
        TryChoice: Option;
        TryWkshTempl: Code[10];
        TryWkshName: Code[10];
        LineNo: Integer;
        CouldNotChangeSupplyTxt: Label 'The supply type could not be changed in order %1, order line %2.', Comment = '%1 - Production Order No. or Assembly Header No. or Purchase Header No., %2 - Production Order Line or Assembly Line No. or Purchase Line No.';

    procedure TryCarryOutAction(SourceType: Enum "Planning Create Source Type"; var RequisitionLine: Record "Requisition Line"; Choice: Option; WkshTempl: Code[10]; WkshName: Code[10]): Boolean
    begin
        CarryOutAction.SetSplitTransferOrders(SplitTransferOrders);
        CarryOutAction.SetParameters(SourceType, Choice, WkshTempl, WkshName);
        exit(CarryOutAction.Run(RequisitionLine));
    end;

    procedure SetParameters(SourceType: Enum "Planning Create Source Type"; Choice: Integer; WkshTempl: Code[10]; WkshName: Code[10])
    begin
        TrySourceType := SourceType;
        TryChoice := Choice;
        TryWkshTempl := WkshTempl;
        TryWkshName := WkshName;
    end;


    procedure CarryOutActionsFromTransOrder(RequisitionLine: Record "Requisition Line"; TransOrderChoice: Enum "Planning Create Transfer Order"; TransWkshTempName: Code[10];
                                                                                                              TransJournalName: Code[10])
    var
        IsHandled: Boolean;
    begin
        OnBeforeCarryOutTransOrder(SplitTransferOrders);

        PrintOrder := TransOrderChoice = TransOrderChoice::"Make Trans. Order & Print";

        if SplitTransferOrders then
            Clear(LastTransferHeader);

        if TransOrderChoice = TransOrderChoice::"Copy to Req. Wksh" then
            CarryOutToReqWksh(RequisitionLine, TransWkshTempName, TransJournalName)
        else
            case RequisitionLine."Action Message" of
                RequisitionLine."Action Message"::New:
                    begin
                        IsHandled := false;
                        OnCarryOutActionsFromTransOrderOnBeforeInsertTransLine(RequisitionLine, PrintOrder, IsHandled);
                        if not IsHandled then
                            InsertTransLine(RequisitionLine, LastTransferHeader);
                    end;
                RequisitionLine."Action Message"::"Change Qty.",
              RequisitionLine."Action Message"::Reschedule,
              RequisitionLine."Action Message"::"Resched. & Chg. Qty.":
                    begin
                        IsHandled := false;
                        OnCarryOutActionsFromTransOrderOnBeforeTransOrderChgAndReshedule(RequisitionLine, PrintOrder, IsHandled);
                        if not IsHandled then
                            TransOrderChgAndReshedule(RequisitionLine);
                    end;
                RequisitionLine."Action Message"::Cancel:
                    DeleteOrderLines(RequisitionLine);
            end;
    end;


    procedure CarryOutToReqWksh(RequisitionLine: Record "Requisition Line"; ReqWkshTempName: Code[10]; ReqJournalName: Code[10])
    var
        RequisitionLine2: Record "Requisition Line";
        PlanningComponent: Record "Planning Component";
        PlanningComponent2: Record "Planning Component";
        RequisitionLine3: Record "Requisition Line";
    begin
        RequisitionLine2 := RequisitionLine;
        RequisitionLine2."Worksheet Template Name" := ReqWkshTempName;
        RequisitionLine2."Journal Batch Name" := ReqJournalName;

        if LineNo = 0 then begin // we need to find the last line in worksheet
            RequisitionLine3.SetCurrentKey("Worksheet Template Name", "Journal Batch Name", "Line No.");
            RequisitionLine3.SetRange("Worksheet Template Name", ReqWkshTempName);
            RequisitionLine3.SetRange("Journal Batch Name", ReqJournalName);
            if RequisitionLine3.FindLast() then
                LineNo := RequisitionLine3."Line No.";
        end;
        LineNo += 10000;
        RequisitionLine2."Line No." := LineNo;

        if RequisitionLine2."Planning Line Origin" = RequisitionLine2."Planning Line Origin"::"Order Planning" then begin
            RequisitionLine2."Planning Line Origin" := RequisitionLine2."Planning Line Origin"::" ";
            RequisitionLine2.Level := 0;
            RequisitionLine2.Status := 0;
            RequisitionLine2.Reserve := false;
            RequisitionLine2."Demand Type" := 0;
            RequisitionLine2."Demand Subtype" := 0;
            RequisitionLine2."Demand Order No." := '';
            RequisitionLine2."Demand Line No." := 0;
            RequisitionLine2."Demand Ref. No." := 0;
            RequisitionLine2."Demand Date" := 0D;
            RequisitionLine2."Demand Quantity" := 0;
            RequisitionLine2."Demand Quantity (Base)" := 0;
            RequisitionLine2."Needed Quantity" := 0;
            RequisitionLine2."Needed Quantity (Base)" := 0;
            RequisitionLine2."Qty. per UOM (Demand)" := 0;
            RequisitionLine2."Unit Of Measure Code (Demand)" := '';
        end;
        OnCarryOutToReqWkshOnBeforeReqLineInsert(RequisitionLine2, ReqWkshTempName, ReqJournalName, LineNo);
        RequisitionLine2.Insert();

        ReqLineReserve.TransferReqLineToReqLine(RequisitionLine, RequisitionLine2, 0, true);
        if RequisitionLine.Reserve then
            ReserveBindingOrderToReqline(RequisitionLine2, RequisitionLine);

        PlanningComponent.SetRange("Worksheet Template Name", RequisitionLine."Worksheet Template Name");
        PlanningComponent.SetRange("Worksheet Batch Name", RequisitionLine."Journal Batch Name");
        PlanningComponent.SetRange("Worksheet Line No.", RequisitionLine."Line No.");
        if PlanningComponent.Find('-') then
            repeat
                PlanningComponent2 := PlanningComponent;
                PlanningComponent2."Worksheet Template Name" := ReqWkshTempName;
                PlanningComponent2."Worksheet Batch Name" := ReqJournalName;
                PlanningComponent2."Worksheet Line No." := LineNo;
                if PlanningComponent2."Planning Line Origin" = PlanningComponent2."Planning Line Origin"::"Order Planning" then
                    PlanningComponent2."Planning Line Origin" := PlanningComponent2."Planning Line Origin"::" ";
                PlanningComponent2."Dimension Set ID" := RequisitionLine2."Dimension Set ID";
                PlanningComponent2.Insert();
                OnCarryOutToReqWkshOnAfterPlanningCompInsert(PlanningComponent2, PlanningComponent);
            until PlanningComponent.Next() = 0;

        OnAfterCarryOutToReqWksh(RequisitionLine, RequisitionLine2, ReqWkshTempName, ReqJournalName, LineNo);
    end;

    procedure GetTransferOrdersToPrint(var TransferHeader: Record "Transfer Header")
    begin
        if TempTransferHeaderToPrint.FindSet() then
            repeat
                TransferHeader := TempTransferHeaderToPrint;
                TransferHeader.Insert();
            until TempTransferHeaderToPrint.Next() = 0;
    end;


    procedure PurchOrderChgAndReshedule(RequisitionLine: Record "Requisition Line")
    var
        PurchaseLine: Record "Purchase Line";
        PurchaseHeader: Record "Purchase Header";
        PurchaseLineExists: Boolean;
    begin
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Purchase);

        PurchaseLineExists := PurchaseLine.Get(PurchaseLine."Document Type"::Order, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.");
        OnPurchOrderChgAndResheduleOnAfterPurchaseLineExistsCheck(RequisitionLine, PurchaseLine, PurchaseLineExists);

        if PurchaseLineExists then begin
            OnPurchOrderChgAndResheduleOnAfterGetPurchLine(PurchaseLine);
            PurchaseLine.BlockDynamicTracking(true);
            PurchaseLine.Validate(Quantity, RequisitionLine.Quantity);
            OnPurchOrderChgAndResheduleOnBeforeValidateExpectedReceiptDate(RequisitionLine);
            PurchaseLine.Validate("Expected Receipt Date", RequisitionLine."Due Date");
            PurchaseLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            OnPurchOrderChgAndResheduleOnBeforePurchLineModify(RequisitionLine, PurchaseLine);
            PurchaseLine.Modify(true);
            ReqLineReserve.TransferReqLineToPurchLine(RequisitionLine, PurchaseLine, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(PurchaseLine);
            ReservationManagement.DeleteReservEntries(false, PurchaseLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(PurchaseLine."Outstanding Qty. (Base)");

            PurchaseHeader.Get(PurchaseLine."Document Type", PurchaseLine."Document No.");
            OnPurchOrderChgAndResheduleOnAfterGetPurchHeader(PurchaseHeader, PurchaseLine, RequisitionLine);
            PrintPurchaseOrder(PurchaseHeader);
        end else
            Error(CouldNotChangeSupplyTxt, RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.");
    end;

    procedure TransOrderChgAndReshedule(RequisitionLine: Record "Requisition Line")
    var
        TransferLine: Record "Transfer Line";
        TransferHeader: Record "Transfer Header";
    begin
        RequisitionLine.TestField("Ref. Order Type", RequisitionLine."Ref. Order Type"::Transfer);

        if TransferLine.Get(RequisitionLine."Ref. Order No.", RequisitionLine."Ref. Line No.") then begin
            TransferLine.BlockDynamicTracking(true);
            TransferLine.Validate(Quantity, RequisitionLine.Quantity);
            TransferLine.Validate("Receipt Date", RequisitionLine."Due Date");
            TransferLine."Shipment Date" := RequisitionLine."Transfer Shipment Date";
            TransferLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
            OnTransOrderChgAndResheduleOnBeforeTransLineModify(RequisitionLine, TransferLine);
            TransferLine.Modify(true);
            ReqLineReserve.TransferReqLineToTransLine(RequisitionLine, TransferLine, 0, true);
            ReqLineReserve.UpdateDerivedTracking(RequisitionLine);
            ReservationManagement.SetReservSource(TransferLine, Enum::"Transfer Direction"::Outbound);
            ReservationManagement.DeleteReservEntries(false, TransferLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(TransferLine."Outstanding Qty. (Base)");
            ReservationManagement.SetReservSource(TransferLine, Enum::"Transfer Direction"::Inbound);
            ReservationManagement.DeleteReservEntries(false, TransferLine."Outstanding Qty. (Base)");
            ReservationManagement.ClearSurplus();
            ReservationManagement.AutoTrack(TransferLine."Outstanding Qty. (Base)");
            TransferHeader.Get(TransferLine."Document No.");
            PrintTransferOrder(TransferHeader);
        end;
    end;


    procedure DeleteOrderLines(RequisitionLine: Record "Requisition Line")
    begin
        OnBeforeDeleteOrderLines(RequisitionLine);

        case RequisitionLine."Ref. Order Type" of
            RequisitionLine."Ref. Order Type"::Purchase:
                DeletePurchaseOrderLines(RequisitionLine);
            RequisitionLine."Ref. Order Type"::Transfer:
                DeleteTransferOrderLines(RequisitionLine);
        end;

        OnAfterDeleteOrderLines(RequisitionLine);
    end;

    local procedure DeletePurchaseOrderLines(RequisitionLine: Record "Requisition Line")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeletePurchaseLines(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        PurchaseLine.SetCurrentKey("Document Type", "Document No.", "Line No.");
        PurchaseLine.SetFilter(Type, '<>%1', PurchaseLine.Type::" ");
        PurchaseLine.SetRange("Document Type", PurchaseLine."Document Type"::Order);
        PurchaseLine.SetRange("Document No.", RequisitionLine."Ref. Order No.");
        if PurchaseLine.Count in [0, 1] then begin
            if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, RequisitionLine."Ref. Order No.") then
                PurchaseHeader.Delete(true);
        end else begin
            PurchaseLine.SetRange("Line No.", RequisitionLine."Ref. Line No.");
            if PurchaseLine.FindFirst() then
                PurchaseLine.Delete(true);
        end;
    end;

    local procedure DeleteTransferOrderLines(RequisitionLine: Record "Requisition Line")
    var
        TransferHeader: Record "Transfer Header";
        TransferLine: Record "Transfer Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeDeleteTransferLines(RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine.SetCurrentKey("Document No.", "Line No.");
        TransferLine.SetRange("Document No.", RequisitionLine."Ref. Order No.");
        if TransferLine.Count in [0, 1] then begin
            if TransferHeader.Get(RequisitionLine."Ref. Order No.") then
                TransferHeader.Delete(true);
        end else begin
            TransferLine.SetRange("Line No.", RequisitionLine."Ref. Line No.");
            if TransferLine.FindFirst() then
                TransferLine.Delete(true);
        end;
    end;

    local procedure DeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
        OnBeforeDeleteRequisitionLine(RequisitionLine);
        RequisitionLine.Delete(true);
        OnAfterDeleteRequisitionLine(RequisitionLine);
    end;





    procedure InsertTransHeader(RequisitionLine: Record "Requisition Line"; var TransferHeader: Record "Transfer Header")
    var
        InventorySetup: Record "Inventory Setup";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeInsertTransHeader(RequisitionLine, TransferHeader, IsHandled);
        if IsHandled then
            exit;

        InventorySetup.Get();
        InventorySetup.TestField("Transfer Order Nos.");

        TransferHeader.Init();
        TransferHeader."No." := '';
        TransferHeader."Posting Date" := WorkDate();
        OnInsertTransHeaderOnBeforeTransHeaderInsert(TransferHeader, RequisitionLine);
        TransferHeader.Insert(true);
        OnInsertTransHeaderOnAfterTransHeaderInsert(TransferHeader, RequisitionLine);
        TransferHeader.Validate("Transfer-from Code", RequisitionLine."Transfer-from Code");
        TransferHeader.Validate("Transfer-to Code", RequisitionLine."Location Code");
        TransferHeader."Receipt Date" := RequisitionLine."Due Date";
        TransferHeader."Shipment Date" := RequisitionLine."Transfer Shipment Date";
        OnInsertTransHeaderOnBeforeTransHeaderModify(TransferHeader, RequisitionLine);
        TransferHeader.Modify();
        TempDocumentEntry.Init();
        TempDocumentEntry."Table ID" := Database::"Transfer Header";
        TempDocumentEntry."Document No." := TransferHeader."No.";
        TempDocumentEntry."Entry No." := TempDocumentEntry.Count + 1;
        TempDocumentEntry.Insert();

        if PrintOrder then begin
            TempTransferHeaderToPrint."No." := TransferHeader."No.";
            TempTransferHeaderToPrint.Insert();
        end;
    end;

    procedure InsertTransLine(RequisitionLine: Record "Requisition Line"; var TransferHeader: Record "Transfer Header")
    var
        TransferLine: Record "Transfer Line";
        NextLineNo: Integer;
        ShouldInsertTransHeader: Boolean;
    begin
        ShouldInsertTransHeader := (RequisitionLine."Transfer-from Code" <> TransferHeader."Transfer-from Code") or
           (RequisitionLine."Location Code" <> TransferHeader."Transfer-to Code");
        OnInsertTransLineOnAfterCalcShouldInsertTransHeader(RequisitionLine, TransferHeader, ShouldInsertTransHeader);
        if ShouldInsertTransHeader then
            InsertTransHeader(RequisitionLine, TransferHeader);

        TransferLine.SetRange("Document No.", TransferHeader."No.");
        if TransferLine.FindLast() then
            NextLineNo := TransferLine."Line No." + 10000
        else
            NextLineNo := 10000;

        TransferLine.Init();
        OnInsertTransLineOnAfterTransLineInit(TransferLine, RequisitionLine);
        TransferLine.BlockDynamicTracking(true);
        TransferLine."Document No." := TransferHeader."No.";
        TransferLine."Line No." := NextLineNo;
        TransferLine.Validate("Item No.", RequisitionLine."No.");
        TransferLine.Description := RequisitionLine.Description;
        TransferLine."Description 2" := RequisitionLine."Description 2";
        TransferLine.Validate("Variant Code", RequisitionLine."Variant Code");
        TransferLine.Validate("Transfer-from Code", RequisitionLine."Transfer-from Code");
        TransferLine.Validate("Transfer-to Code", RequisitionLine."Location Code");
        TransferLine.Validate(Quantity, RequisitionLine.Quantity);
        TransferLine.Validate("Unit of Measure Code", RequisitionLine."Unit of Measure Code");
        CopyDimensionsFromReqToTransLine(TransferLine, RequisitionLine);
        TransferLine."Receipt Date" := RequisitionLine."Due Date";
        TransferLine."Shipment Date" := RequisitionLine."Transfer Shipment Date";
        TransferLine.Validate("Planning Flexibility", RequisitionLine."Planning Flexibility");
        OnInsertTransLineWithReqLine(TransferLine, RequisitionLine, NextLineNo);
        TransferLine.Insert();
        OnAfterTransLineInsert(TransferLine, RequisitionLine);

        ReqLineReserve.TransferReqLineToTransLine(RequisitionLine, TransferLine, RequisitionLine."Quantity (Base)", false);
        if RequisitionLine.Reserve then
            ReserveBindingOrderToTrans(TransferLine, RequisitionLine);

        OnAfterInsertTransLine(TransferHeader, RequisitionLine, TransferLine, NextLineNo);
    end;

    local procedure CopyDimensionsFromReqToTransLine(var TransferLine: Record "Transfer Line"; RequisitionLine: Record "Requisition Line")
    var
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCopyDimensionsFromReqToTransLine(TransferLine, RequisitionLine, IsHandled);
        if IsHandled then
            exit;

        TransferLine."Shortcut Dimension 1 Code" := RequisitionLine."Shortcut Dimension 1 Code";
        TransferLine."Shortcut Dimension 2 Code" := RequisitionLine."Shortcut Dimension 2 Code";
        TransferLine."Dimension Set ID" := RequisitionLine."Dimension Set ID";
    end;

    procedure PrintTransferOrders()
    var
        TransferHeader: Record "Transfer Header";
        ReportSelections: Record "Report Selections";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
        TransferOrderNoFilter: Text;
    begin
        CarryOutAction.GetTransferOrdersToPrint(TempTransferHeaderToPrint);

        case TempTransferHeaderToPrint.Count() of
            0:
                exit;
            1:
                begin
                    PrintOrder := true;
                    TempTransferHeaderToPrint.FindFirst();
                    PrintTransferOrder(TempTransferHeaderToPrint);
                end;
            else begin
                RecordRefToPrint.GetTable(TempTransferHeaderToPrint);
                RecordRefToHeader.GetTable(TransferHeader);
                TransferOrderNoFilter := SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, TransferHeader.FieldNo("No."));

                TransferHeader.SetFilter("No.", TransferOrderNoFilter);
                OnPrintTransferOrderOnBeforePrintWithDialogWithCheckForCust(ReportSelections);
                ReportSelections.PrintWithDialogWithCheckForCust(Enum::"Report Selection Usage"::Inv1, TransferHeader, false, 0);
            end;
        end;

        TempTransferHeaderToPrint.DeleteAll();
    end;

    procedure PrintTransferOrder(TransferHeader: Record "Transfer Header")
    var
        ReportSelections: Record "Report Selections";
        TransferHeader2: Record "Transfer Header";
    begin
        if PrintOrder then begin
            TransferHeader2 := TransferHeader;
            TransferHeader2.SetRecFilter();
            OnPrintTransferOrderOnBeforePrintWithDialogWithCheckForCust(ReportSelections);
            ReportSelections.PrintWithDialogWithCheckForCust(Enum::"Report Selection Usage"::Inv1, TransferHeader2, false, 0);
        end;
    end;

    procedure PrintPurchaseOrder(PurchaseHeader: Record "Purchase Header")
    var
        ReportSelections: Record "Report Selections";
        PurchaseHeader2: Record "Purchase Header";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        PurchaseLine: Record "Purchase Line";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintPurchaseOrder2(PurchaseHeader, PrintOrder, IsHandled);
        if IsHandled then
            exit;

        if PrintOrder and (PurchaseHeader."Buy-from Vendor No." <> '') then begin
            PurchaseHeader2 := PurchaseHeader;
            PurchasesPayablesSetup.Get();
            if PurchasesPayablesSetup."Calc. Inv. Discount" then begin
                PurchaseLine.Reset();
                PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
                PurchaseLine.SetRange("Document No.", PurchaseHeader."No.");
                PurchaseLine.FindFirst();
                CODEUNIT.Run(CODEUNIT::"Purch.-Calc.Discount", PurchaseLine);
            end;

            IsHandled := false;
            OnBeforePrintPurchaseOrder(PurchaseHeader2, IsHandled, PrintOrder);
            if IsHandled then
                exit;

            PurchaseHeader2.SetRecFilter();
            ReportSelections.PrintWithDialogWithCheckForVend(
              ReportSelections.Usage::"P.Order", PurchaseHeader2, false, PurchaseHeader2.FieldNo("Buy-from Vendor No."));
        end;
    end;

    procedure PrintMultiplePurchaseOrders(var TempPurchaseHeader: Record "Purchase Header" temporary)
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
        PurchCalcDiscByType: Codeunit "Purch - Calc Disc. By Type";
        SelectionFilterManagement: Codeunit SelectionFilterManagement;
        RecordRefToPrint: RecordRef;
        RecordRefToHeader: RecordRef;
        PurchaseOrderNoFilter: Text;
        IsHandled: Boolean;
    begin
        if not PrintOrder then
            exit;

        TempPurchaseHeader.Reset();
        if TempPurchaseHeader.IsEmpty() then
            exit;

        TempPurchaseHeader.FindSet();
        repeat
            PurchaseHeader.Get(TempPurchaseHeader."Document Type", TempPurchaseHeader."No.");
            PurchCalcDiscByType.ApplyDefaultInvoiceDiscount(0, PurchaseHeader);
        until TempPurchaseHeader.Next() = 0;

        IsHandled := false;
        OnBeforePrintMultiplePurchaseDocs(TempPurchaseHeader, IsHandled);
        if IsHandled then
            exit;

        RecordRefToPrint.GetTable(TempPurchaseHeader);
        RecordRefToHeader.GetTable(PurchaseHeader);
        PurchaseOrderNoFilter := SelectionFilterManagement.CreateFilterFromTempTable(RecordRefToPrint, RecordRefToHeader, PurchaseHeader.FieldNo("No."));

        PurchaseHeader.SetRange("Document Type", PurchaseHeader."Document Type"::Order);
        PurchaseHeader.SetFilter("No.", PurchaseOrderNoFilter);
        PurchaseHeader.SetFilter("Buy-from Vendor No.", '<>%1', '');
        ReportSelections.PrintWithDialogWithCheckForVend(
            ReportSelections.Usage::"P.Order", PurchaseHeader, false, PurchaseHeader.FieldNo("Buy-from Vendor No."));
    end;






    procedure SetCreatedDocumentBuffer(var TempDocumentEntryNew: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.Copy(TempDocumentEntryNew, true);
    end;

    procedure SetPrintOrder(OrderPrinting: Boolean)
    begin
        PrintOrder := OrderPrinting;
    end;

    procedure SetSplitTransferOrders(Split: Boolean)
    begin
        SplitTransferOrders := Split;
    end;


    procedure ReserveBindingOrderToTrans(var TransferLine: Record "Transfer Line"; var RequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        TransferLine.CalcFields("Reserved Quantity Inbnd.", "Reserved Qty. Inbnd. (Base)");
        if (TransferLine."Outstanding Qty. (Base)" - TransferLine."Reserved Qty. Inbnd. (Base)") > RequisitionLine."Demand Quantity (Base)" then begin
            ReservQty := RequisitionLine."Demand Quantity";
            ReservQtyBase := RequisitionLine."Demand Quantity (Base)";
        end else begin
            ReservQty := TransferLine."Outstanding Quantity" - TransferLine."Reserved Quantity Inbnd.";
            ReservQtyBase := TransferLine."Outstanding Qty. (Base)" - TransferLine."Reserved Qty. Inbnd. (Base)";
        end;

        TrackingSpecification.InitTrackingSpecification(
            Database::"Transfer Line", 1, TransferLine."Document No.", '', 0, TransferLine."Line No.",
            TransferLine."Variant Code", TransferLine."Transfer-to Code", TransferLine."Qty. per Unit of Measure");

        RequisitionLine.ReserveBindingOrder(
            TrackingSpecification, TransferLine.Description, TransferLine."Receipt Date", ReservQty, ReservQtyBase, true);

        TransferLine.Modify();
    end;


    procedure ReserveBindingOrderToReqLine(var DemandRequisitionLine: Record "Requisition Line"; var SupplyRequisitionLine: Record "Requisition Line")
    var
        TrackingSpecification: Record "Tracking Specification";
        ReservQty: Decimal;
        ReservQtyBase: Decimal;
    begin
        TrackingSpecification.InitTrackingSpecification(
            Database::"Requisition Line",
            0, DemandRequisitionLine."Worksheet Template Name", DemandRequisitionLine."Journal Batch Name", 0, DemandRequisitionLine."Line No.",
            DemandRequisitionLine."Variant Code", DemandRequisitionLine."Location Code", DemandRequisitionLine."Qty. per Unit of Measure");

        ReservQty := SupplyRequisitionLine."Needed Quantity";
        ReservQtyBase := SupplyRequisitionLine."Needed Quantity (Base)";

        SupplyRequisitionLine.ReserveBindingOrder(
            TrackingSpecification, DemandRequisitionLine.Description, DemandRequisitionLine."Due Date", ReservQty, ReservQtyBase, true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCarryOutToReqWksh(var RequisitionLine: Record "Requisition Line"; var RequisitionLine2: Record "Requisition Line"; ReqWkshTempName: Code[10]; ReqJournalName: Code[10]; LineNo: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteOrderLines(RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterDeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;




    [IntegrationEvent(false, false)]
    local procedure OnAfterInsertTransLine(var TransHeader: Record "Transfer Header"; var ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line"; var NextLineNo: Integer);
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnAfterTransLineInsert(var TransferLine: Record "Transfer Line"; RequisitionLine: Record "Requisition Line")
    begin
    end;






    [IntegrationEvent(false, false)]
    local procedure OnBeforeCopyDimensionsFromReqToTransLine(var TransferLine: Record "Transfer Line"; RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteOrderLines(RequisitionLine: Record "Requisition Line")
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeletePurchaseLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteRequisitionLine(var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeDeleteTransferLines(RequisitionLine: Record "Requisition Line"; var IsHandled: Boolean)
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertTransHeader(ReqLine: Record "Requisition Line"; var TransHeader: Record "Transfer Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchaseOrder(var PurchaseHeader: Record "Purchase Header"; var IsHandled: Boolean; PrintOrder: Boolean)
    begin
    end;






    [IntegrationEvent(false, false)]
    local procedure OnCarryOutToReqWkshOnAfterPlanningCompInsert(var PlanningComponent: Record "Planning Component"; PlanningComponent2: Record "Planning Component")
    begin
    end;


    [IntegrationEvent(false, false)]
    local procedure OnCarryOutToReqWkshOnBeforeReqLineInsert(var ReqLine: Record "Requisition Line"; var ReqWkshTempName: Code[10]; var ReqJournalName: Code[10]; var LineNo: Integer);
    begin
    end;




    [IntegrationEvent(false, false)]
    local procedure OnInsertTransLineWithReqLine(var TransferLine: Record "Transfer Line"; var RequisitionLine: Record "Requisition Line"; var NextLineNo: Integer)
    begin
    end;







    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterGetPurchHeader(var PurchaseHeader: Record "Purchase Header"; var PurchaseLine: Record "Purchase Line"; var RequisitionLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterGetPurchLine(var PurchaseLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnBeforePurchLineModify(var ReqLine: Record "Requisition Line"; var PurchLine: Record "Purchase Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnTransOrderChgAndResheduleOnBeforeTransLineModify(var ReqLine: Record "Requisition Line"; var TransLine: Record "Transfer Line")
    begin
    end;





    [IntegrationEvent(false, false)]
    local procedure OnInsertTransHeaderOnBeforeTransHeaderInsert(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransHeaderOnAfterTransHeaderInsert(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransHeaderOnBeforeTransHeaderModify(var TransHeader: Record "Transfer Header"; ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransLineOnAfterCalcShouldInsertTransHeader(RequisitionLine: Record "Requisition Line"; TransferHeader: Record "Transfer Header"; var Result: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInsertTransLineOnAfterTransLineInit(var TransLine: Record "Transfer Line"; ReqLine: Record "Requisition Line")
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnPrintTransferOrderOnBeforePrintWithDialogWithCheckForCust(var ReportSelections: Record "Report Selections")
    begin
    end;




    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromTransOrderOnBeforeTransOrderChgAndReshedule(ReqLine: Record "Requisition Line"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnCarryOutActionsFromTransOrderOnBeforeInsertTransLine(ReqLine: Record "Requisition Line"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintPurchaseOrder2(var PurchHeader: Record "Purchase Header"; PrintOrder: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnBeforeValidateExpectedReceiptDate(var ReqLine: Record "Requisition Line")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRunOnBeforeCalcProductionExist(RequisitionLine: Record "Requisition Line"; TryChoice: Option; TryWkshTempl: Code[10]; TryWkshName: Code[10]; var ProductionExist: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCarryOutTransOrder(SplitTransferOrders: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintMultiplePurchaseDocs(var TempPurchaseHeader: Record "Purchase Header" temporary; var IsHandled: Boolean)
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnBeforeRun(var Rec: Record "Requisition Line")
    begin
    end;



    [IntegrationEvent(false, false)]
    local procedure OnTrySourceTypeForAssembly(var RequisitionLine: Record "Requisition Line"; TryChoice: Option; var AssemblyExist: Boolean; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(true, false)]
    local procedure OnTrySourceTypeForProduction(var RequisitionLine: Record "Requisition Line"; TryChoice: Option; TryWkshTempl: Code[10]; TryWkshName: Code[10]; var ProductionExist: Boolean; var TempDocumentEntry: Record "Document Entry" temporary)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPurchOrderChgAndResheduleOnAfterPurchaseLineExistsCheck(RequisitionLine: Record "Requisition Line"; var PurchaseLine: Record "Purchase Line"; var PurchaseLineExists: Boolean)
    begin
    end;
}

