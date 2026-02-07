// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.History;

codeunit 148202 "Unit Tests - Table Extensions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDocument: Codeunit "Library - E-Document";
        IsInitialized: Boolean;

    // AvalaraSalesHeader.TableExt Tests

    [Test]
    procedure TestAvalaraSalesHeader_AvalaraDocumentId_CanBeSet()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Avalara Document ID can be set on E-Document

        // [GIVEN] An E-Document record
        Initialize();
        CreateMockEDocument(EDocument);

        // [WHEN] Setting Avalara Document ID
        EDocument."Avalara Document Id" := 'AVALARA-DOC-12345';
        EDocument.Modify();

        // [THEN] Document ID should be stored
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual('AVALARA-DOC-12345', EDocument."Avalara Document Id", 'Document ID should match');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure TestAvalaraEdoc_DocumentIdPersists()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Avalara Document ID persists through modifications

        // [GIVEN] An E-Document with Avalara Document ID
        Initialize();
        CreateMockEDocument(EDocument);
        EDocument."Avalara Document Id" := 'DOC-PERSIST-001';
        EDocument.Modify();

        // [WHEN] Modifying other fields
        EDocument.Status := EDocument.Status::Sent;
        EDocument.Modify();

        // [THEN] Document ID should still be present
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual('DOC-PERSIST-001', EDocument."Avalara Document Id",
            'Document ID should persist through modifications');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure TestAvalaraEdoc_EmptyDocumentId_Allowed()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] E-Document can exist without Avalara Document ID

        // [GIVEN] An E-Document
        Initialize();
        CreateMockEDocument(EDocument);

        // [WHEN] Document ID is not set
        // [THEN] Should be empty
        Assert.AreEqual('', EDocument."Avalara Document Id", 'Document ID can be empty');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure TestAvalaraEdoc_MultipleDocuments_UniqueIds()
    var
        EDocument1, EDocument2 : Record "E-Document";
    begin
        // [SCENARIO] Multiple E-Documents can have different Avalara Document IDs

        // [GIVEN] Two E-Documents
        Initialize();
        CreateMockEDocument(EDocument1);
        CreateMockEDocument(EDocument2);

        // [WHEN] Setting different document IDs
        EDocument1."Avalara Document Id" := 'DOC-001';
        EDocument1.Modify();
        EDocument2."Avalara Document Id" := 'DOC-002';
        EDocument2.Modify();

        // [THEN] Each should have its own ID
        EDocument1.Get(EDocument1."Entry No");
        EDocument2.Get(EDocument2."Entry No");
        Assert.AreEqual('DOC-001', EDocument1."Avalara Document Id", 'First document ID should match');
        Assert.AreEqual('DOC-002', EDocument2."Avalara Document Id", 'Second document ID should match');
        Assert.AreNotEqual(EDocument1."Avalara Document Id", EDocument2."Avalara Document Id",
            'Document IDs should be unique');

        // Cleanup
        EDocument1.Delete();
        EDocument2.Delete();
    end;

    [Test]
    procedure TestAvalaraEdoc_LongDocumentId_Truncated()
    var
        EDocument: Record "E-Document";
        MaxLength: Integer;
        LongDocumentId: Text;
    begin
        // [SCENARIO] Very long document IDs are truncated to field length

        // [GIVEN] An E-Document and a very long document ID
        Initialize();
        CreateMockEDocument(EDocument);
        MaxLength := MaxStrLen(EDocument."Avalara Document Id");
        LongDocumentId := PadStr('', MaxLength + 50, 'A');  // Longer than field length

        // [WHEN] Setting the long document ID
        EDocument."Avalara Document Id" := CopyStr(LongDocumentId, 1, MaxLength);
        EDocument.Modify();

        // [THEN] Should be truncated to max length
        EDocument.Get(EDocument."Entry No");
        Assert.AreEqual(MaxLength, StrLen(EDocument."Avalara Document Id"),
            'Document ID should be truncated to max length');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure TestAvalaraEdoc_FilterByDocumentId()
    var
        EDocument1, EDocument2, EDocument3 : Record "E-Document";
        FilteredDocuments: Record "E-Document";
    begin
        // [SCENARIO] E-Documents can be filtered by Avalara Document ID

        // [GIVEN] Multiple E-Documents, some with document IDs
        Initialize();
        CreateMockEDocument(EDocument1);
        EDocument1."Avalara Document Id" := 'FILTER-DOC-001';
        EDocument1.Modify();

        CreateMockEDocument(EDocument2);
        EDocument2."Avalara Document Id" := 'FILTER-DOC-002';
        EDocument2.Modify();

        CreateMockEDocument(EDocument3);
        // EDocument3 has no Avalara Document ID

        // [WHEN] Filtering for documents with IDs
        FilteredDocuments.SetFilter("Avalara Document Id", '<>%1', '');

        // [THEN] Should find only documents with IDs
        FilteredDocuments.SetRange("Entry No", EDocument1."Entry No");
        Assert.IsTrue(FilteredDocuments.FindFirst(), 'Should find document 1');

        FilteredDocuments.SetRange("Entry No", EDocument2."Entry No");
        Assert.IsTrue(FilteredDocuments.FindFirst(), 'Should find document 2');

        FilteredDocuments.SetRange("Entry No", EDocument3."Entry No");
        Assert.IsFalse(FilteredDocuments.FindFirst(), 'Should not find document 3 without ID');

        // Cleanup
        EDocument1.Delete();
        EDocument2.Delete();
        EDocument3.Delete();
    end;

    [Test]
    procedure TestAvalaraEdoc_SpecialCharacters_InDocumentId()
    var
        EDocument: Record "E-Document";
        SpecialDocId: Text;
    begin
        // [SCENARIO] Document IDs with special characters are handled correctly

        // [GIVEN] An E-Document
        Initialize();
        CreateMockEDocument(EDocument);
        SpecialDocId := 'DOC-2026/02/04-TEST_001';

        // [WHEN] Setting document ID with special characters
        EDocument."Avalara Document Id" := CopyStr(SpecialDocId, 1, MaxStrLen(EDocument."Avalara Document Id"));
        EDocument.Modify();

        // [THEN] Special characters should be preserved
        EDocument.Get(EDocument."Entry No");
        Assert.IsTrue(StrPos(EDocument."Avalara Document Id", '/') > 0,
            'Forward slash should be preserved');
        Assert.IsTrue(StrPos(EDocument."Avalara Document Id", '_') > 0,
            'Underscore should be preserved');

        // Cleanup
        EDocument.Delete();
    end;

    [Test]
    procedure TestConnectionSetup_SendModeExtension()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup Avalara Send Mode extension works

        // [GIVEN] A connection setup
        Initialize();
        CreateConnectionSetup(ConnectionSetup);

        // [WHEN] Setting send mode through extension
        ConnectionSetup."Avalara Send Mode" := ConnectionSetup."Avalara Send Mode"::Test;
        ConnectionSetup.Modify();

        // [THEN] Send mode should be set correctly
        ConnectionSetup.Get();
        Assert.IsTrue(ConnectionSetup."Avalara Send Mode" = ConnectionSetup."Avalara Send Mode"::Test,
            'Send mode should be Test');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateMockEDocument(var EDocument: Record "E-Document")
    begin
        EDocument.Init();
        EDocument."Entry No" := 0;  // Auto-assigned
        EDocument.Insert(true);
        EDocument.Status := EDocument.Status::"In Progress";
        EDocument.Modify();
    end;

    local procedure CreateConnectionSetup(var ConnectionSetup: Record "Connection Setup")
    begin
        if ConnectionSetup.Get() then
            ConnectionSetup.Delete();

        ConnectionSetup.Init();
        ConnectionSetup.Insert(true);
        ConnectionSetup."Client Id" := 'test-client';
        ConnectionSetup.SetClientSecret('test-secret');
        ConnectionSetup."Environment Url" := 'https://test.avalara.com';
        ConnectionSetup.Modify();
    end;
}
