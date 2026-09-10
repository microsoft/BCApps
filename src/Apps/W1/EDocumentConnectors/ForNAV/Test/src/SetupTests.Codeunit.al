// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.ForNAV;

using System.Environment;
using System.Utilities;

codeunit 148222 "Setup Tests"
{
    Subtype = Test;

    // Covers the endpoint setup/swap flow (SetupOauth), the UTC secret-expiry checks, and the
    // background secret rotation path (GetNewSecurityKey) flagged as untested in the PR #9370
    // review. All outbound HTTP is mocked via "ForNAV Peppol Test" - see its OnBeforeSendRaw /
    // OnBeforeSendTokenRequest / OnBeforeSend subscribers - so none of this needs a real
    // FORNAV Peppol Network endpoint or Azure AD token endpoint to run.

    [Test]
    procedure SetupOauth_SameEndpointStillValid_SkipsFullSetup()
    var
        Setup: Record "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        Initialize();

        // [Given] A client id and a still-valid secret already registered for the current endpoint
        PeppolOauth.ValidateClientID('CACHEDCLIENT');
        PeppolOauth.ValidateSecretValidTo(CreateDateTime(Today + 30, 120000T));

        Setup.FindFirst();
        Setup.Endpoint := 'v2';
        Setup.Modify();

        // Any attempt to (re)request setup from the network fails loudly, so the test fails
        // instead of silently passing if the cached-authorization short-circuit regresses.
        Test.SetSetupRequestStatusCode(0);

        // [When] Setting up again for the same endpoint
        Setup.SetupOauth('v2');

        // [Then] The existing authorization is reused; no new setup request was needed
        Assert.IsTrue(Setup.Authorized, 'Setup should stay authorized when the endpoint is unchanged and the secret is still valid');
        Assert.AreEqual('v2', Setup.Endpoint, 'Endpoint should be unchanged');
    end;

    [Test]
    procedure SetupOauth_NewEndpoint_RequestsSetup()
    var
        EnvironmentInformation: Codeunit "Environment Information";
        Setup: Record "ForNAV Peppol Setup";
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
    begin
        Initialize();

        // The non-cached setup flow only runs on SaaS (SetupOauth fails fast otherwise, see
        // fix for PR #9370 S3); in an on-premises test environment there is nothing further to
        // verify here.
        if not EnvironmentInformation.IsSaaSInfrastructure() then
            exit;

        // [Given] An existing authorization for a different endpoint
        PeppolOauth.ValidateClientID('OLDCLIENT');
        PeppolOauth.ValidateSecretValidTo(CreateDateTime(Today + 30, 120000T));

        Setup.FindFirst();
        Setup.Endpoint := 'v1';
        Setup.Modify();

        Test.SetSetupRequestStatusCode(204);

        // [When] Setting up for a new endpoint
        Setup.SetupOauth('v2');

        // [Then] A new setup request was sent for the new endpoint
        Assert.AreEqual('v2', Setup.Endpoint, 'Endpoint should be updated to the newly requested one');
        Assert.AreEqual(Today, Setup."Oauth Setup Request Sent", 'A new setup request should have been recorded as sent today');

        // [Then] Authorization is not granted synchronously - the new client id/secret are
        // delivered asynchronously after the request is accepted, so client id is reset in the
        // meantime, and validation of the (now blank) client id fails gracefully.
        Assert.IsFalse(Setup.Authorized, 'Setup should not be authorized until credentials for the new endpoint are delivered');
    end;

    [Test]
    procedure SecretValidTo_LocalConversion_DoesNotAffectStoredUtcValue()
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
        TypeHelper: Codeunit "Type Helper";
        TimeZoneOffset: Duration;
        StoredValidTo: DateTime;
    begin
        Initialize();

        // [Given] A secret expiry stored in UTC
        StoredValidTo := CreateDateTime(Today + 30, 120000T);
        PeppolOauth.ValidateSecretValidTo(StoredValidTo);

        // [Then] The value used for expiry logic is returned exactly as stored, never shifted
        Assert.AreEqual(StoredValidTo, PeppolOauth.GetSecretValidTo(), 'GetSecretValidTo must return the stored value unshifted by the user''s timezone');

        // [Then] Only the *Local variant applies the user's timezone offset, and only for display
        if not TypeHelper.GetUserTimezoneOffset(TimeZoneOffset) then
            Clear(TimeZoneOffset);

        Assert.AreEqual(StoredValidTo + TimeZoneOffset, PeppolOauth.GetSecretValidToLocal(), 'GetSecretValidToLocal must shift the stored value by the user''s timezone offset');
    end;

    [Test]
    procedure GetNewSecurityKey_RotatesSecretFromMockedResponse()
    var
        PeppolOauth: Codeunit "ForNAV Peppol Oauth";
        NewValidTo: DateTime;
    begin
        Initialize();

        // [Given] A client id and a mocked RotateSecret response with a new secret/expiry
        PeppolOauth.ValidateClientID('ROTATECLIENT');
        NewValidTo := CreateDateTime(Today + 90, 120000T);
        Test.SetRotatedSecret('rotatedsecret', NewValidTo);

        // [When] Requesting a new security key (the background rotation path)
        Assert.IsTrue(PeppolOauth.GetNewSecurityKey(), 'Rotation should succeed against the mocked RotateSecret endpoint');

        // [Then] The rotated secret''s expiry from the response is persisted
        Assert.AreEqual(NewValidTo, PeppolOauth.GetSecretValidTo(), 'New secret expiry from the mocked response should be persisted');
    end;

    local procedure Initialize()
    begin
        LibraryPermission.SetOutsideO365Scope();

        if IsInitialized then
            exit;

        Test.Init();
        IsInitialized := true;
    end;

    var
        LibraryPermission: Codeunit "Library - Lower Permissions";
        Assert: Codeunit Assert;
        Test: Codeunit "ForNAV Peppol Test";
        IsInitialized: Boolean;
}
