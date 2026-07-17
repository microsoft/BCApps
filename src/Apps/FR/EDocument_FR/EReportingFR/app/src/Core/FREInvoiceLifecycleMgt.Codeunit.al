// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;

codeunit 10971 "FR E-Invoice Lifecycle Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "FR E-Invoice Lifecycle" = rim;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertDtldCustLedgEntry', '', false, false)]
    local procedure OnAfterInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
        ProcessDetailedLedgerApplication(DtldCustLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertDtldCustLedgEntryUnapply', '', false, false)]
    local procedure OnAfterInsertDtldCustLedgEntryUnapply(var CustomerPostingGroup: Record "Customer Posting Group"; var OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlLine: Record "Gen. Journal Line"; var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        ProcessDetailedLedgerUnapplication(OldDetailedCustLedgEntry, NewDetailedCustLedgEntry);
    end;

    internal procedure ProcessDetailedLedgerApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        EDocument: Record "E-Document";
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        PaymentCustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if not IsInvoiceApplication(DetailedCustLedgEntry) then
            exit;
        if not InvoiceCustLedgerEntry.Get(DetailedCustLedgEntry."Cust. Ledger Entry No.") then
            exit;
        if not PaymentCustLedgerEntry.Get(DetailedCustLedgEntry."Applied Cust. Ledger Entry No.") then
            exit;
        if PaymentCustLedgerEntry."Document Type" <> PaymentCustLedgerEntry."Document Type"::Payment then
            exit;
        if not FindInvoiceEDocuments(EDocument, InvoiceCustLedgerEntry) then
            exit;

        repeat
            if IsFREInvoiceEDocument(EDocument) then
                CapturePaymentOccurrence(
                    EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, DetailedCustLedgEntry.SystemId,
                    -DetailedCustLedgEntry.Amount, DetailedCustLedgEntry."Currency Code", DetailedCustLedgEntry."Posting Date",
                    InvoiceCustLedgerEntry."Entry No.", PaymentCustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry No.", 0);
        until EDocument.Next() = 0;
    end;

    internal procedure ProcessDetailedLedgerUnapplication(OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
    begin
        if not IsInvoiceApplication(OldDetailedCustLedgEntry) then
            exit;
        if not FindCollectedOccurrence(CollectedLifecycle, OldDetailedCustLedgEntry."Entry No.") then
            exit;

        CapturePaymentOccurrence(
            CollectedLifecycle."E-Document Entry No.", "FR E-Invoice Lifecycle Status"::"Negative Collected", NewDetailedCustLedgEntry.SystemId,
            -CollectedLifecycle."Reported Amount", CollectedLifecycle."Currency Code", NewDetailedCustLedgEntry."Posting Date",
            CollectedLifecycle."Invoice Cust. Ledger Entry No.", CollectedLifecycle."Payment Cust. Ledger Entry No.", NewDetailedCustLedgEntry."Entry No.", CollectedLifecycle."Entry No.");
    end;

    internal procedure CapturePaymentOccurrence(EDocumentEntryNo: Integer; LifecycleStatus: Enum "FR E-Invoice Lifecycle Status"; SourceOccurrenceID: Guid; ReportedAmount: Decimal; CurrencyCode: Code[10]; EventDate: Date; InvoiceCustLedgerEntryNo: Integer; PaymentCustLedgerEntryNo: Integer; DetailedLedgerEntryNo: Integer; OriginalOccurrenceEntryNo: Integer) FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"
    begin
        ValidatePaymentOccurrence(EDocumentEntryNo, LifecycleStatus, SourceOccurrenceID, ReportedAmount, EventDate, OriginalOccurrenceEntryNo);

        if FindOccurrence(FREInvoiceLifecycle, EDocumentEntryNo, LifecycleStatus, SourceOccurrenceID) then begin
            VerifyReplay(FREInvoiceLifecycle, ReportedAmount, CurrencyCode, EventDate, InvoiceCustLedgerEntryNo, PaymentCustLedgerEntryNo, DetailedLedgerEntryNo, OriginalOccurrenceEntryNo);
            exit(FREInvoiceLifecycle);
        end;

        FREInvoiceLifecycle.Init();
        FREInvoiceLifecycle."E-Document Entry No." := EDocumentEntryNo;
        FREInvoiceLifecycle."Lifecycle Status" := LifecycleStatus;
        FREInvoiceLifecycle."Source Occurrence ID" := SourceOccurrenceID;
        FREInvoiceLifecycle."Original Occurrence Entry No." := OriginalOccurrenceEntryNo;
        FREInvoiceLifecycle."Reported Amount" := ReportedAmount;
        FREInvoiceLifecycle."Currency Code" := CurrencyCode;
        FREInvoiceLifecycle."Event Date" := EventDate;
        FREInvoiceLifecycle."Invoice Cust. Ledger Entry No." := InvoiceCustLedgerEntryNo;
        FREInvoiceLifecycle."Payment Cust. Ledger Entry No." := PaymentCustLedgerEntryNo;
        FREInvoiceLifecycle."Detailed Ledger Entry No." := DetailedLedgerEntryNo;
        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::Captured;
        FREInvoiceLifecycle."Created At" := CurrentDateTime();
        FREInvoiceLifecycle.Insert();
    end;

    local procedure ValidatePaymentOccurrence(EDocumentEntryNo: Integer; LifecycleStatus: Enum "FR E-Invoice Lifecycle Status"; SourceOccurrenceID: Guid; ReportedAmount: Decimal; EventDate: Date; OriginalOccurrenceEntryNo: Integer)
    var
        EDocument: Record "E-Document";
        OriginalOccurrence: Record "FR E-Invoice Lifecycle";
    begin
        EDocument.Get(EDocumentEntryNo);
        if IsNullGuid(SourceOccurrenceID) then
            Error(SourceOccurrenceIDErr);
        if EventDate = 0D then
            Error(EventDateErr);

        case LifecycleStatus of
            LifecycleStatus::Collected:
                begin
                    if ReportedAmount <= 0 then
                        Error(CollectedAmountErr);
                    if OriginalOccurrenceEntryNo <> 0 then
                        Error(CollectedOriginalOccurrenceErr);
                end;
            LifecycleStatus::"Negative Collected":
                begin
                    if ReportedAmount >= 0 then
                        Error(NegativeCollectedAmountErr);
                    if not OriginalOccurrence.Get(OriginalOccurrenceEntryNo) then
                        Error(OriginalOccurrenceErr);
                    OriginalOccurrence.TestField("E-Document Entry No.", EDocumentEntryNo);
                    OriginalOccurrence.TestField("Lifecycle Status", OriginalOccurrence."Lifecycle Status"::Collected);
                    if ReportedAmount <> -OriginalOccurrence."Reported Amount" then
                        Error(ReversalAmountErr);
                end;
            else
                Error(PaymentStatusErr, LifecycleStatus);
        end;
    end;

    local procedure FindOccurrence(var FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; EDocumentEntryNo: Integer; LifecycleStatus: Enum "FR E-Invoice Lifecycle Status"; SourceOccurrenceID: Guid): Boolean
    begin
        FREInvoiceLifecycle.SetRange("E-Document Entry No.", EDocumentEntryNo);
        FREInvoiceLifecycle.SetRange("Source Occurrence ID", SourceOccurrenceID);
        FREInvoiceLifecycle.SetRange("Lifecycle Status", LifecycleStatus);
        exit(FREInvoiceLifecycle.FindFirst());
    end;

    local procedure FindCollectedOccurrence(var FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; DetailedLedgerEntryNo: Integer): Boolean
    begin
        FREInvoiceLifecycle.SetRange("Lifecycle Status", FREInvoiceLifecycle."Lifecycle Status"::Collected);
        FREInvoiceLifecycle.SetRange("Detailed Ledger Entry No.", DetailedLedgerEntryNo);
        exit(FREInvoiceLifecycle.FindFirst());
    end;

    local procedure FindInvoiceEDocuments(var EDocument: Record "E-Document"; InvoiceCustLedgerEntry: Record "Cust. Ledger Entry"): Boolean
    var
        SalesInvoiceHeader: Record "Sales Invoice Header";
    begin
        if InvoiceCustLedgerEntry."Document Type" <> InvoiceCustLedgerEntry."Document Type"::Invoice then
            exit(false);
        if not SalesInvoiceHeader.Get(InvoiceCustLedgerEntry."Document No.") then
            exit(false);

        EDocument.SetRange("Document Record ID", SalesInvoiceHeader.RecordId);
        EDocument.SetRange(Direction, EDocument.Direction::Outgoing);
        EDocument.SetRange("Document Type", EDocument."Document Type"::"Sales Invoice");
        exit(EDocument.FindSet());
    end;

    local procedure IsFREInvoiceEDocument(EDocument: Record "E-Document"): Boolean
    var
        EDocumentService: Record "E-Document Service";
    begin
        exit(EDocumentService.Get(EDocument.Service) and IsFREInvoiceFormat(EDocumentService."Document Format"));
    end;

    local procedure IsFREInvoiceFormat(EDocumentFormat: Enum "E-Document Format"): Boolean
    begin
        exit(EDocumentFormat in [EDocumentFormat::"Peppol BIS 3.0 FR", EDocumentFormat::"Factur-X FR"]);
    end;

    local procedure IsInvoiceApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    begin
        exit(
            (DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::Application) and
            (DetailedCustLedgEntry."Initial Document Type" = DetailedCustLedgEntry."Initial Document Type"::Invoice) and
            (DetailedCustLedgEntry.Amount < 0));
    end;

    local procedure VerifyReplay(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; ReportedAmount: Decimal; CurrencyCode: Code[10]; EventDate: Date; InvoiceCustLedgerEntryNo: Integer; PaymentCustLedgerEntryNo: Integer; DetailedLedgerEntryNo: Integer; OriginalOccurrenceEntryNo: Integer)
    begin
        if (FREInvoiceLifecycle."Reported Amount" <> ReportedAmount) or
           (FREInvoiceLifecycle."Currency Code" <> CurrencyCode) or
           (FREInvoiceLifecycle."Event Date" <> EventDate) or
           (FREInvoiceLifecycle."Invoice Cust. Ledger Entry No." <> InvoiceCustLedgerEntryNo) or
           (FREInvoiceLifecycle."Payment Cust. Ledger Entry No." <> PaymentCustLedgerEntryNo) or
           (FREInvoiceLifecycle."Detailed Ledger Entry No." <> DetailedLedgerEntryNo) or
           (FREInvoiceLifecycle."Original Occurrence Entry No." <> OriginalOccurrenceEntryNo)
        then
            Error(ConflictingReplayErr);
    end;

    var
        SourceOccurrenceIDErr: Label 'A source occurrence ID is required for a French payment lifecycle occurrence.';
        EventDateErr: Label 'An event date is required for a French payment lifecycle occurrence.';
        CollectedAmountErr: Label 'The reported amount for a Collected occurrence must be positive.';
        NegativeCollectedAmountErr: Label 'The reported amount for a Negative Collected occurrence must be negative.';
        CollectedOriginalOccurrenceErr: Label 'A Collected occurrence cannot reference an original occurrence.';
        OriginalOccurrenceErr: Label 'The original Collected occurrence does not exist.';
        ReversalAmountErr: Label 'A Negative Collected occurrence must exactly reverse the reported amount of the original Collected occurrence.';
        PaymentStatusErr: Label 'Lifecycle status %1 is not a payment lifecycle status.', Comment = '%1 = lifecycle status';
        ConflictingReplayErr: Label 'The payment lifecycle occurrence was already captured with different values.';
}