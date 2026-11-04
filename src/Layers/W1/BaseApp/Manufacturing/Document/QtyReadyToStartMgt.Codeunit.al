// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Document;

using Microsoft.Foundation.UOM;
using Microsoft.Manufacturing.Capacity;

codeunit 99000894 "Qty. Ready to Start Mgt."
{
    Permissions = tabledata "Capacity Ledger Entry" = r;

    /// <summary>
    /// Calculates the quantity ready to start of a production order routing line and stores it on the line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The routing line to update. Only the field Quantity Ready to Start is changed.</param>
    procedure UpdateQtyReadyToStart(var ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        StoreQtyReadyToStart(ProdOrderRoutingLine, CalcQtyReadyToStart(ProdOrderRoutingLine));
    end;

    /// <summary>
    /// Recalculates and stores the quantity ready to start of the operations that follow a production order routing line.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The routing line whose next operations are recalculated. Its Routing Status is used as given, even when the line is not yet modified in the database.</param>
    procedure UpdateSuccessorsQtyReadyToStart(ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    var
        SuccessorProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if ProdOrderRoutingLine."Next Operation No." = '' then
            exit;

        SetRoutingFilters(SuccessorProdOrderRoutingLine, ProdOrderRoutingLine);
        SuccessorProdOrderRoutingLine.SetFilter("Operation No.", ProdOrderRoutingLine."Next Operation No.");
        SuccessorProdOrderRoutingLine.SetLoadFields("Previous Operation No.", "Input Quantity", "Quantity Ready to Start");
        if SuccessorProdOrderRoutingLine.FindSet(true) then
            repeat
                StoreQtyReadyToStart(
                  SuccessorProdOrderRoutingLine, CalcQtyReadyToStart(SuccessorProdOrderRoutingLine, ProdOrderRoutingLine));
            until SuccessorProdOrderRoutingLine.Next() = 0;
    end;

    /// <summary>
    /// Recalculates and stores the quantity ready to start of every routing line of every production order in the current company that is not finished.
    /// </summary>
    internal procedure UpdateQtyReadyToStartForOpenProdOrders()
    var
        ProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        ProdOrderRoutingLine.SetFilter(Status, '<>%1', ProdOrderRoutingLine.Status::Finished);
        ProdOrderRoutingLine.SetLoadFields("Previous Operation No.", "Input Quantity", "Quantity Ready to Start");
        if ProdOrderRoutingLine.FindSet(true) then
            repeat
                UpdateQtyReadyToStart(ProdOrderRoutingLine);
            until ProdOrderRoutingLine.Next() = 0;
    end;

    /// <summary>
    /// Calculates the quantity that the previous operations have made available for a production order routing line to start.
    /// </summary>
    /// <param name="ProdOrderRoutingLine">The routing line to calculate the quantity for.</param>
    /// <returns>The input quantity for a first operation; otherwise the smallest posted output of the previous operations once all of them have reached their start threshold, or zero.</returns>
    internal procedure CalcQtyReadyToStart(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        NoChangedPredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        exit(CalcQtyReadyToStart(ProdOrderRoutingLine, NoChangedPredecessorProdOrderRoutingLine));
    end;

    local procedure CalcQtyReadyToStart(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ChangedPredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line") QtyReadyToStart: Decimal
    var
        IsHandled: Boolean;
    begin
        OnBeforeCalcQtyReadyToStart(ProdOrderRoutingLine, QtyReadyToStart, IsHandled);
        if IsHandled then
            exit(QtyReadyToStart);
        if IsFirstOperation(ProdOrderRoutingLine) then
            QtyReadyToStart := ProdOrderRoutingLine."Input Quantity"
        else
            QtyReadyToStart := CalcQtyReleasedByPredecessors(ProdOrderRoutingLine, ChangedPredecessorProdOrderRoutingLine);

        OnAfterCalcQtyReadyToStart(ProdOrderRoutingLine, QtyReadyToStart);
    end;

    local procedure StoreQtyReadyToStart(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; QtyReadyToStart: Decimal)
    begin
        if ProdOrderRoutingLine."Quantity Ready to Start" = QtyReadyToStart then
            exit;

        ProdOrderRoutingLine."Quantity Ready to Start" := QtyReadyToStart;
        ProdOrderRoutingLine.Modify(false);
    end;

    local procedure IsFirstOperation(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Boolean
    var
        PredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line";
    begin
        if ProdOrderRoutingLine."Previous Operation No." = '' then
            exit(true);

        SetPredecessorFilters(PredecessorProdOrderRoutingLine, ProdOrderRoutingLine);
        exit(PredecessorProdOrderRoutingLine.IsEmpty());
    end;

    local procedure CalcQtyReleasedByPredecessors(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; ChangedPredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line") QtyReleased: Decimal
    var
        PredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line";
        FullLotQty: Decimal;
        IsFirstPredecessor: Boolean;
    begin
        FullLotQty := CalcFullLotQty(ProdOrderRoutingLine);
        IsFirstPredecessor := true;

        SetPredecessorFilters(PredecessorProdOrderRoutingLine, ProdOrderRoutingLine);
        PredecessorProdOrderRoutingLine.SetLoadFields("Send-Ahead Quantity", "Routing Status");
        PredecessorProdOrderRoutingLine.SetAutoCalcFields("Posted Output Quantity");
        if not PredecessorProdOrderRoutingLine.FindSet() then
            exit(0);
        repeat
            if IsSameRoutingLine(PredecessorProdOrderRoutingLine, ChangedPredecessorProdOrderRoutingLine) then
                PredecessorProdOrderRoutingLine."Routing Status" := ChangedPredecessorProdOrderRoutingLine."Routing Status";
            if not HasReachedStartThreshold(PredecessorProdOrderRoutingLine, ProdOrderRoutingLine."Input Quantity", FullLotQty) then
                exit(0);
            if IsFirstPredecessor or (PredecessorProdOrderRoutingLine."Posted Output Quantity" < QtyReleased) then
                QtyReleased := PredecessorProdOrderRoutingLine."Posted Output Quantity";
            IsFirstPredecessor := false;
        until PredecessorProdOrderRoutingLine.Next() = 0;
    end;

    local procedure IsSameRoutingLine(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; OtherProdOrderRoutingLine: Record "Prod. Order Routing Line"): Boolean
    begin
        exit(
          (ProdOrderRoutingLine.Status = OtherProdOrderRoutingLine.Status) and
          (ProdOrderRoutingLine."Prod. Order No." = OtherProdOrderRoutingLine."Prod. Order No.") and
          (ProdOrderRoutingLine."Routing Reference No." = OtherProdOrderRoutingLine."Routing Reference No.") and
          (ProdOrderRoutingLine."Routing No." = OtherProdOrderRoutingLine."Routing No.") and
          (ProdOrderRoutingLine."Operation No." = OtherProdOrderRoutingLine."Operation No."));
    end;

    local procedure HasReachedStartThreshold(PredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line"; InputQty: Decimal; FullLotQty: Decimal): Boolean
    begin
        if PredecessorProdOrderRoutingLine."Routing Status" = PredecessorProdOrderRoutingLine."Routing Status"::Finished then
            exit(true);

        exit(PredecessorProdOrderRoutingLine."Posted Output Quantity" >= GetStartThreshold(PredecessorProdOrderRoutingLine."Send-Ahead Quantity", InputQty, FullLotQty));
    end;

    local procedure GetStartThreshold(SendAheadQty: Decimal; InputQty: Decimal; FullLotQty: Decimal): Decimal
    begin
        if (SendAheadQty > 0) and (SendAheadQty < InputQty) then
            exit(SendAheadQty);

        exit(FullLotQty);
    end;

    local procedure CalcFullLotQty(ProdOrderRoutingLine: Record "Prod. Order Routing Line"): Decimal
    var
        ProdOrderLine: Record "Prod. Order Line";
        UOMMgt: Codeunit "Unit of Measure Management";
    begin
        ProdOrderLine.SetCurrentKey(Status, "Prod. Order No.", "Routing No.", "Routing Reference No.");
        ProdOrderLine.SetRange(Status, ProdOrderRoutingLine.Status);
        ProdOrderLine.SetRange("Prod. Order No.", ProdOrderRoutingLine."Prod. Order No.");
        ProdOrderLine.SetRange("Routing No.", ProdOrderRoutingLine."Routing No.");
        ProdOrderLine.SetRange("Routing Reference No.", ProdOrderRoutingLine."Routing Reference No.");
        ProdOrderLine.SetLoadFields("Qty. Rounding Precision (Base)");
        if not ProdOrderLine.FindFirst() then
            exit(UOMMgt.RoundQty(ProdOrderRoutingLine."Input Quantity"));

        exit(UOMMgt.RoundQty(ProdOrderRoutingLine."Input Quantity", ProdOrderLine."Qty. Rounding Precision (Base)"));
    end;

    local procedure SetPredecessorFilters(var PredecessorProdOrderRoutingLine: Record "Prod. Order Routing Line"; ProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        SetRoutingFilters(PredecessorProdOrderRoutingLine, ProdOrderRoutingLine);
        PredecessorProdOrderRoutingLine.SetFilter("Operation No.", ProdOrderRoutingLine."Previous Operation No.");
    end;

    local procedure SetRoutingFilters(var ProdOrderRoutingLine: Record "Prod. Order Routing Line"; FromProdOrderRoutingLine: Record "Prod. Order Routing Line")
    begin
        ProdOrderRoutingLine.SetRange(Status, FromProdOrderRoutingLine.Status);
        ProdOrderRoutingLine.SetRange("Prod. Order No.", FromProdOrderRoutingLine."Prod. Order No.");
        ProdOrderRoutingLine.SetRange("Routing Reference No.", FromProdOrderRoutingLine."Routing Reference No.");
        ProdOrderRoutingLine.SetRange("Routing No.", FromProdOrderRoutingLine."Routing No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCalcQtyReadyToStart(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var QtyReadyToStart: Decimal; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterCalcQtyReadyToStart(ProdOrderRoutingLine: Record "Prod. Order Routing Line"; var QtyReadyToStart: Decimal)
    begin
    end;
}