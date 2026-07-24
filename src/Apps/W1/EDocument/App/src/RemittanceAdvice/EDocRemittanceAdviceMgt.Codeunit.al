namespace Microsoft.eServices.EDocument.RemittanceAdvice;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Company;
using Microsoft.Peppol;
using Microsoft.Purchases.Payables;

codeunit 6530 "E-Doc. Remittance Advice Mgt."
{
    Access = Internal;

    var
        NoAppliedDocumentsErr: Label 'The payment has no applied documents. A remittance advice requires at least one applied document.';

    /// <summary>
    /// Validates an unposted vendor payment journal line (and its group) is fit to build a
    /// remittance advice buffer from. Buffer derivation lives in the PEPPOL app
    /// (Codeunit "Remit. Advice Buffer Mgt.") so format apps can reuse it without a Core dependency.
    /// </summary>
    internal procedure CheckJournalPayment(AnchorGenJnlLine: Record "Gen. Journal Line")
    var
        TempBuffer: Record "Remit. Advice Buffer" temporary;
        CompanyInformation: Record "Company Information";
        RemitAdviceBufferMgt: Codeunit "Remit. Advice Buffer Mgt.";
    begin
        AnchorGenJnlLine.TestField("Account Type", AnchorGenJnlLine."Account Type"::Vendor);
        AnchorGenJnlLine.TestField("Account No.");
        AnchorGenJnlLine.TestField("Document Type", AnchorGenJnlLine."Document Type"::Payment);
        AnchorGenJnlLine.TestField("Document No.");
        CompanyInformation.Get();

        RemitAdviceBufferMgt.BuildFromJournalPayment(AnchorGenJnlLine, TempBuffer);
        TempBuffer.SetFilter("Line No.", '>%1', 0);
        if TempBuffer.IsEmpty() then
            Error(NoAppliedDocumentsErr);
    end;

    /// <summary>
    /// Validates a posted payment Vendor Ledger Entry is fit to build a remittance advice buffer from.
    /// </summary>
    internal procedure CheckPostedPayment(PaymentVendLedgEntry: Record "Vendor Ledger Entry")
    var
        TempBuffer: Record "Remit. Advice Buffer" temporary;
        CompanyInformation: Record "Company Information";
        RemitAdviceBufferMgt: Codeunit "Remit. Advice Buffer Mgt.";
    begin
        PaymentVendLedgEntry.TestField("Document Type", PaymentVendLedgEntry."Document Type"::Payment);
        PaymentVendLedgEntry.TestField("Vendor No.");
        CompanyInformation.Get();

        RemitAdviceBufferMgt.BuildFromPostedPayment(PaymentVendLedgEntry, TempBuffer);
        TempBuffer.SetFilter("Line No.", '>%1', 0);
        if TempBuffer.IsEmpty() then
            Error(NoAppliedDocumentsErr);
    end;

    /// <summary>
    /// Finds the E-Document (of any type) whose "Document Record ID" matches the given record.
    /// </summary>
    internal procedure FindEDocument(var EDocument: Record "E-Document"; RecRef: RecordRef): Boolean
    begin
        EDocument.SetRange("Document Record ID", RecRef.RecordId());
        exit(EDocument.FindFirst());
    end;

    /// <summary>
    /// Finds the lowest-numbered vendor line of the payment group (same journal template, batch,
    /// account no. and document no.) that the given journal line belongs to. The anchor is the
    /// group's stable handle: e-documents are created against it and looked up through it.
    /// </summary>
    internal procedure FindGroupAnchor(SourceGenJnlLine: Record "Gen. Journal Line"; var AnchorGenJnlLine: Record "Gen. Journal Line"): Boolean
    begin
        AnchorGenJnlLine.SetCurrentKey("Journal Template Name", "Journal Batch Name", "Line No.");
        SetGroupFilters(AnchorGenJnlLine, SourceGenJnlLine);
        AnchorGenJnlLine.SetRange("Account Type", AnchorGenJnlLine."Account Type"::Vendor);
        exit(AnchorGenJnlLine.FindFirst());
    end;

    /// <summary>
    /// Returns true when any line of the payment group is flagged as having a remittance advice
    /// e-document created. Deliberately flag-based, not Record-ID-based: Gen. Journal Line numbers
    /// are reused after delete, so a Record ID lookup could match an unrelated older e-document.
    /// </summary>
    internal procedure HasExportedGroup(AnchorGenJnlLine: Record "Gen. Journal Line"): Boolean
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SetGroupFilters(GenJournalLine, AnchorGenJnlLine);
        GenJournalLine.SetRange("Remit. Advice E-Doc. Created", true);
        exit(not GenJournalLine.IsEmpty());
    end;

    /// <summary>
    /// Flags every line of the payment group as having a remittance advice e-document created.
    /// </summary>
    internal procedure MarkGroupExported(AnchorGenJnlLine: Record "Gen. Journal Line")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        SetGroupFilters(GenJournalLine, AnchorGenJnlLine);
        if GenJournalLine.FindSet(true) then
            repeat
                GenJournalLine.SetRemitAdviceEDocCreated();
            until GenJournalLine.Next() = 0;
    end;

    local procedure SetGroupFilters(var GenJournalLine: Record "Gen. Journal Line"; AnchorGenJnlLine: Record "Gen. Journal Line")
    begin
        GenJournalLine.SetRange("Journal Template Name", AnchorGenJnlLine."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", AnchorGenJnlLine."Journal Batch Name");
        GenJournalLine.SetRange("Account No.", AnchorGenJnlLine."Account No.");
        GenJournalLine.SetRange("Document No.", AnchorGenJnlLine."Document No.");
    end;
}
