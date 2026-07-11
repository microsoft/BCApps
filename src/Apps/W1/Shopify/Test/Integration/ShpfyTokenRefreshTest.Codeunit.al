// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace Microsoft.Integration.Shopify.Test;

using Microsoft.Integration.Shopify;
using System.TestLibraries.Utilities;

codeunit 139635 "Shpfy Token Refresh Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        LibraryAssert: Codeunit "Library Assert";
        Any: Codeunit Any;
        StoreTok: Label 'shpfytokentest.myshopify.com', Locked = true;

    [Test]
    procedure RefreshTokenRoundTrips()
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
    begin
        // [SCENARIO] A refresh token stored for a registered store can be retrieved.
        // [GIVEN] A registered store with a stored refresh token.
        SetupStore(RegisteredStoreNew, true, DaysFromNow(1));

        // [THEN] The refresh token is present.
        LibraryAssert.IsTrue(RegisteredStoreNew.HasRefreshToken(), 'Refresh token should be stored.');
        LibraryAssert.IsFalse(RegisteredStoreNew.GetRefreshToken().IsEmpty(), 'Refresh token should not be empty.');
    end;

    [Test]
    procedure IsRefreshTokenExpiredFalseWhenNoRefreshToken()
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
    begin
        // [SCENARIO] A legacy non-expiring token (no refresh token) is never reported as expired.
        // [GIVEN] A registered store without a refresh token, even with a past refresh expiry.
        SetupStore(RegisteredStoreNew, false, DaysFromNow(-1));

        // [THEN] The refresh token is not considered expired.
        LibraryAssert.IsFalse(AuthenticationMgt.IsRefreshTokenExpired(StoreTok), 'A store without a refresh token must not be reported as expired.');
    end;

    [Test]
    procedure IsRefreshTokenExpiredTrueWhenExpired()
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
    begin
        // [SCENARIO] An expiring token whose refresh token lifetime has passed is reported as expired.
        // [GIVEN] A registered store with a refresh token and a refresh expiry in the past.
        SetupStore(RegisteredStoreNew, true, DaysFromNow(-1));

        // [THEN] The refresh token is considered expired.
        LibraryAssert.IsTrue(AuthenticationMgt.IsRefreshTokenExpired(StoreTok), 'An expired refresh token must be reported as expired.');
    end;

    [Test]
    procedure IsRefreshTokenExpiredFalseWhenValid()
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
    begin
        // [SCENARIO] An expiring token whose refresh token is still within its lifetime is not expired.
        // [GIVEN] A registered store with a refresh token and a refresh expiry in the future.
        SetupStore(RegisteredStoreNew, true, DaysFromNow(30));

        // [THEN] The refresh token is not considered expired.
        LibraryAssert.IsFalse(AuthenticationMgt.IsRefreshTokenExpired(StoreTok), 'A valid refresh token must not be reported as expired.');
    end;

    [Test]
    procedure IsRefreshTokenExpiredFalseWhenExpiryUnknown()
    var
        RegisteredStoreNew: Record "Shpfy Registered Store New";
        AuthenticationMgt: Codeunit "Shpfy Authentication Mgt.";
    begin
        // [SCENARIO] A refresh token with no recorded expiry is not reported as expired.
        // [GIVEN] A registered store with a refresh token but a blank refresh expiry.
        SetupStore(RegisteredStoreNew, true, 0DT);

        // [THEN] The refresh token is not considered expired.
        LibraryAssert.IsFalse(AuthenticationMgt.IsRefreshTokenExpired(StoreTok), 'A refresh token with no recorded expiry must not be reported as expired.');
    end;

    local procedure SetupStore(var RegisteredStoreNew: Record "Shpfy Registered Store New"; SetRefresh: Boolean; RefreshExpiresAt: DateTime)
    var
        RefreshToken: SecretText;
    begin
        if RegisteredStoreNew.Get(StoreTok) then
            RegisteredStoreNew.Delete();
        RegisteredStoreNew.Init();
        RegisteredStoreNew.Store := CopyStr(StoreTok, 1, MaxStrLen(RegisteredStoreNew.Store));
        RegisteredStoreNew."Refresh Token Expires At" := RefreshExpiresAt;
        RegisteredStoreNew.Insert();
        if SetRefresh then begin
            RefreshToken := Any.AlphanumericText(20);
            RegisteredStoreNew.SetRefreshToken(RefreshToken);
        end;
    end;

    local procedure DaysFromNow(Days: Integer) Result: DateTime
    var
        Milliseconds: BigInteger;
        Offset: Duration;
    begin
        Milliseconds := Days;
        Milliseconds := Milliseconds * 24 * 60 * 60 * 1000;
        Offset := Milliseconds;
        exit(CurrentDateTime() + Offset);
    end;
}
