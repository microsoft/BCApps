// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Attachment;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 139896 "E-Doc. Attachment Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    Permissions = tabledata "E-Document" = rimd,
                  tabledata "Document Attachment" = rimd,
                  tabledata "E-Document Log" = rimd,
                  tabledata "E-Doc. Data Storage" = rimd;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";

    [Test]
    procedure UploadAttachmentToEDocSetsEDocFields()
    var
        EDocument: Record "E-Document";
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        RecRef: RecordRef;
        OutStream: OutStream;
        InStream: InStream;
    begin
        // [FEATURE] [E-Document] [Attachment]
        // [SCENARIO] Bug 619590: When uploading an attachment to an E-Document via the factbox,
        // the Document Attachment record must have "E-Document Attachment" = true and
        // "E-Document Entry No." set. Without OnBeforeInsertAttachment subscriber, these
        // fields are not populated and the attachment won't appear in the factbox.

        // [GIVEN] An E-Document record exists
        EDocument.Init();
        EDocument."Document Type" := "E-Document Type"::"Purchase Invoice";
        EDocument.Direction := "E-Document Direction"::Incoming;
        EDocument.Insert(true);

        // [GIVEN] A RecRef pointing to the E-Document
        // (In the real flow, OnAfterGetRecRefFail constructs this from the factbox SubPageLink filters)
        RecRef.GetTable(EDocument);

        // [WHEN] We save an attachment via SaveAttachmentFromStream (same path as factbox upload)
        TempBlob.CreateOutStream(OutStream);
        OutStream.WriteText('Test attachment content for bug 619590');
        TempBlob.CreateInStream(InStream);
        DocumentAttachment.Init();
        DocumentAttachment.SaveAttachmentFromStream(InStream, RecRef, 'test-edoc-attachment.txt');

        // [THEN] The Document Attachment is created with Table ID = E-Document
        DocumentAttachment.Reset();
        DocumentAttachment.SetRange("Table ID", Database::"E-Document");
        DocumentAttachment.SetRange("No.", Format(EDocument."Entry No"));
        DocumentAttachment.FindFirst();

        // [THEN] E-Document fields are set by the OnBeforeInsertAttachment subscriber
        Assert.IsTrue(DocumentAttachment."E-Document Attachment",
            'E-Document Attachment should be true — OnBeforeInsertAttachment subscriber must set this field');
        Assert.AreEqual(EDocument."Entry No", DocumentAttachment."E-Document Entry No.",
            'E-Document Entry No. should match the E-Document — OnBeforeInsertAttachment subscriber must set this field');
    end;

    [Test]
    procedure GetRefTableReturnsFalseForTableIdZero()
    var
        DocumentAttachment: Record "Document Attachment";
        DocumentAttachmentMgmt: Codeunit "Document Attachment Mgmt";
        RecRef: RecordRef;
    begin
        // [FEATURE] [E-Document] [Attachment]
        // [SCENARIO] Bug 619590: Verify precondition — GetRefTable returns false when Table ID = 0
        // This is the state of Rec in the factbox when no attachments exist (SubPageLink
        // does not set Table ID).

        // [GIVEN] A Document Attachment with Table ID = 0
        DocumentAttachment.Init();
        DocumentAttachment."Table ID" := 0;

        // [WHEN] GetRefTable is called
        // [THEN] It returns false because Table ID = 0 is not handled
        Assert.IsFalse(
            DocumentAttachmentMgmt.GetRefTable(RecRef, DocumentAttachment),
            'GetRefTable should return false for Table ID = 0');
    end;

    [Test]
    procedure ViewFileFindsExportedFileForOutgoingDocument()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
        FoundLog: Record "E-Document Log";
        DataStorageEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] View file on an outgoing E-Document resolves the exported file from the log.
        CreateOutgoingEDocument(EDocument);

        DataStorageEntryNo := CreateDataStorage('Exported.xml');
        InsertExportLog(EDocumentLog, EDocument, "E-Document Service Status"::Exported, DataStorageEntryNo);

        Assert.IsTrue(EDocument.TryGetExportedFileLog(FoundLog), 'The exported file log should be found for an outgoing E-Document.');
        Assert.AreEqual(DataStorageEntryNo, FoundLog."E-Doc. Data Storage Entry No.", 'The resolved log should point at the exported file.');
    end;

    [Test]
    procedure ViewFileReturnsLatestExportedFileForOutgoingDocument()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
        FoundLog: Record "E-Document Log";
        LatestDataStorageEntryNo: Integer;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] View file resolves the most recent exported file when an order is re-exported.
        CreateOutgoingEDocument(EDocument);
        InsertExportLog(EDocumentLog, EDocument, "E-Document Service Status"::Exported, CreateDataStorage('Exported1.xml'));
        LatestDataStorageEntryNo := CreateDataStorage('Exported2.xml');
        InsertExportLog(EDocumentLog, EDocument, "E-Document Service Status"::Exported, LatestDataStorageEntryNo);

        Assert.IsTrue(EDocument.TryGetExportedFileLog(FoundLog), 'The exported file log should be found for an outgoing E-Document.');
        Assert.AreEqual(LatestDataStorageEntryNo, FoundLog."E-Doc. Data Storage Entry No.", 'The most recent exported file should be resolved.');
    end;

    [Test]
    procedure ViewFileIgnoresNonExportedLogsForOutgoingDocument()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
        FoundLog: Record "E-Document Log";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] View file only surfaces the exported file, not blobs logged under other statuses.
        CreateOutgoingEDocument(EDocument);
        InsertExportLog(EDocumentLog, EDocument, "E-Document Service Status"::Sent, CreateDataStorage('Sent.xml'));

        Assert.IsFalse(EDocument.TryGetExportedFileLog(FoundLog), 'Only exported files should be surfaced by View file.');
    end;

    [Test]
    procedure ViewFileErrorsWhenOutgoingDocumentHasNoFile()
    var
        EDocument: Record "E-Document";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] View file on an outgoing E-Document with no exported file shows a clear message instead of a raw record-not-found error.
        CreateOutgoingEDocument(EDocument);

        asserterror EDocument.ViewSourceFile();

        Assert.ExpectedError('There is no file to view for this electronic document.');
        Assert.ExpectedErrorCode('Dialog');
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure ViewFileForOutgoingWithExportedFileShowsDownloadHint()
    var
        EDocument: Record "E-Document";
        EDocumentLog: Record "E-Document Log";
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO] View file on an outgoing E-Document with an exported file tells the user it can be downloaded from E-Document Logs.
        CreateOutgoingEDocument(EDocument);
        InsertExportLog(EDocumentLog, EDocument, "E-Document Service Status"::Exported, CreateDataStorage('Exported.xml'));

        EDocument.ViewSourceFile();

        Assert.AreEqual('This XML file cannot be viewed but can be downloaded from E-Document Logs.', LibraryVariableStorage.DequeueText(), 'The download hint message should be shown.');
        LibraryVariableStorage.AssertEmpty();
    end;

    local procedure CreateOutgoingEDocument(var EDocument: Record "E-Document")
    begin
        Clear(EDocument);
        EDocument."Document Type" := "E-Document Type"::"Sales Invoice";
        EDocument.Direction := "E-Document Direction"::Outgoing;
        EDocument."Unstructured Data Entry No." := 0;
        EDocument.Insert(true);
    end;

    local procedure CreateDataStorage(Name: Text[256]): Integer
    var
        EDocDataStorage: Record "E-Doc. Data Storage";
        OutStream: OutStream;
    begin
        EDocDataStorage.Init();
        EDocDataStorage.Name := Name;
        EDocDataStorage."File Format" := "E-Doc. File Format"::XML;
        EDocDataStorage.Insert(true);
        EDocDataStorage."Data Storage".CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('<Order/>');
        EDocDataStorage."Data Storage Size" := 8;
        EDocDataStorage.Modify(true);
        exit(EDocDataStorage."Entry No.");
    end;

    local procedure InsertExportLog(var EDocumentLog: Record "E-Document Log"; EDocument: Record "E-Document"; LogStatus: Enum "E-Document Service Status"; DataStorageEntryNo: Integer)
    begin
        Clear(EDocumentLog);
        EDocumentLog."E-Doc. Entry No" := EDocument."Entry No";
        EDocumentLog.Status := LogStatus;
        EDocumentLog."E-Doc. Data Storage Entry No." := DataStorageEntryNo;
        EDocumentLog.Insert(true);
    end;

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        LibraryVariableStorage.Enqueue(Message);
    end;
}
