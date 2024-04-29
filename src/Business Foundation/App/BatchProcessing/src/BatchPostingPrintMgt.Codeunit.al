// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Foundation.BatchProcessing;

using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Ledger;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using Microsoft.Sales.Setup;
using System.Threading;

codeunit 1373 "Batch Posting Print Mgt."
{
    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Batch Processing Mgt.", 'OnAfterBatchProcessing', '', false, false)]
    local procedure PrintDocumentOnAfterBatchPosting(var RecRef: RecordRef; PostingResult: Boolean)
    var
        BatchProcessingMgt: Codeunit "Batch Processing Mgt.";
        Print: Boolean;
    begin
        OnBeforePrintDocumentOnAfterBatchPosting(RecRef, PostingResult);
        if not PostingResult then
            exit;

        if not BatchProcessingMgt.GetBooleanParameter(RecRef.RecordId, "Batch Posting Parameter Type"::Print, Print) or not Print then
            exit;

        PrintSalesDocument(RecRef);
        PrintPurchaseDocument(RecRef);
    end;

    [Scope('OnPrem')]
    procedure PrintSalesDocument(RecRef: RecordRef)
    var
        SalesHeader: Record "Sales Header";
        ReportSelections: Record "Report Selections";
        SalesInvoiceHeader: Record "Sales Invoice Header";
        SalesShipmentHeader: Record "Sales Shipment Header";
        SalesCrMemoHeader: Record "Sales Cr.Memo Header";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
    begin
        if RecRef.Number <> DATABASE::"Sales Header" then
            exit;

        RecRef.SetTable(SalesHeader);
        if not SalesHeader."Print Posted Documents" then
            exit;

        SalesReceivablesSetup.Get();
        case SalesHeader."Document Type" of
            SalesHeader."Document Type"::Order:
                begin
                    if SalesHeader.Ship then begin
                        SalesShipmentHeader."No." := SalesHeader."Last Shipping No.";
                        SalesShipmentHeader.SetRecFilter();
                        PrintDocument(
                            ReportSelections.Usage::"S.Shipment", SalesShipmentHeader,
                            SalesReceivablesSetup."Post & Print with Job Queue",
                            SalesReceivablesSetup."Report Output Type");
                    end;
                    if SalesHeader.Invoice then begin
                        SalesInvoiceHeader."No." := SalesHeader."Last Posting No.";
                        SalesInvoiceHeader.SetRecFilter();
                        PrintDocument(
                            ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader,
                            SalesReceivablesSetup."Post & Print with Job Queue",
                            SalesReceivablesSetup."Report Output Type");
                    end;
                end;
            SalesHeader."Document Type"::Invoice:
                begin
                    if SalesHeader."Last Posting No." = '' then
                        SalesInvoiceHeader."No." := SalesHeader."No."
                    else
                        SalesInvoiceHeader."No." := SalesHeader."Last Posting No.";
                    SalesInvoiceHeader.SetRecFilter();
                    PrintDocument(
                        ReportSelections.Usage::"S.Invoice", SalesInvoiceHeader,
                        SalesReceivablesSetup."Post & Print with Job Queue",
                        SalesReceivablesSetup."Report Output Type");
                end;
            SalesHeader."Document Type"::"Credit Memo":
                begin
                    if SalesHeader."Last Posting No." = '' then
                        SalesCrMemoHeader."No." := SalesHeader."No."
                    else
                        SalesCrMemoHeader."No." := SalesHeader."Last Posting No.";
                    SalesCrMemoHeader.SetRecFilter();
                    PrintDocument(
                        ReportSelections.Usage::"S.Cr.Memo", SalesCrMemoHeader,
                        SalesReceivablesSetup."Post & Print with Job Queue",
                        SalesReceivablesSetup."Report Output Type");
                end;
        end;

        OnAfterPrintSalesDocument(RecRef);
    end;

    [Scope('OnPrem')]
    procedure PrintPurchaseDocument(RecRef: RecordRef)
    var
        PurchaseHeader: Record "Purchase Header";
        ReportSelections: Record "Report Selections";
        PurchRcptHeader: Record "Purch. Rcpt. Header";
        PurchInvHeader: Record "Purch. Inv. Header";
        PurchCrMemoHdr: Record "Purch. Cr. Memo Hdr.";
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
    begin
        if RecRef.Number <> DATABASE::"Purchase Header" then
            exit;

        RecRef.SetTable(PurchaseHeader);
        if not PurchaseHeader."Print Posted Documents" then
            exit;

        PurchasesPayablesSetup.Get();
        case PurchaseHeader."Document Type" of
            PurchaseHeader."Document Type"::Order:
                begin
                    if PurchaseHeader.Receive then begin
                        PurchRcptHeader."No." := PurchaseHeader."Last Receiving No.";
                        PurchRcptHeader.SetRecFilter();
                        PrintDocument(
                            ReportSelections.Usage::"P.Receipt", PurchRcptHeader,
                            PurchasesPayablesSetup."Post & Print with Job Queue",
                            PurchasesPayablesSetup."Report Output Type");
                    end;
                    if PurchaseHeader.Invoice then begin
                        PurchInvHeader."No." := PurchaseHeader."Last Posting No.";
                        PurchInvHeader.SetRecFilter();
                        PrintDocument(
                            ReportSelections.Usage::"P.Invoice", PurchInvHeader,
                            PurchasesPayablesSetup."Post & Print with Job Queue",
                            PurchasesPayablesSetup."Report Output Type");
                    end;
                end;
            PurchaseHeader."Document Type"::Invoice:
                begin
                    if PurchaseHeader."Last Posting No." = '' then
                        PurchInvHeader."No." := PurchaseHeader."No."
                    else
                        PurchInvHeader."No." := PurchaseHeader."Last Posting No.";
                    PurchInvHeader.SetRecFilter();
                    PrintDocument(
                        ReportSelections.Usage::"P.Invoice", PurchInvHeader,
                        PurchasesPayablesSetup."Post & Print with Job Queue",
                        PurchasesPayablesSetup."Report Output Type");
                end;
            PurchaseHeader."Document Type"::"Credit Memo":
                begin
                    if PurchaseHeader."Last Posting No." = '' then
                        PurchCrMemoHdr."No." := PurchaseHeader."No."
                    else
                        PurchCrMemoHdr."No." := PurchaseHeader."Last Posting No.";
                    PurchCrMemoHdr.SetRecFilter();
                    PrintDocument(
                        ReportSelections.Usage::"P.Cr.Memo", PurchCrMemoHdr,
                        PurchasesPayablesSetup."Post & Print with Job Queue",
                        PurchasesPayablesSetup."Report Output Type");
                end;
        end;

        OnAfterPrintPurchaseDocument(RecRef);
    end;

    procedure PrintJournal(RecRef: RecordRef)
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
        GenJnlTemplate: Record "Gen. Journal Template";
        GenJrnlLine: Record "Gen. Journal Line";
        GLReg: Record "G/L Register";
    begin
        if RecRef.Number <> DATABASE::"Gen. Journal Line" then
            exit;

        RecRef.SetTable(GenJrnlLine);
        GenJnlTemplate.Get(GenJrnlLine."Journal Template Name");

        GeneralLedgerSetup.Get();
        if GLReg.Get(GenJrnlLine."Line No.") then begin
            if GenJnlTemplate."Cust. Receipt Report ID" <> 0 then
                PrintCustReceiptReport(GLReg, GenJnlTemplate, GeneralLedgerSetup);

            if GenJnlTemplate."Vendor Receipt Report ID" <> 0 then
                PrintVendorReceiptReport(GLReg, GenJnlTemplate, GeneralLedgerSetup);

            if GenJnlTemplate."Posting Report ID" <> 0 then
                PrintPostingReport(GLReg, GenJnlTemplate, GeneralLedgerSetup);
        end;
    end;

    local procedure PrintCustReceiptReport(GLReg: Record "G/L Register"; GenJnlTemplate: Record "Gen. Journal Template"; GeneralLedgerSetup: Record "General Ledger Setup")
    var
        CustLedgEntry: Record "Cust. Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintCustReceiptReport(GLReg, GenJnlTemplate, GeneralLedgerSetup, IsHandled);
        if IsHandled then
            exit;

        CustLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        if GeneralLedgerSetup."Post & Print with Job Queue" then
            SchedulePrintJobQueueEntry(GLReg, GenJnlTemplate."Cust. Receipt Report ID", GeneralLedgerSetup."Report Output Type".AsInteger())
        else
            REPORT.Run(GenJnlTemplate."Cust. Receipt Report ID", false, false, CustLedgEntry);
    end;

    local procedure PrintVendorReceiptReport(GLReg: Record "G/L Register"; GenJnlTemplate: Record "Gen. Journal Template"; GeneralLedgerSetup: Record "General Ledger Setup")
    var
        VendLedgEntry: Record "Vendor Ledger Entry";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintVendorReceiptReport(GLReg, GenJnlTemplate, GeneralLedgerSetup, IsHandled);
        if IsHandled then
            exit;

        VendLedgEntry.SetRange("Entry No.", GLReg."From Entry No.", GLReg."To Entry No.");
        if GeneralLedgerSetup."Post & Print with Job Queue" then
            SchedulePrintJobQueueEntry(GLReg, GenJnlTemplate."Vendor Receipt Report ID", GeneralLedgerSetup."Report Output Type".AsInteger())
        else
            REPORT.Run(GenJnlTemplate."Vendor Receipt Report ID", false, false, VendLedgEntry);
    end;

    local procedure PrintPostingReport(GLReg: Record "G/L Register"; GenJnlTemplate: Record "Gen. Journal Template"; GeneralLedgerSetup: Record "General Ledger Setup")
    var
        IsHandled: Boolean;
    begin
        GLReg.SetRecFilter();
        IsHandled := false;
        OnBeforeGLRegPostingReportPrint(GenJnlTemplate."Posting Report ID", false, false, GLReg, IsHandled);
        if IsHandled then
            exit;

        if GeneralLedgerSetup."Post & Print with Job Queue" then
            SchedulePrintJobQueueEntry(GLReg, GenJnlTemplate."Posting Report ID", GeneralLedgerSetup."Report Output Type".AsInteger())
        else
            REPORT.Run(GenJnlTemplate."Posting Report ID", false, false, GLReg);
    end;

    local procedure PrintDocument(ReportUsage: Enum "Report Selection Usage"; RecVariant: Variant; PrintViaJobQueue: Boolean; ReportOutputType: Enum "Job Queue Report Output Type")
    var
        ReportSelections: Record "Report Selections";
        IsHandled: Boolean;
    begin
        IsHandled := false;
        OnBeforePrintDocument(ReportUsage.AsInteger(), RecVariant, IsHandled);
        if IsHandled then
            exit;

        ReportSelections.Reset();
        ReportSelections.SetRange(Usage, ReportUsage);
        ReportSelections.FindSet();
        repeat
            ReportSelections.TestField("Report ID");
            if PrintViaJobQueue then
                SchedulePrintJobQueueEntry(RecVariant, ReportSelections."Report ID", ReportOutputType.AsInteger())
            else
                REPORT.Run(ReportSelections."Report ID", false, false, RecVariant);
        until ReportSelections.Next() = 0;
    end;

    procedure SchedulePrintJobQueueEntry(RecVar: Variant; ReportId: Integer; ReportOutputType: Option)
    var
        JobQueueEntry: Record "Job Queue Entry";
        RecRefToPrint: RecordRef;
    begin
        RecRefToPrint.GetTable(RecVar);
        Clear(JobQueueEntry.ID);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Report;
        JobQueueEntry."Object ID to Run" := ReportId;
        JobQueueEntry."Report Output Type" := "Job Queue Report Output Type".FromInteger(ReportOutputType);
        JobQueueEntry."Record ID to Process" := RecRefToPrint.RecordId;
        JobQueueEntry.Description := Format(JobQueueEntry."Report Output Type");
        CODEUNIT.Run(CODEUNIT::"Job Queue - Enqueue", JobQueueEntry);
        Commit();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintSalesDocument(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterPrintPurchaseDocument(RecRef: RecordRef)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeGLRegPostingReportPrint(var ReportID: Integer; ReqWindow: Boolean; SystemPrinter: Boolean; var GLRegister: Record "G/L Register"; var Handled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocument(ReportUsage: Option; RecVar: Variant; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintDocumentOnAfterBatchPosting(var RecRef: RecordRef; PostingResult: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintCustReceiptReport(GLReg: Record "G/L Register"; GenJnlTemplate: Record "Gen. Journal Template"; GeneralLedgerSetup: Record "General Ledger Setup"; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforePrintVendorReceiptReport(GLReg: Record "G/L Register"; GenJnlTemplate: Record "Gen. Journal Template"; GeneralLedgerSetup: Record "General Ledger Setup"; var IsHandled: Boolean)
    begin
    end;
}

