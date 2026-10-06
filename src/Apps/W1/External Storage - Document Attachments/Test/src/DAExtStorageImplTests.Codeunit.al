// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.ExternalStorage.DocumentAttachments;
using Microsoft.Foundation.Attachment;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.Environment;
using System.ExternalFileStorage;
using System.TestLibraries.ExternalFileStorage;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 136820 "DA Ext. Storage Impl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "Document Attachment" = rimd,
                  tabledata "Tenant Media" = r,
                  tabledata "DA External Storage Setup" = rimd,
                  tabledata "DA Internal Cleanup Entry" = rimd,
                  tabledata "DA Cleanup Media Owner" = rimd;

    var
        Any: Codeunit Any;
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenarioMock: Codeunit "File Scenario Mock";
        Assert: Codeunit "Library Assert";
        CannotRetrieveExternalFileErr: Label 'could not be retrieved from external storage', Locked = true;
        DialogErrorCodeTok: Label 'Dialog', Locked = true;

    #region Successful Operations Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UploadSucceedsWithValidSetup()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Upload should succeed when feature is enabled and document has content
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] A document attachment with content
        CreateDocumentAttachmentWithContent(DocumentAttachment);

        // [WHEN] Upload is attempted
        Result := DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);

        // [THEN] Upload should succeed
        Assert.IsTrue(Result, 'Upload should succeed with valid setup');

        // [THEN] Document should be marked as stored externally
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'Document should be marked as stored externally');
        Assert.AreNotEqual('', DocumentAttachment."External File Path", 'External file path should be set');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UploadSetsCorrectMetadata()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        EnvironmentHash: Text[32];
    begin
        // [SCENARIO] Upload should set all required metadata fields
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] A document attachment with content
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        EnvironmentHash := DAExternalStorageImpl.GetCurrentEnvironmentHash();

        // [WHEN] Upload is performed
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);

        // [THEN] All metadata fields should be set correctly
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'Should be marked as externally stored');
        Assert.AreNotEqual(0DT, DocumentAttachment."External Upload Date", 'Upload date should be set');
        Assert.AreEqual(EnvironmentHash, DocumentAttachment."Source Environment Hash", 'Environment hash should match');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteFromExternalSucceedsForUploadedFile()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Delete from external should succeed for properly uploaded file
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] A document that has been uploaded to external storage
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();

        // [WHEN] Delete is attempted
        Result := DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment);

        // [THEN] Delete should succeed
        Assert.IsTrue(Result, 'Delete should succeed for uploaded file');

        // [THEN] Document should be marked as not stored externally
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'Document should not be marked as stored externally');
        Assert.AreEqual('', DocumentAttachment."External File Path", 'External file path should be cleared');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteFromInternalQueuesWithoutReadback()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Upload and a cleanup request must not remove media or fetch external content.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] A document that has been uploaded to external storage
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();

        // [WHEN] Delete from internal is attempted
        Result := DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment);

        Assert.IsTrue(Result, 'Cleanup request should be accepted');

        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'Internal content must remain until independent validation');
        Assert.IsTrue(DocumentAttachment."Document Reference ID".HasValue(), 'Request must not detach media');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Upload/request must not read back in the caller transaction');

        // [THEN] Document should still be marked as stored externally
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'Document should still be marked as stored externally');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MultipleUploadsCreateUniqueFiles()
    var
        DocumentAttachment1: Record "Document Attachment";
        DocumentAttachment2: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result1: Boolean;
        Result2: Boolean;
    begin
        // [SCENARIO] Multiple uploads should create unique file paths
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] Two document attachments with content
        CreateDocumentAttachmentWithContent(DocumentAttachment1);
        CreateDocumentAttachmentWithContent(DocumentAttachment2);

        // [WHEN] Both are uploaded
        Result1 := DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment1);
        Result2 := DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment2);

        // [THEN] Both uploads should succeed
        Assert.IsTrue(Result1, 'First upload should succeed');
        Assert.IsTrue(Result2, 'Second upload should succeed');

        // [THEN] Each document should have a unique path
        DocumentAttachment1.SetRecFilter();
        DocumentAttachment1.FindFirst();
        DocumentAttachment2.SetRecFilter();
        DocumentAttachment2.FindFirst();
        Assert.AreNotEqual(DocumentAttachment1."External File Path", DocumentAttachment2."External File Path",
            'Each document should have unique external path');
    end;

    #endregion

    #region Failure Condition Tests

    [Test]
    procedure UploadFailsWhenFeatureDisabled()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Upload should fail when feature is disabled
        Initialize();

        // [GIVEN] Feature is disabled
        if DAExternalStorageSetup.Get() then
            DAExternalStorageSetup.Delete();

        // [GIVEN] A document attachment with content
        CreateDocumentAttachmentWithContent(DocumentAttachment);

        // [WHEN] Upload is attempted
        Result := DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);

        // [THEN] Upload should fail
        Assert.IsFalse(Result, 'Upload should fail when feature is disabled');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UploadFailsForAlreadyUploadedDocument()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Upload should fail for already uploaded document
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] A document attachment already uploaded
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."External File Path" := 'existing/path.txt';
        DocumentAttachment.Modify();

        // [WHEN] Upload is attempted again
        Result := DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);

        // [THEN] Upload should fail
        Assert.IsFalse(Result, 'Upload should fail for already uploaded document');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UploadFailsWhenNoFileScenarioConfigured()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Upload should fail when no file scenario is configured
        Initialize();
        EnableFeatureOnly();

        // [GIVEN] No file scenario is configured (Initialize already clears all mappings)

        // [GIVEN] A document attachment with content
        CreateDocumentAttachmentWithContent(DocumentAttachment);

        // [WHEN] Upload is attempted
        Result := DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);

        // [THEN] Upload should fail
        Assert.IsFalse(Result, 'Upload should fail when no file scenario is configured');
    end;

    [Test]
    procedure DeleteFailsWhenFeatureDisabled()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Delete should fail when feature is disabled
        Initialize();

        // [GIVEN] Feature is disabled
        if DAExternalStorageSetup.Get() then
            DAExternalStorageSetup.Delete();

        // [GIVEN] A document attachment marked as externally stored
        CreateExternallyStoredDocument(DocumentAttachment);

        // [WHEN] Delete is attempted
        Result := DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment);

        // [THEN] Delete should fail
        Assert.IsFalse(Result, 'Delete should fail when feature is disabled');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DeleteSkippedWhenSkipDeleteOnCopyIsSet()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Delete should be skipped when Skip Delete On Copy is set
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] A document attachment with Skip Delete On Copy
        CreateExternallyStoredDocument(DocumentAttachment);
        DocumentAttachment."Skip Delete On Copy" := true;
        DocumentAttachment.Modify();

        // [WHEN] Delete is attempted
        Result := DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment);

        // [THEN] Delete should fail (skipped)
        Assert.IsFalse(Result, 'Delete should be skipped when Skip Delete On Copy is set');

        // [THEN] Document should still be marked as externally stored
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'Document should still be marked as stored externally');
    end;

    [Test]
    procedure LegacyExternalFlagDoesNotAuthorizeCleanup()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Legacy external flags alone do not establish upload provenance.
        Initialize();

        // [GIVEN] A document attachment with content and marked as externally stored
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment.Modify();

        // [WHEN] Delete from internal is attempted
        Result := DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment);

        Assert.IsFalse(Result, 'Legacy cleanup must be blocked');

        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'Legacy internal content must be retained');
    end;

    [Test]
    procedure DeleteFromInternalFailsForNonExternalDocument()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Delete from internal should fail for non-external document
        Initialize();

        // [GIVEN] A document attachment not stored externally
        CreateDocumentAttachmentWithContent(DocumentAttachment);

        // [WHEN] Delete from internal is attempted
        Result := DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment);

        // [THEN] Delete should fail
        Assert.IsFalse(Result, 'Delete from internal should fail for non-external document');
    end;

    #endregion

    #region OnAfterDelete Subscriber Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RecordDeleteRemovesBlobFromExternalStorage()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Deleting a Document Attachment row must delete its blob via the OnAfterDelete subscriber.
        // Regression test for the bug where the subscriber called DeleteFromExternalStorage(Rec), which
        // started with Rec.Find() and exited because the row was already gone, leaving the blob orphaned.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] A document attachment that has been uploaded to external storage
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        ExternalFilePath := DocumentAttachment."External File Path";
        Assert.AreNotEqual('', ExternalFilePath, 'Precondition: upload should set the External File Path');

        // [WHEN] The Document Attachment row is deleted (fires OnAfterDeleteEvent)
        DocumentAttachment.Delete(true);

        // [THEN] The subscriber invoked DeleteFile against the external connector with the stored path
        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(),
            'External connector DeleteFile should be invoked with the stored External File Path when the attachment row is deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RecordDeleteKeepsBlobWhenSkipDeleteOnCopyIsSet()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] When the row was created by an attachment copy, the blob is shared with the source
        // and must NOT be deleted when the copy is removed.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] An externally-stored attachment flagged as a copy
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        DocumentAttachment."Skip Delete On Copy" := true;
        DocumentAttachment.Modify();
        ExternalFilePath := DocumentAttachment."External File Path";

        // [WHEN] The row is deleted
        DocumentAttachment.Delete(true);

        // [THEN] The subscriber must NOT invoke DeleteFile for this path
        Assert.AreNotEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(),
            'External connector DeleteFile should not be invoked when Skip Delete On Copy is set');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RecordDeleteKeepsBlobWhenFileIsFromAnotherEnvironment()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Files owned by another environment or company must not be deleted
        // when the local attachment row is removed - the owning environment is responsible
        // for the blob's lifecycle.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] An externally-stored attachment carrying a foreign source environment hash
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        DocumentAttachment."Source Environment Hash" := 'DIFFERENTHASH123';
        DocumentAttachment.Modify();
        ExternalFilePath := DocumentAttachment."External File Path";

        // [WHEN] The row is deleted
        DocumentAttachment.Delete(true);

        // [THEN] The subscriber must NOT invoke DeleteFile for this path
        Assert.AreNotEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(),
            'External connector DeleteFile should not be invoked when the file belongs to another environment or company');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RecordDeleteKeepsBlobWhenDeleteFromExternalStorageDisabled()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] When the user opted out of automatic deletion, the blob must stay even if the row is deleted.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature(); // "Delete from External Storage" = false

        // [GIVEN] An uploaded externally-stored attachment
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        ExternalFilePath := DocumentAttachment."External File Path";

        // [WHEN] The row is deleted
        DocumentAttachment.Delete(true);

        // [THEN] The subscriber must NOT invoke DeleteFile when the feature setting opts out
        Assert.AreNotEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(),
            'External connector DeleteFile should not be invoked when Delete from External Storage is disabled');
    end;

    #endregion

    #region MIME Type Tests

    [Test]
    procedure FileExtensionToContentMimeTypeReturnsPdfForPdf()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ContentType: Text[100];
    begin
        // [SCENARIO] Should return correct MIME type for PDF
        Initialize();

        // [GIVEN] A document attachment with PDF extension
        DocumentAttachment.Init();
        DocumentAttachment."File Extension" := 'pdf';

        // [WHEN] Content type is requested
        DAExternalStorageImpl.FileExtensionToContentMimeType(DocumentAttachment, ContentType);

        // [THEN] Should return PDF MIME type
        Assert.AreEqual('application/pdf', ContentType, 'Should return PDF MIME type');
    end;

    [Test]
    procedure FileExtensionToContentMimeTypeReturnsJpegForJpg()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ContentType: Text[100];
    begin
        // [SCENARIO] Should return correct MIME type for JPG
        Initialize();

        // [GIVEN] A document attachment with JPG extension
        DocumentAttachment.Init();
        DocumentAttachment."File Extension" := 'jpg';

        // [WHEN] Content type is requested
        DAExternalStorageImpl.FileExtensionToContentMimeType(DocumentAttachment, ContentType);

        // [THEN] Should return JPEG MIME type
        Assert.AreEqual('image/jpeg', ContentType, 'Should return JPEG MIME type');
    end;

    [Test]
    procedure FileExtensionToContentMimeTypeReturnsOctetStreamForUnknown()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ContentType: Text[100];
    begin
        // [SCENARIO] Should return octet-stream for unknown extensions
        Initialize();

        // [GIVEN] A document attachment with unknown extension
        DocumentAttachment.Init();
        DocumentAttachment."File Extension" := 'xyz123';

        // [WHEN] Content type is requested
        DAExternalStorageImpl.FileExtensionToContentMimeType(DocumentAttachment, ContentType);

        // [THEN] Should return octet-stream
        Assert.AreEqual('application/octet-stream', ContentType, 'Should return octet-stream for unknown extension');
    end;

    [Test]
    procedure FileExtensionToContentMimeTypeReturnsDocxMimeType()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ContentType: Text[100];
    begin
        // [SCENARIO] Should return correct MIME type for DOCX
        Initialize();

        // [GIVEN] A document attachment with DOCX extension
        DocumentAttachment.Init();
        DocumentAttachment."File Extension" := 'docx';

        // [WHEN] Content type is requested
        DAExternalStorageImpl.FileExtensionToContentMimeType(DocumentAttachment, ContentType);

        // [THEN] Should return DOCX MIME type
        Assert.AreEqual('application/vnd.openxmlformats-officedocument.wordprocessingml.document', ContentType,
            'Should return DOCX MIME type');
    end;

    [Test]
    procedure FileExtensionToContentMimeTypeReturnsXlsxMimeType()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ContentType: Text[100];
    begin
        // [SCENARIO] Should return correct MIME type for XLSX
        Initialize();

        // [GIVEN] A document attachment with XLSX extension
        DocumentAttachment.Init();
        DocumentAttachment."File Extension" := 'xlsx';

        // [WHEN] Content type is requested
        DAExternalStorageImpl.FileExtensionToContentMimeType(DocumentAttachment, ContentType);

        // [THEN] Should return XLSX MIME type
        Assert.AreEqual('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet', ContentType,
            'Should return XLSX MIME type');
    end;

    #endregion

    #region Environment Hash Tests

    [Test]
    procedure GetCurrentEnvironmentHashReturnsConsistentValue()
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Hash1: Text[32];
        Hash2: Text[32];
    begin
        // [SCENARIO] Environment hash should be consistent
        Initialize();

        // [WHEN] Hash is generated twice
        Hash1 := DAExternalStorageImpl.GetCurrentEnvironmentHash();
        Hash2 := DAExternalStorageImpl.GetCurrentEnvironmentHash();

        // [THEN] Both hashes should be equal
        Assert.AreEqual(Hash1, Hash2, 'Environment hash should be consistent');

        // [THEN] Hash should not be empty
        Assert.AreNotEqual('', Hash1, 'Hash should not be empty');
    end;

    [Test]
    procedure IsFileFromAnotherEnvironmentReturnsFalseForCurrentEnvironment()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Should return false for files from current environment
        Initialize();

        // [GIVEN] A document with current environment hash
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Source Environment Hash" := DAExternalStorageImpl.GetCurrentEnvironmentHash();
        DocumentAttachment.Modify();

        // [WHEN] Checking if from another environment
        Result := DAExternalStorageImpl.IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment);

        // [THEN] Should return false
        Assert.IsFalse(Result, 'Should return false for current environment');
    end;

    [Test]
    procedure IsFileFromAnotherEnvironmentReturnsTrueForDifferentEnvironment()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Should return true for files from different environment
        Initialize();

        // [GIVEN] A document with different environment hash
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Source Environment Hash" := 'DIFFERENTHASH123';
        DocumentAttachment.Modify();

        // [WHEN] Checking if from another environment
        Result := DAExternalStorageImpl.IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment);

        // [THEN] Should return true
        Assert.IsTrue(Result, 'Should return true for different environment');
    end;

    [Test]
    procedure IsFileFromAnotherEnvironmentReturnsFalseForEmptyHash()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Should return false when source hash is empty
        Initialize();

        // [GIVEN] A document without source environment hash
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Source Environment Hash" := '';
        DocumentAttachment.Modify();

        // [WHEN] Checking if from another environment
        Result := DAExternalStorageImpl.IsFileFromAnotherEnvironmentOrCompany(DocumentAttachment);

        // [THEN] Should return false (assumes current environment)
        Assert.IsFalse(Result, 'Should return false when hash is empty');
    end;

    #endregion

    #region External File Status Tests

    [Test]
    procedure IsFileUploadedExternallyAndDeletedInternallyChecksAllConditions()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Should correctly identify externally stored and internally deleted files
        Initialize();

        // [GIVEN] A document that is externally stored but not internally stored
        CreateExternallyStoredOnlyDocument(DocumentAttachment);

        // [WHEN] Checking if uploaded externally and deleted internally
        Result := DAExternalStorageImpl.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment);

        // [THEN] Should return true
        Assert.IsTrue(Result, 'Should return true for externally stored and internally deleted file');
    end;

    [Test]
    procedure HasContentUsesExternalStorageMetadataWithFileAccount()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Checking attachment content should not contact external storage
        Initialize();
        SetupFileScenarioWithTestConnector();

        // [GIVEN] An externally stored attachment with a configured file account
        CreateExternallyStoredOnlyDocument(DocumentAttachment);

        // [WHEN] Checking if the attachment has content
        // [THEN] The external storage metadata indicates content is available
        Assert.IsTrue(DocumentAttachment.HasContent(), 'Externally stored attachment should report content from its metadata');
        Assert.AreEqual(0, FileConnectorMock.GetFileExistsCallCount(), 'Checking content should not call the external file connector');
    end;

    [Test]
    procedure HasContentUsesExternalStorageMetadataWithoutFileAccount()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] External attachment metadata remains available when the file account mapping is missing
        Initialize();

        // [GIVEN] An externally stored attachment without a configured file account
        CreateExternallyStoredOnlyDocument(DocumentAttachment);

        // [WHEN] Checking if the attachment has content
        // [THEN] The external storage metadata indicates content is available
        Assert.IsTrue(DocumentAttachment.HasContent(), 'Externally stored attachment should report content without a file account mapping');
    end;

    [Test]
    procedure HasContentUsesInternalStorageWithoutExternalCall()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Internally stored attachments continue to use the document reference
        Initialize();
        SetupFileScenarioWithTestConnector();

        // [GIVEN] An internally stored attachment
        CreateDocumentAttachmentWithContent(DocumentAttachment);

        // [WHEN] Checking if the attachment has content
        // [THEN] The internal content is available without calling external storage
        Assert.IsTrue(DocumentAttachment.HasContent(), 'Internally stored attachment should report content from its document reference');
        Assert.AreEqual(0, FileConnectorMock.GetFileExistsCallCount(), 'Internal content checks should not call the external file connector');
    end;

    [Test]
    procedure ExportToStreamErrorsWhenExternalFileCannotBeRetrieved()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        AttachmentOutStream: OutStream;
    begin
        // [SCENARIO] Exporting an unavailable external attachment surfaces an error
        Initialize();
        SetupFileScenarioWithTestConnector();
        FileConnectorMock.SetFailOnGetFile(true);

        // [GIVEN] An externally stored attachment that the connector cannot retrieve
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        TempBlob.CreateOutStream(AttachmentOutStream);

        // [WHEN] Exporting the attachment to a stream
        asserterror DocumentAttachment.ExportToStream(AttachmentOutStream);

        // [THEN] The retrieval failure is surfaced
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
        Assert.ExpectedError(CannotRetrieveExternalFileErr);
    end;

    [Test]
    procedure GetAsTempBlobErrorsWhenExternalFileCannotBeRetrieved()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Previewing an unavailable external attachment surfaces an error
        Initialize();
        SetupFileScenarioWithTestConnector();
        FileConnectorMock.SetFailOnGetFile(true);

        // [GIVEN] An externally stored attachment that the connector cannot retrieve
        CreateExternallyStoredOnlyDocument(DocumentAttachment);

        // [WHEN] Loading the attachment into a temporary blob
        asserterror DocumentAttachment.GetAsTempBlob(TempBlob);

        // [THEN] The retrieval failure is surfaced
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
        Assert.ExpectedError(CannotRetrieveExternalFileErr);
    end;

    [Test]
    procedure GetAsTempBlobErrorsWithoutFileAccount()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
    begin
        // [SCENARIO] Previewing an external attachment without a file account mapping surfaces an error
        Initialize();

        // [GIVEN] An externally stored attachment without a configured file account
        CreateExternallyStoredOnlyDocument(DocumentAttachment);

        // [WHEN] Loading the attachment into a temporary blob
        asserterror DocumentAttachment.GetAsTempBlob(TempBlob);

        // [THEN] The missing configuration is surfaced
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
        Assert.ExpectedError(CannotRetrieveExternalFileErr);
    end;

    [Test]
    procedure ExportToStreamErrorsWithoutFileAccount()
    var
        DocumentAttachment: Record "Document Attachment";
        TempBlob: Codeunit "Temp Blob";
        AttachmentOutStream: OutStream;
    begin
        // [SCENARIO] Exporting an external attachment without a file account mapping surfaces an error
        Initialize();

        // [GIVEN] An externally stored attachment without a configured file account
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        TempBlob.CreateOutStream(AttachmentOutStream);

        // [WHEN] Exporting the attachment to a stream
        asserterror DocumentAttachment.ExportToStream(AttachmentOutStream);

        // [THEN] The missing configuration is surfaced
        Assert.ExpectedErrorCode(DialogErrorCodeTok);
        Assert.ExpectedError(CannotRetrieveExternalFileErr);
    end;

    [Test]
    procedure IsFileUploadedExternallyReturnsFalseWhenStoredInternally()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Should return false when file is still stored internally
        Initialize();

        // [GIVEN] A document that is externally stored AND internally stored
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment."External File Path" := 'test/path/file.txt';
        DocumentAttachment.Modify();

        // [WHEN] Checking if uploaded externally and deleted internally
        Result := DAExternalStorageImpl.IsFileUploadedToExternalStorageAndDeletedInternally(DocumentAttachment);

        // [THEN] Should return false (still has internal copy)
        Assert.IsFalse(Result, 'Should return false when file is still stored internally');
    end;

    #endregion

    #region Shared Tenant Media Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure DeleteFromInternalKeepsMediaSharedWithCopiedAttachment()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        TenantMedia: Record "Tenant Media";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        SharedMediaId: Guid;
    begin
        // [SCENARIO] Deleting an attachment from internal storage must not remove the Tenant Media
        // while a copied attachment still references it.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] An attachment with content that has been copied to another document
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        SharedMediaId := DocumentAttachment."Document Reference ID".MediaId();
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);

        // [GIVEN] The original attachment is stored externally
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload should capture provenance');

        // [WHEN] The original is deleted from internal storage
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Delete from internal should succeed');
        RunCleanup();

        // [THEN] The shared Tenant Media is kept
        Assert.IsTrue(TenantMedia.Get(SharedMediaId), 'Shared Tenant Media should not be deleted');

        // [THEN] The copied attachment still has its content
        RefreshAttachment(CopiedDocumentAttachment);
        Assert.IsTrue(CopiedDocumentAttachment."Document Reference ID".HasValue(), 'Copied attachment should still have content');

        // [THEN] The original has released its own reference
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Document Reference ID".HasValue(), 'Original attachment should have released its media reference');
        Assert.IsFalse(DocumentAttachment."Stored Internally", 'Original should not be marked as stored internally');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure VerifiedCleanupDetachesWithoutDeletingMedia()
    var
        DocumentAttachment: Record "Document Attachment";
        TenantMedia: Record "Tenant Media";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        MediaId: Guid;
    begin
        // [SCENARIO] Cleanup detaches this reference without claiming globally safe physical reclamation.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] An attachment with content that is not shared and is stored externally
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        MediaId := DocumentAttachment."Document Reference ID".MediaId();
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload should capture provenance');

        // [WHEN] It is deleted from internal storage
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Delete from internal should succeed');
        RunCleanup();

        Assert.IsTrue(TenantMedia.Get(MediaId), 'This feature must not physically delete Tenant Media');
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Stored Internally", 'Reference should be detached after current nonempty readback');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure UploadSucceedsForCopiedAttachmentAfterSourceIsMigrated()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // [SCENARIO] A copied attachment can still be migrated after the attachment it was copied from
        // has been moved to external storage. The shared Tenant Media used to be deleted together with
        // the source, which left the copy with neither internal content nor an external file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();

        // [GIVEN] An attachment that has been copied to another document
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);

        // [GIVEN] The source attachment has been moved to external storage
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload of the source should succeed');
        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Delete from internal should succeed for the source');
        RunCleanup();

        // [WHEN] The copied attachment is uploaded
        RefreshAttachment(CopiedDocumentAttachment);
        Assert.IsTrue(CopiedDocumentAttachment."Document Reference ID".HasValue(), 'Copied attachment should still have content');

        // [THEN] The upload succeeds
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(CopiedDocumentAttachment), 'Upload of the copied attachment should succeed');

        // [THEN] Both attachments are stored externally, each in its own file
        RefreshAttachment(DocumentAttachment);
        RefreshAttachment(CopiedDocumentAttachment);
        Assert.IsTrue(CopiedDocumentAttachment."Stored Externally", 'Copied attachment should be marked as stored externally');
        Assert.AreNotEqual(DocumentAttachment."External File Path", CopiedDocumentAttachment."External File Path", 'Each attachment should have its own external file');
    end;

    #endregion

    #region Verified Cleanup Lifecycle Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure FailedReadbackRetainsMediaAndExternalTracking()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        Path: Text;
        MediaId: Guid;
    begin
        PrepareCleanup(Attachment);
        Path := Attachment."External File Path";
        MediaId := Attachment."Document Reference ID".MediaId();
        FileConnectorMock.SetFailOnGetFile(true);
        RunCleanup();
        RefreshAttachment(Attachment);
        Entry.Get(Attachment.SystemId);
        Assert.IsTrue(Attachment."Stored Internally", 'Failed readback must preserve internal content');
        Assert.AreEqual(MediaId, Attachment."Document Reference ID".MediaId(), 'Media must remain attached');
        Assert.AreEqual(Path, Attachment."External File Path", 'External path must not be untracked');
        Assert.IsTrue(Attachment."Stored Externally", 'External tracking must remain');
        Assert.AreEqual(Entry.Status::"Retry Due", Entry.Status, 'Readback failure should schedule a bounded retry');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Validation must never delete external content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure EmptyReadbackRetainsInternalContent()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        PrepareCleanup(Attachment);
        FileConnectorMock.ConfigureReadback('');
        RunCleanup();
        RefreshAttachment(Attachment);
        Entry.Get(Attachment.SystemId);
        Assert.IsTrue(Attachment."Stored Internally", 'Empty content must not authorize cleanup');
        Assert.AreEqual(Entry.Status::"Retry Due", Entry.Status, 'Empty content is inconclusive');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure TransformedReadbackCompletesWithoutByteEquality()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        PrepareCleanup(Attachment);
        FileConnectorMock.ConfigureReadback('x');
        RunCleanup();
        RefreshAttachment(Attachment);
        Entry.Get(Attachment.SystemId);
        Assert.IsFalse(Attachment."Stored Internally", 'Nonempty transformed content is retrievable');
        Assert.AreEqual(Entry.Status::Completed, Entry.Status, 'Cleanup should complete without original byte equality');
        Assert.AreEqual(Attachment."External File Path", FileConnectorMock.GetLastReadPath(), 'Use the exact stored path');
        Assert.AreEqual(Entry."Account ID", FileConnectorMock.GetLastReadAccountId(), 'Use the upload account');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CopyUploadDoesNotAuthorizeCleanup()
    var
        Attachment: Record "Document Attachment";
        CopyAttachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        Impl: Codeunit "DA External Storage Impl.";
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateDocumentAttachmentWithContent(Attachment);
        Assert.IsTrue(Impl.UploadToExternalStorage(Attachment), 'Copy upload should succeed');
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::"Not Requested", Entry.Status, 'Copy must not authorize cleanup');
        Assert.AreEqual(Entry.Origin::Copy, Entry.Origin, 'Copy provenance has no destructive intent');
        CreateCopyOfDocumentAttachment(Attachment, CopyAttachment);
        Assert.IsFalse(Entry.Get(CopyAttachment.SystemId), 'TransferFields must not copy authority into the new SystemId');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Copy must not perform verification');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PostedDocumentCopyAddsNoReadbackOrUpload()
    var
        Attachment: Record "Document Attachment";
        PostedAttachment: Record "Document Attachment";
        Source: Record "Sales Header";
        Posted: Record "Sales Invoice Header";
        SourceRef: RecordRef;
        PostedRef: RecordRef;
        Management: Codeunit "Document Attachment Mgmt";
        Impl: Codeunit "DA External Storage Impl.";
        CreateCalls: Integer;
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateDocumentAttachmentWithContent(Attachment);
        Attachment.Rename(Database::"Sales Header", Attachment."No.", Attachment."Document Type"::Order, Attachment."Line No.", Attachment.ID);
        Assert.IsTrue(Impl.UploadToExternalStorage(Attachment), 'Source should have existing external metadata');
        CreateCalls := FileConnectorMock.GetCreateFileCallCount();
        Source."Document Type" := Source."Document Type"::Order;
        Source."No." := Attachment."No.";
        SourceRef.GetTable(Source);
        Posted."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        PostedRef.GetTable(Posted);
        Management.CopyAttachmentsForPostedDocs(SourceRef, PostedRef);
        PostedAttachment.SetRange("Table ID", Database::"Sales Invoice Header");
        PostedAttachment.SetRange("No.", Posted."No.");
        Assert.IsTrue(PostedAttachment.FindFirst(), 'Posted copy must exist');
        Assert.IsTrue(PostedAttachment."Document Reference ID".HasValue(), 'Posted copy must retain internal media');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Posted attachment copying must not add a download');
        Assert.AreEqual(CreateCalls, FileConnectorMock.GetCreateFileCallCount(), 'Existing external metadata must not cause a new upload while copying');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RootFolderChangeDoesNotRecalculateStoredPath()
    var
        Attachment: Record "Document Attachment";
        Setup: Record "DA External Storage Setup";
        Path: Text;
    begin
        PrepareCleanup(Attachment);
        Path := Attachment."External File Path";
        Setup.Get();
        Setup."Root Folder" := 'new-root';
        Setup.Modify();
        RunCleanup();
        Assert.AreEqual(Path, FileConnectorMock.GetLastReadPath(), 'Readback must use persisted path, not a newly generated root path');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RestoreCancelsPendingCleanup()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        Impl: Codeunit "DA External Storage Impl.";
    begin
        PrepareCleanup(Attachment);
        Assert.IsTrue(Impl.DownloadFromExternalStorageToInternal(Attachment), 'Explicit internal restore should succeed');
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::Cancelled, Entry.Status, 'Restore must cancel prior destructive intent');
        Assert.IsTrue(Attachment."Stored Internally", 'Restore must retain internal content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SkipDeleteOnCopyBlocksBeforeReadback()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        PrepareCleanup(Attachment);
        Attachment."Skip Delete On Copy" := true;
        Attachment.Modify();
        RunCleanup();
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::Blocked, Entry.Status, 'Copy guard must remain authoritative');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Ownership rejection must not fetch content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ForeignEnvironmentBlocksBeforeReadback()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        PrepareCleanup(Attachment);
        Attachment."Source Environment Hash" := 'another-environment';
        Attachment.Modify();
        RunCleanup();
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::Blocked, Entry.Status, 'Foreign ownership must remain protected');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Foreign ownership must not fetch content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UnsupportedContextRetainsBothCopies()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        Impl: Codeunit "DA External Storage Impl.";
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.EnableDestinationContext(false);
        CreateDocumentAttachmentWithContent(Attachment);
        Assert.IsTrue(Impl.UploadToExternalStorage(Attachment), 'Unsupported context must not disable existing uploads');
        Assert.IsFalse(Impl.DeleteFromInternalStorage(Attachment), 'Missing context blocks destructive cleanup');
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::Blocked, Entry.Status, 'Show a blocked reason');
        RefreshAttachment(Attachment);
        Assert.IsTrue(Attachment."Stored Internally" and Attachment."Stored Externally", 'Retain both copies');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure AutomaticInsertRequestsWithoutReadback()
    var
        Attachment: Record "Document Attachment";
        SourceAttachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
        Setup: Record "DA External Storage Setup";
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        Setup.Get();
        Setup."Automatic Verified Cleanup" := true;
        Setup.Modify();
        CreateDocumentAttachmentWithContent(SourceAttachment);
        Attachment.TransferFields(SourceAttachment);
        Attachment.ID := SourceAttachment.ID + 1;
        Attachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        Attachment.Insert(true);
        RefreshAttachment(Attachment);
        Entry.Get(Attachment.SystemId);
        Assert.IsTrue(Attachment."Stored Internally", 'Insertion must not detach media');
        Assert.AreEqual(Entry.Status::Pending, Entry.Status, 'Opted-in insertion requests background cleanup');
        Assert.AreEqual(Entry.Origin::Automatic, Entry.Origin, 'Automatic origin should be recorded');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'No readback while inserting or posting');
        Assert.AreEqual(1, FileConnectorMock.GetCreateFileCallCount(), 'Only the existing upload should occur');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DefaultAutomaticUploadIsCopyOnly()
    var
        Source: Record "Document Attachment";
        Attachment: Record "Document Attachment";
        Setup: Record "DA External Storage Setup";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        Setup.Get();
        Assert.IsFalse(Setup."Automatic Verified Cleanup", 'Automatic cleanup must default off');
        CreateDocumentAttachmentWithContent(Source);
        Attachment.TransferFields(Source);
        Attachment.ID := Source.ID + 1;
        Attachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        Attachment.Insert(true);
        RefreshAttachment(Attachment);
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::"Not Requested", Entry.Status, 'Default automatic upload has no cleanup intent');
        Assert.IsTrue(Attachment."Stored Internally", 'Default automatic upload retains media');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Insertion must not read back');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TemporaryAndTriggerFalseInsertNeverUpload()
    var
        Source: Record "Document Attachment";
        TempAttachment: Record "Document Attachment" temporary;
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateDocumentAttachmentWithContent(Source);
        Assert.AreEqual(0, FileConnectorMock.GetCreateFileCallCount(), 'Insert(false) must not auto-upload');
        TempAttachment.TransferFields(Source);
        TempAttachment.Insert(true);
        Assert.AreEqual(0, FileConnectorMock.GetCreateFileCallCount(), 'Temporary Insert(true) must not upload');
        Assert.AreEqual(0, FileConnectorMock.GetReadbackCallCount(), 'Temporary/trigger-false insertion must not read back');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CancellationWinsOverReadback()
    begin
        AssertMutationRetainsContent(Enum::"DA Cleanup Test Mutation"::Cancel);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PathChangeWinsOverReadback()
    begin
        AssertMutationRetainsContent(Enum::"DA Cleanup Test Mutation"::Path);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ConfigurationChangeAwayAndBackBlocksCleanup()
    begin
        AssertMutationRetainsContent(Enum::"DA Cleanup Test Mutation"::Configuration);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure MediaReplacementWinsOverReadback()
    begin
        AssertMutationRetainsContent(Enum::"DA Cleanup Test Mutation"::Media);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure SupersededLeaseCannotDetach()
    begin
        AssertMutationRetainsContent(Enum::"DA Cleanup Test Mutation"::Lease);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure PolicyMutationBlocksCurrentAttempt()
    begin
        AssertMutationRetainsContent(Enum::"DA Cleanup Test Mutation"::Policy);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure RetryLimitRetainsContent()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        PrepareCleanup(Attachment);
        Entry.Get(Attachment.SystemId);
        Entry."Attempt Count" := 4;
        Entry.Modify();
        FileConnectorMock.SetFailOnGetFile(true);
        RunCleanup();
        Entry.Get(Attachment.SystemId);
        RefreshAttachment(Attachment);
        Assert.AreEqual(5, Entry."Attempt Count", 'Final retry should be counted');
        Assert.AreEqual(Entry.Status::Blocked, Entry.Status, 'Retries must stop at the configured limit');
        Assert.IsTrue(Attachment."Stored Internally", 'Exhausted retries retain content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure ExpiredAttemptPerformsFreshReadback()
    var
        Attachment: Record "Document Attachment";
        Entry: Record "DA Internal Cleanup Entry";
    begin
        PrepareCleanup(Attachment);
        Entry.Get(Attachment.SystemId);
        Entry.Status := Entry.Status::"In Progress";
        Entry."Lease Token" := CreateGuid();
        Entry."Lease Expires At" := CurrentDateTime() - 1000;
        Entry."Last Verified At" := CurrentDateTime() - 10000;
        Entry.Modify();
        RunCleanup();
        Assert.AreEqual(1, FileConnectorMock.GetReadbackCallCount(), 'An expired attempt cannot reuse its old evidence');
        Entry.Get(Attachment.SystemId);
        Assert.AreEqual(Entry.Status::Completed, Entry.Status, 'Fresh validation can complete restarted work');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure BatchLimitDefersRemainingWork()
    var
        Attachment: Record "Document Attachment";
        Attachment2: Record "Document Attachment";
        Setup: Record "DA External Storage Setup";
        Impl: Codeunit "DA External Storage Impl.";
    begin
        PrepareCleanup(Attachment);
        CreateDocumentAttachmentWithContent(Attachment2);
        Assert.IsTrue(Impl.UploadToExternalStorage(Attachment2), 'Second upload should succeed');
        Assert.IsTrue(Impl.DeleteFromInternalStorage(Attachment2), 'Second request should be accepted');
        Setup.Get();
        Setup."Cleanup Batch Size" := 1;
        Setup.Modify();
        RunCleanup();
        Assert.AreEqual(1, FileConnectorMock.GetReadbackCallCount(), 'One run must respect the finite attachment limit');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CrossTableMediaOwnerSurvivesDetachment()
    var
        Attachment: Record "Document Attachment";
        Owner: Record "DA Cleanup Media Owner";
        MediaId: Guid;
    begin
        PrepareCleanup(Attachment);
        MediaId := Attachment."Document Reference ID".MediaId();
        Owner.ID := CreateGuid();
        Owner.Media.Insert(MediaId);
        Owner.Insert();
        RunCleanup();
        Owner.Get(Owner.ID);
        Assert.AreEqual(MediaId, Owner.Media.Item(1), 'Supported cross-table MediaSet owner must retain its reference');
        Assert.IsTrue(Owner.Media.Count() > 0, 'Cross-table owner must remain populated');
        AssertMediaContentExists(MediaId);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure CrossCompanyAttachmentOwnerSurvivesDetachment()
    var
        Attachment: Record "Document Attachment";
        OtherAttachment: Record "Document Attachment";
        Company: Record Company;
        MediaId: Guid;
        OtherCompanyName: Text;
    begin
        PrepareCleanup(Attachment);
        Company.SetFilter(Name, '<>%1', CompanyName());
        if not Company.FindFirst() then
            Error('This ownership validation requires a second test company.');
        OtherCompanyName := Company.Name;
        MediaId := Attachment."Document Reference ID".MediaId();
        OtherAttachment.ChangeCompany(OtherCompanyName);
        OtherAttachment.TransferFields(Attachment);
        OtherAttachment.ID := Any.IntegerInRange(100000, 999999);
        OtherAttachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        OtherAttachment.Insert(false);
        Commit();
        RunCleanup();
        OtherAttachment.Get(OtherAttachment."Table ID", OtherAttachment."No.", OtherAttachment."Document Type", OtherAttachment."Line No.", OtherAttachment.ID);
        Assert.IsTrue(OtherAttachment."Document Reference ID".HasValue(), 'Another company must retain content after detachment');
        AssertMediaContentExists(MediaId);
        OtherAttachment.Delete(false);
        Commit();
    end;

    local procedure PrepareCleanup(var Attachment: Record "Document Attachment")
    var
        Impl: Codeunit "DA External Storage Impl.";
    begin
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateDocumentAttachmentWithContent(Attachment);
        Assert.IsTrue(Impl.UploadToExternalStorage(Attachment), 'Upload must succeed');
        Assert.IsTrue(Impl.DeleteFromInternalStorage(Attachment), 'Cleanup intent must be accepted');
    end;

    local procedure AssertMutationRetainsContent(Mutation: Enum "DA Cleanup Test Mutation")
    var
        Attachment: Record "Document Attachment";
        Subscriber: Codeunit "DA Cleanup Race Subscriber";
    begin
        PrepareCleanup(Attachment);
        Subscriber.SetMutation(Mutation);
        BindSubscription(Subscriber);
        RunCleanup();
        UnbindSubscription(Subscriber);
        RefreshAttachment(Attachment);
        Assert.IsTrue(Attachment."Stored Internally", 'State mutation must defeat stale cleanup authorization');
        Assert.IsTrue(Attachment."Document Reference ID".HasValue(), 'State mutation must retain local content');
        Assert.IsTrue(Attachment."Stored Externally", 'State mutation must not clear external tracking');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Cleanup must not delete external content');
    end;

    local procedure AssertMediaContentExists(MediaId: Guid)
    var
        TenantMedia: Record "Tenant Media";
    begin
        Assert.IsTrue(TenantMedia.Get(MediaId), 'Shared physical media must survive');
        TenantMedia.CalcFields(Content);
        Assert.IsTrue(TenantMedia.Content.HasValue(), 'Shared media content must remain nonempty');
    end;

    #endregion

    #region Helper Functions

    local procedure Initialize()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DocumentAttachment: Record "Document Attachment";
        CleanupEntry: Record "DA Internal Cleanup Entry";
        MediaOwner: Record "DA Cleanup Media Owner";
    begin
        // Clean up test data
        DocumentAttachment.DeleteAll();
        CleanupEntry.DeleteAll();
        MediaOwner.DeleteAll();
        if DAExternalStorageSetup.Get() then
            DAExternalStorageSetup.Delete();

        // Clean up file scenario mappings using mock
        FileScenarioMock.DeleteAllMappings();

        // Initialize file connector mock
        FileConnectorMock.Initialize();
        FileConnectorMock.EnableDestinationContext(true);
        FileConnectorMock.ConfigureReadback('Nonempty transformed external content');
    end;

    local procedure RunCleanup()
    var
        Worker: Codeunit "DA Internal Cleanup Worker";
    begin
        Commit();
        Worker.ProcessPending();
        Commit();
    end;

    local procedure SetupFileScenarioWithTestConnector()
    var
        AccountId: Guid;
    begin
        // Add a test account
        FileConnectorMock.AddAccount(AccountId);

        // Set up file scenario to use test connector using the mock
        FileScenarioMock.AddMapping(
            Enum::"File Scenario"::"Doc. Attach. - External Storage",
            AccountId,
            Enum::"Ext. File Storage Connector"::"Test File Storage Connector"
        );
    end;

    local procedure EnableFeature()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
    begin
        if not DAExternalStorageSetup.Get() then begin
            DAExternalStorageSetup.Init();
            DAExternalStorageSetup.Insert();
        end;
        DAExternalStorageSetup.Validate(Enabled, true);
        DAExternalStorageSetup.Validate("Delete from External Storage", false);
        DAExternalStorageSetup.Modify();
    end;

    local procedure EnableFeatureOnly()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
    begin
        // Enable with confirm handler
        if not DAExternalStorageSetup.Get() then begin
            DAExternalStorageSetup.Init();
            DAExternalStorageSetup.Insert();
        end;
        DAExternalStorageSetup.Validate(Enabled, true);
        DAExternalStorageSetup.Validate("Delete from External Storage", false);
        DAExternalStorageSetup.Modify();
    end;

    local procedure EnableFeatureWithDelete()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
    begin
        if not DAExternalStorageSetup.Get() then begin
            DAExternalStorageSetup.Init();
            DAExternalStorageSetup.Insert();
        end;
        DAExternalStorageSetup.Validate(Enabled, true);
        DAExternalStorageSetup.Validate("Delete from External Storage", true);
        DAExternalStorageSetup.Modify();
    end;

    local procedure CreateDocumentAttachmentWithContent(var DocumentAttachment: Record "Document Attachment")
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream, TextEncoding::UTF8);
        OutStream.WriteText('Test content for attachment ' + Any.AlphanumericText(10));
        TempBlob.CreateInStream(InStream);

        DocumentAttachment.Init();
        DocumentAttachment.ID := Any.IntegerInRange(10000, 99999);
        DocumentAttachment."Table ID" := Database::"Document Attachment";
        DocumentAttachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        DocumentAttachment."File Name" := 'TestFile_' + CopyStr(Any.AlphanumericText(5), 1, 5);
        DocumentAttachment."File Extension" := 'txt';
        DocumentAttachment."Stored Internally" := true;
        DocumentAttachment.Insert(false);
        DocumentAttachment.ImportAttachment(InStream, DocumentAttachment."File Name" + '.txt');
        DocumentAttachment.Modify(false);
    end;

    local procedure CreateCopyOfDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; var CopiedDocumentAttachment: Record "Document Attachment")
    begin
        // Mirrors Document Attachment Mgmt, which copies attachments onto posted documents with
        // TransferFields. That copies the media reference itself, so both records end up sharing
        // a single Tenant Media row.
        CopiedDocumentAttachment.Init();
        CopiedDocumentAttachment.TransferFields(DocumentAttachment);
        CopiedDocumentAttachment.ID := DocumentAttachment.ID + 1;
        CopiedDocumentAttachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        CopiedDocumentAttachment.Insert(false);

        Assert.AreEqual(
            DocumentAttachment."Document Reference ID".MediaId(),
            CopiedDocumentAttachment."Document Reference ID".MediaId(),
            'The copied attachment is expected to share the media of the attachment it was copied from');
    end;

    local procedure CreateExternallyStoredDocument(var DocumentAttachment: Record "Document Attachment")
    begin
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment."External File Path" := 'test/environment/Document_Attachment/file-' + Format(CreateGuid()) + '.txt';
        DocumentAttachment."External Upload Date" := CurrentDateTime();
        DocumentAttachment.Modify();
    end;

    local procedure CreateExternallyStoredOnlyDocument(var DocumentAttachment: Record "Document Attachment")
    begin
        DocumentAttachment.Init();
        DocumentAttachment.ID := Any.IntegerInRange(10000, 99999);
        DocumentAttachment."Table ID" := Database::"Document Attachment";
        DocumentAttachment."No." := CopyStr(Any.AlphanumericText(20), 1, 20);
        DocumentAttachment."File Name" := 'TestFile';
        DocumentAttachment."File Extension" := 'txt';
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment."Stored Internally" := false;
        DocumentAttachment."External File Path" := 'test/path/file.txt';
        DocumentAttachment.Insert();
    end;

    local procedure RefreshAttachment(var DocumentAttachment: Record "Document Attachment")
    begin
        DocumentAttachment.Get(
            DocumentAttachment."Table ID",
            DocumentAttachment."No.",
            DocumentAttachment."Document Type",
            DocumentAttachment."Line No.",
            DocumentAttachment.ID);
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    #endregion
}
