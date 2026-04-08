// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;

codeunit 133624 "Unit Tests"
{
    Permissions = tabledata "Activation Header" = rimd,
                  tabledata "Activation Mandate" = rimd,
                  tabledata "Connection Setup" = rimd,
                  tabledata "E-Document" = r,
                  tabledata "Message Event" = rimd,
                  tabledata "Message Response Header" = rimd;
    Subtype = Test;
    TestType = UnitTest;

    // ========================================================================
    // LoadStatusFromJson / Message Response Header Tests
    // ========================================================================

    [Test]
    procedure LoadStatusFromJson_CompleteResponse_CreatesHeaderAndEvents()
    var
        EDocument: Record "E-Document";
        MessageEvent: Record "Message Event";
        MessageResponseHeader: Record "Message Response Header";
        AvalaraProcessing: Codeunit Processing;
        ResponseJson: Text;
    begin
        // [SCENARIO] LoadStatusFromJson with a complete response should create header and event records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean message tables
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        // [GIVEN] A mock E-Document
        EDocument.Init();
        EDocument."Entry No" := 99999;
        EDocument."Document No." := 'INV-TEST-001';

        // [GIVEN] A complete JSON response
        ResponseJson :=
            '{"id":"52f60401-44d0-4667-ad47-4afe519abb53",' +
            '"companyId":"610f55f3-76b6-42eb-a697-2b0b2e02a5bf",' +
            '"status":"Complete",' +
            '"events":[' +
            '{"eventDateTime":"2024-08-16T12:14:06.653Z","message":"Document started processing"},' +
            '{"eventDateTime":"2024-08-16T12:14:12.435Z","message":"The document was delivered","responseKey":"Receipt Message ID","responseValue":"f9681599-test"}' +
            ']}';

        // [WHEN] LoadStatusFromJson is called
        AvalaraProcessing.LoadStatusFromJson(ResponseJson, EDocument);

        // [THEN] Message Response Header is created
        Assert.IsTrue(MessageResponseHeader.Get('52f60401-44d0-4667-ad47-4afe519abb53'), 'Message Response Header should be created');
        Assert.AreEqual('610f55f3-76b6-42eb-a697-2b0b2e02a5bf', MessageResponseHeader.CompanyId, 'CompanyId should match');
        Assert.AreEqual('Complete', MessageResponseHeader.Status, 'Status should be Complete');

        // [THEN] Two events are created
        MessageEvent.SetRange(Id, '52f60401-44d0-4667-ad47-4afe519abb53');
        Assert.AreEqual(2, MessageEvent.Count(), 'Should have 2 events');

        // [THEN] First event has correct data
        MessageEvent.Get('52f60401-44d0-4667-ad47-4afe519abb53', 1);
        Assert.AreEqual('Document started processing', MessageEvent.Message, 'First event message should match');
        Assert.AreEqual('INV-TEST-001', MessageEvent.PostedDocument, 'PostedDocument should match');
        Assert.AreEqual(99999, MessageEvent.EDocEntryNo, 'EDocEntryNo should match');

        // [THEN] Second event has response key/value
        MessageEvent.Get('52f60401-44d0-4667-ad47-4afe519abb53', 2);
        Assert.AreEqual('The document was delivered', MessageEvent.Message, 'Second event message should match');
        Assert.AreEqual('Receipt Message ID', MessageEvent.ResponseKey, 'ResponseKey should match');
        Assert.AreEqual('f9681599-test', MessageEvent.ResponseValue, 'ResponseValue should match');

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();
    end;

    [Test]
    procedure LoadStatusFromJson_ErrorResponse_CreatesHeaderAndErrorEvents()
    var
        EDocument: Record "E-Document";
        MessageEvent: Record "Message Event";
        MessageResponseHeader: Record "Message Response Header";
        AvalaraProcessing: Codeunit Processing;
        ResponseJson: Text;
    begin
        // [SCENARIO] LoadStatusFromJson with error response should create header and error events
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean message tables
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        // [GIVEN] A mock E-Document
        EDocument.Init();
        EDocument."Entry No" := 99998;
        EDocument."Document No." := 'INV-TEST-002';

        // [GIVEN] An error JSON response
        ResponseJson :=
            '{"id":"err-doc-001",' +
            '"companyId":"610f55f3-76b6-42eb-a697-2b0b2e02a5bf",' +
            '"status":"Error",' +
            '"events":[' +
            '{"eventDateTime":"2024-08-16T12:14:06.653Z","message":"Document started processing"},' +
            '{"eventDateTime":"2024-08-16T12:14:12.435Z","message":"Validation failed: missing buyer reference"}' +
            ']}';

        // [WHEN] LoadStatusFromJson is called
        AvalaraProcessing.LoadStatusFromJson(ResponseJson, EDocument);

        // [THEN] Message Response Header is created with Error status
        Assert.IsTrue(MessageResponseHeader.Get('err-doc-001'), 'Message Response Header should be created');
        Assert.AreEqual('Error', MessageResponseHeader.Status, 'Status should be Error');

        // [THEN] Both error events are created
        MessageEvent.SetRange(Id, 'err-doc-001');
        Assert.AreEqual(2, MessageEvent.Count(), 'Should have 2 error events');

        MessageEvent.Get('err-doc-001', 2);
        Assert.AreEqual('Validation failed: missing buyer reference', MessageEvent.Message, 'Error message should match');

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();
    end;

    [Test]
    procedure LoadStatusFromJson_NoEvents_CreatesHeaderOnly()
    var
        EDocument: Record "E-Document";
        MessageEvent: Record "Message Event";
        MessageResponseHeader: Record "Message Response Header";
        AvalaraProcessing: Codeunit Processing;
        ResponseJson: Text;
    begin
        // [SCENARIO] LoadStatusFromJson with no events array should create header but no events
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean message tables
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        // [GIVEN] A mock E-Document
        EDocument.Init();
        EDocument."Entry No" := 99997;
        EDocument."Document No." := 'INV-TEST-003';

        // [GIVEN] A JSON response with no events array
        ResponseJson :=
            '{"id":"no-events-001",' +
            '"companyId":"610f55f3-76b6-42eb-a697-2b0b2e02a5bf",' +
            '"status":"Pending"}';

        // [WHEN] LoadStatusFromJson is called
        AvalaraProcessing.LoadStatusFromJson(ResponseJson, EDocument);

        // [THEN] Message Response Header is created
        Assert.IsTrue(MessageResponseHeader.Get('no-events-001'), 'Message Response Header should be created');
        Assert.AreEqual('Pending', MessageResponseHeader.Status, 'Status should be Pending');

        // [THEN] No events are created
        MessageEvent.SetRange(Id, 'no-events-001');
        Assert.AreEqual(0, MessageEvent.Count(), 'Should have no events');

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();
    end;

    [Test]
    procedure LoadStatusFromJson_InvalidJson_RaisesError()
    var
        EDocument: Record "E-Document";
        AvalaraProcessing: Codeunit Processing;
    begin
        // [SCENARIO] LoadStatusFromJson with invalid JSON should raise error
        LibraryPermission.SetOutsideO365Scope();

        EDocument.Init();
        EDocument."Entry No" := 99990;

        // [WHEN] LoadStatusFromJson is called with invalid JSON
        asserterror AvalaraProcessing.LoadStatusFromJson('not valid json', EDocument);

        // [THEN] Error is raised about invalid JSON
        Assert.ExpectedError('Invalid JSON response.');
    end;

    [Test]
    procedure LoadStatusFromJson_MissingId_RaisesError()
    var
        EDocument: Record "E-Document";
        AvalaraProcessing: Codeunit Processing;
    begin
        // [SCENARIO] LoadStatusFromJson with JSON missing "id" field should raise error
        LibraryPermission.SetOutsideO365Scope();

        EDocument.Init();
        EDocument."Entry No" := 99989;

        // [WHEN] LoadStatusFromJson is called with JSON that has no id
        asserterror AvalaraProcessing.LoadStatusFromJson('{"status":"Complete","companyId":"test"}', EDocument);

        // [THEN] Error is raised about missing id
        Assert.ExpectedError('Missing "id" in response.');
    end;

    [Test]
    procedure LoadStatusFromJson_EmptyId_RaisesError()
    var
        EDocument: Record "E-Document";
        AvalaraProcessing: Codeunit Processing;
    begin
        // [SCENARIO] LoadStatusFromJson with empty "id" value should raise error
        LibraryPermission.SetOutsideO365Scope();

        EDocument.Init();
        EDocument."Entry No" := 99988;

        // [WHEN] LoadStatusFromJson is called with empty id value
        asserterror AvalaraProcessing.LoadStatusFromJson('{"id":"","status":"Complete"}', EDocument);

        // [THEN] Error is raised about missing id
        Assert.ExpectedError('Missing "id" in response.');
    end;

    [Test]
    procedure LoadStatusFromJson_DuplicateCall_NoDuplicate()
    var
        EDocument: Record "E-Document";
        MessageEvent: Record "Message Event";
        MessageResponseHeader: Record "Message Response Header";
        AvalaraProcessing: Codeunit Processing;
        ResponseJson: Text;
    begin
        // [SCENARIO] Calling LoadStatusFromJson twice with same data should not create duplicate records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean message tables
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        // [GIVEN] A mock E-Document
        EDocument.Init();
        EDocument."Entry No" := 99987;
        EDocument."Document No." := 'INV-DUP-TEST';

        // [GIVEN] A JSON response
        ResponseJson :=
            '{"id":"dup-test-001",' +
            '"companyId":"comp-test",' +
            '"status":"Complete",' +
            '"events":[' +
            '{"eventDateTime":"2024-08-16T12:00:00.000Z","message":"Processing started"}' +
            ']}';

        // [WHEN] LoadStatusFromJson is called twice
        AvalaraProcessing.LoadStatusFromJson(ResponseJson, EDocument);
        AvalaraProcessing.LoadStatusFromJson(ResponseJson, EDocument);

        // [THEN] Only one header exists
        MessageResponseHeader.SetRange(Id, 'dup-test-001');
        Assert.AreEqual(1, MessageResponseHeader.Count(), 'Should have exactly 1 header after duplicate call');

        // [THEN] Only one event exists (not duplicated)
        MessageEvent.SetRange(Id, 'dup-test-001');
        Assert.AreEqual(1, MessageEvent.Count(), 'Should have exactly 1 event after duplicate call');

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();
    end;

    [Test]
    procedure LoadStatusFromJson_EventDateTime_IsParsed()
    var
        EDocument: Record "E-Document";
        MessageEvent: Record "Message Event";
        MessageResponseHeader: Record "Message Response Header";
        AvalaraProcessing: Codeunit Processing;
        ResponseJson: Text;
    begin
        // [SCENARIO] LoadStatusFromJson should parse ISO 8601 eventDateTime values
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clean message tables
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        EDocument.Init();
        EDocument."Entry No" := 99986;
        EDocument."Document No." := 'INV-DT-TEST';

        // [GIVEN] JSON with ISO 8601 datetime including fractional seconds and UTC marker
        ResponseJson :=
            '{"id":"dt-test-001",' +
            '"companyId":"comp-test",' +
            '"status":"Complete",' +
            '"events":[' +
            '{"eventDateTime":"2024-08-16T12:14:06.653Z","message":"Test event"}' +
            ']}';

        // [WHEN] LoadStatusFromJson is called
        AvalaraProcessing.LoadStatusFromJson(ResponseJson, EDocument);

        // [THEN] Event DateTime is parsed (non-zero)
        MessageEvent.Get('dt-test-001', 1);
        Assert.AreNotEqual(0DT, MessageEvent.EventDateTime, 'EventDateTime should be parsed from ISO 8601 string');

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();
    end;

    // ========================================================================
    // Activation Codeunit JSON Parsing Tests
    // ========================================================================

    [Test]
    procedure Activation_PopulateFromJson_CreatesHeadersAndMandates()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        ActivationCU: Codeunit Activation;
        ActivationJson: Text;
    begin
        // [SCENARIO] Activation.PopulateFromJson should parse activation data and create header + mandate records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] No existing activation data (avoids Confirm prompt in ClearExistingData)
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        // [GIVEN] Connection setup with a company ID
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'comp-001';
        ConnectionSetup.Modify();

        // [GIVEN] Activation JSON response
        ActivationJson :=
            '{"value":[{' +
            '"id":"a0a0a0a0-b1b1-c2c2-d3d3-e4e4e4e4e4e4",' +
            '"registrationType":"Full",' +
            '"registrationData":{"jurisdiction":"GB","schemeId":"VAT","identifier":"GB777777771","fullAuthorityNetworkValue":"PEPPOL"},' +
            '"status":{"code":"Completed","message":"Activation completed successfully"},' +
            '"company":{"displayName":"Test Company","location":"GB","identifier":"comp-001"},' +
            '"meta":{"lastModified":"2024-08-16T12:00:00Z","location":"/activations/a0a0a0a0"},' +
            '"mandates":[' +
            '{"countryMandate":"GB-B2B-PEPPOL","countryCode":"GB","mandateType":"B2B"},' +
            '{"countryMandate":"GB-B2G-PEPPOL","countryCode":"GB","mandateType":"B2G"}' +
            ']}]}';

        // [WHEN] PopulateFromJson is called
        ActivationCU.PopulateFromJson(ActivationJson);

        // [THEN] Activation Header is created
        ActivationHeader.FindFirst();
        Assert.AreEqual('comp-001', ActivationHeader."Company Id", 'Company Id should match');
        Assert.AreEqual('Full', ActivationHeader."Registration Type", 'Registration type should be Full');
        Assert.AreEqual('GB', ActivationHeader.Jurisdiction, 'Jurisdiction should be GB');
        Assert.AreEqual('Completed', ActivationHeader."Status Code", 'Status code should be Completed');
        Assert.IsTrue(ActivationHeader."Is Active ID", 'Should be active since Company Id matches');

        // [THEN] Two mandates are created
        ActivationMandate.Reset();
        ActivationMandate.SetRange("Company Id", 'comp-001');
        Assert.AreEqual(2, ActivationMandate.Count(), 'Should have 2 mandates');

        // [THEN] B2B mandate is activated (because header status is Completed)
        ActivationMandate.SetRange("Country Mandate", 'GB-B2B-PEPPOL');
        ActivationMandate.FindFirst();
        Assert.AreEqual('GB', Format(ActivationMandate."Country Code"), 'Country code should be GB');
        Assert.AreEqual('B2B', Format(ActivationMandate."Mandate Type"), 'Mandate type should be B2B');
        Assert.IsTrue(ActivationMandate.Activated, 'Mandate should be activated when header status is Completed');

        // [THEN] B2G mandate is also activated
        ActivationMandate.SetRange("Country Mandate", 'GB-B2G-PEPPOL');
        ActivationMandate.FindFirst();
        Assert.AreEqual('B2G', Format(ActivationMandate."Mandate Type"), 'Mandate type should be B2G');
        Assert.IsTrue(ActivationMandate.Activated, 'B2G mandate should be activated');

        // [CLEANUP]
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();
    end;

    [Test]
    procedure Activation_EmptyJsonText_RaisesError()
    var
        ActivationCU: Codeunit Activation;
    begin
        // [SCENARIO] PopulateFromJson with empty text should raise error
        LibraryPermission.SetOutsideO365Scope();

        // [WHEN] PopulateFromJson is called with empty string
        asserterror ActivationCU.PopulateFromJson('');

        // [THEN] Error about invalid JSON is raised
        Assert.ExpectedError('The provided JSON is invalid or malformed.');
    end;

    [Test]
    procedure Activation_MissingValueArray_RaisesError()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ActivationCU: Codeunit Activation;
    begin
        // [SCENARIO] PopulateFromJson with JSON missing "value" array should raise error
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] No existing activation data (avoids Confirm prompt in ClearExistingData)
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        // [WHEN] PopulateFromJson is called with JSON missing value array
        asserterror ActivationCU.PopulateFromJson('{"data":"something"}');

        // [THEN] Error about missing value array is raised
        Assert.ExpectedError('The JSON response is missing the required "value" array.');
    end;

    [Test]
    procedure Activation_StatusNotCompleted_MandatesNotActivated()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        ActivationCU: Codeunit Activation;
        ActivationJson: Text;
    begin
        // [SCENARIO] Activation with status != Completed should create mandates with Activated = false
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Clear existing data so ClearExistingData won't require Confirm
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        // [GIVEN] Connection setup with company ID
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'pending-comp';
        ConnectionSetup.Modify();

        // [GIVEN] Activation JSON with Pending status (not Completed)
        ActivationJson :=
            '{"value":[{' +
            '"id":"b1b1b1b1-c2c2-d3d3-e4e4-f5f5f5f5f5f5",' +
            '"registrationType":"Full",' +
            '"registrationData":{"jurisdiction":"DE","schemeId":"VAT","identifier":"DE123456789","fullAuthorityNetworkValue":"PEPPOL"},' +
            '"status":{"code":"Pending","message":"Awaiting verification"},' +
            '"company":{"displayName":"Pending Company","location":"DE","identifier":"pending-comp"},' +
            '"meta":{"lastModified":"2024-08-16T12:00:00Z","location":"/activations/b1b1b1b1"},' +
            '"mandates":[' +
            '{"countryMandate":"DE-B2B-PEPPOL","countryCode":"DE","mandateType":"B2B"}' +
            ']}]}';

        // [WHEN] PopulateFromJson is called
        ActivationCU.PopulateFromJson(ActivationJson);

        // [THEN] Activation Header is created with Pending status
        ActivationHeader.FindFirst();
        Assert.AreEqual('Pending', ActivationHeader."Status Code", 'Status code should be Pending');

        // [THEN] Mandate exists but is NOT activated (status is not Completed)
        ActivationMandate.SetRange("Country Mandate", 'DE-B2B-PEPPOL');
        ActivationMandate.FindFirst();
        Assert.IsFalse(ActivationMandate.Activated, 'Mandate should NOT be activated when status is Pending');

        // [CLEANUP]
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();
    end;

    // ========================================================================
    // AvalaraDocumentManagement Parse Tests
    // ========================================================================

    [Test]
    procedure DocumentManagement_ParseIntoTemp_PopulatesBuffer()
    var
        TempDocBuffer: Record "Avalara Document Buffer" temporary;
        DocMgt: Codeunit "Avalara Document Management";
        DocJson: Text;
    begin
        // [SCENARIO] ParseIntoTemp should correctly populate temporary document buffer from API JSON
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A JSON document list response
        DocJson :=
            '{"@nextLink":null,"value":[{' +
            '"id":"doc-001",' +
            '"companyId":"comp-001",' +
            '"processDateTime":"2024-08-16T12:00:00.000Z",' +
            '"status":"Complete",' +
            '"documentNumber":"INV-001",' +
            '"documentType":"ubl-invoice",' +
            '"documentVersion":"2.1",' +
            '"documentDate":"2024-04-08",' +
            '"flow":"in",' +
            '"countryCode":"GB",' +
            '"countryMandate":"GB-B2B-PEPPOL",' +
            '"receiver":"9932:GB777777771",' +
            '"supplierName":"CRONUS UK Ltd.",' +
            '"customerName":"Adatum Corporation",' +
            '"interface":"PEPPOL"' +
            '},{' +
            '"id":"doc-002",' +
            '"companyId":"comp-001",' +
            '"processDateTime":"2024-08-17T14:30:00.000Z",' +
            '"status":"Complete",' +
            '"documentNumber":"INV-002",' +
            '"documentType":"ubl-invoice",' +
            '"documentVersion":"2.1",' +
            '"documentDate":"2024-04-09",' +
            '"flow":"in",' +
            '"countryCode":"GB",' +
            '"countryMandate":"GB-B2B-PEPPOL",' +
            '"receiver":"9932:GB777777771",' +
            '"supplierName":"Test Supplier",' +
            '"customerName":"Test Customer",' +
            '"interface":"PEPPOL"' +
            '}]}';

        // [WHEN] ParseIntoTemp is called
        DocMgt.ParseIntoTemp(TempDocBuffer, DocJson);

        // [THEN] Two documents are created in the buffer
        Assert.AreEqual(2, TempDocBuffer.Count(), 'Should have 2 documents in buffer');

        // [THEN] First document has correct fields
        TempDocBuffer.FindFirst();
        Assert.AreEqual('doc-001', TempDocBuffer.Id, 'First document Id should be doc-001');
        Assert.AreEqual('comp-001', TempDocBuffer."Company Id", 'Company Id should match');
        Assert.AreEqual('Complete', TempDocBuffer.Status, 'Status should be Complete');
        Assert.AreEqual('INV-001', TempDocBuffer."Document Number", 'Document Number should match');
        Assert.AreEqual('ubl-invoice', TempDocBuffer."Document Type", 'Document Type should match');
        Assert.AreEqual('in', TempDocBuffer.Flow, 'Flow should be in');
        Assert.AreEqual('GB', Format(TempDocBuffer."Country Code"), 'Country Code should be GB');
        Assert.AreEqual('GB-B2B-PEPPOL', Format(TempDocBuffer."Country Mandate"), 'Country Mandate should match');
        Assert.AreEqual('CRONUS UK Ltd.', TempDocBuffer."Supplier Name", 'Supplier Name should match');
        Assert.AreEqual('Adatum Corporation', TempDocBuffer."Customer Name", 'Customer Name should match');
        Assert.AreEqual('PEPPOL', TempDocBuffer.Interface, 'Interface should be PEPPOL');
    end;

    [Test]
    procedure DocumentManagement_ParseIntoTemp_EmptyJson()
    var
        TempDocBuffer: Record "Avalara Document Buffer" temporary;
        DocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ParseIntoTemp with empty string should produce no records and no error
        LibraryPermission.SetOutsideO365Scope();

        // [WHEN] ParseIntoTemp is called with empty text
        DocMgt.ParseIntoTemp(TempDocBuffer, '');

        // [THEN] No records created
        Assert.AreEqual(0, TempDocBuffer.Count(), 'Should have 0 documents for empty input');
    end;

    [Test]
    procedure DocumentManagement_ParseIntoTemp_EmptyValueArray()
    var
        TempDocBuffer: Record "Avalara Document Buffer" temporary;
        DocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ParseIntoTemp with empty value array should produce no records
        LibraryPermission.SetOutsideO365Scope();

        // [WHEN] ParseIntoTemp is called with empty value array
        DocMgt.ParseIntoTemp(TempDocBuffer, '{"@nextLink":null,"value":[]}');

        // [THEN] No records created
        Assert.AreEqual(0, TempDocBuffer.Count(), 'Should have 0 documents for empty value array');
    end;

    [Test]
    procedure DocumentManagement_MalformedJson_RaisesError()
    var
        TempDocBuffer: Record "Avalara Document Buffer" temporary;
        DocMgt: Codeunit "Avalara Document Management";
    begin
        // [SCENARIO] ParseIntoTemp with malformed (non-empty) JSON should raise error
        LibraryPermission.SetOutsideO365Scope();

        // [WHEN] ParseIntoTemp is called with malformed JSON
        asserterror DocMgt.ParseIntoTemp(TempDocBuffer, 'not valid json');

        // [THEN] Error about invalid JSON is raised
        Assert.ExpectedError('The provided JSON is invalid or malformed.');
    end;

    // ========================================================================
    // GetMandateTypeFromName Tests
    // ========================================================================

    [Test]
    procedure MandateType_B2B_Detected()
    var
        AvalaraProcessing: Codeunit Processing;
    begin
        // [SCENARIO] GetMandateTypeFromName should detect B2B mandate type
        Assert.AreEqual('B2B', AvalaraProcessing.GetMandateTypeFromName('GB-B2B-PEPPOL'), 'Should detect B2B');
        Assert.AreEqual('B2B', AvalaraProcessing.GetMandateTypeFromName('AU-B2B'), 'Should detect B2B without suffix');
    end;

    [Test]
    procedure MandateType_B2G_Detected()
    var
        AvalaraProcessing: Codeunit Processing;
    begin
        // [SCENARIO] GetMandateTypeFromName should detect B2G mandate type
        Assert.AreEqual('B2G', AvalaraProcessing.GetMandateTypeFromName('IT-B2G-SDI'), 'Should detect B2G');
        Assert.AreEqual('B2G', AvalaraProcessing.GetMandateTypeFromName('FR-B2G'), 'Should detect B2G without suffix');
    end;

    [Test]
    procedure MandateType_NoMatch_ReturnsEmpty()
    var
        AvalaraProcessing: Codeunit Processing;
    begin
        // [SCENARIO] GetMandateTypeFromName with no B2B/B2G should return empty
        Assert.AreEqual('', AvalaraProcessing.GetMandateTypeFromName('GB-Test-Mandate'), 'Should return empty for no match');
        Assert.AreEqual('', AvalaraProcessing.GetMandateTypeFromName(''), 'Should return empty for empty input');
    end;

    // ========================================================================
    // FormatDateTime Tests
    // ========================================================================

    [Test]
    procedure FormatDateTime_ProducesIso8601Format()
    var
        AvalaraProcessing: Codeunit Processing;
        InputDate: Date;
        FormattedResult: Text;
    begin
        // [SCENARIO] FormatDateTime should produce ISO 8601 formatted datetime string
        InputDate := DMY2Date(15, 3, 2024);

        // [WHEN] FormatDateTime is called
        FormattedResult := AvalaraProcessing.FormatDateTime(InputDate);

        // [THEN] Result starts with the correct date portion
        Assert.IsTrue(FormattedResult.StartsWith('2024-03-15T'), 'Should start with correct date in ISO 8601 format');
        Assert.IsTrue(StrLen(FormattedResult) >= 19, 'Should be at least 19 characters (YYYY-MM-DDTHH:MM:SS)');
    end;

    // ========================================================================
    // ActivationMandate.SetBlocked Tests
    // ========================================================================

    [Test]
    procedure ActivationMandate_SetBlocked_BlocksCorrectMandates()
    var
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] SetBlocked should block mandates matching company and country mandate
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup with company ID
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'block-test-comp';
        ConnectionSetup.Modify();

        // [GIVEN] Mandate records
        ActivationMandate.DeleteAll();

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-B2B-PEPPOL';
        ActivationMandate."Mandate Type" := 'B2B';
        ActivationMandate."Company Id" := 'block-test-comp';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := false;
        ActivationMandate.Insert(true);

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-B2G-PEPPOL';
        ActivationMandate."Mandate Type" := 'B2G';
        ActivationMandate."Company Id" := 'block-test-comp';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := false;
        ActivationMandate.Insert(true);

        // [WHEN] SetBlocked is called for B2B mandate
        ActivationMandate.SetBlocked(ConnectionSetup, 'GB-B2B-PEPPOL', true);

        // [THEN] B2B mandate is blocked
        ActivationMandate.Reset();
        ActivationMandate.SetRange("Country Mandate", 'GB-B2B-PEPPOL');
        ActivationMandate.SetRange("Company Id", 'block-test-comp');
        ActivationMandate.FindFirst();
        Assert.IsTrue(ActivationMandate.Blocked, 'B2B mandate should be blocked');

        // [THEN] B2G mandate is NOT blocked
        ActivationMandate.Reset();
        ActivationMandate.SetRange("Country Mandate", 'GB-B2G-PEPPOL');
        ActivationMandate.SetRange("Company Id", 'block-test-comp');
        ActivationMandate.FindFirst();
        Assert.IsFalse(ActivationMandate.Blocked, 'B2G mandate should NOT be blocked');

        // [CLEANUP]
        ActivationMandate.DeleteAll();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();
    end;

    [Test]
    procedure ActivationMandate_SetBlocked_CanUnblock()
    var
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] SetBlocked(false) should unblock a previously blocked mandate
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup with company ID
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'unblock-comp';
        ConnectionSetup.Modify();

        // [GIVEN] A blocked mandate
        ActivationMandate.DeleteAll();
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := CreateGuid();
        ActivationMandate."Country Mandate" := 'GB-B2B-PEPPOL';
        ActivationMandate."Mandate Type" := 'B2B';
        ActivationMandate."Company Id" := 'unblock-comp';
        ActivationMandate.Blocked := true;
        ActivationMandate.Insert(true);

        // [WHEN] SetBlocked is called with false
        ActivationMandate.SetBlocked(ConnectionSetup, 'GB-B2B-PEPPOL', false);

        // [THEN] Mandate is now unblocked
        ActivationMandate.Reset();
        ActivationMandate.SetRange("Country Mandate", 'GB-B2B-PEPPOL');
        ActivationMandate.FindFirst();
        Assert.IsFalse(ActivationMandate.Blocked, 'Mandate should be unblocked after SetBlocked(false)');

        // [CLEANUP]
        ActivationMandate.DeleteAll();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();
    end;

    // ========================================================================
    // ConnectionSetup Tests
    // ========================================================================

    [Test]
    procedure ConnectionSetup_CreateRecord_SetsDefaultUrls()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraAuth: Codeunit Authenticator;
    begin
        // [SCENARIO] CreateConnectionSetupRecord should set default API and authentication URLs
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] No connection setup exists
        ConnectionSetup.DeleteAll();

        // [WHEN] CreateConnectionSetupRecord is called
        AvalaraAuth.CreateConnectionSetupRecord();

        // [THEN] Connection setup exists with expected URLs
        Assert.IsTrue(ConnectionSetup.Get(), 'Connection Setup should exist');
        Assert.AreEqual('https://identity.avalara.com', ConnectionSetup."Authentication URL", 'Authentication URL should match');
        Assert.AreEqual('https://api.avalara.com', ConnectionSetup."API URL", 'API URL should match');
        Assert.AreEqual('https://ai-sbx.avlr.sh', ConnectionSetup."Sandbox Authentication URL", 'Sandbox Auth URL should match');
        Assert.AreEqual('https://api.sbx.avalara.com', ConnectionSetup."Sandbox API URL", 'Sandbox API URL should match');
    end;

    [Test]
    procedure ConnectionSetup_CreateRecord_DoesNotOverwrite()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraAuth: Codeunit Authenticator;
    begin
        // [SCENARIO] CreateConnectionSetupRecord should not overwrite an existing record
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup already exists with company ID
        ConnectionSetup.DeleteAll();
        AvalaraAuth.CreateConnectionSetupRecord();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'existing-company';
        ConnectionSetup.Modify();

        // [WHEN] CreateConnectionSetupRecord is called again
        AvalaraAuth.CreateConnectionSetupRecord();

        // [THEN] Existing record is not overwritten
        ConnectionSetup.Get();
        Assert.AreEqual('existing-company', ConnectionSetup."Company Id", 'Existing Company Id should be preserved');

        // [CLEANUP]
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();
    end;

    // ========================================================================
    // Authenticator Tests
    // ========================================================================

    [Test]
    procedure Authenticator_IsClientCredsSet_ReturnsTrueWhenSet()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
        SecretValue: SecretText;
        ClientId: Text;
        ClientSecret: Text;
    begin
        // [SCENARIO] IsClientCredsSet should return true with masked values when credentials are configured
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup with valid client credentials
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        SecretValue := SecretText.SecretStrSubstNo('1590fa93-f12c-446c-8e41-c86d082fe3e0');
        AvalaraAuth.SetClientId(KeyGuid, SecretValue);
        ConnectionSetup."Client Id - Key" := KeyGuid;
        SecretValue := SecretText.SecretStrSubstNo('1590fa93-f12c-446c-8e41-c86d082fe3e0');
        AvalaraAuth.SetClientSecret(KeyGuid, SecretValue);
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup.Modify(true);

        // [WHEN] IsClientCredsSet is called
        // [THEN] Returns true
        Assert.IsTrue(AvalaraAuth.IsClientCredsSet(ClientId, ClientSecret), 'Should return true when credentials are set');

        // [THEN] Values are masked with '*'
        Assert.AreEqual('*', ClientId, 'Client Id should be masked');
        Assert.AreEqual('*', ClientSecret, 'Client Secret should be masked');
    end;

    // ========================================================================
    // Helpers
    // ========================================================================

    local procedure EnsureConnectionSetup()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraAuth: Codeunit Authenticator;
    begin
        if not ConnectionSetup.Get() then
            AvalaraAuth.CreateConnectionSetupRecord();
    end;

    [ConfirmHandler]
    procedure ConfirmYesHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := true;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermission: Codeunit "Library - Lower Permissions";
}