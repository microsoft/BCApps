// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Warehouse.History;
using Microsoft.Warehouse.Ledger;

codeunit 7328 "Whse. Navigate Mgt."
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedWhseRcptLine: Record "Posted Whse. Receipt Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        PostedWhseShptLine: Record "Posted Whse. Shipment Line";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WarehouseEntry: Record "Warehouse Entry";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindLedgerEntries', '', false, false)]
    local procedure OnAfterFindLedgerEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindWarehouseEntries(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindWarehouseEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if WarehouseEntry.ReadPermission() then begin
            SetWarehouseEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Warehouse Entry", WarehouseEntry.TableCaption(), WarehouseEntry.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', false, false)]
    local procedure OnAfterFindPostedDocuments(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindPostedWhseShptLine(DocumentEntry, DocNoFilter, PostingDateFilter);
        FindPostedWhseRcptLine(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindPostedWhseShptLine(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedWhseShptLine.ReadPermission() then begin
            SetPostedWhseShptLineFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Posted Whse. Shipment Line", PostedWhseShptLine.TableCaption(), PostedWhseShptLine.Count);
        end;
    end;

    local procedure FindPostedWhseRcptLine(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if PostedWhseRcptLine.ReadPermission() then begin
            SetPostedWhseRcptLineFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Posted Whse. Receipt Line", PostedWhseRcptLine.TableCaption(), PostedWhseRcptLine.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"Posted Whse. Shipment Line":
                begin
                    SetPostedWhseShptLineFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, PostedWhseShptLine);
                end;
            Database::"Posted Whse. Receipt Line":
                begin
                    SetPostedWhseRcptLineFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, PostedWhseRcptLine);
                end;
            Database::"Warehouse Entry":
                begin
                    SetWarehouseEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, WarehouseEntry);
                end;
        end;
    end;

    local procedure SetPostedWhseRcptLineFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        PostedWhseRcptLine.Reset();
        PostedWhseRcptLine.SetCurrentKey("Posted Source No.", "Posting Date");
        PostedWhseRcptLine.SetFilter("Posted Source No.", DocNoFilter);
        PostedWhseRcptLine.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetPostedWhseShptLineFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        PostedWhseShptLine.Reset();
        PostedWhseShptLine.SetCurrentKey("Posted Source No.", "Posting Date");
        PostedWhseShptLine.SetFilter("Posted Source No.", DocNoFilter);
        PostedWhseShptLine.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetWarehouseEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        WarehouseEntry.Reset();
        WarehouseEntry.SetCurrentKey("Reference No.", "Registering Date");
        WarehouseEntry.SetFilter("Reference No.", DocNoFilter);
        WarehouseEntry.SetFilter("Registering Date", PostingDateFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindRecordsOnAfterSetSource', '', false, false)]
    local procedure OnFindRecordsOnAfterSetSource(
        var DocumentEntry: Record "Document Entry"; var PostingDate: Date;
        var DocType2: Text[100]; var DocNo: Code[20];
        var SourceType2: Integer; var SourceNo: Code[20];
        var DocNoFilter: Text; var PostingDateFilter: Text;
        var IsHandled: Boolean)
    begin
        if NoOfRecords(DocumentEntry, Database::"Posted Whse. Receipt Line") = 1 then begin
            SetPostedWhseRcptLineFilters(DocNoFilter, PostingDateFilter);
            PostedWhseRcptLine.FindFirst();
            PostingDate := PostedWhseRcptLine."Posting Date";
            DocType2 := Format(DocumentEntry."Table Name");
            DocNo := PostedWhseRcptLine."Posted Source No.";
            SourceType2 := 2;
            SourceNo := '';
            IsHandled := true;
        end;
        if NoOfRecords(DocumentEntry, Database::"Posted Whse. Shipment Line") = 1 then begin
            SetPostedWhseShptLineFilters(DocNoFilter, PostingDateFilter);
            PostedWhseShptLine.FindFirst();
            PostingDate := PostedWhseShptLine."Posting Date";
            DocType2 := Format(DocumentEntry."Table Name");
            DocNo := PostedWhseShptLine."Posted Source No.";
            SourceType2 := 1;
            SourceNo := PostedWhseShptLine."Destination No.";
            IsHandled := true;
        end;
    end;

    local procedure NoOfRecords(var DocumentEntry: Record "Document Entry"; TableID: Integer): Integer
    var
        DocEntryNoOfRecords: Integer;
    begin
        DocumentEntry.SetRange(DocumentEntry."Table ID", TableID);
        if not DocumentEntry.FindFirst() then
            DocumentEntry.Init();
        DocumentEntry.SetRange(DocumentEntry."Table ID");
        DocEntryNoOfRecords := DocumentEntry."No. of Records";
        if not DocumentEntry.FindLast() then
            DocumentEntry.Init();
        exit(DocEntryNoOfRecords);
    end;
}