// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Avalara;

using System.Utilities;

codeunit 148193 "Unit Tests - Authentication"
{
    Subtype = Test;
    TestHttpRequestPolicy = AllowOutboundFromHandler;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        IsInitialized: Boolean;

    [Test]
    [HandlerFunctions('HttpAuthSuccessHandler')]
    procedure TestGetAccessToken_FirstTime_Success()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        Token: SecretText;
    begin
        // [SCENARIO] GetAccessToken successfully retrieves token on first call

        // [GIVEN] Connection setup with valid credentials
        Initialize();
        CreateMockConnectionSetup(ConnectionSetup);

        // [WHEN] Getting access token for the first time
        Token := Authenticator.GetAccessToken();

        // [THEN] Token should be returned and stored
        Assert.IsFalse(IsNullGuid(ConnectionSetup."Token - Key"), 'Token key should be stored');
        Assert.AreNotEqual(0DT, ConnectionSetup."Token Expiry", 'Token expiry should be set');
    end;

    [Test]
    [HandlerFunctions('HttpAuthSuccessHandler')]
    procedure TestGetAccessToken_ReuseValidToken()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        OriginalTokenKey: Guid;
        Token1, Token2 : SecretText;
    begin
        // [SCENARIO] GetAccessToken reuses valid token without making new HTTP request

        // [GIVEN] Connection setup with a valid cached token
        Initialize();
        CreateMockConnectionSetup(ConnectionSetup);
        Token1 := Authenticator.GetAccessToken();
        ConnectionSetup.Get();
        OriginalTokenKey := ConnectionSetup."Token - Key";

        // [WHEN] Getting access token again before expiry
        Token2 := Authenticator.GetAccessToken();

        // [THEN] Same token should be reused
        ConnectionSetup.Get();
        Assert.AreEqual(Format(OriginalTokenKey), Format(ConnectionSetup."Token - Key"), 'Token key should be the same');
    end;

    [Test]
    [HandlerFunctions('HttpAuthSuccessHandler')]
    procedure TestGetAccessToken_ExpiredToken_NewTokenObtained()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        Token1, Token2 : SecretText;
    begin
        // [SCENARIO] GetAccessToken obtains new token when cached token is expired

        // [GIVEN] Connection setup with an expired token
        Initialize();
        CreateMockConnectionSetup(ConnectionSetup);
        Token1 := Authenticator.GetAccessToken();
        ConnectionSetup.Get();
        ConnectionSetup."Token Expiry" := CurrentDateTime() - 1000; // Set to past
        ConnectionSetup.Modify();

        // [WHEN] Getting access token after expiry
        Token2 := Authenticator.GetAccessToken();

        // [THEN] New token should be obtained
        ConnectionSetup.Get();
        Assert.IsTrue(ConnectionSetup."Token Expiry" > CurrentDateTime(), 'Token expiry should be in future');
    end;

    [Test]
    procedure TestGetAccessToken_MissingClientId_Error()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        Token: SecretText;
    begin
        // [SCENARIO] GetAccessToken throws error when Client ID is missing

        // [GIVEN] Connection setup without Client ID
        Initialize();
        if not ConnectionSetup.Get() then begin
            Authenticator.CreateConnectionSetupRecord();
            ConnectionSetup.Get();
        end;

        ConnectionSetup."Client Id - Key" := CreateGuid(); // Invalid key
        ConnectionSetup."Client Secret - Key" := CreateGuid(); // Invalid key
        ConnectionSetup.Modify();

        // [WHEN] [THEN] Getting access token should throw error
        asserterror Token := Authenticator.GetAccessToken();
        Assert.ExpectedError('Client Id');
    end;

    [Test]
    procedure TestGetAccessToken_MissingClientSecret_Error()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        KeyGuid: Guid;
        Token: SecretText;
    begin
        // [SCENARIO] GetAccessToken throws error when Client Secret is missing

        // [GIVEN] Connection setup with Client ID but no Client Secret
        Initialize();
        if not ConnectionSetup.Get() then begin
            Authenticator.CreateConnectionSetupRecord();
            ConnectionSetup.Get();
        end;

        Authenticator.SetClientId(KeyGuid, 'test-client-id');
        ConnectionSetup."Client Id - Key" := KeyGuid;
        ConnectionSetup."Client Secret - Key" := CreateGuid(); // Invalid key
        ConnectionSetup.Modify();

        // [WHEN] [THEN] Getting access token should throw error
        asserterror Token := Authenticator.GetAccessToken();
        Assert.ExpectedError('Client Secret');
    end;

    [Test]
    [HandlerFunctions('HttpAuthFailureHandler')]
    procedure TestGetAccessToken_AuthenticationFailure_Error()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        Token: SecretText;
    begin
        // [SCENARIO] GetAccessToken throws error when authentication fails

        // [GIVEN] Connection setup with invalid credentials
        Initialize();
        CreateMockConnectionSetup(ConnectionSetup);

        // [WHEN] [THEN] Getting access token with invalid credentials should throw error
        asserterror Token := Authenticator.GetAccessToken();
    end;

    [Test]
    procedure TestIsClientCredsSet_WithValidCredentials_ReturnsTrue()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        ClientId, ClientSecret : Text;
    begin
        // [SCENARIO] IsClientCredsSet returns true when credentials are set

        // [GIVEN] Connection setup with valid credentials
        Initialize();
        CreateMockConnectionSetup(ConnectionSetup);

        // [WHEN] Checking if credentials are set
        // [THEN] Should return true
        Assert.IsTrue(Authenticator.IsClientCredsSet(ClientId, ClientSecret), 'Should return true with valid credentials');
        Assert.AreNotEqual('', ClientId, 'Client ID should not be empty');
        Assert.AreNotEqual('', ClientSecret, 'Client Secret should not be empty');
    end;

    [Test]
    procedure TestIsClientCredsSet_WithoutCredentials_ReturnsFalse()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
        ClientId, ClientSecret : Text;
    begin
        // [SCENARIO] IsClientCredsSet returns false when credentials are not set

        // [GIVEN] Connection setup without credentials
        Initialize();
        if not ConnectionSetup.Get() then begin
            Authenticator.CreateConnectionSetupRecord();
            ConnectionSetup.Get();
        end;

        // Clear any existing credentials
        if not IsNullGuid(ConnectionSetup."Client Id - Key") then
            IsolatedStorage.Delete(ConnectionSetup."Client Id - Key", DataScope::Company);
        if not IsNullGuid(ConnectionSetup."Client Secret - Key") then
            IsolatedStorage.Delete(ConnectionSetup."Client Secret - Key", DataScope::Company);

        // [WHEN] Checking if credentials are set
        // [THEN] Should return false
        Assert.IsFalse(Authenticator.IsClientCredsSet(ClientId, ClientSecret), 'Should return false without credentials');
    end;

    [Test]
    procedure TestCreateConnectionSetupRecord_CreatesRecord()
    var
        ConnectionSetup: Record "Connection Setup";
        Authenticator: Codeunit Authenticator;
    begin
        // [SCENARIO] CreateConnectionSetupRecord creates connection setup with default values

        // [GIVEN] No connection setup exists
        Initialize();
        if ConnectionSetup.Get() then
            ConnectionSetup.Delete();

        // [WHEN] Creating connection setup record
        Authenticator.CreateConnectionSetupRecord();

        // [THEN] Record should exist with default URLs
        Assert.IsTrue(ConnectionSetup.Get(), 'Connection setup should exist');
        Assert.AreNotEqual('', ConnectionSetup."API URL", 'API URL should be set');
        Assert.AreNotEqual('', ConnectionSetup."Authentication URL", 'Auth URL should be set');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    local procedure CreateMockConnectionSetup(var ConnectionSetup: Record "Connection Setup")
    var
        AvalaraAuth: Codeunit Authenticator;
        KeyGuid: Guid;
    begin
        if not ConnectionSetup.Get() then begin
            AvalaraAuth.CreateConnectionSetupRecord();
            ConnectionSetup.Get();
        end;

        AvalaraAuth.SetClientId(KeyGuid, 'mock-client-id');
        ConnectionSetup."Client Id - Key" := KeyGuid;
        AvalaraAuth.SetClientSecret(KeyGuid, 'mock-client-secret');
        ConnectionSetup."Client Secret - Key" := KeyGuid;
        ConnectionSetup.Modify(true);
    end;

    [HttpClientHandler]
    internal procedure HttpAuthSuccessHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ResponseText: Text;
    begin
        ResponseText := '{"access_token":"mock-access-token-12345","token_type":"Bearer","expires_in":3600}';
        Response.Content.WriteFrom(ResponseText);
        Response.HttpStatusCode := 200;
    end;

    [HttpClientHandler]
    internal procedure HttpAuthFailureHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    var
        ResponseText: Text;
    begin
        ResponseText := '{"error":"invalid_client","error_description":"Invalid client credentials"}';
        Response.Content.WriteFrom(ResponseText);
        Response.HttpStatusCode := 401;
    end;
}
