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
        httpRequestMessages: List of [Text];
        httpResponseBodies: List of [Text];
        httpResponseStatusCodes: List of [Integer];
        currentResponseIndex: Integer;
        sendError: Text;

    procedure Send(HttpClient: HttpClient; HttpRequestMessage: Codeunit System.RestClient."Http Request Message"; var HttpResponseMessage: Codeunit System.RestClient."Http Response Message") Success: Boolean;
    begin
        ClearLastError();
        exit(TrySend(HttpRequestMessage, HttpResponseMessage));
    end;

    procedure ExpectSendToFailWithError(NewSendError: Text)
    begin
        this.SendError := NewSendError;
    end;

    procedure AddResponse(StatusCode: Integer; ResponseBody: Text)
    begin
        this.httpResponseStatusCodes.Add(StatusCode);
        this.httpResponseBodies.Add(ResponseBody);
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
        if (Index > 0) and (Index <= this.httpRequestMessages.Count()) then
            exit(this.httpRequestMessages.Get(Index));
    end;

    procedure GetRequestCount(): Integer
    begin
        exit(this.httpRequestMessages.Count());
    end;

    procedure Reset()
    begin
        Clear(this.httpRequestMessages);
        Clear(this.httpResponseBodies);
        Clear(this.httpResponseStatusCodes);
        this.currentResponseIndex := 0;
        this.sendError := '';
    end;

    [TryFunction]
    local procedure TrySend(HttpRequestMessage: Codeunit System.RestClient."Http Request Message"; var HttpResponseMessage: Codeunit System.RestClient."Http Response Message")
    var
        HttpContent: Codeunit "Http Content";
    begin
        this.httpRequestMessages.Add(HttpRequestMessage.GetRequestUri());

        if this.sendError <> '' then
            Error(this.sendError);

        this.currentResponseIndex += 1;
        if (this.currentResponseIndex > 0) and (this.currentResponseIndex <= this.httpResponseBodies.Count()) then begin
            HttpResponseMessage.SetHttpStatusCode(this.httpResponseStatusCodes.Get(this.currentResponseIndex));
            HttpContent := HttpContent.Create(this.httpResponseBodies.Get(this.currentResponseIndex));
            HttpResponseMessage.SetContent(HttpContent);
        end else
            Error('No more mock responses available. Request index: %1, Available responses: %2', this.currentResponseIndex, this.httpResponseBodies.Count());
    end;
}