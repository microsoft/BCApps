// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Service.Item;

using Microsoft.Inventory.Item;
using Microsoft.Inventory.Ledger;
using Microsoft.Inventory.Tracking;
using Microsoft.Service.Contract;
using Microsoft.Service.Document;
using Microsoft.Service.Loaner;
using Microsoft.Service.History;
using System.IO;

codeunit 6473 "Serv. Item Track Navigate Mgt"
{
    var
        ServItemLine: Record "Service Item Line";
        Loaner: Record Loaner;
        ServiceItem: Record "Service Item";
        ServiceItemComponent: Record "Service Item Component";
        ServContractLine: Record "Service Contract Line";
        FiledContractLine: Record "Filed Contract Line";
        ItemTrackingSetup: Record "Item Tracking Setup";
        RecRef: RecordRef;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindTrackingRecordsOnAfterFindSerialNo', '', false, false)]
    local procedure OnFindTrackingRecordsOnAfterFindSerialNo(var TempRecordBuffer: Record "Record Buffer" temporary; var ItemFilters: Record Item; sender: Codeunit "Item Tracking Navigate Mgt.");
    begin
        FindSerialNoServItemLine(ItemFilters, sender);
        FindSerialNoLoaner(ItemFilters, sender);
        FindSerialNoServiceItem(ItemFilters, sender);
        FindSerialNoServiceItemComponent(ItemFilters, sender);
        FindSerialNoServContractLine(ItemFilters, sender);
        FindSerialNoFiledContractLine(ItemFilters, sender);
    end;

    local procedure FindSerialNoServItemLine(var ItemFilters: Record Item; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if not ServItemLine.ReadPermission then
            exit;

        ServItemLine.Reset();
        if ServItemLine.SetCurrentKey("Serial No.") then;
        ServItemLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServItemLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ServItemLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServItemLine.FindSet() then
            repeat
                RecRef.GetTable(ServItemLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServItemLine."Serial No.";
                ItemTrackingNavigateMgt.InsertBufferRec(RecRef, ItemTrackingSetup, ServItemLine."Item No.", ServItemLine."Variant Code");
            until ServItemLine.Next() = 0;
    end;

    local procedure FindSerialNoServiceItem(var ItemFilters: Record Item; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if not ServiceItem.ReadPermission then
            exit;

        ServiceItem.Reset();
        if ServiceItem.SetCurrentKey("Serial No.") then;
        ServiceItem.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServiceItem.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ServiceItem.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServiceItem.FindSet() then
            repeat
                RecRef.GetTable(ServiceItem);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServiceItem."Serial No.";
                ItemTrackingNavigateMgt.InsertBufferRec(RecRef, ItemTrackingSetup, ServiceItem."Item No.", ServiceItem."Variant Code");
            until ServiceItem.Next() = 0;
    end;

    local procedure FindSerialNoServiceItemComponent(var ItemFilters: Record Item; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if not ServiceItemComponent.ReadPermission then
            exit;

        ServiceItemComponent.Reset();
        if ServiceItemComponent.SetCurrentKey("Serial No.") then;
        ServiceItemComponent.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServiceItemComponent.SetFilter("Parent Service Item No.", ItemFilters.GetFilter("No."));
        ServiceItemComponent.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServiceItemComponent.FindSet() then
            repeat
                RecRef.GetTable(ServiceItemComponent);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServiceItemComponent."Serial No.";
                ItemTrackingNavigateMgt.InsertBufferRec(RecRef, ItemTrackingSetup, ServiceItemComponent."Parent Service Item No.", ServiceItemComponent."Variant Code");
            until ServiceItemComponent.Next() = 0;
    end;

    local procedure FindSerialNoServContractLine(var ItemFilters: Record Item; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if not ServContractLine.ReadPermission then
            exit;

        ServContractLine.Reset();
        if ServContractLine.SetCurrentKey("Serial No.") then;
        ServContractLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        ServContractLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        ServContractLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if ServContractLine.FindSet() then
            repeat
                RecRef.GetTable(ServContractLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := ServContractLine."Serial No.";
                ItemTrackingNavigateMgt.InsertBufferRec(RecRef, ItemTrackingSetup, ServContractLine."Item No.", ServContractLine."Variant Code");
            until ServContractLine.Next() = 0;
    end;

    local procedure FindSerialNoLoaner(var ItemFilters: Record Item; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if not Loaner.ReadPermission then
            exit;

        Loaner.Reset();
        if Loaner.SetCurrentKey("Serial No.") then;
        Loaner.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        Loaner.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        if Loaner.FindSet() then
            repeat
                RecRef.GetTable(Loaner);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := Loaner."Serial No.";
                ItemTrackingNavigateMgt.InsertBufferRec(RecRef, ItemTrackingSetup, Loaner."Item No.", '');
            until Loaner.Next() = 0;
    end;

    local procedure FindSerialNoFiledContractLine(var ItemFilters: Record Item; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    begin
        if not FiledContractLine.ReadPermission then
            exit;

        FiledContractLine.Reset();
        if FiledContractLine.SetCurrentKey("Serial No.") then;
        FiledContractLine.SetFilter("Serial No.", ItemFilters.GetFilter("Serial No. Filter"));
        FiledContractLine.SetFilter("Item No.", ItemFilters.GetFilter("No."));
        FiledContractLine.SetFilter("Variant Code", ItemFilters.GetFilter("Variant Filter"));
        if FiledContractLine.FindSet() then
            repeat
                RecRef.GetTable(FiledContractLine);
                Clear(ItemTrackingSetup);
                ItemTrackingSetup."Serial No." := FiledContractLine."Serial No.";
                ItemTrackingNavigateMgt.InsertBufferRec(RecRef, ItemTrackingSetup, FiledContractLine."Item No.", FiledContractLine."Variant Code");
            until FiledContractLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnSearchValueEntriesOnAfterFindValueEntry', '', false, false)]
    local procedure OnSearchValueEntriesOnAfterFindValueEntry(ValueEntry: Record "Value Entry"; sender: Codeunit "Item Tracking Navigate Mgt.");
    begin
        case ValueEntry."Document Type" of
            ValueEntry."Document Type"::"Service Invoice":
                FindServInvoice(ValueEntry."Document No.", sender);
            ValueEntry."Document Type"::"Service Credit Memo":
                FindServCrMemo(ValueEntry."Document No.", sender);
        end;
    end;

    local procedure FindServInvoice(DocumentNo: Code[20]; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    var
        ServInvHeader: Record "Service Invoice Header";
    begin
        if not ServInvHeader.ReadPermission then
            exit;

        if ServInvHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ServInvHeader);
            ItemTrackingNavigateMgt.InsertBufferRecFromItemLedgEntry();
        end;
    end;

    local procedure FindServCrMemo(DocumentNo: Code[20]; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    var
        ServCrMemoHeader: Record "Service Cr.Memo Header";
    begin
        if not ServCrMemoHeader.ReadPermission then
            exit;

        if ServCrMemoHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ServCrMemoHeader);
            ItemTrackingNavigateMgt.InsertBufferRecFromItemLedgEntry();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindReservEntryOnBeforeCaseDocumentType', '', false, false)]
    local procedure OnFindReservEntryOnBeforeCaseDocumentType(var ReservationEntry: Record "Reservation Entry"; var sender: Codeunit "Item Tracking Navigate Mgt.");
    begin
        case ReservationEntry."Source Type" of
            Database::"Service Line":
                FindServiceLines(ReservationEntry, sender);
        end;
    end;

    local procedure FindServiceLines(ReservationEntry: Record "Reservation Entry"; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    var
        ServLine: Record "Service Line";
    begin
        if not ServLine.ReadPermission then
            exit;

        if ServLine.Get(ReservationEntry."Source Subtype", ReservationEntry."Source ID", ReservationEntry."Source Ref. No.") then begin
            RecRef.GetTable(ServLine);
            ItemTrackingNavigateMgt.InsertBufferRecFromReservEntry();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnFindItemLedgerEntryOnBeforeCaseDocumentType', '', false, false)]
    local procedure OnFindItemLedgerEntryOnBeforeCaseDocumentType(var ItemLedgerEntry: Record "Item Ledger Entry"; var sender: Codeunit "Item Tracking Navigate Mgt.")
    begin
        case ItemLedgerEntry."Document Type" of
            ItemLedgerEntry."Document Type"::"Service Shipment":
                FindServShptHeader(ItemLedgerEntry."Document No.", sender);
            ItemLedgerEntry."Document Type"::"Service Invoice":
                FindServInvoice(ItemLedgerEntry."Document No.", sender);
            ItemLedgerEntry."Document Type"::"Service Credit Memo":
                FindServCrMemo(ItemLedgerEntry."Document No.", sender);
        end;
    end;

    local procedure FindServShptHeader(DocumentNo: Code[20]; var ItemTrackingNavigateMgt: Codeunit "Item Tracking Navigate Mgt.")
    var
        ServShptHeader: Record "Service Shipment Header";
    begin
        if not ServShptHeader.ReadPermission then
            exit;

        if ServShptHeader.Get(DocumentNo) then begin
            RecRef.GetTable(ServShptHeader);
            ItemTrackingNavigateMgt.InsertBufferRecFromItemLedgEntry();
            // Find Invoice if it exists
            ItemTrackingNavigateMgt.SearchValueEntries();
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Item Tracking Navigate Mgt.", 'OnShowTable', '', false, false)]
    local procedure OnShowTable(TableNo: Integer; var TempRecordBuffer: Record "Record Buffer" temporary)
    begin
        case TableNo of
            Database::"Service Item Line":
                Page.Run(0, ServItemLine);
            Database::Loaner:
                Page.Run(0, Loaner);
            Database::"Service Item":
                Page.Run(0, ServiceItem);
            Database::"Service Item Component":
                Page.Run(0, ServiceItemComponent);
            Database::"Service Contract Line":
                Page.Run(0, ServContractLine);
            Database::"Filed Contract Line":
                Page.Run(0, FiledContractLine);
            Database::"Service Shipment Header":
                ShowServiceShipmentHeader(TableNo, TempRecordBuffer);
            Database::"Service Invoice Header":
                ShowServiceInvoiceHeader(TableNo, TempRecordBuffer);
            Database::"Service Cr.Memo Header":
                ShowServiceCrMemoHeader(TableNo, TempRecordBuffer);
            Database::"Service Line":
                ShowServiceLine(TableNo, TempRecordBuffer);
        end;
    end;

    local procedure ShowServiceLine(TableNo: Integer; var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        TempServLine: Record "Service Line" temporary;
    begin
        TempServLine.DeleteAll();
        TempRecordBuffer.SetRange("Table No.", TableNo);
        if TempRecordBuffer.FindSet() then
            repeat
                RecRef := TempRecordBuffer.RecordId.GetRecord();
                RecRef.SetTable(TempServLine);
                TempServLine.Insert();
            until TempRecordBuffer.Next() = 0;
        Page.Run(0, TempServLine);
    end;

    local procedure ShowServiceShipmentHeader(TableNo: Integer; var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        TempServShptHeader: Record "Service Shipment Header" temporary;
    begin
        TempServShptHeader.DeleteAll();
        TempRecordBuffer.SetRange("Table No.", TableNo);
        if TempRecordBuffer.FindSet() then
            repeat
                RecRef := TempRecordBuffer.RecordId.GetRecord();
                RecRef.SetTable(TempServShptHeader);
                TempServShptHeader.Insert();
            until TempRecordBuffer.Next() = 0;
        Page.Run(0, TempServShptHeader);
    end;

    local procedure ShowServiceInvoiceHeader(TableNo: Integer; var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        TempServiceInvoiceHeader: Record "Service Invoice Header" temporary;
    begin
        TempServiceInvoiceHeader.DeleteAll();
        TempRecordBuffer.SetRange("Table No.", TableNo);
        if TempRecordBuffer.FindSet() then
            repeat
                RecRef := TempRecordBuffer.RecordId.GetRecord();
                RecRef.SetTable(TempServiceInvoiceHeader);
                TempServiceInvoiceHeader.Insert();
            until TempRecordBuffer.Next() = 0;
        Page.Run(0, TempServiceInvoiceHeader);
    end;

    local procedure ShowServiceCrMemoHeader(TableNo: Integer; var TempRecordBuffer: Record "Record Buffer" temporary)
    var
        TempServiceCrMemoHeader: Record "Service Cr.Memo Header" temporary;
    begin
        TempServiceCrMemoHeader.DeleteAll();
        TempRecordBuffer.SetRange("Table No.", TableNo);
        if TempRecordBuffer.FindSet() then
            repeat
                RecRef := TempRecordBuffer.RecordId.GetRecord();
                RecRef.SetTable(TempServiceCrMemoHeader);
                TempServiceCrMemoHeader.Insert();
            until TempRecordBuffer.Next() = 0;
        Page.Run(0, TempServiceCrMemoHeader);
    end;
}
