// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration;

using System.Integration;
using System.RestClient;
using System.Test.RestClient;

codeunit 134968 "Http Client Foundation Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        TestHandler: Codeunit "Test Http Client Handler";

    [Test]
    procedure CreateRequestAddsTextAndSecretHeaders()
    var
        Foundation: Codeunit "Http Client Foundation";
        Request: Codeunit "Http Request Message";
        SecretValues: List of [SecretText];
    begin
        Foundation.CreateRequest(Enum::"Http Method"::POST, 'https://example.com', Request);
        Foundation.AddHeader(Request, 'Accept', 'application/json');
        Foundation.AddHeader(Request, 'X-Secret', SecretStrSubstNo('secret-value'));

        Assert.AreEqual('POST', Request.GetHttpMethod(), 'The request method is incorrect.');
        Assert.AreEqual('https://example.com/', Request.GetRequestUri(), 'The request URI is incorrect.');
        SecretValues := Request.GetSecretHeaderValues('X-Secret');
        Assert.AreEqual(1, SecretValues.Count(), 'The secret header should be present.');
    end;

    [Test]
    procedure BasicAuthenticationUsesSecretHeader()
    var
        Foundation: Codeunit "Http Client Foundation";
        Request: Codeunit "Http Request Message";
        SecretValues: List of [SecretText];
    begin
        Foundation.CreateRequest(Enum::"Http Method"::GET, 'https://example.com', Request);
        Foundation.AddBasicAuthentication(Request, 'user', SecretStrSubstNo('password'));

        SecretValues := Request.GetSecretHeaderValues('Authorization');
        Assert.AreEqual(1, SecretValues.Count(), 'The authorization header should be present.');
        Assert.AreEqual('Basic dXNlcjpwYXNzd29yZA==', SecretValues.Get(1).Unwrap(), 'The authorization header is incorrect.');
    end;

    [Test]
    procedure ValidateUrlRequiresHttps()
    var
        Foundation: Codeunit "Http Client Foundation";
    begin
        Assert.IsTrue(Foundation.ValidateUrl('https://example.com', false), 'A valid HTTPS URL should pass.');
        Assert.IsTrue(Foundation.ValidateUrl('http://example.com', true), 'HTTP should pass when explicitly allowed.');
        Assert.IsFalse(Foundation.ValidateUrl('http://example.com', false), 'HTTP should be rejected by default.');
        Assert.IsFalse(Foundation.ValidateUrl('not a URL', false), 'Malformed URLs should be rejected.');
    end;

    [Test]
    procedure SendDistinguishesTransportFailure()
    var
        Foundation: Codeunit "Http Client Foundation";
        Request: Codeunit "Http Request Message";
        Response: Codeunit "Http Response Message";
        ErrorMessage: Text;
        ErrorDetails: Text;
    begin
        TestHandler.SetMockConnectionFailed();
        Foundation.Initialize(TestHandler);
        Foundation.CreateRequest(Enum::"Http Method"::GET, 'https://example.com', Request);

        Assert.IsFalse(Foundation.Send(Request, Response, ErrorMessage, ErrorDetails), 'Transport failure should return false.');
        Assert.IsTrue(ErrorMessage.Contains('could not be sent'), 'Transport failure should provide an error message.');
        Assert.AreEqual('', ErrorDetails, 'Transport failure should not provide HTTP details.');
    end;

    [Test]
    procedure SendDistinguishesHttpFailure()
    var
        Foundation: Codeunit "Http Client Foundation";
        Request: Codeunit "Http Request Message";
        Response: Codeunit "Http Response Message";
        ErrorMessage: Text;
        ErrorDetails: Text;
    begin
        TestHandler.SetMockRequestFailed();
        Foundation.Initialize(TestHandler);
        Foundation.CreateRequest(Enum::"Http Method"::GET, 'https://example.com', Request);

        Assert.IsFalse(Foundation.Send(Request, Response, ErrorMessage, ErrorDetails), 'HTTP failure should return false.');
        Assert.IsTrue(ErrorMessage.Contains('status code 400 Bad Request'), 'HTTP failure should include status and reason.');
    end;

    [Test]
    procedure SendAndReadTextReturnsResponseBody()
    var
        Foundation: Codeunit "Http Client Foundation";
        Handler: Codeunit "Http Client Foundation Handler";
        Request: Codeunit "Http Request Message";
        Response: Codeunit "Http Response Message";
        ResponseBody: Text;
        ErrorMessage: Text;
        ErrorDetails: Text;
    begin
        Handler.Initialize('response body');
        Foundation.Initialize(Handler);
        Foundation.CreateRequest(Enum::"Http Method"::GET, 'https://example.com', Request);

        Assert.IsTrue(Foundation.SendAndReadText(Request, ResponseBody, ErrorMessage, ErrorDetails, Response), 'The request should succeed.');
        Assert.AreEqual('response body', ResponseBody, 'The response body is incorrect.');
    end;

    [Test]
    procedure SendAndReadBlobReturnsBinaryResponse()
    var
        Foundation: Codeunit "Http Client Foundation";
        Handler: Codeunit "Http Client Foundation Handler";
        Request: Codeunit "Http Request Message";
        Response: Codeunit "Http Response Message";
        ResponseBlob: Codeunit "Temp Blob";
        ErrorMessage: Text;
        ErrorDetails: Text;
        ResponseInStream: InStream;
        ResponseText: Text;
    begin
        Handler.Initialize('binary response');
        Foundation.Initialize(Handler);
        Foundation.CreateRequest(Enum::"Http Method"::PATCH, 'https://example.com', Request);

        Assert.IsTrue(Foundation.SendAndReadBlob(Request, ResponseBlob, ErrorMessage, ErrorDetails, Response), 'The request should succeed.');
        ResponseBlob.CreateInStream(ResponseInStream);
        ResponseInStream.ReadText(ResponseText);
        Assert.AreEqual('binary response', ResponseText, 'The binary response is incorrect.');
    end;
}

codeunit 134969 "Http Client Foundation Handler" implements "Http Client Handler"
{
    var
        ResponseBody: Text;
        ResponseStatusCode: Integer;
        ResponseReasonPhrase: Text;

    procedure Initialize(NewResponseBody: Text)
    begin
        ResponseBody := NewResponseBody;
        ResponseStatusCode := 200;
        ResponseReasonPhrase := 'OK';
    end;

    procedure Send(HttpClient: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean
    var
        HttpContent: Codeunit "Http Content";
    begin
        HttpContent := HttpContent.Create(ResponseBody);
        HttpResponseMessage.SetHttpStatusCode(ResponseStatusCode);
        HttpResponseMessage.SetReasonPhrase(ResponseReasonPhrase);
        HttpResponseMessage.SetIsSuccessStatusCode((ResponseStatusCode >= 200) and (ResponseStatusCode < 300));
        HttpResponseMessage.SetContent(HttpContent);
        exit(true);
    end;
}
