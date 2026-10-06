// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

codeunit 139497 "Web Service Key Auth Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    RequiredTestIsolation = Disabled;

    var
        FixtureUser: Record User;
        Assert: Codeunit Assert;
        LibraryPermissions: Codeunit "Library - Permissions";
        WebServiceManagement: Codeunit "Web Service Management";
        IdentityManagement: Codeunit "Identity Management";
        Base64Convert: Codeunit "Base64 Convert";
        FixturePassword: SecretText;
        ServiceName: Text;
        ResponseText: Text;
        ResponseStatus: Integer;

    [Test]
    procedure MissingKeyAuthenticatesAnotherHttpSession()
    var
        RequestSucceeded: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] A missing key changes HTTP 401 to 200 and has a bounded expiry.
        Initialize();

        // [GIVEN] Disposable user "U" without a key, in a committed fixture.
        CreateFixture();
        Commit();

        // [WHEN] A separate session configures the provider and sends real OData requests.
        RequestSucceeded := TryRunScenario('Missing', '');
        DeleteFixture();
        Commit();

        // [THEN] Authentication and the 24-hour expiry were verified in that session.
        VerifySuccessfulScenario(RequestSucceeded);
    end;

    [Test]
    procedure RepeatedRequestsReuseKey()
    var
        RequestSucceeded: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] Repeated requests through the same Graph instance reuse the key.
        Initialize();

        // [GIVEN] Disposable user "U" with no pre-existing integration credential.
        CreateFixture();
        Commit();

        // [WHEN] The same Graph instance authenticates twice.
        RequestSucceeded := TryRunScenario('Repeated', '');
        DeleteFixture();
        Commit();

        // [THEN] Both requests returned 200 without changing the key.
        VerifySuccessfulScenario(RequestSucceeded);
    end;

    [Test]
    procedure SecondInstanceDoesNotInvalidateFirst()
    var
        RequestSucceeded: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] A second Graph instance preserves the first instance's credential.
        Initialize();

        // [GIVEN] Disposable user "U" and two independent Graph instances.
        CreateFixture();
        Commit();

        // [WHEN] Requests use the first, second, and first instances in that order.
        RequestSucceeded := TryRunScenario('SecondInstance', '');
        DeleteFixture();
        Commit();

        // [THEN] Every authenticated request returned 200 and the key was unchanged.
        VerifySuccessfulScenario(RequestSucceeded);
    end;

    [Test]
    procedure ExistingValidExpiringKeyIsPreserved()
    var
        RequestSucceeded: Boolean;
        ExistingKey: SecretText;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] The provider preserves an existing valid key and its expiry.
        Initialize();

        // [GIVEN] Disposable user "U" with an existing two-hour key.
        CreateFixture();
        ExistingKey := IdentityManagement.CreateWebServicesKey(FixtureUser."User Security ID", CurrentDateTime() + 2 * 60 * 60 * 1000);
        Clear(ExistingKey);
        Commit();

        // [WHEN] A new provider instance authenticates as "U".
        RequestSucceeded := TryRunScenario('Existing', '');
        DeleteFixture();
        Commit();

        // [THEN] Authentication succeeded without replacing the key or extending its expiry.
        VerifySuccessfulScenario(RequestSucceeded);
    end;

    [Test]
    procedure ExpiredKeyFailsExplicitly()
    var
        RequestSucceeded: Boolean;
        ExistingKey: SecretText;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] An expired credential causes an explicit error instead of rotation.
        Initialize();

        // [GIVEN] Disposable user "U" whose existing key expires before the request.
        CreateFixture();
        ExistingKey := IdentityManagement.CreateWebServicesKey(FixtureUser."User Security ID", CurrentDateTime() + 1000);
        Clear(ExistingKey);
        Commit();
        Sleep(1100);

        // [WHEN] The provider tries to configure authentication.
        RequestSucceeded := TryRunScenario('Expired', '');
        DeleteFixture();
        Commit();

        // [THEN] SOAP reports the explicit provider error, not an HTTP credential fallback.
        VerifyFailedScenario(RequestSucceeded, 'The current user web service key has expired.');
    end;

    [Test]
    procedure KeyCreationDoesNotCommitBusinessData()
    var
        CountryRegion: Record "Country/Region";
        MarkerCode: Code[10];
        RequestSucceeded: Boolean;
        MarkerWasCommitted: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] Creating a key must not implicitly commit the caller's transaction.
        Initialize();

        // [GIVEN] Disposable user "U" and an unused transaction marker.
        CreateFixture();
        MarkerCode := CopyStr(DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(MarkerCode));
        Assert.IsFalse(CountryRegion.Get(MarkerCode), 'The transaction marker must not already exist.');
        Commit();

        // [WHEN] Another session inserts the marker, configures the provider, and raises an error.
        RequestSucceeded := TryRunScenario('Rollback', MarkerCode);
        MarkerWasCommitted := CountryRegion.Get(MarkerCode);
        CountryRegion.SetRange(Code, MarkerCode);
        CountryRegion.DeleteAll();
        DeleteFixture();
        Commit();

        // [THEN] The deliberate error rolled back the marker despite key creation.
        VerifyFailedScenario(RequestSucceeded, 'Web service key rollback probe.');
        Assert.IsFalse(MarkerWasCommitted, 'Key creation must not commit business data.');
    end;

    [Test]
    procedure SelectingNoneRestoresUnauthenticatedRequests()
    var
        RequestSucceeded: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] Selecting None after Microsoft authentication restores HTTP 401.
        Initialize();

        // [GIVEN] Disposable user "U" and the default provider.
        CreateFixture();
        Commit();

        // [WHEN] The session selects Microsoft authentication and then None.
        RequestSucceeded := TryRunScenario('None', '');
        DeleteFixture();
        Commit();

        // [THEN] The response sequence was 401, 200, 401.
        VerifySuccessfulScenario(RequestSucceeded);
    end;

    [Test]
    [NonDebuggable]
    procedure PublicKeyGetterSignalsUnknownUserFailure()
    var
        User: Record User;
        UnknownUserId: Guid;
        ErrorWasReported: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] The public key getter reports a failed lookup through fresh AL last-error state.
        Initialize();

        // [GIVEN] User "U" does not exist and the previous error state is cleared.
        UnknownUserId := CreateGuid();
        Assert.IsFalse(User.Get(UnknownUserId), 'The failure probe must use a nonexistent user.');
        ClearLastError();

        // [WHEN] The public getter cannot retrieve a key for "U".
        IdentityManagement.GetWebServicesKey(UnknownUserId);
        ErrorWasReported := GetLastErrorText() <> '';
        ClearLastError();

        // [THEN] Failure is detectable without interpreting the returned text as a credential.
        Assert.IsTrue(ErrorWasReported, 'A failed public key lookup must set AL last-error state; otherwise this provider design is blocked.');
    end;

    [Test]
    procedure PublicExpiryGetterSignalsUnknownUserFailure()
    var
        User: Record User;
        UnknownUserId: Guid;
        ErrorWasReported: Boolean;
    begin
        // [FEATURE] [AI test 1.0]
        // [SCENARIO 646383] The public expiry getter reports failure despite returning a fallback date.
        Initialize();

        // [GIVEN] User "U" does not exist and the previous error state is cleared.
        UnknownUserId := CreateGuid();
        Assert.IsFalse(User.Get(UnknownUserId), 'The failure probe must use a nonexistent user.');
        ClearLastError();

        // [WHEN] The public getter cannot retrieve the expiry for "U".
        IdentityManagement.GetWebServiceExpiryDate(UnknownUserId);
        ErrorWasReported := GetLastErrorText() <> '';
        ClearLastError();

        // [THEN] Failure is detectable without relying on the fallback date or localized error text.
        Assert.IsTrue(ErrorWasReported, 'A failed public expiry lookup must set AL last-error state; otherwise this provider design is blocked.');
    end;

    local procedure Initialize()
    var
        EnvironmentInfo: Codeunit "Environment Information";
    begin
        Assert.IsFalse(EnvironmentInfo.IsSaaSInfrastructure(), 'These HTTP proofs require a disposable OnPrem CI container.');
        Assert.IsTrue(IdentityManagement.IsUserNamePasswordAuthentication(), 'These HTTP proofs require NavUserPassword; Windows is not a passing substitute.');
        Clear(FixtureUser);
        Clear(FixturePassword);
        Clear(ResponseText);
        Clear(ResponseStatus);
    end;

    [NonDebuggable]
    local procedure CreateFixture()
    var
        TenantWebService: Record "Tenant Web Service";
        PasswordText: Text;
        UserName: Text[50];
    begin
        UserName := CopyStr('WEBKEYTEST-' + DelChr(Format(CreateGuid()), '=', '{}-'), 1, MaxStrLen(UserName));
        LibraryPermissions.CreateUser(FixtureUser, UserName, false);
        LibraryPermissions.AddPermissionSetNameToUser(FixtureUser."User Security ID", 'SUPER', '');
        PasswordText := 'Aa1!' + Format(CreateGuid());
        FixturePassword := PasswordText;
        SetUserPassword(FixtureUser."User Security ID", PasswordText);
        Clear(PasswordText);
        ServiceName := DelChr(Format(CreateGuid()), '=', '{}-');
        WebServiceManagement.CreateTenantWebService(TenantWebService."Object Type"::Codeunit, Codeunit::"Web Service Key Auth Probe", ServiceName, true);
    end;

    [TryFunction]
    local procedure TryRunScenario(Scenario: Text; MarkerCode: Code[10])
    var
        TenantWebService: Record "Tenant Web Service";
        Client: HttpClient;
        Request: HttpRequestMessage;
        Response: HttpResponseMessage;
        Content: HttpContent;
        Headers: HttpHeaders;
    begin
        Content.WriteFrom(
            '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/"><s:Body>' +
            '<RunScenario xmlns="urn:microsoft-dynamics-schemas/codeunit/' + ServiceName + '">' +
            '<scenario>' + Scenario + '</scenario><markerCode>' + MarkerCode + '</markerCode>' +
            '</RunScenario></s:Body></s:Envelope>');
        Content.GetHeaders(Headers);
        Headers.Clear();
        Headers.Add('Content-Type', 'text/xml; charset=utf-8');
        Request.Content := Content;
        Request.Method := 'POST';
        TenantWebService.Get(TenantWebService."Object Type"::Codeunit, ServiceName);
        Request.SetRequestUri(GetUrl(ClientType::SOAP, CompanyName(), ObjectType::Codeunit, Codeunit::"Web Service Key Auth Probe", TenantWebService));
        Request.GetHeaders(Headers);
        Headers.Add('SOAPAction', 'urn:microsoft-dynamics-schemas/codeunit/' + ServiceName + ':RunScenario');
        Headers.Add('Authorization', SecretStrSubstNo('Basic %1', Base64Convert.ToBase64(SecretStrSubstNo('%1:%2', FixtureUser."User Name", FixturePassword))));
        if not Client.Send(Request, Response) then
            Error('The disposable web service key probe could not be reached.');
        ResponseStatus := Response.HttpStatusCode();
        Response.Content.ReadAs(ResponseText);
    end;

    local procedure DeleteFixture()
    var
        TenantWebService: Record "Tenant Web Service";
        AccessControl: Record "Access Control";
    begin
        TenantWebService.SetRange("Object Type", TenantWebService."Object Type"::Codeunit);
        TenantWebService.SetRange("Service Name", ServiceName);
        TenantWebService.DeleteAll(true);
        AccessControl.SetRange("User Security ID", FixtureUser."User Security ID");
        AccessControl.DeleteAll(true);
        // Password/key operations can update the user through another record buffer or session.
        FixtureUser.Get(FixtureUser."User Security ID");
        FixtureUser.Delete(true);
        Clear(FixturePassword);
    end;

    local procedure VerifySuccessfulScenario(RequestSucceeded: Boolean)
    var
        ResponseDocument: XmlDocument;
        ResultNode: XmlNode;
    begin
        Assert.IsTrue(RequestSucceeded, 'The disposable SOAP probe must return a response.');
        Assert.AreEqual(200, ResponseStatus, 'The SOAP probe must complete all HTTP and key assertions.');
        Assert.IsTrue(XmlDocument.ReadFrom(ResponseText, ResponseDocument), 'The SOAP response must be XML.');
        Assert.IsTrue(ResponseDocument.SelectSingleNode('//*[local-name()="return_value"]', ResultNode), 'The probe must return a result.');
        Assert.AreEqual('true', ResultNode.AsXmlElement().InnerText(), 'The probe must confirm success.');
    end;

    local procedure VerifyFailedScenario(RequestSucceeded: Boolean; ExpectedError: Text)
    begin
        Assert.IsTrue(RequestSucceeded, 'The disposable SOAP probe must return an error response.');
        Assert.AreEqual(500, ResponseStatus, 'The probe must return a SOAP fault.');
        Assert.IsTrue(ResponseText.Contains(ExpectedError), 'The SOAP fault must contain the expected explicit error.');
    end;
}
