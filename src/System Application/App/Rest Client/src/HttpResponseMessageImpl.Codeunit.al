// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace System.RestClient;

codeunit 2357 "Http Response Message Impl."
{
    Access = Internal;
    InherentEntitlements = X;
    InherentPermissions = X;

    #region Constructors
    procedure Create(ResponseMessage: HttpResponseMessage): Codeunit "Http Response Message Impl."
    begin
        SetResponseMessage(ResponseMessage);
        exit(this);
    end;
    #endregion

    #region IsBlockedByEnvironment
    var
        IsBlockedByEnvironment: Boolean;

    procedure SetIsBlockedByEnvironment(Value: Boolean)
    begin
        IsBlockedByEnvironment := Value;
    end;

    procedure GetIsBlockedByEnvironment() ReturnValue: Boolean
    begin
        ReturnValue := IsBlockedByEnvironment;
    end;
    #endregion

    #region HttpStatusCode
    var
        HttpStatusCode: Integer;

    procedure SetHttpStatusCode(Value: Integer)
    begin
        HttpStatusCode := Value;
        IsSuccessStatusCode := Value in [200 .. 299];
    end;

    procedure GetHttpStatusCode() ReturnValue: Integer
    begin
        ReturnValue := HttpStatusCode
    end;
    #endregion

    #region IsSuccessStatusCode
    var
        IsSuccessStatusCode: Boolean;

    procedure GetIsSuccessStatusCode() Result: Boolean
    begin
        Result := IsSuccessStatusCode;
    end;

    procedure SetIsSuccessStatusCode(Value: Boolean)
    begin
        IsSuccessStatusCode := Value;
    end;
    #endregion

    #region ReasonPhrase
    var
        ReasonPhrase: Text;

    procedure SetReasonPhrase(Value: Text)
    begin
        ReasonPhrase := Value;
    end;

    procedure GetReasonPhrase() ReturnValue: Text
    begin
        ReturnValue := ReasonPhrase;
    end;
    #endregion

    #region HttpContent
    var
        HttpContent: Codeunit "Http Content";

    procedure SetContent(Content: Codeunit "Http Content")
    begin
        HttpContent := Content;
    end;

    procedure GetContent() ReturnValue: Codeunit "Http Content"
    begin
        ReturnValue := HttpContent;
    end;
    #endregion

    #region HttpResponseMessage
    var
        CurrHttpResponseMessageInstance: HttpResponseMessage;

    procedure SetResponseMessage(var ResponseMessage: HttpResponseMessage)
    begin
        ClearAll();
        CurrHttpResponseMessageInstance := ResponseMessage;
        SetIsBlockedByEnvironment(ResponseMessage.IsBlockedByEnvironment);
        SetHttpStatusCode(ResponseMessage.HttpStatusCode);
        SetReasonPhrase(ResponseMessage.ReasonPhrase);
        SetIsSuccessStatusCode(ResponseMessage.IsSuccessStatusCode);
        SetHeaders(ResponseMessage.Headers);
        SetContent(HttpContent.Create(ResponseMessage.Content));
    end;

    procedure GetResponseMessage() ReturnValue: HttpResponseMessage
    begin
        ReturnValue := CurrHttpResponseMessageInstance;
    end;
    #endregion

    #region HttpHeaders
    var
        ResponseHttpHeaders: HttpHeaders;

    procedure SetHeaders(Headers: HttpHeaders)
    begin
        ResponseHttpHeaders := Headers;
    end;

    procedure GetHeaders() ReturnValue: HttpHeaders
    begin
        ReturnValue := ResponseHttpHeaders;
    end;
    #endregion

    #region Cookies
    var
        GlobalCookiesInitialized: Boolean;
        GlobalCookies: Dictionary of [Text, Cookie];

    procedure SetCookies(Cookies: Dictionary of [Text, Cookie])
    begin
        GlobalCookies := Cookies;
        GlobalCookiesInitialized := true;
    end;

    procedure GetCookies() Cookies: Dictionary of [Text, Cookie]
    begin
        InitializeCookies();
        Cookies := GlobalCookies;
    end;

    procedure GetCookieNames() CookieNames: List of [Text]
    begin
        InitializeCookies();
        CookieNames := GlobalCookies.Keys();
    end;

    procedure GetCookie(Name: Text) TheCookie: Cookie
    begin
        InitializeCookies();
        if GlobalCookies.Get(Name, TheCookie) then;
    end;

    procedure GetCookie(Name: Text; var TheCookie: Cookie) Success: Boolean
    begin
        InitializeCookies();
        Success := GlobalCookies.Get(Name, TheCookie);
    end;

    local procedure InitializeCookies()
    var
        CookieName: Text;
        Cookie: Cookie;
    begin
        if GlobalCookiesInitialized then
            exit;

        foreach CookieName in CurrHttpResponseMessageInstance.GetCookieNames() do begin
            CurrHttpResponseMessageInstance.GetCookie(CookieName, Cookie);
            GlobalCookies.Add(CookieName, Cookie);
        end;

        GlobalCookiesInitialized := true;
    end;
    #endregion

    #region ErrorMessage
    var
        ErrorMessage: Text;
        GlobalException: ErrorInfo;

    procedure SetErrorMessage(Value: Text)
    begin
        ErrorMessage := Value;
    end;

    procedure GetErrorMessage(): Text
    begin
        if GlobalException.Message <> '' then
            exit(GlobalException.Message);

        if ErrorMessage <> '' then
            exit(ErrorMessage);

        exit(GetLastErrorText());
    end;

    procedure SetException(Exception: ErrorInfo)
    begin
        GlobalException := Exception;
    end;

    procedure GetException() Exception: ErrorInfo
    var
        RestClientExceptionBuilder: Codeunit "Rest Client Exception Builder";
    begin
        if GlobalException.Message = '' then
            Exception := RestClientExceptionBuilder.CreateException(Enum::"Rest Client Exception"::UnknownException, GetErrorMessage())
        else
            Exception := GlobalException;
    end;
    #endregion
}