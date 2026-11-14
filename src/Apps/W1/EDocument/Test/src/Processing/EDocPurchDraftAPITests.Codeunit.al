// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.eServices.EDocument.Processing.Import.Purchase;

// [FEATURE] [E-Document] [Purchase Draft] [External Writer]
codeunit 133509 "E-Doc Purch Draft API Tests"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EDocPurchaseDraftWriter: Codeunit "E-Doc. Purchase Draft Writer";
        LibraryEDoc: Codeunit "Library - E-Document";

    [Test]
    procedure PersistsHeaderAndLinesWithStandardLinkageAndLineNumbers()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] The public writer persists a staged header and lines with standard linkage and numbering.
        // [GIVEN] An incoming document, parsed header, and out-of-order temporary lines
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'External supplier';
        TempHeader."Sales Invoice No." := 'INV-100';
        AddTempLine(TempLines, 30000, 'Third line');
        AddTempLine(TempLines, 10000, 'First line');

        // [WHEN] The external reader persists the buffers
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] The standard header linkage, values, line order, and numbering are preserved
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Purchase draft header was not persisted.');
        Assert.AreEqual('External supplier', SavedHeader."Vendor Company Name", 'Vendor name must be preserved.');
        Assert.AreEqual('INV-100', SavedHeader."Sales Invoice No.", 'Invoice number must be preserved.');
        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(2, SavedLines.Count(), 'Both purchase draft lines must be persisted.');
        Assert.IsTrue(SavedLines.FindFirst(), 'Expected first persisted line.');
        Assert.AreEqual(10000, SavedLines."Line No.", 'First line must use standard numbering.');
        Assert.AreEqual('First line', SavedLines.Description, 'First line must follow temporary key order.');
        Assert.IsTrue(SavedLines.Next() <> 0, 'Expected second persisted line.');
        Assert.AreEqual(20000, SavedLines."Line No.", 'Second line must use standard numbering.');
        Assert.AreEqual('Third line', SavedLines.Description, 'Second line must follow temporary key order.');
    end;

    [Test]
    procedure ReimportReplacesPreviousHeaderAndLines()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] Re-importing replaces the complete previous purchase draft.
        // [GIVEN] An incoming document with a previously persisted header and two lines
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Old supplier';
        AddTempLine(TempLines, 10000, 'Old line');
        AddTempLine(TempLines, 20000, 'Another old line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        TempHeader."Vendor Company Name" := 'New supplier';
        TempLines.DeleteAll();
        AddTempLine(TempLines, 50000, 'Replacement line');
        // [WHEN] The new header and replacement lines are persisted
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] Only the new header and replacement line remain
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Replacement header must exist.');
        Assert.AreEqual('New supplier', SavedHeader."Vendor Company Name", 'Header must be replaced.');
        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        Assert.AreEqual(1, SavedLines.Count(), 'Previous lines must be removed.');
        Assert.IsTrue(SavedLines.FindFirst(), 'Replacement line must exist.');
        Assert.AreEqual(10000, SavedLines."Line No.", 'Line numbering must restart after replacement.');
        Assert.AreEqual('Replacement line', SavedLines.Description, 'Replacement line must be persisted.');
    end;

    [Test]
    procedure PersistsPurchaseCreditMemoUsingSameDraftContract()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLine: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] Purchase credit memos use the same staging persistence API.
        // [GIVEN] An incoming purchase credit memo and its parsed staging data
        CreateEDocument(EDocument);
        EDocument."Document Type" := Enum::"E-Document Type"::"Purchase Credit Memo";
        EDocument.Modify();
        TempHeader."Sales Invoice No." := 'CREDIT-100';
        AddTempLine(TempLines, 10000, 'Credit memo line');

        // [WHEN] The credit memo staging buffers are persisted
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] The credit memo staging values persist without changing the E-Document type
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Credit memo staging header must be persisted.');
        Assert.AreEqual('CREDIT-100', SavedHeader."Sales Invoice No.", 'Credit memo header data must be preserved.');
        Assert.IsTrue(SavedLine.Get(EDocument."Entry No", 10000), 'Credit memo staging line must be persisted.');
        Assert.AreEqual('Credit memo line', SavedLine.Description, 'Credit memo line data must be preserved.');
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(Enum::"E-Document Type"::"Purchase Credit Memo", EDocument."Document Type", 'PersistDraft must not change the E-Document type.');
    end;

    [Test]
    procedure EmptyLineBufferRemovesPreviousLines()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedLines: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] An empty line selection replaces the previous draft with no lines.
        // [GIVEN] An incoming document with an already persisted draft line
        CreateEDocument(EDocument);
        AddTempLine(TempLines, 10000, 'Previous line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        TempLines.DeleteAll();
        // [WHEN] The reader persists an empty line buffer
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        // [THEN] No old purchase lines remain
        Assert.IsTrue(SavedLines.IsEmpty(), 'An empty buffer must replace, not retain, previous lines.');
    end;

    [Test]
    procedure PersistingAnotherDocumentDoesNotChangeExistingDraft()
    var
        FirstEDocument: Record "E-Document";
        SecondEDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] Persisting a second document leaves the first document's draft untouched.
        // [GIVEN] Two distinct incoming documents and separately parsed draft data
        CreateEDocument(FirstEDocument);
        CreateEDocument(SecondEDocument);
        TempHeader."Vendor Company Name" := 'First supplier';
        AddTempLine(TempLines, 10000, 'First document line');
        EDocPurchaseDraftWriter.PersistDraft(FirstEDocument, TempHeader, TempLines);

        TempHeader."Vendor Company Name" := 'Second supplier';
        TempLines.DeleteAll();
        AddTempLine(TempLines, 10000, 'Second document line');
        // [WHEN] The reader persists the second document
        EDocPurchaseDraftWriter.PersistDraft(SecondEDocument, TempHeader, TempLines);

        // [THEN] Both documents retain their independent drafts
        Assert.IsTrue(SavedHeader.Get(FirstEDocument."Entry No"), 'First header must remain.');
        Assert.AreEqual('First supplier', SavedHeader."Vendor Company Name", 'First header must not change.');
        Assert.IsTrue(SavedHeader.Get(SecondEDocument."Entry No"), 'Second header must exist.');
        Assert.AreEqual('Second supplier', SavedHeader."Vendor Company Name", 'Second header must be independent.');
        SavedLines.SetRange("E-Document Entry No.", FirstEDocument."Entry No");
        Assert.IsTrue(SavedLines.FindFirst(), 'First line must remain.');
        Assert.AreEqual('First document line', SavedLines.Description, 'First line must not change.');
        SavedLines.SetRange("E-Document Entry No.", SecondEDocument."Entry No");
        Assert.IsTrue(SavedLines.FindFirst(), 'Second line must exist.');
        Assert.AreEqual('Second document line', SavedLines.Description, 'Second line must be independent.');
    end;

    [Test]
    procedure PersistDraftDoesNotModifyTemporaryInputs()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
    begin
        // [SCENARIO] The writer does not mutate the caller's temporary buffers.
        // [GIVEN] An incoming document and a temporary header and line
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Unchanged supplier';
        AddTempLine(TempLines, 30000, 'Unchanged line');

        // [WHEN] The caller passes its temporary buffers to the writer
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] The original temporary header and line are unchanged
        Assert.AreEqual(0, TempHeader."E-Document Entry No.", 'Input header linkage must not be overwritten.');
        Assert.AreEqual('Unchanged supplier', TempHeader."Vendor Company Name", 'Input header must remain intact.');
        Assert.IsTrue(TempLines.Get(0, 30000), 'Original temporary line key must remain intact.');
        Assert.AreEqual('Unchanged line', TempLines.Description, 'Input line must remain intact.');
    end;

    [Test]
    procedure RejectsMissingEDocumentWithoutWritingDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
    begin
        // [SCENARIO] An E-Document with no entry number cannot be persisted.
        // [GIVEN] An E-Document record without a persisted entry number
        EDocument."Entry No" := 0;
        // [WHEN] The writer is called with an unsaved E-Document
        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        // [THEN] The writer rejects the missing document
        Assert.ExpectedError('The E-Document must exist');
    end;

    [Test]
    procedure RejectsOutboundEDocumentWithoutWritingDraft()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
    begin
        // [SCENARIO] Outbound documents cannot use the incoming purchase draft writer.
        // [GIVEN] A persisted outgoing E-Document
        CreateEDocument(EDocument);
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Modify();

        // [WHEN] The writer is called with the outbound document
        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        // [THEN] The writer rejects the outbound direction without creating a draft
        Assert.ExpectedError('requires an incoming E-Document');
        Assert.IsFalse(SavedHeader.Get(EDocument."Entry No"), 'No purchase draft must be written.');
    end;

    [Test]
    procedure AcceptsFilteredTemporaryLineBufferLikeInternalUtility()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedLines: Record "E-Document Purchase Line";
    begin
        // [SCENARIO] Only lines visible through the temporary buffer filters are persisted.
        // [GIVEN] An incoming document and a temporary line selection excluding one line
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Filtered importer';
        AddTempLine(TempLines, 10000, 'Excluded line');
        AddTempLine(TempLines, 20000, 'Included line');
        TempLines.SetRange("Line No.", 20000);

        // [WHEN] The reader persists the filtered line selection
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        SavedLines.SetRange("E-Document Entry No.", EDocument."Entry No");
        // [THEN] Only the selected line persists with standard numbering
        Assert.AreEqual(1, SavedLines.Count(), 'Only the visible temporary lines must be persisted.');
        Assert.IsTrue(SavedLines.FindFirst(), 'The selected line must be persisted.');
        Assert.AreEqual('Included line', SavedLines.Description, 'Filtered record selection must match the internal utility.');
        Assert.AreEqual(10000, SavedLines."Line No.", 'Persisted line numbering must be regenerated.');
    end;

    [Test]
    procedure ReplacesEditedDraftWithoutChangingProcessingStatus()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        SavedLines: Record "E-Document Purchase Line";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [SCENARIO] Re-importing can retain edits explicitly supplied in buffers without changing the pre-preparation status.
        // [GIVEN] A Ready for draft document with a draft edited and copied back into temporary buffers
        CreateEDocument(EDocument);
        SetImportProcessingStatus(EDocument, Enum::"Import E-Doc. Proc. Status"::"Ready for draft");

        TempHeader."Vendor Company Name" := 'Original parsed header';
        AddTempLine(TempLines, 10000, 'Original parsed line');
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        SavedHeader.Get(EDocument."Entry No");
        SavedHeader."Vendor Company Name" := 'Manually edited header';
        SavedHeader.Modify();
        SavedLines.Get(EDocument."Entry No", 10000);
        SavedLines.Description := 'Manually edited line';
        SavedLines.Modify();

        TempHeader := SavedHeader;
        TempLines.DeleteAll();
        TempLines.Init();
        TempLines."E-Document Entry No." := SavedLines."E-Document Entry No.";
        TempLines."Line No." := SavedLines."Line No.";
        TempLines.Description := SavedLines.Description;
        TempLines.Insert();
        // [WHEN] The caller re-persists the explicitly edited draft data
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        SavedHeader.Get(EDocument."Entry No");
        SavedLines.Get(EDocument."Entry No", 10000);
        // [THEN] The supplied edits remain and the processing status is unchanged
        Assert.AreEqual('Manually edited header', SavedHeader."Vendor Company Name", 'Header edits should survive replacement when included in the buffer.');
        Assert.AreEqual('Manually edited line', SavedLines.Description, 'Line edits should survive replacement when included in the buffer.');
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocument.Service);
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::"Ready for draft", EDocumentServiceStatus."Import Processing Status", 'Persisting a draft must not itself change the import status.');
    end;

    [Test]
    procedure ReplacesPreparedDraftWithoutChangingProcessingStatus()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [SCENARIO] Low-level draft persistence is status-neutral, like the internal utility.
        // [GIVEN] An incoming E-Document with a prepared draft and Draft ready status
        CreateEDocument(EDocument);
        TempHeader."Vendor Company Name" := 'Original supplier';
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);
        SetImportProcessingStatus(EDocument, Enum::"Import E-Doc. Proc. Status"::"Draft ready");
        TempHeader."Vendor Company Name" := 'Replacement supplier';

        // [WHEN] The draft buffers are persisted through the low-level facade
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] The staging data is replaced, while the import status remains untouched
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Purchase draft header must exist.');
        Assert.AreEqual('Replacement supplier', SavedHeader."Vendor Company Name", 'Writer must match internal status-neutral draft replacement.');
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocument.Service);
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::"Draft ready", EDocumentServiceStatus."Import Processing Status", 'The writer must not modify the import-processing status.');
    end;

    [Test]
    procedure RejectsMissingPersistedEDocumentWithNonzeroEntryNo()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
    begin
        // [SCENARIO] A record with an assigned but nonexistent entry number cannot write a draft.
        // [GIVEN] An incoming E-Document with a nonexistent negative entry number
        EDocument.Init();
        EDocument."Entry No" := -1;
        EDocument.Direction := EDocument.Direction::Incoming;

        // [WHEN] The writer tries to persist the missing E-Document
        asserterror EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] The missing record is rejected before any draft is persisted
        Assert.ExpectedError('The E-Document must exist');
    end;

    [Test]
    procedure AllowsPersistenceForReadableDocument()
    var
        EDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
        SavedHeader: Record "E-Document Purchase Header";
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        // [SCENARIO] The normal read-into-draft stage can persist a purchase draft.
        // [GIVEN] An incoming E-Document in Readable state with a new parsed header
        CreateEDocument(EDocument);
        SetImportProcessingStatus(EDocument, Enum::"Import E-Doc. Proc. Status"::Readable);
        TempHeader."Vendor Company Name" := 'Parsed supplier';

        // [WHEN] The structured reader persists its purchase draft
        EDocPurchaseDraftWriter.PersistDraft(EDocument, TempHeader, TempLines);

        // [THEN] The draft is persisted and the orchestrator still owns the status transition
        Assert.IsTrue(SavedHeader.Get(EDocument."Entry No"), 'Readable document must accept its draft.');
        Assert.AreEqual('Parsed supplier', SavedHeader."Vendor Company Name", 'Parsed header data must be preserved.');
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocument.Service);
        Assert.AreEqual(Enum::"Import E-Doc. Proc. Status"::Readable, EDocumentServiceStatus."Import Processing Status", 'The writer must not advance the processing status.');
    end;

    [Test]
    procedure RejectsStaleIncomingRecordWhenStoredDocumentIsOutgoing()
    var
        EDocument: Record "E-Document";
        IncomingEDocument: Record "E-Document";
        TempHeader: Record "E-Document Purchase Header" temporary;
        TempLines: Record "E-Document Purchase Line" temporary;
    begin
        // [SCENARIO] The persisted direction check rejects stale incoming record arguments.
        // [GIVEN] A record argument still says Incoming while the persisted document is Outgoing
        CreateEDocument(EDocument);
        IncomingEDocument := EDocument;
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Modify();

        // [WHEN] The external reader tries to persist using the stale incoming record
        asserterror EDocPurchaseDraftWriter.PersistDraft(IncomingEDocument, TempHeader, TempLines);

        // [THEN] The database-backed direction validation rejects the write
        Assert.ExpectedError('requires an incoming E-Document');
    end;

    local procedure CreateEDocument(var EDocument: Record "E-Document")
    var
        EDocumentService: Record "E-Document Service";
    begin
        EDocumentService.Get(LibraryEDoc.CreateService(Enum::"E-Document Format"::Mock, Enum::"Service Integration"::"No Integration"));
        LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
    end;

    local procedure SetImportProcessingStatus(EDocument: Record "E-Document"; NewStatus: Enum "Import E-Doc. Proc. Status")
    var
        EDocumentServiceStatus: Record "E-Document Service Status";
    begin
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocument.Service);
        EDocumentServiceStatus.Validate("Import Processing Status", NewStatus);
        EDocumentServiceStatus.Modify();
    end;

    local procedure AddTempLine(var TempLines: Record "E-Document Purchase Line" temporary; LineNo: Integer; Description: Text[100])
    begin
        TempLines.Init();
        TempLines."E-Document Entry No." := 0;
        TempLines."Line No." := LineNo;
        TempLines.Description := Description;
        TempLines.Insert();
    end;
}
