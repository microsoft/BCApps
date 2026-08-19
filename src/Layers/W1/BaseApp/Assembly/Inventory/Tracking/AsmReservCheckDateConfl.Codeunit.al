// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;

codeunit 937 "Asm. ReservCheckDateConfl"
{
    var
        ReservMgt: Codeunit "Reservation Management";

    procedure AssemblyHeaderCheck(AssemblyHeader: Record "Assembly Header"; ForceRequest: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        AssemblyHeaderReserve: Codeunit "Assembly Header-Reserve";
        IsHandled: Boolean;
    begin
        if not AssemblyHeaderReserve.FindReservEntry(AssemblyHeader, ReservationEntry) then
            exit;

        IsHandled := false;
        OnAssemblyHeaderCheckOnBeforeIssueError(ReservationEntry, AssemblyHeader, ForceRequest, IsHandled);
#if not CLEAN27
        ReservationCheckDateConfl.RunOnAssemblyHeaderCheckOnBeforeIssueError(ReservationEntry, AssemblyHeader, ForceRequest, IsHandled);
#endif
        if not IsHandled then
            if ReservationCheckDateConfl.DateConflict(AssemblyHeader."Due Date", ForceRequest, ReservationEntry) then
                if ForceRequest then
                    ReservationCheckDateConfl.IssueError(ReservationEntry, AssemblyHeader."Due Date");

        IsHandled := false;
        OnAssemblyHeaderCheckOnBeforeUpdateDate(ReservationEntry, AssemblyHeader, IsHandled);
#if not CLEAN27
        ReservationCheckDateConfl.RunOnAssemblyHeaderCheckOnBeforeUpdateDate(ReservationEntry, AssemblyHeader, IsHandled);
#endif
        if not IsHandled then
            ReservationCheckDateConfl.UpdateDate(ReservationEntry, AssemblyHeader."Due Date");

        ReservMgt.SetReservSource(AssemblyHeader);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(AssemblyHeader."Remaining Quantity (Base)");
    end;

    procedure AssemblyLineCheck(AssemblyLine: Record "Assembly Line"; ForceRequest: Boolean)
    var
        ReservationEntry: Record "Reservation Entry";
        ReservationCheckDateConfl: Codeunit "Reservation-Check Date Confl.";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
        IsHandled: Boolean;
    begin
        if not AssemblyLineReserve.FindReservEntry(AssemblyLine, ReservationEntry) then
            exit;

        if ReservationCheckDateConfl.DateConflict(AssemblyLine."Due Date", ForceRequest, ReservationEntry) then
            if ForceRequest then
                ReservationCheckDateConfl.IssueError(ReservationEntry, AssemblyLine."Due Date");

        IsHandled := false;
        OnAssemblyLineCheckOnBeforeUpdateDate(ReservationEntry, AssemblyLine, IsHandled);
#if not CLEAN27
        ReservationCheckDateConfl.RunOnAssemblyLineCheckOnBeforeUpdateDate(ReservationEntry, AssemblyLine, IsHandled);
#endif
        if not IsHandled then
            ReservationCheckDateConfl.UpdateDate(ReservationEntry, AssemblyLine."Due Date");

        ReservMgt.SetReservSource(AssemblyLine);
        ReservMgt.ClearSurplus();
        ReservMgt.AutoTrack(AssemblyLine."Remaining Quantity (Base)");
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyHeaderCheckOnBeforeIssueError(var ReservationEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header"; var ForceRequest: Boolean; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyHeaderCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; AssemblyHeader: Record "Assembly Header"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAssemblyLineCheckOnBeforeUpdateDate(var ReservationEntry: Record "Reservation Entry"; AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;
}