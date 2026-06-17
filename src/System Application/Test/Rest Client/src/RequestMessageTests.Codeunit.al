// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.RestClient;

using System.RestClient;
using System.TestLibraries.Utilities;

codeunit 134972 "Request Message Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure TestSetHttpMethod()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpRequestMessage: HttpRequestMessage;
    begin
        // [SCENARIO] The request message is initialized with an empty content

        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod(Enum::"Http Method"::PATCH);

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        Assert.AreEqual('PATCH', HttpRequestMessage.Method(), 'The request message method is not correct.');
    end;

    [Test]
    procedure TestRequestMessageWithoutContent()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpRequestMessage: HttpRequestMessage;
    begin
        // [SCENARIO] The request message is initialized without content

        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('GET');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        Assert.AreEqual('GET', HttpRequestMessage.Method(), 'The request message method is not correct.');
        Assert.AreEqual('https://www.microsoft.com/', HttpRequestMessage.GetRequestUri(), 'The request message request URI is not correct.');
    end;

    [Test]
    procedure TestRequestMessageWithTextContent()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpContent: Codeunit "Http Content";
        HttpRequestMessage: HttpRequestMessage;
        ContentHeaders: HttpHeaders;
        ContentHeaderValues: List of [Text];
        ContentText: Text;
    begin
        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('POST');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [GIVEN] The request message content is a text
        ALHttpRequestMessage.SetContent(HttpContent.Create('Hello World!'));

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        Assert.AreEqual('POST', HttpRequestMessage.Method(), 'The request message method is not correct.');
        Assert.AreEqual('https://www.microsoft.com/', HttpRequestMessage.GetRequestUri(), 'The request message request URI is not correct.');

        HttpRequestMessage.Content().ReadAs(ContentText);
        Assert.AreEqual('Hello World!', ContentText, 'The request message content is not correct.');

        HttpRequestMessage.Content.GetHeaders(ContentHeaders);
        Assert.AreEqual(true, ContentHeaders.Contains('Content-Type'), 'The content type header is missing.');

        ContentHeaders.GetValues('Content-Type', ContentHeaderValues);
        Assert.AreEqual('text/plain', ContentHeaderValues.Get(1), 'The request message content type is not correct.');
    end;

    [Test]
    procedure TestRequestMessageWithJsonContent()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpContent: Codeunit "Http Content";
        HttpRequestMessage: HttpRequestMessage;
        ContentHeaders: HttpHeaders;
        ContentHeaderValues: List of [Text];
        ContentJson: JsonObject;
        ContentText: Text;
    begin
        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('POST');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [GIVEN] The request message content is a JSON object
        ContentJson.Add('value', 'Hello World!');
        ALHttpRequestMessage.SetContent(HttpContent.Create(ContentJson));

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        Assert.AreEqual('POST', HttpRequestMessage.Method(), 'The request message method is not correct.');
        Assert.AreEqual('https://www.microsoft.com/', HttpRequestMessage.GetRequestUri(), 'The request message request URI is not correct.');

        HttpRequestMessage.Content().ReadAs(ContentText);
        Assert.AreEqual(true, ContentJson.ReadFrom(ContentText), 'The request message content is not a valid JSON object.');
        Assert.AreEqual(true, ContentJson.Contains('value'), 'The request message content does not contain the expected property "value".');
        Assert.AreEqual('Hello World!', GetJsonToken(ContentJson, 'value').AsValue().AsText(), 'The request message content property "value" is not correct.');

        HttpRequestMessage.Content.GetHeaders(ContentHeaders);
        Assert.AreEqual(true, ContentHeaders.Contains('Content-Type'), 'The content type header is missing.');

        ContentHeaders.GetValues('Content-Type', ContentHeaderValues);
        Assert.AreEqual('application/json', ContentHeaderValues.Get(1), 'The request message content type is not correct.');
    end;

    [Test]
    procedure TestAddRequestHeader()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpRequestMessage: HttpRequestMessage;
        ContentHeaders: HttpHeaders;
        ContentHeaderValues: List of [Text];
    begin
        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('GET');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [GIVEN] The request message has a custom header
        ALHttpRequestMessage.SetHeader('X-Custom-Header', 'My Request Header');

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        HttpRequestMessage.GetHeaders(ContentHeaders);
        Assert.IsTrue(ContentHeaders.Contains('X-Custom-Header'), 'The custom header is missing.');

        ContentHeaders.GetValues('X-Custom-Header', ContentHeaderValues);
        Assert.AreEqual('My Request Header', ContentHeaderValues.Get(1), 'The custom header value is not correct.');
    end;

    [Test]
    [NonDebuggable]
    procedure TestAddSecretRequestHeader()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpRequestMessage: HttpRequestMessage;
        ContentHeaders: HttpHeaders;
        SecretHeaderText: SecretText;
        ContentHeaderValues: List of [SecretText];
    begin
        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('GET');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [GIVEN] The request message has a secret header
        SecretHeaderText := SecretStrSubstNo('My Secret Request Header');
        ALHttpRequestMessage.SetHeader('X-Secret-Header', SecretHeaderText);

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        HttpRequestMessage.GetHeaders(ContentHeaders);
        Assert.IsTrue(ContentHeaders.ContainsSecret('X-Secret-Header'), 'The secret header is missing.');

        ContentHeaders.GetSecretValues('X-Secret-Header', ContentHeaderValues);
        Assert.AreEqual(SecretHeaderText.Unwrap(), ContentHeaderValues.Get(1).Unwrap(), 'The secret header value is not correct.');
    end;

    [Test]
    procedure TestAddCookie()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpRequestMessage: HttpRequestMessage;
        RequestCookie: Cookie;
    begin
        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('GET');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [GIVEN] The request message has a cookie
        ALHttpRequestMessage.SetCookie('MyCookie', 'MyCookieValue');

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        Assert.IsTrue(HttpRequestMessage.GetCookie('MyCookie', RequestCookie), 'The cookie is missing.');
        Assert.AreEqual('MyCookieValue', RequestCookie.Value(), 'The cookie value is not correct.');
    end;

    [Test]
    procedure TestRemoveCookie()
    var
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpRequestMessage: HttpRequestMessage;
        RequestCookie: Cookie;
    begin
        // [GIVEN] An initialized Http Request Message
        ALHttpRequestMessage.SetHttpMethod('GET');
        ALHttpRequestMessage.SetRequestUri('https://www.microsoft.com/');

        // [GIVEN] The request message has a cookie
        ALHttpRequestMessage.SetCookie('MyCookie', 'MyCookieValue');
        ALHttpRequestMessage.RemoveCookie('MyCookie');

        // [WHEN] The request message is read
        HttpRequestMessage := ALHttpRequestMessage.GetHttpRequestMessage();

        // [THEN] The request message is initialized correctly
        Assert.IsFalse(HttpRequestMessage.GetCookie('MyCookie', RequestCookie), 'The cookie is not removed.');
    end;


    local procedure GetJsonToken(JsonObject: JsonObject; Name: Text) JsonToken: JsonToken
    begin
        JsonObject.Get(Name, JsonToken);
    end;
}