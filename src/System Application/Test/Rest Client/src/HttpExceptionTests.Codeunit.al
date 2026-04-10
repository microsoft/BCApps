// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.RestClient;

using System.RestClient;
using System.TestLibraries.Utilities;

codeunit 134977 "Http Exception Tests"
{
    Subtype = Test;

    var
        Assert: Codeunit "Library Assert";
        HttpClientHandler: Codeunit "Test Http Client Handler";

    [Test]
    procedure TestConnectionFailed()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        // [SCENARIO] Error is raised when the connection fails

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockConnectionFailed();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        asserterror HttpResponseMessage := RestClient.Get('http://www.example.com');

        // [THEN] RestClient returns an error
        Assert.ExpectedError('Connection to the remote service "http://www.example.com/" could not be established.');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestConnectionFailedWithErrorCollection()
    var
        RestClient: Codeunit "Rest Client";
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        HttpResponseMessage: Codeunit "Http Response Message";
        Exceptions: List of [ErrorInfo];
        Exception: ErrorInfo;
        RestClientException: Enum "Rest Client Exception";
    begin
        // [SCENARIO] Error is raised when the connection fails

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockConnectionFailed();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        HttpResponseMessage := RestClient.Get('http://www.example.com');

        // [THEN] RestClient returns one collectible error of type ConnectionFailed
        Assert.IsTrue(HasCollectedErrors(), 'No collectible error was returned');
        Exceptions := GetCollectedErrors(true);
        Assert.AreEqual(1, Exceptions.Count, 'There should be 1 exception');

        Exception := Exceptions.Get(1);
        RestClientException := RestClientExceptionBuilder.GetRestClientException(Exception);
        Assert.AreEqual(Enum::"Rest Client Exception"::ConnectionFailed, RestClientException, 'The exception should be of type ConnectionFailed');
        Assert.AreEqual('ConnectionFailed', Exception.CustomDimensions.Get('ExceptionName'), 'The exception name should be "ConnectionFailed"');
        Assert.AreEqual('Connection to the remote service "http://www.example.com/" could not be established.', Exception.Message, 'The error message is incorrect');
    end;

    [Test]
    procedure TestBlockedByEnvironment()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        // [SCENARIO] Error is raised when the request is blocked by the environment

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockIsBlockedByEnvironment();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        asserterror HttpResponseMessage := RestClient.Get('http://www.example.com');

        // [THEN] RestClient returns an error
        Assert.ExpectedError('The outgoing HTTP request to "http://www.example.com/" was blocked by the environment.');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestBlockedByEnvironmentWithErrorCollection()
    var
        RestClient: Codeunit "Rest Client";
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        HttpResponseMessage: Codeunit "Http Response Message";
        Exceptions: List of [ErrorInfo];
        Exception: ErrorInfo;
        RestClientException: Enum "Rest Client Exception";
    begin
        // [SCENARIO] Error is raised when the request is blocked by the environment

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockIsBlockedByEnvironment();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        HttpResponseMessage := RestClient.Get('http://www.example.com');

        // [THEN] RestClient returns one collectible error of type BlockedByEnvironment
        Assert.IsTrue(HasCollectedErrors(), 'No collectible error was returned');
        Exceptions := GetCollectedErrors(true);
        Assert.AreEqual(1, Exceptions.Count, 'There should be 1 exception');

        Exception := Exceptions.Get(1);
        RestClientException := RestClientExceptionBuilder.GetRestClientException(Exception);
        Assert.AreEqual(Enum::"Rest Client Exception"::BlockedByEnvironment, RestClientException, 'The exception should be of type BlockedByEnvironment');
        Assert.AreEqual('BlockedByEnvironment', Exception.CustomDimensions.Get('ExceptionName'), 'The exception name should be "BlockedByEnvironment"');
        Assert.AreEqual('The outgoing HTTP request to "http://www.example.com/" was blocked by the environment.', Exception.Message, 'The error message is incorrect');
    end;

    [Test]
    procedure TestRequestFailedOnGenericMethod()
    var
        RestClient: Codeunit "Rest Client";
        HttpResponseMessage: Codeunit "Http Response Message";
    begin
        // [SCENARIO] Error is raised when the request fails

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockRequestFailed();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        HttpResponseMessage := RestClient.Get('http://www.example.com');

        // [THEN] HttpResponseMessage contains an error
        Assert.IsFalse(HttpResponseMessage.GetIsSuccessStatusCode(), 'The request should not be successful');
        asserterror Error(HttpResponseMessage.GetException());
        Assert.ExpectedError('The request to "http://www.example.com/" failed with status code 400 Bad Request.');
    end;

    [Test]
    procedure TestRequestFailedOnTypedMethod()
    var
        RestClient: Codeunit "Rest Client";
        JsonToken: JsonToken;
    begin
        // [SCENARIO] Error is raised when the request fails

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockRequestFailed();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        asserterror JsonToken := RestClient.GetAsJson('http://www.example.com');

        // [THEN] HttpResponseMessage contains an error
        Assert.ExpectedError('The request to "http://www.example.com/" failed with status code 400 Bad Request.');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestRequestFailedWithErrorCollection()
    var
        RestClient: Codeunit "Rest Client";
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        JsonToken: JsonToken;
        Exceptions: List of [ErrorInfo];
        Exception: ErrorInfo;
        RestClientException: Enum "Rest Client Exception";
    begin
        // [SCENARIO] Error is raised when the request fails

        // [GIVEN] An initialized Rest Client
        HttpClientHandler.SetMockRequestFailed();
        RestClient := RestClient.Create(HttpClientHandler);

        // [WHEN] Sending a request
        JsonToken := RestClient.GetAsJson('http://www.example.com');

        // [THEN] RestClient returns one collectible error of type RequestFailed
        Assert.IsTrue(HasCollectedErrors(), 'No collectible error was returned');
        Exceptions := GetCollectedErrors(true);
        Assert.AreEqual(1, Exceptions.Count, 'There should be 1 exception');

        Exception := Exceptions.Get(1);
        RestClientException := RestClientExceptionBuilder.GetRestClientException(Exception);
        Assert.AreEqual(Enum::"Rest Client Exception"::RequestFailed, RestClientException, 'The exception should be of type RequestFailed');
        Assert.AreEqual('RequestFailed', Exception.CustomDimensions.Get('ExceptionName'), 'The exception name should be "RequestFailed"');
        Assert.AreEqual('The request to "http://www.example.com/" failed with status code 400 Bad Request.', Exception.Message, 'The error message is incorrect');
    end;

    [Test]
    procedure TestInvalidJson()
    var
        HttpContent: Codeunit "Http Content";
        JsonToken: JsonToken;
    begin
        // [SCENARIO] Error is raised when trying to read as JSON from a HttpContent object with invalid JSON

        // [GIVEN] HttpContent object with invalid JSON
        HttpContent := HttpContent.Create('{"key": "value"');

        // [WHEN] Trying to read as JSON
        asserterror JsonToken := HttpContent.AsJson();

        // [THEN] HttpContent returns an error
        Assert.ExpectedError('The content is not a valid JSON.');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestInvalidJsonWithErrorCollection()
    var
        HttpContent: Codeunit "Http Content";
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        JsonToken: JsonToken;
        Exceptions: List of [ErrorInfo];
        Exception: ErrorInfo;
        RestClientException: Enum "Rest Client Exception";
    begin
        // [SCENARIO] Error is raised when trying to read as JSON from a HttpContent object with invalid JSON

        // [GIVEN] HttpContent object with invalid JSON
        HttpContent := HttpContent.Create('{"key": "value"');

        // [WHEN] Trying to read as JSON
        JsonToken := HttpContent.AsJson();

        // [THEN] HttpContent returns one collectible error of type InvalidJson
        Assert.IsTrue(HasCollectedErrors(), 'No collectible error was returned');
        Exceptions := GetCollectedErrors(true);
        Assert.AreEqual(1, Exceptions.Count, 'There should be 1 exception');

        Exception := Exceptions.Get(1);
        RestClientException := RestClientExceptionBuilder.GetRestClientException(Exception);
        Assert.AreEqual(Enum::"Rest Client Exception"::InvalidJson, RestClientException, 'The exception should be of type InvalidJson');
        Assert.AreEqual('InvalidJson', Exception.CustomDimensions.Get('ExceptionName'), 'The exception name should be "InvalidJson"');
        Assert.AreEqual('The content is not a valid JSON.', Exception.Message, 'The message should be "The content is not a valid JSON."');
    end;

    [Test]
    procedure TestInvalidXml()
    var
        HttpContent: Codeunit "Http Content";
        XmlDocument: XmlDocument;
    begin
        // [SCENARIO] Error is raised when trying to read as XML from a HttpContent object with invalid XML

        // [GIVEN] HttpContent object with invalid XML
        HttpContent := HttpContent.Create('<root><child></root>');

        // [WHEN] Trying to read as XML
        asserterror XmlDocument := HttpContent.AsXmlDocument();

        // [THEN] HttpContent returns an error
        Assert.ExpectedError('The content is not a valid XML.');
    end;

    [Test]
    [ErrorBehavior(ErrorBehavior::Collect)]
    procedure TestInvalidXmlWithErrorCollection()
    var
        HttpContent: Codeunit "Http Content";
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
        XmlDocument: XmlDocument;
        Exceptions: List of [ErrorInfo];
        Exception: ErrorInfo;
        RestClientException: Enum "Rest Client Exception";
    begin
        // [SCENARIO] Error is raised when trying to read as XML from a HttpContent object with invalid XML

        // [GIVEN] HttpContent object with invalid XML
        HttpContent := HttpContent.Create('<root><child></root>');

        // [WHEN] Trying to read as XML
        XmlDocument := HttpContent.AsXmlDocument();

        // [THEN] HttpContent returns one collectible error of type InvalidXml
        Assert.IsTrue(HasCollectedErrors(), 'No collectible error was returned');
        Exceptions := GetCollectedErrors(true);
        Assert.AreEqual(1, Exceptions.Count, 'There should be 1 exception');

        Exception := Exceptions.Get(1);
        RestClientException := RestClientExceptionBuilder.GetRestClientException(Exception);
        Assert.AreEqual(Enum::"Rest Client Exception"::InvalidXml, RestClientException, 'The exception should be of type InvalidXml');
        Assert.AreEqual('InvalidXml', Exception.CustomDimensions.Get('ExceptionName'), 'The exception name should be "InvalidXml"');
        Assert.AreEqual('The content is not a valid XML.', Exception.Message, 'The message should be "The content is not a valid XML."');
    end;
}