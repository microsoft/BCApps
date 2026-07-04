// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.Navigate;

using Microsoft.Bank.Check;
using Microsoft.Bank.Ledger;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.FixedAssets.Insurance;
using Microsoft.FixedAssets.Ledger;
using Microsoft.FixedAssets.Maintenance;
using Microsoft.Projects.Project.Ledger;
using Microsoft.Projects.Resources.Ledger;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 7000115 "CRTNavigateCartera"
{
    SingleInstance = true;

    var
        CarteraDocNoFilter: Text[250];

    procedure SetCarteraDocNoFilter(NewCarteraDocNoFilter: Text[250])
    begin
        CarteraDocNoFilter := NewCarteraDocNoFilter;
    end;

    local procedure IsCarteraFilterActive(): Boolean
    begin
        exit(CarteraDocNoFilter <> '');
    end;

    local procedure RemoveDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary; TableId: Integer)
    begin
        TempDocumentEntry.SetRange("Table ID", TableId);
        TempDocumentEntry.DeleteAll();
        TempDocumentEntry.SetRange("Table ID");
    end;

    local procedure HasDocumentEntry(var TempDocumentEntry: Record "Document Entry" temporary; TableId: Integer): Boolean
    begin
        TempDocumentEntry.SetRange("Table ID", TableId);
        exit(not TempDocumentEntry.IsEmpty());
    end;

    local procedure AddCarteraDocsByType(var TempDocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; AccountType: Option Receivable,Payable)
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
    begin
        if (DocNoFilter = '') and (PostingDateFilter = '') and (CarteraDocNoFilter = '') then
            exit;

        if CarteraDoc.ReadPermission() then begin
            CarteraDoc.Reset();
            CarteraDoc.SetCurrentKey(Type, "Original Document No.");
            CarteraDoc.SetFilter("Original Document No.", DocNoFilter);
            CarteraDoc.SetFilter("No.", CarteraDocNoFilter);
            CarteraDoc.SetFilter("Posting Date", PostingDateFilter);
            CarteraDoc.SetRange(Type, AccountType);
            TempDocumentEntry.InsertIntoDocEntry(Database::"Cartera Doc.", CarteraDoc.TableCaption(), CarteraDoc.Count());
        end;

        if PostedCarteraDoc.ReadPermission() then begin
            PostedCarteraDoc.Reset();
            PostedCarteraDoc.SetCurrentKey(Type, "Original Document No.");
            PostedCarteraDoc.SetFilter("Original Document No.", DocNoFilter);
            PostedCarteraDoc.SetFilter("No.", CarteraDocNoFilter);
            PostedCarteraDoc.SetFilter("Posting Date", PostingDateFilter);
            TempDocumentEntry.InsertIntoDocEntry(Database::"Posted Cartera Doc.", PostedCarteraDoc.TableCaption(), PostedCarteraDoc.Count());
        end;

        if ClosedCarteraDoc.ReadPermission() then begin
            ClosedCarteraDoc.Reset();
            ClosedCarteraDoc.SetCurrentKey(Type, "Original Document No.");
            ClosedCarteraDoc.SetFilter("Original Document No.", DocNoFilter);
            ClosedCarteraDoc.SetFilter("No.", CarteraDocNoFilter);
            ClosedCarteraDoc.SetFilter("Posting Date", PostingDateFilter);
            ClosedCarteraDoc.SetRange(Type, AccountType);
            TempDocumentEntry.InsertIntoDocEntry(Database::"Closed Cartera Doc.", ClosedCarteraDoc.TableCaption(), ClosedCarteraDoc.Count());
        end;
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindCustEntriesOnAfterSetFilters', '', false, false)]
    local procedure OnFindCustEntriesOnAfterSetFilters(var CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        if IsCarteraFilterActive() then
            CustLedgerEntry.SetFilter("Bill No.", CarteraDocNoFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindCustEntriesOnAfterDtldCustLedgEntriesSetFilters', '', false, false)]
    local procedure OnFindCustEntriesOnAfterDtldCustLedgEntriesSetFilters(var DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        if IsCarteraFilterActive() then
            DetailedCustLedgEntry.SetFilter("Bill No.", CarteraDocNoFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindVendEntriesOnAfterSetFilters', '', false, false)]
    local procedure OnFindVendEntriesOnAfterSetFilters(var VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
        if IsCarteraFilterActive() then
            VendorLedgerEntry.SetFilter("Bill No.", CarteraDocNoFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindVendEntriesOnAfterDtldVendLedgEntriesSetFilters', '', false, false)]
    local procedure OnFindVendEntriesOnAfterDtldVendLedgEntriesSetFilters(var DetailedVendorLedgEntry: Record "Detailed Vendor Ledg. Entry")
    begin
        if IsCarteraFilterActive() then
            DetailedVendorLedgEntry.SetFilter("Bill No.", CarteraDocNoFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindBankEntriesOnAfterSetFilters', '', false, false)]
    local procedure OnFindBankEntriesOnAfterSetFilters(var BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
        if IsCarteraFilterActive() then
            BankAccountLedgerEntry.SetFilter("Bill No.", CarteraDocNoFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindGLEntriesOnAfterSetFilters', '', false, false)]
    local procedure OnFindGLEntriesOnAfterSetFilters(var GLEntry: Record "G/L Entry")
    begin
        if IsCarteraFilterActive() then
            GLEntry.SetFilter("Bill No.", CarteraDocNoFilter);
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindLedgerEntries', '', false, false)]
    local procedure OnAfterFindLedgerEntries(var DocumentEntry: Record "Document Entry"; DocNoFilter: Text; PostingDateFilter: Text)
    begin
        if HasDocumentEntry(DocumentEntry, Database::"Cust. Ledger Entry") then
            AddCarteraDocsByType(DocumentEntry, DocNoFilter, PostingDateFilter, 0);

        if HasDocumentEntry(DocumentEntry, Database::"Vendor Ledger Entry") then
            AddCarteraDocsByType(DocumentEntry, DocNoFilter, PostingDateFilter, 1);

        DocumentEntry.SetRange("Table ID");

        if not IsCarteraFilterActive() then
            exit;

        RemoveDocumentEntry(DocumentEntry, Database::"No Taxable Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"Check Ledger Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"VAT Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"FA Ledger Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"Maintenance Ledger Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"Ins. Coverage Ledger Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"Res. Ledger Entry");
        RemoveDocumentEntry(DocumentEntry, Database::"Job Ledger Entry");
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnAfterFindPostedDocuments', '', false, false)]
    local procedure OnAfterFindPostedDocuments(var DocNoFilter: Text; var PostingDateFilter: Text; var DocumentEntry: Record "Document Entry")
    var
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        PostedPmtOrd: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
    begin
        if (DocNoFilter <> '') or (PostingDateFilter <> '') then
            if not IsCarteraFilterActive() then begin
                if PostedBillGr.ReadPermission() then begin
                    PostedBillGr.Reset();
                    PostedBillGr.SetCurrentKey("No.");
                    PostedBillGr.SetFilter("No.", DocNoFilter);
                    PostedBillGr.SetFilter("Posting Date", PostingDateFilter);
                    DocumentEntry.InsertIntoDocEntry(Database::"Posted Bill Group", PostedBillGr.TableCaption(), PostedBillGr.Count());
                end;

                if ClosedBillGr.ReadPermission() then begin
                    ClosedBillGr.Reset();
                    ClosedBillGr.SetCurrentKey("No.");
                    ClosedBillGr.SetFilter("No.", DocNoFilter);
                    ClosedBillGr.SetFilter("Posting Date", PostingDateFilter);
                    DocumentEntry.InsertIntoDocEntry(Database::"Closed Bill Group", ClosedBillGr.TableCaption(), ClosedBillGr.Count());
                end;

                if PostedPmtOrd.ReadPermission() then begin
                    PostedPmtOrd.Reset();
                    PostedPmtOrd.SetCurrentKey("No.");
                    PostedPmtOrd.SetFilter("No.", DocNoFilter);
                    PostedPmtOrd.SetFilter("Posting Date", PostingDateFilter);
                    DocumentEntry.InsertIntoDocEntry(Database::"Posted Payment Order", PostedPmtOrd.TableCaption(), PostedPmtOrd.Count());
                end;

                if ClosedPmtOrd.ReadPermission() then begin
                    ClosedPmtOrd.Reset();
                    ClosedPmtOrd.SetCurrentKey("No.");
                    ClosedPmtOrd.SetFilter("No.", DocNoFilter);
                    ClosedPmtOrd.SetFilter("Posting Date", PostingDateFilter);
                    DocumentEntry.InsertIntoDocEntry(Database::"Closed Payment Order", ClosedPmtOrd.TableCaption(), ClosedPmtOrd.Count());
                end;
            end;

        if not IsCarteraFilterActive() then
            exit;

        RemoveDocumentEntry(DocumentEntry, Database::"Purch. Rcpt. Header");
        RemoveDocumentEntry(DocumentEntry, Database::"Purch. Inv. Header");
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnFindExtRecordsOnBeforeFormUpdate', '', false, false)]
    local procedure OnFindExtRecordsOnBeforeFormUpdate(var Rec: Record "Document Entry"; var SalesInvHeader: Record "Sales Invoice Header"; var SalesCrMemoHeader: Record "Sales Cr.Memo Header")
    begin
        if not IsCarteraFilterActive() then
            exit;

        RemoveDocumentEntry(Rec, Database::"Sales Invoice Header");
        RemoveDocumentEntry(Rec, Database::"Sales Cr.Memo Header");
    end;

    [EventSubscriber(ObjectType::Page, Page::Navigate, 'OnBeforeShowRecords', '', false, false)]
    local procedure OnBeforeShowRecords(var TempDocumentEntry: Record "Document Entry" temporary; DocNoFilter: Text; PostingDateFilter: Text; ItemTrackingSearch: Boolean; ContactNo: Code[250]; ExtDocNo: Code[250]; var IsHandled: Boolean)
    var
        CarteraDoc: Record "Cartera Doc.";
        PostedCarteraDoc: Record "Posted Cartera Doc.";
        ClosedCarteraDoc: Record "Closed Cartera Doc.";
        PostedBillGr: Record "Posted Bill Group";
        ClosedBillGr: Record "Closed Bill Group";
        PostedPmtOrd: Record "Posted Payment Order";
        ClosedPmtOrd: Record "Closed Payment Order";
    begin
        if ItemTrackingSearch then
            exit;

        case TempDocumentEntry."Table ID" of
            Database::"Cartera Doc.":
                begin
                    CarteraDoc.SetCurrentKey(Type, "Original Document No.");
                    CarteraDoc.SetFilter("Original Document No.", DocNoFilter);
                    CarteraDoc.SetFilter("No.", CarteraDocNoFilter);
                    CarteraDoc.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, CarteraDoc);
                    IsHandled := true;
                end;
            Database::"Posted Cartera Doc.":
                begin
                    PostedCarteraDoc.SetCurrentKey(Type, "Original Document No.");
                    PostedCarteraDoc.SetFilter("Original Document No.", DocNoFilter);
                    PostedCarteraDoc.SetFilter("No.", CarteraDocNoFilter);
                    PostedCarteraDoc.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, PostedCarteraDoc);
                    IsHandled := true;
                end;
            Database::"Closed Cartera Doc.":
                begin
                    ClosedCarteraDoc.SetCurrentKey(Type, "Original Document No.");
                    ClosedCarteraDoc.SetFilter("Original Document No.", DocNoFilter);
                    ClosedCarteraDoc.SetFilter("No.", CarteraDocNoFilter);
                    ClosedCarteraDoc.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, ClosedCarteraDoc);
                    IsHandled := true;
                end;
            Database::"Posted Bill Group":
                begin
                    PostedBillGr.SetCurrentKey("No.");
                    PostedBillGr.SetFilter("No.", DocNoFilter);
                    PostedBillGr.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, PostedBillGr);
                    IsHandled := true;
                end;
            Database::"Closed Bill Group":
                begin
                    ClosedBillGr.SetCurrentKey("No.");
                    ClosedBillGr.SetFilter("No.", DocNoFilter);
                    ClosedBillGr.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, ClosedBillGr);
                    IsHandled := true;
                end;
            Database::"Posted Payment Order":
                begin
                    PostedPmtOrd.SetCurrentKey("No.");
                    PostedPmtOrd.SetFilter("No.", DocNoFilter);
                    PostedPmtOrd.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, PostedPmtOrd);
                    IsHandled := true;
                end;
            Database::"Closed Payment Order":
                begin
                    ClosedPmtOrd.SetCurrentKey("No.");
                    ClosedPmtOrd.SetFilter("No.", DocNoFilter);
                    ClosedPmtOrd.SetFilter("Posting Date", PostingDateFilter);
                    Page.Run(0, ClosedPmtOrd);
                    IsHandled := true;
                end;
        end;
    end;
}
