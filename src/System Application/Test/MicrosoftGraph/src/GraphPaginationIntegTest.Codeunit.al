// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Graph;

using System.Integration.Graph;
using System.RestClient;
using System.TestLibraries.Utilities;
using System.Utilities;

codeunit 135146 "Graph Pagination Integ. Test"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure FullPaginationFlowTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler Multi";
        MockHttpResponseMessage1: Codeunit "Http Response Message";
        MockHttpResponseMessage2: Codeunit "Http Response Message";
        MockHttpResponseMessage3: Codeunit "Http Response Message";
        MockHttpContent1: Codeunit "Http Content";
        MockHttpContent2: Codeunit "Http Content";
        MockHttpContent3: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        AllResults: JsonArray;
        Success: Boolean;
    begin
        // [GIVEN] Three pages of responses
        MockHttpResponseMessage1.SetHttpStatusCode(200);
        MockHttpContent1 := HttpContent.Create(GetPaginationResponsePage1());
        MockHttpResponseMessage1.SetContent(MockHttpContent1);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage1);

        MockHttpResponseMessage2.SetHttpStatusCode(200);
        MockHttpContent2 := HttpContent.Create(GetPaginationResponsePage2());
        MockHttpResponseMessage2.SetContent(MockHttpContent2);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage2);

        MockHttpResponseMessage3.SetHttpStatusCode(200);
        MockHttpContent3 := HttpContent.Create(GetPaginationResponsePage3());
        MockHttpResponseMessage3.SetContent(MockHttpContent3);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage3);

        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [WHEN] GetAllPages is called
        Success := GraphClient.GetAllPages('users', GraphOptionalParameters, HttpResponseMessage, AllResults);

        // [THEN] Should retrieve all pages successfully
        LibraryAssert.IsTrue(Success, 'GetAllPages should succeed');
        LibraryAssert.AreEqual(6, AllResults.Count(), 'Should have 6 total users (2 per page)');
        LibraryAssert.AreEqual(3, MockHttpClientHandler.GetRequestCount(), 'Should make 3 requests');
    end;

    [Test]
    procedure ManualPaginationFlowTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler Multi";
        MockHttpResponseMessage1: Codeunit "Http Response Message";
        MockHttpResponseMessage2: Codeunit "Http Response Message";
        MockHttpResponseMessage3: Codeunit "Http Response Message";
        MockHttpContent1: Codeunit "Http Content";
        MockHttpContent2: Codeunit "Http Content";
        MockHttpContent3: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        PageCount: Integer;
        TotalItems: Integer;
        Success: Boolean;
    begin
        // [GIVEN] Three pages of responses
        MockHttpResponseMessage1.SetHttpStatusCode(200);
        MockHttpContent1 := HttpContent.Create(GetPaginationResponsePage1());
        MockHttpResponseMessage1.SetContent(MockHttpContent1);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage1);

        MockHttpResponseMessage2.SetHttpStatusCode(200);
        MockHttpContent2 := HttpContent.Create(GetPaginationResponsePage2());
        MockHttpResponseMessage2.SetContent(MockHttpContent2);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage2);

        MockHttpResponseMessage3.SetHttpStatusCode(200);
        MockHttpContent3 := HttpContent.Create(GetPaginationResponsePage3());
        MockHttpResponseMessage3.SetContent(MockHttpContent3);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage3);

        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [GIVEN] Set page size
        GraphPaginationData.SetPageSize(2);

        // [WHEN] Process pages manually
        Success := GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);
        LibraryAssert.IsTrue(Success, 'First page should succeed');
        PageCount := 1;
        TotalItems += CountItemsInResponse(HttpResponseMessage);

        while GraphPaginationData.HasMorePages() do begin
            Success := GraphClient.GetNextPage(GraphPaginationData, HttpResponseMessage);
            LibraryAssert.IsTrue(Success, 'Page should succeed');
            PageCount += 1;
            TotalItems += CountItemsInResponse(HttpResponseMessage);
        end;

        // [THEN] Should process all pages
        LibraryAssert.AreEqual(3, PageCount, 'Should process 3 pages');
        LibraryAssert.AreEqual(6, TotalItems, 'Should have 6 total items');
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should have no more pages');
    end;

    [Test]
    procedure PaginationWithFiltersTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler Multi";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpContent: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        Uri: Codeunit Uri;
        QueryString: Text;
    begin
        // [GIVEN] Response with pagination
        MockHttpResponseMessage.SetHttpStatusCode(200);
        MockHttpContent := HttpContent.Create(GetPaginationResponsePage1());
        MockHttpResponseMessage.SetContent(MockHttpContent);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage);

        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [GIVEN] Set filters and page size
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::filter, 'displayName eq ''Test''');
        GraphOptionalParameters.SetODataQueryParameter(Enum::"Graph OData Query Parameter"::select, 'id,displayName');
        GraphPaginationData.SetPageSize(10);

        // [WHEN] GetWithPagination is called
        GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);

        // [THEN] Request should include all parameters
        QueryString := MockHttpClientHandler.GetHttpRequestUri(1);
        Uri.Init(QueryString);
        QueryString := Uri.GetQuery();

        LibraryAssert.AreNotEqual(0, StrPos(QueryString, '$top=10'), 'Should include page size');
        LibraryAssert.AreNotEqual(0, StrPos(QueryString, '$filter=displayName'), 'Should include filter');
        LibraryAssert.AreNotEqual(0, StrPos(QueryString, '$select=id'), 'Should include select');
    end;

    [Test]
    procedure PaginationErrorHandlingTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler Multi";
        MockHttpResponseMessage1: Codeunit "Http Response Message";
        MockHttpResponseMessage2: Codeunit "Http Response Message";
        MockHttpContent1: Codeunit "Http Content";
        MockHttpContent2: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        Success: Boolean;
    begin
        // [GIVEN] First page succeeds, second page fails
        MockHttpResponseMessage1.SetHttpStatusCode(200);
        MockHttpContent1 := HttpContent.Create(GetPaginationResponsePage1());
        MockHttpResponseMessage1.SetContent(MockHttpContent1);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage1);

        MockHttpResponseMessage2.SetHttpStatusCode(429); // Too Many Requests
        MockHttpContent2 := HttpContent.Create('{"error":{"code":"TooManyRequests","message":"Rate limit exceeded"}}');
        MockHttpResponseMessage2.SetContent(MockHttpContent2);
        MockHttpClientHandler.AddResponse(MockHttpResponseMessage2);

        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [WHEN] Process pages
        Success := GraphClient.GetWithPagination('users', GraphOptionalParameters, GraphPaginationData, HttpResponseMessage);
        LibraryAssert.IsTrue(Success, 'First page should succeed');
        LibraryAssert.IsTrue(GraphPaginationData.HasMorePages(), 'Should have more pages');

        // [WHEN] Second page fails
        Success := GraphClient.GetNextPage(GraphPaginationData, HttpResponseMessage);

        // [THEN] Should handle error gracefully
        LibraryAssert.AreEqual(false, Success, 'Second page should fail');
        LibraryAssert.AreEqual(429, HttpResponseMessage.GetHttpStatusCode(), 'Should return 429 status');
    end;

    [Test]
    procedure GetAllPagesWithMaxIterationTest()
    var
        GraphAuthSpy: Codeunit "Graph Auth. Spy";
        GraphClient: Codeunit "Graph Client";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        HttpResponseMessage: Codeunit "Http Response Message";
        MockHttpClientHandler: Codeunit "Mock Http Client Handler Multi";
        MockHttpResponseMessage: Codeunit "Http Response Message";
        MockHttpContent: Codeunit "Http Content";
        HttpContent: Codeunit "Http Content";
        AllResults: JsonArray;
        i: Integer;
        Success: Boolean;
    begin
        // [GIVEN] Many pages (simulate endless pagination)
        for i := 1 to 1005 do begin
            MockHttpResponseMessage.SetHttpStatusCode(200);
            MockHttpContent := HttpContent.Create(GetEndlessPaginationResponse());
            MockHttpResponseMessage.SetContent(MockHttpContent);
            MockHttpClientHandler.AddResponse(MockHttpResponseMessage);
        end;

        GraphClient.Initialize(Enum::"Graph API Version"::"v1.0", GraphAuthSpy, MockHttpClientHandler);

        // [WHEN] GetAllPages is called
        Success := GraphClient.GetAllPages('users', GraphOptionalParameters, HttpResponseMessage, AllResults);

        // [THEN] Should stop at max iterations (1000)
        LibraryAssert.IsTrue(Success, 'Should succeed even with max iterations');
        LibraryAssert.AreEqual(1001, MockHttpClientHandler.GetRequestCount(), 'Should make 1001 requests (1 initial + 1000 iterations)');
    end;

    local procedure GetPaginationResponsePage1(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "@odata.nextLink": "https://graph.microsoft.com/v1.0/users?$skiptoken=page2",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {"id": "1", "displayName": "User 1"},');
        StringBuilder.Append('        {"id": "2", "displayName": "User 2"}');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure GetPaginationResponsePage2(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "@odata.nextLink": "https://graph.microsoft.com/v1.0/users?$skiptoken=page3",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {"id": "3", "displayName": "User 3"},');
        StringBuilder.Append('        {"id": "4", "displayName": "User 4"}');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure GetPaginationResponsePage3(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "value": [');
        StringBuilder.Append('        {"id": "5", "displayName": "User 5"},');
        StringBuilder.Append('        {"id": "6", "displayName": "User 6"}');
        StringBuilder.Append('    ]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure GetEndlessPaginationResponse(): Text
    var
        StringBuilder: TextBuilder;
    begin
        StringBuilder.Append('{');
        StringBuilder.Append('    "@odata.context": "https://graph.microsoft.com/v1.0/$metadata#users",');
        StringBuilder.Append('    "@odata.nextLink": "https://graph.microsoft.com/v1.0/users?$skiptoken=endless",');
        StringBuilder.Append('    "value": [{"id": "x", "displayName": "User X"}]');
        StringBuilder.Append('}');
        exit(StringBuilder.ToText());
    end;

    local procedure CountItemsInResponse(HttpResponseMessage: Codeunit "Http Response Message"): Integer
    var
        ResponseJson: JsonObject;
        ValueArray: JsonArray;
        JsonToken: JsonToken;
        ResponseText: Text;
    begin
        ResponseText := HttpResponseMessage.GetContent().AsText();
        if ResponseJson.ReadFrom(ResponseText) then
            if ResponseJson.Get('value', JsonToken) then begin
                ValueArray := JsonToken.AsArray();
                exit(ValueArray.Count());
            end;
    end;
}