// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Finance.VAT.Ledger;

using Microsoft.Finance.VAT.Calculation;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.Receivables;
using Microsoft.Service.Document;
using Microsoft.Service.History;
using Microsoft.Service.Posting;

codeunit 10741 "Serv. No Taxable Mgt."
{
    var
        NoTaxableMgt: Codeunit "No Taxable Mgt.";

    [EventSubscriber(ObjectType::Table, Database::"Service Header", 'OnTestMandatoryFieldsOnBeforePassedServLineFind', '', false, false)]
    local procedure TestServiceLineOnServicePost(var ServiceLine: Record "Service Line")
    var
        VATPostingSetup: Record "VAT Posting Setup";
    begin
        if ServiceLine.FindSet() then
            repeat
                if VATPostingSetup.Get(ServiceLine."VAT Bus. Posting Group", ServiceLine."VAT Prod. Posting Group") and
                    (VATPostingSetup."No Taxable Type" <> VATPostingSetup."No Taxable Type"::" ") then
                    VATPostingSetup.TestField("VAT Calculation Type", VATPostingSetup."VAT Calculation Type"::"No Taxable VAT");
            until ServiceLine.Next() = 0;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"No Taxable Mgt.", 'OnUpdateNoTaxableEntryFromCustomerLedgerEntryOnBeforeCalcAmount', '', false, false)]
    local procedure OnUpdateNoTaxableEntryFromCustomerLedgerEntryOnBeforeCalcAmount(CustLedgerEntry: Record "Cust. Ledger Entry"; var ShouldExit: Boolean)
    begin
        if CreateNoTaxableEntriesServiceInvoiceFromCustEntry(CustLedgerEntry) then begin
            ShouldExit := true;
            exit;
        end;
        if CreateNoTaxableEntriesServiceCreditMemoFromCustEntry(CustLedgerEntry) then
            ShouldExit := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Service-Post", 'OnAfterPostServiceDoc', '', false, false)]
    local procedure InsertNoTaxableEntryOnAfterPostServiceDoc(var ServiceHeader: Record "Service Header"; ServShipmentNo: Code[20]; ServInvoiceNo: Code[20]; ServCrMemoNo: Code[20])
    begin
        if not CreateNoTaxableEntriesServiceInvoice(ServiceHeader, ServInvoiceNo) then
            CreateNoTaxableEntriesServiceCreditMemo(ServiceHeader, ServCrMemoNo);
    end;

    local procedure CreateNoTaxableEntriesServiceInvoice(ServiceHeader: Record "Service Header"; ServInvoiceNo: Code[20]): Boolean
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if not (ServiceHeader."Document Type" in [ServiceHeader."Document Type"::Order, ServiceHeader."Document Type"::Invoice]) then
            exit(false);
        if not ServiceInvoiceHeader.Get(ServInvoiceNo) then
            exit(false);
        if not FindNoTaxableLinesServiceInvoice(
             ServiceInvoiceLine, ServiceHeader."Customer No.", ServInvoiceNo, ServiceHeader."Posting Date")
        then
            exit(true);

        InitFromServiceDocument(NoTaxableEntry, ServiceHeader, ServInvoiceNo);
        PostedLineRecordRef.GetTable(ServiceInvoiceLine);
        NoTaxableMgt.InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, -1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesServiceCreditMemo(ServiceHeader: Record "Service Header"; ServCrMemoNo: Code[20]): Boolean
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if ServiceHeader."Document Type" <> ServiceHeader."Document Type"::"Credit Memo" then
            exit(false);
        if not ServiceCrMemoHeader.Get(ServCrMemoNo) then
            exit(false);
        if not FindNoTaxableLinesServiceCrMemo(
             ServiceCrMemoLine, ServiceHeader."Customer No.", ServCrMemoNo, ServiceHeader."Posting Date")
        then
            exit(true);

        InitFromServiceDocument(NoTaxableEntry, ServiceHeader, ServCrMemoNo);
        PostedLineRecordRef.GetTable(ServiceCrMemoLine);
        NoTaxableMgt.InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, 1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesServiceInvoiceFromCustEntry(var CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        ServiceInvoiceHeader: Record "Service Invoice Header";
        ServiceInvoiceLine: Record "Service Invoice Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::Invoice then
            exit(false);
        if not ServiceInvoiceHeader.Get(CustLedgerEntry."Document No.") then
            exit(false);
        if not FindNoTaxableLinesServiceInvoice(
             ServiceInvoiceLine, CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")
        then
            exit(true);

        NoTaxableEntry.InitFromCustomerEntry(
          CustLedgerEntry, ServiceInvoiceHeader."Bill-to Country/Region Code",
          ServiceInvoiceHeader."EU 3-Party Trade", ServiceInvoiceHeader."VAT Registration No.");
        PostedLineRecordRef.GetTable(ServiceInvoiceLine);
        NoTaxableMgt.InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, -1);
        exit(true);
    end;

    local procedure CreateNoTaxableEntriesServiceCreditMemoFromCustEntry(CustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        ServiceCrMemoHeader: Record "Service Cr.Memo Header";
        ServiceCrMemoLine: Record "Service Cr.Memo Line";
        NoTaxableEntry: Record "No Taxable Entry";
        PostedLineRecordRef: RecordRef;
    begin
        if CustLedgerEntry."Document Type" <> CustLedgerEntry."Document Type"::"Credit Memo" then
            exit(false);
        if not ServiceCrMemoHeader.Get(CustLedgerEntry."Document No.") then
            exit(false);
        if not FindNoTaxableLinesServiceCrMemo(
             ServiceCrMemoLine, CustLedgerEntry."Customer No.", CustLedgerEntry."Document No.", CustLedgerEntry."Posting Date")
        then
            exit(true);

        NoTaxableEntry.InitFromCustomerEntry(
          CustLedgerEntry, ServiceCrMemoHeader."Bill-to Country/Region Code",
          ServiceCrMemoHeader."EU 3-Party Trade", ServiceCrMemoHeader."VAT Registration No.");
        PostedLineRecordRef.GetTable(ServiceCrMemoLine);
        NoTaxableMgt.InsertNoTaxableEntriesFromSalesLines(PostedLineRecordRef, NoTaxableEntry, 1);
        exit(true);
    end;

    procedure FindNoTaxableLinesServiceInvoice(var ServiceInvoiceLine: Record "Service Invoice Line"; CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        ServiceInvoiceLine.SetRange("Bill-to Customer No.", CustomerNo);
        ServiceInvoiceLine.SetRange("Document No.", DocumentNo);
        ServiceInvoiceLine.SetRange("Posting Date", PostingDate);
        ServiceInvoiceLine.SetRange("VAT Calculation Type", ServiceInvoiceLine."VAT Calculation Type"::"No Taxable VAT");
        ServiceInvoiceLine.SetRange("VAT %", 0);
        exit(ServiceInvoiceLine.FindSet());
    end;

    procedure FindNoTaxableLinesServiceCrMemo(var ServiceCrMemoLine: Record "Service Cr.Memo Line"; CustomerNo: Code[20]; DocumentNo: Code[20]; PostingDate: Date): Boolean
    begin
        ServiceCrMemoLine.SetRange("Bill-to Customer No.", CustomerNo);
        ServiceCrMemoLine.SetRange("Document No.", DocumentNo);
        ServiceCrMemoLine.SetRange("Posting Date", PostingDate);
        ServiceCrMemoLine.SetRange("VAT Calculation Type", ServiceCrMemoLine."VAT Calculation Type"::"No Taxable VAT");
        ServiceCrMemoLine.SetRange("VAT %", 0);
        exit(ServiceCrMemoLine.FindSet());
    end;

    procedure InitFromServiceDocument(var NoTaxableEntry: Record "No Taxable Entry"; ServiceHeader: Record Microsoft.Service.Document."Service Header"; PostedDocumentNo: Code[20])
    begin
        NoTaxableEntry."Document No." := PostedDocumentNo;
        if ServiceHeader."Document Type" = ServiceHeader."Document Type"::"Credit Memo" then
            NoTaxableEntry."Document Type" := NoTaxableEntry."Document Type"::"Credit Memo"
        else
            NoTaxableEntry."Document Type" := NoTaxableEntry."Document Type"::Invoice;
        NoTaxableEntry."Document Date" := ServiceHeader."Document Date";
        NoTaxableEntry."Posting Date" := ServiceHeader."Posting Date";
        NoTaxableEntry."Currency Code" := ServiceHeader."Currency Code";
        NoTaxableEntry."Country/Region Code" := ServiceHeader."Country/Region Code";
        NoTaxableEntry."Source No." := ServiceHeader."Customer No.";
        NoTaxableEntry."External Document No." := ServiceHeader."No.";
        NoTaxableEntry."Currency Factor" := ServiceHeader."Currency Factor";
        NoTaxableEntry."No. Series" := ServiceHeader."Posting No. Series";
        NoTaxableEntry."EU 3-Party Trade" := ServiceHeader."EU 3-Party Trade";
        NoTaxableEntry."VAT Registration No." := ServiceHeader."VAT Registration No.";
        NoTaxableEntry."VAT Reporting Date" := ServiceHeader."VAT Reporting Date";

        OnAfterInitFromServiceDocument(NoTaxableEntry, ServiceHeader);
#if not CLEAN27
        NoTaxableEntry.RunOnAfterInitFromServiceDocument(NoTaxableEntry, ServiceHeader);
#endif
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitFromServiceDocument(var NoTaxableEntry: Record "No Taxable Entry"; ServiceHeader: Record Microsoft.Service.Document."Service Header")
    begin
    end;
}