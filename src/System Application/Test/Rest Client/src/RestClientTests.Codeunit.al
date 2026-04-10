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
    TestHttpRequestPolicy = BlockOutboundRequests;

    var
        Assert: Codeunit "Library Assert";
        HttpClientHandler: Codeunit "Test Http Client Handler";
        MockRestClientService: Codeunit "Mock Rest Client Service";
        ResponseBodyUrlTxt: Label '{"url": "%1"}', Locked = true;

    local procedure Initialize()
    begin
        Clear(MockRestClientService);
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestGet()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        Initialize();

        // [SCENARIO] Test GET request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Get method is called
        MockRestClientService.SetResponse(GetResponseData(MockRestClientService.GetGetUrl()));
        HttpResponseMessage := RestClient.Get(MockRestClientService.GetGetUrl());

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetGetUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestGetWithQueryParameters()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        QueryParameters: Text;
        QueryParametersDictionary: Dictionary of [Text, Text];
        ResponseBodyTxt: Text;
    begin
        Initialize();

        // [SCENARIO] Test GET request with query parameters

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);

        // [WHEN] The Get method is called with query parameters                              
        QueryParameters := '?param1=value1&param2=value2';
        QueryParametersDictionary.Add('param1', 'value1');
        QueryParametersDictionary.Add('param2', 'value2');
        MockRestClientService.SetQueryParameters(QueryParametersDictionary);

        ResponseBodyTxt := GetResponseData(MockRestClientService.GetGetUrl() + QueryParameters);
        ResponseBodyTxt := AddResponseData(ResponseBodyTxt, 'param1', 'value1');
        ResponseBodyTxt := AddResponseData(ResponseBodyTxt, 'param2', 'value2');
        MockRestClientService.SetResponse(ResponseBodyTxt);
        HttpResponseMessage := RestClient.Get(MockRestClientService.GetGetUrl() + QueryParameters);

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual('value1', SelectJsonToken(JsonObject, 'param1').AsValue().AsText(), 'The response should contain the expected query parameter');
        Assert.AreEqual('value2', SelectJsonToken(JsonObject, 'param2').AsValue().AsText(), 'The response should contain the expected query parameter');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestPost()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        ResponseBodyTxt: Text;
        ResponseText: Text;
    begin
        Initialize();

        // [SCENARIO] Test POST request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        ResponseText := 'Hello World';

        ResponseBodyTxt := GetResponseData(MockRestClientService.GetPostUrl());
        ResponseBodyTxt := AddResponseData(ResponseBodyTxt, 'data', ResponseText);
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The Post method is called
        HttpResponseMessage := RestClient.Post(MockRestClientService.GetPostUrl(), HttpGetContent.Create(ResponseText));

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetPostUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual(ResponseText, GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestPatch()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        ResponseText: Text;
        ResponseBodyTxt: Text;
    begin
        Initialize();

        // [SCENARIO] Test PATCH request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        ResponseText := 'Hello World';

        ResponseBodyTxt := GetResponseData(MockRestClientService.GetPatchUrl());
        ResponseBodyTxt := AddResponseData(ResponseBodyTxt, 'data', ResponseText);
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The Patch method is called
        HttpResponseMessage := RestClient.Patch(MockRestClientService.GetPatchUrl(), HttpGetContent.Create(ResponseText));

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetPatchUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual(ResponseText, GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestPut()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        ResponseBodyTxt: Text;
        ResponseText: Text;
    begin
        Initialize();

        // [SCENARIO] Test PUT request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        ResponseText := 'Hello World';
        ResponseBodyTxt := GetResponseData(MockRestClientService.GetPutUrl());
        ResponseBodyTxt := AddResponseData(ResponseBodyTxt, 'data', ResponseText);
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The Put method is called
        HttpResponseMessage := RestClient.Put(MockRestClientService.GetPutUrl(), HttpGetContent.Create(ResponseText));

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetPutUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual(ResponseText, GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestDelete()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        ResponseBodyTxt: Text;
    begin
        Initialize();

        // [SCENARIO] Test DELETE request

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        ResponseBodyTxt := GetResponseData(MockRestClientService.GetDeleteUrl());
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The Delete method is called
        HttpResponseMessage := RestClient.Delete(MockRestClientService.GetDeleteUrl());

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetDeleteUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;


    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestBaseAddress()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        ResponseBodyTxt: Text;
    begin
        Initialize();

        // [SCENARIO] Test GET request with base address

        // [GIVEN] An initialized Rest Client with base address
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RestClient.SetBaseAddress(MockRestClientService.GetBaseURL());
        ResponseBodyTxt := GetResponseData(MockRestClientService.GetGetUrl());
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The Get method is called with relative url
        HttpResponseMessage := RestClient.Get('get');

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetGetUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestGetAsJson()
    var
        RestClient: Codeunit "Rest Client";
        JsonObject: JsonObject;
        ResponseBodyTxt: Text;
    begin
        Initialize();

        // [SCENARIO] Test GET request with JSON response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        ResponseBodyTxt := GetResponseData(MockRestClientService.GetGetUrl());
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The GetAsJson method is called
        JsonObject := RestClient.GetAsJson(MockRestClientService.GetGetUrl()).AsObject();

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(MockRestClientService.GetGetUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestPostAsJson()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        JsonObject1: JsonObject;
        JsonObject2: JsonObject;
        RequestURL: Text;
    begin
        Initialize();

        // [SCENARIO] Test POST request with JSON request and response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RequestURL := MockRestClientService.GetPostUrl();

        // [GIVEN] A Json object
        JsonObject1.Add('name', 'John');
        JsonObject1.Add('age', 30);
        HttpGetContent := HttpGetContent.Create(JsonObject1);
        MockRestClientService.SetResponse(GetResponseData(RequestURL, JsonObject1));

        // [WHEN] The PostAsJson method is called with a Json object
        JsonObject2 := RestClient.PostAsJson(RequestURL, JsonObject1).AsObject();

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(RequestURL, GetJsonToken(JsonObject2, 'url').AsValue().AsText(), 'The response should contain the expected url');
        JsonObject2.ReadFrom(GetJsonToken(JsonObject2, 'data').AsValue().AsText());
        Assert.AreEqual('John', GetJsonToken(JsonObject2, 'name').AsValue().AsText(), 'The response should contain the expected data');
        Assert.AreEqual(30, GetJsonToken(JsonObject2, 'age').AsValue().AsInteger(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestPatchAsJson()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        JsonObject1: JsonObject;
        JsonObject2: JsonObject;
        RequestURL: Text;
    begin
        Initialize();

        // [SCENARIO] Test PATCH request with JSON request and response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RequestURL := MockRestClientService.GetPatchUrl();

        // [GIVEN] A Json object
        JsonObject1.Add('name', 'John');
        JsonObject1.Add('age', 30);

        HttpGetContent := HttpGetContent.Create(JsonObject1);
        MockRestClientService.SetResponse(GetResponseData(RequestURL, JsonObject1));

        // [WHEN] The PatchAsJson method is called with a Json object
        JsonObject2 := RestClient.PatchAsJson(RequestURL, JsonObject1).AsObject();

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(RequestURL, GetJsonToken(JsonObject2, 'url').AsValue().AsText(), 'The response should contain the expected url');
        JsonObject2.ReadFrom(GetJsonToken(JsonObject2, 'data').AsValue().AsText());
        Assert.AreEqual('John', GetJsonToken(JsonObject2, 'name').AsValue().AsText(), 'The response should contain the expected data');
        Assert.AreEqual(30, GetJsonToken(JsonObject2, 'age').AsValue().AsInteger(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestPutAsJson()
    var
        RestClient: Codeunit "Rest Client";
        HttpGetContent: Codeunit "Http Content";
        JsonObject1: JsonObject;
        JsonObject2: JsonObject;
        RequestURL: Text;
    begin
        Initialize();

        // [SCENARIO] Test PUT request with JSON request and response

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RequestURL := MockRestClientService.GetPutUrl();

        // [GIVEN] A Json object
        JsonObject1.Add('name', 'John');
        JsonObject1.Add('age', 30);
        HttpGetContent := HttpGetContent.Create(JsonObject1);
        MockRestClientService.SetResponse(GetResponseData(RequestURL, JsonObject1));

        // [WHEN] The PutAsJson method is called with a Json object
        JsonObject2 := RestClient.PutAsJson(RequestURL, JsonObject1).AsObject();

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(RequestURL, GetJsonToken(JsonObject2, 'url').AsValue().AsText(), 'The response should contain the expected url');
        JsonObject2.ReadFrom(GetJsonToken(JsonObject2, 'data').AsValue().AsText());
        Assert.AreEqual('John', GetJsonToken(JsonObject2, 'name').AsValue().AsText(), 'The response should contain the expected data');
        Assert.AreEqual(30, GetJsonToken(JsonObject2, 'age').AsValue().AsInteger(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestSendWithoutGetContent()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        Initialize();

        // [SCENARIO] Test Send method without Getcontent

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        MockRestClientService.SetResponse(GetResponseData(MockRestClientService.GetGetUrl()));

        // [WHEN] The Send method is called without Getcontent
        HttpResponseMessage := RestClient.Send(Enum::"Http Method"::GET, MockRestClientService.GetGetUrl());

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetGetUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestSendWithGetContent()
    var
        RestClient: Codeunit "Rest Client";
        HttpContent: Codeunit "Http Content";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
        ResponseBodyTxt: Text;
        RequestText: Text;
    begin
        Initialize();

        // [SCENARIO] Test Send method with Get content

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        RequestText := 'Hello World';
        ResponseBodyTxt := GetResponseData(MockRestClientService.GetPostUrl());
        ResponseBodyTxt := AddResponseData(ResponseBodyTxt, 'data', RequestText);
        MockRestClientService.SetResponse(ResponseBodyTxt);

        // [WHEN] The Send method is called with Get content
        HttpResponseMessage := RestClient.Send(Enum::"Http Method"::POST, MockRestClientService.GetPostUrl(), HttpContent.Create(RequestText));

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetPostUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
        Assert.AreEqual(RequestText, GetJsonToken(JsonObject, 'data').AsValue().AsText(), 'The response should contain the expected data');
    end;

    [Test]
    [HandlerFunctions('HandleRestClientCall')]
    procedure TestSendRequestMessage()
    var
        RestClient: Codeunit "Rest Client";
        ALHttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        JsonObject: JsonObject;
    begin
        Initialize();

        // [SCENARIO] Test Send method with request message

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.Initialize();
        RestClient.Initialize(HttpClientHandler);
        MockRestClientService.SetResponse(GetResponseData(MockRestClientService.GetGetUrl()));

        // [WHEN] The Send method is called with a request message
        ALHttpRequestMessage.SetHttpMethod(Enum::"Http Method"::GET);
        ALHttpRequestMessage.SetRequestUri(MockRestClientService.GetGetUrl());
        HttpResponseMessage := RestClient.Send(ALHttpRequestMessage);

        // [THEN] The response contains the expected data
        MockRestClientService.VerifyAllExpectedRequestWereHandled();
        Assert.AreEqual(200, HttpResponseMessage.GetHttpStatusCode(), 'The response status code should be 200');
        Assert.IsTrue(HttpResponseMessage.GetIsSuccessStatusCode(), 'GetIsSuccessStatusCode should be true');
        JsonObject := HttpResponseMessage.GetContent().AsJson().AsObject();
        Assert.AreEqual(MockRestClientService.GetGetUrl(), GetJsonToken(JsonObject, 'url').AsValue().AsText(), 'The response should contain the expected url');
    end;

    local procedure GetResponseData(Url: Text; BodyJsonObject: JsonObject): Text
    var
        ResponseBodyText: Text;
        JsonObjectText: Text;
    begin
        ResponseBodyText := GetResponseData(Url);
        BodyJsonObject.WriteTo(JsonObjectText);
        ResponseBodyText := AddResponseData(ResponseBodyText, 'data', JsonObjectText);
        exit(ResponseBodyText);
    end;

    local procedure GetResponseData(Url: Text): Text
    begin
        exit(StrSubstNo(ResponseBodyUrlTxt, Url));
    end;

    local procedure AddResponseData(ResponseBodyTxt: Text; ExpectedData1Name: Text; ExpectedData1: Text): Text
    var
        ResponseJsonObject: JsonObject;
        ResponseText: Text;
    begin
        ResponseJsonObject.ReadFrom(ResponseBodyTxt);
        ResponseJsonObject.Add(ExpectedData1Name, ExpectedData1);
        ResponseJsonObject.WriteTo(ResponseText);
        exit(ResponseText);
    end;

    local procedure GetJsonToken(JsonObject: JsonObject; Name: Text) JsonToken: JsonToken
    begin
        JsonObject.Get(Name, JsonToken);
    end;

    local procedure SelectJsonToken(JsonObject: JsonObject; Path: Text) JsonToken: JsonToken
    begin
        JsonObject.SelectToken(Path, JsonToken);
    end;

    [HttpClientHandler]
    procedure HandleRestClientCall(Request: TestHttpRequestMessage; var Response: TestHttpResponseMessage): Boolean
    begin
        MockRestClientService.HandleRequest(Request, Response);
        exit(false);
    end;
}