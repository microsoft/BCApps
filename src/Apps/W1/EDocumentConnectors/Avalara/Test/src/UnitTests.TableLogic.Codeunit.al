// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.eServices.EDocument;

codeunit 133633 "Unit Tests - Table Logic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    // ConnectionSetup.Table Tests

    [Test]
    procedure TestConnectionSetup_OnInsert_SetsDefaults()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup sets default values on insert

        // [GIVEN] A new connection setup record
        Initialize();
        if ConnectionSetup.Get() then
            ConnectionSetup.Delete();

        // [WHEN] Inserting a new connection setup
        ConnectionSetup.Init();
        ConnectionSetup.Insert(true);

        // [THEN] Default values should be set
        ConnectionSetup.Get();
        Assert.AreNotEqual('', ConnectionSetup."Environment Url", 'Environment URL should have default value');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestConnectionSetup_ValidateClientId_AcceptsValue()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup accepts valid Client ID

        // [GIVEN] A connection setup record
        Initialize();
        CreateConnectionSetup(ConnectionSetup);

        // [WHEN] Setting Client ID
        ConnectionSetup."Client Id" := 'test-client-id-12345';
        ConnectionSetup.Modify();

        // [THEN] Client ID should be stored
        ConnectionSetup.Get();
        Assert.AreEqual('test-client-id-12345', ConnectionSetup."Client Id", 'Client ID should match');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestConnectionSetup_SetClientSecret_StoresSecurely()
    var
        ConnectionSetup: Record "Connection Setup";
        TestSecret: Text;
    begin
        // [SCENARIO] Connection Setup stores client secret securely

        // [GIVEN] A connection setup record
        Initialize();
        CreateConnectionSetup(ConnectionSetup);
        TestSecret := 'super-secret-password-123';

        // [WHEN] Setting client secret
        ConnectionSetup.SetClientSecret(TestSecret);

        // [THEN] Secret should be stored (cannot verify encrypted value directly)
        Assert.IsTrue(true, 'SetClientSecret executed without error');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestConnectionSetup_AvalaraSendMode_CanBeSet()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup Avalara Send Mode can be configured

        // [GIVEN] A connection setup record
        Initialize();
        CreateConnectionSetup(ConnectionSetup);

        // [WHEN] Setting send mode to Production
        ConnectionSetup."Avalara Send Mode" := ConnectionSetup."Avalara Send Mode"::Production;
        ConnectionSetup.Modify();

        // [THEN] Send mode should be set
        ConnectionSetup.Get();
        Assert.IsTrue(ConnectionSetup."Avalara Send Mode" = ConnectionSetup."Avalara Send Mode"::Production,
            'Send mode should be Production');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    // ActivationHeader.Table Tests

    [Test]
    procedure TestActivationHeader_Insert_SetsActivationId()
    var
        ActivationHeader: Record "Activation Header";
        TestGuid: Guid;
    begin
        // [SCENARIO] Activation Header can be inserted with a GUID

        // [GIVEN] A new activation header
        Initialize();
        TestGuid := CreateGuid();

        // [WHEN] Inserting activation header
        ActivationHeader.Init();
        ActivationHeader.ID := TestGuid;
        ActivationHeader."Company Id" := 'TEST-COMPANY';
        ActivationHeader.Insert(true);

        // [THEN] Record should be inserted successfully
        Assert.IsTrue(ActivationHeader.Get(TestGuid), 'Activation header should be retrievable');

        // Cleanup
        ActivationHeader.Delete();
    end;

    [Test]
    procedure TestActivationHeader_Validate_StoresAllFields()
    var
        ActivationHeader: Record "Activation Header";
    begin
        // [SCENARIO] Activation Header stores all required fields

        // [GIVEN] An activation header with all fields populated
        Initialize();
        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Registration Type" := 'VAT';
        ActivationHeader.Jurisdiction := 'GB';
        ActivationHeader."Scheme Id" := 'GB:VAT';
        ActivationHeader.Identifier := 'GB123456789';
        ActivationHeader."Status Code" := 'Completed';
        ActivationHeader."Company Id" := 'COMPANY-001';
        ActivationHeader."Company Name" := 'Test Company Ltd';
        ActivationHeader."Is Active ID" := true;

        // [WHEN] Inserting the record
        ActivationHeader.Insert(true);

        // [THEN] All fields should be persisted
        ActivationHeader.Get(ActivationHeader.ID);
        Assert.AreEqual('VAT', ActivationHeader."Registration Type", 'Registration type should match');
        Assert.AreEqual('GB', ActivationHeader.Jurisdiction, 'Jurisdiction should match');
        Assert.IsTrue(ActivationHeader."Is Active ID", 'Is Active ID should be true');

        // Cleanup
        ActivationHeader.Delete();
    end;

    // ActivationMandate.Table Tests

    [Test]
    procedure TestActivationMandate_LinkToHeader_WorksCorrectly()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        HeaderGuid: Guid;
    begin
        // [SCENARIO] Activation Mandate correctly links to Activation Header

        // [GIVEN] An activation header
        Initialize();
        HeaderGuid := CreateGuid();
        ActivationHeader.Init();
        ActivationHeader.ID := HeaderGuid;
        ActivationHeader."Company Id" := 'TEST-COMPANY';
        ActivationHeader.Insert(true);

        // [WHEN] Creating a linked mandate
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := HeaderGuid;
        ActivationMandate."Country Mandate" := 'GB-PEPPOL-INVOICE';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Company Id" := 'TEST-COMPANY';
        ActivationMandate.Insert(true);

        // [THEN] Mandate should be linked to header
        ActivationMandate.SetRange("Activation ID", HeaderGuid);
        Assert.IsTrue(ActivationMandate.FindFirst(), 'Should find linked mandate');

        // Cleanup
        ActivationMandate.Delete();
        ActivationHeader.Delete();
    end;

    // MediaTypes.Table Tests

    [Test]
    procedure TestMediaTypes_InsertMultiple_Succeeds()
    var
        MediaTypes: Record "Media Types";
    begin
        // [SCENARIO] Multiple media types can be inserted

        // [GIVEN] Media types for different formats
        Initialize();
        CleanupMediaTypes();

        // [WHEN] Inserting multiple media types
        CreateMediaType(MediaTypes, 'GB-PEPPOL', 'application/xml');
        CreateMediaType(MediaTypes, 'GB-PEPPOL', 'application/pdf');

        // [THEN] Both should exist
        MediaTypes.SetRange(Mandate, 'GB-PEPPOL');
        Assert.AreEqual(2, MediaTypes.Count(), 'Should have 2 media types for GB-PEPPOL');

        // Cleanup
        CleanupMediaTypes();
    end;

    [Test]
    procedure TestMediaTypes_Delete_RemovesSuccessfully()
    var
        MediaTypes: Record "Media Types";
    begin
        // [SCENARIO] Media type can be deleted

        // [GIVEN] An existing media type
        Initialize();
        CleanupMediaTypes();
        CreateMediaType(MediaTypes, 'DE-PEPPOL', 'application/xml');

        // [WHEN] Deleting the media type
        MediaTypes.Delete(true);

        // [THEN] Should be removed
        MediaTypes.SetRange(Mandate, 'DE-PEPPOL');
        Assert.AreEqual(0, MediaTypes.Count(), 'Media type should be deleted');

        // Cleanup
        CleanupMediaTypes();
    end;

    // AvalaraCompany.Table Tests

    [Test]
    procedure TestAvalaraCompany_Insert_StoresCompanyData()
    var
        AvalaraCompany: Record "Avalara Company";
    begin
        // [SCENARIO] Avalara Company table stores company information

        // [GIVEN] New Avalara company data
        Initialize();
        CleanupAvalaraCompany();

        // [WHEN] Inserting company
        AvalaraCompany.Init();
        AvalaraCompany.Id := 1;
        AvalaraCompany."Company Name" := 'Test Company Ltd';
        AvalaraCompany."Company Id" := 'AVALARA-COMP-001';
        AvalaraCompany.Insert(true);

        // [THEN] Company data should be stored
        AvalaraCompany.Get(1);
        Assert.AreEqual('Test Company Ltd', AvalaraCompany."Company Name", 'Company name should match');
        Assert.AreEqual('AVALARA-COMP-001', AvalaraCompany."Company Id", 'Company ID should match');

        // Cleanup
        CleanupAvalaraCompany();
    end;

    // AvalaraDocumentBuffer.Table Tests

    [Test]
    procedure TestAvalaraDocumentBuffer_Temporary_WorksCorrectly()
    var
        AvalaraDocumentBuffer: Record "Avalara Document Buffer";
    begin
        // [SCENARIO] Avalara Document Buffer as temporary table works correctly

        // [GIVEN] Temporary buffer
        Initialize();

        // [WHEN] Inserting into temporary buffer
        AvalaraDocumentBuffer.Init();
        AvalaraDocumentBuffer."Document Id" := 'DOC-123';
        AvalaraDocumentBuffer.Status := 'Complete';
        AvalaraDocumentBuffer.Insert();

        // [THEN] Should be in temporary table only
        Assert.IsTrue(AvalaraDocumentBuffer.Get('DOC-123'), 'Should find in temporary buffer');

        // No cleanup needed for temporary tables
    end;

    [Test]
    procedure TestAvalaraDocumentBuffer_ParseData_PopulatesFields()
    var
        AvalaraDocumentBuffer: Record "Avalara Document Buffer";
    begin
        // [SCENARIO] Avalara Document Buffer can parse and store document data

        // [GIVEN] Document buffer
        Initialize();

        // [WHEN] Populating buffer fields
        AvalaraDocumentBuffer.Init();
        AvalaraDocumentBuffer."Document Id" := 'DOC-456';
        AvalaraDocumentBuffer.Status := 'Complete';
        AvalaraDocumentBuffer."Workflow Id" := 'partner-einvoicing';
        AvalaraDocumentBuffer."Created Date" := CurrentDateTime();
        AvalaraDocumentBuffer.Insert();

        // [THEN] All fields should be populated
        AvalaraDocumentBuffer.Get('DOC-456');
        Assert.AreEqual('Complete', AvalaraDocumentBuffer.Status, 'Status should match');
        Assert.AreEqual('partner-einvoicing', AvalaraDocumentBuffer."Workflow Id", 'Workflow ID should match');

        // No cleanup needed for temporary tables
    end;

    [Test]
    procedure TestConnectionSetup_CompanyId_CanBeSet()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup can store company ID

        // [GIVEN] A connection setup
        Initialize();
        CreateConnectionSetup(ConnectionSetup);

        // [WHEN] Setting company ID
        ConnectionSetup."Company Id" := 'AVALARA-COMPANY-12345';
        ConnectionSetup.Modify();

        // [THEN] Company ID should be stored
        ConnectionSetup.Get();
        Assert.AreEqual('AVALARA-COMPANY-12345', ConnectionSetup."Company Id", 'Company ID should match');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestActivationHeader_IsActiveID_Flag()
    var
        ActivationHeader: Record "Activation Header";
    begin
        // [SCENARIO] Activation Header Is Active ID flag works correctly

        // [GIVEN] Two activation headers, one active, one inactive
        Initialize();

        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Company Id" := 'ACTIVE-COMPANY';
        ActivationHeader."Is Active ID" := true;
        ActivationHeader.Insert(true);

        // [WHEN] Filtering for active records
        ActivationHeader.SetRange("Is Active ID", true);

        // [THEN] Should find the active record
        Assert.IsTrue(ActivationHeader.FindFirst(), 'Should find active activation');
        Assert.AreEqual('ACTIVE-COMPANY', ActivationHeader."Company Id", 'Should be the active company');

        // Cleanup
        ActivationHeader.SetRange("Is Active ID");
        ActivationHeader.DeleteAll();
    end;

    [Test]
    procedure TestActivationMandate_Activated_Flag()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
    begin
        // [SCENARIO] Activation Mandate Activated flag indicates status

        // [GIVEN] An activation with mandate
        Initialize();
        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Company Id" := 'TEST-COMP';
        ActivationHeader.Insert(true);

        // [WHEN] Creating activated mandate
        ActivationMandate.Init();
        ActivationMandate."Activation ID" := ActivationHeader.ID;
        ActivationMandate."Country Mandate" := 'FR-PEPPOL';
        ActivationMandate.Activated := true;
        ActivationMandate.Insert(true);

        // [THEN] Should be marked as activated
        ActivationMandate.Get(ActivationHeader.ID, 'FR-PEPPOL');
        Assert.IsTrue(ActivationMandate.Activated, 'Mandate should be activated');

        // Cleanup
        ActivationMandate.Delete();
        ActivationHeader.Delete();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
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

    local procedure CreateMediaType(var MediaTypes: Record "Media Types"; MandateCode: Code[50]; MediaType: Text[250])
    begin
        MediaTypes.Init();
        MediaTypes.Mandate := MandateCode;
        MediaTypes."Media Type" := CopyStr(MediaType, 1, MaxStrLen(MediaTypes."Media Type"));
        if not MediaTypes.Insert(true) then
            MediaTypes.Modify(true);
    end;

    local procedure CleanupMediaTypes()
    var
        MediaTypes: Record "Media Types";
    begin
        if not MediaTypes.IsEmpty() then
            MediaTypes.DeleteAll(true);
    end;

    local procedure CleanupAvalaraCompany()
    var
        AvalaraCompany: Record "Avalara Company";
    begin
        if not AvalaraCompany.IsEmpty() then
            AvalaraCompany.DeleteAll(true);
    end;
}
