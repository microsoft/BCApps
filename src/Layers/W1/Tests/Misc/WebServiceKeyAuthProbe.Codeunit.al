// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

codeunit 139498 "Web Service Key Auth Probe"
{
    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        SecondLibraryGraphMgt: Codeunit "Library - Graph Mgt";
        IdentityManagement: Codeunit "Identity Management";

    // Published only by the fixture, which authenticates as its newly created disposable user.
    procedure RunScenario(Scenario: Text; MarkerCode: Code[10]): Boolean
    var
        CountryRegion: Record "Country/Region";
        HttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        OriginalKey: SecretText;
        OriginalExpiry: DateTime;
        StartedAt: DateTime;
    begin
        Assert.IsTrue(CopyStr(UserId(), 1, 11) = 'WEBKEYTEST-', 'The probe requires its disposable fixture user.');
        Assert.IsTrue(IdentityManagement.IsUserNamePasswordAuthentication(), 'The probe requires NavUserPassword.');
        Clear(LibraryGraphMgt);
        Clear(SecondLibraryGraphMgt);

        if Scenario = 'Rollback' then begin
            CountryRegion.Init();
            CountryRegion.Code := MarkerCode;
            CountryRegion.Insert();
            LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::"Microsoft Test Environment");
            LibraryGraphMgt.InitializeWebRequestWithURL(HttpWebRequestMgt, GetUrl(ClientType::ODataV4));
            Error('Web service key rollback probe.');
        end;

        OriginalKey := ReadKey();
        OriginalExpiry := IdentityManagement.GetWebServiceExpiryDate(UserSecurityId());
        StartedAt := CurrentDateTime();
        if Scenario <> 'Existing' then
            if Scenario <> 'Expired' then
                Assert.IsTrue(OriginalKey.IsEmpty(), 'The fixture must start without a web service key.');

        VerifyResponse(LibraryGraphMgt, 401);
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::"Microsoft Test Environment");
        VerifyResponse(LibraryGraphMgt, 200);

        case Scenario of
            'Missing':
                VerifyBoundedExpiry(StartedAt);
            'Repeated':
                begin
                    OriginalKey := ReadKey();
                    VerifyResponse(LibraryGraphMgt, 200);
                    VerifyKeyUnchanged(OriginalKey);
                end;
            'SecondInstance':
                begin
                    OriginalKey := ReadKey();
                    SecondLibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::"Microsoft Test Environment");
                    VerifyResponse(SecondLibraryGraphMgt, 200);
                    VerifyResponse(LibraryGraphMgt, 200);
                    VerifyKeyUnchanged(OriginalKey);
                end;
            'Existing':
                begin
                    VerifyKeyUnchanged(OriginalKey);
                    Assert.AreEqual(OriginalExpiry, IdentityManagement.GetWebServiceExpiryDate(UserSecurityId()), 'An existing expiry must not change.');
                end;
            'None':
                begin
                    LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::None);
                    VerifyResponse(LibraryGraphMgt, 401);
                end;
            else
                Error('Unexpected web service key probe scenario.');
        end;
        exit(true);
    end;

    local procedure VerifyResponse(var GraphMgt: Codeunit "Library - Graph Mgt"; ExpectedStatus: Integer)
    var
        ResponseText: Text;
    begin
        GraphMgt.GetFromWebServiceAndCheckResponseCode(ResponseText, GetUrl(ClientType::ODataV4), ExpectedStatus);
    end;

    [NonDebuggable]
    local procedure ReadKey(): SecretText
    begin
        exit(IdentityManagement.GetWebServicesKey(UserSecurityId()));
    end;

    [NonDebuggable]
    local procedure VerifyKeyUnchanged(OriginalKey: SecretText)
    var
        CurrentKey: SecretText;
    begin
        CurrentKey := ReadKey();
        Assert.IsTrue(OriginalKey.Unwrap() = CurrentKey.Unwrap(), 'The provider must preserve the existing key.');
    end;

    local procedure VerifyBoundedExpiry(StartedAt: DateTime)
    var
        ExpiryDate: DateTime;
    begin
        ExpiryDate := IdentityManagement.GetWebServiceExpiryDate(UserSecurityId());
        Assert.IsTrue(ExpiryDate >= StartedAt + 24 * 60 * 60 * 1000, 'A new key must expire 24 hours after creation.');
        Assert.IsTrue(ExpiryDate <= CurrentDateTime() + 24 * 60 * 60 * 1000, 'A new key must not be non-expiring.');
    end;
}
