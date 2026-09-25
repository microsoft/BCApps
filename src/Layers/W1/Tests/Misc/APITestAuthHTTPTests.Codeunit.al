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
    procedure MicrosoftAuthenticationRespectsServerAuthMode()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        TargetURL: Text;
        ResponseCode: Integer;
        ExpectedAmbientResponseCode: Integer;
    begin
        // [SCENARIO] Authentication supplies UserPassword credentials or preserves ambient Windows credentials
        Initialize();

        // [GIVEN] An OnPrem service accepts configured UserPassword credentials or authorized ambient Windows credentials
        Assert.IsFalse(EnvironmentInfo.IsSaaSInfrastructure(), 'This HTTP scenario requires an OnPrem test environment.');
        ExpectedAmbientResponseCode := GetExpectedAmbientResponseCode();
        TargetURL := GetUrl(ClientType::ODataV4);

        // [WHEN] The default provider sends a real request to the authenticated OData service document
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURL);
        ResponseCode := ExecuteRequest(FirstHttpWebRequestMgt);

        // [THEN] Only a Windows-authenticated service accepts ambient credentials
        Assert.AreEqual(ExpectedAmbientResponseCode, ResponseCode, 'The default provider must respect the server authentication mode.');

        // [WHEN] The Microsoft provider configures a new request to the same endpoint
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::"Microsoft Test Environment");
        LibraryGraphMgt.InitializeWebRequestWithURL(SecondHttpWebRequestMgt, TargetURL);
        ResponseCode := ExecuteRequest(SecondHttpWebRequestMgt);

        // [THEN] Configured UserPassword credentials or preserved Windows credentials authenticate the request
        Assert.AreEqual(200, ResponseCode, 'The Microsoft provider must authenticate without disrupting ambient Windows credentials.');

        // [WHEN] Authentication is deselected and another request is created
        LibraryGraphMgt.SetAuthenticationProvider(Enum::"API Test Authentication"::None);
        LibraryGraphMgt.InitializeWebRequestWithURL(FirstHttpWebRequestMgt, TargetURL);
        ResponseCode := ExecuteRequest(FirstHttpWebRequestMgt);

        // [THEN] Configured credentials do not leak and ambient Windows authentication remains available
        Assert.AreEqual(ExpectedAmbientResponseCode, ResponseCode, 'Deselecting the provider must restore the server authentication mode.');
    end;

    local procedure Initialize()
    begin
        Clear(LibraryGraphMgt);
        Clear(FirstHttpWebRequestMgt);
        Clear(SecondHttpWebRequestMgt);
    end;

    local procedure GetExpectedAmbientResponseCode(): Integer
    var
        SecurityGroup: Codeunit "Security Group";
    begin
        if SecurityGroup.IsWindowsAuthentication() then
            exit(200);

        exit(401);
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
