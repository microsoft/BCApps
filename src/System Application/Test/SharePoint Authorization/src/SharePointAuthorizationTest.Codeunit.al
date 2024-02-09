// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.Integration.Sharepoint;
using System.TestLibraries.Utilities;

codeunit 132977 "SharePoint Authorization Test"
{
    Subtype = Test;

    var
        SharePointAuthSubscription: Codeunit "SharePoint Auth. Subscription";
        Assert: Codeunit "Library Assert";
        Any: Codeunit Any;
        IsInitialized: Boolean;

    [Test]
    procedure TestAuthorizationCodeAuthorization()
    var
        SharepointAuth: Codeunit "SharePoint Auth.";
        HttpRequestMessage: HttpRequestMessage;
        HttpHeaders: HttpHeaders;
        SecretValues: array[100] of SecretText;
        SharepointAuthorization: Interface "SharePoint Authorization";
    begin
        // [Scenario] Request is succesfully authorized with authorization code
        Initialize();

        SharePointAuthSubscription.SetParameters(false, '');
        SharepointAuthorization := SharepointAuth.CreateAuthorizationCode(CreateGuid(), Any.AlphanumericText(10), GetClientSecret(), Any.AlphabeticText(20));
        SharepointAuthorization.Authorize(HttpRequestMessage);
        HttpRequestMessage.GetHeaders(HttpHeaders);
        Assert.IsTrue(HttpHeaders.GetSecretValues('Authorization', SecretValues), 'Authorization header expected');
        CheckAuthorizationHeader(SecretValues[1]);
    end;

    [Test]
    procedure TestAuthorizationCodeAuthorizationFail()
    var
        SharepointAuth: Codeunit "SharePoint Auth.";
        HttpRequestMessage: HttpRequestMessage;
        SharepointAuthorization: Interface "SharePoint Authorization";
        ErrorText: Text;
    begin
        // [Scenario] Request is succesfully authorized with authorization code
        Initialize();
        ErrorText := Any.AlphanumericText(50);
        SharePointAuthSubscription.SetParameters(true, ErrorText);
        SharepointAuthorization := SharepointAuth.CreateAuthorizationCode(CreateGuid(), Any.AlphanumericText(10), GetClientSecret(), Any.AlphabeticText(20));
        asserterror SharepointAuthorization.Authorize(HttpRequestMessage);

        Assert.AreEqual(ErrorText, GetLastErrorText(), 'Error expected');
    end;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
        BindSubscription(SharePointAuthSubscription);
    end;

    local procedure GetClientSecret(): SecretText
    begin
        exit(Any.AlphabeticText(20));
    end;

    [NonDebuggable]
    local procedure CheckAuthorizationHeader(Value: SecretText): Boolean
    begin
        Assert.IsTrue(Value.Unwrap().StartsWith('Bearer '), 'Incorrect header value');
        Assert.IsTrue(StrLen(Value.Unwrap().Remove(1, StrLen('Bearer '))) > 0, 'Missing token');
    end;
}