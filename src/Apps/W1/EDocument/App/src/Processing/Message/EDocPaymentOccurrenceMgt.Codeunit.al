// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Processing.Message;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.ReceivablesPayables;
using Microsoft.Sales.Customer;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Threading;

/// <summary>
/// Captures payment applications and reversals for outgoing E-Documents and publishes them to localization apps.
/// </summary>
codeunit 6536 "E-Doc. Payment Occurrence Mgt."
{
    Access = Public;
    TableNo = "Job Queue Entry";
    InherentEntitlements = X;
    InherentPermissions = X;

    Permissions =
        tabledata "Cust. Ledger Entry" = r,
        tabledata "Detailed Cust. Ledg. Entry" = r,
        tabledata "E-Document" = r,
        tabledata "E-Doc. Payment Occurrence" = rim,
        tabledata "Sales Invoice Header" = r;

    trigger OnRun()
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
    begin
        EDocPaymentOccurrence.Get(Rec."Record ID to Process");
        ProcessPaymentOccurrence(EDocPaymentOccurrence);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertDtldCustLedgEntry', '', false, false)]
    local procedure OnAfterInsertDtldCustLedgEntry(var DtldCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; GenJournalLine: Record "Gen. Journal Line"; DtldCVLedgEntryBuffer: Record "Detailed CV Ledg. Entry Buffer"; Offset: Integer)
    begin
        ProcessApplication(DtldCustLedgEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Gen. Jnl.-Post Line", 'OnAfterInsertDtldCustLedgEntryUnapply', '', false, false)]
    local procedure OnAfterInsertDtldCustLedgEntryUnapply(var CustomerPostingGroup: Record "Customer Posting Group"; var OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; var GenJnlLine: Record "Gen. Journal Line"; var NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    begin
        ProcessUnapplication(OldDetailedCustLedgEntry, NewDetailedCustLedgEntry);
    end;

    /// <summary>
    /// Captures an invoice payment application for every matching outgoing E-Document.
    /// </summary>
    /// <param name="DetailedCustLedgEntry">The detailed customer ledger application entry.</param>
    procedure ProcessApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
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
            CreateOccurrence(
                EDocument."Entry No", "E-Doc. Payment Occurrence Type"::Applied, DetailedCustLedgEntry.SystemId,
                -DetailedCustLedgEntry.Amount, DetailedCustLedgEntry."Currency Code", DetailedCustLedgEntry."Posting Date",
                DetailedCustLedgEntry."Entry No.", 0);
        until EDocument.Next() = 0;
    end;

    /// <summary>
    /// Captures the reversal of each payment occurrence created from the original application entry.
    /// </summary>
    /// <param name="OldDetailedCustLedgEntry">The original detailed customer ledger application entry.</param>
    /// <param name="NewDetailedCustLedgEntry">The detailed customer ledger reversal entry.</param>
    procedure ProcessUnapplication(OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        AppliedOccurrence: Record "E-Doc. Payment Occurrence";
    begin
        if not IsInvoiceApplication(OldDetailedCustLedgEntry) then
            exit;

        AppliedOccurrence.SetRange("Source Occurrence ID", OldDetailedCustLedgEntry.SystemId);
        AppliedOccurrence.SetRange(Type, AppliedOccurrence.Type::Applied);
        AppliedOccurrence.SetLoadFields("E-Document Entry No.", Amount, "Currency Code", "Entry No.");
        if not AppliedOccurrence.FindSet() then
            exit;

        repeat
            CreateOccurrence(
                AppliedOccurrence."E-Document Entry No.", "E-Doc. Payment Occurrence Type"::Reversed, NewDetailedCustLedgEntry.SystemId,
                -AppliedOccurrence.Amount, AppliedOccurrence."Currency Code", NewDetailedCustLedgEntry."Posting Date",
                NewDetailedCustLedgEntry."Entry No.", AppliedOccurrence."Entry No.");
        until AppliedOccurrence.Next() = 0;
    end;

    local procedure CreateOccurrence(EDocumentEntryNo: Integer; OccurrenceType: Enum "E-Doc. Payment Occurrence Type"; SourceOccurrenceID: Guid; Amount: Decimal; CurrencyCode: Code[10]; EventDate: Date; DetailedLedgerEntryNo: Integer; OriginalOccurrenceEntryNo: Integer)
    var
        EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence";
    begin
        EDocPaymentOccurrence.LockTable();
        EDocPaymentOccurrence.SetRange("E-Document Entry No.", EDocumentEntryNo);
        EDocPaymentOccurrence.SetRange("Source Occurrence ID", SourceOccurrenceID);
        EDocPaymentOccurrence.SetRange(Type, OccurrenceType);
        if not EDocPaymentOccurrence.IsEmpty() then
            exit;

        EDocPaymentOccurrence.Init();
        EDocPaymentOccurrence."E-Document Entry No." := EDocumentEntryNo;
        EDocPaymentOccurrence.Type := OccurrenceType;
        EDocPaymentOccurrence."Source Occurrence ID" := SourceOccurrenceID;
        EDocPaymentOccurrence."Original Occurrence Entry No." := OriginalOccurrenceEntryNo;
        EDocPaymentOccurrence.Amount := Amount;
        EDocPaymentOccurrence."Currency Code" := CurrencyCode;
        EDocPaymentOccurrence."Event Date" := EventDate;
        EDocPaymentOccurrence."Detailed Ledger Entry No." := DetailedLedgerEntryNo;
        EDocPaymentOccurrence."Created At" := CurrentDateTime();
        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Pending;
        EDocPaymentOccurrence.Insert();
    end;

    internal procedure ProcessPaymentOccurrence(var EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    var
        LastErrorText: Text;
    begin
        EDocPaymentOccurrence.LockTable();
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        if (EDocPaymentOccurrence.Status = EDocPaymentOccurrence.Status::Processed) or
           ((EDocPaymentOccurrence.Status = EDocPaymentOccurrence.Status::Processing) and
            (EDocPaymentOccurrence."Next Attempt At" > CurrentDateTime()))
        then
            exit;

        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Processing;
        EDocPaymentOccurrence."Last Attempt At" := CurrentDateTime();
        EDocPaymentOccurrence."Next Attempt At" := CurrentDateTime() + RetryDelay();
        EDocPaymentOccurrence.Modify();
        Commit();
        if Codeunit.Run(Codeunit::"E-Doc. Payment Occ. Runner", EDocPaymentOccurrence) then begin
            EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
            EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Processed;
            EDocPaymentOccurrence."Last Attempt At" := CurrentDateTime();
            EDocPaymentOccurrence."Next Attempt At" := 0DT;
            Clear(EDocPaymentOccurrence."Last Error");
            EDocPaymentOccurrence.Modify();
            exit;
        end;

        LastErrorText := GetLastErrorText();
        EDocPaymentOccurrence.Get(EDocPaymentOccurrence."Entry No.");
        EDocPaymentOccurrence.Status := EDocPaymentOccurrence.Status::Error;
        EDocPaymentOccurrence."Last Attempt At" := CurrentDateTime();
        EDocPaymentOccurrence."Retry Count" += 1;
        EDocPaymentOccurrence."Next Attempt At" := CurrentDateTime() + RetryDelay();
        EDocPaymentOccurrence."Last Error" := CopyStr(LastErrorText, 1, MaxStrLen(EDocPaymentOccurrence."Last Error"));
        EDocPaymentOccurrence.Modify();
        ClearLastError();
    end;

    internal procedure NotifyPaymentOccurrence(var EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    begin
        OnAfterCreatePaymentOccurrence(EDocPaymentOccurrence);
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

    local procedure IsInvoiceApplication(DetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"): Boolean
    begin
        exit(
            (DetailedCustLedgEntry."Entry Type" = DetailedCustLedgEntry."Entry Type"::Application) and
            (DetailedCustLedgEntry."Initial Document Type" = DetailedCustLedgEntry."Initial Document Type"::Invoice) and
            (DetailedCustLedgEntry.Amount < 0));
    end;

    /// <summary>
    /// Notifies localization and format apps after a payment occurrence has been persisted.
    /// </summary>
    /// <param name="EDocPaymentOccurrence">The persisted payment occurrence.</param>
    [IntegrationEvent(false, false)]
    procedure OnAfterCreatePaymentOccurrence(var EDocPaymentOccurrence: Record "E-Doc. Payment Occurrence")
    begin
    end;

    local procedure RetryDelay(): Duration
    begin
        exit(300000);
    end;
}