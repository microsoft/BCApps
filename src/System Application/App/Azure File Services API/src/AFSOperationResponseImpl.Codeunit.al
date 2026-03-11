// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------

namespace System.Azure.Storage.Files;

/// <summary>
/// Stores the response of an AFS client operation.
/// </summary>
codeunit 8964 "AFS Operation Response Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        [NonDebuggable]
        HttpResponseMessage: HttpResponseMessage;
        ResponseError: Text;

    procedure IsSuccessful(): Boolean
    begin
        exit(HttpResponseMessage.IsSuccessStatusCode);
    end;

    procedure GetError(): Text
    begin
        exit(ResponseError);
    end;

    procedure GetHeaders(): HttpHeaders
    begin
        exit(HttpResponseMessage.Headers());
    end;

    procedure SetError(Error: Text)
    begin
        ResponseError := Error;
    end;

    [NonDebuggable]
    [TryFunction]
    procedure GetResultAsText(var Result: Text);
    begin
        HttpResponseMessage.Content.ReadAs(Result);
    end;

    [NonDebuggable]
    [TryFunction]
    procedure GetResultAsStream(var ResultInStream: InStream)
    begin
        HttpResponseMessage.Content.ReadAs(ResultInStream);
    end;

    [NonDebuggable]
    procedure SetHttpResponse(NewHttpResponseMessage: HttpResponseMessage)
    begin
        HttpResponseMessage := NewHttpResponseMessage;
    end;

    [NonDebuggable]
    procedure GetHeaderValueFromResponseHeaders(HeaderName: Text): Text
    var
        Headers: HttpHeaders;
        Values: array[100] of Text;
    begin
        Headers := HttpResponseMessage.Headers;
        if not Headers.GetValues(HeaderName, Values) then
            exit('');
        exit(Values[1]);
    end;
}