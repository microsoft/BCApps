// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Ledger;

codeunit 6494 "Serv. Navigate Mgt."
{
    var
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServShptHeader: Record "Service Shipment Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServInvHeader: Record "Service Invoice Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServCrMemoHeader: Record "Service Cr.Memo Header";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServLedgerEntry: Record "Service Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        WarrantyLedgerEntry: Record "Warranty Ledger Entry";
        [SecurityFiltering(SecurityFilter::Filtered)]
        ServiceHeader: Record Microsoft.Service.Document."Service Header";

        PostedServiceInvoiceTxt: Label 'Posted Service Invoice';
        PostedServiceCreditMemoTxt: Label 'Posted Service Credit Memo';
        PostedServiceShipmentTxt: Label 'Posted Service Shipment';
        ServiceOrderTxt: Label 'Service Order';
        ServiceInvoiceTxt: Label 'Service Invoice';
        ServiceCreditMemoTxt: Label 'Service Credit Memo';

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', false, false)]
    local procedure OnAfterFindPostedDocuments(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindServShipmentHeader(DocumentEntry, DocNoFilter, PostingDateFilter);
        FindServInvoiceHeader(DocumentEntry, DocNoFilter, PostingDateFilter);
        FindServCrMemoHeader(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindServShipmentHeader(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServShptHeader.ReadPermission() then begin
            SetServiceShipmentHeaderFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Service Shipment Header", PostedServiceShipmentTxt, ServShptHeader.Count);
        end;
    end;

    local procedure FindServInvoiceHeader(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServInvHeader.ReadPermission() then begin
            SetServiceInvoiceHeaderFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Service Invoice Header", PostedServiceInvoiceTxt, ServInvHeader.Count);
        end;
    end;

    local procedure FindServCrMemoHeader(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServCrMemoHeader.ReadPermission() then begin
            SetServiceCrMemoHeaderFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Service Cr.Memo Header", PostedServiceCreditMemoTxt, ServCrMemoHeader.Count);
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindLedgerEntries', '', false, false)]
    local procedure OnAfterFindLedgerEntries(var DocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        FindServEntries(DocumentEntry, DocNoFilter, PostingDateFilter);
    end;

    local procedure FindServEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') then
            exit;
        if ServLedgerEntry.ReadPermission() then begin
            SetServiceLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Service Ledger Entry", ServLedgerEntry.TableCaption(), ServLedgerEntry.Count);
        end;
        if WarrantyLedgerEntry.ReadPermission() then begin
            SetWarrantyLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            DocumentEntry.InsertIntoDocEntry(Database::"Warranty Ledger Entry", WarrantyLedgerEntry.TableCaption(), WarrantyLedgerEntry.Count);
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
        if NoOfRecords(DocumentEntry, Database::"Service Ledger Entry") = 1 then begin
            SetServiceLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            if ServLedgerEntry.FindFirst() then
                if ServLedgerEntry.Type = ServLedgerEntry.Type::"Service Contract" then begin
                    PostingDate := ServLedgerEntry."Posting Date";
                    DocType2 := Format(ServLedgerEntry."Document Type");
                    DocNo := ServLedgerEntry."Document No.";
                    SourceType2 := 2;
                    SourceNo := ServLedgerEntry."Service Contract No.";
                    IsHandled := true;
                end else begin
                    PostingDate := ServLedgerEntry."Posting Date";
                    DocType2 := Format(ServLedgerEntry."Document Type");
                    DocNo := ServLedgerEntry."Document No.";
                    SourceType2 := 2;
                    SourceNo := ServLedgerEntry."Service Order No.";
                    IsHandled := true;
                end;
        end;
        if NoOfRecords(DocumentEntry, Database::"Warranty Ledger Entry") = 1 then begin
            SetWarrantyLedgerEntryFilters(DocNoFilter, PostingDateFilter);
            if WarrantyLedgerEntry.FindFirst() then begin
                PostingDate := WarrantyLedgerEntry."Posting Date";
                DocType2 := '';
                DocNo := WarrantyLedgerEntry."Document No.";
                SourceType2 := 2;
                SourceNo := WarrantyLedgerEntry."Service Order No.";
                IsHandled := true;
            end;
        end;
        if NoOfRecords(DocumentEntry, Database::"Service Invoice Header") = 1 then begin
            SetServiceInvoiceHeaderFilters(DocNoFilter, PostingDateFilter);
            if ServInvHeader.FindFirst() then begin
                PostingDate := ServInvHeader."Posting Date";
                DocType2 := PostedServiceInvoiceTxt;
                DocNo := ServInvHeader."No.";
                SourceType2 := 1;
                SourceNo := ServInvHeader."Bill-to Customer No.";
                IsHandled := true;
            end;
        end;
        if NoOfRecords(DocumentEntry, Database::"Service Cr.Memo Header") = 1 then begin
            SetServiceCrMemoHeaderFilters(DocNoFilter, PostingDateFilter);
            if ServCrMemoHeader.FindFirst() then begin
                PostingDate := ServCrMemoHeader."Posting Date";
                DocType2 := PostedServiceCreditMemoTxt;
                DocNo := ServCrMemoHeader."No.";
                SourceType2 := 1;
                SourceNo := ServCrMemoHeader."Bill-to Customer No.";
                IsHandled := true;
            end;
        end;
        if NoOfRecords(DocumentEntry, Database::"Service Shipment Header") = 1 then begin
            SetServiceShipmentHeaderFilters(DocNoFilter, PostingDateFilter);
            if ServShptHeader.FindFirst() then begin
                PostingDate := ServShptHeader."Posting Date";
                DocType2 := PostedServiceShipmentTxt;
                DocNo := ServShptHeader."No.";
                SourceType2 := 1;
                SourceNo := ServShptHeader."Customer No.";
                IsHandled := true;
            end;
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

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindExtRecordsForCustomer', '', false, false)]
    local procedure OnFindExtRecordsForCustomer(var DocumentEntry: Record "Document Entry"; ContactNo: Code[20]; ExtDocNo: Text[35])
    begin
        if ExtDocNo = '' then begin
            FindUnpostedServDocs(DocumentEntry, "Service Document Type"::Order, ServiceOrderTxt, ContactNo);
            FindUnpostedServDocs(DocumentEntry, "Service Document Type"::Invoice, ServiceInvoiceTxt, ContactNo);
            FindUnpostedServDocs(DocumentEntry, "Service Document Type"::"Credit Memo", ServiceCreditMemoTxt, ContactNo);
        end;
        if ServShptHeader.ReadPermission() then
            if ExtDocNo = '' then begin
                ServShptHeader.Reset();
                ServShptHeader.SetCurrentKey("Customer No.");
                ServShptHeader.SetFilter("Customer No.", ContactNo);
                DocumentEntry.InsertIntoDocEntry(Database::"Service Shipment Header", PostedServiceShipmentTxt, ServShptHeader.Count);
            end;
        if ServInvHeader.ReadPermission() then
            if ExtDocNo = '' then begin
                ServInvHeader.Reset();
                ServInvHeader.SetCurrentKey("Customer No.");
                ServInvHeader.SetFilter("Customer No.", ContactNo);
                DocumentEntry.InsertIntoDocEntry(Database::"Service Invoice Header", PostedServiceInvoiceTxt, ServInvHeader.Count);
            end;
        if ServCrMemoHeader.ReadPermission() then
            if ExtDocNo = '' then begin
                ServCrMemoHeader.Reset();
                ServCrMemoHeader.SetCurrentKey("Customer No.");
                ServCrMemoHeader.SetFilter("Customer No.", ContactNo);
                DocumentEntry.InsertIntoDocEntry(Database::"Service Cr.Memo Header", PostedServiceCreditMemoTxt, ServCrMemoHeader.Count);
            end;
    end;

    local procedure FindUnpostedServDocs(var DocumentEntry: Record "Document Entry"; DocType: Enum "Service Document Type"; DocTableName: Text[100]; CustomerNo: Code[20])
    begin
        if CustomerNo = '' then
            exit;
        ServiceHeader."SecurityFiltering"(SECURITYFILTER::Filtered);
        if not ServiceHeader.ReadPermission() then
            exit;

        SetServiceHeaderFilters(DocType, CustomerNo);
        DocumentEntry.InsertIntoDocEntry(Database::"Service Header", DocType, DocTableName, ServiceHeader.Count());
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text; var IsHandled: Boolean; ContactNo: Code[250])
    begin
        case TempDocumentEntry."Table ID" of
            Database::"Service Header":
                ShowServiceHeaderRecords(TempDocumentEntry, ContactNo);
            Database::"Service Invoice Header":
                begin
                    SetServiceInvoiceHeaderFilters(DocNoFilter, PostingDateFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Invoice", ServInvHeader)
                    else
                        PAGE.Run(0, ServInvHeader);
                end;
            Database::"Service Cr.Memo Header":
                begin
                    SetServiceCrMemoHeaderFilters(DocNoFilter, PostingDateFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Credit Memo", ServCrMemoHeader)
                    else
                        PAGE.Run(0, ServCrMemoHeader);
                end;
            Database::"Service Shipment Header":
                begin
                    SetServiceShipmentHeaderFilters(DocNoFilter, PostingDateFilter);
                    if TempDocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Posted Service Shipment", ServShptHeader)
                    else
                        PAGE.Run(0, ServShptHeader);
                end;
            Database::"Service Ledger Entry":
                begin
                    SetServiceLedgerEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, ServLedgerEntry);
                end;
            Database::"Warranty Ledger Entry":
                begin
                    SetWarrantyLedgerEntryFilters(DocNoFilter, PostingDateFilter);
                    PAGE.Run(0, WarrantyLedgerEntry);
                end;
        end;
    end;

    local procedure ShowServiceHeaderRecords(var DocumentEntry: Record "Document Entry"; CustomerNo: Code[250])
    begin
        DocumentEntry.TestField("Table ID", Database::"Service Header");

        case DocumentEntry."Document Type" of
            DocumentEntry."Document Type"::Order:
                begin
                    SetServiceHeaderFilters(DocumentEntry."Document Type", CustomerNo);
                    if DocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Service Order", ServiceHeader)
                    else
                        PAGE.Run(0, ServiceHeader);
                end;
            DocumentEntry."Document Type"::Invoice:
                begin
                    SetServiceHeaderFilters(DocumentEntry."Document Type", CustomerNo);
                    if DocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Service Invoice", ServiceHeader)
                    else
                        PAGE.Run(0, ServiceHeader);
                end;
            DocumentEntry."Document Type"::"Credit Memo":
                begin
                    SetServiceHeaderFilters(DocumentEntry."Document Type", CustomerNo);
                    if DocumentEntry."No. of Records" = 1 then
                        PAGE.Run(PAGE::"Service Credit Memo", ServiceHeader)
                    else
                        PAGE.Run(0, ServiceHeader);
                end;
        end;
    end;

    local procedure SetServiceShipmentHeaderFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        ServShptHeader.Reset();
        ServShptHeader.SetFilter("No.", DocNoFilter);
        ServShptHeader.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetServiceInvoiceHeaderFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        ServInvHeader.Reset();
        ServInvHeader.SetFilter("No.", DocNoFilter);
        ServInvHeader.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetServiceCrMemoHeaderFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        ServCrMemoHeader.Reset();
        ServCrMemoHeader.SetFilter("No.", DocNoFilter);
        ServCrMemoHeader.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetServiceLedgerEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        ServLedgerEntry.Reset();
        ServLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        ServLedgerEntry.SetFilter("Document No.", DocNoFilter);
        ServLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetWarrantyLedgerEntryFilters(DocNoFilter: Text; PostingDateFilter: Text)
    begin
        WarrantyLedgerEntry.Reset();
        WarrantyLedgerEntry.SetCurrentKey("Document No.", "Posting Date");
        WarrantyLedgerEntry.SetFilter("Document No.", DocNoFilter);
        WarrantyLedgerEntry.SetFilter("Posting Date", PostingDateFilter);
    end;

    local procedure SetServiceHeaderFilters(DocType: Enum "Service Document Type"; CustomerNo: Code[250])
    begin
        ServiceHeader.Reset();
        ServiceHeader.SetCurrentKey("Customer No.");
        ServiceHeader.SetFilter("Customer No.", CustomerNo);
        ServiceHeader.SetRange("Document Type", DocType);
    end;
}