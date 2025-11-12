// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Projects.Project.Planning;
using Microsoft.Projects.Project.Job;
using Microsoft.Sales.Customer;

codeunit 99000847 "Job Planning Line Get Demand"
{
    var
        ProjectTok: Label 'Project';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                begin
                    if not JobPlanningLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not JobPlanningLine.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> JobPlanningLine."No.") or
                       (ReservationWkshLine."Variant Code" <> JobPlanningLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> JobPlanningLine."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> JobPlanningLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        if JobPlanningLine.Get(ReservationWorksheetLog."Record ID") then begin
            JobPlanningLine.SetRecFilter();
            Page.Run(0, JobPlanningLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                LineText := StrSubstNo(SourceDocTok, ProjectTok, ReservationWkshLine."Source ID", '');
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := JobPlanningLine;
                    JobPlanningLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := JobPlanningLine."Planning Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        JobPlanningLine: Record "Job Planning Line";
        JobPlanningLineReserve: Codeunit "Job Planning Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.SetLoadFields("Remaining Qty.");
                    JobPlanningLine.Get(ReservationWkshLine."Record ID");
                    JobPlanningLine.CalcFields("Reserved Quantity");
                    OutstandingQty := JobPlanningLine."Remaining Qty.";
                    ReservedQty := JobPlanningLine."Reserved Quantity";
                    ReservedFromStockQty := JobPlanningLineReserve.GetReservedQtyFromInventory(JobPlanningLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                if JobPlanningLine.Get(ReservationWkshLine."Record ID") then begin
                    JobPlanningLine.SetRecFilter();
                    Page.Run(0, JobPlanningLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        JobPlanningLine: Record "Job Planning Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                begin
                    JobPlanningLine.Get(ReservationWkshLine."Record ID");
                    JobPlanningLine.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        Job: Record Job;
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Job Planning Line":
                begin
                    Job.SetLoadFields("No.");
                    Job.Get(ReservationWkshLine."Source ID");
                    Page.RunModal(Page::"Job Statistics", Job);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnCalculateDemandOnAfterSync', '', false, false)]
    local procedure SyncJobPlanningLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempJobPlanningLine: Record "Job Planning Line" temporary;
        Job: Record Job;
        Customer: Record Customer;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetJobPlanningLines(TempJobPlanningLine);
        if TempJobPlanningLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Job Planning Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempJobPlanningLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempJobPlanningLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Job Planning Line";
            ReservationWkshLine."Source Subtype" := TempJobPlanningLine.Status.AsInteger();
            ReservationWkshLine."Source ID" := TempJobPlanningLine."Job No.";
            ReservationWkshLine."Source Ref. No." := TempJobPlanningLine."Job Contract Entry No.";
            ReservationWkshLine."Record ID" := TempJobPlanningLine.RecordId;
            ReservationWkshLine."Item No." := TempJobPlanningLine."No.";
            ReservationWkshLine."Variant Code" := TempJobPlanningLine."Variant Code";
            ReservationWkshLine."Location Code" := TempJobPlanningLine."Location Code";
            ReservationWkshLine.Description := TempJobPlanningLine.Description;
            ReservationWkshLine."Description 2" := TempJobPlanningLine."Description 2";

            Job.Get(TempJobPlanningLine."Job No.");
            ReservationWkshLine."Sell-to Customer No." := Job."Sell-to Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := Job."Sell-to Customer Name";
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempJobPlanningLine."Planning Date";
            ReservationWkshLine."Unit of Measure Code" := TempJobPlanningLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempJobPlanningLine."Qty. per Unit of Measure";

            TempJobPlanningLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
            ReservationWkshLine."Remaining Qty. to Reserve" := RemainingQty;
            ReservationWkshLine."Rem. Qty. to Reserve (Base)" := RemainingQtyBase;

            ReservationWorksheetMgt.GetAvailRemainingQtyOnItemLedgerEntry(
              AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase,
              ReservationWkshLine."Item No.", ReservationWkshLine."Variant Code", ReservationWkshLine."Location Code");

            ReservationWkshLine.Validate("Avail. Qty. to Reserve (Base)", AvailableQtyBase);
            ReservationWkshLine.Validate("Qty. in Stock (Base)", InventoryQtyBase);
            ReservationWkshLine.Validate("Qty. Reserv. in Stock (Base)", ReservedQtyBase);
            ReservationWkshLine.Validate("Qty. in Whse. Handling (Base)", WarehouseQtyBase);

            if (ReservationWkshLine."Remaining Qty. to Reserve" > 0) and
               (ReservationWkshLine."Available Qty. to Reserve" > 0)
            then
                ReservationWkshLine.Insert(true);
        until TempJobPlanningLine.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempJobPlanningLine(var JobPlanningLine: Record "Job Planning Line"; var IsHandled: Boolean)
    begin
    end;
#endif
}
