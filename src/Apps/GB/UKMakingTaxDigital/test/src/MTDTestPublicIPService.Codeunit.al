// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

codeunit 148113 "MTDTestPublicIPService"
{
    Subtype = Test;
    TestType = Uncategorized;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
        // [FEATURE] [Making Tax Digital] [Fraud Prevention] [Public IP]
    end;

    var
        Assert: Codeunit Assert;
        PublicIPServiceUrlTok: Label 'https://ip.example/', Locked = true;

    [Test]
    [HandlerFunctions('OversizedResponseHandler')]
    [Scope('OnPrem')]
    procedure GetServerPublicIPRejectsOversizedResponse()
    var
        MTDFraudPreventionMgt: Codeunit "MTD Fraud Prevention Mgt.";
        ServerIPAddress: Text;
    begin
        // [SCENARIO] A public-IP service response larger than the 4 KB cap is rejected and no IP is extracted

        // [WHEN] The unauthenticated public-IP service returns an oversized body
        if MTDFraudPreventionMgt.GetServerPublicIPFromExternalService(ServerIPAddress, PublicIPServiceUrlTok) then;

        // [THEN] No IP address is trusted from the oversized response
        Assert.AreEqual('', ServerIPAddress, 'An oversized public-IP response must be rejected.');
    end;

    [Test]
    [HandlerFunctions('ValidResponseHandler')]
    [Scope('OnPrem')]
    procedure GetServerPublicIPAcceptsWithinLimitResponse()
    var
        MTDFraudPreventionMgt: Codeunit "MTD Fraud Prevention Mgt.";
        ServerIPAddress: Text;
    begin
        // [SCENARIO] A public-IP service response within the 4 KB cap is accepted and the IP is extracted

        // [WHEN] The public-IP service returns a small valid IP response
        if MTDFraudPreventionMgt.GetServerPublicIPFromExternalService(ServerIPAddress, PublicIPServiceUrlTok) then;

        // [THEN] The IP address is extracted from the within-limit response
        Assert.AreEqual('203.0.113.7', ServerIPAddress, 'A within-limit public-IP response should be accepted.');
    end;

    [HttpClientHandler]
    internal procedure OversizedResponseHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom(PadStr('', 5000, 'A')); // exceeds the 4 KB public-IP response cap
        exit(false);
    end;

    [HttpClientHandler]
    internal procedure ValidResponseHandler(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        Response.HttpStatusCode := 200;
        Response.Content.WriteFrom('203.0.113.7');
        exit(false);
    end;
}
