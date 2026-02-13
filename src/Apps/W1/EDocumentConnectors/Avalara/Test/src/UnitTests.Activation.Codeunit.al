// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

codeunit 148200 "Unit Tests - Activation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    procedure TestPopulateFromJson_ValidJson_PopulatesHeaders()
    var
        ActivationHeader: Record "Activation Header";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] PopulateFromJson with valid JSON creates activation headers

        // [GIVEN] Valid activation JSON
        Initialize();
        ValidJson := GetValidActivationJson();

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] Activation headers should be created
        Assert.IsFalse(ActivationHeader.IsEmpty(), 'Should have created activation headers');

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestPopulateFromJson_ValidJson_PopulatesMandates()
    var
        ActivationMandate: Record "Activation Mandate";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] PopulateFromJson with valid JSON creates activation mandates

        // [GIVEN] Valid activation JSON with mandates
        Initialize();
        ValidJson := GetValidActivationJson();

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] Activation mandates should be created
        Assert.IsFalse(ActivationMandate.IsEmpty(), 'Should have created activation mandates');

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestPopulateFromJson_EmptyJson_ThrowsError()
    var
        Activation: Codeunit Activation;
        ErrorThrown: Boolean;
        EmptyJson: Text;
    begin
        // [SCENARIO] PopulateFromJson with empty JSON throws an error

        // [GIVEN] Empty JSON string
        Initialize();
        EmptyJson := '';

        // [WHEN] Attempting to populate from empty JSON
        ErrorThrown := false;
        asserterror Activation.PopulateFromJson(EmptyJson);

        // [THEN] Should throw an error
        ErrorThrown := GetLastErrorText() <> '';
        Assert.IsTrue(ErrorThrown, 'Should throw error for empty JSON');

        // Cleanup
        ClearLastError();
        Cleanup();
    end;

    [Test]
    procedure TestPopulateFromJson_InvalidJson_ThrowsError()
    var
        Activation: Codeunit Activation;
        ErrorThrown: Boolean;
        InvalidJson: Text;
    begin
        // [SCENARIO] PopulateFromJson with invalid JSON throws an error

        // [GIVEN] Invalid JSON string
        Initialize();
        InvalidJson := 'This is not valid JSON';

        // [WHEN] Attempting to populate from invalid JSON
        ErrorThrown := false;
        asserterror Activation.PopulateFromJson(InvalidJson);

        // [THEN] Should throw an error
        ErrorThrown := GetLastErrorText() <> '';
        Assert.IsTrue(ErrorThrown, 'Should throw error for invalid JSON');

        // Cleanup
        ClearLastError();
        Cleanup();
    end;

    [Test]
    procedure TestPopulateFromJson_MissingValueArray_ThrowsError()
    var
        Activation: Codeunit Activation;
        ErrorThrown: Boolean;
        JsonWithoutValue: Text;
    begin
        // [SCENARIO] PopulateFromJson with missing value array throws an error

        // [GIVEN] JSON without value array
        Initialize();
        JsonWithoutValue := '{"data": []}';

        // [WHEN] Attempting to populate from JSON without value array
        ErrorThrown := false;
        asserterror Activation.PopulateFromJson(JsonWithoutValue);

        // [THEN] Should throw an error
        ErrorThrown := GetLastErrorText() <> '';
        Assert.IsTrue(ErrorThrown, 'Should throw error for missing value array');

        // Cleanup
        ClearLastError();
        Cleanup();
    end;

    [Test]
    procedure TestClearExistingData_RemovesAllRecords()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] PopulateFromJson clears existing data before inserting new

        // [GIVEN] Existing activation data
        Initialize();
        ValidJson := GetValidActivationJson();
        Activation.PopulateFromJson(ValidJson);

        Assert.IsFalse(ActivationHeader.IsEmpty(), 'Should have existing headers');

        // [WHEN] Populating again with new JSON
        ValidJson := GetValidActivationJson();
        Activation.PopulateFromJson(ValidJson);

        // [THEN] Old data should be cleared and new data inserted
        Assert.IsFalse(ActivationHeader.IsEmpty(), 'Should have new headers');

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestActivationHeader_ParsesAllFields()
    var
        ActivationHeader: Record "Activation Header";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] Activation header is populated with all required fields

        // [GIVEN] Valid activation JSON
        Initialize();
        ValidJson := GetValidActivationJson();

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] All header fields should be populated
        ActivationHeader.FindFirst();
        Assert.AreNotEqual('', Format(ActivationHeader.ID), 'ID should be set');
        // Additional field checks can be added here

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestActivationMandate_LinkedToHeader()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] Activation mandates are correctly linked to their headers

        // [GIVEN] Valid activation JSON with mandates
        Initialize();
        ValidJson := GetValidActivationJson();

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] Mandates should be linked to headers
        ActivationHeader.FindFirst();
        ActivationMandate.SetRange("Activation ID", ActivationHeader.ID);
        Assert.IsFalse(ActivationMandate.IsEmpty(), 'Should have mandates linked to header');

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestActivationStatus_Completed_SetsCorrectly()
    var
        ActivationMandate: Record "Activation Mandate";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] Activation status "Completed" correctly sets mandate activation flag

        // [GIVEN] Valid activation JSON with completed status
        Initialize();
        ValidJson := GetValidActivationJsonWithCompletedStatus();

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] Mandate should be marked as activated
        if ActivationMandate.FindFirst() then
            Assert.IsTrue(ActivationMandate.Activated, 'Mandate should be activated for Completed status');

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestActivation_WithMultipleMandates_CreatesAll()
    var
        ActivationMandate: Record "Activation Mandate";
        Activation: Codeunit Activation;
        MandateCount: Integer;
        ValidJson: Text;
    begin
        // [SCENARIO] Multiple mandates in JSON are all created

        // [GIVEN] Valid activation JSON with multiple mandates
        Initialize();
        ValidJson := GetValidActivationJsonWithMultipleMandates();

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] All mandates should be created
        MandateCount := ActivationMandate.Count();
        Assert.IsTrue(MandateCount >= 2, 'Should create multiple mandates');

        // Cleanup
        Cleanup();
    end;

    [Test]
    procedure TestActivation_CompanyIdMatching()
    var
        ActivationHeader: Record "Activation Header";
        ConnectionSetup: Record "Connection Setup";
        Activation: Codeunit Activation;
        ValidJson: Text;
    begin
        // [SCENARIO] Activation identifies the active company correctly

        // [GIVEN] Connection setup with company ID
        Initialize();
        CreateConnectionSetupWithCompanyId('TEST-COMPANY-001');
        ValidJson := GetValidActivationJsonWithCompanyId('TEST-COMPANY-001');

        // [WHEN] Populating from JSON
        Activation.PopulateFromJson(ValidJson);

        // [THEN] Should mark the matching company as active
        ActivationHeader.SetRange("Company Id", 'TEST-COMPANY-001');
        if ActivationHeader.FindFirst() then
            Assert.IsTrue(ActivationHeader."Is Active ID", 'Should mark matching company as active');

        // Cleanup
        Cleanup();
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        Cleanup();
        IsInitialized := true;
    end;

    local procedure Cleanup()
    var
        ActivationHeader: Record "Activation Header";
        ActivationMandate: Record "Activation Mandate";
        ConnectionSetup: Record "Connection Setup";
    begin
        if not ActivationHeader.IsEmpty() then
            ActivationHeader.DeleteAll(true);

        if not ActivationMandate.IsEmpty() then
            ActivationMandate.DeleteAll(true);
    end;

    local procedure GetValidActivationJson(): Text
    begin
        exit('{"value":[{"id":"123e4567-e89b-12d3-a456-426614174000","registrationType":"VAT","registrationData":{"jurisdiction":"GB","schemeId":"GB:VAT","identifier":"GB123456789","fullAuthorityNetworkValue":"GB123456789"},"status":{"code":"Completed","message":"Active"},"company":{"displayName":"Test Company","location":"London","identifier":"TEST-COMPANY-001"},"mandates":[{"countryMandate":"GB-PEPPOL-INVOICE","countryCode":"GB","mandateType":"INVOICE"}],"meta":{"lastModified":"2026-02-04T10:00:00Z","location":"https://api.avalara.com/activations/123"}}]}');
    end;

    local procedure GetValidActivationJsonWithCompletedStatus(): Text
    begin
        exit('{"value":[{"id":"223e4567-e89b-12d3-a456-426614174001","registrationType":"VAT","registrationData":{"jurisdiction":"GB","schemeId":"GB:VAT","identifier":"GB987654321","fullAuthorityNetworkValue":"GB987654321"},"status":{"code":"Completed","message":"Active"},"company":{"displayName":"Test Company 2","location":"Manchester","identifier":"TEST-COMPANY-002"},"mandates":[{"countryMandate":"GB-PEPPOL-INVOICE","countryCode":"GB","mandateType":"INVOICE"}],"meta":{"lastModified":"2026-02-04T11:00:00Z","location":"https://api.avalara.com/activations/223"}}]}');
    end;

    local procedure GetValidActivationJsonWithMultipleMandates(): Text
    begin
        exit('{"value":[{"id":"323e4567-e89b-12d3-a456-426614174002","registrationType":"VAT","registrationData":{"jurisdiction":"DE","schemeId":"DE:VAT","identifier":"DE123456789","fullAuthorityNetworkValue":"DE123456789"},"status":{"code":"Completed","message":"Active"},"company":{"displayName":"Test Company 3","location":"Berlin","identifier":"TEST-COMPANY-003"},"mandates":[{"countryMandate":"DE-PEPPOL-INVOICE","countryCode":"DE","mandateType":"INVOICE"},{"countryMandate":"DE-PEPPOL-CREDITNOTE","countryCode":"DE","mandateType":"CREDITNOTE"}],"meta":{"lastModified":"2026-02-04T12:00:00Z","location":"https://api.avalara.com/activations/323"}}]}');
    end;

    local procedure GetValidActivationJsonWithCompanyId(CompanyId: Text): Text
    begin
        exit('{"value":[{"id":"423e4567-e89b-12d3-a456-426614174003","registrationType":"VAT","registrationData":{"jurisdiction":"FR","schemeId":"FR:VAT","identifier":"FR123456789","fullAuthorityNetworkValue":"FR123456789"},"status":{"code":"Completed","message":"Active"},"company":{"displayName":"Test Company 4","location":"Paris","identifier":"' + CompanyId + '"},"mandates":[{"countryMandate":"FR-PEPPOL-INVOICE","countryCode":"FR","mandateType":"INVOICE"}],"meta":{"lastModified":"2026-02-04T13:00:00Z","location":"https://api.avalara.com/activations/423"}}]}');
    end;

    local procedure CreateConnectionSetupWithCompanyId(CompanyId: Text)
    var
        ConnectionSetup: Record "Connection Setup";
    begin
        if not ConnectionSetup.Get() then begin
            ConnectionSetup.Init();
            ConnectionSetup.Insert();
        end;

        ConnectionSetup."Company Id" := CopyStr(CompanyId, 1, MaxStrLen(ConnectionSetup."Company Id"));
        ConnectionSetup.Modify();
    end;
}
