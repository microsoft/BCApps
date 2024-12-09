// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

codeunit 2353 "Http Request Message Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    var
        HttpRequestMessage: HttpRequestMessage;

    procedure Create(Method: Enum "Http Method"; RequestUri: Text; Content: Codeunit "Http Content"): Codeunit "Http Request Message Impl."
    begin
        ClearAll();
        SetHttpMethod(Method);
        SetRequestUri(RequestUri);
        SetContent(Content);
        exit(this);
    end;

    procedure SetHttpMethod(Method: Text)
    begin
        HttpRequestMessage.Method := Method;
    end;

    procedure SetHttpMethod(Method: Enum "Http Method")
    begin
        SetHttpMethod(Method.Names.Get(Method.Ordinals.IndexOf(Method.AsInteger())));
    end;

    procedure GetHttpMethod() ReturnValue: Text
    begin
        ReturnValue := HttpRequestMessage.Method;
    end;

    procedure SetRequestUri(Uri: Text)
    begin
        HttpRequestMessage.SetRequestUri(Uri);
    end;

    procedure GetRequestUri() Uri: Text
    begin
        Uri := HttpRequestMessage.GetRequestUri();
    end;

    procedure SetHeader(HeaderName: Text; HeaderValue: Text)
    var
        HttpHeaders: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains(HeaderName) or HttpHeaders.ContainsSecret(HeaderName) then
            HttpHeaders.Remove(HeaderName);
        HttpHeaders.Add(HeaderName, HeaderValue);
    end;

    procedure SetHeader(HeaderName: Text; HeaderValue: SecretText)
    var
        HttpHeaders: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains(HeaderName) or HttpHeaders.ContainsSecret(HeaderName) then
            HttpHeaders.Remove(HeaderName);
        HttpHeaders.Add(HeaderName, HeaderValue);
    end;

    procedure GetHeaders() ReturnValue: HttpHeaders
    begin
        HttpRequestMessage.GetHeaders(ReturnValue);
    end;

    procedure GetHeaderValue(HeaderName: Text) Value: Text
    var
        HttpHeaders: HttpHeaders;
        Values: List of [Text];
    begin
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains(HeaderName) then begin
            HttpHeaders.GetValues(HeaderName, Values);
            if Values.Count > 0 then
                Value := Values.Get(1);
        end;
    end;

    procedure GetHeaderValues(HeaderName: Text) Values: List of [Text]
    var
        HttpHeaders: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if HttpHeaders.Contains(HeaderName) then
            HttpHeaders.GetValues(HeaderName, Values);
    end;

    procedure GetSecretHeaderValues(HeaderName: Text) Values: List of [SecretText]
    var
        HttpHeaders: HttpHeaders;
    begin
        HttpRequestMessage.GetHeaders(HttpHeaders);
        if HttpHeaders.ContainsSecret(HeaderName) then
            HttpHeaders.GetSecretValues(HeaderName, Values);
    end;

    procedure SetCookie(Name: Text; Value: Text) Success: Boolean
    begin
        Success := HttpRequestMessage.SetCookie(Name, Value);
    end;

    procedure SetCookie(Cookie: Cookie) Success: Boolean
    begin
        Success := HttpRequestMessage.SetCookie(Cookie);
    end;

    procedure GetCookieNames() CookieNames: List of [Text]
    begin
        CookieNames := HttpRequestMessage.GetCookieNames();
    end;

    procedure GetCookies() Cookies: List of [Cookie]
    var
        CookieName: Text;
        Cookie: Cookie;
    begin
        foreach CookieName in HttpRequestMessage.GetCookieNames() do begin
            HttpRequestMessage.GetCookie(CookieName, Cookie);
            Cookies.Add(Cookie);
        end;
    end;

    procedure GetCookie(Name: Text) ReturnValue: Cookie
    begin
        if HttpRequestMessage.GetCookie(Name, ReturnValue) then;
    end;

    procedure GetCookie(Name: Text; var Cookie: Cookie) Success: Boolean
    begin
        Success := HttpRequestMessage.GetCookie(Name, Cookie);
    end;

    procedure RemoveCookie(Name: Text) Success: Boolean
    begin
        Success := HttpRequestMessage.RemoveCookie(Name);
    end;

    procedure SetHttpRequestMessage(var RequestMessage: HttpRequestMessage)
    begin
        HttpRequestMessage := RequestMessage;
    end;

    procedure SetContent(HttpContent: Codeunit "Http Content")
    begin
        HttpRequestMessage.Content := HttpContent.GetHttpContent();
    end;

    procedure GetRequestMessage() ReturnValue: HttpRequestMessage
    begin
        ReturnValue := HttpRequestMessage;
    end;
}