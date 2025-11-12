// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Inventory.Ledger;
using Microsoft.Manufacturing.Document;

codeunit 99000885 "Mfg. ItemTrackingNavigateMgt"
{
    SingleInstance = true;

    var
        TempProdOrder: Record "Production Order" temporary;
        TempProdOrderLine: Record "Prod. Order Line" temporary;
        TempProdOrderComp: Record "Prod. Order Component" temporary;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindTrackingRecordsOnBeforeFind', '', false, false)]
    local procedure OnFindTrackingRecordsOnBeforeFind()
    begin
        TempProdOrder.DeleteAll();
        TempProdOrderComp.DeleteAll();
        TempProdOrderLine.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindLedgerEntryByDocumentType', '', false, false)]
    local procedure OnFindLedgerEntryByDocumentType(var ItemLedgerEntry: Record "Item Ledger Entry"; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if ItemLedgerEntry."Entry Type" in [ItemLedgerEntry."Entry Type"::Consumption, ItemLedgerEntry."Entry Type"::Output] then
            FindProductionOrder(ItemLedgerEntry."Document No.", RecRef, sender);
    end;

    local procedure FindProductionOrder(DocumentNo: Code[20]; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    var
        ProdOrder: Record "Production Order";
    begin
        if not ProdOrder.ReadPermission then
            exit;

        ProdOrder.SetRange(Status, ProdOrder.Status::Released, ProdOrder.Status::Finished);
        ProdOrder.SetRange("No.", DocumentNo);
        if ProdOrder.FindFirst() then begin
            RecRef.GetTable(ProdOrder);
            sender.InsertBufferRecFromItemLedgEntry();
            TempProdOrder := ProdOrder;
            if TempProdOrder.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindReservEntryOnBeforeCaseDocumentType', '', false, false)]
    local procedure OnFindReservEntryOnBeforeCaseDocumentType(var ReservationEntry: Record "Reservation Entry"; RecRef: RecordRef; var IsHandled: Boolean; var sender: Codeunit "Item Tracking Navigate Mgt.")
    begin
        case ReservationEntry."Source Type" of
            Database::"Prod. Order Line":
                FindProdOrderLines(ReservationEntry, RecRef, sender);
            Database::"Prod. Order Component":
                FindProdOrderComponents(ReservationEntry, RecRef, sender);
        end;
    end;

    local procedure FindProdOrderLines(ReservEntry: Record "Reservation Entry"; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    var
        ProdOrderLine: Record "Prod. Order Line";
    begin
        if not ProdOrderLine.ReadPermission then
            exit;

        if ProdOrderLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line") then begin
            RecRef.GetTable(ProdOrderLine);
            sender.InsertBufferRecFromReservEntry();
            TempProdOrderLine := ProdOrderLine;
            if TempProdOrderLine.Insert() then;
        end;
    end;

    local procedure FindProdOrderComponents(ReservEntry: Record "Reservation Entry"; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    var
        ProdOrderComp: Record "Prod. Order Component";
    begin
        if not ProdOrderComp.ReadPermission then
            exit;

        if ProdOrderComp.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Prod. Order Line", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(ProdOrderComp);
            sender.InsertBufferRecFromReservEntry();
            TempProdOrderComp := ProdOrderComp;
            if TempProdOrderComp.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnShowTable', '', false, false)]
    local procedure OnShowTable(TableNo: Integer)
    begin
        case TableNo of
            Database::"Production Order":
                PAGE.Run(0, TempProdOrder);
            Database::"Prod. Order Line":
                PAGE.Run(0, TempProdOrderLine);
            Database::"Prod. Order Component":
                PAGE.Run(0, TempProdOrderComp);
        end;
    end;

}