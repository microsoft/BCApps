// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Navigate;
using System.TestLibraries.Utilities;

codeunit 139557 "E-Doc. Linkage Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        WrongValueErr: Label 'Wrong value';
        NoEDocumentForRecordMsg: Label 'No electronic document is linked to this record.';

    #region Tests

    [Test]
    procedure HasEDocumentReturnsTrueWhenLinked()
    var
        EDocument: Record "E-Document";
        LinkedRecordId: RecordId;
    begin
        //[SCENARIO] HasEDocument returns true when an E-Document is linked to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document is linked to a specific record id.
        LinkedRecordId := this.CreateEDocumentLinkedToRecord();

        //[WHEN] HasEDocument is called with that record id.
        this.Assert.IsTrue(EDocument.HasEDocument(LinkedRecordId), this.WrongValueErr);

        //[THEN] Verified in WHEN — the call returned true.
    end;

    [Test]
    procedure HasEDocumentReturnsFalseWhenNotLinked()
    var
        EDocument: Record "E-Document";
        UnlinkedRecordId: RecordId;
    begin
        //[SCENARIO] HasEDocument returns false when no E-Document is linked to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A record id for which no E-Document exists.
        UnlinkedRecordId := this.GetRecordIdWithoutEDocument();

        //[WHEN] HasEDocument is called with that record id.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocument(UnlinkedRecordId), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsTrueWhenAllIdentitiesMatch()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns true when document no., posting date, and partner all match.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentity('INV-001', WorkDate(), 'C-001');

        //[WHEN] HasEDocumentForDocument is called with the same identity.
        //[THEN] It returns true.
        this.Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-001', WorkDate(), 'C-001', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsFalseWhenDocumentNoIsEmpty()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false when the document number is empty, regardless of other data.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentity('INV-002', WorkDate(), 'C-002');

        //[WHEN] HasEDocumentForDocument is called with an empty document no.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocumentForDocument('', WorkDate(), 'C-002', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsFalseOnDifferentPostingDate()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false when the posting date does not match.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific posting date exists.
        this.CreateEDocumentWithIdentity('INV-003', WorkDate(), 'C-003');

        //[WHEN] HasEDocumentForDocument is called with a different posting date.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-003', WorkDate() + 1, 'C-003', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsFalseOnDifferentPartner()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false when the partner number does not match.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific partner exists.
        this.CreateEDocumentWithIdentity('INV-004', WorkDate(), 'C-004');

        //[WHEN] HasEDocumentForDocument is called with a different partner.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-004', WorkDate(), 'C-999', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentIgnoresPostingDateWhenBlank()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not filter on posting date when 0D is passed.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific posting date exists.
        this.CreateEDocumentWithIdentity('INV-005', WorkDate(), 'C-005');

        //[WHEN] HasEDocumentForDocument is called without a posting date filter.
        //[THEN] It returns true because the posting date filter is skipped.
        this.Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-005', 0D, 'C-005', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentIgnoresPartnerWhenBlank()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not filter on partner when an empty partner no. is passed.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific partner exists.
        this.CreateEDocumentWithIdentity('INV-006', WorkDate(), 'C-006');

        //[WHEN] HasEDocumentForDocument is called without a partner filter.
        //[THEN] It returns true because the partner filter is skipped.
        this.Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-006', WorkDate(), '', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentMatchesOnlySameDocumentNo()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false for a document no. that does not exist even when other E-Documents are present.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific document no. exists.
        this.CreateEDocumentWithIdentity('INV-007', WorkDate(), 'C-007');

        //[WHEN] HasEDocumentForDocument is called with a different document no.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-999', WorkDate(), 'C-007', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentDoesNotMatchDifferentDirection()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not match an E-Document that shares the same document no.,
        // posting date, and partner no. but has a different direction (e.g. a purchase invoice colliding with
        // a sales invoice number for the same partner code).

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An incoming E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentityDirectionAndStatus('INV-017', WorkDate(), 'C-017', Enum::"E-Document Direction"::Incoming, Enum::"E-Document Status"::"In Progress");

        //[WHEN] HasEDocumentForDocument is called with the same identity but the opposite direction.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-017', WorkDate(), 'C-017', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure GetLatestStatusReturnsBlankWhenRecordIdHasNoEDocument()
    var
        EDocument: Record "E-Document";
        UnlinkedRecordId: RecordId;
    begin
        //[SCENARIO] GetLatestStatus(RecordId) returns blank when no E-Document is linked to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A record id for which no E-Document exists.
        UnlinkedRecordId := this.GetRecordIdWithoutEDocument();

        //[WHEN] GetLatestStatus is called with that record id.
        //[THEN] It returns blank.
        this.Assert.AreEqual('', EDocument.GetLatestStatus(UnlinkedRecordId), this.WrongValueErr);
    end;

    [Test]
    procedure GetLatestStatusReturnsLatestStatusForRecordId()
    var
        EDocument: Record "E-Document";
        LinkedRecordId: RecordId;
    begin
        //[SCENARIO] GetLatestStatus(RecordId) returns the status of the most recently created E-Document when several are linked to the same record.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] Two E-Documents are linked to the same record id, the newest one being in error.
        LinkedRecordId := this.CreateEDocumentLinkedToRecordWithStatus(Enum::"E-Document Status"::Processed);
        this.LinkEDocumentToRecordWithStatus(LinkedRecordId, Enum::"E-Document Status"::Error);

        //[WHEN] GetLatestStatus is called with that record id.
        //[THEN] It returns the status of the newest E-Document.
        this.Assert.AreEqual(Format(Enum::"E-Document Status"::Error), EDocument.GetLatestStatus(LinkedRecordId), this.WrongValueErr);
    end;

    [Test]
    procedure GetLatestStatusForDocumentReturnsBlankWhenDocumentNoEmpty()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] GetLatestStatus(DocumentNo, PostingDate, PartnerNo) returns blank when the document number is empty.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentity('INV-015', WorkDate(), 'C-015');

        //[WHEN] GetLatestStatus is called with an empty document no.
        //[THEN] It returns blank.
        this.Assert.AreEqual('', EDocument.GetLatestStatus('', WorkDate(), 'C-015', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure GetLatestStatusForDocumentReturnsLatestStatusForIdentity()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] GetLatestStatus(DocumentNo, PostingDate, PartnerNo) returns the status of the most recently created E-Document sharing that identity.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] Two E-Documents share the same identity, the newest one being processed.
        this.CreateEDocumentWithIdentityAndStatus('INV-016', WorkDate(), 'C-016', Enum::"E-Document Status"::"In Progress");
        this.CreateEDocumentWithIdentityAndStatus('INV-016', WorkDate(), 'C-016', Enum::"E-Document Status"::Processed);

        //[WHEN] GetLatestStatus is called with the shared identity.
        //[THEN] It returns the status of the newest E-Document.
        this.Assert.AreEqual(Format(Enum::"E-Document Status"::Processed), EDocument.GetLatestStatus('INV-016', WorkDate(), 'C-016', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TryOpenEDocumentForDocumentShowsMessageWhenDocumentNoEmpty()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] TryOpenEDocumentForDocument returns false and shows the "no e-document" message when the document no. is empty.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists for a different record.
        this.CreateEDocumentWithIdentity('INV-008', WorkDate(), 'C-008');

        //[WHEN] TryOpenEDocumentForDocument is called with an empty document no.
        this.Assert.IsFalse(EDocument.TryOpenEDocumentForDocument('', WorkDate(), 'C-008', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);

        //[THEN] The "no e-document" message was shown.
        this.AssertNoEDocumentMessageShown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TryOpenEDocumentForDocumentShowsMessageWhenNoMatch()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] TryOpenEDocumentForDocument returns false and shows the "no e-document" message when no E-Document matches.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists for a different record.
        this.CreateEDocumentWithIdentity('INV-009', WorkDate(), 'C-009');

        //[WHEN] TryOpenEDocumentForDocument is called with an unmatched document no.
        this.Assert.IsFalse(EDocument.TryOpenEDocumentForDocument('INV-NOPE', WorkDate(), 'C-009', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);

        //[THEN] The "no e-document" message was shown.
        this.AssertNoEDocumentMessageShown();
    end;

    [Test]
    [HandlerFunctions('EDocumentCardModalPageHandler')]
    procedure TryOpenEDocumentForDocumentOpensCardWhenOneMatch()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] TryOpenEDocumentForDocument returns true and opens the E-Document card when exactly one E-Document matches.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A single E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentity('INV-013', WorkDate(), 'C-013');

        //[WHEN] TryOpenEDocumentForDocument is called with the matching identity.
        //[THEN] The E-Document card opens for the matching record (verified in the ModalPageHandler).
        this.LibraryVariableStorage.Enqueue('INV-013');
        this.Assert.IsTrue(EDocument.TryOpenEDocumentForDocument('INV-013', WorkDate(), 'C-013', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    [HandlerFunctions('EDocumentsListModalPageHandler')]
    procedure TryOpenEDocumentForDocumentOpensListWhenMultipleMatches()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] TryOpenEDocumentForDocument returns true and opens the E-Documents list when more than one E-Document matches.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] Two E-Documents with the same identity exist.
        this.CreateTwoEDocumentsWithSameIdentity('INV-014', WorkDate(), 'C-014');

        //[WHEN] TryOpenEDocumentForDocument is called with the shared identity.
        //[THEN] The E-Documents list opens showing both matching records (verified in the ModalPageHandler).
        this.Assert.IsTrue(EDocument.TryOpenEDocumentForDocument('INV-014', WorkDate(), 'C-014', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure NavigateHandlerFindEDocumentsInsertsRowWhenMatchExists()
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        EDocNavigateHandler: Codeunit "E-Doc. Navigate Handler";
    begin
        //[SCENARIO] E-Doc. Navigate Handler.FindEDocuments inserts a Document Entry row for the E-Document table when a match exists.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific document no. and posting date exists.
        this.CreateEDocumentWithIdentity('INV-010', WorkDate(), 'C-010');

        //[WHEN] FindEDocuments is called with matching filters.
        EDocNavigateHandler.FindEDocuments(TempDocumentEntry, 'INV-010', Format(WorkDate()));

        //[THEN] A Document Entry row for the E-Document table is present with one record.
        this.AssertDocumentEntryHasEDocumentRow(TempDocumentEntry, 1);
    end;

    [Test]
    procedure NavigateHandlerFindEDocumentsInsertsNoRowWhenNoMatch()
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        EDocNavigateHandler: Codeunit "E-Doc. Navigate Handler";
    begin
        //[SCENARIO] E-Doc. Navigate Handler.FindEDocuments does not insert a Document Entry row when no E-Document matches.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists for a different document no.
        this.CreateEDocumentWithIdentity('INV-011', WorkDate(), 'C-011');

        //[WHEN] FindEDocuments is called with a document no. that does not match.
        EDocNavigateHandler.FindEDocuments(TempDocumentEntry, 'INV-NOMATCH', Format(WorkDate()));

        //[THEN] No Document Entry row for the E-Document table is inserted.
        this.AssertDocumentEntryHasNoEDocumentRow(TempDocumentEntry);
    end;

    [Test]
    procedure NavigateHandlerFindEDocumentsCountsAllMatchingRecords()
    var
        TempDocumentEntry: Record "Document Entry" temporary;
        EDocNavigateHandler: Codeunit "E-Doc. Navigate Handler";
    begin
        //[SCENARIO] E-Doc. Navigate Handler.FindEDocuments reports the total count of matching E-Documents.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] Two E-Documents with the same document no. and posting date exist.
        this.CreateTwoEDocumentsWithSameIdentity('INV-012', WorkDate(), 'C-012');

        //[WHEN] FindEDocuments is called with matching filters.
        EDocNavigateHandler.FindEDocuments(TempDocumentEntry, 'INV-012', Format(WorkDate()));

        //[THEN] The Document Entry row for the E-Document table reports two records.
        this.AssertDocumentEntryHasEDocumentRow(TempDocumentEntry, 2);
    end;

    [Test]
    procedure HasEDocumentReturnsFalseWhenNoEDocumentsExist()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocument returns false when the company has no E-Documents at all - this is
        // what pages over large tables (ledger entries) use to skip per-row status lookups entirely.

        //[GIVEN] Test setup exists and no E-Documents exist.
        this.Initialize();

        //[WHEN] HasEDocument is called.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocument(), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentReturnsTrueWhenAnyEDocumentExists()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocument returns true as soon as any E-Document exists, regardless of what it links to.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists, unrelated to any specific source record.
        this.CreateEDocumentWithIdentity('INV-015', WorkDate(), 'C-015');

        //[WHEN] HasEDocument is called.
        //[THEN] It returns true.
        this.Assert.IsTrue(EDocument.HasEDocument(), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentDoesNotMatchDifferentDocumentType()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not match an E-Document that shares the same document no.,
        // posting date, partner no. and direction but has a different Document Type (e.g. an invoice and a
        // credit memo that happen to reuse the same document/partner combination).

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A Sales Invoice E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentityDirectionTypeAndStatus('INV-018', WorkDate(), 'C-018', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Document Status"::"In Progress");

        //[WHEN] HasEDocumentForDocument is called with the same identity but a different Document Type.
        //[THEN] It returns false.
        this.Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-018', WorkDate(), 'C-018', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::"Sales Credit Memo"), this.WrongValueErr);

        //[WHEN] HasEDocumentForDocument is called with the matching Document Type.
        //[THEN] It returns true.
        this.Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-018', WorkDate(), 'C-018', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::"Sales Invoice"), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentIgnoresDocumentTypeWhenNone()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not filter on Document Type when "None" is passed, preserving
        // the behavior expected by callers that cannot derive a Document Type (e.g. payments/refunds).

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A Sales Invoice E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentityDirectionTypeAndStatus('INV-019', WorkDate(), 'C-019', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Document Status"::"In Progress");

        //[WHEN] HasEDocumentForDocument is called without a Document Type filter.
        //[THEN] It returns true because the Document Type filter is skipped.
        this.Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-019', WorkDate(), 'C-019', Enum::"E-Document Direction"::Outgoing, Enum::"E-Document Type"::None), this.WrongValueErr);
    end;

    [Test]
    procedure OpenEDocumentDoesNothingWhenNoMatch()
    var
        EDocument: Record "E-Document";
        UnlinkedRecordId: RecordId;
    begin
        //[SCENARIO] OpenEDocument(RecordId) does nothing (no page opens, no message) when no E-Document is
        // linked to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A record id for which no E-Document exists.
        UnlinkedRecordId := this.GetRecordIdWithoutEDocument();

        //[WHEN] OpenEDocument is called with that record id.
        //[THEN] No page opens - a stray RunModal() with no registered handler would fail the test.
        EDocument.OpenEDocument(UnlinkedRecordId);
    end;

    [Test]
    [HandlerFunctions('EDocumentCardModalPageHandler')]
    procedure OpenEDocumentOpensCardWhenOneMatch()
    var
        EDocument: Record "E-Document";
        LinkedRecordId: RecordId;
    begin
        //[SCENARIO] OpenEDocument(RecordId) opens the E-Document card when exactly one E-Document is linked
        // to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A single E-Document linked to a specific record id.
        LinkedRecordId := this.CreateEDocumentLinkedToRecord();

        //[WHEN] OpenEDocument is called with that record id.
        //[THEN] The E-Document card opens for the matching record (verified in the ModalPageHandler).
        this.LibraryVariableStorage.Enqueue('');
        EDocument.OpenEDocument(LinkedRecordId);
    end;

    [Test]
    [HandlerFunctions('EDocumentsListModalPageHandler')]
    procedure OpenEDocumentOpensListWhenMultipleMatches()
    var
        EDocument: Record "E-Document";
        LinkedRecordId: RecordId;
    begin
        //[SCENARIO] OpenEDocument(RecordId) opens the E-Documents list when more than one E-Document is
        // linked to the given record id (resend, correction, cancel-and-recreate scenarios).

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] Two E-Documents are linked to the same record id.
        LinkedRecordId := this.CreateEDocumentLinkedToRecord();
        this.LinkEDocumentToRecordWithStatus(LinkedRecordId, Enum::"E-Document Status"::Processed);

        //[WHEN] OpenEDocument is called with that record id.
        //[THEN] The E-Documents list opens showing both matching records (verified in the ModalPageHandler).
        EDocument.OpenEDocument(LinkedRecordId);
    end;

    #endregion

    #region Initialize

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
    begin
        this.LibraryVariableStorage.Clear();
        EDocument.DeleteAll(false);
        if this.IsInitialized then
            exit;
        this.IsInitialized := true;
    end;

    #endregion

    #region Given

    local procedure InsertNewEDocument(var EDocument: Record "E-Document"; Direction: Enum "E-Document Direction")
    begin
        // Use the E-Document table itself as a stable source of a real RecordId — the linkage logic
        // only checks whether an "E-Document" row references the given RecordId; the target table is
        // irrelevant to the code under test.
        EDocument.Init();
        EDocument.Direction := Direction;
        EDocument.Insert(true);
    end;

    local procedure CreateEDocumentLinkedToRecord() LinkedRecordId: RecordId
    var
        EDocument: Record "E-Document";
    begin
        this.InsertNewEDocument(EDocument, Enum::"E-Document Direction"::Outgoing);
        LinkedRecordId := EDocument.RecordId();
        EDocument."Document Record ID" := LinkedRecordId;
        EDocument.Modify(false);
    end;

    local procedure GetRecordIdWithoutEDocument() UnlinkedRecordId: RecordId
    var
        EDocument: Record "E-Document";
    begin
        this.InsertNewEDocument(EDocument, Enum::"E-Document Direction"::Outgoing);
        UnlinkedRecordId := EDocument.RecordId();
        EDocument.Delete(false);
    end;

    local procedure CreateEDocumentLinkedToRecordWithStatus(Status: Enum "E-Document Status") LinkedRecordId: RecordId
    var
        EDocument: Record "E-Document";
    begin
        this.InsertNewEDocument(EDocument, Enum::"E-Document Direction"::Outgoing);
        LinkedRecordId := EDocument.RecordId();
        EDocument."Document Record ID" := LinkedRecordId;
        EDocument.Status := Status;
        EDocument.Modify(false);
    end;

    local procedure LinkEDocumentToRecordWithStatus(LinkedRecordId: RecordId; Status: Enum "E-Document Status")
    var
        EDocument: Record "E-Document";
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument."Document Record ID" := LinkedRecordId;
        EDocument.Status := Status;
        EDocument.Insert(true);
    end;

    local procedure CreateEDocumentWithIdentity(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20])
    begin
        this.CreateEDocumentWithIdentityAndStatus(DocumentNo, PostingDate, PartnerNo, Enum::"E-Document Status"::"In Progress");
    end;

    local procedure CreateEDocumentWithIdentityAndStatus(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20]; Status: Enum "E-Document Status")
    begin
        this.CreateEDocumentWithIdentityDirectionAndStatus(DocumentNo, PostingDate, PartnerNo, Enum::"E-Document Direction"::Outgoing, Status);
    end;

    local procedure CreateEDocumentWithIdentityDirectionAndStatus(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20]; Direction: Enum "E-Document Direction"; Status: Enum "E-Document Status")
    begin
        this.CreateEDocumentWithIdentityDirectionTypeAndStatus(DocumentNo, PostingDate, PartnerNo, Direction, Enum::"E-Document Type"::None, Status);
    end;

    local procedure CreateEDocumentWithIdentityDirectionTypeAndStatus(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20]; Direction: Enum "E-Document Direction"; DocumentType: Enum "E-Document Type"; Status: Enum "E-Document Status")
    var
        EDocument: Record "E-Document";
    begin
        EDocument.Init();
        EDocument.Direction := Direction;
        EDocument."Document No." := DocumentNo;
        EDocument."Posting Date" := PostingDate;
        EDocument."Bill-to/Pay-to No." := PartnerNo;
        EDocument."Document Type" := DocumentType;
        EDocument.Status := Status;
        EDocument.Insert(true);
    end;

    local procedure CreateTwoEDocumentsWithSameIdentity(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20])
    begin
        this.CreateEDocumentWithIdentity(DocumentNo, PostingDate, PartnerNo);
        this.CreateEDocumentWithIdentity(DocumentNo, PostingDate, PartnerNo);
    end;

    #endregion

    #region Then

    local procedure AssertNoEDocumentMessageShown()
    begin
        this.Assert.AreEqual(this.NoEDocumentForRecordMsg, this.LibraryVariableStorage.DequeueText(), this.WrongValueErr);
    end;

    local procedure AssertDocumentEntryHasEDocumentRow(var TempDocumentEntry: Record "Document Entry" temporary; ExpectedCount: Integer)
    begin
        TempDocumentEntry.SetRange("Table ID", Database::"E-Document");
        this.Assert.IsTrue(TempDocumentEntry.FindFirst(), 'Expected a Document Entry row for the E-Document table.');
        this.Assert.AreEqual(ExpectedCount, TempDocumentEntry."No. of Records", this.WrongValueErr);
    end;

    local procedure AssertDocumentEntryHasNoEDocumentRow(var TempDocumentEntry: Record "Document Entry" temporary)
    begin
        TempDocumentEntry.SetRange("Table ID", Database::"E-Document");
        this.Assert.IsTrue(TempDocumentEntry.IsEmpty(), 'Expected no Document Entry row for the E-Document table.');
    end;

    #endregion

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        this.LibraryVariableStorage.Enqueue(Message);
    end;

    [ModalPageHandler]
    procedure EDocumentCardModalPageHandler(var EDocumentPage: TestPage "E-Document")
    begin
        this.Assert.AreEqual(this.LibraryVariableStorage.DequeueText(), EDocumentPage."Document No.".Value(), this.WrongValueErr);
    end;

    [ModalPageHandler]
    procedure EDocumentsListModalPageHandler(var EDocumentsPage: TestPage "E-Documents")
    begin
        this.Assert.IsTrue(EDocumentsPage.First(), this.WrongValueErr);
        this.Assert.IsTrue(EDocumentsPage.Next(), this.WrongValueErr);
    end;
}
