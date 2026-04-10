// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Graph;

using System.Integration.Graph;
using System.RestClient;
using System.TestLibraries.Utilities;

codeunit 135144 "Graph Pagination Helper Test"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;
    Subtype = Test;
    TestPermissions = Disabled;

    var
        LibraryAssert: Codeunit "Library Assert";

    [Test]
    procedure ExtractNextLinkSuccessTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        ResponseText: Text;
    begin
        // [GIVEN] Successful response with next link
        HttpResponseMessage.SetHttpStatusCode(200);
        ResponseText := '{"@odata.nextLink":"https://graph.microsoft.com/v1.0/users?$skiptoken=123","value":[]}';
        HttpContent := HttpContent.Create(ResponseText);
        HttpResponseMessage.SetContent(HttpContent);

        // [WHEN] ExtractNextLink is called
        GraphPaginationHelper.ExtractNextLink(HttpResponseMessage, GraphPaginationData);

        // [THEN] Should extract and set the next link
        LibraryAssert.AreEqual('https://graph.microsoft.com/v1.0/users?$skiptoken=123', GraphPaginationData.GetNextLink(), 'Should extract next link');
        LibraryAssert.IsTrue(GraphPaginationData.HasMorePages(), 'Should have more pages');
    end;

    [Test]
    procedure ExtractNextLinkNoNextLinkTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        ResponseText: Text;
    begin
        // [GIVEN] Successful response without next link
        HttpResponseMessage.SetHttpStatusCode(200);
        ResponseText := '{"value":[{"id":"123","displayName":"Test User"}]}';
        HttpContent := HttpContent.Create(ResponseText);
        HttpResponseMessage.SetContent(HttpContent);

        // [WHEN] ExtractNextLink is called
        GraphPaginationHelper.ExtractNextLink(HttpResponseMessage, GraphPaginationData);

        // [THEN] Should have empty next link
        LibraryAssert.AreEqual('', GraphPaginationData.GetNextLink(), 'Should have empty next link');
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages');
    end;

    [Test]
    procedure ExtractNextLinkErrorResponseTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        // [GIVEN] Error response
        HttpResponseMessage.SetHttpStatusCode(400);

        // [WHEN] ExtractNextLink is called
        GraphPaginationHelper.ExtractNextLink(HttpResponseMessage, GraphPaginationData);

        // [THEN] Should have empty next link
        LibraryAssert.AreEqual('', GraphPaginationData.GetNextLink(), 'Should have empty next link on error');
        LibraryAssert.IsFalse(GraphPaginationData.HasMorePages(), 'Should not have more pages on error');
    end;

    [Test]
    procedure ExtractValueArraySuccessTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        ValueArray: JsonArray;
        ResponseText: Text;
        Success: Boolean;
    begin
        // [GIVEN] Successful response with value array
        HttpResponseMessage.SetHttpStatusCode(200);
        ResponseText := '{"value":[{"id":"1","name":"User1"},{"id":"2","name":"User2"}]}';
        HttpContent := HttpContent.Create(ResponseText);
        HttpResponseMessage.SetContent(HttpContent);

        // [WHEN] ExtractValueArray is called
        Success := GraphPaginationHelper.ExtractValueArray(HttpResponseMessage, ValueArray);

        // [THEN] Should extract value array successfully
        LibraryAssert.IsTrue(Success, 'Should extract value array successfully');
        LibraryAssert.AreEqual(2, ValueArray.Count(), 'Should have 2 items in value array');
    end;

    [Test]
    procedure ExtractValueArrayNoValueTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        ValueArray: JsonArray;
        ResponseText: Text;
        Success: Boolean;
    begin
        // [GIVEN] Response without value array
        HttpResponseMessage.SetHttpStatusCode(200);
        ResponseText := '{"@odata.context":"https://graph.microsoft.com/v1.0/$metadata#users"}';
        HttpContent := HttpContent.Create(ResponseText);
        HttpResponseMessage.SetContent(HttpContent);

        // [WHEN] ExtractValueArray is called
        Success := GraphPaginationHelper.ExtractValueArray(HttpResponseMessage, ValueArray);

        // [THEN] Should fail to extract
        LibraryAssert.IsFalse(Success, 'Should fail when no value array');
        LibraryAssert.AreEqual(0, ValueArray.Count(), 'Should have empty array');
    end;

    [Test]
    procedure ApplyPageSizeTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        GraphOptionalParameters: Codeunit "Graph Optional Parameters";
        GraphPaginationData: Codeunit "Graph Pagination Data";
        ODataParams: Dictionary of [Text, Text];
    begin
        // [GIVEN] Page size is set
        GraphPaginationData.SetPageSize(25);

        // [WHEN] ApplyPageSize is called
        GraphPaginationHelper.ApplyPageSize(GraphOptionalParameters, GraphPaginationData);

        // [THEN] Should set $top parameter
        ODataParams := GraphOptionalParameters.GetODataQueryParameters();
        LibraryAssert.IsTrue(ODataParams.ContainsKey('$top'), 'Should contain $top parameter');
        LibraryAssert.AreEqual('25', ODataParams.Get('$top'), 'Should set correct page size');
    end;

    [Test]
    procedure CombineValueArraysTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
        JsonResults: JsonArray;
        JsonToken: JsonToken;
        Success: Boolean;
    begin
        // [GIVEN] Initial results array with one item
        JsonToken.ReadFrom('{"id":"0","name":"Initial"}');
        JsonResults.Add(JsonToken);

        // [GIVEN] Response with new items
        HttpResponseMessage.SetHttpStatusCode(200);
        HttpContent := HttpContent.Create('{"value":[{"id":"1","name":"User1"},{"id":"2","name":"User2"}]}');
        HttpResponseMessage.SetContent(HttpContent);

        // [WHEN] CombineValueArrays is called
        Success := GraphPaginationHelper.CombineValueArrays(HttpResponseMessage, JsonResults);

        // [THEN] Should combine arrays successfully
        LibraryAssert.IsTrue(Success, 'Should combine arrays successfully');
        LibraryAssert.AreEqual(3, JsonResults.Count(), 'Should have 3 total items');
    end;

    [Test]
    procedure IsWithinIterationLimitTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
        IterationCount: Integer;
        WithinLimit: Boolean;
    begin
        // [GIVEN] Iteration count is 0
        IterationCount := 0;

        // [WHEN] IsWithinIterationLimit is called
        WithinLimit := GraphPaginationHelper.IsWithinIterationLimit(IterationCount, 5);

        // [THEN] Should be within limit and increment count
        LibraryAssert.IsTrue(WithinLimit, 'Should be within limit');
        LibraryAssert.AreEqual(1, IterationCount, 'Should increment iteration count');

        // [GIVEN] Iteration count at limit
        IterationCount := 5;

        // [WHEN] IsWithinIterationLimit is called
        WithinLimit := GraphPaginationHelper.IsWithinIterationLimit(IterationCount, 5);

        // [THEN] Should not be within limit
        LibraryAssert.IsFalse(WithinLimit, 'Should not be within limit');
        LibraryAssert.AreEqual(5, IterationCount, 'Should not increment when at limit');
    end;

    [Test]
    procedure GetMaxIterationsTest()
    var
        GraphPaginationHelper: Codeunit "Graph Pagination Helper";
    begin
        // [WHEN] GetMaxIterations is called
        // [THEN] Should return 1000
        LibraryAssert.AreEqual(1000, GraphPaginationHelper.GetMaxIterations(), 'Max iterations should be 1000');
    end;
}