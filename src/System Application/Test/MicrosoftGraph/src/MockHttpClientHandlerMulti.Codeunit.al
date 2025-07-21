// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.Test.Integration.Graph;

using System.RestClient;

codeunit 135145 "Mock Http Client Handler Multi" implements "Http Client Handler"
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        _httpRequestMessages: List of [Text];
        _httpResponseBodies: List of [Text];
        _httpResponseStatusCodes: List of [Integer];
        _currentResponseIndex: Integer;
        _sendError: Text;

    procedure Send(HttpClient: HttpClient; HttpRequestMessage: Codeunit System.RestClient."Http Request Message"; var HttpResponseMessage: Codeunit System.RestClient."Http Response Message") Success: Boolean;
    begin
        ClearLastError();
        exit(TrySend(HttpRequestMessage, HttpResponseMessage));
    end;

    procedure ExpectSendToFailWithError(SendError: Text)
    begin
        _sendError := SendError;
    end;

    procedure AddResponse(StatusCode: Integer; ResponseBody: Text)
    begin
        _httpResponseStatusCodes.Add(StatusCode);
        _httpResponseBodies.Add(ResponseBody);
    end;

    procedure AddResponse(var NewHttpResponseMessage: Codeunit System.RestClient."Http Response Message")
    var
        ResponseBody: Text;
    begin
        ResponseBody := NewHttpResponseMessage.GetContent().AsText();
        AddResponse(NewHttpResponseMessage.GetHttpStatusCode(), ResponseBody);
    end;

    procedure GetHttpRequestUri(Index: Integer): Text
    begin
        if (Index > 0) and (Index <= _httpRequestMessages.Count()) then
            exit(_httpRequestMessages.Get(Index));
    end;

    procedure GetRequestCount(): Integer
    begin
        exit(_httpRequestMessages.Count());
    end;

    procedure Reset()
    begin
        Clear(_httpRequestMessages);
        Clear(_httpResponseBodies);
        Clear(_httpResponseStatusCodes);
        _currentResponseIndex := 0;
        _sendError := '';
    end;

    [TryFunction]
    local procedure TrySend(HttpRequestMessage: Codeunit System.RestClient."Http Request Message"; var HttpResponseMessage: Codeunit System.RestClient."Http Response Message")
    var
        HttpContent: Codeunit "Http Content";
    begin
        _httpRequestMessages.Add(HttpRequestMessage.GetRequestUri());

        if _sendError <> '' then
            Error(_sendError);

        _currentResponseIndex += 1;
        if (_currentResponseIndex > 0) and (_currentResponseIndex <= _httpResponseBodies.Count()) then begin
            HttpResponseMessage.SetHttpStatusCode(_httpResponseStatusCodes.Get(_currentResponseIndex));
            HttpContent := HttpContent.Create(_httpResponseBodies.Get(_currentResponseIndex));
            HttpResponseMessage.SetContent(HttpContent);
        end else
            Error('No more mock responses available. Request index: %1, Available responses: %2', _currentResponseIndex, _httpResponseBodies.Count());
    end;
}