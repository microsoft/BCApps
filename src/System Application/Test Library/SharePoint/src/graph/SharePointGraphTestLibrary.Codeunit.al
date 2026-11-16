// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.RestClient;

codeunit 132975 "SharePoint Graph Test Library"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        MockHttpClientHandler: Codeunit "SharePoint Http Client Handler";

    /// <summary>
    /// Sets a single mock response that is returned for every request.
    /// Clears any responses queued with AddMockResponse and the recorded request history.
    /// Use this when all requests in the test should get the same response;
    /// use AddMockResponse to return different responses for consecutive requests.
    /// </summary>
    /// <param name="NewHttpResponseMessage">The response to return for every request.</param>
    procedure SetMockResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    begin
        MockHttpClientHandler.SetResponse(NewHttpResponseMessage);
    end;

    /// <summary>
    /// Gets the most recently sent request.
    /// </summary>
    /// <param name="OutHttpRequestMessage">The last request received by the mock handler.</param>
    procedure GetHttpRequestMessage(var OutHttpRequestMessage: Codeunit "Http Request Message")
    begin
        MockHttpClientHandler.GetHttpRequestMessage(OutHttpRequestMessage);
    end;

    /// <summary>
    /// Makes every subsequent request fail with the given error instead of returning a response.
    /// The request is still recorded in the request history before failing.
    /// Cleared by ResetMockHandler.
    /// </summary>
    /// <param name="ErrorText">The error that sending a request fails with.</param>
    procedure ExpectRequestToFailWithError(ErrorText: Text)
    begin
        MockHttpClientHandler.ExpectSendToFailWithError(ErrorText);
    end;

    /// <summary>
    /// Queues a mock response. Call multiple times to return a different response for each
    /// consecutive request: the first request gets the first queued response, and so on.
    /// Once the queue is exhausted, subsequent requests fall back to the response set with
    /// SetMockResponse; if none was set, the request receives a 500 response whose reason phrase
    /// states that no mock response was queued. Note that SetMockResponse clears the queue,
    /// so a fallback response must be set before queueing.
    /// </summary>
    /// <param name="StatusCode">The HTTP status code of the queued response.</param>
    /// <param name="ResponseBody">The body of the queued response.</param>
    procedure AddMockResponse(StatusCode: Integer; ResponseBody: Text)
    begin
        MockHttpClientHandler.AddResponse(StatusCode, ResponseBody);
    end;

    /// <summary>
    /// Queues a mock response. Call multiple times to return a different response for each
    /// consecutive request: the first request gets the first queued response, and so on.
    /// Once the queue is exhausted, subsequent requests fall back to the response set with
    /// SetMockResponse; if none was set, the request receives a 500 response whose reason phrase
    /// states that no mock response was queued. Note that SetMockResponse clears the queue,
    /// so a fallback response must be set before queueing.
    /// </summary>
    /// <param name="NewHttpResponseMessage">The response to queue. The full message, including headers and reason phrase, is replayed. It is stored by reference, so use a separate variable for each queued response.</param>
    procedure AddMockResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    begin
        MockHttpClientHandler.AddResponse(NewHttpResponseMessage);
    end;

    /// <summary>
    /// Gets the URI of a recorded request.
    /// </summary>
    /// <param name="Index">The 1-based position of the request in the request history.</param>
    /// <returns>The request URI, or an empty text if no request was recorded at the given index.</returns>
    procedure GetMockHttpRequestUri(Index: Integer): Text
    begin
        exit(MockHttpClientHandler.GetHttpRequestUri(Index));
    end;

    /// <summary>
    /// Gets the HTTP method of a recorded request.
    /// </summary>
    /// <param name="Index">The 1-based position of the request in the request history.</param>
    /// <returns>The HTTP method (e.g. GET, POST), or an empty text if no request was recorded at the given index.</returns>
    procedure GetMockHttpRequestMethod(Index: Integer): Text
    begin
        exit(MockHttpClientHandler.GetHttpRequestMethod(Index));
    end;

    /// <summary>
    /// Gets the number of requests recorded by the mock handler.
    /// </summary>
    /// <returns>The number of requests sent since the last reset or SetMockResponse call.</returns>
    procedure GetMockRequestCount(): Integer
    begin
        exit(MockHttpClientHandler.GetRequestCount());
    end;

    /// <summary>
    /// Resets the mock handler to its initial state: clears the queued and fallback responses,
    /// the recorded request history, and any error set with ExpectRequestToFailWithError.
    /// </summary>
    procedure ResetMockHandler()
    begin
        this.MockHttpClientHandler.Reset();
    end;

    /// <summary>
    /// Gets the mock handler for injecting into the client under test,
    /// so that its requests are answered with the configured mock responses.
    /// </summary>
    /// <returns>The mock Http Client Handler.</returns>
    procedure GetMockHandler(): Interface "Http Client Handler"
    begin
        exit(this.MockHttpClientHandler);
    end;
}