// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Inventory.Tracking;

using Microsoft.Assembly.Document;
using Microsoft.Assembly.History;
using Microsoft.Inventory.Ledger;

codeunit 985 "Asm. ItemTrackingNavigateMgt"
{
    SingleInstance = true;

    var
        TempAssemblyLine: Record "Assembly Line" temporary;
        TempAssemblyHeader: Record "Assembly Header" temporary;
        TempPostedAssemblyLine: Record "Posted Assembly Line" temporary;
        TempPostedAssemblyHeader: Record "Posted Assembly Header" temporary;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindTrackingRecordsOnBeforeFind', '', false, false)]
    local procedure OnFindTrackingRecordsOnBeforeFind()
    begin
        TempAssemblyHeader.DeleteAll();
        TempAssemblyLine.DeleteAll();
        TempPostedAssemblyHeader.DeleteAll();
        TempPostedAssemblyLine.DeleteAll();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindLedgerEntryByDocumentType', '', false, false)]
    local procedure OnFindLedgerEntryByDocumentType(var ItemLedgerEntry: Record "Item Ledger Entry"; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if ItemLedgerEntry."Document Type" = ItemLedgerEntry."Document Type"::"Posted Assembly" then
            FindPostedAssembly(ItemLedgerEntry."Document No.", RecRef, sender);
    end;

    local procedure FindPostedAssembly(DocumentNo: Code[20]; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    var
        PostedAssemblyHeader: Record "Posted Assembly Header";
    begin
        if not PostedAssemblyHeader.ReadPermission then
            exit;

        if PostedAssemblyHeader.Get(DocumentNo) then begin
            RecRef.GetTable(PostedAssemblyHeader);
            sender.InsertBufferRecFromItemLedgEntry();
            TempPostedAssemblyHeader := PostedAssemblyHeader;
            if TempPostedAssemblyHeader.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindReservEntryOnBeforeCaseDocumentType', '', false, false)]
    local procedure OnFindReservEntryOnBeforeCaseDocumentType(var ReservationEntry: Record "Reservation Entry"; RecRef: RecordRef; var IsHandled: Boolean; var sender: Codeunit "Item Tracking Navigate Mgt.")
    begin
        case ReservationEntry."Source Type" of
            Database::"Assembly Header":
                FindAssemblyHeaders(ReservationEntry, RecRef, sender);
            Database::"Assembly Line":
                FindAssemblyLines(ReservationEntry, RecRef, sender);
        end;
    end;

    local procedure FindAssemblyHeaders(ReservEntry: Record "Reservation Entry"; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    var
        AssemblyHeader: Record "Assembly Header";
    begin
        if not AssemblyHeader.ReadPermission then
            exit;

        if AssemblyHeader.Get(ReservEntry."Source Subtype", ReservEntry."Source ID") then begin
            RecRef.GetTable(AssemblyHeader);
            sender.InsertBufferRecFromReservEntry();
            TempAssemblyHeader := AssemblyHeader;
            if TempAssemblyHeader.Insert() then;
        end;
    end;

    local procedure FindAssemblyLines(ReservEntry: Record "Reservation Entry"; RecRef: RecordRef; var sender: Codeunit "Item Tracking Navigate Mgt.")
    var
        AssemblyLine: Record "Assembly Line";
    begin
        if not AssemblyLine.ReadPermission then
            exit;

        if AssemblyLine.Get(ReservEntry."Source Subtype", ReservEntry."Source ID", ReservEntry."Source Ref. No.") then begin
            RecRef.GetTable(AssemblyLine);
            sender.InsertBufferRecFromReservEntry();
            TempAssemblyLine := AssemblyLine;
            if TempAssemblyLine.Insert() then;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnShowTable', '', false, false)]
    local procedure OnShowTable(TableNo: Integer)
    begin
        case TableNo of
            Database::"Assembly Line":
                PAGE.Run(0, TempAssemblyLine);
            Database::"Assembly Header":
                PAGE.Run(0, TempAssemblyHeader);
            Database::"Posted Assembly Line":
                PAGE.Run(0, TempPostedAssemblyLine);
            Database::"Posted Assembly Header":
                PAGE.Run(0, TempPostedAssemblyHeader);
        end;
    end;

}