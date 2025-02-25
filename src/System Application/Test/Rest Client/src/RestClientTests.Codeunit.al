// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.RestClient;

using System.RestClient;
using System.TestLibraries.Utilities;

codeunit 134971 "Rest Client Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        HttpClientHandler: Codeunit "Test Http Client Handler";

    [Test]
    procedure TestGet()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Get method is called
        HttpResponseMessage := RestClient.Get('https://httpbin.org/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/get', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    procedure TestGetWithQueryParameters()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with query parameters

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Get method is called with query parameters
        HttpResponseMessage := RestClient.Get('https://httpbin.org/get?param1=value1&param2=value2');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('value1', SelectJsonToken(JsonObject, '$.args.param1').AsValue().AsText(), 'The response should contain the expected query parameter');
        Assert.AreEqual('value2', SelectJsonToken(JsonObject, '$.args.param2').AsValue().AsText(), 'The response should contain the expected query parameter');
    end;

    [Test]
    procedure TestPost()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test POST request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Post method is called
        HttpResponseMessage := RestClient.Post('https://httpbin.org/post', HttpGetContent.Create('Hello World'));

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/post', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual('Hello World', GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestPatch()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test PATCH request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Patch method is called
        HttpResponseMessage := RestClient.Patch('https://httpbin.org/patch', HttpGetContent.Create('Hello World'));

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/patch', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual('Hello World', GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestPut()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test PUT request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Put method is called
        HttpResponseMessage := RestClient.Put('https://httpbin.org/put', HttpGetContent.Create('Hello World'));

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/put', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual('Hello World', GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestDelete()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test DELETE request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Delete method is called
        HttpResponseMessage := RestClient.Delete('https://httpbin.org/delete');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/delete', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    procedure TestGetWithDefaultHeaders()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with headers

        // [GIVEN] An initialized Rest Client with default request headers
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RestClient.SetDefaultRequestHeader('X-Test-Header', 'Test');

        // [WHEN] The Get method is called with headers
        HttpResponseMessage := RestClient.Get('https://httpbin.org/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/get', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual('Test', SelectJsonToken(JsonObject, '$.headers.X-Test-Header').AsValue().AsText(), 'The response should contain the expected header');
    end;

    [Test]
    procedure TestBaseAddress()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with base address

        // [GIVEN] An initialized Rest Client with base address
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RestClient.SetBaseAddress('https://httpbin.org');

        // [WHEN] The Get method is called with relative url
        HttpResponseMessage := RestClient.Get('/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/get', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    procedure TestDefaultUserAgentHeader()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with default User-Agent header

        // [GIVEN] An initialized Rest Client 
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Get method is called using the default User-Agent header
        HttpResponseMessage := RestClient.Get('https://httpbin.org/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.IsTrue(SelectJsonToken(JsonObject, '$.headers.User-Agent').AsValue().AsText().StartsWith('Dynamics 365 Business Central '), 'The response should contain a User-Agent header');
    end;

    [Test]
    procedure TestCustomUserAgentHeader()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with custom User-Agent header

        // [GIVEN] An initialized Rest Client with a customer User-Agent header
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RestClient.SetUserAgentHeader('BC Rest Client Test');

        // [WHEN] The Get method is called using a custom User-Agent header
        HttpResponseMessage := RestClient.Get('https://httpbin.org/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('BC Rest Client Test', SelectJsonToken(JsonObject, '$.headers.User-Agent').AsValue().AsText(), 'The response should contain the expected User-Agent header');
    end;

    [Test]
    procedure TestGetAsJson()
    var
        RestClient: Codeunit "Rest Client";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with JSON response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The GetAsJson method is called
        JsonObject := RestClient.GetAsJson('https://httpbin.org/get').AsObject();

        // [THEN] The response contains the expected data
        Assert.AreEqual('https://httpbin.org/get', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestGetAsJsonWithCollectingErrors()
    var
        RestClient: Codeunit "Rest Client";
        JsonToken: JsonToken;
        ExceptionList: List of [ErrorInfo];
        Exception: ErrorInfo;
    begin
        // [SCENARIO] Test GET request with JSON response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The GetAsJson method is called
        JsonToken := RestClient.GetAsJson('https://httpbin.org/xml');

        // [THEN] The response contains the expected data
        ExceptionList := GetCollectedErrors(true);
        Exception := ExceptionList.Get(1);

        Assert.AreEqual('The content is not a valid JSON.', Exception.Message, 'The collected error message should be as expected');
    end;

    [Test]
    procedure TestPostAsJson()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        JsonObject1: JsonObject;
        JsonObject2: JsonObject;
    begin
        // [SCENARIO] Test POST request with JSON request and response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] A Json object
        JsonObject1.Add('name', 'John');
        JsonObject1.Add('age', 30);

        // [WHEN] The PostAsJson method is called with a Json object
        HttpGetContent := HttpGetContent.Create(JsonObject1);
        JsonObject2 := RestClient.PostAsJson('https://httpbin.org/post', JsonObject1).AsObject();

        // [THEN] The response contains the expected data
        Assert.AreEqual('https://httpbin.org/post', GetJsonToken(JsonObject2, 'url').AsValue().AsText(), 'The response should contain the expected url');
        JsonObject2.ReadFrom(GetJsonToken(JsonObject2, 'data').AsValue().AsText());
        Assert.AreEqual('John', GetJsonToken(JsonObject2, 'name').AsValue().AsText(), 'The response should contain the expected data');
        Assert.AreEqual(30, GetJsonToken(JsonObject2, 'age').AsValue().AsInteger(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestPatchAsJson()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        JsonObject1: JsonObject;
        JsonObject2: JsonObject;
    begin
        // [SCENARIO] Test PATCH request with JSON request and response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] A Json object
        JsonObject1.Add('name', 'John');
        JsonObject1.Add('age', 30);

        // [WHEN] The PatchAsJson method is called with a Json object
        HttpGetContent := HttpGetContent.Create(JsonObject1);
        JsonObject2 := RestClient.PatchAsJson('https://httpbin.org/patch', JsonObject1).AsObject();

        // [THEN] The response contains the expected data
        Assert.AreEqual('https://httpbin.org/patch', GetJsonToken(JsonObject2, 'url').AsValue().AsText(), 'The response should contain the expected url');
        JsonObject2.ReadFrom(GetJsonToken(JsonObject2, 'data').AsValue().AsText());
        Assert.AreEqual('John', GetJsonToken(JsonObject2, 'name').AsValue().AsText(), 'The response should contain the expected data');
        Assert.AreEqual(30, GetJsonToken(JsonObject2, 'age').AsValue().AsInteger(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestPutAsJson()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        JsonObject1: JsonObject;
        JsonObject2: JsonObject;
    begin
        // [SCENARIO] Test PUT request with JSON request and response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] A Json object
        JsonObject1.Add('name', 'John');
        JsonObject1.Add('age', 30);

        // [WHEN] The PutAsJson method is called with a Json object
        HttpGetContent := HttpGetContent.Create(JsonObject1);
        JsonObject2 := RestClient.PutAsJson('https://httpbin.org/put', JsonObject1).AsObject();

        // [THEN] The response contains the expected data
        Assert.AreEqual('https://httpbin.org/put', GetJsonToken(JsonObject2, 'url').AsValue().AsText(), 'The response should contain the expected url');
        JsonObject2.ReadFrom(GetJsonToken(JsonObject2, 'data').AsValue().AsText());
        Assert.AreEqual('John', GetJsonToken(JsonObject2, 'name').AsValue().AsText(), 'The response should contain the expected data');
        Assert.AreEqual(30, GetJsonToken(JsonObject2, 'age').AsValue().AsInteger(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestSendWithoutGetContent()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test Send method without Getcontent

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Send method is called without Getcontent
        HttpResponseMessage := RestClient.Send(Enum::"Http Method"::GET, 'https://httpbin.org/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/get', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    procedure TestSendWithGetContent()
    var
        RestClient: Codeunit "Rest Client";
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test Send method with Getcontent

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Send method is called with Getcontent
        HttpResponseMessage := RestClient.Send(Enum::"Http Method"::POST, 'https://httpbin.org/post', HttpContent.Create('Hello World'));

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/post', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual('Hello World', GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestSendRequestMessage()
    var
        RestClient: Codeunit "Rest Client";
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test Send method with request message

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Send method is called with a request message
        ALHttpRequestMessage.SetHttpMethod(Enum::"Http Method"::GET);
        ALHttpRequestMessage.SetRequestUri('https://httpbin.org/get');
        HttpResponseMessage := RestClient.Send(ALHttpRequestMessage);

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('https://httpbin.org/get', GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    procedure TestBasicAuthentication()
    var
        RestClient: Codeunit "Rest Client";
        HttpAuthenticationBasic: Codeunit "Http Authentication Basic";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        PasswordText: Text;
    begin
        // [SCENARIO] Test Http Get with Basic Authentication

        // [GIVEN] An initialized Rest Client with Basic Authentication
        PasswordText := 'Password123';
        HttpAuthenticationBasic.Initialize('user01', PasswordText);
        RestClient.Initialize(HttpClientHandler, HttpAuthenticationBasic);

        // [WHEN] The Get method is called
        HttpResponseMessage := RestClient.Get('https://httpbin.org/basic-auth/user01/Password123');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(true, GetJsonToken(JsonObject, 'authenticated').AsValue().AsBoolean(), 'The response should contain the expected data');
    end;

    [Test]
    procedure TestResponseWithCookies()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        // [SCENARIO] Test GET request with cookies

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Get method is called
        HttpResponseMessage := RestClient.Get('https://postman-echo.com/get');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        Assert.IsTrue(HttpResponseMessage.GetCookieNames().Contains('sails.sid'), 'The response should contain the expected cookie');
    end;

    [Test]
    procedure TestRequestWithCookies()
    var
        RestClient: Codeunit "Rest Client";
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with cookies

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] A request message with cookies
        HttpRequestMessage.SetRequestUri('https://httpbin.org/cookies');
        HttpRequestMessage.SetCookie('cookie1', 'value1');
        HttpRequestMessage.SetCookie('cookie2', 'value2');

        // [WHEN] The Send method is called with a request message
        HttpResponseMessage := RestClient.Send(HttpRequestMessage);

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('value1', SelectJsonToken(JsonObject, '$.cookies.cookie1').AsValue().AsText(), 'The response should contain the expected cookie1');
        Assert.AreEqual('value2', SelectJsonToken(JsonObject, '$.cookies.cookie2').AsValue().AsText(), 'The response should contain the expected cookie2');
    end;

    [Test]
    procedure TestWithoutUseResponseCookies()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        JsonToken: JsonToken;
    begin
        // [SCENARIO] Test GET request without using response cookies

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] Use response cookies is disabled
        RestClient.SetUseResponseCookies(false);

        // [GIVEN] Specific cookies are set
        HttpResponseMessage := RestClient.Get('https://httpbin.org/cookies/set?cookie1=value1');

        // [WHEN] The cookies list is retrieved
        HttpResponseMessage := RestClient.Get('https://httpbin.org/cookies');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.IsFalse(JsonObject.SelectToken('$.cookies.cookie1', JsonToken), 'The response should not contain cookies');
    end;

    [Test]
    procedure TestWithUseResponseCookies()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with using response cookies

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] Use response cookies is enabled
        RestClient.SetUseResponseCookies(true);

        // [GIVEN] Specific cookies are set
        HttpResponseMessage := RestClient.Get('https://httpbin.org/cookies/set?cookie1=value1');

        // [WHEN] The cookies list is retrieved
        HttpResponseMessage := RestClient.Get('https://httpbin.org/cookies');

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('value1', SelectJsonToken(JsonObject, '$.cookies.cookie1').AsValue().AsText(), 'The response should contain the expected cookie');
    end;

    [Test]
    procedure TestUseResponseCookiesWithAdditionalCookies()
    var
        RestClient: Codeunit "Rest Client";
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        // [SCENARIO] Test GET request with using response cookies and additional cookies

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [GIVEN] Use response cookies is enabled
        RestClient.SetUseResponseCookies(true);

        // [GIVEN] Specific cookies are set
        HttpResponseMessage := RestClient.Get('https://httpbin.org/cookies/set?cookie1=value1');

        // [WHEN] The cookies list is retrieved with additional cookies
        HttpRequestMessage.SetRequestUri('https://httpbin.org/cookies');
        HttpRequestMessage.SetCookie('cookie2', 'value2');
        HttpResponseMessage := RestClient.Send(HttpRequestMessage);

        // [THEN] The response contains the expected data
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('value1', SelectJsonToken(JsonObject, '$.cookies.cookie1').AsValue().AsText(), 'The response should contain the expected cookie1');
        Assert.AreEqual('value2', SelectJsonToken(JsonObject, '$.cookies.cookie2').AsValue().AsText(), 'The response should contain the expected cookie2');
    end;

    local procedure GetJsonToken(JsonObject: JsonObject; Name: Text) JsonToken: JsonToken
    begin
        JsonObject.Get(Name, JsonToken);
    end;

    local procedure SelectJsonToken(JsonObject: JsonObject; Path: Text) JsonToken: JsonToken
    begin
        JsonObject.SelectToken(Path, JsonToken);
    end;
}