// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Test.RestClient;

using System.RestClient;

codeunit 134974 "Test Http Client Handler" implements "Http Client Handler"
{
    SingleInstance = true;

    var
        MockConnectionFailed: Boolean;
        MockIsBlockedByEnvironment: Boolean;
        MockRequestFailed: Boolean;

    procedure Send(HttpClient: HttpClient; HttpRequestMessage: Codeunit "Http Request Message"; var HttpResponseMessage: Codeunit "Http Response Message") Success: Boolean;
    var
        ResponseMessage: HttpResponseMessage;
    begin
        if MockConnectionFailed then begin
            Success := false;
            exit;
        end;

        if MockIsBlockedByEnvironment then begin
            Success := false;
            HttpResponseMessage.SetIsBlockedByEnvironment(true);
            exit;
        end;

        if MockRequestFailed then begin
            Success := true;
            HttpResponseMessage.SetHttpStatusCode(400);
            HttpResponseMessage.SetReasonPhrase('Bad Request');
            exit;
        end;

        Success := HttpClient.Send(HttpRequestMessage.GetHttpRequestMessage(), ResponseMessage);
        HttpResponseMessage.SetResponseMessage(ResponseMessage);
    end;

    procedure Initialize()
    begin
        MockConnectionFailed := false;
        MockIsBlockedByEnvironment := false;
        MockRequestFailed := false;
    end;

    procedure SetMockConnectionFailed()
    begin
        MockConnectionFailed := true;
        MockIsBlockedByEnvironment := false;
        MockRequestFailed := false;
    end;

    procedure SetMockIsBlockedByEnvironment()
    begin
        MockConnectionFailed := false;
        MockIsBlockedByEnvironment := true;
        MockRequestFailed := false;
    end;

    procedure SetMockRequestFailed()
    begin
        MockConnectionFailed := false;
        MockIsBlockedByEnvironment := false;
        MockRequestFailed := true;
    end;
}