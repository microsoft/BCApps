// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Service.Document;
using Microsoft.Sales.Customer;

codeunit 6485 "Serv. Get Demand To Reserve"
{
    var
        ServiceTok: Label 'Service';
        SourceDocTok: Label '%1 %2 %3', Locked = true;

    // Reservation Worksheet

    [EventSubscriber(ObjectType::Table, Database::"Reservation Wksh. Line", 'OnIsOutdated', '', false, false)]
    local procedure OnIsOutdated(ReservationWkshLine: Record "Reservation Wksh. Line"; var Outdated: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    if not ServiceLine.Get(ReservationWkshLine."Record ID") then
                        Outdated := true;
                    if not ServiceLine.IsInventoriableItem() or
                       (ReservationWkshLine."Item No." <> ServiceLine."No.") or
                       (ReservationWkshLine."Variant Code" <> ServiceLine."Variant Code") or
                       (ReservationWkshLine."Location Code" <> ServiceLine."Location Code") or
                       (ReservationWkshLine."Unit of Measure Code" <> ServiceLine."Unit of Measure Code")
                    then
                        Outdated := true;
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::"Reservation Wksh. Log Factbox", 'OnShowDocument', '', false, false)]
    local procedure OnShowDocument(var ReservationWorksheetLog: Record "Reservation Worksheet Log"; var IsHandled: Boolean)
    var
        ServiceLine: Record "Service Line";
    begin
        if ServiceLine.Get(ReservationWorksheetLog."Record ID") then begin
            ServiceLine.SetRecFilter();
            Page.Run(0, ServiceLine);
            IsHandled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnBeforeCreateSourceDocumentText', '', false, false)]
    local procedure OnBeforeCreateSourceDocumentText(var ReservationWkshLine: Record "Reservation Wksh. Line"; var LineText: Text[100])
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                LineText :=
                  StrSubstNo(
                    SourceDocTok, ServiceTok,
                    Enum::"Service Document Type".FromInteger(ReservationWkshLine."Source Subtype"), ReservationWkshLine."Source ID");
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLine', '', false, false)]
    local procedure OnGetSourceDocumentLine(var ReservationWkshLine: Record "Reservation Wksh. Line"; var RecordVariant: Variant; var MaxQtyToReserve: Decimal; var MaxQtyToReserveBase: Decimal; var AvailabilityDate: Date)
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    RecordVariant := ServiceLine;
                    ServiceLine.GetRemainingQty(MaxQtyToReserve, MaxQtyToReserveBase);
                    AvailabilityDate := ServiceLine."Needed by Date";
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnGetSourceDocumentLineQuantities', '', false, false)]
    local procedure OnGetSourceDocumentLineQuantities(var ReservationWkshLine: Record "Reservation Wksh. Line"; var OutstandingQty: Decimal; var ReservedQty: Decimal; var ReservedFromStockQty: Decimal)
    var
        ServiceLine: Record "Service Line";
        ServiceLineReserve: Codeunit "Service Line-Reserve";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.SetLoadFields("Outstanding Quantity");
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    ServiceLine.CalcFields("Reserved Quantity");
                    OutstandingQty := ServiceLine."Outstanding Quantity";
                    ReservedQty := ServiceLine."Reserved Quantity";
                    ReservedFromStockQty := ServiceLineReserve.GetReservedQtyFromInventory(ServiceLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowSourceDocument', '', false, false)]
    local procedure OnShowSourceDocument(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                if ServiceLine.Get(ReservationWkshLine."Record ID") then begin
                    ServiceLine.SetRecFilter();
                    Page.Run(0, ServiceLine);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowReservationEntries', '', false, false)]
    local procedure OnShowReservationEntries(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ServiceLine: Record "Service Line";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceLine.Get(ReservationWkshLine."Record ID");
                    ServiceLine.ShowReservationEntries(false);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnShowStatistics', '', false, false)]
    local procedure OnShowStatistics(var ReservationWkshLine: Record "Reservation Wksh. Line")
    var
        ServiceHeader: Record "Service Header";
    begin
        case ReservationWkshLine."Source Type" of
            Database::"Service Line":
                begin
                    ServiceHeader.SetLoadFields("Document Type", "No.");
                    ServiceHeader.Get(ReservationWkshLine."Source Subtype", ReservationWkshLine."Source ID");
                    Page.Run(Page::"Service Order Statistics", ServiceHeader);
                end;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Reservation Worksheet Mgt.", 'OnCalculateDemandOnAfterSync', '', false, false)]
    local procedure SyncServiceOrderLines(BatchName: Code[10]; var GetDemandToReserve: Report "Get Demand To Reserve")
    var
        ReservationWkshLine: Record "Reservation Wksh. Line";
        TempServiceLine: Record "Service Line" temporary;
        ServiceHeader: Record "Service Header";
        Customer: Record Customer;
        ReservationWorksheetMgt: Codeunit "Reservation Worksheet Mgt.";
        RemainingQty, RemainingQtyBase : Decimal;
        AvailableQtyBase, InventoryQtyBase, ReservedQtyBase, WarehouseQtyBase : Decimal;
        LineNo: Integer;
    begin
        GetDemandToReserve.GetServiceOrderLines(TempServiceLine);
        if TempServiceLine.IsEmpty() then
            exit;

        ReservationWkshLine.SetCurrentKey("Journal Batch Name", "Source Type");
        ReservationWkshLine.SetRange("Journal Batch Name", BatchName);
        ReservationWkshLine.SetRange("Source Type", Database::"Service Line");
        if ReservationWkshLine.FindSet(true) then
            repeat
                if ReservationWkshLine.IsOutdated() or TempServiceLine.Get(ReservationWkshLine."Record ID") then
                    ReservationWkshLine.Delete(true);
            until ReservationWkshLine.Next() = 0;

        ReservationWkshLine."Journal Batch Name" := BatchName;
        LineNo := ReservationWkshLine.GetLastLineNo();

        TempServiceLine.FindSet();
        repeat
            LineNo += 10000;
            ReservationWkshLine.Init();
            ReservationWkshLine."Journal Batch Name" := BatchName;
            ReservationWkshLine."Line No." := LineNo;
            ReservationWkshLine."Source Type" := Database::"Service Line";
            ReservationWkshLine."Source Subtype" := TempServiceLine."Document Type".AsInteger();
            ReservationWkshLine."Source ID" := TempServiceLine."Document No.";
            ReservationWkshLine."Source Ref. No." := TempServiceLine."Line No.";
            ReservationWkshLine."Record ID" := TempServiceLine.RecordId;
            ReservationWkshLine."Item No." := TempServiceLine."No.";
            ReservationWkshLine."Variant Code" := TempServiceLine."Variant Code";
            ReservationWkshLine."Location Code" := TempServiceLine."Location Code";
            ReservationWkshLine.Description := TempServiceLine.Description;
            ReservationWkshLine."Description 2" := TempServiceLine."Description 2";

            ServiceHeader.Get(TempServiceLine."Document Type", TempServiceLine."Document No.");
            ReservationWkshLine."Sell-to Customer No." := ServiceHeader."Customer No.";
            ReservationWkshLine."Sell-to Customer Name" := ServiceHeader.Name;
            Customer.SetLoadFields(Priority);
            if Customer.Get(ReservationWkshLine."Sell-to Customer No.") then
                ReservationWkshLine.Priority := Customer.Priority;

            ReservationWkshLine."Demand Date" := TempServiceLine."Needed by Date";
            ReservationWkshLine."Unit of Measure Code" := TempServiceLine."Unit of Measure Code";
            ReservationWkshLine."Qty. per Unit of Measure" := TempServiceLine."Qty. per Unit of Measure";

            TempServiceLine.GetRemainingQty(RemainingQty, RemainingQtyBase);
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
        until TempServiceLine.Next() = 0;
    end;

#if not CLEAN27
    [Obsolete('This event is never raised.', '27.0')]
    [IntegrationEvent(false, false)]
    local procedure OnGetDemandOnBeforeSetTempServiceLine(var ServiceLine: Record "Service Line"; var IsHandled: Boolean)
    begin
    end;
#endif
}
