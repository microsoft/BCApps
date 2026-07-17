// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Formats;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
using Microsoft.Finance.Currency;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Setup;
using Microsoft.Finance.VAT.Ledger;
using Microsoft.Finance.VAT.Setup;
using Microsoft.Sales.History;
using Microsoft.Sales.Receivables;
using System.Utilities;

codeunit 10971 "FR E-Invoice Lifecycle Mgt."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Permissions = tabledata "FR E-Invoice Lifecycle" = rim,
                  tabledata "FR E-Invoice Lifecycle VAT" = ri;

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
        FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle";
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
            if IsFREInvoiceEDocument(EDocument) then begin
                FREInvoiceLifecycle := CapturePaymentOccurrence(
                    EDocument."Entry No", "FR E-Invoice Lifecycle Status"::Collected, DetailedCustLedgEntry.SystemId,
                    -DetailedCustLedgEntry.Amount, DetailedCustLedgEntry."Currency Code", DetailedCustLedgEntry."Posting Date",
                    InvoiceCustLedgerEntry."Entry No.", PaymentCustLedgerEntry."Entry No.", DetailedCustLedgEntry."Entry No.", 0);
                ScheduleMessageCreation(FREInvoiceLifecycle);
            end;
        until EDocument.Next() = 0;
    end;

    internal procedure ProcessDetailedLedgerUnapplication(OldDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry"; NewDetailedCustLedgEntry: Record "Detailed Cust. Ledg. Entry")
    var
        CollectedLifecycle: Record "FR E-Invoice Lifecycle";
        NegativeCollectedLifecycle: Record "FR E-Invoice Lifecycle";
    begin
        if not IsInvoiceApplication(OldDetailedCustLedgEntry) then
            exit;
        if not FindCollectedOccurrences(CollectedLifecycle, OldDetailedCustLedgEntry."Entry No.") then
            exit;

        repeat
            NegativeCollectedLifecycle := CapturePaymentOccurrence(
                CollectedLifecycle."E-Document Entry No.", "FR E-Invoice Lifecycle Status"::"Negative Collected", NewDetailedCustLedgEntry.SystemId,
                -CollectedLifecycle."Reported Amount", CollectedLifecycle."Currency Code", NewDetailedCustLedgEntry."Posting Date",
                CollectedLifecycle."Invoice Cust. Ledger Entry No.", CollectedLifecycle."Payment Cust. Ledger Entry No.", NewDetailedCustLedgEntry."Entry No.", CollectedLifecycle."Entry No.");
            ScheduleMessageCreation(NegativeCollectedLifecycle);
        until CollectedLifecycle.Next() = 0;
    end;

    internal procedure CapturePaymentOccurrence(EDocumentEntryNo: Integer; LifecycleStatus: Enum "FR E-Invoice Lifecycle Status"; SourceOccurrenceID: Guid; ReportedAmount: Decimal; CurrencyCode: Code[10]; EventDate: Date; InvoiceCustLedgerEntryNo: Integer; PaymentCustLedgerEntryNo: Integer; DetailedLedgerEntryNo: Integer; OriginalOccurrenceEntryNo: Integer) FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"
    begin
        CurrencyCode := ResolveCurrencyCode(CurrencyCode);
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

        if InvoiceCustLedgerEntryNo <> 0 then
            if LifecycleStatus = LifecycleStatus::Collected then
                CreateVATBreakdown(FREInvoiceLifecycle)
            else
                CreateReversalVATBreakdown(FREInvoiceLifecycle, OriginalOccurrenceEntryNo);
    end;

    local procedure CreateVATBreakdown(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    var
        InvoiceCustLedgerEntry: Record "Cust. Ledger Entry";
        VATEntry: Record "VAT Entry";
        VATPostingSetup: Record "VAT Posting Setup";
        AmountByVATRate: Dictionary of [Decimal, Decimal];
        VATRates: List of [Decimal];
        VATRate: Decimal;
        GrossAmount: Decimal;
        TotalGrossAmount: Decimal;
    begin
        InvoiceCustLedgerEntry.Get(FREInvoiceLifecycle."Invoice Cust. Ledger Entry No.");
        FindInvoiceVATEntries(VATEntry, InvoiceCustLedgerEntry);
        if VATEntry.FindSet() then
            repeat
                VATPostingSetup.Get(VATEntry."VAT Bus. Posting Group", VATEntry."VAT Prod. Posting Group");
                VATRate := VATPostingSetup."VAT %";
                GrossAmount := GetVATEntryGrossAmount(VATEntry, FREInvoiceLifecycle."Currency Code");
                AddVATRateAmount(AmountByVATRate, VATRates, VATRate, GrossAmount);
                TotalGrossAmount += GrossAmount;
            until VATEntry.Next() = 0;

        if (VATRates.Count() = 0) or (TotalGrossAmount = 0) then
            Error(VATBreakdownErr, InvoiceCustLedgerEntry."Document No.");

        InsertAllocatedVATAmounts(FREInvoiceLifecycle, AmountByVATRate, VATRates, TotalGrossAmount);
    end;

    local procedure FindInvoiceVATEntries(var VATEntry: Record "VAT Entry"; InvoiceCustLedgerEntry: Record "Cust. Ledger Entry")
    begin
        VATEntry.SetRange(Type, VATEntry.Type::Sale);
        VATEntry.SetRange("Document Type", VATEntry."Document Type"::Invoice);
        VATEntry.SetRange("Document No.", InvoiceCustLedgerEntry."Document No.");
        VATEntry.SetRange("Posting Date", InvoiceCustLedgerEntry."Posting Date");
        VATEntry.SetRange("Transaction No.", InvoiceCustLedgerEntry."Transaction No.");
    end;

    local procedure GetVATEntryGrossAmount(VATEntry: Record "VAT Entry"; CurrencyCode: Code[10]): Decimal
    begin
        if VATEntry."Source Currency Code" = CurrencyCode then
            exit(-(VATEntry."Source Currency VAT Base" + VATEntry."Source Currency VAT Amount"));

        if VATEntry."Source Currency Code" = '' then
            exit(-(VATEntry.Base + VATEntry.Amount));

        Error(VATEntryCurrencyErr, VATEntry."Entry No.", CurrencyCode);
    end;

    local procedure AddVATRateAmount(var AmountByVATRate: Dictionary of [Decimal, Decimal]; var VATRates: List of [Decimal]; VATRate: Decimal; GrossAmount: Decimal)
    begin
        if AmountByVATRate.ContainsKey(VATRate) then begin
            AmountByVATRate.Set(VATRate, AmountByVATRate.Get(VATRate) + GrossAmount);
            exit;
        end;

        AmountByVATRate.Add(VATRate, GrossAmount);
        VATRates.Add(VATRate);
    end;

    local procedure InsertAllocatedVATAmounts(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; AmountByVATRate: Dictionary of [Decimal, Decimal]; VATRates: List of [Decimal]; TotalGrossAmount: Decimal)
    var
        Currency: Record Currency;
        FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        AllocatedAmount: Decimal;
        RemainingAmount: Decimal;
        RoundingPrecision: Decimal;
        VATRate: Decimal;
        LineNo: Integer;
    begin
        RoundingPrecision := GetAmountRoundingPrecision(Currency, FREInvoiceLifecycle."Currency Code");
        RemainingAmount := FREInvoiceLifecycle."Reported Amount";
        LineNo := 0;
        foreach VATRate in VATRates do begin
            LineNo += 10000;
            if LineNo div 10000 = VATRates.Count() then
                AllocatedAmount := RemainingAmount
            else begin
                AllocatedAmount := Round(FREInvoiceLifecycle."Reported Amount" * AmountByVATRate.Get(VATRate) / TotalGrossAmount, RoundingPrecision);
                RemainingAmount -= AllocatedAmount;
            end;

            InsertVATBreakdown(FREInvoiceLifecycleVAT, FREInvoiceLifecycle."Entry No.", LineNo, VATRate, AllocatedAmount, FREInvoiceLifecycle."Currency Code");
        end;
    end;

    local procedure GetAmountRoundingPrecision(var Currency: Record Currency; CurrencyCode: Code[10]): Decimal
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        GeneralLedgerSetup.Get();
        if CurrencyCode = GeneralLedgerSetup."LCY Code" then
            exit(GeneralLedgerSetup."Amount Rounding Precision");

        Currency.Get(CurrencyCode);
        Currency.TestField("Amount Rounding Precision");
        exit(Currency."Amount Rounding Precision");
    end;

    local procedure CreateReversalVATBreakdown(FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; OriginalOccurrenceEntryNo: Integer)
    var
        OriginalLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
        ReversalLifecycleVAT: Record "FR E-Invoice Lifecycle VAT";
    begin
        OriginalLifecycleVAT.SetRange("Lifecycle Entry No.", OriginalOccurrenceEntryNo);
        if not OriginalLifecycleVAT.FindSet() then
            Error(OriginalVATBreakdownErr, OriginalOccurrenceEntryNo);

        repeat
            InsertVATBreakdown(
                ReversalLifecycleVAT, FREInvoiceLifecycle."Entry No.", OriginalLifecycleVAT."Line No.", OriginalLifecycleVAT."VAT %",
                -OriginalLifecycleVAT."Reported Amount", OriginalLifecycleVAT."Currency Code");
        until OriginalLifecycleVAT.Next() = 0;
    end;

    local procedure InsertVATBreakdown(var FREInvoiceLifecycleVAT: Record "FR E-Invoice Lifecycle VAT"; LifecycleEntryNo: Integer; LineNo: Integer; VATRate: Decimal; ReportedAmount: Decimal; CurrencyCode: Code[10])
    begin
        FREInvoiceLifecycleVAT.Init();
        FREInvoiceLifecycleVAT."Lifecycle Entry No." := LifecycleEntryNo;
        FREInvoiceLifecycleVAT."Line No." := LineNo;
        FREInvoiceLifecycleVAT."VAT %" := VATRate;
        FREInvoiceLifecycleVAT."Reported Amount" := ReportedAmount;
        FREInvoiceLifecycleVAT."Currency Code" := CurrencyCode;
        FREInvoiceLifecycleVAT.Insert();
    end;

    internal procedure CreateLifecycleMessage(var FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    var
        EDocument: Record "E-Document";
        EDocMessageMgt: Codeunit "E-Doc. Message Mgt.";
        FREInvoiceLifecycleMsg: Codeunit "FR E-Invoice Lifecycle Msg.";
        TempBlob: Codeunit "Temp Blob";
    begin
        if FREInvoiceLifecycle."E-Document Message Entry No." <> 0 then
            exit;

        EDocument.Get(FREInvoiceLifecycle."E-Document Entry No.");
        FREInvoiceLifecycleMsg.BuildLifecycleMessage(EDocument, FREInvoiceLifecycle, TempBlob);
        FREInvoiceLifecycle."E-Document Message Entry No." := EDocMessageMgt.CreateMessage(
            EDocument, "E-Document Message Type"::"FR Invoice Lifecycle", EDocument.Direction::Outgoing, TempBlob);
        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::"Message Created";
        Clear(FREInvoiceLifecycle."Last Error");
        FREInvoiceLifecycle.Modify();
    end;

    internal procedure RetryLifecycleMessage(var FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    begin
        FREInvoiceLifecycle.TestField("Processing Status", FREInvoiceLifecycle."Processing Status"::Failed);
        FREInvoiceLifecycle.TestField("E-Document Message Entry No.", 0);
        ScheduleMessageCreation(FREInvoiceLifecycle);
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

    local procedure FindCollectedOccurrences(var FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle"; DetailedLedgerEntryNo: Integer): Boolean
    begin
        FREInvoiceLifecycle.SetRange("Lifecycle Status", FREInvoiceLifecycle."Lifecycle Status"::Collected);
        FREInvoiceLifecycle.SetRange("Detailed Ledger Entry No.", DetailedLedgerEntryNo);
        exit(FREInvoiceLifecycle.FindSet());
    end;

    local procedure ScheduleMessageCreation(var FREInvoiceLifecycle: Record "FR E-Invoice Lifecycle")
    begin
        if FREInvoiceLifecycle."E-Document Message Entry No." <> 0 then
            exit;
        if FREInvoiceLifecycle."Processing Status" = FREInvoiceLifecycle."Processing Status"::Queued then
            exit;

        FREInvoiceLifecycle."Processing Status" := FREInvoiceLifecycle."Processing Status"::Queued;
        Clear(FREInvoiceLifecycle."Last Error");
        FREInvoiceLifecycle.Modify();
        TaskScheduler.CreateTask(
            Codeunit::"FR E-Invoice Lifecycle Worker", Codeunit::"FR E-Invoice Lifecycle Error", true,
            CompanyName(), CurrentDateTime(), FREInvoiceLifecycle.RecordId);
    end;

    local procedure ResolveCurrencyCode(CurrencyCode: Code[10]): Code[10]
    var
        GeneralLedgerSetup: Record "General Ledger Setup";
    begin
        if CurrencyCode <> '' then
            exit(CurrencyCode);

        GeneralLedgerSetup.Get();
        GeneralLedgerSetup.TestField("LCY Code");
        exit(GeneralLedgerSetup."LCY Code");
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
        VATBreakdownErr: Label 'A VAT breakdown could not be determined for posted sales invoice %1.', Comment = '%1 = posted sales invoice number';
        VATEntryCurrencyErr: Label 'VAT entry %1 does not contain amounts in lifecycle currency %2.', Comment = '%1 = VAT entry number, %2 = currency code';
        OriginalVATBreakdownErr: Label 'The VAT breakdown for original lifecycle occurrence %1 does not exist.', Comment = '%1 = lifecycle occurrence entry number';
}