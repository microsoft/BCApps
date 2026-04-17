// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Manufacturing.Subcontracting;

using Microsoft.Foundation.Navigate;

codeunit 99001562 "Subc. WIP Item Ledg Find Entry"
{

    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        SubcontractorWIPLedgerEntry: Record "Subcontractor WIP Ledger Entry";


    [EventSubscriber(ObjectType::Page, Page::Navigate, OnAfterFindLedgerEntries, '', false, false)]
    local procedure OnFindWIPLedgerEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindWIPItemEntries(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindWIPItemEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if SubcontractorWIPLedgerEntry.ReadPermission() then begin
            FilterWIPLedgerEntries(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Subcontractor WIP Ledger Entry", SubcontractorWIPLedgerEntry.TableCaption(), SubcontractorWIPLedgerEntry.Count);
        end;
    end;

    local procedure FilterWIPLedgerEntries(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        SubcontractorWIPLedgerEntry.Reset();
        SubcontractorWIPLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        SubcontractorWIPLedgerEntry.SetFilter("Document No.", DocNoFilter);
        SubcontractorWIPLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, OnAfterShowRecords, '', false, false)]
    local procedure OnShowWIPLedgerEntries(var Sender: Page Navigate; var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; ContactType: Enum "Navigate Contact Type"; ContactNo: Code[250]; ExtDocNo: Code[250])
    begin
        if DocumentEntry."Table ID" = Database::"Subcontractor WIP Ledger Entry" then begin
            FilterWIPLedgerEntries(DocNoFilter, PostingDateFilter);
            Page.Run(0, SubcontractorWIPLedgerEntry);
        end;
    end;
}