// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.ExternalStorage.DocumentAttachments.Test;

using Microsoft.ExternalStorage.DocumentAttachments;
using Microsoft.Foundation.Attachment;
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
                  tabledata "DA External Storage Setup" = rimd;

    var
        Any: Codeunit Any;
        FileConnectorMock: Codeunit "File Connector Mock";
        FileScenarioMock: Codeunit "File Scenario Mock";
        Assert: Codeunit "Library Assert";
        ExpectedSyncSummary: Text;
        SyncToInternalStorage: Boolean;
        MoveAttachments: Boolean;
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

    #region File Name Migration Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure InvalidFileNameCharactersRoundTrip()
    var
        InvalidCharacters: Text;
        InvalidCharacter: Char;
    begin
        // [SCENARIO] Invalid path characters, including a leading slash, do not change the attachment name or content.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);

        VerifyFileNameRoundTrip('Invoice Nov''25', 'pdf');
        InvalidCharacters := '"''<>/\|';
        foreach InvalidCharacter in InvalidCharacters do
            VerifyFileNameRoundTrip(Format(InvalidCharacter) + 'Invoice Nov25', 'pdf');
        VerifyFileNameRoundTrip('Invoice/Nov25', 'pdf');
        VerifyFileNameRoundTrip(InvalidCharacters, 'pdf');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure InvalidFileExtensionCharactersRoundTrip()
    var
        InvalidCharacters: Text;
        InvalidCharacter: Char;
    begin
        // [SCENARIO] Only the external path is sanitized when an extension contains invalid characters.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);

        InvalidCharacters := '"''<>/\|';
        foreach InvalidCharacter in InvalidCharacters do
            VerifyFileNameRoundTrip('Invoice Nov25', 'p' + Format(InvalidCharacter) + 'df');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure ValidFileNameRoundTrip()
    begin
        // [SCENARIO] Valid filename characters and the existing path layout remain unchanged.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);

        VerifyFileNameRoundTrip('Invoice Nov25 (final)_100%+v1', 'pdf');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure SanitizedFileNamesDoNotCollide()
    var
        FirstFilePath: Text;
        SecondFilePath: Text;
    begin
        // [SCENARIO] Names that sanitize to the same value retain distinct paths and round-trip independently.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);

        FirstFilePath := VerifyFileNameRoundTrip('Invoice Nov''25', 'pdf');
        SecondFilePath := VerifyFileNameRoundTrip('Invoice Nov25', 'pdf');

        Assert.AreNotEqual(FirstFilePath, SecondFilePath, 'Sanitized file names must not collide');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler')]
    procedure CompanyMigrationSanitizesFileName()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalContent: Text;
        OriginalPath: Text;
    begin
        // [SCENARIO] Migration to the current environment also sanitizes the new path without renaming the attachment.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        OriginalContent := GetAttachmentContent(DocumentAttachment);
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Initial upload should succeed');
        OriginalPath := DocumentAttachment."External File Path";
        DocumentAttachment."File Name" := 'Invoice Nov''25';
        DocumentAttachment."Source Environment Hash" := 'previous-environment';
        DocumentAttachment.Modify();

        Assert.IsTrue(DAExternalStorageImpl.MigrateFileToCurrentEnvironment(DocumentAttachment), 'Company migration should succeed');

        RefreshAttachment(DocumentAttachment);
        Assert.AreNotEqual(OriginalPath, DocumentAttachment."External File Path", 'Migration should create a new path');
        Assert.IsTrue(DocumentAttachment."External File Path".Contains('/Invoice Nov25-'), 'The migrated path should be sanitized');
        Assert.AreEqual('Invoice Nov''25', DocumentAttachment."File Name", 'Migration must preserve the original name');
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Internal cleanup should succeed');
        Assert.IsTrue(DAExternalStorageImpl.DownloadFromExternalStorageToInternal(DocumentAttachment), 'The migrated file should be retrievable');
        Assert.AreEqual(OriginalContent, GetAttachmentContent(DocumentAttachment), 'Migration must preserve the file content');
    end;

    #endregion

    #region Storage Sync Report Tests

    [Test]
    [HandlerFunctions('ConfirmYesHandler,StorageSyncRequestPageHandler,SyncSummaryMessageHandler')]
    procedure SyncMovesInvalidFileNameRoundTrip()
    var
        DocumentAttachment: Record "Document Attachment";
        OriginalContent: Text;
    begin
        // [SCENARIO] Storage Sync can move an attachment with an unsafe name in both directions without renaming it.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);
        CreateNamedDocumentAttachment(DocumentAttachment, '/Invoice Nov''25', 'pdf');
        OriginalContent := GetAttachmentContent(DocumentAttachment);
        MoveAttachments := true;
        ExpectedSyncSummary := 'Processed 1 attachments successfully. 0 failed.';

        Commit();
        Report.Run(Report::"DA External Storage Sync");

        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'The attachment should be stored externally');
        Assert.IsFalse(DocumentAttachment."Stored Internally", 'Move should remove the internal copy');
        Assert.AreEqual('/Invoice Nov''25', DocumentAttachment."File Name", 'Upload must preserve the original name');
        Assert.AreEqual('pdf', DocumentAttachment."File Extension", 'Upload must preserve the original extension');

        SyncToInternalStorage := true;
        Commit();
        Report.Run(Report::"DA External Storage Sync");

        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'The attachment should be restored internally');
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'Move should clear the external reference');
        Assert.AreEqual('/Invoice Nov''25', DocumentAttachment."File Name", 'Download must preserve the original name');
        Assert.AreEqual('pdf', DocumentAttachment."File Extension", 'Download must preserve the original extension');
        Assert.AreEqual(OriginalContent, GetAttachmentContent(DocumentAttachment), 'Storage Sync must preserve the file content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,StorageSyncRequestPageHandler,SyncSummaryMessageHandler')]
    procedure SyncReportsUploadFailureWithFileName()
    var
        DocumentAttachment: Record "Document Attachment";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO] A connector upload failure identifies the affected attachment and the actual error.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);
        FileConnectorMock.FailOnSend(true);
        CreateNamedDocumentAttachment(DocumentAttachment, 'Invoice Nov''25', 'pdf');
        ExpectedSyncSummary := 'Processed 0 attachments successfully. 1 failed.';
        ErrorMessages.Trap();

        Commit();
        Report.Run(Report::"DA External Storage Sync");

        Assert.IsTrue(ErrorMessages.First(), 'The failed attachment should be listed');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'Invoice Nov''25.pdf') > 0, 'The error should identify the original filename');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'Failed to create file.') > 0, 'The connector error should be reported');
        Assert.IsFalse(ErrorMessages.Next(), 'Only the failed attachment should be listed');
        ErrorMessages.Close();
        RefreshAttachment(DocumentAttachment);
        Assert.IsFalse(DocumentAttachment."Stored Externally", 'A failed upload must not mark the attachment as externally stored');
        Assert.IsTrue(DocumentAttachment."Document Reference ID".HasValue(), 'A failed upload must retain the internal content');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,StorageSyncRequestPageHandler,SyncSummaryMessageHandler')]
    procedure SyncReportsDownloadFailureWithFileName()
    var
        DocumentAttachment: Record "Document Attachment";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO] A connector download failure is reported with the attachment name rather than only a failed count.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateExternallyStoredOnlyDocument(DocumentAttachment);
        FileConnectorMock.SetFailOnGetFile(true);
        SyncToInternalStorage := true;
        ExpectedSyncSummary := 'Processed 0 attachments successfully. 1 failed.';
        ErrorMessages.Trap();

        Commit();
        Report.Run(Report::"DA External Storage Sync");

        Assert.IsTrue(ErrorMessages.First(), 'The failed attachment should be listed');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'TestFile.txt') > 0, 'The error should identify the attachment');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'Failed to get file.') > 0, 'The connector error should be reported');
        ErrorMessages.Close();
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,StorageSyncRequestPageHandler,SyncSummaryMessageHandler')]
    procedure SyncReportsAllFailedAttachments()
    var
        FirstAttachment: Record "Document Attachment";
        SecondAttachment: Record "Document Attachment";
        ErrorMessages: TestPage "Error Messages";
        ReportedErrors: Text;
        FailureCount: Integer;
    begin
        // [SCENARIO] Every failed attachment is diagnosed, even when the storage error includes customer-specific paths.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateExternallyStoredOnlyDocument(FirstAttachment);
        FirstAttachment."File Name" := 'First customer invoice';
        FirstAttachment."External File Path" := 'customer-one/Invoice Nov''25.pdf';
        FirstAttachment.Modify();
        CreateExternallyStoredOnlyDocument(SecondAttachment);
        SecondAttachment."File Name" := 'Second customer invoice';
        SecondAttachment."External File Path" := 'customer-two/Invoice Dec''25.pdf';
        SecondAttachment.Modify();
        SyncToInternalStorage := true;
        ExpectedSyncSummary := 'Processed 0 attachments successfully. 2 failed.';
        ErrorMessages.Trap();

        Commit();
        Report.Run(Report::"DA External Storage Sync");

        Assert.IsTrue(ErrorMessages.First(), 'The failed attachments should be listed');
        repeat
            FailureCount += 1;
            ReportedErrors += ErrorMessages.Description.Value;
        until not ErrorMessages.Next();
        ErrorMessages.Close();
        Assert.AreEqual(2, FailureCount, 'Each failed attachment should be diagnosed exactly once');
        Assert.IsTrue(ReportedErrors.Contains('First customer invoice.txt'), 'The first attachment should be identified to the user');
        Assert.IsTrue(ReportedErrors.Contains('Second customer invoice.txt'), 'The second attachment should be identified to the user');
        Assert.IsTrue(ReportedErrors.Contains(FirstAttachment."External File Path"), 'The user should retain the detailed first error');
        Assert.IsTrue(ReportedErrors.Contains(SecondAttachment."External File Path"), 'The user should retain the detailed second error');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,StorageSyncRequestPageHandler,SyncSummaryMessageHandler')]
    procedure SyncContinuesWithoutReusingPreviousError()
    var
        FailedAttachment: Record "Document Attachment";
        SuccessfulAttachment: Record "Document Attachment";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO] A failure without a platform error is explained, does not reuse a stale error, and does not stop other attachments.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        CreateNamedDocumentAttachment(FailedAttachment, 'Missing content', 'pdf');
        Clear(FailedAttachment."Document Reference ID");
        FailedAttachment.Modify();
        CreateDocumentAttachmentWithContent(SuccessfulAttachment);
        ExpectedSyncSummary := 'Processed 1 attachments successfully. 1 failed.';
        ErrorMessages.Trap();
        Commit();
        asserterror Error('Previous unrelated failure');

        Report.Run(Report::"DA External Storage Sync");

        Assert.IsTrue(ErrorMessages.First(), 'The failed attachment should be listed');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'Missing content.pdf') > 0, 'The error should identify the attachment');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'could not be copied') > 0, 'The failed operation should be explained');
        Assert.AreEqual(0, StrPos(ErrorMessages.Description.Value, 'Previous unrelated failure'), 'A stale error must not be reported');
        Assert.IsFalse(ErrorMessages.Next(), 'Successful attachments must not be listed as failures');
        ErrorMessages.Close();
        RefreshAttachment(SuccessfulAttachment);
        Assert.IsTrue(SuccessfulAttachment."Stored Externally", 'Other attachments should still be processed');
    end;

    [Test]
    [HandlerFunctions('ConfirmYesHandler,StorageSyncRequestPageHandler,SyncSummaryMessageHandler')]
    procedure SyncReportsMoveCleanupFailure()
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        ErrorMessages: TestPage "Error Messages";
    begin
        // [SCENARIO] A successful copy with failed source cleanup is reported without discarding either copy.
        Initialize();
        SetupFileScenarioWithTestConnector();
        EnableFeature();
        FileConnectorMock.SetStoreFileContent(true);
        CreateNamedDocumentAttachment(DocumentAttachment, 'Invoice Nov25', 'pdf');
        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload should succeed');
        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Internal cleanup should succeed');
        DAExternalStorageSetup.Get();
        DAExternalStorageSetup.Enabled := false;
        DAExternalStorageSetup.Modify();
        SyncToInternalStorage := true;
        MoveAttachments := true;
        ExpectedSyncSummary := 'Processed 0 attachments successfully. 1 failed.';
        ErrorMessages.Trap();

        Commit();
        Report.Run(Report::"DA External Storage Sync");

        Assert.IsTrue(ErrorMessages.First(), 'The failed cleanup should be listed');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'Invoice Nov25.pdf') > 0, 'The error should identify the attachment');
        Assert.IsTrue(StrPos(ErrorMessages.Description.Value, 'copied, but could not be removed') > 0, 'The cleanup failure should be explained');
        ErrorMessages.Close();
        RefreshAttachment(DocumentAttachment);
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'The restored content should be retained');
        Assert.IsTrue(DocumentAttachment."Stored Externally", 'The external reference should be retained when cleanup fails');
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

    #region Helper Functions

    local procedure Initialize()
    var
        DAExternalStorageSetup: Record "DA External Storage Setup";
        DocumentAttachment: Record "Document Attachment";
    begin
        Clear(ExpectedSyncSummary);
        Clear(SyncToInternalStorage);
        Clear(MoveAttachments);

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

    local procedure CreateNamedDocumentAttachment(var DocumentAttachment: Record "Document Attachment"; FileName: Text; FileExtension: Text)
    begin
        CreateDocumentAttachmentWithContent(DocumentAttachment);
        DocumentAttachment."File Name" := CopyStr(FileName, 1, MaxStrLen(DocumentAttachment."File Name"));
        DocumentAttachment."File Extension" := CopyStr(FileExtension, 1, MaxStrLen(DocumentAttachment."File Extension"));
        DocumentAttachment.Modify();
    end;

    local procedure GetAttachmentContent(DocumentAttachment: Record "Document Attachment") Content: Text
    var
        TempBlob: Codeunit "Temp Blob";
        InStream: InStream;
        OutStream: OutStream;
    begin
        TempBlob.CreateOutStream(OutStream);
        DocumentAttachment.ExportToStream(OutStream);
        TempBlob.CreateInStream(InStream, TextEncoding::UTF8);
        InStream.ReadText(Content);
    end;

    local procedure VerifyFileNameRoundTrip(FileName: Text; FileExtension: Text): Text
    var
        DocumentAttachment: Record "Document Attachment";
        DAExternalStorageImpl: Codeunit "DA External Storage Impl.";
        OriginalContent: Text;
        PathParts: List of [Text];
        FileNamePart: Text;
    begin
        CreateNamedDocumentAttachment(DocumentAttachment, FileName, FileExtension);
        OriginalContent := GetAttachmentContent(DocumentAttachment);

        Assert.IsTrue(DAExternalStorageImpl.UploadToExternalStorage(DocumentAttachment), 'Upload should succeed for ' + FileName);

        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual(FileName, DocumentAttachment."File Name", 'Upload must preserve the original filename');
        Assert.AreEqual(FileExtension, DocumentAttachment."File Extension", 'Upload must preserve the original extension');
        PathParts := DocumentAttachment."External File Path".Split('/');
        Assert.AreEqual(3, PathParts.Count(), 'A filename must not add path segments');
        Assert.AreEqual(DAExternalStorageImpl.GetCurrentEnvironmentHash(), PathParts.Get(1), 'The path must start with the environment folder');
        Assert.AreEqual('Document_Attachment', PathParts.Get(2), 'The table folder should be unchanged');
        FileNamePart := PathParts.Get(3);
        Assert.AreEqual(FileNamePart, DelChr(FileNamePart, '=', '"''<>/\|'), 'The filename must contain no invalid path characters');
        Assert.IsTrue(FileNamePart.StartsWith(DelChr(FileName, '=', '"''<>/\|') + '-'), 'The safe filename should retain the original valid characters');
        Assert.IsTrue(FileNamePart.EndsWith('.' + DelChr(FileExtension, '=', '"''<>/\|')), 'The safe extension should retain the original valid characters');

        Assert.IsTrue(DAExternalStorageImpl.DeleteFromInternalStorage(DocumentAttachment), 'Internal cleanup should succeed');
        Assert.IsFalse(DocumentAttachment."Document Reference ID".HasValue(), 'The round-trip must retrieve the external content');
        Assert.IsTrue(DAExternalStorageImpl.DownloadFromExternalStorageToInternal(DocumentAttachment), 'The attachment should be restored from its stored path');

        RefreshAttachment(DocumentAttachment);
        Assert.AreEqual(FileName, DocumentAttachment."File Name", 'Download must preserve the original filename');
        Assert.AreEqual(FileExtension, DocumentAttachment."File Extension", 'Download must preserve the original extension');
        Assert.IsTrue(DocumentAttachment."Stored Internally", 'The attachment should be restored internally');
        Assert.AreEqual(OriginalContent, GetAttachmentContent(DocumentAttachment), 'The original file content should survive the round-trip');
        exit(DocumentAttachment."External File Path");
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

    [RequestPageHandler]
    procedure StorageSyncRequestPageHandler(var StorageSync: TestRequestPage "DA External Storage Sync")
    begin
        if SyncToInternalStorage then
            StorageSync.SyncDirectionField.SetValue('To Internal Storage')
        else
            StorageSync.SyncDirectionField.SetValue('To External Storage');
        if MoveAttachments then
            StorageSync.OperationField.SetValue('Move')
        else
            StorageSync.OperationField.SetValue('Copy');
        StorageSync.MaxRecordsToProcessField.SetValue(0);
        StorageSync.OK().Invoke();
    end;

    [MessageHandler]
    procedure SyncSummaryMessageHandler(Message: Text[1024])
    begin
        Assert.AreEqual(ExpectedSyncSummary, Message, 'The sync summary should count successful and failed attachments');
    end;

    #endregion
}
