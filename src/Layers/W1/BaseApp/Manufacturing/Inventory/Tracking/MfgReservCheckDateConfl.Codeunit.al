// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Manufacturing.Document;

codeunit 99000849 "Mfg. ReservCheckDateConfl"
{
    var
        ReservMgt: Codeunit "Reservation Management";

    procedure ProdOrderLineCheck(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        ProdOrderLineReserve: Codeunit "Prod. Order Line-Reserve";
        IsHandled: Boolean;
    begin
        if not ProdOrderLineReserve.FindReservEntry(ProdOrderLine, ReservationEntry) then
            exit;

        CheckProdOrderLineDateConflict(ProdOrderLine, ForceRequest, ReservationEntry);

        IsHandled := false;
        OnProdOrderLineCheckOnBeforeUpdateDate(ReservationEntry, ProdOrderLine, IsHandled);
#if not CLEAN27
        ReservationCheckDateConfl.RunOnProdOrderLineCheckOnBeforeUpdateDate(ReservationEntry, ProdOrderLine, IsHandled);
#endif
        if not IsHandled then
            ReservationCheckDateConfl.UpdateDate(ReservationEntry, ProdOrderLine."Due Date");

        ReservMgt.SetReservSource(ProdOrderLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ProdOrderLine."Remaining Qty. (Base)");
    end;

    local procedure CheckProdOrderLineDateConflict(ProdOrderLine: Record "Prod. Order Line"; ForceRequest: Boolean; var ReservationEntry: Record "Reservation Entry")
    var
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforeCheckProdOrderLineDateConflict(ProdOrderLine."Due Date", ForceRequest, ReservationEntry, IsHandled);
        if IsHandled then
            exit;

        if ReservationCheckDateConfl.DateConflict(ProdOrderLine."Due Date", ForceRequest, ReservationEntry) then
            if ForceRequest then
                ReservationCheckDateConfl.IssueError(ReservationEntry, ProdOrderLine."Due Date");
    end;

    procedure ProdOrderComponentCheck(ProdOrderComponent: Record "Prod. Order Component"; ForceRequest: Boolean; IsCritical: Boolean): Boolean
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        ProdOrderCompReserve: Codeunit "Prod. Order Comp.-Reserve";
        IsHandled: Boolean;
    begin
        if not ProdOrderCompReserve.FindReservEntry(ProdOrderComponent, ReservationEntry) then
            exit(false);

        IsHandled := false;
        OnProdOrderComponentCheckOnBeforeIssueError(ReservationEntry, ProdOrderComponent, ForceRequest, IsHandled, IsCritical);
#if not CLEAN27
        ReservationCheckDateConfl.RunOnProdOrderComponentCheckOnBeforeIssueError(ReservationEntry, ProdOrderComponent, ForceRequest, IsHandled);
#endif
        if not IsHandled then
            if ReservationCheckDateConfl.DateConflict(ProdOrderComponent."Due Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    if IsCritical then
                        ReservationCheckDateConfl.IssueError(ReservationEntry, ProdOrderComponent."Due Date")
                    else
                        ReservationCheckDateConfl.IssueWarning(ReservationEntry, ProdOrderComponent."Due Date");

        IsHandled := false;
        OnProdOrderComponentCheckOnBeforeUpdateDate(ReservationEntry, ProdOrderComponent, IsHandled);
#if not CLEAN27
        ReservationCheckDateConfl.RunOnProdOrderComponentCheckOnBeforeUpdateDate(ReservationEntry, ProdOrderComponent, IsHandled);
#endif
        if not IsHandled then
            ReservationCheckDateConfl.UpdateDate(ReservationEntry, ProdOrderComponent."Due Date");

        ReservMgt.SetReservSource(ProdOrderComponent);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(ProdOrderComponent."Remaining Qty. (Base)");
        exit(ForceRequest);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation-Check Date Confl.", 'OnSameProdOrderAutoReserve', '', false, false)]
    local procedure OnSameProdOrderAutoReserve(var FilterReservationEntry: Record "Reservation Entry"; var Result: Boolean)
    var
        ProdOrderLineReservationEntry: Record "Reservation Entry";
    begin
        if FilterReservationEntry."Source Type" = Database::"Prod. Order Component" then
            if ProdOrderLineReservationEntry.Get(FilterReservationEntry."Entry No.", not FilterReservationEntry.Positive) then
                if ProdOrderLineReservationEntry."Source Type" = Database::"Prod. Order Line" then
                    if FilterReservationEntry."Source ID" = ProdOrderLineReservationEntry."Source ID" then
                        Result := ProdOrderLineReservationEntry."Source Prod. Order Line" = GetSuppliedByLineNoByReservationEntry(FilterReservationEntry);
    end;

    local procedure GetSuppliedByLineNoByReservationEntry(ReservationEntry2: Record "Reservation Entry"): Integer
    var
        ProdOrderComponent: Record "Prod. Order Component";
    begin
        ProdOrderComponent.Get(
            ReservationEntry2."Source Subtype", ReservationEntry2."Source ID", ReservationEntry2."Source Prod. Order Line", ReservationEntry2."Source Ref. No.");
        exit(ProdOrderComponent."Supplied-by Line No.");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; ProdOrderLine: Record Microsoft.Manufacturing.Document."Prod. Order Line"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeCheckProdOrderLineDateConflict(DueDate: Date; var ForceRequest: Boolean; var ReservationEntry: Record "Reservation Entry"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderComponentCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; ProdOrderComponent: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var ForceRequest: Boolean; var IsHandled: Boolean; var IsCritical: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnProdOrderComponentCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; ProdOrderComp: Record Microsoft.Manufacturing.Document."Prod. Order Component"; var IsHandled: Boolean)
    begin
    end;
}
