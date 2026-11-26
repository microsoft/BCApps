// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Logiq;

/// <summary>
/// Unit tests for the Logiq integration URL validation. The stored authentication/base URL is used
/// only when its host (and scheme) match the hardcoded endpoint for the selected environment;
/// otherwise it falls back to the hardcoded value so credentials/traffic cannot be redirected.
/// </summary>
codeunit 139781 "Logiq Url Validation Test"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    [Test]
    procedure ProductionAuthUrlSameHostIsKept()
    var
        Setup: Record "Logiq Connection Setup";
    begin
        // [GIVEN] Production environment and an Authentication URL on the production Logiq host
        Setup.Init();
        Setup.Environment := Setup.Environment::Production;
        Setup."Authentication URL" := 'https://sso.logiq.no/auth/realms/other/token';

        // [THEN] The same-host value is returned unchanged
        Assert.AreEqual('https://sso.logiq.no/auth/realms/other/token', Setup.GetValidatedAuthenticationUrl(), SameHostMsg);
    end;

    [Test]
    procedure ProductionAuthUrlForeignHostFallsBack()
    var
        Setup: Record "Logiq Connection Setup";
    begin
        // [GIVEN] Production environment and a tampered Authentication URL on a foreign host
        Setup.Init();
        Setup.Environment := Setup.Environment::Production;
        Setup."Authentication URL" := 'https://malicious.example.com/token';

        // [THEN] Validation falls back to the hardcoded production authentication URL
        Assert.AreEqual('https://sso.logiq.no/auth/realms/connect-api/protocol/openid-connect/token', Setup.GetValidatedAuthenticationUrl(), FallbackMsg);
    end;

    [Test]
    procedure PilotEnvironmentRejectsProductionHost()
    var
        Setup: Record "Logiq Connection Setup";
    begin
        // [GIVEN] Pilot environment but an Authentication URL pointing at the production host
        Setup.Init();
        Setup.Environment := Setup.Environment::Pilot;
        Setup."Authentication URL" := 'https://sso.logiq.no/auth/realms/connect-api/protocol/openid-connect/token';

        // [THEN] Validation falls back to the pilot authentication URL (host does not match the pilot host)
        Assert.AreEqual('https://pilot-sso.logiq.no/auth/realms/connect-api/protocol/openid-connect/token', Setup.GetValidatedAuthenticationUrl(), FallbackMsg);
    end;

    [Test]
    procedure BaseUrlSchemeDowngradeFallsBack()
    var
        Setup: Record "Logiq Connection Setup";
    begin
        // [GIVEN] Production environment and a Base URL downgraded to http on the correct host
        Setup.Init();
        Setup.Environment := Setup.Environment::Production;
        Setup."Base URL" := 'http://api.logiq.no/edi/connect/';

        // [THEN] Validation falls back to the hardcoded https base URL instead of allowing cleartext
        Assert.AreEqual('https://api.logiq.no/edi/connect/', Setup.GetValidatedBaseUrl(), DowngradeMsg);
    end;

    [Test]
    procedure ProductionBaseUrlSameHostIsKept()
    var
        Setup: Record "Logiq Connection Setup";
    begin
        // [GIVEN] Production environment and a Base URL on the production host
        Setup.Init();
        Setup.Environment := Setup.Environment::Production;
        Setup."Base URL" := 'https://api.logiq.no/edi/connect/v2/';

        // [THEN] The same-host value is returned unchanged
        Assert.AreEqual('https://api.logiq.no/edi/connect/v2/', Setup.GetValidatedBaseUrl(), SameHostMsg);
    end;

    var
        Assert: Codeunit Assert;
        SameHostMsg: Label 'A same-host URL should be returned unchanged.';
        FallbackMsg: Label 'A different-host URL should fall back to the hardcoded value.';
        DowngradeMsg: Label 'An http downgrade should fall back to the hardcoded https URL.';
}
