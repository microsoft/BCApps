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
        CurrHttpRequestMessageInstance: HttpRequestMessage;

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
        CurrHttpRequestMessageInstance.Method := Method;
    end;

    procedure SetHttpMethod(Method: Enum "Http Method")
    begin
        SetHttpMethod(Method.Names.Get(Method.Ordinals.IndexOf(Method.AsInteger())));
    end;

    procedure GetHttpMethod() ReturnValue: Text
    begin
        ReturnValue := CurrHttpRequestMessageInstance.Method;
    end;

    procedure SetRequestUri(Uri: Text)
    begin
        CurrHttpRequestMessageInstance.SetRequestUri(Uri);
    end;

    procedure GetRequestUri() Uri: Text
    begin
        Uri := CurrHttpRequestMessageInstance.GetRequestUri();
    end;

    procedure SetHeader(HeaderName: Text; HeaderValue: Text)
    var
        RequestHttpHeaders: HttpHeaders;
    begin
        CurrHttpRequestMessageInstance.GetHeaders(RequestHttpHeaders);
        if RequestHttpHeaders.Contains(HeaderName) or RequestHttpHeaders.ContainsSecret(HeaderName) then
            RequestHttpHeaders.Remove(HeaderName);
        RequestHttpHeaders.Add(HeaderName, HeaderValue);
    end;

    procedure SetHeader(HeaderName: Text; HeaderValue: SecretText)
    var
        RequestHttpHeaders: HttpHeaders;
    begin
        CurrHttpRequestMessageInstance.GetHeaders(RequestHttpHeaders);
        if RequestHttpHeaders.Contains(HeaderName) or RequestHttpHeaders.ContainsSecret(HeaderName) then
            RequestHttpHeaders.Remove(HeaderName);
        RequestHttpHeaders.Add(HeaderName, HeaderValue);
    end;

    procedure GetHeaders() ReturnValue: HttpHeaders
    begin
        CurrHttpRequestMessageInstance.GetHeaders(ReturnValue);
    end;

    procedure GetHeaderValue(HeaderName: Text) Value: Text
    var
        RequestHttpHeaders: HttpHeaders;
        Values: List of [Text];
    begin
        CurrHttpRequestMessageInstance.GetHeaders(RequestHttpHeaders);
        if RequestHttpHeaders.Contains(HeaderName) then begin
            RequestHttpHeaders.GetValues(HeaderName, Values);
            if Values.Count > 0 then
                Value := Values.Get(1);
        end;
    end;

    procedure GetHeaderValues(HeaderName: Text) Values: List of [Text]
    var
        RequestHttpHeaders: HttpHeaders;
    begin
        CurrHttpRequestMessageInstance.GetHeaders(RequestHttpHeaders);
        if RequestHttpHeaders.Contains(HeaderName) then
            RequestHttpHeaders.GetValues(HeaderName, Values);
    end;

    procedure GetSecretHeaderValues(HeaderName: Text) Values: List of [SecretText]
    var
        RequestHttpHeaders: HttpHeaders;
    begin
        CurrHttpRequestMessageInstance.GetHeaders(RequestHttpHeaders);
        if RequestHttpHeaders.ContainsSecret(HeaderName) then
            RequestHttpHeaders.GetSecretValues(HeaderName, Values);
    end;

    procedure SetCookie(Name: Text; Value: Text) Success: Boolean
    begin
        Success := CurrHttpRequestMessageInstance.SetCookie(Name, Value);
    end;

    procedure SetCookie(TheCookie: Cookie) Success: Boolean
    begin
        Success := CurrHttpRequestMessageInstance.SetCookie(TheCookie);
    end;

    procedure GetCookieNames() CookieNames: List of [Text]
    begin
        CookieNames := CurrHttpRequestMessageInstance.GetCookieNames();
    end;

    procedure GetCookies() Cookies: List of [Cookie]
    var
        CookieName: Text;
        TheCookie: Cookie;
    begin
        foreach CookieName in CurrHttpRequestMessageInstance.GetCookieNames() do begin
            CurrHttpRequestMessageInstance.GetCookie(CookieName, TheCookie);
            Cookies.Add(TheCookie);
        end;
    end;

    procedure GetCookie(Name: Text) ReturnValue: Cookie
    begin
        if CurrHttpRequestMessageInstance.GetCookie(Name, ReturnValue) then;
    end;

    procedure GetCookie(Name: Text; var TheCookie: Cookie) Success: Boolean
    begin
        Success := CurrHttpRequestMessageInstance.GetCookie(Name, TheCookie);
    end;

    procedure RemoveCookie(Name: Text) Success: Boolean
    begin
        Success := CurrHttpRequestMessageInstance.RemoveCookie(Name);
    end;

    procedure SetHttpRequestMessage(var RequestMessage: HttpRequestMessage)
    begin
        CurrHttpRequestMessageInstance := RequestMessage;
    end;

    procedure SetContent(HttpContent: Codeunit "Http Content")
    begin
        CurrHttpRequestMessageInstance.Content := HttpContent.GetHttpContent();
    end;

    procedure GetRequestMessage() ReturnValue: HttpRequestMessage
    begin
        ReturnValue := CurrHttpRequestMessageInstance;
    end;
}