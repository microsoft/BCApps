// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;

codeunit 929 "Asm. Get Demand To Reserve"
{
    var
        AssemblyTok: Label 'Assembly';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    if not AssemblyLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not AssemblyLine.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> AssemblyLine."No.") or
                       (ReservationWkshLine."Variant Code" <> AssemblyLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> AssemblyLine."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> AssemblyLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if AssemblyLine.Get(ReservationWorksheetLog."Record ID") then begin
            AssemblyLine.SetRecFilter();
            Page.Run(0, AssemblyLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                LineText :=
                  StrSubstNo(
                    SourceDocTok, AssemblyTok,
                    Enum::"Assembly Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := AssemblyLine;
                    AssemblyLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := AssemblyLine."Due Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        AssemblyLine: Record "Assembly Line";
        AssemblyLineReserve: Codeunit "Assembly Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.SetLoadFields("Remaining Quantity");
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    AssemblyLine.CalcFields("Reserved Quantity");
                    OutstandingQty := AssemblyLine."Remaining Quantity";
                    ReservedQty := AssemblyLine."Reserved Quantity";
                    ReservedFromStockQty := AssemblyLineReserve.GetReservedQtyFromInventory(AssemblyLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                if AssemblyLine.Get(ReservationWkshLine."Record ID") then begin
                    AssemblyLine.SetRecFilter();
                    Page.Run(0, AssemblyLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyLine.Get(ReservationWkshLine."Record ID");
                    AssemblyLine.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Assembly Line":
                begin
                    AssemblyHeader.SetLoadFields("Document Type", "No.");
                    AssemblyHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    PAGE.Run(PAGE::"Assembly Order Statistics", AssemblyHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnCalculateDemandOnAfterSync', '', false, false)]
    local procedure SyncAssemblyOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempAssemblyLine: Record "Assembly Line" temporary;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetAssemblyLines(TempAssemblyLine);
        if TempAssemblyLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Assembly Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempAssemblyLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempAssemblyLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Assembly Line";
            ReservationWkshLine."Source Subtype" := TempAssemblyLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempAssemblyLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempAssemblyLine."Line No.";
            ReservationWkshLine."Record ID" := TempAssemblyLine.RecordId;
            ReservationWkshLine."Item No." := TempAssemblyLine."No.";
            ReservationWkshLine."Variant Code" := TempAssemblyLine."Variant Code";
            ReservationWkshLine."Location Code" := TempAssemblyLine."Location Code";
            ReservationWkshLine.Description := TempAssemblyLine.Description;
            ReservationWkshLine."Description 2" := TempAssemblyLine."Description 2";

            ReservationWkshLine."Demand Date" := TempAssemblyLine."Due Date";
            ReservationWkshLine."Unit of Measure Code" := TempAssemblyLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempAssemblyLine."Qty. per Unit of Measure";

            TempAssemblyLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
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
        until TempAssemblyLine.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempAssemblyLine(var AssemblyLine: Record "Assembly Line"; var IsHandled: Boolean)
    begin
    end;
#endif
}
