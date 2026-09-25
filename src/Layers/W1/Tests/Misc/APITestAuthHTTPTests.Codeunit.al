// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

#pragma warning disable AA0247

codeunit 139496 "API Test Auth HTTP Tests"
{
    // A separate codeunit ends the URL tests' metadata transaction before making HTTP requests.
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryGraphMgt: Codeunit "Library - Graph Mgt";
        FirstHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";
        SecondHttpWebRequestMgt: Codeunit "Http Web Request Mgt.";

    [Test]
    procedure MicrosoftAuthenticationIsRequiredForHttpRequest()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        SecurityGroup: Codeunit "Security Group";
        TargetURL: Text;
        ResponseCode: Integer;
    begin
        // [SCENARIO] A UserPassword service accepts the configured credentials but rejects requests without them
        Initialize();

        // [GIVEN] The uptake fixture provisions credentials for the current OnPrem UserPassword tenant
        Assert.IsFalse(EnvironmentInfo.IsSaaSInfrastructure(), 'This HTTP scenario requires an OnPrem UserPassword test environment.');
        Assert.IsFalse(SecurityGroup.IsWindowsAuthentication(), 'This HTTP scenario must not pass under ambient Windows authentication.');
        TargetURL := GetUrl(ClientType::ODataV4);

        // [WHEN] The default provider sends a real request to the authenticated OData service document
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURL);
        ResponseCode := ExecuteRequest(FirstHttpWebRequestMgt);

        // [THEN] The service rejects ambient credentials
        Assert.AreEqual(401, ResponseCode, 'A request without the provider must be unauthorized.');

        // [WHEN] The Microsoft provider configures a new request to the same endpoint
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::"Microsoft Test Environment");
        LibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURL);
        ResponseCode := ExecuteRequest(SecondHttpWebRequestMgt);

        // [THEN] Credentials applied by the context reach the server and authenticate the request
        Assert.AreEqual(200, ResponseCode, 'The configured credentials must authenticate the HTTP request.');

        // [WHEN] Authentication is deselected and another request is created
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::None);
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURL);
        ResponseCode := ExecuteRequest(FirstHttpWebRequestMgt);

        // [THEN] Credentials do not leak to the new request
        Assert.AreEqual(401, ResponseCode, 'Deselecting the provider must leave the new request unauthorized.');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryGraphMgt);
        Clear(FirstHttpWebRequestMgt);
        Clear(SecondHttpWebRequestMgt);
    end;

    local procedure ExecuteRequest(var HttpWebRequestMgt: Codeunit "Http Web Request Mgt.") ResponseCode: Integer
    var
        TempBlob: Codeunit "Temp Blob";
        HttpStatusCode: DotNet HttpStatusCode;
        ResponseHeaders: DotNet NameValueCollection;
        ErrorMessage: Text;
        ErrorDetails: Text;
        Successful: Boolean;
    begin
        HttpWebRequestMgt.DisableUI();
        HttpWebRequestMgt.SetReturnType('application/json');
        Successful := HttpWebRequestMgt.SendRequestAndReadResponse(TempBlob, ErrorMessage, ErrorDetails, HttpStatusCode, ResponseHeaders);
        Assert.IsFalse(IsNull(HttpStatusCode), 'The service must return an HTTP status, not a transport failure.');
        ResponseCode := HttpStatusCode;
        Assert.AreEqual(ResponseCode = 200, Successful, 'The response status must agree with the transport result.');
    end;
}
