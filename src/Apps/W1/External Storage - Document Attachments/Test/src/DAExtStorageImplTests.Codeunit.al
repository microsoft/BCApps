// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.ExternalStorage.DocumentAttachments;
using Microsoft.Foundation.Attachment;
using Microsoft.Purchases.Document;
using Microsoft.Purchases.History;
using Microsoft.Purchases.Setup;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using Microsoft.Sales.Setup;
using System.Environment;
using System.ExternalFileStorage;
using System.TestLibraries.ExternalFileStorage;
using System.TestLibraries.Upgrade;
using System.TestLibraries.Utilities;
using System.Upgrade;
using System.Utilities;

codeunit 136820 "DA Ext. Storage Impl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "Document Attachment" = rimd,
                  tabledata "Tenant Media" = r,
                  tabledata "DA External Storage Setup" = rimd;

    var
        Any: Codeunit Any;
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenarioMock: Codeunit "File Scenario Mock";
        Assert: Codeunit "Library Assert";
        LibraryPurchase: Codeunit "Library - Purchase";
        LibrarySales: Codeunit "Library - Sales";
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
    procedure DeleteFromInternalSucceedsAfterExternalUpload()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Delete from internal should succeed after file is uploaded externally
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

        // [THEN] Delete should succeed
        Assert.IsTrue(Result, 'Delete from internal should succeed');

        // [THEN] Document should be marked as not stored internally
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsFalse(DocumentAttachment."Stored Internally", 'Document should not be marked as stored internally');

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
    procedure DeleteFromInternalStorageSucceeds()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Delete from internal storage should succeed for externally stored docs
        Initialize();

        // [GIVEN] A document attachment with content and marked as externally stored
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment.Modify();

        // [WHEN] Delete from internal is attempted
        Result := DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment);

        // [THEN] Delete should succeed
        Assert.IsTrue(Result, 'Delete from internal should succeed');

        // [THEN] Document should be marked as not stored internally
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsFalse(DocumentAttachment."Stored Internally", 'Document should not be marked as stored internally');
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

        // [GIVEN] An attachment with content that has been copied to another document
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        SharedMediaId := DocumentAttachment."Document Reference ID".MediaId();
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);

        // [GIVEN] The original attachment is stored externally
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment.Modify();

        // [WHEN] The original is deleted from internal storage
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Delete from internal should succeed');

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
    procedure DeleteFromInternalRemovesMediaWhenNotShared()
    var
        DocumentAttachment: Record "Document Attachment";
        TenantMedia: Record "Tenant Media";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        MediaId: Guid;
    begin
        // [SCENARIO] Database space is still reclaimed when the attachment is the only owner
        Initialize();

        // [GIVEN] An attachment with content that is not shared and is stored externally
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        MediaId := DocumentAttachment."Document Reference ID".MediaId();
        DocumentAttachment."Stored Externally" := true;
        DocumentAttachment.Modify();

        // [WHEN] It is deleted from internal storage
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Delete from internal should succeed');

        // [THEN] The Tenant Media is removed
        Assert.IsFalse(TenantMedia.Get(MediaId), 'Tenant Media should be deleted when no other attachment references it');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
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

    #region Shared External File Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PurchaseQuoteConversionKeepsSharedExternalFile()
    var
        PurchaseQuote: Record "Purchase Header";
        PurchaseOrder: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        OrderDocumentAttachment: Record "Document Attachment";
        PurchQuoteToOrder: Codeunit "Purch.-Quote to Order";
        QuoteNo: Code[20];
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Make Order deletes the quote, not the external file now referenced by the order.
        Initialize();
        InitializeDocumentSetup();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        LibraryPurchase.CreatePurchHeader(PurchaseQuote, PurchaseQuote."Document Type"::Quote, '');
        QuoteNo := PurchaseQuote."No.";
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.Rename(Database::"Purchase Header", QuoteNo, DocumentAttachment."Document Type"::Quote, 0, DocumentAttachment.ID);
        ExternalFilePath := DocumentAttachment."External File Path";

        PurchQuoteToOrder.Run(PurchaseQuote);
        PurchQuoteToOrder.GetPurchOrderHeader(PurchaseOrder);

        Assert.IsFalse(PurchaseQuote.Get(PurchaseQuote."Document Type"::Quote, QuoteNo), 'Make Order must delete the source quote');
        Assert.AreEqual(QuoteNo, PurchaseOrder."Quote No.", 'The order must originate from the quote');
        VerifySourceAttachmentDeleted(Database::"Purchase Header", QuoteNo);
        FindHeaderAttachment(OrderDocumentAttachment, Database::"Purchase Header", PurchaseOrder."No.");
        Assert.IsTrue(OrderDocumentAttachment."Skip Delete On Copy", 'The actual quote copy flow must protect the destination');
        VerifySharedExternalFileRetained(OrderDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SalesPostingKeepsSharedExternalFile()
    var
        SalesHeader: Record "Sales Header";
        DocumentAttachment: Record "Document Attachment";
        PostedDocumentAttachment: Record "Document Attachment";
        SourceNo: Code[20];
        PostedNo: Code[20];
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Actual sales posting copies the external-only attachment before deleting its source.
        Initialize();
        InitializeDocumentSetup();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        LibrarySales.CreateSalesInvoice(SalesHeader);
        SourceNo := SalesHeader."No.";
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.Rename(Database::"Sales Header", SourceNo, DocumentAttachment."Document Type"::Invoice, 0, DocumentAttachment.ID);
        ExternalFilePath := DocumentAttachment."External File Path";

        PostedNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::Invoice, SourceNo), 'Posting must delete the source sales invoice');
        VerifySourceAttachmentDeleted(Database::"Sales Header", SourceNo);
        FindHeaderAttachment(PostedDocumentAttachment, Database::"Sales Invoice Header", PostedNo);
        VerifySharedExternalFileRetained(PostedDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PurchasePostingKeepsSharedExternalFile()
    var
        PurchaseHeader: Record "Purchase Header";
        DocumentAttachment: Record "Document Attachment";
        PostedDocumentAttachment: Record "Document Attachment";
        SourceNo: Code[20];
        PostedNo: Code[20];
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Actual purchase posting retains the file copied onto the posted invoice.
        Initialize();
        InitializeDocumentSetup();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        LibraryPurchase.CreatePurchaseInvoice(PurchaseHeader);
        SourceNo := PurchaseHeader."No.";
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.Rename(Database::"Purchase Header", SourceNo, DocumentAttachment."Document Type"::Invoice, 0, DocumentAttachment.ID);
        ExternalFilePath := DocumentAttachment."External File Path";

        PostedNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, SourceNo), 'Posting must delete the source purchase invoice');
        VerifySourceAttachmentDeleted(Database::"Purchase Header", SourceNo);
        FindHeaderAttachment(PostedDocumentAttachment, Database::"Purch. Inv. Header", PostedNo);
        VerifySharedExternalFileRetained(PostedDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RecordDeleteKeepsSharedExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Deleting an unflagged source retains the file referenced by a protected copy.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        CopiedDocumentAttachment."Skip Delete On Copy" := true;
        CopiedDocumentAttachment.Modify(false);
        ExternalFilePath := DocumentAttachment."External File Path";

        DocumentAttachment.Delete(true);

        VerifySharedExternalFileRetained(CopiedDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure DirectDeleteDetachesSharedExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Explicit deletion removes only the selected shared reference.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        ExternalFilePath := DocumentAttachment."External File Path";

        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Shared deletion must detach successfully');

        VerifyExternalReferenceDetached(DocumentAttachment);
        VerifySharedExternalFileRetained(CopiedDocumentAttachment, ExternalFilePath);
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(CopiedDocumentAttachment), 'The final eligible reference must still be removable');
        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(), 'Final explicit deletion must clean up the file');
        VerifyExternalReferenceDetached(CopiedDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LastEligibleReferenceDeletesExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] An unflagged last reference still cleans up after the protected copy is removed.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        CopiedDocumentAttachment."Skip Delete On Copy" := true;
        CopiedDocumentAttachment.Modify(false);
        CopiedDocumentAttachment.Delete(true);
        ExternalFilePath := DocumentAttachment."External File Path";
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Removing the copy must not delete the file');

        DocumentAttachment.Delete(true);

        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(), 'The final eligible reference must delete its file');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SourceDeletionDoesNotTransferOwnershipToCopy()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // [SCENARIO] Removing the source must not promote a protected copy into a deletion owner.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        CopiedDocumentAttachment."Skip Delete On Copy" := true;
        CopiedDocumentAttachment.Modify(false);

        DocumentAttachment.Delete(true);
        RefreshAttachment(CopiedDocumentAttachment);
        Assert.IsTrue(CopiedDocumentAttachment."Skip Delete On Copy", 'Copy policy must not change');
        Assert.IsFalse(DAExternalStorageImpl.DeleteFromExternalStorage(CopiedDocumentAttachment), 'Explicit deletion must still respect the copy policy');
        CopiedDocumentAttachment.Delete(true);

        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Even the last protected copy must retain the file');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ForeignExternalReferenceIsDetachedWithoutDeletion()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // [SCENARIO] Explicit deletion of a foreign reference never deletes the owning environment's file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment."Source Environment Hash" := 'FOREIGN';
        DocumentAttachment.Modify(false);

        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'The foreign reference must detach');

        VerifyExternalReferenceDetached(DocumentAttachment);
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Foreign files must never be physically deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SharedDeletionDoesNotDependOnReadback()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // [SCENARIO] Failed retrieval is not permission to delete a shared file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        FileConnectorMock.SetFailOnGetFile(true);

        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Detaching a shared reference needs no readback');

        VerifyExternalReferenceDetached(DocumentAttachment);
        RefreshAttachment(CopiedDocumentAttachment);
        Assert.IsTrue(CopiedDocumentAttachment."Stored Externally", 'The other reference must remain');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'A retrieval failure must not cause physical deletion');
        Assert.AreEqual(0, FileConnectorMock.GetFileExistsCallCount(), 'Shared deletion must not probe external storage');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure RecordDeleteWithoutTriggersKeepsExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Delete(false) keeps the existing automatic-deletion guard.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);

        DocumentAttachment.Delete(false);

        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Trigger-disabled deletion must not delete an external file');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TemporaryRecordDeletionKeepsExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
        TempDocumentAttachment: Record "Document Attachment" temporary;
    begin
        // [SCENARIO] Deleting a temporary row cannot delete a persistent attachment's file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        TempDocumentAttachment.TransferFields(DocumentAttachment);
        TempDocumentAttachment.Insert(false);

        TempDocumentAttachment.Delete(true);

        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Temporary rows must never cause physical deletion');
    end;

    #endregion

    #region External Path Identity Tests

    [Test]
    procedure ExternalPathHashTracksInsertAndModifyWithoutTriggers()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalHash: Text[64];
    begin
        // [SCENARIO] Trigger-disabled writes maintain and repair the compact identity.
        Initialize();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        RefreshAttachment(DocumentAttachment);
        OriginalHash := DocumentAttachment."External File Path Hash";
        Assert.AreEqual(64, StrLen(OriginalHash), 'The digest must contain the complete SHA256 hash');
        Assert.AreEqual(DAExternalStorageImpl.GetExternalFilePathHash(DocumentAttachment."External File Path"), OriginalHash, 'Insert(false) must derive the hash');
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        Assert.AreEqual(OriginalHash, CopiedDocumentAttachment."External File Path Hash", 'TransferFields and Insert(false) must maintain identity');

        DocumentAttachment."External File Path" := 'changed/path/file.txt';
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        Assert.AreNotEqual(OriginalHash, DocumentAttachment."External File Path Hash", 'Changing the path must change the hash');
        Assert.AreEqual(DAExternalStorageImpl.GetExternalFilePathHash(DocumentAttachment."External File Path"),
            DocumentAttachment."External File Path Hash", 'Modify(false) must derive the new hash');

        SetLegacyExternalPathHash(DocumentAttachment, '');
        DocumentAttachment."File Name" := 'ChangedName';
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual(DAExternalStorageImpl.GetExternalFilePathHash(DocumentAttachment."External File Path"),
            DocumentAttachment."External File Path Hash", 'An unrelated modification must repair a legacy blank hash');

        DocumentAttachment."External File Path" := '';
        DocumentAttachment.Modify(false);
        Assert.AreEqual('', DocumentAttachment."External File Path Hash", 'Clearing the path must clear its hash');
        CopiedDocumentAttachment."Stored Externally" := false;
        CopiedDocumentAttachment.Modify(false);
        Assert.AreEqual('', CopiedDocumentAttachment."External File Path Hash", 'Internal-only rows must not retain an external hash');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure UploadAndDetachMaintainPathHash()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalHash: Text[64];
    begin
        // [SCENARIO] Upload and detach maintain identity; failed migration leaves file and identity intact.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        OriginalHash := DocumentAttachment."External File Path Hash";
        Assert.AreEqual(DAExternalStorageImpl.GetExternalFilePathHash(DocumentAttachment."External File Path"), OriginalHash, 'Upload must persist the hash');
        FileConnectorMock.SetFailOnGetFile(true);

        Assert.IsFalse(DAExternalStorageImpl.MigrateFileToCurrentEnvironment(DocumentAttachment), 'Migration must fail when retrieval fails');
        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual(OriginalHash, DocumentAttachment."External File Path Hash", 'Failed migration must preserve identity');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Failed retrieval must not cause physical deletion');
        FileConnectorMock.SetFailOnGetFile(false);
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Final deletion must succeed');
        VerifyExternalReferenceDetached(DocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LongSharedExternalPathIsRetained()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text[2048];
    begin
        // [SCENARIO] Maximum-length paths are protected without a wide SQL index.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        ExternalFilePath := PadStr('long/path/', MaxStrLen(ExternalFilePath), 'x');
        DocumentAttachment."External File Path" := ExternalFilePath;
        DocumentAttachment.Modify(false);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        Assert.AreEqual(2048, StrLen(ExternalFilePath), 'Exercise the full path length');

        DocumentAttachment.Delete(true);

        VerifySharedExternalFileRetained(CopiedDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LongPathsWithDifferentSuffixesAreNotShared()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text[2048];
    begin
        // [SCENARIO] Paths differing only at their final character identify different files.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        ExternalFilePath := PadStr('long/path/', MaxStrLen(ExternalFilePath) - 1, 'x') + 'a';
        DocumentAttachment."External File Path" := ExternalFilePath;
        DocumentAttachment.Modify(false);
        CreateCopyOfDocumentAttachment(DocumentAttachment, OtherDocumentAttachment);
        OtherDocumentAttachment."External File Path" := CopyStr(ExternalFilePath, 1, 2047) + 'b';
        OtherDocumentAttachment.Modify(false);
        Assert.AreNotEqual(DocumentAttachment."External File Path Hash", OtherDocumentAttachment."External File Path Hash", 'Hash the complete path, not a prefix');

        DocumentAttachment.Delete(true);

        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(), 'A different long path must not prevent cleanup');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure InternalOnlyReferenceDoesNotPreventExternalDeletion()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] An internal-only row with stale path metadata is not an external reference.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, OtherDocumentAttachment);
        OtherDocumentAttachment."Stored Externally" := false;
        OtherDocumentAttachment.Modify(false);
        ExternalFilePath := DocumentAttachment."External File Path";

        DocumentAttachment.Delete(true);

        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(), 'Internal-only rows must not prevent cleanup');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LegacySharedReferencePreventsRecordDeletion()
    var
        DocumentAttachment: Record "Document Attachment";
        LegacyDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Blank-hash legacy references protect the file before upgrade.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, LegacyDocumentAttachment);
        SetLegacyExternalPathHash(LegacyDocumentAttachment, '');
        ExternalFilePath := DocumentAttachment."External File Path";

        DocumentAttachment.Delete(true);

        VerifySharedExternalFileRetained(LegacyDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LegacySharedReferencePreventsDirectDeletion()
    var
        DocumentAttachment: Record "Document Attachment";
        LegacyDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Explicit deletion also protects a blank-hash legacy reference.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, LegacyDocumentAttachment);
        SetLegacyExternalPathHash(LegacyDocumentAttachment, '');
        ExternalFilePath := DocumentAttachment."External File Path";

        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Shared deletion must detach successfully');

        VerifyExternalReferenceDetached(DocumentAttachment);
        VerifySharedExternalFileRetained(LegacyDocumentAttachment, ExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure HashMatchStillRequiresFullPathMatch()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Simulated digest collisions do not establish shared identity.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, OtherDocumentAttachment);
        OtherDocumentAttachment."External File Path" := 'different/path/file.txt';
        OtherDocumentAttachment.Modify(false);
        SetLegacyExternalPathHash(OtherDocumentAttachment, DocumentAttachment."External File Path Hash");
        ExternalFilePath := DocumentAttachment."External File Path";

        DocumentAttachment.Delete(true);

        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(), 'Full-path confirmation must reject a digest collision');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LegacyPathCaseDifferenceIsNotShared()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] A case-distinct legacy path does not refer to the same file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, OtherDocumentAttachment);
        OtherDocumentAttachment."External File Path" := UpperCase(DocumentAttachment."External File Path");
        OtherDocumentAttachment.Modify(false);
        SetLegacyExternalPathHash(OtherDocumentAttachment, '');
        ExternalFilePath := DocumentAttachment."External File Path";

        DocumentAttachment.Delete(true);

        Assert.AreEqual(ExternalFilePath, FileConnectorMock.GetLastDeletedPath(), 'Legacy path identity must remain case-sensitive');
    end;

    [Test]
    procedure ExternalPathHashUpgradeIsScopedAndIdempotent()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        InternalDocumentAttachment: Record "Document Attachment";
        EmptyPathDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        DAExternalStorageUpgrade: Codeunit "DA External Storage Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        UpgradeTags: List of [Code[250]];
        ModifiedAt: DateTime;
    begin
        // [SCENARIO] Per-company backfill visits all legacy external paths and runs only once.
        Initialize();
        if UpgradeTag.HasUpgradeTag(DAExternalStorageUpgrade.GetExternalFilePathHashUpgradeTag()) then
            UpgradeTagLibrary.DeleteUpgradeTag(DAExternalStorageUpgrade.GetExternalFilePathHashUpgradeTag(), CompanyName());
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        SetLegacyExternalPathHash(DocumentAttachment, '');
        CreateCopyOfDocumentAttachment(DocumentAttachment, OtherDocumentAttachment);
        SetLegacyExternalPathHash(OtherDocumentAttachment, '');
        CreateCopyOfDocumentAttachment(DocumentAttachment, InternalDocumentAttachment);
        InternalDocumentAttachment."Stored Externally" := false;
        InternalDocumentAttachment.Modify(false);
        CreateCopyOfDocumentAttachment(DocumentAttachment, EmptyPathDocumentAttachment);
        EmptyPathDocumentAttachment."External File Path" := '';
        EmptyPathDocumentAttachment.Modify(false);
        ModifiedAt := InternalDocumentAttachment.SystemModifiedAt;

        DAExternalStorageUpgrade.UpgradeExternalFilePathHashes();

        RefreshAttachment(DocumentAttachment);
        RefreshAttachment(OtherDocumentAttachment);
        RefreshAttachment(InternalDocumentAttachment);
        RefreshAttachment(EmptyPathDocumentAttachment);
        Assert.AreEqual(DAExternalStorageImpl.GetExternalFilePathHash(DocumentAttachment."External File Path"),
            DocumentAttachment."External File Path Hash", 'Backfill the first legacy path');
        Assert.AreEqual(DocumentAttachment."External File Path Hash", OtherDocumentAttachment."External File Path Hash", 'Backfill all rows while the index changes');
        Assert.AreEqual('', InternalDocumentAttachment."External File Path Hash", 'Internal-only rows must stay unindexed');
        Assert.AreEqual(ModifiedAt, InternalDocumentAttachment.SystemModifiedAt, 'Do not modify internal-only rows');
        Assert.AreEqual('', EmptyPathDocumentAttachment."External File Path Hash", 'Empty paths must stay unindexed');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(DAExternalStorageUpgrade.GetExternalFilePathHashUpgradeTag()), 'Record the company upgrade tag');
        UpgradeTag.GetPerCompanyUpgradeTags(UpgradeTags);
        Assert.IsTrue(UpgradeTags.Contains(DAExternalStorageUpgrade.GetExternalFilePathHashUpgradeTag()), 'Register the tag for new companies');

        SetLegacyExternalPathHash(DocumentAttachment, '');
        ModifiedAt := DocumentAttachment.SystemModifiedAt;
        DAExternalStorageUpgrade.UpgradeExternalFilePathHashes();
        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual('', DocumentAttachment."External File Path Hash", 'A completed company upgrade must not rerun the backfill');
        Assert.AreEqual(ModifiedAt, DocumentAttachment.SystemModifiedAt, 'A completed upgrade must not modify rows again');
    end;

    #endregion

    #region Helper Functions

    local procedure InitializeDocumentSetup()
    var
        PurchasesPayablesSetup: Record "Purchases & Payables Setup";
        SalesReceivablesSetup: Record "Sales & Receivables Setup";
        LibraryERMCountryData: Codeunit "Library - ERM Country Data";
        LibraryUtility: Codeunit "Library - Utility";
    begin
        LibraryERMCountryData.CreateVATData();
        LibraryERMCountryData.UpdateGeneralPostingSetup();
        LibraryERMCountryData.UpdateGeneralLedgerSetup();
        LibraryERMCountryData.UpdatePurchasesPayablesSetup();
        LibraryERMCountryData.UpdateSalesReceivablesSetup();
        LibraryPurchase.SetQuoteNoSeriesInSetup();
        LibraryPurchase.SetOrderNoSeriesInSetup();
        LibraryPurchase.SetPostedNoSeriesInSetup();
        LibrarySales.SetPostedNoSeriesInSetup();
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Purchases & Payables Setup", PurchasesPayablesSetup.FieldNo("Invoice Nos."));
        LibraryUtility.UpdateSetupNoSeriesCode(Database::"Sales & Receivables Setup", SalesReceivablesSetup.FieldNo("Invoice Nos."));
    end;

    local procedure CreateUploadedExternalOnlyAttachment(var DocumentAttachment: Record "Document Attachment")
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload must succeed');
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'The attachment must become external-only');
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Skip Delete On Copy", 'The source must be eligible for deletion');
    end;

    local procedure VerifySourceAttachmentDeleted(TableId: Integer; SourceNo: Code[20])
    var
        DocumentAttachment: Record "Document Attachment";
    begin
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", SourceNo);
        Assert.IsTrue(DocumentAttachment.IsEmpty(), 'The actual document flow must delete the source attachment');
    end;

    local procedure FindHeaderAttachment(var DocumentAttachment: Record "Document Attachment"; TableId: Integer; DocumentNo: Code[20])
    begin
        DocumentAttachment.SetRange("Table ID", TableId);
        DocumentAttachment.SetRange("No.", DocumentNo);
        Assert.AreEqual(1, DocumentAttachment.Count(), 'The destination must have exactly one copied attachment');
        DocumentAttachment.FindFirst();
    end;

    local procedure VerifySharedExternalFileRetained(var DocumentAttachment: Record "Document Attachment"; ExternalFilePath: Text)
    var
        ExternalFileStorage: Codeunit "External File Storage";
        AttachmentInStream: InStream;
    begin
        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'The remaining attachment must stay external');
        Assert.AreEqual(ExternalFilePath, DocumentAttachment."External File Path", 'The shared path must remain unchanged');
        Assert.IsFalse(DocumentAttachment."Document Reference ID".HasValue(), 'Internal media must not mask external file loss');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Do not delete a file while another attachment references it');
        Assert.IsTrue(DocumentAttachment.HasContent(), 'The remaining attachment must report content');
        ExternalFileStorage.Initialize(Enum::"File Scenario"::"Doc. Attach. - External Storage");
        Assert.IsTrue(ExternalFileStorage.GetFile(ExternalFilePath, AttachmentInStream), 'The remaining path must be readable through the mock connector');
    end;

    local procedure VerifyExternalReferenceDetached(var DocumentAttachment: Record "Document Attachment")
    begin
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'The selected attachment must be detached');
        Assert.AreEqual('', DocumentAttachment."External File Path", 'Clear the selected path');
        Assert.AreEqual('', DocumentAttachment."External File Path Hash", 'Clear the selected hash');
        Assert.AreEqual(0DT, DocumentAttachment."External Upload Date", 'Clear the selected upload date');
    end;

    local procedure SetLegacyExternalPathHash(var DocumentAttachment: Record "Document Attachment"; PathHash: Text[64])
    var
        LegacyDocumentAttachment: Record "Document Attachment";
    begin
        LegacyDocumentAttachment.GetBySystemId(DocumentAttachment.SystemId);
        LegacyDocumentAttachment.SetRecFilter();
        LegacyDocumentAttachment.ModifyAll("External File Path Hash", PathHash, false);
        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual(PathHash, DocumentAttachment."External File Path Hash", 'Persist the legacy or collision fixture without modify events');
    end;

    local procedure Initialize()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DocumentAttachment: Record "Document Attachment";
    begin
        // Clean up test data
        DocumentAttachment.DeleteAll();
        if DAExternalStorageSetup.Get() then
            DAExternalStorageSetup.Delete();

        // Clean up file scenario mappings using mock
        FileScenarioMock.DeleteAllMappings();

        // Initialize file connector mock
        FileConnectorMock.Initialize();
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
        DocumentAttachment.Insert(false);
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
