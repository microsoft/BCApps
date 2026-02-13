// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

codeunit 148204 "Unit Tests - Page Logic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    procedure TestConnectionSetupCard_CanOpen()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup Card page can be opened with data

        // [GIVEN] A connection setup record
        Initialize();
        CreateConnectionSetup(ConnectionSetup);

        // [WHEN] Page would be opened (tested via record existence)
        ConnectionSetup.Get();

        // [THEN] Record should have required fields
        Assert.AreNotEqual('', ConnectionSetup."Client Id", 'Client ID should be set');
        Assert.AreNotEqual('', ConnectionSetup."Environment Url", 'Environment URL should be set');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestConnectionSetup_DefaultValues_OnInsert()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup has default values on insert

        // [GIVEN] System ready for new setup
        Initialize();
        if ConnectionSetup.Get() then
            ConnectionSetup.Delete();

        // [WHEN] Creating new connection setup
        ConnectionSetup.Init();
        ConnectionSetup.Insert(true);

        // [THEN] Should have default environment URL
        ConnectionSetup.Get();
        Assert.IsTrue(StrLen(ConnectionSetup."Environment Url") > 0,
            'Environment URL should have default value');

        // Cleanup
        ConnectionSetup.Delete();
    end;

    [Test]
    procedure TestActivationCard_DataAvailable()
    var
        ActivationHeader: Record "Activation Header";
    begin
        // [SCENARIO] Activation Card page has data to display

        // [GIVEN] An activation header record
        Initialize();
        CreateActivationHeader(ActivationHeader);

        // [WHEN] Page would open with this record
        ActivationHeader.Get(ActivationHeader.ID);

        // [THEN] Should have required data
        Assert.AreNotEqual('', ActivationHeader."Company Id", 'Company ID should be set');
        Assert.AreNotEqual('', ActivationHeader."Status Code", 'Status should be set');

        // Cleanup
        ActivationHeader.Delete();
    end;

    [Test]
    procedure TestCompanyList_CanFilter()
    var
        AvalaraCompany: Record "Avalara Company";
        Company1, Company2 : Record "Avalara Company";
    begin
        // [SCENARIO] Company List page can filter companies

        // [GIVEN] Multiple Avalara companies
        Initialize();
        CleanupCompanies();

        Company1.Init();
        Company1.Id := 1;
        Company1."Company Name" := 'Test Company 1';
        Company1."Company Id" := 'COMP-001';
        Company1.Insert();

        Company2.Init();
        Company2.Id := 2;
        Company2."Company Name" := 'Test Company 2';
        Company2."Company Id" := 'COMP-002';
        Company2.Insert();

        // [WHEN] Filtering by name
        AvalaraCompany.SetFilter("Company Name", '*Company 1*');

        // [THEN] Should find the specific company
        Assert.IsTrue(AvalaraCompany.FindFirst(), 'Should find filtered company');
        Assert.AreEqual('Test Company 1', AvalaraCompany."Company Name", 'Should be Company 1');

        // Cleanup
        CleanupCompanies();
    end;

    [Test]
    procedure TestMandateList_DisplaysData()
    var
        ActivationMandate: Record "Activation Mandate";
    begin
        // [SCENARIO] Mandate List page displays mandate data

        // [GIVEN] Activation mandates
        Initialize();
        CreateActivationMandate(ActivationMandate);

        // [WHEN] Loading mandate data
        ActivationMandate.Get(ActivationMandate."Activation ID", ActivationMandate."Country Mandate");

        // [THEN] Should have displayable data
        Assert.AreNotEqual('', ActivationMandate."Country Mandate", 'Country mandate should be set');
        Assert.AreNotEqual('', ActivationMandate."Country Code", 'Country code should be set');

        // Cleanup
        ActivationMandate.Delete();
    end;

    [Test]
    procedure TestAvalaraDocuments_FilterByStatus()
    var
        AvalaraDocumentBuffer: Record "Avalara Document Buffer";
        Doc1, Doc2 : Record "Avalara Document Buffer";
    begin
        // [SCENARIO] Avalara Documents page can filter by status

        // [GIVEN] Documents with different statuses
        Initialize();

        Doc1.Init();
        Doc1."Document Id" := 'DOC-COMPLETE-001';
        Doc1.Status := 'Complete';
        Doc1.Insert();

        Doc2.Init();
        Doc2."Document Id" := 'DOC-PENDING-002';
        Doc2.Status := 'Pending';
        Doc2.Insert();

        // [WHEN] Filtering for Complete status
        AvalaraDocumentBuffer.SetRange(Status, 'Complete');

        // [THEN] Should find only complete documents
        Assert.IsTrue(AvalaraDocumentBuffer.FindFirst(), 'Should find complete document');
        Assert.AreEqual('Complete', AvalaraDocumentBuffer.Status, 'Status should be Complete');

        // No cleanup needed for temporary table
    end;

    [Test]
    procedure TestMediaTypes_PageData()
    var
        MediaTypes: Record "Media Types";
    begin
        // [SCENARIO] Media Types data is available for page display

        // [GIVEN] Media type records
        Initialize();
        CleanupMediaTypes();

        MediaTypes.Init();
        MediaTypes.Mandate := 'GB-PEPPOL';
        MediaTypes."Media Type" := 'application/xml';
        MediaTypes.Insert();

        // [WHEN] Page would load this data
        MediaTypes.Get('GB-PEPPOL', 'application/xml');

        // [THEN] Data should be displayable
        Assert.AreEqual('GB-PEPPOL', MediaTypes.Mandate, 'Mandate should match');
        Assert.AreEqual('application/xml', MediaTypes."Media Type", 'Media type should match');

        // Cleanup
        CleanupMediaTypes();
    end;

    [Test]
    procedure TestActivationList_CanSort()
    var
        ActivationHeader: Record "Activation Header";
        Header1, Header2 : Record "Activation Header";
    begin
        // [SCENARIO] Activation List can sort by company name

        // [GIVEN] Multiple activation headers
        Initialize();
        CleanupActivations();

        Header1.Init();
        Header1.ID := CreateGuid();
        Header1."Company Name" := 'Zebra Company';
        Header1."Company Id" := 'COMP-Z';
        Header1.Insert();

        Header2.Init();
        Header2.ID := CreateGuid();
        Header2."Company Name" := 'Alpha Company';
        Header2."Company Id" := 'COMP-A';
        Header2.Insert();

        // [WHEN] Sorting by company name (ascending)
        ActivationHeader.SetCurrentKey("Company Name");
        ActivationHeader.SetAscending("Company Name", true);

        // [THEN] First should be Alpha Company
        Assert.IsTrue(ActivationHeader.FindFirst(), 'Should find first record');
        Assert.AreEqual('Alpha Company', ActivationHeader."Company Name",
            'First record should be Alpha Company when sorted');

        // Cleanup
        CleanupActivations();
    end;

    [Test]
    procedure TestConnectionSetup_SingletonPattern()
    var
        ConnectionSetup1, ConnectionSetup2 : Record "Connection Setup";
    begin
        // [SCENARIO] Connection Setup follows singleton pattern

        // [GIVEN] System ready
        Initialize();
        CleanupConnectionSetup();

        // [WHEN] Creating connection setup
        ConnectionSetup1.Init();
        ConnectionSetup1.Insert(true);

        // [THEN] Should be the only record (singleton)
        Assert.AreEqual(1, ConnectionSetup2.Count(), 'Should only have one connection setup record');

        // Cleanup
        CleanupConnectionSetup();
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
        ConnectionSetup."Client Id" := 'test-client-id';
        ConnectionSetup.SetClientSecret('test-secret');
        ConnectionSetup."Environment Url" := 'https://test.avalara.com';
        ConnectionSetup.Modify();
    end;

    local procedure CreateActivationHeader(var ActivationHeader: Record "Activation Header")
    begin
        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Company Id" := 'TEST-COMPANY-001';
        ActivationHeader."Company Name" := 'Test Company Ltd';
        ActivationHeader."Status Code" := 'Completed';
        ActivationHeader."Registration Type" := 'VAT';
        ActivationHeader.Insert(true);
    end;

    local procedure CreateActivationMandate(var ActivationMandate: Record "Activation Mandate")
    var
        ActivationHeader: Record "Activation Header";
    begin
        CreateActivationHeader(ActivationHeader);

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := ActivationHeader.ID;
        ActivationMandate."Country Mandate" := 'GB-PEPPOL-INVOICE';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Company Id" := ActivationHeader."Company Id";
        ActivationMandate.Insert(true);
    end;

    local procedure CleanupCompanies()
    var
        AvalaraCompany: Record "Avalara Company";
    begin
        if not AvalaraCompany.IsEmpty() then
            AvalaraCompany.DeleteAll(true);
    end;

    local procedure CleanupMediaTypes()
    var
        MediaTypes: Record "Media Types";
    begin
        if not MediaTypes.IsEmpty() then
            MediaTypes.DeleteAll(true);
    end;

    local procedure CleanupActivations()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
    begin
        if not ActivationMandate.IsEmpty() then
            ActivationMandate.DeleteAll(true);
        if not ActivationHeader.IsEmpty() then
            ActivationHeader.DeleteAll(true);
    end;

    local procedure CleanupConnectionSetup()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        if ConnectionSetup.Get() then
            ConnectionSetup.Delete();
    end;
}
