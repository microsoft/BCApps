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
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 136820 "DA Ext. Storage Impl. Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    Permissions = tabledata "Document Attachment" = rimd,
                  tabledata "Tenant Media" = rmd,
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
    procedure RetireUploadedExternalReferenceKeepsInternalContent()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalDocumentAttachment: Record "Document Attachment";
        Result: Boolean;
    begin
        // [SCENARIO] Verified local retirement removes only external metadata and keeps both local and remote bytes.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] A document that has been uploaded to external storage
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment);
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        OriginalDocumentAttachment := DocumentAttachment;

        // [WHEN] Delete is attempted
        Result := DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment);

        Assert.IsTrue(Result, 'The legacy entry point must retire a verified local reference');
        VerifyExternalReferenceRetired(DocumentAttachment, OriginalDocumentAttachment);
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
    procedure CopiedReferenceWithInternalContentCanRetireLocally()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        Result: Boolean;
    begin
        // [SCENARIO] Copy protection prevents physical deletion, not safe local retirement with actual internal bytes.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();

        // [GIVEN] A document attachment with Skip Delete On Copy
        CreateExternallyStoredDocument(DocumentAttachment);
        DocumentAttachment."Skip Delete On Copy" := true;
        DocumentAttachment.Modify();

        // [WHEN] Delete is attempted
        Result := DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment);

        Assert.IsTrue(Result, 'A copied reference with confirmed internal bytes can retire locally');

        // [THEN] Document should still be marked as externally stored
        DocumentAttachment.SetRecFilter();
        DocumentAttachment.FindFirst();
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'Retire only local external metadata');
        Assert.IsFalse(DocumentAttachment."Skip Delete On Copy", 'Retirement must clear stale copy metadata');
        Assert.IsTrue(DocumentAttachment."Document Reference ID".HasValue(), 'Copied internal content must remain');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Copy retirement must not send a remote DELETE');
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
    procedure RecordDeleteRetainsLoneExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Even a lone external file is retained when its attachment row is deleted.
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

        Assert.IsFalse(DocumentAttachment.Find(), 'The attachment row must still be deleted');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Lone external files must also be retained');
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
        SalesLine: Record "Sales Line";
        DocumentAttachment: Record "Document Attachment";
        LineDocumentAttachment: Record "Document Attachment";
        PostedDocumentAttachment: Record "Document Attachment";
        PostedLineDocumentAttachment: Record "Document Attachment";
        SourceNo: Code[20];
        PostedNo: Code[20];
        ExternalFilePath: Text;
        LineExternalFilePath: Text;
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
        SalesLine.SetRange("Document Type", SalesHeader."Document Type");
        SalesLine.SetRange("Document No.", SourceNo);
        SalesLine.FindFirst();
        CreateUploadedExternalOnlyAttachment(LineDocumentAttachment);
        LineDocumentAttachment.Rename(Database::"Sales Line", SourceNo, LineDocumentAttachment."Document Type"::Invoice, SalesLine."Line No.", LineDocumentAttachment.ID);
        LineExternalFilePath := LineDocumentAttachment."External File Path";

        PostedNo := LibrarySales.PostSalesDocument(SalesHeader, true, true);

        Assert.IsFalse(SalesHeader.Get(SalesHeader."Document Type"::Invoice, SourceNo), 'Posting must delete the source sales invoice');
        VerifySourceAttachmentDeleted(Database::"Sales Header", SourceNo);
        VerifySourceAttachmentDeleted(Database::"Sales Line", SourceNo);
        FindHeaderAttachment(PostedDocumentAttachment, Database::"Sales Invoice Header", PostedNo);
        VerifySharedExternalFileRetained(PostedDocumentAttachment, ExternalFilePath);
        FindHeaderAttachment(PostedLineDocumentAttachment, Database::"Sales Invoice Line", PostedNo);
        VerifySharedExternalFileRetained(PostedLineDocumentAttachment, LineExternalFilePath);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure PurchasePostingKeepsSharedExternalFile()
    var
        PurchaseHeader: Record "Purchase Header";
        PurchaseLine: Record "Purchase Line";
        DocumentAttachment: Record "Document Attachment";
        LineDocumentAttachment: Record "Document Attachment";
        PostedDocumentAttachment: Record "Document Attachment";
        PostedLineDocumentAttachment: Record "Document Attachment";
        SourceNo: Code[20];
        PostedNo: Code[20];
        ExternalFilePath: Text;
        LineExternalFilePath: Text;
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
        PurchaseLine.SetRange("Document Type", PurchaseHeader."Document Type");
        PurchaseLine.SetRange("Document No.", SourceNo);
        PurchaseLine.FindFirst();
        CreateUploadedExternalOnlyAttachment(LineDocumentAttachment);
        LineDocumentAttachment.Rename(Database::"Purchase Line", SourceNo, LineDocumentAttachment."Document Type"::Invoice, PurchaseLine."Line No.", LineDocumentAttachment.ID);
        LineExternalFilePath := LineDocumentAttachment."External File Path";

        PostedNo := LibraryPurchase.PostPurchaseDocument(PurchaseHeader, true, true);

        Assert.IsFalse(PurchaseHeader.Get(PurchaseHeader."Document Type"::Invoice, SourceNo), 'Posting must delete the source purchase invoice');
        VerifySourceAttachmentDeleted(Database::"Purchase Header", SourceNo);
        VerifySourceAttachmentDeleted(Database::"Purchase Line", SourceNo);
        FindHeaderAttachment(PostedDocumentAttachment, Database::"Purch. Inv. Header", PostedNo);
        VerifySharedExternalFileRetained(PostedDocumentAttachment, ExternalFilePath);
        FindHeaderAttachment(PostedLineDocumentAttachment, Database::"Purch. Inv. Line", PostedNo);
        VerifySharedExternalFileRetained(PostedLineDocumentAttachment, LineExternalFilePath);
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
    procedure DirectDeleteRetainsSharedExternalMetadata()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalDocumentAttachment: Record "Document Attachment";
        OriginalCopiedDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Explicit deletion keeps both shared references and the external file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        ExternalFilePath := DocumentAttachment."External File Path";
        OriginalDocumentAttachment := DocumentAttachment;
        RefreshAttachment(CopiedDocumentAttachment);
        OriginalCopiedDocumentAttachment := CopiedDocumentAttachment;

        Assert.IsFalse(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Shared cleanup must be blocked');
        Assert.IsFalse(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Repeated cleanup must remain blocked');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
        VerifySharedExternalFileRetained(CopiedDocumentAttachment, ExternalFilePath);
        Assert.IsFalse(DAExternalStorageImpl.DeleteFromExternalStorage(CopiedDocumentAttachment), 'The other shared reference must also be blocked');
        VerifyExternalMetadataRetained(CopiedDocumentAttachment, OriginalCopiedDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure LastEligibleReferenceRetainsExternalFile()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] Removing the final unflagged reference still retains the external file.
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

        Assert.AreNotEqual('', ExternalFilePath, 'The test must have an external file');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'The final eligible reference must also retain its file');
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
    procedure ForeignExternalReferenceKeepsMetadata()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalDocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Explicit foreign deletion retains both file and reference metadata.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment."Source Environment Hash" := 'FOREIGN';
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;

        Assert.IsFalse(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'Foreign cleanup must be blocked');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Foreign files must never be physically deleted');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SharedDeletionDoesNotDependOnReadback()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalDocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Failed retrieval is not permission to delete a shared file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        FileConnectorMock.SetFailOnGetFile(true);

        Assert.IsFalse(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment), 'A retrieval failure must not bypass blocked cleanup');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
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

    #region External Retention Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure StaleInternalDeleteCannotRemoveLocallyRetiredContent()
    var
        DocumentAttachment: Record "Document Attachment";
        StaleDocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] A cached pre-retirement row must not delete the remaining internal bytes after retirement commits.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        StaleDocumentAttachment := DocumentAttachment;
        Assert.IsTrue(DAExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason), 'The valid reference must retire');

        Assert.IsFalse(DAExternalStorageImpl.DeleteFromInternalStorage(StaleDocumentAttachment), 'A stale release must recheck the retired current row');

        VerifyExternalReferenceRetired(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CopiedEnvironmentReferenceRetiresWithoutRemoteContact()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] Foreign/copy metadata does not prevent local retirement when actual internal bytes are present.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        DocumentAttachment."Source Environment Hash" := 'COPIEDENVIRONMENT';
        DocumentAttachment."Skip Delete On Copy" := true;
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        FileConnectorMock.SetFailOnGetFile(true);
        FileScenarioMock.DeleteAllMappings();

        Assert.IsTrue(DAExternalStorageImpl.DeleteFromExternalStorage(DocumentAttachment, FailureReason), 'Local retirement must not depend on a configured or accessible remote account');
        Assert.AreEqual('', FailureReason, 'Successful retirement must not report a failure');

        VerifyExternalReferenceRetired(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SharedInternalReferenceRetiresWithoutChangingExternalOnlyCopy()
    var
        DocumentAttachment: Record "Document Attachment";
        CopiedDocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        OriginalCopiedDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] Retiring one valid local reference must not modify another external-only reference or its remote file.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        CreateCopyOfDocumentAttachment(DocumentAttachment, CopiedDocumentAttachment);
        Clear(CopiedDocumentAttachment."Document Reference ID");
        CopiedDocumentAttachment."Stored Internally" := false;
        CopiedDocumentAttachment.Modify(false);
        RefreshAttachment(CopiedDocumentAttachment);
        OriginalCopiedDocumentAttachment := CopiedDocumentAttachment;

        Assert.IsTrue(DAExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason), 'The selected internal reference should retire');

        VerifyExternalReferenceRetired(DocumentAttachment, OriginalDocumentAttachment);
        VerifyExternalMetadataRetained(CopiedDocumentAttachment, OriginalCopiedDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MissingMediaDoesNotRetireExternalReference()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        TenantMedia: Record "Tenant Media";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] A media GUID and stored-internal flag are not proof that bytes exist.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        TenantMedia.Get(DocumentAttachment."Document Reference ID".MediaId());
        TenantMedia.Delete(false);

        Assert.IsFalse(DAExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason), 'Missing media must block local retirement');
        Assert.AreNotEqual('', FailureReason, 'Blocked retirement must explain the missing content');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure EmptyMediaDoesNotRetireExternalReference()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        TenantMedia: Record "Tenant Media";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] An existing media row with empty content is not a safe internal copy.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        TenantMedia.Get(DocumentAttachment."Document Reference ID".MediaId());
        TenantMedia.CalcFields(Content);
        Clear(TenantMedia.Content);
        TenantMedia.Modify(false);

        Assert.IsFalse(DAExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason), 'Empty media must block local retirement');
        Assert.AreNotEqual('', FailureReason, 'Blocked retirement must explain the empty content');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MissingInternalFlagDoesNotRetireEvenWithMedia()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] Present media cannot override an inconsistent stored-internal flag.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        DocumentAttachment."Stored Internally" := false;
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;

        Assert.IsFalse(DAExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason), 'Both actual content and its stored-internal flag are required');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure StaleExternalReferenceDoesNotRetireCurrentRow()
    var
        DocumentAttachment: Record "Document Attachment";
        StaleDocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] A stale selection cannot retire a different external path on the same attachment.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        StaleDocumentAttachment := DocumentAttachment;
        DocumentAttachment."External File Path" := 'changed/current/path.txt';
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;

        Assert.IsFalse(DAExternalStorageImpl.RetireExternalReference(StaleDocumentAttachment, FailureReason), 'Changed source state must block retirement');
        Assert.IsTrue(StrPos(FailureReason, 'changed') > 0, 'The refusal must explain stale state');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure TemporaryReferenceCannotRetirePersistentMetadata()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        TempDocumentAttachment: Record "Document Attachment" temporary;
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        FailureReason: Text;
    begin
        // [SCENARIO] A temporary copy must not clear the persistent source's external metadata.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        TempDocumentAttachment.TransferFields(DocumentAttachment);
        TempDocumentAttachment.Insert(false);

        Assert.IsFalse(DAExternalStorageImpl.RetireExternalReference(TempDocumentAttachment, FailureReason), 'Temporary records cannot retire persistent references');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure MissingAttachmentCannotRetireStaleReference()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalExternalPath: Text;
        FailureReason: Text;
    begin
        // [SCENARIO] An attachment already removed from the database cannot authorize local metadata mutation.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalExternalPath := DocumentAttachment."External File Path";
        DocumentAttachment.Delete(false);

        Assert.IsFalse(DAExternalStorageImpl.RetireExternalReference(DocumentAttachment, FailureReason), 'The permanent source row must still exist');
        Assert.IsTrue(StrPos(FailureReason, 'no longer exists') > 0, 'The refusal must explain the missing row');
        Assert.AreEqual(OriginalExternalPath, DocumentAttachment."External File Path", 'The stale caller snapshot must not be silently cleared');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'A missing row cannot authorize any remote DELETE');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,RetirementBlockedMessageHandler')]
    procedure RetirementPageBlocksInternalFlagWithoutActualMedia()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DocumentAttachmentExternal: TestPage "Document Attachment - External";
    begin
        // [SCENARIO] The page refuses a stored-internal flag with no media and reports that metadata was retained.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment."Stored Internally" := true;
        DocumentAttachment.Modify(false);
        RefreshAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;

        DocumentAttachmentExternal.OpenView();
        DocumentAttachmentExternal.GoToRecord(DocumentAttachment);
        DocumentAttachmentExternal."Delete from External".Invoke();
        DocumentAttachmentExternal.Close();

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,CopyToInternalRequestPageHandler,SyncCopyMessageHandler')]
    procedure CopyToInternalKeepsBothReferences()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalExternalPath: Text;
        OriginalUploadDate: DateTime;
        OriginalSourceEnvironmentHash: Text[32];
    begin
        // [SCENARIO] Copy restores internal bytes without retiring any external metadata.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        OriginalExternalPath := DocumentAttachment."External File Path";
        OriginalUploadDate := DocumentAttachment."External Upload Date";
        OriginalSourceEnvironmentHash := DocumentAttachment."Source Environment Hash";
        DocumentAttachment.SetRecFilter();

        Report.RunModal(Report::"DA External Storage Sync", true, false, DocumentAttachment);

        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'Copy must restore internal content');
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'Copy must keep the external reference');
        Assert.AreEqual(OriginalExternalPath, DocumentAttachment."External File Path", 'Copy must preserve the external path');
        Assert.AreEqual(OriginalUploadDate, DocumentAttachment."External Upload Date", 'Copy must preserve upload metadata');
        Assert.AreEqual(OriginalSourceEnvironmentHash, DocumentAttachment."Source Environment Hash", 'Copy must preserve origin metadata');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Copy must not send a remote DELETE');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,MoveToInternalRequestPageHandler,SyncRetirementMessageHandler')]
    procedure MoveWithExistingInternalContentDoesNotReadRemote()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
    begin
        // [SCENARIO] Move can retire an already valid internal copy even when its remote account is unavailable.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        FileConnectorMock.SetFailOnGetFile(true);
        FileScenarioMock.DeleteAllMappings();
        DocumentAttachment.SetRecFilter();

        Report.RunModal(Report::"DA External Storage Sync", true, false, DocumentAttachment);

        VerifyExternalReferenceRetired(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,ReferenceRetiredMessageHandler')]
    procedure RetirementPageRetiresVerifiedInternalReference()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DocumentAttachmentExternal: TestPage "Document Attachment - External";
        ExternalStorageSetup: TestPage "DA External Storage Setup";
    begin
        // [SCENARIO] The explicit action reports local reference retirement and retained remote bytes.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        UploadDocumentAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;

        ExternalStorageSetup.OpenEdit();
        Assert.IsFalse(ExternalStorageSetup."Delete from External Storage".Enabled(), 'The saved policy must not allow cleanup to be re-enabled');
        ExternalStorageSetup.Close();
        DocumentAttachmentExternal.OpenView();
        DocumentAttachmentExternal.GoToRecord(DocumentAttachment);
        Assert.IsTrue(DocumentAttachmentExternal."Delete from External".Enabled(), 'Local retirement should be offered for internally stored rows');
        DocumentAttachmentExternal."Delete from External".Invoke();
        DocumentAttachmentExternal.Close();

        VerifyExternalReferenceRetired(DocumentAttachment, OriginalDocumentAttachment);
    end;

    [Test]
    [HandlerFunctions('LifecycleConfirmHandler,MoveToInternalRequestPageHandler,SyncRetirementMessageHandler')]
    procedure MoveToInternalRetiresReferenceAndAllowsConfigurationChanges()
    var
        DocumentAttachment: Record "Document Attachment";
        ExternalStorageSetup: Record "DA External Storage Setup";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // [SCENARIO] Move restores actual bytes and locally retires the external reference, allowing lifecycle changes.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        DocumentAttachment.SetRecFilter();

        Report.RunModal(Report::"DA External Storage Sync", true, false, DocumentAttachment);

        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Document Reference ID".HasValue(), 'The external file must be restored internally');
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'Restore must succeed');
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'The local external reference must be retired');
        Assert.AreEqual('', DocumentAttachment."External File Path", 'Clear the locally retired path');
        Assert.AreEqual(0DT, DocumentAttachment."External Upload Date", 'Clear the locally retired upload date');
        Assert.AreEqual('', DocumentAttachment."Source Environment Hash", 'Clear the locally retired source environment');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Move to internal must not send a remote DELETE');
        ExternalStorageSetup.Get();
        ExternalStorageSetup.CalcFields("Has Uploaded Files");
        Assert.IsFalse(ExternalStorageSetup."Has Uploaded Files", 'Locally retired references must not block lifecycle changes');
        Assert.IsFalse(DAExternalStorageImpl.BeforeReassignFileScenarioCheck(Enum::"File Scenario"::"Doc. Attach. - External Storage"), 'Reassignment guard must no longer block');
        Assert.IsFalse(DAExternalStorageImpl.BeforeDeleteFileScenarioCheck(Enum::"File Scenario"::"Doc. Attach. - External Storage", Enum::"Ext. File Storage Connector"::"Test File Storage Connector"), 'Unassignment guard must no longer block');
        Assert.IsFalse(DAExternalStorageImpl.BeforeAddOrModifyFileScenarioCheck(Enum::"File Scenario"::"Doc. Attach. - External Storage", Enum::"Ext. File Storage Connector"::"Test File Storage Connector"), 'Account replacement guard must no longer block');
        ExternalStorageSetup.Validate(Enabled, false);
        ExternalStorageSetup.Modify();
        Assert.IsFalse(ExternalStorageSetup.Enabled, 'Feature disablement must succeed after local retirement');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure FailedMigrationPreservesExternalMetadata()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalDocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        // [SCENARIO] A failed migration cannot delete content or clear the external reference.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateUploadedExternalOnlyAttachment(DocumentAttachment);
        OriginalDocumentAttachment := DocumentAttachment;
        FileConnectorMock.SetFailOnGetFile(true);

        Assert.IsFalse(DAExternalStorageImpl.MigrateFileToCurrentEnvironment(DocumentAttachment), 'Migration must fail when retrieval fails');

        VerifyExternalMetadataRetained(DocumentAttachment, OriginalDocumentAttachment);
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
    procedure DistinctLongExternalPathsAreRetained()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text[2048];
    begin
        // [SCENARIO] Retention does not depend on matching even the last character of a long path.
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
        Assert.AreNotEqual(DocumentAttachment."External File Path", OtherDocumentAttachment."External File Path", 'The paths must differ');

        DocumentAttachment.Delete(true);

        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Distinct long paths must also be retained');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure InternalOnlyMetadataDoesNotAuthorizeExternalDeletion()
    var
        DocumentAttachment: Record "Document Attachment";
        OtherDocumentAttachment: Record "Document Attachment";
        ExternalFilePath: Text;
    begin
        // [SCENARIO] An internal-only copy must not authorize cleanup of its external source.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeatureWithDelete();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        CreateCopyOfDocumentAttachment(DocumentAttachment, OtherDocumentAttachment);
        OtherDocumentAttachment."Stored Externally" := false;
        OtherDocumentAttachment.Modify(false);
        ExternalFilePath := DocumentAttachment."External File Path";

        DocumentAttachment.Delete(true);

        Assert.AreNotEqual('', ExternalFilePath, 'The source must have an external file');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'An internal-only copy cannot enable external cleanup');
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

    local procedure VerifyExternalMetadataRetained(var DocumentAttachment: Record "Document Attachment"; OriginalDocumentAttachment: Record "Document Attachment")
    begin
        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual(OriginalDocumentAttachment."Stored Externally", DocumentAttachment."Stored Externally", 'Retain the external storage flag');
        Assert.AreEqual(OriginalDocumentAttachment."External File Path", DocumentAttachment."External File Path", 'Retain the exact external path');
        Assert.AreEqual(OriginalDocumentAttachment."External Upload Date", DocumentAttachment."External Upload Date", 'Retain the upload date');
        Assert.AreEqual(OriginalDocumentAttachment."Source Environment Hash", DocumentAttachment."Source Environment Hash", 'Retain source environment metadata');
        Assert.AreEqual(OriginalDocumentAttachment."Stored Internally", DocumentAttachment."Stored Internally", 'Do not alter internal storage');
        Assert.AreEqual(OriginalDocumentAttachment."Document Reference ID".MediaId(), DocumentAttachment."Document Reference ID".MediaId(), 'Do not alter internal media');
        Assert.AreEqual(OriginalDocumentAttachment.SystemModifiedAt, DocumentAttachment.SystemModifiedAt, 'Blocked cleanup must not modify the row');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Blocked cleanup must not send a remote DELETE');
    end;

    local procedure VerifyExternalReferenceRetired(var DocumentAttachment: Record "Document Attachment"; OriginalDocumentAttachment: Record "Document Attachment")
    var
        TenantMedia: Record "Tenant Media";
    begin
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'Retire the local external flag');
        Assert.AreEqual('', DocumentAttachment."External File Path", 'Clear the local external path');
        Assert.AreEqual(0DT, DocumentAttachment."External Upload Date", 'Clear the local upload date');
        Assert.AreEqual('', DocumentAttachment."Source Environment Hash", 'Clear local origin metadata');
        Assert.IsFalse(DocumentAttachment."Skip Delete On Copy", 'Clear stale copy metadata');
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'Internal storage must remain valid');
        Assert.AreEqual(OriginalDocumentAttachment."Document Reference ID".MediaId(), DocumentAttachment."Document Reference ID".MediaId(), 'Retirement must preserve the exact internal media reference');
        TenantMedia.Get(DocumentAttachment."Document Reference ID".MediaId());
        TenantMedia.CalcFields(Content);
        Assert.IsTrue(TenantMedia.Content.HasValue(), 'Actual internal bytes must remain');
        Assert.IsTrue(TenantMedia.Content.Length() > 0, 'Internal content must be nonempty');
        Assert.AreEqual('', FileConnectorMock.GetLastDeletedPath(), 'Local retirement must never send a remote DELETE');
    end;

    local procedure UploadDocumentAttachment(var DocumentAttachment: Record "Document Attachment")
    var
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
    begin
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload must succeed');
        RefreshAttachment(DocumentAttachment);
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

    [MessageHandler]
    procedure RetirementBlockedMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, '0 external reference(s) retired locally') > 0, 'The action must not claim a successful retirement');
        Assert.IsTrue(StrPos(Message, '1 reference(s) could not be retired') > 0, 'The action must report blocked retirement');
        Assert.IsTrue(StrPos(Message, 'nonempty internal content') > 0, 'The action must explain missing actual internal content');
    end;

    [MessageHandler]
    procedure ReferenceRetiredMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, '1 external reference(s) retired locally') > 0, 'The action must report local retirement');
        Assert.IsTrue(StrPos(Message, 'remote files were retained') > 0, 'The action must not claim remote deletion');
    end;

    [RequestPageHandler]
    procedure MoveToInternalRequestPageHandler(var ExternalStorageSync: TestRequestPage "DA External Storage Sync")
    begin
        ExternalStorageSync.SyncDirectionField.SetValue(1);
        ExternalStorageSync.OperationField.SetValue(1);
        ExternalStorageSync.MaxRecordsToProcessField.SetValue(0);
        ExternalStorageSync.OK().Invoke();
    end;

    [MessageHandler]
    procedure SyncRetirementMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'Processed 1 attachments successfully. 0 failed.') > 0, 'External retention must not be counted as a failed internal restore');
        Assert.IsTrue(StrPos(Message, 'Remote files for 1 attachment(s) were retained') > 0, 'The report must distinguish remote safety copies');
        Assert.IsTrue(StrPos(Message, '1 external reference(s) were retired locally') > 0, 'The report must distinguish local retirement');
    end;

    [RequestPageHandler]
    procedure CopyToInternalRequestPageHandler(var ExternalStorageSync: TestRequestPage "DA External Storage Sync")
    begin
        ExternalStorageSync.SyncDirectionField.SetValue(1);
        ExternalStorageSync.OperationField.SetValue(0);
        ExternalStorageSync.MaxRecordsToProcessField.SetValue(0);
        ExternalStorageSync.OK().Invoke();
    end;

    [MessageHandler]
    procedure SyncCopyMessageHandler(Message: Text[1024])
    begin
        Assert.IsTrue(StrPos(Message, 'Processed 1 attachments successfully. 0 failed.') > 0, 'Copy must succeed without retiring the external reference');
        Assert.IsTrue(StrPos(Message, 'retired') = 0, 'Copy must not report retirement');
    end;

    [ConfirmHandler]
    procedure LifecycleConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := StrPos(LowerCase(Question), 'configure external storage settings') = 0;
    end;

    #endregion
}
