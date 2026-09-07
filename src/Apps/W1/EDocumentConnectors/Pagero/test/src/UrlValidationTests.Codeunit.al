// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.EServices.EDocumentConnector.Pagero;

using Microsoft.EServices.EDocumentConnector;

/// <summary>
/// Unit tests for the Pagero integration URL validation. A stored URL whose host matches the
/// hardcoded Pagero host is used as-is; a tampered URL on a foreign host falls back to the
/// hardcoded value so credentials/tokens cannot be redirected to a malicious endpoint.
/// </summary>
codeunit 148193 "Url Validation Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    TestHttpRequestPolicy = BlockOutboundRequests;
    Permissions = tabledata "E-Doc. Ext. Connection Setup" = rimd;

    [Test]
    procedure AuthenticationUrlKeepsSameHostValue()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
    begin
        // [SCENARIO] A stored Authentication URL on the expected host is used unchanged.
        InitSetup(ConnectionSetup);
        ConnectionSetup."Authentication URL" := 'https://sso.pageroonline.com/oauth/v2/tenant';
        ConnectionSetup.Modify();

        Assert.AreEqual('https://sso.pageroonline.com/oauth/v2/tenant', PageroAuth.GetAuthenticationURL(), StoredUrlErr);
    end;

    [Test]
    procedure AuthenticationUrlFallsBackOnDifferentHost()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
    begin
        // [SCENARIO] A tampered Authentication URL on a foreign host falls back to the hardcoded value.
        InitSetup(ConnectionSetup);
        ConnectionSetup."Authentication URL" := 'https://malicious.example.com/oauth/v2';
        ConnectionSetup.Modify();

        Assert.AreEqual('https://sso.pageroonline.com/oauth/v2', PageroAuth.GetAuthenticationURL(), FallbackUrlErr);
    end;

    [Test]
    procedure FileApiUrlKeepsSameHostValue()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
    begin
        InitSetup(ConnectionSetup);
        ConnectionSetup."FileAPI URL" := 'https://api.pageroonline.com/file/v2/files';
        ConnectionSetup.Modify();

        Assert.AreEqual('https://api.pageroonline.com/file/v2/files', PageroAuth.GetFileAPIURL(), StoredUrlErr);
    end;

    [Test]
    procedure FileApiUrlFallsBackOnDifferentHost()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
    begin
        InitSetup(ConnectionSetup);
        ConnectionSetup."FileAPI URL" := 'https://malicious.example.com/file/v1/files';
        ConnectionSetup.Modify();

        Assert.AreEqual('https://api.pageroonline.com/file/v1/files', PageroAuth.GetFileAPIURL(), FallbackUrlErr);
    end;

    [Test]
    procedure DocumentApiUrlFallsBackOnDifferentHost()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
    begin
        InitSetup(ConnectionSetup);
        ConnectionSetup."DocumentAPI URL" := 'https://malicious.example.com/document/v1/documents';
        ConnectionSetup.Modify();

        Assert.AreEqual('https://api.pageroonline.com/document/v1/documents', PageroAuth.GetDocumentAPIURL(), FallbackUrlErr);
    end;

    [Test]
    procedure FilepartsUrlFallsBackOnDifferentHost()
    var
        ConnectionSetup: Record "E-Doc. Ext. Connection Setup";
    begin
        InitSetup(ConnectionSetup);
        ConnectionSetup."Fileparts URL" := 'https://malicious.example.com/file/v1/fileparts';
        ConnectionSetup.Modify();

        Assert.AreEqual('https://api.pageroonline.com/file/v1/fileparts', PageroAuth.GetFilepartsURL(), FallbackUrlErr);
    end;

    local procedure InitSetup(var ConnectionSetup: Record "E-Doc. Ext. Connection Setup")
    begin
        if ConnectionSetup.Get() then
            ConnectionSetup.DeleteAll();
        PageroAuth.InitConnectionSetup();
        ConnectionSetup.Get();
    end;

    var
        Assert: Codeunit Assert;
        PageroAuth: Codeunit "Pagero Auth.";
        StoredUrlErr: Label 'A same-host URL should be returned unchanged.';
        FallbackUrlErr: Label 'A different-host URL should fall back to the hardcoded value.';
}
