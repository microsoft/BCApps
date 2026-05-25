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
        HttpRequestUris: List of [Text];
        HttpRequestMethods: List of [Text];
        QueuedStatusCodes: List of [Integer];
        QueuedBodies: List of [Text];
        CurrentResponseIndex: Integer;
        SingleResponseSet: Boolean;
        SendError: Text;

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
        Clear(this.QueuedStatusCodes);
        Clear(this.QueuedBodies);
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
    begin
        this.QueuedStatusCodes.Add(StatusCode);
        this.QueuedBodies.Add(ResponseBody);
    end;

    procedure AddResponse(var NewHttpResponseMessage: Codeunit "Http Response Message")
    var
        ResponseBody: Text;
    begin
        ResponseBody := NewHttpResponseMessage.GetContent().AsText();
        AddResponse(NewHttpResponseMessage.GetHttpStatusCode(), ResponseBody);
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
        Clear(this.HttpRequestUris);
        Clear(this.HttpRequestMethods);
        Clear(this.QueuedStatusCodes);
        Clear(this.QueuedBodies);
        this.CurrentResponseIndex := 0;
        this.SingleResponseSet := false;
        this.SendError := '';
    end;

    [TryFunction]
    local procedure TrySend(InHttpRequestMessage: Codeunit "Http Request Message"; var OutHttpResponseMessage: Codeunit "Http Response Message")
    var
        HttpContent: Codeunit "Http Content";
    begin
        this.LastHttpRequestMessage := InHttpRequestMessage;
        this.HttpRequestUris.Add(InHttpRequestMessage.GetRequestUri());
        this.HttpRequestMethods.Add(InHttpRequestMessage.GetHttpMethod());

        if this.SendError <> '' then
            Error(this.SendError);

        if (this.QueuedBodies.Count() > 0) and (this.CurrentResponseIndex < this.QueuedBodies.Count()) then begin
            this.CurrentResponseIndex += 1;
            OutHttpResponseMessage.SetHttpStatusCode(this.QueuedStatusCodes.Get(this.CurrentResponseIndex));
            HttpContent := HttpContent.Create(this.QueuedBodies.Get(this.CurrentResponseIndex));
            OutHttpResponseMessage.SetContent(HttpContent);
        end else
            if this.SingleResponseSet then
                OutHttpResponseMessage := this.SingleHttpResponseMessage
            else
                Error('No mock response queued. Request count: %1, queue size: %2', this.HttpRequestUris.Count(), this.QueuedBodies.Count());
    end;
}