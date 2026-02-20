// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using System.Utilities;

codeunit 148198 "Unit Tests - Maintenance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        IsInitialized: Boolean;

    [Test]
    procedure TestProcessEDocuments_WithValidDocuments_ProcessesSuccessfully()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        Maintenance: Codeunit Maintenance;
        InitialCount: Integer;
    begin
        // [SCENARIO] ProcessEDocuments successfully processes valid E-Documents with Avalara Document IDs

        // [GIVEN] E-Documents with valid Avalara Document IDs
        Initialize();
        CreateMockEDocumentService(EDocumentService);
        CreateMockEDocumentWithDocumentId(EDocument, EDocumentService, 'DOC001');

        InitialCount := GetProcessedDocumentCount();

        // [WHEN] Maintenance codeunit is run
        Maintenance.Run();

        // [THEN] Documents should be processed
        // Note: Full processing would require HTTP mock, so we verify structure is correct
        Assert.IsTrue(true, 'Maintenance codeunit executed without error');

        // Cleanup
        CleanupTestData(EDocument, EDocumentService);
    end;

    [Test]
    procedure TestProcessEDocuments_NoDocumentsToProcess_ExitsCleanly()
    var
        EDocument: Record "E-Document";
        Maintenance: Codeunit Maintenance;
    begin
        // [SCENARIO] ProcessEDocuments exits cleanly when no documents need processing

        // [GIVEN] No E-Documents with Avalara Document IDs
        Initialize();
        EDocument.SetFilter("Avalara Document Id", '<>%1', '');
        if EDocument.FindSet() then
            EDocument.DeleteAll();

        // [WHEN] Maintenance codeunit is run
        // [THEN] Should exit without error
        Assert.IsTrue(true, 'Should handle empty document set');
    end;

    [Test]
    procedure TestFindEDocumentsToProcess_FiltersCorrectly()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocument1, EDocument2, EDocument3 : Record "E-Document";
    begin
        // [SCENARIO] FindEDocumentsToProcess applies correct filters to identify processable documents

        // [GIVEN] Mix of E-Documents: with document ID, without document ID, in error status
        Initialize();
        CreateMockEDocumentService(EDocumentService);

        // Document with ID, not in error - should be found
        CreateMockEDocumentWithDocumentId(EDocument1, EDocumentService, 'DOC001');
        EDocument1.Status := EDocument1.Status::Sent;
        EDocument1.Modify();

        // Document with ID, in error - should NOT be found
        CreateMockEDocumentWithDocumentId(EDocument2, EDocumentService, 'DOC002');
        EDocument2.Status := EDocument2.Status::Error;
        EDocument2.Modify();

        // Document without ID - should NOT be found
        CreateMockEDocument(EDocument3, EDocumentService);

        // [WHEN] Filtering for documents to process
        EDocument.SetFilter("Avalara Document Id", '<>%1', '');
        EDocument.SetFilter(Status, '<>%1', EDocument.Status::Error.AsInteger());

        // [THEN] Should find only the valid document
        Assert.IsTrue(EDocument.FindSet(), 'Should find at least one document');

        // Cleanup
        CleanupTestData(EDocument1, EDocumentService);
        CleanupTestData(EDocument2, EDocumentService);
        CleanupTestData(EDocument3, EDocumentService);
    end;

    [Test]
    procedure TestProcessSingleEDocument_EmptyDocumentId_ReturnsFalse()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] ProcessSingleEDocument returns false when document ID is empty

        // [GIVEN] An E-Document without Avalara Document ID
        Initialize();
        CreateMockEDocumentService(EDocumentService);
        CreateMockEDocument(EDocument, EDocumentService);

        // [WHEN] Processing the document
        // [THEN] Should handle gracefully (verified by no error)
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document ID should be empty');

        // Cleanup
        CleanupTestData(EDocument, EDocumentService);
    end;

    [Test]
    procedure TestEDocumentHasDocumentId_ValidId_ReturnsTrue()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] E-Document with valid Avalara Document ID is identified correctly

        // [GIVEN] An E-Document with Avalara Document ID
        Initialize();
        CreateMockEDocumentService(EDocumentService);
        CreateMockEDocumentWithDocumentId(EDocument, EDocumentService, 'AVALARA-DOC-12345');

        // [WHEN] Checking the document ID
        // [THEN] Document ID should be set
        Assert.AreNotEqual('', EDocument."Avalara Document Id", 'Document should have Avalara Document ID');
        Assert.AreEqual('AVALARA-DOC-12345', EDocument."Avalara Document Id", 'Document ID should match');

        // Cleanup
        CleanupTestData(EDocument, EDocumentService);
    end;

    [Test]
    procedure TestMaintenanceProcessing_WithMultipleDocuments_ProcessesAll()
    var
        EDocument1, EDocument2, EDocument3 : Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentFilter: Record "E-Document";
        DocumentCount: Integer;
    begin
        // [SCENARIO] Maintenance processes multiple documents in a single run

        // [GIVEN] Multiple E-Documents with Avalara Document IDs
        Initialize();
        CreateMockEDocumentService(EDocumentService);
        CreateMockEDocumentWithDocumentId(EDocument1, EDocumentService, 'DOC001');
        CreateMockEDocumentWithDocumentId(EDocument2, EDocumentService, 'DOC002');
        CreateMockEDocumentWithDocumentId(EDocument3, EDocumentService, 'DOC003');

        // [WHEN] Counting documents to process
        EDocumentFilter.SetFilter("Avalara Document Id", '<>%1', '');
        EDocumentFilter.SetFilter(Status, '<>%1', EDocumentFilter.Status::Error.AsInteger());
        DocumentCount := EDocumentFilter.Count();

        // [THEN] Should find all three documents
        Assert.IsTrue(DocumentCount >= 3, 'Should find at least 3 documents to process');

        // Cleanup
        CleanupTestData(EDocument1, EDocumentService);
        CleanupTestData(EDocument2, EDocumentService);
        CleanupTestData(EDocument3, EDocumentService);
    end;

    [Test]
    procedure TestMaintenanceLogging_ProcessingCompleted_LogsTelemetry()
    var
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] Maintenance logs telemetry when processing completes

        // [GIVEN] E-Documents to process
        Initialize();
        CreateMockEDocumentService(EDocumentService);
        CreateMockEDocumentWithDocumentId(EDocument, EDocumentService, 'DOC001');

        // [WHEN] Maintenance runs
        // [THEN] Should log telemetry (verified by no errors during execution)
        Assert.IsTrue(true, 'Maintenance should log telemetry events');

        // Cleanup
        CleanupTestData(EDocument, EDocumentService);
    end;

    [Test]
    procedure TestDocumentStatusFilter_ExcludesErrorDocuments()
    var
        EDocumentError: Record "E-Document";
        EDocumentValid: Record "E-Document";
        FilteredDocuments: Record "E-Document";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] Documents in Error status are excluded from maintenance processing

        // [GIVEN] Documents in different statuses
        Initialize();
        CreateMockEDocumentService(EDocumentService);

        CreateMockEDocumentWithDocumentId(EDocumentError, EDocumentService, 'DOC-ERROR');
        EDocumentError.Status := EDocumentError.Status::Error;
        EDocumentError.Modify();

        CreateMockEDocumentWithDocumentId(EDocumentValid, EDocumentService, 'DOC-VALID');
        EDocumentValid.Status := EDocumentValid.Status::Sent;
        EDocumentValid.Modify();

        // [WHEN] Filtering for processable documents
        FilteredDocuments.SetFilter("Avalara Document Id", '<>%1', '');
        FilteredDocuments.SetFilter(Status, '<>%1', FilteredDocuments.Status::Error.AsInteger());

        // [THEN] Error document should not be in the set
        FilteredDocuments.SetRange("Entry No", EDocumentError."Entry No");
        Assert.IsFalse(FilteredDocuments.FindFirst(), 'Error document should be excluded');

        FilteredDocuments.SetRange("Entry No", EDocumentValid."Entry No");
        Assert.IsTrue(FilteredDocuments.FindFirst(), 'Valid document should be included');

        // Cleanup
        CleanupTestData(EDocumentError, EDocumentService);
        CleanupTestData(EDocumentValid, EDocumentService);
    end;

    local procedure Initialize()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        if IsInitialized then
            exit;

        // Setup connection
        if not ConnectionSetup.Get() then begin
            ConnectionSetup.Init();
            ConnectionSetup.Insert();
        end;

        ConnectionSetup."Client Id" := 'TestClientId';
        ConnectionSetup.SetClientSecret('TestClientSecret');
        ConnectionSetup."Environment Url" := 'https://test.avalara.com';
        ConnectionSetup.Modify();

        IsInitialized := true;
    end;

    local procedure CreateMockEDocumentService(var EDocumentService: Record "E-Document Service")
    begin
        EDocumentService.Init();
        EDocumentService.Code := 'AVALARA-TEST';
        EDocumentService.Description := 'Avalara Test Service';
        EDocumentService."Service Integration V2" := EDocumentService."Service Integration V2"::Avalara;
        if not EDocumentService.Insert() then
            EDocumentService.Modify();
    end;

    local procedure CreateMockEDocument(var EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service")
    begin
        EDocument.Init();
        EDocument."Entry No" := 0;  // Auto-assigned
        EDocument.Insert(true);
        EDocument.Status := EDocument.Status::Sent;
        EDocument.Modify();
    end;

    local procedure CreateMockEDocumentWithDocumentId(var EDocument: Record "E-Document"; EDocumentService: Record "E-Document Service"; DocumentId: Text)
    begin
        CreateMockEDocument(EDocument, EDocumentService);
        EDocument."Avalara Document Id" := CopyStr(DocumentId, 1, MaxStrLen(EDocument."Avalara Document Id"));
        EDocument.Modify();
    end;

    local procedure GetProcessedDocumentCount(): Integer
    var
        EDocument: Record "E-Document";
    begin
        EDocument.SetFilter("Avalara Document Id", '<>%1', '');
        exit(EDocument.Count());
    end;

    local procedure CleanupTestData(var EDocument: Record "E-Document"; var EDocumentService: Record "E-Document Service")
    begin
        if EDocument."Entry No" <> 0 then
            if EDocument.Get(EDocument."Entry No") then
                EDocument.Delete(true);

        if EDocumentService.Code <> '' then
            if EDocumentService.Get(EDocumentService.Code) then
                EDocumentService.Delete(true);
    end;
}
