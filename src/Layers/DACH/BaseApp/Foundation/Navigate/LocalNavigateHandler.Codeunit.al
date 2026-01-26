// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Purchases.Document;

codeunit 355 "Local Navigate Handler"
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        IssuedDeliveryReminderHeader: Record "Issued Deliv. Reminder Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        DeliveryReminderLedgerEntry: Record "Delivery Reminder Ledger Entry";

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterNavigateFindRecords', '', false, false)]
    local procedure OnAfterNavigateFindRecords(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if DeliveryReminderLedgerEntry.ReadPermission() then begin
            SetDeliveryReminderLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"Delivery Reminder Ledger Entry", DeliveryReminderLedgerEntry.TableCaption(), DeliveryReminderLedgerEntry.Count());
        end;
        if IssuedDeliveryReminderHeader.ReadPermission() then begin
            SetIssuedDeliveryReminderHeaderFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(DATABASE::"Issued Deliv. Reminder Header", IssuedDeliveryReminderHeader.TableCaption(), IssuedDeliveryReminderHeader.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindRecordsOnAfterSetSource', '', false, false)]
    local procedure OnFindRecordsOnAfterSetSource(
        var DocumentEntry: Record "Document Entry"; var PostingDate: Date;
        var DocType2: Text[100]; var DocNo: Code[20];
        var SourceType2: Integer; var SourceNo: Code[20];
        var DocNoFilter: Text; var PostingDateFilter: Text;
        var IsHandled: Boolean)
    begin
        SetIssuedDeliveryReminderHeaderFilters(DocNoFilter, PostingDateFilter);
        if NoOfRecords(DocumentEntry, DATABASE::"Issued Deliv. Reminder Header") = 1 then begin
            IssuedDeliveryReminderHeader.FindFirst();
            PostingDate := IssuedDeliveryReminderHeader."Posting Date";
            DocType2 := Format(DocumentEntry."Table Name");
            DocNo := IssuedDeliveryReminderHeader."No.";
            SourceType2 := 2;
            SourceNo := IssuedDeliveryReminderHeader."Vendor No.";
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

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            DATABASE::"Issued Deliv. Reminder Header":
                begin
                    SetIssuedDeliveryReminderHeaderFilters(DocNoFilter, PostingDateFilter);
                    Page.Run(0, IssuedDeliveryReminderHeader);
                end;
            DATABASE::"Delivery Reminder Ledger Entry":
                begin
                    SetDeliveryReminderLedgerEntryFilters(DocNoFilter, PostingDateFilter);
                    Page.Run(0, DeliveryReminderLedgerEntry);
                end;
        end;
    end;

    local procedure SetDeliveryReminderLedgerEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        DeliveryReminderLedgerEntry.Reset();
        DeliveryReminderLedgerEntry.SetCurrentKey("Reminder No.", "Posting Date");
        DeliveryReminderLedgerEntry.SetFilter("Reminder No.", DocNoFilter);
        DeliveryReminderLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetIssuedDeliveryReminderHeaderFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        IssuedDeliveryReminderHeader.Reset();
        IssuedDeliveryReminderHeader.SetFilter("No.", DocNoFilter);
        IssuedDeliveryReminderHeader.SetFilter("Posting Date", PostingDateFilter);
    end;
}
