// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using Microsoft.EServices.EDocument;
using Microsoft.Sales.Document;
using Microsoft.Sales.History;
using System.IO;

/// <summary>
/// Tests for custom tables (CRUD, triggers, composite PKs, procedures)
/// and table extensions (field accessibility, CalcFields, OnValidate).
/// </summary>
codeunit 133628 "Table Tests"
{
    Permissions = tabledata "Activation Header" = rimd,
                  tabledata "Activation Mandate" = rimd,
                  tabledata "Avalara Input Field" = rimd,
                  tabledata "Avl Message Event" = rimd,
                  tabledata "Avl Message Response Header" = rimd,
                  tabledata "Connection Setup" = rimd,
                  tabledata "Media Types" = rimd,
                  tabledata "Transformation Rule" = rimd;
    Subtype = Test;
    TestType = UnitTest;

    // ========================================================================
    // Activation Mandate Table Tests
    // ========================================================================

    [Test]
    procedure ActivationMandate_CompositePK_InsertsMultipleRecords()
    var
        Mandate: Record "Activation Mandate";
        ActivationId: Guid;
    begin
        // [SCENARIO] Activation Mandate supports composite 3-part PK
        LibraryPermission.SetOutsideO365Scope();
        ActivationId := CreateGuid();

        // [GIVEN] Two mandates with same Activation ID but different Country Mandate and Mandate Type
        Mandate.Init();
        Mandate."Activation ID" := ActivationId;
        Mandate."Country Mandate" := 'DE-B2G-PEPPOL';
        Mandate."Mandate Type" := 'B2G';
        Mandate."Country Code" := 'DE';
        Mandate.Insert(false);

        Mandate.Init();
        Mandate."Activation ID" := ActivationId;
        Mandate."Country Mandate" := 'GB-B2B-PEPPOL';
        Mandate."Mandate Type" := 'B2B';
        Mandate."Country Code" := 'GB';
        Mandate.Insert(false);

        // [THEN] Both records exist
        Mandate.SetRange("Activation ID", ActivationId);
        Assert.AreEqual(2, Mandate.Count(), 'Should have 2 mandates for the activation');

        // Cleanup
        Mandate.DeleteAll(false);
    end;

    [Test]
    procedure ActivationMandate_GetBlocked_ReturnsTrueWhenBlocked()
    var
        Mandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        ActivationId: Guid;
    begin
        // [SCENARIO] GetBlocked returns true when mandate is blocked
        LibraryPermission.SetOutsideO365Scope();
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ActivationId := CreateGuid();

        // [GIVEN] A blocked mandate matching ConnectionSetup Company Id
        Mandate.Init();
        Mandate."Activation ID" := ActivationId;
        Mandate."Country Mandate" := 'DE-B2G-PEPPOL';
        Mandate."Mandate Type" := 'B2G';
        Mandate."Company Id" := CopyStr(ConnectionSetup."Company Id", 1, MaxStrLen(Mandate."Company Id"));
        Mandate.Blocked := true;
        Mandate.Insert(false);

        // [WHEN] GetBlocked is called
        // [THEN] Returns true
        Assert.IsTrue(Mandate.GetBlocked(ConnectionSetup, 'DE-B2G-PEPPOL'), 'GetBlocked should return true for blocked mandate');

        // Cleanup
        Mandate.DeleteAll(false);
    end;

    [Test]
    procedure ActivationMandate_GetBlocked_ReturnsFalseWhenNotBlocked()
    var
        Mandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
        ActivationId: Guid;
    begin
        // [SCENARIO] GetBlocked returns false when mandate is not blocked
        LibraryPermission.SetOutsideO365Scope();
        EnsureConnectionSetup();
        ConnectionSetup.Get();
        ActivationId := CreateGuid();

        // [GIVEN] An unblocked mandate matching ConnectionSetup Company Id
        Mandate.Init();
        Mandate."Activation ID" := ActivationId;
        Mandate."Country Mandate" := 'IT-B2B-SDI';
        Mandate."Mandate Type" := 'B2B';
        Mandate."Company Id" := CopyStr(ConnectionSetup."Company Id", 1, MaxStrLen(Mandate."Company Id"));
        Mandate.Blocked := false;
        Mandate.Insert(false);

        // [WHEN] GetBlocked is called
        // [THEN] Returns false
        Assert.IsFalse(Mandate.GetBlocked(ConnectionSetup, 'IT-B2B-SDI'), 'GetBlocked should return false for unblocked mandate');

        // Cleanup
        Mandate.DeleteAll(false);
    end;

    // ========================================================================
    // Avalara Company Table Tests (Temporary)
    // ========================================================================

    [Test]
    procedure AvalaraCompany_TempTable_InsertAndRetrieve()
    var
        TempCompany: Record "Avalara Company" temporary;
    begin
        // [SCENARIO] Avalara Company temp table supports multiple records with explicit IDs
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Two company records with explicit PKs
        TempCompany.Init();
        TempCompany.Id := 1;
        TempCompany."Company Name" := 'First Company';
        TempCompany."Company Id" := 'COMP-001';
        TempCompany.Insert(false);

        TempCompany.Init();
        TempCompany.Id := 2;
        TempCompany."Company Name" := 'Second Company';
        TempCompany."Company Id" := 'COMP-002';
        TempCompany.Insert(false);

        // [THEN] Both records exist
        Assert.AreEqual(2, TempCompany.Count(), 'Should have 2 companies');

        TempCompany.Get(1);
        Assert.AreEqual('First Company', TempCompany."Company Name", 'First company name should match');
        Assert.AreEqual('COMP-001', TempCompany."Company Id", 'First company id should match');

        TempCompany.Get(2);
        Assert.AreEqual('Second Company', TempCompany."Company Name", 'Second company name should match');
        Assert.AreEqual('COMP-002', TempCompany."Company Id", 'Second company id should match');
    end;

    // ========================================================================
    // Avalara Document Buffer Table Tests (Temporary)
    // ========================================================================

    [Test]
    procedure AvalaraDocumentBuffer_CompositePK_InsertRetrieve()
    var
        TempBuffer: Record "Avalara Document Buffer" temporary;
    begin
        // [SCENARIO] Avalara Document Buffer supports composite PK (Id + Process DateTime)
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Two records with same Id but different Process DateTime
        TempBuffer.Init();
        TempBuffer.Id := 'DOC-001';
        TempBuffer."Process DateTime" := CreateDateTime(20250101D, 100000T);
        TempBuffer.Status := 'pending';
        TempBuffer."Document Number" := 'INV-001';
        TempBuffer.Insert(false);

        TempBuffer.Init();
        TempBuffer.Id := 'DOC-001';
        TempBuffer."Process DateTime" := CreateDateTime(20250102D, 100000T);
        TempBuffer.Status := 'complete';
        TempBuffer."Document Number" := 'INV-001';
        TempBuffer.Insert(false);

        // [THEN] Both records exist (different PK due to different Process DateTime)
        TempBuffer.SetRange(Id, 'DOC-001');
        Assert.AreEqual(2, TempBuffer.Count(), 'Should have 2 records for same doc with different datetimes');

        // [THEN] Each record has correct status
        TempBuffer.Get('DOC-001', CreateDateTime(20250101D, 100000T));
        Assert.AreEqual('pending', TempBuffer.Status, 'First record should be pending');

        TempBuffer.Get('DOC-001', CreateDateTime(20250102D, 100000T));
        Assert.AreEqual('complete', TempBuffer.Status, 'Second record should be complete');
    end;

    // ========================================================================
    // Avalara Input Field Table Tests
    // ========================================================================

    [Test]
    procedure AvalaraInputField_FourPartPK_InsertRetrieve()
    var
        InputField: Record "Avalara Input Field";
    begin
        // [SCENARIO] Avalara Input Field supports 4-part composite PK
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Two input fields with different PK combinations
        InputField.Init();
        InputField.FieldId := 99901;
        InputField.Mandate := 'DE-B2G-PEPPOL';
        InputField.DocumentType := 'Invoice';
        InputField.DocumentVersion := '2.1';
        InputField.Path := '/Invoice/ID';
        InputField.FieldName := 'InvoiceID';
        InputField.Insert(false);

        InputField.Init();
        InputField.FieldId := 99902;
        InputField.Mandate := 'DE-B2G-PEPPOL';
        InputField.DocumentType := 'Invoice';
        InputField.DocumentVersion := '2.1';
        InputField.Path := '/Invoice/IssueDate';
        InputField.FieldName := 'IssueDate';
        InputField.Insert(false);

        // [THEN] Both records retrievable by their 4-part PK
        Assert.IsTrue(
            InputField.Get(99901, 'DE-B2G-PEPPOL', 'Invoice', '2.1'),
            'First input field should be retrievable');
        Assert.AreEqual('InvoiceID', InputField.FieldName, 'First field name should match');

        Assert.IsTrue(
            InputField.Get(99902, 'DE-B2G-PEPPOL', 'Invoice', '2.1'),
            'Second input field should be retrievable');
        Assert.AreEqual('IssueDate', InputField.FieldName, 'Second field name should match');

        // Cleanup
        InputField.SetFilter(FieldId, '99901|99902');
        InputField.DeleteAll(false);
    end;

    // ========================================================================
    // Message Response Header Table Tests
    // ========================================================================

    [Test]
    procedure MessageResponseHeader_InsertModifyRetrieve()
    var
        Header: Record "Avl Message Response Header";
    begin
        // [SCENARIO] Message Response Header supports insert, modify, retrieve
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A new message response header
        Header.Init();
        Header.Id := 'MSG-TEST-001';
        Header.CompanyId := 'COMP-001';
        Header.Status := 'pending';
        Header.Insert(false);

        // [WHEN] Status is updated
        Header.Status := 'complete';
        Header.Modify(false);

        // [THEN] Modified value persists after re-read
        Header.Get('MSG-TEST-001');
        Assert.AreEqual('complete', Header.Status, 'Status should be updated to complete');
        Assert.AreEqual('COMP-001', Header.CompanyId, 'CompanyId should be unchanged');

        // Cleanup
        Header.Delete(false);
    end;

    // ========================================================================
    // Message Event Table Tests
    // ========================================================================

    [Test]
    procedure MessageEvent_MultipleEventsPerMessage()
    var
        MsgEvent: Record "Avl Message Event";
    begin
        // [SCENARIO] Message Event supports multiple events per message via composite PK (Id + MessageRow)
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] Three events for the same message
        MsgEvent.Init();
        MsgEvent.Id := 'MSG-EVT-001';
        MsgEvent.MessageRow := 1;
        MsgEvent.Message := 'Document received';
        MsgEvent.Insert(false);

        MsgEvent.Init();
        MsgEvent.Id := 'MSG-EVT-001';
        MsgEvent.MessageRow := 2;
        MsgEvent.Message := 'Validation passed';
        MsgEvent.Insert(false);

        MsgEvent.Init();
        MsgEvent.Id := 'MSG-EVT-001';
        MsgEvent.MessageRow := 3;
        MsgEvent.Message := 'Document delivered';
        MsgEvent.Insert(false);

        // [THEN] All three events exist
        MsgEvent.SetRange(Id, 'MSG-EVT-001');
        Assert.AreEqual(3, MsgEvent.Count(), 'Should have 3 events for the message');

        // [THEN] Each event retrievable by composite PK
        MsgEvent.Get('MSG-EVT-001', 2);
        Assert.AreEqual('Validation passed', MsgEvent.Message, 'Second event message should match');

        // Cleanup
        MsgEvent.DeleteAll(false);
    end;

    // ========================================================================
    // Media Types Table Tests
    // ========================================================================

    [Test]
    procedure MediaTypes_InsertRetrieve()
    var
        MediaType: Record "Media Types";
    begin
        // [SCENARIO] Media Types table supports insert and retrieval by mandate PK
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A media type record
        MediaType.Init();
        MediaType.Mandate := 'DE-B2G-PEPPOL-TEST';
        MediaType."Invoice Available Media Types" := 'application/xml,application/pdf';
        MediaType.Insert(false);

        // [THEN] Record is retrievable
        Assert.IsTrue(MediaType.Get('DE-B2G-PEPPOL-TEST'), 'Media type record should exist');
        Assert.AreEqual(
            'application/xml,application/pdf',
            MediaType."Invoice Available Media Types",
            'Available media types should match');

        // Cleanup
        MediaType.Delete(false);
    end;

    // ========================================================================
    // E-Document Table Extension Tests
    // ========================================================================

    [Test]
    procedure EDocument_AvalaraExtensionFields_AreAccessible()
    var
        EDocument: Record "E-Document";
    begin
        // [SCENARIO] Avalara extension fields on E-Document table are accessible
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An initialized E-Document record (not inserted)
        EDocument.Init();

        // [WHEN] Avalara extension fields are set
        EDocument."Avalara Document Id" := 'AVL-DOC-12345';
        EDocument."Avalara Response Value" := 'Success-Response';

        // [THEN] Field values are stored correctly on the in-memory record
        Assert.AreEqual('AVL-DOC-12345', EDocument."Avalara Document Id", 'Avalara Document Id should store value');
        Assert.AreEqual('Success-Response', EDocument."Avalara Response Value", 'Avalara Response Value should store value');
    end;

    // ========================================================================
    // Sales Header Table Extension Tests
    // ========================================================================

    [Test]
    procedure SalesHeader_AvalaraDocID_FieldIsAccessible()
    var
        SalesHeader: Record "Sales Header";
    begin
        // [SCENARIO] Avalara Doc. ID extension field on Sales Header is accessible
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An initialized Sales Header (not inserted)
        SalesHeader.Init();

        // [WHEN] Avalara Doc. ID is set
        SalesHeader."Avalara Doc. ID" := 'TEST-DOC-123';

        // [THEN] Field value stored correctly
        Assert.AreEqual('TEST-DOC-123', SalesHeader."Avalara Doc. ID", 'Avalara Doc. ID field should store value');
    end;

    // ========================================================================
    // Sales Cr.Memo Header Table Extension Tests
    // ========================================================================

    [Test]
    procedure SalesCrMemoHeader_AvalaraDocID_FieldIsAccessible()
    var
        CrMemoHeader: Record "Sales Cr.Memo Header";
    begin
        // [SCENARIO] Avalara Doc. ID extension field on Sales Cr.Memo Header is accessible
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] An initialized Sales Cr.Memo Header (not inserted)
        CrMemoHeader.Init();

        // [WHEN] Avalara Doc. ID is set
        CrMemoHeader."Avalara Doc. ID" := 'CR-DOC-456';

        // [THEN] Field value stored correctly
        Assert.AreEqual('CR-DOC-456', CrMemoHeader."Avalara Doc. ID", 'Avalara Doc. ID field should store value');
    end;

    // ========================================================================
    // Transformation Rule Table Extension Tests
    // ========================================================================

    [Test]
    procedure TransformationRule_LookupTableID_Validate_CalcsTableName()
    var
        TransRule: Record "Transformation Rule";
    begin
        // [SCENARIO] Validating Lookup Table ID populates Lookup Table Name via CalcField
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule record
        TransRule.Init();
        TransRule.Code := 'AVALARA-TBL-T01';
        TransRule.Insert(false);

        // [WHEN] Lookup Table ID is set to Connection Setup (table 6372) and saved
        TransRule."Lookup Table ID" := 6372;
        TransRule.Modify(true);

        // [THEN] Lookup Table Name FlowField resolves to table name
        TransRule.Get('AVALARA-TBL-T01');
        TransRule.CalcFields("Lookup Table Name");
        Assert.AreEqual('Connection Setup', TransRule."Lookup Table Name", 'Lookup Table Name should resolve from table ID');

        // Cleanup
        TransRule.Delete(false);
    end;

    [Test]
    procedure TransformationRule_FieldNos_Validate_CalcFieldNames()
    var
        TransRule: Record "Transformation Rule";
    begin
        // [SCENARIO] Validating Primary/Secondary/Result Field Nos populates field names via CalcFields
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule with Lookup Table ID set to Connection Setup
        TransRule.Init();
        TransRule.Code := 'AVALARA-TBL-T02';
        TransRule."Lookup Table ID" := 6372;
        TransRule.Insert(false);

        // [WHEN] Primary, Secondary, and Result Field Nos are set
        TransRule."Primary Field No." := 10;     // "Company Id"
        TransRule."Secondary Field No." := 11;   // "Company Name"
        TransRule."Result Field No." := 12;      // "Avalara Send Mode"
        TransRule.Modify(true);

        // [THEN] Field name FlowFields resolve correctly
        TransRule.Get('AVALARA-TBL-T02');
        TransRule.CalcFields("Primary Field Name");
        Assert.AreEqual('Company Id', TransRule."Primary Field Name", 'Primary Field Name should resolve');

        TransRule.CalcFields("Secondary Field Name");
        Assert.AreEqual('Company Name', TransRule."Secondary Field Name", 'Secondary Field Name should resolve');

        TransRule.CalcFields("Result Field Name");
        Assert.AreEqual('Avalara Send Mode', TransRule."Result Field Name", 'Result Field Name should resolve');

        // Cleanup
        TransRule.Delete(false);
    end;

    [Test]
    procedure TransformationRule_LookupTableID_Zero_FlowFieldEmpty()
    var
        TransRule: Record "Transformation Rule";
    begin
        // [SCENARIO] When Lookup Table ID is 0, FlowField Lookup Table Name returns empty
        LibraryPermission.SetOutsideO365Scope();

        // [GIVEN] A Transformation Rule with no Lookup Table ID set
        TransRule.Init();
        TransRule.Code := 'AVALARA-TBL-T03';
        TransRule.Insert(false);

        // [WHEN] CalcFields is called
        TransRule.Get('AVALARA-TBL-T03');
        TransRule.CalcFields("Lookup Table Name");

        // [THEN] Name is empty since no table referenced
        Assert.AreEqual('', TransRule."Lookup Table Name", 'Lookup Table Name should be empty when Table ID is 0');

        // Cleanup
        TransRule.Delete(false);
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

    [ConfirmHandler]
    procedure ConfirmNoHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Reply := false;
    end;

    var
        Assert: Codeunit Assert;
        LibraryPermission: Codeunit "Library - Lower Permissions";
}
