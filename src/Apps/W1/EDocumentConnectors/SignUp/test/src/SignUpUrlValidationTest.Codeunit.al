// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.SignUp;

/// <summary>
/// Unit tests for the SignUp Service URL validation. The stored Service URL is used only when its
/// host and scheme match the hardcoded service endpoint; otherwise it falls back to the hardcoded
/// value so credentials/traffic cannot be redirected to a malicious endpoint.
/// </summary>
codeunit 148206 "SignUp Url Validation Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;
    Permissions = tabledata "SignUp Connection Setup" = rimd;

    [Test]
    procedure ServiceUrlSameHostIsKept()
    var
        SignUpAuthentication: Codeunit "SignUp Authentication";
    begin
        // [GIVEN] A stored Service URL on the expected service host
        InitSetup('https://edoc.exflow.io/api/v2/Peppol');

        // [THEN] The same-host value is returned unchanged
        Assert.AreEqual('https://edoc.exflow.io/api/v2/Peppol', SignUpAuthentication.GetServiceUrl(), SameHostMsg);
    end;

    [Test]
    procedure ServiceUrlForeignHostFallsBack()
    var
        SignUpAuthentication: Codeunit "SignUp Authentication";
    begin
        // [GIVEN] A tampered Service URL on a foreign host
        InitSetup('https://malicious.example.com');

        // [THEN] Validation falls back to the hardcoded service URL
        Assert.AreEqual('https://edoc.exflow.io', SignUpAuthentication.GetServiceUrl(), FallbackMsg);
    end;

    [Test]
    procedure ServiceUrlSchemeDowngradeFallsBack()
    var
        SignUpAuthentication: Codeunit "SignUp Authentication";
    begin
        // [GIVEN] A Service URL downgraded to http on the correct host
        InitSetup('http://edoc.exflow.io');

        // [THEN] Validation falls back to the hardcoded https service URL instead of allowing cleartext
        Assert.AreEqual('https://edoc.exflow.io', SignUpAuthentication.GetServiceUrl(), DowngradeMsg);
    end;

    local procedure InitSetup(ServiceUrl: Text)
    var
        SignUpConnectionSetup: Record "SignUp Connection Setup";
    begin
        if SignUpConnectionSetup.Get() then
            SignUpConnectionSetup.Delete();
        SignUpConnectionSetup.Init();
        SignUpConnectionSetup."Service URL" := CopyStr(ServiceUrl, 1, MaxStrLen(SignUpConnectionSetup."Service URL"));
        SignUpConnectionSetup.Insert();
    end;

    var
        Assert: Codeunit Assert;
        SameHostMsg: Label 'A same-host URL should be returned unchanged.';
        FallbackMsg: Label 'A different-host URL should fall back to the hardcoded value.';
        DowngradeMsg: Label 'An http downgrade should fall back to the hardcoded https URL.';
}
