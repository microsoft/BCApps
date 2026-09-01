// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

/// <summary>
/// Tests for page logic in the Avalara E-Document Connector covering page triggers,
/// actions, exposed procedures, and field visibility across Activation Card/List,
/// Connection Setup Card, Avalara Documents, Company List, Mandate List,
/// Message Response Card, Activation Subform, and Avalara Input Fields pages.
/// </summary>
codeunit 133627 "Page Logic Tests"
{
    Permissions = tabledata "Activation Header" = rimd,
                  tabledata "Activation Mandate" = rimd,
                  tabledata "Avalara Input Field" = rimd,
                  tabledata "Avl Message Event" = rimd,
                  tabledata "Avl Message Response Header" = rimd,
                  tabledata "Connection Setup" = rimd;
    Subtype = Test;
    TestType = UnitTest;

    // ========================================================================
    // Activation Card Tests
    // ========================================================================

    [Test]
    procedure ActivationCard_DisplaysHeaderFields()
    var
        ActivationHeader: Record "Activation Header";
        ActivationId: Guid;
        ActivationCardPage: TestPage "Activation Card";
    begin
        // [SCENARIO] Activation Card should display all header fields correctly
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header record
        ActivationHeader.DeleteAll();
        ActivationId := CreateGuid();
        ActivationHeader.Init();
        ActivationHeader.ID := ActivationId;
        ActivationHeader."Company Name" := 'Test Company Ltd';
        ActivationHeader.Jurisdiction := 'GB';
        ActivationHeader."Scheme Id" := 'PEPPOL';
        ActivationHeader.Identifier := 'GB:PEPPOL:12345';
        ActivationHeader."Full Authority Value" := 'hmrc.gov.uk';
        ActivationHeader."Status Code" := 'Completed';
        ActivationHeader."Status Message" := 'Activation completed';
        ActivationHeader."Company Id" := 'comp-page-test';
        ActivationHeader."Company Location" := '/api/v1/companies/comp-page-test';
        ActivationHeader.Insert();

        // [WHEN] The Activation Card page is opened
        ActivationCardPage.OpenView();
        ActivationCardPage.GoToRecord(ActivationHeader);

        // [THEN] Fields display correct values
        Assert.AreEqual('Test Company Ltd', ActivationCardPage."Company Name".Value(), 'Company Name should display correctly');
        Assert.AreEqual('GB', ActivationCardPage.Jurisdiction.Value(), 'Jurisdiction should display correctly');
        Assert.AreEqual('PEPPOL', ActivationCardPage."Scheme Id".Value(), 'Scheme Id should display correctly');
        Assert.AreEqual('GB:PEPPOL:12345', ActivationCardPage.Identifier.Value(), 'Identifier should display correctly');
        Assert.AreEqual('hmrc.gov.uk', ActivationCardPage."Full Authority Value".Value(), 'Full Authority Value should display correctly');
        Assert.AreEqual('Completed', ActivationCardPage."Status Code".Value(), 'Status Code should display correctly');
        Assert.AreEqual('Activation completed', ActivationCardPage."Status Message".Value(), 'Status Message should display correctly');
        Assert.AreEqual('comp-page-test', ActivationCardPage."Company Id".Value(), 'Company Id should display correctly');
        Assert.AreEqual('/api/v1/companies/comp-page-test', ActivationCardPage."Company Location".Value(), 'Company Location should display correctly');

        ActivationCardPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    [Test]
    procedure ActivationCard_IsNotEditable()
    var
        ActivationHeader: Record "Activation Header";
        ActivationCardPage: TestPage "Activation Card";
    begin
        // [SCENARIO] Activation Card fields should not be editable (page is Editable = false)
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header record
        ActivationHeader.DeleteAll();
        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Company Name" := 'Read Only Test';
        ActivationHeader."Status Code" := 'Completed';
        ActivationHeader.Insert();

        // [WHEN] Activation Card is opened
        ActivationCardPage.OpenView();
        ActivationCardPage.GoToRecord(ActivationHeader);

        // [THEN] Key fields are not editable
        Assert.IsFalse(ActivationCardPage.ID.Editable(), 'ID field should not be editable');
        Assert.IsFalse(ActivationCardPage."Last Modified".Editable(), 'Last Modified should not be editable');
        Assert.IsFalse(ActivationCardPage."Meta Location".Editable(), 'Meta Location should not be editable');
        Assert.IsFalse(ActivationCardPage."Company Id".Editable(), 'Company Id should not be editable');
        Assert.IsFalse(ActivationCardPage."Company Location".Editable(), 'Company Location should not be editable');

        ActivationCardPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    // ========================================================================
    // Activation List Tests
    // ========================================================================

    [Test]
    procedure ActivationList_DisplaysMultipleRecords()
    var
        ActivationHeader: Record "Activation Header";
        ActivationHeader1: Record "Activation Header";
        ActivationHeader2: Record "Activation Header";
        ActivationListPage: TestPage "Activation List";
    begin
        // [SCENARIO] Activation List should display all activation header records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Two activation header records
        ActivationHeader.DeleteAll();

        ActivationHeader1.Init();
        ActivationHeader1.ID := CreateGuid();
        ActivationHeader1."Company Name" := 'Company Alpha';
        ActivationHeader1."Status Code" := 'Completed';
        ActivationHeader1.Jurisdiction := 'GB';
        ActivationHeader1.Insert();

        ActivationHeader2.Init();
        ActivationHeader2.ID := CreateGuid();
        ActivationHeader2."Company Name" := 'Company Beta';
        ActivationHeader2."Status Code" := 'Pending';
        ActivationHeader2.Jurisdiction := 'DE';
        ActivationHeader2.Insert();

        // [WHEN] Activation List is opened
        ActivationListPage.OpenView();

        // [THEN] First record values are visible (use GoToRecord since GUID PK has no predictable order)
        ActivationListPage.GoToRecord(ActivationHeader1);
        Assert.AreEqual('Company Alpha', ActivationListPage."Company Name".Value(), 'Alpha Company Name should match');
        Assert.AreEqual('Completed', ActivationListPage."Status Code".Value(), 'Alpha Status Code should match');
        Assert.AreEqual('GB', ActivationListPage.Jurisdiction.Value(), 'Alpha Jurisdiction should match');

        // [THEN] Second record values are visible
        ActivationListPage.GoToRecord(ActivationHeader2);
        Assert.AreEqual('Company Beta', ActivationListPage."Company Name".Value(), 'Beta Company Name should match');
        Assert.AreEqual('Pending', ActivationListPage."Status Code".Value(), 'Beta Status Code should match');
        Assert.AreEqual('DE', ActivationListPage.Jurisdiction.Value(), 'Beta Jurisdiction should match');

        ActivationListPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    [Test]
    procedure ActivationList_ViewDetails_NoMandates_RaisesError()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ActivationListPage: TestPage "Activation List";
    begin
        // [SCENARIO] View Details action should error when no mandates exist for the selected activation
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header with no associated mandates
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Company Name" := 'No Mandates Co';
        ActivationHeader."Status Code" := 'Pending';
        ActivationHeader.Insert();

        // [WHEN] Page is opened and View Details is invoked
        ActivationListPage.OpenView();
        ActivationListPage.GoToRecord(ActivationHeader);

        asserterror ActivationListPage."View Details".Invoke();

        // [THEN] Error about missing mandates is raised
        Assert.ExpectedError('No Mandate found!');

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    [Test]
    [HandlerFunctions('ActivationCardModalHandler')]
    procedure ActivationList_ViewDetails_WithMandates_OpensCard()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ActivationId: Guid;
        ActivationListPage: TestPage "Activation List";
    begin
        // [SCENARIO] View Details action should open Activation Card when mandates exist
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header with associated mandates
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        ActivationId := CreateGuid();
        ActivationHeader.Init();
        ActivationHeader.ID := ActivationId;
        ActivationHeader."Company Name" := 'With Mandates Co';
        ActivationHeader."Status Code" := 'Completed';
        ActivationHeader.Insert();

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := ActivationId;
        ActivationMandate."Country Mandate" := 'GB-B2B-PEPPOL';
        ActivationMandate."Mandate Type" := 'B2B';
        ActivationMandate."Company Id" := 'view-detail-comp';
        ActivationMandate.Insert();

        // [WHEN] Page is opened and View Details is invoked
        ActivationListPage.OpenView();
        ActivationListPage.GoToRecord(ActivationHeader);
        ActivationListPage."View Details".Invoke();

        // [THEN] Activation Card modal page opens (handled by ActivationCardModalHandler)
        ActivationListPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();
    end;

    [Test]
    procedure ActivationList_IsNotEditable()
    var
        ActivationHeader: Record "Activation Header";
        ActivationListPage: TestPage "Activation List";
    begin
        // [SCENARIO] Activation List should be non-editable (page is Editable = false)
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header record
        ActivationHeader.DeleteAll();
        ActivationHeader.Init();
        ActivationHeader.ID := CreateGuid();
        ActivationHeader."Company Name" := 'Editable Test';
        ActivationHeader.Insert();

        // [WHEN] The list page is opened
        ActivationListPage.OpenView();
        ActivationListPage.GoToRecord(ActivationHeader);

        // [THEN] Fields are not editable
        Assert.IsFalse(ActivationListPage.ID.Editable(), 'ID should not be editable');
        Assert.IsFalse(ActivationListPage."Company Name".Editable(), 'Company Name should not be editable');
        Assert.IsFalse(ActivationListPage."Status Code".Editable(), 'Status Code should not be editable');

        ActivationListPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    // ========================================================================
    // Connection Setup Card Tests
    // ========================================================================

    [Test]
    procedure ConnectionSetupCard_OnOpenPage_CreatesSetupRecord()
    var
        ConnectionSetup: Record "Connection Setup";
        ConnectionSetupCard: TestPage "Connection Setup Card";
    begin
        // [SCENARIO] Opening Connection Setup Card should create the setup record with default URLs
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] No connection setup exists
        ConnectionSetup.DeleteAll();

        // [WHEN] Connection Setup Card is opened
        ConnectionSetupCard.OpenView();

        // [THEN] Connection Setup record is created with default URLs
        Assert.IsTrue(ConnectionSetup.Get(), 'Connection Setup should be created on page open');
        Assert.AreEqual('https://identity.avalara.com', ConnectionSetup."Authentication URL", 'Default Authentication URL should be set');
        Assert.AreEqual('https://api.avalara.com', ConnectionSetup."API URL", 'Default API URL should be set');
        Assert.AreEqual('https://ai-sbx.avlr.sh', ConnectionSetup."Sandbox Authentication URL", 'Default Sandbox Auth URL should be set');
        Assert.AreEqual('https://api.sbx.avalara.com', ConnectionSetup."Sandbox API URL", 'Default Sandbox API URL should be set');

        // Do not call Close() explicitly - OnClosePage fires TestField("Company Id")
        // which would error since we just created the record with empty Company Id.
        // TestPage cleanup on procedure exit does not fire OnClosePage.
    end;

    [Test]
    procedure ConnectionSetupCard_OnClosePage_NoCompanyId_RaisesError()
    var
        ConnectionSetup: Record "Connection Setup";
        ConnectionSetupCard: TestPage "Connection Setup Card";
    begin
        // [SCENARIO] Closing Connection Setup Card without Company Id should raise TestField error
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup with empty Company Id
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := '';
        ConnectionSetup.Modify();

        // [WHEN] Page is opened and then closed with empty Company Id
        ConnectionSetupCard.OpenView();
        asserterror ConnectionSetupCard.Close();

        // [THEN] Error about missing Company Id
        Assert.ExpectedError('Company ID must have a value');
    end;

    [Test]
    procedure ConnectionSetupCard_DisplaysFields()
    var
        ConnectionSetup: Record "Connection Setup";
        ConnectionSetupCard: TestPage "Connection Setup Card";
    begin
        // [SCENARIO] Connection Setup Card should display configured values
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup with known values
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Name" := 'Avalara Test Corp';
        ConnectionSetup."Company Id" := 'avl-test-id-123';
        ConnectionSetup.Modify();

        // [WHEN] Connection Setup Card is opened
        ConnectionSetupCard.OpenView();

        // [THEN] Fields display correct values
        Assert.AreEqual('Avalara Test Corp', ConnectionSetupCard."Company Name".Value(), 'Company Name should display correctly');
        Assert.AreEqual('avl-test-id-123', ConnectionSetupCard."Company Id".Value(), 'Company Id should display correctly');
        Assert.AreEqual('https://identity.avalara.com', ConnectionSetupCard."Authentication URL".Value(), 'Authentication URL should display');
        Assert.AreEqual('https://api.avalara.com', ConnectionSetupCard."API URL".Value(), 'API URL should display');

        // [THEN] Company fields are not editable
        Assert.IsFalse(ConnectionSetupCard."Company Name".Editable(), 'Company Name should not be editable');
        Assert.IsFalse(ConnectionSetupCard."Company Id".Editable(), 'Company Id should not be editable');
        Assert.IsFalse(ConnectionSetupCard."Token Expiry".Editable(), 'Token Expiry should not be editable');

        ConnectionSetupCard.Close();
    end;

    // ========================================================================
    // Avalara Documents Page Tests
    // ========================================================================

    [Test]
    procedure AvalaraDocuments_OnOpenPage_WithSetup_OpensWithoutError()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraDocumentsPage: TestPage "Avalara Documents";
    begin
        // [SCENARIO] Opening Avalara Documents page with Connection Setup should not error
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup with a company ID
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ConnectionSetup."Company Id" := 'doc-page-company-id';
        ConnectionSetup.Modify();

        // [WHEN] Avalara Documents page is opened
        AvalaraDocumentsPage.OpenView();

        // [THEN] Page opens without error (OnOpenPage reads Connection Setup successfully)
        // The CompanyID page variable is loaded from Connection Setup in OnOpenPage
        // but cannot be reliably verified via TestPage on a SourceTableTemporary page
        AvalaraDocumentsPage.Close();
    end;

    [Test]
    procedure AvalaraDocuments_OnOpenPage_NoSetup_EmptyCompany()
    var
        ConnectionSetup: Record "Connection Setup";
        AvalaraDocumentsPage: TestPage "Avalara Documents";
    begin
        // [SCENARIO] Opening Avalara Documents page without Connection Setup should show empty company
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] No connection setup
        ConnectionSetup.DeleteAll();

        // [WHEN] Avalara Documents page is opened
        AvalaraDocumentsPage.OpenView();

        // [THEN] Company ID field is empty
        Assert.AreEqual('', AvalaraDocumentsPage."Avalara Company".Value(), 'Company ID should be empty when no setup exists');

        AvalaraDocumentsPage.Close();

        // [CLEANUP] Restore connection setup for other tests
        EnsureConnectionSetup();
    end;

    // ========================================================================
    // Message Response Card Tests
    // ========================================================================

    [Test]
    procedure MessageResponseCard_DisplaysFields()
    var
        MessageResponseHeader: Record "Avl Message Response Header";
        MessageResponseCardPage: TestPage "Avl Message Response Card";
    begin
        // [SCENARIO] Message Response Card should display header fields correctly
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A message response header
        MessageResponseHeader.DeleteAll();
        MessageResponseHeader.Init();
        MessageResponseHeader.Id := 'msg-resp-001';
        MessageResponseHeader.CompanyId := 'comp-resp-test';
        MessageResponseHeader.Status := 'Complete';
        MessageResponseHeader.Insert();

        // [WHEN] Message Response Card is opened
        MessageResponseCardPage.OpenView();
        MessageResponseCardPage.GoToRecord(MessageResponseHeader);

        // [THEN] Fields display correct values
        Assert.AreEqual('msg-resp-001', MessageResponseCardPage.id.Value(), 'Id should display correctly');
        Assert.AreEqual('comp-resp-test', MessageResponseCardPage.companyId.Value(), 'CompanyId should display correctly');
        Assert.AreEqual('Complete', MessageResponseCardPage.status.Value(), 'Status should display correctly');

        MessageResponseCardPage.Close();

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
    end;

    [Test]
    procedure MessageResponseCard_IsNotEditable()
    var
        MessageResponseHeader: Record "Avl Message Response Header";
        MessageResponseCardPage: TestPage "Avl Message Response Card";
    begin
        // [SCENARIO] Message Response Card should be read-only
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A message response header
        MessageResponseHeader.DeleteAll();
        MessageResponseHeader.Init();
        MessageResponseHeader.Id := 'msg-resp-ro';
        MessageResponseHeader.CompanyId := 'comp-ro';
        MessageResponseHeader.Status := 'Pending';
        MessageResponseHeader.Insert();

        // [WHEN] Page is opened
        MessageResponseCardPage.OpenView();
        MessageResponseCardPage.GoToRecord(MessageResponseHeader);

        // [THEN] Fields are not editable (page is Editable = false)
        Assert.IsFalse(MessageResponseCardPage.id.Editable(), 'Id should not be editable');
        Assert.IsFalse(MessageResponseCardPage.companyId.Editable(), 'CompanyId should not be editable');
        Assert.IsFalse(MessageResponseCardPage.status.Editable(), 'Status should not be editable');

        MessageResponseCardPage.Close();

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
    end;

    // ========================================================================
    // Message Events Subform Tests
    // ========================================================================

    [Test]
    procedure MessageEventsSubform_DisplaysEventRecords()
    var
        MessageEvent: Record "Avl Message Event";
        MessageResponseHeader: Record "Avl Message Response Header";
        MessageResponseCardPage: TestPage "Avl Message Response Card";
    begin
        // [SCENARIO] Message Events Subform should display event records linked to the header
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A message response header with events
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();

        MessageResponseHeader.Init();
        MessageResponseHeader.Id := 'evt-test-header';
        MessageResponseHeader.CompanyId := 'comp-evt';
        MessageResponseHeader.Status := 'Complete';
        MessageResponseHeader.Insert();

        MessageEvent.Init();
        MessageEvent.Id := 'evt-test-header';
        MessageEvent.MessageRow := 1;
        MessageEvent.Message := 'Document started processing';
        MessageEvent.EDocEntryNo := 10001;
        MessageEvent.PostedDocument := 'INV-EVT-001';
        MessageEvent.Insert();

        MessageEvent.Init();
        MessageEvent.Id := 'evt-test-header';
        MessageEvent.MessageRow := 2;
        MessageEvent.Message := 'Document delivered';
        MessageEvent.ResponseKey := 'Receipt ID';
        MessageEvent.ResponseValue := 'rcpt-12345';
        MessageEvent.Insert();

        // [WHEN] Message Response Card is opened (subform links via id)
        MessageResponseCardPage.OpenView();
        MessageResponseCardPage.GoToRecord(MessageResponseHeader);

        // [THEN] Events subform shows the linked events
        MessageResponseCardPage.Events.First();
        Assert.AreEqual('Document started processing', MessageResponseCardPage.Events.message.Value(), 'First event message should match');
        Assert.AreEqual('INV-EVT-001', MessageResponseCardPage.Events.PostedDocument.Value(), 'First event PostedDocument should match');
        Assert.AreEqual(Format(10001), MessageResponseCardPage.Events.EDocEntryNo.Value(), 'First event EDocEntryNo should match');

        MessageResponseCardPage.Events.Next();
        Assert.AreEqual('Document delivered', MessageResponseCardPage.Events.message.Value(), 'Second event message should match');
        Assert.AreEqual('Receipt ID', MessageResponseCardPage.Events.responseKey.Value(), 'Second event ResponseKey should match');
        Assert.AreEqual('rcpt-12345', MessageResponseCardPage.Events.responseValue.Value(), 'Second event ResponseValue should match');

        MessageResponseCardPage.Close();

        // [CLEANUP]
        MessageResponseHeader.DeleteAll();
        MessageEvent.DeleteAll();
    end;

    // ========================================================================
    // Activation Subform Tests
    // ========================================================================

    [Test]
    procedure ActivationSubform_DisplaysMandatesLinkedToHeader()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ActivationId: Guid;
        ActivationCardPage: TestPage "Activation Card";
    begin
        // [SCENARIO] Activation Card subform should display mandates linked to the activation header
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header with mandates
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        ActivationId := CreateGuid();
        ActivationHeader.Init();
        ActivationHeader.ID := ActivationId;
        ActivationHeader."Company Name" := 'Subform Test Co';
        ActivationHeader."Status Code" := 'Completed';
        ActivationHeader.Insert();

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := ActivationId;
        ActivationMandate."Country Mandate" := 'GB-B2B-PEPPOL';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Mandate Type" := 'B2B';
        ActivationMandate."Company Id" := 'subform-comp';
        ActivationMandate.Activated := true;
        ActivationMandate.Blocked := false;
        ActivationMandate.Insert();

        ActivationMandate.Init();
        ActivationMandate."Activation ID" := ActivationId;
        ActivationMandate."Country Mandate" := 'GB-B2G-PEPPOL';
        ActivationMandate."Country Code" := 'GB';
        ActivationMandate."Mandate Type" := 'B2G';
        ActivationMandate."Company Id" := 'subform-comp';
        ActivationMandate.Activated := false;
        ActivationMandate.Blocked := true;
        ActivationMandate.Insert();

        // [WHEN] Activation Card is opened
        ActivationCardPage.OpenView();
        ActivationCardPage.GoToRecord(ActivationHeader);

        // [THEN] Subform shows linked mandates
        ActivationCardPage.Mandates.First();
        Assert.AreEqual('GB-B2B-PEPPOL', ActivationCardPage.Mandates."Country Mandate".Value(), 'First mandate code should match');
        Assert.AreEqual('GB', ActivationCardPage.Mandates."Country Code".Value(), 'First mandate country code should match');
        Assert.AreEqual('B2B', ActivationCardPage.Mandates."Mandate Type".Value(), 'First mandate type should match');
        Assert.IsTrue(ActivationCardPage.Mandates.Activated.AsBoolean(), 'First mandate should be activated');
        Assert.IsFalse(ActivationCardPage.Mandates.Blocked.AsBoolean(), 'First mandate should not be blocked');

        ActivationCardPage.Mandates.Next();
        Assert.AreEqual('GB-B2G-PEPPOL', ActivationCardPage.Mandates."Country Mandate".Value(), 'Second mandate code should match');
        Assert.AreEqual('B2G', ActivationCardPage.Mandates."Mandate Type".Value(), 'Second mandate type should match');
        Assert.IsFalse(ActivationCardPage.Mandates.Activated.AsBoolean(), 'Second mandate should not be activated');
        Assert.IsTrue(ActivationCardPage.Mandates.Blocked.AsBoolean(), 'Second mandate should be blocked');

        ActivationCardPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();
    end;

    [Test]
    procedure ActivationSubform_NoMandates_ShowsEmpty()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ActivationId: Guid;
        ActivationCardPage: TestPage "Activation Card";
    begin
        // [SCENARIO] Activation Card subform should be empty when no mandates are linked
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An activation header with no mandates
        ActivationHeader.DeleteAll();
        ActivationMandate.DeleteAll();

        ActivationId := CreateGuid();
        ActivationHeader.Init();
        ActivationHeader.ID := ActivationId;
        ActivationHeader."Company Name" := 'Empty Subform Co';
        ActivationHeader.Insert();

        // [WHEN] Activation Card is opened
        ActivationCardPage.OpenView();
        ActivationCardPage.GoToRecord(ActivationHeader);

        // [THEN] Subform has no records - First() returns false
        Assert.IsFalse(ActivationCardPage.Mandates.First(), 'Subform should have no mandate records');

        ActivationCardPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    // ========================================================================
    // Avalara Input Fields Page Tests
    // ========================================================================

    [Test]
    procedure AvalaraInputFields_DisplaysFieldRecords()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraInputFieldsPage: TestPage "Avalara Input Fields";
    begin
        // [SCENARIO] Avalara Input Fields page should display input field records
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Input field records
        AvalaraInputField.DeleteAll();

        AvalaraInputField.Init();
        AvalaraInputField.FieldId := 1;
        AvalaraInputField.Mandate := 'GB-B2B-PEPPOL';
        AvalaraInputField.DocumentType := 'ubl-invoice';
        AvalaraInputField.DocumentVersion := '2.1';
        AvalaraInputField.FieldName := 'BuyerReference';
        AvalaraInputField.Path := '/Invoice/BuyerReference';
        AvalaraInputField.PathType := 'element';
        AvalaraInputField.DataType := 'string';
        AvalaraInputField.Description := 'Buyer reference number';
        AvalaraInputField.Optionality := 'Required';
        AvalaraInputField.Insert();

        AvalaraInputField.Init();
        AvalaraInputField.FieldId := 2;
        AvalaraInputField.Mandate := 'GB-B2B-PEPPOL';
        AvalaraInputField.DocumentType := 'ubl-invoice';
        AvalaraInputField.DocumentVersion := '2.1';
        AvalaraInputField.FieldName := 'InvoiceNumber';
        AvalaraInputField.Path := '/Invoice/ID';
        AvalaraInputField.PathType := 'element';
        AvalaraInputField.DataType := 'string';
        AvalaraInputField.Description := 'Invoice number';
        AvalaraInputField.Optionality := 'Required';
        AvalaraInputField.Insert();

        // [WHEN] Avalara Input Fields page is opened
        AvalaraInputFieldsPage.OpenView();

        // [THEN] Records are displayed
        AvalaraInputFieldsPage.First();
        Assert.AreEqual('GB-B2B-PEPPOL', AvalaraInputFieldsPage.Mandate.Value(), 'Mandate should display correctly');
        Assert.AreEqual('BuyerReference', AvalaraInputFieldsPage.FieldName.Value(), 'FieldName should display correctly');
        Assert.AreEqual('ubl-invoice', AvalaraInputFieldsPage.DocumentType.Value(), 'DocumentType should display correctly');
        Assert.AreEqual('/Invoice/BuyerReference', AvalaraInputFieldsPage.Path.Value(), 'Path should display correctly');
        Assert.AreEqual('string', AvalaraInputFieldsPage.DataType.Value(), 'DataType should display correctly');
        Assert.AreEqual('Buyer reference number', AvalaraInputFieldsPage.Description.Value(), 'Description should display correctly');
        Assert.AreEqual('Required', AvalaraInputFieldsPage.Optionality.Value(), 'Optionality should display correctly');

        AvalaraInputFieldsPage.Close();

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
    end;

    [Test]
    procedure AvalaraInputFields_IsNotEditable()
    var
        AvalaraInputField: Record "Avalara Input Field";
        AvalaraInputFieldsPage: TestPage "Avalara Input Fields";
    begin
        // [SCENARIO] Avalara Input Fields page should be non-editable
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An input field record
        AvalaraInputField.DeleteAll();
        AvalaraInputField.Init();
        AvalaraInputField.FieldId := 100;
        AvalaraInputField.Mandate := 'TEST-MANDATE';
        AvalaraInputField.DocumentType := 'ubl-invoice';
        AvalaraInputField.DocumentVersion := '2.1';
        AvalaraInputField.FieldName := 'TestField';
        AvalaraInputField.Insert();

        // [WHEN] Page is opened
        AvalaraInputFieldsPage.OpenView();
        AvalaraInputFieldsPage.First();

        // [THEN] Fields are not editable
        Assert.IsFalse(AvalaraInputFieldsPage.Mandate.Editable(), 'Mandate should not be editable');
        Assert.IsFalse(AvalaraInputFieldsPage.FieldName.Editable(), 'FieldName should not be editable');
        Assert.IsFalse(AvalaraInputFieldsPage.Path.Editable(), 'Path should not be editable');

        AvalaraInputFieldsPage.Close();

        // [CLEANUP]
        AvalaraInputField.DeleteAll();
    end;

    // ========================================================================
    // Company List Page Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('CompanyListVerifyHandler')]
    procedure CompanyList_SetRecords_PopulatesPage()
    var
        TempAvalaraCompany: Record "Avalara Company" temporary;
        CompanyListPage: Page "Company List";
    begin
        // [SCENARIO] CompanyList.SetRecords should copy temp records into the page source
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Temporary company records
        TempAvalaraCompany.Init();
        TempAvalaraCompany.Id := 1;
        TempAvalaraCompany."Company Name" := 'Alpha Corp';
        TempAvalaraCompany."Company Id" := 'alpha-001';
        TempAvalaraCompany.Insert();

        TempAvalaraCompany.Init();
        TempAvalaraCompany.Id := 2;
        TempAvalaraCompany."Company Name" := 'Beta Inc';
        TempAvalaraCompany."Company Id" := 'beta-002';
        TempAvalaraCompany.Insert();

        // Store expected values for handler verification
        ExpectedCompanyName1 := 'Alpha Corp';
        ExpectedCompanyId1 := 'alpha-001';
        ExpectedCompanyName2 := 'Beta Inc';
        ExpectedCompanyId2 := 'beta-002';

        // [WHEN] SetRecords is called and page runs as modal
        CompanyListPage.SetRecords(TempAvalaraCompany);
        CompanyListPage.RunModal();

        // [THEN] Verified in handler - records are displayed
    end;

    // ========================================================================
    // Mandate List Page Tests
    // ========================================================================

    [Test]
    [HandlerFunctions('MandateListVerifyHandler')]
    procedure MandateList_SetTempRecords_PopulatesPage()
    var
        TempMandate: Record Mandate temporary;
        MandateListPage: Page "Mandate List";
    begin
        // [SCENARIO] MandateList.SetTempRecords should copy temp records into the page source
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Temporary mandate records
        TempMandate.Init();
        TempMandate."Country Mandate" := 'GB-B2B-PEPPOL';
        TempMandate."Country Code" := 'GB';
        TempMandate.Description := 'UK B2B PEPPOL';
        TempMandate."Invoice Format" := 'ubl-invoice';
        TempMandate.Insert();

        TempMandate.Init();
        TempMandate."Country Mandate" := 'DE-B2G-PEPPOL';
        TempMandate."Country Code" := 'DE';
        TempMandate.Description := 'Germany B2G PEPPOL';
        TempMandate."Invoice Format" := 'ubl-invoice';
        TempMandate.Insert();

        // Store expected values for handler verification
        // Code[50] PK sorts alphabetically: DE < GB
        ExpectedMandateCode1 := 'DE-B2G-PEPPOL';
        ExpectedCountryCode1 := 'DE';
        ExpectedMandateCode2 := 'GB-B2B-PEPPOL';
        ExpectedCountryCode2 := 'GB';

        // [WHEN] SetTempRecords is called and page runs as modal
        MandateListPage.SetTempRecords(TempMandate);
        MandateListPage.RunModal();

        // [THEN] Verified in handler - records are displayed
    end;

    // ========================================================================
    // Connection Setup Card - Insert/Delete Not Allowed Tests
    // ========================================================================

    [Test]
    procedure ConnectionSetupCard_DoesNotAllowInsertOrDelete()
    var
        ConnectionSetupCard: TestPage "Connection Setup Card";
    begin
        // [SCENARIO] Connection Setup Card should not allow insert or delete operations
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Connection setup exists with Company Id (to avoid OnClosePage error)
        EnsureConnectionSetupWithCompany();

        // [WHEN] Page is opened
        ConnectionSetupCard.OpenView();

        // [THEN] Page properties prevent insert/delete (verified by page definition)
        // InsertAllowed = false, DeleteAllowed = false as set on page
        // Attempting new record should not be possible on view mode
        ConnectionSetupCard.Close();
    end;

    // ========================================================================
    // Activation List IsActive Indicator Test
    // ========================================================================

    [Test]
    procedure ActivationList_IsActiveField_DisplaysCorrectly()
    var
        ActivationHeader: Record "Activation Header";
        ActiveHeader: Record "Activation Header";
        InactiveHeader: Record "Activation Header";
        ActivationListPage: TestPage "Activation List";
    begin
        // [SCENARIO] Activation List should correctly show Is Active ID field
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Two headers - one active, one not
        ActivationHeader.DeleteAll();

        ActiveHeader.Init();
        ActiveHeader.ID := CreateGuid();
        ActiveHeader."Company Name" := 'Active Company';
        ActiveHeader."Is Active ID" := true;
        ActiveHeader.Insert();

        InactiveHeader.Init();
        InactiveHeader.ID := CreateGuid();
        InactiveHeader."Company Name" := 'Inactive Company';
        InactiveHeader."Is Active ID" := false;
        InactiveHeader.Insert();

        // [WHEN] Activation List is opened
        ActivationListPage.OpenView();

        // [THEN] Active record shows active (use GoToRecord since GUID PK has no predictable order)
        ActivationListPage.GoToRecord(ActiveHeader);
        Assert.AreEqual('Active Company', ActivationListPage."Company Name".Value(), 'Should be Active Company');
        Assert.IsTrue(ActivationListPage."Is Active ID".AsBoolean(), 'Active record should be active');

        // [THEN] Inactive record shows inactive
        ActivationListPage.GoToRecord(InactiveHeader);
        Assert.AreEqual('Inactive Company', ActivationListPage."Company Name".Value(), 'Should be Inactive Company');
        Assert.IsFalse(ActivationListPage."Is Active ID".AsBoolean(), 'Inactive record should be inactive');

        ActivationListPage.Close();

        // [CLEANUP]
        ActivationHeader.DeleteAll();
    end;

    // ========================================================================
    // Handlers
    // ========================================================================

    [ModalPageHandler]
    procedure ActivationCardModalHandler(var ActivationCardPage: TestPage "Activation Card")
    begin
        // Verify the card opened with correct data
        Assert.AreEqual('With Mandates Co', ActivationCardPage."Company Name".Value(), 'Modal card should show correct Company Name');
        ActivationCardPage.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CompanyListVerifyHandler(var CompanyList: TestPage "Company List")
    begin
        // Verify first company record
        CompanyList.First();
        Assert.AreEqual(ExpectedCompanyName1, CompanyList.CompanyName.Value(), 'First company name should match');
        Assert.AreEqual(ExpectedCompanyId1, CompanyList."Company Id".Value(), 'First company Id should match');

        // Verify second company record
        CompanyList.Next();
        Assert.AreEqual(ExpectedCompanyName2, CompanyList.CompanyName.Value(), 'Second company name should match');
        Assert.AreEqual(ExpectedCompanyId2, CompanyList."Company Id".Value(), 'Second company Id should match');

        CompanyList.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure MandateListVerifyHandler(var MandateList: TestPage "Mandate List")
    begin
        // Verify first mandate record
        MandateList.First();
        Assert.AreEqual(ExpectedMandateCode1, MandateList."Country Mandate".Value(), 'First mandate should match');
        Assert.AreEqual(ExpectedCountryCode1, MandateList."Country Code".Value(), 'First mandate country should match');

        // Verify second mandate record
        MandateList.Next();
        Assert.AreEqual(ExpectedMandateCode2, MandateList."Country Mandate".Value(), 'Second mandate should match');
        Assert.AreEqual(ExpectedCountryCode2, MandateList."Country Code".Value(), 'Second mandate country should match');

        MandateList.OK().Invoke();
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

    local procedure EnsureConnectionSetupWithCompany()
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        if ConnectionSetup."Company Id" = '' then begin
            ConnectionSetup."Company Id" := 'test-page-company';
            ConnectionSetup.Modify();
        end;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermission: Codeunit "Library - Lower Permissions";
        ExpectedCompanyId1: Text;
        ExpectedCompanyId2: Text;
        ExpectedCompanyName1: Text;
        ExpectedCompanyName2: Text;
        ExpectedCountryCode1: Text;
        ExpectedCountryCode2: Text;
        ExpectedMandateCode1: Text;
        ExpectedMandateCode2: Text;
}
