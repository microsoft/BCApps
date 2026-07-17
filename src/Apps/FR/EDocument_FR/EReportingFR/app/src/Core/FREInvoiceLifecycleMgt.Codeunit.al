// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;

codeunit 10971 "FR E-Invoice Lifecycle Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "FR E-Invoice Lifecycle" = rim;

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