// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Graph;

using System.Integration.Graph;
using System.RestClient;
using System.Utilities;
using System.TestLibraries.Utilities;

codeunit 135140 "Graph Client Test"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";


    [Test]
    procedure AuthTriggeredTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
    begin
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);
        ResponseInStream := TempBlob.CreateInStream();

        // [WHEN] When Get Method is called  
        GraphClient.Get('groups', HttpResponseMessage);

        // [THEN] Verify authorization of request is triggered
        LibraryAssert.IsTrue(GraphAuthSpy.IsInvoked(), 'Authorization should be invoked.');
    end;

    [Test]
    procedure RequestUriTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
    begin
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);
        ResponseInStream := TempBlob.CreateInStream();

        // [WHEN] When Get Method is called  
        GraphClient.Get('groups', HttpResponseMessage);

        // [THEN] Verify request uri is build correct
        MockHttpClientHandler.GetHttpRequestMessage(HttpRequestMessage);
        LibraryAssert.AreEqual('https://graph.microsoft.com/v1.0/groups', HttpRequestMessage.GetRequestUri(), 'Incorrect Request URI.');
    end;

    [Test]
    procedure RequestUriWithODataQueryParameterTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        TempBlob: Codeunit "Temp Blob";
        Uri: Codeunit Uri;
        ResponseInStream: InStream;
    begin
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);
        ResponseInStream := TempBlob.CreateInStream();

        // [GIVEN] Optional Parameters with OData Query Parameter set
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::format, 'json');

        // [WHEN] When Get Method is called  
        GraphClient.Get('groups', GraphOptionalParameters, HttpResponseMessage);

        // [THEN] Verify request uri is build correct
        MockHttpClientHandler.GetHttpRequestMessage(HttpRequestMessage);
        Uri.Init(HttpRequestMessage.GetRequestUri());
        LibraryAssert.AreEqual('?$format=json', Uri.GetQuery(), 'Incorrect query string.');
    end;

    [Test]
    procedure ResponseBodyTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        HttpContent: Codeunit "Http Content";
        MockHttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        TempBlob: Codeunit "Temp Blob";
        ResponseInStream: InStream;
        ResponseJsonObject: JsonObject;
        DisplayNameJsonToken: JsonToken;
    begin
        // [GIVEN] Mocked Response for groups
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetGroupsResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage);
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);
        ResponseInStream := TempBlob.CreateInStream();

        // [WHEN] When Get Method is called  
        GraphClient.Get('groups', HttpResponseMessage);

        // [THEN] Verify response is correct
        LibraryAssert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'Should be success status code.');
        HttpContent := HttpResponseMessage.GetContent();
        ResponseInStream := HttpContent.AsInStream();
        ResponseJsonObject.ReadFrom(ResponseInStream);
        ResponseJsonObject.SelectToken('$.value[:1].displayName', DisplayNameJsonToken);
        LibraryAssert.AreEqual('HR Taskforce (ÄÖÜßäöü)', DisplayNameJsonToken.AsValue().AsText(), 'Incorrect Displayname.');
    end;

    [Test]
    procedure GetWithPaginationSinglePageTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        MockHttpContent: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        Success: Boolean;
    begin
        // [GIVEN] Mock response with no next link (single page)
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetSinglePageResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage);
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [GIVEN] Set page size
        GraphPaginationData.SetPageSize(50);

        // [WHEN] GetWithPagination is called
        Success := GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);

        // [THEN] Should be successful
        LibraryAssert.IsTrue(Success, 'GetWithPagination should succeed');
        LibraryAssert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'Should return 200 status');

        // [THEN] Should have no more pages
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages');
    end;

    [Test]
    procedure GetWithPaginationMultiplePagesTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        MockHttpContent: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        Success: Boolean;
    begin
        // [GIVEN] Mock response with next link (multiple pages)
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetMultiPageResponsePage1());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage);
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [WHEN] GetWithPagination is called
        Success := GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);

        // [THEN] Should be successful and have more pages
        LibraryAssert.IsTrue(Success, 'GetWithPagination should succeed');
        LibraryAssert.IsTrue(GraphPaginationData.HasMorePages(), 'Should have more pages');
        LibraryAssert.AreNotEqual('', GraphPaginationData.GetNextLink(), 'Should have next link');
    end;

    [Test]
    procedure GetNextPageTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage2: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        MockHttpContent: Codeunit "Http Content";
        MockHttpContent2: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        Success: Boolean;
    begin
        // [GIVEN] First page with next link
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetMultiPageResponsePage1());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage);
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [GIVEN] Get first page
        Success := GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);
        LibraryAssert.IsTrue(Success, 'First page should succeed');

        // [GIVEN] Mock second page response
        MockHttpResponseMessage2.SetHttpStatusCode(200);
        MockHttpContent2 := HttpContent.Create(GetMultiPageResponsePage2());
        MockHttpResponseMessage2.SetContent(MockHttpContent2);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage2);

        // [WHEN] GetNextPage is called
        Success := GraphClient.GetNextPage(GraphPaginationData, HttpResponseMessage);

        // [THEN] Should be successful
        LibraryAssert.IsTrue(Success, 'GetNextPage should succeed');
        LibraryAssert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'Should return 200 status');

        // [THEN] Should have no more pages (last page)
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages after last page');
    end;

    [Test]
    procedure GetAllPagesTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        MockHttpContent: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        AllResults: JsonArray;
        Success: Boolean;
    begin
        // [GIVEN] Mock multi-page response
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetMultiPageResponsePage1());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage);
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // Note: This test is simplified as we can't easily mock multiple sequential responses
        // In real scenario, would need enhanced mock to handle multiple calls

        // [WHEN] GetAllPages is called
        Success := GraphClient.GetAllPages('users', GraphOptionalParameters, HttpResponseMessage, AllResults);

        // [THEN] Should be successful
        LibraryAssert.IsTrue(Success, 'GetAllPages should succeed');
        LibraryAssert.AreNotEqual(0, AllResults.Count(), 'Should have results');
    end;

    [Test]
    procedure GetWithPaginationPageSizeTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler";
        MockHttpContent: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        Uri: Codeunit Uri;
    begin
        // [GIVEN] Mock response
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetSinglePageResponse());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.SetResponse(MockHttpResponseMessage);
        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [GIVEN] Set page size
        GraphPaginationData.SetPageSize(25);

        // [WHEN] GetWithPagination is called
        GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);

        // [THEN] Request should include $top parameter
        MockHttpClientHandler.GetHttpRequestMessage(HttpRequestMessage);
        Uri.Init(HttpRequestMessage.GetRequestUri());
        LibraryAssert.AreEqual('?$top=25', Uri.GetQuery(), 'Should include page size as $top parameter');
    end;

    local procedure GetGroupsResponse(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#groups",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {');
        StringBuilder.Append('            "id": "02bd9fd6-8f93-4758-87c3-1fb73740a315",');
        StringBuilder.Append('            "deletedDateTime": null,');
        StringBuilder.Append('            "classification": null,');
        StringBuilder.Append('            "createdDateTime": "2017-07-31T18:56:16Z",');
        StringBuilder.Append('            "creationOptions": [');
        StringBuilder.Append('                "ExchangeProvisioningFlags:481"');
        StringBuilder.Append('            ],');
        StringBuilder.Append('            "description": "Welcome to the HR Taskforce team.",');
        StringBuilder.Append('            "displayName": "HR Taskforce (ÄÖÜßäöü)",');
        StringBuilder.Append('            "expirationDateTime": null,');
        StringBuilder.Append('            "groupTypes": [');
        StringBuilder.Append('                "Unified"');
        StringBuilder.Append('            ],');
        StringBuilder.Append('            "isAssignableToRole": null,');
        StringBuilder.Append('            "mail": "HRTaskforce@M365x214355.onmicrosoft.com",');
        StringBuilder.Append('            "mailEnabled": true,');
        StringBuilder.Append('            "mailNickname": "HRTaskforce",');
        StringBuilder.Append('            "membershipRule": null,');
        StringBuilder.Append('            "membershipRuleProcessingState": null,');
        StringBuilder.Append('            "onPremisesDomainName": null,');
        StringBuilder.Append('            "onPremisesLastSyncDateTime": null,');
        StringBuilder.Append('            "onPremisesNetBiosName": null,');
        StringBuilder.Append('            "onPremisesSamAccountName": null,');
        StringBuilder.Append('            "onPremisesSecurityIdentifier": null,');
        StringBuilder.Append('            "onPremisesSyncEnabled": null,');
        StringBuilder.Append('            "preferredDataLocation": null,');
        StringBuilder.Append('            "preferredLanguage": null,');
        StringBuilder.Append('            "proxyAddresses": [],');
        StringBuilder.Append('            "renewedDateTime": "2023-01-31T00:00:00Z",');
        StringBuilder.Append('            "resourceBehaviorOptions": [],');
        StringBuilder.Append('            "resourceProvisioningOptions": [');
        StringBuilder.Append('                "Team"');
        StringBuilder.Append('            ],');
        StringBuilder.Append('            "securityEnabled": false,');
        StringBuilder.Append('            "securityIdentifier": "S-1-12-1-45981654-1196986259-3072312199-363020343",');
        StringBuilder.Append('            "theme": null,');
        StringBuilder.Append('            "visibility": "Private",');
        StringBuilder.Append('            "onPremisesProvisioningErrors": [],');
        StringBuilder.Append('            "serviceProvisioningErrors": []');
        StringBuilder.Append('        }');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure GetSinglePageResponse(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {');
        StringBuilder.Append('            "id": "87d349ed-44d7-43e1-9a83-5f2406dee5bd",');
        StringBuilder.Append('            "displayName": "Test User 1",');
        StringBuilder.Append('            "mail": "testuser1@contoso.com"');
        StringBuilder.Append('        },');
        StringBuilder.Append('        {');
        StringBuilder.Append('            "id": "45d349ed-44d7-43e1-9a83-5f2406dee5bd",');
        StringBuilder.Append('            "displayName": "Test User 2",');
        StringBuilder.Append('            "mail": "testuser2@contoso.com"');
        StringBuilder.Append('        }');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure GetMultiPageResponsePage1(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "@odata.nextLink": "https://graph.microsoft.com/v1.0/users?$skiptoken=X%274453707402000100000017",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {');
        StringBuilder.Append('            "id": "87d349ed-44d7-43e1-9a83-5f2406dee5bd",');
        StringBuilder.Append('            "displayName": "Test User 1",');
        StringBuilder.Append('            "mail": "testuser1@contoso.com"');
        StringBuilder.Append('        }');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure GetMultiPageResponsePage2(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {');
        StringBuilder.Append('            "id": "45d349ed-44d7-43e1-9a83-5f2406dee5bd",');
        StringBuilder.Append('            "displayName": "Test User 2",');
        StringBuilder.Append('            "mail": "testuser2@contoso.com"');
        StringBuilder.Append('        }');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

}