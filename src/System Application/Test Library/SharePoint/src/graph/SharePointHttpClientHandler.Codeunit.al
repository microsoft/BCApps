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
        HttpRequestMessage: Codeunit "Http Request Message";
        HttpResponseMessage: Codeunit "Http Response Message";
        ResponseMessageSet: Boolean;
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
        this.HttpResponseMessage := NewHttpResponseMessage;
        this.ResponseMessageSet := true;
    end;

    procedure GetHttpRequestMessage(var OutHttpRequestMessage: Codeunit "Http Request Message")
    begin
        OutHttpRequestMessage := this.HttpRequestMessage;
    end;

    [TryFunction]
    local procedure TrySend(InHttpRequestMessage: Codeunit "Http Request Message"; var OutHttpResponseMessage: Codeunit "Http Response Message")
    begin
        this.HttpRequestMessage := InHttpRequestMessage;
        if SendError <> '' then
            Error(SendError);

        if ResponseMessageSet then
            OutHttpResponseMessage := this.HttpResponseMessage;
    end;
}