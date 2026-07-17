namespace Microsoft.eServices.EDocument.RemittanceAdvice;

using Microsoft.eServices.EDocument;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Foundation.Reporting;
using Microsoft.Purchases.Payables;

codeunit 6411 "E-Doc. Remit. Advice Export"
{
    Access = Internal;

    /// <summary>
    /// Resolves the document sending profile for the payment journal line's vendor and exports.
    /// See the profile-taking overload for behavior details.
    /// </summary>
    internal procedure ExportFromJournalLine(AnchorGenJnlLine: Record "Gen. Journal Line"; AllowReExport: Boolean): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        EDocumentProcessing: Codeunit "E-Document Processing";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(AnchorGenJnlLine);
        DocumentSendingProfile := EDocumentProcessing.GetDocSendingProfileForDocRef(RecRef);
        exit(ExportFromJournalLine(AnchorGenJnlLine, DocumentSendingProfile, AllowReExport));
    end;

    /// <summary>
    /// Validates the journal payment is fit to build a remittance advice from, creates/exports the
    /// E-Document, and flags the payment group's journal lines on success.
    /// Returns false (without error) when the profile is not set up for the Extended E-Document
    /// Service Flow, when the group is already flagged and re-export is not allowed, or when no
    /// e-document was created (e.g. no service supports the Remittance Advice document type).
    /// The profile is a parameter because callers like SendVendorRecords let the user modify it in
    /// the Select Sending Options dialog - re-resolving the vendor default here could contradict
    /// that choice.
    /// </summary>
    internal procedure ExportFromJournalLine(AnchorGenJnlLine: Record "Gen. Journal Line"; DocumentSendingProfile: Record "Document Sending Profile"; AllowReExport: Boolean): Boolean
    var
        EDocument: Record "E-Document";
        EDocRemittanceAdviceMgt: Codeunit "E-Doc. Remittance Advice Mgt.";
        EDocExport: Codeunit "E-Doc. Export";
        RecRef: RecordRef;
    begin
        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow" then
            exit(false);

        if (not AllowReExport) and EDocRemittanceAdviceMgt.HasExportedGroup(AnchorGenJnlLine) then
            exit(false);

        RecRef.GetTable(AnchorGenJnlLine);

        // After Void the group flag is cleared but the (canceled) e-document still exists;
        // exporting into it again requires the re-export path downstream.
        if not AllowReExport then
            AllowReExport := EDocRemittanceAdviceMgt.FindEDocument(EDocument, RecRef);

        EDocRemittanceAdviceMgt.CheckJournalPayment(AnchorGenJnlLine);

        EDocExport.CreateEDocument(RecRef, DocumentSendingProfile, Enum::"E-Document Type"::"Remittance Advice", AllowReExport);

        // CreateEDocument is a silent no-op when no service supports the document type - only
        // flag the group when an e-document actually exists for the anchor.
        if not EDocRemittanceAdviceMgt.FindEDocument(EDocument, RecRef) then
            exit(false);

        EDocRemittanceAdviceMgt.MarkGroupExported(AnchorGenJnlLine);
        exit(true);
    end;

    /// <summary>
    /// Resolves the document sending profile for the posted payment's vendor and exports.
    /// See the profile-taking overload for behavior details.
    /// </summary>
    internal procedure ExportFromPostedPayment(PaymentVendLedgEntry: Record "Vendor Ledger Entry"; AllowReExport: Boolean): Boolean
    var
        DocumentSendingProfile: Record "Document Sending Profile";
        EDocumentProcessing: Codeunit "E-Document Processing";
        AlreadyExists: Boolean;
        RecRef: RecordRef;
    begin
        RecRef.GetTable(PaymentVendLedgEntry);
        DocumentSendingProfile := EDocumentProcessing.GetDocSendingProfileForDocRef(RecRef);
        exit(ExportFromPostedPayment(PaymentVendLedgEntry, DocumentSendingProfile, AllowReExport, AlreadyExists));
    end;

    /// <summary>
    /// Validates the posted payment is fit to build a remittance advice from and creates/exports
    /// the E-Document. Returns false (without error) when the profile is not set up for the
    /// Extended E-Document Service Flow, or when an e-document already exists for this entry and
    /// re-export is not allowed (in which case AlreadyExists is set to true). The profile is a
    /// parameter for the same reason as the journal overload.
    /// </summary>
    internal procedure ExportFromPostedPayment(PaymentVendLedgEntry: Record "Vendor Ledger Entry"; DocumentSendingProfile: Record "Document Sending Profile"; AllowReExport: Boolean; var AlreadyExists: Boolean): Boolean
    var
        EDocument: Record "E-Document";
        EDocRemittanceAdviceMgt: Codeunit "E-Doc. Remittance Advice Mgt.";
        EDocExport: Codeunit "E-Doc. Export";
        RecRef: RecordRef;
    begin
        AlreadyExists := false;
        if DocumentSendingProfile."Electronic Document" <> DocumentSendingProfile."Electronic Document"::"Extended E-Document Service Flow" then
            exit(false);

        RecRef.GetTable(PaymentVendLedgEntry);

        if (not AllowReExport) and EDocRemittanceAdviceMgt.FindEDocument(EDocument, RecRef) then begin
            AlreadyExists := true;
            exit(false);
        end;

        EDocRemittanceAdviceMgt.CheckPostedPayment(PaymentVendLedgEntry);

        EDocExport.CreateEDocument(RecRef, DocumentSendingProfile, Enum::"E-Document Type"::"Remittance Advice", AllowReExport);
        exit(true);
    end;
}
