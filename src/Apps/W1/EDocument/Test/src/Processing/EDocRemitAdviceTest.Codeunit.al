namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.RemittanceAdvice;
using Microsoft.Finance.GeneralLedger.Journal;
using Microsoft.Finance.GeneralLedger.Posting;
using Microsoft.Finance.GeneralLedger.Preview;
using Microsoft.Foundation.Address;
using Microsoft.Foundation.Company;
using Microsoft.Foundation.PaymentTerms;
using Microsoft.Inventory.Item;
using Microsoft.Peppol;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.Payables;
using Microsoft.Purchases.Reports;
using Microsoft.Purchases.Vendor;
using Microsoft.Sales.Customer;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139520 "E-Doc. Remit. Advice Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        EDocumentService: Record "E-Document Service";
        Customer: Record Customer;
        Vendor: Record Vendor;
        GenJournalBatch: Record "Gen. Journal Batch";
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibraryERM: Codeunit "Library - ERM";
        LibraryJournals: Codeunit "Library - Journals";
        LibraryUtility: Codeunit "Library - Utility";
        LibraryRandom: Codeunit "Library - Random";
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        LibraryReportDataset: Codeunit "Library - Report Dataset";
        LibraryJobQueue: Codeunit "Library - Job Queue";
        EDocImplState: Codeunit "E-Doc. Impl. State";
        IsInitialized: Boolean;
        IncorrectValueErr: Label 'Wrong value';

    [Test]
    [HandlerFunctions('RemitAdviceJournalRequestPageHandler')]
    procedure JournalReportCreatesEDocument()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [Remittance Advice] [E-Document]
        // [SCENARIO] Running report 399 with the Create E-Documents checkbox creates a Remittance Advice e-document for the payment
        Initialize();

        // [GIVEN] A posted purchase invoice and a payment journal line applied to it
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);

        // [WHEN] Report 399 runs with Create E-Documents enabled
        RunRemitAdviceJournalReport(true);

        // [THEN] An e-document of type Remittance Advice exists for the journal line with the payment data
        Assert.IsTrue(FindEDocumentForRecord(EDocument, GenJournalLine), 'An e-document should be created for the payment journal line');
        Assert.AreEqual(Enum::"E-Document Type"::"Remittance Advice", EDocument."Document Type", IncorrectValueErr);
        Assert.AreEqual(Enum::"E-Document Direction"::Outgoing, EDocument.Direction, IncorrectValueErr);
        Assert.AreEqual(GenJournalLine."Document No.", EDocument."Document No.", IncorrectValueErr);
        Assert.AreEqual(Vendor."No.", EDocument."Bill-to/Pay-to No.", IncorrectValueErr);
        Assert.AreEqual(GenJournalLine.SystemId, EDocument."Journal Line System ID", IncorrectValueErr);

        // [THEN] The service status is Exported and the journal line is flagged
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Exported);
        GenJournalLine.Find();
        Assert.IsTrue(GenJournalLine."Remit. Advice E-Doc. Created", 'The journal line should be flagged');
    end;

    [Test]
    [HandlerFunctions('RemitAdviceJournalRequestPageHandler')]
    procedure JournalReportCheckboxOffCreatesNothing()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Running report 399 with the checkbox off changes nothing
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);

        // [WHEN] Report 399 runs with Create E-Documents disabled
        RunRemitAdviceJournalReport(false);

        // [THEN] No e-document exists and the line is not flagged
        Assert.IsFalse(FindEDocumentForRecord(EDocument, GenJournalLine), 'No e-document should be created when the checkbox is off');
        GenJournalLine.Find();
        Assert.IsFalse(GenJournalLine."Remit. Advice E-Doc. Created", 'The journal line should not be flagged');
    end;

    [Test]
    [HandlerFunctions('RemitAdviceJournalRequestPageHandler')]
    procedure JournalReportCreatesOneEDocumentPerPaymentGroup()
    var
        Vendor2: Record Vendor;
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine1: Record "Gen. Journal Line";
        GenJournalLine2: Record "Gen. Journal Line";
        GenJournalLine3: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] A multi-line payment group yields one e-document (anchored on its first line); a second vendor's payment yields its own
        Initialize();

        // [GIVEN] Vendor 1: two journal lines under the same payment document no., each applied to its own invoice
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine1, Vendor."No.", InvoiceVendLedgEntry);
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine2, Vendor."No.", InvoiceVendLedgEntry);
        GenJournalLine2."Document No." := GenJournalLine1."Document No.";
        GenJournalLine2.Modify();

        // [GIVEN] Vendor 2 (same sending profile): one payment line applied to its own invoice
        LibraryPurchase.CreateVendor(Vendor2);
        Vendor2."Document Sending Profile" := Vendor."Document Sending Profile";
        Vendor2.Validate("VAT Bus. Posting Group", Vendor."VAT Bus. Posting Group");
        Vendor2.Modify(true);
        PostPurchaseInvoice(Vendor2."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine3, Vendor2."No.", InvoiceVendLedgEntry);

        // [WHEN] Report 399 runs with Create E-Documents enabled
        RunRemitAdviceJournalReport(true);

        // [THEN] One e-document per (vendor, document no.) group, anchored to the group's first line only
        Assert.IsTrue(FindEDocumentForRecord(EDocument, GenJournalLine1), 'Vendor 1 group should have an e-document on its anchor line');
        Assert.IsFalse(FindEDocumentForRecord(EDocument, GenJournalLine2), 'The second line of the group should not carry its own e-document');
        Assert.IsTrue(FindEDocumentForRecord(EDocument, GenJournalLine3), 'Vendor 2 payment should have its own e-document');

        // [THEN] All lines of both groups are flagged
        GenJournalLine1.Find();
        GenJournalLine2.Find();
        GenJournalLine3.Find();
        Assert.IsTrue(GenJournalLine1."Remit. Advice E-Doc. Created", 'Group line 1 should be flagged');
        Assert.IsTrue(GenJournalLine2."Remit. Advice E-Doc. Created", 'Group line 2 should be flagged');
        Assert.IsTrue(GenJournalLine3."Remit. Advice E-Doc. Created", 'Vendor 2 line should be flagged');
    end;

    [Test]
    [HandlerFunctions('RemitAdviceEntriesRequestPageHandler')]
    procedure EntriesReportCreatesEDocument()
    var
        PaymentVendLedgEntry: Record "Vendor Ledger Entry";
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Running report 400 with the Create E-Documents checkbox creates a Remittance Advice e-document for the posted payment
        Initialize();

        // [GIVEN] A posted vendor payment applied to an invoice
        PostAppliedPayment(Vendor."No.", PaymentVendLedgEntry);

        // [WHEN] Report 400 runs on the payment entry with Create E-Documents enabled
        RunRemitAdviceEntriesReport(PaymentVendLedgEntry, true);

        // [THEN] An e-document of type Remittance Advice exists for the vendor ledger entry
        Assert.IsTrue(FindEDocumentForRecord(EDocument, PaymentVendLedgEntry), 'An e-document should be created for the payment vendor ledger entry');
        Assert.AreEqual(Enum::"E-Document Type"::"Remittance Advice", EDocument."Document Type", IncorrectValueErr);
        Assert.AreEqual(PaymentVendLedgEntry."Document No.", EDocument."Document No.", IncorrectValueErr);
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Exported);
    end;

    [Test]
    [HandlerFunctions('RemitAdviceJournalRequestPageHandler,ConfirmHandlerNo')]
    procedure JournalReportRerunConfirmNoSkipsGroup()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        RecRef: RecordRef;
    begin
        // [SCENARIO] Rerunning report 399 on an already exported payment asks to confirm; answering No skips the group
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        RunRemitAdviceJournalReport(true);

        // [WHEN] The report runs again and the re-export confirm is declined
        RunRemitAdviceJournalReport(true);

        // [THEN] Still exactly one e-document for the anchor line
        RecRef.GetTable(GenJournalLine);
        EDocument.SetRange("Document Record ID", RecRef.RecordId());
        Assert.RecordCount(EDocument, 1);
    end;

    [Test]
    [HandlerFunctions('RemitAdviceJournalRequestPageHandler,ConfirmHandlerYes')]
    procedure JournalReportRerunConfirmYesReExportsSameEDocument()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        RecRef: RecordRef;
        FirstEntryNo: Integer;
    begin
        // [SCENARIO] Rerunning report 399 and confirming re-export reuses the same e-document record
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        RunRemitAdviceJournalReport(true);
        FindEDocumentForRecord(EDocument, GenJournalLine);
        FirstEntryNo := EDocument."Entry No";

        // [WHEN] The report runs again and the re-export confirm is accepted
        RunRemitAdviceJournalReport(true);

        // [THEN] The same e-document record was re-exported - no duplicate created
        RecRef.GetTable(GenJournalLine);
        EDocument.Reset();
        EDocument.SetRange("Document Record ID", RecRef.RecordId());
        Assert.RecordCount(EDocument, 1);
        EDocument.FindFirst();
        Assert.AreEqual(FirstEntryNo, EDocument."Entry No", 'Re-export should reuse the existing e-document');
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Exported);
    end;

    [Test]
    procedure PostingRePointsEDocumentToVendorLedgerEntry()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        PaymentVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        JournalLineSystemId: Guid;
        PaymentDocNo: Code[20];
    begin
        // [SCENARIO] Posting a flagged payment journal line re-points its e-document to the posted payment vendor ledger entry
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        Assert.IsTrue(EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false), 'Export should succeed');
        JournalLineSystemId := GenJournalLine.SystemId;
        PaymentDocNo := GenJournalLine."Document No.";

        // [WHEN] The payment journal is posted
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        // [THEN] The e-document's record id now points to the posted payment vendor ledger entry
        EDocument.SetRange("Journal Line System ID", JournalLineSystemId);
        EDocument.FindFirst();
        Assert.AreEqual(Database::"Vendor Ledger Entry", EDocument."Document Record ID".TableNo(), 'The e-document should point to the vendor ledger entry after posting');

        PaymentVendLedgEntry.SetRange("Document Type", PaymentVendLedgEntry."Document Type"::Payment);
        PaymentVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        PaymentVendLedgEntry.SetRange("Document No.", PaymentDocNo);
        PaymentVendLedgEntry.FindFirst();
        Assert.AreEqual(Format(PaymentVendLedgEntry.RecordId()), Format(EDocument."Document Record ID"), IncorrectValueErr);
        Assert.AreEqual(PaymentVendLedgEntry."Document No.", EDocument."Document No.", IncorrectValueErr);
        Assert.AreEqual(PaymentVendLedgEntry."Posting Date", EDocument."Posting Date", IncorrectValueErr);

        // [THEN] The e-document was not canceled by the journal-line deletion that posting performs
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Exported);
    end;

    [Test]
    procedure PreviewPostingDoesNotRePointEDocument()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        GenJnlPost: Codeunit "Gen. Jnl.-Post";
        GLPostingPreview: TestPage "G/L Posting Preview";
    begin
        // [SCENARIO] Preview posting does not re-point the e-document
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);
        Commit();

        // [WHEN] The journal is posted in preview mode
        GLPostingPreview.Trap();
        asserterror GenJnlPost.Preview(GenJournalLine);
        Assert.AreEqual('', GetLastErrorText(), 'Preview should end with an empty error');
        GLPostingPreview.Close();

        // [THEN] The e-document still points to the journal line
        Assert.IsTrue(FindEDocumentForRecord(EDocument, GenJournalLine), 'The e-document should still point to the journal line');
        Assert.AreEqual(Database::"Gen. Journal Line", EDocument."Document Record ID".TableNo(), IncorrectValueErr);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VoidClearsFlagAndCancelsEDocument()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] The Void action clears the group flag and cancels the e-document, keeping the record
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);
        Commit();

        // [WHEN] Void Remittance Advice E-Doc. is invoked on the payment line
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(GenJournalLine);
        PaymentJournal."Void Remittance Advice E-Doc.".Invoke();
        PaymentJournal.Close();

        // [THEN] The flag is cleared, the service status is Canceled and the e-document record still exists
        GenJournalLine.Find();
        Assert.IsFalse(GenJournalLine."Remit. Advice E-Doc. Created", 'The flag should be cleared after Void');
        Assert.IsTrue(FindEDocumentForRecord(EDocument, GenJournalLine), 'The e-document record should be kept after Void');
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Canceled);
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure VoidAfterSentErrors()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        PaymentJournal: TestPage "Payment Journal";
    begin
        // [SCENARIO] Voiding a payment whose e-document was already sent raises an error pointing to the E-Document page Cancel action
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);
        FindEDocumentForRecord(EDocument, GenJournalLine);

        // [GIVEN] The e-document's service status is Sent
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.FindFirst();
        EDocumentServiceStatus.Status := EDocumentServiceStatus.Status::Sent;
        EDocumentServiceStatus.Modify();
        Commit();

        // [WHEN] Void Remittance Advice E-Doc. is invoked
        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(GenJournalLine);
        asserterror PaymentJournal."Void Remittance Advice E-Doc.".Invoke();

        // [THEN] The action errors and the flag stays set
        Assert.ExpectedError('already been sent');
        GenJournalLine.Find();
        Assert.IsTrue(GenJournalLine."Remit. Advice E-Doc. Created", 'The flag should remain set when Void errors');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure ReExportAfterVoidReusesEDocument()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        PaymentJournal: TestPage "Payment Journal";
        RecRef: RecordRef;
        FirstEntryNo: Integer;
    begin
        // [SCENARIO] After Void, a new export run re-exports into the same (canceled) e-document
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);
        FindEDocumentForRecord(EDocument, GenJournalLine);
        FirstEntryNo := EDocument."Entry No";
        Commit();

        PaymentJournal.OpenEdit();
        PaymentJournal.CurrentJnlBatchName.SetValue(GenJournalBatch.Name);
        PaymentJournal.GotoRecord(GenJournalLine);
        PaymentJournal."Void Remittance Advice E-Doc.".Invoke();
        PaymentJournal.Close();

        // [WHEN] The payment is exported again after the void
        GenJournalLine.Find();
        Assert.IsTrue(EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false), 'Re-export after Void should succeed');

        // [THEN] The same e-document is reused, exported again, and the flag is set again
        RecRef.GetTable(GenJournalLine);
        EDocument.Reset();
        EDocument.SetRange("Document Record ID", RecRef.RecordId());
        Assert.RecordCount(EDocument, 1);
        EDocument.FindFirst();
        Assert.AreEqual(FirstEntryNo, EDocument."Entry No", 'Re-export after Void should reuse the e-document');
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Exported);
        GenJournalLine.Find();
        Assert.IsTrue(GenJournalLine."Remit. Advice E-Doc. Created", 'The flag should be set again after re-export');
    end;

    [Test]
    [HandlerFunctions('ConfirmHandlerYes')]
    procedure DeletingJournalLineCancelsEDocument()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        JournalLineSystemId: Guid;
    begin
        // [SCENARIO] Deleting an unposted flagged journal line cancels its e-document
        Initialize();
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);
        JournalLineSystemId := GenJournalLine.SystemId;

        // [WHEN] The journal line is deleted without posting
        GenJournalLine.Find();
        GenJournalLine.Delete(true);

        // [THEN] The e-document is kept but its service status is Canceled
        EDocument.SetRange("Journal Line System ID", JournalLineSystemId);
        EDocument.FindFirst();
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::Canceled);
    end;

    [Test]
    procedure FormatImplementationReceivesJournalAndEntryRecRef()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        PaymentVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        SourceDocumentHeader: RecordRef;
        DequeuedVariant: Variant;
        PaymentDocNo: Code[20];
    begin
        // [SCENARIO] The mock format's Create receives the journal line (table 81) and vendor ledger entry (table 25) as source document header
        // Create fires on every export (both first-time creation and re-export after posting re-points
        // the e-document), unlike OnBeforeCreateEDocument/OnAfterCreateEDocument which only fire once,
        // on first creation - so it's the event that reliably carries the source header both times.
        Initialize();
        BindSubscription(EDocImplState);
        EDocImplState.SetVariableStorage(LibraryVariableStorage);
        EDocImplState.EnableSourceDocumentHeaderCaptureEvent();

        // [WHEN] A journal payment is exported
        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);
        PaymentDocNo := GenJournalLine."Document No.";
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);

        // [THEN] The mock format's Create got the Gen. Journal Line record
        // This first export is a fresh creation, so OnBeforeCreateEDocument/OnAfterCreateEDocument
        // also fired and each enqueued the E-Document ahead of Create's source header - skip those.
        EDocImplState.GetVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(DequeuedVariant); // OnBeforeCreateEDocument's E-Document
        LibraryVariableStorage.Dequeue(DequeuedVariant); // OnAfterCreateEDocument's E-Document
        LibraryVariableStorage.Dequeue(DequeuedVariant); // Create's source document header
        SourceDocumentHeader.GetTable(DequeuedVariant);
        Assert.AreEqual(Database::"Gen. Journal Line", SourceDocumentHeader.Number(), 'Create should receive the journal line as source header');
        LibraryVariableStorage.Clear();
        EDocImplState.SetVariableStorage(LibraryVariableStorage);

        // [WHEN] The payment is posted and exported from the posted vendor ledger entry
        LibraryERM.PostGeneralJnlLine(GenJournalLine);
        PaymentVendLedgEntry.SetRange("Document Type", PaymentVendLedgEntry."Document Type"::Payment);
        PaymentVendLedgEntry.SetRange("Vendor No.", Vendor."No.");
        PaymentVendLedgEntry.SetRange("Document No.", PaymentDocNo);
        PaymentVendLedgEntry.FindFirst();
        EDocRemitAdviceExport.ExportFromPostedPayment(PaymentVendLedgEntry, true);

        // [THEN] The mock format's Create got the Vendor Ledger Entry record
        // This second export re-points the existing e-document (posting already re-pointed it to
        // the VLE), so OnBeforeCreateEDocument/OnAfterCreateEDocument don't fire this time - only
        // Create does, so its source header is the first (and only) item in the queue.
        EDocImplState.GetVariableStorage(LibraryVariableStorage);
        LibraryVariableStorage.Dequeue(DequeuedVariant); // Create's source document header
        SourceDocumentHeader.GetTable(DequeuedVariant);
        Assert.AreEqual(Database::"Vendor Ledger Entry", SourceDocumentHeader.Number(), 'Create should receive the vendor ledger entry as source header');

        UnbindSubscription(EDocImplState);
    end;

    [Test]
    procedure UnsupportedDocumentTypeCreatesNothing()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
    begin
        // [SCENARIO] When no service supports the Remittance Advice type, export is a silent no-op: no e-document, no error, no flag
        Initialize();
        EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice");
        EDocServiceSupportedType.Delete();

        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);

        // [WHEN] The payment is exported
        Assert.IsFalse(EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false), 'Export should report nothing was created');

        // [THEN] No e-document exists and the line is not flagged
        Assert.IsFalse(FindEDocumentForRecord(EDocument, GenJournalLine), 'No e-document should be created for an unsupported type');
        GenJournalLine.Find();
        Assert.IsFalse(GenJournalLine."Remit. Advice E-Doc. Created", 'The line should not be flagged when nothing was created');

        // Restore the supported type for subsequent tests
        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Remittance Advice");
    end;

    [Test]
    procedure CheckFailureSetsExportErrorStatus()
    var
        CompanyInformation: Record "Company Information";
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
        SavedVATRegNo: Text[20];
        SavedGLN: Code[13];
    begin
        // [SCENARIO] A PEPPOL check failure (company has neither VAT registration no. nor GLN) results in Export Error status
        Initialize();
        SetServiceDocumentFormat(Enum::"E-Document Format"::"PEPPOL BIS 3.0");
        CompanyInformation.Get();
        SavedVATRegNo := CompanyInformation."VAT Registration No.";
        SavedGLN := CompanyInformation.GLN;
        CompanyInformation."VAT Registration No." := '';
        CompanyInformation.GLN := '';
        CompanyInformation.Modify();

        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);

        // [WHEN] The payment is exported
        EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false);

        // [THEN] The e-document exists with service status Export Error
        Assert.IsTrue(FindEDocumentForRecord(EDocument, GenJournalLine), 'The e-document should exist even when the check fails');
        AssertServiceStatus(EDocument, Enum::"E-Document Service Status"::"Export Error");

        // Restore shared setup for subsequent tests
        CompanyInformation."VAT Registration No." := SavedVATRegNo;
        CompanyInformation.GLN := SavedGLN;
        CompanyInformation.Modify();
        SetServiceDocumentFormat(Enum::"E-Document Format"::Mock);
    end;

    [Test]
    procedure PeppolXmlContainsRemittanceAdviceData()
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        EDocument: Record "E-Document";
        TempBlob: Codeunit "Temp Blob";
        EDocumentLog: Codeunit "E-Document Log";
        EDocRemitAdviceExport: Codeunit "E-Doc. Remit. Advice Export";
    begin
        // [SCENARIO] With the PEPPOL BIS 3.0 format the exported blob is a UBL 2.1 RemittanceAdvice with the payment data
        Initialize();
        EnsureCompanyPeppolData();
        EnsureVendorPeppolData();
        SetServiceDocumentFormat(Enum::"E-Document Format"::"PEPPOL BIS 3.0");

        PostPurchaseInvoice(Vendor."No.", InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, Vendor."No.", InvoiceVendLedgEntry);

        // [WHEN] The payment is exported
        Assert.IsTrue(EDocRemitAdviceExport.ExportFromJournalLine(GenJournalLine, false), 'Export should succeed');

        // [THEN] The exported blob is a RemittanceAdvice document carrying the payment document no. and total
        FindEDocumentForRecord(EDocument, GenJournalLine);
        EDocumentLog.GetDocumentBlobFromLog(EDocument, EDocumentService, TempBlob, Enum::"E-Document Service Status"::Exported);
        Assert.IsTrue(TempBlob.HasValue(), 'The exported blob should have content');
        AssertRemittanceAdviceXml(TempBlob, GenJournalLine."Document No.");

        SetServiceDocumentFormat(Enum::"E-Document Format"::Mock);
    end;

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        LibraryVariableStorage.Clear();
        Clear(EDocImplState);

        EDocument.DeleteAll();
        EDocumentServiceStatus.DeleteAll();

        if IsInitialized then begin
            ClearRemitAdviceEDocFlag(GenJournalBatch);
            LibraryERM.ClearGenJournalLines(GenJournalBatch);
            exit;
        end;

        if BindSubscription(LibraryJobQueue) then;
        LibraryJobQueue.SetDoNotHandleCodeunitJobQueueEnqueueEvent(true);

        EDocumentService.DeleteAll();

        LibraryEDoc.SetupStandardVAT();
        LibraryEDoc.SetupStandardSalesScenario(Customer, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"Mock");
        LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"Mock");
        EDocumentService.Modify();
        LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Remittance Advice");
        LibraryEDoc.SetupCompanyInfo();

        Vendor."Document Sending Profile" := Customer."Document Sending Profile";
        Vendor.Modify(true);

        CreatePaymentJournalBatch();

        IsInitialized := true;
    end;

    local procedure CreatePaymentJournalBatch()
    var
        TemplateName: Code[10];
    begin
        TemplateName := LibraryJournals.SelectGenJournalTemplate(Enum::"Gen. Journal Template Type"::Payments, Page::"Payment Journal");
        LibraryJournals.SelectGenJournalBatch(GenJournalBatch, TemplateName);
        ClearRemitAdviceEDocFlag(GenJournalBatch);
        LibraryERM.ClearGenJournalLines(GenJournalBatch);
    end;

    local procedure ClearRemitAdviceEDocFlag(GenJnlBatch: Record "Gen. Journal Batch")
    var
        GenJournalLine: Record "Gen. Journal Line";
    begin
        // A previous test's export commits (E-Doc. Export's CreateEDocument) can leave flagged
        // lines behind, surviving the test's rollback. Clear the flag via ModifyAll (no OnDelete
        // trigger) so the cleanup below doesn't hit the delete-confirmation guard unhandled.
        GenJournalLine.SetRange("Journal Template Name", GenJnlBatch."Journal Template Name");
        GenJournalLine.SetRange("Journal Batch Name", GenJnlBatch.Name);
        GenJournalLine.ModifyAll("Remit. Advice E-Doc. Created", false);
    end;

    local procedure PostPurchaseInvoice(VendorNo: Code[20]; var InvoiceVendLedgEntry: Record "Vendor Ledger Entry")
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        Item: Record Item;
        InvoiceNo: Code[20];
    begin
        LibraryEDoc.GetGenericItem(Item);
        LibraryPurchase.CreatePurchHeader(PurchaseHeader, PurchaseHeader."Document Type"::Invoice, VendorNo);
        LibraryPurchase.CreatePurchaseLine(PurchaseLine, PurchaseHeader, PurchaseLine.Type::Item, Item."No.", LibraryRandom.RandInt(100));
        PurchaseLine.Validate("Direct Unit Cost", LibraryRandom.RandDecInRange(1, 100, 2));
        PurchaseLine.Modify(true);
        InvoiceNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, false, true);

        InvoiceVendLedgEntry.Reset();
        InvoiceVendLedgEntry.SetRange("Document Type", InvoiceVendLedgEntry."Document Type"::Invoice);
        InvoiceVendLedgEntry.SetRange("Document No.", InvoiceNo);
        InvoiceVendLedgEntry.SetRange("Vendor No.", VendorNo);
        InvoiceVendLedgEntry.FindFirst();
        InvoiceVendLedgEntry.CalcFields("Remaining Amount");
        InvoiceVendLedgEntry."Amount to Apply" := InvoiceVendLedgEntry."Remaining Amount";
        InvoiceVendLedgEntry.Modify();
    end;

    local procedure CreatePaymentLine(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; LineAmount: Decimal)
    begin
        LibraryERM.CreateGeneralJnlLineWithBalAcc(
            GenJournalLine, GenJournalBatch."Journal Template Name", GenJournalBatch.Name,
            GenJournalLine."Document Type"::Payment, GenJournalLine."Account Type"::Vendor, VendorNo,
            GenJournalLine."Bal. Account Type"::"G/L Account", LibraryERM.CreateGLAccountNo(), LineAmount);
    end;

    local procedure CreatePaymentLineAppliedToInvoice(var GenJournalLine: Record "Gen. Journal Line"; VendorNo: Code[20]; InvoiceVendLedgEntry: Record "Vendor Ledger Entry")
    begin
        CreatePaymentLine(GenJournalLine, VendorNo, -InvoiceVendLedgEntry."Remaining Amount");
        GenJournalLine.Validate("Applies-to Doc. Type", GenJournalLine."Applies-to Doc. Type"::Invoice);
        GenJournalLine.Validate("Applies-to Doc. No.", InvoiceVendLedgEntry."Document No.");
        GenJournalLine.Modify(true);
    end;

    local procedure PostAppliedPayment(VendorNo: Code[20]; var PaymentVendLedgEntry: Record "Vendor Ledger Entry")
    var
        InvoiceVendLedgEntry: Record "Vendor Ledger Entry";
        GenJournalLine: Record "Gen. Journal Line";
        PaymentDocNo: Code[20];
    begin
        PostPurchaseInvoice(VendorNo, InvoiceVendLedgEntry);
        CreatePaymentLineAppliedToInvoice(GenJournalLine, VendorNo, InvoiceVendLedgEntry);
        PaymentDocNo := GenJournalLine."Document No.";
        LibraryERM.PostGeneralJnlLine(GenJournalLine);

        PaymentVendLedgEntry.Reset();
        PaymentVendLedgEntry.SetRange("Document Type", PaymentVendLedgEntry."Document Type"::Payment);
        PaymentVendLedgEntry.SetRange("Vendor No.", VendorNo);
        PaymentVendLedgEntry.SetRange("Document No.", PaymentDocNo);
        PaymentVendLedgEntry.FindFirst();
    end;

    local procedure RunRemitAdviceJournalReport(CreateEDocs: Boolean)
    var
        FilterGenJournalLine: Record "Gen. Journal Line";
    begin
        LibraryVariableStorage.Enqueue(CreateEDocs);
        FilterGenJournalLine.SetRange("Journal Template Name", GenJournalBatch."Journal Template Name");
        FilterGenJournalLine.SetRange("Journal Batch Name", GenJournalBatch.Name);
        Commit();
        Report.Run(Report::"Remittance Advice - Journal", true, false, FilterGenJournalLine);
    end;

    local procedure RunRemitAdviceEntriesReport(PaymentVendLedgEntry: Record "Vendor Ledger Entry"; CreateEDocs: Boolean)
    var
        FilterVendorLedgerEntry: Record "Vendor Ledger Entry";
    begin
        LibraryVariableStorage.Enqueue(CreateEDocs);
        FilterVendorLedgerEntry.SetRange("Entry No.", PaymentVendLedgEntry."Entry No.");
        Commit();
        Report.Run(Report::"Remittance Advice - Entries", true, false, FilterVendorLedgerEntry);
    end;

    local procedure FindEDocumentForRecord(var EDocument: Record "E-Document"; RecVariant: Variant): Boolean
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(RecVariant);
        EDocument.Reset();
        EDocument.SetRange("Document Record ID", RecRef.RecordId());
        exit(EDocument.FindFirst());
    end;

    local procedure AssertServiceStatus(EDocument: Record "E-Document"; ExpectedStatus: Enum "E-Document Service Status")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.SetRange("E-Document Entry No", EDocument."Entry No");
        EDocumentServiceStatus.FindFirst();
        if EDocumentServiceStatus.Status <> ExpectedStatus then
            Error('Unexpected e-document service status for E-Document Entry No. %1. Expected %2, actual %3.', EDocument."Entry No", ExpectedStatus, EDocumentServiceStatus.Status);
    end;

    local procedure SetServiceDocumentFormat(EDocumentFormat: Enum "E-Document Format")
    begin
        EDocumentService."Document Format" := EDocumentFormat;
        EDocumentService.Modify();
    end;

    local procedure EnsureCompanyPeppolData()
    var
        CompanyInformation: Record "Company Information";
        CountryRegion: Record "Country/Region";
    begin
        CompanyInformation.Get();
        if CompanyInformation."VAT Registration No." = '' then
            CompanyInformation."VAT Registration No." := '123456789';
        if CompanyInformation."Country/Region Code" = '' then begin
            CountryRegion.SetFilter("ISO Code", '<>%1', '');
            CountryRegion.FindFirst();
            CompanyInformation."Country/Region Code" := CountryRegion.Code;
        end else begin
            CountryRegion.Get(CompanyInformation."Country/Region Code");
            if CountryRegion."ISO Code" = '' then begin
                CountryRegion."ISO Code" := 'XX';
                CountryRegion.Modify();
            end;
        end;
        CompanyInformation.Modify();
    end;

    local procedure EnsureVendorPeppolData()
    var
        CompanyInformation: Record "Company Information";
    begin
        CompanyInformation.Get();
        if Vendor."VAT Registration No." = '' then
            Vendor."VAT Registration No." := '987654321';
        if Vendor."Country/Region Code" = '' then
            Vendor."Country/Region Code" := CompanyInformation."Country/Region Code";
        Vendor.Modify();
    end;

    local procedure AssertRemittanceAdviceXml(var TempBlob: Codeunit "Temp Blob"; ExpectedPaymentDocNo: Code[20])
    var
        DocInStream: InStream;
        XmlDoc: XmlDocument;
        XmlNsManager: XmlNamespaceManager;
        XmlNode: XmlNode;
    begin
        TempBlob.CreateInStream(DocInStream, TextEncoding::UTF8);
        XmlDocument.ReadFrom(DocInStream, XmlDoc);
        XmlNsManager.NameTable(XmlDoc.NameTable());
        XmlNsManager.AddNamespace('ra', 'urn:oasis:names:specification:ubl:schema:xsd:RemittanceAdvice-2');
        XmlNsManager.AddNamespace('cbc', 'urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-2');

        Assert.IsTrue(XmlDoc.SelectSingleNode('/ra:RemittanceAdvice', XmlNsManager, XmlNode), 'The root element should be a RemittanceAdvice in the UBL 2.1 namespace');
        Assert.IsTrue(XmlDoc.SelectSingleNode('/ra:RemittanceAdvice/cbc:ID', XmlNsManager, XmlNode), 'The document should have a cbc:ID element');
        Assert.AreEqual(ExpectedPaymentDocNo, XmlNode.AsXmlElement().InnerText(), 'cbc:ID should be the payment document no.');
        Assert.IsTrue(XmlDoc.SelectSingleNode('/ra:RemittanceAdvice/cbc:TotalPaymentAmount', XmlNsManager, XmlNode), 'The document should have a cbc:TotalPaymentAmount element');
    end;

    [RequestPageHandler]
    procedure RemitAdviceJournalRequestPageHandler(var RemittanceAdviceJournal: TestRequestPage "Remittance Advice - Journal")
    begin
        RemittanceAdviceJournal.CreateEDocuments.SetValue(LibraryVariableStorage.DequeueBoolean());
        RemittanceAdviceJournal.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [RequestPageHandler]
    procedure RemitAdviceEntriesRequestPageHandler(var RemittanceAdviceEntries: TestRequestPage "Remittance Advice - Entries")
    begin
        RemittanceAdviceEntries.CreateEDocuments.SetValue(LibraryVariableStorage.DequeueBoolean());
        RemittanceAdviceEntries.SaveAsXml(LibraryReportDataset.GetParametersFileName(), LibraryReportDataset.GetFileName());
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerYes(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    [ConfirmHandler]
    procedure ConfirmHandlerNo(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;
}
