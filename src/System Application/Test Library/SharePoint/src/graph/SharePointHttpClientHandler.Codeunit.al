// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.Integration.Sharepoint;

using System.RestClient;

codeunit 132981 "SharePoint Http Client Handler" implements "Http Client Handler"
{
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        LastHttpRequestMessage: Codeunit "Http Request Message";
        SingleHttpResponseMessage: Codeunit "Http Response Message";
        QueuedHttpResponseMessages: array[25] of Codeunit "Http Response Message";
        HttpRequestUris: List of [Text];
        HttpRequestMethods: List of [Text];
        QueuedResponseCount: Integer;
        CurrentResponseIndex: Integer;
        SingleResponseSet: Boolean;
        SendError: Text;
        ResponseQueueFullErr: Label 'Cannot queue more than %1 mock responses.', Locked = true;
        NoMockResponseTxt: Label 'No mock response queued. Request count: %1, queue size: %2', Locked = true;

    procedure Send(HttpClient: HttpClient; InHttpRequestMessage: Codeunit "Http Request Message"; var OutHttpResponseMessage: Codeunit "Http Response Message") Success: Boolean;
    begin
        ClearLastError();
        exit(TrySend(InHttpRequestMessage, OutHttpResponseMessage));
    end;

    procedure ExpectSendToFailWithError(NewSendError: Text)
    begin
        this.SendError := NewSendError;
    end;

    procedure SetResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    begin
        Clear(this.QueuedHttpResponseMessages);
        this.QueuedResponseCount := 0;
        this.CurrentResponseIndex := 0;
        Clear(this.HttpRequestUris);
        Clear(this.HttpRequestMethods);
        this.SingleHttpResponseMessage := NewHttpResponseMessage;
        this.SingleResponseSet := true;
    end;

    procedure GetHttpRequestMessage(var OutHttpRequestMessage: Codeunit "Http Request Message")
    begin
        OutHttpRequestMessage := this.LastHttpRequestMessage;
    end;

    procedure AddResponse(StatusCode: Integer; ResponseBody: Text)
    var
        HttpResponseMessage: Codeunit "Http Response Message";
        HttpContent: Codeunit "Http Content";
    begin
        HttpResponseMessage.SetHttpStatusCode(StatusCode);
        HttpContent := HttpContent.Create(ResponseBody);
        HttpResponseMessage.SetContent(HttpContent);
        AddResponse(HttpResponseMessage);
    end;

    procedure AddResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    begin
        if this.QueuedResponseCount >= ArrayLen(this.QueuedHttpResponseMessages) then
            Error(this.ResponseQueueFullErr, ArrayLen(this.QueuedHttpResponseMessages));

        this.QueuedResponseCount += 1;
        this.QueuedHttpResponseMessages[this.QueuedResponseCount] := NewHttpResponseMessage;
    end;

    procedure GetHttpRequestUri(Index: Integer): Text
    begin
        if (Index > 0) and (Index <= this.HttpRequestUris.Count()) then
            exit(this.HttpRequestUris.Get(Index));
    end;

    procedure GetHttpRequestMethod(Index: Integer): Text
    begin
        if (Index > 0) and (Index <= this.HttpRequestMethods.Count()) then
            exit(this.HttpRequestMethods.Get(Index));
    end;

    procedure GetRequestCount(): Integer
    begin
        exit(this.HttpRequestUris.Count());
    end;

    procedure Reset()
    begin
        ClearAll();
    end;

    [TryFunction]
    local procedure TrySend(InHttpRequestMessage: Codeunit "Http Request Message"; var OutHttpResponseMessage: Codeunit "Http Response Message")
    begin
        this.LastHttpRequestMessage := InHttpRequestMessage;
        this.HttpRequestUris.Add(InHttpRequestMessage.GetRequestUri());
        this.HttpRequestMethods.Add(InHttpRequestMessage.GetHttpMethod());

        if this.SendError <> '' then
            Error(this.SendError);

        if this.CurrentResponseIndex < this.QueuedResponseCount then begin
            this.CurrentResponseIndex += 1;
            OutHttpResponseMessage := this.QueuedHttpResponseMessages[this.CurrentResponseIndex];
        end else
            if this.SingleResponseSet then
                OutHttpResponseMessage := this.SingleHttpResponseMessage
            else begin
                OutHttpResponseMessage.SetHttpStatusCode(500);
                OutHttpResponseMessage.SetReasonPhrase(StrSubstNo(this.NoMockResponseTxt, this.HttpRequestUris.Count(), this.QueuedResponseCount));
            end;
    end;
}
